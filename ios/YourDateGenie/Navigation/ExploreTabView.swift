import SwiftUI

// MARK: - Luxury Explore Tab View
struct LuxuryExploreTabView: View {
    @EnvironmentObject var coordinator: NavigationCoordinator
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.luxuryMaroon
                    .ignoresSafeArea()
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 24) {
                        VStack(spacing: 8) {
                            Text("Explore")
                                .font(Font.tangerine(52, weight: .bold))
                                .italic()
                                .foregroundColor(Color.luxuryGold)
                            
                            Text("Discover new date ideas")
                                .font(Font.bodySans(15, weight: .regular))
                                .foregroundColor(Color.luxuryCreamMuted)
                        }
                        .padding(.top, 16)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 6) {
                                Text("Date")
                                    .font(Font.header(17, weight: .regular))
                                    .foregroundColor(Color.luxuryCream)
                                Text("Types")
                                    .font(Font.tangerine(28, weight: .bold))
                                    .italic()
                                    .foregroundColor(Color.luxuryGold)
                            }
                            .padding(.horizontal, 20)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    LuxuryDateTypeTile(emoji: "🌹", title: "Romantic")
                                    LuxuryDateTypeTile(emoji: "🎉", title: "Fun")
                                    LuxuryDateTypeTile(emoji: "🏠", title: "Cozy")
                                    LuxuryDateTypeTile(emoji: "🚀", title: "Adventure")
                                    LuxuryDateTypeTile(emoji: "✨", title: "Special")
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 6) {
                                Text("Get")
                                    .font(Font.header(17, weight: .regular))
                                    .foregroundColor(Color.luxuryCream)
                                Text("Inspired")
                                    .font(Font.tangerine(28, weight: .bold))
                                    .italic()
                                    .foregroundColor(Color.luxuryGold)
                            }
                            .padding(.horizontal, 20)
                            
                            VStack(spacing: 12) {
                                LuxuryInspirationCard(
                                    title: "Wine & Dine",
                                    description: "Elegant evening with wine tasting",
                                    emoji: "🍷"
                                )
                                
                                LuxuryInspirationCard(
                                    title: "Outdoor Adventure",
                                    description: "Hiking, picnic, and sunset views",
                                    emoji: "🌄"
                                )
                                
                                LuxuryInspirationCard(
                                    title: "Arts & Culture",
                                    description: "Museums, galleries, and live shows",
                                    emoji: "🎨"
                                )
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.bottom, 120)
                }
                .scrollBounceBehavior(.basedOnSize)
            }
            .toolbarBackground(Color.luxuryMaroon, for: .navigationBar)
        }
    }
}

// MARK: - Date Type Tile
struct LuxuryDateTypeTile: View {
    let emoji: String
    let title: String
    
    private var imageUrl: String {
        switch title {
        case "Romantic": return "https://images.unsplash.com/photo-1529634806980-85c3dd6d34ac?w=140&h=140&fit=crop"
        case "Fun": return "https://images.unsplash.com/photo-1533174072545-7a4b6ad7a6c3?w=140&h=140&fit=crop"
        case "Cozy": return "https://images.unsplash.com/photo-1558171813-4c088753af8f?w=140&h=140&fit=crop"
        case "Adventure": return "https://images.unsplash.com/photo-1533130061792-64b345e4a833?w=140&h=140&fit=crop"
        case "Special": return "https://images.unsplash.com/photo-1519671482749-fd09be7ccebf?w=140&h=140&fit=crop"
        default: return "https://images.unsplash.com/photo-1529333166437-7750a6dd5a70?w=140&h=140&fit=crop"
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                AsyncImage(url: URL(string: imageUrl)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .empty, .failure:
                        Color.luxuryMaroonLight
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(width: 68, height: 68)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                
                Text(emoji)
                    .font(.system(size: 28))
                    .shadow(color: .black.opacity(0.5), radius: 2, y: 1)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.luxuryGold.opacity(0.3), lineWidth: 1)
            )
            
            Text(title)
                .font(Font.bodySans(13, weight: .medium))
                .foregroundColor(Color.luxuryCream)
        }
    }
}

// MARK: - Inspiration Card
struct LuxuryInspirationCard: View {
    let title: String
    let description: String
    let emoji: String
    
    private var imageUrl: String {
        switch title {
        case "Wine & Dine": return "https://images.unsplash.com/photo-1510812431401-41d2bd2722f3?w=120&h=120&fit=crop"
        case "Outdoor Adventure": return "https://images.unsplash.com/photo-1501555088652-021faa106b9b?w=120&h=120&fit=crop"
        case "Arts & Culture": return "https://images.unsplash.com/photo-1499781350541-7783f6c6a0c8?w=120&h=120&fit=crop"
        default: return "https://images.unsplash.com/photo-1529333166437-7750a6dd5a70?w=120&h=120&fit=crop"
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                AsyncImage(url: URL(string: imageUrl)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .empty, .failure:
                        Color.luxuryMaroonLight
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                
                Text(emoji)
                    .font(.system(size: 28))
                    .shadow(color: .black.opacity(0.5), radius: 2, y: 1)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.luxuryGold.opacity(0.3), lineWidth: 1)
            )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(Font.header(16, weight: .bold))
                    .foregroundColor(Color.luxuryGold)
                
                Text(description)
                    .font(Font.bodySans(14, weight: .regular))
                    .foregroundColor(Color.luxuryCreamMuted)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(Color.luxuryGold.opacity(0.6))
        }
        .padding(20)
        .luxuryCard()
    }
}
