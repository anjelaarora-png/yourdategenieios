import SwiftUI
import Photos

// MARK: - Love Note Generator Tab View
struct LoveNoteGeneratorView: View {
    @EnvironmentObject var coordinator: NavigationCoordinator
    @StateObject private var storage = LoveNoteStorageManager.shared
    @State private var noteText = ""
    @State private var poeticText = "" // AI-rewritten loving & poetic version
    @State private var selectedPromptIndex = 0
    @State private var selectedSavedNote: SavedLoveNote?
    @State private var showSaveSuccess = false
    @State private var saveSuccessMessage = ""
    @State private var showSaveError = false
    @State private var saveErrorMessage = ""
    @State private var isSaving = false
    @State private var isGeneratingPoetic = false
    @State private var poeticErrorMessage: String?
    @State private var showPoeticError = false
    /// Name to sign the love note with; defaults to profile display name.
    @State private var signOffName: String = ""
    /// Selected rewrite style for the Rewrite button.
    @State private var selectedRewriteStyle: LoveNoteRewriteStyle = .romantic
    /// When non-nil, we show "Draft saved" above the editor; cleared after a few seconds.
    @State private var draftSavedAt: Date?
    @State private var draftSaveWorkItem: DispatchWorkItem?

    private let prompts: [(title: String, placeholder: String)] = [
        ("What do you love most about them?", "Tell them what makes your heart skip..."),
        ("A moment you'll never forget", "Describe a memory that still makes you smile..."),
        ("Why they make you smile", "Share the little things that brighten your day..."),
        ("What you're grateful for", "Thank them for something specific..."),
        ("A promise or hope for the future", "Write something you look forward to together...")
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.luxuryMaroon
                    .ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 24) {
                        headerSection
                        savedLoveNotesSection
                        draftIndicatorSection
                        promptsSection
                        writerSection
                        rewriteStyleSection
                        makeItPoeticButton
                        signOffSection
                        previewSection
                        saveButton
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 120)
                }
            }
            .toolbarBackground(Color.luxuryMaroon, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        storage.clearDraft()
                        noteText = ""
                        poeticText = ""
                        signOffName = UserProfileManager.shared.currentUser?.displayName ?? ""
                        coordinator.currentTab = .home
                    }
                    .foregroundColor(Color.luxuryGold)
                }
            }
            .onAppear {
                if signOffName.isEmpty {
                    signOffName = UserProfileManager.shared.currentUser?.displayName ?? ""
                }
                loadDraftIfNeeded()
            }
            .onChange(of: noteText) { _, _ in scheduleDraftSave() }
            .onChange(of: signOffName) { _, _ in scheduleDraftSave() }
            .onChange(of: poeticText) { _, _ in scheduleDraftSave() }
            .onChange(of: selectedRewriteStyle) { _, _ in scheduleDraftSave() }
            .alert("Saved!", isPresented: $showSaveSuccess) {
                Button("OK") { showSaveSuccess = false }
            } message: {
                Text(saveSuccessMessage)
            }
            .alert("Couldn't Save", isPresented: $showSaveError) {
                Button("OK") { showSaveError = false }
            } message: {
                Text(saveErrorMessage)
            }
            .sheet(item: $selectedSavedNote) { note in
                SavedLoveNoteDetailSheet(note: note) {
                    selectedSavedNote = nil
                }
            }
        }
    }

    /// "Draft" / "Draft saved" label above the writer when there is draft content.
    private var draftIndicatorSection: some View {
        Group {
            if hasDraftContent {
                HStack(spacing: 6) {
                    Image(systemName: "heart.text.square.fill")
                        .font(.system(size: 12))
                        .foregroundColor(Color.luxuryGold.opacity(0.9))
                    Text(draftSavedAt != nil ? "Draft saved" : "Draft")
                        .font(Font.bodySans(13, weight: .medium))
                        .foregroundColor(Color.luxuryCreamMuted)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.luxuryMaroonLight.opacity(0.6))
                .cornerRadius(10)
            }
        }
    }

    private var hasDraftContent: Bool {
        !noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !poeticText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func loadDraftIfNeeded() {
        guard let draft = storage.loadDraft(), !draft.isEmpty else { return }
        noteText = draft.noteText
        if !draft.signOffName.isEmpty { signOffName = draft.signOffName }
        poeticText = draft.poeticText
        if let raw = draft.selectedRewriteStyleRaw, let style = LoveNoteRewriteStyle(rawValue: raw) {
            selectedRewriteStyle = style
        }
    }

    private func scheduleDraftSave() {
        draftSaveWorkItem?.cancel()
        let work = DispatchWorkItem { [storage] in
            let draft = LoveNoteDraft(
                noteText: noteText,
                signOffName: signOffName,
                poeticText: poeticText,
                selectedRewriteStyleRaw: selectedRewriteStyle.rawValue,
                updatedAt: Date()
            )
            storage.saveDraft(draft)
            DispatchQueue.main.async {
                draftSavedAt = Date()
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    draftSavedAt = nil
                }
            }
        }
        draftSaveWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: work)
    }

    private var savedLoveNotesSection: some View {
        Group {
            if !storage.savedNotes.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 6) {
                        Image(systemName: "heart.text.square.fill")
                            .font(.system(size: 22))
                            .foregroundColor(Color.luxuryGold)
                        Text("Saved")
                            .font(Font.tangerine(28, weight: .bold))
                            .italic()
                            .foregroundColor(Color.luxuryGold)
                        Text("Love Notes")
                            .font(Font.tangerine(28, weight: .bold))
                            .italic()
                            .foregroundColor(Color.luxuryGold)
                    }
                    Text("Tap to view or save to photos again.")
                        .font(Font.bodySans(13, weight: .regular))
                        .foregroundColor(Color.luxuryCreamMuted)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(storage.savedNotes) { note in
                                SavedLoveNoteCard(note: note) {
                                    selectedSavedNote = note
                                }
                            }
                        }
                        .padding(.horizontal, 2)
                    }
                }
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 10) {
            Text("Write a Love Note")
                .font(Font.tangerine(44, weight: .bold))
                .italic()
                .foregroundColor(Color.luxuryGold)
                .multilineTextAlignment(.center)

            Text("Write your feelings, pick a style to rewrite, then save as a love letter to send.")
                .font(Font.bodySans(15, weight: .regular))
                .foregroundColor(Color.luxuryCreamMuted)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
    }

    private var promptsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Text("Need")
                    .font(Font.tangerine(28, weight: .bold))
                    .italic()
                    .foregroundColor(Color.luxuryGold)
                Text("inspiration?")
                    .font(Font.tangerine(28, weight: .bold))
                    .italic()
                    .foregroundColor(Color.luxuryGold)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(Array(prompts.enumerated()), id: \.offset) { index, prompt in
                        Button {
                            selectedPromptIndex = index
                        } label: {
                            Text(prompt.title)
                                .font(Font.bodySans(13, weight: .medium))
                                .foregroundColor(selectedPromptIndex == index ? Color.luxuryMaroon : Color.luxuryCream)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(
                                    selectedPromptIndex == index
                                        ? LinearGradient.goldShimmer
                                        : LinearGradient(colors: [Color.luxuryGold.opacity(0.2)], startPoint: .leading, endPoint: .trailing)
                                )
                                .cornerRadius(20)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 2)
            }
        }
    }

    private var writerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Text("Your")
                    .font(Font.tangerine(28, weight: .bold))
                    .italic()
                    .foregroundColor(Color.luxuryGold)
                Text("words")
                    .font(Font.tangerine(28, weight: .bold))
                    .italic()
                    .foregroundColor(Color.luxuryGold)
            }
            ZStack(alignment: .topLeading) {
                if noteText.isEmpty {
                    Text(prompts[selectedPromptIndex].placeholder)
                        .font(Font.bodySans(16, weight: .regular))
                        .foregroundColor(Color.luxuryCreamMuted)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                }
                TextEditor(text: $noteText)
                    .font(Font.bodySans(16, weight: .regular))
                    .foregroundColor(Color.luxuryCream)
                    .scrollContentBackground(.hidden)
                    .padding(12)
                    .frame(minHeight: 140)
            }
            .background(Color.luxuryMaroonLight.opacity(0.8))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.luxuryGold.opacity(0.4), lineWidth: 1)
            )
        }
    }

    private var signOffSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Text("Sign")
                    .font(Font.tangerine(28, weight: .bold))
                    .italic()
                    .foregroundColor(Color.luxuryGold)
                Text("as")
                    .font(Font.tangerine(28, weight: .bold))
                    .italic()
                    .foregroundColor(Color.luxuryGold)
            }
            TextField("Your name", text: $signOffName)
                .font(Font.bodySans(16, weight: .regular))
                .foregroundColor(Color.luxuryCream)
                .padding(14)
                .background(Color.luxuryMaroonLight.opacity(0.8))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.luxuryGold.opacity(0.3), lineWidth: 1)
                )
                .autocapitalization(.words)
        }
    }

    private var rewriteStyleSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Text("Rewrite")
                    .font(Font.tangerine(28, weight: .bold))
                    .italic()
                    .foregroundColor(Color.luxuryGold)
                Text("style")
                    .font(Font.tangerine(28, weight: .bold))
                    .italic()
                    .foregroundColor(Color.luxuryGold)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(LoveNoteRewriteStyle.allCases) { style in
                        Button {
                            selectedRewriteStyle = style
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: style.icon)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(selectedRewriteStyle == style ? Color.luxuryMaroon : Color.luxuryGold)
                                Text(style.displayName)
                                    .font(Font.bodySans(13, weight: .medium))
                                    .foregroundColor(selectedRewriteStyle == style ? Color.luxuryMaroon : Color.luxuryCream)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(
                                selectedRewriteStyle == style
                                    ? LinearGradient.goldShimmer
                                    : LinearGradient(colors: [Color.luxuryGold.opacity(0.2)], startPoint: .leading, endPoint: .trailing)
                            )
                            .cornerRadius(20)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 2)
            }
        }
    }

    private var makeItPoeticButton: some View {
        Button {
            generatePoeticVersion()
        } label: {
            HStack(spacing: 10) {
                if isGeneratingPoetic {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color.luxuryMaroon))
                    Text("Rewriting...")
                        .font(Font.bodySans(15, weight: .medium))
                } else {
                    Image(systemName: "heart.text.square.fill")
                        .font(.system(size: 18))
                    Text(poeticText.isEmpty ? "Rewrite" : "Rewrite again")
                        .font(Font.bodySans(15, weight: .medium))
                }
            }
            .foregroundColor(Color.luxuryMaroon)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(LinearGradient.goldShimmer)
            .cornerRadius(14)
            .shadow(color: Color.luxuryGold.opacity(0.3), radius: 6, y: 2)
        }
        .buttonStyle(.plain)
        .disabled(noteText.trimmingCharacters(in: .whitespaces).isEmpty || isGeneratingPoetic)
        .opacity(noteText.trimmingCharacters(in: .whitespaces).isEmpty ? 0.6 : 1)
        .alert("Couldn't rewrite", isPresented: $showPoeticError) {
            Button("OK") {
                showPoeticError = false
                poeticErrorMessage = nil
            }
        } message: {
            if let msg = poeticErrorMessage { Text(msg) }
        }
    }

    private func generatePoeticVersion() {
        let raw = noteText.trimmingCharacters(in: .whitespaces)
        guard !raw.isEmpty else { return }
        isGeneratingPoetic = true
        poeticErrorMessage = nil
        let style = selectedRewriteStyle
        Task {
            do {
                let rewritten = try await LoveNoteAIService.rewrite(userText: raw, style: style)
                await MainActor.run {
                    poeticText = rewritten
                    isGeneratingPoetic = false
                }
            } catch {
                await MainActor.run {
                    poeticErrorMessage = error.localizedDescription
                    showPoeticError = true
                    isGeneratingPoetic = false
                }
            }
        }
    }

    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Text("Love letter")
                    .font(Font.tangerine(28, weight: .bold))
                    .italic()
                    .foregroundColor(Color.luxuryGold)
                Text("preview")
                    .font(Font.tangerine(28, weight: .bold))
                    .italic()
                    .foregroundColor(Color.luxuryGold)
            }
            LoveLetterCardView(
                message: displayMessage,
                signOffName: signOffName.trimmingCharacters(in: .whitespaces).isEmpty ? nil : signOffName.trimmingCharacters(in: .whitespaces),
                placeholder: displayMessage.isEmpty || displayMessage == "Your words will appear here..."
            )
            .padding(4)
        }
    }

    /// Text to show in preview and to save: use rewritten version if available, otherwise raw note.
    private var displayMessage: String {
        if !poeticText.isEmpty { return poeticText }
        if noteText.isEmpty { return "Your words will appear here..." }
        return noteText
    }

    private var hasContentToSave: Bool {
        let msg = displayMessage
        return !msg.isEmpty && msg != "Your words will appear here..."
    }

    private var saveButton: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Text("Save")
                    .font(Font.tangerine(28, weight: .bold))
                    .italic()
                    .foregroundColor(Color.luxuryGold)
                Text("or send")
                    .font(Font.tangerine(28, weight: .bold))
                    .italic()
                    .foregroundColor(Color.luxuryGold)
            }
            VStack(spacing: 10) {
                Button {
                    saveLoveNoteInApp()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "heart.text.square.fill")
                            .font(.system(size: 18))
                        Text("Save love note")
                            .font(Font.bodySans(15, weight: .semibold))
                        Spacer()
                    }
                    .foregroundColor(Color.luxuryMaroon)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(LinearGradient.goldShimmer)
                    .cornerRadius(14)
                }
                .buttonStyle(.plain)
                .disabled(!hasContentToSave)

                Button {
                    saveLoveNoteAsImage()
                } label: {
                    HStack(spacing: 10) {
                        if isSaving {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: Color.luxuryMaroon))
                            Text("Saving...")
                                .font(Font.bodySans(15, weight: .semibold))
                        } else {
                            Image(systemName: "photo.fill")
                                .font(.system(size: 18))
                            Text("Save as photo")
                                .font(Font.bodySans(15, weight: .semibold))
                        }
                        Spacer()
                    }
                    .foregroundColor(Color.luxuryMaroon)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(LinearGradient.goldShimmer)
                    .cornerRadius(14)
                }
                .buttonStyle(.plain)
                .disabled(!hasContentToSave || isSaving)

                Button {
                    sendToPartner()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 18))
                        Text("Send to partner")
                            .font(Font.bodySans(15, weight: .semibold))
                        Spacer()
                    }
                    .foregroundColor(Color.luxuryMaroon)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(LinearGradient.goldShimmer)
                    .cornerRadius(14)
                }
                .buttonStyle(.plain)
                .disabled(!hasContentToSave)
            }
        }
    }

    private func saveLoveNoteInApp() {
        let signOff = signOffName.trimmingCharacters(in: .whitespaces).isEmpty ? nil : signOffName.trimmingCharacters(in: .whitespaces)
        storage.add(message: displayMessage, signOffName: signOff)
        storage.clearDraft()
        saveSuccessMessage = "Saved to your love notes."
        showSaveSuccess = true
    }

    private func saveLoveNoteAsImage() {
        let signOff = signOffName.trimmingCharacters(in: .whitespaces).isEmpty ? nil : signOffName.trimmingCharacters(in: .whitespaces)
        guard let image = loveNoteImage(signOffName: signOff) else {
            saveErrorMessage = "Could not create image."
            showSaveError = true
            return
        }
        isSaving = true
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            guard status == .authorized || status == .limited else {
                DispatchQueue.main.async {
                    isSaving = false
                    saveErrorMessage = "Photo library access is needed to save your love note. Enable it in Settings."
                    showSaveError = true
                }
                return
            }
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            } completionHandler: { success, error in
                DispatchQueue.main.async {
                    isSaving = false
                    if success {
                        storage.add(message: displayMessage, signOffName: signOff)
                        storage.clearDraft()
                        saveSuccessMessage = "Your love note was saved to your photos. Share it with someone special!"
                        showSaveSuccess = true
                    } else {
                        saveErrorMessage = error?.localizedDescription ?? "Could not save to photos."
                        showSaveError = true
                    }
                }
            }
        }
    }

    private func sendToPartner() {
        let signOff = signOffName.trimmingCharacters(in: .whitespaces).isEmpty ? nil : signOffName.trimmingCharacters(in: .whitespaces)
        guard let image = loveNoteImage(signOffName: signOff) else {
            saveErrorMessage = "Could not create image."
            showSaveError = true
            return
        }
        storage.add(message: displayMessage, signOffName: signOff)
        let shareText = "A love note for you 💕"
        let activityController = UIActivityViewController(activityItems: [image, shareText], applicationActivities: nil)
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }) ?? windowScene.windows.first,
              let topVC = topViewControllerForShare(from: window.rootViewController) else { return }
        if let popover = activityController.popoverPresentationController {
            popover.sourceView = topVC.view
            popover.sourceRect = CGRect(x: topVC.view.bounds.midX, y: topVC.view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        topVC.present(activityController, animated: true)
    }

    private func loveNoteImage(signOffName: String?) -> UIImage? {
        let card = LoveLetterCardView(
            message: displayMessage,
            signOffName: signOffName,
            placeholder: false
        )
        .frame(width: 340, height: 440)
        .padding(24)
        return ImageRenderer(content: card).uiImage
    }

    private func topViewControllerForShare(from base: UIViewController?) -> UIViewController? {
        guard let base = base else { return nil }
        if let presented = base.presentedViewController {
            return topViewControllerForShare(from: presented)
        }
        if let nav = base as? UINavigationController, let visible = nav.visibleViewController {
            return topViewControllerForShare(from: visible)
        }
        if let tab = base as? UITabBarController, let selected = tab.selectedViewController {
            return topViewControllerForShare(from: selected)
        }
        return base
    }
}

// MARK: - Saved Love Note Card (thumbnail in list)
struct SavedLoveNoteCard: View {
    let note: SavedLoveNote
    let onTap: () -> Void

    private var preview: String {
        let trimmed = note.message.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count <= 60 { return trimmed }
        return String(trimmed.prefix(57)) + "..."
    }

    private var dateText: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: note.createdAt)
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                Text(preview)
                    .font(Font.bodySerif(14, weight: .regular))
                    .foregroundColor(Color(hex: "3D2C2C"))
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
                Text(dateText)
                    .font(Font.bodySans(11, weight: .medium))
                    .foregroundColor(Color.luxuryGold)
            }
            .frame(width: 160, height: 100)
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: "FDF8F0"),
                                Color(hex: "F5EDE0")
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.luxuryGold.opacity(0.4), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Saved Love Note Detail Sheet (view full note, save to photos, delete)
struct SavedLoveNoteDetailSheet: View {
    let note: SavedLoveNote
    let onDismiss: () -> Void
    @StateObject private var storage = LoveNoteStorageManager.shared
    @State private var isSavingToPhotos = false
    @State private var showSaveSuccess = false
    @State private var showSaveError = false
    @State private var saveErrorMessage = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color.luxuryMaroon
                    .ignoresSafeArea()
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 24) {
                        LoveLetterCardView(message: note.message, signOffName: note.signOffName, placeholder: false)
                            .padding(.horizontal, 20)
                        VStack(spacing: 12) {
                            Button {
                                saveToPhotos()
                            } label: {
                                HStack(spacing: 10) {
                                    if isSavingToPhotos {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: Color.luxuryMaroon))
                                    } else {
                                        Image(systemName: "square.and.arrow.down.fill")
                                        Text("Save to Photos Again")
                                            .lineLimit(2)
                                            .multilineTextAlignment(.center)
                                    }
                                }
                                .font(Font.bodySans(16, weight: .semibold))
                                .foregroundColor(Color.luxuryMaroon)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(LinearGradient.goldShimmer)
                                .cornerRadius(14)
                            }
                            .buttonStyle(.plain)
                            .disabled(isSavingToPhotos)
                            Button(role: .destructive) {
                                storage.remove(id: note.id)
                                onDismiss()
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "trash")
                                    Text("Remove from saved")
                                        .lineLimit(2)
                                        .multilineTextAlignment(.center)
                                }
                                .font(Font.bodySans(15, weight: .medium))
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.vertical, 24)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Saved love note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.luxuryMaroon, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onDismiss()
                    }
                    .foregroundColor(Color.luxuryGold)
                }
            }
            .alert("Saved!", isPresented: $showSaveSuccess) {
                Button("OK") { showSaveSuccess = false }
            } message: {
                Text("Saved to your photos.")
            }
            .alert("Couldn't save", isPresented: $showSaveError) {
                Button("OK") { showSaveError = false }
            } message: {
                Text(saveErrorMessage)
            }
        }
    }

    private func saveToPhotos() {
        let card = LoveLetterCardView(message: note.message, signOffName: note.signOffName, placeholder: false)
            .frame(width: 340, height: 440)
            .padding(24)
        guard let image = ImageRenderer(content: card).uiImage else {
            saveErrorMessage = "Could not create image."
            showSaveError = true
            return
        }
        isSavingToPhotos = true
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            guard status == .authorized || status == .limited else {
                DispatchQueue.main.async {
                    isSavingToPhotos = false
                    saveErrorMessage = "Photo library access is needed. Enable it in Settings."
                    showSaveError = true
                }
                return
            }
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            } completionHandler: { success, error in
                DispatchQueue.main.async {
                    isSavingToPhotos = false
                    if success {
                        showSaveSuccess = true
                    } else {
                        saveErrorMessage = error?.localizedDescription ?? "Could not save to photos."
                        showSaveError = true
                    }
                }
            }
        }
    }
}

// MARK: - Love Letter Card (styled for preview and export)
struct LoveLetterCardView: View {
    let message: String
    var signOffName: String? = nil
    var placeholder: Bool = false

    private var signOffLine: String {
        guard let name = signOffName, !name.isEmpty else { return "With love" }
        return "With love, \(name)"
    }

    var body: some View {
        ZStack {
            // Paper / parchment style background
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "FDF8F0"),
                            Color(hex: "F5EDE0"),
                            Color(hex: "F0E6D8")
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.luxuryGold.opacity(0.6),
                                    Color.luxuryGold.opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
                .shadow(color: Color.black.opacity(0.15), radius: 20, y: 8)

            VStack(alignment: .leading, spacing: 20) {
                // Decorative header
                HStack {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(LinearGradient(
                            colors: [Color.luxuryGold, Color.luxuryGoldDark],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                    Spacer()
                    Text(signOffLine)
                        .font(Font.tangerine(28, weight: .bold))
                        .italic()
                        .foregroundColor(Color.luxuryMaroon.opacity(0.9))
                }
                .padding(.horizontal, 4)

                Divider()
                    .background(Color.luxuryGold.opacity(0.4))
                    .padding(.vertical, 4)

                Text(message)
                    .font(Font.bodySans(16, weight: .regular))
                    .foregroundColor(placeholder ? Color.gray.opacity(0.6) : Color(hex: "3D2C2C"))
                    .lineSpacing(8)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)
            }
            .padding(28)
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(340/440, contentMode: .fit)
    }
}

#Preview {
    LoveNoteGeneratorView()
}
