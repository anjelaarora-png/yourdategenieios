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
}

// MARK: - Memory Manager

/// Singleton manager for handling memory storage and retrieval
class MemoryManager: ObservableObject {
    static let shared = MemoryManager()
    
    @Published var memories: [DateMemory] = []
    @Published var isLoading = false
    
    private let memoriesKey = "savedMemories"
    
    private init() {
        loadMemories()
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
    }
    
    func deleteMemory(at indexSet: IndexSet) {
        memories.remove(atOffsets: indexSet)
        saveMemories()
    }
    
    func getMemory(for datePlanId: UUID) -> DateMemory? {
        memories.first { $0.datePlanId == datePlanId }
    }
    
    /// Restore memories from Supabase after login so history persists across reinstalls.
    func syncMemoriesFromCloud(coupleId: UUID) {
        Task {
            do {
                let dbMemories = try await SupabaseService.shared.getMemories(coupleId: coupleId)
                let converted: [DateMemory] = dbMemories.map { db in
                    DateMemory(
                        id: db.memoryId,
                        title: db.notes ?? "Memory",
                        date: db.createdAt,
                        location: "",
                        photoData: nil,
                        imageUrl: db.photoUrls?.first,
                        caption: db.notes,
                        datePlanId: db.planId,
                        createdAt: db.createdAt
                    )
                }
                await MainActor.run {
                    if !converted.isEmpty {
                        memories = converted
                        saveMemories()
                    }
                }
            } catch {
                // User may be offline or table may not exist
            }
        }
    }
    
    private func uploadMemoryToCloudIfNeeded(_ memory: DateMemory) async {
        guard let coupleId = UserProfileManager.shared.coupleId,
              let planId = memory.datePlanId,
              let data = memory.photoData, !data.isEmpty else { return }
        do {
            let path = "\(UserProfileManager.shared.userId?.uuidString ?? "user")/\(memory.id.uuidString).jpg"
            _ = try await SupabaseService.shared.uploadImage(data: data, bucket: "memories", path: path)
            let publicURL = SupabaseService.shared.getPublicURL(bucket: "memories", path: path).absoluteString
            let db = DBDateMemory(
                memoryId: memory.id,
                planId: planId,
                coupleId: coupleId,
                rating: nil,
                notes: memory.caption ?? memory.title,
                photoUrls: [publicURL],
                createdAt: memory.createdAt
            )
            _ = try await SupabaseService.shared.createMemory(db)
        } catch {
            // User may be offline
        }
    }
    
    // MARK: - Persistence
    
    private func loadMemories() {
        guard let data = UserDefaults.standard.data(forKey: memoriesKey),
              let decoded = try? JSONDecoder().decode([DateMemory].self, from: data) else {
            return
        }
        memories = decoded
    }
    
    private func saveMemories() {
        if let encoded = try? JSONEncoder().encode(memories) {
            UserDefaults.standard.set(encoded, forKey: memoriesKey)
        }
    }
    
    func clearAllMemories() {
        memories.removeAll()
        UserDefaults.standard.removeObject(forKey: memoriesKey)
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
