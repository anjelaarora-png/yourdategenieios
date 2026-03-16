import SwiftUI

// MARK: - Genie Lamp Shape (vector, resolution-independent)

private struct GenieLampShape: Shape {
    /// Draws a genie lamp + smoke wisps + sparkles in unit coordinates; scales crisply at any size.
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x * w, y: rect.minY + y * h)
        }
        var path = Path()

        // Lamp body (rounded vase)
        let bodyCenterX: CGFloat = 0.5
        let bodyCenterY: CGFloat = 0.72
        let bodyW: CGFloat = 0.32
        let bodyH: CGFloat = 0.26
        path.addEllipse(in: CGRect(
            x: (bodyCenterX - bodyW / 2) * w,
            y: (bodyCenterY - bodyH / 2) * h,
            width: bodyW * w,
            height: bodyH * h
        ))

        // Spout (curved left and up)
        let spoutTip = pt(0.22, 0.42)
        let spoutBase = pt(0.34, 0.62)
        path.move(to: spoutBase)
        path.addQuadCurve(to: spoutTip, control: pt(0.12, 0.48))
        path.addLine(to: pt(0.20, 0.46))
        path.addQuadCurve(to: pt(0.36, 0.64), control: pt(0.14, 0.56))
        path.closeSubpath()

        // Handle (right side)
        path.addArc(center: pt(0.72, 0.70), radius: 0.06 * w, startAngle: .degrees(-70), endAngle: .degrees(70), clockwise: false)
        path.addLine(to: pt(0.78, 0.68))
        path.addArc(center: pt(0.72, 0.70), radius: 0.04 * w, startAngle: .degrees(70), endAngle: .degrees(-70), clockwise: true)
        path.closeSubpath()

        // Lid (domed cap)
        path.addEllipse(in: CGRect(x: (0.5 - 0.06) * w, y: (0.54 - 0.04) * h, width: 0.12 * w, height: 0.08 * h))

        // Smoke wisps (3 wavy strokes as filled ribbons)
        addSmokeWisp(to: &path, from: spoutTip, w: w, h: h, dy: -0.18, dx: 0.08)
        addSmokeWisp(to: &path, from: pt(0.20, 0.44), w: w, h: h, dy: -0.14, dx: 0.06)
        addSmokeWisp(to: &path, from: pt(0.24, 0.40), w: w, h: h, dy: -0.10, dx: 0.04)

        // Sparkles (4-pointed stars)
        for (cx, cy, size) in [(0.28, 0.32, 0.018), (0.34, 0.28, 0.014), (0.22, 0.36, 0.012), (0.38, 0.30, 0.011), (0.30, 0.26, 0.010), (0.26, 0.30, 0.009)] {
            addSparkle(to: &path, center: pt(cx, cy), size: size * w, w: w, h: h)
        }

        return path
    }

    private func addSmokeWisp(to path: inout Path, from start: CGPoint, w: CGFloat, h: CGFloat, dy: CGFloat, dx: CGFloat) {
        let end = CGPoint(x: start.x + dx * w, y: start.y + dy * h)
        let c1 = CGPoint(x: start.x - 0.02 * w, y: start.y + dy * h * 0.4)
        let c2 = CGPoint(x: end.x + 0.02 * w, y: end.y - dy * h * 0.2)
        path.move(to: start)
        path.addCurve(to: end, control1: c1, control2: c2)
        path.addLine(to: CGPoint(x: end.x + 0.008 * w, y: end.y))
        path.addCurve(to: CGPoint(x: start.x + 0.008 * w, y: start.y), control1: CGPoint(x: c2.x + 0.008 * w, y: c2.y), control2: CGPoint(x: c1.x + 0.008 * w, y: c1.y))
        path.closeSubpath()
    }

    private func addSparkle(to path: inout Path, center: CGPoint, size: CGFloat, w: CGFloat, h: CGFloat) {
        let s = size
        let s2 = s * 0.45
        path.move(to: CGPoint(x: center.x, y: center.y - s))
        path.addLine(to: CGPoint(x: center.x + s2, y: center.y))
        path.addLine(to: CGPoint(x: center.x, y: center.y + s))
        path.addLine(to: CGPoint(x: center.x - s2, y: center.y))
        path.closeSubpath()
        path.move(to: CGPoint(x: center.x - s, y: center.y))
        path.addLine(to: CGPoint(x: center.x, y: center.y - s2))
        path.addLine(to: CGPoint(x: center.x + s, y: center.y))
        path.addLine(to: CGPoint(x: center.x, y: center.y + s2))
        path.closeSubpath()
    }
}

// MARK: - Magical Loading View (Confetti, petals, sparkles, genie lamp + smoke hero)

struct MagicalLoadingView: View {
    @ObservedObject var generator: DatePlanGeneratorService
    
    @State private var confettiPieces: [LoadingConfettiPiece] = []
    @State private var petalPositions: [CGPoint] = []
    @State private var sparkleOpacity: [Double] = Array(repeating: 0.3, count: 20)
    @State private var sparklePositions: [CGPoint] = []
    @State private var glowOpacity: Double = 0
    @State private var glowScale: CGFloat = 0.4
    @State private var titleOpacity: Double = 0
    @State private var titleScale: CGFloat = 0.92
    @State private var tipOfTheDay: String = "Pick a place you've been to or have vetted—don't experiment on a first date."
    
    /// Route progress for trim animation (0...1).
    private var routeProgress: CGFloat {
        CGFloat(generator.generationProgress)
    }
    
    /// Tips of the day for date planning (shown during loading).
    private static let tipsOfTheDay: [String] = [
        "Pick a place you've been to or have vetted—don't experiment on a first date.",
        "Match the plan to how well you know them—coffee for first meet, dinner if you've already clicked.",
        "Have a backup if the place is closed or packed.",
        "Suggest a specific time and place; 'we'll figure it out' can fizzle.",
        "Think about logistics: parking, transit, accessibility.",
        "If they have dietary needs or preferences, choose a place that works.",
        "A little research goes a long way—check hours, dress code, noise level.",
        "Leave room for the date to extend—don't book back-to-back things.",
        "Consider the time of day: brunch, lunch, dinner, or drinks each have a different vibe.",
        "Have one or two backup ideas in case they're not into the first suggestion.",
        "Don't over-plan; leave room for spontaneity.",
        "If the date is outdoors, have a rain or weather backup.",
        "Choose a place where you can hear each other.",
        "If you're meeting for the first time, pick somewhere public and easy to find.",
        "A walk or activity can ease pressure compared to just sitting across a table.",
        "If you're not sure, suggest two options and let them choose.",
        "Consider budget: suggest something in a range that works for both.",
        "A first date doesn't have to be dinner; coffee, drinks, or a walk are valid.",
        "Your goal is to create a setting where you can connect—everything else supports that.",
    ]
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.luxuryMaroon
                    .ignoresSafeArea()
                
                // 1. Confetti
                ForEach(confettiPieces) { piece in
                    LoadingConfettiShape(style: piece.style)
                        .fill(piece.color)
                        .frame(width: piece.size, height: piece.size * (piece.style == .rect ? 0.6 : 1))
                        .rotationEffect(.degrees(piece.rotation))
                        .position(x: piece.x, y: piece.y)
                        .opacity(piece.opacity)
                }
                
                // 2. Floating petals
                ForEach(0..<8, id: \.self) { index in
                    RosePetal()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hex: "8B0000").opacity(0.4),
                                    Color(hex: "DC143C").opacity(0.2)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 20, height: 25)
                        .rotationEffect(.degrees(Double(index * 45)))
                        .position(petalPosition(for: index, in: geo.size))
                        .animation(
                            .easeInOut(duration: Double.random(in: 4...7))
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.3),
                            value: petalPositions
                        )
                }
                
                // 3. Golden sparkles
                ForEach(0..<20, id: \.self) { index in
                    if index < sparklePositions.count {
                        Image(systemName: "sparkle")
                            .font(.system(size: [10, 12, 14, 16][index % 4]))
                            .foregroundColor(Color.luxuryGold)
                            .opacity(sparkleOpacity[index])
                            .position(sparklePositions[index])
                    }
                }
                
                // Soft radial glow behind hero
                RadialGradient(
                    colors: [
                        Color.luxuryGold.opacity(0.12),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 40,
                    endRadius: 220
                )
                .opacity(glowOpacity)
                .scaleEffect(glowScale)
                
                // 4 + 5: Hero on top, then text block below (so both fully visible)
                VStack(spacing: 0) {
                    Spacer(minLength: 20)
                    GenieLampHeroView(progress: routeProgress)
                        .frame(width: 140, height: 200)
                    Spacer(minLength: 16)
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 12) {
                            Text("Crafting your date plan")
                                .font(Font.tangerine(32, weight: .bold))
                                .foregroundColor(Color.luxuryCream)
                                .multilineTextAlignment(.center)
                                .opacity(titleOpacity)
                                .scaleEffect(titleScale)
                            
                            Text("Hidden gems & perfect timing")
                                .font(Font.inter(15, weight: .regular))
                                .foregroundColor(Color.luxuryCreamMuted)
                                .opacity(titleOpacity)
                            
                            Text("Tip of the day: \(tipOfTheDay)")
                                .font(Font.inter(13, weight: .regular))
                                .foregroundColor(Color.luxuryCreamMuted.opacity(0.95))
                                .multilineTextAlignment(.center)
                                .lineLimit(4)
                                .opacity(titleOpacity)
                            
                            VStack(spacing: 6) {
                                GeometryReader { geometry in
                                    ZStack(alignment: .leading) {
                                        Capsule()
                                            .fill(Color.luxuryMaroonLight)
                                            .frame(height: 5)
                                        Capsule()
                                            .fill(LinearGradient.goldShimmer)
                                            .frame(width: max(0, geometry.size.width * CGFloat(generator.generationProgress)), height: 5)
                                            .animation(.easeInOut(duration: 0.5), value: generator.generationProgress)
                                    }
                                }
                                .frame(height: 8)
                                .padding(.horizontal, 24)
                                
                                Text("\(Int(generator.generationProgress * 100))%")
                                    .font(Font.inter(12, weight: .medium))
                                    .foregroundColor(Color.luxuryGold)
                            }
                            .opacity(titleOpacity)
                            
                            Text("Magic takes a moment")
                                .font(Font.inter(11, weight: .regular))
                                .foregroundColor(Color.luxuryMuted)
                                .opacity(titleOpacity)
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 40)
                    }
                    .frame(maxHeight: geo.size.height * 0.45)
                }
            }
        }
        .onAppear {
            tipOfTheDay = Self.tipsOfTheDay.randomElement() ?? Self.tipsOfTheDay[0]
            let size = UIScreen.main.bounds.size
            spawnConfetti(in: size)
            animateConfetti(delay: 0.3)
            petalPositions = (0..<8).map { _ in
                CGPoint(
                    x: CGFloat.random(in: 50...(size.width - 50)),
                    y: CGFloat.random(in: 100...(size.height - 100))
                )
            }
            sparklePositions = (0..<20).map { _ in
                CGPoint(
                    x: CGFloat.random(in: 20...(size.width - 20)),
                    y: CGFloat.random(in: 100...(size.height - 100))
                )
            }
            startSparkleAnimations()
            runEntryAnimation()
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
        var pieces: [LoadingConfettiPiece] = []
        for i in 0..<36 {
            let angle = Double(i) * 10 * .pi / 180
            let dist: CGFloat = CGFloat.random(in: 50...100)
            pieces.append(LoadingConfettiPiece(
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
    
    private func startSparkleAnimations() {
        for i in 0..<20 {
            withAnimation(
                .easeInOut(duration: Double.random(in: 1.5...3))
                .repeatForever(autoreverses: true)
                .delay(Double.random(in: 0...2))
            ) {
                sparkleOpacity[i] = Double.random(in: 0.5...1.0)
            }
        }
    }
    
    private func runEntryAnimation() {
        withAnimation(.easeOut(duration: 0.5).delay(0.25)) {
            glowOpacity = 0.9
            glowScale = 1.2
        }
        withAnimation(.easeOut(duration: 0.5).delay(0.5)) {
            titleOpacity = 1
            titleScale = 1
        }
    }
    
    private func petalPosition(for index: Int, in size: CGSize) -> CGPoint {
        guard index < petalPositions.count else {
            return CGPoint(x: size.width / 2, y: size.height / 2)
        }
        return petalPositions[index]
    }
}

// MARK: - Confetti (loading screen)

private struct LoadingConfettiPiece: Identifiable {
    let id: Int
    var x: CGFloat
    var y: CGFloat
    let size: CGFloat
    let color: Color
    let style: LoadingConfettiStyle
    var rotation: Double
    var opacity: Double
}

private enum LoadingConfettiStyle {
    case circle, rect
}

private struct LoadingConfettiShape: Shape {
    var style: LoadingConfettiStyle
    func path(in rect: CGRect) -> Path {
        switch style {
        case .circle: return Path(ellipseIn: rect)
        case .rect: return Path(roundedRect: rect, cornerRadius: 1)
        }
    }
}

// MARK: - Rose Petal Shape

struct RosePetal: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        path.move(to: CGPoint(x: width / 2, y: 0))
        path.addQuadCurve(
            to: CGPoint(x: width, y: height * 0.6),
            control: CGPoint(x: width * 1.2, y: height * 0.3)
        )
        path.addQuadCurve(
            to: CGPoint(x: width / 2, y: height),
            control: CGPoint(x: width * 0.8, y: height)
        )
        path.addQuadCurve(
            to: CGPoint(x: 0, y: height * 0.6),
            control: CGPoint(x: width * 0.2, y: height)
        )
        path.addQuadCurve(
            to: CGPoint(x: width / 2, y: 0),
            control: CGPoint(x: -width * 0.2, y: height * 0.3)
        )
        return path
    }
}

// MARK: - Genie Lamp Hero (golden lamp image + glow + swirling smoke)

private struct GenieLampHeroView: View {
    var progress: CGFloat
    
    @State private var smokeRise: CGFloat = 0
    @State private var smokeSwirl: Double = 0
    @State private var smokeOpacity1: Double = 0.5
    @State private var smokeOpacity2: Double = 0.4
    @State private var pulseScale: CGFloat = 0.98
    @State private var shimmerOffset: CGFloat = -80
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Swirling smoke wisps (golden motion behind lamp)
            SwirlingSmokeWisp(phase: smokeSwirl, rise: smokeRise, opacity: smokeOpacity1)
                .frame(width: 85, height: 95)
                .offset(y: -18 - smokeRise)
            SwirlingSmokeWisp(phase: smokeSwirl + .pi * 0.6, rise: smokeRise * 0.9, opacity: smokeOpacity2)
                .frame(width: 65, height: 75)
                .offset(x: 10, y: -28 - smokeRise * 0.9)
            
            // Glow under lamp
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.luxuryGold.opacity(0.4),
                            Color.luxuryGold.opacity(0.1),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 50
                    )
                )
                .frame(width: 100, height: 24)
                .blur(radius: 8)
                .offset(y: -8)
            
            // Golden genie lamp (vector shape — crisp at any scale)
            ZStack {
                GenieLampShape()
                    .fill(LinearGradient.goldShimmer)
                    .scaleEffect(pulseScale)

                // Shimmer gleam overlay
                LinearGradient(
                    colors: [
                        Color.clear,
                        Color.luxuryGoldLight.opacity(0.35),
                        Color.clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: 60, height: 200)
                .offset(x: shimmerOffset)
                .mask(GenieLampShape())
            }
            .frame(width: 140, height: 200)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                smokeRise = 40
                smokeOpacity1 = 0.22
                smokeOpacity2 = 0.16
            }
            withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                smokeSwirl = .pi * 2
            }
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pulseScale = 1.02
            }
            withAnimation(.linear(duration: 2.2).repeatForever(autoreverses: true)) {
                shimmerOffset = 80
            }
        }
    }
}

private struct SwirlingSmokeWisp: View {
    var phase: Double
    var rise: CGFloat
    var opacity: Double
    
    var body: some View {
        Ellipse()
            .fill(
                LinearGradient(
                    colors: [
                        Color.luxuryCream.opacity(opacity),
                        Color.luxuryGold.opacity(opacity * 0.5),
                        Color.clear
                    ],
                    startPoint: .bottom,
                    endPoint: .top
                )
            )
            .blur(radius: 7)
            .rotationEffect(.radians(phase))
            .scaleEffect(x: 1.0 + sin(phase) * 0.15, y: 1.0)
    }
}

// MARK: - Generation Error View

struct GenerationErrorView: View {
    let error: DatePlanGeneratorService.GenerationError
    let onRetry: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        ZStack {
            Color.luxuryMaroon
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(LinearGradient.goldShimmer)
                
                VStack(spacing: 12) {
                    Text("Something went wrong")
                        .font(Font.header(24, weight: .semibold))
                        .foregroundColor(Color.luxuryGold)
                    
                    Text(error.localizedDescription)
                        .font(Font.inter(14, weight: .regular))
                        .foregroundColor(Color.luxuryCreamMuted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                VStack(spacing: 16) {
                    Button("Try Again", action: onRetry)
                        .buttonStyle(LuxuryGoldButtonStyle())
                    
                    Button("Cancel", action: onCancel)
                        .buttonStyle(LuxuryOutlineButtonStyle())
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    MagicalLoadingView(generator: DatePlanGeneratorService.shared)
}
