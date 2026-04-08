import SwiftUI
import CoreLocation

private enum GiftFinderTab: String, CaseIterable {
    case find = "Find a Gift"
    case saved = "Saved"
    case bought = "Bought"
}

struct GiftFinderView: View {
    var datePlan: DatePlan?
    var dateLocation: String?
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab: GiftFinderTab = .find
    @State private var selectedBudget: String = ""
    @State private var selectedOccasion: String = ""
    @State private var interests: String = ""
    @State private var additionalNotes: String = ""
    @State private var selectedRecipient: String = "partner"
    @State private var selectedGiftStyles: Set<String> = []
    @State private var resultBudgetFilter: String = ""
    @State private var hasPrefilledOnce = false
    @State private var isLoading = false
    @State private var gifts: [GiftSuggestion] = []
    @State private var showResults = false
    @State private var nearbyStores: [NearbyStore] = []
    /// When true, show full-screen big gift unwrap animation; then reveal form.
    @State private var showUnwrapAnimation = true
    /// When true, show box-open celebration overlay (after save or bought).
    @State private var showBoxOpenCelebration = false
    @State private var celebrationMessage = "Gift saved!"
    /// When non-nil, the AI gift API failed; user sees message and can retry.
    @State private var giftLoadError: String?
    
    @ObservedObject private var giftStore = GiftStorageManager.shared
    
    private var effectiveLocation: String {
        if let location = dateLocation, !location.isEmpty {
            return location
        }
        if let firstStop = datePlan?.stops.first, let address = firstStop.address {
            return address
        }
        // Fallback to user's saved location so "find near me" always has a usable location
        let fromProfile = UserProfileManager.shared.currentUser?.preferences.defaultStartingPoint.trimmingCharacters(in: .whitespacesAndNewlines)
        if let loc = fromProfile, !loc.isEmpty { return loc }
        let fromUserLocation = UserProfileManager.shared.currentUser?.location.trimmingCharacters(in: .whitespacesAndNewlines)
        if let loc = fromUserLocation, !loc.isEmpty { return loc }
        return ""
    }

    /// Location for display only: no zip/postal code (any country). Uses "Near me" when no location so the nearby-stores option always shows.
    private var effectiveLocationDisplay: String {
        if effectiveLocation.isEmpty { return "Near me" }
        let parsed = MapURLHelper.cityStateOrRegionFromAddress(effectiveLocation)
        return parsed.isEmpty ? effectiveLocation : parsed
    }

    /// Location string for map search queries. Use "me" when no address so Maps does a "near me" search.
    private var mapSearchLocation: String {
        effectiveLocation.isEmpty ? "me" : effectiveLocationDisplay
    }
    
    private let occasionOptions = [
        ("anniversary", "Anniversary", "💕"),
        ("birthday", "Birthday", "🎂"),
        ("valentines", "Valentine's Day", "❤️"),
        ("just-because", "Just Because", "💝"),
        ("holiday", "Holiday", "🎄"),
        ("date-night", "Date Night", "🌙"),
    ]
    
    private let budgetOptions = [
        ("under-25", "Under $25"),
        ("25-50", "$25-50"),
        ("50-100", "$50-100"),
        ("100-200", "$100-200"),
        ("200-plus", "$200+"),
    ]
    
    private let recipientOptions = [
        ("partner", "Partner"),
        ("friend", "Friend"),
        ("family", "Family"),
        ("other", "Other"),
    ]
    
    private let styleOptions = [
        ("luxe", "Luxe"),
        ("casual", "Casual"),
        ("experiences", "Experiences"),
        ("understated", "Understated"),
    ]
    
    /// Gifts filtered by result budget filter (if set).
    private var filteredGifts: [GiftSuggestion] {
        guard !resultBudgetFilter.isEmpty else { return gifts }
        return gifts.filter { gift in
            let p = gift.priceRange.lowercased()
            switch resultBudgetFilter {
            case "under-25": return p.contains("under")
            case "25-50": return (p.contains("25") && p.contains("50")) || (p.contains("25") && p.contains("-"))
            case "50-100": return (p.contains("50") && p.contains("100")) || (p.contains("50") && p.contains("-"))
            case "100-200": return (p.contains("100") && p.contains("200")) || (p.contains("100") && p.contains("-"))
            case "200-plus": return p.contains("200") || p.contains("+") || p.contains("300") || p.contains("over") || p.contains("luxury")
            default: return true
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.luxuryMaroon
                    .ignoresSafeArea()
                
                if showUnwrapAnimation {
                    BigGiftUnwrapView {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            showUnwrapAnimation = false
                        }
                    }
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            headerSection
                                .padding(.bottom, 20)
                            
                            giftFinderTabBar
                                .padding(.bottom, 24)
                            
                            switch selectedTab {
                            case .find:
                                if !showResults {
                                    inputFormSection
                                } else {
                                    resultsSection
                                }
                            case .saved:
                                savedTabContent
                            case .bought:
                                boughtTabContent
                            }
                        }
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Gift Finder")
                        .font(Font.tangerine(24, weight: .bold))
                        .foregroundColor(Color.luxuryGold)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .font(Font.inter(16, weight: .medium))
                    .foregroundColor(Color.luxuryGold)
                }
            }
            .toolbarBackground(Color.luxuryMaroon, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .onAppear {
                prefillFromProfile()
            }
        }
    }
    
    // MARK: - Tab Bar
    private var giftFinderTabBar: some View {
        HStack(spacing: 0) {
            ForEach(GiftFinderTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 6) {
                        Text(tab.rawValue)
                            .font(Font.inter(14, weight: selectedTab == tab ? .semibold : .regular))
                            .foregroundColor(selectedTab == tab ? Color.luxuryGold : Color.luxuryCreamMuted)
                        
                        Rectangle()
                            .fill(selectedTab == tab ? Color.luxuryGold : Color.clear)
                            .frame(height: 2)
                    }
                }
                .frame(maxWidth: .infinity)
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
        .overlay(
            Rectangle()
                .fill(Color.luxuryGold.opacity(0.15))
                .frame(height: 1),
            alignment: .bottom
        )
    }
    
    /// Pre-fill budget and interests from UserProfileManager when opening finder (only once, when form is empty).
    private func prefillFromProfile() {
        guard !hasPrefilledOnce else { return }
        let prefs = UserProfileManager.shared.currentUser?.preferences
        guard let prefs = prefs else { return }
        if selectedBudget.isEmpty, !prefs.defaultBudget.isEmpty {
            switch prefs.defaultBudget {
            case "budget": selectedBudget = "25-50"
            case "moderate": selectedBudget = "50-100"
            case "upscale": selectedBudget = "100-200"
            case "luxury": selectedBudget = "200-plus"
            default: break
            }
        }
        if interests.isEmpty, !prefs.favoriteActivities.isEmpty {
            let labels = prefs.favoriteActivities.compactMap { value in
                QuestionnaireOptions.activities.first(where: { $0.value == value })?.label
            }
            if !labels.isEmpty {
                interests = labels.joined(separator: ", ")
            }
        }
        if selectedOccasion.isEmpty, let title = datePlan?.title, title.lowercased().contains("date night") {
            selectedOccasion = "date-night"
        }
        hasPrefilledOnce = true
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.luxuryGold.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "gift.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(LinearGradient.goldShimmer)
            }
            
            Text("Find the Perfect Gift")
                .font(Font.tangerine(42, weight: .bold))
                .foregroundColor(Color.luxuryGold)
            
            Text("Discover gifts from stores near your date")
                .font(Font.bodySans(15, weight: .regular))
                .foregroundColor(Color.luxuryCreamMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            
            if !showResults {
                Text("Personalized to your person and occasion")
                    .font(Font.bodySans(15, weight: .regular))
                    .foregroundColor(Color.luxuryCreamMuted)
            }
            
            if let plan = datePlan {
                dateContextBadge(plan: plan)
            }
        }
        .padding(.top, 20)
    }
    
    // MARK: - Saved Tab Content
    private var savedTabContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            if giftStore.savedOnly.isEmpty {
                GiftListEmptyState(
                    icon: "heart.circle.fill",
                    title: "No saved gifts yet",
                    subtitle: "Save ideas from your search results to keep them here"
                )
                .padding(.top, 40)
            } else {
                VStack(spacing: 10) {
                    ForEach(giftStore.savedOnly) { stored in
                        StoredGiftRowView(
                            stored: stored,
                            onShop: { openStoredShop(stored: stored) },
                            onNewLink: { openStoredSearch(name: stored.name) },
                            onMarkBought: { giftStore.markAsBought(storedToGiftSuggestion(stored)) }
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    // MARK: - Bought Tab Content
    private var boughtTabContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            if giftStore.boughtOnly.isEmpty {
                GiftListEmptyState(
                    icon: "checkmark.circle.fill",
                    title: "No bought gifts yet",
                    subtitle: "Mark an idea as bought so we won't suggest it again"
                )
                .padding(.top, 40)
            } else {
                VStack(spacing: 10) {
                    ForEach(giftStore.boughtOnly) { stored in
                        StoredGiftRowView(
                            stored: stored,
                            onShop: { openStoredShop(stored: stored) },
                            onNewLink: { openStoredSearch(name: stored.name) },
                            onMarkBought: nil
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    private func openStoredShop(stored: StoredGift) {
        if let s = stored.purchaseUrl, !s.isEmpty,
           let url = URL(string: s),
           url.scheme == "http" || url.scheme == "https" {
            UIApplication.shared.open(url)
        } else {
            openStoredSearch(name: stored.name)
        }
    }
    
    private func openStoredSearch(name: String) {
        let query = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? name
        if let url = URL(string: "https://www.google.com/search?tbm=shop&q=\(query)") {
            UIApplication.shared.open(url)
        }
    }
    
    private func storedToGiftSuggestion(_ stored: StoredGift) -> GiftSuggestion {
        GiftSuggestion(
            name: stored.name,
            description: stored.description,
            priceRange: stored.priceRange,
            whereToBuy: stored.whereToBuy,
            purchaseUrl: stored.purchaseUrl,
            whyItFits: stored.whyItFits,
            emoji: stored.emoji,
            storeSearchQuery: stored.storeSearchQuery,
            imageUrl: stored.imageUrl
        )
    }
    
    private func dateContextBadge(plan: DatePlan) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 12))
                    .foregroundColor(Color.luxuryGold)
                Text("Your date: \(plan.title)")
                    .font(Font.tangerine(18, weight: .bold))
                    .foregroundColor(Color.luxuryGold)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.luxuryGold.opacity(0.15))
            .cornerRadius(20)
            
            Button {
                openInAppleMaps(query: "gift shop", near: mapSearchLocation)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 11))
                        .foregroundColor(Color.luxuryGold)
                    Text(effectiveLocationDisplay)
                        .font(Font.inter(11, weight: .regular))
                        .foregroundColor(Color.luxuryGold)
                        .lineLimit(1)
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 9))
                        .foregroundColor(Color.luxuryGold)
                }
            }
        }
    }
    
    // MARK: - Input Form Section
    private var inputFormSection: some View {
        VStack(spacing: 24) {
            // Who is this for?
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 6) {
                    Image(systemName: "person.fill")
                        .foregroundColor(Color.luxuryGold)
                    Text("Who is this for?")
                        .font(Font.tangerine(28, weight: .bold))
                        .italic()
                        .foregroundColor(Color.luxuryGold)
                }
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(recipientOptions, id: \.0) { option in
                            GiftBudgetChip(
                                text: option.1,
                                isSelected: selectedRecipient == option.0,
                                action: { selectedRecipient = option.0 }
                            )
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            
            // Occasion Selection
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 6) {
                    Image(systemName: "heart.fill")
                        .foregroundColor(Color.luxuryGold)
                    Text("What's the occasion? *")
                        .font(Font.tangerine(28, weight: .bold))
                        .italic()
                        .foregroundColor(Color.luxuryGold)
                }
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(occasionOptions, id: \.0) { occasion in
                        GiftOccasionCard(
                            emoji: occasion.2,
                            title: occasion.1,
                            isSelected: selectedOccasion == occasion.0,
                            action: { selectedOccasion = occasion.0 }
                        )
                    }
                }
            }
            .padding(.horizontal, 20)
            
            // Budget Selection
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 6) {
                    Image(systemName: "dollarsign.circle")
                        .foregroundColor(Color.luxuryGold)
                    Text("Your budget")
                        .font(Font.tangerine(28, weight: .bold))
                        .italic()
                        .foregroundColor(Color.luxuryGold)
                }
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(budgetOptions, id: \.0) { budget in
                            GiftBudgetChip(
                                text: budget.1,
                                isSelected: selectedBudget == budget.0,
                                action: { selectedBudget = budget.0 }
                            )
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            
            // Style or vibe (optional)
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 6) {
                    Image(systemName: "sparkle")
                        .foregroundColor(Color.luxuryGold)
                    Text("Style or vibe (optional)")
                        .font(Font.tangerine(28, weight: .bold))
                        .italic()
                        .foregroundColor(Color.luxuryGold)
                }
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(styleOptions, id: \.0) { option in
                            Button {
                                if selectedGiftStyles.contains(option.0) {
                                    selectedGiftStyles.remove(option.0)
                                } else {
                                    selectedGiftStyles.insert(option.0)
                                }
                            } label: {
                                Text(option.1)
                                    .font(Font.inter(14, weight: .medium))
                                    .foregroundColor(selectedGiftStyles.contains(option.0) ? Color.luxuryMaroon : Color.luxuryCream)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(selectedGiftStyles.contains(option.0) ? Color.luxuryGold : Color.luxuryMaroonLight)
                                    .cornerRadius(20)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(Color.luxuryGold.opacity(0.5), lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            
            // Interests
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .foregroundColor(Color.luxuryGold)
                    Text("Their interests (optional)")
                        .font(Font.tangerine(28, weight: .bold))
                        .italic()
                        .foregroundColor(Color.luxuryGold)
                }
                
                TextField("e.g., cooking, travel, photography, books...", text: $interests)
                    .font(Font.inter(15, weight: .regular))
                    .foregroundColor(Color.luxuryCream)
                    .padding(16)
                    .background(Color.luxuryMaroonLight)
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.luxuryGold.opacity(0.3), lineWidth: 1)
                    )
            }
            .padding(.horizontal, 20)
            
            // Additional Notes
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    Image(systemName: "text.bubble")
                        .foregroundColor(Color.luxuryGold)
                    Text("Anything else we should know?")
                        .font(Font.tangerine(28, weight: .bold))
                        .italic()
                        .foregroundColor(Color.luxuryGold)
                }
                
                TextEditor(text: $additionalNotes)
                    .font(Font.inter(15, weight: .regular))
                    .foregroundColor(Color.luxuryCream)
                    .scrollContentBackground(.hidden)
                    .frame(height: 80)
                    .padding(14)
                    .background(Color.luxuryMaroonLight)
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.luxuryGold.opacity(0.3), lineWidth: 1)
                    )
                    .overlay(
                        Group {
                            if additionalNotes.isEmpty {
                                Text("e.g., allergies, dislikes, preferred brands, sizes...")
                                    .font(Font.inter(15, weight: .regular))
                                    .foregroundColor(Color.luxuryMuted.opacity(0.5))
                                    .padding(.horizontal, 18)
                                    .padding(.vertical, 22)
                                    .allowsHitTesting(false)
                            }
                        },
                        alignment: .topLeading
                    )
            }
            .padding(.horizontal, 20)
            
            // Generate button
            Button {
                generateGifts()
            } label: {
                HStack(spacing: 10) {
                    if isLoading {
                        ProgressView()
                            .tint(Color.luxuryMaroon)
                    } else {
                        Image(systemName: "sparkles")
                            .foregroundColor(Color.luxuryGold)
                        Text("Find Gift Ideas")
                            .font(Font.tangerine(28, weight: .bold))
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(LuxuryGoldButtonStyle())
            .disabled(isLoading || selectedOccasion.isEmpty)
            .opacity(selectedOccasion.isEmpty ? 0.6 : 1)
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Results Section
    private var resultsSection: some View {
        VStack(spacing: 20) {
            // API error — couldn't reach AI gift service; show message and retry
            if let error = giftLoadError {
                VStack(spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "wifi.exclamationmark")
                            .font(.system(size: 18))
                            .foregroundColor(Color.luxuryGold)
                        Text("Couldn't load gift ideas from the server")
                            .font(Font.tangerine(20, weight: .bold))
                            .foregroundColor(Color.luxuryGold)
                    }
                    Text("Check your connection and tap Try again to get AI-powered suggestions.")
                        .font(Font.inter(12, weight: .regular))
                        .foregroundColor(Color.luxuryCreamMuted)
                        .multilineTextAlignment(.center)
                    Button {
                        generateGifts()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.clockwise")
                            Text("Try again")
                                .font(Font.inter(14, weight: .semibold))
                        }
                        .foregroundColor(Color.luxuryMaroon)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.luxuryGold)
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }
                .padding(20)
                .frame(maxWidth: .infinity)
                .background(Color.luxuryMaroonLight)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.luxuryGold.opacity(0.4), lineWidth: 1)
                )
                .padding(.horizontal, 20)
            }
            
            // Results header with Refine + New Search
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(filteredGifts.isEmpty && giftLoadError != nil ? "Gift ideas" : "\(filteredGifts.count) gift ideas")
                        .font(Font.tangerine(28, weight: .bold))
                        .italic()
                        .foregroundColor(Color.luxuryGold)
                    
                    Text(effectiveLocation.isEmpty ? "With stores near you" : "With stores near \(effectiveLocationDisplay)")
                        .font(Font.inter(12, weight: .regular))
                        .foregroundColor(Color.luxuryMuted)
                        .lineLimit(1)
                }
                
                Spacer()
                
                HStack(spacing: 10) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showResults = false
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 12))
                                .foregroundColor(Color.luxuryGold)
                            Text("Refine")
                                .font(Font.inter(13, weight: .medium))
                        }
                        .foregroundColor(Color.luxuryGold)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.luxuryMaroonLight)
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.luxuryGold.opacity(0.3), lineWidth: 1)
                        )
                    }
                    
                    Button {
                        resetSearch()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 12))
                                .foregroundColor(Color.luxuryGold)
                            Text("New Search")
                                .font(Font.inter(13, weight: .medium))
                        }
                        .foregroundColor(Color.luxuryGold)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.luxuryMaroonLight)
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.luxuryGold.opacity(0.3), lineWidth: 1)
                        )
                    }
                }
            }
            .padding(.horizontal, 20)
            
            // Result filters (budget)
            VStack(alignment: .leading, spacing: 10) {
                Text("Filter by budget")
                    .font(Font.tangerine(28, weight: .bold))
                    .italic()
                    .foregroundColor(Color.luxuryGold)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(title: "All", isSelected: resultBudgetFilter.isEmpty) {
                            resultBudgetFilter = ""
                        }
                        ForEach(budgetOptions, id: \.0) { option in
                            FilterChip(title: option.1, isSelected: resultBudgetFilter == option.0) {
                                resultBudgetFilter = resultBudgetFilter == option.0 ? "" : option.0
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            
            // Nearby Stores Section - always show when we have results so users can find gifts near them
            if !nearbyStores.isEmpty {
                nearbyStoresSection
            }
            
            // Gift cards with shop nearby buttons
            VStack(spacing: 14) {
                ForEach(filteredGifts) { gift in
                    GiftResultCardWithMap(
                        gift: gift,
                        location: mapSearchLocation,
                        isSaved: giftStore.isSaved(gift),
                        isBought: giftStore.isBought(gift),
                        onSave: {
                            giftStore.addSaved(gift)
                            celebrationMessage = "Gift saved!"
                            showBoxOpenCelebration = true
                        },
                        onBought: {
                            giftStore.markAsBought(gift)
                            celebrationMessage = "Marked as bought!"
                            showBoxOpenCelebration = true
                        }
                    )
                }
            }
            .padding(.horizontal, 20)
            
            // Get more ideas button
            Button {
                generateGifts()
            } label: {
                HStack(spacing: 8) {
                    if isLoading {
                        ProgressView()
                            .tint(Color.luxuryGold)
                    } else {
                        Image(systemName: "sparkles")
                            .foregroundColor(Color.luxuryGold)
                        Text("Get More Ideas")
                            .font(Font.tangerine(20, weight: .bold))
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(LuxuryOutlineButtonStyle())
            .disabled(isLoading)
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Nearby Stores Section
    private var nearbyStoresSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.system(size: 14))
                    .foregroundColor(Color.luxuryGold)
                Text(effectiveLocation.isEmpty ? "Find Stores Near You" : "Find Stores Near Your Date")
                    .font(Font.tangerine(28, weight: .bold))
                    .italic()
                    .foregroundColor(Color.luxuryGold)
            }
            .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(nearbyStores) { store in
                        NearbyStoreCard(store: store, location: mapSearchLocation)
                    }
                }
                .padding(.horizontal, 20)
            }
            
            // View all on map button
            Button {
                openInAppleMaps(query: "gift shop", near: mapSearchLocation)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "map.fill")
                        .font(.system(size: 14))
                        .foregroundColor(Color.luxuryGold)
                    Text("View All Gift Shops on Map")
                        .font(Font.tangerine(22, weight: .bold))
                        .foregroundColor(Color.luxuryGold)
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 12))
                        .foregroundColor(Color.luxuryGold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.luxuryMaroonLight)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.luxuryGold.opacity(0.4), lineWidth: 1)
                )
            }
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Functions
    private func generateGifts() {
        giftLoadError = nil
        isLoading = true
        let occasion = selectedOccasion
        let budget = selectedBudget
        let interestsText = interests
        let notesText = additionalNotes
        let loc = effectiveLocation
        let planTitle: String? = {
            if let title = datePlan?.title, !title.isEmpty { return title }
            if occasion.isEmpty { return nil }
            let label = occasionOptions.first(where: { $0.0 == occasion })?.1 ?? occasion
            return "Gift Ideas for \(label)"
        }()
        let recipient = selectedRecipient
        let style = selectedGiftStyles.isEmpty ? nil : Array(selectedGiftStyles)
        
        var existingNames = gifts.map(\.name)
        let boughtNames = giftStore.purchasedGiftNames
        existingNames = Array(Set(existingNames + boughtNames))
        let planForFallback = datePlan
        Task {
            do {
                let result: [GiftSuggestion]
                if Config.isOpenAIConfigured {
                    result = try await GiftAIService.generateGifts(
                        occasion: occasion.isEmpty ? "just because" : occasion,
                        budget: budget.isEmpty ? "any" : budget,
                        interests: interestsText,
                        notes: notesText,
                        location: loc,
                        planTitle: planTitle,
                        existingGiftNames: existingNames,
                        recipient: recipient.isEmpty ? nil : recipient,
                        giftStyle: style,
                        count: 6
                    )
                } else {
                    let fallback: [GiftSuggestion] = planForFallback.map { generateContextualGifts(for: $0) } ?? generateSampleGifts()
                    await MainActor.run {
                        self.gifts = fallback.shuffled()
                        self.nearbyStores = self.generateNearbyStores()
                        self.giftLoadError = "Add OPENAI_API_KEY in Secrets for AI-powered gift ideas."
                        self.isLoading = false
                        withAnimation(.spring(response: 0.5)) { self.showResults = true }
                    }
                    return
                }
                await MainActor.run {
                    self.gifts = result
                    self.nearbyStores = self.generateNearbyStores()
                    self.giftLoadError = nil
                    self.isLoading = false
                    withAnimation(.spring(response: 0.5)) { self.showResults = true }
                }
            } catch {
                await MainActor.run {
                    self.giftLoadError = error.localizedDescription
                    self.isLoading = false
                    withAnimation(.spring(response: 0.5)) { self.showResults = true }
                }
            }
        }
    }
    
    private func resetSearch() {
        withAnimation {
            showResults = false
            gifts = []
            nearbyStores = []
            giftLoadError = nil
        }
    }
    
    private func openInAppleMaps(query: String, near location: String) {
        let searchQuery = "\(query) near \(location)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        if let url = URL(string: "maps://?q=\(searchQuery)") {
            UIApplication.shared.open(url)
        }
    }
    
    // MARK: - Generate Nearby Stores
    private func generateNearbyStores() -> [NearbyStore] {
        var stores: [NearbyStore] = []
        
        // Core store types for gifts
        stores.append(NearbyStore(
            name: "Jewelry Stores",
            category: "Fine Jewelry & Watches",
            searchQuery: "jewelry store",
            emoji: "💎",
            giftIdeas: ["Necklaces", "Bracelets", "Rings", "Watches"]
        ))
        
        stores.append(NearbyStore(
            name: "Florists",
            category: "Fresh Flowers & Arrangements",
            searchQuery: "florist flower shop",
            emoji: "💐",
            giftIdeas: ["Bouquets", "Roses", "Arrangements"]
        ))
        
        stores.append(NearbyStore(
            name: "Gift Shops",
            category: "Unique & Curated Gifts",
            searchQuery: "gift shop boutique",
            emoji: "🎁",
            giftIdeas: ["Candles", "Home Decor", "Personalized Items"]
        ))
        
        stores.append(NearbyStore(
            name: "Wine & Spirits",
            category: "Fine Wine & Champagne",
            searchQuery: "wine shop liquor store",
            emoji: "🍾",
            giftIdeas: ["Wine", "Champagne", "Gift Sets"]
        ))
        
        stores.append(NearbyStore(
            name: "Chocolatiers",
            category: "Artisan Chocolates & Sweets",
            searchQuery: "chocolate shop chocolatier",
            emoji: "🍫",
            giftIdeas: ["Truffles", "Gift Boxes", "Artisan Bars"]
        ))
        
        stores.append(NearbyStore(
            name: "Bookstores",
            category: "Books & Journals",
            searchQuery: "bookstore",
            emoji: "📚",
            giftIdeas: ["Books", "Journals", "Book Accessories"]
        ))
        
        // Add date-specific stores based on venue types
        if let plan = datePlan {
            for stop in plan.stops {
                let venueType = stop.venueType.lowercased()
                
                if venueType.contains("spa") || venueType.contains("wellness") {
                    if !stores.contains(where: { $0.searchQuery.contains("spa") }) {
                        stores.append(NearbyStore(
                            name: "Spa & Beauty",
                            category: "Wellness & Self-Care",
                            searchQuery: "spa beauty supply skincare",
                            emoji: "🧴",
                            giftIdeas: ["Bath Products", "Skincare", "Aromatherapy"]
                        ))
                    }
                }
                
                if venueType.contains("art") || venueType.contains("gallery") || venueType.contains("museum") {
                    if !stores.contains(where: { $0.searchQuery.contains("art") }) {
                        stores.append(NearbyStore(
                            name: "Art & Craft Stores",
                            category: "Art Supplies & Prints",
                            searchQuery: "art supply store gallery",
                            emoji: "🎨",
                            giftIdeas: ["Art Prints", "Supplies", "Frames"]
                        ))
                    }
                }
            }
        }
        
        return stores
    }
    
    // MARK: - Contextual Gift Generation
    private func generateContextualGifts(for plan: DatePlan) -> [GiftSuggestion] {
        var contextualGifts: [GiftSuggestion] = []
        
        for stop in plan.stops {
            let venueType = stop.venueType.lowercased()
            
            if venueType.contains("wine") || venueType.contains("bar") {
                contextualGifts.append(GiftSuggestion(
                    name: "Premium Wine & Glasses Set",
                    description: "Fine wine with crystal glasses for romantic evenings at home",
                    priceRange: "$65-120",
                    whereToBuy: "Wine Shop",
                    purchaseUrl: nil,
                    whyItFits: "Continue the wine experience from \(stop.name)",
                    emoji: "🍷",
                    storeSearchQuery: "wine shop liquor store"
                ))
            }
            
            if venueType.contains("restaurant") || venueType.contains("italian") || venueType.contains("dining") {
                contextualGifts.append(GiftSuggestion(
                    name: "Gourmet Food Basket",
                    description: "Curated selection of artisan cheeses, crackers, and specialties",
                    priceRange: "$50-100",
                    whereToBuy: "Gourmet Food Store",
                    purchaseUrl: nil,
                    whyItFits: "Recreate the flavors of \(stop.name) at home",
                    emoji: "🧀",
                    storeSearchQuery: "gourmet food store specialty foods"
                ))
            }
            
            if venueType.contains("rooftop") || venueType.contains("view") || venueType.contains("scenic") {
                contextualGifts.append(GiftSuggestion(
                    name: "Instant Camera",
                    description: "Capture moments instantly with vintage-style photos",
                    priceRange: "$70-130",
                    whereToBuy: "Electronics Store",
                    purchaseUrl: "https://www.amazon.com/s?k=polaroid+instant+camera",
                    whyItFits: "Capture views like the ones at \(stop.name)",
                    emoji: "📸",
                    storeSearchQuery: "camera store electronics"
                ))
            }
            
            if venueType.contains("spa") || venueType.contains("wellness") {
                contextualGifts.append(GiftSuggestion(
                    name: "Luxury Spa Gift Set",
                    description: "Bath bombs, oils, and candles for relaxation",
                    priceRange: "$55-90",
                    whereToBuy: "Spa & Beauty Store",
                    purchaseUrl: nil,
                    whyItFits: "Bring the \(stop.name) experience home",
                    emoji: "🛁",
                    storeSearchQuery: "spa beauty bath body works"
                ))
            }
        }
        
        // Always add these romantic essentials
        contextualGifts.append(contentsOf: [
            GiftSuggestion(
                name: "Fresh Flower Bouquet",
                description: "Beautiful arrangement of roses or seasonal flowers",
                priceRange: "$40-80",
                whereToBuy: "Local Florist",
                purchaseUrl: nil,
                whyItFits: "Classic romantic gesture for any occasion",
                emoji: "🌹",
                storeSearchQuery: "florist flower shop"
            ),
            GiftSuggestion(
                name: "Artisan Chocolates",
                description: "Handcrafted truffles and chocolate assortment",
                priceRange: "$30-60",
                whereToBuy: "Chocolate Shop",
                purchaseUrl: nil,
                whyItFits: "Sweet ending to your special date",
                emoji: "🍫",
                storeSearchQuery: "chocolate shop chocolatier"
            ),
            GiftSuggestion(
                name: "Jewelry Piece",
                description: "Elegant necklace, bracelet, or earrings",
                priceRange: "$75-200",
                whereToBuy: "Jewelry Store",
                purchaseUrl: nil,
                whyItFits: "Timeless gift to commemorate your date",
                emoji: "💎",
                storeSearchQuery: "jewelry store"
            ),
            GiftSuggestion(
                name: "Personalized Photo Gift",
                description: "Custom photo book or framed print of your memories",
                priceRange: "$35-70",
                whereToBuy: "Photo Print Shop",
                purchaseUrl: "https://www.shutterfly.com",
                whyItFits: "Capture and display your favorite moments",
                emoji: "📷",
                storeSearchQuery: "photo printing shop"
            ),
            GiftSuggestion(
                name: "Luxury Candle",
                description: "Hand-poured candle with romantic scents",
                priceRange: "$35-65",
                whereToBuy: "Home & Gift Store",
                purchaseUrl: nil,
                whyItFits: "Set the mood for cozy nights in",
                emoji: "🕯️",
                storeSearchQuery: "home decor candle shop"
            ),
        ])
        
        return contextualGifts
    }
    
    private func generateSampleGifts() -> [GiftSuggestion] {
        return [
            GiftSuggestion(
                name: "Fresh Flower Bouquet",
                description: "Beautiful arrangement of roses or seasonal flowers",
                priceRange: "$40-80",
                whereToBuy: "Local Florist",
                purchaseUrl: nil,
                whyItFits: "Classic romantic gesture for any occasion",
                emoji: "🌹",
                storeSearchQuery: "florist flower shop"
            ),
            GiftSuggestion(
                name: "Artisan Chocolates",
                description: "Handcrafted truffles and chocolate assortment",
                priceRange: "$30-60",
                whereToBuy: "Chocolate Shop",
                purchaseUrl: nil,
                whyItFits: "Sweet indulgence to enjoy together",
                emoji: "🍫",
                storeSearchQuery: "chocolate shop chocolatier"
            ),
            GiftSuggestion(
                name: "Fine Jewelry",
                description: "Elegant necklace, bracelet, or earrings",
                priceRange: "$75-250",
                whereToBuy: "Jewelry Store",
                purchaseUrl: nil,
                whyItFits: "Timeless gift that lasts forever",
                emoji: "💎",
                storeSearchQuery: "jewelry store"
            ),
            GiftSuggestion(
                name: "Premium Wine Selection",
                description: "Fine wine or champagne for celebrating",
                priceRange: "$40-100",
                whereToBuy: "Wine Shop",
                purchaseUrl: nil,
                whyItFits: "Perfect for romantic evenings together",
                emoji: "🍾",
                storeSearchQuery: "wine shop liquor store"
            ),
            GiftSuggestion(
                name: "Luxury Candle Set",
                description: "Hand-poured candles with romantic scents",
                priceRange: "$45-75",
                whereToBuy: "Home & Gift Store",
                purchaseUrl: nil,
                whyItFits: "Sets the mood for intimate moments",
                emoji: "🕯️",
                storeSearchQuery: "home decor candle shop"
            ),
            GiftSuggestion(
                name: "Spa & Relaxation Kit",
                description: "Bath products, oils, and self-care essentials",
                priceRange: "$50-90",
                whereToBuy: "Spa & Beauty Store",
                purchaseUrl: nil,
                whyItFits: "Relaxation gift to enjoy together",
                emoji: "🧴",
                storeSearchQuery: "spa beauty bath body"
            ),
        ]
    }
}

// MARK: - Models
struct NearbyStore: Identifiable {
    let id = UUID()
    let name: String
    let category: String
    let searchQuery: String
    let emoji: String
    let giftIdeas: [String]
}

// MARK: - Gift Occasion Card
struct GiftOccasionCard: View {
    let emoji: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(emoji)
                    .font(.system(size: 28))
                
                Text(title)
                    .font(Font.inter(12, weight: .medium))
                    .foregroundColor(isSelected ? Color.luxuryMaroon : Color.luxuryCream)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                isSelected ? LinearGradient.goldShimmer : LinearGradient(colors: [Color.luxuryMaroonLight], startPoint: .top, endPoint: .bottom)
            )
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color.clear : Color.luxuryGold.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Gift Budget Chip
struct GiftBudgetChip: View {
    let text: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(Font.inter(13, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? Color.luxuryMaroon : Color.luxuryCream)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(
                    isSelected ? LinearGradient.goldShimmer : LinearGradient(colors: [Color.clear], startPoint: .top, endPoint: .bottom)
                )
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isSelected ? Color.clear : Color.luxuryGold.opacity(0.4), lineWidth: 1)
                )
        }
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Filter Chip (results budget filter)
private struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Font.inter(12, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? Color.luxuryMaroon : Color.luxuryCreamMuted)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? Color.luxuryGold : Color.luxuryMaroonLight)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.luxuryGold.opacity(isSelected ? 0 : 0.4), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Nearby Store Card
struct NearbyStoreCard: View {
    let store: NearbyStore
    let location: String
    
    var body: some View {
        Button {
            openInAppleMaps(query: store.searchQuery, near: location)
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    Text(store.emoji)
                        .font(.system(size: 28))
                        .frame(width: 44, height: 44)
                        .background(Color.luxuryMaroon)
                        .cornerRadius(10)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(store.name)
                            .font(Font.playfair(14, weight: .semibold))
                            .foregroundColor(Color.luxuryCream)
                        
                        Text(store.category)
                            .font(Font.inter(10, weight: .regular))
                            .foregroundColor(Color.luxuryMuted)
                            .lineLimit(1)
                    }
                }
                
                // Gift ideas tags
                HStack(spacing: 4) {
                    ForEach(store.giftIdeas.prefix(3), id: \.self) { idea in
                        Text(idea)
                            .font(Font.inter(9, weight: .medium))
                            .foregroundColor(Color.luxuryGoldLight)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.luxuryGold.opacity(0.15))
                            .cornerRadius(4)
                    }
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "map.fill")
                        .font(.system(size: 10))
                        .foregroundColor(Color.luxuryGold)
                    Text("Find on Google Maps")
                        .font(Font.inter(11, weight: .semibold))
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 9))
                        .foregroundColor(Color.luxuryGold)
                }
                .foregroundColor(Color.luxuryGold)
            }
            .padding(14)
            .frame(width: 180)
            .background(Color.luxuryMaroonLight)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.luxuryGold.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    private func openInAppleMaps(query: String, near location: String) {
        let searchQuery = "\(query) near \(location)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        if let url = URL(string: "maps://?q=\(searchQuery)") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Gift Result Card with Map
struct GiftResultCardWithMap: View {
    let gift: GiftSuggestion
    let location: String
    var isSaved: Bool = false
    var isBought: Bool = false
    var onSave: (() -> Void)?
    var onBought: (() -> Void)?
    
    private var hasValidPurchaseURL: Bool {
        guard let s = gift.purchaseUrl, !s.isEmpty,
              let url = URL(string: s) else { return false }
        return url.scheme == "http" || url.scheme == "https"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                Text(gift.emoji)
                    .font(.system(size: 40))
                    .frame(width: 60, height: 60)
                    .background(Color.luxuryMaroonLight)
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.luxuryGold.opacity(0.3), lineWidth: 1)
                    )
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(gift.name)
                            .font(Font.bodySans(17, weight: .semibold))
                            .foregroundColor(Color.luxuryCream)
                        
                        Spacer()
                        
                        if isBought {
                            Text("Bought")
                                .font(Font.inter(10, weight: .semibold))
                                .foregroundColor(Color.luxuryMaroon)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.luxuryGold)
                                .cornerRadius(6)
                        } else {
                            Text(gift.priceRange)
                                .font(Font.inter(11, weight: .semibold))
                                .foregroundColor(Color.luxuryGold)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.luxuryGold.opacity(0.15))
                                .cornerRadius(8)
                        }
                    }
                    
                    Text(gift.description)
                        .font(Font.inter(13, weight: .regular))
                        .foregroundColor(Color.luxuryCreamMuted)
                        .lineLimit(2)
                }
            }
            
            HStack(spacing: 8) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 10))
                    .foregroundColor(Color.luxuryGold)
                Text(gift.whyItFits)
                    .font(Font.playfairItalic(13))
                    .foregroundColor(Color.luxuryGoldLight)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.luxuryGold.opacity(0.1))
            .cornerRadius(10)
            
            // Row 1: Save, Find Nearby
            HStack(spacing: 10) {
                if let onSave = onSave {
                    Button {
                        onSave()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: isSaved ? "heart.fill" : "heart.fill")
                                .font(.system(size: 12))
                                .foregroundColor(Color.luxuryGold)
                            Text(isSaved ? "Saved" : "Save")
                                .font(Font.inter(13, weight: .semibold))
                        }
                        .foregroundColor(isSaved ? Color.luxuryCreamMuted : Color.luxuryMaroon)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(isSaved ? Color.luxuryMaroonLight.opacity(0.6) : Color.luxuryCream.opacity(0.9))
                        .cornerRadius(10)
                    }
                    .disabled(isSaved)
                }
                
                Button {
                    openStoreNearby()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 13))
                            .foregroundColor(Color.luxuryGold)
                        Text("Find Nearby")
                            .font(Font.inter(13, weight: .semibold))
                    }
                    .foregroundColor(Color.luxuryGold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.luxuryMaroonLight)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.luxuryGold.opacity(0.4), lineWidth: 1)
                    )
                }
            }
            
            // Row 2: Shop Online, Get new link, Bought
            HStack(spacing: 10) {
                Button {
                    if hasValidPurchaseURL, let url = URL(string: gift.purchaseUrl!) {
                        UIApplication.shared.open(url)
                    } else {
                        openSearchLink()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "cart.fill")
                            .font(.system(size: 12))
                        Text("Shop Online")
                            .font(Font.inter(13, weight: .semibold))
                    }
                    .foregroundColor(Color.luxuryMaroon)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(LinearGradient.goldShimmer)
                    .cornerRadius(10)
                }
                
                Button {
                    openSearchLink()
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "link")
                            .font(.system(size: 11))
                            .foregroundColor(Color.luxuryGold)
                        Text("New link")
                            .font(Font.inter(12, weight: .semibold))
                    }
                    .foregroundColor(Color.luxuryGold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.clear)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.luxuryGold.opacity(0.5), lineWidth: 1)
                    )
                }
                
                if let onBought = onBought {
                    Button {
                        onBought()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 12))
                            Text(isBought ? "Bought" : "Bought")
                                .font(Font.inter(13, weight: .semibold))
                        }
                        .foregroundColor(Color.luxuryMaroon)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            Group {
                                if isBought {
                                    Color.luxuryCreamMuted.opacity(0.5)
                                } else {
                                    LinearGradient.goldShimmer
                                }
                            }
                        )
                        .cornerRadius(10)
                    }
                    .disabled(isBought)
                }
            }
        }
        .padding(18)
        .luxuryCard()
    }
    
    private func openStoreNearby() {
        let query = gift.storeSearchQuery ?? "\(gift.whereToBuy)"
        let searchQuery = "\(query) near \(location)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        if let url = URL(string: "maps://?q=\(searchQuery)") {
            UIApplication.shared.open(url)
        }
    }
    
    /// Opens a search (Google Shopping) for the gift name — "Get new link" / alternative purchase option.
    private func openSearchLink() {
        let query = gift.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? gift.name
        if let url = URL(string: "https://www.google.com/search?tbm=shop&q=\(query)") {
            UIApplication.shared.open(url)
        }
    }
}

#Preview {
    GiftFinderView(datePlan: DatePlan.sample, dateLocation: "San Francisco, CA")
}
