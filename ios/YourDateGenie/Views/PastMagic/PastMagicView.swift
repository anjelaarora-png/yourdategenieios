import SwiftUI

// MARK: - Past Dates (dates that have already taken place)
struct PastMagicView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var coordinator: NavigationCoordinator

    var body: some View {
        NavigationStack {
            ZStack {
                Color.luxuryMaroon
                    .ignoresSafeArea()

                if coordinator.pastPlans.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Dates you’ve already enjoyed — tap to revisit the plan.")
                                .font(Font.bodySans(14, weight: .regular))
                                .foregroundColor(Color.luxuryCreamMuted)
                                .padding(.horizontal, 4)

                            ForEach(coordinator.pastPlans) { plan in
                                PastMagicCard(plan: plan) {
                                    coordinator.currentDatePlan = plan
                                    coordinator.activeSheet = nil
                                    coordinator.activeSheet = .datePlanResult
                                }
                            }
                        }
                        .padding(20)
                    }
                }
            }
            .navigationTitle("Past Dates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.luxuryMaroon, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                            .font(Font.bodySans(15, weight: .semibold))
                            .foregroundColor(Color.luxuryGold)
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Color.luxuryGold.opacity(0.15))
                    .frame(width: 80, height: 80)
                Image(systemName: "clock.fill")
                    .font(.system(size: 36))
                    .foregroundColor(Color.luxuryGold.opacity(0.8))
            }

            Text("No past dates yet")
                .font(Font.header(20, weight: .semibold))
                .foregroundColor(Color.luxuryCream)

            Text("When you mark a saved date as done, it will show up here so you can look back on your adventures.")
                .font(Font.bodySans(14, weight: .regular))
                .foregroundColor(Color.luxuryCreamMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Past Dates Card
private struct PastMagicCard: View {
    let plan: DatePlan
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.luxuryMaroonLight)
                        .frame(width: 56, height: 56)
                    HStack(spacing: 2) {
                        ForEach(plan.stops.prefix(3)) { stop in
                            Text(stop.emoji)
                                .font(.system(size: 18))
                        }
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.luxuryGold.opacity(0.3), lineWidth: 1)
                )

                VStack(alignment: .leading, spacing: 4) {
                    Text(plan.title)
                        .font(Font.bodySans(14, weight: .semibold))
                        .foregroundColor(Color.luxuryCream)
                        .lineLimit(2)
                    Text("\(plan.stops.count) stops · \(plan.totalDuration)")
                        .font(Font.bodySans(12, weight: .regular))
                        .foregroundColor(Color.luxuryMuted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color.luxuryGold.opacity(0.8))
            }
            .padding(16)
            .background(Color.luxuryMaroonLight.opacity(0.8))
            .cornerRadius(18)
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.luxuryGold.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    PastMagicView()
        .environmentObject(NavigationCoordinator.shared)
}
