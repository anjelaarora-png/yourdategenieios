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
        .background(
            tabBarBackground
                .ignoresSafeArea(edges: .bottom)
        )
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
                    .font(.system(size: 20, weight: isSelected ? .semibold : .regular))
                    .frame(height: 22)
                Text(tab.tabBarTitle)
                    .font(Font.bodySans(10, weight: isSelected ? .semibold : .regular))
            }
            .foregroundColor(isSelected ? Color.accentGold : Color.luxuryMuted)
            .frame(maxWidth: .infinity)
            .overlay(alignment: .bottom) {
                if isSelected {
                    Rectangle()
                        .fill(Color.accentMaroon)
                        .frame(height: 2)
                        .padding(.horizontal, 14)
                        .offset(y: 6)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.tabBarTitle)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var planButton: some View {
        Button(action: onPlanTapped) {
            VStack(spacing: 5) {
                ZStack {
                    Circle()
                        .fill(Color.accentGold)
                        .frame(width: 58, height: 58)
                        .shadow(color: Color.accentGold.opacity(0.4), radius: 12, y: 4)
                        .overlay(
                            Circle()
                                .stroke(Color.backgroundPrimary, lineWidth: 3)
                        )

                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(Color.backgroundPrimary)
                }

                Text("Plan Date")
                    .font(Font.bodySans(10, weight: .bold))
                    .tracking(0.2)
                    .foregroundColor(Color.accentGold)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Plan Date")
        .accessibilityHint("Start planning a new date night")
        .homeTutorialAnchor(.planDateButton)
    }

    private var tabBarBackground: some View {
        ZStack {
            CharcoalMaroonBackground()
            Color.black.opacity(0.15)
        }
        .overlay(
            Rectangle()
                .fill(Color.luxeSurfaceBorder)
                .frame(height: 1),
            alignment: .top
        )
    }
}
