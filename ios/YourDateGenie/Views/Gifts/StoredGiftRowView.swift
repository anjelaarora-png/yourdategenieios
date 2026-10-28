import SwiftUI

// MARK: - Compact row for saved / bought gift lists (Gifts tab + Gift Finder)
struct StoredGiftRowView: View {
    let stored: StoredGift
    let onShop: () -> Void
    let onNewLink: () -> Void
    var onMarkBought: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: YDGSpace.sm) {
            HStack(alignment: .top, spacing: YDGSpace.sm) {
                Text(stored.emoji)
                    .font(.system(size: 26))
                    .frame(width: 48, height: 48)
                    .background(Color.ydgOverlay, in: RoundedRectangle(cornerRadius: YDGRadius.chip, style: .continuous))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(stored.name)
                        .ydgText(.headline)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(stored.priceRange)
                        .ydgText(.subhead, weight: .semibold)
                }
                Spacer(minLength: 0)
            }
            HStack(spacing: YDGSpace.xs) {
                Button("New link", action: onNewLink)
                    .buttonStyle(YDGButtonStyle(kind: .secondary, fullWidth: false, compact: true))
                if let onMarkBought {
                    Button("Bought", action: onMarkBought)
                        .buttonStyle(YDGButtonStyle(kind: .secondary, fullWidth: false, compact: true))
                }
                Button("Shop now", action: onShop)
                    .buttonStyle(YDGButtonStyle(kind: .accentOutline, compact: true))
            }
        }
        .ydgCard()
    }
}

// MARK: - Empty state for saved / bought lists
struct GiftListEmptyState: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .top, spacing: YDGSpace.sm) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(Color.ydgHighlight)
                .frame(width: 24)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: YDGSpace.xxs) {
                Text(title)
                    .ydgText(.headline)
                Text(subtitle)
                    .ydgText(.subhead, weight: .regular, color: .ydgTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(.top, YDGSpace.xs)
    }
}
