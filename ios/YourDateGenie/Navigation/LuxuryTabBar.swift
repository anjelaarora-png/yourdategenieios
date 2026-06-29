import SwiftUI

/// Layout constants for the pinned bottom tab bar (shared with scroll insets).
enum LuxuryTabBarMetrics {
    /// Icon + label row height.
    static let barRowHeight: CGFloat = 56
    /// Center + button rises above the bar row.
    static let planButtonProtrusion: CGFloat = 22
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
                    .frame(width: 72)

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
            ZStack {
                Circle()
                    .fill(Color.accentGold)
                    .frame(width: 60, height: 60)
                    .shadow(color: Color.accentGold.opacity(0.35), radius: 12, y: 4)
                    .overlay(
                        Circle()
                            .stroke(Color.backgroundPrimary, lineWidth: 4)
                    )

                Image(systemName: "plus")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundColor(Color.backgroundPrimary)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Plan a date")
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
