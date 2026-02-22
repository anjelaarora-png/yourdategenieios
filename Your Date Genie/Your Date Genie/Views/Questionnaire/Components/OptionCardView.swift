import SwiftUI

struct OptionCardView: View {
    let item: OptionItem
    let isSelected: Bool
    let onTap: () -> Void
    var compact: Bool = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: compact ? 4 : 8) {
                Text(item.emoji)
                    .font(.system(size: compact ? 24 : 32))
                
                Text(item.label)
                    .font(.system(size: compact ? 12 : 14, weight: .medium))
                    .foregroundColor(isSelected ? .white : Color(UIColor.label))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                if let desc = item.desc, !compact {
                    Text(desc)
                        .font(.system(size: 11))
                        .foregroundColor(isSelected ? .white.opacity(0.8) : Color(UIColor.secondaryLabel))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
                
                if let time = item.time, !compact {
                    Text(time)
                        .font(.system(size: 10))
                        .foregroundColor(isSelected ? .white.opacity(0.7) : Color(UIColor.tertiaryLabel))
                }
                
                if let distance = item.distance, !compact {
                    Text(distance)
                        .font(.system(size: 10))
                        .foregroundColor(isSelected ? .white.opacity(0.7) : Color(UIColor.tertiaryLabel))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, compact ? 12 : 16)
            .padding(.horizontal, 8)
            .background(
                isSelected
                    ? AnyShapeStyle(LinearGradient.goldGradient)
                    : AnyShapeStyle(Color.white)
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.brandGold : Color.gray.opacity(0.2), lineWidth: isSelected ? 2 : 1)
            )
            .shadow(color: isSelected ? Color.brandGold.opacity(0.3) : Color.black.opacity(0.05), radius: isSelected ? 8 : 4, y: 2)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Multi-Select Option Card
struct MultiSelectOptionCard: View {
    let item: OptionItem
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Text(item.emoji)
                    .font(.system(size: 24))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.label)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(UIColor.label))
                    
                    if let desc = item.desc {
                        Text(desc)
                            .font(.system(size: 12))
                            .foregroundColor(Color(UIColor.secondaryLabel))
                    }
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundColor(isSelected ? .brandGold : Color.gray.opacity(0.4))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(isSelected ? Color.brandGold.opacity(0.1) : Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.brandGold : Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Chip Option View (for compact multi-select)
struct ChipOptionView: View {
    let item: OptionItem
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Text(item.emoji)
                    .font(.system(size: 16))
                Text(item.label)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(isSelected ? .white : Color(UIColor.label))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(isSelected ? Color.brandGold : Color.white)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? Color.brandGold : Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Section Header
struct SectionHeader: View {
    let emoji: String
    let title: String
    var subtitle: String? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Text(emoji)
                    .font(.system(size: 20))
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(UIColor.label))
            }
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundColor(Color(UIColor.secondaryLabel))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    VStack(spacing: 20) {
        OptionCardView(
            item: OptionItem(value: "romantic", label: "Romantic", emoji: "💕", desc: "Intimate evening"),
            isSelected: true,
            onTap: {}
        )
        .frame(width: 120)
        
        OptionCardView(
            item: OptionItem(value: "casual", label: "Casual", emoji: "🎉"),
            isSelected: false,
            onTap: {}
        )
        .frame(width: 120)
        
        MultiSelectOptionCard(
            item: OptionItem(value: "italian", label: "Italian", emoji: "🍝", desc: "Pasta, pizza, and more"),
            isSelected: true,
            onTap: {}
        )
        
        ChipOptionView(
            item: OptionItem(value: "wine", label: "Wine", emoji: "🍷"),
            isSelected: false,
            onTap: {}
        )
    }
    .padding()
    .background(Color.brandCream)
}
