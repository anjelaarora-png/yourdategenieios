import SwiftUI

struct HomeTutorialOverlayView: View {
    @Binding var isPresented: Bool
    @State private var currentCard = 0

    private struct TutorialCard {
        let icon: String; let title: String; let body: String
    }

    private let cards: [TutorialCard] = [
        TutorialCard(icon: "wand.and.stars", title: "Plan your perfect date",
            body: "Tap Plan My Next Date on the home screen. Answer a few quick questions and we will build a complete evening for you with venues, timing, and all the details."),
        TutorialCard(icon: "heart.fill", title: "Your plans live here",
            body: "Every date plan you save shows up right on your home screen. Tap any plan to view the route, make a reservation, or share it with your partner."),
        TutorialCard(icon: "sparkles", title: "More awaits below",
            body: "Explore the tabs at the bottom. Love Notes, Gifts, and Memories unlock special tools to make every date more meaningful.")
    ]

    var body: some View {
        ZStack {
            Color.black.opacity(0.65).ignoresSafeArea()
            VStack(spacing: 0) {
                Spacer()
                VStack(spacing: 24) {
                    TabView(selection: $currentCard) {
                        ForEach(Array(cards.enumerated()), id: \.offset) { index, card in
                            cardView(card).tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .frame(height: 260)

                    HStack(spacing: 10) {
                        ForEach(0..<cards.count, id: \.self) { i in
                            Capsule()
                                .fill(i == currentCard ? Color.luxuryGold : Color.luxuryMuted.opacity(0.4))
                                .frame(width: i == currentCard ? 24 : 8, height: 8)
                                .animation(.spring(response: 0.4), value: currentCard)
                        }
                    }

                    VStack(spacing: 12) {
                        Button {
                            if currentCard < cards.count - 1 { withAnimation { currentCard += 1 } }
                            else { isPresented = false }
                        } label: {
                            HStack(spacing: 8) {
                                Text(currentCard == cards.count - 1 ? "Got it!" : "Next")
                                Image(systemName: currentCard == cards.count - 1 ? "checkmark" : "arrow.right")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(LuxuryGoldButtonStyle())

                        if currentCard < cards.count - 1 {
                            Button { isPresented = false } label: {
                                Text("Skip intro")
                                    .font(Font.bodySans(14, weight: .regular))
                                    .foregroundColor(Color.luxuryMuted)
                                    .frame(minHeight: 44)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.vertical, 32)
                .background(Color.luxuryMaroon)
                .clipShape(HTRoundedCorner(radius: 24, corners: [.topLeft, .topRight]))
            }
            .ignoresSafeArea(edges: .bottom)
        }
    }

    private func cardView(_ card: TutorialCard) -> some View {
        VStack(spacing: 20) {
            ZStack {
                Circle().fill(Color.luxuryGold.opacity(0.15)).frame(width: 72, height: 72)
                Image(systemName: card.icon).font(.system(size: 30)).foregroundStyle(LinearGradient.goldShimmer)
            }
            VStack(spacing: 10) {
                Text(card.title).font(Font.header(22, weight: .bold)).foregroundColor(Color.luxuryCream).multilineTextAlignment(.center)
                Text(card.body).font(Font.bodySans(15, weight: .regular)).foregroundColor(Color.luxuryCreamMuted)
                    .multilineTextAlignment(.center).lineSpacing(4).padding(.horizontal, 8)
            }
        }
        .padding(.horizontal, 24)
    }
}

private struct HTRoundedCorner: Shape {
    var radius: CGFloat; var corners: UIRectCorner
    func path(in rect: CGRect) -> Path {
        Path(UIBezierPath(roundedRect: rect, byRoundingCorners: corners,
                          cornerRadii: CGSize(width: radius, height: radius)).cgPath)
    }
}
