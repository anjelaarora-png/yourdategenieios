import SwiftUI

struct Step2TransportationView: View {
    @Binding var data: QuestionnaireData
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                // Transportation Mode
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(
                        emoji: "🚗",
                        title: "How will you get around?",
                        subtitle: "Select your preferred transportation"
                    )
                    
                    VStack(spacing: 10) {
                        ForEach(QuestionnaireOptions.transportationModes) { mode in
                            MultiSelectOptionCard(
                                item: mode,
                                isSelected: data.transportationMode == mode.value,
                                onTap: { data.transportationMode = mode.value }
                            )
                        }
                    }
                }
                
                // Travel Radius
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(
                        emoji: "📍",
                        title: "How far are you willing to travel?",
                        subtitle: "Select your comfort zone"
                    )
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ForEach(QuestionnaireOptions.travelRadius) { radius in
                            TravelRadiusCard(
                                item: radius,
                                isSelected: data.travelRadius == radius.value,
                                onTap: { data.travelRadius = radius.value }
                            )
                        }
                    }
                }
            }
            .padding(20)
        }
    }
}

// MARK: - Travel Radius Card
struct TravelRadiusCard: View {
    let item: OptionItem
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Text(item.emoji)
                    .font(.system(size: 28))
                
                Text(item.label)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(isSelected ? .white : Color(UIColor.label))
                
                if let distance = item.distance {
                    Text(distance)
                        .font(.system(size: 12))
                        .foregroundColor(isSelected ? .white.opacity(0.8) : Color(UIColor.secondaryLabel))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isSelected ? Color.brandGold : Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.brandGold : Color.gray.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: isSelected ? Color.brandGold.opacity(0.3) : Color.clear, radius: 6, y: 3)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

#Preview {
    Step2TransportationView(data: .constant(QuestionnaireData()))
        .background(Color.luxuryMaroon)
}
