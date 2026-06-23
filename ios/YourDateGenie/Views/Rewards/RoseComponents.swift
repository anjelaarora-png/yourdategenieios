import SwiftUI

// MARK: - Shared Rose UI components (Charcoal Maroon)
//
// Discipline (spec §1 + design rules): accentGold appears EXACTLY ONCE per
// screen — always as `RosePrimaryButton` (the single gold action). Everything
// else here is cream / muted / maroon-outline so the hierarchy stays clean.

// MARK: Primary CTA — the one gold element per screen

struct RosePrimaryButton: View {
    let title: String
    var action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Font.inter(16, weight: .semibold))
                .foregroundColor(Color.backgroundPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.accentGold)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(RosePressStyle(reduceMotion: reduceMotion))
    }
}

/// Subtle press feedback; flattens scale animation under Reduce Motion.
struct RosePressStyle: ButtonStyle {
    var reduceMotion: Bool = false
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.9 : 1)
            .scaleEffect(reduceMotion ? 1 : (configuration.isPressed ? 0.98 : 1))
            .animation(reduceMotion ? nil : .easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: Demoted underlined link (secondary action)

struct RoseGhostLink: View {
    let title: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Font.inter(14, weight: .medium))
                .foregroundColor(Color.luxuryCreamMuted)
                .underline()
        }
        .buttonStyle(.plain)
    }
}

// MARK: Progress bar — cream fill on a dark maroon track (never gold)

struct RoseProgressBar: View {
    /// 0…1
    let progress: Double
    var height: CGFloat = 7
    var fill: Color = .textPrimary

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animated: Double = 0

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.roseTrack)
                Capsule()
                    .fill(fill)
                    .frame(width: max(0, geo.size.width * animated))
            }
        }
        .frame(height: height)
        .onAppear {
            if reduceMotion { animated = clamped }
            else { withAnimation(.easeOut(duration: 0.7)) { animated = clamped } }
        }
        .onChange(of: progress) { _ in
            if reduceMotion { animated = clamped }
            else { withAnimation(.easeOut(duration: 0.5)) { animated = clamped } }
        }
        .accessibilityElement()
        .accessibilityLabel("Progress")
        .accessibilityValue("\(Int(clamped * 100)) percent")
    }

    private var clamped: Double { min(1, max(0, progress)) }
}

// MARK: Maroon-outlined info pill

struct RosePill: View {
    let text: String
    var body: some View {
        Text(text)
            .font(Font.inter(11, weight: .semibold))
            .foregroundColor(Color.textPrimary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.accentMaroon.opacity(0.25))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.accentMaroon.opacity(0.55), lineWidth: 1))
    }
}

// MARK: Elevated surface card

struct RoseCard<Content: View>: View {
    var padding: CGFloat = 14
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.surfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.maroonBorderTint, lineWidth: 1)
            )
    }
}

// MARK: Cream stat card (recap numerals)

struct RoseStatCard: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(Font.displaySerif(24, weight: .bold))
                .foregroundColor(Color.textOnCard)
            Text(label)
                .font(Font.inter(11, weight: .regular))
                .foregroundColor(Color.textMutedOnCard)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 8)
        .background(Color.creamCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: Section label (uppercase, tracked)

struct RoseLabel: View {
    let text: String
    var body: some View {
        Text(text.uppercased())
            .font(Font.inter(11, weight: .semibold))
            .tracking(1.5)
            .foregroundColor(Color.luxuryCreamMuted)
    }
}
