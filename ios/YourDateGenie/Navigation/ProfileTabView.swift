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
                Color.ydgBase
                    .ignoresSafeArea()
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: YDGSpace.lg) {
                        YDGLargeTitle(title: "You")

                        profileRow
                            .padding(.horizontal, YDGSpace.margin)

                        if let partnerName = linkedPartnerName {
                            partnerStrip(name: partnerName)
                                .padding(.horizontal, YDGSpace.margin)
                        }
                        
                        HStack(spacing: 10) {
                            ProfileStatBox(value: "\(coordinator.savedPlans.count)", label: "Saved")
                            ProfileStatBox(value: "\(coordinator.pastPlans.count)", label: "Completed")
                            ProfileStatBox(value: "\(memoryManager.totalMemoriesCount)", label: "Memories")
                        }
                        .padding(.horizontal, YDGSpace.margin)
                        
                        if let prefs = userProfile?.preferences {
                            PreferencesSummaryCard(preferences: prefs, onEdit: {
                                coordinator.startEditPreferencesOnly()
                            })
                                .padding(.horizontal, YDGSpace.margin)
                        }
                        
                        VStack(spacing: 0) {
                            LuxuryProfileMenuItem(icon: "bookmark", title: "Saved plans", isLocked: !access.canAccess(.datePlan)) {
                                access.require(.datePlan) {
                                    coordinator.activeSheet = .savedPlansList
                                }
                            }
                            YDGListDivider()
                            LuxuryProfileMenuItem(icon: "clock", title: "Date history", isLocked: !access.canAccess(.datePlan)) {
                                access.require(.datePlan) {
                                    coordinator.activeSheet = .pastMagic
                                }
                            }
                            YDGListDivider()
                            LuxuryProfileMenuItem(icon: "gift", title: "Gift finder", isLocked: !access.canAccess(.gifting)) {
                                access.require(.gifting) {
                                    coordinator.activeSheet = .gifts
                                }
                            }
                            YDGListDivider()
                            LuxuryProfileMenuItem(icon: "camera.macro", title: "Your rose garden") {
                                coordinator.activeSheet = .roseRewards
                            }
                            YDGListDivider()
                            LuxuryProfileMenuItem(icon: "slider.horizontal.3", title: "Preferences") {
                                coordinator.startEditPreferencesOnly()
                            }
                            YDGListDivider()
                            LuxuryProfileMenuItem(icon: "bell", title: "Notifications") {
                                notificationManager.showNotificationsSheet = true
                            }
                            YDGListDivider()
                            LuxuryProfileMenuItem(icon: "gearshape", title: "Settings") {
                                coordinator.activeSheet = .settings
                            }
                            YDGListDivider()
                            LuxuryProfileMenuItem(icon: "questionmark.circle", title: "Help & support") {
                                showHelpSupport = true
                            }
                        }
                        .ydgGroupedList()
                        .padding(.horizontal, YDGSpace.margin)
                        
                        // Account actions: quiet text buttons, destructive ones last.
                        VStack(spacing: YDGSpace.xxs) {
                            Button("Restore purchases") {
                                Task {
                                    do {
                                        try await PurchaseManager.shared.restorePurchases()
                                        restoreMessage = "Purchases restored successfully."
                                    } catch {
                                        restoreMessage = "No purchases found to restore."
                                    }
                                    showRestoreAlert = true
                                }
                            }
                            .buttonStyle(.ydgTertiary)

                            if coordinator.isLoggedIn {
                                Button {
                                    showSignOutAlert = true
                                } label: {
                                    Text("Sign out")
                                        .ydgText(.callout, weight: .semibold, color: .ydgDanger)
                                        .frame(minHeight: 44)
                                }
                                .buttonStyle(.plain)

                                Button {
                                    showDeleteAccountAlert = true
                                } label: {
                                    if isDeletingAccount {
                                        ProgressView().tint(Color.ydgTextTertiary)
                                    } else {
                                        Text("Delete account")
                                            .ydgText(.footnote, color: .ydgTextTertiary)
                                    }
                                }
                                .buttonStyle(.plain)
                                .frame(minHeight: 44)
                                .disabled(isDeletingAccount)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, YDGSpace.md)
                    }
                }
                .mainTabBarScrollInset()
                .scrollBounceBehavior(.basedOnSize)
            }
            .toolbar(.hidden, for: .navigationBar)
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

    /// Avatar tile, name and email; a guest sees a sign-in prompt instead.
    private var profileRow: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(Color.ydgIconTile)
                if coordinator.isLoggedIn {
                    Text(userInitials)
                        .font(.ydgSans(18, weight: .semibold))
                        .foregroundColor(Color.ydgIconCream)
                } else {
                    Image(systemName: "person")
                        .font(.system(size: 20, weight: .regular))
                        .foregroundColor(Color.ydgIconCream)
                }
            }
            .frame(width: 52, height: 52)
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                if coordinator.isLoggedIn {
                    Text(userProfile?.displayName ?? "Your profile")
                        .ydgText(.headline)
                    if let email = userProfile?.email, !email.isEmpty {
                        Text(memberLine(email: email))
                            .ydgText(.footnote, color: .ydgTextSecondary)
                            .lineLimit(1)
                    }
                } else {
                    Text("Guest").ydgText(.headline)
                    Text("Sign in to keep plans and memories")
                        .ydgText(.footnote, color: .ydgTextSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if !coordinator.isLoggedIn {
                Button("Sign in") {
                    coordinator.activeSheet = .authRequired(.fresh)
                }
                .buttonStyle(.ydgTertiary)
            }
        }
    }

    private func partnerStrip(name: String) -> some View {
        Button {
            coordinator.showPartnerPlanning()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "person.2")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(Color.ydgHighlight)
                Text("Planning with \(name)")
                    .ydgText(.callout, weight: .medium)
                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color.ydgTextTertiary)
            }
            .padding(.horizontal, YDGSpace.md)
            .frame(minHeight: 52)
            .background(Color.ydgHighlightSubtle, in: RoundedRectangle(cornerRadius: YDGRadius.card, style: .continuous))
            .contentShape(Rectangle())
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
            HStack(alignment: .firstTextBaseline) {
                Text("Your preferences")
                    .ydgText(.title3)
                    .accessibilityAddTraits(.isHeader)
                
                Spacer()
                
                Button("Edit") {
                    onEdit?()
                }
                .buttonStyle(.ydgTertiary)
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
        .padding(YDGSpace.md)
        .goldHighlightMaroonAccent(cornerRadius: YDGRadius.card)
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
                        .foregroundColor(Color.ydgTextSecondary)
                    Text("Starting point")
                        .ydgText(.subhead, weight: .semibold)
                }
                Spacer()
                Button {
                    onEdit?()
                } label: {
                    Text("Change")
                        .font(.ydg(.subhead, weight: .semibold))
                        .foregroundColor(Color.ydgAccent)
                        .frame(minHeight: 44)
                }
                .buttonStyle(.plain)
            }
            Text(trimmed.isEmpty ? "Not set. Add an address for routes and nearby picks." : trimmed)
                .ydgText(.subhead, weight: .regular, color: trimmed.isEmpty ? .ydgTextTertiary : .ydgTextPrimary)
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
                    .foregroundColor(Color.ydgTextSecondary)
                Text(title)
                    .ydgText(.subhead, weight: .semibold)
            }
            
            if chips.isEmpty {
                Text("None selected")
                    .ydgText(.footnote, color: .ydgTextTertiary)
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
                .font(.ydg(.footnote, weight: .medium))
                .foregroundColor(Color.ydgTextPrimary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(Capsule().fill(Color.ydgOverlay))
    }
}

// MARK: - Profile stat box
struct ProfileStatBox: View {
    let value: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.ydgSans(24, weight: .semibold))
                .foregroundColor(Color.ydgTextPrimary)
                .monospacedDigit()
            Text(label)
                .ydgText(.footnote, color: .ydgTextSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 14)
        .padding(.horizontal, 14)
        .background(Color.ydgRaised, in: RoundedRectangle(cornerRadius: YDGRadius.card, style: .continuous))
        .accessibilityElement(children: .combine)
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
                .font(Font.bodySerif(26, weight: .bold))
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
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(Color.ydgTextSecondary)
                    .frame(width: 24, alignment: .center)
                
                Text(title)
                    .ydgText(.body)
                
                Spacer()

                if isLocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color.ydgTextTertiary)
                        .accessibilityLabel("Premium")
                }
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color.ydgTextTertiary)
            }
            .padding(.horizontal, YDGSpace.md)
            .frame(minHeight: 52)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
