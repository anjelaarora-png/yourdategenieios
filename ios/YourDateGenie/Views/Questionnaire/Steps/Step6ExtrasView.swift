import SwiftUI

struct Step6ExtrasView: View {
    @Binding var data: QuestionnaireData
    var isPreferencesOnly: Bool = false

    private var loveLanguageSetBinding: Binding<Set<LoveLanguage>> {
        Binding(
            get: {
                Set((data.loveLanguageRaws ?? []).compactMap { LoveLanguage(rawValue: $0) })
            },
            set: { newVal in
                data.loveLanguageRaws = newVal.map(\.rawValue)
            }
        )
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                // You & partner (gender) – saved in settings
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(
                        emoji: "💑",
                        title: "You & your partner",
                        subtitle: "Saved to your profile for better personalization"
                    )
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your gender")
                            .font(Font.bodySans(14, weight: .medium))
                            .foregroundColor(Color.luxuryMuted)
                        FlowLayout(spacing: 8) {
                            ForEach(PreferenceOptions.genderOptions, id: \.value) { option in
                                ChipOptionView(
                                    item: option,
                                    isSelected: data.userGender == option.value,
                                    onTap: { data.userGender = option.value }
                                )
                            }
                        }
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Partner's gender")
                            .font(Font.bodySans(14, weight: .medium))
                            .foregroundColor(Color.luxuryMuted)
                        FlowLayout(spacing: 8) {
                            ForEach(PreferenceOptions.genderOptions, id: \.value) { option in
                                ChipOptionView(
                                    item: option,
                                    isSelected: data.partnerGender == option.value,
                                    onTap: { data.partnerGender = option.value }
                                )
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(
                        emoji: "💕",
                        title: "Your love languages",
                        subtitle: "Select all that resonate — we'll tailor plans to what makes you feel loved"
                    )
                    LoveLanguageSelector(selectedLanguages: loveLanguageSetBinding)
                }
                
                if !isPreferencesOnly {
                HStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .foregroundColor(Color.accentGold)
                    Text("Optional extras to make your date extra special")
                        .font(Font.bodySans(14, weight: .regular))
                        .foregroundColor(Color.luxuryMuted)
                }
                .padding(16)
                .background(Color.accentGold.opacity(0.08))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.accentGold.opacity(0.18), lineWidth: 1)
                )
                
                // Gift Suggestions Toggle
                VStack(alignment: .leading, spacing: 12) {
                    Toggle(isOn: $data.wantGiftSuggestions) {
                        HStack(spacing: 12) {
                            Text("🎁")
                                .font(.system(size: 24))
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Gift Suggestions")
                                    .font(Font.bodySans(16, weight: .semibold))
                                    .foregroundColor(Color.luxuryCream)
                                Text("Get personalized gift ideas")
                                    .font(Font.bodySans(13, weight: .regular))
                                    .foregroundColor(Color.luxuryMuted)
                            }
                        }
                    }
                    .toggleStyle(SwitchToggleStyle(tint: Color.accentGold))
                    .questionnaireInsetSurface()
                    
                    if data.wantGiftSuggestions {
                        GiftUnwrapView()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("What are they into?")
                                .font(Font.bodySans(15, weight: .semibold))
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
                                    .font(Font.bodySans(16, weight: .semibold))
                                    .foregroundColor(Color.luxuryCream)
                                Text("Never have awkward silences")
                                    .font(Font.bodySans(13, weight: .regular))
                                    .foregroundColor(Color.luxuryMuted)
                            }
                        }
                    }
                    .toggleStyle(SwitchToggleStyle(tint: Color.accentGold))
                    .questionnaireInsetSurface()
                    
                    if data.wantConversationStarters {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Relationship stage")
                                .font(Font.bodySans(15, weight: .semibold))
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
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Topics you'd like to explore")
                                .font(Font.bodySans(15, weight: .semibold))
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
                    }
                }
                } // end if !isPreferencesOnly
                
                // Summary card
                VStack(alignment: .leading, spacing: 12) {
                    if isPreferencesOnly {
                        Text("Save your preferences")
                            .font(Font.bodySans(16, weight: .semibold))
                            .foregroundColor(Color.accentGold)
                        Text("Tap 'Save preferences' below. No date plan will be generated.")
                            .font(Font.bodySans(14, weight: .regular))
                            .foregroundColor(Color.luxuryMuted)
                    } else {
                        Text("Ready to create your plan")
                            .font(Font.bodySans(16, weight: .semibold))
                            .foregroundColor(Color.accentGold)
                        Text("Tap Generate below — we'll build three personalized options from everything you've told us.")
                            .font(Font.bodySans(14, weight: .regular))
                            .foregroundColor(Color.luxuryMuted)
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.luxeSurfaceTintStrong)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.luxeSurfaceBorder, lineWidth: 1)
                )
            }
            .padding(20)
            .padding(.bottom, 24)
        }
        .scrollBounceBehavior(.basedOnSize)
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
        .background(Color.backgroundPrimary)
}
