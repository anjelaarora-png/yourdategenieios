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

            // Quiet loading indicator, as in the final design.
            VStack {
                Spacer()
                SplashLoadingBar()
                    .padding(.bottom, YDGSpace.xxl)
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

private struct SplashLoadingBar: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase: CGFloat = 0

    var body: some View {
        ZStack(alignment: .leading) {
            Capsule().fill(Color.ydgOverlay)
            Capsule().fill(Color.ydgAccent)
                .frame(width: 16)
                .offset(x: reduceMotion ? 0 : phase * 24)
        }
        .frame(width: 40, height: 3)
        .accessibilityHidden(true)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) { phase = 1 }
        }
    }
}

#Preview {
    LuxurySplashView()
}
