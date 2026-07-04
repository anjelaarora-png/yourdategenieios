import SwiftUI

// MARK: - Shared playlist screen typography (matches Love Notes / Home)

enum PlaylistScreenStyle {
    static func sectionLabel(title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color.accentMaroon)
            Text(title.uppercased())
                .font(Font.bodySans(11, weight: .bold))
                .tracking(1.4)
                .foregroundColor(Color.textPrimary.opacity(0.55))
        }
    }
}

// MARK: - Name playlist before saving

struct PlaylistSaveNameSheet: View {
    @Binding var name: String
    let subtitle: String
    let onSave: () -> Void
    let onCancel: () -> Void
    @FocusState private var nameFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                Color.backgroundPrimary.ignoresSafeArea()
                VStack(alignment: .leading, spacing: 20) {
                    Text("Give your playlist a name you'll recognize later.")
                        .font(Font.bodySans(14, weight: .regular))
                        .foregroundColor(Color.luxuryCreamMuted)
                        .fixedSize(horizontal: false, vertical: true)

                    LoveNoteCreamCard(bannerSubtitle: "Playlist name") {
                        TextField("e.g. Our Anniversary Mix", text: $name)
                            .font(Font.bodySerif(16, weight: .regular))
                            .foregroundColor(Color.textOnCard)
                            .padding(14)
                            .autocapitalization(.words)
                            .focused($nameFocused)
                            .submitLabel(.done)
                            .onSubmit { saveIfValid() }
                    }

                    if !subtitle.isEmpty {
                        Text("From: \(subtitle)")
                            .font(Font.bodySans(12, weight: .regular))
                            .foregroundColor(Color.luxuryCreamMuted.opacity(0.85))
                            .lineLimit(2)
                    }

                    Button(action: saveIfValid) {
                        Text("Save Playlist")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(LuxuryGoldButtonStyle())
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    Spacer(minLength: 0)
                }
                .padding(20)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Name Your Playlist")
                        .font(Font.displaySerif(18, weight: .semibold))
                        .foregroundColor(Color.textPrimary)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                        .foregroundColor(Color.accentGold)
                }
            }
            .toolbarBackground(Color.backgroundPrimary, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    nameFocused = true
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    private func saveIfValid() {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        onSave()
    }
}
