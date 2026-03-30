import SwiftUI

// MARK: - Sparks deck (Tinder-style swipe, Save button below card, prompts)
struct SparksDeckView: View {
    let session: SparkSession
    @Binding var currentIndex: Int
    let onDone: () -> Void
    let onRegenerate: () -> Void
    @StateObject private var storage = ConversationStarterStorageManager.shared

    @State private var dragOffset: CGFloat = 0
    @State private var showWelcomePrompt = true
    @State private var saveConfirmation: String? = nil
    @State private var showEndOfDeck = false

    private let swipeThreshold: CGFloat = 100

    private var sparks: [SparkItem] {
        session.sparks
    }

    private var currentSpark: SparkItem? {
        guard !sparks.isEmpty, currentIndex >= 0, currentIndex < sparks.count else { return nil }
        return sparks[currentIndex]
    }

    private var relationshipLabel: String {
        ConversationOpenerContent.relationshipStages.first(where: { $0.value == session.relationshipStage })?.label ?? session.relationshipStage
    }

    private var vibeLabel: String {
        ConversationOpenerContent.vibeOptions.first(where: { $0.value == session.mood })?.label
            ?? ConversationOpenerContent.moods.first(where: { $0.value == session.mood })?.label
            ?? session.mood
    }

    private var isOnLastCard: Bool {
        guard !sparks.isEmpty else { return true }
        return currentIndex >= sparks.count - 1
    }

    /// Indices to render: current card + up to 2 behind (stack peek), back-to-front order.
    private var cardIndices: [Int] {
        guard !sparks.isEmpty else { return [] }
        return (0..<sparks.count).filter { i in
            let rel = i - currentIndex
            return rel >= 0 && rel <= 2
        }.reversed()
    }

    var body: some View {
        ZStack {
            Color.luxuryMaroon
                .ignoresSafeArea()

            VStack(spacing: 0) {
                headerSection

                if sparks.isEmpty {
                    emptyState
                } else if let spark = currentSpark {
                    dotIndicators
                    cardStackSection
                    swipeHintSection
                    saveButtonSection(spark: spark)
                    bottomButtons
                } else {
                    emptyState
                }
            }

            if showWelcomePrompt && !sparks.isEmpty {
                welcomeOverlay
            }

            if saveConfirmation != nil {
                saveToast
            }

            if showEndOfDeck {
                endOfDeckOverlay
            }
        }
        .onAppear {
            clampIndex()
            // Hide welcome after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation(.easeOut(duration: 0.3)) {
                    showWelcomePrompt = false
                }
            }
        }
        .onChange(of: currentIndex) { _, _ in
            clampIndex()
        }
    }

    // MARK: - Header
    private var headerSection: some View {
        VStack(spacing: 4) {
            Text("Your Sparks")
                .font(Font.tangerine(48, weight: .bold))
                .italic()
                .foregroundColor(Color.luxuryGold)
                .frame(maxWidth: .infinity)
            Text("\(relationshipLabel) · \(vibeLabel)")
                .font(Font.bodySans(16, weight: .semibold))
                .foregroundColor(Color.luxuryCream)
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    // MARK: - Welcome prompt (swipe hint)
    private var welcomeOverlay: some View {
        VStack {
            Spacer()
            Text("Swipe left for next · Swipe right to skip")
                .font(Font.bodySans(14, weight: .semibold))
                .foregroundColor(Color.luxuryCream)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(Color.luxuryMaroonLight.opacity(0.95))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.luxuryGold.opacity(0.5), lineWidth: 1)
                )
                .padding(.horizontal, 32)
                .padding(.bottom, 200)
            Spacer()
        }
        .allowsHitTesting(false)
    }

    private var saveToast: some View {
        VStack {
            Spacer()
            if let msg = saveConfirmation {
                HStack(spacing: 8) {
                    Image(systemName: "bookmark.fill")
                        .foregroundColor(Color.luxuryGold)
                    Text(msg)
                        .font(Font.bodySans(14, weight: .semibold))
                        .foregroundColor(Color.luxuryCream)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.luxuryMaroonLight)
                .cornerRadius(10)
                .padding(.bottom, 120)
            }
            Spacer()
        }
        .allowsHitTesting(false)
    }

    // MARK: - End of deck overlay (Regenerate vs Back)
    private var endOfDeckOverlay: some View {
        VStack(spacing: 0) {
            Color.luxuryMaroon.opacity(0.85)
                .ignoresSafeArea()
            VStack(spacing: 24) {
                Text("You've seen all your sparks")
                    .font(Font.tangerine(38, weight: .bold))
                    .italic()
                    .foregroundColor(Color.luxuryGold)
                    .multilineTextAlignment(.center)
                Text("Get a fresh set or head back.")
                    .font(Font.bodySans(16, weight: .regular))
                    .foregroundColor(Color.luxuryCreamMuted)
                    .multilineTextAlignment(.center)
                VStack(spacing: 12) {
                    Button {
                        showEndOfDeck = false
                        onRegenerate()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                            Text("Get more sparks")
                                .font(Font.bodySans(16, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(LuxuryGoldButtonStyle(isSmall: false))
                    Button {
                        showEndOfDeck = false
                        onDone()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "chevron.left")
                            Text("Back to Conversation Starters")
                                .font(Font.bodySans(16, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(LuxuryOutlineButtonStyle(isSmall: false))
                }
                .padding(.horizontal, 32)
            }
            .padding(28)
            .frame(maxWidth: .infinity)
            .background(Color.luxuryMaroonLight.opacity(0.98))
            .cornerRadius(24)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.luxuryGold.opacity(0.4), lineWidth: 1)
            )
            .padding(.horizontal, 24)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Dot indicators
    private var dotIndicators: some View {
        HStack(spacing: 8) {
            ForEach(0..<sparks.count, id: \.self) { i in
                Capsule()
                    .fill(i == currentIndex ? Color.luxuryGold : Color.luxuryGold.opacity(0.25))
                    .frame(width: i == currentIndex ? 22 : 6, height: 6)
                    .animation(.spring(response: 0.35, dampingFraction: 0.7), value: currentIndex)
            }
        }
        .padding(.top, 12)
    }

    // MARK: - Card stack (reference-style: multiple cards with stack transform + seamless swipe)
    private var cardStackSection: some View {
        ZStack {
            HStack {
                hintLabel(text: "← Back", visible: dragOffset > 40)
                Spacer()
                hintLabel(text: "Next →", visible: dragOffset < -40)
            }
            .padding(.horizontal, 28)
            .zIndex(20)

            ForEach(cardIndices, id: \.self) { i in
                let relPos = i - currentIndex
                SparkCardView(
                    spark: sparks[i],
                    index: i,
                    total: sparks.count,
                    relativePosition: relPos,
                    dragOffset: relPos == 0 ? dragOffset : 0
                )
                .zIndex(relPos == 0 ? 10 : Double(-relPos))
                .gesture(relPos == 0 ? dragGesture : nil)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 280)
        .padding(.top, 16)
        .padding(.horizontal, 24)
    }

    private func hintLabel(text: String, visible: Bool) -> some View {
        Text(text)
            .font(Font.bodySans(12, weight: .medium))
            .tracking(1.5)
            .foregroundColor(Color.luxuryGoldLight)
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.luxuryMaroonLight.opacity(0.92))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.luxuryGold.opacity(0.4), lineWidth: 1)
                    )
            )
            .opacity(visible ? min(abs(dragOffset) / swipeThreshold, 1.0) : 0)
            .animation(.easeInOut(duration: 0.15), value: visible)
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged { value in
                dragOffset = value.translation.width
            }
            .onEnded { value in
                let velocity = value.predictedEndTranslation.width - value.translation.width

                if dragOffset < -swipeThreshold, currentIndex < sparks.count - 1 {
                    // Swipe left → next
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    withAnimation(.easeIn(duration: 0.28)) {
                        dragOffset = -500
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.26) {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            currentIndex += 1
                            dragOffset = 0
                        }
                    }
                } else if dragOffset > swipeThreshold, currentIndex > 0 {
                    // Swipe right → previous
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    withAnimation(.easeIn(duration: 0.28)) {
                        dragOffset = 500
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.26) {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            currentIndex -= 1
                            dragOffset = 0
                        }
                    }
                } else if isOnLastCard && dragOffset < -swipeThreshold {
                    // Last card swiped left → end of deck
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    withAnimation(.easeIn(duration: 0.28)) {
                        dragOffset = -500
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.26) {
                        dragOffset = 0
                        showEndOfDeck = true
                    }
                } else {
                    // Snap back
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        dragOffset = 0
                    }
                }
            }
    }

    private var swipeHintSection: some View {
        HStack(spacing: 10) {
            Image(systemName: "arrow.left")
                .font(Font.bodySans(12, weight: .regular))
            Text("swipe to explore")
                .font(Font.bodySans(11, weight: .regular))
                .tracking(2)
            Image(systemName: "arrow.right")
                .font(Font.bodySans(12, weight: .regular))
        }
        .foregroundColor(Color.luxuryGoldLight.opacity(0.35))
        .padding(.top, 14)
    }

    // MARK: - Empty state
    private var emptyState: some View {
        VStack(spacing: 16) {
            Text("No sparks in this session")
                .font(Font.bodySans(16, weight: .medium))
                .foregroundColor(Color.luxuryMuted)
            Button("Done") {
                onDone()
            }
            .buttonStyle(LuxuryGoldButtonStyle(isSmall: false))
            .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Save button (below card)
    private func saveButtonSection(spark: SparkItem) -> some View {
        Button {
            performSave(spark: spark)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "bookmark")
                    .font(Font.bodySans(18, weight: .medium))
                Text("Save to favorites")
                    .font(Font.bodySans(16, weight: .semibold))
            }
            .foregroundColor(Color.luxuryGold)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
        }
        .buttonStyle(LuxuryOutlineButtonStyle(isSmall: false))
        .padding(.horizontal, 24)
        .padding(.top, 16)
    }

    // MARK: - Bottom buttons
    private var bottomButtons: some View {
        HStack(spacing: 12) {
            Button {
                if currentIndex > 0 {
                    navigateTo(currentIndex - 1)
                } else {
                    onDone()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left")
                    Text("Back")
                        .font(Font.bodySans(16, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(LuxuryOutlineButtonStyle(isSmall: false))

            Button {
                if isOnLastCard {
                    showEndOfDeck = true
                } else {
                    navigateTo(currentIndex + 1)
                }
            } label: {
                HStack(spacing: 8) {
                    Text(isOnLastCard ? "Done" : "Next spark")
                        .font(Font.bodySans(16, weight: .semibold))
                    if !isOnLastCard {
                        Image(systemName: "arrow.right")
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(LuxuryGoldButtonStyle(isSmall: false))
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 32)
    }

    // MARK: - Helpers
    private func clampIndex() {
        guard !sparks.isEmpty else { return }
        if currentIndex < 0 {
            currentIndex = 0
        } else if currentIndex >= sparks.count {
            currentIndex = max(0, sparks.count - 1)
        }
    }

    private func navigateTo(_ index: Int) {
        guard index >= 0, index < sparks.count else { return }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            currentIndex = index
            dragOffset = 0
        }
    }

    private func performSave(spark: SparkItem) {
        DispatchQueue.main.async {
            storage.add(openingQuestion: spark.openingQuestion, followUp: spark.followUp, tagsLabel: spark.tagsLabel)
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            saveConfirmation = "Saved!"
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                saveConfirmation = nil
            }
        }
    }
}

// MARK: - Spark card (stack-aware: scale, offset, opacity; active card follows drag)
private struct SparkCardView: View {
    let spark: SparkItem
    let index: Int
    let total: Int
    let relativePosition: Int
    let dragOffset: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.luxuryMaroonLight.opacity(0.95))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.luxuryGold.opacity(0.4), lineWidth: 1)
                )
                .overlay(
                    VStack(spacing: 0) {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                LinearGradient(
                                    colors: [Color.luxuryGold.opacity(0.35), Color.luxuryGold.opacity(0.08), Color.clear],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(height: 6)
                            .frame(maxWidth: .infinity)
                        Spacer(minLength: 0)
                    }
                )
                .overlay(
                    LinearGradient(
                        colors: [Color.luxuryGold.opacity(0.07), Color.clear],
                        startPoint: .top,
                        endPoint: .center
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                )
                .shadow(color: .black.opacity(0.35), radius: 16, x: 0, y: 6)

            VStack(spacing: 0) {
                Text("\(index + 1) of \(total)")
                    .font(Font.bodySans(11, weight: .regular))
                    .tracking(2)
                    .foregroundColor(Color.luxuryMuted)
                    .padding(.bottom, 14)

                Text("• \(spark.tagsLabel.uppercased())")
                    .font(Font.bodySans(11, weight: .semibold))
                    .tracking(2.5)
                    .foregroundColor(Color.luxuryGold)
                    .padding(.bottom, 18)

                Text(spark.openingQuestion)
                    .font(Font.bodySans(18, weight: .regular))
                    .foregroundColor(Color.luxuryCream)
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 4)
            }
            .padding(26)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 260)
        .scaleEffect(stackScale)
        .offset(y: stackOffsetY)
        .opacity(stackOpacity)
        .offset(x: relativePosition == 0 ? dragOffset : 0)
        .rotationEffect(.degrees(relativePosition == 0 ? Double(dragOffset) * 0.06 : 0))
        .animation(
            relativePosition == 0 ? nil : .spring(response: 0.4, dampingFraction: 0.75),
            value: relativePosition
        )
    }

    private var stackScale: CGFloat {
        switch relativePosition {
        case 0: return 1.0
        case 1: return 0.95
        default: return 0.90
        }
    }

    private var stackOffsetY: CGFloat {
        switch relativePosition {
        case 0: return 0
        case 1: return 12
        default: return 22
        }
    }

    private var stackOpacity: Double {
        switch relativePosition {
        case 0: return 1.0
        case 1: return 0.6
        default: return 0.3
        }
    }
}
