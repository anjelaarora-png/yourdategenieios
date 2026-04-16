import SwiftUI
import MapKit

struct RouteMapView: View {
    let stops: [DatePlanStop]
    /// When set, route origin is the starting point (not the first stop). Itinerary steps remain 1, 2, 3...
    var startingPoint: StartingPoint?
    /// When false, only pins are shown (e.g. "all places from Past Dates"); no route line or legs.
    var showRouteLine: Bool = true
    @State private var position: MapCameraPosition
    @State private var selectedStop: DatePlanStop?
    /// Geocoded coordinates for stops that didn't have lat/long (so map can show pins and route line).
    @State private var resolvedCoords: [UUID: (lat: Double, lon: Double)] = [:]
    
    init(stops: [DatePlanStop], startingPoint: StartingPoint? = nil, showRouteLine: Bool = true) {
        self.stops = stops
        self.startingPoint = startingPoint
        self.showRouteLine = showRouteLine
        let initialRegion = Self.computeRegion(from: stops, including: startingPoint) ?? Self.neutralFallbackRegion()
        _position = State(initialValue: .region(initialRegion))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Map – position binding so programmatic updates (e.g. after geocode) drive the camera
            Map(position: $position) {
                // Route line connecting starting point to all stops in order (draw under markers); skip when showing "all places" (Past Dates).
                if showRouteLine, routeCoordinates.count >= 2 {
                    MapPolyline(coordinates: routeCoordinates)
                        .stroke(Color.luxuryGold, lineWidth: 4)
                        .mapOverlayLevel(level: .aboveRoads)
                }
                if let start = startingPoint {
                    Annotation(start.address, coordinate: CLLocationCoordinate2D(latitude: start.latitude, longitude: start.longitude)) {
                        StartPointMarker()
                    }
                }
                if showRouteLine {
                    ForEach(Array(legAnnotations.enumerated()), id: \.offset) { _, leg in
                        Annotation(leg.label, coordinate: leg.coordinate) {
                            LegTimeDistanceBadge(time: leg.time, distance: leg.distance, mode: leg.mode)
                        }
                    }
                }
                ForEach(displayStopsWithCoordinates, id: \.stop.id) { item in
                    Annotation(item.stop.name, coordinate: item.coordinate) {
                        StopMarker(stop: item.stop, isSelected: selectedStop?.id == item.stop.id)
                            .onTapGesture {
                                withAnimation {
                                    selectedStop = item.stop
                                }
                            }
                    }
                }
            }
            .frame(height: 300)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.luxuryGold.opacity(0.3), lineWidth: 1)
            )
            
            // Stops List (or empty state)
            if stops.isEmpty {
                Text("Complete dates and mark them as done to see your journey here.")
                    .font(Font.bodySans(15, weight: .medium))
                    .foregroundColor(Color.luxuryCreamMuted)
                    .multilineTextAlignment(.center)
                    .padding(.top, 24)
                    .padding(.horizontal, 20)
            } else {
                VStack(spacing: 12) {
                    ForEach(Array(stops.enumerated()), id: \.element.id) { index, stop in
                        StopListItem(
                            stop: stop,
                            number: index + 1,
                            isLast: index == stops.count - 1
                        )
                    }
                }
                .padding(.top, 16)
            }
            
            // Legs summary (Start → 1, 1 → 2, …) with mode icon, time and distance – readable fonts; only when single route.
            if showRouteLine, !legsList.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Route legs")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color.luxuryCream)
                    VStack(spacing: 8) {
                        ForEach(Array(legsList.enumerated()), id: \.offset) { _, leg in
                            HStack(spacing: 12) {
                                Image(systemName: TravelModeIcon.sfSymbol(for: leg.mode))
                                    .font(.system(size: 16))
                                    .foregroundColor(Color.luxuryGold)
                                    .frame(width: 24, alignment: .center)
                                Text(leg.label)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(Color.luxuryCream)
                                Spacer(minLength: 8)
                                legTimeDistanceLabel(time: leg.time, distance: leg.distance, mode: leg.mode)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(Color.luxuryMaroonLight)
                            .cornerRadius(10)
                        }
                    }
                }
                .padding(.top, 14)
            }
            
            // Open in Maps Button - match app gold button style (dark text on gold); hide when no stops
            if !stops.isEmpty {
                Button {
                    openInMaps()
                } label: {
                    HStack {
                        Image(systemName: "map.fill")
                        Text(showRouteLine ? "Open Route in Maps" : "View in Maps")
                    }
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color.luxuryMaroon)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(LinearGradient.goldGradient)
                .cornerRadius(12)
                .padding(.top, 16)
            }
        }
        .background(Color.luxuryMaroon)
        .onAppear {
            updateRegionFromStops()
            resolveMissingCoordinates()
        }
        .onChange(of: stops) {
            resolvedCoords = [:]
            updateRegionFromStops()
            resolveMissingCoordinates()
        }
        .onChange(of: startingPoint?.latitude) {
            updateRegionFromStops()
        }
        .onChange(of: resolvedCoords.count) {
            updateRegionFromStops()
        }
    }
    
    /// Geocode any stop that lacks coordinates so the map can show pins and the route line.
    private func resolveMissingCoordinates() {
        for stop in stops where stop.latitude == nil || stop.longitude == nil {
            let query = stop.address ?? stop.name
            guard !query.isEmpty else { continue }
            Task { @MainActor in
                if let result = try? await GooglePlacesService.shared.geocodeAddress(query) {
                    resolvedCoords[stop.id] = (result.latitude, result.longitude)
                }
            }
        }
    }
    
    /// Recompute map region from current stops (and starting point when set). Updates position so the map camera follows.
    private func updateRegionFromStops() {
        // Prefer region from all points we can show (stored + resolved coords) so route and pins fit.
        if !routeCoordinates.isEmpty, let newRegion = Self.region(from: routeCoordinates) {
            position = .region(newRegion)
            return
        }
        if let newRegion = Self.computeRegion(from: stops, including: startingPoint) {
            position = .region(newRegion)
            return
        }
        // No coordinates: try to geocode the first stop so the map shows the right area
        guard let first = stops.first else {
            position = .region(Self.neutralFallbackRegion())
            return
        }
        let searchString = first.address ?? first.name
        Task { @MainActor in
            if let result = try? await GooglePlacesService.shared.geocodeAddress(searchString) {
                position = .region(MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: result.latitude, longitude: result.longitude),
                    span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
                ))
            } else {
                position = .region(Self.neutralFallbackRegion())
            }
        }
    }
    
    /// Stops that have coordinates (from model or resolved by geocoding), with their display coordinate, in order.
    private var displayStopsWithCoordinates: [(stop: DatePlanStop, coordinate: CLLocationCoordinate2D)] {
        stops.compactMap { stop in
            let coord: CLLocationCoordinate2D?
            if let lat = stop.latitude, let lon = stop.longitude {
                coord = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            } else if let (lat, lon) = resolvedCoords[stop.id] {
                coord = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            } else {
                coord = nil
            }
            return coord.map { (stop, $0) }
        }
    }
    
    /// Ordered coordinates for the route line: starting point (if set) then stop 1, 2, 3... so the map shows one connected path.
    private var routeCoordinates: [CLLocationCoordinate2D] {
        var coords: [CLLocationCoordinate2D] = []
        if let start = startingPoint {
            coords.append(CLLocationCoordinate2D(latitude: start.latitude, longitude: start.longitude))
        }
        for stop in stops {
            if let lat = stop.latitude, let lon = stop.longitude {
                coords.append(CLLocationCoordinate2D(latitude: lat, longitude: lon))
            } else if let (lat, lon) = resolvedCoords[stop.id] {
                coords.append(CLLocationCoordinate2D(latitude: lat, longitude: lon))
            }
        }
        return coords
    }
    
    /// Legs for summary: Start → 1, 1 → 2, … with time, distance, mode from each stop’s travel fields.
    @ViewBuilder
    private func legTimeDistanceLabel(time: String, distance: String?, mode: String) -> some View {
        let modeLabel = TravelModeIcon.displayLabel(for: mode)
        let hasTime = !time.isEmpty
        let hasDist = (distance ?? "").isEmpty == false
        if hasTime || hasDist {
            HStack(spacing: 6) {
                if hasTime {
                    Text(time)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color.luxuryCream)
                }
                if hasTime && hasDist {
                    Text("·")
                        .font(.system(size: 14))
                        .foregroundColor(Color.luxuryCreamMuted)
                }
                if hasDist, let dist = distance {
                    Text(dist)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color.luxuryCream)
                }
                Text("(\(modeLabel))")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color.luxuryGold.opacity(0.95))
            }
        }
    }
    
    private var legsList: [(label: String, time: String, distance: String?, mode: String)] {
        var list: [(label: String, time: String, distance: String?, mode: String)] = []
        if startingPoint != nil {
            for i in 0..<stops.count {
                let from = i == 0 ? "Start" : "\(i)"
                let to = "\(i + 1)"
                let stop = stops[i]
                list.append((
                    label: "\(from) → \(to)",
                    time: stop.travelTimeFromPrevious ?? "",
                    distance: stop.travelDistanceFromPrevious,
                    mode: stop.travelMode ?? "walking"
                ))
            }
        } else {
            for i in 1..<stops.count {
                let stop = stops[i]
                list.append((
                    label: "\(i) → \(i + 1)",
                    time: stop.travelTimeFromPrevious ?? "",
                    distance: stop.travelDistanceFromPrevious,
                    mode: stop.travelMode ?? "walking"
                ))
            }
        }
        return list
    }
    
    /// Midpoint coordinates and leg info for time/distance badges on the map.
    private var legAnnotations: [(label: String, coordinate: CLLocationCoordinate2D, time: String, distance: String?, mode: String)] {
        let legs = legsList
        let coords = routeCoordinates
        guard coords.count >= 2, legs.count == coords.count - 1 else { return [] }
        return legs.enumerated().map { index, leg in
            let a = coords[index]
            let b = coords[index + 1]
            let mid = CLLocationCoordinate2D(
                latitude: (a.latitude + b.latitude) / 2,
                longitude: (a.longitude + b.longitude) / 2
            )
            return (label: leg.label, coordinate: mid, time: leg.time, distance: leg.distance, mode: leg.mode)
        }
    }
    
    private func openInMaps() {
        guard !stops.isEmpty else { return }
        
        // Build map items: starting point first (when set), then stops in order, so the route is Start → 1 → 2 → 3
        var mapItems: [MKMapItem] = []
        if let start = startingPoint {
            let startCoord = CLLocationCoordinate2D(latitude: start.latitude, longitude: start.longitude)
            let startPlacemark = MKPlacemark(coordinate: startCoord)
            let startItem = MKMapItem(placemark: startPlacemark)
            startItem.name = start.name
            mapItems.append(startItem)
        }
        for display in displayStopsWithCoordinates {
            let placemark = MKPlacemark(coordinate: display.coordinate)
            let mapItem = MKMapItem(placemark: placemark)
            mapItem.name = display.stop.name
            mapItems.append(mapItem)
        }
        
        if !mapItems.isEmpty {
            MKMapItem.openMaps(with: mapItems, launchOptions: [
                MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
            ])
        } else {
            // Fallback: Google Maps URL - origin = starting point when set, else first stop
            guard !stops.isEmpty,
                  var components = URLComponents(string: "https://www.google.com/maps/dir/") else { return }
            components.queryItems = [URLQueryItem(name: "api", value: "1")]
            guard let destStop = stops.last else { return }
            let destValue = MapURLHelper.directionsQueryValue(for: destStop)
            let originValue: String
            let waypointStops: ArraySlice<DatePlanStop>
            if let start = startingPoint {
                originValue = "\(start.latitude),\(start.longitude)"
                waypointStops = stops.count > 1 ? stops.dropLast() : []
            } else {
                guard let originStop = stops.first else { return }
                originValue = MapURLHelper.directionsQueryValue(for: originStop)
                waypointStops = stops.count > 2 ? stops.dropFirst().dropLast() : []
            }
            components.queryItems?.append(URLQueryItem(name: "origin", value: originValue))
            components.queryItems?.append(URLQueryItem(name: "destination", value: destValue))
            if !waypointStops.isEmpty {
                let waypoints = waypointStops
                    .map { MapURLHelper.directionsQueryValue(for: $0) }
                    .filter { !$0.isEmpty }
                    .joined(separator: "|")
                if !waypoints.isEmpty {
                    components.queryItems?.append(URLQueryItem(name: "waypoints", value: waypoints))
                }
            }
            if let url = components.url {
                UIApplication.shared.open(url)
            }
        }
    }
}

// MARK: - RouteMapView region helpers (static to allow use from init)
private extension RouteMapView {
    static func region(from coordinates: [CLLocationCoordinate2D]) -> MKCoordinateRegion? {
        guard !coordinates.isEmpty else { return nil }
        let lats = coordinates.map(\.latitude)
        let lons = coordinates.map(\.longitude)
        guard let minLat = lats.min(), let maxLat = lats.max(),
              let minLon = lons.min(), let maxLon = lons.max() else { return nil }
        let padding = 0.015
        let latDelta = max(maxLat - minLat + padding * 2, 0.02)
        let lonDelta = max(maxLon - minLon + padding * 2, 0.02)
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        return MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
        )
    }

    static func computeRegion(from stops: [DatePlanStop], including start: StartingPoint? = nil) -> MKCoordinateRegion? {
        var valid = stops.compactMap { stop -> CLLocationCoordinate2D? in
            guard let lat = stop.latitude, let lon = stop.longitude else { return nil }
            return CLLocationCoordinate2D(latitude: lat, longitude: lon)
        }
        if let s = start {
            valid.append(CLLocationCoordinate2D(latitude: s.latitude, longitude: s.longitude))
        }
        guard !valid.isEmpty else { return nil }
        let lats = valid.map(\.latitude)
        let lons = valid.map(\.longitude)
        guard let minLat = lats.min(), let maxLat = lats.max(),
              let minLon = lons.min(), let maxLon = lons.max() else { return nil }
        let padding = 0.015
        let latDelta = max(maxLat - minLat + padding * 2, 0.02)
        let lonDelta = max(maxLon - minLon + padding * 2, 0.02)
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        return MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
        )
    }

    static func neutralFallbackRegion() -> MKCoordinateRegion {
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 39.0, longitude: -98.0),
            span: MKCoordinateSpan(latitudeDelta: 25.0, longitudeDelta: 25.0)
        )
    }
}

// MARK: - Start Point Marker (home icon – user's starting address)
struct StartPointMarker: View {
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(Color.luxuryCream)
                    .frame(width: 38, height: 38)
                    .overlay(Circle().stroke(Color.luxuryGold, lineWidth: 2))
                
                Image(systemName: "house.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color.luxuryMaroon)
            }
            Triangle()
                .fill(Color.luxuryCream)
                .frame(width: 12, height: 8)
                .offset(y: -2)
        }
    }
}

// MARK: - Leg time/distance badge on map
struct LegTimeDistanceBadge: View {
    let time: String
    let distance: String?
    let mode: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: TravelModeIcon.sfSymbol(for: mode))
                .font(.system(size: 10))
            Text(time)
                .font(.system(size: 11, weight: .semibold))
            if let d = distance, !d.isEmpty {
                Text("·")
                    .font(.system(size: 10))
                Text(d)
                    .font(.system(size: 11, weight: .medium))
            }
        }
        .foregroundColor(Color.luxuryMaroon)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(Color.luxuryCream)
        .cornerRadius(8)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.luxuryGold.opacity(0.6), lineWidth: 1))
    }
}

// MARK: - Stop Marker
struct StopMarker: View {
    let stop: DatePlanStop
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(LinearGradient.goldGradient)
                    .frame(width: isSelected ? 44 : 36, height: isSelected ? 44 : 36)
                    .shadow(color: Color.brandGold.opacity(0.4), radius: 4, y: 2)
                
                Text("\(stop.order)")
                    .font(.system(size: isSelected ? 16 : 14, weight: .bold))
                    .foregroundColor(.white)
            }
            
            Triangle()
                .fill(Color.brandGold)
                .frame(width: 12, height: 8)
                .offset(y: -2)
        }
        .animation(.spring(response: 0.3), value: isSelected)
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Stop List Item (themed to match app - readable on dark maroon)
struct StopListItem: View {
    let stop: DatePlanStop
    let number: Int
    let isLast: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Number badge
            ZStack {
                Circle()
                    .fill(LinearGradient.goldGradient)
                    .frame(width: 28, height: 28)
                
                Text("\(number)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color.luxuryMaroon)
            }
            
            // Content – readable body sizes
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(stop.emoji)
                        .font(.system(size: 18))
                    Text(stop.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color.luxuryCream)
                }
                
                Text(stop.venueType)
                    .font(.system(size: 14))
                    .foregroundColor(Color.luxuryCreamMuted)
                
                if let address = stop.address {
                    Text(address)
                        .font(.system(size: 13))
                        .foregroundColor(Color.luxuryMuted)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            // Get Directions - gold icon on dark card for visibility
            Button {
                openDirections(to: stop)
            } label: {
                Image(systemName: "arrow.triangle.turn.up.right.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(Color.luxuryGold)
            }
        }
        .padding(12)
        .background(Color.luxuryMaroonLight)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.luxuryGold.opacity(0.25), lineWidth: 1)
        )
    }
    
    private func openDirections(to stop: DatePlanStop) {
        if let url = MapURLHelper.urlForStop(stop) {
            UIApplication.shared.open(url)
        } else if let address = stop.address,
                  let encoded = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                  let url = URL(string: "https://www.google.com/maps/search/?api=1&query=\(encoded)") {
            UIApplication.shared.open(url)
        }
    }
}

#Preview {
    RouteMapView(stops: DatePlan.sample.stops)
        .padding()
        .background(Color.brandCream)
}
