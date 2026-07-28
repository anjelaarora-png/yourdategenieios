import SwiftUI

// MARK: - Section Header (questionnaire questions in display serif)
struct SectionHeader: View {
    var emoji: String = ""
    let title: String
    var subtitle: String? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                if !emoji.isEmpty {
                    Text(emoji)
                        .font(.system(size: 22))
                }
                
                Text(title)
                    .font(Font.bodySerif(22, weight: .regular))
                    .foregroundColor(Color.accentGold)
            }
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(Font.bodySans(14, weight: .regular))
                    .foregroundColor(Color.luxuryMuted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Shared option surface styling (Home / questionnaire parity)
private struct QuestionnaireOptionSurface: ViewModifier {
    let isSelected: Bool
    var cornerRadius: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .background {
                if isSelected {
                    LinearGradient.goldShimmer
                } else {
                    Color.luxeSurfaceTintStrong
                }
            }
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(isSelected ? Color.clear : Color.luxeSurfaceBorder, lineWidth: 1)
            )
            .shadow(color: isSelected ? Color.luxuryGold.opacity(0.25) : Color.clear, radius: 8, y: 4)
    }
}

private extension View {
    func questionnaireOptionSurface(isSelected: Bool, cornerRadius: CGFloat = 16) -> some View {
        modifier(QuestionnaireOptionSurface(isSelected: isSelected, cornerRadius: cornerRadius))
    }
}

// MARK: - Option Card View (Grid selection)
struct OptionCardView: View {
    let item: OptionItem
    let isSelected: Bool
    let onTap: () -> Void
    
    init(option: OptionItem, isSelected: Bool, onSelect: @escaping () -> Void) {
        self.item = option
        self.isSelected = isSelected
        self.onTap = onSelect
    }
    
    init(item: OptionItem, isSelected: Bool, onTap: @escaping () -> Void) {
        self.item = item
        self.isSelected = isSelected
        self.onTap = onTap
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                Text(item.emoji)
                    .font(.system(size: 34))
                
                Text(item.label)
                    .font(Font.bodySans(13, weight: .semibold))
                    .foregroundColor(isSelected ? Color.luxuryMaroon : Color.luxuryCream)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, minHeight: 100)
            .padding(.vertical, 16)
            .padding(.horizontal, 12)
            .questionnaireOptionSurface(isSelected: isSelected)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Chip Option View (Flow layout chips)
struct ChipOptionView: View {
    let item: OptionItem
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Text(item.emoji)
                    .font(.system(size: 16))
                
                Text(item.label)
                    .font(Font.bodySans(13, weight: isSelected ? .semibold : .medium))
                    .foregroundColor(isSelected ? Color.luxuryMaroon : Color.luxuryCream)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .questionnaireOptionSurface(isSelected: isSelected, cornerRadius: 20)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Multi-Select Option Card (List style)
struct MultiSelectOptionCard: View {
    let item: OptionItem
    let isSelected: Bool
    let onTap: () -> Void
    
    init(option: OptionItem, isSelected: Bool, onToggle: @escaping () -> Void) {
        self.item = option
        self.isSelected = isSelected
        self.onTap = onToggle
    }
    
    init(item: OptionItem, isSelected: Bool, onTap: @escaping () -> Void) {
        self.item = item
        self.isSelected = isSelected
        self.onTap = onTap
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                Text(item.emoji)
                    .font(.system(size: 26))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.label)
                        .font(Font.bodySans(13, weight: .semibold))
                        .foregroundColor(isSelected ? Color.luxuryMaroon : Color.luxuryCream)
                    
                    if let desc = item.desc {
                        Text(desc)
                            .font(Font.bodySans(10, weight: .regular))
                            .foregroundColor(isSelected ? Color.luxuryMaroon.opacity(0.7) : Color.luxuryMuted)
                    }
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? Color.luxuryMaroon : Color.luxuryMuted.opacity(0.4))
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .questionnaireOptionSurface(isSelected: isSelected)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Text Input Card
struct TextInputCard: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var icon: String? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .foregroundColor(Color.luxuryGold)
                }
                Text(title)
                    .font(Font.bodySerif(16, weight: .regular))
                    .foregroundColor(Color.luxuryCream)
            }
            
            TextField(placeholder, text: $text)
                .font(Font.bodySans(15, weight: .regular))
                .foregroundColor(Color.luxuryCream)
                .padding(16)
                .luxeInsetSurface(cornerRadius: 14)
        }
    }
}

// MARK: - Slider Input Card
struct SliderInputCard: View {
    let title: String
    var emoji: String = ""
    @Binding var value: Double
    var range: ClosedRange<Double> = 0...100
    var step: Double = 1
    var valueLabel: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                if !emoji.isEmpty {
                    Text(emoji)
                        .font(.system(size: 20))
                }
                Text(title)
                    .font(Font.bodySerif(16, weight: .regular))
                    .foregroundColor(Color.luxuryCream)
                
                Spacer()
                
                Text(valueLabel.isEmpty ? "\(Int(value))" : valueLabel)
                    .font(Font.bodySans(14, weight: .semibold))
                    .foregroundColor(Color.luxuryGold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.luxuryGold.opacity(0.15))
                    .cornerRadius(8)
            }
            
            Slider(value: $value, in: range, step: step)
                .tint(Color.luxuryGold)
        }
        .padding(18)
        .questionnaireInsetSurface(cornerRadius: 16)
    }
}

// MARK: - Toggle Option Card
struct ToggleOptionCard: View {
    let title: String
    var emoji: String = ""
    var subtitle: String? = nil
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: 14) {
            if !emoji.isEmpty {
                Text(emoji)
                    .font(.system(size: 26))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(Font.bodySerif(16, weight: .regular))
                    .foregroundColor(Color.luxuryCream)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(Font.bodySans(12, weight: .regular))
                        .foregroundColor(Color.luxuryMuted)
                }
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .tint(Color.luxuryGold)
                .labelsHidden()
        }
        .questionnaireInsetSurface(cornerRadius: 16)
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        Color.backgroundPrimary.ignoresSafeArea()
        
        ScrollView {
            VStack(spacing: 20) {
                SectionHeader(
                    emoji: "⚡",
                    title: "What's the energy?",
                    subtitle: "Set the pace for your date"
                )
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    OptionCardView(
                        item: OptionItem(value: "romantic", label: "Romantic", emoji: "🌹"),
                        isSelected: true,
                        onTap: {}
                    )
                    
                    OptionCardView(
                        item: OptionItem(value: "fun", label: "Fun & Playful", emoji: "🎉"),
                        isSelected: false,
                        onTap: {}
                    )
                }
                
                SectionHeader(emoji: "🎯", title: "Activities")
                
                HStack(spacing: 10) {
                    ChipOptionView(
                        item: OptionItem(value: "hiking", label: "Hiking", emoji: "🥾"),
                        isSelected: true,
                        onTap: {}
                    )
                    
                    ChipOptionView(
                        item: OptionItem(value: "movies", label: "Movies", emoji: "🎬"),
                        isSelected: false,
                        onTap: {}
                    )
                }
                
                SectionHeader(emoji: "🍽️", title: "Cuisine")
                
                MultiSelectOptionCard(
                    item: OptionItem(value: "italian", label: "Italian", emoji: "🍝", desc: "Pasta, pizza, and more"),
                    isSelected: true,
                    onTap: {}
                )
                
                MultiSelectOptionCard(
                    item: OptionItem(value: "sushi", label: "Japanese", emoji: "🍣", desc: "Sushi and ramen"),
                    isSelected: false,
                    onTap: {}
                )
            }
            .padding(20)
        }
    }
}
