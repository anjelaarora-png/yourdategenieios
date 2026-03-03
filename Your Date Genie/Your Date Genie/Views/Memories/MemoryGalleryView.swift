import SwiftUI
import PhotosUI

struct MemoryGalleryView: View {
    var showCloseButton: Bool = false
    
    @Environment(\.dismiss) private var dismiss
    @State private var memories: [DateMemory] = []
    @State private var selectedItem: PhotosPickerItem?
    @State private var showAddMemory = false
    @State private var selectedMemory: DateMemory?
    
    private let columns = [
        GridItem(.flexible(), spacing: 3),
        GridItem(.flexible(), spacing: 3),
        GridItem(.flexible(), spacing: 3)
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Luxurious background
                Color.luxuryMaroon
                    .ignoresSafeArea()
                
                if memories.isEmpty {
                    emptyState
                } else {
                    galleryGrid
                }
            }
            .navigationTitle("Memories")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if showCloseButton {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Close") {
                            dismiss()
                        }
                        .font(Font.bodySans(16, weight: .medium))
                        .foregroundColor(Color.luxuryGold)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(LinearGradient.goldShimmer)
                    }
                }
            }
            .toolbarBackground(Color.luxuryMaroon, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .onChange(of: selectedItem) { newValue in
                if newValue != nil {
                    addMemory()
                }
            }
            .sheet(item: $selectedMemory) { memory in
                MemoryDetailView(memory: memory) {
                    deleteMemory(memory)
                }
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Color.luxuryGold.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "photo.stack.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(LinearGradient.goldShimmer)
            }
            
            VStack(spacing: 10) {
                Text("Capture Your Moments")
                    .font(Font.header(32, weight: .bold))
                    .foregroundColor(Color.luxuryGold)
                
                Text("Save photos from your special evenings together")
                    .font(Font.subheader(15, weight: .regular))
                    .foregroundColor(Color.luxuryCreamMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            PhotosPicker(selection: $selectedItem, matching: .images) {
                HStack(spacing: 10) {
                    Image(systemName: "photo.badge.plus")
                    Text("Add First Memory")
                }
            }
            .buttonStyle(LuxuryGoldButtonStyle())
        }
    }
    
    private var galleryGrid: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // Stats header
                HStack(spacing: 0) {
                    VStack(spacing: 6) {
                        Text("\(memories.count)")
                            .font(Font.header(28, weight: .bold))
                            .foregroundColor(Color.luxuryGold)
                        Text("memories")
                            .font(Font.bodySans(12, weight: .regular))
                            .foregroundColor(Color.luxuryMuted)
                    }
                    .frame(maxWidth: .infinity)
                    
                    Rectangle()
                        .fill(Color.luxuryGold.opacity(0.3))
                        .frame(width: 1, height: 40)
                    
                    VStack(spacing: 6) {
                        Text(uniqueDatesCount)
                            .font(Font.header(28, weight: .bold))
                            .foregroundColor(Color.luxuryGold)
                        Text("dates")
                            .font(Font.bodySans(12, weight: .regular))
                            .foregroundColor(Color.luxuryMuted)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.vertical, 20)
                .luxuryCard()
                .padding(.horizontal, 20)
                .padding(.top, 16)
                
                // Grid
                LazyVGrid(columns: columns, spacing: 3) {
                    ForEach(memories) { memory in
                        MemoryThumbnail(memory: memory)
                            .aspectRatio(1, contentMode: .fill)
                            .onTapGesture {
                                selectedMemory = memory
                            }
                    }
                }
                .padding(.horizontal, 3)
                
                // Add more button
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle")
                        Text("Add More Memories")
                    }
                    .font(Font.bodySans(14, weight: .medium))
                    .foregroundColor(Color.luxuryGold)
                    .padding(.vertical, 14)
                    .frame(maxWidth: .infinity)
                    .background(Color.luxuryMaroonLight)
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.luxuryGold.opacity(0.3), lineWidth: 1)
                    )
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
            }
        }
    }
    
    private var uniqueDatesCount: String {
        let uniqueDates = Set(memories.map { Calendar.current.startOfDay(for: $0.date) })
        return "\(uniqueDates.count)"
    }
    
    private func addMemory() {
        let newMemory = DateMemory(
            id: UUID(),
            imageData: nil,
            date: Date(),
            caption: "",
            location: "Recent Date"
        )
        memories.append(newMemory)
        selectedItem = nil
    }
    
    private func deleteMemory(_ memory: DateMemory) {
        memories.removeAll { $0.id == memory.id }
        selectedMemory = nil
    }
}

// MARK: - Memory Thumbnail
struct MemoryThumbnail: View {
    let memory: DateMemory
    
    var body: some View {
        ZStack {
            if let imageData = memory.imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                LinearGradient(
                    colors: [Color.luxuryMaroonLight, Color.luxuryMaroonMedium],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                Image(systemName: "photo")
                    .font(.system(size: 28))
                    .foregroundColor(Color.luxuryGold.opacity(0.4))
            }
        }
        .frame(minWidth: 0, maxWidth: .infinity)
        .aspectRatio(1, contentMode: .fill)
        .clipped()
    }
}

// MARK: - Memory Detail View
struct MemoryDetailView: View {
    let memory: DateMemory
    let onDelete: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var caption: String = ""
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.luxuryMaroon
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Image
                    ZStack {
                        if let imageData = memory.imageData, let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        } else {
                            Rectangle()
                                .fill(Color.luxuryMaroonLight)
                                .aspectRatio(4/3, contentMode: .fit)
                                .overlay(
                                    Image(systemName: "photo")
                                        .font(.system(size: 60))
                                        .foregroundColor(Color.luxuryGold.opacity(0.3))
                                )
                        }
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Details
                    VStack(alignment: .leading, spacing: 20) {
                        // Date & location
                        HStack(spacing: 20) {
                            HStack(spacing: 8) {
                                Image(systemName: "calendar")
                                    .foregroundColor(Color.luxuryGold)
                                Text(formattedDate)
                                    .font(Font.bodySans(14, weight: .medium))
                                    .foregroundColor(Color.luxuryCream)
                            }
                            
                            HStack(spacing: 8) {
                                Image(systemName: "mappin.circle")
                                    .foregroundColor(Color.luxuryGold)
                                Text(memory.location)
                                    .font(Font.bodySans(14, weight: .medium))
                                    .foregroundColor(Color.luxuryCream)
                            }
                        }
                        
                        // Caption editor
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Caption")
                                .font(Font.subheader(16, weight: .semibold))
                                .foregroundColor(Color.luxuryGold)
                            
                            TextField("Add a caption...", text: $caption)
                                .font(Font.bodySans(15, weight: .regular))
                                .foregroundColor(Color.luxuryCream)
                                .padding(14)
                                .background(Color.luxuryMaroonLight)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.luxuryGold.opacity(0.3), lineWidth: 1)
                                )
                        }
                        
                        Spacer()
                        
                        // Delete button
                        Button {
                            showDeleteConfirmation = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "trash")
                                Text("Delete Memory")
                            }
                            .font(Font.bodySans(14, weight: .medium))
                            .foregroundColor(Color.luxuryError)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.luxuryError.opacity(0.1))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.luxuryError.opacity(0.3), lineWidth: 1)
                            )
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Memory")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .font(Font.bodySans(16, weight: .medium))
                    .foregroundColor(Color.luxuryGold)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        dismiss()
                    }
                    .font(Font.bodySans(16, weight: .semibold))
                    .foregroundColor(Color.luxuryGold)
                }
            }
            .toolbarBackground(Color.luxuryMaroon, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .alert("Delete Memory?", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    onDelete()
                }
            } message: {
                Text("This action cannot be undone.")
            }
            .onAppear {
                caption = memory.caption
            }
        }
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: memory.date)
    }
}

// MARK: - Memory Model
struct DateMemory: Identifiable {
    let id: UUID
    var imageData: Data?
    var date: Date
    var caption: String
    var location: String
}

#Preview {
    MemoryGalleryView()
}
