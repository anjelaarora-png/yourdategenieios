import SwiftUI

// MARK: - Luxury Splash View
struct LuxurySplashView: View {
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0
    @State private var textOpacity: Double = 0
    
    var body: some View {
        ZStack {
            Color.luxuryMaroon
                .ignoresSafeArea()
            
            RadialGradient.goldGlow
                .opacity(0.4)
                .scaleEffect(1.5)
            
            VStack(spacing: 24) {
                Image("Logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 200, height: 200)
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)
                
                VStack(spacing: 10) {
                    HStack(spacing: 6) {
                        Text("Date nights,")
                            .font(Font.header(18, weight: .regular))
                            .foregroundColor(Color.luxuryCreamMuted)
                        Text("planned")
                            .font(Font.tangerine(28, weight: .bold))
                            .italic()
                            .foregroundColor(Color.luxuryGold)
                        Text("for you.")
                            .font(Font.header(18, weight: .regular))
                            .foregroundColor(Color.luxuryCreamMuted)
                    }
                }
                .opacity(textOpacity)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
            withAnimation(.easeIn(duration: 0.8).delay(0.4)) {
                textOpacity = 1.0
            }
        }
    }
}

#Preview {
    LuxurySplashView()
}
