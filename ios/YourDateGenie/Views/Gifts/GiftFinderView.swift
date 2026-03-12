import SwiftUI
import CoreLocation

struct GiftFinderView: View {
    var datePlan: DatePlan?
    var dateLocation: String?
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedBudget: String = ""
    @State private var selectedOccasion: String = ""
    @State private var interests: String = ""
    @State private var additionalNotes: String = ""
    @State private var isLoading = false
    @State private var gifts: [GiftSuggestion] = []
    @State private var showResults = false
    @State private var nearbyStores: [NearbyStore] = []
    
    private var effectiveLocation: String {
        if let location = dateLocation, !location.isEmpty {
            return location
        }
        if let firstStop = datePlan?.stops.first, let address = firstStop.address {
            return address
        }
        return ""
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
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.luxuryMaroon
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        headerSection
                        
                        if !showResults {
                            inputFormSection
                        } else {
                            resultsSection
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Gift Finder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
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
        }
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
                .font(Font.displayTitle())
                .foregroundColor(Color.luxuryGold)
            
            Text("Discover gifts from stores near your date")
                .font(Font.playfair(15, weight: .regular))
                .foregroundColor(Color.luxuryCreamMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            
            if let plan = datePlan {
                dateContextBadge(plan: plan)
            }
        }
        .padding(.top, 20)
    }
    
    private func dateContextBadge(plan: DatePlan) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 12))
                Text("Your date: \(plan.title)")
                    .font(Font.inter(12, weight: .medium))
            }
            .foregroundColor(Color.luxuryGold)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.luxuryGold.opacity(0.15))
            .cornerRadius(20)
            
            if !effectiveLocation.isEmpty {
                Button {
                    openInAppleMaps(query: "gift shop", near: effectiveLocation)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 11))
                        Text(effectiveLocation)
                            .font(Font.inter(11, weight: .regular))
                            .lineLimit(1)
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 9))
                    }
                    .foregroundColor(Color.luxuryMuted)
                }
            }
        }
    }
    
    // MARK: - Input Form Section
    private var inputFormSection: some View {
        VStack(spacing: 24) {
            // Occasion Selection
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Image(systemName: "heart.fill")
                        .foregroundColor(Color.luxuryGold)
                    Text("What's the occasion?")
                        .font(Font.playfair(16, weight: .semibold))
                        .foregroundColor(Color.luxuryCream)
                    Text("*")
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
                HStack {
                    Image(systemName: "dollarsign.circle")
                        .foregroundColor(Color.luxuryGold)
                    Text("Budget")
                        .font(Font.playfair(16, weight: .semibold))
                        .foregroundColor(Color.luxuryCream)
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
            
            // Interests
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundColor(Color.luxuryGold)
                    Text("Their interests")
                        .font(Font.playfair(16, weight: .semibold))
                        .foregroundColor(Color.luxuryCream)
                    Text("(optional)")
                        .font(Font.inter(12, weight: .regular))
                        .foregroundColor(Color.luxuryMuted)
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
                HStack {
                    Image(systemName: "text.bubble")
                        .foregroundColor(Color.luxuryGold)
                    Text("Anything else we should know?")
                        .font(Font.playfair(16, weight: .semibold))
                        .foregroundColor(Color.luxuryCream)
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
                        Text("Find Gift Ideas")
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
            // Results header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(gifts.count) gift ideas")
                        .font(Font.sectionTitle())
                        .foregroundColor(Color.luxuryGold)
                    
                    if !effectiveLocation.isEmpty {
                        Text("With stores near \(effectiveLocation)")
                            .font(Font.inter(12, weight: .regular))
                            .foregroundColor(Color.luxuryMuted)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                Button {
                    resetSearch()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 12))
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
            .padding(.horizontal, 20)
            
            // Nearby Stores Section - Opens Google Maps
            if !nearbyStores.isEmpty && !effectiveLocation.isEmpty {
                nearbyStoresSection
            }
            
            // Gift cards with shop nearby buttons
            VStack(spacing: 14) {
                ForEach(gifts) { gift in
                    GiftResultCardWithMap(
                        gift: gift,
                        location: effectiveLocation
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
                        Text("Get More Ideas")
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
            HStack(spacing: 8) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.system(size: 14))
                    .foregroundColor(Color.luxuryGold)
                Text("Find Stores Near Your Date")
                    .font(Font.playfair(16, weight: .semibold))
                    .foregroundColor(Color.luxuryCream)
            }
            .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(nearbyStores) { store in
                        NearbyStoreCard(store: store, location: effectiveLocation)
                    }
                }
                .padding(.horizontal, 20)
            }
            
            // View all on map button
            Button {
                openInAppleMaps(query: "gift shop", near: effectiveLocation)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "map.fill")
                        .font(.system(size: 14))
                    Text("View All Gift Shops on Map")
                        .font(Font.inter(14, weight: .semibold))
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 12))
                }
                .foregroundColor(Color.luxuryGold)
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
        isLoading = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: {
            if let plan = self.datePlan {
                self.gifts = self.generateContextualGifts(for: plan)
            } else {
                self.gifts = self.generateSampleGifts()
            }
            self.nearbyStores = self.generateNearbyStores()
            self.isLoading = false
            withAnimation(.spring(response: 0.5)) {
                self.showResults = true
            }
        })
    }
    
    private func resetSearch() {
        withAnimation {
            showResults = false
            gifts = []
            nearbyStores = []
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
                    Text("Find on Google Maps")
                        .font(Font.inter(11, weight: .semibold))
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 9))
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
                            .font(Font.playfair(17, weight: .semibold))
                            .foregroundColor(Color.luxuryCream)
                        
                        Spacer()
                        
                        Text(gift.priceRange)
                            .font(Font.inter(11, weight: .semibold))
                            .foregroundColor(Color.luxuryGold)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.luxuryGold.opacity(0.15))
                            .cornerRadius(8)
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
                    .foregroundColor(Color.luxuryGoldLight)
                Text(gift.whyItFits)
                    .font(Font.playfairItalic(13))
                    .foregroundColor(Color.luxuryGoldLight)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.luxuryGold.opacity(0.1))
            .cornerRadius(10)
            
            // Action buttons
            HStack(spacing: 10) {
                // Find Nearby button - Opens Google Maps
                Button {
                    openStoreNearby()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 13))
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
                
                // Shop Online button (if available)
                if let purchaseUrl = gift.purchaseUrl, !purchaseUrl.isEmpty {
                    Button {
                        if let url = URL(string: purchaseUrl) {
                            UIApplication.shared.open(url)
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
                } else {
                    // Google Shopping fallback
                    Button {
                        openGoogleShopping()
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
    
    private func openGoogleShopping() {
        let searchQuery = gift.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? gift.name
        if let url = URL(string: "https://www.google.com/search?tbm=shop&q=\(searchQuery)") {
            UIApplication.shared.open(url)
        }
    }
}

#Preview {
    GiftFinderView(datePlan: DatePlan.sample, dateLocation: "San Francisco, CA")
}
