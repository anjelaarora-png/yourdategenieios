import SwiftUI

// MARK: - Luxury Profile Tab View
struct LuxuryProfileTabView: View {
    @EnvironmentObject var coordinator: NavigationCoordinator
    @EnvironmentObject private var access: AccessManager
    @ObservedObject private var profileManager = UserProfileManager.shared
    @StateObject private var notificationManager = NotificationManager.shared
    @StateObject private var memoryManager = MemoryManager.shared
    @State private var showSignOutAlert = false
    
    private var userProfile: UserProfile? {
        profileManager.currentUser
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.luxuryMaroon
                    .ignoresSafeArea()
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 24) {
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(LinearGradient.goldShimmer.opacity(0.2))
                                    .frame(width: 90, height: 90)
                                
                                Text(userInitials)
                                    .font(Font.header(32, weight: .bold))
                                    .foregroundColor(Color.luxuryGold)
                            }
                            
                            VStack(spacing: 4) {
                                Text(userProfile?.displayName ?? "Date Enthusiast")
                                    .font(Font.tangerine(40, weight: .bold))
                                    .italic()
                                    .foregroundColor(Color.luxuryGold)
                                
                                if let email = userProfile?.email, !email.isEmpty {
                                    Text(email)
                                        .font(Font.bodySans(13, weight: .regular))
                                        .foregroundColor(Color.luxuryMuted)
                                }
                                
                                Text("Member since \(userProfile?.memberSince ?? "2024")")
                                    .font(Font.bodySans(12, weight: .regular))
                                    .foregroundColor(Color.luxuryMuted.opacity(0.7))
                            }
                        }
                        .padding(.top, 16)
                        
                        HStack(spacing: 0) {
                            LuxuryStatItem(value: "\(coordinator.savedPlans.count)", label: "Saved")
                            
                            Rectangle()
                                .fill(Color.luxuryGold.opacity(0.3))
                                .frame(width: 1, height: 40)
                            
                            LuxuryStatItem(value: "\(coordinator.pastPlans.count)", label: "Completed")
                            
                            Rectangle()
                                .fill(Color.luxuryGold.opacity(0.3))
                                .frame(width: 1, height: 40)
                            
                            LuxuryStatItem(value: "\(memoryManager.totalMemoriesCount)", label: "Memories")
                        }
                        .padding(.vertical, 16)
                        .luxuryCard()
                        .padding(.horizontal, 20)
                        
                        if let prefs = userProfile?.preferences {
                            PreferencesSummaryCard(preferences: prefs, onEdit: {
                                coordinator.startEditPreferencesOnly()
                            })
                                .padding(.horizontal, 20)
                        }
                        
                        VStack(spacing: 2) {
                            LuxuryProfileMenuItem(icon: "bookmark.fill", title: "Saved Plans", isLocked: !access.canAccess(.datePlan)) {
                                access.require(.datePlan) {
                                    coordinator.activeSheet = .savedPlansList
                                }
                            }
                            LuxuryProfileMenuItem(icon: "clock.fill", title: "Date History", isLocked: !access.canAccess(.datePlan)) {
                                access.require(.datePlan) {
                                    coordinator.activeSheet = .pastMagic
                                }
                            }
                            LuxuryProfileMenuItem(icon: "heart.fill", title: "Preferences") {
                                coordinator.startEditPreferencesOnly()
                            }
                            LuxuryProfileMenuItem(icon: "bell.fill", title: "Notifications") {
                                notificationManager.showNotificationsSheet = true
                            }
                            LuxuryProfileMenuItem(icon: "gearshape.fill", title: "Settings") {
                                coordinator.activeSheet = .settings
                            }
                        }
                        .luxuryCard(hasBorder: false)
                        .padding(.horizontal, 20)
                        
                        Button {
                            showSignOutAlert = true
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "arrow.left.square.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(Color.luxuryError)
                                    .frame(width: 24, height: 24)

                                Text("Sign Out")
                            }
                            .font(Font.bodySans(14, weight: .medium))
                            .foregroundColor(Color.luxuryError)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.luxuryMaroonLight)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.luxuryError.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 120)
                }
                .scrollBounceBehavior(.basedOnSize)
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.luxuryMaroon, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .sheet(isPresented: $notificationManager.showNotificationsSheet) {
                NotificationsSheetView(notificationManager: notificationManager)
            }
            .alert("Sign Out", isPresented: $showSignOutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    coordinator.signOut()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
    }
    
    private var userInitials: String {
        guard let profile = userProfile else { return "DG" }
        let first = profile.firstName.prefix(1).uppercased()
        let last = profile.lastName.prefix(1).uppercased()
        return first.isEmpty ? "DG" : "\(first)\(last)"
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
                        .font(Font.tangerine(26, weight: .bold))
                        .italic()
                        .foregroundColor(Color.luxuryGold)
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
        .luxuryCard()
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
        .background(Color.luxuryMaroonLight)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.luxuryGold.opacity(0.35), lineWidth: 1)
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
                    .font(.system(size: 18))
                    .foregroundColor(Color.luxuryGold)
                    .frame(width: 32, height: 32)
                    .background(Color.luxuryGold.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.luxuryGold.opacity(0.3), lineWidth: 1)
                    )
                
                Text(title)
                    .font(Font.bodySans(16, weight: .regular))
                    .foregroundColor(Color.luxuryCream)
                
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
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .opacity(isLocked ? 0.5 : 1)
        }
    }
}
