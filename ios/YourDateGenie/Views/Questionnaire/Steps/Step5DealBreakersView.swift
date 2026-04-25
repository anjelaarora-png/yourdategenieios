import SwiftUI

struct Step5DealBreakersView: View {
    @Binding var data: QuestionnaireData
    var isPreferencesOnly: Bool = false
    @State private var showDealBreakerHelp = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                StepHelpCard(
                    isExpanded: $showDealBreakerHelp,
                    hint: "What counts as a deal-breaker?",
                    explanation: "Deal-breakers are things that would make a date uncomfortable — like food allergies, mobility needs, or places you want to avoid. Only used to filter out bad matches."
                )

                // Info banner
                HStack(spacing: 12) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.brandGold)
                    Text("This step is optional but helps us avoid any no-go's")
                        .font(.system(size: 14))
                        .foregroundColor(Color.luxuryMuted)
                }
                .padding(16)
                .background(Color.brandGold.opacity(0.1))
                .cornerRadius(12)
                
                // Allergies
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(
                        emoji: "⚠️",
                        title: "Any food allergies?",
                        subtitle: "Safety first"
                    )
                    
                    FlowLayout(spacing: 10) {
                        ForEach(QuestionnaireOptions.allergies) { allergy in
                            ChipOptionView(
                                item: allergy,
                                isSelected: data.allergies.contains(allergy.value),
                                onTap: {
                                    if allergy.value == "none" {
                                        data.allergies = ["none"]
                                    } else {
                                        data.allergies.removeAll { $0 == "none" }
                                        toggleSelection(allergy.value, in: &data.allergies)
                                    }
                                }
                            )
                        }
                    }
                }
                
                // Hard No's
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(
                        emoji: "🚫",
                        title: "Any hard no's?",
                        subtitle: "Things to definitely avoid"
                    )
                    
                    FlowLayout(spacing: 10) {
                        ForEach(QuestionnaireOptions.hardNos) { hardNo in
                            ChipOptionView(
                                item: hardNo,
                                isSelected: data.hardNos.contains(hardNo.value),
                                onTap: {
                                    toggleSelection(hardNo.value, in: &data.hardNos)
                                }
                            )
                        }
                    }
                }
                
                if !isPreferencesOnly {
                // Additional Notes
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(
                        emoji: "📝",
                        title: "Anything else we should know?",
                        subtitle: "Special requests or considerations"
                    )
                    
                    TextEditor(text: $data.additionalNotes)
                        .frame(minHeight: 100)
                        .padding(12)
                        .scrollContentBackground(.hidden)
                        .foregroundColor(Color.luxuryCream)
                        .background(Color.luxuryMaroonLight)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.luxuryGold.opacity(0.3), lineWidth: 1)
                        )
                        .overlay(
                            Group {
                                if data.additionalNotes.isEmpty {
                                    Text("E.g., Partner has a bad knee, prefer quieter venues, celebrating a promotion...")
                                        .foregroundColor(Color.luxuryMuted)
                                        .padding(16)
                                        .allowsHitTesting(false)
                                }
                            },
                            alignment: .topLeading
                        )
                }
                } // end if !isPreferencesOnly
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
    Step5DealBreakersView(data: .constant(QuestionnaireData()), isPreferencesOnly: false)
        .background(Color.luxuryMaroon)
}
