import SwiftUI
import CoreLocation

struct Step1LocationView: View {
    @Binding var data: QuestionnaireData
    var isPreferencesOnly: Bool = false
    @StateObject private var locationHelper = CurrentLocationHelper()

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                // Location Input
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(emoji: "📍", title: isPreferencesOnly ? "Your location" : "Where are you planning?")
                    
                    PlacesAutocompleteField(
                        placeholder: "City or neighborhood",
                        text: $data.city,
                        mode: .city
                    )
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Where are you leaving from?")
                            .font(Font.bodySans(13, weight: .medium))
                            .foregroundColor(Color.luxuryMuted)
                        PlacesAutocompleteField(
                            placeholder: "Your starting address (required)",
                            text: $data.startingAddress,
                            mode: .address
                        )
                        if data.startingAddress.isEmpty {
                            Text("Required for your route and map")
                                .font(Font.inter(11, weight: .regular))
                                .foregroundColor(Color.luxuryGold.opacity(0.9))
                        }

                        Button {
                            locationHelper.requestCurrentLocation { address, city in
                                if let address = address {
                                    data.startingAddress = address
                                }
                                if let city = city, data.city.isEmpty {
                                    data.city = city
                                }
                            }
                        } label: {
                            HStack(spacing: 8) {
                                if locationHelper.isLoading {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .tint(Color.luxuryGold)
                                } else {
                                    Image(systemName: "location.fill")
                                        .font(.system(size: 14))
                                }
                                Text(locationHelper.isLoading ? "Finding your location..." : "Use my current location")
                                    .font(Font.bodySans(14, weight: .medium))
                            }
                            .foregroundColor(Color.luxuryGold)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 44)
                            .background(Color.luxuryMaroonLight.opacity(0.7))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.luxuryGold.opacity(0.5), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(locationHelper.isLoading)
                    }
                }
                
                if !isPreferencesOnly {
                // Date Type
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(emoji: "💑", title: "What kind of date?")
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ForEach(QuestionnaireOptions.dateTypes) { type in
                            OptionCardView(
                                item: type,
                                isSelected: data.dateType == type.value,
                                onTap: { data.dateType = type.value }
                            )
                        }
                    }
                }
                
                // Occasion
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(emoji: "🎉", title: "Any special occasion?")
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ForEach(QuestionnaireOptions.occasions) { occasion in
                            OptionCardView(
                                item: occasion,
                                isSelected: data.occasion == occasion.value,
                                onTap: { data.occasion = occasion.value }
                            )
                        }
                    }
                }
                
                // Date & Time — unified, asked once
                VStack(alignment: .leading, spacing: 16) {
                    SectionHeader(emoji: "📅", title: "When?", subtitle: "Pick your date and preferred time")
                    
                    // Date Picker
                    DatePicker(
                        "",
                        selection: Binding(
                            get: { data.dateScheduled ?? Date() },
                            set: { data.dateScheduled = $0 }
                        ),
                        in: Date()...,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .tint(Color.luxuryGold)
                    .colorScheme(.dark)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.luxuryMaroonLight)
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.luxuryGold.opacity(0.3), lineWidth: 1)
                    )
                    
                    // Part of day + time — one seamless selection
                    VStack(alignment: .leading, spacing: 14) {
                        Text("What time works best?")
                            .font(Font.tangerine(22, weight: .bold))
                            .italic()
                            .foregroundColor(Color.luxuryGold)
                        
                        // Period cards (Morning / Afternoon / Evening / Late Night)
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 10) {
                            ForEach(QuestionnaireOptions.timeOfDay) { period in
                                TimeOfDayCard(
                                    period: period,
                                    isSelected: data.timeOfDay == period.value,
                                    onTap: {
                                        data.timeOfDay = period.value
                                        data.startTime = timeOptions(for: period.value).first ?? "7:00 PM"
                                    }
                                )
                            }
                        }
                        
                        // Time slots within selected period
                        if !data.timeOfDay.isEmpty {
                            let slots = timeOptions(for: data.timeOfDay)
                            FlowLayout(spacing: 8) {
                                ForEach(slots, id: \.self) { time in
                                    TimeSlotChip(
                                        time: time,
                                        isSelected: data.startTime == time,
                                        onTap: { data.startTime = time }
                                    )
                                }
                            }
                        }
                    }
                    .padding(16)
                    .background(Color.luxuryMaroonLight.opacity(0.6))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.luxuryGold.opacity(0.25), lineWidth: 1)
                    )
                }
                } // end if !isPreferencesOnly
            }
            .padding(20)
        }
        .scrollDismissesKeyboard(.interactively)
        .onAppear {
            if !isPreferencesOnly && data.timeOfDay.isEmpty {
                data.timeOfDay = "evening"
                data.startTime = "7:00 PM"
            }
        }
        .alert("Location Access Needed", isPresented: $locationHelper.showPermissionDeniedAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Please allow location access in Settings so we can fill in your starting address automatically.")
        }
    }
    
    private func timeOptions(for period: String) -> [String] {
        switch period {
        case "morning": return ["8:00 AM", "9:00 AM", "10:00 AM", "11:00 AM"]
        case "afternoon": return ["12:00 PM", "1:00 PM", "2:00 PM", "3:00 PM", "4:00 PM"]
        case "evening": return ["5:00 PM", "6:00 PM", "7:00 PM", "8:00 PM", "9:00 PM"]
        case "night": return ["9:00 PM", "9:30 PM", "10:00 PM", "10:30 PM", "11:00 PM"]
        default: return ["6:00 PM", "7:00 PM", "8:00 PM", "9:00 PM"]
        }
    }
}

// MARK: - Time of Day Card (compact period selector)
private struct TimeOfDayCard: View {
    let period: OptionItem
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                Text(period.emoji)
                    .font(.system(size: 26))
                Text(period.label)
                    .font(Font.inter(13, weight: .semibold))
                    .foregroundColor(isSelected ? Color.luxuryMaroon : Color.luxuryCream)
                    .lineLimit(1)
                if let timeRange = period.time {
                    Text(timeRange)
                        .font(Font.inter(10, weight: .regular))
                        .foregroundColor(isSelected ? Color.luxuryMaroon.opacity(0.8) : Color.luxuryMuted)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .background(
                isSelected ? LinearGradient.goldShimmer : LinearGradient(colors: [Color.luxuryMaroonLight], startPoint: .top, endPoint: .bottom)
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.clear : Color.luxuryGold.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Time Slot Chip
private struct TimeSlotChip: View {
    let time: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(time)
                .font(Font.inter(13, weight: isSelected ? .semibold : .medium))
                .foregroundColor(isSelected ? Color.luxuryMaroon : Color.luxuryCream)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    isSelected ? LinearGradient.goldShimmer : LinearGradient(colors: [Color.luxuryMaroonLight], startPoint: .top, endPoint: .bottom)
                )
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isSelected ? Color.clear : Color.luxuryGold.opacity(0.3), lineWidth: 1)
                )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Custom TextField Style
struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(Font.inter(15, weight: .regular))
            .foregroundColor(Color.luxuryCream)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.luxuryMaroonLight)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.luxuryGold.opacity(0.3), lineWidth: 1)
            )
    }
}

// MARK: - Current Location Helper

@MainActor
final class CurrentLocationHelper: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var isLoading = false
    @Published var showPermissionDeniedAlert = false
    private let manager = CLLocationManager()
    private var completion: ((String?, String?) -> Void)?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    /// Requests the device's current location and reverse-geocodes it.
    /// Completion delivers `(address, city)` — both may be nil on failure or denial.
    func requestCurrentLocation(completion: @escaping (String?, String?) -> Void) {
        self.completion = completion
        isLoading = true
        let status = manager.authorizationStatus
        if status == .notDetermined {
            manager.requestWhenInUseAuthorization()
        } else if status == .authorizedWhenInUse || status == .authorizedAlways {
            manager.requestLocation()
        } else {
            isLoading = false
            showPermissionDeniedAlert = true
            completion(nil, nil)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.first else {
            Task { @MainActor in self.finish(address: nil, city: nil) }
            return
        }
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(loc) { placemarks, _ in
            let placemark = placemarks?.first
            var parts: [String] = []
            if let number = placemark?.subThoroughfare { parts.append(number) }
            if let street = placemark?.thoroughfare { parts.append(street) }
            if let cityName = placemark?.locality { parts.append(cityName) }
            if let state = placemark?.administrativeArea { parts.append(state) }
            let address = parts.isEmpty ? nil : parts.joined(separator: ", ")
            let city = placemark?.locality
            Task { @MainActor in self.finish(address: address, city: city) }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in self.finish(address: nil, city: nil) }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            DispatchQueue.main.async { manager.requestLocation() }
        } else if status != .notDetermined {
            Task { @MainActor in
                self.showPermissionDeniedAlert = true
                self.finish(address: nil, city: nil)
            }
        }
    }

    private func finish(address: String?, city: String?) {
        isLoading = false
        completion?(address, city)
        completion = nil
    }
}

#Preview {
    Step1LocationView(data: .constant(QuestionnaireData()), isPreferencesOnly: false)
        .background(Color.luxuryMaroon)
}
