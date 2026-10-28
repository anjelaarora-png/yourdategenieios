import SwiftUI

/// Shown when the user taps + Plan — pick how to fill the questionnaire (final design 3.0).
/// A single-choice list with one Continue, rather than a stack of buttons.
struct PlanDateStartSheet: View {
    @EnvironmentObject private var coordinator: NavigationCoordinator
    @Environment(\.dismiss) private var dismiss

    private struct Option: Identifiable {
        let id: PlanIntent
        let title: String
        let subtitle: String
    }

    @State private var selection: PlanIntent = .prefilled

    private var resumeStep: Int? {
        QuestionnaireProgressStore.load()?.step
    }

    private var options: [Option] {
        var list = [Option(id: .prefilled, title: "Use my saved preferences", subtitle: "Location, vibe and food come prefilled. Edit anything.")]
        if QuestionnaireProgressStore.hasValidProgress, let step = resumeStep {
            list.append(Option(id: .resume, title: "Continue where I left off", subtitle: "Pick up at step \(step) of 6."))
        }
        if LastQuestionnaireStore.hasLastData {
            list.append(Option(id: .repeatLast, title: "Repeat my last date setup", subtitle: "Same answers as last time."))
        }
        list.append(Option(id: .startFresh, title: "Start from scratch", subtitle: "A blank form."))
        return list
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.ydgRaised
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: YDGSpace.sm) {
                        VStack(alignment: .leading, spacing: YDGSpace.xs) {
                            Text("Plan a date")
                                .ydgText(.caption)
                            Text("How should we set this one up?")
                                .ydgText(.title1)
                                .fixedSize(horizontal: false, vertical: true)
                                .accessibilityAddTraits(.isHeader)
                            Text("Most people keep their saved preferences and change only what’s different tonight.")
                                .ydgText(.body, color: .ydgTextSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.top, YDGSpace.xl)
                        .padding(.bottom, YDGSpace.sm)

                        ForEach(options) { option in
                            optionRow(option)
                        }
                    }
                    .padding(.horizontal, YDGSpace.lg)
                    .padding(.bottom, YDGSpace.lg)
                }

                Button("Continue") {
                    // Same order as before the redesign: hand off, then close the chooser.
                    coordinator.startDatePlanning(mode: selection)
                    dismiss()
                }
                .buttonStyle(.ydgPrimary)
                .padding(.horizontal, YDGSpace.lg)
                .padding(.bottom, YDGSpace.md)
            }

            Button {
                coordinator.showPlanStartChooser = false
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color.ydgTextPrimary)
                    .frame(width: 30, height: 30)
                    .background(Circle().fill(Color.ydgOverlay))
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Close")
            .padding(.top, YDGSpace.sm)
            .padding(.trailing, YDGSpace.sm)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(Color.ydgRaised)
    }

    private func optionRow(_ option: Option) -> some View {
        let isSelected = selection == option.id
        return Button {
            selection = option.id
        } label: {
            HStack(alignment: .top, spacing: YDGSpace.sm) {
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.ydgAccent : Color.ydgBorderStrong, lineWidth: isSelected ? 6 : 1.5)
                        .frame(width: 22, height: 22)
                    if isSelected {
                        Circle().fill(Color.ydgAccentSubtle).frame(width: 10, height: 10)
                    }
                }
                .padding(.top, 1)
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text(option.title)
                        .ydgText(.headline)
                        .multilineTextAlignment(.leading)
                    Text(option.subtitle)
                        .ydgText(.subhead, weight: .regular, color: .ydgTextSecondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            .padding(YDGSpace.md)
            .background(
                isSelected ? Color.ydgAccentSubtle : Color.ydgOverlay,
                in: RoundedRectangle(cornerRadius: YDGRadius.card, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: YDGRadius.card, style: .continuous)
                    .stroke(isSelected ? Color.ydgAccent : Color.ydgBorder, lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

#Preview {
    PlanDateStartSheet()
        .environmentObject(NavigationCoordinator.shared)
}
