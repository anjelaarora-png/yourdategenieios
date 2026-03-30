import SwiftUI

// MARK: - Reservation region & top-two platforms (matches web config)
private enum ReservationRegion: String {
    case us, uk, ca, au, fr, de, it, es, jp, india, ae, sa, sg, th, my, br, mx, za, nz, eu, latam, other
}

private func detectReservationRegion(from address: String?) -> ReservationRegion {
    guard let address = address, !address.isEmpty else { return .us }
    let lower = address.lowercased()
    if lower.contains("usa") || lower.contains("united states") || lower.range(of: #", [a-z]{2} \d{5}"#, options: .regularExpression) != nil { return .us }
    if lower.contains("canada") || lower.contains("ontario") || lower.contains("quebec") || lower.contains("british columbia") || lower.contains("toronto") || lower.contains("vancouver") || lower.contains("montreal") || lower.contains("calgary") || lower.contains("ottawa") || lower.contains(", bc") || lower.contains(", ab") || lower.contains(", qc") || lower.contains(", on") { return .ca }
    if lower.contains("mexico") || lower.contains("méxico") || lower.contains("cdmx") || lower.contains("guadalajara") || lower.contains("monterrey") || lower.contains("cancun") || lower.contains("oaxaca") { return .mx }
    if lower.contains("new zealand") || lower.contains("auckland") || lower.contains("wellington") || lower.contains("christchurch") || lower.contains("queenstown") || lower.contains("dunedin") { return .nz }
    if lower.contains("uae") || lower.contains("dubai") || lower.contains("abu dhabi") || lower.contains("emirates") { return .ae }
    if lower.contains("saudi arabia") || lower.contains("saudi") || lower.contains("riyadh") || lower.contains("jeddah") || lower.contains("mecca") || lower.contains("dammam") { return .sa }
    if lower.contains("south africa") || lower.contains("johannesburg") || lower.contains("cape town") || lower.contains("durban") || lower.contains("pretoria") { return .za }
    if lower.contains("brazil") || lower.contains("brasil") || lower.contains("são paulo") || lower.contains("sao paulo") || lower.contains("rio de janeiro") || lower.contains("brasília") || lower.contains("brasilia") { return .br }
    if lower.contains("uk") || lower.contains("united kingdom") || lower.contains("england") || lower.contains("london") || lower.contains("scotland") || lower.contains("wales") { return .uk }
    if lower.contains("france") || lower.contains("paris") || lower.contains("lyon") || lower.contains("marseille") { return .fr }
    if lower.contains("germany") || lower.contains("deutschland") || lower.contains("berlin") || lower.contains("munich") || lower.contains("hamburg") || lower.contains("frankfurt") || lower.contains("cologne") { return .de }
    if lower.contains("italy") || lower.contains("italia") || lower.contains("rome") || lower.contains("roma") || lower.contains("milan") || lower.contains("milano") || lower.contains("naples") || lower.contains("florence") || lower.contains("venice") { return .it }
    if lower.contains("spain") || lower.contains("españa") || lower.contains("espana") || lower.contains("madrid") || lower.contains("barcelona") || lower.contains("valencia") || lower.contains("seville") { return .es }
    if lower.contains("japan") || lower.contains("tokyo") || lower.contains("osaka") || lower.contains("kyoto") || lower.contains("yokohama") || lower.contains("nagoya") || lower.contains("fukuoka") || lower.contains("sapporo") || lower.contains("hiroshima") { return .jp }
    if lower.contains("india") || lower.contains("mumbai") || lower.contains("delhi") || lower.contains("bangalore") || lower.contains("chennai") || lower.contains("hyderabad") || lower.contains("kolkata") || lower.contains("pune") || lower.contains("ahmedabad") || lower.contains("jaipur") { return .india }
    if lower.contains("singapore") || lower.contains(" sg ") { return .sg }
    if lower.contains("thailand") || lower.contains("bangkok") || lower.contains("phuket") || lower.contains("chiang mai") { return .th }
    if lower.contains("malaysia") || lower.contains("kuala lumpur") || lower.contains("penang") || lower.contains("george town") || lower.contains("johor") { return .my }
    if lower.contains("argentina") || lower.contains("chile") || lower.contains("colombia") || lower.contains("peru") || lower.contains("lima") || lower.contains("buenos aires") || lower.contains("bogotá") || lower.contains("bogota") || lower.contains("santiago") { return .latam }
    let usStates = ["ny", "nyc", "ca", "tx", "fl", "wa", "il", "pa", "oh", "ga", "nc", "mi", "nj", "va", "az", "ma", "tn", "in", "mo", "md", "wi", "mn", "co", "al", "sc", "la", "ky", "or", "ok", "ct", "ut", "ia", "nv", "ar", "ms", "ks", "nm", "ne", "wv", "id", "hi", "nh", "me", "mt", "ri", "de", "sd", "nd", "ak", "vt", "dc", "wy"]
    if usStates.contains(where: { lower.contains($0) }) { return .us }
    if lower.contains("australia") || lower.contains("sydney") || lower.contains("melbourne") || lower.contains("brisbane") || lower.contains("perth") || lower.contains("adelaide") || lower.contains("canberra") { return .au }
    let euTerms = ["netherlands", "belgium", "austria", "switzerland", "portugal", "ireland", "denmark", "sweden", "norway", "finland", "greece", "poland", "amsterdam", "brussels", "vienna", "zurich", "lisbon", "dublin", "copenhagen", "stockholm"]
    if euTerms.contains(where: { lower.contains($0) }) { return .eu }
    return .us
}

private struct ReservationPlatformItem: Identifiable {
    let id: String
    let name: String
}

private func topTwoPlatforms(for region: ReservationRegion) -> [ReservationPlatformItem] {
    switch region {
    case .us: return [ReservationPlatformItem(id: "opentable", name: "OpenTable"), ReservationPlatformItem(id: "resy", name: "Resy")]
    case .uk: return [ReservationPlatformItem(id: "opentable", name: "OpenTable"), ReservationPlatformItem(id: "thefork", name: "TheFork")]
    case .ca: return [ReservationPlatformItem(id: "opentable", name: "OpenTable"), ReservationPlatformItem(id: "resy", name: "Resy")]
    case .au: return [ReservationPlatformItem(id: "opentable", name: "OpenTable"), ReservationPlatformItem(id: "quandoo", name: "Quandoo")]
    case .fr: return [ReservationPlatformItem(id: "thefork", name: "TheFork"), ReservationPlatformItem(id: "opentable", name: "OpenTable")]
    case .de: return [ReservationPlatformItem(id: "thefork", name: "TheFork"), ReservationPlatformItem(id: "quandoo", name: "Quandoo")]
    case .it: return [ReservationPlatformItem(id: "thefork", name: "TheFork"), ReservationPlatformItem(id: "opentable", name: "OpenTable")]
    case .es: return [ReservationPlatformItem(id: "thefork", name: "TheFork"), ReservationPlatformItem(id: "opentable", name: "OpenTable")]
    case .jp: return [ReservationPlatformItem(id: "tabelog", name: "Tabelog"), ReservationPlatformItem(id: "opentable", name: "OpenTable")]
    case .india: return [ReservationPlatformItem(id: "swiggy", name: "Swiggy"), ReservationPlatformItem(id: "district", name: "District")]
    case .ae: return [ReservationPlatformItem(id: "eatapp", name: "Eat App"), ReservationPlatformItem(id: "zomato", name: "Zomato")]
    case .sa: return [ReservationPlatformItem(id: "eatapp", name: "Eat App"), ReservationPlatformItem(id: "thechefz", name: "The Chefz")]
    case .sg: return [ReservationPlatformItem(id: "chope", name: "Chope"), ReservationPlatformItem(id: "eatigo", name: "Eatigo")]
    case .th: return [ReservationPlatformItem(id: "eatigo", name: "Eatigo"), ReservationPlatformItem(id: "opentable", name: "OpenTable")]
    case .my: return [ReservationPlatformItem(id: "eatigo", name: "Eatigo"), ReservationPlatformItem(id: "opentable", name: "OpenTable")]
    case .br: return [ReservationPlatformItem(id: "opentable", name: "OpenTable"), ReservationPlatformItem(id: "tripadvisor", name: "TripAdvisor")]
    case .mx: return [ReservationPlatformItem(id: "opentable", name: "OpenTable"), ReservationPlatformItem(id: "tripadvisor", name: "TripAdvisor")]
    case .za: return [ReservationPlatformItem(id: "zomato", name: "Zomato"), ReservationPlatformItem(id: "opentable", name: "OpenTable")]
    case .nz: return [ReservationPlatformItem(id: "opentable", name: "OpenTable"), ReservationPlatformItem(id: "firsttable", name: "First Table")]
    case .eu: return [ReservationPlatformItem(id: "thefork", name: "TheFork"), ReservationPlatformItem(id: "quandoo", name: "Quandoo")]
    case .latam: return [ReservationPlatformItem(id: "opentable", name: "OpenTable"), ReservationPlatformItem(id: "thefork", name: "TheFork")]
    case .other: return [ReservationPlatformItem(id: "opentable", name: "OpenTable"), ReservationPlatformItem(id: "quandoo", name: "Quandoo")]
    }
}

/// Search string sent to reservation platforms: restaurant name plus city when address is available.
private func restaurantSearchTerm(venueName: String, address: String?) -> String {
    let name = venueName.trimmingCharacters(in: .whitespaces)
    let effectiveName = name.isEmpty ? "Restaurant" : name
    guard let address = address, !address.isEmpty else { return effectiveName }
    let parts = address.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
    guard parts.count >= 2 else { return effectiveName }
    let city = String(parts[parts.count - 2])
    return "\(effectiveName) \(city)"
}

private func regionDisplayName(_ region: ReservationRegion) -> String {
    switch region {
    case .us: return "USA"
    case .uk: return "UK"
    case .ca: return "Canada"
    case .au: return "Australia"
    case .fr: return "France"
    case .de: return "Germany"
    case .it: return "Italy"
    case .es: return "Spain"
    case .jp: return "Japan"
    case .india: return "India"
    case .ae: return "UAE / Dubai"
    case .sa: return "Saudi Arabia"
    case .sg: return "Singapore"
    case .th: return "Thailand"
    case .my: return "Malaysia"
    case .br: return "Brazil"
    case .mx: return "Mexico"
    case .za: return "South Africa"
    case .nz: return "New Zealand"
    case .eu: return "Europe"
    case .latam: return "Latin America"
    case .other: return "International"
    }
}

struct ReservationWidgetView: View {
    let venueName: String
    let venueType: String
    var address: String?
    var phoneNumber: String?
    /// Direct OpenTable/Resy or venue booking URL — shown as primary CTA when set.
    var bookingUrl: String?
    var websiteUrl: String?
    var openingHours: [String]?
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDate = Date()
    @State private var selectedTime = "7:00 PM"
    @State private var partySize = 2
    @State private var specialRequests = ""
    @State private var isSubmitting = false
    @State private var showConfirmation = false
    @State private var hoursExpanded = false
    
    private let timeSlots = ["6:00 PM", "6:30 PM", "7:00 PM", "7:30 PM", "8:00 PM", "8:30 PM", "9:00 PM", "9:30 PM"]
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Luxurious background
                Color.luxuryMaroon
                    .ignoresSafeArea()
                
                if showConfirmation {
                    confirmationView
                } else {
                    formContent
                }
            }
            .navigationTitle("Make a Reservation")
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
    
    private var formContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // Venue info card
                VStack(spacing: 14) {
                    Image(systemName: "fork.knife.circle.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(LinearGradient.goldShimmer)
                    
                    VStack(spacing: 6) {
                        Text(venueName)
                            .font(Font.displayTitle())
                            .foregroundColor(Color.luxuryGold)
                        
                        Text(venueType)
                            .font(Font.playfair(15, weight: .regular))
                            .foregroundColor(Color.luxuryCreamMuted)
                    }
                    
                    if let address = address {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "mappin.circle")
                                .foregroundColor(Color.luxuryGold.opacity(0.7))
                            Text(address)
                                .font(Font.inter(13, weight: .regular))
                                .foregroundColor(Color.luxuryMuted)
                        }
                    }
                    if let hours = openingHours, !hours.isEmpty {
                        DisclosureGroup(isExpanded: $hoursExpanded) {
                            VStack(alignment: .leading, spacing: 2) {
                                ForEach(hours, id: \.self) { line in
                                    Text(line)
                                        .font(Font.inter(11, weight: .regular))
                                        .foregroundColor(Color.luxuryMuted)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 4)
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "clock")
                                    .foregroundColor(Color.luxuryGold.opacity(0.7))
                                Text("Hours")
                                    .font(Font.inter(12, weight: .semibold))
                                    .foregroundColor(Color.luxuryMuted)
                            }
                        }
                        .tint(Color.luxuryGold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 6)
                    }
                    if let url = websiteUrl, !url.isEmpty {
                        Link(destination: URL(string: url)!) {
                            HStack(spacing: 6) {
                                Image(systemName: "globe")
                                    .foregroundColor(Color.luxuryGold)
                                Text("Website")
                                    .font(Font.inter(13, weight: .medium))
                                    .foregroundColor(Color.luxuryGold)
                            }
                        }
                        .padding(.top, 4)
                    }
                }
                .padding(24)
                .frame(maxWidth: .infinity)
                .luxuryCard()
                .padding(.horizontal, 20)
                .padding(.top, 12)
                
                // Direct reservation link – primary CTA when we have OpenTable/Resy booking URL
                if let urlString = effectiveReservationUrl, let url = URL(string: urlString) {
                    Button {
                        UIApplication.shared.open(url)
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "link.circle.fill")
                                .font(.system(size: 20))
                            Text(reservationPlatformLabel(urlString))
                                .font(Font.inter(16, weight: .semibold))
                        }
                        .foregroundColor(Color.luxuryMaroon)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(LinearGradient.goldShimmer)
                        .cornerRadius(16)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                }
                
                // Date picker
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(Color.luxuryGold)
                        Text("Select Date")
                            .font(Font.playfair(16, weight: .semibold))
                            .foregroundColor(Color.luxuryCream)
                    }
                    
                    DatePicker("", selection: $selectedDate, in: Date()..., displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .tint(Color.luxuryGold)
                        .colorScheme(.dark)
                        .padding(16)
                        .background(Color.luxuryMaroonLight)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.luxuryGold.opacity(0.3), lineWidth: 1)
                        )
                }
                .padding(.horizontal, 20)
                
                // Time selection
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(Color.luxuryGold)
                        Text("Select Time")
                            .font(Font.playfair(16, weight: .semibold))
                            .foregroundColor(Color.luxuryCream)
                    }
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 10) {
                        ForEach(timeSlots, id: \.self) { time in
                            TimeChip(time: time, isSelected: selectedTime == time) {
                                selectedTime = time
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                // Party size
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "person.2")
                            .foregroundColor(Color.luxuryGold)
                        Text("Party Size")
                            .font(Font.playfair(16, weight: .semibold))
                            .foregroundColor(Color.luxuryCream)
                    }
                    
                    HStack(spacing: 20) {
                        Button {
                            if partySize > 1 { partySize -= 1 }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(partySize > 1 ? Color.luxuryGold : Color.luxuryMuted.opacity(0.4))
                        }
                        .disabled(partySize <= 1)
                        
                        VStack(spacing: 2) {
                            Text("\(partySize)")
                                .font(Font.header(36, weight: .bold))
                                .foregroundColor(Color.luxuryGold)
                            Text(partySize == 1 ? "guest" : "guests")
                                .font(Font.inter(12, weight: .regular))
                                .foregroundColor(Color.luxuryMuted)
                        }
                        .frame(width: 80)
                        
                        Button {
                            if partySize < 12 { partySize += 1 }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(partySize < 12 ? Color.luxuryGold : Color.luxuryMuted.opacity(0.4))
                        }
                        .disabled(partySize >= 12)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.luxuryMaroonLight)
                    .cornerRadius(16)
                    .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.luxuryGold.opacity(0.3), lineWidth: 1)
                        )
                }
                .padding(.horizontal, 20)
                
                // Reserve a table – platform buttons (use restaurant's booking URL when we have it for that platform)
                VStack(alignment: .leading, spacing: 12) {
                    Text("Reserve a table")
                        .font(Font.playfair(16, weight: .semibold))
                        .foregroundColor(Color.luxuryCream)
                    Text("Select date & time above, then tap a platform to open it.")
                        .font(Font.inter(12, weight: .regular))
                        .foregroundColor(Color.luxuryMuted)
                    HStack(spacing: 12) {
                        ForEach(reservedPlatforms) { platform in
                            if let url = reservationUrl(for: platform.id) {
                                Button {
                                    UIApplication.shared.open(url)
                                } label: {
                                    HStack(spacing: 10) {
                                        ReservationPlatformIconView(platformId: platform.id, platformName: platform.name)
                                        Text(platform.name)
                                            .font(Font.inter(15, weight: .semibold))
                                            .foregroundColor(Color.luxuryMaroon)
                                            .lineLimit(2)
                                            .minimumScaleFactor(0.85)
                                            .multilineTextAlignment(.leading)
                                            .fixedSize(horizontal: false, vertical: true)
                                        Spacer(minLength: 4)
                                        Image(systemName: "arrow.up.right")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(Color.luxuryMaroon.opacity(0.8))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .padding(.horizontal, 12)
                                    .background(LinearGradient.goldShimmer)
                                    .cornerRadius(12)
                                }
                            }
                        }
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity)
                .luxuryCard()
                .padding(.horizontal, 20)
                .padding(.top, 12)
                
                // Special requests
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "note.text")
                            .foregroundColor(Color.luxuryGold)
                        Text("Special Requests")
                            .font(Font.playfair(16, weight: .semibold))
                            .foregroundColor(Color.luxuryCream)
                        
                        Text("(optional)")
                            .font(Font.inter(12, weight: .regular))
                            .foregroundColor(Color.luxuryMuted)
                    }
                    
                    TextEditor(text: $specialRequests)
                        .font(Font.inter(15, weight: .regular))
                        .foregroundColor(Color.luxuryCream)
                        .scrollContentBackground(.hidden)
                        .frame(height: 100)
                        .padding(14)
                        .background(Color.luxuryMaroonLight)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.luxuryGold.opacity(0.3), lineWidth: 1)
                        )
                        .overlay(
                            Group {
                                if specialRequests.isEmpty {
                                    Text("Window seat, anniversary celebration...")
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
                
                // Submit button
                Button {
                    submitReservation()
                } label: {
                    HStack(spacing: 10) {
                        if isSubmitting {
                            ProgressView()
                                .tint(Color.luxuryMaroon)
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Request Reservation")
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(LuxuryGoldButtonStyle())
                .disabled(isSubmitting)
                .padding(.horizontal, 20)
                
                // Call option
                if let phone = phoneNumber {
                    Button {
                        if let url = URL(string: "tel://\(phone.replacingOccurrences(of: "-", with: ""))") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "phone.fill")
                            Text("Or Call Directly: \(phone)")
                        }
                        .font(Font.inter(14, weight: .medium))
                        .foregroundColor(Color.luxuryMuted)
                    }
                }
            }
            .padding(.bottom, 40)
        }
    }
    
    private var confirmationView: some View {
        VStack(spacing: 28) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color.luxuryGold.opacity(0.15))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 70))
                    .foregroundStyle(LinearGradient.goldShimmer)
            }
            
            VStack(spacing: 10) {
                Text("Reservation Requested!")
                    .font(Font.displayTitle())
                    .foregroundColor(Color.luxuryGold)
                
                Text("We'll confirm your booking shortly")
                    .font(Font.playfair(16, weight: .regular))
                    .foregroundColor(Color.luxuryCreamMuted)
            }
            
            // Details card
            VStack(spacing: 16) {
                ReservationDetailRow(icon: "building.2", label: "Venue", value: venueName)
                ReservationDetailRow(icon: "calendar", label: "Date", value: formattedDate)
                ReservationDetailRow(icon: "clock", label: "Time", value: selectedTime)
                ReservationDetailRow(icon: "person.2", label: "Guests", value: "\(partySize)")
            }
            .padding(20)
            .luxuryCard()
            .padding(.horizontal, 40)
            
            Spacer()
            
            Button {
                dismiss()
            } label: {
                Text("Done")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(LuxuryGoldButtonStyle())
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: selectedDate)
    }
    
    /// Reservation URL for the primary CTA: bookingUrl, or websiteUrl when it's OpenTable/Resy.
    private var effectiveReservationUrl: String? {
        if let b = bookingUrl, !b.isEmpty { return b }
        if let w = websiteUrl, !w.isEmpty, isOpenTableOrResy(w) { return w }
        return nil
    }
    
    /// Top two reservation platforms for the detected region (for "Reserve a table" buttons).
    private var reservedPlatforms: [ReservationPlatformItem] {
        topTwoPlatforms(for: detectReservationRegion(from: address))
    }
    
    /// Platform id for effectiveReservationUrl when it's a known booking platform (opentable / resy).
    private var effectiveReservationPlatformId: String? {
        guard let urlString = effectiveReservationUrl else { return nil }
        let lower = urlString.lowercased()
        if lower.contains("opentable.com") { return "opentable" }
        if lower.contains("resy.com") { return "resy" }
        return nil
    }
    
    /// URL to open for a platform: use restaurant's actual booking page when we have it for this platform, else search URL.
    private func reservationUrl(for platformId: String) -> URL? {
        if let directId = effectiveReservationPlatformId, directId == platformId,
           let urlString = effectiveReservationUrl, let url = URL(string: urlString) {
            return url
        }
        return searchUrl(forPlatformId: platformId)
    }
    
    private var isoDateString: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: selectedDate)
    }
    
    /// selectedTime is like "7:00 PM" -> "19:00" for URL
    private var isoTimeString: String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        guard let date = f.date(from: selectedTime) else { return "19:00" }
        let out = DateFormatter()
        out.dateFormat = "HH:mm"
        return out.string(from: date)
    }
    
    /// OpenTable search URL: send restaurant name + city so the platform can pre-fill search.
    private var openTableSearchUrl: URL? {
        let termRaw = restaurantSearchTerm(venueName: venueName, address: address)
        let term = termRaw.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? venueName
        let neighborhood = address?.split(separator: ",").first.map(String.init)?.trimmingCharacters(in: .whitespaces).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        var comp = URLComponents(string: "https://www.opentable.com/s")!
        comp.queryItems = [
            URLQueryItem(name: "covers", value: "\(partySize)"),
            URLQueryItem(name: "dateTime", value: "\(isoDateString)T\(isoTimeString)"),
            URLQueryItem(name: "term", value: term),
        ]
        if !neighborhood.isEmpty {
            comp.queryItems?.append(URLQueryItem(name: "neighborhood", value: neighborhood))
        }
        return comp.url
    }
    
    /// Resy search URL: send restaurant name + city so the platform can pre-fill search.
    private var resySearchUrl: URL? {
        let termRaw = restaurantSearchTerm(venueName: venueName, address: address)
        let query = termRaw.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? venueName
        let citySlug = resyCitySlugFromAddress(address)
        var comp = URLComponents(string: "https://resy.com/cities/\(citySlug)")!
        comp.queryItems = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "date", value: isoDateString),
            URLQueryItem(name: "seats", value: "\(partySize)"),
        ]
        return comp.url
    }
    
    private func resyCitySlugFromAddress(_ addr: String?) -> String {
        guard let addr = addr, !addr.isEmpty else { return "ny" }
        let parts = addr.split(separator: ",")
        guard parts.count >= 2 else { return "ny" }
        let city = parts[parts.count - 2].trimmingCharacters(in: .whitespaces).lowercased()
        let map: [String: String] = [
            "new york": "ny", "nyc": "ny", "manhattan": "ny", "brooklyn": "ny",
            "los angeles": "la", "la": "la",
            "san francisco": "sf", "sf": "sf",
            "chicago": "chi", "miami": "mia", "austin": "atx", "denver": "den",
            "seattle": "sea", "boston": "bos", "washington": "dc", "dc": "dc",
            "atlanta": "atl", "nashville": "nash", "houston": "hou", "dallas": "dal",
            "philadelphia": "phl",
        ]
        for (key, value) in map {
            if city.contains(key) { return value }
        }
        return "ny"
    }
    
    private func chopeCitySlugFromAddress(_ addr: String?) -> String {
        guard let addr = addr, !addr.isEmpty else { return "singapore" }
        let city = addr.split(separator: ",").dropLast().last.map(String.init)?.trimmingCharacters(in: .whitespaces).lowercased() ?? ""
        let map: [String: String] = [
            "singapore": "singapore", "hong kong": "hong-kong", "bangkok": "bangkok",
            "phuket": "phuket", "bali": "bali", "jakarta": "jakarta", "shanghai": "shanghai",
        ]
        for (key, value) in map {
            if city.contains(key) { return value }
        }
        return "singapore"
    }
    
    private func tabelogAreaSlugFromAddress(_ addr: String?) -> String {
        guard let addr = addr, !addr.isEmpty else { return "tokyo" }
        let city = addr.split(separator: ",").dropLast().last.map(String.init)?.trimmingCharacters(in: .whitespaces).lowercased() ?? ""
        let map: [String: String] = [
            "tokyo": "tokyo", "osaka": "osaka", "kyoto": "kyoto", "yokohama": "kanagawa",
            "fukuoka": "fukuoka", "sapporo": "hokkaido", "nagoya": "aichi", "hiroshima": "hiroshima",
        ]
        for (key, value) in map {
            if city.contains(key) { return value }
        }
        return "tokyo"
    }
    
    private func eatigoPathFromAddress(_ addr: String?) -> String {
        guard let addr = addr, !addr.isEmpty else { return "sg/singapore" }
        let lower = addr.lowercased()
        if lower.contains("thailand") || lower.contains("bangkok") || lower.contains("phuket") { return "th/bangkok" }
        if lower.contains("malaysia") || lower.contains("kuala lumpur") || lower.contains("penang") { return "my/kuala-lumpur" }
        return "sg/singapore"
    }
    
    /// Build search URL for a platform id; sends restaurant name + city so the platform can pre-fill search.
    private func searchUrl(forPlatformId id: String) -> URL? {
        let searchTerm = restaurantSearchTerm(venueName: venueName, address: address)
        let term = searchTerm.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? venueName
        switch id {
        case "opentable": return openTableSearchUrl
        case "resy": return resySearchUrl
        case "thefork":
            var c = URLComponents(string: "https://www.thefork.com/search")!
            c.queryItems = [
                URLQueryItem(name: "queryText", value: term),
                URLQueryItem(name: "date", value: isoDateString),
                URLQueryItem(name: "time", value: isoTimeString),
                URLQueryItem(name: "partySize", value: "\(partySize)"),
            ]
            return c.url
        case "quandoo":
            var c = URLComponents(string: "https://www.quandoo.com/en/search")!
            c.queryItems = [
                URLQueryItem(name: "query", value: term),
                URLQueryItem(name: "date", value: isoDateString),
                URLQueryItem(name: "time", value: isoTimeString),
                URLQueryItem(name: "pax", value: "\(partySize)"),
            ]
            return c.url
        case "tablecheck":
            var c = URLComponents(string: "https://www.tablecheck.com/en/search")!
            c.queryItems = [
                URLQueryItem(name: "query", value: term),
                URLQueryItem(name: "date", value: isoDateString),
                URLQueryItem(name: "time", value: isoTimeString),
                URLQueryItem(name: "pax", value: "\(partySize)"),
            ]
            return c.url
        case "eatapp":
            var c = URLComponents(string: "https://eat.app/search")!
            c.queryItems = [URLQueryItem(name: "q", value: term)]
            return c.url
        case "chope":
            let slug = chopeCitySlugFromAddress(address)
            var c = URLComponents(string: "https://www.chope.co/\(slug)-restaurants")!
            c.queryItems = [URLQueryItem(name: "query", value: term)]
            return c.url
        case "tabelog":
            let area = tabelogAreaSlugFromAddress(address)
            return URL(string: "https://tabelog.com/en/\(area)/rstLst/?vs=1&sk=\(term)")
        case "swiggy":
            var c = URLComponents(string: "https://www.swiggy.com/dineout")!
            c.queryItems = [URLQueryItem(name: "query", value: term)]
            return c.url
        case "district":
            var c = URLComponents(string: "https://www.district.in/dine")!
            c.queryItems = [URLQueryItem(name: "q", value: term)]
            return c.url
        case "thechefz":
            var c = URLComponents(string: "https://thechefz.co/en/search")!
            c.queryItems = [URLQueryItem(name: "q", value: term)]
            return c.url
        case "eatigo":
            let path = eatigoPathFromAddress(address)
            return URL(string: "https://eatigo.com/\(path)/en?search=\(term)")
        case "tripadvisor":
            var c = URLComponents(string: "https://www.tripadvisor.com/Search")!
            c.queryItems = [URLQueryItem(name: "q", value: "\(searchTerm) restaurant")]
            return c.url
        case "firsttable":
            let isNz = address.map { let l = $0.lowercased(); return l.contains("zealand") || l.contains("auckland") || l.contains("wellington") } ?? true
            let base = isNz ? "https://www.firsttable.co.nz" : "https://www.firsttable.com.au"
            var c = URLComponents(string: "\(base)/search")!
            c.queryItems = [URLQueryItem(name: "q", value: term)]
            return c.url
        case "zomato":
            let city = address?.split(separator: ",").dropLast().last.map(String.init)?.trimmingCharacters(in: .whitespaces).lowercased().replacingOccurrences(of: " ", with: "-") ?? "mumbai"
            var c = URLComponents(string: "https://www.zomato.com/\(city)/restaurants")!
            c.queryItems = [URLQueryItem(name: "q", value: term)]
            return c.url
        default: return nil
        }
    }
    
    private func isOpenTableOrResy(_ urlString: String) -> Bool {
        let lower = urlString.lowercased()
        return lower.contains("opentable.com") || lower.contains("resy.com")
    }
    
    private func reservationPlatformLabel(_ urlString: String) -> String {
        let lower = urlString.lowercased()
        if lower.contains("opentable.com") { return "Reserve on OpenTable" }
        if lower.contains("resy.com") { return "Reserve on Resy" }
        return "Make reservation"
    }
    
    private func submitReservation() {
        isSubmitting = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            isSubmitting = false
            withAnimation(.spring(response: 0.5)) {
                showConfirmation = true
            }
        }
    }
}

// MARK: - Platform brand icon (Simple Icons CDN per region, fallback initial when missing)
private struct ReservationPlatformIconView: View {
    let platformId: String
    let platformName: String
    
    private static let iconSlugs: [String: String] = [
        "opentable": "opentable",
        "resy": "resy",
        "thefork": "thefork",
        "quandoo": "quandoo",
        "tabelog": "tabelog",
        "tripadvisor": "tripadvisor",
        "zomato": "zomato",
        "tablecheck": "tablecheck",
        "swiggy": "swiggy",
        "district": "district",
        "eatapp": "eatapp",
        "thechefz": "thechefz",
        "chope": "chope",
        "eatigo": "eatigo",
        "firsttable": "firsttable",
    ]
    private static let iconColors: [String: String] = [
        "opentable": "DA3741",
        "resy": "2D2D2D",
        "thefork": "F05537",
        "quandoo": "00A0DC",
        "tabelog": "E60012",
        "tripadvisor": "34E0A1",
        "zomato": "E23744",
        "tablecheck": "0D9488",
        "swiggy": "FC8019",
        "district": "334155",
        "eatapp": "212121",
        "thechefz": "E31937",
        "chope": "E31937",
        "eatigo": "EE2E24",
        "firsttable": "E31937",
    ]
    
    var body: some View {
        Group {
            if let slug = Self.iconSlugs[platformId], let hex = Self.iconColors[platformId],
               let url = URL(string: "https://cdn.simpleicons.org/\(slug)/\(hex)") {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    case .failure, .empty:
                        fallbackView
                    @unknown default:
                        fallbackView
                    }
                }
                .frame(width: 24, height: 24)
            } else {
                fallbackView
            }
        }
        .frame(width: 40, height: 40)
        .background(Color.luxuryMaroonLight)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.luxuryGold.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var fallbackView: some View {
        Text(String(platformName.prefix(1)))
            .font(Font.inter(16, weight: .bold))
            .foregroundColor(Color.luxuryGold)
    }
}

// MARK: - Time Chip
struct TimeChip: View {
    let time: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(time)
                .font(Font.inter(13, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? Color.luxuryMaroon : Color.luxuryCream)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(
                    isSelected ? LinearGradient.goldShimmer : LinearGradient(colors: [Color.luxuryMaroonLight], startPoint: .top, endPoint: .bottom)
                )
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isSelected ? Color.clear : Color.luxuryGold.opacity(0.3), lineWidth: 1)
                )
        }
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Reservation Detail Row
struct ReservationDetailRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .foregroundColor(Color.luxuryGold)
                .frame(width: 20)
            
            Text(label)
                .font(Font.inter(14, weight: .regular))
                .foregroundColor(Color.luxuryMuted)
            
            Spacer()
            
            Text(value)
                .font(Font.playfair(15, weight: .semibold))
                .foregroundColor(Color.luxuryCream)
        }
    }
}

#Preview {
    ReservationWidgetView(
        venueName: "Carbone",
        venueType: "Italian Restaurant",
        address: "181 Thompson St, New York",
        phoneNumber: "212-254-3000"
    )
}
