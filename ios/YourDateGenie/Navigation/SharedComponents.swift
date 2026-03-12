import SwiftUI

// MARK: - Luxury Quick Tile
struct LuxuryQuickTile: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    var imageUrl: String? = nil
    
    private var defaultImageUrl: String {
        switch icon {
        case "gift.fill": return "https://images.unsplash.com/photo-1549465220-1a8b9238cd48?w=120&h=120&fit=crop"
        case "photo.stack.fill": return "https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=120&h=120&fit=crop"
        case "bookmark.fill": return "https://images.unsplash.com/photo-1529333166437-7750a6dd5a70?w=120&h=120&fit=crop"
        case "clock.fill": return "https://images.unsplash.com/photo-1501139083538-0139583c060f?w=120&h=120&fit=crop"
        case "music.note.list": return "https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=120&h=120&fit=crop"
        case "bubble.left.and.bubble.right.fill": return "https://images.unsplash.com/photo-1522202176988-66273c2fd55f?w=120&h=120&fit=crop"
        default: return "https://images.unsplash.com/photo-1529333166437-7750a6dd5a70?w=120&h=120&fit=crop"
        }
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                AsyncImage(url: URL(string: imageUrl ?? defaultImageUrl)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .empty, .failure:
                        Image(systemName: icon)
                            .font(.system(size: 24))
                            .foregroundColor(color)
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
                
                Text(title)
                    .font(Font.bodySans(12, weight: .medium))
                    .foregroundColor(Color.luxuryCream)
            }
            .frame(width: 80)
        }
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
                        .font(Font.header(15, weight: .bold))
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
    
    private var imageUrl: String {
        switch icon {
        case "wand.and.stars": return "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100&h=100&fit=crop"
        case "map.fill": return "https://images.unsplash.com/photo-1524661135-423995f22d0b?w=100&h=100&fit=crop"
        case "music.note": return "https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=100&h=100&fit=crop"
        case "heart.circle.fill": return "https://images.unsplash.com/photo-1518199266791-5375a83190b7?w=100&h=100&fit=crop"
        default: return "https://images.unsplash.com/photo-1529333166437-7750a6dd5a70?w=100&h=100&fit=crop"
        }
    }
    
    var body: some View {
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
}
