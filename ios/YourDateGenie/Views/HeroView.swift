import SwiftUI

struct HeroView: View {
    @EnvironmentObject var coordinator: NavigationCoordinator
    @State private var glowPulse = false
    /// When set (e.g. post–email-confirm gate), overrides default `startDatePlanning()` CTA.
    var onBeginJourney: (() -> Void)? = nil

    var body: some View {
        ZStack(alignment: .bottom) {
            // Background image with luxurious overlay
            AsyncImage(url: URL(string: "https://images.unsplash.com/photo-1529333166437-7750a6dd5a70?w=800&h=600&fit=crop")) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .empty:
                    Rectangle()
                        .fill(Color.luxuryMaroonLight)
                        .overlay(ProgressView().tint(Color.luxuryGold))
                case .failure:
                    Rectangle()
                        .fill(Color.luxuryMaroonLight)
                @unknown default:
                    EmptyView()
                }
            }
            .frame(height: UIScreen.main.bounds.height * 0.65)
            .clipped()
            .overlay(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.luxuryMaroon.opacity(0.3),
                        Color.luxuryMaroon.opacity(0.5),
                        Color.luxuryMaroon.opacity(0.9),
                        Color.luxuryMaroon
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            
            // Content
            VStack(spacing: 28) {
                // Logo with glow effect
                ZStack {
                    Image("Logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 180, height: 180)
                        .blur(radius: glowPulse ? 15 : 10)
                        .opacity(0.3)
                    
                    Image("Logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 160, height: 160)
                }
                
                // Tagline
                VStack(spacing: 4) {
                    Text("Date nights,")
                        .font(Font.header(36, weight: .regular))
                        .foregroundColor(Color.luxuryCream)
                    
                    HStack(spacing: 6) {
                        Text("planned")
                            .font(Font.tangerine(52, weight: .bold))
                            .italic()
                            .foregroundStyle(LinearGradient.goldShimmer)
                        Text("for you.")
                            .font(Font.header(36, weight: .regular))
                            .foregroundColor(Color.luxuryCream)
                    }
                }
                .multilineTextAlignment(.center)
                
                // Description
                Text("Tell us what you love. We'll create a complete evening — venues, timing, and all the details.")
                    .font(Font.bodySans(15, weight: .regular))
                    .foregroundColor(Color.luxuryCreamMuted)
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
                    .padding(.horizontal, 24)
                
                // CTA Button
                Button {
                    if let onBeginJourney {
                        onBeginJourney()
                    } else {
                        coordinator.startDatePlanning()
                    }
                } label: {
                    HStack(spacing: 12) {
                        Text("Begin Your Journey")
                            .font(Font.bodySans(16, weight: .semibold))
                        
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .semibold))
                    }
                }
                .buttonStyle(LuxuryGoldButtonStyle())
                
                // Trust text
                HStack(spacing: 4) {
                    Text("Join 500+ couples planning")
                        .font(Font.bodySans(12, weight: .regular))
                        .foregroundColor(Color.luxuryMuted)
                    Text("magical")
                        .font(Font.tangerine(24, weight: .bold))
                        .italic()
                        .foregroundColor(Color.luxuryGold)
                    Text("dates")
                        .font(Font.bodySans(12, weight: .regular))
                        .foregroundColor(Color.luxuryMuted)
                }
            }
            .padding(.bottom, 60)
        }
        .overlay(alignment: .topTrailing) {
            if onBeginJourney != nil {
                Button {
                    coordinator.deferInitialPreferences()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(Color.luxuryGold.opacity(0.9))
                        .symbolRenderingMode(.hierarchical)
                }
                .padding(.top, 56)
                .padding(.trailing, 20)
                .accessibilityLabel("Skip for now")
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                glowPulse = true
            }
        }
    }
}

// MARK: - Scale Button Style (for reuse)
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

#Preview {
    HeroView()
        .environmentObject(NavigationCoordinator.shared)
}
