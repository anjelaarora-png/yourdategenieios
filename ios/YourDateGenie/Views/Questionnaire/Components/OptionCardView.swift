import SwiftUI

// MARK: - Section Header (one question per group)
/// Emoji are no longer shown (Final design: text-led questions); the parameter is kept
/// so existing call sites compile.
struct SectionHeader: View {
    var emoji: String = ""
    let title: String
    var subtitle: String? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .ydgText(.callout, weight: .semibold)
                .accessibilityAddTraits(.isHeader)
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .ydgText(.footnote, color: .ydgTextSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Shared option surface styling (raised, gold when selected)
private struct QuestionnaireOptionSurface: ViewModifier {
    let isSelected: Bool
    var cornerRadius: CGFloat = YDGRadius.card

    func body(content: Content) -> some View {
        content
            .background(
                isSelected ? Color.ydgAccentSubtle : Color.ydgRaised,
                in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(isSelected ? Color.ydgAccent : Color.ydgBorder, lineWidth: isSelected ? 1.5 : 1)
            )
    }
}

private extension View {
    func questionnaireOptionSurface(isSelected: Bool, cornerRadius: CGFloat = YDGRadius.card) -> some View {
        modifier(QuestionnaireOptionSurface(isSelected: isSelected, cornerRadius: cornerRadius))
    }
}

// MARK: - Option Card View (Grid selection: title, optional description, check when selected)
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
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(item.label)
                        .ydgText(.subhead, weight: .semibold, color: isSelected ? .ydgAccent : .ydgTextPrimary)
                        .multilineTextAlignment(.leading)
                        // A single long word ("Anniversary") shrinks rather than breaking mid-word.
                        .lineLimit(item.label.contains(" ") ? 2 : 1)
                        .minimumScaleFactor(0.75)
                    Spacer(minLength: 0)
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 17))
                            .foregroundColor(Color.ydgAccent)
                    }
                }
                if let desc = item.desc, !desc.isEmpty {
                    Text(desc)
                        .ydgText(.footnote, color: .ydgTextSecondary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 40, alignment: .leading)
            .padding(.horizontal, YDGSpace.sm + 2)
            .padding(.vertical, YDGSpace.sm + 2)
            .questionnaireOptionSurface(isSelected: isSelected)
            .contentShape(Rectangle())
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Chip Option View (Flow layout chips; same look as YDGChip)
struct ChipOptionView: View {
    let item: OptionItem
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(item.label)
                .font(.ydg(.subhead, weight: isSelected ? .semibold : .medium))
                .foregroundColor(isSelected ? Color.ydgAccent : Color.ydgTextPrimary)
                .lineLimit(1)
                .padding(.horizontal, 14)
                .frame(minHeight: 40)
                .questionnaireOptionSurface(isSelected: isSelected, cornerRadius: 20)
                .contentShape(Capsule())
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityAddTraits(isSelected ? .isSelected : [])
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
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.label)
                        .ydgText(.headline, color: isSelected ? .ydgAccent : .ydgTextPrimary)
                    
                    if let desc = item.desc {
                        Text(desc)
                            .ydgText(.footnote, color: .ydgTextSecondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundColor(isSelected ? Color.ydgAccent : Color.ydgTextTertiary)
            }
            .padding(.horizontal, YDGSpace.md)
            .frame(minHeight: 56)
            .questionnaireOptionSurface(isSelected: isSelected)
            .contentShape(Rectangle())
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityAddTraits(isSelected ? .isSelected : [])
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
                        .foregroundColor(Color.ydgTextSecondary)
                }
                Text(title)
                    .ydgText(.callout, weight: .semibold)
            }
            
            TextField("", text: $text, prompt: Text(placeholder).foregroundColor(Color.ydgTextTertiary))
                .font(.ydg(.body))
                .foregroundColor(Color.ydgTextPrimary)
                .padding(.horizontal, YDGSpace.md)
                .frame(minHeight: 52)
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
                    .ydgText(.callout, weight: .semibold)
                
                Spacer()
                
                Text(valueLabel.isEmpty ? "\(Int(value))" : valueLabel)
                    .font(.ydg(.subhead, weight: .semibold))
                    .foregroundColor(Color.ydgTextPrimary)
                    .monospacedDigit()
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
                    .ydgText(.callout, weight: .semibold)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .ydgText(.footnote, color: .ydgTextSecondary)
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
