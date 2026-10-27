import SwiftUI

// MARK: - Aladdin / genie lamp (outline to match Icons8-style lamp)
private struct AladdinLampShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        func x(_ u: CGFloat) -> CGFloat { rect.minX + u * w }
        func y(_ u: CGFloat) -> CGFloat { rect.minY + u * h }
        var p = Path()

        // Body: single ellipse (main vase)
        p.addEllipse(in: CGRect(x: x(0.26), y: y(0.38), width: w * 0.48, height: h * 0.38))

        // Lid: small ellipse on top of body
        p.addEllipse(in: CGRect(x: x(0.38), y: y(0.26), width: w * 0.24, height: h * 0.14))

        // Spout: curved tube (left side) — simple ribbon so stroke is clear
        p.move(to: CGPoint(x: x(0.30), y: y(0.54)))
        p.addQuadCurve(to: CGPoint(x: x(0.08), y: y(0.26)), control: CGPoint(x: x(0.00), y: y(0.38)))
        p.addLine(to: CGPoint(x: x(0.12), y: y(0.28)))
        p.addQuadCurve(to: CGPoint(x: x(0.34), y: y(0.56)), control: CGPoint(x: x(0.16), y: y(0.42)))
        p.closeSubpath()

        // Handle: C-shape on right — arc from bottom to top, then bridge to inner arc
        let hx = x(0.76)
        let hy = y(0.52)
        let ro = w * 0.08
        let ri = w * 0.045
        p.addArc(center: CGPoint(x: hx, y: hy), radius: ro, startAngle: .degrees(-90), endAngle: .degrees(90), clockwise: false)
        p.addLine(to: CGPoint(x: hx, y: hy - ri))
        p.addArc(center: CGPoint(x: hx, y: hy), radius: ri, startAngle: .degrees(90), endAngle: .degrees(-90), clockwise: false)
        p.closeSubpath()

        return p
    }
}

// MARK: - Magical Loading View (Confetti, petals, sparkles, genie lamp + smoke hero)

struct MagicalLoadingView: View {
    @ObservedObject var generator: DatePlanGeneratorService
    var onCancel: (() -> Void)? = nil

    private static let sparkleCount = 6
    
    @State private var confettiPieces: [LoadingConfettiPiece] = []
    @State private var petalPositions: [CGPoint] = []
    @State private var sparkleOpacity: [Double] = Array(repeating: 0.3, count: sparkleCount)
    @State private var sparklePositions: [CGPoint] = []
    @State private var glowOpacity: Double = 0
    @State private var glowScale: CGFloat = 0.4
    @State private var titleOpacity: Double = 0
    @State private var titleScale: CGFloat = 0.92
    @State private var tipOfTheDay: String = "Pick a place you've been to or have vetted—don't experiment on a first date."
    
    @State private var petalAnimationDurations: [Double] = Array(repeating: 5.0, count: 3)
    
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
    
    /// Honest, coarse milestones keyed to generator progress (no invented counts).
    private static let milestones: [(threshold: Double, title: String)] = [
        (0.25, "Finding spots near your starting point"),
        (0.50, "Checking they're open for your night"),
        (0.75, "Timing the walk between stops"),
        (1.00, "Writing your three options"),
    ]

    var body: some View {
        ZStack {
            Color.ydgBase
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: YDGSpace.sm) {
                    Text("\(Int(generator.generationProgress * 100))%")
                        // Inter, not Playfair: Playfair's old-style figures read as decoration, not a number.
                        .font(.ydgSans(56, weight: .semibold))
                        .tracking(-1.7)
                        .foregroundColor(Color.ydgAccent)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .animation(.easeInOut(duration: 0.4), value: generator.generationProgress)
                        .accessibilityLabel("\(Int(generator.generationProgress * 100)) percent")

                    Text("Crafting your date plan")
                        .ydgText(.title1)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)

                    Text("This usually takes under a minute.")
                        .ydgText(.body, color: .ydgTextSecondary)
                }
                .padding(.top, YDGSpace.xxl + YDGSpace.lg)
                .padding(.bottom, YDGSpace.xl)

                VStack(alignment: .leading, spacing: 18) {
                    ForEach(Array(Self.milestones.enumerated()), id: \.offset) { index, milestone in
                        milestoneRow(index: index, title: milestone.title)
                    }
                }

                Spacer(minLength: YDGSpace.lg)

                VStack(alignment: .leading, spacing: YDGSpace.xxs) {
                    Text("Tip of the day")
                        .ydgText(.caption, color: .ydgHighlight)
                    Text(tipOfTheDay)
                        .ydgText(.subhead, weight: .regular)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .ydgCard()

                if let onCancel {
                    Button("Cancel", action: onCancel)
                        .buttonStyle(.ydgTertiary)
                        .frame(maxWidth: .infinity)
                        .padding(.top, YDGSpace.sm)
                }
            }
            .padding(.horizontal, YDGSpace.margin)
            .padding(.bottom, YDGSpace.lg)
        }
        .onAppear {
            tipOfTheDay = Self.tipsOfTheDay.randomElement() ?? Self.tipsOfTheDay[0]
        }
    }

    @ViewBuilder
    private func milestoneRow(index: Int, title: String) -> some View {
        let progress = generator.generationProgress
        let previous = index == 0 ? 0 : Self.milestones[index - 1].threshold
        let isDone = progress >= Self.milestones[index].threshold
        let isActive = !isDone && progress >= previous

        HStack(spacing: 14) {
            ZStack {
                if isDone {
                    Circle().fill(Color.ydgAccent)
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color.ydgTextOnAccent)
                } else if isActive {
                    Circle().stroke(Color.ydgBorder, lineWidth: 2)
                    ProgressView()
                        .controlSize(.mini)
                        .tint(Color.ydgAccent)
                } else {
                    Circle().stroke(Color.ydgBorder, lineWidth: 2)
                }
            }
            .frame(width: 24, height: 24)

            Text(title)
                .ydgText(.body, weight: isActive ? .semibold : .regular,
                         color: isDone || isActive ? .ydgTextPrimary : .ydgTextTertiary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityValue(isDone ? "Done" : isActive ? "In progress" : "Waiting")
    }
    
    private func spawnConfetti(in size: CGSize) {
        let centerX = size.width / 2
        let centerY = size.height / 2
        let colors: [Color] = [
            Color.luxuryGold,
            Color.luxuryGoldLight,
            Color.luxuryCream,
            Color.luxeSurfaceTintStrong,
            Color.luxuryGoldDark
        ]
        var pieces: [LoadingConfettiPiece] = []
        for i in 0..<12 {
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
        // Keep confetti in upper area so it doesn't cover the text block
        let confettiMaxY = size.height * 0.38
        var endStates: [(x: CGFloat, y: CGFloat, opacity: Double, rotation: Double)] = []
        for _ in confettiPieces.indices {
            endStates.append((
                centerX + CGFloat.random(in: -170...170),
                CGFloat.random(in: 60...(confettiMaxY)),
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
        for i in sparkleOpacity.indices {
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

// MARK: - Genie Lamp Hero (golden lamp + glow blended to maroon background)

private struct GenieLampHeroView: View {
    var progress: CGFloat
    
    @State private var smokeRise: CGFloat = 0
    @State private var smokeSwirl: Double = 0
    @State private var smokeOpacity1: Double = 0.5
    @State private var smokeOpacity2: Double = 0.4
    @State private var pulseScale: CGFloat = 0.94
    @State private var iconOpacity: Double = 0.9
    @State private var glowScale: CGFloat = 0.85
    @State private var glowOpacity: Double = 0.5

    var body: some View {
        ZStack(alignment: .bottom) {
            // Big flashy glow behind bulb (pulses)
            RadialGradient(
                colors: [
                    Color.luxuryGold.opacity(glowOpacity),
                    Color.luxuryGold.opacity(glowOpacity * 0.4),
                    Color.luxeSurfaceTint,
                    Color.clear
                ],
                center: .center,
                startRadius: 10,
                endRadius: 140
            )
            .frame(width: 280, height: 320)
            .scaleEffect(glowScale)
            .blur(radius: 30)
            .offset(y: -10)

            // Soft halo
            RadialGradient(
                colors: [
                    Color.luxuryGold.opacity(0.12),
                    Color.luxeSurfaceTintStrong,
                    Color.clear
                ],
                center: .center,
                startRadius: 30,
                endRadius: 130
            )
            .frame(width: 240, height: 280)
            .blur(radius: 22)
            .offset(y: -15)

            // Swirling wisps
            SwirlingSmokeWisp(phase: smokeSwirl, rise: smokeRise, opacity: smokeOpacity1)
                .frame(width: 85, height: 95)
                .offset(y: -18 - smokeRise)
            SwirlingSmokeWisp(phase: smokeSwirl + .pi * 0.6, rise: smokeRise * 0.9, opacity: smokeOpacity2)
                .frame(width: 65, height: 75)
                .offset(x: 10, y: -28 - smokeRise * 0.9)

            // Glow under bulb
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.luxuryGold.opacity(0.45),
                            Color.luxuryGold.opacity(0.15),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 60
                    )
                )
                .frame(width: 130, height: 32)
                .blur(radius: 14)
                .offset(y: -12)

            // Lightbulb with glow
            ZStack {
                Image(systemName: "lightbulb")
                    .font(.system(size: 100, weight: .medium))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(LinearGradient.goldShimmer)
                    .shadow(color: Color.luxuryGold.opacity(0.8), radius: 25, x: 0, y: 0)
                    .shadow(color: Color.luxuryGoldLight.opacity(0.5), radius: 40, x: 0, y: 0)
            }
            .scaleEffect(pulseScale)
            .opacity(iconOpacity)
            .shadow(color: Color.luxuryGold.opacity(0.5), radius: 24, x: 0, y: 4)
        }
        .frame(width: 140, height: 200)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                smokeRise = 40
                smokeOpacity1 = 0.22
                smokeOpacity2 = 0.16
            }
            withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                smokeSwirl = .pi * 2
            }
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                pulseScale = 1.08
                iconOpacity = 1.0
                glowScale = 1.15
                glowOpacity = 0.75
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
                        Color.luxeSurfaceTintStrong.opacity(opacity * 0.3),
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
            Color.backgroundPrimary
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(LinearGradient.goldShimmer)
                
                VStack(spacing: 12) {
                    Text("Something went wrong")
                        .font(Font.bodySerif(24, weight: .semibold))
                        .foregroundColor(Color.luxuryGold)
                    
                    Text(error.localizedDescription)
                        .font(Font.bodySans(14, weight: .regular))
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
