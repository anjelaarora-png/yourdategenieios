import SwiftUI

/// 3-slide partner onboarding shown before the advertising application.
/// Explains the problem we solve and the benefit of advertising to couples.
struct BusinessOnboardingView: View {
    let onComplete: () -> Void
    let onSkip: () -> Void

    @State private var slide = 0

    private struct Slide {
        let icon: String
        let pill: String
        let title: String
        let body: String
        let cardTitle: String
        let cardBody: String
    }

    private let slides: [Slide] = [
        Slide(
            icon: "person.2.fill",
            pill: "Why join our platform",
            title: "Couples are already planning tonight",
            body: "Your Date Genie builds full date nights — not random banner ads. When a couple searches your city and vibe, your spot can appear as a featured stop in their itinerary.",
            cardTitle: "The problem we solve",
            cardBody: "Empty weeknights & slow discovery — couples want great local spots but don’t know you exist mid-plan."
        ),
        Slide(
            icon: "location.fill",
            pill: "Intent-rich traffic",
            title: "Reach couples mid-plan, not mid-scroll",
            body: "These are couples who picked cozy cocktails, live music, adventure, or a quiet dinner — and are ready to book.",
            cardTitle: "Every category welcome",
            cardBody: "Jazz bar, brewery, spa, mini-golf, boutique hotel, gift shop — not cuisine-specific."
        ),
        Slide(
            icon: "chart.line.uptrend.xyaxis",
            pill: "Launch partner advantage",
            title: "Shape date-night ads in your city",
            body: "Early venues get featured placement pricing before we open self-serve ads. Join now to advertise to couples planning tonight.",
            cardTitle: "Next step",
            cardBody: "A short application so we can match you to the right couples. We’ll email placement options within a few days."
        ),
    ]

    private var isLast: Bool { slide == slides.count - 1 }

    var body: some View {
        ZStack {
            Color.backgroundPrimary.ignoresSafeArea()
            RadialGradient.goldGlow.opacity(0.15).ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                Spacer(minLength: 8)
                content
                Spacer()
                bottomActions
            }
            .padding(.horizontal, 24)
        }
    }

    private var topBar: some View {
        HStack {
            Button {
                if slide > 0 {
                    withAnimation(.easeInOut(duration: 0.2)) { slide -= 1 }
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Color.luxuryGold)
                    .frame(width: 44, height: 44)
            }
            .opacity(slide > 0 ? 1 : 0)
            .disabled(slide == 0)

            Spacer()

            HStack(spacing: 8) {
                ForEach(0..<slides.count, id: \.self) { i in
                    Capsule()
                        .fill(i == slide ? Color.luxuryGold : Color.luxuryMuted.opacity(0.4))
                        .frame(width: i == slide ? 26 : 8, height: 8)
                        .animation(.spring(response: 0.4), value: slide)
                }
            }

            Spacer()

            Button("Skip", action: onSkip)
                .font(Font.bodySans(13, weight: .medium))
                .foregroundColor(Color.luxuryMuted)
                .frame(width: 44, height: 44)
        }
        .padding(.top, 12)
    }

    private var content: some View {
        let item = slides[slide]
        return VStack(alignment: .leading, spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.luxuryGold.opacity(0.12))
                    .frame(width: 56, height: 56)
                Image(systemName: item.icon)
                    .font(.system(size: 24))
                    .foregroundColor(Color.luxuryGold)
            }

            Text(item.pill.uppercased())
                .font(Font.bodySans(11, weight: .semibold))
                .tracking(1.2)
                .foregroundColor(Color.luxuryGold)

            Text(item.title)
                .font(Font.displaySerif(40, weight: .bold))
                .foregroundColor(Color.luxuryCream)
                .fixedSize(horizontal: false, vertical: true)

            Text(item.body)
                .font(Font.bodySans(15, weight: .regular))
                .foregroundColor(Color.luxuryCreamMuted)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 6) {
                Text(item.cardTitle)
                    .font(Font.bodySans(14, weight: .semibold))
                    .foregroundColor(Color.luxuryCream)
                Text(item.cardBody)
                    .font(Font.bodySans(13, weight: .regular))
                    .foregroundColor(Color.luxuryMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.luxuryMaroonLight.opacity(0.7))
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.luxuryGold.opacity(0.2), lineWidth: 1)
            )
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .id(slide)
        .transition(.opacity)
    }

    private var bottomActions: some View {
        VStack(spacing: 12) {
            Button {
                if isLast {
                    onComplete()
                } else {
                    withAnimation(.easeInOut(duration: 0.2)) { slide += 1 }
                }
            } label: {
                HStack(spacing: 10) {
                    Text(isLast ? "Start application" : "Next")
                        .font(Font.bodySans(16, weight: .semibold))
                    Image(systemName: isLast ? "arrow.right" : "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(LuxuryGoldButtonStyle())

            if !isLast {
                Button("Skip intro → apply now", action: onComplete)
                    .font(Font.bodySans(13, weight: .regular))
                    .foregroundColor(Color.luxuryMuted)
            }
        }
        .padding(.bottom, 24)
    }
}
