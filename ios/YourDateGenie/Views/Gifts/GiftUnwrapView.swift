import SwiftUI

/// Small 3D luxe gift-with-bow for Step 6. No strokes — gradients and shadows only.
struct GiftUnwrapView: View {
    @State private var lidOffset: CGFloat = 0
    @State private var lidOpacity: Double = 1
    @State private var bowScale: CGFloat = 0.9
    @State private var contentOpacity: Double = 0
    @State private var contentScale: CGFloat = 0.94
    
    private var boxGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.luxuryGoldLight.opacity(0.5),
                Color.luxuryGold.opacity(0.35),
                Color.luxuryGoldDark.opacity(0.3)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var ribbonGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.luxuryGoldLight.opacity(0.9),
                Color.luxuryGold,
                Color.luxuryGoldDark.opacity(0.85)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    var body: some View {
        ZStack {
            // Box base — gradient only, no stroke
            RoundedRectangle(cornerRadius: 8)
                .fill(boxGradient)
                .frame(width: 56, height: 44)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.2), Color.clear],
                                startPoint: .topLeading,
                                endPoint: .center
                            )
                        )
                )
                .shadow(color: Color.black.opacity(0.25), radius: 4, x: 0, y: 2)
            
            // Ribbons — filled bands with highlight
            RoundedRectangle(cornerRadius: 4)
                .fill(ribbonGradient)
                .frame(width: 10, height: 44)
                .shadow(color: Color.black.opacity(0.15), radius: 2, x: 0, y: 1)
            
            RoundedRectangle(cornerRadius: 4)
                .fill(ribbonGradient)
                .frame(width: 56, height: 10)
                .shadow(color: Color.black.opacity(0.15), radius: 2, x: 0, y: 1)
            
            // Lid
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.luxuryGoldLight.opacity(0.45),
                            Color.luxuryGold.opacity(0.35),
                            Color.luxuryGoldDark.opacity(0.35)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.25), Color.clear],
                                startPoint: .top,
                                endPoint: .center
                            )
                        )
                )
                .frame(width: 58, height: 20)
                .shadow(color: Color.black.opacity(0.2), radius: 3, x: 0, y: 2)
                .offset(y: lidOffset)
                .opacity(lidOpacity)
            
            // Bow — gradient center + highlight
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.luxuryGoldLight,
                                Color.luxuryGold,
                                Color.luxuryGoldDark
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 12
                        )
                    )
                    .frame(width: 22, height: 22)
                    .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)
                Circle()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 8, height: 8)
                    .offset(x: -3, y: -3)
            }
            .scaleEffect(bowScale)
            .offset(y: -2 + lidOffset)
        }
        .frame(width: 80, height: 70)
        .scaleEffect(contentScale)
        .opacity(contentOpacity)
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                contentOpacity = 1
                contentScale = 1
            }
            withAnimation(.easeOut(duration: 0.85)) {
                lidOffset = -22
                lidOpacity = 0.2
            }
            withAnimation(.easeOut(duration: 0.25).delay(0.35)) {
                bowScale = 1.2
            }
            withAnimation(.easeOut(duration: 0.2).delay(0.6)) {
                bowScale = 1.0
            }
        }
        .onDisappear {
            lidOffset = 0
            lidOpacity = 1
            bowScale = 0.9
            contentOpacity = 0
            contentScale = 0.94
        }
    }
}

#Preview {
    ZStack {
        Color.luxuryMaroon.ignoresSafeArea()
        GiftUnwrapView()
    }
}
