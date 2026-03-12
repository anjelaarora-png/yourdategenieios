import SwiftUI

struct Step1LocationView: View {
    @Binding var data: QuestionnaireData
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                // Location Input
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(emoji: "📍", title: "Where are you planning?")
                    
                    PlacesAutocompleteField(
                        placeholder: "City or neighborhood",
                        text: $data.city,
                        mode: .city
                    )
                    
                    PlacesAutocompleteField(
                        placeholder: "Starting point (optional)",
                        text: $data.startingAddress,
                        mode: .address
                    )
                }
                
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
                            .font(Font.inter(14, weight: .medium))
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
            }
            .padding(20)
        }
        .onAppear {
            if data.timeOfDay.isEmpty {
                data.timeOfDay = "evening"
                data.startTime = "7:00 PM"
            }
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

#Preview {
    Step1LocationView(data: .constant(QuestionnaireData()))
        .background(Color.luxuryMaroon)
}
