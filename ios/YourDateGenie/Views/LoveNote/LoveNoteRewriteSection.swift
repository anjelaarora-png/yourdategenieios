import SwiftUI

/// Style picker + AI rewrite controls for love-note text fields (Partner Share, etc.).
struct LoveNoteRewriteSection: View {
    @Binding var text: String
    var skin: Skin = .charcoal

    @State private var selectedStyle: LoveNoteRewriteStyle = .romantic
    @State private var isRewriting = false
    @State private var showError = false
    @State private var errorMessage: String?
    @State private var preRewriteSnapshot: String?
    @State private var appliedStyle: LoveNoteRewriteStyle?
    @State private var suppressChangeHandling = false

    enum Skin {
        case charcoal
        case luxury
    }

    private var trimmedText: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canRewrite: Bool {
        !trimmedText.isEmpty && !isRewriting
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            stylePickerLabel

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(LoveNoteRewriteStyle.allCases) { style in
                        styleChip(style)
                    }
                }
                .padding(.horizontal, 1)
            }

            rewriteButton

            if let appliedStyle, preRewriteSnapshot != nil {
                rewriteStatusRow(style: appliedStyle)
            }
        }
        .alert("Couldn't rewrite", isPresented: $showError) {
            Button("OK") {
                showError = false
                errorMessage = nil
            }
        } message: {
            if let errorMessage { Text(errorMessage) }
        }
        .onChange(of: text) { _, _ in
            guard !suppressChangeHandling, appliedStyle != nil else { return }
            preRewriteSnapshot = nil
            appliedStyle = nil
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private var stylePickerLabel: some View {
        switch skin {
        case .charcoal:
            Text("REWRITE STYLE")
                .font(Font.bodySans(11, weight: .bold))
                .tracking(1.4)
                .foregroundColor(Color.textPrimary.opacity(0.45))
        case .luxury:
            HStack(spacing: 6) {
                Text("Rewrite")
                    .font(Font.bodySerif(28, weight: .bold))
                    .italic()
                    .foregroundColor(Color.luxuryGold)
                Text("style")
                    .font(Font.bodySerif(28, weight: .bold))
                    .italic()
                    .foregroundColor(Color.luxuryGold)
            }
        }
    }

    private func styleChip(_ style: LoveNoteRewriteStyle) -> some View {
        let isSelected = selectedStyle == style

        return Button {
            selectedStyle = style
        } label: {
            HStack(spacing: 5) {
                Image(systemName: style.icon)
                    .font(.system(size: 12, weight: .semibold))
                Text(style.displayName)
                    .font(Font.bodySans(12, weight: .semibold))
            }
            .foregroundColor(chipForeground(isSelected: isSelected))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(chipBackground(isSelected: isSelected))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(chipBorder(isSelected: isSelected), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var rewriteButton: some View {
        Button(action: performRewrite) {
            HStack(spacing: 8) {
                if isRewriting {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: rewriteButtonForeground))
                        .scaleEffect(0.85)
                    Text("Rewriting…")
                        .font(Font.bodySans(14, weight: .semibold))
                } else {
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 15, weight: .semibold))
                    Text(appliedStyle == nil ? "Rewrite note" : "Try another style")
                        .font(Font.bodySans(14, weight: .semibold))
                }
            }
            .foregroundColor(rewriteButtonForeground)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(rewriteButtonBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(rewriteButtonBorder, lineWidth: skin == .charcoal ? 1 : 0)
            )
        }
        .buttonStyle(.plain)
        .disabled(!canRewrite)
        .opacity(canRewrite ? 1 : 0.5)
    }

    private func rewriteStatusRow(style: LoveNoteRewriteStyle) -> some View {
        HStack(spacing: 8) {
            Image(systemName: style.icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Color.accentGold)
            Text("Rewritten as \(style.displayName)")
                .font(Font.bodySans(12, weight: .medium))
                .foregroundColor(Color.textPrimary.opacity(0.55))

            Spacer()

            Button("Undo") {
                if let snapshot = preRewriteSnapshot {
                    suppressChangeHandling = true
                    text = snapshot
                    suppressChangeHandling = false
                }
                preRewriteSnapshot = nil
                appliedStyle = nil
            }
            .font(Font.bodySans(12, weight: .semibold))
            .foregroundColor(Color.accentGold)
        }
    }

    // MARK: - Styling

    @ViewBuilder
    private func chipBackground(isSelected: Bool) -> some View {
        switch skin {
        case .charcoal:
            if isSelected {
                LinearGradient.goldShimmer
            } else {
                Color.luxeSurfaceTintStrong
            }
        case .luxury:
            if isSelected {
                LinearGradient.goldShimmer
            } else {
                Color.luxuryGold.opacity(0.2)
            }
        }
    }

    private func chipForeground(isSelected: Bool) -> Color {
        switch skin {
        case .charcoal:
            return isSelected ? Color.luxuryMaroon : Color.luxuryCream
        case .luxury:
            return isSelected ? Color.luxuryMaroon : Color.luxuryCream
        }
    }

    private func chipBorder(isSelected: Bool) -> Color {
        switch skin {
        case .charcoal:
            return isSelected ? Color.clear : Color.luxeSurfaceBorder
        case .luxury:
            return Color.clear
        }
    }

    private var rewriteButtonForeground: Color {
        switch skin {
        case .charcoal: return Color.backgroundPrimary
        case .luxury: return Color.luxuryMaroon
        }
    }

    @ViewBuilder
    private var rewriteButtonBackground: some View {
        switch skin {
        case .charcoal:
            Color.accentGold
        case .luxury:
            LinearGradient.goldShimmer
        }
    }

    private var rewriteButtonBorder: Color {
        skin == .charcoal ? Color.clear : Color.clear
    }

    // MARK: - Action

    private func performRewrite() {
        let raw = trimmedText
        guard !raw.isEmpty else { return }

        if preRewriteSnapshot == nil {
            preRewriteSnapshot = text
        }

        isRewriting = true
        errorMessage = nil
        let style = selectedStyle

        Task {
            do {
                let rewritten = try await LoveNoteAIService.rewrite(userText: raw, style: style)
                await MainActor.run {
                    suppressChangeHandling = true
                    text = rewritten
                    suppressChangeHandling = false
                    appliedStyle = style
                    isRewriting = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                    isRewriting = false
                }
            }
        }
    }
}
