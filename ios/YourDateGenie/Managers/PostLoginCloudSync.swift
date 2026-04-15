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
        } else {
            await NavigationCoordinator.shared.syncDatePlansFromCloudAsync(userId: userId)
            await NavigationCoordinator.shared.syncExperiencesWaitingFromCloudAsync(userId: userId)
            // Still sync playlists even without a couple — the user_id-scoped RLS added in the
            // web-sync migration allows access without couple_id.
            await PlaylistStorageManager.shared.syncFromSupabaseWhenLoggedInByUserIdAsync(userId: userId)
        }
        await MemoryManager.shared.syncMemoriesFromCloudAsync(userId: userId)
        await UserIosContentSync.syncFromSupabase(userId: userId)
        // Gift sync works with or without a couple: pull uses user_id only; push requires coupleId
        // (handled internally by GiftStorageManager — skipped when coupleId is absent).
        await MainActor.run {
            GiftStorageManager.shared.syncFromSupabaseWhenLoggedIn(coupleId: coupleId, userId: userId)
        }
    }
}
