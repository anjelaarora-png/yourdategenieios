import Foundation

/// Runs all Supabase-backed restores **in order** after login (same coordination model as `experiences_waiting`:
/// one pass at a time, pull/merge then push, so tables do not race each other or duplicate `UserIosContentSync` work).
enum PostLoginCloudSync {

    /// Ordered: `date_plans` → `experiences_waiting` → `playlists` → partner session restore → `date_memories` → `user_ios_sync_payload` → `gift_suggestions`.
    static func run(coupleId: UUID?, userId: UUID) async {
        if let cid = coupleId {
            await NavigationCoordinator.shared.syncDatePlansFromCloudAsync(coupleId: cid)
            await NavigationCoordinator.shared.syncExperiencesWaitingFromCloudAsync(coupleId: cid)
            await PlaylistStorageManager.shared.syncFromSupabaseWhenLoggedInAsync(coupleId: cid)
            await PartnerSessionManager.shared.restoreFromSupabaseIfNeededAsync(userId: userId)
            await MainActor.run {
                GiftStorageManager.shared.syncFromSupabaseWhenLoggedIn(coupleId: cid, userId: userId)
            }
        } else {
            await MainActor.run {
                NavigationCoordinator.shared.markExperiencesWaitingCloudPullFinished()
            }
        }
        await MemoryManager.shared.syncMemoriesFromCloudAsync(userId: userId)
        await UserIosContentSync.syncFromSupabase(userId: userId)
    }
}
