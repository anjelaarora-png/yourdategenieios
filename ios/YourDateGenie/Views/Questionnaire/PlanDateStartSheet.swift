import SwiftUI

/// Shown when the user taps + Plan — pick how to fill the questionnaire.
struct PlanDateStartSheet: View {
    @EnvironmentObject private var coordinator: NavigationCoordinator
    @Environment(\.dismiss) private var dismiss

    private var resumeStep: Int? {
        QuestionnaireProgressStore.load()?.step
    }

    var body: some View {
        NavigationStack {
            ZStack {
                CharcoalMaroonBackground()
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("How should we set up this date?")
                            .font(Font.bodySerif(22, weight: .regular))
                            .foregroundColor(Color.luxuryCream)
                            .padding(.top, 8)

                        Text("Most people keep their saved preferences and change only what’s different tonight.")
                            .font(Font.bodySans(14, weight: .regular))
                            .foregroundColor(Color.luxuryCreamMuted)

                        planOptionButton(
                            title: "Use my saved preferences",
                            subtitle: "Prefill location, vibe, food, and more from Settings. You can edit anything.",
                            badge: "Recommended",
                            isPrimary: true
                        ) {
                            coordinator.startDatePlanning(mode: .prefilled)
                            dismiss()
                        }

                        if LastQuestionnaireStore.hasLastData {
                            planOptionButton(
                                title: "Repeat my last date setup",
                                subtitle: "Same answers as your previous plan — swap details where you want.",
                                badge: nil,
                                isPrimary: false
                            ) {
                                coordinator.startDatePlanning(mode: .repeatLast)
                                dismiss()
                            }
                        }

                        if QuestionnaireProgressStore.hasValidProgress, let step = resumeStep {
                            planOptionButton(
                                title: "Continue where I left off",
                                subtitle: "Pick up at step \(step) of 6 from your last session.",
                                badge: nil,
                                isPrimary: false
                            ) {
                                coordinator.startDatePlanning(mode: .resume)
                                dismiss()
                            }
                        }

                        planOptionButton(
                            title: "Start from scratch",
                            subtitle: "Blank form. Nothing from Settings or your last plan.",
                            badge: nil,
                            isPrimary: false,
                            outline: true
                        ) {
                            coordinator.startDatePlanning(mode: .startFresh)
                            dismiss()
                        }
                    }
                    .padding(20)
                    .padding(.bottom, 24)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Plan a date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        coordinator.showPlanStartChooser = false
                        dismiss()
                    }
                    .foregroundColor(Color.luxuryGold)
                }
            }
            .toolbarBackground(Color.backgroundPrimary, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    @ViewBuilder
    private func planOptionButton(
        title: String,
        subtitle: String,
        badge: String?,
        isPrimary: Bool,
        outline: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(title)
                        .font(Font.bodySans(16, weight: .semibold))
                        .foregroundColor(isPrimary ? Color.backgroundPrimary : Color.luxuryCream)
                        .multilineTextAlignment(.leading)
                    if let badge {
                        Text(badge)
                            .font(Font.bodySans(10, weight: .bold))
                            .foregroundColor(Color.luxuryMaroon)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.luxuryGold.opacity(0.95))
                            .clipShape(Capsule())
                    }
                    Spacer(minLength: 0)
                }
                Text(subtitle)
                    .font(Font.bodySans(13, weight: .regular))
                    .foregroundColor(isPrimary ? Color.backgroundPrimary.opacity(0.85) : Color.luxuryCreamMuted)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background {
                if isPrimary {
                    LinearGradient.goldShimmer
                } else if outline {
                    Color.clear
                } else {
                    Color.luxuryMaroonLight.opacity(0.9)
                }
            }
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        isPrimary ? Color.clear : Color.luxuryGold.opacity(outline ? 0.45 : 0.22),
                        lineWidth: outline ? 1.5 : 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    PlanDateStartSheet()
        .environmentObject(NavigationCoordinator.shared)
}
