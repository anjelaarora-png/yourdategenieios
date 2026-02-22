import SwiftUI

struct Step1LocationView: View {
    @Binding var data: QuestionnaireData
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                // Location Input
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(emoji: "📍", title: "Where are you planning?")
                    
                    TextField("City or neighborhood", text: $data.city)
                        .textFieldStyle(CustomTextFieldStyle())
                    
                    TextField("Starting point (optional)", text: $data.startingAddress)
                        .textFieldStyle(CustomTextFieldStyle())
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
                                onTap: { data.dateType = type.value },
                                compact: true
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
                                onTap: { data.occasion = occasion.value },
                                compact: true
                            )
                        }
                    }
                }
                
                // Date & Time Picker
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(emoji: "📅", title: "When?", subtitle: "Optional")
                    
                    HStack(spacing: 12) {
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
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.white)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                        
                        // Time Picker
                        Picker("Time", selection: $data.startTime) {
                            Text("Time").tag("")
                            ForEach(timeOptions, id: \.self) { time in
                                Text(time).tag(time)
                            }
                        }
                        .pickerStyle(.menu)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.white)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                    }
                }
            }
            .padding(20)
        }
    }
    
    private var timeOptions: [String] {
        ["6:00 PM", "6:30 PM", "7:00 PM", "7:30 PM", "8:00 PM", "8:30 PM", "9:00 PM", "9:30 PM", "10:00 PM"]
    }
}

// MARK: - Custom TextField Style
struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
    }
}

#Preview {
    Step1LocationView(data: .constant(QuestionnaireData()))
        .background(Color.brandCream)
}
