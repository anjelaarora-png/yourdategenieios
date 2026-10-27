import SwiftUI

/// Layout constants for the pinned bottom tab bar (shared with scroll insets).
enum LuxuryTabBarMetrics {
    /// Icon + label row height.
    static let barRowHeight: CGFloat = 56
    /// Center plan button rises above the bar row (icon + label).
    static let planButtonProtrusion: CGFloat = 28
    /// Total chrome height above the home-indicator safe area.
    static var barShellHeight: CGFloat { barRowHeight + planButtonProtrusion }
    /// Padding so the last scroll item clears the bar when scrolled to the end.
    static let scrollBreathingRoom: CGFloat = 12
    static var scrollBottomInset: CGFloat { barShellHeight + scrollBreathingRoom }
}

extension View {
    /// Keeps scroll content from sitting under the pinned tab bar; content scrolls behind the opaque bar.
    func mainTabBarScrollInset() -> some View {
        contentMargins(.bottom, LuxuryTabBarMetrics.scrollBottomInset, for: .scrollContent)
    }
}

/// Custom bottom navigation: Home · Dates · [ + Plan ] · Convo · You.
/// The center action is elevated because planning a date is the app's single primary job.
struct LuxuryTabBar: View {
    @Binding var selectedTab: NavigationCoordinator.Tab
    let onPlanTapped: () -> Void

    private let leftTabs: [NavigationCoordinator.Tab] = [.home, .dates]
    private let rightTabs: [NavigationCoordinator.Tab] = [.convo, .you]

    var body: some View {
        ZStack(alignment: .bottom) {
            tabBarBackground
                .frame(height: LuxuryTabBarMetrics.barRowHeight)
                .frame(maxWidth: .infinity, alignment: .bottom)

            HStack(spacing: 0) {
                ForEach(leftTabs, id: \.self) { tab in
                    tabButton(tab)
                }

                Color.clear
                    .frame(width: 80)

                ForEach(rightTabs, id: \.self) { tab in
                    tabButton(tab)
                }
            }
            .frame(height: LuxuryTabBarMetrics.barRowHeight)

            planButton
                .offset(y: -LuxuryTabBarMetrics.planButtonProtrusion)
        }
        .frame(height: LuxuryTabBarMetrics.barShellHeight, alignment: .bottom)
        .frame(maxWidth: .infinity)
        .background(alignment: .bottom) {
            // Fill only the bar row and the home-indicator area; the plan button's
            // protrusion floats over content.
            Color.ydgRaised
                .padding(.top, LuxuryTabBarMetrics.planButtonProtrusion)
                .ignoresSafeArea(edges: .bottom)
        }
        .homeTutorialAnchor(.tabBar)
    }

    private func tabButton(_ tab: NavigationCoordinator.Tab) -> some View {
        let isSelected = selectedTab == tab
        return Button {
            withAnimation(.easeInOut(duration: 0.18)) {
                selectedTab = tab
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: isSelected ? tab.selectedIcon : tab.icon)
                    .font(.system(size: 21, weight: isSelected ? .semibold : .regular))
                    .frame(height: 24)
                Text(tab.tabBarTitle)
                    .font(Font.ydgSans(11, weight: isSelected ? .semibold : .medium))
            }
            .foregroundColor(isSelected ? Color.ydgAccent : Color.ydgTextSecondary)
            .frame(maxWidth: .infinity, minHeight: 48)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.tabBarTitle)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var planButton: some View {
        Button(action: onPlanTapped) {
            VStack(spacing: 4) {
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(Color.ydgTextOnAccent)
                    .frame(width: 60, height: 60)
                    .background(Circle().fill(Color.ydgAccent))
                    .overlay(Circle().stroke(Color.ydgBase, lineWidth: 4))

                Text("Plan")
                    .font(Font.ydgSans(11, weight: .semibold))
                    .foregroundColor(Color.ydgTextPrimary)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Plan Date")
        .accessibilityHint("Start planning a new date night")
        .homeTutorialAnchor(.planDateButton)
    }

    /// Raised surface with a top hairline (no maroon glow, no shadow).
    private var tabBarBackground: some View {
        Color.ydgRaised
            .overlay(
                Rectangle()
                    .fill(Color.ydgBorder)
                    .frame(height: 1),
                alignment: .top
            )
    }
}
