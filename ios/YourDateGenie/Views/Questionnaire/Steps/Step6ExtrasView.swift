import SwiftUI

struct Step6ExtrasView: View {
    @Binding var data: QuestionnaireData
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                // Info banner
                HStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .foregroundColor(.brandGold)
                    Text("Optional extras to make your date extra special")
                        .font(.system(size: 14))
                        .foregroundColor(Color.luxuryMuted)
                }
                .padding(16)
                .background(Color.brandGold.opacity(0.1))
                .cornerRadius(12)
                
                // Gift Suggestions Toggle
                VStack(alignment: .leading, spacing: 12) {
                    Toggle(isOn: $data.wantGiftSuggestions) {
                        HStack(spacing: 12) {
                            Text("🎁")
                                .font(.system(size: 24))
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Gift Suggestions")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(Color.luxuryCream)
                                Text("Get personalized gift ideas")
                                    .font(.system(size: 13))
                                    .foregroundColor(Color.luxuryMuted)
                            }
                        }
                    }
                    .toggleStyle(SwitchToggleStyle(tint: .brandGold))
                    .padding(16)
                    .background(Color.luxuryMaroonLight)
                    .cornerRadius(12)
                    
                    if data.wantGiftSuggestions {
                        // Partner Interests
                        VStack(alignment: .leading, spacing: 8) {
                            Text("What are they into?")
                                .font(Font.inter(14, weight: .medium))
                                .foregroundColor(Color.luxuryCream)
                            
                            FlowLayout(spacing: 8) {
                                ForEach(QuestionnaireOptions.partnerInterests) { interest in
                                    ChipOptionView(
                                        item: interest,
                                        isSelected: data.partnerInterests.contains(interest.value),
                                        onTap: {
                                            toggleSelection(interest.value, in: &data.partnerInterests)
                                        }
                                    )
                                }
                            }
                        }
                        .padding(16)
                        .background(Color.luxuryMaroonLight.opacity(0.6))
                        .cornerRadius(12)
                    }
                }
                
                // Conversation Starters Toggle
                VStack(alignment: .leading, spacing: 12) {
                    Toggle(isOn: $data.wantConversationStarters) {
                        HStack(spacing: 12) {
                            Text("💬")
                                .font(.system(size: 24))
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Conversation Starters")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(Color.luxuryCream)
                                Text("Never have awkward silences")
                                    .font(.system(size: 13))
                                    .foregroundColor(Color.luxuryMuted)
                            }
                        }
                    }
                    .toggleStyle(SwitchToggleStyle(tint: .brandGold))
                    .padding(16)
                    .background(Color.luxuryMaroonLight)
                    .cornerRadius(12)
                    
                    if data.wantConversationStarters {
                        // Relationship Stage
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Relationship stage")
                                .font(Font.inter(14, weight: .medium))
                                .foregroundColor(Color.luxuryCream)
                            
                            FlowLayout(spacing: 8) {
                                ForEach(QuestionnaireOptions.relationshipStages) { stage in
                                    ChipOptionView(
                                        item: stage,
                                        isSelected: data.relationshipStage == stage.value,
                                        onTap: { data.relationshipStage = stage.value }
                                    )
                                }
                            }
                        }
                        .padding(16)
                        .background(Color.luxuryMaroonLight.opacity(0.6))
                        .cornerRadius(12)
                        
                        // Conversation Topics
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Topics you'd like to explore")
                                .font(Font.inter(14, weight: .medium))
                                .foregroundColor(Color.luxuryCream)
                            
                            FlowLayout(spacing: 8) {
                                ForEach(QuestionnaireOptions.conversationTopics) { topic in
                                    ChipOptionView(
                                        item: topic,
                                        isSelected: data.conversationTopics.contains(topic.value),
                                        onTap: {
                                            toggleSelection(topic.value, in: &data.conversationTopics)
                                        }
                                    )
                                }
                            }
                        }
                        .padding(16)
                        .background(Color.luxuryMaroonLight.opacity(0.6))
                        .cornerRadius(12)
                    }
                }
                
                // Summary card
                VStack(alignment: .leading, spacing: 12) {
                    Text("✨ Ready to create your plan!")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color.luxuryGold)
                    
                    Text("Tap 'Create Plan' below and we'll generate a personalized date itinerary based on everything you've told us.")
                        .font(.system(size: 14))
                        .foregroundColor(Color.luxuryMuted)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.brandPrimary.opacity(0.05))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.brandPrimary.opacity(0.2), lineWidth: 1)
                )
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

#Preview {
    Step6ExtrasView(data: .constant(QuestionnaireData()))
        .background(Color.luxuryMaroon)
}
