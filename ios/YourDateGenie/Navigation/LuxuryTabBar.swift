import SwiftUI

/// Custom bottom navigation: Home · Dates · [ + Plan ] · Convo · You.
/// The center action is elevated because planning a date is the app's single primary job.
struct LuxuryTabBar: View {
    @Binding var selectedTab: NavigationCoordinator.Tab
    let onPlanTapped: () -> Void

    private let leftTabs: [NavigationCoordinator.Tab] = [.home, .dates]
    private let rightTabs: [NavigationCoordinator.Tab] = [.convo, .you]

    var body: some View {
        ZStack(alignment: .top) {
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
            .frame(height: 56)
            .background(tabBarBackground)

            planButton
                .offset(y: -22)
        }
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
        Color.backgroundPrimary
            .overlay(
                Rectangle()
                    .fill(Color.white.opacity(0.08))
                    .frame(height: 1),
                alignment: .top
            )
            .ignoresSafeArea(edges: .bottom)
    }
}
