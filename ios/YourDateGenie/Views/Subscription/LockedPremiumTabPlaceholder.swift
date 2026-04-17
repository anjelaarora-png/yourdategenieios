import SwiftUI

/// Shown in place of a premium tab when the user is not subscribed.
struct LockedPremiumTabPlaceholder: View {
    let feature: AppFeature
    let title: String
    let subtitle: String

    @EnvironmentObject private var access: AccessManager

    var body: some View {
        ZStack {
            Color.luxuryMaroon
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    VStack(spacing: 12) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 36))
                            .foregroundStyle(LinearGradient.goldShimmer)

                        Text(title)
                            .font(Font.tangerine(28, weight: .bold))
                            .italic()
                            .foregroundColor(Color.luxuryGold)
                            .multilineTextAlignment(.center)

                        Text(subtitle)
                            .font(Font.bodySans(15, weight: .regular))
                            .foregroundColor(Color.luxuryCreamMuted)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }

                    PremiumIncludesView()
                        .padding(.horizontal, 20)

                    VStack(spacing: 12) {
                        Button {
                            access.require(feature) {}
                        } label: {
                            Text("Start 7-Day Free Trial")
                                .font(Font.bodySans(16, weight: .semibold))
                                .foregroundColor(Color.luxuryMaroon)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(LinearGradient.goldShimmer)
                                .cornerRadius(16)
                        }
                        .buttonStyle(.plain)

                        Text("Then $4.99/month or $49.99/year · Cancel anytime")
                            .font(Font.bodySans(12, weight: .regular))
                            .foregroundColor(Color.luxuryMuted)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 32)
                }
                .padding(.vertical, 40)
            }
        }
    }
}

// MARK: - Premium includes list

private struct PremiumIncludesView: View {
    private struct PremiumFeature {
        let icon: String
        let title: String
        let detail: String
    }

    private let features: [PremiumFeature] = [
        PremiumFeature(icon: "sparkles",         title: "Unlimited date plans",         detail: "AI-powered, personalised to you"),
        PremiumFeature(icon: "heart.text.square", title: "Love Notes",                 detail: "Write beautiful messages for your partner"),
        PremiumFeature(icon: "gift",              title: "Gift Finder",                 detail: "Personalised gift ideas for any occasion"),
        PremiumFeature(icon: "photo.on.rectangle.angled", title: "Memories",           detail: "Photo timeline of all your special dates"),
        PremiumFeature(icon: "music.note.list",   title: "Smart playlists",            detail: "The perfect soundtrack for every date"),
        PremiumFeature(icon: "bubble.left.and.bubble.right", title: "Conversation starters", detail: "Never run out of things to say"),
        PremiumFeature(icon: "map",               title: "Route maps & calendar",      detail: "Full journey planned end to end"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "crown.fill")
                    .font(.system(size: 14))
                    .foregroundColor(Color.luxuryGold)
                Text("Everything included with Premium")
                    .font(Font.bodySans(13, weight: .semibold))
                    .foregroundColor(Color.luxuryGold)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.luxuryMaroonLight)

            ForEach(Array(features.enumerated()), id: \.offset) { idx, feature in
                HStack(spacing: 12) {
                    Image(systemName: feature.icon)
                        .font(.system(size: 16))
                        .foregroundColor(Color.luxuryGold)
                        .frame(width: 24, alignment: .center)

                    VStack(alignment: .leading, spacing: 1) {
                        Text(feature.title)
                            .font(Font.bodySans(14, weight: .semibold))
                            .foregroundColor(Color.luxuryCream)
                        Text(feature.detail)
                            .font(Font.bodySans(12, weight: .regular))
                            .foregroundColor(Color.luxuryMuted)
                    }

                    Spacer()

                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(Color.luxuryGold)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 11)
                .background(idx % 2 == 0 ? Color.luxuryMaroonLight.opacity(0.4) : Color.clear)
            }
        }
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.luxuryGold.opacity(0.25), lineWidth: 1)
        )
    }
}
