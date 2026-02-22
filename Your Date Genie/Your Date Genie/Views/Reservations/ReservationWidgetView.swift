import SwiftUI

struct ReservationWidgetView: View {
    let venueName: String
    let venueType: String
    var address: String?
    var phoneNumber: String?
    var websiteUrl: String?
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDate = Date()
    @State private var selectedTime = "7:00 PM"
    @State private var partySize = 2
    @State private var specialRequests = ""
    
    let timeSlots = [
        "5:00 PM", "5:30 PM", "6:00 PM", "6:30 PM",
        "7:00 PM", "7:30 PM", "8:00 PM", "8:30 PM",
        "9:00 PM", "9:30 PM", "10:00 PM"
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Venue Header
                    venueHeader
                    
                    // Quick Actions
                    quickActions
                    
                    // Reservation Form
                    reservationForm
                    
                    // Booking Options
                    bookingOptions
                }
                .padding(20)
            }
            .background(Color.brandCream)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.brandPrimary)
                }
            }
        }
    }
    
    private var venueHeader: some View {
        VStack(spacing: 12) {
            // Venue icon
            ZStack {
                Circle()
                    .fill(Color.brandGold.opacity(0.15))
                    .frame(width: 72, height: 72)
                
                Image(systemName: venueIcon)
                    .font(.system(size: 32))
                    .foregroundColor(.brandGold)
            }
            
            Text(venueName)
                .font(.custom("Cormorant-Bold", size: 24, relativeTo: .title))
                .foregroundColor(Color(UIColor.label))
                .multilineTextAlignment(.center)
            
            Text(venueType)
                .font(.system(size: 15))
                .foregroundColor(Color(UIColor.secondaryLabel))
            
            if let address = address {
                HStack(spacing: 6) {
                    Image(systemName: "mappin")
                        .font(.system(size: 12))
                    Text(address)
                        .font(.system(size: 13))
                }
                .foregroundColor(Color(UIColor.tertiaryLabel))
            }
        }
    }
    
    private var quickActions: some View {
        HStack(spacing: 12) {
            if let phone = phoneNumber {
                QuickActionCard(icon: "phone.fill", title: "Call", color: .green) {
                    if let url = URL(string: "tel://\(phone.replacingOccurrences(of: " ", with: ""))") {
                        UIApplication.shared.open(url)
                    }
                }
            }
            
            QuickActionCard(icon: "map.fill", title: "Directions", color: .blue) {
                if let addr = address,
                   let encoded = addr.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                   let url = URL(string: "maps://?daddr=\(encoded)") {
                    UIApplication.shared.open(url)
                }
            }
            
            if let website = websiteUrl, let url = URL(string: website) {
                QuickActionCard(icon: "globe", title: "Website", color: .purple) {
                    UIApplication.shared.open(url)
                }
            }
        }
    }
    
    private var reservationForm: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Make a Reservation")
                .font(.system(size: 18, weight: .semibold))
            
            // Date Picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Date")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(UIColor.secondaryLabel))
                
                DatePicker("", selection: $selectedDate, in: Date()..., displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .padding(12)
                    .background(Color.white)
                    .cornerRadius(12)
            }
            
            // Time Picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Time")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(UIColor.secondaryLabel))
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(timeSlots, id: \.self) { time in
                            TimeSlotButton(
                                time: time,
                                isSelected: selectedTime == time,
                                onTap: { selectedTime = time }
                            )
                        }
                    }
                }
            }
            
            // Party Size
            VStack(alignment: .leading, spacing: 8) {
                Text("Party Size")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(UIColor.secondaryLabel))
                
                HStack(spacing: 12) {
                    ForEach(1...8, id: \.self) { size in
                        PartySizeButton(
                            size: size,
                            isSelected: partySize == size,
                            onTap: { partySize = size }
                        )
                    }
                }
            }
            
            // Special Requests
            VStack(alignment: .leading, spacing: 8) {
                Text("Special Requests (optional)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(UIColor.secondaryLabel))
                
                TextField("E.g., window seat, quiet corner...", text: $specialRequests)
                    .padding(12)
                    .background(Color.white)
                    .cornerRadius(12)
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.5))
        .cornerRadius(16)
    }
    
    private var bookingOptions: some View {
        VStack(spacing: 12) {
            Text("Book via")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(UIColor.secondaryLabel))
            
            HStack(spacing: 12) {
                BookingServiceButton(
                    name: "OpenTable",
                    color: Color(red: 0.85, green: 0.22, blue: 0.26)
                ) {
                    openBookingService(service: "opentable")
                }
                
                BookingServiceButton(
                    name: "Resy",
                    color: Color(red: 0.78, green: 0.65, blue: 0.35)
                ) {
                    openBookingService(service: "resy")
                }
                
                BookingServiceButton(
                    name: "Yelp",
                    color: Color(red: 0.83, green: 0.14, blue: 0.14)
                ) {
                    openBookingService(service: "yelp")
                }
            }
            
            // Or call directly
            if let phone = phoneNumber {
                Button {
                    if let url = URL(string: "tel://\(phone.replacingOccurrences(of: " ", with: ""))") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    HStack {
                        Image(systemName: "phone.fill")
                        Text("Call to reserve: \(phone)")
                    }
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.brandPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.brandPrimary.opacity(0.3), lineWidth: 1)
                    )
                }
            }
        }
    }
    
    private var venueIcon: String {
        switch venueType.lowercased() {
        case let t where t.contains("restaurant"): return "fork.knife"
        case let t where t.contains("bar"): return "wineglass"
        case let t where t.contains("cafe"), let t where t.contains("coffee"): return "cup.and.saucer"
        case let t where t.contains("rooftop"): return "building.2"
        default: return "mappin.circle"
        }
    }
    
    private func openBookingService(service: String) {
        let encodedName = venueName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        var urlString = ""
        
        switch service {
        case "opentable":
            urlString = "https://www.opentable.com/s?term=\(encodedName)"
        case "resy":
            urlString = "https://resy.com/cities/ny?query=\(encodedName)"
        case "yelp":
            urlString = "https://www.yelp.com/search?find_desc=\(encodedName)"
        default:
            break
        }
        
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Supporting Views
struct QuickActionCard: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                    .frame(width: 44, height: 44)
                    .background(color.opacity(0.1))
                    .cornerRadius(12)
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(UIColor.label))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.white)
            .cornerRadius(14)
            .shadow(color: Color.black.opacity(0.05), radius: 6, y: 2)
        }
    }
}

struct TimeSlotButton: View {
    let time: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(time)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .white : Color(UIColor.label))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(isSelected ? Color.brandGold : Color.white)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isSelected ? Color.brandGold : Color.gray.opacity(0.2), lineWidth: 1)
                )
        }
    }
}

struct PartySizeButton: View {
    let size: Int
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text("\(size)")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(isSelected ? .white : Color(UIColor.label))
                .frame(width: 36, height: 36)
                .background(isSelected ? Color.brandGold : Color.white)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? Color.brandGold : Color.gray.opacity(0.2), lineWidth: 1)
                )
        }
    }
}

struct BookingServiceButton: View {
    let name: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(name)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(color)
                .cornerRadius(12)
        }
    }
}

#Preview {
    ReservationWidgetView(
        venueName: "Trattoria Milano",
        venueType: "Italian Restaurant",
        address: "123 Main Street",
        phoneNumber: "(555) 123-4567"
    )
}
