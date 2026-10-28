import SwiftUI

// MARK: - Screen 10 · Low-key / at-home date (varied, never-repeating)
//
// The low-key fallback (Home "Low-key tonight?" link + rose revive). Per spec §9 it
// must be diversified and never-repeating: each pick is framed as "1 of dozens" with a
// shuffle. Low effort (~15–30 min, low/no cost, 0 travel). Positive-only, no shame copy.

struct LowKeyIdea: Identifiable, Equatable {
    let id: String
    let emoji: String
    let title: String
    let blurb: String
    /// e.g. "~20 min · $0 · 0 travel"
    let meta: String
}

struct LowKeyDateView: View {
    /// Called when the user commits to tonight's idea (hook into planning / dismiss).
    var onChoose: ((LowKeyIdea) -> Void)?
    /// Called to close the screen.
    var onClose: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var current: LowKeyIdea
    @State private var lastID: String
    @State private var cardBump = false

    init(onChoose: ((LowKeyIdea) -> Void)? = nil, onClose: (() -> Void)? = nil) {
        self.onChoose = onChoose
        self.onClose = onClose
        let first = Self.pool.randomElement() ?? Self.pool[0]
        _current = State(initialValue: first)
        _lastID = State(initialValue: first.id)
    }

    var body: some View {
        ZStack {
            Color.ydgBase.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                header

                ideaCard
                    .padding(.top, YDGSpace.lg)
                    .scaleEffect(cardBump ? 1.0 : 0.98)
                    .opacity(cardBump ? 1 : 0.92)

                Spacer(minLength: YDGSpace.lg)

                footer
            }
            .padding(.horizontal, YDGSpace.margin)
            .padding(.top, YDGSpace.xs)
            .padding(.bottom, YDGSpace.md)
        }
        .onAppear { animateIn() }
    }

    // MARK: Header
    private var header: some View {
        VStack(alignment: .leading, spacing: YDGSpace.xs) {
            HStack {
                Spacer()
                Button {
                    onClose?(); dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color.ydgTextPrimary)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(Color.ydgOverlay))
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close")
            }
            .padding(.trailing, -YDGSpace.xs)

            Text("A low-key night in")
                .ydgText(.title1)
                .accessibilityAddTraits(.isHeader)

            Text("No reservations, no travel. Just you two.")
                .ydgText(.body, color: .ydgTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: Idea card
    private var ideaCard: some View {
        VStack(alignment: .leading, spacing: YDGSpace.sm) {
            Text(current.emoji)
                .font(.system(size: 24))
                .frame(width: 48, height: 48)
                .background(Circle().fill(Color.ydgHighlightSubtle))
                .accessibilityHidden(true)

            Text("Tonight's idea")
                .ydgText(.caption)
                .padding(.top, YDGSpace.xs)

            Text(current.title)
                .ydgText(.title2)
                .fixedSize(horizontal: false, vertical: true)

            Text(current.blurb)
                .ydgText(.body, color: .ydgTextSecondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: YDGSpace.xs) {
                ForEach(current.meta.components(separatedBy: " · "), id: \.self) { raw in
                    let tag = raw == "0 travel" ? "No travel" : raw.prefix(1).uppercased() + raw.dropFirst()
                    Text(tag)
                        .font(.ydg(.footnote, weight: .medium))
                        .foregroundColor(Color.ydgTextPrimary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.ydgOverlay, in: RoundedRectangle(cornerRadius: YDGRadius.chip, style: .continuous))
                }
            }
            .padding(.top, YDGSpace.xxs)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .ydgCard(padding: YDGSpace.lg)
    }

    // MARK: Footer — one gold CTA + outline shuffle
    private var footer: some View {
        VStack(spacing: YDGSpace.sm) {
            Button("Plan this tonight") {
                onChoose?(current)
                onClose?(); dismiss()
            }
            .buttonStyle(.ydgPrimary)

            Button {
                shuffle()
            } label: {
                Label("Show me another", systemImage: "shuffle")
            }
            .buttonStyle(.ydgSecondary)
        }
    }

    // MARK: Logic
    private func shuffle() {
        let pick = Self.pool.filter { $0.id != lastID }.randomElement() ?? Self.pool[0]
        lastID = pick.id
        if reduceMotion {
            current = pick
        } else {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                cardBump = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                current = pick
                withAnimation(.spring(response: 0.34, dampingFraction: 0.7)) {
                    cardBump = true
                }
            }
        }
    }

    private func animateIn() {
        guard !reduceMotion else { cardBump = true; return }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75).delay(0.05)) {
            cardBump = true
        }
    }

    // MARK: Idea pool (dozens, never-repeating per session)
    static let pool: [LowKeyIdea] = [
        LowKeyIdea(id: "cook", emoji: "🍳", title: "Cook one dish together",
                   blurb: "Pick a recipe neither of you has tried. One cooks, one sous-chefs, then swap. The mess is part of it.",
                   meta: "~30 min · low cost · 0 travel"),
        LowKeyIdea(id: "world", emoji: "🌍", title: "Around-the-world dinner",
                   blurb: "Choose a country at random. Order or cook its signature dish and queue up a song or two from there.",
                   meta: "~30 min · low cost · 0 travel"),
        LowKeyIdea(id: "game", emoji: "🎲", title: "Game night, just us",
                   blurb: "Best of three: cards, a board game, or a phone trivia round. Loser picks tomorrow's coffee order.",
                   meta: "~25 min · $0 · 0 travel"),
        LowKeyIdea(id: "spa", emoji: "🛁", title: "At-home spa night",
                   blurb: "Dim the lights, warm towels, take turns with a 10-minute hand or shoulder massage. Phones in another room.",
                   meta: "~20 min · $0 · 0 travel"),
        LowKeyIdea(id: "cards", emoji: "🃏", title: "Question-card night",
                   blurb: "Trade three questions you've never asked each other. Go deeper than usual — that's the whole point.",
                   meta: "~20 min · $0 · 0 travel"),
        LowKeyIdea(id: "camp", emoji: "🏕", title: "Living-room camp-out",
                   blurb: "Blankets on the floor, string lights on, a documentary about somewhere you'd love to go.",
                   meta: "~30 min · $0 · 0 travel"),
        LowKeyIdea(id: "wine", emoji: "🧀", title: "Wine-&-cheese tasting",
                   blurb: "Three small things to taste, rated out of ten. Whatever's in the fridge counts — score everything.",
                   meta: "~25 min · low cost · 0 travel"),
        LowKeyIdea(id: "fort", emoji: "🛋", title: "Build-a-fort movie night",
                   blurb: "Cushions, blankets, a fort worthy of a ten-year-old. One snack each, one movie you both veto-approve.",
                   meta: "~30 min · $0 · 0 travel"),
        LowKeyIdea(id: "playlist", emoji: "🎧", title: "Make each other a playlist",
                   blurb: "Ten minutes, five songs each that say 'this reminds me of you.' Play them back and explain one.",
                   meta: "~20 min · $0 · 0 travel"),
        LowKeyIdea(id: "bake", emoji: "🍪", title: "Midnight bake",
                   blurb: "One batch of something sweet. Eat the first one warm, straight off the tray, no plates.",
                   meta: "~30 min · low cost · 0 travel"),
        LowKeyIdea(id: "stars", emoji: "✨", title: "Step outside & look up",
                   blurb: "Five minutes on the porch or balcony. Find one star, make one wish each, head back in for tea.",
                   meta: "~15 min · $0 · 0 travel"),
        LowKeyIdea(id: "memory", emoji: "📷", title: "Scroll your photo roll together",
                   blurb: "Go back to your first month of photos. Pick your favourite memory and say why out loud.",
                   meta: "~20 min · $0 · 0 travel"),
    ]
}
