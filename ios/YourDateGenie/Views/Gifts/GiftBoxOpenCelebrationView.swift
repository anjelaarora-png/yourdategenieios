import SwiftUI

/// Save/bought celebration: same as reference — box with lid open, glow from inside, intricate bow, confetti.
struct GiftBoxOpenCelebrationView: View {
    var message: String = "Gift saved!"
    var onDismiss: () -> Void
    
    @State private var scale: CGFloat = 0.6
    @State private var opacity: Double = 0
    @State private var lidAngle: Double = 0
    @State private var lidOffset: CGFloat = 0
    @State private var innerGlowOpacity: Double = 0
    @State private var innerGlowScale: CGFloat = 0.2
    @State private var confetti: [CelebrationConfettiPiece] = []
    
    private let boxW: CGFloat = 100
    private let boxH: CGFloat = 72
    private let lidH: CGFloat = 26
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .onTapGesture { onDismiss() }
                
                ForEach(confetti) { piece in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(piece.color)
                        .frame(width: piece.w, height: piece.h)
                        .rotationEffect(.degrees(piece.rotation))
                        .position(x: piece.x, y: piece.y)
                        .opacity(piece.opacity)
                }
                
                VStack(spacing: 16) {
                    ZStack(alignment: .bottom) {
                        RadialGradient(
                            colors: [
                                Color.luxuryCream.opacity(0.65),
                                Color.luxuryGold.opacity(0.35),
                                Color.luxuryGold.opacity(0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 70
                        )
                        .scaleEffect(innerGlowScale)
                        .opacity(innerGlowOpacity)
                        .offset(y: -boxH / 2 - lidH - 10)
                        .blur(radius: 6)
                        
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    colors: [Color.luxuryMaroonLight, Color.luxuryMaroon],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.luxuryGold.opacity(0.35), lineWidth: 1))
                            .frame(width: boxW, height: boxH)
                            .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                        
                        RoundedRectangle(cornerRadius: 3)
                            .fill(LinearGradient(colors: [Color.luxuryGold.opacity(0.9), Color.luxuryGoldDark.opacity(0.85)], startPoint: .top, endPoint: .bottom))
                            .frame(width: 10, height: boxH)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(LinearGradient(colors: [Color.luxuryGold.opacity(0.9), Color.luxuryGoldDark.opacity(0.85)], startPoint: .top, endPoint: .bottom))
                            .frame(width: boxW, height: 10)
                        
                        ZStack(alignment: .bottom) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(LinearGradient(colors: [Color.luxuryMaroonLight.opacity(0.95), Color.luxuryMaroon], startPoint: .top, endPoint: .bottom))
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.luxuryGold.opacity(0.4), lineWidth: 1))
                                .frame(width: boxW + 3, height: lidH)
                                .frame(height: lidH, alignment: .bottom)
                        }
                        .frame(height: lidH * 2, alignment: .bottom)
                        .rotation3DEffect(.degrees(lidAngle), axis: (x: 1, y: 0, z: 0), perspective: 0.5)
                        .offset(y: lidOffset)
                        
                        CelebrationBowView()
                            .frame(width: 40, height: 32)
                            .offset(y: lidOffset - lidH / 2 - 18)
                    }
                    .frame(width: boxW, height: boxH + 60)
                    
                    Text(message)
                        .font(Font.playfair(17, weight: .semibold))
                        .foregroundColor(Color.luxuryCream)
                }
                .padding(24)
                .background(Color.luxuryMaroon)
                .cornerRadius(20)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.luxuryGold.opacity(0.5), lineWidth: 1))
                .shadow(color: .black.opacity(0.4), radius: 20, x: 0, y: 10)
                .scaleEffect(scale)
                .opacity(opacity)
            }
        }
        .onAppear {
            spawnConfetti(size: UIScreen.main.bounds.size)
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                scale = 1
                opacity = 1
            }
            withAnimation(.spring(response: 0.45, dampingFraction: 0.7).delay(0.2)) {
                lidAngle = -92
                lidOffset = -38
            }
            withAnimation(.easeOut(duration: 0.4).delay(0.4)) {
                innerGlowOpacity = 0.9
                innerGlowScale = 1.2
            }
            animateConfetti()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.7) {
                onDismiss()
            }
        }
    }
    
    private func spawnConfetti(size: CGSize) {
        let cx = size.width / 2
        let cy = size.height / 2
        let colors: [Color] = [Color.luxuryGold, Color.luxuryGoldLight, Color.luxuryCream, Color.luxuryMaroonLight, Color.luxuryGoldDark]
        var pieces: [CelebrationConfettiPiece] = []
        for i in 0..<28 {
            pieces.append(CelebrationConfettiPiece(
                id: i,
                x: cx,
                y: cy,
                w: CGFloat.random(in: 4...10),
                h: CGFloat.random(in: 3...8),
                color: colors.randomElement() ?? Color.luxuryGold,
                rotation: 0,
                opacity: 0
            ))
        }
        confetti = pieces
    }
    
    private func animateConfetti() {
        let size = UIScreen.main.bounds.size
        let cx = size.width / 2
        let cy = size.height / 2
        withAnimation(.easeOut(duration: 0.9)) {
            for i in confetti.indices {
                let angle = Double(i) * 12.5 * .pi / 180
                let dist: CGFloat = CGFloat.random(in: 70...150)
                confetti[i].x = cx + cos(angle) * dist
                confetti[i].y = cy + sin(angle) * dist
                confetti[i].opacity = 0.9
                confetti[i].rotation = Double.random(in: 120...400)
            }
        }
        withAnimation(.easeOut(duration: 0.35).delay(0.55)) {
            for i in confetti.indices {
                confetti[i].opacity = 0.3
            }
        }
    }
}

private struct CelebrationConfettiPiece: Identifiable {
    let id: Int
    var x: CGFloat
    var y: CGFloat
    let w: CGFloat
    let h: CGFloat
    let color: Color
    var rotation: Double
    var opacity: Double
}

private struct CelebrationBowView: View {
    var body: some View {
        ZStack {
            Ellipse()
                .fill(LinearGradient(colors: [Color.luxuryCream.opacity(0.95), Color.luxuryGold, Color.luxuryGoldDark], startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(Ellipse().stroke(Color.luxuryGold.opacity(0.6), lineWidth: 1))
                .frame(width: 22, height: 16)
                .offset(x: -12, y: -4)
            Ellipse()
                .fill(LinearGradient(colors: [Color.luxuryCream.opacity(0.95), Color.luxuryGold, Color.luxuryGoldDark], startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(Ellipse().stroke(Color.luxuryGold.opacity(0.6), lineWidth: 1))
                .frame(width: 22, height: 16)
                .offset(x: 12, y: -4)
            ZStack {
                Circle()
                    .fill(RadialGradient(colors: [Color.luxuryCream, Color.luxuryGoldLight, Color.luxuryGold], center: .center, startRadius: 0, endRadius: 7))
                    .frame(width: 14, height: 14)
                    .overlay(Circle().stroke(Color.luxuryGold.opacity(0.8), lineWidth: 1))
                Circle().fill(Color.white.opacity(0.5)).frame(width: 4, height: 4).offset(x: -1, y: -1)
            }
            .offset(y: 2)
        }
    }
}

#Preview {
    GiftBoxOpenCelebrationView(onDismiss: {})
}
