import SwiftUI

struct ReservationWidgetView: View {
    let venueName: String
    let venueType: String
    var address: String?
    var phoneNumber: String?
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDate = Date()
    @State private var selectedTime = "7:00 PM"
    @State private var partySize = 2
    @State private var specialRequests = ""
    @State private var isSubmitting = false
    @State private var showConfirmation = false
    
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
                        HStack(spacing: 8) {
                            Image(systemName: "mappin.circle")
                                .foregroundColor(Color.luxuryGold.opacity(0.7))
                            Text(address)
                                .font(Font.inter(13, weight: .regular))
                                .foregroundColor(Color.luxuryMuted)
                        }
                    }
                }
                .padding(24)
                .frame(maxWidth: .infinity)
                .luxuryCard()
                .padding(.horizontal, 20)
                .padding(.top, 12)
                
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
                                .font(Font.cormorant(36, weight: .bold))
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
