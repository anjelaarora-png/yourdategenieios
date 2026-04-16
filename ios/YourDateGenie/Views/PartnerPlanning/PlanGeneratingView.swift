import SwiftUI

// MARK: - Plan Generating View
// Shown to both users while date options are being generated.
// Polls phase every 2s; auto-dismisses when phase reaches options_ready_for_ranking.

struct PlanGeneratingView: View {
    let sessionId: String
    let role: PartnerRole

    @EnvironmentObject var coordinator: NavigationCoordinator
    @StateObject private var partnerManager = PartnerSessionManager.shared
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var pulseScale: CGFloat = 1.0
    @State private var shimmerOffset: CGFloat = -1.0
    @State private var messageIndex: Int = 0
    @State private var dotCount: Int = 1
    @State private var dotTimer: Timer?

    private let progressMessages = [
        "Combining your preferences…",
        "Finding overlapping vibes…",
        "Crafting options you'll both love…",
        "Checking timing and logistics…",
        "Adding a touch of magic…",
        "Almost ready…"
    ]

    var body: some View {
        ZStack {
            Color.luxuryMaroon.ignoresSafeArea()
            FloatingParticlesView().ignoresSafeArea().opacity(0.5)

            VStack(spacing: 40) {
                Spacer()
                orbAnimation
                progressText
                Spacer()
                phaseStatusPill
                    .padding(.bottom, 40)
            }
            .padding(.horizontal, 32)
        }
        .onAppear {
            startAnimations()
        }
        .onDisappear {
            dotTimer?.invalidate()
        }
        .onChange(of: partnerManager.currentPhase) { phase in
            if phase == .optionsReadyForRanking || phase == .finalOptionSelected {
                dotTimer?.invalidate()
            }
        }
        // Auto-advance when phase changes via the coordinator's phase observer
        .onChange(of: coordinator.activeSheet?.id) { _ in }
    }

    // MARK: - Orb animation

    private var orbAnimation: some View {
        ZStack {
            // Outer pulse ring
            Circle()
                .stroke(Color.luxuryGold.opacity(0.15), lineWidth: 1)
                .frame(width: 140, height: 140)
                .scaleEffect(pulseScale)

            // Mid ring
            Circle()
                .stroke(Color.luxuryGold.opacity(0.3), lineWidth: 1.5)
                .frame(width: 110, height: 110)

            // Inner filled orb
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.luxuryGold.opacity(0.9), Color.luxuryGold.opacity(0.3)],
                        center: .center,
                        startRadius: 10,
                        endRadius: 50
                    )
                )
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: "heart.fill")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(Color.luxuryMaroon)
                )

            // Shimmer arc
            Circle()
                .trim(from: 0, to: 0.3)
                .stroke(Color.luxuryGold, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .frame(width: 110, height: 110)
                .rotationEffect(.degrees(shimmerOffset * 360))
        }
    }

    // MARK: - Progress text

    private var progressText: some View {
        VStack(spacing: 16) {
            Text("Creating your options")
                .font(Font.tangerine(38, weight: .bold))
                .italic()
                .foregroundColor(Color.luxuryGold)
                .multilineTextAlignment(.center)

            Text(progressMessages[messageIndex] + String(repeating: ".", count: dotCount))
                .font(Font.bodySans(15, weight: .regular))
                .foregroundColor(Color.luxuryCreamMuted)
                .multilineTextAlignment(.center)
                .animation(.easeInOut(duration: 0.3), value: messageIndex)
                .frame(minHeight: 24)
        }
    }

    // MARK: - Phase pill

    private var phaseStatusPill: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color.luxuryGold)
                .frame(width: 6, height: 6)
                .opacity(Double((dotCount % 3) + 1) / 3.0)
            Text(partnerManager.currentPhase.displayLabel)
                .font(Font.bodySans(12, weight: .semibold))
                .tracking(1.5)
                .foregroundColor(Color.luxuryGold.opacity(0.8))
                .textCase(.uppercase)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.luxuryMaroonLight.opacity(0.6))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.luxuryGold.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - Animations

    private func startAnimations() {
        guard !reduceMotion else {
            // Static state for Reduce Motion — just cycle messages slowly
            dotTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
                messageIndex = (messageIndex + 1) % progressMessages.count
            }
            return
        }
        // Pulse
        withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
            pulseScale = 1.12
        }
        // Shimmer spin
        withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
            shimmerOffset = 1.0
        }
        // Cycling dots + messages
        dotTimer = Timer.scheduledTimer(withTimeInterval: 0.6, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.2)) {
                dotCount = (dotCount % 3) + 1
                if dotCount == 1 {
                    messageIndex = (messageIndex + 1) % progressMessages.count
                }
            }
        }
    }
}

#Preview("Generating") {
    PlanGeneratingView(sessionId: "preview", role: .inviter)
        .environmentObject(NavigationCoordinator.shared)
}
