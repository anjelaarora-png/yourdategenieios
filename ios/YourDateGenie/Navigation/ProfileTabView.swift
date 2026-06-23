import SwiftUI

// MARK: - Luxury Profile Tab View
struct LuxuryProfileTabView: View {
    @EnvironmentObject var coordinator: NavigationCoordinator
    @EnvironmentObject private var access: AccessManager
    @ObservedObject private var profileManager = UserProfileManager.shared
    @ObservedObject private var partnerManager = PartnerSessionManager.shared
    @StateObject private var notificationManager = NotificationManager.shared
    @EnvironmentObject private var memoryManager: MemoryManager
    @State private var showSignOutAlert = false
    @State private var showDeleteAccountAlert = false
    @State private var showDeleteAccountConfirm = false
    @State private var isDeletingAccount = false
    @State private var restoreMessage: String?
    @State private var showRestoreAlert = false
    @State private var showHelpSupport = false
    
    private var userProfile: UserProfile? {
        profileManager.currentUser
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.backgroundPrimary
                    .ignoresSafeArea()
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 24) {
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Color.surfaceElevated)
                                    .frame(width: 72, height: 72)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.accentGold, lineWidth: 2)
                                    )
                                
                                Text(userInitials)
                                    .font(Font.bodySerif(28, weight: .regular))
                                    .foregroundColor(Color.accentGold)
                            }
                            
                            VStack(spacing: 4) {
                                Text(userProfile?.displayName ?? "Date Enthusiast")
                                    .font(Font.bodySerif(20, weight: .regular))
                                    .foregroundColor(Color.textPrimary)
                                
                                if let email = userProfile?.email, !email.isEmpty {
                                    Text(memberLine(email: email))
                                        .font(Font.bodySans(12, weight: .regular))
                                        .foregroundColor(Color.luxuryMuted)
                                }
                            }
                        }
                        .padding(.top, 16)

                        if let partnerName = linkedPartnerName {
                            partnerStrip(name: partnerName)
                                .padding(.horizontal, 20)
                        }
                        
                        HStack(spacing: 10) {
                            ProfileStatBox(value: "\(coordinator.savedPlans.count)", label: "Saved")
                            ProfileStatBox(value: "\(coordinator.pastPlans.count)", label: "Completed")
                            ProfileStatBox(value: "\(memoryManager.totalMemoriesCount)", label: "Memories")
                        }
                        .padding(.horizontal, 20)
                        
                        if let prefs = userProfile?.preferences {
                            PreferencesSummaryCard(preferences: prefs, onEdit: {
                                coordinator.startEditPreferencesOnly()
                            })
                                .padding(.horizontal, 20)
                        }
                        
                        VStack(spacing: 0) {
                            LuxuryProfileMenuItem(icon: "bookmark.fill", title: "Saved Plans", isLocked: !access.canAccess(.datePlan)) {
                                access.require(.datePlan) {
                                    coordinator.activeSheet = .savedPlansList
                                }
                            }
                            Divider().background(Color.white.opacity(0.06))
                            LuxuryProfileMenuItem(icon: "clock.fill", title: "Date History", isLocked: !access.canAccess(.datePlan)) {
                                access.require(.datePlan) {
                                    coordinator.activeSheet = .pastMagic
                                }
                            }
                            Divider().background(Color.white.opacity(0.06))
                            LuxuryProfileMenuItem(icon: "gift.fill", title: "Gifts", isLocked: !access.canAccess(.gifting)) {
                                access.require(.gifting) {
                                    coordinator.activeSheet = .gifts
                                }
                            }
                            Divider().background(Color.white.opacity(0.06))
                            LuxuryProfileMenuItem(icon: "heart.fill", title: "Preferences") {
                                coordinator.startEditPreferencesOnly()
                            }
                            Divider().background(Color.white.opacity(0.06))
                            LuxuryProfileMenuItem(icon: "bell.fill", title: "Notifications") {
                                notificationManager.showNotificationsSheet = true
                            }
                            Divider().background(Color.white.opacity(0.06))
                            LuxuryProfileMenuItem(icon: "gearshape.fill", title: "Settings") {
                                coordinator.activeSheet = .settings
                            }
                            Divider().background(Color.white.opacity(0.06))
                            LuxuryProfileMenuItem(icon: "questionmark.circle.fill", title: "Help & Support") {
                                showHelpSupport = true
                            }
                        }
                        .background(Color.surfaceElevated)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.accentGold.opacity(0.15), lineWidth: 1)
                        )
                        .padding(.horizontal, 20)
                        
                        // Restore Purchases
                        Button {
                            Task {
                                do {
                                    try await PurchaseManager.shared.restorePurchases()
                                    restoreMessage = "Purchases restored successfully."
                                } catch {
                                    restoreMessage = "No purchases found to restore."
                                }
                                showRestoreAlert = true
                            }
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "arrow.clockwise.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(Color.luxuryGold)
                                    .frame(width: 24, height: 24)
                                Text("Restore Purchases")
                            }
                            .font(Font.bodySans(14, weight: .medium))
                            .foregroundColor(Color.accentGold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.clear)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
                            )
                        }
                        .padding(.horizontal, 20)

                        // Sign Out
                        Button {
                            showSignOutAlert = true
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "arrow.left.square.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(Color.luxuryError.opacity(0.85))
                                    .frame(width: 24, height: 24)

                                Text("Sign Out")
                            }
                            .font(Font.bodySans(14, weight: .medium))
                            .foregroundColor(Color.luxuryError.opacity(0.85))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.clear)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.luxuryError.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .padding(.horizontal, 20)

                        // Delete Account (required by App Store / GDPR)
                        Button {
                            showDeleteAccountAlert = true
                        } label: {
                            if isDeletingAccount {
                                ProgressView()
                                    .tint(Color.luxuryError.opacity(0.7))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                            } else {
                                Text("Delete Account")
                                    .font(Font.bodySans(13, weight: .medium))
                                    .foregroundColor(Color.luxuryError.opacity(0.7))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                            }
                        }
                        .disabled(isDeletingAccount)
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 120)
                }
                .scrollBounceBehavior(.basedOnSize)
            }
            .navigationTitle("You")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.backgroundPrimary, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .sheet(isPresented: $notificationManager.showNotificationsSheet) {
                NotificationsSheetView(notificationManager: notificationManager)
            }
            .sheet(isPresented: $showHelpSupport) {
                HelpSupportSheetView()
            }
            .alert("Sign Out", isPresented: $showSignOutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    coordinator.signOut()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .alert("Delete Account", isPresented: $showDeleteAccountAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    isDeletingAccount = true
                    Task {
                        do {
                            try await profileManager.deleteAccount(password: "")
                            await MainActor.run {
                                isDeletingAccount = false
                                coordinator.signOut()
                            }
                        } catch {
                            await MainActor.run {
                                isDeletingAccount = false
                            }
                        }
                    }
                }
            } message: {
                Text("This will permanently delete your account and all data. This action cannot be undone.")
            }
            .alert("Restore Purchases", isPresented: $showRestoreAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(restoreMessage ?? "")
            }
        }
    }
    
    private var userInitials: String {
        guard let profile = userProfile else { return "DG" }
        let first = profile.firstName.prefix(1).uppercased()
        let last = profile.lastName.prefix(1).uppercased()
        return first.isEmpty ? "DG" : "\(first)\(last)"
    }

    private var linkedPartnerName: String? {
        guard partnerManager.partnerState != .none else { return nil }
        let inviteName = partnerManager.inviteInfo?.partnerName
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !inviteName.isEmpty { return inviteName }
        let inviter = partnerManager.inviterName?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return inviter.isEmpty ? nil : inviter
    }

    private func memberLine(email: String) -> String {
        if let memberSince = userProfile?.memberSince, !memberSince.isEmpty {
            return "\(email) · member since \(memberSince)"
        }
        return email
    }

    private func partnerStrip(name: String) -> some View {
        Button {
            coordinator.showPartnerPlanning()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 13, weight: .semibold))
                Text("Planning with \(name)")
                    .font(Font.bodySans(11, weight: .semibold))
                    .tracking(0.4)
                    .textCase(.uppercase)
                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .opacity(0.6)
            }
            .foregroundColor(Color.textPrimary)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.surfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(alignment: .leading) {
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(Color.accentMaroon)
                    .frame(width: 3)
                    .padding(.vertical, 4)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.accentMaroon.opacity(0.45), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preferences Summary Card
struct PreferencesSummaryCard: View {
    let preferences: DatePreferences
    var onEdit: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                HStack(spacing: 6) {
                    Text("Your")
                        .font(Font.header(16, weight: .regular))
                        .foregroundColor(Color.luxuryCream)
                    Text("Preferences")
                        .font(Font.bodySerif(20, weight: .regular))
                        .foregroundColor(Color.accentGold)
                }
                
                Spacer()
                
                Button {
                    onEdit?()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "pencil")
                            .font(.system(size: 13))
                            .foregroundColor(Color.luxuryGold)
                        Text("Edit")
                    }
                    .font(Font.bodySans(13, weight: .medium))
                    .foregroundColor(Color.luxuryGold)
                }
            }
            
            VStack(alignment: .leading, spacing: 14) {
                // Starting point — used for routes, walk times, and nearby recommendations
                PreferenceStartingPointSection(
                    address: preferences.defaultStartingPoint,
                    onEdit: onEdit
                )

                // Your gender & partner's gender
                PreferenceChipsSection(
                    icon: "person.fill",
                    title: "Your gender",
                    chips: [(emoji: preferences.gender.emoji, label: preferences.gender.displayName)]
                )
                PreferenceChipsSection(
                    icon: "person.2.fill",
                    title: "Partner's gender",
                    chips: [(emoji: preferences.partnerGender.emoji, label: preferences.partnerGender.displayName)]
                )
                
                // Activities that interest me
                PreferenceChipsSection(
                    icon: "sparkles",
                    title: "Activities that interest me",
                    chips: preferences.favoriteActivities.compactMap { value in
                        QuestionnaireOptions.activities.first { $0.value == value }.map { (emoji: $0.emoji, label: $0.label) }
                    }
                )
                
                // Cuisines of interest
                PreferenceChipsSection(
                    icon: "fork.knife",
                    title: "Cuisines of interest",
                    chips: preferences.favoriteCuisines.compactMap { value in
                        QuestionnaireOptions.cuisines.first { $0.value == value }.map { (emoji: $0.emoji, label: $0.label) }
                    }
                )
                
                // Hard nos
                PreferenceChipsSection(
                    icon: "xmark.circle.fill",
                    title: "Hard nos",
                    chips: preferences.hardNos.compactMap { value in
                        QuestionnaireOptions.hardNos.first { $0.value == value }.map { (emoji: $0.emoji, label: $0.label) }
                    }
                )
                
                // Drink of choice
                PreferenceChipsSection(
                    icon: "wineglass.fill",
                    title: "Drink of choice",
                    chips: preferences.beveragePreferences.compactMap { value in
                        QuestionnaireOptions.drinkPreferences.first { $0.value == value }.map { (emoji: $0.emoji, label: $0.label) }
                    }
                )
                
                // Dietary restrictions
                PreferenceChipsSection(
                    icon: "leaf.fill",
                    title: "Dietary restrictions",
                    chips: preferences.dietaryRestrictions.compactMap { value in
                        QuestionnaireOptions.dietaryRestrictions.first { $0.value == value }.map { (emoji: $0.emoji, label: $0.label) }
                    }
                )
                
                // Love Languages
                PreferenceChipsSection(
                    icon: "heart.fill",
                    title: "Love Languages",
                    chips: preferences.loveLanguages.map { (emoji: $0.emoji, label: $0.displayName) }
                )
            }
        }
        .padding(18)
        .background(Color.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.accentGold.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Starting point (address) in preferences summary
private struct PreferenceStartingPointSection: View {
    let address: String
    var onEdit: (() -> Void)?

    private var trimmed: String {
        address.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                HStack(spacing: 8) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 14))
                        .foregroundColor(Color.luxuryGold.opacity(0.9))
                    Text("Starting point")
                        .font(Font.bodySans(13, weight: .semibold))
                        .foregroundColor(Color.luxuryCream)
                }
                Spacer()
                Button {
                    onEdit?()
                } label: {
                    Text("Change")
                        .font(Font.bodySans(12, weight: .semibold))
                        .foregroundColor(Color.luxuryGold)
                }
                .buttonStyle(.plain)
            }
            Text(trimmed.isEmpty ? "Not set — add an address for routes and nearby picks." : trimmed)
                .font(Font.bodySans(13, weight: .regular))
                .foregroundColor(trimmed.isEmpty ? Color.luxuryMuted : Color.luxuryCream)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Preference Chips Section (icon + title + emoji chips like Love Language)
struct PreferenceChipsSection: View {
    let icon: String
    let title: String
    let chips: [(emoji: String, label: String)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(Color.luxuryGold.opacity(0.9))
                Text(title)
                    .font(Font.bodySans(13, weight: .semibold))
                    .foregroundColor(Color.luxuryCream)
            }
            
            if chips.isEmpty {
                Text("None selected")
                    .font(Font.bodySans(12, weight: .regular))
                    .foregroundColor(Color.luxuryMuted)
            } else {
                FlowLayout(spacing: 8) {
                    ForEach(Array(chips.enumerated()), id: \.offset) { _, chip in
                        PreferenceChip(emoji: chip.emoji, label: chip.label)
                    }
                }
            }
        }
    }
}

// MARK: - Preference Chip (emoji + label pill, like Love Language card style)
struct PreferenceChip: View {
    let emoji: String
    let label: String
    
    var body: some View {
        HStack(spacing: 6) {
            Text(emoji)
                .font(.system(size: 16))
            Text(label)
                .font(Font.bodySans(12, weight: .medium))
                .foregroundColor(Color.luxuryCream)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.backgroundPrimary.opacity(0.5))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.accentGold.opacity(0.25), lineWidth: 1)
        )
    }
}

// MARK: - Profile stat box (cream card)
struct ProfileStatBox: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(Font.bodySerif(24, weight: .regular))
                .foregroundColor(Color.accentGold)
            Text(label.lowercased())
                .font(Font.bodySans(10, weight: .regular))
                .foregroundColor(Color.textMutedOnCard)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .padding(.horizontal, 8)
        .background(Color.creamCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.accentGold.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Preference Summary Row (legacy single-line row)
struct PreferenceSummaryRow: View {
    let icon: String
    let title: String
    let values: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(Color.luxuryGold.opacity(0.8))
                .frame(width: 20)
            
            Text(title)
                .font(Font.bodySans(13, weight: .medium))
                .foregroundColor(Color.luxuryCream)
            
            Spacer()
            
            Text(values)
                .font(Font.bodySans(12, weight: .regular))
                .foregroundColor(Color.luxuryMuted)
                .lineLimit(1)
        }
    }
}

// MARK: - Stat Item
struct LuxuryStatItem: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 6) {
            Text(value)
                .font(Font.header(26, weight: .bold))
                .foregroundColor(Color.luxuryGold)
            
            Text(label)
                .font(Font.bodySans(12, weight: .regular))
                .foregroundColor(Color.luxuryMuted)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Profile Menu Item
struct LuxuryProfileMenuItem: View {
    let icon: String
    let title: String
    var isLocked: Bool = false
    var action: (() -> Void)? = nil
    
    var body: some View {
        Button {
            action?()
        } label: {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(Color.accentGold)
                    .frame(width: 24, alignment: .center)
                
                Text(title)
                    .font(Font.bodySans(14, weight: .regular))
                    .foregroundColor(Color.textPrimary)
                
                Spacer()

                if isLocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color.luxuryGold.opacity(0.85))
                }
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(Color.luxuryMuted)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .opacity(isLocked ? 0.5 : 1)
        }
    }
}
