import SwiftUI

// MARK: - Partner Planning Sheet View

struct PartnerPlanningSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var coordinator: NavigationCoordinator
    @StateObject private var partnerManager = PartnerSessionManager.shared
    @StateObject private var userProfileManager = UserProfileManager.shared
    
    @State private var partnerName = ""
    @State private var partnerEmail = ""
    @State private var partnerMessage = ""
    @State private var showConfirmStep = false
    @State private var confirmDate = Date()
    @State private var confirmTime = "7:00 PM"
    @State private var reminderCountdown: String = ""
    
    private static let confirmTimeOptions = ["5:00 PM", "6:00 PM", "7:00 PM", "8:00 PM", "9:00 PM", "10:00 PM"]
    
    private var canSendReminder: Bool {
        guard let sentAt = partnerManager.inviteInfo?.sentAt else { return true }
        return Date().timeIntervalSince(sentAt) >= 24 * 3600
    }
    
    private var showUseLast: Bool {
        LastQuestionnaireStore.hasLastData || coordinator.hasCompletedPreferences
    }
    private var showResume: Bool {
        QuestionnaireProgressStore.hasValidProgress
    }
    private var isWaitingForPartner: Bool {
        switch partnerManager.partnerState {
        case .inviteSent, .partnerJoined: return true
        default: return false
        }
    }
    private var partnerReady: Bool {
        partnerManager.partnerState == .partnerJoined || partnerManager.partnerState == .partnerFilled
    }
    
    var body: some View {
        ZStack {
            Color.luxuryMaroon
                .ignoresSafeArea()
            
            FloatingParticlesView()
                .ignoresSafeArea()
                .opacity(0.6)
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 24) {
                    headerSection
                    ctaSection
                    dividerSection
                    if isWaitingForPartner {
                        waitingBlock
                    } else if showConfirmStep {
                        confirmStepSection
                    } else {
                        inviteFormSection
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 120)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    coordinator.dismissSheet()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color.luxuryGold)
                }
            }
        }
        .toolbarBackground(Color.luxuryMaroon, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .onAppear {
            if partnerManager.sessionId == nil {
                _ = partnerManager.createSession(inviterName: userProfileManager.currentUser?.firstName)
            }
            updateReminderCountdown()
        }
        .onReceive(Timer.publish(every: 60, on: .main, in: .common).autoconnect()) { _ in
            updateReminderCountdown()
        }
    }
    
    private func updateReminderCountdown() {
        guard let sentAt = partnerManager.inviteInfo?.sentAt else {
            reminderCountdown = "You can send a reminder in 24 hours."
            return
        }
        let remaining = 24 * 3600 - Date().timeIntervalSince(sentAt)
        if remaining <= 0 {
            reminderCountdown = ""
            return
        }
        let h = Int(remaining) / 3600
        let m = (Int(remaining) % 3600) / 60
        if h > 0 {
            reminderCountdown = "You can send a reminder in \(h)h \(m)m"
        } else {
            reminderCountdown = "You can send a reminder in \(m)m"
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(spacing: 10) {
            Image(systemName: "sparkles")
                .font(.system(size: 28))
                .foregroundColor(Color.luxuryGold)
            Text("Plan Together")
                .font(Font.tangerine(28, weight: .bold))
                .italic()
                .foregroundColor(Color.luxuryGold)
            Text("Two hearts, one perfect date")
                .font(Font.bodySans(13, weight: .regular))
                .foregroundColor(Color.luxuryCreamMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }
    
    // MARK: - CTAs
    
    private var ctaSection: some View {
        VStack(spacing: 16) {
            Button {
                coordinator.dismissSheet()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    coordinator.startDatePlanning(mode: .fresh)
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 18))
                    Text("Plan My Next Date")
                        .font(Font.bodySans(16, weight: .semibold))
                }
                .foregroundColor(Color.luxuryMaroon)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(LinearGradient.goldShimmer)
                .cornerRadius(16)
                .shadow(color: Color.luxuryGold.opacity(0.35), radius: 12, y: 4)
            }
            .buttonStyle(.plain)
            
            if showUseLast {
                Button {
                    coordinator.showReuseLastPlan()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 16))
                        Text("Reuse Last Plan")
                            .font(Font.bodySans(14, weight: .semibold))
                    }
                    .foregroundColor(Color.luxuryGold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.luxuryGold, lineWidth: 1.5)
                    )
                }
                .buttonStyle(.plain)
            }
            
            if showResume {
                Button {
                    coordinator.startDatePlanning(mode: .resume)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "bookmark.fill")
                            .font(.system(size: 16))
                        Text("Pick up where you left off")
                            .font(Font.bodySans(14, weight: .semibold))
                    }
                    .foregroundColor(Color.luxuryGold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.luxuryGold, lineWidth: 1.5)
                    )
                }
                .buttonStyle(.plain)
            }
            
            if partnerReady {
                Text("Partner is ready.")
                    .font(Font.bodySans(13, weight: .regular))
                    .foregroundColor(Color.luxuryCreamMuted)
            }
        }
    }
    
    // MARK: - Divider
    
    private var dividerSection: some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(Color.luxuryGold.opacity(0.5))
                .frame(height: 1)
            Text("or invite your partner")
                .font(Font.bodySans(13, weight: .regular))
                .foregroundColor(Color.luxuryCreamMuted)
            Rectangle()
                .fill(Color.luxuryGold.opacity(0.5))
                .frame(height: 1)
        }
    }
    
    // MARK: - Confirm step (date, time, summary from account preferences — no login)
    
    private var confirmStepSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Confirm your preferences for this date are up to date")
                .font(Font.tangerine(24, weight: .bold))
                .italic()
                .foregroundColor(Color.luxuryGold)
            
            Text("We'll use your saved preferences from your account — confirm the date and time below.")
                .font(Font.bodySans(13, weight: .regular))
                .foregroundColor(Color.luxuryCreamMuted)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Date")
                    .font(Font.bodySans(13, weight: .medium))
                    .foregroundColor(Color.luxuryGold)
                DatePicker("", selection: $confirmDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .tint(Color.luxuryGold)
            }
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Time")
                    .font(Font.bodySans(13, weight: .medium))
                    .foregroundColor(Color.luxuryGold)
                FlowLayout(spacing: 8) {
                    ForEach(Self.confirmTimeOptions, id: \.self) { time in
                        Button {
                            confirmTime = time
                        } label: {
                            Text(time)
                                .font(Font.bodySans(14, weight: .medium))
                                .foregroundColor(confirmTime == time ? Color.luxuryMaroon : Color.luxuryCream)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(confirmTime == time ? Color.luxuryGold : Color.luxuryMaroonLight.opacity(0.6))
                                .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            if let prefs = userProfileManager.currentUser?.preferences {
                let parts = [prefs.defaultCity.isEmpty ? nil : "City: \(prefs.defaultCity)",
                             prefs.defaultBudget.isEmpty ? nil : "Budget: \(prefs.defaultBudget)",
                             prefs.favoriteCuisines.isEmpty ? nil : "Cuisines: \(prefs.favoriteCuisines.joined(separator: ", "))"].compactMap { $0 }
                if !parts.isEmpty {
                    Text(parts.joined(separator: " · "))
                        .font(Font.bodySans(13, weight: .regular))
                        .foregroundColor(Color.luxuryCreamMuted)
                }
                Text("Your full preferences from your account will be used.")
                    .font(Font.bodySans(12, weight: .regular))
                    .foregroundColor(Color.luxuryCreamMuted.opacity(0.9))
            } else {
                Text("Add your preferences in Settings to personalize the plan.")
                    .font(Font.bodySans(12, weight: .regular))
                    .foregroundColor(Color.luxuryCreamMuted.opacity(0.9))
            }
            
            Button {
                coordinator.dismissSheet()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    coordinator.currentTab = .profile
                    coordinator.activeSheet = .settings
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 14))
                    Text("Update preferences in Settings")
                        .font(Font.bodySans(14, weight: .medium))
                }
                .foregroundColor(Color.luxuryGold)
            }
            .buttonStyle(.plain)
            
            Button {
                confirmAndSendInvite()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                    Text("Confirm & Send Invite")
                        .font(Font.bodySans(16, weight: .semibold))
                }
                .foregroundColor(Color.luxuryMaroon)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(LinearGradient.goldShimmer)
                .cornerRadius(16)
                .shadow(color: Color.luxuryGold.opacity(0.35), radius: 12, y: 4)
            }
            .buttonStyle(.plain)
            
            Button {
                showConfirmStep = false
            } label: {
                Text("Back")
                    .font(Font.bodySans(14, weight: .semibold))
                    .foregroundColor(Color.luxuryGold)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 8)
    }
    
    private func confirmAndSendInvite() {
        var data = QuestionnaireData()
        UserProfileManager.shared.prePopulateQuestionnaireData(&data)
        data.dateScheduled = confirmDate
        data.startTime = confirmTime
        partnerManager.setInviterFilled(data)
        let name = partnerName.trimmingCharacters(in: .whitespacesAndNewlines)
        let email = partnerEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        partnerManager.saveInvite(partnerName: name, partnerEmail: email, message: partnerMessage, plannedDate: confirmDate, plannedTime: confirmTime)
        showConfirmStep = false
        presentShareSheet(customMessage: partnerMessage.isEmpty ? nil : partnerMessage)
    }
    
    // MARK: - Invite (share sheet: text, email, WhatsApp, etc.)
    
    private var inviteFormSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Button {
                showConfirmStep = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 18))
                    Text("Invite Partner")
                        .font(Font.bodySans(16, weight: .semibold))
                }
                .foregroundColor(Color.luxuryMaroon)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(LinearGradient.goldShimmer)
                .cornerRadius(16)
                .shadow(color: Color.luxuryGold.opacity(0.35), radius: 12, y: 4)
            }
            .buttonStyle(.plain)
            
            Text("Send the link via Messages, Mail, WhatsApp, or copy link — they'll join and add their preferences.")
                .font(Font.bodySans(13, weight: .regular))
                .foregroundColor(Color.luxuryCreamMuted)
            
            Text("Optional: add their name & message")
                .font(Font.bodySans(12, weight: .semibold))
                .foregroundColor(Color.luxuryGold.opacity(0.9))
            
            PartnerInviteTextField(
                title: "Partner name",
                placeholder: "Their name",
                text: $partnerName,
                icon: "person.fill"
            )
            PartnerInviteTextField(
                title: "Partner email",
                placeholder: "their@email.com",
                text: $partnerEmail,
                icon: "envelope.fill",
                keyboardType: .emailAddress
            )
            VStack(alignment: .leading, spacing: 8) {
                Text("Personal message (optional)")
                    .font(Font.bodySans(13, weight: .medium))
                    .foregroundColor(Color.luxuryGold)
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "message.fill")
                        .foregroundColor(Color.luxuryGold.opacity(0.7))
                        .frame(width: 20)
                    TextField("", text: $partnerMessage, axis: .vertical)
                        .font(Font.bodySans(16, weight: .regular))
                        .foregroundColor(Color.luxuryCream)
                        .lineLimit(3...6)
                        .padding(.vertical, 8)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color.luxuryMaroonLight)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(partnerMessage.isEmpty ? Color.luxuryGold.opacity(0.2) : Color.luxuryGold.opacity(0.5), lineWidth: 1)
                )
            }
        }
    }
    
    // MARK: - Waiting Block (inline)
    
    private var waitingBlock: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(Color.luxuryGold.opacity(0.3), lineWidth: 2)
                    .frame(width: 80, height: 80)
                WaitingRingView()
            }
            
            let partnerDisplayName: String = {
                let name = (partnerManager.inviteInfo?.partnerName ?? "").trimmingCharacters(in: .whitespaces)
                return name.isEmpty ? "the other person" : name
            }()
            Text("We're waiting for \(partnerDisplayName) to join and add their preferences.")
                .font(Font.tangerine(22, weight: .bold))
                .italic()
                .foregroundColor(Color.luxuryGold)
                .multilineTextAlignment(.center)
            Text("Magic is brewing ✨")
                .font(Font.bodySans(13, weight: .regular))
                .foregroundColor(Color.luxuryCreamMuted)
            
            Circle()
                .stroke(Color.luxuryGold, lineWidth: 2)
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Color.luxuryGold.opacity(0.6))
                )
            
            if canSendReminder {
                Button {
                    presentShareSheet()
                } label: {
                    Text("Send a Reminder")
                        .font(Font.bodySans(14, weight: .semibold))
                        .foregroundColor(Color.luxuryGold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.luxuryGold, lineWidth: 1.5)
                        )
                }
                .buttonStyle(.plain)
            } else {
                Text(reminderCountdown.isEmpty ? "You can send a reminder in 24 hours." : reminderCountdown)
                    .font(Font.bodySans(13, weight: .regular))
                    .foregroundColor(Color.luxuryCreamMuted)
            }
            
            Button {
                coordinator.isPartnerPlanningInviter = true
                coordinator.dismissSheet()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    coordinator.startDatePlanning(mode: .fresh)
                }
            } label: {
                Text("Fill my preferences")
                    .font(Font.bodySans(14, weight: .semibold))
                    .foregroundColor(Color.luxuryGold)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.luxuryMaroonLight.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.luxuryGold.opacity(0.25), lineWidth: 1)
                )
        )
    }
    
    private func presentShareSheet(customMessage: String? = nil) {
        var text = partnerManager.getShareMessage()
        if let msg = customMessage?.trimmingCharacters(in: .whitespacesAndNewlines), !msg.isEmpty {
            text += "\n\n" + msg
        }
        let url = partnerManager.getJoinURL()
        var items: [Any] = [text]
        if let u = url { items.append(u) }
        let activityController = UIActivityViewController(activityItems: items, applicationActivities: nil)
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
}

// MARK: - Partner Invite Text Field

private struct PartnerInviteTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var icon: String
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(Font.bodySans(13, weight: .medium))
                .foregroundColor(Color.luxuryGold)
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(Color.luxuryGold.opacity(0.7))
                    .frame(width: 20)
                TextField("", text: $text, prompt: Text(placeholder).foregroundColor(Color.luxuryMuted.opacity(0.6)))
                    .font(Font.bodySans(16, weight: .regular))
                    .foregroundColor(Color.luxuryCream)
                    .keyboardType(keyboardType)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.luxuryMaroonLight)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(text.isEmpty ? Color.luxuryGold.opacity(0.2) : Color.luxuryGold.opacity(0.5), lineWidth: 1)
            )
        }
    }
}

// MARK: - Spinning ring animation

struct WaitingRingView: View {
    @State private var rotation: Double = 0
    var body: some View {
        Circle()
            .trim(from: 0, to: 0.7)
            .stroke(Color.luxuryGold, style: StrokeStyle(lineWidth: 2, lineCap: .round))
            .frame(width: 80, height: 80)
            .rotationEffect(.degrees(rotation))
            .onAppear {
                withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            }
    }
}
