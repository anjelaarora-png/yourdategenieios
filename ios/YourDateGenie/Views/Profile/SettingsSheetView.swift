import SwiftUI

// MARK: - Settings Sheet (profile → Settings)
struct SettingsSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var coordinator: NavigationCoordinator
    @ObservedObject private var profileManager = UserProfileManager.shared
    @ObservedObject private var purchases = PurchaseManager.shared
    @ObservedObject private var calendarSync = CalendarSyncManager.shared
    @State private var preferredMapsApp: String = UserDefaults.standard.string(forKey: "dateGenie_preferredMapsApp") ?? "apple"
    @State private var showMapsPicker = false
    @State private var showCalendarPicker = false
    @State private var isConnectingGoogleCalendar = false
    @State private var showEditAccount = false
    @State private var showSubscriptionOffer = false

    @State private var remotePreferences: DBPreferences?
    @State private var isLoadingRemotePreferences = false
    @State private var remotePreferencesError: String?
    @State private var showingReportSheet = false
    @State private var showLegalLinks = false
    @State private var showSignOutConfirm = false
    @Environment(\.openURL) private var openURL

    private var userProfile: UserProfile? {
        profileManager.currentUser
    }

    private func valueOrNotSet(_ v: String?) -> String {
        guard let v, !v.isEmpty else { return "Not set" }
        return v
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.ydgBase
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: YDGSpace.lg) {
                        Text("Settings")
                            .ydgText(.title1)
                            .accessibilityAddTraits(.isHeader)

                        // MARK: - Account (name, email, premium)
                        VStack(alignment: .leading, spacing: YDGSpace.xs) {
                            SettingsGroup(title: "Account") {
                                SettingsValueRow(title: "Name", value: valueOrNotSet(userProfile?.fullName)) { showEditAccount = true }
                                YDGListDivider(leadingInset: YDGSpace.md)
                                SettingsValueRow(title: "Email", value: valueOrNotSet(userProfile?.email)) { showEditAccount = true }
                                YDGListDivider(leadingInset: YDGSpace.md)
                                SettingsValueRow(
                                    title: "Premium",
                                    value: purchases.isSubscribed ? "Active" : "7-day free trial"
                                ) {
                                    // Subscribers manage the plan in the App Store; everyone else sees the offer.
                                    if purchases.isSubscribed, let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                                        openURL(url)
                                    } else {
                                        showSubscriptionOffer = true
                                    }
                                }
                            }
                            if let msg = purchases.lastErrorMessage, !msg.isEmpty {
                                Text(msg)
                                    .ydgText(.footnote, color: .ydgWarning)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .padding(.horizontal, YDGSpace.xxs)
                            }
                        }

                        // MARK: - Planning defaults
                        SettingsGroup(title: "Planning defaults") {
                            if let prefs = userProfile?.preferences, !prefs.defaultStartingPoint.isEmpty || !prefs.defaultCity.isEmpty {
                                SettingsValueRow(
                                    title: "Starting point",
                                    value: prefs.defaultStartingPoint.isEmpty ? prefs.defaultCity : prefs.defaultStartingPoint
                                ) {
                                    dismiss()
                                    coordinator.startEditPreferencesOnly()
                                }
                                YDGListDivider(leadingInset: YDGSpace.md)
                            }
                            SettingsValueRow(title: "Your preferences", value: "Edit") {
                                dismiss()
                                coordinator.startEditPreferencesOnly()
                            }
                            YDGListDivider(leadingInset: YDGSpace.md)
                            SettingsValueRow(title: "Maps app", value: preferredMapsApp == "google" ? "Google Maps" : "Apple Maps") {
                                showMapsPicker = true
                            }
                            if Config.isGoogleCalendarEnabled {
                                YDGListDivider(leadingInset: YDGSpace.md)
                                SettingsValueRow(
                                    title: "Calendar",
                                    value: calendarSync.provider.displayName,
                                    isLoading: isConnectingGoogleCalendar
                                ) { showCalendarPicker = true }
                                .disabled(isConnectingGoogleCalendar)
                            }
                        }

                        // MARK: - Cloud preferences (Supabase)
                        if profileManager.userId != nil {
                            SettingsGroup(title: "Cloud preferences") {
                                if isLoadingRemotePreferences {
                                    HStack {
                                        ProgressView().tint(Color.ydgTextSecondary)
                                        Spacer()
                                    }
                                    .padding(YDGSpace.md)
                                } else if let remotePreferencesError {
                                    Text(remotePreferencesError)
                                        .ydgText(.footnote, color: .ydgWarning)
                                        .fixedSize(horizontal: false, vertical: true)
                                        .padding(YDGSpace.md)
                                } else if let row = remotePreferences {
                                    let items = Self.remotePreferenceRows(for: row)
                                    ForEach(Array(items.enumerated()), id: \.element.label) { index, item in
                                        if index > 0 { YDGListDivider(leadingInset: YDGSpace.md) }
                                        HStack(alignment: .top, spacing: YDGSpace.sm) {
                                            Text(item.label)
                                                .ydgText(.subhead, weight: .regular, color: .ydgTextSecondary)
                                                .frame(width: 110, alignment: .leading)
                                            Text(item.value)
                                                .ydgText(.subhead, weight: .regular)
                                                .frame(maxWidth: .infinity, alignment: .trailing)
                                                .multilineTextAlignment(.trailing)
                                        }
                                        .padding(.horizontal, YDGSpace.md)
                                        .padding(.vertical, YDGSpace.sm)
                                    }
                                } else {
                                    Text("No saved preferences in the cloud for this account yet.")
                                        .ydgText(.footnote, color: .ydgTextSecondary)
                                        .padding(YDGSpace.md)
                                }
                            }
                        }

                        // MARK: - Support & Safety (Apple §1.2) + Legal (Apple §3.1.2 + §5.1.1)
                        SettingsGroup(title: "Support & safety") {
                            SettingsValueRow(title: "Notifications", value: nil) {
                                if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                                    openURL(url)
                                }
                            }
                            if let contactURL = URL(string: "mailto:hello@yourdategenie.com") {
                                YDGListDivider(leadingInset: YDGSpace.md)
                                SettingsLinkRow(title: "Contact support", url: contactURL)
                            }
                            YDGListDivider(leadingInset: YDGSpace.md)
                            SettingsValueRow(title: "Report a concern", value: nil) { showingReportSheet = true }
                            YDGListDivider(leadingInset: YDGSpace.md)
                            SettingsValueRow(title: "Privacy & terms", value: nil) { showLegalLinks = true }
                        }

                        // MARK: - App tour & intro
                        SettingsGroup(title: "Help") {
                            SettingsValueRow(title: "Show home tour again", value: nil) {
                                coordinator.replayHomeTutorial()
                                dismiss()
                            }
                            YDGListDivider(leadingInset: YDGSpace.md)
                            SettingsValueRow(title: "Replay intro slides", value: nil) {
                                coordinator.replayIntroOnboarding()
                                dismiss()
                            }
                            #if DEBUG
                            YDGListDivider(leadingInset: YDGSpace.md)
                            SettingsValueRow(title: "Reset onboarding flags", value: "Debug") {
                                coordinator.replayIntroOnboarding()
                                dismiss()
                            }
                            #endif
                        }

                        if profileManager.isLoggedIn {
                            Button {
                                showSignOutConfirm = true
                            } label: {
                                Text("Sign out")
                                    .ydgText(.body, weight: .semibold, color: .ydgDanger)
                                    .frame(maxWidth: .infinity, minHeight: 44)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, YDGSpace.margin)
                    .padding(.bottom, YDGSpace.xxl)
                }
            }
            .sheet(isPresented: $showEditAccount) {
                EditAccountSheetView()
            }
            .confirmationDialog("Privacy & terms", isPresented: $showLegalLinks, titleVisibility: .visible) {
                Button("Privacy policy") {
                    if let url = URL(string: "https://yourdategenie.com/privacy-policy") { openURL(url) }
                }
                Button("Terms of use") {
                    if let url = URL(string: "https://yourdategenie.com/terms") { openURL(url) }
                }
                Button("Cancel", role: .cancel) {}
            }
            .alert("Sign out?", isPresented: $showSignOutConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Sign out", role: .destructive) {
                    dismiss()
                    coordinator.signOut()
                }
            } message: {
                Text("You can sign back in anytime.")
            }
            .sheet(isPresented: $showingReportSheet) {
                ReportConcernView()
            }
            .sheet(isPresented: $showSubscriptionOffer) {
                PaywallView(onSubscribed: {
                    showSubscriptionOffer = false
                }, showsNotNowButton: true)
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
            .confirmationDialog("Calendar for date nights", isPresented: $showCalendarPicker) {
                Button("Apple Calendar") {
                    calendarSync.selectAppleCalendar()
                }
                if Config.isGoogleSignInConfigured {
                    Button("Google Calendar") {
                        isConnectingGoogleCalendar = true
                        Task {
                            await calendarSync.selectGoogleCalendar()
                            isConnectingGoogleCalendar = false
                        }
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Free-evening detection and adding plans to your calendar use this choice. Google Calendar asks for permission the first time.")
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.ydgBase, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                            .font(.ydg(.body, weight: .semibold))
                            .foregroundColor(Color.ydgAccent)
                    }
                }
            }
            .task(id: profileManager.userId) {
                await loadRemotePreferences()
            }
        }
    }

    private func loadRemotePreferences() async {
        guard let userId = profileManager.userId else {
            remotePreferences = nil
            remotePreferencesError = nil
            isLoadingRemotePreferences = false
            return
        }
        isLoadingRemotePreferences = true
        remotePreferencesError = nil
        defer { isLoadingRemotePreferences = false }
        do {
            remotePreferences = try await SupabaseDatabaseService.shared.fetchPreferences(userId: userId)
        } catch {
            remotePreferences = nil
            remotePreferencesError = error.localizedDescription
        }
    }

    private struct PreferenceRowItem {
        let label: String
        let value: String
    }

    private static func remotePreferenceRows(for prefs: DBPreferences) -> [PreferenceRowItem] {
        let dash = "—"
        func join(_ arr: [String]?) -> String {
            guard let arr, !arr.isEmpty else { return dash }
            return arr.joined(separator: ", ")
        }
        return [
            PreferenceRowItem(label: "Default city", value: prefs.defaultCity?.isEmpty == false ? prefs.defaultCity! : dash),
            PreferenceRowItem(label: "Starting point", value: prefs.defaultStartingPoint?.isEmpty == false ? prefs.defaultStartingPoint! : dash),
            PreferenceRowItem(label: "Budget", value: prefs.budgetRange ?? dash),
            PreferenceRowItem(label: "Cuisines", value: join(prefs.cuisineTypes)),
            PreferenceRowItem(label: "Activities", value: join(prefs.activityTypes)),
            PreferenceRowItem(label: "Updated", value: prefs.updatedAt.formatted(date: .abbreviated, time: .shortened))
        ]
    }
}

// MARK: - Settings group (caption + raised card of rows)
private struct SettingsGroup<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: YDGSpace.xs) {
            Text(title)
                .ydgText(.caption)
                .padding(.horizontal, YDGSpace.xxs)
            VStack(spacing: 0) { content }
                .background(Color.ydgRaised, in: RoundedRectangle(cornerRadius: YDGRadius.card, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: YDGRadius.card, style: .continuous)
                        .stroke(Color.ydgBorder, lineWidth: 1)
                )
        }
    }
}

// MARK: - Settings row (title · trailing value · chevron)
private struct SettingsValueRow: View {
    let title: String
    let value: String?
    var isLoading: Bool = false
    var showsChevron: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: YDGSpace.sm) {
                Text(title)
                    .ydgText(.body, weight: .regular)
                Spacer(minLength: YDGSpace.sm)
                if let value {
                    Text(value)
                        .ydgText(.body, weight: .regular, color: .ydgTextSecondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                if isLoading {
                    ProgressView().tint(Color.ydgTextSecondary)
                } else if showsChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color.ydgTextTertiary)
                }
            }
            .padding(.horizontal, YDGSpace.md)
            .frame(minHeight: 52)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Settings external link row
private struct SettingsLinkRow: View {
    let title: String
    let url: URL

    var body: some View {
        Link(destination: url) {
            HStack(spacing: YDGSpace.sm) {
                Text(title)
                    .ydgText(.body, weight: .regular)
                Spacer(minLength: YDGSpace.sm)
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color.ydgTextTertiary)
            }
            .padding(.horizontal, YDGSpace.md)
            .frame(minHeight: 52)
            .contentShape(Rectangle())
        }
        .accessibilityHint("Opens outside the app")
    }
}

#Preview {
    SettingsSheetView()
        .environmentObject(NavigationCoordinator.shared)
}
