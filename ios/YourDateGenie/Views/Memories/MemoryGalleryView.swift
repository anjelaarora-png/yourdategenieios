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
                luxuryBackground
                
                if memoryManager.memories.isEmpty {
                    emptyStateView
                } else {
                    timelineView
                }
                
                floatingAddButton
            }
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
            }
            .toolbarBackground(Color.luxuryMaroon, for: .navigationBar)
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
                #if DEBUG
                SupabaseService.shared.debugTestStorageUpload()
                #endif
            }
        }
    }
    
    // MARK: - Luxury Background
    private var luxuryBackground: some View {
        ZStack {
            Color.luxuryMaroon
                .ignoresSafeArea()
            
            FloatingSparklesView()
                .ignoresSafeArea()
        }
    }
    
    // MARK: - Floating Add Button
    private var floatingAddButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button {
                    showAddMemory = true
                } label: {
                    ZStack {
                        Circle()
                            .fill(LinearGradient.goldShimmer)
                            .frame(width: 60, height: 60)
                            .shadow(color: Color.luxuryGold.opacity(0.5), radius: 12, y: 4)
                        
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Color.luxuryMaroon)
                    }
                }
                .padding(.trailing, 24)
                .padding(.bottom, 24)
            }
        }
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 32) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color.luxuryGold.opacity(0.1))
                    .frame(width: 160, height: 160)
                
                Circle()
                    .fill(Color.luxuryGold.opacity(0.05))
                    .frame(width: 200, height: 200)
                
                Image(systemName: "sparkles")
                    .font(.system(size: 60))
                    .foregroundStyle(LinearGradient.goldShimmer)
                    .symbolEffect(.pulse)
            }
            
            VStack(spacing: 16) {
                HStack(spacing: 6) {
                    Text("Your")
                        .font(Font.header(24, weight: .regular))
                        .foregroundColor(Color.luxuryCream)
                    Text("love story")
                        .font(Font.tangerine(36, weight: .bold))
                        .italic()
                        .foregroundColor(Color.luxuryGold)
                    Text("begins here")
                        .font(Font.header(24, weight: .regular))
                        .foregroundColor(Color.luxuryCream)
                }
                .multilineTextAlignment(.center)
                
                Text("Capture memories from your magical dates together")
                    .font(Font.bodySans(15, weight: .regular))
                    .foregroundColor(Color.luxuryCreamMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Button {
                showAddMemory = true
            } label: {
                Text("Add Your First Memory")
                    .font(Font.bodySans(16, weight: .semibold))
            }
            .buttonStyle(LuxuryOutlineButtonStyle())
            
            Spacer()
        }
    }
    
    // MARK: - Timeline View
    private var timelineView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                headerSection
                    .padding(.bottom, 32)
                
                PolaroidTimelineView(
                    memories: memoryManager.memoriesSortedByDate,
                    onSelect: { memory in
                        selectedMemory = memory
                    }
                )
                .padding(.bottom, 100)
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 16)
            
            HStack(spacing: 6) {
                Text("Our")
                    .font(Font.header(30, weight: .regular))
                    .foregroundColor(Color.luxuryCream)
                Text("Memories")
                    .font(Font.tangerine(48, weight: .bold))
                    .italic()
                    .foregroundColor(Color.luxuryGold)
            }
            
            Text("Every date, beautifully remembered")
                .font(Font.bodySans(16, weight: .regular))
                .foregroundColor(Color.luxuryCreamMuted)
            
            HStack(spacing: 8) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 12))
                Text("\(memoryManager.totalMemoriesCount) dates together")
                    .font(Font.bodySans(14, weight: .medium))
            }
            .foregroundColor(Color.luxuryMaroon)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(Color.luxuryGold.opacity(0.9))
            )
            .padding(.top, 8)
        }
    }
}

// MARK: - Polaroid Timeline View

struct PolaroidTimelineView: View {
    let memories: [DateMemory]
    let onSelect: (DateMemory) -> Void
    
    var body: some View {
        ZStack(alignment: .leading) {
            timelineLine
                .padding(.leading, 40)
            
            VStack(spacing: 40) {
                ForEach(Array(memories.enumerated()), id: \.element.id) { index, memory in
                    PolaroidTimelineItem(
                        memory: memory,
                        isLeft: index % 2 == 0,
                        rotation: Double.random(in: -3...3),
                        delay: Double(index) * 0.1
                    )
                    .onTapGesture {
                        onSelect(memory)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    private var timelineLine: some View {
        GeometryReader { geometry in
            Rectangle()
                .fill(LinearGradient.timelineGold)
                .frame(width: 3)
                .shadow(color: Color.luxuryGold.opacity(0.6), radius: 8)
                .shadow(color: Color.luxuryGold.opacity(0.3), radius: 16)
        }
    }
}

// MARK: - Polaroid Timeline Item

struct PolaroidTimelineItem: View {
    let memory: DateMemory
    let isLeft: Bool
    let rotation: Double
    let delay: Double
    
    @State private var isVisible = false
    
    var body: some View {
        HStack(spacing: 16) {
            if !isLeft {
                Spacer()
            }
            
            timelineDot
            
            polaroidCard
            
            if isLeft {
                Spacer()
            }
        }
        .opacity(isVisible ? 1 : 0)
        .offset(x: isVisible ? 0 : (isLeft ? -50 : 50))
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(delay)) {
                isVisible = true
            }
        }
    }
    
    private var timelineDot: some View {
        ZStack {
            Circle()
                .fill(Color.luxuryGold)
                .frame(width: 16, height: 16)
                .shadow(color: Color.luxuryGold.opacity(0.6), radius: 6)
            
            Circle()
                .fill(Color.luxuryMaroon)
                .frame(width: 6, height: 6)
        }
    }
    
    private var polaroidCard: some View {
        VStack(spacing: 0) {
            photoArea
            
            captionArea
        }
        .frame(width: 200)
        .background(Color.polaroidWhite)
        .cornerRadius(4)
        .shadow(color: Color.polaroidShadow.opacity(0.25), radius: 8, x: 2, y: 4)
        .shadow(color: Color.black.opacity(0.12), radius: 20, x: 4, y: 8)
        .rotationEffect(.degrees(rotation))
    }
    
    private var photoArea: some View {
        ZStack {
            Rectangle()
                .fill(Color.polaroidCream)
            
            MemoryPhotoView(memory: memory)
        }
        .frame(width: 180, height: 180)
        .clipped()
        .padding(.top, 10)
        .padding(.horizontal, 10)
    }
    
    private var placeholderPhoto: some View {
        ZStack {
            LinearGradient(
                colors: [Color.luxuryMaroonLight.opacity(0.3), Color.luxuryMaroonMedium.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            Image(systemName: "sparkle")
                .font(.system(size: 40))
                .foregroundStyle(LinearGradient.goldShimmer)
                .opacity(0.6)
        }
    }
    
    private var captionArea: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(memory.caption ?? memory.title)
                .font(Font.tangerine(22, weight: .bold))
                .foregroundColor(Color.polaroidCaption)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 4) {
                Image(systemName: "mappin")
                    .font(.system(size: 10))
                Text(memory.shortFormattedDate)
                if !memory.location.isEmpty {
                    Text("•")
                    Text(memory.location)
                        .lineLimit(1)
                }
            }
            .font(Font.bodySans(10, weight: .regular))
            .foregroundColor(Color.polaroidCaption.opacity(0.6))
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .padding(.bottom, 16)
    }
}

// MARK: - Floating Sparkles View

struct FloatingSparklesView: View {
    @State private var sparkles: [SparkleData] = []
    
    var body: some View {
        GeometryReader { geometry in
            ForEach(sparkles) { sparkle in
                Image(systemName: "sparkle")
                    .font(.system(size: sparkle.size))
                    .foregroundColor(Color.luxuryGold.opacity(sparkle.opacity))
                    .position(x: sparkle.x, y: sparkle.y)
                    .animation(
                        .easeInOut(duration: sparkle.animationDuration)
                        .repeatForever(autoreverses: true),
                        value: sparkle.opacity
                    )
            }
            .onAppear {
                createSparkles(in: geometry.size)
            }
        }
    }
    
    private func createSparkles(in size: CGSize) {
        sparkles = (0..<15).map { _ in
            SparkleData(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: 0...size.height),
                size: CGFloat.random(in: 6...14),
                opacity: Double.random(in: 0.1...0.4),
                animationDuration: Double.random(in: 2...4)
            )
        }
    }
}

struct SparkleData: Identifiable {
    let id = UUID()
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    var opacity: Double
    let animationDuration: Double
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
                Color.luxuryMaroon
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
                    .font(Font.bodySans(16, weight: .medium))
                    .foregroundColor(Color.luxuryGold)
                }
            }
            .toolbarBackground(Color.luxuryMaroon, for: .navigationBar)
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
        VStack(spacing: 8) {
            Text("Add Memory")
                .font(Font.header(28, weight: .bold))
                .foregroundColor(Color.luxuryGold)
            
            Text("Capture this beautiful moment")
                .font(Font.headerItalic(16))
                .foregroundColor(Color.luxuryCreamMuted)
        }
    }
    
    private var photoPickerSection: some View {
        PhotosPicker(selection: $selectedItem, matching: .images) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.luxuryMaroonLight)
                    .frame(height: 200)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient.goldShimmer,
                                style: StrokeStyle(lineWidth: 2, dash: [8, 4])
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
                            .font(.system(size: 40))
                            .foregroundStyle(LinearGradient.goldShimmer)
                        
                        Text("Tap to add photo")
                            .font(Font.bodySans(14, weight: .medium))
                            .foregroundColor(Color.luxuryGold)
                    }
                }
            }
        }
    }
    
    private var formFieldsSection: some View {
        VStack(spacing: 20) {
            formField(title: "Memory Title", placeholder: "e.g., Dinner at La Belle", text: $title)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Date")
                    .font(Font.bodySans(13, weight: .medium))
                    .foregroundColor(Color.luxuryGold)
                
                DatePicker("", selection: $date, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .tint(Color.luxuryGold)
                    .padding(14)
                    .background(Color.luxuryMaroonLight)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.luxuryGold.opacity(0.3), lineWidth: 1)
                    )
            }
            
            formField(title: "Location", placeholder: "e.g., San Francisco, CA", text: $location)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Caption")
                    .font(Font.bodySans(13, weight: .medium))
                    .foregroundColor(Color.luxuryGold)
                
                TextField("Write something memorable...", text: $caption, axis: .vertical)
                    .font(Font.bodySans(15, weight: .regular))
                    .foregroundColor(Color.luxuryCream)
                    .lineLimit(3...6)
                    .padding(14)
                    .background(Color.luxuryMaroonLight)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.luxuryGold.opacity(0.3), lineWidth: 1)
                    )
            }
        }
    }
    
    private func formField(title: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(Font.bodySans(13, weight: .medium))
                .foregroundColor(Color.luxuryGold)
            
            TextField(placeholder, text: text)
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
    }
    
    private var linkToDatePlanSection: some View {
        Group {
            if !coordinator.savedPlans.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(Color.luxuryGold)
                        Text("Link to date plan")
                            .font(Font.bodySans(13, weight: .medium))
                            .foregroundColor(Color.luxuryGold)
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
                                .foregroundColor(Color.luxuryGold)
                        }
                        .padding(14)
                        .background(Color.luxuryMaroonLight)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.luxuryGold.opacity(0.3), lineWidth: 1)
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
            Text("Save Memory")
                .font(Font.header(18, weight: .bold))
                .foregroundColor(Color.luxuryMaroon)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(LinearGradient.goldShimmer)
                .cornerRadius(14)
                .shadow(color: Color.luxuryGold.opacity(0.4), radius: 12, y: 4)
        }
        .disabled(title.isEmpty)
        .opacity(title.isEmpty ? 0.6 : 1)
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
                Color.luxuryMaroon
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
                    .foregroundColor(Color.luxuryGold)
                }
            }
            .toolbarBackground(Color.luxuryMaroon, for: .navigationBar)
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
                    .font(Font.tangerine(32, weight: .bold))
                    .foregroundColor(Color.polaroidCaption)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .background(Color.polaroidWhite)
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
                .foregroundColor(Color.luxuryGold)
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
                colors: [Color.luxuryMaroonLight.opacity(0.3), Color.luxuryMaroonMedium.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Image(systemName: "sparkle")
                .font(.system(size: 40))
                .foregroundStyle(LinearGradient.goldShimmer)
                .opacity(0.6)
        }
    }
}

#Preview {
    MemoryGalleryView()
}
