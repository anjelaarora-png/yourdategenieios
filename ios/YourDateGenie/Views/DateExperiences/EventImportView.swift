import SwiftUI

// MARK: - Preview payload returned by the Edge Function (dry_run = true)

fileprivate struct EventPreview: Decodable, Equatable {
    let title: String
    let description: String
    let date_time: String
    let location: String
    let image_url: String
    let eventbrite_url: String
}

// MARK: - EventImportViewModel

@MainActor
final class EventImportViewModel: ObservableObject {
    @Published var urlText: String = ""
    @Published fileprivate var preview: EventPreview? = nil
    @Published var isPreviewing = false
    @Published var isSaving = false
    @Published var saveSuccess = false
    @Published var errorMessage: String? = nil

    private let edgeFunctionURL: URL = {
        let base = AppConfig.supabaseURL.hasSuffix("/")
            ? AppConfig.supabaseURL
            : AppConfig.supabaseURL + "/"
        return URL(string: "\(base)functions/v1/import-eventbrite-event")!
    }()

    // MARK: Step 1 — Dry-run preview

    func fetchPreview() async {
        let cleaned = urlText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else {
            errorMessage = "Please paste an Eventbrite link first."
            return
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        isPreviewing = true
        errorMessage = nil
        preview = nil
        do {
            preview = try await callFunction(url: cleaned, dryRun: true)
        } catch {
            errorMessage = error.localizedDescription
        }
        isPreviewing = false
    }

    // MARK: Step 2 — Confirm and save

    func saveEvent() async {
        let cleaned = urlText.trimmingCharacters(in: .whitespacesAndNewlines)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        isSaving = true
        errorMessage = nil
        do {
            _ = try await callFunction(url: cleaned, dryRun: false)
            saveSuccess = true
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }

    func reset() {
        urlText = ""
        preview = nil
        saveSuccess = false
        errorMessage = nil
    }

    // MARK: Shared network call

    private func callFunction(url: String, dryRun: Bool) async throws -> EventPreview {
        var req = URLRequest(url: edgeFunctionURL)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(AppConfig.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        req.timeoutInterval = 30
        req.httpBody = try JSONSerialization.data(withJSONObject: ["url": url, "dry_run": dryRun])

        let (data, response) = try await URLSession.shared.data(for: req)

        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            let msg = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])?["error"] as? String
                ?? "Server returned \(http.statusCode). Ensure the event is public."
            throw URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: msg])
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let eventDict = (json["preview"] ?? json["event"]) as? [String: Any] else {
            throw URLError(.cannotParseResponse, userInfo: [NSLocalizedDescriptionKey: "Unexpected response from server."])
        }

        let eventData = try JSONSerialization.data(withJSONObject: eventDict)
        return try JSONDecoder().decode(EventPreview.self, from: eventData)
    }
}

// MARK: - EventImportView

struct EventImportView: View {
    @StateObject private var viewModel = EventImportViewModel()
    @Environment(\.dismiss) private var dismiss
    var onEventSaved: (() -> Void)?

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color(hex: "3A0606"), Color(hex: "5B0A0A")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 28) {
                        headerText
                        urlInputSection
                        if let p = viewModel.preview {
                            previewSection(p)
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }
                        if let err = viewModel.errorMessage {
                            errorBanner(err)
                        }
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .animation(.easeOut(duration: 0.3), value: viewModel.preview)
                    .animation(.easeOut(duration: 0.2), value: viewModel.errorMessage)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Color(hex: "E8C27D"))
                }
            }
            .toolbarBackground(Color(hex: "3A0606"), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .alert("Event Added ✨", isPresented: $viewModel.saveSuccess) {
                Button("Done") {
                    onEventSaved?()
                    dismiss()
                }
            } message: {
                Text("The event is now live in Date Experiences.")
            }
        }
    }

    // MARK: Header

    private var headerText: some View {
        VStack(spacing: 8) {
            Text("Import an Event")
                .font(Font.header(26, weight: .bold))
                .foregroundColor(.white)

            Text("Paste any public Eventbrite link — title, date, location, and cover photo are filled in automatically.")
                .font(Font.bodySans(14, weight: .regular))
                .foregroundColor(Color(hex: "EADBC8"))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
    }

    // MARK: URL Input

    private var urlInputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Eventbrite URL")
                .font(Font.bodySans(13, weight: .semibold))
                .foregroundColor(Color(hex: "E8C27D"))

            HStack(spacing: 10) {
                TextField("https://www.eventbrite.com/e/...", text: $viewModel.urlText)
                    .font(Font.bodySans(14, weight: .regular))
                    .foregroundColor(.white)
                    .tint(Color(hex: "E8C27D"))
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)
                    .submitLabel(.go)
                    .onSubmit { Task { await viewModel.fetchPreview() } }

                if !viewModel.urlText.isEmpty {
                    Button {
                        viewModel.reset()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Color(hex: "E8C27D").opacity(0.6))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .background(Color.black.opacity(0.35))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(hex: "E8C27D").opacity(0.3), lineWidth: 1)
            )

            Button {
                Task { await viewModel.fetchPreview() }
            } label: {
                HStack(spacing: 8) {
                    if viewModel.isPreviewing {
                        ProgressView().tint(Color(hex: "1A0A0A")).scaleEffect(0.85)
                    } else {
                        Image(systemName: "wand.and.sparkles").font(.system(size: 15))
                    }
                    Text(viewModel.isPreviewing ? "Fetching..." : "Auto-Fill from Link")
                        .font(Font.bodySans(15, weight: .semibold))
                }
                .foregroundColor(Color(hex: "1A0A0A"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "E8C27D"), Color(hex: "F3D9A4")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .opacity(viewModel.isPreviewing || viewModel.urlText.isEmpty ? 0.5 : 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: Color(hex: "E8C27D").opacity(0.3), radius: 10, y: 4)
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isPreviewing || viewModel.urlText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }

    // MARK: Preview Card

    @ViewBuilder
    private func previewSection(_ p: EventPreview) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Preview")
                .font(Font.bodySans(13, weight: .semibold))
                .foregroundColor(Color(hex: "E8C27D"))

            if !p.image_url.isEmpty {
                AsyncImage(url: URL(string: p.image_url)) { phase in
                    switch phase {
                    case .success(let img):
                        img.resizable().aspectRatio(contentMode: .fill)
                    case .empty:
                        Color(hex: "5B0A0A")
                            .overlay(ProgressView().tint(Color(hex: "E8C27D")))
                    case .failure:
                        Color(hex: "5B0A0A")
                            .overlay(Image(systemName: "photo").foregroundColor(Color(hex: "E8C27D").opacity(0.4)))
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: 200)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color(hex: "E8C27D").opacity(0.2), lineWidth: 1)
                )
            }

            VStack(alignment: .leading, spacing: 10) {
                previewRow(icon: "text.quote",    label: "Title",       value: p.title)
                previewRow(icon: "calendar",      label: "Date",        value: formatISO(p.date_time))
                previewRow(icon: "location.fill", label: "Location",    value: p.location.isEmpty ? "—" : p.location)
                if !p.description.isEmpty {
                    previewRow(icon: "doc.text",  label: "Description", value: p.description, multiline: true)
                }
            }
            .padding(16)
            .background(Color.black.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color(hex: "E8C27D").opacity(0.2), lineWidth: 1)
            )

            Button {
                Task { await viewModel.saveEvent() }
            } label: {
                HStack(spacing: 8) {
                    if viewModel.isSaving {
                        ProgressView().tint(Color(hex: "1A0A0A")).scaleEffect(0.85)
                    } else {
                        Image(systemName: "checkmark.circle.fill").font(.system(size: 16))
                    }
                    Text(viewModel.isSaving ? "Saving..." : "Save to Date Experiences ✨")
                        .font(Font.bodySans(15, weight: .semibold))
                }
                .foregroundColor(Color(hex: "1A0A0A"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "E8C27D"), Color(hex: "F3D9A4")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .opacity(viewModel.isSaving ? 0.7 : 1)
                )
                .clipShape(Capsule())
                .shadow(color: Color(hex: "E8C27D").opacity(0.4), radius: 14, y: 5)
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isSaving)
        }
    }

    // MARK: Error Banner

    private func errorBanner(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(Color.luxuryError)
                .padding(.top, 1)
            Text(message)
                .font(Font.bodySans(13, weight: .regular))
                .foregroundColor(Color(hex: "EADBC8"))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.luxuryError.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.luxuryError.opacity(0.4), lineWidth: 1)
        )
    }

    // MARK: Preview Row

    private func previewRow(icon: String, label: String, value: String, multiline: Bool = false) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "E8C27D"))
                .frame(width: 18)
                .padding(.top, 1)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(Font.bodySans(11, weight: .semibold))
                    .foregroundColor(Color(hex: "E8C27D").opacity(0.8))
                Text(value)
                    .font(Font.bodySans(13, weight: .regular))
                    .foregroundColor(.white)
                    .lineLimit(multiline ? 4 : 1)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: ISO formatter

    private func formatISO(_ iso: String) -> String {
        let f1 = ISO8601DateFormatter()
        f1.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let f2 = ISO8601DateFormatter()
        if let d = f1.date(from: iso) ?? f2.date(from: iso) {
            let out = DateFormatter()
            out.dateStyle = .long
            out.timeStyle = .short
            return out.string(from: d)
        }
        return iso
    }
}
