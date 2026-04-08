import Foundation

/// Pull/push love notes, saved conversation starters, and spark sessions for the logged-in user (survives reinstall after migration `user_ios_sync_payload`).
enum UserIosContentSync {

    /// Coalesces rapid `schedulePushIfLoggedIn()` calls (e.g. every keystroke path) and runs at most one network upsert at a time.
    fileprivate actor PushCoordinator {
        static let shared = PushCoordinator()

        private var debounceTask: Task<Void, Never>?
        private var inFlight = false
        private var rerunUserId: UUID?

        func scheduleDebouncedPush(userId: UUID) {
            debounceTask?.cancel()
            debounceTask = Task {
                guard !Task.isCancelled else { return }
                await runSerializedPush(userId: userId)
            }
        }

        func runImmediatePush(userId: UUID) async {
            debounceTask?.cancel()
            await runSerializedPush(userId: userId)
        }

        private func runSerializedPush(userId: UUID) async {
            if inFlight {
                rerunUserId = userId
                return
            }
            inFlight = true
            await executePushAll(userId: userId)
            inFlight = false
            if let again = rerunUserId {
                rerunUserId = nil
                await runSerializedPush(userId: again)
            }
        }
    }

    static func syncFromSupabase(userId: UUID) async {
        do {
            if let remote = try await SupabaseService.shared.getUserIosSync(userId: userId) {
                await MainActor.run {
                    let mergedNotes = mergeById(
                        local: LoveNoteStorageManager.shared.exportNotes(),
                        remote: remote.loveNotes,
                        timestamp: \.createdAt
                    )
                    LoveNoteStorageManager.shared.replaceFromCloud(mergedNotes)
                    let mergedStarters = mergeById(
                        local: ConversationStarterStorageManager.shared.exportStarters(),
                        remote: remote.savedConversationStarters,
                        timestamp: \.savedAt
                    )
                    ConversationStarterStorageManager.shared.replaceFromCloud(mergedStarters)
                    let mergedSessions = mergeById(
                        local: SparkSessionStorageManager.shared.exportSessions(),
                        remote: remote.sparkSessions,
                        timestamp: \.createdAt
                    )
                    SparkSessionStorageManager.shared.replaceFromCloud(mergedSessions)
                }
                await PushCoordinator.shared.runImmediatePush(userId: userId)
                return
            }
            await PushCoordinator.shared.runImmediatePush(userId: userId)
        } catch {
            await PushCoordinator.shared.runImmediatePush(userId: userId)
        }
    }

    static func pushAll(userId: UUID) async {
        await PushCoordinator.shared.runImmediatePush(userId: userId)
    }

    private static func executePushAll(userId: UUID) async {
        let payload = await MainActor.run {
            DBUserIosSyncPayload(
                userId: userId,
                loveNotes: LoveNoteStorageManager.shared.exportNotes(),
                savedConversationStarters: ConversationStarterStorageManager.shared.exportStarters(),
                sparkSessions: SparkSessionStorageManager.shared.exportSessions()
            )
        }
        do {
            _ = try await SupabaseService.shared.upsertUserIosSync(payload)
        } catch {
            print("[UserIosContentSync] upsertUserIosSync error: \(error)")
        }
    }

    static func schedulePushIfLoggedIn() {
        Task { @MainActor in
            let userId: UUID
            if let uid = UserProfileManager.shared.userId {
                userId = uid
            } else {
                do {
                    let uid = try await SupabaseService.shared.syncAuthSessionAndReturnUserId()
                    if UserProfileManager.shared.userId == nil {
                        UserProfileManager.shared.userId = uid
                    }
                    userId = uid
                } catch {
                    print("[UserIosContentSync] schedulePushIfLoggedIn skip: \(error)")
                    return
                }
            }
            await PushCoordinator.shared.scheduleDebouncedPush(userId: userId)
        }
    }

    /// Union local and remote by `id`; same id keeps the value with the later timestamp.
    private static func mergeById<T: Identifiable>(
        local: [T],
        remote: [T],
        timestamp: KeyPath<T, Date>
    ) -> [T] where T.ID == UUID {
        var byId: [UUID: T] = [:]
        for item in remote {
            byId[item.id] = item
        }
        for item in local {
            guard let existing = byId[item.id] else {
                byId[item.id] = item
                continue
            }
            if item[keyPath: timestamp] >= existing[keyPath: timestamp] {
                byId[item.id] = item
            }
        }
        return Array(byId.values)
    }
}
