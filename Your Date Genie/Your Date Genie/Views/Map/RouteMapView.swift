import SwiftUI
import MapKit

struct RouteMapView: View {
    let stops: [DatePlanStop]
    @State private var region: MKCoordinateRegion
    @State private var selectedStop: DatePlanStop?
    
    init(stops: [DatePlanStop]) {
        self.stops = stops
        
        // Calculate center region from stops
        let validStops = stops.filter { $0.latitude != nil && $0.longitude != nil }
        if let firstStop = validStops.first,
           let lat = firstStop.latitude,
           let lon = firstStop.longitude {
            _region = State(initialValue: MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            ))
        } else {
            _region = State(initialValue: MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            ))
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Map
            Map(coordinateRegion: $region, annotationItems: stopsWithCoordinates) { stop in
                MapAnnotation(coordinate: CLLocationCoordinate2D(
                    latitude: stop.latitude ?? 0,
                    longitude: stop.longitude ?? 0
                )) {
                    StopMarker(stop: stop, isSelected: selectedStop?.id == stop.id)
                        .onTapGesture {
                            withAnimation {
                                selectedStop = stop
                            }
                        }
                }
            }
            .frame(height: 300)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
            
            // Stops List
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
            
            // Open in Maps Button
            Button {
                openInMaps()
            } label: {
                HStack {
                    Image(systemName: "map.fill")
                    Text("Open Route in Maps")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(LinearGradient.goldGradient)
                .cornerRadius(12)
            }
            .padding(.top, 16)
        }
    }
    
    private var stopsWithCoordinates: [DatePlanStop] {
        stops.filter { $0.latitude != nil && $0.longitude != nil }
    }
    
    private func openInMaps() {
        guard !stops.isEmpty else { return }
        
        // Build Google Maps URL with all stops
        var urlString = "https://www.google.com/maps/dir/"
        
        for stop in stops {
            if let address = stop.address {
                urlString += "\(address.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? "")/"
            }
        }
        
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
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

// MARK: - Stop List Item
struct StopListItem: View {
    let stop: DatePlanStop
    let number: Int
    let isLast: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Number badge
            ZStack {
                Circle()
                    .fill(Color.brandGold)
                    .frame(width: 28, height: 28)
                
                Text("\(number)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(stop.emoji)
                        .font(.system(size: 16))
                    Text(stop.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color(UIColor.label))
                }
                
                Text(stop.venueType)
                    .font(.system(size: 13))
                    .foregroundColor(Color(UIColor.secondaryLabel))
                
                if let address = stop.address {
                    Text(address)
                        .font(.system(size: 12))
                        .foregroundColor(Color(UIColor.tertiaryLabel))
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Get Directions
            Button {
                openDirections(to: stop)
            } label: {
                Image(systemName: "arrow.triangle.turn.up.right.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.brandPrimary)
            }
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(12)
    }
    
    private func openDirections(to stop: DatePlanStop) {
        if let address = stop.address,
           let encoded = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
           let url = URL(string: "maps://?daddr=\(encoded)") {
            UIApplication.shared.open(url)
        }
    }
}

#Preview {
    RouteMapView(stops: DatePlan.sample.stops)
        .padding()
        .background(Color.brandCream)
}
