import SwiftUI
import Combine

// MARK: - Rose Gamification Model (Phase 3 · G1–G5)
//
// Self-contained "rose that blooms as you date" mechanic. UI / presentation only:
// state is persisted locally via UserDefaults. NO Supabase / auth / networking here.
// The parent integration may later sync `datesThisMonth` / streak to the cloud
// (see Backend follow-ups in the integration note) — this manager intentionally
// owns no networking so it can ship and be wired in without conflicts.
//
// Design guardrail (spec §8): the rose blooms toward 2–4 dates/month and
// DROOPS when behind pace — it NEVER dies and NEVER shames. Behind pace drops
// the bar to a 15-minute revive. No streak-break guilt copy anywhere.

// MARK: - Rose health

/// Visual state of the rose. Drives `RosePlantView` and which screen leads.
enum RoseHealth: Equatable {
    /// On or ahead of pace — buds opening toward the monthly goal.
    case blooming
    /// Behind pace (a couple weeks quiet) — the rose droops and we offer a gentle revive.
    case needsRevive
}

// MARK: - Supporting value types

/// A milestone badge. Earned badges render in cream; locked ones dim out.
struct RoseBadge: Identifiable, Equatable {
    let id: String
    let emoji: String
    let title: String
    var isEarned: Bool
}

/// A low-effort, never-repeating at-home idea used to revive the rose (spec §9).
struct ReviveIdea: Identifiable, Equatable {
    let id: String
    let title: String
    let emoji: String
    /// e.g. "~15 min · 0 travel · revives your rose"
    let detail: String

    /// Safe default for `@State` initializers (avoids touching the manager during view init).
    static let placeholder = ReviveIdea(
        id: "fort",
        title: "Build-a-fort movie night",
        emoji: "🏕",
        detail: "~15 min · a fresh easy idea each time · 0 travel · revives your rose"
    )
}

/// A variable "hidden date" reward (the dopamine hit — spec §8 hook model).
struct HiddenDateReward: Identifiable, Equatable {
    let id: String
    let emoji: String
    let title: String
    let blurb: String
    /// e.g. "Rare · 1 of 8 secret dates"
    let rarityLabel: String
}

/// Shareable end-of-month recap (G5).
struct RoseMonthlyRecap: Equatable {
    let monthName: String
    let nightsOut: Int
    let newPlaces: Int
    let streakWeeks: Int
    let badgesEarned: Int
    let mostLovedNight: String
}

// MARK: - Rose Manager

/// Owns all rose state. Singleton mirrors the app's existing `*.shared` pattern
/// (e.g. `PartnerSessionManager.shared`). Persistence is local + self-contained.
final class RoseManager: ObservableObject {
    static let shared = RoseManager()

    // Tunables (kept here so copy/levels stay in one place).
    static let xpPerNight = 180
    static let xpPerLevel = 1000
    /// Weeks of quiet before the rose droops into a revive state.
    static let droopAfterWeeks = 2

    private let defaults: UserDefaults
    private let levelNames = [
        "Newcomers", "Sweethearts", "Explorers", "Adventurers",
        "Soulmates", "Legends"
    ]

    // MARK: Persisted state (manual UserDefaults — @Published drives the UI)

    @Published var datesThisMonth: Int { didSet { persist(datesThisMonth, .datesThisMonth) } }
    /// Research target window is 2–4 nights/month; default goal = 4 (full bloom).
    @Published var monthlyGoal: Int { didSet { persist(monthlyGoal, .monthlyGoal) } }
    @Published var streakWeeks: Int { didSet { persist(streakWeeks, .streakWeeks) } }
    @Published var streakFreezeAvailable: Bool { didSet { persist(streakFreezeAvailable, .streakFreeze) } }
    @Published var totalXP: Int { didSet { persist(totalXP, .totalXP) } }
    @Published var lastDateAt: Date? { didSet { persistDate(lastDateAt, .lastDateAt) } }
    /// Name of the partner tending the same rose, when known.
    @Published var partnerName: String?
    /// A pending variable reward to present (G4), if any.
    @Published var pendingReward: HiddenDateReward?

    private init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        // Seed sensible first-run values that match the spec mockup
        // (2 of 4 this month · 6-week streak · Level 4 · 3 badges).
        if defaults.object(forKey: Key.seeded.rawValue) == nil {
            defaults.set(true, forKey: Key.seeded.rawValue)
            defaults.set(2, forKey: Key.datesThisMonth.rawValue)
            defaults.set(4, forKey: Key.monthlyGoal.rawValue)
            defaults.set(6, forKey: Key.streakWeeks.rawValue)
            defaults.set(true, forKey: Key.streakFreeze.rawValue)
            defaults.set(3 * RoseManager.xpPerLevel + 820, forKey: Key.totalXP.rawValue)
            defaults.set(Date().addingTimeInterval(-5 * 24 * 3600), forKey: Key.lastDateAt.rawValue)
        }

        self.datesThisMonth = defaults.integer(forKey: Key.datesThisMonth.rawValue)
        self.monthlyGoal = max(2, defaults.integer(forKey: Key.monthlyGoal.rawValue))
        self.streakWeeks = defaults.integer(forKey: Key.streakWeeks.rawValue)
        self.streakFreezeAvailable = defaults.bool(forKey: Key.streakFreeze.rawValue)
        self.totalXP = defaults.integer(forKey: Key.totalXP.rawValue)
        self.lastDateAt = defaults.object(forKey: Key.lastDateAt.rawValue) as? Date
    }

    // MARK: Derived state

    /// Buds still to open this month.
    var budsRemaining: Int { max(0, monthlyGoal - datesThisMonth) }

    /// 0…1 progress toward the monthly goal.
    var monthProgress: Double {
        guard monthlyGoal > 0 else { return 0 }
        return min(1, Double(datesThisMonth) / Double(monthlyGoal))
    }

    /// Weeks since the last completed date (used for the droop guardrail).
    var weeksSinceLastDate: Int {
        guard let last = lastDateAt else { return RoseManager.droopAfterWeeks + 1 }
        let days = Calendar.current.dateComponents([.day], from: last, to: Date()).day ?? 0
        return max(0, days / 7)
    }

    /// The rose droops (never dies) once the couple has been quiet a while.
    var health: RoseHealth {
        weeksSinceLastDate >= RoseManager.droopAfterWeeks ? .needsRevive : .blooming
    }

    var needsRevive: Bool { health == .needsRevive }

    // Level / journey ----------------------------------------------------------

    var level: Int { totalXP / RoseManager.xpPerLevel + 1 }

    var levelName: String {
        let idx = min(max(0, level - 1), levelNames.count - 1)
        return levelNames[idx]
    }

    var nextLevelName: String {
        let idx = min(level, levelNames.count - 1)
        return levelNames[idx]
    }

    var xpIntoLevel: Int { totalXP % RoseManager.xpPerLevel }

    var xpForLevel: Int { RoseManager.xpPerLevel }

    var levelProgress: Double {
        Double(xpIntoLevel) / Double(RoseManager.xpPerLevel)
    }

    /// Nights still needed to reach the next level.
    var nightsToNextLevel: Int {
        let remaining = RoseManager.xpPerLevel - xpIntoLevel
        return max(1, Int(ceil(Double(remaining) / Double(RoseManager.xpPerNight))))
    }

    var earnedBadgeCount: Int { badges.filter(\.isEarned).count }

    /// Badge wall (G3). First three earned by default to match the spec mockup.
    var badges: [RoseBadge] {
        let earnedCount = max(0, min(defaults.integer(forKey: Key.badgesEarned.rawValue), 7))
        let resolvedEarned = defaults.object(forKey: Key.badgesEarned.rawValue) == nil ? 3 : earnedCount
        let defs: [(String, String, String)] = [
            ("first_night", "🌙", "First night"),
            ("new_cuisine", "🍝", "New cuisine"),
            ("anniv_hero", "💍", "Anniv hero"),
            ("spark_master", "✨", "Spark master"),
            ("ten_nights", "🔟", "10 nights"),
            ("gift_giver", "🎁", "Gift giver"),
            ("globe_trot", "🌍", "Globe-trot"),
            ("memory_keeper", "📸", "Memory keeper")
        ]
        return defs.enumerated().map { idx, def in
            RoseBadge(id: def.0, emoji: def.1, title: def.2, isEarned: idx < resolvedEarned)
        }
    }

    /// This month's recap snapshot (G5).
    var monthlyRecap: RoseMonthlyRecap {
        RoseMonthlyRecap(
            monthName: Self.monthFormatter.string(from: Date()),
            nightsOut: max(datesThisMonth, monthlyGoal),
            newPlaces: max(1, datesThisMonth / 2 + 1),
            streakWeeks: streakWeeks,
            badgesEarned: earnedBadgeCount,
            mostLovedNight: "the gallery walk 🎨"
        )
    }

    // MARK: Revive ideas (varied, never-repeating — spec §9)

    private static let reviveIdeas: [ReviveIdea] = [
        ReviveIdea(id: "fort", title: "Build-a-fort movie night", emoji: "🏕",
                   detail: "~15 min · a fresh easy idea each time · 0 travel · revives your rose"),
        ReviveIdea(id: "cook", title: "Cook one dish together", emoji: "🍳",
                   detail: "~20 min · whatever's in the fridge · 0 travel · revives your rose"),
        ReviveIdea(id: "cards", title: "Question-card night", emoji: "🃏",
                   detail: "~15 min · pulls from your Sparks · 0 travel · revives your rose"),
        ReviveIdea(id: "wine", title: "Wine-&-cheese tasting", emoji: "🧀",
                   detail: "~20 min · raid the pantry · 0 travel · revives your rose"),
        ReviveIdea(id: "spa", title: "At-home spa night", emoji: "🛁",
                   detail: "~25 min · candles + playlist · 0 travel · revives your rose"),
        ReviveIdea(id: "world", title: "Around-the-world dinner", emoji: "🌍",
                   detail: "~30 min · pick a country, improvise · 0 travel · revives your rose")
    ]

    /// A fresh idea each time the revive screen is shown (rotates, never repeats back-to-back).
    func nextReviveIdea() -> ReviveIdea {
        let lastID = defaults.string(forKey: Key.lastReviveID.rawValue)
        let pool = Self.reviveIdeas.filter { $0.id != lastID }
        let pick = pool.randomElement() ?? Self.reviveIdeas[0]
        defaults.set(pick.id, forKey: Key.lastReviveID.rawValue)
        return pick
    }

    // MARK: Variable reward (the dopamine — spec §8)

    private static let hiddenDates: [HiddenDateReward] = [
        HiddenDateReward(id: "rooftop", emoji: "🌃", title: "Hidden date unlocked",
                         blurb: "Rooftop stargazing + cocoa — only for couples on a 6-week streak.",
                         rarityLabel: "Rare · 1 of 8 secret dates"),
        HiddenDateReward(id: "speakeasy", emoji: "🥃", title: "Hidden date unlocked",
                         blurb: "A speakeasy with no sign on the door — find it together.",
                         rarityLabel: "Rare · 1 of 8 secret dates"),
        HiddenDateReward(id: "sunrise", emoji: "🌅", title: "Hidden date unlocked",
                         blurb: "A sunrise picnic spot the locals keep quiet about.",
                         rarityLabel: "Rare · 1 of 8 secret dates")
    ]

    /// Roughly 1-in-3 chance after a completed night, gated behind a healthy streak.
    /// Sets `pendingReward` so the entry can present G4.
    @discardableResult
    func maybeUnlockReward() -> HiddenDateReward? {
        guard streakWeeks >= 6, Int.random(in: 0..<3) == 0 else { return nil }
        let reward = Self.hiddenDates.randomElement()
        pendingReward = reward
        return reward
    }

    // MARK: Mutations (local only)

    /// Mark a date completed: opens a bud, bumps XP, refreshes the streak, and
    /// may unlock a variable reward. Called by the parent's plan flow on completion.
    func completeDate() {
        datesThisMonth += 1
        totalXP += RoseManager.xpPerNight
        lastDateAt = Date()
        if streakWeeks == 0 { streakWeeks = 1 }
        maybeUnlockReward()
    }

    /// Revive the rose from a 15-minute at-home idea. Restores pace warmly —
    /// never penalizes the gap (uses streak-freeze if the streak would break).
    func revive() {
        if streakFreezeAvailable { streakFreezeAvailable = false }
        lastDateAt = Date()
        totalXP += RoseManager.xpPerNight / 2
    }

    func clearPendingReward() { pendingReward = nil }

    /// Reset to first-run seed — useful for QA / previews.
    func resetForTesting() {
        defaults.removeObject(forKey: Key.seeded.rawValue)
        defaults.removeObject(forKey: Key.badgesEarned.rawValue)
        defaults.removeObject(forKey: Key.lastReviveID.rawValue)
    }

    // MARK: Persistence plumbing

    private enum Key: String {
        case seeded = "rose_seeded_v1"
        case datesThisMonth = "rose_dates_this_month"
        case monthlyGoal = "rose_monthly_goal"
        case streakWeeks = "rose_streak_weeks"
        case streakFreeze = "rose_streak_freeze"
        case totalXP = "rose_total_xp"
        case lastDateAt = "rose_last_date_at"
        case badgesEarned = "rose_badges_earned"
        case lastReviveID = "rose_last_revive_id"
    }

    private func persist(_ value: Int, _ key: Key) { defaults.set(value, forKey: key.rawValue) }
    private func persist(_ value: Bool, _ key: Key) { defaults.set(value, forKey: key.rawValue) }
    private func persistDate(_ value: Date?, _ key: Key) {
        if let value { defaults.set(value, forKey: key.rawValue) }
        else { defaults.removeObject(forKey: key.rawValue) }
    }

    private static let monthFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMMM"
        return f
    }()
}

// MARK: - Rose palette (illustration only — NOT the accentGold token)
//
// The rose uses its own romantic rose/maroon palette so the gold-exactly-once
// rule is preserved (accentGold is reserved for the single primary CTA per screen).

extension Color {
    /// Stem / leaf green — used only by the rose illustration.
    static let roseStem = Color(hex: "5E6B3A")
    static let roseStemDroop = Color(hex: "4F5A30")
    /// Open-bloom petals (deep → mid → blush).
    static let rosePetalOuter = Color(hex: "7A2C3A")
    static let rosePetalMid = Color(hex: "B5485E")
    static let rosePetalCore = Color(hex: "E8B7C2")
    /// Closed buds (maroon family).
    static let roseBud = Color(hex: "6A2029")
    static let roseBudHighlight = Color(hex: "8A3A45")
    /// Drooping rose (desaturated, never-dead grey-rose).
    static let roseDroopPetal = Color(hex: "7A2C3A")
    static let roseDroopCore = Color(hex: "8A5F48")
    /// Dark progress-track behind cream fills (matches mockup #3a0a0d).
    static let roseTrack = Color(hex: "2A0A0A")
}
