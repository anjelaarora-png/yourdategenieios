import SwiftUI

/// Gift Finder intro: gift box with lid lifting open, glow from inside, intricate bow on lid, confetti. Matches reference style in app colors.
struct BigGiftUnwrapView: View {
    var onComplete: () -> Void
    
    @State private var boxScale: CGFloat = 0.6
    @State private var boxOpacity: Double = 0
    @State private var lidAngle: Double = 0
    @State private var lidOffset: CGFloat = 0
    @State private var innerGlowOpacity: Double = 0
    @State private var innerGlowScale: CGFloat = 0.3
    @State private var confettiPieces: [ConfettiPiece] = []
    @State private var titleOpacity: Double = 0
    @State private var titleScale: CGFloat = 0.92
    
    private let boxW: CGFloat = 140
    private let boxH: CGFloat = 100
    private let lidH: CGFloat = 36
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.luxuryMaroon
                    .ignoresSafeArea()
                
                // Confetti
                ForEach(confettiPieces) { piece in
                    ConfettiShape(style: piece.style)
                        .fill(piece.color)
                        .frame(width: piece.size, height: piece.size * (piece.style == .rect ? 0.6 : 1))
                        .rotationEffect(.degrees(piece.rotation))
                        .position(x: piece.x, y: piece.y)
                        .opacity(piece.opacity)
                }
                
                // Gift box (base + lid + bow) with glow from inside
                ZStack(alignment: .bottom) {
                    // Glow emanating from inside the box when lid opens
                    RadialGradient(
                        colors: [
                            Color.luxuryCream.opacity(0.7),
                            Color.luxuryGold.opacity(0.4),
                            Color.luxuryGold.opacity(0.15),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 120
                    )
                    .scaleEffect(innerGlowScale)
                    .opacity(innerGlowOpacity)
                    .offset(y: -boxH / 2 - lidH)
                    .blur(radius: 8)
                    
                    // Box base
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.luxuryMaroonLight,
                                    Color.luxuryMaroon,
                                    Color.luxuryMaroon.opacity(0.95)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.luxuryGold.opacity(0.35), lineWidth: 1)
                        )
                        .frame(width: boxW, height: boxH)
                        .shadow(color: .black.opacity(0.35), radius: 10, x: 0, y: 6)
                    
                    // Vertical ribbon on base
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [Color.luxuryGold.opacity(0.9), Color.luxuryGoldDark.opacity(0.85)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 12, height: boxH)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [Color.luxuryGold.opacity(0.9), Color.luxuryGoldDark.opacity(0.85)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: boxW, height: 12)
                    
                    // Lid (hinges open, floats up)
                    ZStack(alignment: .bottom) {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.luxuryMaroonLight.opacity(0.95),
                                        Color.luxuryMaroon,
                                        Color.luxuryMaroon.opacity(0.9)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.luxuryGold.opacity(0.4), lineWidth: 1)
                            )
                            .frame(width: boxW + 4, height: lidH)
                            .frame(height: lidH, alignment: .bottom)
                    }
                    .frame(height: lidH * 2, alignment: .bottom)
                    .rotation3DEffect(.degrees(lidAngle), axis: (x: 1, y: 0, z: 0), perspective: 0.5)
                    .offset(y: lidOffset)
                    
                    // Intricate bow on the lid (moves with lid)
                    IntricateBowView()
                        .frame(width: 56, height: 46)
                        .offset(y: lidOffset - lidH / 2 - 28)
                }
                .frame(width: boxW, height: boxH + 80)
                .scaleEffect(boxScale)
                .opacity(boxOpacity)
                .offset(y: geo.size.height * 0.06)
                
                VStack(spacing: 0) {
                    Spacer()
                    
                    Text("Find the perfect gift")
                        .font(Font.tangerine(32, weight: .bold))
                        .foregroundColor(Color.luxuryCream)
                        .multilineTextAlignment(.center)
                        .opacity(titleOpacity)
                        .scaleEffect(titleScale)
                    
                    Text("Thoughtful ideas, tailored to them")
                        .font(Font.inter(15, weight: .regular))
                        .foregroundColor(Color.luxuryCreamMuted)
                        .padding(.top, 10)
                        .opacity(titleOpacity)
                    
                    Spacer()
                    Spacer()
                }
                .padding(.horizontal, 32)
            }
        }
        .onAppear {
            runSequence()
        }
    }
    
    private func runSequence() {
        spawnConfetti(in: UIScreen.main.bounds.size)
        
        withAnimation(.easeOut(duration: 0.45)) {
            boxScale = 1
            boxOpacity = 1
        }
        
        withAnimation(.spring(response: 0.55, dampingFraction: 0.72).delay(0.3)) {
            lidAngle = -95
            lidOffset = -50
        }
        
        withAnimation(.easeOut(duration: 0.5).delay(0.55)) {
            innerGlowOpacity = 0.95
            innerGlowScale = 1.4
        }
        
        animateConfetti(delay: 0.5)
        
        withAnimation(.easeOut(duration: 0.5).delay(0.75)) {
            titleOpacity = 1
            titleScale = 1
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.1) {
            onComplete()
        }
    }
    
    private func spawnConfetti(in size: CGSize) {
        let centerX = size.width / 2
        let centerY = size.height / 2
        let colors: [Color] = [
            Color.luxuryGold,
            Color.luxuryGoldLight,
            Color.luxuryCream,
            Color.luxuryMaroonLight,
            Color.luxuryGoldDark
        ]
        var pieces: [ConfettiPiece] = []
        for i in 0..<36 {
            let angle = Double(i) * 10 * .pi / 180
            let dist: CGFloat = CGFloat.random(in: 50...100)
            pieces.append(ConfettiPiece(
                id: i,
                x: centerX + cos(angle) * dist,
                y: centerY + sin(angle) * dist,
                size: CGFloat.random(in: 5...12),
                color: colors.randomElement() ?? Color.luxuryGold,
                style: i % 3 == 0 ? .rect : .circle,
                rotation: Double.random(in: 0...360),
                opacity: 0
            ))
        }
        confettiPieces = pieces
    }
    
    private func animateConfetti(delay: Double = 0) {
        let size = UIScreen.main.bounds.size
        let centerX = size.width / 2
        let centerY = size.height / 2
        var endStates: [(x: CGFloat, y: CGFloat, opacity: Double, rotation: Double)] = []
        for _ in confettiPieces.indices {
            endStates.append((
                centerX + CGFloat.random(in: -170...170),
                centerY + CGFloat.random(in: -130...130),
                0.92,
                Double.random(in: 180...540)
            ))
        }
        withAnimation(.easeOut(duration: 1.0).delay(delay)) {
            for i in confettiPieces.indices {
                confettiPieces[i].x = endStates[i].x
                confettiPieces[i].y = endStates[i].y
                confettiPieces[i].opacity = endStates[i].opacity
                confettiPieces[i].rotation += endStates[i].rotation
            }
        }
        withAnimation(.easeOut(duration: 0.5).delay(delay + 0.75)) {
            for i in confettiPieces.indices {
                confettiPieces[i].opacity = 0.4
            }
        }
    }
}

// MARK: - Intricate bow (loops + knot + ribbons)
private struct IntricateBowView: View {
    var body: some View {
        ZStack {
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [Color.luxuryCream.opacity(0.95), Color.luxuryGold, Color.luxuryGoldDark],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(Ellipse().stroke(Color.luxuryGold.opacity(0.65), lineWidth: 1))
                .frame(width: 28, height: 22)
                .offset(x: -16, y: -6)
                .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
            
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [Color.luxuryCream.opacity(0.95), Color.luxuryGold, Color.luxuryGoldDark],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(Ellipse().stroke(Color.luxuryGold.opacity(0.65), lineWidth: 1))
                .frame(width: 28, height: 22)
                .offset(x: 16, y: -6)
                .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
            
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.luxuryCream, Color.luxuryGoldLight, Color.luxuryGold, Color.luxuryGoldDark],
                            center: .center,
                            startRadius: 0,
                            endRadius: 10
                        )
                    )
                    .frame(width: 20, height: 20)
                    .overlay(Circle().stroke(Color.luxuryGold.opacity(0.8), lineWidth: 1))
                Circle()
                    .fill(Color.white.opacity(0.5))
                    .frame(width: 6, height: 6)
                    .offset(x: -2, y: -2)
            }
            .offset(y: 2)
            .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
            
            RoundedRectangle(cornerRadius: 1)
                .fill(LinearGradient(colors: [Color.luxuryGoldDark.opacity(0.9), Color.luxuryGold.opacity(0.7)], startPoint: .top, endPoint: .bottom))
                .frame(width: 4, height: 18)
                .offset(x: -22, y: 14)
            RoundedRectangle(cornerRadius: 1)
                .fill(LinearGradient(colors: [Color.luxuryGoldDark.opacity(0.9), Color.luxuryGold.opacity(0.7)], startPoint: .top, endPoint: .bottom))
                .frame(width: 4, height: 18)
                .offset(x: 22, y: 14)
        }
    }
}

private struct ConfettiPiece: Identifiable {
    let id: Int
    var x: CGFloat
    var y: CGFloat
    let size: CGFloat
    let color: Color
    let style: ConfettiStyle
    var rotation: Double
    var opacity: Double
}

private enum ConfettiStyle {
    case circle, rect
}

private struct ConfettiShape: Shape {
    var style: ConfettiStyle
    func path(in rect: CGRect) -> Path {
        switch style {
        case .circle: return Path(ellipseIn: rect)
        case .rect: return Path(roundedRect: rect, cornerRadius: 1)
        }
    }
}

#Preview {
    BigGiftUnwrapView(onComplete: {})
}
