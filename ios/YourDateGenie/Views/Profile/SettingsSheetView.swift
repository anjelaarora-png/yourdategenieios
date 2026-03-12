import SwiftUI

// MARK: - Settings Sheet (profile → Settings)
struct SettingsSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var coordinator: NavigationCoordinator

    var body: some View {
        NavigationStack {
            ZStack {
                Color.luxuryMaroon
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        Text("App settings and preferences. More options coming soon.")
                            .font(Font.bodySans(14, weight: .regular))
                            .foregroundColor(Color.luxuryCreamMuted)
                            .padding(.horizontal, 4)

                        VStack(spacing: 12) {
                            SettingsRow(
                                icon: "bell.fill",
                                title: "Notifications",
                                subtitle: "Reminders and alerts"
                            )
                            SettingsRow(
                                icon: "moon.fill",
                                title: "Appearance",
                                subtitle: "Theme and display"
                            )
                            SettingsRow(
                                icon: "lock.fill",
                                title: "Privacy",
                                subtitle: "Data and security"
                            )
                        }
                        .padding(18)
                        .luxuryCard()
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Settings")
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
}

// MARK: - Settings Row
private struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(Color.luxuryGold)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Font.bodySans(15, weight: .medium))
                    .foregroundColor(Color.luxuryCream)
                Text(subtitle)
                    .font(Font.bodySans(12, weight: .regular))
                    .foregroundColor(Color.luxuryMuted)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundColor(Color.luxuryMuted)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    SettingsSheetView()
        .environmentObject(NavigationCoordinator.shared)
}
