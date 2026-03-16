import SwiftUI

// MARK: - Conversation Starters Sheet (3-step flow, app brand)
struct ConversationStartersView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var coordinator: NavigationCoordinator

    private let totalSteps = 3
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
                Color.luxuryMaroon
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // STEP X OF 3
                    stepProgressHeader
                        .padding(.top, 8)
                        .padding(.horizontal, 20)

                    TabView(selection: $step) {
                        step1Content.tag(1)
                        step2Content.tag(2)
                        step3Content.tag(3)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .animation(.easeInOut(duration: 0.3), value: step)

                    // Bottom CTA
                    bottomBar
                }
            }
            .navigationTitle("Conversation Starters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.luxuryMaroon, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                            .font(Font.bodySans(15, weight: .semibold))
                            .foregroundColor(Color.luxuryGold)
                    }
                }
            }
        }
        .onChange(of: step) { _, newStep in
            if newStep == 3 {
                generateOpener()
            }
        }
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

    // MARK: - Step 1: Relationship stage
    private var step1Content: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                // Title: "You two are what?"
                HStack(spacing: 4) {
                    Text("You two are ")
                        .font(Font.header(22, weight: .regular))
                        .foregroundColor(Color.luxuryCream)
                    Text("what?")
                        .font(Font.tangerine(26, weight: .bold))
                        .italic()
                        .foregroundColor(Color.luxuryGold)
                }
                .padding(.horizontal, 4)

                Text("Just one tap — we'll tailor everything to you.")
                    .font(Font.bodySans(14, weight: .regular))
                    .foregroundColor(Color.luxuryMuted)
                    .padding(.horizontal, 4)

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

                interactionHint("1 TAP, NO TYPING.")
            }
            .padding(20)
            .padding(.bottom, 100)
        }
    }

    // MARK: - Step 2: Mood + optional topic
    private var step2Content: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                // Tonight's energy
                HStack(spacing: 4) {
                    Text("Tonight's ")
                        .font(Font.header(22, weight: .regular))
                        .foregroundColor(Color.luxuryCream)
                    Text("energy")
                        .font(Font.tangerine(26, weight: .bold))
                        .italic()
                        .foregroundColor(Color.luxuryGold)
                }
                .padding(.horizontal, 4)

                Text("One feeling. That's all we need.")
                    .font(Font.bodySans(14, weight: .regular))
                    .foregroundColor(Color.luxuryMuted)
                    .padding(.horizontal, 4)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(ConversationOpenerContent.moods, id: \.value) { m in
                        OptionCardView(
                            item: OptionItem(value: m.value, label: m.label, emoji: moodEmoji(m.value)),
                            isSelected: mood == m.value,
                            onTap: { mood = m.value }
                        )
                    }
                }

                // Optional topic
                SectionLabel(text: "OPTIONAL · ADD A TOPIC", color: Color.luxuryMuted)
                    .padding(.top, 8)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(ConversationOpenerContent.topics, id: \.value) { t in
                        ChipOptionView(
                            item: OptionItem(value: t.value, label: t.label, emoji: topicEmoji(t.value)),
                            isSelected: topic == t.value,
                            onTap: { topic = topic == t.value ? nil : t.value }
                        )
                    }
                }

                interactionHint("1 REQUIRED TAP + EXTRAS OPTIONAL.")
            }
            .padding(20)
            .padding(.bottom, 100)
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

    // MARK: - Step 3: Result
    private var step3Content: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                SectionLabel(text: "YOUR EVENING BEGINS", color: Color.luxuryMuted)
                    .padding(.horizontal, 4)

                HStack(spacing: 4) {
                    Text("Tonight's ")
                        .font(Font.header(22, weight: .regular))
                        .foregroundColor(Color.luxuryCream)
                    Text("opener")
                        .font(Font.tangerine(26, weight: .bold))
                        .italic()
                        .foregroundColor(Color.luxuryGold)
                }
                .padding(.horizontal, 4)

                if let opener = currentOpener {
                    summaryLine(relationshipStage: relationshipStage, mood: mood, topic: topic)
                        .padding(.horizontal, 4)

                    // Opening question card
                    VStack(alignment: .leading, spacing: 12) {
                        SectionLabel(text: "OPENING QUESTION", color: Color.luxuryMuted)
                        Text(opener.openingQuestion)
                            .font(Font.bodySerif(16, weight: .regular))
                            .foregroundColor(Color.luxuryCream)
                            .fixedSize(horizontal: false, vertical: true)
                        HStack {
                            Text(opener.tagsLabel)
                                .font(Font.bodySans(12, weight: .medium))
                                .foregroundColor(Color.luxuryMuted)
                            Spacer()
                            Button {
                                UIPasteboard.general.string = opener.openingQuestion
                                copied = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { copied = false }
                            } label: {
                                Image(systemName: copied ? "checkmark.circle.fill" : "heart")
                                    .font(.system(size: 18))
                                    .foregroundColor(copied ? Color.luxurySuccess : Color.luxuryGold)
                            }
                        }
                    }
                    .padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.luxuryMaroonLight.opacity(0.9))
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.luxuryGold.opacity(0.35), lineWidth: 1)
                    )

                    // Follow-up
                    VStack(alignment: .leading, spacing: 8) {
                        SectionLabel(text: "FOLLOW-UP IF CONVERSATION FLOWS", color: Color.luxuryMuted)
                        Text(opener.followUp)
                            .font(Font.bodySerifItalic(15))
                            .foregroundColor(Color.luxuryCreamMuted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 4)

                    interactionHint("NO DEAD ENDS, ALWAYS A NEXT MOVE.")
                } else {
                    ProgressView()
                        .tint(Color.luxuryGold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                }
            }
            .padding(20)
            .padding(.bottom, 120)
        }
    }

    private func summaryLine(relationshipStage: String?, mood: String?, topic: String?) -> some View {
        let stageLabel = ConversationOpenerContent.relationshipStages.first(where: { $0.value == relationshipStage })?.label ?? ""
        let moodLabel = ConversationOpenerContent.moods.first(where: { $0.value == mood })?.label ?? ""
        let topicLabel = topic.flatMap { t in ConversationOpenerContent.topics.first(where: { $0.value == t })?.label } ?? ""
        let parts = [stageLabel, moodLabel, topicLabel].filter { !$0.isEmpty }
        return Text(parts.joined(separator: " · "))
            .font(Font.bodySans(13, weight: .medium))
            .foregroundColor(Color.luxuryMuted)
    }

    private func interactionHint(_ text: String) -> some View {
        Text(text)
            .font(Font.bodySans(11, weight: .medium))
            .tracking(1)
            .foregroundColor(Color.luxuryMuted.opacity(0.8))
            .padding(.top, 8)
            .padding(.horizontal, 4)
    }

    // MARK: - Bottom bar
    private var bottomBar: some View {
        VStack(spacing: 12) {
            if step == 3 {
                HStack(spacing: 12) {
                    Button {
                        generateOpener()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "rectangle.stack.badge.plus")
                            Text("New card")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(LuxuryOutlineButtonStyle(isSmall: false))

                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 8) {
                            Text("Begin the evening")
                            Image(systemName: "arrow.right")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(LuxuryGoldButtonStyle(isSmall: false))
                }
                .padding(.horizontal, 20)
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
                        Text(step == 1 ? "Continue" : "Reveal my starter")
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(LuxuryGoldButtonStyle(isSmall: false))
                .disabled(!canContinue)
                .opacity(canContinue ? 1 : 0.5)
                .padding(.horizontal, 20)
            }
        }
        .padding(.vertical, 16)
        .background(
            Color.luxuryMaroon
                .shadow(color: Color.black.opacity(0.3), radius: 10, y: -5)
        )
    }

    private func generateOpener() {
        guard let r = relationshipStage, let m = mood else { return }
        if let t = topic,
           let opener = ConversationOpenerContent.pickOpener(relationshipStage: r, mood: m, topic: t) {
            currentOpener = opener
        } else if let opener = ConversationOpenerContent.pickOpenerFallback(relationshipStage: r, mood: m) {
            currentOpener = opener
        } else {
            currentOpener = ConversationOpenerContent.openers.filter {
                $0.relationshipStages.contains(r) && $0.moods.contains(m)
            }.randomElement()
                ?? ConversationOpenerContent.openers.randomElement()
        }
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
                        .font(.system(size: 16))
                        .foregroundColor(isSelected ? Color.luxuryGold : Color.luxuryMuted.opacity(0.6))
                    Spacer()
                }
                Text(title)
                    .font(Font.subheader(16, weight: .semibold))
                    .foregroundColor(isSelected ? Color.luxuryMaroon : Color.luxuryCream)
                    .multilineTextAlignment(.leading)
                Text(subtitle)
                    .font(Font.bodySans(12, weight: .regular))
                    .foregroundColor(isSelected ? Color.luxuryMaroon.opacity(0.8) : Color.luxuryMuted)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                isSelected ? LinearGradient.goldShimmer : LinearGradient(colors: [Color.luxuryMaroonLight], startPoint: .top, endPoint: .bottom)
            )
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.clear : Color.luxuryGold.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: isSelected ? Color.luxuryGold.opacity(0.3) : Color.clear, radius: 10, y: 4)
        }
        .buttonStyle(ScaleButtonStyle())
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
