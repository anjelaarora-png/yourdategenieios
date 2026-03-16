import SwiftUI

// MARK: - Settings Sheet (profile → Settings)
struct SettingsSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var coordinator: NavigationCoordinator
    @ObservedObject private var profileManager = UserProfileManager.shared
    @State private var preferredMapsApp: String = UserDefaults.standard.string(forKey: "dateGenie_preferredMapsApp") ?? "apple"
    @State private var showMapsPicker = false

    private var userProfile: UserProfile? {
        profileManager.currentUser
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.luxuryMaroon
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // MARK: - Account (name, email, phone)
                        VStack(alignment: .leading, spacing: 16) {
                            HStack(spacing: 6) {
                                Text("Account")
                                    .font(Font.header(18, weight: .semibold))
                                    .foregroundColor(Color.luxuryCream)
                            }
                            VStack(alignment: .leading, spacing: 14) {
                                SettingsAccountRow(
                                    icon: "person.fill",
                                    label: "Name",
                                    value: userProfile?.fullName.isEmpty == false ? userProfile!.fullName : "Not set"
                                )
                                SettingsAccountRow(
                                    icon: "envelope.fill",
                                    label: "Email",
                                    value: userProfile?.email.isEmpty == false ? userProfile!.email : "Not set"
                                )
                                SettingsAccountRow(
                                    icon: "phone.fill",
                                    label: "Phone",
                                    value: userProfile?.phoneNumber.isEmpty == false ? userProfile!.phoneNumber : "Not set"
                                )
                            }
                        }
                        .padding(18)
                        .luxuryCard()

                        // MARK: - Date preferences (saved from onboarding / profile)
                        if let prefs = userProfile?.preferences {
                            PreferencesSummaryCard(preferences: prefs) {
                                dismiss()
                                coordinator.startEditPreferencesOnly()
                            }
                        }

                        Text("App settings")
                            .font(Font.bodySans(14, weight: .medium))
                            .foregroundColor(Color.luxuryCreamMuted)
                            .padding(.horizontal, 4)

                        VStack(spacing: 12) {
                            Button {
                                showMapsPicker = true
                            } label: {
                                HStack(spacing: 14) {
                                    Image(systemName: "map.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(Color.luxuryGold)
                                        .frame(width: 28)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Maps app")
                                            .font(Font.bodySans(15, weight: .medium))
                                            .foregroundColor(Color.luxuryCream)
                                        Text(preferredMapsApp == "google" ? "Google Maps" : "Apple Maps")
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
                            .buttonStyle(.plain)
                            
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

                            #if DEBUG
                            Button {
                                coordinator.resetOnboarding()
                                dismiss()
                            } label: {
                                HStack(spacing: 14) {
                                    Image(systemName: "arrow.counterclockwise")
                                        .font(.system(size: 18))
                                        .foregroundColor(Color.luxuryGold)
                                        .frame(width: 28)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Show onboarding again")
                                            .font(Font.bodySans(15, weight: .medium))
                                            .foregroundColor(Color.luxuryCream)
                                        Text("For testing")
                                            .font(Font.bodySans(12, weight: .regular))
                                            .foregroundColor(Color.luxuryMuted)
                                    }
                                    Spacer()
                                }
                                .padding(.vertical, 4)
                            }
                            .buttonStyle(.plain)
                            #endif
                        }
                        .padding(18)
                        .luxuryCard()
                    }
                    .padding(20)
                }
            }
            .confirmationDialog("Maps app", isPresented: $showMapsPicker) {
                Button("Apple Maps") {
                    preferredMapsApp = "apple"
                    UserDefaults.standard.set("apple", forKey: "dateGenie_preferredMapsApp")
                }
                Button("Google Maps") {
                    preferredMapsApp = "google"
                    UserDefaults.standard.set("google", forKey: "dateGenie_preferredMapsApp")
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Trending places and map links will open in this app.")
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

// MARK: - Settings Account Row (read-only label + value)
private struct SettingsAccountRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(Color.luxuryGold)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(Font.bodySans(12, weight: .medium))
                    .foregroundColor(Color.luxuryMuted)
                Text(value)
                    .font(Font.bodySans(15, weight: .regular))
                    .foregroundColor(Color.luxuryCream)
            }
            Spacer()
        }
        .padding(.vertical, 4)
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
