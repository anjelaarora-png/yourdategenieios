import SwiftUI
import CoreLocation

struct Step1LocationView: View {
    @Binding var data: QuestionnaireData
    var isPreferencesOnly: Bool = false
    @StateObject private var locationHelper = CurrentLocationHelper()

    /// "Other" reveals the full calendar; the three quick tiles cover tonight and the next two nights.
    @State private var showCalendar = false

    private static let quickTimes = ["11:00 AM", "1:00 PM", "3:00 PM", "5:00 PM", "6:00 PM", "7:00 PM", "8:00 PM", "9:00 PM", "10:00 PM"]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: YDGSpace.lg) {
                Text(isPreferencesOnly
                     ? "We use this as the default start for routes and nearby spots."
                     : "Your starting point sets the route, the map and what's nearby.")
                    .ydgText(.body, color: .ydgTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                // Location Input
                VStack(alignment: .leading, spacing: YDGSpace.xs) {
                    Text("Where are you leaving from?")
                        .ydgText(.subhead, weight: .medium)
                    PlacesAutocompleteField(
                        placeholder: "Your starting address (required)",
                        text: $data.startingAddress,
                        mode: .address
                    )
                    if data.startingAddress.isEmpty {
                        Text("Required for your route and map")
                            .ydgText(.footnote, color: .ydgTextSecondary)
                    }

                    Button {
                        locationHelper.requestCurrentLocation { address, city in
                            if let address = address {
                                data.startingAddress = address
                                data.syncCityFromStartingAddress()
                            }
                            if let city = city, data.city.isEmpty {
                                data.city = city
                            }
                        }
                    } label: {
                        HStack(spacing: YDGSpace.xs) {
                            if locationHelper.isLoading {
                                ProgressView()
                                    .controlSize(.small)
                                    .tint(Color.ydgAccent)
                            } else {
                                Image(systemName: "location")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            Text(locationHelper.isLoading ? "Finding your location…" : "Use my current location")
                        }
                    }
                    .buttonStyle(.ydgTertiary)
                    .disabled(locationHelper.isLoading)
                }
                
                if !isPreferencesOnly {
                    chipSection("What kind of date?", options: QuestionnaireOptions.dateTypes, selected: data.dateType) {
                        data.dateType = $0
                    }

                    chipSection("Any special occasion?", options: QuestionnaireOptions.occasions, selected: data.occasion) {
                        data.occasion = data.occasion == $0 ? "" : $0
                    }

                    nightSection

                    VStack(alignment: .leading, spacing: YDGSpace.sm) {
                        Text("Starting around")
                            .ydgText(.subhead, weight: .medium)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: YDGSpace.xs) {
                                ForEach(Self.quickTimes, id: \.self) { time in
                                    YDGChip(title: time.replacingOccurrences(of: ":00", with: ""),
                                            isSelected: data.startTime == time,
                                            showsCheckmark: false) {
                                        data.startTime = time
                                        data.timeOfDay = Self.period(for: time)
                                    }
                                }
                            }
                            .padding(.horizontal, 1)
                        }
                        .scrollClipDisabled()
                    }
                }
            }
            .padding(.horizontal, YDGSpace.margin)
            .padding(.top, YDGSpace.xs)
            .padding(.bottom, YDGSpace.lg)
        }
        .scrollDismissesKeyboard(.interactively)
        .onChange(of: data.startingAddress) { _, _ in
            data.syncCityFromStartingAddress()
        }
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
    
    private func chipSection(_ title: String, options: [OptionItem], selected: String, onSelect: @escaping (String) -> Void) -> some View {
        VStack(alignment: .leading, spacing: YDGSpace.sm) {
            Text(title)
                .ydgText(.subhead, weight: .medium)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: YDGSpace.xs) {
                    ForEach(options) { option in
                        YDGChip(title: option.label, isSelected: selected == option.value, showsCheckmark: false) {
                            onSelect(option.value)
                        }
                    }
                }
                .padding(.horizontal, 1)
            }
            .scrollClipDisabled()
        }
    }

    // MARK: Which night?

    private var nightSection: some View {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let quickDays = (0..<3).compactMap { cal.date(byAdding: .day, value: $0, to: today) }
        // No date picked yet behaves as tonight, same as the old calendar's default.
        let selectedDay = cal.startOfDay(for: data.dateScheduled ?? today)
        let isOther = !quickDays.contains(selectedDay)

        return VStack(alignment: .leading, spacing: YDGSpace.sm) {
            Text("Which night?")
                .ydgText(.subhead, weight: .medium)
            HStack(spacing: YDGSpace.xs) {
                ForEach(Array(quickDays.enumerated()), id: \.offset) { index, day in
                    nightTile(
                        top: index == 0 ? "Tonight" : day.formatted(.dateTime.weekday(.abbreviated)),
                        bottom: index == 0 ? day.formatted(.dateTime.weekday(.abbreviated).day()) : day.formatted(.dateTime.month(.abbreviated).day()),
                        isSelected: !showCalendar && selectedDay == day
                    ) {
                        showCalendar = false
                        data.dateScheduled = day
                    }
                }
                nightTile(top: nil, bottom: isOther ? (data.dateScheduled?.formatted(.dateTime.month(.abbreviated).day()) ?? "Other") : "Other",
                          systemImage: "calendar", isSelected: showCalendar || isOther) {
                    withAnimation(.easeInOut(duration: 0.2)) { showCalendar.toggle() }
                }
            }
            if showCalendar {
                CreamGraphicalDatePicker(
                    selection: Binding(
                        get: { data.dateScheduled ?? Date() },
                        set: { data.dateScheduled = $0 }
                    )
                )
                .transition(.opacity)
            }
        }
    }

    private func nightTile(top: String?, bottom: String, systemImage: String? = nil, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 2) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(isSelected ? Color.ydgAccent : Color.ydgTextPrimary)
                }
                if let top {
                    Text(top)
                        .ydgText(.footnote, color: isSelected ? .ydgAccent : .ydgTextSecondary)
                }
                Text(bottom)
                    .ydgText(systemImage == nil ? .headline : .footnote, weight: systemImage == nil ? .medium : .regular,
                             color: isSelected ? .ydgAccent : (systemImage == nil ? .ydgTextPrimary : .ydgTextSecondary))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, minHeight: 64)
            .background(isSelected ? Color.ydgAccentSubtle : Color.ydgRaised,
                        in: RoundedRectangle(cornerRadius: YDGRadius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: YDGRadius.card, style: .continuous)
                    .stroke(isSelected ? Color.ydgAccent : Color.ydgBorder, lineWidth: isSelected ? 1.5 : 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private static func period(for time: String) -> String {
        let parts = time.split(separator: " ")
        guard parts.count == 2, let hour = Int(parts[0].split(separator: ":").first ?? "") else { return "evening" }
        let isPM = parts[1] == "PM"
        let h24 = isPM ? (hour == 12 ? 12 : hour + 12) : (hour == 12 ? 0 : hour)
        switch h24 {
        case ..<12: return "morning"
        case 12..<17: return "afternoon"
        case 17..<21: return "evening"
        default: return "night"
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
                    .font(Font.bodySans(13, weight: .semibold))
                    .foregroundColor(isSelected ? Color.ydgAccent : Color.ydgTextPrimary)
                    .lineLimit(1)
                if let timeRange = period.time {
                    Text(timeRange)
                        .font(Font.ydgSans(12, weight: .regular))
                        .foregroundColor(Color.ydgTextSecondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .background(
                isSelected ? Color.ydgAccentSubtle : Color.ydgRaised
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.ydgAccent : Color.ydgBorder, lineWidth: isSelected ? 1.5 : 1)
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
                .font(Font.bodySans(13, weight: isSelected ? .semibold : .medium))
                .foregroundColor(isSelected ? Color.ydgAccent : Color.ydgTextPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    isSelected ? Color.ydgAccentSubtle : Color.ydgRaised
                )
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isSelected ? Color.ydgAccent : Color.ydgBorder, lineWidth: isSelected ? 1.5 : 1)
                )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Custom TextField Style
struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(Font.bodySans(15, weight: .regular))
            .foregroundColor(Color.ydgTextPrimary)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.ydgRaised)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.ydgBorder, lineWidth: 1)
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
        .background(Color.ydgBase)
}
