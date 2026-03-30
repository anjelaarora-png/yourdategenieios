import Foundation

/// Pull/push love notes, saved conversation starters, and spark sessions for the logged-in user (survives reinstall after migration `user_ios_sync_payload`).
enum UserIosContentSync {
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
                await pushAll(userId: userId)
                return
            }
            await pushAll(userId: userId)
        } catch {
            await pushAll(userId: userId)
        }
    }

    static func pushAll(userId: UUID) async {
        print("[UserIosContentSync] pushAll called userId=\(userId)")
        let payload = await MainActor.run {
            DBUserIosSyncPayload(
                userId: userId,
                loveNotes: LoveNoteStorageManager.shared.exportNotes(),
                savedConversationStarters: ConversationStarterStorageManager.shared.exportStarters(),
                sparkSessions: SparkSessionStorageManager.shared.exportSessions()
            )
        }
        do {
            print("[UserIosContentSync] before upsertUserIosSync")
            _ = try await SupabaseService.shared.upsertUserIosSync(payload)
            print("[UserIosContentSync] upsertUserIosSync success")
        } catch {
            print("[UserIosContentSync] upsertUserIosSync error: \(error)")
        }
    }

    static func schedulePushIfLoggedIn() {
        Task { @MainActor in
            if let uid = UserProfileManager.shared.userId {
                Task { await pushAll(userId: uid) }
                return
            }
            Task {
                do {
                    let uid = try await SupabaseService.shared.syncAuthSessionAndReturnUserId()
                    await MainActor.run {
                        if UserProfileManager.shared.userId == nil {
                            UserProfileManager.shared.userId = uid
                        }
                    }
                    await pushAll(userId: uid)
                } catch {
                    print("[UserIosContentSync] schedulePushIfLoggedIn skip: \(error)")
                }
            }
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
