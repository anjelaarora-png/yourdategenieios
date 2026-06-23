import Foundation
import SwiftUI

// MARK: - Calendar Provider

/// Which calendar backend the user has chosen for free/busy detection and event writes.
/// Apple (EventKit) is the default; Google is opt-in and requires Google Calendar scopes.
enum CalendarProvider: String, CaseIterable, Identifiable {
    case apple
    case google

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .apple: return "Apple Calendar"
        case .google: return "Google Calendar"
        }
    }

    var shortName: String {
        switch self {
        case .apple: return "Apple"
        case .google: return "Google"
        }
    }
}

// MARK: - Calendar Sync Manager

/// Single entry point for calendar free/busy + event writes that routes to either the
/// EventKit (`CalendarService`) or Google (`GoogleCalendarService`) backend based on the
/// user's stored preference. Call sites use this instead of a specific backend so switching
/// providers is a one-line preference change with no flow rewrites.
@MainActor
final class CalendarSyncManager: ObservableObject {
    static let shared = CalendarSyncManager()

    private static let providerKey = "calendarProvider"

    @Published var provider: CalendarProvider {
        didSet { UserDefaults.standard.set(provider.rawValue, forKey: Self.providerKey) }
    }

    private init() {
        let stored = UserDefaults.standard.string(forKey: Self.providerKey)
        self.provider = stored.flatMap(CalendarProvider.init(rawValue:)) ?? .apple
    }

    /// Switch to Google Calendar, requesting calendar scopes interactively. Reverts to Apple
    /// if the user cancels or scopes are denied so we never claim Google access we don't have.
    /// Returns the provider actually in effect afterwards.
    @discardableResult
    func selectGoogleCalendar() async -> CalendarProvider {
        let connected = await GoogleCalendarService.connect()
        provider = connected ? .google : .apple
        return provider
    }

    func selectAppleCalendar() {
        provider = .apple
    }

    /// True when the active provider is ready to use without an additional prompt.
    var isActiveProviderConnected: Bool {
        switch provider {
        case .apple: return CalendarService.hasCalendarAccess
        case .google: return GoogleCalendarService.hasCalendarAccess
        }
    }

    // MARK: - Routed operations

    func findFreeEvenings(
        count: Int = 3,
        daysAhead: Int = 21,
        eveningStartHour: Int = 18,
        eveningEndHour: Int = 22
    ) async -> CalendarService.FreeEveningResult {
        switch provider {
        case .apple:
            return await CalendarService.findFreeEvenings(
                count: count,
                daysAhead: daysAhead,
                eveningStartHour: eveningStartHour,
                eveningEndHour: eveningEndHour
            )
        case .google:
            return await GoogleCalendarService.findFreeEvenings(
                count: count,
                daysAhead: daysAhead,
                eveningStartHour: eveningStartHour,
                eveningEndHour: eveningEndHour
            )
        }
    }

    func addDatePlan(_ plan: DatePlan, on date: Date, withReminders: Bool = true) async -> CalendarService.AddResult {
        switch provider {
        case .apple:
            return await CalendarService.addDatePlan(plan, on: date, withReminders: withReminders)
        case .google:
            return await GoogleCalendarService.addDatePlan(plan, on: date, withReminders: withReminders)
        }
    }
}
