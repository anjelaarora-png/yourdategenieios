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
    
    /// Add a single calendar event for the date plan on the given date.
    /// Uses the first stop's time slot and the plan's total duration to set start/end.
    static func addDatePlan(_ plan: DatePlan, on date: Date) async -> AddResult {
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
