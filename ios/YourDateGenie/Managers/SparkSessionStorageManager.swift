import Foundation

/// Persists spark sessions (past runs) to UserDefaults. Used by Conversation Starters hub.
final class SparkSessionStorageManager: ObservableObject {
    static let shared = SparkSessionStorageManager()

    private let key = "date_genie_spark_sessions"

    @Published private(set) var sessions: [SparkSession] = []

    private init() {
        load()
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([SparkSession].self, from: data) else {
            sessions = []
            return
        }
        sessions = decoded.sorted { $0.createdAt > $1.createdAt }
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(sessions) else { return }
        UserDefaults.standard.set(data, forKey: key)
        UserIosContentSync.schedulePushIfLoggedIn()
    }

    func add(session: SparkSession) {
        sessions.insert(session, at: 0)
        save()
    }

    func replaceFromCloud(_ items: [SparkSession]) {
        sessions = items.sorted { $0.createdAt > $1.createdAt }
        if let data = try? JSONEncoder().encode(sessions) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    func exportSessions() -> [SparkSession] { sessions }
}
