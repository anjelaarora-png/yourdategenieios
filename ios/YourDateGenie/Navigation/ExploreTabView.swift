import SwiftUI
import MapKit

// MARK: - Explore category (for trending spots in city; ample options in Continue exploring)
struct ExploreCategory: Identifiable {
    let id: String
    let title: String
    let emoji: String
    static let all: [ExploreCategory] = [
        ExploreCategory(id: "restaurants", title: "Restaurants", emoji: "🍽️"),
        ExploreCategory(id: "cafes", title: "Cafes", emoji: "☕"),
        ExploreCategory(id: "bars", title: "Bars & Lounges", emoji: "🍸"),
        ExploreCategory(id: "romantic", title: "Romantic", emoji: "🌹"),
        ExploreCategory(id: "date_night", title: "Date Night", emoji: "✨"),
        ExploreCategory(id: "brunch", title: "Brunch", emoji: "🥞"),
        ExploreCategory(id: "wine", title: "Wine & Vineyards", emoji: "🍷"),
        ExploreCategory(id: "outdoor", title: "Outdoor & Parks", emoji: "🌳"),
        ExploreCategory(id: "arts", title: "Arts & Culture", emoji: "🎨"),
        ExploreCategory(id: "nightlife", title: "Nightlife", emoji: "🎉"),
        ExploreCategory(id: "live_music", title: "Live Music", emoji: "🎵"),
        ExploreCategory(id: "bakeries", title: "Bakeries & Desserts", emoji: "🧁"),
        ExploreCategory(id: "rooftop", title: "Rooftop & Views", emoji: "🌆"),
        ExploreCategory(id: "spa", title: "Spa & Wellness", emoji: "💆"),
    ]
}

// MARK: - Luxury Explore Tab View (6 recommended tiles → Continue exploring → categories + list)
struct LuxuryExploreTabView: View {
    @EnvironmentObject var coordinator: NavigationCoordinator
    @State private var selectedExploreCategory: ExploreCategory? = nil
    @State private var recommendedPlaces: [GooglePlacesService.PlaceSearchResult] = []
    @State private var recommendedLoading = false
    @State private var explorePlaces: [GooglePlacesService.PlaceSearchResult] = []
    @State private var explorePlacesLoading = false
    @State private var exploreNextPageToken: String?
    @State private var exploreLoadMoreLoading = false
    @State private var exploreRadiusMiles: Int = 10

    private static let radiusOptions: [(label: String, miles: Int)] = [
        ("5 mi", 5), ("10 mi", 10), ("25 mi", 25), ("50 mi", 50)
    ]

    private var exploreRadiusMeters: Int { exploreRadiusMiles * 1609 }

    /// Same as Home: starting point address first, then city (from Google Places / Maps).
    private var preferredCity: String {
        guard let user = UserProfileManager.shared.currentUser else { return "your area" }
        let start = user.preferences.defaultStartingPoint.trimmingCharacters(in: .whitespaces)
        let city = user.preferences.defaultCity.trimmingCharacters(in: .whitespaces)
        if !start.isEmpty { return start }
        if !city.isEmpty { return city }
        return "your area"
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.luxuryMaroon
                    .ignoresSafeArea()
                
                ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 24) {
                            // Header: Recommended in [city]
                            VStack(spacing: 6) {
                                Text("Recommended in your area")
                                    .font(Font.bodySans(16, weight: .regular))
                                    .foregroundColor(Color.luxuryCreamMuted)
                                    .multilineTextAlignment(.center)
                                    .frame(maxWidth: .infinity)
                                Text(preferredCity)
                                    .font(Font.tangerine(26, weight: .bold))
                                    .italic()
                                    .foregroundColor(Color.luxuryGold)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                                    .minimumScaleFactor(0.6)
                                    .frame(maxWidth: geo.size.width - 40)
                                Text("4★+ restaurants, bars, activities & outdoor spots")
                                    .font(Font.bodySans(12, weight: .medium))
                                    .foregroundColor(Color.luxuryCreamMuted)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 16)
                            .padding(.horizontal, 20)
                            
                            // Radius filter bar
                            radiusBar

                            // 6 tiles: horizontal scroll of recommended places
                            recommendedTilesSection(geo: geo)
                            
                            // Pick a category — isolated so horizontal scroll/taps don’t hit results below
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Pick a category")
                                    .font(Font.tangerine(32, weight: .bold))
                                    .italic()
                                    .foregroundColor(Color.luxuryGold)
                                    .padding(.horizontal, 20)
                                
                                ScrollView(.horizontal, showsIndicators: true) {
                                    HStack(spacing: 10) {
                                        Button {
                                            selectedExploreCategory = nil
                                            Task { await loadExplorePlaces() }
                                        } label: {
                                            chipLabel("All", isSelected: selectedExploreCategory == nil)
                                        }
                                        .buttonStyle(ChipButtonStyle())
                                        ForEach(ExploreCategory.all) { category in
                                            Button {
                                                selectedExploreCategory = category
                                                Task { await loadExplorePlaces() }
                                            } label: {
                                                HStack(spacing: 6) {
                                                    Text(category.emoji).font(.system(size: 14))
                                                    Text(category.title)
                                                        .font(Font.bodySans(13, weight: .semibold))
                                                        .foregroundColor(selectedExploreCategory?.id == category.id ? Color.luxuryMaroon : Color.luxuryCream)
                                                        .lineLimit(1)
                                                        .truncationMode(.tail)
                                                        .minimumScaleFactor(0.8)
                                                }
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 8)
                                                .background(selectedExploreCategory?.id == category.id ? Color.luxuryGold : Color.luxuryMaroonLight.opacity(0.8))
                                                .cornerRadius(20)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 20)
                                                        .stroke(Color.luxuryGold.opacity(selectedExploreCategory?.id == category.id ? 1 : 0.35), lineWidth: 1)
                                                )
                                                .contentShape(Rectangle())
                                            }
                                            .buttonStyle(ChipButtonStyle())
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 4)
                                }
                                .scrollBounceBehavior(.automatic)
                                .frame(maxWidth: .infinity)
                                .background(Color.luxuryMaroon)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.bottom, 20)
                            .background(Color.luxuryMaroon)
                            .zIndex(1)
                            
                            // Category results list — clear gap so chips scroll doesn’t hit first card
                            if explorePlacesLoading {
                                VStack(spacing: 16) {
                                    ProgressView().tint(Color.luxuryGold)
                                    Text("Finding spots…")
                                        .font(Font.bodySans(14, weight: .medium))
                                        .foregroundColor(Color.luxuryCreamMuted)
                                }
                                .frame(maxWidth: .infinity).padding(.vertical, 40)
                            } else if explorePlaces.isEmpty {
                                VStack(spacing: 10) {
                                    Text(selectedExploreCategory == nil
                                         ? "Pick a category above to see more spots"
                                         : "No spots found for this category — try a different one or pull to refresh.")
                                        .font(Font.bodySans(15, weight: .medium))
                                        .foregroundColor(Color.luxuryCreamMuted)
                                        .multilineTextAlignment(.center)
                                        .lineLimit(4)
                                        .frame(maxWidth: .infinity)
                                        .padding(.horizontal, 24)
                                    if selectedExploreCategory != nil {
                                        Button {
                                            Task { await loadExplorePlaces() }
                                        } label: {
                                            HStack(spacing: 6) {
                                                Image(systemName: "arrow.clockwise")
                                                    .font(.system(size: 13, weight: .semibold))
                                                Text("Retry")
                                                    .font(Font.bodySans(13, weight: .semibold))
                                            }
                                            .foregroundColor(Color.luxuryMaroon)
                                            .padding(.horizontal, 20)
                                            .padding(.vertical, 10)
                                            .background(LinearGradient.goldShimmer)
                                            .cornerRadius(12)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.vertical, 40)
                            } else {
                                // Results header: spot count + quick-access refresh button
                                HStack {
                                    Text("\(explorePlaces.count) spots found")
                                        .font(Font.bodySans(13, weight: .medium))
                                        .foregroundColor(Color.luxuryCreamMuted)
                                    Spacer()
                                    Button {
                                        Task { await loadExplorePlaces() }
                                    } label: {
                                        HStack(spacing: 5) {
                                            Image(systemName: "arrow.clockwise")
                                                .font(.system(size: 13, weight: .semibold))
                                            Text("Refresh")
                                                .font(Font.bodySans(13, weight: .semibold))
                                        }
                                        .foregroundColor(Color.luxuryGold)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 7)
                                        .background(Color.luxuryMaroonLight.opacity(0.8))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 20)
                                                .stroke(Color.luxuryGold.opacity(0.5), lineWidth: 1)
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 20))
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(explorePlacesLoading)
                                }
                                .padding(.horizontal, 20)
                                .padding(.top, 4)

                                LazyVStack(spacing: 14) {
                                    ForEach(explorePlaces, id: \.placeId) { place in
                                        ExplorePlaceCard(place: place, preferredCity: preferredCity) {
                                            openPlaceInPreferredMaps(place: place)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    // Generate more options — appends more spots (uses pagination token when
                                    // available, otherwise fetches a fresh set and adds only new results)
                                    Button {
                                        Task { await loadMoreExplorePlaces() }
                                    } label: {
                                        HStack(spacing: 8) {
                                            if exploreLoadMoreLoading {
                                                ProgressView()
                                                    .tint(Color.luxuryMaroon)
                                            } else {
                                                Image(systemName: "sparkles")
                                                    .font(.system(size: 18, weight: .medium))
                                                Text("Generate more options")
                                                    .font(Font.bodySans(16, weight: .semibold))
                                            }
                                        }
                                        .foregroundColor(Color.luxuryMaroon)
                                        .padding(.horizontal, 24)
                                        .padding(.vertical, 16)
                                        .frame(maxWidth: .infinity)
                                        .background(Color.luxuryMaroonLight.opacity(0.9))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(Color.luxuryGold.opacity(0.6), lineWidth: 1)
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(exploreLoadMoreLoading || explorePlacesLoading)
                                    .padding(.top, 10)
                                    .padding(.horizontal, 20)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal, 20)
                                .padding(.top, 8)
                                .padding(.bottom, 24)
                            }
                        }
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .padding(.bottom, 120)
                    }
                    .scrollBounceBehavior(.basedOnSize)
            }
        }
        .toolbarBackground(Color.luxuryMaroon, for: .navigationBar)
        .onAppear {
            Task { await loadRecommendedPlaces() }
            Task { await loadExplorePlaces() }
        }
        .refreshable {
            await loadRecommendedPlaces()
            await loadExplorePlaces()
        }
    }
    
    /// Top 6 recommended tiles (horizontal scroll); loading state or empty state when no location.
    private func recommendedTilesSection(geo: GeometryProxy) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if recommendedLoading {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(0..<6, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: 24)
                                .fill(Color.luxuryMaroonLight.opacity(0.5))
                                .frame(width: 200, height: 200)
                                .overlay(ProgressView().tint(Color.luxuryGold))
                        }
                    }
                    .padding(.horizontal, 20)
                }
            } else if recommendedPlaces.isEmpty {
                Text("Set your starting address or city in Settings to see recommended spots here.")
                    .font(Font.bodySans(14, weight: .medium))
                    .foregroundColor(Color.luxuryCreamMuted)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 24)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(recommendedPlaces.prefix(6), id: \.placeId) { place in
                            ExplorePlaceCard(place: place, preferredCity: preferredCity) {
                                openPlaceInPreferredMaps(place: place)
                            }
                            .frame(width: min(220, geo.size.width - 60))
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private var radiusBar: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 5) {
                Image(systemName: "location.circle.fill")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color.luxuryGold)
                Text("Area radius")
                    .font(Font.bodySans(12, weight: .medium))
                    .foregroundColor(Color.luxuryCreamMuted)
            }
            .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Self.radiusOptions, id: \.miles) { option in
                        Button {
                            guard exploreRadiusMiles != option.miles else { return }
                            exploreRadiusMiles = option.miles
                            Task {
                                await loadRecommendedPlaces()
                                await loadExplorePlaces()
                            }
                        } label: {
                            Text(option.label)
                                .font(Font.bodySans(13, weight: .semibold))
                                .foregroundColor(exploreRadiusMiles == option.miles ? Color.luxuryMaroon : Color.luxuryCream)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(exploreRadiusMiles == option.miles ? Color.luxuryGold : Color.luxuryMaroonLight.opacity(0.8))
                                .cornerRadius(20)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.luxuryGold.opacity(exploreRadiusMiles == option.miles ? 1 : 0.35), lineWidth: 1)
                                )
                        }
                        .buttonStyle(ChipButtonStyle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 2)
            }
            .scrollBounceBehavior(.automatic)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func chipLabel(_ title: String, isSelected: Bool) -> some View {
        Text(title)
            .font(Font.bodySans(14, weight: .semibold))
            .foregroundColor(isSelected ? Color.luxuryMaroon : Color.luxuryCream)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(isSelected ? Color.luxuryGold : Color.luxuryMaroonLight.opacity(0.8))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.luxuryGold.opacity(isSelected ? 1 : 0.35), lineWidth: 1)
            )
    }
    
    private func loadRecommendedPlaces() async {
        let city = preferredCity
        guard city != "your area", !city.isEmpty else {
            await MainActor.run { recommendedPlaces = []; recommendedLoading = false }
            return
        }
        await MainActor.run { if recommendedLoading { return }; recommendedLoading = true }
        let radius = exploreRadiusMeters
        do {
            let places = try await GooglePlacesService.shared.fetchRecommendedInCity(city: city, limit: 6, radiusMeters: radius)
            await MainActor.run { recommendedPlaces = places; recommendedLoading = false }
        } catch {
            await MainActor.run { recommendedPlaces = []; recommendedLoading = false }
        }
    }
    
    private func loadExplorePlaces() async {
        let city = preferredCity
        guard city != "your area", !city.isEmpty else {
            await MainActor.run { explorePlaces = []; exploreNextPageToken = nil; explorePlacesLoading = false }
            return
        }
        await MainActor.run { if explorePlacesLoading { return }; explorePlacesLoading = true }
        let isAll = selectedExploreCategory == nil
        let radius = exploreRadiusMeters
        do {
            let page: GooglePlacesService.TrendingPlacesPage
            if isAll {
                page = try await GooglePlacesService.shared.fetchTrendingPlacesAllCategory(city: city, minCount: 10, radiusMeters: radius)
            } else {
                page = try await GooglePlacesService.shared.fetchTrendingPlacesPage(city: city, categoryId: selectedExploreCategory?.id, pageToken: nil, radiusMeters: radius)
            }
            await MainActor.run {
                explorePlaces = page.places
                exploreNextPageToken = page.nextPageToken
                explorePlacesLoading = false
            }
        } catch {
            await MainActor.run { explorePlaces = []; exploreNextPageToken = nil; explorePlacesLoading = false }
        }
    }
    
    /// Append more spots to the current list.
    /// Uses the pagination token when Google returned one; otherwise fetches a fresh set for the
    /// same category/location and appends only results not already shown.
    private func loadMoreExplorePlaces() async {
        let city = preferredCity
        guard city != "your area", !city.isEmpty else { return }
        let skip = await MainActor.run { () -> Bool in
            if exploreLoadMoreLoading { return true }
            exploreLoadMoreLoading = true
            return false
        }
        if skip { return }

        let categoryId = selectedExploreCategory?.id
        let token = await MainActor.run { exploreNextPageToken }
        let radius = exploreRadiusMeters

        do {
            let page: GooglePlacesService.TrendingPlacesPage
            if let token, !token.isEmpty {
                // Pagination token available — brief delay for Google's token to activate
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                page = try await GooglePlacesService.shared.fetchTrendingPlacesPage(city: city, categoryId: categoryId, pageToken: token, radiusMeters: radius)
            } else {
                // No token — fetch a fresh set and append genuinely new spots
                let isAll = categoryId == nil
                if isAll {
                    page = try await GooglePlacesService.shared.fetchTrendingPlacesAllCategory(city: city, minCount: 10, radiusMeters: radius)
                } else {
                    page = try await GooglePlacesService.shared.fetchTrendingPlacesPage(city: city, categoryId: categoryId, pageToken: nil, radiusMeters: radius)
                }
            }
            await MainActor.run {
                var seen = Set(explorePlaces.map(\.placeId))
                let newPlaces = page.places.filter { seen.insert($0.placeId).inserted }
                explorePlaces.append(contentsOf: newPlaces)
                exploreNextPageToken = page.nextPageToken
                exploreLoadMoreLoading = false
            }
        } catch {
            await MainActor.run { exploreLoadMoreLoading = false }
        }
    }
    
    /// Opens the business profile in Google Maps or Apple Maps (reviews, hours, photos).
    private func openPlaceInPreferredMaps(place: GooglePlacesService.PlaceSearchResult) {
        let app = UserDefaults.standard.string(forKey: "dateGenie_preferredMapsApp") ?? "apple"
        if app == "google" {
            // Google Maps: api=1 + query (lat,lon) + query_place_id opens the business profile in the app
            let query = "\(place.latitude),\(place.longitude)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            let placeIdEncoded = place.placeId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? place.placeId
            if let url = URL(string: "https://www.google.com/maps/search/?api=1&query=\(query)&query_place_id=\(placeIdEncoded)") {
                UIApplication.shared.open(url)
                return
            }
        }
        // Apple Maps: place URL shows business-style card with name, address, coordinate
        var comp = URLComponents(string: "https://maps.apple.com/place")!
        comp.queryItems = [
            URLQueryItem(name: "address", value: place.address),
            URLQueryItem(name: "coordinate", value: "\(place.latitude),\(place.longitude)"),
            URLQueryItem(name: "name", value: place.name),
            URLQueryItem(name: "q", value: place.name),
            URLQueryItem(name: "map", value: "explore"),
        ]
        if let url = comp.url {
            UIApplication.shared.open(url)
        } else {
            let coord = CLLocationCoordinate2D(latitude: place.latitude, longitude: place.longitude)
            let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coord))
            mapItem.name = place.name
            mapItem.openInMaps(launchOptions: nil)
        }
    }
}

// MARK: - Chip button style — ensures chip taps are consumed and don’t pass through to cards below
private struct ChipButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .contentShape(Rectangle())
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - Explore Place Card (Google Places result, View in Maps)
private struct ExplorePlaceCard: View {
    let place: GooglePlacesService.PlaceSearchResult
    let preferredCity: String
    let onOpenInMaps: () -> Void
    
    private var tagline: String {
        if let r = place.rating {
            let stars = "★ \(String(format: "%.1f", r))"
            if let n = place.userRatingsTotal, n > 0 { return "\(stars) · \(n) reviews" }
            return stars
        }
        return "Trending on Google"
    }
    
    private var locationText: String {
        let cityState = MapURLHelper.cityStateOrRegionFromAddress(place.address)
        return cityState.isEmpty ? preferredCity : cityState
    }
    
    var body: some View {
        Button(action: onOpenInMaps) {
            VStack(alignment: .leading, spacing: 0) {
                AsyncImage(url: URL(string: place.photoUrl ?? "https://images.unsplash.com/photo-1514933651103-005eec06c04b?w=400&h=300&fit=crop")) { phase in
                    switch phase {
                    case .success(let image): image.resizable().aspectRatio(contentMode: .fill)
                    case .empty, .failure: Color.luxuryMaroonLight
                    @unknown default: EmptyView()
                    }
                }
                .frame(height: 120)
                .frame(maxWidth: .infinity)
                .clipped()
                .overlay(LinearGradient(colors: [.clear, Color.luxuryMaroon.opacity(0.8)], startPoint: .top, endPoint: .bottom))
                .clipShape(RoundedRectangle(cornerRadius: 24))
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(place.name)
                        .font(Font.bodySans(15, weight: .semibold))
                        .foregroundColor(Color.luxuryCream)
                        .lineLimit(2)
                        .truncationMode(.tail)
                        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                    Text(tagline)
                        .font(Font.bodySans(12, weight: .regular))
                        .foregroundColor(Color.luxuryMuted)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                    HStack(spacing: 8) {
                        Label(locationText, systemImage: "location")
                            .font(Font.bodySans(11, weight: .medium))
                            .foregroundColor(Color.luxuryCreamMuted)
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .minimumScaleFactor(0.9)
                            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                        if place.openNow == true {
                            Label("Open now", systemImage: "clock")
                                .font(Font.bodySans(11, weight: .medium))
                                .foregroundColor(Color.luxuryCreamMuted)
                        }
                        if !CurrencyHelper.formattedPriceLevel(place.priceLevel).isEmpty {
                            Text(CurrencyHelper.formattedPriceLevel(place.priceLevel))
                                .font(Font.bodySans(11, weight: .medium))
                                .foregroundColor(Color.luxuryCreamMuted)
                        }
                        Spacer(minLength: 0)
                    }
                    Text("View in Maps")
                        .font(Font.bodySans(12, weight: .semibold))
                        .foregroundColor(Color.luxuryMaroon)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(LinearGradient.goldShimmer)
                        .cornerRadius(12)
                }
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                .padding(16)
            }
            .frame(maxWidth: .infinity)
            .background(Color.luxuryMaroonLight.opacity(0.7))
            .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.luxuryGold.opacity(0.3), lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(color: Color.luxuryGold.opacity(0.15), radius: 12, y: 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Explore Category Tile
struct ExploreCategoryTile: View {
    let category: ExploreCategory
    
    var body: some View {
        VStack(spacing: 10) {
            Text(category.emoji)
                .font(.system(size: 32))
            Text(category.title)
                .font(Font.bodySans(14, weight: .semibold))
                .foregroundColor(Color.luxuryCream)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color.luxuryMaroonLight.opacity(0.8))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.luxuryGold.opacity(0.25), lineWidth: 1)
        )
    }
}

// MARK: - Date Type Tile
struct LuxuryDateTypeTile: View {
    let emoji: String
    let title: String
    
    private var imageUrl: String {
        switch title {
        case "Romantic": return "https://images.unsplash.com/photo-1529634806980-85c3dd6d34ac?w=140&h=140&fit=crop"
        case "Fun": return "https://images.unsplash.com/photo-1533174072545-7a4b6ad7a6c3?w=140&h=140&fit=crop"
        case "Cozy": return "https://images.unsplash.com/photo-1558171813-4c088753af8f?w=140&h=140&fit=crop"
        case "Adventure": return "https://images.unsplash.com/photo-1533130061792-64b345e4a833?w=140&h=140&fit=crop"
        case "Special": return "https://images.unsplash.com/photo-1519671482749-fd09be7ccebf?w=140&h=140&fit=crop"
        default: return "https://images.unsplash.com/photo-1529333166437-7750a6dd5a70?w=140&h=140&fit=crop"
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                AsyncImage(url: URL(string: imageUrl)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .empty, .failure:
                        Color.luxuryMaroonLight
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(width: 68, height: 68)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                
                Text(emoji)
                    .font(.system(size: 28))
                    .shadow(color: .black.opacity(0.5), radius: 2, y: 1)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.luxuryGold.opacity(0.3), lineWidth: 1)
            )
            
            Text(title)
                .font(Font.bodySans(13, weight: .medium))
                .foregroundColor(Color.luxuryCream)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - Inspiration Card
struct LuxuryInspirationCard: View {
    let title: String
    let description: String
    let emoji: String
    
    private var imageUrl: String {
        switch title {
        case "Wine & Dine": return "https://images.unsplash.com/photo-1510812431401-41d2bd2722f3?w=120&h=120&fit=crop"
        case "Outdoor Adventure": return "https://images.unsplash.com/photo-1501555088652-021faa106b9b?w=120&h=120&fit=crop"
        case "Arts & Culture": return "https://images.unsplash.com/photo-1499781350541-7783f6c6a0c8?w=120&h=120&fit=crop"
        default: return "https://images.unsplash.com/photo-1529333166437-7750a6dd5a70?w=120&h=120&fit=crop"
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                AsyncImage(url: URL(string: imageUrl)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .empty, .failure:
                        Color.luxuryMaroonLight
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                
                Text(emoji)
                    .font(.system(size: 28))
                    .shadow(color: .black.opacity(0.5), radius: 2, y: 1)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.luxuryGold.opacity(0.3), lineWidth: 1)
            )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(Font.header(16, weight: .bold))
                    .foregroundColor(Color.luxuryGold)
                    .lineLimit(2)
                    .truncationMode(.tail)
                
                Text(description)
                    .font(Font.bodySans(14, weight: .regular))
                    .foregroundColor(Color.luxuryCreamMuted)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
            
            Spacer(minLength: 8)
            
            Image(systemName: "chevron.right")
                .foregroundColor(Color.luxuryGold.opacity(0.6))
        }
        .padding(20)
        .luxuryCard()
    }
}
