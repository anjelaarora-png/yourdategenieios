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
                
                // Drink Preferences
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(emoji: "🍷", title: "Drink preferences?")
                    
                    FlowLayout(spacing: 10) {
                        ForEach(QuestionnaireOptions.drinkPreferences) { drink in
                            ChipOptionView(
                                item: drink,
                                isSelected: data.drinkPreferences == drink.value,
                                onTap: { data.drinkPreferences = drink.value }
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
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(isSelected ? .white : .brandPrimary)
                
                if let desc = item.desc {
                    Text(desc)
                        .font(.system(size: 11))
                        .foregroundColor(isSelected ? .white.opacity(0.8) : Color(UIColor.secondaryLabel))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isSelected ? Color.brandGold : Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.brandGold : Color.gray.opacity(0.2), lineWidth: isSelected ? 2 : 1)
            )
            .shadow(color: isSelected ? Color.brandGold.opacity(0.3) : Color.clear, radius: 6, y: 3)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

#Preview {
    Step4FoodView(data: .constant(QuestionnaireData()))
        .background(Color.brandCream)
}
