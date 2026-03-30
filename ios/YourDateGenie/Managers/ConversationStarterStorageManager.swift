import Foundation

/// A conversation opener saved by the user (opening question + follow-up + tags). Persisted to UserDefaults.
struct SavedConversationStarter: Identifiable, Codable, Equatable {
    let id: UUID
    let openingQuestion: String
    let followUp: String
    let tagsLabel: String
    let savedAt: Date

    init(id: UUID = UUID(), openingQuestion: String, followUp: String, tagsLabel: String, savedAt: Date = Date()) {
        self.id = id
        self.openingQuestion = openingQuestion
        self.followUp = followUp
        self.tagsLabel = tagsLabel
        self.savedAt = savedAt
    }
}

/// Persists saved conversation starters to UserDefaults. Used by Conversation Starters flow.
final class ConversationStarterStorageManager: ObservableObject {
    static let shared = ConversationStarterStorageManager()

    private let key = "date_genie_saved_conversation_starters"

    @Published private(set) var savedStarters: [SavedConversationStarter] = []

    private init() {
        load()
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([SavedConversationStarter].self, from: data) else {
            savedStarters = []
            return
        }
        savedStarters = decoded.sorted { $0.savedAt > $1.savedAt }
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(savedStarters) else { return }
        UserDefaults.standard.set(data, forKey: key)
        UserIosContentSync.schedulePushIfLoggedIn()
    }

    func add(openingQuestion: String, followUp: String, tagsLabel: String) {
        let starter = SavedConversationStarter(
            openingQuestion: openingQuestion,
            followUp: followUp,
            tagsLabel: tagsLabel
        )
        savedStarters.insert(starter, at: 0)
        save()
    }

    func remove(id: UUID) {
        savedStarters.removeAll { $0.id == id }
        save()
    }

    func isSaved(openingQuestion: String) -> Bool {
        savedStarters.contains { $0.openingQuestion == openingQuestion }
    }

    func savedId(forOpeningQuestion question: String) -> UUID? {
        savedStarters.first(where: { $0.openingQuestion == question })?.id
    }

    func replaceFromCloud(_ starters: [SavedConversationStarter]) {
        savedStarters = starters.sorted { $0.savedAt > $1.savedAt }
        if let data = try? JSONEncoder().encode(savedStarters) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    func exportStarters() -> [SavedConversationStarter] { savedStarters }
}
