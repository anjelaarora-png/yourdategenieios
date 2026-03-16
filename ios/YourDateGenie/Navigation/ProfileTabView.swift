import SwiftUI

// MARK: - Luxury Profile Tab View
struct LuxuryProfileTabView: View {
    @EnvironmentObject var coordinator: NavigationCoordinator
    @ObservedObject private var profileManager = UserProfileManager.shared
    @StateObject private var notificationManager = NotificationManager.shared
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
                            
                            LuxuryStatItem(value: "0", label: "Completed")
                            
                            Rectangle()
                                .fill(Color.luxuryGold.opacity(0.3))
                                .frame(width: 1, height: 40)
                            
                            LuxuryStatItem(value: "0", label: "Memories")
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
                            LuxuryProfileMenuItem(icon: "bookmark.fill", title: "Saved Plans") {
                                coordinator.activeSheet = .savedPlansList
                            }
                            LuxuryProfileMenuItem(icon: "clock.fill", title: "Date History") {
                                coordinator.activeSheet = .pastMagic
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
                                AsyncImage(url: URL(string: "https://images.unsplash.com/photo-1516534775068-ba3e7458af70?w=40&h=40&fit=crop")) { phase in
                                    if let image = phase.image {
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    } else {
                                        Circle().fill(Color.luxuryError.opacity(0.3))
                                    }
                                }
                                .frame(width: 24, height: 24)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(Color.luxuryError.opacity(0.5), lineWidth: 1)
                                )
                                
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
                        AsyncImage(url: URL(string: "https://images.unsplash.com/photo-1455390582262-044cdead277a?w=40&h=40&fit=crop")) { phase in
                            if let image = phase.image {
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } else {
                                Circle().fill(Color.luxuryGold.opacity(0.3))
                            }
                        }
                        .frame(width: 20, height: 20)
                        .clipShape(Circle())
                        
                        Text("Edit")
                    }
                    .font(Font.bodySans(13, weight: .medium))
                    .foregroundColor(Color.luxuryGold)
                }
            }
            
            VStack(alignment: .leading, spacing: 14) {
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
    var action: (() -> Void)? = nil

    private var imageUrl: String {
        switch icon {
        case "bookmark.fill": return "https://images.unsplash.com/photo-1529333166437-7750a6dd5a70?w=80&h=80&fit=crop"
        case "clock.fill": return "https://images.unsplash.com/photo-1501139083538-0139583c060f?w=80&h=80&fit=crop"
        case "heart.fill": return "https://images.unsplash.com/photo-1518199266791-5375a83190b7?w=80&h=80&fit=crop"
        case "bell.fill": return "https://images.unsplash.com/photo-1577563908411-5077b6dc7624?w=80&h=80&fit=crop"
        case "gearshape.fill": return "https://images.unsplash.com/photo-1461749280684-dccba630e2f6?w=80&h=80&fit=crop"
        default: return "https://images.unsplash.com/photo-1529333166437-7750a6dd5a70?w=80&h=80&fit=crop"
        }
    }
    
    var body: some View {
        Button {
            action?()
        } label: {
            HStack(spacing: 16) {
                AsyncImage(url: URL(string: imageUrl)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .empty, .failure:
                        Image(systemName: icon)
                            .font(.system(size: 18))
                            .foregroundColor(Color.luxuryGold)
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(width: 32, height: 32)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.luxuryGold.opacity(0.3), lineWidth: 1)
                )
                
                Text(title)
                    .font(Font.bodySans(16, weight: .regular))
                    .foregroundColor(Color.luxuryCream)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(Color.luxuryMuted)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
        }
    }
}
