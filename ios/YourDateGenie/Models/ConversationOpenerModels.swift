import Foundation

// MARK: - Spark Item (stored in session; one question + follow-up)
struct SparkItem: Codable, Equatable, Identifiable {
    var id: String { openingQuestion }
    let openingQuestion: String
    let followUp: String
    let tagsLabel: String
}

// MARK: - Spark Session (one run: relationship + vibe + optional topic → N sparks)
struct SparkSession: Identifiable, Codable, Equatable {
    let id: UUID
    let relationshipStage: String
    let mood: String
    let topic: String?
    let createdAt: Date
    let sparks: [SparkItem]

    init(id: UUID = UUID(), relationshipStage: String, mood: String, topic: String? = nil, createdAt: Date = Date(), sparks: [SparkItem]) {
        self.id = id
        self.relationshipStage = relationshipStage
        self.mood = mood
        self.topic = topic
        self.createdAt = createdAt
        self.sparks = sparks
    }
}

// MARK: - Conversation Opener (for generator flow)
/// One opening question + follow-up, tagged for relationship stage, mood, and optional topic.
struct ConversationOpenerSet: Identifiable {
    let id = UUID()
    let openingQuestion: String
    let followUp: String
    let relationshipStages: [String]  // e.g. ["new_flame", "growing_bond"]
    let moods: [String]                // e.g. ["deep", "playful"]
    let topics: [String]?              // nil = any; [] = general only; ["ambitions"] = that topic
    let tagsLabel: String              // e.g. "Deep · Bold · Under 1 year" for display
}

// MARK: - Curated openers (Lume-style: thoughtful, no dead ends)
enum ConversationOpenerContent {
    static let relationshipStages: [(value: String, label: String, subtitle: String)] = [
        ("new_flame", "New Flame", "Early days, getting to know each other"),
        ("growing_bond", "Growing Bond", "A few months in, things are blooming"),
        ("deeply_rooted", "Deeply Rooted", "A year or more, real depth between you"),
        ("life_partners", "Life Partners", "In it for the long haul, forever curious")
    ]

    static let moods: [(value: String, label: String)] = [
        ("deep", "Deep"),
        ("playful", "Playful"),
        ("nostalgic", "Nostalgic"),
        ("daring", "Daring"),
        ("dreamy", "Dreamy"),
        ("tender", "Tender")
    ]

    /// Four vibe options for step 2 (reference layout): label, subtitle, maps to mood value.
    static let vibeOptions: [(value: String, label: String, subtitle: String)] = [
        ("playful", "Playful & light", "Fun, teasing, laughing all night"),
        ("tender", "Romantic & slow", "Soft, intimate, savoring every moment"),
        ("deep", "Deep & curious", "Real talk, going beneath the surface"),
        ("daring", "Adventurous & bold", "Daring questions, no filter tonight")
    ]

    static let topics: [(value: String, label: String)] = [
        ("childhood", "Childhood"),
        ("travel", "Travel"),
        ("ambitions", "Ambitions"),
        ("desires", "Desires"),
        ("family", "Family"),
        ("fears", "Fears")
    ]

    static let openers: [ConversationOpenerSet] = [
        ConversationOpenerSet(
            openingQuestion: "If you could live an entirely different life for one year — different career, city, everything — what would you choose, and why haven't you?",
            followUp: "And what's one small step you could take toward that life — even now?",
            relationshipStages: ["new_flame", "growing_bond", "deeply_rooted", "life_partners"],
            moods: ["deep", "daring"],
            topics: ["ambitions"],
            tagsLabel: "Deep · Bold · Ambitions"
        ),
        ConversationOpenerSet(
            openingQuestion: "What's a place you've always wanted to go, and what's the first thing you'd do when you got there?",
            followUp: "Would you rather go there together or alone first?",
            relationshipStages: ["new_flame", "growing_bond", "deeply_rooted", "life_partners"],
            moods: ["dreamy", "playful", "daring"],
            topics: ["travel"],
            tagsLabel: "Dreamy · Travel"
        ),
        ConversationOpenerSet(
            openingQuestion: "What's a childhood memory that still makes you smile — and have you ever shared it with someone you love?",
            followUp: "What would you want your future family to inherit from that memory?",
            relationshipStages: ["growing_bond", "deeply_rooted", "life_partners"],
            moods: ["nostalgic", "tender"],
            topics: ["childhood", "family"],
            tagsLabel: "Nostalgic · Tender · Childhood"
        ),
        ConversationOpenerSet(
            openingQuestion: "What's something you're secretly proud of that you've never said out loud?",
            followUp: "What would need to be true for you to say it out loud tonight?",
            relationshipStages: ["new_flame", "growing_bond", "deeply_rooted", "life_partners"],
            moods: ["deep", "tender", "daring"],
            topics: nil,
            tagsLabel: "Deep · Bold"
        ),
        ConversationOpenerSet(
            openingQuestion: "If you could have one long dinner with anyone, living or not, who would it be and what would you ask them first?",
            followUp: "What would you want them to ask you?",
            relationshipStages: ["new_flame", "growing_bond", "deeply_rooted", "life_partners"],
            moods: ["deep", "dreamy", "nostalgic"],
            topics: nil,
            tagsLabel: "Deep · Dreamy"
        ),
        ConversationOpenerSet(
            openingQuestion: "What's a fear you've overcome — or one you're still working on?",
            followUp: "What would it feel like to share that with someone who wouldn't judge?",
            relationshipStages: ["growing_bond", "deeply_rooted", "life_partners"],
            moods: ["deep", "tender"],
            topics: ["fears"],
            tagsLabel: "Deep · Tender · Fears"
        ),
        ConversationOpenerSet(
            openingQuestion: "What's one desire you've been too shy or too busy to pursue — and what would it take to give it a little more room?",
            followUp: "How could the two of you support each other in that?",
            relationshipStages: ["growing_bond", "deeply_rooted", "life_partners"],
            moods: ["deep", "tender", "dreamy"],
            topics: ["desires"],
            tagsLabel: "Deep · Desires"
        ),
        ConversationOpenerSet(
            openingQuestion: "What's the most playful thing you did as a kid that you'd still do now if no one was watching?",
            followUp: "Want to try it together sometime?",
            relationshipStages: ["new_flame", "growing_bond", "deeply_rooted", "life_partners"],
            moods: ["playful", "nostalgic"],
            topics: ["childhood"],
            tagsLabel: "Playful · Nostalgic · Childhood"
        ),
        ConversationOpenerSet(
            openingQuestion: "What does family mean to you now — and how has it changed since you were young?",
            followUp: "What would you want your own family to feel like one day?",
            relationshipStages: ["growing_bond", "deeply_rooted", "life_partners"],
            moods: ["deep", "tender", "nostalgic"],
            topics: ["family"],
            tagsLabel: "Deep · Tender · Family"
        ),
        ConversationOpenerSet(
            openingQuestion: "What's something you used to believe about love or partnership that you've changed your mind about?",
            followUp: "What showed you the other side?",
            relationshipStages: ["growing_bond", "deeply_rooted", "life_partners"],
            moods: ["deep", "tender", "nostalgic"],
            topics: nil,
            tagsLabel: "Deep · Tender"
        ),
        ConversationOpenerSet(
            openingQuestion: "If tonight could end with one thing being true that isn't true yet, what would you want it to be?",
            followUp: "What's one tiny step toward that?",
            relationshipStages: ["new_flame", "growing_bond", "deeply_rooted", "life_partners"],
            moods: ["dreamy", "tender", "daring"],
            topics: nil,
            tagsLabel: "Dreamy · Tender"
        ),
        ConversationOpenerSet(
            openingQuestion: "What's a small moment from your past week that made you feel really seen or loved?",
            followUp: "How could you create more of those moments for each other?",
            relationshipStages: ["growing_bond", "deeply_rooted", "life_partners"],
            moods: ["tender", "nostalgic"],
            topics: nil,
            tagsLabel: "Tender · Nostalgic"
        ),
        ConversationOpenerSet(
            openingQuestion: "What's something you'd dare to do together that you wouldn't do alone?",
            followUp: "What's holding you back from making it real?",
            relationshipStages: ["new_flame", "growing_bond", "deeply_rooted", "life_partners"],
            moods: ["daring", "playful"],
            topics: nil,
            tagsLabel: "Daring · Playful"
        ),
        ConversationOpenerSet(
            openingQuestion: "Where do you see yourself in five years — and who do you want beside you?",
            followUp: "What would need to happen for that to feel true?",
            relationshipStages: ["new_flame", "growing_bond"],
            moods: ["dreamy", "deep"],
            topics: ["ambitions"],
            tagsLabel: "Dreamy · Deep · Ambitions"
        ),
        ConversationOpenerSet(
            openingQuestion: "What's a song, book, or place that feels like home to you — and why?",
            followUp: "Have you ever shared that with someone and had them get it?",
            relationshipStages: ["new_flame", "growing_bond", "deeply_rooted", "life_partners"],
            moods: ["nostalgic", "tender", "dreamy"],
            topics: nil,
            tagsLabel: "Nostalgic · Tender"
        )
    ]

    /// Pick an opener that matches the current selection; optional topic can narrow or be nil.
    static func pickOpener(relationshipStage: String, mood: String, topic: String?) -> ConversationOpenerSet? {
        let matching = openers.filter { set in
            guard set.relationshipStages.contains(relationshipStage), set.moods.contains(mood) else { return false }
            if topic == nil { return true }
            return set.topics == nil || set.topics?.isEmpty == true || set.topics?.contains(topic!) == true
        }
        return matching.randomElement()
    }

    /// Fallback when topic is selected but no exact match — match relationship + mood only.
    static func pickOpenerFallback(relationshipStage: String, mood: String) -> ConversationOpenerSet? {
        let matching = openers.filter {
            $0.relationshipStages.contains(relationshipStage) && $0.moods.contains(mood)
        }
        return matching.randomElement()
    }

    /// Pick multiple openers for a session. Prefers topic-matched; fills to requested count with stage+mood matches. Shuffled so each generation is different.
    static func pickMultipleOpeners(relationshipStage: String, mood: String, topic: String?, count: Int = 10) -> [SparkItem] {
        let topicMatching = openers.filter { set in
            guard set.relationshipStages.contains(relationshipStage), set.moods.contains(mood) else { return false }
            if topic == nil { return true }
            return set.topics == nil || set.topics?.isEmpty == true || set.topics?.contains(topic!) == true
        }
        let stageMoodMatching = openers.filter {
            $0.relationshipStages.contains(relationshipStage) && $0.moods.contains(mood)
        }
        var pool = topicMatching.isEmpty ? stageMoodMatching : topicMatching
        if pool.count < count {
            let seen = Set(pool.map { $0.openingQuestion })
            let extra = stageMoodMatching.filter { !seen.contains($0.openingQuestion) }
            pool.append(contentsOf: extra)
        }
        return pool.shuffled().prefix(count).map { o in
            SparkItem(openingQuestion: o.openingQuestion, followUp: o.followUp, tagsLabel: o.tagsLabel)
        }
    }
}
