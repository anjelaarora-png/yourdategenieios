import SwiftUI

struct HeroView: View {
    @EnvironmentObject var coordinator: NavigationCoordinator
    @EnvironmentObject private var access: AccessManager
    /// When set (e.g. post–email-confirm gate), overrides default `startDatePlanning()` CTA.
    var onBeginJourney: (() -> Void)? = nil

    var body: some View {
        ZStack {
            Color.ydgBase
                .ignoresSafeArea()

            VStack(spacing: YDGSpace.lg) {
                Spacer(minLength: 0)

                DateNightMarkView(side: 180)

                DateNightsTagline()

                if onBeginJourney != nil {
                    Text("Next, a two-minute Genie profile so every plan fits you both.")
                        .ydgText(.body, color: .ydgTextSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: YDGSpace.lg)

                VStack(spacing: YDGSpace.xs) {
                    Button(onBeginJourney == nil ? "Plan my next date" : "Build my Genie profile") {
                        if let onBeginJourney {
                            onBeginJourney()
                        } else {
                            access.require(.datePlan) {
                                coordinator.startDatePlanning()
                            }
                        }
                    }
                    .buttonStyle(.ydgPrimary)

                    if onBeginJourney != nil {
                        Button("Skip for now") {
                            coordinator.deferInitialPreferences()
                        }
                        .buttonStyle(.ydgTertiary)
                    }
                }
                .padding(.bottom, YDGSpace.xs)
            }
            .padding(.horizontal, YDGSpace.margin)
        }
    }
}

// MARK: - Scale Button Style (for reuse)
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

#Preview {
    HeroView()
        .environmentObject(NavigationCoordinator.shared)
        .environmentObject(AccessManager.shared)
}
