import SwiftUI

// MARK: - Share with Your Partner (cream itinerary card + charcoal chrome)
struct PartnerShareView: View {
    let plan: DatePlan

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shareMessage = ""
    @State private var copiedToClipboard = false
    @State private var showContentFilterAlert = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.backgroundPrimary
                    .ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 28) {
                        headerSection
                        planPreviewSection
                        personalNoteSection
                        shareActionsSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 48)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color.luxuryGold)
                    }
                }
                ToolbarItem(placement: .principal) {
                    Text("Share Plan")
                        .font(Font.displaySerif(18, weight: .semibold))
                        .foregroundColor(Color.textPrimary)
                }
            }
            .toolbarBackground(Color.backgroundPrimary, for: .navigationBar)
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
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(Color.accentGold.opacity(0.55), lineWidth: 2)
                    .frame(width: 80, height: 80)
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 34))
                    .foregroundColor(Color.accentGold)
            }

            Text("Share with your partner")
                .font(Font.displaySerif(32, weight: .bold))
                .foregroundColor(Color.textPrimary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Text("Send tonight's plan — they'll see every stop, timing, and your personal note.")
                .font(Font.bodySans(14, weight: .regular))
                .foregroundColor(Color.textPrimary.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .padding(.top, 4)
    }

    // MARK: - Plan preview (shared cream card)

    private var planPreviewSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel(title: "Tonight's plan", icon: "sparkles")

            ItineraryCreamPlanPreviewCard(plan: plan, edgePadding: 0)
        }
    }

    // MARK: - Personal note

    private var personalNoteSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel(title: "Add a personal note", icon: "heart.text.square")

            LoveNoteCreamCard(edgePadding: 0, bannerSubtitle: "Your words") {
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $shareMessage)
                        .font(Font.bodySerif(15, weight: .regular))
                        .foregroundColor(Color.textOnCard)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 108)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)

                    if shareMessage.isEmpty {
                        Text("Type a rough note — we'll help polish it…")
                            .font(Font.bodySerif(15, weight: .regular))
                            .foregroundColor(Color.textMutedOnCard.opacity(0.55))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 18)
                            .allowsHitTesting(false)
                    }
                }
            }

            LoveNoteRewriteSection(text: $shareMessage, skin: .charcoal)
        }
    }

    // MARK: - Share actions

    private var shareActionsSection: some View {
        VStack(spacing: 14) {
            Button {
                sharePlan()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Share plan")
                        .font(Font.bodySans(16, weight: .semibold))
                }
                .foregroundColor(Color.backgroundPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.accentGold)
                .cornerRadius(16)
            }
            .buttonStyle(.plain)

            Button {
                copyToClipboard()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: copiedToClipboard ? "checkmark.circle.fill" : "doc.on.doc")
                        .font(.system(size: 15, weight: .medium))
                    Text(copiedToClipboard ? "Copied!" : "Copy plan text")
                        .font(Font.bodySans(15, weight: .semibold))
                }
                .foregroundColor(Color.accentGold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.accentGold.opacity(0.55), lineWidth: 1.5)
                )
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 10) {
                Text("QUICK SEND")
                    .font(Font.bodySans(11, weight: .bold))
                    .tracking(1.4)
                    .foregroundColor(Color.textPrimary.opacity(0.45))

                HStack(spacing: 12) {
                    PartnerShareChannelButton(icon: "message.fill", label: "Message") {
                        shareViaMessages()
                    }
                    PartnerShareChannelButton(icon: "envelope.fill", label: "Email") {
                        shareViaEmail()
                    }
                    PartnerShareChannelButton(icon: "note.text", label: "Notes") {
                        shareAsNote()
                    }
                }
            }
            .padding(.top, 4)
        }
    }

    private func sectionLabel(title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color.accentGold)
            Text(title.uppercased())
                .font(Font.bodySans(11, weight: .bold))
                .tracking(1.4)
                .foregroundColor(Color.textPrimary.opacity(0.55))
        }
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
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Color.backgroundPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.accentGold)
                    .cornerRadius(14)

                Text(label)
                    .font(Font.bodySans(11, weight: .semibold))
                    .foregroundColor(Color.accentGold)
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    PartnerShareView(plan: DatePlan.sample)
}
