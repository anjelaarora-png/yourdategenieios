import SwiftUI

// MARK: - Saved Plans List Sheet (profile → Saved Plans)
struct SavedPlansListSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var coordinator: NavigationCoordinator

    var body: some View {
        NavigationStack {
            ZStack {
                Color.luxuryMaroon
                    .ignoresSafeArea()

                if coordinator.savedPlans.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Your saved date plans — tap to view or add to calendar.")
                                .font(Font.bodySans(14, weight: .regular))
                                .foregroundColor(Color.luxuryCreamMuted)
                                .padding(.horizontal, 4)

                            ForEach(coordinator.savedPlans) { plan in
                                SavedPlanRowCard(plan: plan) {
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
            .navigationTitle("Saved Plans")
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
                Image(systemName: "bookmark.fill")
                    .font(.system(size: 36))
                    .foregroundColor(Color.luxuryGold.opacity(0.8))
            }

            Text("No saved plans yet")
                .font(Font.header(20, weight: .semibold))
                .foregroundColor(Color.luxuryCream)

            Text("When you save a date plan from the result screen, it will show up here.")
                .font(Font.bodySans(14, weight: .regular))
                .foregroundColor(Color.luxuryCreamMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Saved Plan Row Card
private struct SavedPlanRowCard: View {
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
                        .font(Font.header(15, weight: .bold))
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
    SavedPlansListSheetView()
        .environmentObject(NavigationCoordinator.shared)
}
