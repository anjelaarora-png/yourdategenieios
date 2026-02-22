import SwiftUI

struct Step5DealBreakersView: View {
    @Binding var data: QuestionnaireData
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                // Info banner
                HStack(spacing: 12) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.brandGold)
                    Text("This step is optional but helps us avoid any no-go's")
                        .font(.system(size: 14))
                        .foregroundColor(Color(UIColor.secondaryLabel))
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
                        .background(Color.white)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                        .overlay(
                            Group {
                                if data.additionalNotes.isEmpty {
                                    Text("E.g., Partner has a bad knee, prefer quieter venues, celebrating a promotion...")
                                        .foregroundColor(Color(UIColor.placeholderText))
                                        .padding(16)
                                        .allowsHitTesting(false)
                                }
                            },
                            alignment: .topLeading
                        )
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

#Preview {
    Step5DealBreakersView(data: .constant(QuestionnaireData()))
        .background(Color.brandCream)
}
