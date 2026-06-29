import SwiftUI

// MARK: - Anchor IDs (must match scroll targets in HomeTabView)

enum HomeTutorialAnchor: String, Hashable, CaseIterable {
    case planButton
    case heroPlan
    case tabBar
}

struct HomeTutorialAnchorPreferenceKey: PreferenceKey {
    static var defaultValue: [HomeTutorialAnchor: CGRect] = [:]

    static func reduce(value: inout [HomeTutorialAnchor: CGRect], nextValue: () -> [HomeTutorialAnchor: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}

extension View {
    func homeTutorialAnchor(_ anchor: HomeTutorialAnchor) -> some View {
        background(
            GeometryReader { geo in
                Color.clear.preference(
                    key: HomeTutorialAnchorPreferenceKey.self,
                    value: [anchor: geo.frame(in: .named("homeTutorialSpace"))]
                )
            }
        )
    }
}

// MARK: - Coach-mark overlay

struct HomeTutorialOverlayView: View {
    @Binding var isPresented: Bool
    @Binding var step: Int
    let anchors: [HomeTutorialAnchor: CGRect]

    @State private var pulse = false
    @State private var anchorsReady = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private struct StepContent {
        let anchor: HomeTutorialAnchor
        let icon: String
        let title: String
        let body: String
        let calloutBelowSpotlight: Bool
    }

    private let steps: [StepContent] = [
        StepContent(
            anchor: .planButton,
            icon: "wand.and.stars",
            title: "Plan your perfect date",
            body: "Tap Plan My Next Date. Answer a few quick questions and we'll build a complete evening — venues, timing, and all the details.",
            calloutBelowSpotlight: true
        ),
        StepContent(
            anchor: .heroPlan,
            icon: "heart.fill",
            title: "Your plans live here",
            body: "Saved and upcoming dates show up on Home. Tap any plan to view the route, reserve, or share with your partner.",
            calloutBelowSpotlight: true
        ),
        StepContent(
            anchor: .tabBar,
            icon: "sparkles",
            title: "Explore the app",
            body: "Use the tabs below — Dates, Convo, and You — plus the center + button to plan anytime. Love Notes, Gift Finder, and Memories live in Convo and Dates.",
            calloutBelowSpotlight: false
        )
    ]

    private var current: StepContent {
        steps[min(max(step, 0), steps.count - 1)]
    }

    private var spotlightRect: CGRect? {
        guard let rect = anchors[current.anchor], rect.width > 1, rect.height > 1 else { return nil }
        return rect.insetBy(dx: -10, dy: -8)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                spotlightDimLayer(in: geo.size)
                if let rect = spotlightRect {
                    spotlightRing(for: rect)
                }
                calloutLayer(in: geo.size)
            }
        }
        .opacity(anchorsReady ? 1 : 0)
        .animation(.easeOut(duration: 0.2), value: anchorsReady)
        .ignoresSafeArea()
        .transition(.opacity)
        .onAppear {
            pulse = false
            anchorsReady = spotlightRect != nil
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
        .onChange(of: anchors) { _, _ in
            anchorsReady = spotlightRect != nil
        }
        .onChange(of: step) { _, _ in
            anchorsReady = spotlightRect != nil
            pulse = false
            guard !reduceMotion else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                    pulse = true
                }
            }
        }
    }

    @ViewBuilder
    private func spotlightDimLayer(in size: CGSize) -> some View {
        if let rect = spotlightRect {
            Canvas { context, canvasSize in
                var dimPath = Path(CGRect(origin: .zero, size: canvasSize))
                dimPath.addPath(Path(roundedRect: rect, cornerRadius: 18))
                context.fill(dimPath, with: .color(.black.opacity(0.78)), style: FillStyle(eoFill: true))
            }
            .allowsHitTesting(false)
        } else {
            Color.black.opacity(anchorsReady ? 0.78 : 0.35)
                .allowsHitTesting(false)
        }
    }

    @ViewBuilder
    private func spotlightRing(for rect: CGRect) -> some View {
        RoundedRectangle(cornerRadius: 18)
            .stroke(Color.accentGold, lineWidth: 2.5)
            .frame(width: rect.width, height: rect.height)
            .position(x: rect.midX, y: rect.midY)
            .shadow(color: Color.accentGold.opacity(0.55), radius: pulse ? 14 : 6)
            .scaleEffect(pulse ? 1.03 : 1.0)
            .animation(reduceMotion ? nil : .easeInOut(duration: 1.1).repeatForever(autoreverses: true), value: pulse)
            .allowsHitTesting(false)
    }

    @ViewBuilder
    private func calloutLayer(in size: CGSize) -> some View {
        VStack(spacing: 0) {
            if !current.calloutBelowSpotlight, let rect = spotlightRect {
                Spacer(minLength: max(24, rect.minY - 220))
                calloutCard
                Spacer()
            } else if let rect = spotlightRect {
                Spacer(minLength: min(size.height - 48, rect.maxY + 18))
                calloutCard
                Spacer(minLength: 48)
            } else {
                Spacer()
                calloutCard
                Spacer()
            }
        }
        .padding(.horizontal, 20)
    }

    private var calloutCard: some View {
        VStack(spacing: 18) {
            HStack(spacing: 8) {
                ForEach(0..<steps.count, id: \.self) { i in
                    Capsule()
                        .fill(i == step ? Color.luxuryGold : Color.luxuryMuted.opacity(0.45))
                        .frame(width: i == step ? 22 : 8, height: 8)
                }
                Spacer()
                Button { isPresented = false } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color.luxuryMuted)
                        .frame(width: 32, height: 32)
                        .background(Color.luxeSurfaceTint)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.luxuryGold.opacity(0.18))
                        .frame(width: 52, height: 52)
                    Image(systemName: current.icon)
                        .font(.system(size: 22))
                        .foregroundStyle(LinearGradient.goldShimmer)
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text(current.title)
                        .font(Font.header(18, weight: .bold))
                        .foregroundColor(Color.luxuryCream)
                    Text(current.body)
                        .font(Font.bodySans(14, weight: .regular))
                        .foregroundColor(Color.luxuryCreamMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 12) {
                if step < steps.count - 1 {
                    Button("Skip") { isPresented = false }
                        .font(Font.bodySans(15, weight: .medium))
                        .foregroundColor(Color.luxuryMuted)
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                Button {
                    advanceOrDismiss()
                } label: {
                    HStack(spacing: 8) {
                        Text(step == steps.count - 1 ? "Got it!" : "Next")
                        Image(systemName: step == steps.count - 1 ? "checkmark" : "arrow.right")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(LuxuryGoldButtonStyle(isSmall: true))
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.surfaceElevated)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.accentGold.opacity(0.35), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.35), radius: 24, y: 8)
    }

    private func advanceOrDismiss() {
        if step < steps.count - 1 {
            withAnimation(.spring(response: 0.42, dampingFraction: 0.86)) {
                step += 1
            }
        } else {
            withAnimation(.easeOut(duration: 0.25)) {
                isPresented = false
            }
        }
    }
}
