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
                Color.ydgRaised
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: YDGSpace.sm) {
                        VStack(alignment: .leading, spacing: YDGSpace.xs) {
                            Text("How should we set this one up?")
                                .font(.ydgDisplay(30))
                                .tracking(-0.6)
                                .foregroundColor(Color.ydgTextPrimary)
                                .fixedSize(horizontal: false, vertical: true)
                                .accessibilityAddTraits(.isHeader)
                            Text("Most people keep their saved preferences and change only what’s different tonight.")
                                .ydgText(.callout, color: .ydgTextSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.top, YDGSpace.xs)
                        .padding(.bottom, YDGSpace.sm)

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
                    .padding(.horizontal, YDGSpace.lg)
                    .padding(.bottom, YDGSpace.lg)
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
                    .foregroundColor(Color.ydgAccent)
                }
            }
            .toolbarBackground(Color.ydgRaised, for: .navigationBar)
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
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(title)
                            .ydgText(.headline, color: isPrimary ? .ydgAccent : .ydgTextPrimary)
                            .multilineTextAlignment(.leading)
                        if let badge {
                            Text(badge)
                                .font(Font.ydgSans(12, weight: .semibold))
                                .foregroundColor(Color.ydgTextOnAccent)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color.ydgAccent))
                        }
                        Spacer(minLength: 0)
                    }
                    Text(subtitle)
                        .ydgText(.subhead, weight: .regular, color: .ydgTextSecondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(isPrimary ? Color.ydgAccent : Color.ydgTextTertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(YDGSpace.md)
            .background(
                isPrimary ? Color.ydgAccentSubtle : (outline ? Color.clear : Color.ydgOverlay),
                in: RoundedRectangle(cornerRadius: YDGRadius.card, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: YDGRadius.card, style: .continuous)
                    .stroke(isPrimary ? Color.ydgAccent : Color.ydgBorder, lineWidth: isPrimary ? 1.5 : 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    PlanDateStartSheet()
        .environmentObject(NavigationCoordinator.shared)
}
