import SwiftUI
import Photos

// MARK: - Love Note Generator Tab View
struct LoveNoteGeneratorView: View {
    @EnvironmentObject var coordinator: NavigationCoordinator
    @StateObject private var storage = LoveNoteStorageManager.shared
    @State private var noteText = ""
    @State private var selectedPromptIndex = 0
    @State private var selectedSavedNote: SavedLoveNote?
    @State private var showSaveSuccess = false
    @State private var saveSuccessMessage = ""
    @State private var showSaveError = false
    @State private var saveErrorMessage = ""
    @State private var isSaving = false
    /// Name to sign the love note with; defaults to profile display name.
    @State private var signOffName = ""
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
                Color.ydgBase
                    .ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: YDGSpace.lg) {
                        savedLoveNotesSection
                        draftIndicatorSection
                        promptsSection
                        writerSection
                        LoveNoteRewriteSection(text: $noteText, skin: .charcoal)
                        signOffSection
                        previewSection
                        saveButton
                    }
                    .padding(.horizontal, YDGSpace.margin)
                    .padding(.top, YDGSpace.xs)
                }
                .mainTabBarScrollInset()
            }
            // The Convo tab supplies the title; this view has no bar of its own.
            .toolbar(.hidden, for: .navigationBar)
            .onAppear {
                if signOffName.isEmpty {
                    signOffName = UserProfileManager.shared.currentUser?.displayName ?? ""
                }
                loadDraftIfNeeded()
            }
            .onChange(of: noteText) { _, _ in scheduleDraftSave() }
            .onChange(of: signOffName) { _, _ in scheduleDraftSave() }
            .alert("Love Note Saved!", isPresented: $showSaveSuccess) {
                Button("OK") { showSaveSuccess = false }
            } message: {
                Text(saveSuccessMessage)
            }
            .alert("Couldn't Save Love Note", isPresented: $showSaveError) {
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
                    Image(systemName: draftSavedAt != nil ? "checkmark" : "pencil")
                        .font(.system(size: 12, weight: .semibold))
                    Text(draftSavedAt != nil ? "Draft saved" : "Draft")
                        .font(Font.ydgSans(13, weight: .medium))
                    Spacer(minLength: 0)
                    Button("Start over") {
                        storage.clearDraft()
                        noteText = ""
                        signOffName = UserProfileManager.shared.currentUser?.displayName ?? ""
                    }
                    .buttonStyle(.ydgTertiary)
                }
                .foregroundColor(Color.ydgTextSecondary)
            }
        }
    }

    private var hasDraftContent: Bool {
        !noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func loadDraftIfNeeded() {
        guard let draft = storage.loadDraft(), !draft.isEmpty else { return }
        noteText = draft.noteText
        if noteText.isEmpty, !draft.poeticText.isEmpty {
            noteText = draft.poeticText
        }
        if !draft.signOffName.isEmpty { signOffName = draft.signOffName }
    }

    private func scheduleDraftSave() {
        draftSaveWorkItem?.cancel()
        let work = DispatchWorkItem { [storage] in
            let draft = LoveNoteDraft(
                noteText: noteText,
                signOffName: signOffName,
                poeticText: "",
                selectedRewriteStyleRaw: nil,
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
                    sectionLabel(title: "Saved love notes", icon: "heart.text.square")
                    Text("Tap one to view it or save it to Photos again.")
                        .ydgText(.footnote, color: .ydgTextSecondary)
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

    private var promptsSection: some View {
        VStack(alignment: .leading, spacing: YDGSpace.sm) {
            sectionLabel(title: "Need a starting point?", icon: "lightbulb")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: YDGSpace.xs) {
                    ForEach(Array(prompts.enumerated()), id: \.offset) { index, prompt in
                        YDGChip(title: prompt.title, isSelected: selectedPromptIndex == index, showsCheckmark: false) {
                            selectedPromptIndex = index
                        }
                    }
                }
                .padding(.horizontal, 2)
            }
            .scrollClipDisabled()
        }
    }

    private var writerSection: some View {
        ZStack(alignment: .topLeading) {
            if noteText.isEmpty {
                Text(prompts[selectedPromptIndex].placeholder)
                    .ydgText(.body, color: .ydgTextTertiary)
                    .padding(.horizontal, YDGSpace.md)
                    .padding(.vertical, YDGSpace.md + 2)
                    .accessibilityHidden(true)
            }
            TextEditor(text: $noteText)
                .font(.ydg(.body))
                .foregroundColor(Color.ydgTextPrimary)
                .scrollContentBackground(.hidden)
                .padding(YDGSpace.sm)
                .frame(minHeight: 170)
                .accessibilityLabel("Your love note")
        }
        .luxeInsetSurface()
    }

    private var signOffSection: some View {
        VStack(alignment: .leading, spacing: YDGSpace.xs) {
            sectionLabel(title: "Sign as", icon: "signature")
            TextField("", text: $signOffName, prompt: Text("Your name").foregroundColor(Color.ydgTextTertiary))
                .font(.ydg(.body))
                .foregroundColor(Color.ydgTextPrimary)
                .padding(.horizontal, YDGSpace.md)
                .frame(minHeight: 52)
                .autocapitalization(.words)
                .luxeInsetSurface()
        }
    }

    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel(title: "Preview", icon: "eye")
            LoveLetterCardView(
                message: displayMessage,
                signOffName: signOffName.trimmingCharacters(in: .whitespaces).isEmpty ? nil : signOffName.trimmingCharacters(in: .whitespaces),
                placeholder: displayMessage.isEmpty || displayMessage == "Your words will appear here..."
            )
        }
    }

    /// Text to show in preview and to save.
    private var displayMessage: String {
        let trimmed = noteText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "Your words will appear here..." }
        return noteText
    }

    private func sectionLabel(title: String, icon: String) -> some View {
        Text(title)
            .ydgText(.subhead, color: .ydgTextSecondary)
            .accessibilityAddTraits(.isHeader)
    }

    private func goldPrimaryButton(title: String, icon: String, disabled: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
        }
        .buttonStyle(.ydgPrimary)
        .disabled(disabled)
    }

    private func goldOutlineButton(title: String, icon: String, disabled: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
        }
        .buttonStyle(.ydgSecondary)
        .disabled(disabled)
    }

    private var hasContentToSave: Bool {
        let msg = displayMessage
        return !msg.isEmpty && msg != "Your words will appear here..."
    }

    private var saveButton: some View {
        VStack(alignment: .leading, spacing: YDGSpace.sm) {
            VStack(spacing: YDGSpace.sm) {
                goldPrimaryButton(
                    title: "Save love note",
                    icon: "heart.text.square.fill",
                    disabled: !hasContentToSave,
                    action: saveLoveNoteInApp
                )

                if isSaving {
                    Button("Saving…") {}
                        .buttonStyle(YDGButtonStyle(kind: .secondary, isLoading: true))
                        .disabled(true)
                } else {
                    goldOutlineButton(
                        title: "Save as photo",
                        icon: "photo.fill",
                        disabled: !hasContentToSave,
                        action: saveLoveNoteAsImage
                    )
                }

                goldOutlineButton(
                    title: "Send to partner",
                    icon: "paperplane.fill",
                    disabled: !hasContentToSave,
                    action: sendToPartner
                )
            }
        }
        .padding(.bottom, 24)
    }

    private func saveLoveNoteInApp() {
        let signOff = signOffName.trimmingCharacters(in: .whitespaces).isEmpty ? nil : signOffName.trimmingCharacters(in: .whitespaces)
        storage.add(message: displayMessage, signOffName: signOff)
        storage.clearDraft()
        saveSuccessMessage = "Saved to your Love Notes."
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
                        saveSuccessMessage = "Your Love Note was saved to Photos. Share it with someone special!"
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
        let shareText = "A Love Note for you 💕"
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
            LoveNoteCreamCard(bannerSubtitle: "Saved") {
                VStack(alignment: .leading, spacing: 8) {
                    Text(preview)
                        .font(Font.bodySerif(14, weight: .regular))
                        .foregroundColor(Color.textOnCard)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                    Spacer(minLength: 0)
                    Text(dateText)
                        .font(Font.bodySans(11, weight: .medium))
                        .foregroundColor(Color.textMutedOnCard)
                }
                .frame(width: 160, height: 88)
                .padding(12)
            }
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
                Color.backgroundPrimary
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
                                            .progressViewStyle(CircularProgressViewStyle(tint: Color.backgroundPrimary))
                                    } else {
                                        Image(systemName: "square.and.arrow.down.fill")
                                        Text("Save to Photos Again")
                                            .lineLimit(2)
                                            .multilineTextAlignment(.center)
                                    }
                                }
                                .font(Font.bodySans(15, weight: .semibold))
                                .foregroundColor(Color.backgroundPrimary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.accentGold)
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
                                    Text("Remove from Love Notes")
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
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.backgroundPrimary, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Saved Love Note")
                        .font(Font.bodySerif(18, weight: .regular))
                        .foregroundColor(Color.accentGold)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onDismiss()
                    }
                    .foregroundColor(Color.accentGold)
                }
            }
            .alert("Love Note Saved!", isPresented: $showSaveSuccess) {
                Button("OK") { showSaveSuccess = false }
            } message: {
                Text("Saved to your Photos.")
            }
            .alert("Couldn't Save Love Note", isPresented: $showSaveError) {
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
        VStack(alignment: .leading, spacing: 0) {
            LoveNoteGradientBanner(subtitle: signOffLine)

            VStack(alignment: .leading, spacing: 16) {
                Text(message)
                    .font(Font.bodySerif(15, weight: .regular))
                    .foregroundColor(placeholder ? Color.textMutedOnCard.opacity(0.55) : Color.textOnCard)
                    .lineSpacing(6)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .fixedSize(horizontal: false, vertical: true)

                if !placeholder {
                    Text(signOffLine)
                        .font(Font.bodySerif(14, weight: .semibold))
                        .foregroundColor(Color.textMutedOnCard)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }

                Spacer(minLength: 0)
            }
            .padding(20)
        }
        .background(Color.creamCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.maroonBorderTint, lineWidth: 1)
        )
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 1.5)
                .fill(Color.accentMaroon)
                .frame(width: 3)
                .padding(.vertical, 1)
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(340/440, contentMode: .fit)
    }
}

#Preview {
    LoveNoteGeneratorView()
}
