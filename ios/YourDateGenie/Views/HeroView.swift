import SwiftUI

struct HeroView: View {
    @EnvironmentObject var coordinator: NavigationCoordinator
    @EnvironmentObject private var access: AccessManager
    /// When set (e.g. post–email-confirm gate), overrides default `startDatePlanning()` CTA.
    var onBeginJourney: (() -> Void)? = nil

    var body: some View {
        ZStack {
            CharcoalMaroonBackground()
                .ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer(minLength: 0)

                DateNightMarkView(side: 200)

                DateNightsTagline()

                Spacer(minLength: 24)

                Button {
                    if let onBeginJourney {
                        onBeginJourney()
                    } else {
                        access.require(.datePlan) {
                            coordinator.startDatePlanning()
                        }
                    }
                } label: {
                    Text(onBeginJourney == nil ? "Plan My Next Date" : "Continue")
                        .font(Font.bodySans(16, weight: .semibold))
                        .foregroundColor(Color.backgroundPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.accentGold)
                        .cornerRadius(16)
                }
                .buttonStyle(.plain)
                .padding(.bottom, 28)
            }
            .padding(.horizontal, 20)
        }
        .overlay(alignment: .topTrailing) {
            if onBeginJourney != nil {
                Button {
                    coordinator.deferInitialPreferences()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(Color.luxuryGold.opacity(0.9))
                        .symbolRenderingMode(.hierarchical)
                }
                .padding(.top, 56)
                .padding(.trailing, 20)
                .accessibilityLabel("Skip for now")
            }
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
