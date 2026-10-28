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
    @State private var explorePlaces: [GooglePlacesService.PlaceSearchResult] = []
    @State private var explorePlacesLoading = false
    @State private var exploreNextPageToken: String?
    @State private var exploreLoadMoreLoading = false
    @State private var exploreRadiusMiles: Int = 10

    private static let radiusOptions: [(label: String, miles: Int)] = [
        ("5 mi", 5), ("10 mi", 10), ("25 mi", 25), ("50 mi", 50)
    ]

    private var exploreRadiusMeters: Int { exploreRadiusMiles * 1609 }

    /// Same as Home: starting point address first, then city (from profile or last questionnaire).
    private var preferredCity: String {
        let resolved = UserProfileManager.resolvedLocationForDiscovery()
        return resolved.isEmpty ? "your area" : resolved
    }
    
    /// Short area name for the title: "Explore Williamsburg".
    private var areaTitle: String {
        guard preferredCity != "your area" else { return "Explore nearby" }
        let first = preferredCity.components(separatedBy: ",").first?.trimmingCharacters(in: .whitespaces) ?? preferredCity
        // A street address reads badly as a title; fall back to the city part.
        if first.rangeOfCharacter(from: .decimalDigits) != nil {
            let city = MapURLHelper.cityStateOrRegionFromAddress(preferredCity)
                .components(separatedBy: ",").first?.trimmingCharacters(in: .whitespaces) ?? ""
            return city.isEmpty ? "Explore nearby" : "Explore \(city)"
        }
        return "Explore \(first)"
    }

    var body: some View {
        ZStack {
            Color.ydgBase
                .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: YDGSpace.md) {
                    VStack(alignment: .leading, spacing: YDGSpace.xxs) {
                        Text(areaTitle)
                            .ydgText(.title1)
                            .lineLimit(2)
                            .minimumScaleFactor(0.7)
                            .accessibilityAddTraits(.isHeader)
                        Text("4.0★ and up, open tonight.")
                            .ydgText(.body, color: .ydgTextSecondary)
                    }
                    .padding(.horizontal, YDGSpace.margin)
                    .padding(.top, YDGSpace.xs)

                    categoryChips

                    resultsList
                }
                .padding(.bottom, YDGSpace.xxl)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                radiusMenu
            }
        }
        .onAppear {
            Task { await loadExplorePlaces() }
        }
        .refreshable {
            await loadExplorePlaces()
        }
    }

    private var radiusMenu: some View {
        Menu {
            ForEach(Self.radiusOptions, id: \.miles) { option in
                Button {
                    guard exploreRadiusMiles != option.miles else { return }
                    exploreRadiusMiles = option.miles
                    Task { await loadExplorePlaces() }
                } label: {
                    if exploreRadiusMiles == option.miles {
                        Label("Within \(option.label)", systemImage: "checkmark")
                    } else {
                        Text("Within \(option.label)")
                    }
                }
            }
        } label: {
            // HStack, not Label: toolbars collapse a Label to its icon.
            HStack(spacing: 4) {
                Image(systemName: "mappin")
                    .font(.system(size: 13, weight: .semibold))
                Text("Within \(exploreRadiusMiles) mi")
                    .font(.ydg(.subhead, weight: .medium))
            }
            .foregroundColor(Color.ydgTextPrimary)
            .padding(.horizontal, YDGSpace.xs)
        }
        .accessibilityLabel("Search radius, \(exploreRadiusMiles) miles")
    }

    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: YDGSpace.xs) {
                YDGChip(title: "All", isSelected: selectedExploreCategory == nil, showsCheckmark: false) {
                    selectedExploreCategory = nil
                    Task { await loadExplorePlaces() }
                }
                ForEach(ExploreCategory.all) { category in
                    YDGChip(title: category.title, isSelected: selectedExploreCategory?.id == category.id, showsCheckmark: false) {
                        selectedExploreCategory = category
                        Task { await loadExplorePlaces() }
                    }
                }
            }
            .padding(.horizontal, YDGSpace.margin)
        }
    }

    @ViewBuilder
    private var resultsList: some View {
        if explorePlacesLoading {
            HStack(spacing: YDGSpace.sm) {
                ProgressView().tint(Color.ydgTextSecondary)
                Text("Finding spots…")
                    .ydgText(.subhead, weight: .regular, color: .ydgTextSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, YDGSpace.xxl)
        } else if explorePlaces.isEmpty {
            VStack(alignment: .leading, spacing: YDGSpace.sm) {
                Text(preferredCity == "your area"
                     ? "Add a starting point in your preferences to see spots near you."
                     : "No spots found here. Try another category or a wider radius.")
                    .ydgText(.body, color: .ydgTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                if preferredCity != "your area" {
                    Button("Try again") { Task { await loadExplorePlaces() } }
                        .buttonStyle(YDGButtonStyle(kind: .secondary, fullWidth: false, compact: true))
                }
            }
            .padding(.horizontal, YDGSpace.margin)
            .padding(.top, YDGSpace.md)
        } else {
            VStack(alignment: .leading, spacing: 0) {
                Text("\(explorePlaces.count) spots")
                    .ydgText(.footnote, color: .ydgTextSecondary)
                    .padding(.bottom, YDGSpace.xs)

                LazyVStack(spacing: 0) {
                    ForEach(explorePlaces, id: \.placeId) { place in
                        ExplorePlaceCard(place: place, preferredCity: preferredCity) {
                            openPlaceInPreferredMaps(place: place)
                        }
                        Rectangle().fill(Color.ydgBorder).frame(height: 1)
                    }
                }

                Button {
                    Task { await loadMoreExplorePlaces() }
                } label: {
                    Text("Show more spots")
                }
                .buttonStyle(YDGButtonStyle(kind: .secondary, isLoading: exploreLoadMoreLoading))
                .disabled(exploreLoadMoreLoading || explorePlacesLoading)
                .padding(.top, YDGSpace.lg)
            }
            .padding(.horizontal, YDGSpace.margin)
        }
    }

    private func loadExplorePlaces() async {
        let city = preferredCity
        guard city != "your area", !city.isEmpty else {
            await MainActor.run { explorePlaces = []; exploreNextPageToken = nil; explorePlacesLoading = false }
            return
        }
        let alreadyLoading = await MainActor.run { () -> Bool in
            if explorePlacesLoading { return true }
            explorePlacesLoading = true
            return false
        }
        guard !alreadyLoading else { return }
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
        ExplorePlaceOpener.open(place)
    }
}

// MARK: - Maps opener (shared by Home preview + full Explore)

enum ExplorePlaceOpener {
    static func open(_ place: GooglePlacesService.PlaceSearchResult) {
        let app = UserDefaults.standard.string(forKey: "dateGenie_preferredMapsApp") ?? "apple"
        if app == "google" {
            let query = "\(place.latitude),\(place.longitude)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            let placeIdEncoded = place.placeId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? place.placeId
            if let url = URL(string: "https://www.google.com/maps/search/?api=1&query=\(query)&query_place_id=\(placeIdEncoded)") {
                UIApplication.shared.open(url)
                return
            }
        }
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

// MARK: - Explore Place Card (Google Places result row)
struct ExplorePlaceCard: View {
    let place: GooglePlacesService.PlaceSearchResult
    let preferredCity: String
    let onOpenInMaps: () -> Void
    
    private var locationText: String {
        let cityState = MapURLHelper.cityStateOrRegionFromAddress(place.address)
        let base = cityState.isEmpty ? preferredCity : cityState
        let price = CurrencyHelper.formattedPriceLevel(place.priceLevel)
        return price.isEmpty ? base : "\(base) · \(price)"
    }
    
    var body: some View {
        Button(action: onOpenInMaps) {
            HStack(alignment: .center, spacing: YDGSpace.sm) {
                AsyncImage(url: place.photoUrl.flatMap(URL.init(string:))) { phase in
                    switch phase {
                    case .success(let image): image.resizable().aspectRatio(contentMode: .fill)
                    default: Color.ydgOverlay
                    }
                }
                .frame(width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: YDGRadius.chip, style: .continuous))
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(place.name)
                        .ydgText(.headline)
                        .lineLimit(1)
                    Text(locationText)
                        .ydgText(.footnote, color: .ydgTextSecondary)
                        .lineLimit(1)
                    HStack(spacing: YDGSpace.xs) {
                        if let r = place.rating {
                            Text("\(String(format: "%.1f", r)) ★")
                                .ydgText(.footnote, weight: .semibold)
                        }
                        if place.openNow == true {
                            Text("Open now")
                                .ydgText(.footnote, color: .ydgSuccess)
                        } else if place.openNow == false {
                            Text("Closed now")
                                .ydgText(.footnote, color: .ydgWarning)
                        }
                    }
                }
                Spacer(minLength: 0)
                Image(systemName: "map")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(Color.ydgAccent)
                    .frame(width: 44, height: 44)
                    .accessibilityHidden(true)
            }
            .padding(.vertical, YDGSpace.sm)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens in Maps")
    }
}

// MARK: - Continue exploring (Home carousel tail → full Explore)
struct ExploreContinueCircleButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color.luxeSurfaceTintStrong)
                    .overlay(Circle().stroke(LinearGradient.goldShimmer, lineWidth: 2))
                    .shadow(color: Color.luxuryGold.opacity(0.3), radius: 16, y: 4)
                    .frame(width: 160, height: 160)
                VStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 44, weight: .medium))
                        .foregroundStyle(LinearGradient.goldShimmer)
                    Text("Continue exploring")
                        .font(Font.bodySans(14, weight: .semibold))
                        .foregroundStyle(LinearGradient.goldShimmer)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(width: 160, height: 160)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Continue exploring — open full Explore")
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
        .background(Color.luxeSurfaceTintStrong)
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
                        Color.luxeSurfaceTintStrong
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
                        Color.luxeSurfaceTintStrong
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
                    .font(Font.bodySerif(16, weight: .bold))
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
