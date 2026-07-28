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
                Color.backgroundPrimary
                    .ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 24) {
                        headerSection
                        savedLoveNotesSection
                        draftIndicatorSection
                        promptsSection
                        writerSection
                        LoveNoteRewriteSection(text: $noteText, skin: .charcoal)
                        signOffSection
                        previewSection
                        saveButton
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
                .mainTabBarScrollInset()
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Love Notes")
                        .font(Font.bodySerif(18, weight: .regular))
                        .foregroundColor(Color.accentGold)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        storage.clearDraft()
                        noteText = ""
                        signOffName = UserProfileManager.shared.currentUser?.displayName ?? ""
                        coordinator.currentTab = .home
                    }
                    .foregroundColor(Color.accentGold)
                }
            }
            .toolbarBackground(Color.backgroundPrimary, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
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
                    Image(systemName: "heart.text.square.fill")
                        .font(.system(size: 12))
                        .foregroundColor(Color.luxuryGold.opacity(0.9))
                    Text(draftSavedAt != nil ? "Love Note draft saved" : "Love Note draft")
                        .font(Font.bodySans(13, weight: .medium))
                        .foregroundColor(Color.luxuryCreamMuted)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.luxeSurfaceTintStrong)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.luxeSurfaceBorder, lineWidth: 1)
                )
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
                    Text("Tap to view or save to photos again.")
                        .font(Font.bodySans(12, weight: .regular))
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
                .font(Font.bodySerif(28, weight: .regular))
                .foregroundColor(Color.accentGold)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

            Text("Pour your heart out, rewrite with AI, then save or send.")
                .font(Font.bodySans(13, weight: .regular))
                .foregroundColor(Color.luxuryCreamMuted)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
    }

    private var promptsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel(title: "Need inspiration?", icon: "lightbulb")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(Array(prompts.enumerated()), id: \.offset) { index, prompt in
                        Button {
                            selectedPromptIndex = index
                        } label: {
                            Text(prompt.title)
                                .font(Font.bodySans(12, weight: .semibold))
                                .foregroundColor(selectedPromptIndex == index ? Color.backgroundPrimary : Color.textPrimary.opacity(0.82))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(
                                    selectedPromptIndex == index
                                        ? Color.accentGold
                                        : Color.luxeSurfaceTintStrong
                                )
                                .cornerRadius(20)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(selectedPromptIndex == index ? Color.clear : Color.maroonBorderTint, lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 2)
            }
        }
    }

    private var writerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel(title: "Your words", icon: "pencil.line")
            LoveNoteCreamCard(bannerSubtitle: "Your words") {
                ZStack(alignment: .topLeading) {
                    if noteText.isEmpty {
                        Text(prompts[selectedPromptIndex].placeholder)
                            .font(Font.bodySerif(15, weight: .regular))
                            .foregroundColor(Color.textMutedOnCard.opacity(0.55))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                    }
                    TextEditor(text: $noteText)
                        .font(Font.bodySerif(15, weight: .regular))
                        .foregroundColor(Color.textOnCard)
                        .scrollContentBackground(.hidden)
                        .padding(12)
                        .frame(minHeight: 140)
                }
            }
        }
    }

    private var signOffSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel(title: "Sign as", icon: "signature")
            LoveNoteCreamCard(bannerSubtitle: "Sign as") {
                TextField("Your name", text: $signOffName)
                    .font(Font.bodySerif(15, weight: .regular))
                    .foregroundColor(Color.textOnCard)
                    .padding(14)
                    .autocapitalization(.words)
            }
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
        ExtrasSectionHeader(icon: icon, title: title)
    }

    private func goldPrimaryButton(title: String, icon: String, disabled: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                Text(title)
                    .font(Font.bodySans(15, weight: .semibold))
                Spacer(minLength: 0)
            }
            .foregroundColor(Color.backgroundPrimary)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.accentGold)
            .cornerRadius(14)
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .opacity(disabled ? 0.5 : 1)
    }

    private func goldOutlineButton(title: String, icon: String, disabled: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .medium))
                Text(title)
                    .font(Font.bodySans(15, weight: .semibold))
                Spacer(minLength: 0)
            }
            .foregroundColor(Color.accentGold)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.accentGold.opacity(0.55), lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .opacity(disabled ? 0.5 : 1)
    }

    private var hasContentToSave: Bool {
        let msg = displayMessage
        return !msg.isEmpty && msg != "Your words will appear here..."
    }

    private var saveButton: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel(title: "Save or send", icon: "square.and.arrow.up")
            VStack(spacing: 10) {
                goldPrimaryButton(
                    title: "Save Love Note",
                    icon: "heart.text.square.fill",
                    disabled: !hasContentToSave,
                    action: saveLoveNoteInApp
                )

                if isSaving {
                    HStack(spacing: 10) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Color.accentGold))
                        Text("Saving…")
                            .font(Font.bodySans(15, weight: .semibold))
                        Spacer(minLength: 0)
                    }
                    .foregroundColor(Color.accentGold)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.accentGold.opacity(0.55), lineWidth: 1.5)
                    )
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
