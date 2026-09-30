import SwiftUI

// MARK: - Luxury Splash View
struct LuxurySplashView: View {
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0
    @State private var textOpacity: Double = 0
    
    var body: some View {
        ZStack {
            CharcoalMaroonBackground()
                .ignoresSafeArea()
            
            VStack(spacing: 28) {
                DateNightMarkView(side: 200)
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)

                DateNightsTagline()
                    .opacity(textOpacity)
            }
            .padding(.horizontal, 24)
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
