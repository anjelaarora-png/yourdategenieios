import SwiftUI

// MARK: - Luxury Quick Tile (icon + label; use .frame(maxWidth: .infinity) for even distribution in a row)
struct LuxuryQuickTile: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 48, height: 48)
                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .symbolRenderingMode(.monochrome)
                        .foregroundColor(color)
                }
                Text(title)
                    .font(Font.bodySans(12, weight: .medium))
                    .foregroundColor(Color.luxuryCream)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .truncationMode(.tail)
                    .minimumScaleFactor(0.85)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Luxury Saved Plan Card
struct LuxurySavedPlanCard: View {
    let plan: DatePlan
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 6) {
                    ForEach(plan.stops.prefix(3)) { stop in
                        Text(stop.emoji)
                            .font(.system(size: 22))
                    }
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(plan.title)
                        .font(Font.bodySans(14, weight: .semibold))
                        .foregroundColor(Color.luxuryCream)
                        .lineLimit(1)
                    
                    Text("\(plan.stops.count) stops · \(plan.totalDuration)")
                        .font(Font.bodySans(12, weight: .regular))
                        .foregroundColor(Color.luxuryMuted)
                }
            }
            .padding(18)
            .frame(width: 190)
            .luxuryCard()
        }
    }
}

// MARK: - Luxury Feature Tile
struct LuxuryFeatureTile: View {
    let icon: String
    let title: String
    let subtitle: String
    var action: (() -> Void)? = nil
    
    private var imageUrl: String {
        switch icon {
        case "wand.and.stars": return "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100&h=100&fit=crop"
        case "map.fill": return "https://images.unsplash.com/photo-1524661135-423995f22d0b?w=100&h=100&fit=crop"
        case "music.note": return "https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=100&h=100&fit=crop"
        case "heart.circle.fill": return "https://images.unsplash.com/photo-1518199266791-5375a83190b7?w=100&h=100&fit=crop"
        case "sparkles": return "https://images.unsplash.com/photo-1529634806980-85c3dd6d34ac?w=100&h=100&fit=crop"
        default: return "https://images.unsplash.com/photo-1529333166437-7750a6dd5a70?w=100&h=100&fit=crop"
        }
    }
    
    private var tileContent: some View {
        HStack(spacing: 14) {
            AsyncImage(url: URL(string: imageUrl)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .empty, .failure:
                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .foregroundStyle(LinearGradient.goldShimmer)
                @unknown default:
                    EmptyView()
                }
            }
            .frame(width: 48, height: 48)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.luxuryGold.opacity(0.2), lineWidth: 1)
            )
            
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(Font.bodySans(14, weight: .semibold))
                    .foregroundColor(Color.luxuryCream)
                
                Text(subtitle)
                    .font(Font.bodySans(11, weight: .regular))
                    .foregroundColor(Color.luxuryMuted)
            }
            
            Spacer()
        }
        .padding(16)
        .luxuryCard(hasBorder: false)
    }
    
    @ViewBuilder
    var body: some View {
        if let action = action {
            Button(action: action) {
                tileContent
            }
            .buttonStyle(.plain)
        } else {
            tileContent
        }
    }
}

// MARK: - Love Letter Itinerary Background
/// Paper/parchment-style background for date plan itinerary (matches LoveLetterCardView aesthetic).
struct LoveLetterItineraryBackground<Content: View>: View {
    let content: Content
    var cornerRadius: CGFloat = 24
    
    init(cornerRadius: CGFloat = 24, @ViewBuilder content: () -> Content) {
        self.cornerRadius = cornerRadius
        self.content = content()
    }
    
    var body: some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: "FDF8F0"),
                                Color(hex: "F5EDE0"),
                                Color(hex: "F0E6D8")
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.luxuryGold.opacity(0.6),
                                Color.luxuryGold.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
            )
            .shadow(color: Color.black.opacity(0.15), radius: 20, y: 8)
    }
}
