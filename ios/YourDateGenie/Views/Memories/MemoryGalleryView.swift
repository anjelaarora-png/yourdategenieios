import SwiftUI
import PhotosUI

// MARK: - Memory Gallery View with Polaroid Timeline

struct MemoryGalleryView: View {
    var showCloseButton: Bool = false
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var memoryManager = MemoryManager.shared
    @State private var showAddMemory = false
    @State private var selectedMemory: DateMemory?
    @State private var hasAppeared = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.ydgBase
                    .ignoresSafeArea()
                
                if memoryManager.memories.isEmpty {
                    emptyStateView
                } else {
                    galleryView
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if showCloseButton {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button { dismiss() } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(Color.ydgTextPrimary)
                                .frame(width: 44, height: 44)
                        }
                        .accessibilityLabel("Close")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showAddMemory = true } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color.ydgAccent)
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel("Add a memory")
                }
            }
            .toolbarBackground(Color.ydgBase, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .sheet(isPresented: $showAddMemory) {
                AddMemorySheet()
            }
            .sheet(item: $selectedMemory) { memory in
                MemoryDetailView(memory: memory)
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.5)) {
                    hasAppeared = true
                }
            }
        }
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerSection
            Spacer()
            YDGEmptyState(
                systemName: "photo.on.rectangle.angled",
                title: "Your story starts here",
                message: "Add a photo and a line from your next date. They'll collect here, one polaroid at a time.",
                actionTitle: "Add your first memory",
                action: { showAddMemory = true }
            )
            Spacer()
        }
        .padding(.horizontal, YDGSpace.margin)
    }
    
    // MARK: - Gallery (two-column polaroids)
    private var galleryView: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: YDGSpace.lg) {
                headerSection
                
                LazyVGrid(columns: [GridItem(.flexible(), spacing: YDGSpace.sm), GridItem(.flexible(), spacing: YDGSpace.sm)], spacing: YDGSpace.md) {
                    ForEach(Array(memoryManager.memoriesSortedByDate.enumerated()), id: \.element.id) { index, memory in
                        Button { selectedMemory = memory } label: {
                            GalleryPolaroidCard(memory: memory, rotation: Self.tilt(for: index))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(memory.title), \(memory.shortFormattedDate)")
                    }
                }
            }
            .padding(.horizontal, YDGSpace.margin)
            .padding(.bottom, YDGSpace.xxl)
        }
    }

    /// Small, stable tilt so the grid feels hand-placed but doesn't reshuffle on redraw.
    private static func tilt(for index: Int) -> Double {
        [-1.5, 1.2, 0.8, -1.0, 1.4, -0.6][index % 6]
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: YDGSpace.xxs) {
            Text("Our memories")
                .ydgText(.title1)
                .accessibilityAddTraits(.isHeader)
            Text(headerSubtitle)
                .ydgText(.body, color: .ydgTextSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, YDGSpace.xs)
    }

    private var headerSubtitle: String {
        let count = memoryManager.totalMemoriesCount
        guard count > 0, let first = memoryManager.memories.map(\.date).min() else {
            return "Every date, beautifully remembered."
        }
        let month = first.formatted(.dateTime.month(.wide))
        return "\(count) \(count == 1 ? "date" : "dates") together since \(month)"
    }
}

// MARK: - Gallery polaroid
private struct GalleryPolaroidCard: View {
    let memory: DateMemory
    let rotation: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Color.polaroidCream
                .aspectRatio(1, contentMode: .fit)
                .overlay { MemoryPhotoView(memory: memory) }
                .clipped()

            VStack(alignment: .leading, spacing: 2) {
                Text(memory.title)
                    .font(.ydgDisplay(16).italic())
                    .foregroundColor(Color.polaroidCaption)
                    .lineLimit(1)
                Text([memory.location, memory.date.formatted(.dateTime.month(.abbreviated).day())].filter { !$0.isEmpty }.joined(separator: " · "))
                    .font(.ydg(.caption))
                    .foregroundColor(Color.polaroidCaption.opacity(0.65))
                    .lineLimit(1)
            }
            .padding(.top, YDGSpace.xs)
            .padding(.bottom, YDGSpace.xxs)
        }
        .padding(YDGSpace.xs)
        .background(Color.creamCard, in: RoundedRectangle(cornerRadius: 3))
        .shadow(color: Color.black.opacity(0.35), radius: 10, x: 0, y: 6)
        .rotationEffect(.degrees(rotation))
    }
}

// MARK: - Add Memory Sheet

struct AddMemorySheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var coordinator: NavigationCoordinator
    @StateObject private var memoryManager = MemoryManager.shared
    
    @State private var title = ""
    @State private var date = Date()
    @State private var location = ""
    @State private var caption = ""
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var selectedPlanId: UUID?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.ydgBase
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        headerSection
                        
                        photoPickerSection
                        
                        formFieldsSection
                        
                        linkToDatePlanSection
                        
                        saveButton
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.ydg(.body))
                    .foregroundColor(Color.ydgTextPrimary)
                }
            }
            .toolbarBackground(Color.ydgBase, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .onChange(of: selectedItem) { _, newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self) {
                        selectedImageData = data
                    }
                }
            }
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: YDGSpace.xxs) {
            Text("Add a memory")
                .ydgText(.title1)
                .accessibilityAddTraits(.isHeader)
            Text("A photo and a line, so you remember how it felt.")
                .ydgText(.body, color: .ydgTextSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var photoPickerSection: some View {
        PhotosPicker(selection: $selectedItem, matching: .images) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.luxeSurfaceTintStrong)
                    .frame(height: 200)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                Color.ydgBorderStrong,
                                style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
                            )
                    )
                
                if let data = selectedImageData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: 32))
                            .foregroundStyle(Color.ydgIconCream)
                        
                        Text("Add a photo")
                            .ydgText(.subhead, weight: .semibold)
                    }
                }
            }
        }
    }
    
    private var formFieldsSection: some View {
        VStack(spacing: YDGSpace.md) {
            LuxuryTextField(title: "Title", placeholder: "e.g. Dinner at La Belle", text: $title)
            
            HStack {
                Text("Date")
                    .ydgText(.body, weight: .regular)
                Spacer()
                DatePicker("Date", selection: $date, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .tint(Color.ydgAccent)
                    .colorScheme(.dark)
            }
            .padding(.horizontal, YDGSpace.md)
            .frame(minHeight: 52)
            .background(Color.ydgRaised, in: RoundedRectangle(cornerRadius: YDGRadius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: YDGRadius.card, style: .continuous)
                    .stroke(Color.ydgBorder, lineWidth: 1)
            )
            
            LuxuryTextField(title: "Location", placeholder: "e.g. West Village, NYC", text: $location)
            
            VStack(alignment: .leading, spacing: YDGSpace.xs) {
                Text("Caption")
                    .ydgText(.subhead, weight: .medium)
                
                TextField("", text: $caption, prompt: Text("Write something you'll want to remember…").foregroundColor(Color.ydgTextTertiary), axis: .vertical)
                    .font(.ydg(.body))
                    .foregroundColor(Color.ydgTextPrimary)
                    .lineLimit(3...6)
                    .padding(YDGSpace.md)
                    .background(Color.ydgRaised, in: RoundedRectangle(cornerRadius: YDGRadius.card, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: YDGRadius.card, style: .continuous)
                            .stroke(Color.ydgBorder, lineWidth: 1)
                    )
            }
        }
    }
    
    private var linkToDatePlanSection: some View {
        Group {
            if !coordinator.savedPlans.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(Color.ydgTextSecondary)
                        Text("Link to date plan")
                            .font(Font.bodySans(13, weight: .medium))
                            .foregroundColor(Color.ydgTextSecondary)
                        Text("(Booked or approved)")
                            .font(Font.bodySans(12, weight: .regular))
                            .foregroundColor(Color.luxuryCreamMuted)
                    }
                    
                    Menu {
                        Button {
                            selectedPlanId = nil
                        } label: {
                            HStack {
                                Text("None")
                                if selectedPlanId == nil { Image(systemName: "checkmark") }
                            }
                        }
                        ForEach(coordinator.savedPlans) { plan in
                            Button {
                                selectedPlanId = plan.id
                                if title.isEmpty { title = plan.title }
                                if location.isEmpty, let first = plan.stops.first, let addr = first.address {
                                    location = addr
                                }
                            } label: {
                                HStack {
                                    Text(plan.title)
                                    if selectedPlanId == plan.id { Image(systemName: "checkmark") }
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text(selectedPlanTitle)
                                .font(Font.bodySans(15, weight: .regular))
                                .foregroundColor(Color.luxuryCream)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Color.ydgTextSecondary)
                        }
                        .padding(14)
                        .background(Color.luxeSurfaceTintStrong)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.ydgBorder, lineWidth: 1)
                        )
                    }
                }
            }
        }
    }
    
    private var selectedPlanTitle: String {
        guard let id = selectedPlanId,
              let plan = coordinator.savedPlans.first(where: { $0.id == id }) else {
            return "None — add memory without linking"
        }
        return plan.title
    }
    
    private var saveButton: some View {
        Button {
            saveMemory()
        } label: {
            Text("Save memory")
        }
        .buttonStyle(.ydgPrimary)
        .disabled(title.isEmpty)
        .padding(.top, 8)
    }
    
    private func saveMemory() {
        let memory = DateMemory(
            title: title,
            date: date,
            location: location,
            photoData: selectedImageData,
            caption: caption.isEmpty ? nil : caption,
            datePlanId: selectedPlanId
        )
        memoryManager.addMemory(memory)
        dismiss()
    }
}

// MARK: - Memory Detail View

struct MemoryDetailView: View {
    let memory: DateMemory
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var memoryManager = MemoryManager.shared
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.ydgBase
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        polaroidDisplay
                        
                        memoryDetails
                        
                        deleteButton
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .font(Font.bodySans(16, weight: .medium))
                    .foregroundColor(Color.ydgTextSecondary)
                }
            }
            .toolbarBackground(Color.ydgBase, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .alert("Delete Memory?", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    memoryManager.deleteMemory(memory)
                    dismiss()
                }
            } message: {
                Text("This action cannot be undone.")
            }
        }
    }
    
    private var polaroidDisplay: some View {
        VStack(spacing: 0) {
            ZStack {
                Rectangle()
                    .fill(Color.polaroidCream)
                
                MemoryPhotoView(memory: memory)
            }
            .frame(height: 280)
            .clipped()
            .padding(.top, 16)
            .padding(.horizontal, 16)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(memory.caption ?? memory.title)
                    .font(Font.ydgDisplay(22))
                    .foregroundColor(Color.polaroidCaption)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .background(Color.creamCard)
        .cornerRadius(6)
        .shadow(color: Color.polaroidShadow.opacity(0.3), radius: 12, x: 3, y: 6)
        .shadow(color: Color.black.opacity(0.15), radius: 24, x: 6, y: 12)
        .rotationEffect(.degrees(-1.5))
        .padding(.top, 20)
    }
    
    private var memoryDetails: some View {
        VStack(spacing: 16) {
            HStack {
                detailItem(icon: "calendar", title: "Date", value: memory.formattedDate)
                Spacer()
            }
            
            if !memory.location.isEmpty {
                HStack {
                    detailItem(icon: "mappin.circle.fill", title: "Location", value: memory.location)
                    Spacer()
                }
            }
            
            HStack {
                detailItem(icon: "heart.fill", title: "Memory", value: memory.title)
                Spacer()
            }
        }
        .padding(20)
        .luxuryCard()
    }
    
    private func detailItem(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(Color.ydgTextSecondary)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(Font.bodySans(12, weight: .medium))
                    .foregroundColor(Color.luxuryMuted)
                
                Text(value)
                    .font(Font.subheader(16, weight: .regular))
                    .foregroundColor(Color.luxuryCream)
            }
        }
    }
    
    private var deleteButton: some View {
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
        .padding(.bottom, 20)
    }
}

// MARK: - Memory photo (local or cloud URL)
private struct MemoryPhotoView: View {
    let memory: DateMemory
    @State private var resolvedImageURL: URL?
    
    var body: some View {
        Group {
            if let url = memory.httpImageURL {
                asyncImageView(url: url)
            } else if let uiImage = memory.uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else if let url = resolvedImageURL {
                asyncImageView(url: url)
            } else {
                placeholder
            }
        }
        .task(id: memory.imageUrl) {
            await resolveCloudImageURLIfNeeded()
        }
    }
    
    @ViewBuilder
    private func asyncImageView(url: URL) -> some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            case .failure:
                placeholder
            case .empty:
                placeholder
            @unknown default:
                placeholder
            }
        }
    }
    
    /// Legacy: `image_url` may be a storage path (`userId/file.jpg`) for the `date-memories` bucket — use signed URL.
    private func resolveCloudImageURLIfNeeded() async {
        guard let raw = memory.imageUrl?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else {
            await MainActor.run { resolvedImageURL = nil }
            return
        }
        if raw.lowercased().hasPrefix("http") {
            await MainActor.run { resolvedImageURL = nil }
            return
        }
        let bucket = SupabaseService.dateMemoriesStorageBucket
        let path = raw
        let url = try? await SupabaseService.shared.getSignedURL(bucket: bucket, path: path, expiresIn: 3600)
        await MainActor.run { resolvedImageURL = url }
    }
    
    private var placeholder: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "5A2E34"), Color(hex: "2A1A1C")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Image(systemName: "photo")
                .font(.system(size: 28))
                .foregroundStyle(Color.ydgIconCream.opacity(0.7))
        }
    }
}

#Preview {
    MemoryGalleryView()
}
