import SwiftUI

// MARK: - Magical Loading View

struct MagicalLoadingView: View {
    @ObservedObject var generator: DatePlanGeneratorService
    
    @State private var ringRotation: Double = 0
    @State private var sparkleOpacity: [Double] = Array(repeating: 0.3, count: 20)
    @State private var petalPositions: [CGPoint] = []
    @State private var messageIndex = 0
    @State private var messageOpacity: Double = 1
    @State private var ringPulse = false
    
    private let loadingMessages = [
        "Crafting your perfect evening...",
        "Consulting the stars...",
        "Finding hidden gems...",
        "Adding the magic touches...",
        "Curating romantic moments...",
        "Discovering secret spots...",
        "Almost ready..."
    ]
    
    var body: some View {
        ZStack {
            backgroundGradient
            
            floatingSparkles
            
            floatingPetals
            
            VStack(spacing: 40) {
                Spacer()
                
                animatedRing
                    .scaleEffect(ringPulse ? 1.04 : 1.0)
                    .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: ringPulse)
                
                statusText
                
                progressBar
                
                Spacer()
                
                brandFooter
            }
            .padding(.horizontal, 40)
        }
        .ignoresSafeArea()
        .onAppear {
            startAnimations()
            let p = generator.generationProgress
            ringPulse = p >= 0.2 && p < 1.0
        }
        .onChange(of: generator.generationProgress) { _, progress in
            ringPulse = progress >= 0.2 && progress < 1.0
        }
    }
    
    // MARK: - Background
    
    private var backgroundGradient: some View {
        ZStack {
            Color.luxuryMaroon
            
            RadialGradient(
                gradient: Gradient(colors: [
                    Color.luxuryGold.opacity(0.15),
                    Color.clear
                ]),
                center: .center,
                startRadius: 50,
                endRadius: 300
            )
            
            RadialGradient.maroonVignette
        }
    }
    
    // MARK: - Animated Ring
    
    private var animatedRing: some View {
        ZStack {
            // Outer glow
            Circle()
                .stroke(
                    LinearGradient.goldShimmer,
                    lineWidth: 3
                )
                .frame(width: 150, height: 150)
                .blur(radius: 10)
                .opacity(0.5)
            
            // Main ring
            Circle()
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [
                            Color.luxuryGold.opacity(0.1),
                            Color.luxuryGold,
                            Color.luxuryGoldLight,
                            Color.luxuryGold,
                            Color.luxuryGold.opacity(0.1)
                        ]),
                        center: .center
                    ),
                    lineWidth: 4
                )
                .frame(width: 140, height: 140)
                .rotationEffect(.degrees(ringRotation))
            
            // Logo
            Image("Logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 80, height: 80)
                .shadow(color: Color.luxuryGold.opacity(0.5), radius: 20)
        }
    }
    
    // MARK: - Status Text
    
    private var statusText: some View {
        VStack(spacing: 16) {
            Text(generator.currentStatusMessage)
                .font(Font.header(24, weight: .semibold))
                .foregroundColor(Color.luxuryGold)
                .opacity(messageOpacity)
                .multilineTextAlignment(.center)
                .animation(.easeInOut(duration: 0.3), value: generator.currentStatusMessage)
            
            Text("Your Genie is working magic")
                .font(Font.playfairItalic(14))
                .foregroundColor(Color.luxuryCreamMuted)
        }
    }
    
    // MARK: - Progress Bar
    
    private var progressBar: some View {
        VStack(spacing: 12) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    Capsule()
                        .fill(Color.luxuryMaroonLight)
                        .frame(height: 6)
                    
                    // Progress fill
                    Capsule()
                        .fill(LinearGradient.goldShimmer)
                        .frame(width: geometry.size.width * generator.generationProgress, height: 6)
                        .animation(.easeInOut(duration: 0.5), value: generator.generationProgress)
                    
                    // Glow effect on progress tip
                    if generator.generationProgress > 0 {
                        Circle()
                            .fill(Color.luxuryGold)
                            .frame(width: 12, height: 12)
                            .blur(radius: 6)
                            .offset(x: geometry.size.width * generator.generationProgress - 6)
                            .animation(.easeInOut(duration: 0.5), value: generator.generationProgress)
                    }
                }
            }
            .frame(height: 12)
            
            Text("\(Int(generator.generationProgress * 100))%")
                .font(Font.inter(12, weight: .medium))
                .foregroundColor(Color.luxuryGold)
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Floating Sparkles
    
    private var floatingSparkles: some View {
        GeometryReader { geometry in
            ForEach(0..<20, id: \.self) { index in
                Image(systemName: "sparkle")
                    .font(.system(size: CGFloat.random(in: 8...16)))
                    .foregroundColor(Color.luxuryGold)
                    .opacity(sparkleOpacity[index])
                    .position(
                        x: CGFloat.random(in: 20...(geometry.size.width - 20)),
                        y: CGFloat.random(in: 100...(geometry.size.height - 100))
                    )
            }
        }
    }
    
    // MARK: - Floating Petals
    
    private var floatingPetals: some View {
        GeometryReader { geometry in
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
                    .position(petalPosition(for: index, in: geometry.size))
                    .animation(
                        .easeInOut(duration: Double.random(in: 4...7))
                        .repeatForever(autoreverses: true)
                        .delay(Double(index) * 0.3),
                        value: petalPositions
                    )
            }
        }
    }
    
    // MARK: - Brand Footer
    
    private var brandFooter: some View {
        VStack(spacing: 8) {
            Image("Logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 60, height: 60)
                .opacity(0.6)
            
            Text("Magic takes a moment")
                .font(Font.inter(11, weight: .regular))
                .foregroundColor(Color.luxuryMuted)
        }
        .padding(.bottom, 40)
    }
    
    // MARK: - Animations
    
    private func startAnimations() {
        // Ring rotation
        withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
            ringRotation = 360
        }
        
        // Sparkle animations
        for i in 0..<20 {
            withAnimation(
                .easeInOut(duration: Double.random(in: 1.5...3))
                .repeatForever(autoreverses: true)
                .delay(Double.random(in: 0...2))
            ) {
                sparkleOpacity[i] = Double.random(in: 0.5...1.0)
            }
        }
        
        // Initialize petal positions
        petalPositions = (0..<8).map { _ in
            CGPoint(
                x: CGFloat.random(in: 50...350),
                y: CGFloat.random(in: 100...700)
            )
        }
    }
    
    private func petalPosition(for index: Int, in size: CGSize) -> CGPoint {
        guard index < petalPositions.count else {
            return CGPoint(x: size.width / 2, y: size.height / 2)
        }
        return petalPositions[index]
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
