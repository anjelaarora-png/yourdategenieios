import Foundation
import SwiftUI
import Combine

// MARK: - Date Memory Model

/// Represents a single memory captured from a date (photo may be local photoData or cloud imageUrl).
struct DateMemory: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var date: Date
    var location: String
    var photoData: Data?
    /// URL of photo in cloud storage (used when restored from Supabase; photoData is nil).
    var imageUrl: String?
    var caption: String?
    var datePlanId: UUID?
    var createdAt: Date
    
    init(
        id: UUID = UUID(),
        title: String,
        date: Date = Date(),
        location: String = "",
        photoData: Data? = nil,
        imageUrl: String? = nil,
        caption: String? = nil,
        datePlanId: UUID? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.date = date
        self.location = location
        self.photoData = photoData
        self.imageUrl = imageUrl
        self.caption = caption
        self.datePlanId = datePlanId
        self.createdAt = createdAt
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }
    
    var shortFormattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
    
    var hasPhoto: Bool {
        (photoData != nil && !photoData!.isEmpty) || (imageUrl != nil && !imageUrl!.isEmpty)
    }
    
    var uiImage: UIImage? {
        guard let data = photoData else { return nil }
        return UIImage(data: data)
    }
    
    /// URL for loading photo from cloud when photoData is nil.
    var imageURL: URL? {
        guard let s = imageUrl, !s.isEmpty, let url = URL(string: s) else { return nil }
        return url
    }
    
    /// Absolute http(s) URL for public Supabase object links (e.g. after `uploadMemoryImage`).
    var httpImageURL: URL? {
        guard let s = imageUrl?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty else { return nil }
        guard s.lowercased().hasPrefix("http") else { return nil }
        return URL(string: s)
    }
}

// MARK: - Memory Manager

/// Singleton manager for handling memory storage and retrieval
class MemoryManager: ObservableObject {
    static let shared = MemoryManager()
    
    @Published var memories: [DateMemory] = []
    @Published var isLoading = false
    
    /// Legacy UserDefaults key — large blobs (photos in JSON) must not live in CFPreferences (iOS ~4MB limit).
    private let memoriesUserDefaultsKey = "savedMemories"
    private static let memoriesFilename = "saved_memories.json"
    
    private init() {
        loadMemories()
    }
    
    /// Application Support file — no size limit like UserDefaults.
    private static func memoriesFileURL() -> URL {
        let fm = FileManager.default
        let base = (try? fm.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )) ?? fm.temporaryDirectory
        let dir = base.appendingPathComponent("YourDateGenie", isDirectory: true)
        if !fm.fileExists(atPath: dir.path) {
            try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir.appendingPathComponent(memoriesFilename)
    }
    
    // MARK: - Computed Properties
    
    var totalMemoriesCount: Int {
        memories.count
    }
    
    var memoriesSortedByDate: [DateMemory] {
        memories.sorted { $0.date > $1.date }
    }
    
    var memoriesGroupedByMonth: [String: [DateMemory]] {
        Dictionary(grouping: memoriesSortedByDate) { memory in
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: memory.date)
        }
    }
    
    // MARK: - CRUD Operations
    
    func addMemory(_ memory: DateMemory) {
        print("📸 Memory save triggered — id=\(memory.id) hasPhotoData=\(memory.photoData != nil && !memory.photoData!.isEmpty)")
        memories.append(memory)
        saveMemories()
        Task { await uploadMemoryToCloudIfNeeded(memory) }
    }
    
    func updateMemory(_ memory: DateMemory) {
        if let index = memories.firstIndex(where: { $0.id == memory.id }) {
            memories[index] = memory
            saveMemories()
        }
    }
    
    func deleteMemory(_ memory: DateMemory) {
        memories.removeAll { $0.id == memory.id }
        saveMemories()
        Task { await deleteMemoryFromCloudIfNeeded(memory) }
    }
    
    func deleteMemory(at indexSet: IndexSet) {
        let removed = indexSet.map { memories[$0] }
        memories.remove(atOffsets: indexSet)
        saveMemories()
        for m in removed {
            Task { await deleteMemoryFromCloudIfNeeded(m) }
        }
    }

    /// Removes the `date_memories` row and best-effort storage object when logged in (keeps Supabase aligned with local deletes).
    private func deleteMemoryFromCloudIfNeeded(_ memory: DateMemory) async {
        guard UserProfileManager.shared.isLoggedIn else { return }
        do {
            try await SupabaseService.shared.deleteMemory(memoryId: memory.id)
        } catch {
            print("[MemoryManager] deleteMemory cloud row: \(error)")
        }
        if let target = SupabaseService.memoryStorageDeletionTarget(publicImageURL: memory.imageUrl) {
            do {
                try await SupabaseService.shared.deleteImage(bucket: target.bucket, path: target.path)
            } catch {
                print("[MemoryManager] deleteMemory storage: \(error)")
            }
        }
    }
    
    func getMemory(for datePlanId: UUID) -> DateMemory? {
        memories.first { $0.datePlanId == datePlanId }
    }
    
    /// Restore memories from Supabase after login so history persists across reinstalls.
    /// Merges with local rows (same id) so unsynced photos are not discarded, then uploads locals still holding image data.
    func syncMemoriesFromCloud(userId: UUID) {
        Task { await syncMemoriesFromCloudAsync(userId: userId) }
    }

    func syncMemoriesFromCloudAsync(userId: UUID) async {
        do {
            let dbMemories = try await SupabaseService.shared.getMemories(userId: userId)
            let converted: [DateMemory] = dbMemories.map { db in
                DateMemory(
                    id: db.id,
                    title: db.caption ?? "Memory",
                    date: db.takenAt,
                    location: "",
                    photoData: nil,
                    imageUrl: db.imageUrl,
                    caption: db.caption,
                    datePlanId: db.datePlanId,
                    createdAt: db.createdAt ?? db.takenAt
                )
            }
            await MainActor.run {
                let merged = Self.mergeMemoriesForSync(local: self.memories, remote: converted)
                self.memories = merged
                saveMemories()
            }
            await pushAllLocalMemoriesPhotoDataToCloud()
        } catch {
            await pushAllLocalMemoriesPhotoDataToCloud()
        }
    }

    /// Prefer cloud row when it has storage path/URL; otherwise keep newer `createdAt` or local photo payload.
    private static func mergeMemoriesForSync(local: [DateMemory], remote: [DateMemory]) -> [DateMemory] {
        let remoteById = Dictionary(uniqueKeysWithValues: remote.map { ($0.id, $0) })
        var handled = Set<UUID>()
        var out: [DateMemory] = []
        for l in local {
            guard let r = remoteById[l.id] else {
                out.append(l)
                handled.insert(l.id)
                continue
            }
            let rHasPath = r.imageUrl.map { !$0.isEmpty } ?? false
            let lPhoto = l.photoData != nil && !l.photoData!.isEmpty
            let merged: DateMemory
            if rHasPath && !lPhoto {
                merged = r
            } else if lPhoto && !rHasPath {
                merged = l
            } else if l.createdAt >= r.createdAt {
                merged = l
            } else {
                merged = r
            }
            out.append(merged)
            handled.insert(l.id)
        }
        for r in remote where !handled.contains(r.id) {
            out.append(r)
        }
        return out.sorted { $0.date > $1.date }
    }

    /// Uploads every memory that still has local photo bytes (e.g. pending after offline use or failed upload).
    func pushAllLocalMemoriesPhotoDataToCloud() async {
        let snapshot = await MainActor.run { memories }
        for m in snapshot {
            await uploadMemoryToCloudIfNeeded(m)
        }
    }
    
    private func uploadMemoryToCloudIfNeeded(_ memory: DateMemory) async {
        print("📸 uploadMemoryToCloudIfNeeded — memoryId=\(memory.id) hasPhotoData=\(memory.photoData != nil && !memory.photoData!.isEmpty)")
        guard let data = memory.photoData, !data.isEmpty else {
            print("⚠️ uploadMemoryToCloudIfNeeded: skip — photoData is nil or empty")
            return
        }
        print("📦 photoData size: \(data.count) bytes")
        do {
            // Check whether a cloud row already exists with a URL — isolate this so a DB error doesn't abort the upload
            let existingUrl: String? = await {
                if let existing = try? await SupabaseService.shared.getMemory(memoryId: memory.id) {
                    return existing.imageUrl.isEmpty ? nil : existing.imageUrl
                }
                return nil
            }()
            if let url = existingUrl {
                print("ℹ️ uploadMemoryToCloudIfNeeded: row already exists with imageUrl=\(url) — skipping upload")
                await MainActor.run {
                    if let idx = memories.firstIndex(where: { $0.id == memory.id }) {
                        memories[idx].imageUrl = url
                        memories[idx].photoData = nil
                        saveMemories()
                    }
                }
                return
            }
            print("📸 uploadMemoryToCloudIfNeeded: resolving userId…")
            let userId = try await SupabaseService.shared.syncAuthSessionAndReturnUserId()
            print("📸 uploadMemoryToCloudIfNeeded: userId=\(userId) — calling uploadMemoryImage")
            await MainActor.run {
                if UserProfileManager.shared.userId == nil {
                    UserProfileManager.shared.userId = userId
                }
            }
            let publicUrlString = try await SupabaseService.shared.uploadMemoryImage(
                data: data,
                userId: userId.uuidString
            )
            print("📸 uploadMemoryToCloudIfNeeded: upload done — url=\(publicUrlString)")
            let db = DBDateMemory(
                id: memory.id,
                userId: userId,
                datePlanId: memory.datePlanId,
                venueId: nil,
                imageUrl: publicUrlString,
                caption: memory.caption ?? memory.title,
                takenAt: memory.date,
                isPublic: false,
                createdAt: nil
            )
            _ = try await SupabaseService.shared.createMemory(db)
            print("✅ uploadMemoryToCloudIfNeeded: createMemory success — memoryId=\(memory.id)")
            await MainActor.run {
                if let idx = memories.firstIndex(where: { $0.id == memory.id }) {
                    memories[idx].imageUrl = publicUrlString
                    memories[idx].photoData = nil
                    saveMemories()
                }
            }
        } catch {
            print("❌ uploadMemoryToCloudIfNeeded error:", error)
        }
    }
    
    // MARK: - Persistence
    
    private func loadMemories() {
        let fileURL = Self.memoriesFileURL()
        if let data = try? Data(contentsOf: fileURL),
           let decoded = try? JSONDecoder().decode([DateMemory].self, from: data) {
            memories = decoded
            return
        }
        // One-time migration from UserDefaults → file (frees CFPreferences so small keys like isLoggedIn work).
        if let data = UserDefaults.standard.data(forKey: memoriesUserDefaultsKey),
           let decoded = try? JSONDecoder().decode([DateMemory].self, from: data) {
            memories = decoded
            UserDefaults.standard.removeObject(forKey: memoriesUserDefaultsKey)
            saveMemories()
        }
    }
    
    private func saveMemories() {
        guard let encoded = try? JSONEncoder().encode(memories) else { return }
        do {
            try encoded.write(to: Self.memoriesFileURL(), options: [.atomic])
            if UserDefaults.standard.object(forKey: memoriesUserDefaultsKey) != nil {
                UserDefaults.standard.removeObject(forKey: memoriesUserDefaultsKey)
            }
        } catch {
            print("[MemoryManager] saveMemories failed: \(error)")
        }
    }
    
    func clearAllMemories() {
        memories.removeAll()
        UserDefaults.standard.removeObject(forKey: memoriesUserDefaultsKey)
        try? FileManager.default.removeItem(at: Self.memoriesFileURL())
    }
    
    // MARK: - Sample Data (for preview/testing)
    
    func loadSampleMemories() {
        let sampleMemories = [
            DateMemory(
                title: "Romantic Dinner at La Belle",
                date: Calendar.current.date(byAdding: .day, value: -3, to: Date())!,
                location: "La Belle Restaurant, San Francisco",
                caption: "The best pasta we've ever had together"
            ),
            DateMemory(
                title: "Sunset Picnic",
                date: Calendar.current.date(byAdding: .day, value: -10, to: Date())!,
                location: "Golden Gate Park",
                caption: "Watching the sunset with my favorite person"
            ),
            DateMemory(
                title: "Wine Tasting Adventure",
                date: Calendar.current.date(byAdding: .day, value: -17, to: Date())!,
                location: "Napa Valley",
                caption: "Discovered our new favorite Cabernet"
            ),
            DateMemory(
                title: "Cooking Class Date",
                date: Calendar.current.date(byAdding: .day, value: -25, to: Date())!,
                location: "Sur La Table, Palo Alto",
                caption: "We made fresh pasta from scratch!"
            ),
            DateMemory(
                title: "Beach Bonfire Night",
                date: Calendar.current.date(byAdding: .month, value: -1, to: Date())!,
                location: "Ocean Beach, SF",
                caption: "S'mores and stargazing"
            )
        ]
        
        for memory in sampleMemories {
            if !memories.contains(where: { $0.title == memory.title }) {
                memories.append(memory)
            }
        }
        saveMemories()
    }
}

// MARK: - Memory Creation Helper

struct MemoryCreationData {
    var title: String = ""
    var date: Date = Date()
    var location: String = ""
    var photoData: Data? = nil
    var caption: String = ""
    var datePlanId: UUID? = nil
    
    var isValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    func toMemory() -> DateMemory {
        DateMemory(
            title: title,
            date: date,
            location: location,
            photoData: photoData,
            caption: caption.isEmpty ? nil : caption,
            datePlanId: datePlanId
        )
    }
}
