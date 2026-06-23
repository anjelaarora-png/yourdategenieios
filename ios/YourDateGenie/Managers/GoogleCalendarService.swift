import Foundation
import GoogleSignIn
import UIKit

// MARK: - Google Calendar Service
/// Reads free/busy and writes date-night events to the user's Google Calendar using the
/// already-integrated GoogleSignIn SDK (incremental authorization). This is the Google
/// counterpart to the EventKit-based `CalendarService`; both return the same result enums
/// so call sites can route through `CalendarSyncManager` without caring which backend ran.
///
/// v1 is intentionally client-side and per-device: each partner authorizes their OWN Google
/// Calendar on their OWN device. We never store Google refresh tokens server-side, and we
/// never read a remote partner's calendar — mutual free/busy is still computed by exchanging
/// each side's uploaded free slots (see `PartnerSessionManager.syncAndComputeFreeEvenings`).
enum GoogleCalendarService {

    /// Calendar scopes requested only when the user opts into Google Calendar sync — never
    /// part of base sign-in. `calendar.readonly` powers freeBusy; `calendar.events` powers writes.
    static let calendarScopes = [
        "https://www.googleapis.com/auth/calendar.readonly",
        "https://www.googleapis.com/auth/calendar.events"
    ]

    private static let calendarAPIBase = "https://www.googleapis.com/calendar/v3"

    // MARK: - Authorization (incremental)

    /// Why a Google Calendar operation could not proceed. Mapped to the shared result enums.
    enum AuthOutcome {
        case authorized(GIDGoogleUser)
        case cancelled
        case needsAuthorization
        case notConfigured
        case noPresenter
        case scopeDenied
        case failed(String)
    }

    private static func hasCalendarScopes(_ user: GIDGoogleUser) -> Bool {
        let granted = Set(user.grantedScopes ?? [])
        return calendarScopes.allSatisfy { granted.contains($0) }
    }

    /// Whether the current Google user has already granted the calendar scopes (no prompt needed).
    @MainActor
    static var hasCalendarAccess: Bool {
        guard let user = GIDSignIn.sharedInstance.currentUser else { return false }
        return hasCalendarScopes(user)
    }

    /// Resolves a Google user that holds the calendar scopes, requesting them interactively
    /// when `interactive` is true. Reuses an existing Google session (incremental auth) when
    /// possible so a user who signed in with Google just grants the extra calendar scopes.
    @MainActor
    static func authorize(interactive: Bool) async -> AuthOutcome {
        guard Config.isGoogleSignInConfigured else { return .notConfigured }

        if GIDSignIn.sharedInstance.configuration == nil {
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: Config.googleIOSClientID)
        }

        var user = GIDSignIn.sharedInstance.currentUser
        if user == nil {
            user = try? await GIDSignIn.sharedInstance.restorePreviousSignIn()
        }

        if let user, hasCalendarScopes(user) {
            return .authorized(user)
        }

        guard interactive else { return .needsAuthorization }
        guard let presenter = SocialAuthService.topViewController() else { return .noPresenter }

        do {
            let result: GIDSignInResult
            if let user {
                result = try await user.addScopes(calendarScopes, presenting: presenter)
            } else {
                result = try await GIDSignIn.sharedInstance.signIn(
                    withPresenting: presenter,
                    hint: nil,
                    additionalScopes: calendarScopes
                )
            }
            guard hasCalendarScopes(result.user) else { return .scopeDenied }
            return .authorized(result.user)
        } catch {
            let nsError = error as NSError
            if nsError.domain == kGIDSignInErrorDomain,
               nsError.code == GIDSignInError.canceled.rawValue {
                return .cancelled
            }
            AppLogger.error("Google Calendar authorization failed: \(error)", category: .network)
            return .failed(error.localizedDescription)
        }
    }

    /// Public entry to (re)connect Google Calendar from a settings/opt-in toggle.
    /// Returns true only when the calendar scopes are granted.
    @MainActor
    static func connect() async -> Bool {
        if case .authorized = await authorize(interactive: true) { return true }
        return false
    }

    /// Refreshes the access token if needed and returns a usable bearer token.
    private static func freshAccessToken(for user: GIDGoogleUser) async -> String {
        await withCheckedContinuation { continuation in
            user.refreshTokensIfNeeded { refreshed, _ in
                continuation.resume(returning: (refreshed ?? user).accessToken.tokenString)
            }
        }
    }

    // MARK: - Free/busy detection

    /// Mirrors `CalendarService.findFreeEvenings` but sources busy blocks from the Google
    /// Calendar freeBusy endpoint. Returns the same `FreeEveningResult` so callers are agnostic.
    static func findFreeEvenings(
        count: Int = 3,
        daysAhead: Int = 21,
        eveningStartHour: Int = 18,
        eveningEndHour: Int = 22
    ) async -> CalendarService.FreeEveningResult {
        let auth = await authorize(interactive: true)
        let user: GIDGoogleUser
        switch auth {
        case .authorized(let u): user = u
        case .cancelled, .scopeDenied, .needsAuthorization: return .denied
        case .notConfigured: return .failed("Google Calendar isn't configured yet.")
        case .noPresenter: return .failed("Couldn't open Google sign-in right now.")
        case .failed(let msg): return .failed(msg)
        }

        let token = await freshAccessToken(for: user)
        let cal = Calendar.current
        let now = Date()
        let startOfToday = cal.startOfDay(for: now)
        guard let rangeEnd = cal.date(byAdding: .day, value: daysAhead, to: startOfToday) else {
            return .failed("Couldn't compute date range")
        }

        let busy: [(start: Date, end: Date)]
        do {
            busy = try await fetchBusyBlocks(token: token, timeMin: now, timeMax: rangeEnd)
        } catch let error as GoogleCalendarError {
            return .failed(error.userMessage)
        } catch {
            return .failed(error.localizedDescription)
        }

        var freeEvenings: [CalendarService.FreeEvening] = []
        for offset in 1...daysAhead {
            guard freeEvenings.count < count,
                  let day = cal.date(byAdding: .day, value: offset, to: startOfToday) else { continue }

            var startComps = cal.dateComponents([.year, .month, .day], from: day)
            startComps.hour = eveningStartHour
            startComps.minute = 0
            var endComps = startComps
            endComps.hour = eveningEndHour

            guard let eveningStart = cal.date(from: startComps),
                  let eveningEnd = cal.date(from: endComps) else { continue }

            let hasConflict = busy.contains { $0.start < eveningEnd && $0.end > eveningStart }
            if !hasConflict {
                freeEvenings.append(
                    CalendarService.FreeEvening(date: eveningStart, label: shortLabel(for: eveningStart))
                )
            }
        }

        return .success(freeEvenings)
    }

    private static func fetchBusyBlocks(token: String, timeMin: Date, timeMax: Date) async throws -> [(start: Date, end: Date)] {
        guard let url = URL(string: "\(calendarAPIBase)/freeBusy") else {
            throw GoogleCalendarError.badResponse
        }
        let iso = isoFormatter()
        let body: [String: Any] = [
            "timeMin": iso.string(from: timeMin),
            "timeMax": iso.string(from: timeMax),
            "items": [["id": "primary"]]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response: response, data: data)

        guard
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let calendars = json["calendars"] as? [String: Any],
            let primary = calendars["primary"] as? [String: Any]
        else {
            return []
        }
        // A per-calendar `errors` array (e.g. notFound) means we can't trust emptiness as "free".
        if let errors = primary["errors"] as? [[String: Any]], !errors.isEmpty {
            throw GoogleCalendarError.api("Couldn't read your Google Calendar availability.")
        }
        let busyRaw = primary["busy"] as? [[String: String]] ?? []
        let parser = isoParser()
        return busyRaw.compactMap { block in
            guard let s = block["start"], let e = block["end"],
                  let start = parser.date(from: s) ?? isoFormatter().date(from: s),
                  let end = parser.date(from: e) ?? isoFormatter().date(from: e) else { return nil }
            return (start, end)
        }
    }

    // MARK: - Event write

    /// Mirrors `CalendarService.addDatePlan` but inserts the event into the user's primary
    /// Google Calendar. Returns the same `AddResult` so callers are agnostic.
    static func addDatePlan(_ plan: DatePlan, on date: Date, withReminders: Bool = true) async -> CalendarService.AddResult {
        let auth = await authorize(interactive: true)
        let user: GIDGoogleUser
        switch auth {
        case .authorized(let u): user = u
        case .cancelled, .scopeDenied, .needsAuthorization: return .denied
        case .notConfigured: return .failed("Google Calendar isn't configured yet.")
        case .noPresenter: return .failed("Couldn't open Google sign-in right now.")
        case .failed(let msg): return .failed(msg)
        }

        let token = await freshAccessToken(for: user)
        let (start, end) = CalendarService.eventTimes(for: plan, on: date)
        let notes = CalendarService.eventNotes(from: plan)
        let tz = TimeZone.current.identifier
        let iso = isoFormatter()

        var event: [String: Any] = [
            "summary": plan.title,
            "description": notes,
            "start": ["dateTime": iso.string(from: start), "timeZone": tz],
            "end": ["dateTime": iso.string(from: end), "timeZone": tz]
        ]
        if let location = plan.stops.first?.address {
            event["location"] = location
        }
        if withReminders {
            event["reminders"] = [
                "useDefault": false,
                "overrides": [
                    ["method": "popup", "minutes": 1440],
                    ["method": "popup", "minutes": 120]
                ]
            ]
        }

        guard let url = URL(string: "\(calendarAPIBase)/calendars/primary/events") else {
            return .failed("Couldn't reach Google Calendar.")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: event)
            let (data, response) = try await URLSession.shared.data(for: request)
            try validate(response: response, data: data)
            return .success
        } catch let error as GoogleCalendarError {
            return .failed(error.userMessage)
        } catch {
            return .failed(error.localizedDescription)
        }
    }

    // MARK: - Helpers

    private enum GoogleCalendarError: Error {
        case unauthorized
        case api(String)
        case badResponse

        var userMessage: String {
            switch self {
            case .unauthorized: return "Google Calendar access expired. Please reconnect Google Calendar."
            case .api(let msg): return msg
            case .badResponse: return "Google Calendar returned an unexpected response."
            }
        }
    }

    private static func validate(response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else { throw GoogleCalendarError.badResponse }
        guard (200..<300).contains(http.statusCode) else {
            if http.statusCode == 401 || http.statusCode == 403 {
                throw GoogleCalendarError.unauthorized
            }
            let snippet = String(data: data.prefix(200), encoding: .utf8) ?? ""
            AppLogger.error("Google Calendar API \(http.statusCode): \(snippet)", category: .network)
            throw GoogleCalendarError.api("Google Calendar request failed (\(http.statusCode)).")
        }
    }

    private static func isoFormatter() -> ISO8601DateFormatter {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        f.timeZone = TimeZone.current
        return f
    }

    private static func isoParser() -> ISO8601DateFormatter {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }

    private static func shortLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEE"
        let weekday = formatter.string(from: date)
        let day = Calendar.current.component(.day, from: date)
        return "\(weekday) \(day)\(ordinalSuffix(day))"
    }

    private static func ordinalSuffix(_ day: Int) -> String {
        switch day % 100 {
        case 11, 12, 13: return "th"
        default:
            switch day % 10 {
            case 1: return "st"
            case 2: return "nd"
            case 3: return "rd"
            default: return "th"
            }
        }
    }
}
