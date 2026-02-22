import SwiftUI

struct GiftFinderView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedBudget: String = ""
    @State private var selectedInterests: [String] = []
    @State private var recipientType: String = "partner"
    @State private var isLoading = false
    @State private var suggestions: [GiftSuggestion] = []
    
    let budgets = [
        ("thoughtful", "Under $50", "$"),
        ("moderate", "$50-150", "$$"),
        ("special", "$150-300", "$$$"),
        ("luxury", "$300+", "$$$$"),
    ]
    
    let interests = [
        ("tech", "Tech", "💻"),
        ("fashion", "Fashion", "👗"),
        ("sports", "Sports", "⚽"),
        ("books", "Books", "📚"),
        ("music", "Music", "🎵"),
        ("art", "Art", "🎨"),
        ("cooking", "Cooking", "👨‍🍳"),
        ("travel", "Travel", "✈️"),
        ("fitness", "Fitness", "💪"),
        ("gaming", "Gaming", "🎮"),
        ("nature", "Nature", "🌿"),
        ("movies", "Movies", "🎬"),
    ]
    
    let recipients = [
        ("partner", "My Partner", "💕"),
        ("date", "My Date", "🌹"),
        ("myself", "Myself", "✨"),
        ("both", "Both of Us", "💑"),
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("🎁")
                            .font(.system(size: 48))
                        Text("Gift Finder")
                            .font(.custom("Cormorant-Bold", size: 28, relativeTo: .title))
                            .foregroundColor(Color(UIColor.label))
                        Text("Find the perfect gift based on their interests")
                            .font(.system(size: 15))
                            .foregroundColor(Color(UIColor.secondaryLabel))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    
                    // Recipient
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Who is this gift for?")
                            .font(.system(size: 16, weight: .semibold))
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            ForEach(recipients, id: \.0) { recipient in
                                RecipientCard(
                                    value: recipient.0,
                                    label: recipient.1,
                                    emoji: recipient.2,
                                    isSelected: recipientType == recipient.0,
                                    onTap: { recipientType = recipient.0 }
                                )
                            }
                        }
                    }
                    
                    // Budget
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Gift budget")
                            .font(.system(size: 16, weight: .semibold))
                        
                        HStack(spacing: 10) {
                            ForEach(budgets, id: \.0) { budget in
                                BudgetPill(
                                    value: budget.0,
                                    label: budget.2,
                                    desc: budget.1,
                                    isSelected: selectedBudget == budget.0,
                                    onTap: { selectedBudget = budget.0 }
                                )
                            }
                        }
                    }
                    
                    // Interests
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Their interests")
                            .font(.system(size: 16, weight: .semibold))
                        
                        FlowLayout(spacing: 8) {
                            ForEach(interests, id: \.0) { interest in
                                InterestChip(
                                    value: interest.0,
                                    label: interest.1,
                                    emoji: interest.2,
                                    isSelected: selectedInterests.contains(interest.0),
                                    onTap: {
                                        if selectedInterests.contains(interest.0) {
                                            selectedInterests.removeAll { $0 == interest.0 }
                                        } else {
                                            selectedInterests.append(interest.0)
                                        }
                                    }
                                )
                            }
                        }
                    }
                    
                    // Generate Button
                    Button {
                        generateSuggestions()
                    } label: {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "sparkles")
                            }
                            Text(isLoading ? "Finding gifts..." : "Find Gift Ideas")
                        }
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            (!selectedBudget.isEmpty && !selectedInterests.isEmpty)
                                ? LinearGradient.goldGradient
                                : LinearGradient(colors: [Color.gray.opacity(0.5)], startPoint: .leading, endPoint: .trailing)
                        )
                        .cornerRadius(14)
                        .shadow(color: (!selectedBudget.isEmpty && !selectedInterests.isEmpty) ? Color.brandGold.opacity(0.4) : .clear, radius: 10, y: 4)
                    }
                    .disabled(selectedBudget.isEmpty || selectedInterests.isEmpty || isLoading)
                    .padding(.top, 8)
                    
                    // Suggestions Results
                    if !suggestions.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Gift Ideas")
                                .font(.system(size: 18, weight: .semibold))
                            
                            ForEach(suggestions) { gift in
                                GiftSuggestionCard(gift: gift)
                            }
                        }
                        .padding(.top, 16)
                    }
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
    
    private func generateSuggestions() {
        isLoading = true
        // Simulate API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            suggestions = [
                GiftSuggestion(
                    name: "Personalized Star Map",
                    description: "A custom print of the night sky from a special date",
                    priceRange: "$45-65",
                    whereToBuy: "Etsy, The Night Sky",
                    whyItFits: "Perfect for the romantic who loves meaningful keepsakes",
                    emoji: "⭐"
                ),
                GiftSuggestion(
                    name: "Couples Cooking Class",
                    description: "Learn to make a new cuisine together",
                    priceRange: "$80-120",
                    whereToBuy: "Sur La Table, Local cooking schools",
                    whyItFits: "Great for foodies who enjoy experiences",
                    emoji: "👨‍🍳"
                ),
                GiftSuggestion(
                    name: "Wireless Earbuds",
                    description: "High-quality audio for music lovers",
                    priceRange: "$100-150",
                    whereToBuy: "Apple, Amazon, Best Buy",
                    whyItFits: "Perfect for tech and music enthusiasts",
                    emoji: "🎧"
                ),
            ]
            isLoading = false
        }
    }
}

// MARK: - Supporting Views
struct RecipientCard: View {
    let value: String
    let label: String
    let emoji: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                Text(emoji)
                    .font(.system(size: 20))
                Text(label)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isSelected ? .white : Color(UIColor.label))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(isSelected ? Color.brandGold : Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.brandGold : Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct BudgetPill: View {
    let value: String
    let label: String
    let desc: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text(label)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(isSelected ? .white : .brandPrimary)
                Text(desc)
                    .font(.system(size: 10))
                    .foregroundColor(isSelected ? .white.opacity(0.8) : Color(UIColor.secondaryLabel))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? Color.brandGold : Color.white)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.brandGold : Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct InterestChip: View {
    let value: String
    let label: String
    let emoji: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Text(emoji)
                    .font(.system(size: 14))
                Text(label)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(isSelected ? .white : Color(UIColor.label))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.brandGold : Color.white)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.brandGold : Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct GiftSuggestionCard: View {
    let gift: GiftSuggestion
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(gift.emoji)
                    .font(.system(size: 32))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(gift.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(UIColor.label))
                    
                    Text(gift.priceRange)
                        .font(.system(size: 13))
                        .foregroundColor(.brandGold)
                }
                
                Spacer()
                
                Button {
                    // Open purchase link
                } label: {
                    Image(systemName: "arrow.up.right.square")
                        .font(.system(size: 20))
                        .foregroundColor(.brandPrimary)
                }
            }
            
            Text(gift.description)
                .font(.system(size: 14))
                .foregroundColor(Color(UIColor.secondaryLabel))
            
            HStack(spacing: 4) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.pink)
                Text(gift.whyItFits)
                    .font(.system(size: 12))
                    .foregroundColor(.pink)
                    .italic()
            }
            
            Text("Buy at: \(gift.whereToBuy)")
                .font(.system(size: 12))
                .foregroundColor(Color(UIColor.tertiaryLabel))
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 2)
    }
}

#Preview {
    GiftFinderView()
}
