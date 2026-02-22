import SwiftUI
import PhotosUI

struct MemoryGalleryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var memories: [DateMemory] = []
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var showingPhotoPicker = false
    @State private var showingCamera = false
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "photo.stack.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.brandGold)
                        
                        Text("Date Memories")
                            .font(.custom("Cormorant-Bold", size: 28, relativeTo: .title))
                            .foregroundColor(Color(UIColor.label))
                        
                        Text("Capture and relive your special moments")
                            .font(.system(size: 15))
                            .foregroundColor(Color(UIColor.secondaryLabel))
                    }
                    .padding(.top, 20)
                    
                    // Add Memory Buttons
                    HStack(spacing: 12) {
                        AddMemoryButton(
                            icon: "camera.fill",
                            title: "Take Photo",
                            color: .blue
                        ) {
                            showingCamera = true
                        }
                        
                        PhotosPicker(selection: $selectedItems, maxSelectionCount: 10, matching: .images) {
                            AddMemoryCard(icon: "photo.on.rectangle", title: "From Library", color: .purple)
                        }
                    }
                    .padding(.horizontal, 16)
                    
                    // Memory Grid
                    if memories.isEmpty {
                        emptyState
                    } else {
                        memoryGrid
                    }
                }
                .padding(.bottom, 40)
            }
            .background(Color.brandCream)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.brandPrimary)
                }
            }
            .onChange(of: selectedItems) { items in
                Task {
                    for item in items {
                        if let data = try? await item.loadTransferable(type: Data.self),
                           let image = UIImage(data: data) {
                            let memory = DateMemory(
                                image: image,
                                caption: "",
                                date: Date()
                            )
                            memories.append(memory)
                        }
                    }
                    selectedItems = []
                }
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart.text.square")
                .font(.system(size: 64))
                .foregroundColor(Color.gray.opacity(0.3))
            
            Text("No memories yet")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color(UIColor.label))
            
            Text("Start capturing photos from your dates\nto build your memory collection")
                .font(.system(size: 14))
                .foregroundColor(Color(UIColor.secondaryLabel))
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }
    
    private var memoryGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 4),
            GridItem(.flexible(), spacing: 4),
            GridItem(.flexible(), spacing: 4)
        ], spacing: 4) {
            ForEach(memories) { memory in
                MemoryThumbnail(memory: memory)
            }
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Memory Model
struct DateMemory: Identifiable {
    let id = UUID()
    let image: UIImage
    var caption: String
    let date: Date
    var datePlanTitle: String?
}

// MARK: - Add Memory Button
struct AddMemoryButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            AddMemoryCard(icon: icon, title: title, color: color)
        }
    }
}

struct AddMemoryCard: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(color)
                .frame(width: 56, height: 56)
                .background(color.opacity(0.1))
                .cornerRadius(14)
            
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(UIColor.label))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 2)
    }
}

// MARK: - Memory Thumbnail
struct MemoryThumbnail: View {
    let memory: DateMemory
    @State private var showDetail = false
    
    var body: some View {
        Button {
            showDetail = true
        } label: {
            Image(uiImage: memory.image)
                .resizable()
                .aspectRatio(1, contentMode: .fill)
                .clipped()
        }
        .sheet(isPresented: $showDetail) {
            MemoryDetailView(memory: memory)
        }
    }
}

// MARK: - Memory Detail View
struct MemoryDetailView: View {
    let memory: DateMemory
    @Environment(\.dismiss) private var dismiss
    @State private var caption: String
    
    init(memory: DateMemory) {
        self.memory = memory
        _caption = State(initialValue: memory.caption)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Image
                Image(uiImage: memory.image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: UIScreen.main.bounds.height * 0.5)
                
                // Details
                VStack(alignment: .leading, spacing: 16) {
                    // Date
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(.brandGold)
                        Text(memory.date.formatted(date: .long, time: .shortened))
                            .font(.system(size: 14))
                            .foregroundColor(Color(UIColor.secondaryLabel))
                    }
                    
                    // Caption
                    TextField("Add a caption...", text: $caption, axis: .vertical)
                        .textFieldStyle(.plain)
                        .font(.system(size: 16))
                        .padding(12)
                        .background(Color.white)
                        .cornerRadius(12)
                    
                    Spacer()
                    
                    // Actions
                    HStack(spacing: 12) {
                        Button {
                            shareImage()
                        } label: {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Share")
                            }
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.brandPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.white)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.brandPrimary.opacity(0.3), lineWidth: 1)
                            )
                        }
                        
                        Button {
                            // Save to photos
                        } label: {
                            HStack {
                                Image(systemName: "square.and.arrow.down")
                                Text("Save")
                            }
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(LinearGradient.goldGradient)
                            .cornerRadius(12)
                        }
                    }
                }
                .padding(20)
            }
            .background(Color.brandCream)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.brandPrimary)
                }
            }
        }
    }
    
    private func shareImage() {
        let activityVC = UIActivityViewController(activityItems: [memory.image], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}

#Preview {
    MemoryGalleryView()
}
