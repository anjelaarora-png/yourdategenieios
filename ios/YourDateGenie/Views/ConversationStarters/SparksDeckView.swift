import SwiftUI

// MARK: - Sparks deck (Tinder-style swipe, Save button below card, prompts)
struct SparksDeckView: View {
    let session: SparkSession
    @Binding var currentIndex: Int
    let onDone: () -> Void
    let onRegenerate: () -> Void
    @StateObject private var storage = ConversationStarterStorageManager.shared

    @State private var dragOffset: CGFloat = 0
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
            Color.ydgBase
                .ignoresSafeArea()

            VStack(spacing: 0) {
                headerSection

                if sparks.isEmpty {
                    emptyState
                } else if let spark = currentSpark {
                    cardStackSection
                    Spacer(minLength: YDGSpace.md)
                    bottomButtons(spark: spark)
                } else {
                    emptyState
                }
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
        }
        .onChange(of: currentIndex) { _, _ in
            clampIndex()
        }
        .onChange(of: session.id) { _, _ in
            dragOffset = 0
            showEndOfDeck = false
        }
    }

    // MARK: - Header
    private var headerSection: some View {
        HStack(alignment: .center) {
            Button {
                onDone()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Color.ydgTextPrimary)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Back")

            Spacer(minLength: 0)

            VStack(spacing: 2) {
                Text("Your sparks")
                    .ydgText(.headline)
                    .accessibilityAddTraits(.isHeader)
                Text("\(relationshipLabel) · \(vibeLabel)")
                    .ydgText(.footnote, color: .ydgTextSecondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            Button {
                showEndOfDeck = false
                dragOffset = 0
                onRegenerate()
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color.ydgTextPrimary)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Refresh sparks")
        }
        .padding(.horizontal, YDGSpace.xs)
        .padding(.top, YDGSpace.xs)
    }

    private var saveToast: some View {
        VStack {
            Spacer()
            if let msg = saveConfirmation {
                Label(msg, systemImage: "heart.fill")
                    .font(.ydg(.subhead, weight: .semibold))
                    .foregroundColor(Color.ydgTextPrimary)
                    .padding(.horizontal, YDGSpace.md)
                    .padding(.vertical, YDGSpace.sm)
                    .background(Capsule().fill(Color.ydgOverlay))
                    .overlay(Capsule().stroke(Color.ydgBorder, lineWidth: 1))
                    .padding(.bottom, 120)
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - End of deck overlay (Regenerate vs Back)
    private var endOfDeckOverlay: some View {
        ZStack {
            Color.ydgBase.opacity(0.9)
                .ignoresSafeArea()
            VStack(alignment: .leading, spacing: YDGSpace.md) {
                Text("That's every spark")
                    .ydgText(.title2)
                    .accessibilityAddTraits(.isHeader)
                Text("Get a fresh set or head back.")
                    .ydgText(.body, color: .ydgTextSecondary)
                VStack(spacing: YDGSpace.sm) {
                    Button {
                        showEndOfDeck = false
                        onRegenerate()
                    } label: {
                        Label("Get more sparks", systemImage: "sparkles")
                    }
                    .buttonStyle(.ydgPrimary)
                    Button("Back to talk sparks") {
                        showEndOfDeck = false
                        onDone()
                    }
                    .buttonStyle(.ydgSecondary)
                }
                .padding(.top, YDGSpace.xs)
            }
            .padding(YDGSpace.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.ydgOverlay, in: RoundedRectangle(cornerRadius: YDGRadius.sheet, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: YDGRadius.sheet, style: .continuous)
                    .stroke(Color.ydgBorder, lineWidth: 1)
            )
            .padding(.horizontal, YDGSpace.margin)
        }
    }

    // MARK: - Card stack
    private var cardStackSection: some View {
        ZStack {
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
        .frame(height: 470)
        .padding(.top, YDGSpace.md)
        .padding(.horizontal, YDGSpace.lg)
        .accessibilityElement(children: .contain)
        .accessibilityAction(named: "Next spark") { if !isOnLastCard { navigateTo(currentIndex + 1) } }
        .accessibilityAction(named: "Previous spark") { navigateTo(currentIndex - 1) }
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

    // MARK: - Empty state
    private var emptyState: some View {
        YDGEmptyState(
            systemName: "bubble.left.and.bubble.right",
            title: "No sparks in this session",
            message: "Head back and start a new one.",
            actionTitle: "Done",
            action: onDone
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Bottom buttons (save + next)
    private func bottomButtons(spark: SparkItem) -> some View {
        HStack(spacing: YDGSpace.sm) {
            Button {
                performSave(spark: spark)
            } label: {
                Image(systemName: saveConfirmation == nil ? "heart" : "heart.fill")
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundColor(saveConfirmation == nil ? Color.ydgTextPrimary : Color.ydgHighlight)
                    .frame(width: 52, height: 52)
                    .overlay(Circle().stroke(Color.ydgBorderStrong, lineWidth: 1))
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Save to favorites")

            Button(isOnLastCard ? "Done" : "Next spark") {
                if isOnLastCard {
                    showEndOfDeck = true
                } else {
                    navigateTo(currentIndex + 1)
                }
            }
            .buttonStyle(.ydgPrimary)
        }
        .padding(.horizontal, YDGSpace.margin)
        .padding(.bottom, YDGSpace.md)
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

    private var isFront: Bool { relativePosition == 0 }

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: YDGRadius.sheet, style: .continuous)
                .fill(isFront ? Color.ydgTextPrimary : Color.ydgRaised)
                .overlay(
                    RoundedRectangle(cornerRadius: YDGRadius.sheet, style: .continuous)
                        .stroke(isFront ? Color.clear : Color.ydgBorder, lineWidth: 1)
                )
                .shadow(color: .black.opacity(isFront ? 0.3 : 0), radius: 18, x: 0, y: 8)

            if isFront {
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text(spark.tagsLabel.uppercased())
                            .font(.ydg(.caption, weight: .semibold))
                            .tracking(1)
                            .foregroundColor(Color(hex: "9A4A4C"))
                            .lineLimit(1)
                        Spacer()
                        Text("\(index + 1) of \(total)")
                            .font(.ydg(.footnote))
                            .foregroundColor(Color(hex: "6B635A"))
                    }

                    Spacer(minLength: YDGSpace.md)

                    Text(spark.openingQuestion)
                        .font(.ydgDisplay(30))
                        .foregroundColor(Color.ydgBase)
                        .lineSpacing(2)
                        .minimumScaleFactor(0.7)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer(minLength: YDGSpace.md)

                    Text("Swipe for the next one")
                        .font(.ydg(.footnote))
                        .foregroundColor(Color(hex: "6B635A"))
                }
                .padding(YDGSpace.lg)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 470)
        .scaleEffect(stackScale)
        .rotationEffect(.degrees(stackRotation))
        .offset(x: stackOffsetX, y: stackOffsetY)
        .offset(x: isFront ? dragOffset : 0)
        .rotationEffect(.degrees(isFront ? Double(dragOffset) * 0.06 : 0))
        .animation(
            isFront ? nil : .spring(response: 0.4, dampingFraction: 0.75),
            value: relativePosition
        )
        .accessibilityElement(children: .combine)
        .accessibilityHidden(!isFront)
    }

    private var stackRotation: Double {
        switch relativePosition {
        case 0: return 0
        case 1: return -4
        default: return 3
        }
    }

    private var stackOffsetX: CGFloat {
        switch relativePosition {
        case 0: return 0
        case 1: return -8
        default: return 8
        }
    }

    private var stackScale: CGFloat {
        switch relativePosition {
        case 0: return 1.0
        case 1: return 0.96
        default: return 0.92
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
        case 1: return 1.0
        default: return 0.6
        }
    }
}
