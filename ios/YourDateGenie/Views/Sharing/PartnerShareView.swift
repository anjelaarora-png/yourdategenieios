import SwiftUI

// MARK: - Share with Your Partner (cream itinerary card + charcoal chrome)
struct PartnerShareView: View {
    let plan: DatePlan

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shareMessage = ""
    @State private var copiedToClipboard = false
    @State private var showContentFilterAlert = false
    /// The AI rewrite tools stay folded away until "Polish it" is tapped (design 4.1).
    @State private var showRewrite = false

    private var partnerName: String? {
        let name = (PartnerSessionManager.shared.inviteInfo?.partnerName ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? nil : name
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.ydgBase
                    .ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: YDGSpace.lg) {
                        headerSection
                        planPreviewSection
                        personalNoteSection
                    }
                    .padding(.horizontal, YDGSpace.margin)
                    .padding(.top, YDGSpace.xs)
                    .padding(.bottom, YDGSpace.xl)
                }
            }
            .safeAreaInset(edge: .bottom) {
                shareActionsSection
                    .padding(.horizontal, YDGSpace.margin)
                    .padding(.bottom, YDGSpace.xs)
                    .background(Color.ydgBase.ignoresSafeArea())
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(Color.ydgTextPrimary)
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel("Close")
                }
            }
            .toolbarBackground(Color.ydgBase, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .alert("Message not allowed", isPresented: $showContentFilterAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(ObjectionableContentFilter.rejectionMessage)
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: YDGSpace.xs) {
            Text(partnerName.map { "Send it to \($0)" } ?? "Share with your partner")
                .ydgText(.title1)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)

            Text("They'll see every stop, the timing and your note.")
                .ydgText(.body, color: .ydgTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Plan preview (shared cream card)

    private var planPreviewSection: some View {
        let stops = ItineraryPlanFormatting.itineraryStops(for: plan)
        return HStack(spacing: YDGSpace.sm) {
            if let date = plan.scheduledDate {
                VStack(spacing: 0) {
                    Text(date.formatted(.dateTime.weekday(.abbreviated)).uppercased())
                        .font(.ydg(.caption, weight: .semibold))
                        .foregroundColor(Color.ydgHighlight)
                    Text(date.formatted(.dateTime.day()))
                        .font(.ydgSans(22, weight: .semibold))
                        .foregroundColor(Color.ydgTextPrimary)
                }
                .frame(width: 48, height: 52)
                .background(Color.ydgOverlay, in: RoundedRectangle(cornerRadius: YDGRadius.chip, style: .continuous))
                .accessibilityHidden(true)
            } else {
                YDGIconTile(systemName: "calendar", size: 48)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(plan.title)
                    .ydgText(.headline)
                    .fixedSize(horizontal: false, vertical: true)
                Text(stops.prefix(3).map(\.name).joined(separator: " → "))
                    .ydgText(.footnote, color: .ydgTextSecondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .ydgCard()
    }

    // MARK: - Personal note

    private var personalNoteSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionLabel(title: "Add a note", icon: "heart.text.square")
                Spacer()
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { showRewrite.toggle() }
                } label: {
                    Label(showRewrite ? "Done" : "Polish it", systemImage: "sparkle")
                }
                .buttonStyle(.ydgTertiary)
            }

            ZStack(alignment: .topLeading) {
                TextEditor(text: $shareMessage)
                    .font(.ydgDisplay(19, weight: .regular).italic())
                    .foregroundColor(Color.ydgTextPrimary)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 120)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .accessibilityLabel("Personal note")

                if shareMessage.isEmpty {
                    Text("Type a rough note. We'll help polish it…")
                        .font(.ydgDisplay(19, weight: .regular).italic())
                        .foregroundColor(Color.ydgTextTertiary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 18)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
            }
            .background(Color.ydgHighlightSubtle, in: RoundedRectangle(cornerRadius: YDGRadius.card, style: .continuous))

            if showRewrite {
                LoveNoteRewriteSection(text: $shareMessage, skin: .charcoal, rewriteButtonKind: .secondary)
                    .transition(.opacity)
            }
        }
    }

    // MARK: - Share actions

    private var shareActionsSection: some View {
        VStack(spacing: YDGSpace.md) {
            HStack(spacing: YDGSpace.sm) {
                PartnerShareChannelButton(icon: "message", label: "Messages") {
                    shareViaMessages()
                }
                PartnerShareChannelButton(icon: "envelope", label: "Email") {
                    shareViaEmail()
                }
                PartnerShareChannelButton(icon: copiedToClipboard ? "checkmark" : "doc.on.doc",
                                          label: copiedToClipboard ? "Copied" : "Copy text") {
                    copyToClipboard()
                }
            }

            Button {
                sharePlan()
            } label: {
                Text("Share plan")
            }
            .buttonStyle(.ydgPrimary)
        }
        .padding(.top, YDGSpace.xs)
    }

    private func sectionLabel(title: String, icon: String) -> some View {
        Text(title)
            .ydgText(.subhead, color: .ydgTextSecondary)
            .accessibilityAddTraits(.isHeader)
    }

    // MARK: - Share payload

    private var shareText: String {
        var text = "I've planned something special for us!\n\n"
        text += "✨ \(plan.title)\n"
        text += "\"\(plan.tagline)\"\n\n"

        for stop in plan.stops {
            text += "\(stop.emoji) \(stop.timeSlot) - \(stop.name)\n"
        }

        text += "\nTotal time: \(plan.totalDuration)\n"
        text += "Estimated cost: \(plan.estimatedCost)\n"

        if !shareMessage.isEmpty {
            text += "\n\(shareMessage)"
        }

        text += "\n\n— Planned with Your Date Genie"
        return text
    }

    private func sharePlan() {
        guard ObjectionableContentFilter.isAllowed(shareMessage) else {
            showContentFilterAlert = true
            return
        }
        let activityController = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }) ?? windowScene.windows.first,
              let topVC = topViewController(from: window.rootViewController) else { return }

        if let popover = activityController.popoverPresentationController {
            popover.sourceView = topVC.view
            popover.sourceRect = CGRect(x: topVC.view.bounds.midX, y: topVC.view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }

        topVC.present(activityController, animated: true)
    }

    private func topViewController(from base: UIViewController?) -> UIViewController? {
        guard let base = base else { return nil }
        if let presented = base.presentedViewController {
            return topViewController(from: presented)
        }
        if let nav = base as? UINavigationController, let visible = nav.visibleViewController {
            return topViewController(from: visible)
        }
        if let tab = base as? UITabBarController, let selected = tab.selectedViewController {
            return topViewController(from: selected)
        }
        return base
    }

    private func copyToClipboard() {
        guard ObjectionableContentFilter.isAllowed(shareMessage) else {
            showContentFilterAlert = true
            return
        }
        UIPasteboard.general.string = shareText
        if reduceMotion {
            copiedToClipboard = true
        } else {
            withAnimation(.easeInOut(duration: 0.2)) { copiedToClipboard = true }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeInOut(duration: 0.2)) { copiedToClipboard = false }
        }
    }

    private func shareViaMessages() {
        guard ObjectionableContentFilter.isAllowed(shareMessage) else {
            showContentFilterAlert = true
            return
        }
        if let encoded = shareText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
           let url = URL(string: "sms:&body=\(encoded)") {
            UIApplication.shared.open(url)
        }
    }

    private func shareViaEmail() {
        guard ObjectionableContentFilter.isAllowed(shareMessage) else {
            showContentFilterAlert = true
            return
        }
        let subject = "Our Date Plan: \(plan.title)"
        if let subjectEncoded = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
           let bodyEncoded = shareText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
           let url = URL(string: "mailto:?subject=\(subjectEncoded)&body=\(bodyEncoded)") {
            UIApplication.shared.open(url)
        }
    }

    private func shareAsNote() {
        copyToClipboard()
    }
}

// MARK: - Quick send channel

private struct PartnerShareChannelButton: View {
    let icon: String
    let label: String
    let action: () -> Void

    var body: some View {
        YDGShortcutButton(title: label, systemName: icon, action: action)
    }
}

#Preview {
    PartnerShareView(plan: DatePlan.sample)
}
