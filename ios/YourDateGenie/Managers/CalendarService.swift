import Foundation
import EventKit

// MARK: - Calendar Service
/// Adds date plans to the user's system calendar (Calendar app).
enum CalendarService {
    private static let store = EKEventStore()
    
    /// Result of adding a plan to the calendar.
    enum AddResult {
        case success
        case denied
        case failed(String)
    }

    /// Outcome of scanning the calendar for mutually-free evenings.
    enum FreeEveningResult {
        case success([FreeEvening])
        case denied
        case failed(String)
    }

    /// A single evening slot the user has no conflicting events in.
    struct FreeEvening: Identifiable, Equatable {
        let id = UUID()
        /// The evening start moment (date + evening start hour).
        let date: Date
        /// Short label, e.g. "Thu 12th".
        let label: String
    }
    
    /// Request calendar access. Call before adding events.
    static func requestAccess() async -> Bool {
        if #available(iOS 17.0, *) {
            return (try? await store.requestFullAccessToEvents()) ?? false
        } else {
            return await withCheckedContinuation { continuation in
                store.requestAccess(to: .event) { granted, _ in
                    continuation.resume(returning: granted)
                }
            }
        }
    }
    
    /// Current authorization status for events.
    static var authorizationStatus: EKAuthorizationStatus {
        EKEventStore.authorizationStatus(for: .event)
    }

    /// Whether the user has previously granted calendar access (avoids re-prompting).
    static var hasCalendarAccess: Bool {
        if #available(iOS 17.0, *) {
            return authorizationStatus == .fullAccess
        } else {
            return authorizationStatus == .authorized
        }
    }

    // MARK: - Free-busy detection (Plan Together · screen 11b)

    /// Scans the user's calendar for evenings with no conflicting events over the
    /// next `daysAhead` days and returns up to `count` free evenings.
    ///
    /// This reads the *local* device calendar via real EventKit free/busy. For "both
    /// partners free" we exchange each side's candidates through the server
    /// (`partner_sessions.inviter_free_slots` / `partner_free_slots`) and intersect with
    /// `mutualFreeEvenings(...)`. One device can only read/write its own calendar, so the
    /// intersection is computed from the uploaded slots — never by reading a remote calendar.
    static func findFreeEvenings(
        count: Int = 3,
        daysAhead: Int = 21,
        eveningStartHour: Int = 18,
        eveningEndHour: Int = 22
    ) async -> FreeEveningResult {
        let granted: Bool
        if #available(iOS 17.0, *) {
            granted = (try? await store.requestFullAccessToEvents()) ?? false
        } else {
            granted = await withCheckedContinuation { cont in
                store.requestAccess(to: .event) { ok, _ in cont.resume(returning: ok) }
            }
        }
        guard granted else { return .denied }

        let cal = Calendar.current
        let now = Date()
        let startOfToday = cal.startOfDay(for: now)
        guard let rangeEnd = cal.date(byAdding: .day, value: daysAhead, to: startOfToday) else {
            return .failed("Couldn't compute date range")
        }

        let predicate = store.predicateForEvents(withStart: startOfToday, end: rangeEnd, calendars: nil)
        let events = store.events(matching: predicate)

        var freeEvenings: [FreeEvening] = []
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

            let hasConflict = events.contains { event in
                guard !event.isAllDay else { return false }
                return event.startDate < eveningEnd && event.endDate > eveningStart
            }

            if !hasConflict {
                freeEvenings.append(FreeEvening(date: eveningStart, label: shortLabel(for: eveningStart)))
            }
        }

        return .success(freeEvenings)
    }

    /// Intersect this device's free evenings with the partner's uploaded free slots so
    /// only nights BOTH are free survive. Matches on calendar day (evening hour is fixed).
    static func mutualFreeEvenings(local: [FreeEvening], partnerSlots: [DBFreeSlot]) -> [FreeEvening] {
        guard !partnerSlots.isEmpty else { return local }
        let cal = Calendar.current
        let partnerDays = Set(partnerSlots.map { cal.startOfDay(for: $0.date) })
        return local.filter { partnerDays.contains(cal.startOfDay(for: $0.date)) }
    }

    /// Compact label like "Thu 12th".
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
    
    /// Add a single calendar event for the date plan on the given date.
    /// Uses the first stop's time slot and the plan's total duration to set start/end.
    /// When `withReminders` is true, sets alarms 1 day and 2 hours before (screen 11f).
    static func addDatePlan(_ plan: DatePlan, on date: Date, withReminders: Bool = true) async -> AddResult {
        let granted: Bool
        if #available(iOS 17.0, *) {
            granted = (try? await store.requestFullAccessToEvents()) ?? false
        } else {
            granted = await withCheckedContinuation { cont in
                store.requestAccess(to: .event) { ok, _ in cont.resume(returning: ok) }
            }
        }
        guard granted else { return .denied }
        
        let (start, end) = eventTimes(for: plan, on: date)
        let event = EKEvent(eventStore: store)
        event.calendar = store.defaultCalendarForNewEvents ?? store.calendars(for: .event).first
        event.title = plan.title
        event.notes = eventNotes(from: plan)
        event.location = plan.stops.first?.address
        event.startDate = start
        event.endDate = end
        event.isAllDay = false

        if withReminders {
            // Gentle nudges for both partners: the night before + a couple hours before.
            event.addAlarm(EKAlarm(relativeOffset: -86_400))
            event.addAlarm(EKAlarm(relativeOffset: -7_200))
        }
        
        do {
            try store.save(event, span: .thisEvent)
            return .success
        } catch {
            return .failed(error.localizedDescription)
        }
    }
    
    /// Build start and end dates from the plan's first stop timeSlot and totalDuration.
    private static func eventTimes(for plan: DatePlan, on date: Date) -> (start: Date, end: Date) {
        let cal = Calendar.current
        var startComps = cal.dateComponents([.year, .month, .day], from: date)
        
        if let first = plan.stops.first,
           let (hour, minute) = parseTimeSlot(first.timeSlot) {
            startComps.hour = hour
            startComps.minute = minute
        } else {
            startComps.hour = 18
            startComps.minute = 0
        }
        
        let start = cal.date(from: startComps) ?? date
        let durationMinutes = parseTotalDuration(plan.totalDuration)
        let end = cal.date(byAdding: .minute, value: durationMinutes, to: start) ?? start
        return (start, end)
    }
    
    /// Parse "3:15 PM" / "4:30 PM" into (hour, minute) in 24h.
    private static func parseTimeSlot(_ timeSlot: String) -> (hour: Int, minute: Int)? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "h:mm a"
        formatter.timeZone = TimeZone.current
        guard let date = formatter.date(from: timeSlot) else {
            formatter.dateFormat = "h a"
            guard let d = formatter.date(from: timeSlot) else { return nil }
            let comps = Calendar.current.dateComponents([.hour, .minute], from: d)
            return (comps.hour ?? 18, comps.minute ?? 0)
        }
        let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (comps.hour ?? 18, comps.minute ?? 0)
    }
    
    /// Parse "4.5 hours", "1 hour", "45 minutes" into total minutes.
    private static func parseTotalDuration(_ totalDuration: String) -> Int {
        let lower = totalDuration.lowercased()
        let numbers = lower.components(separatedBy: CharacterSet.decimalDigits.union(CharacterSet(charactersIn: ".")).inverted)
            .filter { !$0.isEmpty }
        let num = numbers.compactMap { Double($0) }.first ?? 4
        if lower.contains("hour") {
            return Int(num * 60)
        }
        if lower.contains("min") {
            return Int(num)
        }
        return Int(num * 60)
    }
    
    private static func eventNotes(from plan: DatePlan) -> String {
        var lines = [plan.tagline]
        for (i, stop) in plan.stops.enumerated() {
            lines.append("\(i + 1). \(stop.timeSlot) – \(stop.name) (\(stop.duration))")
            if let addr = stop.address { lines.append("   \(addr)") }
        }
        return lines.joined(separator: "\n")
    }
}
