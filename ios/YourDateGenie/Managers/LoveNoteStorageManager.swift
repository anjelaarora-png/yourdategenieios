import Foundation

/// A love note saved in the app (text + sign-off name + date). Persisted to UserDefaults.
struct SavedLoveNote: Identifiable, Codable, Equatable {
    let id: UUID
    let message: String
    let signOffName: String?
    let createdAt: Date

    init(id: UUID = UUID(), message: String, signOffName: String? = nil, createdAt: Date = Date()) {
        self.id = id
        self.message = message
        self.signOffName = signOffName
        self.createdAt = createdAt
    }

    enum CodingKeys: String, CodingKey {
        case id, message, createdAt
        case signOffName = "sign_off_name"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        message = try c.decode(String.self, forKey: .message)
        signOffName = try c.decodeIfPresent(String.self, forKey: .signOffName)
        createdAt = try c.decode(Date.self, forKey: .createdAt)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(message, forKey: .message)
        try c.encodeIfPresent(signOffName, forKey: .signOffName)
        try c.encode(createdAt, forKey: .createdAt)
    }
}

/// In-memory draft for the love note editor. Persisted to UserDefaults for auto-save.
struct LoveNoteDraft: Codable, Equatable {
    var noteText: String
    var signOffName: String
    var poeticText: String
    var selectedRewriteStyleRaw: String?
    var updatedAt: Date

    static let empty = LoveNoteDraft(
        noteText: "",
        signOffName: "",
        poeticText: "",
        selectedRewriteStyleRaw: nil,
        updatedAt: Date()
    )

    var isEmpty: Bool {
        noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        poeticText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

/// Persists saved love notes and love note drafts to UserDefaults. Used by the Love Note tab.
final class LoveNoteStorageManager: ObservableObject {
    static let shared = LoveNoteStorageManager()

    private let key = "date_genie_saved_love_notes"
    private let draftKey = "date_genie_love_note_draft"

    @Published private(set) var savedNotes: [SavedLoveNote] = []

    private init() {
        load()
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([SavedLoveNote].self, from: data) else {
            savedNotes = []
            return
        }
        savedNotes = decoded.sorted { $0.createdAt > $1.createdAt }
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(savedNotes) else { return }
        UserDefaults.standard.set(data, forKey: key)
        UserIosContentSync.schedulePushIfLoggedIn()
    }

    func add(message: String, signOffName: String? = nil) {
        let note = SavedLoveNote(message: message, signOffName: signOffName)
        savedNotes.insert(note, at: 0)
        save()
        NotificationManager.shared.addNotification(AppNotification(
            type: .loveNoteSaved,
            title: "Love note saved!",
            message: "\"\(String(message.prefix(60)).trimmingCharacters(in: .whitespaces))\(message.count > 60 ? "…" : "")\"",
            timestamp: Date()
        ))
    }

    func remove(id: UUID) {
        savedNotes.removeAll { $0.id == id }
        save()
    }

    func replaceFromCloud(_ notes: [SavedLoveNote]) {
        savedNotes = notes.sorted { $0.createdAt > $1.createdAt }
        if let data = try? JSONEncoder().encode(savedNotes) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    func exportNotes() -> [SavedLoveNote] { savedNotes }

    // MARK: - Draft (auto-save)

    func saveDraft(_ draft: LoveNoteDraft) {
        guard let data = try? JSONEncoder().encode(draft) else { return }
        UserDefaults.standard.set(data, forKey: draftKey)
        UserIosContentSync.schedulePushIfLoggedIn()
    }

    func loadDraft() -> LoveNoteDraft? {
        guard let data = UserDefaults.standard.data(forKey: draftKey),
              let draft = try? JSONDecoder().decode(LoveNoteDraft.self, from: data) else {
            return nil
        }
        return draft
    }

    func clearDraft() {
        UserDefaults.standard.removeObject(forKey: draftKey)
        UserIosContentSync.schedulePushIfLoggedIn()
    }
}
