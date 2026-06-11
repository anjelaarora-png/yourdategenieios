import Foundation

/// Runs all Supabase-backed restores **in order** after login (same coordination model as `experiences_waiting`:
/// one pass at a time, pull/merge then push, so tables do not race each other or duplicate `UserIosContentSync` work).
enum PostLoginCloudSync {

    /// Runs all sync steps concurrently — each step operates on a distinct table so there are no
    /// write conflicts between them. `date_memories`, `user_ios_sync_payload`, and gift sync join
    /// the same task group alongside the couple-scoped steps.
    static func run(coupleId: UUID?, userId: UUID) async {
        await withTaskGroup(of: Void.self) { group in
            if let cid = coupleId {
                group.addTask { await NavigationCoordinator.shared.syncDatePlansFromCloudAsync(coupleId: cid) }
                group.addTask { await NavigationCoordinator.shared.syncExperiencesWaitingFromCloudAsync(coupleId: cid) }
                group.addTask { await PlaylistStorageManager.shared.syncFromSupabaseWhenLoggedInAsync(coupleId: cid) }
                group.addTask { await PartnerSessionManager.shared.restoreFromSupabaseIfNeededAsync(userId: userId) }
            } else {
                group.addTask { await NavigationCoordinator.shared.syncDatePlansFromCloudAsync(userId: userId) }
                group.addTask { await NavigationCoordinator.shared.syncExperiencesWaitingFromCloudAsync(userId: userId) }
                // Still sync playlists even without a couple — user_id-scoped RLS allows access.
                group.addTask { await PlaylistStorageManager.shared.syncFromSupabaseWhenLoggedInByUserIdAsync(userId: userId) }
            }
            group.addTask { await MemoryManager.shared.syncMemoriesFromCloudAsync(userId: userId) }
            group.addTask { await UserIosContentSync.syncFromSupabase(userId: userId) }
            // Gift sync works with or without a couple: pull uses user_id only; push requires coupleId
            // (handled internally by GiftStorageManager — skipped when coupleId is absent).
            group.addTask {
                await MainActor.run {
                    GiftStorageManager.shared.syncFromSupabaseWhenLoggedIn(coupleId: coupleId, userId: userId)
                }
            }
        }
    }
}
