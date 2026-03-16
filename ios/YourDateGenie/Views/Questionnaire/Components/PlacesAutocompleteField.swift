import SwiftUI

/// A text field with Google Places autocomplete for city or address input
struct PlacesAutocompleteField: View {
    let placeholder: String
    @Binding var text: String
    var mode: AutocompleteMode = .city
    var title: String? = nil
    var icon: String? = nil
    
    @State private var predictions: [GooglePlacesService.AutocompletePrediction] = []
    @State private var isSearching = false
    @State private var isFetchingPlaceDetails = false
    @State private var debounceTask: Task<Void, Never>?
    @State private var showPredictions = false
    @FocusState private var isFocused: Bool
    
    enum AutocompleteMode {
        case city
        case address
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let title = title {
                Text(title)
                    .font(Font.bodySans(13, weight: .medium))
                    .foregroundColor(Color.luxuryGold)
            }
            
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 12) {
                    if let icon = icon {
                        Image(systemName: icon)
                            .foregroundColor(Color.luxuryGold.opacity(0.7))
                            .frame(width: 20)
                    }
                    TextField("", text: $text, prompt: Text(placeholder).foregroundColor(Color.luxuryMuted.opacity(0.6)))
                        .font(Font.bodySans(16, weight: .regular))
                        .foregroundColor(Color.luxuryCream)
                        .focused($isFocused)
                        .onChange(of: text) { _, newValue in
                            debounceTask?.cancel()
                            debounceTask = Task {
                                try? await Task.sleep(nanoseconds: 300_000_000) // 0.3s
                                guard !Task.isCancelled else { return }
                                await fetchPredictions(for: newValue)
                            }
                        }
                        .onChange(of: isFocused) { _, focused in
                            showPredictions = focused && !predictions.isEmpty
                        }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color.luxuryMaroonLight)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(text.isEmpty ? Color.luxuryGold.opacity(0.2) : Color.luxuryGold.opacity(0.5), lineWidth: 1)
                )
                .overlay(alignment: .trailing) {
                    if isFetchingPlaceDetails {
                        ProgressView()
                            .tint(Color.luxuryGold)
                            .padding(.trailing, 16)
                    }
                }
                
                if showPredictions && !predictions.isEmpty {
                    VStack(spacing: 0) {
                        ForEach(predictions) { prediction in
                            Button {
                                selectPrediction(prediction)
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "mappin.circle.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(Color.luxuryGold.opacity(0.8))
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(prediction.mainText)
                                            .font(Font.inter(15, weight: .medium))
                                            .foregroundColor(Color.luxuryCream)
                                        if let secondary = prediction.secondaryText {
                                            Text(secondary)
                                                .font(Font.inter(12, weight: .regular))
                                                .foregroundColor(Color.luxuryMuted)
                                        }
                                    }
                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color.luxuryMaroonLight)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .background(Color.luxuryMaroonLight)
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.luxuryGold.opacity(0.3), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.3), radius: 12, y: 4)
                    .padding(.top, 4)
                }
            }
        }
    }
    
    private func fetchPredictions(for input: String) async {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else {
            await MainActor.run {
                predictions = []
                showPredictions = false
            }
            return
        }
        
        await MainActor.run { isSearching = true }
        
        do {
            let results: [GooglePlacesService.AutocompletePrediction]
            if Config.isGooglePlacesConfigured {
                switch mode {
                case .city:
                    results = try await GooglePlacesService.shared.fetchAutocompleteCities(input: trimmed)
                case .address:
                    results = try await GooglePlacesService.shared.fetchAutocompleteAddresses(input: trimmed)
                }
            } else {
                #if DEBUG
                print("[PlacesAutocomplete] Google Places not configured. Set GOOGLE_PLACES_API_KEY in Secrets.xcconfig")
                #endif
                results = []
            }
            
            await MainActor.run {
                predictions = Array(results.prefix(5))
                showPredictions = isFocused && !predictions.isEmpty
            }
        } catch {
            #if DEBUG
            print("[PlacesAutocomplete] Error: \(error.localizedDescription)")
            #endif
            await MainActor.run {
                predictions = []
            }
        }
        
        await MainActor.run { isSearching = false }
    }
    
    /// On selection: in address mode fetch Place Details for full accurate address; otherwise use prediction description.
    private func selectPrediction(_ prediction: GooglePlacesService.AutocompletePrediction) {
        predictions = []
        showPredictions = false
        isFocused = false
        text = prediction.description

        if mode == .address && Config.isGooglePlacesConfigured {
            Task { @MainActor in
                isFetchingPlaceDetails = true
                defer { isFetchingPlaceDetails = false }
                if let result = try? await GooglePlacesService.shared.fetchFormattedAddress(placeId: prediction.placeId),
                   !result.formattedAddress.isEmpty {
                    text = result.formattedAddress
                }
            }
        }
    }
}

#Preview {
    ZStack {
        Color.luxuryMaroon.ignoresSafeArea()
        PlacesAutocompleteField(
            placeholder: "City or neighborhood",
            text: .constant(""),
            mode: .city
        )
        .padding()
    }
}
