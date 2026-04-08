import SwiftUI

// MARK: - Compact row for saved / bought gift lists (Gifts tab + Gift Finder)
struct StoredGiftRowView: View {
    let stored: StoredGift
    let onShop: () -> Void
    let onNewLink: () -> Void
    var onMarkBought: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Text(stored.emoji)
                    .font(.system(size: 28))
                    .frame(width: 44, height: 44)
                    .background(Color.luxuryMaroonLight)
                    .cornerRadius(10)
                VStack(alignment: .leading, spacing: 4) {
                    Text(stored.name)
                        .font(Font.bodySans(15, weight: .semibold))
                        .foregroundColor(Color.luxuryCream)
                    Text(stored.priceRange)
                        .font(Font.inter(12, weight: .medium))
                        .foregroundColor(Color.luxuryGold)
                }
                Spacer()
            }
            HStack(spacing: 8) {
                Button(action: onShop) {
                    HStack(spacing: 5) {
                        Image(systemName: "cart.fill")
                            .font(.system(size: 11))
                        Text("Shop")
                            .font(Font.inter(12, weight: .semibold))
                    }
                    .foregroundColor(Color.luxuryMaroon)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(LinearGradient.goldShimmer)
                    .cornerRadius(8)
                }
                Button(action: onNewLink) {
                    HStack(spacing: 4) {
                        Image(systemName: "link")
                            .font(.system(size: 10))
                            .foregroundColor(Color.luxuryGold)
                        Text("New link")
                            .font(Font.inter(11, weight: .semibold))
                    }
                    .foregroundColor(Color.luxuryGold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 10)
                    .background(Color.clear)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.luxuryGold.opacity(0.5), lineWidth: 1)
                    )
                }
                if let onMarkBought = onMarkBought {
                    Button(action: onMarkBought) {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 11))
                            Text("Bought")
                                .font(Font.inter(11, weight: .semibold))
                        }
                        .foregroundColor(Color.luxuryMaroon)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 10)
                        .background(Color.luxuryCream.opacity(0.9))
                        .cornerRadius(8)
                    }
                }
            }
        }
        .padding(14)
        .background(Color.luxuryMaroonLight)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.luxuryGold.opacity(0.25), lineWidth: 1)
        )
    }
}

// MARK: - Empty state for saved / bought lists
struct GiftListEmptyState: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(Color.luxuryGold)
            Text(title)
                .font(Font.tangerine(22, weight: .bold))
                .foregroundColor(Color.luxuryGold)
            Text(subtitle)
                .font(Font.inter(13, weight: .regular))
                .foregroundColor(Color.luxuryMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .padding(.horizontal, 20)
        .background(Color.luxuryMaroonLight.opacity(0.6))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.luxuryGold.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal, 20)
    }
}
