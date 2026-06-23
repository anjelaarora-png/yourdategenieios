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
    @AppStorage("hasSeenHomeTutorial") private var hasSeenHomeTutorial = false

    @State private var remotePreferences: DBPreferences?
    @State private var isLoadingRemotePreferences = false
    @State private var remotePreferencesError: String?
    @State private var showingReportSheet = false

    private var userProfile: UserProfile? {
        profileManager.currentUser
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.backgroundPrimary
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // MARK: - Account (name, email, phone)
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Account")
                                    .font(Font.header(18, weight: .semibold))
                                    .foregroundColor(Color.luxuryCream)
                                Spacer()
                                Button {
                                    showEditAccount = true
                                } label: {
                                    Text("Edit")
                                        .font(Font.bodySans(14, weight: .semibold))
                                        .foregroundColor(Color.luxuryGold)
                                }
                                .buttonStyle(.plain)
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

                        // MARK: - Subscription (StoreKit 2)
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Subscription")
                                .font(Font.header(18, weight: .semibold))
                                .foregroundColor(Color.luxuryCream)

                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: purchases.isSubscribed ? "checkmark.seal.fill" : "crown")
                                    .font(.system(size: 22))
                                    .foregroundColor(Color.luxuryGold)
                                    .frame(width: 28)

                                VStack(alignment: .leading, spacing: 6) {
                                    Text(purchases.isSubscribed ? "Premium active" : "Premium")
                                        .font(Font.bodySans(16, weight: .semibold))
                                        .foregroundColor(Color.luxuryCream)
                                    Text(
                                        purchases.isSubscribed
                                            ? "Thank you for supporting Your Date Genie."
                                            : "Start free for 7 days, then $14.99/month or $99.99/year."
                                    )
                                    .font(Font.bodySans(13, weight: .regular))
                                    .foregroundColor(Color.luxuryMuted)
                                    .fixedSize(horizontal: false, vertical: true)
                                }
                            }

                            Button {
                                showSubscriptionOffer = true
                            } label: {
                                HStack {
                                    Text("View plans")
                                        .font(Font.bodySans(15, weight: .semibold))
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .semibold))
                                }
                                .foregroundColor(Color.luxuryMaroon)
                                .padding(.vertical, 12)
                                .padding(.horizontal, 16)
                                .frame(maxWidth: .infinity)
                                .background(Color.luxuryGold)
                                .cornerRadius(12)
                            }
                            .buttonStyle(.plain)

                            Button {
                                Task {
                                    await purchases.restorePurchases()
                                }
                            } label: {
                                HStack {
                                    if purchases.isRestoring {
                                        ProgressView()
                                            .tint(Color.luxuryGold)
                                    }
                                    Text("Restore purchases")
                                        .font(Font.bodySans(15, weight: .medium))
                                    Spacer()
                                }
                                .foregroundColor(Color.luxuryCream)
                                .padding(.vertical, 8)
                            }
                            .buttonStyle(.plain)
                            .disabled(purchases.isRestoring)

                            if let subscriptionsURL = URL(string: "https://apps.apple.com/account/subscriptions") {
                                Link(destination: subscriptionsURL) {
                                    HStack {
                                        Text("Manage subscriptions")
                                            .font(Font.bodySans(15, weight: .medium))
                                        Spacer()
                                        Image(systemName: "arrow.up.right.square")
                                            .font(.system(size: 14))
                                    }
                                    .foregroundColor(Color.luxuryGold)
                                    .padding(.vertical, 8)
                                }
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

                        // MARK: - Cloud preferences (Supabase)
                        if profileManager.userId != nil {
                            VStack(alignment: .leading, spacing: 14) {
                                HStack {
                                    Text("Cloud preferences")
                                        .font(Font.header(18, weight: .semibold))
                                        .foregroundColor(Color.luxuryCream)
                                    Spacer()
                                    if isLoadingRemotePreferences {
                                        ProgressView()
                                            .tint(Color.luxuryGold)
                                    }
                                }

                                if let remotePreferencesError {
                                    Text(remotePreferencesError)
                                        .font(Font.bodySans(13, weight: .regular))
                                        .foregroundColor(Color.orange.opacity(0.95))
                                        .fixedSize(horizontal: false, vertical: true)
                                } else if !isLoadingRemotePreferences {
                                    List {
                                        if let row = remotePreferences {
                                            ForEach(Self.remotePreferenceRows(for: row), id: \.label) { item in
                                                HStack(alignment: .top) {
                                                    Text(item.label)
                                                        .font(Font.bodySans(12, weight: .medium))
                                                        .foregroundColor(Color.luxuryMuted)
                                                        .frame(width: 120, alignment: .leading)
                                                    Text(item.value)
                                                        .font(Font.bodySans(14, weight: .regular))
                                                        .foregroundColor(Color.luxuryCream)
                                                        .frame(maxWidth: .infinity, alignment: .leading)
                                                }
                                                .listRowBackground(Color.clear)
                                                .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
                                            }
                                        } else {
                                            Text("No preferences row found in Supabase for this account yet.")
                                                .font(Font.bodySans(13, weight: .regular))
                                                .foregroundColor(Color.luxuryMuted)
                                                .listRowBackground(Color.clear)
                                        }
                                    }
                                    .listStyle(.plain)
                                    .scrollContentBackground(.hidden)
                                    .frame(minHeight: cloudPreferencesListMinHeight)
                                }
                            }
                            .padding(18)
                            .luxuryCard()
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

                            if Config.isGoogleCalendarEnabled {
                                Button {
                                    showCalendarPicker = true
                                } label: {
                                    HStack(spacing: 14) {
                                        Image(systemName: "calendar")
                                            .font(.system(size: 18))
                                            .foregroundColor(Color.luxuryGold)
                                            .frame(width: 28)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Calendar for date nights")
                                                .font(Font.bodySans(15, weight: .medium))
                                                .foregroundColor(Color.luxuryCream)
                                            Text(calendarSync.provider.displayName)
                                                .font(Font.bodySans(12, weight: .regular))
                                                .foregroundColor(Color.luxuryMuted)
                                        }
                                        Spacer()
                                        if isConnectingGoogleCalendar {
                                            ProgressView()
                                                .tint(Color.luxuryGold)
                                        } else {
                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 12))
                                                .foregroundColor(Color.luxuryMuted)
                                        }
                                    }
                                    .padding(.vertical, 4)
                                }
                                .buttonStyle(.plain)
                                .disabled(isConnectingGoogleCalendar)
                            }
                            
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

                        // MARK: - Legal (Apple §3.1.2 + §5.1.1)
                        Text("Legal")
                            .font(Font.bodySans(14, weight: .medium))
                            .foregroundColor(Color.luxuryCreamMuted)
                            .padding(.horizontal, 4)

                        VStack(spacing: 12) {
                            if let privacyURL = URL(string: "https://yourdategenie.com/privacy-policy") {
                                Link(destination: privacyURL) {
                                    HStack(spacing: 14) {
                                        Image(systemName: "hand.raised.fill")
                                            .font(.system(size: 18))
                                            .foregroundColor(Color.luxuryGold)
                                            .frame(width: 28)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Privacy Policy")
                                                .font(Font.bodySans(15, weight: .medium))
                                                .foregroundColor(Color.luxuryCream)
                                            Text("How we handle your data")
                                                .font(Font.bodySans(12, weight: .regular))
                                                .foregroundColor(Color.luxuryMuted)
                                        }
                                        Spacer()
                                        Image(systemName: "arrow.up.right.square")
                                            .font(.system(size: 13))
                                            .foregroundColor(Color.luxuryMuted)
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                            if let termsURL = URL(string: "https://yourdategenie.com/terms") {
                                Link(destination: termsURL) {
                                    HStack(spacing: 14) {
                                        Image(systemName: "doc.text.fill")
                                            .font(.system(size: 18))
                                            .foregroundColor(Color.luxuryGold)
                                            .frame(width: 28)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Terms of Use")
                                                .font(Font.bodySans(15, weight: .medium))
                                                .foregroundColor(Color.luxuryCream)
                                            Text("Your agreement with Your Date Genie LLC")
                                                .font(Font.bodySans(12, weight: .regular))
                                                .foregroundColor(Color.luxuryMuted)
                                        }
                                        Spacer()
                                        Image(systemName: "arrow.up.right.square")
                                            .font(.system(size: 13))
                                            .foregroundColor(Color.luxuryMuted)
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                        .padding(18)
                        .luxuryCard()

                        // MARK: - Support & Safety (Apple §1.2)
                        Text("Support & safety")
                            .font(Font.bodySans(14, weight: .medium))
                            .foregroundColor(Color.luxuryCreamMuted)
                            .padding(.horizontal, 4)

                        VStack(spacing: 12) {
                            if let contactURL = URL(string: "mailto:hello@yourdategenie.com") {
                                Link(destination: contactURL) {
                                    HStack(spacing: 14) {
                                        Image(systemName: "envelope.fill")
                                            .font(.system(size: 18))
                                            .foregroundColor(Color.luxuryGold)
                                            .frame(width: 28)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Contact Support")
                                                .font(Font.bodySans(15, weight: .medium))
                                                .foregroundColor(Color.luxuryCream)
                                            Text("hello@yourdategenie.com")
                                                .font(Font.bodySans(12, weight: .regular))
                                                .foregroundColor(Color.luxuryMuted)
                                        }
                                        Spacer()
                                        Image(systemName: "arrow.up.right.square")
                                            .font(.system(size: 13))
                                            .foregroundColor(Color.luxuryMuted)
                                    }
                                    .padding(.vertical, 4)
                                }
                            }

                            Button {
                                showingReportSheet = true
                            } label: {
                                HStack(spacing: 14) {
                                    Image(systemName: "exclamationmark.bubble.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(Color.luxuryGold)
                                        .frame(width: 28)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Report a Concern")
                                            .font(Font.bodySans(15, weight: .medium))
                                            .foregroundColor(Color.luxuryCream)
                                        Text("Report safety or content issues")
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
                        }
                        .padding(18)
                        .luxuryCard()
                    }
                    .padding(20)
                }

                // App tour
                Button {
                    hasSeenHomeTutorial = false
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "questionmark.circle.fill")
                            .foregroundColor(Color.luxuryGold)
                            .frame(width: 24)
                        Text("Show home tutorial again")
                            .font(Font.bodySans(15, weight: .regular))
                            .foregroundColor(Color.luxuryCream)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                            .foregroundColor(Color.luxuryMuted)
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 14)
                    .frame(minHeight: 44)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)
            }
            .sheet(isPresented: $showEditAccount) {
                EditAccountSheetView()
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
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.backgroundPrimary, for: .navigationBar)
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
            .task(id: profileManager.userId) {
                await loadRemotePreferences()
            }
        }
    }

    private var cloudPreferencesListMinHeight: CGFloat {
        guard let p = remotePreferences else { return 56 }
        return CGFloat(max(120, Self.remotePreferenceRows(for: p).count * 40))
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
