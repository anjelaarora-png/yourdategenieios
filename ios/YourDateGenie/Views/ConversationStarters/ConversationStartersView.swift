import SwiftUI

// MARK: - Conversation Starters Sheet (hub + 3-step flow + sparks deck, app brand)
struct ConversationStartersView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var coordinator: NavigationCoordinator
    @StateObject private var storage = ConversationStarterStorageManager.shared
    @StateObject private var sessionStorage = SparkSessionStorageManager.shared

    /// True inside the Convo tab, which supplies its own title; hides the sheet chrome.
    var isEmbeddedInTab = false

    private let totalSteps = 3
    @State private var showingGeneratorFlow = false
    @State private var showingSparksDeck = false
    @State private var currentSession: SparkSession?
    @State private var currentSparkIndex = 0
    @State private var showingSessionDetail: SparkSession?
    @State private var step = 1
    @State private var relationshipStage: String?
    @State private var mood: String?
    @State private var topic: String?
    @State private var currentOpener: ConversationOpenerSet?
    @State private var copied = false

    private var canContinue: Bool {
        switch step {
        case 1: return relationshipStage != nil
        case 2: return mood != nil
        case 3: return true
        default: return false
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.ydgBase
                    .ignoresSafeArea()

                if let session = showingSessionDetail {
                    SessionDetailView(session: session, onDismiss: { showingSessionDetail = nil })
                } else if showingSparksDeck, let session = currentSession {
                    SparksDeckView(
                        session: session,
                        currentIndex: $currentSparkIndex,
                        onDone: {
                            showingSparksDeck = false
                            currentSession = nil
                            currentSparkIndex = 0
                        },
                        onRegenerate: { regenerateSparks() }
                    )
                    .id(session.id)
                } else if showingGeneratorFlow {
                    VStack(spacing: 0) {
                        Text("Find the spark made for you")
                            .ydgText(.title2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, YDGSpace.margin)
                            .padding(.top, YDGSpace.xs)
                        Text("Two taps, made for the two of you.")
                            .ydgText(.subhead, weight: .regular, color: .ydgTextSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, YDGSpace.margin)
                            .padding(.bottom, YDGSpace.xs)
                        stepProgressHeader
                            .padding(.horizontal, 20)
                        TabView(selection: $step) {
                            step1Content.tag(1)
                            step2Content.tag(2)
                            step3Content.tag(3)
                        }
                        .tabViewStyle(.page(indexDisplayMode: .never))
                        .animation(.easeInOut(duration: 0.3), value: step)
                        bottomBar
                    }
                } else {
                    hubContent
                }
            }
            .navigationTitle(isEmbeddedInTab ? "" : "Talk sparks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.backgroundPrimary, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                if showingGeneratorFlow {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            showingGeneratorFlow = false
                            step = 1
                            relationshipStage = nil
                            mood = nil
                            topic = nil
                        } label: {
                            Label("Back", systemImage: "chevron.left")
                                .font(Font.ydgSans(16, weight: .semibold))
                                .foregroundColor(Color.ydgTextPrimary)
                        }
                    }
                }
                if !isEmbeddedInTab {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            dismiss()
                        } label: {
                            Text("Done")
                                .font(Font.ydgSans(16, weight: .semibold))
                                .foregroundColor(Color.ydgAccent)
                        }
                    }
                }
            }
            .toolbar(isEmbeddedInTab && !showingGeneratorFlow ? .hidden : .visible, for: .navigationBar)
        }
        .onChange(of: step) { _, newStep in
            if newStep == 3 {
                // Step 3 now only shows topics; sparks generated on "Reveal my sparks"
            }
        }
    }

    // MARK: - Hub (Conversation Starters)
    private var hubContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: YDGSpace.md) {
                VStack(alignment: .leading, spacing: YDGSpace.xxs) {
                    Text("Find the spark made for you")
                        .ydgText(.title2)
                    Text("Two taps, made for the two of you.")
                        .ydgText(.subhead, weight: .regular, color: .ydgTextSecondary)
                }

                Button {
                    showingGeneratorFlow = true
                    step = 1
                    relationshipStage = nil
                    mood = nil
                    topic = nil
                    currentOpener = nil
                } label: {
                    HStack(spacing: YDGSpace.md) {
                        YDGIconTile(systemName: "plus", size: 48)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("New session").ydgText(.headline)
                            Text("Pick your vibe, get your sparks.")
                                .ydgText(.subhead, weight: .regular, color: .ydgTextSecondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color.ydgTextTertiary)
                    }
                    .ydgCard()
                    .contentShape(Rectangle())
                }
                .buttonStyle(ScaleButtonStyle())

                Text("Your favorites")
                    .ydgText(.title3)
                    .padding(.top, YDGSpace.md)
                    .accessibilityAddTraits(.isHeader)

                if storage.savedStarters.isEmpty {
                    Text("Save sparks you love and they'll show up here.")
                        .ydgText(.subhead, weight: .regular, color: .ydgTextSecondary)
                } else {
                    ForEach(storage.savedStarters) { saved in
                        SavedStarterCard(
                            starter: saved,
                            onCopy: { UIPasteboard.general.string = saved.openingQuestion },
                            onUnsave: { storage.remove(id: saved.id) }
                        )
                    }
                }

                Text("Past sessions")
                    .ydgText(.title3)
                    .padding(.top, YDGSpace.md)
                    .accessibilityAddTraits(.isHeader)

                if sessionStorage.sessions.isEmpty {
                    Text("Your past sessions will show up here.")
                        .ydgText(.subhead, weight: .regular, color: .ydgTextSecondary)
                } else {
                    ForEach(sessionStorage.sessions) { session in
                        PastSessionCard(
                            session: session,
                            savedCount: savedCount(for: session),
                            onTap: { showingSessionDetail = session }
                        )
                    }
                }
            }
            .padding(.horizontal, YDGSpace.margin)
            .padding(.top, YDGSpace.xs)
            .padding(.bottom, YDGSpace.lg)
        }
        .mainTabBarScrollInset()
    }

    private func savedCount(for session: SparkSession) -> Int {
        session.sparks.filter { storage.isSaved(openingQuestion: $0.openingQuestion) }.count
    }

    // MARK: - Step progress
    private var stepProgressHeader: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                ForEach(1...totalSteps, id: \.self) { s in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(s <= step ? Color.luxuryGold : Color.luxuryMuted.opacity(0.4))
                        .frame(height: 4)
                        .frame(maxWidth: s == step ? nil : .infinity)
                    if s < totalSteps { Spacer(minLength: 4) }
                }
            }
            .frame(height: 4)
            Text("STEP \(step) OF \(totalSteps)")
                .font(Font.bodySans(12, weight: .semibold))
                .tracking(2)
                .foregroundColor(Color.luxuryMuted)
                .padding(.top, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var stepLabelForCurrentStep: String {
        switch step {
        case 1: return "WHERE ARE YOU?"
        case 2: return "WHAT DO YOU NEED?"
        case 3: return "OPTIONAL"
        default: return ""
        }
    }

    // MARK: - Step 1: Relationship stage
    private var step1Content: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: YDGSpace.xxs) {
                    Text("Where are you two?")
                        .ydgText(.title3)
                        .accessibilityAddTraits(.isHeader)
                    Text("Pick what best describes your connection.")
                        .ydgText(.subhead, weight: .regular, color: .ydgTextSecondary)
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(ConversationOpenerContent.relationshipStages, id: \.value) { stage in
                        RelationshipStageCard(
                            title: stage.label,
                            subtitle: stage.subtitle,
                            isSelected: relationshipStage == stage.value
                        ) {
                            relationshipStage = stage.value
                        }
                    }
                }

            }
            .padding(20)
        }
        .mainTabBarScrollInset()
    }

    // MARK: - Step 2: Vibe (4 options, list layout)
    private var step2Content: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: YDGSpace.xxs) {
                    Text("What do you need?")
                        .ydgText(.title3)
                        .accessibilityAddTraits(.isHeader)
                    Text("We'll match your sparks to the mood.")
                        .ydgText(.subhead, weight: .regular, color: .ydgTextSecondary)
                }

                ForEach(ConversationOpenerContent.vibeOptions, id: \.value) { vibe in
                    VibeRowCard(
                        title: vibe.label,
                        subtitle: vibe.subtitle,
                        icon: vibeIcon(vibe.value),
                        isSelected: mood == vibe.value
                    ) {
                        mood = vibe.value
                    }
                }
            }
            .padding(20)
        }
        .mainTabBarScrollInset()
    }

    private func vibeIcon(_ value: String) -> String {
        switch value {
        case "playful": return "face.smiling"
        case "tender": return "flame"
        case "deep": return "brain.head.profile"
        case "daring": return "sparkles"
        default: return "heart"
        }
    }

    private func moodEmoji(_ mood: String) -> String {
        switch mood {
        case "deep": return "💭"
        case "playful": return "😄"
        case "nostalgic": return "📸"
        case "daring": return "🔥"
        case "dreamy": return "✨"
        case "tender": return "💕"
        default: return "💬"
        }
    }

    private func topicEmoji(_ topicValue: String) -> String {
        switch topicValue {
        case "childhood": return "📖"
        case "travel": return "✈️"
        case "ambitions": return "🎯"
        case "desires": return "💫"
        case "family": return "👨‍👩‍👧"
        case "fears": return "🫂"
        default: return "💬"
        }
    }

    // MARK: - Step 3: Optional topics + Reveal my sparks
    private var step3Content: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: YDGSpace.xxs) {
                    Text("Any topics?")
                        .ydgText(.title3)
                        .accessibilityAddTraits(.isHeader)
                    Text("Optional. Tap any that feel right, or skip ahead.")
                        .ydgText(.subhead, weight: .regular, color: .ydgTextSecondary)
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(ConversationOpenerContent.topics, id: \.value) { t in
                        ChipOptionView(
                            item: OptionItem(value: t.value, label: t.label, emoji: topicEmoji(t.value)),
                            isSelected: topic == t.value,
                            onTap: { topic = topic == t.value ? nil : t.value }
                        )
                    }
                }
            }
            .padding(20)
        }
        .mainTabBarScrollInset()
    }

    private func revealSparks() {
        guard let r = relationshipStage, let m = mood else { return }
        let sparks = ConversationOpenerContent.pickMultipleOpeners(relationshipStage: r, mood: m, topic: topic, count: 10)
        guard !sparks.isEmpty else { return }
        let session = SparkSession(relationshipStage: r, mood: m, topic: topic, sparks: sparks)
        sessionStorage.add(session: session)
        currentSession = session
        currentSparkIndex = 0
        showingGeneratorFlow = false
        step = 1
        relationshipStage = nil
        mood = nil
        topic = nil
        showingSparksDeck = true
    }

    /// Generate a new set of sparks with the same vibe/stage/topic and stay in the deck.
    private func regenerateSparks() {
        guard let session = currentSession else { return }
        let currentBatch = Set(session.sparks.map(\.openingQuestion))
        var alsoAvoid: Set<String> = []
        for past in sessionStorage.sessions.prefix(8) {
            guard past.id != session.id,
                  past.relationshipStage == session.relationshipStage,
                  past.mood == session.mood,
                  past.topic == session.topic else { continue }
            alsoAvoid.formUnion(past.sparks.map(\.openingQuestion))
        }
        let sparks = ConversationOpenerContent.pickMultipleOpeners(
            relationshipStage: session.relationshipStage,
            mood: session.mood,
            topic: session.topic,
            count: 10,
            excludingQuestions: currentBatch,
            alsoAvoidQuestions: alsoAvoid
        )
        guard !sparks.isEmpty else { return }
        let newSession = SparkSession(
            relationshipStage: session.relationshipStage,
            mood: session.mood,
            topic: session.topic,
            sparks: sparks
        )
        sessionStorage.add(session: newSession)
        currentSession = newSession
        currentSparkIndex = 0
    }

    // MARK: - Bottom bar
    private var bottomBar: some View {
        VStack(spacing: 12) {
            if step == 3 {
                Button {
                    revealSparks()
                } label: {
                    HStack(spacing: 8) {
                        Text("Reveal my sparks")
                            .font(Font.bodySans(16, weight: .semibold))
                        Image(systemName: "sparkles")
                            .font(Font.bodySans(16, weight: .semibold))
                            .symbolRenderingMode(.monochrome)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.ydgPrimary)
                .padding(.horizontal, YDGSpace.margin)
            } else {
                Button {
                    withAnimation {
                        if step == 1 {
                            step = 2
                        } else if step == 2 {
                            step = 3
                        }
                    }
                } label: {
                    HStack(spacing: 8) {
                        Text("Continue")
                            .font(Font.bodySans(16, weight: .semibold))
                        Image(systemName: "arrow.right")
                            .font(Font.bodySans(14, weight: .semibold))
                            .symbolRenderingMode(.monochrome)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.ydgPrimary)
                .disabled(!canContinue)
                .padding(.horizontal, YDGSpace.margin)
            }
        }
        .padding(.vertical, YDGSpace.md)
        .background(Color.ydgBase)
    }
}

// MARK: - Vibe row card (step 2 list item)
private struct VibeRowCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .regular))
                    .foregroundColor(isSelected ? Color.ydgAccent : Color.ydgTextSecondary)
                    .frame(width: 28, alignment: .center)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .ydgText(.headline, color: isSelected ? .ydgAccent : .ydgTextPrimary)
                    Text(subtitle)
                        .ydgText(.footnote, color: .ydgTextSecondary)
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundColor(isSelected ? Color.ydgAccent : Color.ydgTextTertiary)
            }
            .padding(YDGSpace.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? Color.ydgAccentSubtle : Color.ydgRaised,
                        in: RoundedRectangle(cornerRadius: YDGRadius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: YDGRadius.card, style: .continuous)
                    .stroke(isSelected ? Color.ydgAccent : Color.ydgBorder, lineWidth: isSelected ? 1.5 : 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Past session card (hub)
private struct PastSessionCard: View {
    let session: SparkSession
    let savedCount: Int
    let onTap: () -> Void

    private var relationshipLabel: String {
        ConversationOpenerContent.relationshipStages.first(where: { $0.value == session.relationshipStage })?.label ?? session.relationshipStage
    }

    private var vibeLabel: String {
        ConversationOpenerContent.vibeOptions.first(where: { $0.value == session.mood })?.label
            ?? ConversationOpenerContent.moods.first(where: { $0.value == session.mood })?.label
            ?? session.mood
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.luxuryGold)
                            .frame(width: 8, height: 8)
                        Text("\(relationshipLabel) · \(vibeLabel)")
                            .font(Font.bodySans(15, weight: .semibold))
                            .foregroundColor(Color.luxuryCream)
                    }
                    Spacer()
                    Text("\(savedCount) saved")
                        .font(Font.bodySans(12, weight: .medium))
                        .foregroundColor(Color.luxuryCreamMuted)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.luxuryGold.opacity(0.2))
                        .cornerRadius(8)
                }
                Text(relativeDate(session.createdAt))
                    .font(Font.bodySans(13, weight: .regular))
                    .foregroundColor(Color.luxuryMuted)
                Text("\(session.sparks.count) questions")
                    .font(Font.bodySans(12, weight: .regular))
                    .foregroundColor(Color.luxuryMuted)
                if let first = session.sparks.prefix(2).first {
                    Text(first.openingQuestion)
                        .font(Font.bodySans(13, weight: .regular))
                        .foregroundColor(Color.luxuryCreamMuted)
                        .lineLimit(2)
                        .truncationMode(.tail)
                }
                HStack {
                    Text("Tap to view all")
                        .font(Font.bodySans(12, weight: .medium))
                        .foregroundColor(Color.luxuryGold)
                    Image(systemName: "chevron.right")
                        .font(Font.bodySans(10, weight: .semibold))
                        .symbolRenderingMode(.monochrome)
                        .foregroundColor(Color.luxuryGold)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.luxeSurfaceTintStrong)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.luxuryGold.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private func relativeDate(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return "Today" }
        if cal.isDateInYesterday(date) { return "Last night" }
        let days = cal.dateComponents([.day], from: date, to: Date()).day ?? 0
        if days < 7 { return days == 1 ? "1 day ago" : "\(days) days ago" }
        if days < 30 { let w = days / 7; return w == 1 ? "1 week ago" : "\(w) weeks ago" }
        let m = days / 30
        return m == 1 ? "1 month ago" : "\(m) months ago"
    }
}

// MARK: - Saved starter card (on landing list)
private struct SavedStarterCard: View {
    let starter: SavedConversationStarter
    let onCopy: () -> Void
    let onUnsave: () -> Void
    @State private var copied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(starter.openingQuestion)
                .font(Font.bodySans(15, weight: .regular))
                .foregroundColor(Color.luxuryCream)
                .fixedSize(horizontal: false, vertical: true)
            Text(starter.followUp)
                .font(Font.bodySans(13, weight: .regular))
                .foregroundColor(Color.luxuryMuted)
                .lineLimit(2)
                .truncationMode(.tail)
            HStack {
                Text(starter.tagsLabel)
                    .font(Font.bodySans(11, weight: .medium))
                    .foregroundColor(Color.luxuryMuted)
                Spacer()
                Button {
                    UIPasteboard.general.string = starter.openingQuestion
                    copied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { copied = false }
                } label: {
                    Image(systemName: copied ? "checkmark.circle.fill" : "doc.on.doc")
                        .font(Font.bodySans(14, weight: .regular))
                        .symbolRenderingMode(.monochrome)
                        .foregroundColor(copied ? Color.luxurySuccess : Color.luxuryGold)
                }
                Button {
                    onUnsave()
                } label: {
                    Image(systemName: "heart.fill")
                        .font(Font.bodySans(14, weight: .regular))
                        .symbolRenderingMode(.monochrome)
                        .foregroundColor(Color.luxuryGold)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.luxeSurfaceTintStrong)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.luxuryGold.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Relationship stage card (title + subtitle, single select)
private struct RelationshipStageCard: View {
    let title: String
    let subtitle: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 18, weight: .regular))
                        .foregroundColor(isSelected ? Color.ydgAccent : Color.ydgTextTertiary)
                    Spacer()
                }
                Text(title)
                    .ydgText(.headline, color: isSelected ? .ydgAccent : .ydgTextPrimary)
                    .multilineTextAlignment(.leading)
                Text(subtitle)
                    .ydgText(.footnote, color: .ydgTextSecondary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(YDGSpace.md)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(isSelected ? Color.ydgAccentSubtle : Color.ydgRaised,
                        in: RoundedRectangle(cornerRadius: YDGRadius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: YDGRadius.card, style: .continuous)
                    .stroke(isSelected ? Color.ydgAccent : Color.ydgBorder, lineWidth: isSelected ? 1.5 : 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Legacy: default starters when opened from plan context (kept for any direct list use)
extension ConversationStartersView {
    static let defaultStarters: [ConversationStarter] = [
        ConversationStarter(question: "What's something you're really proud of that most people don't know about?", category: "Dreams", emoji: "✨"),
        ConversationStarter(question: "If you could have dinner with anyone, living or not, who would it be and why?", category: "Connection", emoji: "💭"),
        ConversationStarter(question: "What's a small moment recently that made you really happy?", category: "Joy", emoji: "🌻"),
        ConversationStarter(question: "What's a place you've always wanted to go, and what would you do there first?", category: "Adventure", emoji: "🗺️"),
        ConversationStarter(question: "What's something you used to believe that you've changed your mind about?", category: "Growth", emoji: "🦋"),
        ConversationStarter(question: "What's your go-to song or movie when you need to feel better?", category: "Comfort", emoji: "🎵")
    ]
}

#Preview {
    ConversationStartersView()
        .environmentObject(NavigationCoordinator.shared)
}
