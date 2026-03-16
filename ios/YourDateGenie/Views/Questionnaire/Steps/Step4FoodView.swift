import SwiftUI

struct Step4FoodView: View {
    @Binding var data: QuestionnaireData
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                // Budget
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(
                        emoji: "💰",
                        title: "What's your budget?",
                        subtitle: "Total for the date"
                    )
                    
                    HStack(spacing: 12) {
                        ForEach(QuestionnaireOptions.budgetRanges) { budget in
                            BudgetCard(
                                item: budget,
                                isSelected: data.budgetRange == budget.value,
                                onTap: { data.budgetRange = budget.value }
                            )
                        }
                    }
                }
                
                // Cuisines
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(
                        emoji: "🍽️",
                        title: "Cuisine preferences?",
                        subtitle: "Select all that sound good"
                    )
                    
                    FlowLayout(spacing: 10) {
                        ForEach(QuestionnaireOptions.cuisines) { cuisine in
                            ChipOptionView(
                                item: cuisine,
                                isSelected: data.cuisinePreferences.contains(cuisine.value),
                                onTap: {
                                    toggleSelection(cuisine.value, in: &data.cuisinePreferences)
                                }
                            )
                        }
                    }
                }
                
                // Dietary Restrictions
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(
                        emoji: "🥗",
                        title: "Any dietary restrictions?",
                        subtitle: "We'll filter venues accordingly"
                    )
                    
                    FlowLayout(spacing: 10) {
                        ForEach(QuestionnaireOptions.dietaryRestrictions) { diet in
                            ChipOptionView(
                                item: diet,
                                isSelected: data.dietaryRestrictions.contains(diet.value),
                                onTap: {
                                    if diet.value == "none" {
                                        data.dietaryRestrictions = ["none"]
                                    } else {
                                        data.dietaryRestrictions.removeAll { $0 == "none" }
                                        toggleSelection(diet.value, in: &data.dietaryRestrictions)
                                    }
                                }
                            )
                        }
                    }
                }
                
                // Drink Preferences (multi-select)
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(emoji: "🍷", title: "Preferred beverages? (pick any)")
                    
                    FlowLayout(spacing: 10) {
                        ForEach(QuestionnaireOptions.drinkPreferences) { drink in
                            ChipOptionView(
                                item: drink,
                                isSelected: data.drinkPreferences.contains(drink.value),
                                onTap: { toggleSelection(drink.value, in: &data.drinkPreferences) }
                            )
                        }
                    }
                }
            }
            .padding(20)
        }
    }
    
    private func toggleSelection(_ value: String, in array: inout [String]) {
        if let index = array.firstIndex(of: value) {
            array.remove(at: index)
        } else {
            array.append(value)
        }
    }
}

// MARK: - Budget Card
struct BudgetCard: View {
    let item: OptionItem
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                Text(item.label)
                    .font(Font.inter(13, weight: .semibold))
                    .foregroundColor(isSelected ? Color.luxuryMaroon : Color.luxuryCream)
                
                if let desc = item.desc {
                    Text(desc)
                        .font(Font.inter(10, weight: .regular))
                        .foregroundColor(isSelected ? Color.luxuryMaroon.opacity(0.8) : Color.luxuryMuted)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                isSelected ? LinearGradient.goldShimmer : LinearGradient(colors: [Color.luxuryMaroonLight], startPoint: .top, endPoint: .bottom)
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.clear : Color.luxuryGold.opacity(0.3), lineWidth: isSelected ? 2 : 1)
            )
            .shadow(color: isSelected ? Color.brandGold.opacity(0.3) : Color.clear, radius: 6, y: 3)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

#Preview {
    Step4FoodView(data: .constant(QuestionnaireData()))
        .background(Color.luxuryMaroon)
}
