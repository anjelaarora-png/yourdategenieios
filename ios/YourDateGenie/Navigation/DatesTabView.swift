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
            Color.backgroundPrimary
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header
                segmentPicker
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)

                Group {
                    switch segment {
                    case .upcoming:
                        planList(
                            coordinator.savedPlans,
                            emptyTitle: "No upcoming dates yet",
                            emptySubtitle: "Plan a date and save it — it’ll show up here, ready to revisit."
                        )
                    case .past:
                        planList(
                            coordinator.pastPlans,
                            emptyTitle: "No past dates yet",
                            emptySubtitle: "Once you’ve enjoyed a date, it lands here so you can relive it."
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
        Text("Your Dates")
            .font(Font.bodySerif(28, weight: .regular))
            .foregroundColor(Color.accentGold)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 14)
    }

    private var segmentPicker: some View {
        HStack(spacing: 6) {
            ForEach(Segment.allCases) { item in
                let isSelected = segment == item
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) { segment = item }
                } label: {
                    Text(item.rawValue)
                        .font(Font.bodySans(13, weight: isSelected ? .semibold : .regular))
                        .foregroundColor(isSelected ? Color.textPrimary : Color.luxuryCreamMuted)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(
                            isSelected
                                ? AnyShapeStyle(Color.accentMaroon.opacity(0.35))
                                : AnyShapeStyle(Color.clear)
                        )
                        .overlay(alignment: .bottom) {
                            if isSelected {
                                Rectangle()
                                    .fill(Color.accentMaroon)
                                    .frame(height: 2)
                                    .padding(.horizontal, 8)
                            }
                        }
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Color.surfaceElevated)
        .clipShape(Capsule())
        .overlay(
            Capsule().stroke(Color.accentGold.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - Plan list (Upcoming / Past)

    @ViewBuilder
    private func planList(_ plans: [DatePlan], emptyTitle: String, emptySubtitle: String) -> some View {
        if plans.isEmpty {
            emptyState(title: emptyTitle, subtitle: emptySubtitle)
        } else {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    ForEach(plans) { plan in
                        DateListRow(plan: plan) {
                            coordinator.currentDatePlan = plan
                            coordinator.activeSheet = nil
                            coordinator.activeSheet = .datePlanResult
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)
                .padding(.bottom, 24)
            }
        }
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
        VStack(spacing: 16) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Color.luxuryGold.opacity(0.12))
                    .frame(width: 80, height: 80)
                Image(systemName: "heart.text.square")
                    .font(.system(size: 32))
                    .foregroundColor(Color.luxuryGold.opacity(0.8))
            }
            Text(title)
                .font(Font.bodySans(17, weight: .semibold))
                .foregroundColor(Color.luxuryCream)
            Text(subtitle)
                .font(Font.bodySans(14, weight: .regular))
                .foregroundColor(Color.luxuryMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Button {
                coordinator.startDatePlanning()
            } label: {
                Text("Plan a date")
                    .font(Font.bodySans(15, weight: .semibold))
                    .foregroundColor(Color.luxuryMaroon)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 12)
                    .background(LinearGradient.goldShimmer)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Date list row

private struct DateListRow: View {
    let plan: DatePlan
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                AsyncImage(url: URL(string: plan.displayImageUrl)) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().aspectRatio(contentMode: .fill)
                    case .empty, .failure:
                        ZStack {
                            Color.luxuryMaroonLight
                            HStack(spacing: 2) {
                                ForEach(plan.stops.prefix(3)) { stop in
                                    Text(stop.emoji).font(.system(size: 18))
                                }
                            }
                        }
                    @unknown default:
                        Color.luxuryMaroonLight
                    }
                }
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.luxuryGold.opacity(0.3), lineWidth: 1)
                )

                VStack(alignment: .leading, spacing: 4) {
                    Text(plan.title)
                        .font(Font.bodySerif(15, weight: .regular))
                        .foregroundColor(Color.textOnCard)
                        .lineLimit(2)
                    Text("\(plan.stops.count) stops · \(plan.totalDuration)")
                        .font(Font.bodySans(12, weight: .regular))
                        .foregroundColor(Color.textMutedOnCard)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color.accentGold.opacity(0.8))
            }
            .padding(16)
            .background(Color.creamCard)
            .overlay(alignment: .leading) {
                Rectangle()
                    .fill(Color.accentMaroon)
                    .frame(width: 3)
            }
            .cornerRadius(18)
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.maroonBorderTint, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
