import SwiftUI

/// "Dates" tab — the user's date life: Upcoming · Past · Memories.
struct DatesTabView: View {
    @EnvironmentObject var coordinator: NavigationCoordinator
    @EnvironmentObject private var access: AccessManager
    @State private var segment: Segment = .upcoming

    enum Segment: String, CaseIterable, Identifiable {
        case upcoming = "Upcoming"
        case past = "Past"
        case memories = "Memories"
        var id: String { rawValue }
    }

    var body: some View {
        ZStack {
            Color.ydgBase
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header
                segmentPicker
                    .padding(.horizontal, YDGSpace.margin)
                    .padding(.bottom, YDGSpace.md)

                Group {
                    switch segment {
                    case .upcoming:
                        upcomingContent
                    case .past:
                        planList(
                            coordinator.pastPlans,
                            emptyTitle: "No past dates yet",
                            emptySubtitle: "Once you’ve been on a date, it lands here so you can look back on it."
                        )
                    case .memories:
                        memoriesContent
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        YDGLargeTitle(title: "Your dates")
            .padding(.bottom, YDGSpace.md)
    }

    private var segmentPicker: some View {
        YDGSegmentedControl(options: Segment.allCases, selection: $segment) { $0.rawValue }
    }

    // MARK: - Plan list (Upcoming / Past)

    @ViewBuilder
    private func planList(_ plans: [DatePlan], emptyTitle: String, emptySubtitle: String) -> some View {
        if plans.isEmpty {
            emptyState(title: emptyTitle, subtitle: emptySubtitle)
        } else {
            ScrollView(showsIndicators: false) {
                VStack(spacing: YDGSpace.sm) {
                    ForEach(plans) { plan in
                        DateListRow(plan: plan) {
                            coordinator.currentDatePlan = plan
                            coordinator.activeSheet = nil
                            coordinator.activeSheet = .datePlanResult
                        }
                    }
                }
                .padding(.horizontal, YDGSpace.margin)
                .padding(.top, YDGSpace.xxs)
            }
            .mainTabBarScrollInset()
        }
    }

    // MARK: - Upcoming (grouped: this week · coming up · plans waiting)

    private var waitingPlans: [DatePlan] {
        var seen = Set<UUID>()
        return (coordinator.generatedPlans + coordinator.experiencesWaiting).filter { seen.insert($0.id).inserted }
    }

    private func isThisWeek(_ plan: DatePlan) -> Bool {
        guard let d = plan.scheduledDate else { return false }
        let start = Calendar.current.startOfDay(for: Date())
        guard let end = Calendar.current.date(byAdding: .day, value: 7, to: start) else { return false }
        return d >= start && d < end
    }

    @ViewBuilder
    private var upcomingContent: some View {
        let plans = coordinator.savedPlans
        if plans.isEmpty && waitingPlans.isEmpty {
            emptyState(
                title: "No dates planned yet",
                subtitle: "Plan one and save it. It’ll show up here with the route, reservations and extras."
            )
        } else {
            let thisWeek = plans.filter(isThisWeek)
            let later = plans.filter { !isThisWeek($0) }
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: YDGSpace.lg) {
                    if !thisWeek.isEmpty {
                        planGroup("This week", thisWeek)
                    }
                    if !later.isEmpty {
                        planGroup(thisWeek.isEmpty ? "Saved plans" : "Coming up", later)
                    }
                    if !waitingPlans.isEmpty {
                        waitingRow
                    }
                }
                .padding(.horizontal, YDGSpace.margin)
                .padding(.top, YDGSpace.xxs)
            }
            .mainTabBarScrollInset()
        }
    }

    private func planGroup(_ title: String, _ plans: [DatePlan]) -> some View {
        VStack(alignment: .leading, spacing: YDGSpace.sm) {
            Text(title)
                .ydgText(.caption)
                .accessibilityAddTraits(.isHeader)
            ForEach(plans) { plan in
                DateListRow(plan: plan) {
                    coordinator.currentDatePlan = plan
                    coordinator.activeSheet = nil
                    coordinator.activeSheet = .datePlanResult
                }
            }
        }
    }

    private var waitingRow: some View {
        Button {
            coordinator.generatedPlansSelectedIndex = 0
            if coordinator.generatedPlans.isEmpty {
                coordinator.generatedPlans = waitingPlans
            }
            coordinator.activeSheet = .datePlanOptions
        } label: {
            HStack(spacing: YDGSpace.sm) {
                Image(systemName: "sparkle")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color.ydgTextSecondary)
                    .frame(width: 24)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(waitingPlans.count) plan\(waitingPlans.count == 1 ? "" : "s") waiting")
                        .ydgText(.subhead, weight: .semibold)
                    Text("Save one to put it on the calendar")
                        .ydgText(.footnote, color: .ydgTextSecondary)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color.ydgTextTertiary)
            }
            .padding(YDGSpace.md)
            .overlay(
                RoundedRectangle(cornerRadius: YDGRadius.card, style: .continuous)
                    .strokeBorder(Color.ydgBorderStrong, style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var memoriesContent: some View {
        if access.canAccess(.memory) {
            MemoryGalleryView()
        } else {
            LockedPremiumTabPlaceholder(
                feature: .memory,
                title: "Memories",
                subtitle: "Save photos and moments from your dates in one place."
            )
        }
    }

    private func emptyState(title: String, subtitle: String) -> some View {
        VStack {
            Spacer(minLength: YDGSpace.xl)
            YDGEmptyState(
                systemName: "calendar",
                title: title,
                message: subtitle,
                actionTitle: "Plan my next date",
                action: { coordinator.startDatePlanning() }
            )
            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Date list row

/// Raised card: date block (or stop emojis when unscheduled), title, stops and duration.
private struct DateListRow: View {
    let plan: DatePlan
    let onTap: () -> Void

    private static let weekday: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "EEE"; return f
    }()
    private static let day: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "d"; return f
    }()
    private static let time: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "h:mm a"; return f
    }()

    private var metaLine: String {
        var parts: [String] = []
        if let date = plan.scheduledDate { parts.append(Self.time.string(from: date)) }
        parts.append("\(plan.stops.count) stop\(plan.stops.count == 1 ? "" : "s")")
        if !plan.totalDuration.isEmpty { parts.append(plan.totalDuration) }
        return parts.joined(separator: " · ")
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: YDGSpace.md) {
                dateBlock

                VStack(alignment: .leading, spacing: YDGSpace.xxs) {
                    Text(plan.title)
                        .ydgText(.headline)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    Text(metaLine)
                        .ydgText(.footnote, color: .ydgTextSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color.ydgTextTertiary)
            }
            .ydgCard()
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var dateBlock: some View {
        Group {
            if let date = plan.scheduledDate {
                VStack(spacing: 0) {
                    Text(Self.weekday.string(from: date).uppercased())
                        .font(.ydgSans(12, weight: .semibold))
                        .tracking(0.9)
                        .foregroundColor(Color.ydgHighlight)
                    Text(Self.day.string(from: date))
                        .font(.ydgSans(24, weight: .semibold))
                        .foregroundColor(Color.ydgTextPrimary)
                        .monospacedDigit()
                }
            } else {
                HStack(spacing: 1) {
                    ForEach(plan.stops.prefix(2)) { stop in
                        Text(stop.emoji).font(.system(size: 18))
                    }
                }
            }
        }
        .frame(width: 56, height: 64)
        .background(plan.scheduledDate == nil ? Color.ydgOverlay : Color.ydgHighlightSubtle)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .accessibilityHidden(true)
    }
}
