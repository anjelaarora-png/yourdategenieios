import SwiftUI

// MARK: - Partner Planning Sheet View

struct PartnerPlanningSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var coordinator: NavigationCoordinator
    @EnvironmentObject private var access: AccessManager
    @StateObject private var partnerManager = PartnerSessionManager.shared
    @StateObject private var userProfileManager = UserProfileManager.shared
    @StateObject private var calendarSync = CalendarSyncManager.shared
    @State private var isSwitchingCalendarProvider = false
    
    @State private var partnerName = ""
    @State private var partnerEmail = ""
    @State private var partnerMessage = ""
    @State private var specialNotes = ""
    @State private var proposedDateTimes = PartnerSessionManager.defaultProposedDateTimes()
    @State private var showChangeTimes = false
    @State private var reminderCountdown: String = ""
    @State private var selectedTab: PlanTogetherTab = .details
    @State private var planStep: Int = 1
    @State private var showingPlanFlow = false
    @State private var selectedMainTab: PlanTogetherMainTab = .invite
    @AppStorage("hasSeenPartnerTutorial") private var hasSeenPartnerTutorial = false
    @State private var pendingSessions: [DBPartnerSession] = []
    @State private var pastSessions: [DBPartnerSession] = []
    @State private var sessionsLoading = false
    /// When set, we show the waiting block for this session; nil = show hub.
    @State private var viewingPendingSessionId: String? = nil
    /// When true, show the "Invited" celebration screen with confetti.
    @State private var showingInvitedSuccess = false
    @State private var showingUnlinkConfirmation = false
    @State private var showingReportSheet = false

    // Calendar sync (screen 11b)
    @State private var calendarSyncState: CalendarSyncState = .idle
    @State private var freeEvenings: [CalendarService.FreeEvening] = []

    private enum CalendarSyncState: Equatable {
        case idle
        case scanning
        case synced
        case noneFree
        case denied
    }

    private enum PlanTogetherMainTab: String, CaseIterable {
        case invite = "Invite"
        case pending = "Pending"
        case past = "Past"
    }

    private enum PlanTogetherTab: String, CaseIterable {
        case details = "Details"
        case dateTime = "Date & time"
        case invite = "Invite"
    }

    private static let confirmTimeOptions = ["5:00 PM", "6:00 PM", "7:00 PM", "8:00 PM", "9:00 PM", "10:00 PM"]
    private static let totalPlanSteps = 3

    private var canSendReminder: Bool {
        guard let sentAt = partnerManager.inviteInfo?.sentAt else { return true }
        return Date().timeIntervalSince(sentAt) >= 24 * 3600
    }

    private var isWaitingForPartner: Bool {
        switch partnerManager.partnerState {
        case .inviteSent, .partnerJoined: return true
        default: return false
        }
    }

    /// Whether the current phase warrants showing a phase-progress banner in the hub.
    private var showPhaseBanner: Bool {
        guard partnerManager.sessionId != nil else { return false }
        return partnerManager.currentPhase != .preferencesPending
    }

    var body: some View {
        ZStack {
            Color.backgroundPrimary
                .ignoresSafeArea()
            
            if showingPlanFlow {
                VStack(spacing: 0) {
                    Text(planStepLabelForCurrentStep)
                        .font(Font.bodySans(12, weight: .semibold))
                        .tracking(2)
                        .foregroundColor(Color.luxuryMuted)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                        .padding(.top, 6)
                        .padding(.bottom, 4)
                    planStepProgressHeader
                        .padding(.horizontal, 24)
                    TabView(selection: $planStep) {
                        ScrollView(.vertical, showsIndicators: false) {
                            detailsTabContent
                                .padding(.horizontal, 24)
                                .padding(.vertical, 20)
                                .padding(.bottom, 100)
                        }
                        .tag(1)
                        ScrollView(.vertical, showsIndicators: false) {
                            dateTimeTabContent
                                .padding(.horizontal, 24)
                                .padding(.vertical, 20)
                                .padding(.bottom, 100)
                        }
                        .tag(2)
                        ScrollView(.vertical, showsIndicators: false) {
                            inviteTabContent
                                .padding(.horizontal, 24)
                                .padding(.vertical, 20)
                                .padding(.bottom, 100)
                        }
                        .tag(3)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .animation(.easeInOut(duration: 0.3), value: planStep)
                    planFlowBottomBar
                }
            } else if viewingPendingSessionId != nil, isWaitingForPartner, partnerManager.sessionId == viewingPendingSessionId {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 28) {
                        headerSection
                        waitingBlock
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                    .padding(.bottom, 80)
                }
            } else if showingInvitedSuccess {
                invitedSuccessView
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 28) {
                        headerSection
                        planTogetherHubContent
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                    .padding(.bottom, 80)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                if showingPlanFlow {
                    Button {
                        showingPlanFlow = false
                        planStep = 1
                    } label: {
                        Text("Back")
                            .font(Font.bodySans(16, weight: .semibold))
                            .foregroundColor(Color.luxuryGold)
                    }
                } else if viewingPendingSessionId != nil {
                    Button {
                        viewingPendingSessionId = nil
                    } label: {
                        Text("Back")
                            .font(Font.bodySans(16, weight: .semibold))
                            .foregroundColor(Color.luxuryGold)
                    }
                } else {
                    Button {
                        coordinator.dismissSheet()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color.luxuryGold)
                    }
                }
            }
        }
        .toolbarBackground(Color.backgroundPrimary, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .onAppear {
            if partnerManager.sessionId == nil {
                _ = partnerManager.createSession(inviterName: userProfileManager.currentUser?.firstName)
            }
            updateReminderCountdown()
        }
        .task(id: "hub-\(showingPlanFlow)") {
            guard !showingPlanFlow,
                  let userId = SupabaseService.shared.currentUser?.id else { return }
            sessionsLoading = true
            defer { sessionsLoading = false }
            do {
                let all = try await SupabaseService.shared.listPartnerSessions(inviterUserId: userId)
                pendingSessions = all.filter { $0.partnerData == nil }
                pastSessions = all.filter { $0.partnerData != nil }
            } catch {
                pendingSessions = []
                pastSessions = []
            }
        }
        .onReceive(Timer.publish(every: 60, on: .main, in: .common).autoconnect()) { _ in
            updateReminderCountdown()
        }
        // Phase polling is managed by PartnerSessionManager; generation is triggered by
        // coordinator.handlePartnerPhaseChange → partnerDataReceivedMergeAndGenerate.
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
    
    // MARK: - Header (Charcoal Maroon — serif title in cream)

    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("Plan it together")
                .font(Font.displaySerif(32, weight: .bold))
                .foregroundColor(Color.textPrimary)
            Text("Invite your partner to plan a date you'll both love")
                .font(Font.bodySans(14, weight: .regular))
                .foregroundColor(Color.textPrimary.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Plan Together hub (get-started landing)
    private var planTogetherHubContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Get started on your next date together")
                .font(Font.displaySerif(26, weight: .bold))
                .foregroundColor(Color.textPrimary)
                .padding(.horizontal, 4)
                .fixedSize(horizontal: false, vertical: true)

            Text("Sync your calendar, pick a time, then send your partner a link. We'll merge your vibes and create a plan you'll both love.")
                .font(Font.bodySans(15, weight: .regular))
                .foregroundColor(Color.textPrimary.opacity(0.6))
                .padding(.horizontal, 4)
                .padding(.top, -4)

            // Single gold CTA for this screen.
            Button {
                showingPlanFlow = true
                planStep = 1
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "heart.circle.fill")
                        .font(Font.bodySans(18, weight: .semibold))
                    Text("Start Plan Together")
                        .font(Font.bodySans(16, weight: .semibold))
                    Spacer()
                    Image(systemName: "arrow.right")
                        .font(Font.bodySans(14, weight: .semibold))
                }
                .foregroundColor(Color.backgroundPrimary)
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
                .background(Color.accentGold)
                .cornerRadius(14)
            }
            .buttonStyle(ScaleButtonStyle())

            Text("Three quick steps — details, sync a time, then invite.")
                .font(Font.bodySans(13, weight: .regular))
                .foregroundColor(Color.textPrimary.opacity(0.5))
                .padding(.horizontal, 4)
                .padding(.top, -8)

            if showPhaseBanner { phaseBanner }
            hubPendingSection
            hubPastDatesSection
        }
    }

    /// One row in the hub's Pending invites list (from API or current waiting session).
    private struct PendingDisplayItem: Identifiable {
        let id: String
        let sessionId: String
        let inviterName: String?
        let waitingForName: String
        let statusLabel: String
        let date: Date
        let isFromAPI: Bool
    }

    private var hubPendingDisplayItems: [PendingDisplayItem] {
        var list: [PendingDisplayItem] = pendingSessions.map { session in
            PendingDisplayItem(
                id: session.sessionId,
                sessionId: session.sessionId,
                inviterName: session.inviterName,
                waitingForName: "Partner",
                statusLabel: "Invite sent — pending completion",
                date: session.createdAt,
                isFromAPI: true
            )
        }
        if isWaitingForPartner,
           let sid = partnerManager.sessionId,
           !list.contains(where: { $0.sessionId == sid }) {
            let waitingFor: String = {
                let name = (partnerManager.inviteInfo?.partnerName ?? "").trimmingCharacters(in: .whitespaces)
                return name.isEmpty ? "Partner" : name
            }()
            let status: String = {
                switch partnerManager.partnerState {
                case .inviteSent: return "Invite sent — pending completion"
                case .partnerJoined: return "Invite accepted — pending input"
                default: return "Pending"
                }
            }()
            list.insert(PendingDisplayItem(
                id: sid,
                sessionId: sid,
                inviterName: partnerManager.inviterName,
                waitingForName: waitingFor,
                statusLabel: status,
                date: partnerManager.inviteInfo?.sentAt ?? Date(),
                isFromAPI: false
            ), at: 0)
        }
        return list
    }

    private var hubPendingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("PENDING INVITES")
                .font(Font.bodySans(12, weight: .semibold))
                .tracking(1.5)
                .foregroundColor(Color.accentGold)
                .padding(.top, 8)
            if sessionsLoading && pendingSessions.isEmpty && !isWaitingForPartner {
                HStack {
                    Spacer()
                    ProgressView()
                        .tint(Color.textPrimary.opacity(0.7))
                    Spacer()
                }
                .padding(.vertical, 16)
            } else if hubPendingDisplayItems.isEmpty {
                Text("No pending invites.")
                    .font(Font.bodySans(14, weight: .regular))
                    .foregroundColor(Color.textPrimary.opacity(0.55))
                    .padding(.horizontal, 4)
                    .padding(.bottom, 4)
            } else {
                ForEach(hubPendingDisplayItems) { item in
                    HStack(spacing: 12) {
                        Button {
                            partnerManager.switchToSession(sessionId: item.sessionId, inviterName: item.inviterName)
                            viewingPendingSessionId = item.sessionId
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "clock.badge.questionmark")
                                    .font(.system(size: 20))
                                    .foregroundColor(Color.textPrimary.opacity(0.7))
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Waiting for \(item.waitingForName)")
                                        .font(Font.bodySans(15, weight: .semibold))
                                        .foregroundColor(Color.textPrimary)
                                    Text(item.statusLabel)
                                        .font(Font.bodySans(12, weight: .regular))
                                        .foregroundColor(Color.textPrimary.opacity(0.6))
                                    Text("Invite sent \(hubSessionDateString(item.date))")
                                        .font(Font.bodySans(11, weight: .regular))
                                        .foregroundColor(Color.textPrimary.opacity(0.45))
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(Color.textPrimary.opacity(0.4))
                            }
                        }
                        .buttonStyle(.plain)
                        Button {
                            if item.isFromAPI, let session = pendingSessions.first(where: { $0.sessionId == item.sessionId }) {
                                cancelPendingSession(session)
                            } else {
                                cancelCurrentInvite()
                            }
                        } label: {
                            Text("Cancel")
                                .font(Font.bodySans(12, weight: .semibold))
                                .foregroundColor(Color.textPrimary.opacity(0.7))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.luxeSurfaceTint)
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(16)
                    .background(Color.surfaceElevated)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.luxeSurfaceTint, lineWidth: 1)
                    )
                    .overlay(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 1.5)
                            .fill(Color.accentMaroon)
                            .frame(width: 3)
                            .padding(.vertical, 10)
                    }
                }
            }
        }
    }

    private var hubPastDatesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("PAST DATES TOGETHER")
                .font(Font.bodySans(12, weight: .semibold))
                .tracking(1.5)
                .foregroundColor(Color.accentGold)
                .padding(.top, 16)
            if sessionsLoading && pastSessions.isEmpty {
                HStack {
                    Spacer()
                    ProgressView()
                        .tint(Color.textPrimary.opacity(0.7))
                    Spacer()
                }
                .padding(.vertical, 16)
            } else if pastSessions.isEmpty {
                Text("Plans you created together will appear here.")
                    .font(Font.bodySans(14, weight: .regular))
                    .foregroundColor(Color.textPrimary.opacity(0.55))
                    .padding(.horizontal, 4)
                    .padding(.bottom, 4)
            } else {
                ForEach(pastSessions, id: \.sessionId) { session in
                    Button {
                        guard let rowId = session.id else { return }
                        coordinator.showPastPartnerPlans(partnerSessionId: rowId, inviterName: session.inviterName)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "heart.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(Color.accentMaroon)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Date plan together")
                                    .font(Font.bodySans(15, weight: .semibold))
                                    .foregroundColor(Color.textPrimary)
                                Text("Invite sent \(hubSessionDateString(session.createdAt))")
                                    .font(Font.bodySans(12, weight: .regular))
                                    .foregroundColor(Color.textPrimary.opacity(0.6))
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color.textPrimary.opacity(0.4))
                        }
                        .padding(16)
                        .background(Color.surfaceElevated)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.luxeSurfaceTint, lineWidth: 1)
                        )
                        .overlay(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 1.5)
                                .fill(Color.accentMaroon)
                                .frame(width: 3)
                                .padding(.vertical, 10)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func hubSessionDateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    // MARK: - Phase status banner

    private var phaseBanner: some View {
        let phase = partnerManager.currentPhase
        let hasAction = (phase == .optionsReadyForRanking || phase == .finalOptionSelected)
        return HStack(spacing: 10) {
            Image(systemName: phaseBannerIcon(phase))
                .font(.system(size: 14))
                .foregroundColor(Color.accentMaroon)
            VStack(alignment: .leading, spacing: 2) {
                Text(phase.displayLabel)
                    .font(Font.bodySans(13, weight: .semibold))
                    .foregroundColor(Color.textPrimary)
                Text(phaseBannerSubtitle(phase))
                    .font(Font.bodySans(12, weight: .regular))
                    .foregroundColor(Color.textPrimary.opacity(0.6))
            }
            Spacer()
            if hasAction {
                Button {
                    if phase == .optionsReadyForRanking {
                        coordinator.activeSheet = .partnerRanking
                    } else {
                        coordinator.loadFinalOptionAndShowReveal()
                    }
                } label: {
                    Text(phase == .finalOptionSelected ? "Reveal" : "Rank")
                        .font(Font.bodySans(12, weight: .bold))
                        .foregroundColor(Color.backgroundPrimary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(Color.accentGold)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
            } else if phase.requiresPolling {
                WaitingRingView()
                    .frame(width: 20, height: 20)
            }
        }
        .padding(14)
        .background(Color.surfaceElevated)
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.luxeSurfaceTint, lineWidth: 1))
    }

    private func phaseBannerIcon(_ phase: PlanPhase) -> String {
        switch phase {
        case .preferencesPending:              return "clock.badge.questionmark"
        case .preferencesComplete:             return "person.2.fill"
        case .generatingDateOptions:           return "sparkles"
        case .optionsReadyForRanking:          return "list.number"
        case .waitingForPartnerRanking:        return "clock.badge.checkmark"
        case .rankingsComplete:                return "checkmark.circle.fill"
        case .finalOptionSelected:             return "star.circle.fill"
        case .finalized:                       return "heart.circle.fill"
        default:                               return "circle"
        }
    }

    private func phaseBannerSubtitle(_ phase: PlanPhase) -> String {
        switch phase {
        case .preferencesPending:       return "Invite sent — waiting for partner"
        case .preferencesComplete:      return "Both preferences in — generating options"
        case .generatingDateOptions:    return "This takes just a moment"
        case .optionsReadyForRanking:   return "Tap to privately rank your favorites"
        case .waitingForPartnerRanking: return "Your rankings are in"
        case .rankingsComplete:         return "Computing your best match"
        case .finalOptionSelected:      return "Tap to reveal your winning date plan"
        case .finalized:                return "Plan confirmed — enjoy your date!"
        default:                        return ""
        }
    }

    // MARK: - Invited success (confetti + Done)
    private var invitedSuccessView: some View {
        InvitedSuccessCelebrationView(onDone: { showingInvitedSuccess = false })
    }

    // MARK: - Plan flow step progress (same format as Conversation Starters)
    private var planStepProgressHeader: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                ForEach(1...Self.totalPlanSteps, id: \.self) { s in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(s <= planStep ? Color.luxuryGold : Color.luxuryMuted.opacity(0.4))
                        .frame(height: 4)
                        .frame(maxWidth: s == planStep ? nil : .infinity)
                    if s < Self.totalPlanSteps { Spacer(minLength: 4) }
                }
            }
            .frame(height: 4)
            Text("STEP \(planStep) OF \(Self.totalPlanSteps)")
                .font(Font.bodySans(12, weight: .semibold))
                .tracking(2)
                .foregroundColor(Color.luxuryMuted)
                .padding(.top, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var planStepLabelForCurrentStep: String {
        switch planStep {
        case 1: return "DETAILS"
        case 2: return "SYNC CALENDAR"
        case 3: return "INVITE"
        default: return ""
        }
    }

    // MARK: - Plan flow bottom bar (Continue / Share invite link)
    private var planFlowBottomBar: some View {
        VStack(spacing: 12) {
            if planStep == 3 {
                Button {
                    sendInviteAndShare()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.up")
                            .font(Font.bodySans(16, weight: .semibold))
                        Text("Share invite link")
                            .font(Font.bodySans(16, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(LuxuryGoldButtonStyle(isSmall: false))
                .padding(.horizontal, 20)
            } else {
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        planStep += 1
                    }
                } label: {
                    HStack(spacing: 8) {
                        Text("Continue")
                            .font(Font.bodySans(16, weight: .semibold))
                        Image(systemName: "arrow.right")
                            .font(Font.bodySans(14, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(LuxuryGoldButtonStyle(isSmall: false))
                .padding(.horizontal, 20)
            }
        }
        .padding(.vertical, 16)
        .background(
            Color.backgroundPrimary
                .shadow(color: Color.black.opacity(0.3), radius: 10, y: -5)
        )
    }

    // MARK: - Main tab picker (Invite | Pending | Past)

    private var mainTabPicker: some View {
        Picker("Section", selection: $selectedMainTab) {
            ForEach(PlanTogetherMainTab.allCases, id: \.self) { tab in
                Text(tab.rawValue).tag(tab)
            }
        }
        .pickerStyle(.segmented)
        .colorMultiply(Color.luxuryGold)
    }

    // MARK: - Pending list (waiting for partner's input)

    private var pendingListContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Waiting for your partner to add their preferences")
                .font(Font.bodySans(13, weight: .regular))
                .foregroundColor(Color.luxuryCreamMuted)
            if sessionsLoading {
                HStack {
                    Spacer()
                    ProgressView()
                        .tint(Color.luxuryGold)
                    Spacer()
                }
                .padding(.vertical, 24)
            } else if pendingSessions.isEmpty {
                Text("No pending invites")
                    .font(Font.bodySans(14, weight: .medium))
                    .foregroundColor(Color.luxuryCreamMuted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
            } else {
                ForEach(pendingSessions, id: \.sessionId) { session in
                    HStack(spacing: 12) {
                        Button {
                            partnerManager.switchToSession(sessionId: session.sessionId, inviterName: session.inviterName)
                            selectedMainTab = .invite
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "clock.badge.questionmark")
                                    .font(.system(size: 20))
                                    .foregroundColor(Color.luxuryGold)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Waiting for response")
                                        .font(Font.bodySans(15, weight: .semibold))
                                        .foregroundColor(Color.luxuryCream)
                                    Text(pendingSessionDateString(session))
                                        .font(Font.bodySans(12, weight: .regular))
                                        .foregroundColor(Color.luxuryCreamMuted)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(Color.luxuryGold.opacity(0.8))
                            }
                        }
                        .buttonStyle(.plain)
                        Button {
                            cancelPendingSession(session)
                        } label: {
                            Text("Cancel")
                                .font(Font.bodySans(12, weight: .semibold))
                                .foregroundColor(Color.luxuryCreamMuted)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.luxuryMaroonLight.opacity(0.8))
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(16)
                    .background(Color.luxuryMaroonLight.opacity(0.6))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.luxuryGold.opacity(0.25), lineWidth: 1)
                    )
                }
            }
        }
    }

    private func pendingSessionDateString(_ session: DBPartnerSession) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return "Invite sent \(formatter.string(from: session.updatedAt))"
    }

    // MARK: - Past list (date plans together)

    private var pastListContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Plans you created together")
                .font(Font.bodySans(13, weight: .regular))
                .foregroundColor(Color.luxuryCreamMuted)
            if sessionsLoading {
                HStack {
                    Spacer()
                    ProgressView()
                        .tint(Color.luxuryGold)
                    Spacer()
                }
                .padding(.vertical, 24)
            } else if pastSessions.isEmpty {
                Text("No past plans yet")
                    .font(Font.bodySans(14, weight: .medium))
                    .foregroundColor(Color.luxuryCreamMuted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
            } else {
                ForEach(pastSessions, id: \.sessionId) { session in
                    Button {
                        guard let rowId = session.id else { return }
                        coordinator.showPastPartnerPlans(partnerSessionId: rowId, inviterName: session.inviterName)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "heart.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(Color.luxuryGold)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Date plan together")
                                    .font(Font.bodySans(15, weight: .semibold))
                                    .foregroundColor(Color.luxuryCream)
                                Text(pastSessionDateString(session))
                                    .font(Font.bodySans(12, weight: .regular))
                                    .foregroundColor(Color.luxuryCreamMuted)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color.luxuryGold.opacity(0.8))
                        }
                        .padding(16)
                        .background(Color.luxuryMaroonLight.opacity(0.6))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.luxuryGold.opacity(0.25), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func pastSessionDateString(_ session: DBPartnerSession) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return "Updated \(formatter.string(from: session.updatedAt))"
    }

    // MARK: - Details step (full preferences from profile, special note)

    private var profilePreferences: DatePreferences {
        userProfileManager.currentUser?.preferences ?? DatePreferences()
    }

    private var detailsTabContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Preferences from your profile")
                    .font(Font.bodySans(13, weight: .medium))
                    .foregroundColor(Color.textPrimary.opacity(0.6))
                Spacer()
                Button {
                    coordinator.dismissSheet()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        coordinator.startEditPreferencesOnly()
                    }
                } label: {
                    Text("Edit in profile")
                        .font(Font.bodySans(13, weight: .semibold))
                        .foregroundColor(Color.textPrimary)
                        .underline()
                }
                .buttonStyle(.plain)
            }

            profilePreferencesSection(preferences: profilePreferences)

            VStack(alignment: .leading, spacing: 8) {
                Text("Anything special? (e.g. 3-month anniversary)")
                    .font(Font.bodySans(12, weight: .medium))
                    .foregroundColor(Color.textPrimary.opacity(0.6))
                TextField("", text: $specialNotes, prompt: Text("Optional").foregroundColor(Color.textPrimary.opacity(0.35)))
                    .font(Font.bodySans(15, weight: .regular))
                    .foregroundColor(Color.textPrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(Color.surfaceElevated)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.luxeSurfaceBorder, lineWidth: 1)
                    )
            }
        }
    }

    private func profilePreferencesSection(preferences: DatePreferences) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            PreferenceChipsSection(
                icon: "fork.knife",
                title: "Cuisines",
                chips: preferences.favoriteCuisines.compactMap { value in
                    QuestionnaireOptions.cuisines.first { $0.value == value }.map { (emoji: $0.emoji, label: $0.label) }
                }
            )
            PreferenceChipsSection(
                icon: "sparkles",
                title: "Activities",
                chips: preferences.favoriteActivities.compactMap { value in
                    QuestionnaireOptions.activities.first { $0.value == value }.map { (emoji: $0.emoji, label: $0.label) }
                }
            )
            PreferenceChipsSection(
                icon: "wineglass.fill",
                title: "Drink of choice",
                chips: preferences.beveragePreferences.compactMap { value in
                    QuestionnaireOptions.drinkPreferences.first { $0.value == value }.map { (emoji: $0.emoji, label: $0.label) }
                }
            )
            if !preferences.defaultCity.isEmpty || !preferences.defaultStartingPoint.isEmpty {
                let locationLabel = [preferences.defaultStartingPoint, preferences.defaultCity]
                    .filter { !$0.isEmpty }
                    .joined(separator: ", ")
                PreferenceChipsSection(
                    icon: "mappin.circle.fill",
                    title: "Area",
                    chips: [(emoji: "📍", label: locationLabel)]
                )
            }
            PreferenceChipsSection(
                icon: "leaf.fill",
                title: "Dietary",
                chips: preferences.dietaryRestrictions.isEmpty
                    ? [(emoji: "✅", label: "No restrictions")]
                    : preferences.dietaryRestrictions.compactMap { value in
                        QuestionnaireOptions.dietaryRestrictions.first { $0.value == value }.map { (emoji: $0.emoji, label: $0.label) }
                    }
            )
            PreferenceChipsSection(
                icon: "heart.fill",
                title: "Vibe",
                chips: preferences.loveLanguages.map { (emoji: $0.emoji, label: $0.displayName) }
            )
            PreferenceChipsSection(
                icon: "xmark.circle.fill",
                title: "Hard nos",
                chips: preferences.hardNos.compactMap { value in
                    QuestionnaireOptions.hardNos.first { $0.value == value }.map { (emoji: $0.emoji, label: $0.label) }
                }
            )
        }
        .padding(16)
        .background(Color.surfaceElevated)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.luxeSurfaceTint, lineWidth: 1)
        )
    }

    // MARK: - Sync calendar tab (screen 11b — find nights you're both free)

    private var dateTimeTabContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("I'll check your calendar and find evenings you're both free.")
                .font(Font.bodySans(14, weight: .regular))
                .foregroundColor(Color.textPrimary.opacity(0.6))

            // Google Calendar is gated off for v1 (Apple-only). When the feature flag is
            // false the picker is hidden and the step behaves as EventKit-only; the "Your
            // calendar" row reads "Apple Calendar" because the provider is forced to .apple.
            if Config.isGoogleCalendarEnabled {
                calendarProviderPicker
            }

            calendarStatusRow

            switch calendarSyncState {
            case .idle, .scanning:
                calendarScanningCard
            case .synced:
                freeEveningsCard
            case .noneFree:
                noFreeEveningsCard
            case .denied:
                calendarDeniedCard
            }

            manualTimesSection
        }
        .task(id: planStep == 2) {
            if planStep == 2, calendarSyncState == .idle {
                await syncCalendar()
            }
        }
    }

    /// Opt-in segmented control to choose Apple (EventKit, default) or Google Calendar.
    /// Selecting Google triggers an incremental scope request; if denied it reverts to Apple.
    private var calendarProviderPicker: some View {
        HStack(spacing: 8) {
            ForEach(CalendarProvider.selectableCases) { provider in
                Button {
                    Task { await switchCalendarProvider(to: provider) }
                } label: {
                    Text(provider.shortName)
                        .font(Font.bodySans(12, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(calendarSync.provider == provider ? Color.accentMaroon : Color.luxeSurfaceTint)
                        .foregroundColor(calendarSync.provider == provider ? Color.textPrimary : Color.textPrimary.opacity(0.55))
                        .cornerRadius(9)
                }
                .buttonStyle(.plain)
                .disabled(isSwitchingCalendarProvider)
            }
        }
        .padding(3)
        .background(Color.surfaceElevated)
        .cornerRadius(12)
    }

    /// Switches the calendar backend, requesting Google scopes when needed, then re-scans.
    private func switchCalendarProvider(to provider: CalendarProvider) async {
        guard provider != calendarSync.provider, !isSwitchingCalendarProvider else { return }
        isSwitchingCalendarProvider = true
        defer { isSwitchingCalendarProvider = false }

        switch provider {
        case .apple:
            calendarSync.selectAppleCalendar()
        case .google:
            // Reverts to Apple internally if the user cancels or denies calendar scopes.
            await calendarSync.selectGoogleCalendar()
        }

        calendarSyncState = .idle
        await syncCalendar()
    }

    /// "Your calendar" status row (partner calendar shown as pending until they accept).
    private var calendarStatusRow: some View {
        VStack(spacing: 9) {
            calendarRow(
                initial: String((userProfileManager.currentUser?.firstName ?? "You").prefix(1)).uppercased(),
                name: "Your calendar",
                subtitle: calendarSync.provider.displayName,
                isSynced: calendarSyncState == .synced || calendarSyncState == .noneFree
            )
            calendarRow(
                initial: String((partnerName.isEmpty ? "Partner" : partnerName).prefix(1)).uppercased(),
                name: partnerName.isEmpty ? "Partner's calendar" : "\(partnerName)'s calendar",
                subtitle: "Syncs when they accept",
                isSynced: false
            )
        }
    }

    private func calendarRow(initial: String, name: String, subtitle: String, isSynced: Bool) -> some View {
        HStack(spacing: 10) {
            ZStack {
                Circle().fill(Color.accentMaroon.opacity(0.5)).frame(width: 32, height: 32)
                Text(initial)
                    .font(Font.bodySans(13, weight: .semibold))
                    .foregroundColor(Color.textPrimary)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(Font.bodySans(13, weight: .medium))
                    .foregroundColor(Color.textPrimary)
                Text(subtitle)
                    .font(Font.bodySans(11, weight: .regular))
                    .foregroundColor(Color.textPrimary.opacity(0.45))
            }
            Spacer()
            if isSynced {
                Text("✓ synced")
                    .font(Font.bodySans(11, weight: .semibold))
                    .foregroundColor(Color.accentGold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.accentMaroon.opacity(0.35))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.accentGold.opacity(0.35), lineWidth: 1)
                    )
                    .cornerRadius(20)
            } else {
                Text("pending")
                    .font(Font.bodySans(11, weight: .regular))
                    .foregroundColor(Color.textPrimary.opacity(0.45))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.luxeSurfaceTint)
                    .cornerRadius(20)
            }
        }
        .padding(12)
        .background(Color.surfaceElevated)
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.luxeSurfaceTint, lineWidth: 1))
    }

    private var calendarScanningCard: some View {
        HStack(spacing: 12) {
            ProgressView().tint(Color.textPrimary.opacity(0.7))
            Text("Scanning your calendar for free evenings…")
                .font(Font.bodySans(13, weight: .regular))
                .foregroundColor(Color.textPrimary.opacity(0.6))
            Spacer()
        }
        .padding(14)
        .background(Color.surfaceElevated)
        .cornerRadius(14)
    }

    /// Populated state — gold-bordered cream card listing free evenings.
    private var freeEveningsCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("✨ You're both free \(freeEvenings.count) evening\(freeEvenings.count == 1 ? "" : "s")")
                .font(Font.bodySans(13, weight: .semibold))
                .foregroundColor(Color.textOnCard)
            Text(freeEvenings.map(\.label).joined(separator: " · "))
                .font(Font.bodySans(12, weight: .regular))
                .foregroundColor(Color.textMutedOnCard)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .creamGoldHighlightMaroonAccent(cornerRadius: 14)
    }

    private var noFreeEveningsCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("No fully-free evenings in the next 3 weeks")
                .font(Font.bodySans(13, weight: .semibold))
                .foregroundColor(Color.textPrimary)
            Text("Pick times manually below — we'll still plan around them.")
                .font(Font.bodySans(12, weight: .regular))
                .foregroundColor(Color.textPrimary.opacity(0.55))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.surfaceElevated)
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.luxeSurfaceTint, lineWidth: 1))
    }

    private var calendarDeniedCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(calendarSync.provider == .google ? "Google Calendar isn't connected" : "Calendar access is off")
                .font(Font.bodySans(13, weight: .semibold))
                .foregroundColor(Color.textPrimary)
            Text(
                calendarSync.provider == .google
                    ? "Connect Google Calendar to auto-find free nights, or pick times manually below."
                    : "Turn on Calendar access in Settings to auto-find free nights, or pick times manually below."
            )
                .font(Font.bodySans(12, weight: .regular))
                .foregroundColor(Color.textPrimary.opacity(0.55))
            if calendarSync.provider == .google {
                Button {
                    Task {
                        await calendarSync.selectGoogleCalendar()
                        calendarSyncState = .idle
                        await syncCalendar()
                    }
                } label: {
                    Text("Connect Google Calendar")
                        .font(Font.bodySans(13, weight: .semibold))
                        .foregroundColor(Color.textPrimary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.textPrimary.opacity(0.3), lineWidth: 1))
                }
                .buttonStyle(.plain)
            } else {
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Text("Open Settings")
                        .font(Font.bodySans(13, weight: .semibold))
                        .foregroundColor(Color.textPrimary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.textPrimary.opacity(0.3), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.surfaceElevated)
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.luxeSurfaceTint, lineWidth: 1))
    }

    private var manualTimesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation { showChangeTimes.toggle() }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 12, weight: .medium))
                    Text(showChangeTimes ? "Hide manual times" : "Adjust times manually")
                        .font(Font.bodySans(13, weight: .medium))
                }
                .foregroundColor(Color.textPrimary.opacity(0.75))
            }
            .buttonStyle(.plain)

            if showChangeTimes {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(Array(proposedDateTimes.enumerated()), id: \.offset) { index, _ in
                        HStack(spacing: 12) {
                            DatePicker("", selection: Binding(
                                get: { proposedDateTimes[index].date },
                                set: { newDate in
                                    var slot = proposedDateTimes[index]
                                    slot.date = newDate
                                    proposedDateTimes[index] = slot
                                }
                            ), displayedComponents: .date)
                                .datePickerStyle(.compact)
                                .tint(Color.accentGold)
                            TextField("Label", text: Binding(
                                get: { proposedDateTimes[index].timeLabel },
                                set: { newLabel in
                                    var slot = proposedDateTimes[index]
                                    slot.timeLabel = newLabel
                                    proposedDateTimes[index] = slot
                                }
                            ))
                                .font(Font.bodySans(14, weight: .regular))
                                .foregroundColor(Color.textPrimary)
                                .frame(width: 90)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .background(Color.surfaceElevated)
                                .cornerRadius(8)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    /// Scan the local calendar (EventKit), upload this device's free slots, and intersect with
    /// the partner's so proposed slots are nights BOTH are free (screen 11b).
    private func syncCalendar() async {
        calendarSyncState = .scanning
        let result = await partnerManager.syncAndComputeFreeEvenings(count: 3)
        switch result {
        case .success(let evenings):
            await MainActor.run {
                if evenings.isEmpty {
                    calendarSyncState = .noneFree
                } else {
                    freeEvenings = evenings
                    proposedDateTimes = evenings.map {
                        PartnerSessionManager.ProposedDateTime(date: $0.date, timeLabel: $0.label)
                    }
                    calendarSyncState = .synced
                }
            }
        case .denied:
            await MainActor.run { calendarSyncState = .denied }
        case .failed:
            await MainActor.run { calendarSyncState = .noneFree }
        }
    }

    // MARK: - Invite tab (share link via any platform — no email required)

    private var inviteTabContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            // One-time tutorial banner
            if !hasSeenPartnerTutorial {
                PartnerTutorialBannerView {
                    withAnimation { hasSeenPartnerTutorial = true }
                }
            }

            Text("Share the link via Messages, WhatsApp, or any app — no email required.")
                .font(Font.bodySans(13, weight: .regular))
                .foregroundColor(Color.textPrimary.opacity(0.6))

            PartnerInviteTextField(
                title: "Partner name (optional)",
                placeholder: "Their name",
                text: $partnerName,
                icon: "person.fill"
            )
            VStack(alignment: .leading, spacing: 8) {
                Text("Message to include (optional)")
                    .font(Font.bodySans(13, weight: .medium))
                    .foregroundColor(Color.textPrimary.opacity(0.6))
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "message.fill")
                        .foregroundColor(Color.textPrimary.opacity(0.5))
                        .frame(width: 20)
                    TextField("", text: $partnerMessage, axis: .vertical)
                        .font(Font.bodySans(16, weight: .regular))
                        .foregroundColor(Color.textPrimary)
                        .lineLimit(2...4)
                        .padding(.vertical, 8)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color.surfaceElevated)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.luxeSurfaceBorder, lineWidth: 1)
                )
            }

            // Primary gold CTA for this step lives in the bottom bar.
            Button {
                startNewInvite()
            } label: {
                Text("Start a new invite")
                    .font(Font.bodySans(13, weight: .medium))
                    .foregroundColor(Color.textPrimary.opacity(0.7))
                    .underline()
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Multiple invites & cancel

    private func resetInviteForm() {
        partnerName = ""
        partnerEmail = ""
        partnerMessage = ""
        specialNotes = ""
        proposedDateTimes = PartnerSessionManager.defaultProposedDateTimes()
        showChangeTimes = false
        selectedTab = .details
        planStep = 1
    }

    /// Start a new invite (fresh session and form) so user can send another invite.
    private func startNewInvite() {
        _ = partnerManager.createSession(inviterName: userProfileManager.currentUser?.firstName)
        resetInviteForm()
    }

    /// Block the partner and cancel the current session (Apple §1.2).
    private func blockAndUnlinkCurrentPartner() {
        guard let sid = partnerManager.sessionId else { return }
        partnerManager.clearSession()
        viewingPendingSessionId = nil
        startNewInvite()
        Task {
            // Delete the session
            try? await SupabaseService.shared.deletePartnerSession(sessionId: sid)
            // Fetch the session to get the partner's userId for the block row, then insert
            if let session = try? await SupabaseService.shared.getPartnerSession(sessionId: sid) {
                let partnerUUID: UUID? = session.partnerUserId ?? session.inviterUserId
                // Block whoever is the other party
                if let otherUserId = partnerUUID,
                   otherUserId != SupabaseService.shared.currentUser?.id {
                    try? await SupabaseService.shared.blockUser(
                        blockedId: otherUserId,
                        reason: "Unlinked by user via app"
                    )
                }
            }
            await MainActor.run { refreshPendingPastLists() }
        }
    }

    /// Cancel the current invite: delete from backend, clear local state, show fresh invite form.
    private func cancelCurrentInvite() {
        guard let sid = partnerManager.sessionId else { return }
        partnerManager.clearSession()
        startNewInvite()
        Task {
            try? await SupabaseService.shared.deletePartnerSession(sessionId: sid)
            await MainActor.run { refreshPendingPastLists() }
        }
    }

    /// Cancel a pending session by id (from Pending list). If it's the current session, clear and show form.
    private func cancelPendingSession(_ session: DBPartnerSession) {
        let wasCurrent = partnerManager.sessionId == session.sessionId
        if wasCurrent {
            partnerManager.clearSession()
            startNewInvite()
        }
        pendingSessions.removeAll { $0.sessionId == session.sessionId }
        Task {
            try? await SupabaseService.shared.deletePartnerSession(sessionId: session.sessionId)
            await MainActor.run { refreshPendingPastLists() }
        }
    }

    private func refreshPendingPastLists() {
        guard let userId = SupabaseService.shared.currentUser?.id else { return }
        Task {
            do {
                let all = try await SupabaseService.shared.listPartnerSessions(inviterUserId: userId)
                await MainActor.run {
                    pendingSessions = all.filter { $0.partnerData == nil }
                    pastSessions = all.filter { $0.partnerData != nil }
                }
            } catch { }
        }
    }

    // MARK: - Helpers

    private func waitingTitleForPhase(_ partnerName: String) -> String {
        switch partnerManager.currentPhase {
        case .preferencesPending:        return "We're holding a seat for \(partnerName)."
        case .preferencesComplete:       return "Both preferences are in!"
        case .generatingDateOptions:     return "Crafting your date options…"
        case .optionsReadyForRanking:    return "Your options are ready to rank."
        case .waitingForPartnerRanking:  return "Your rankings are submitted."
        case .rankingsComplete:          return "Both rankings are in!"
        case .finalOptionSelected:       return "Your final date plan is ready."
        default:                         return "We're holding a seat for \(partnerName)."
        }
    }

    private var waitingSubtitleForPhase: String {
        switch partnerManager.currentPhase {
        case .preferencesPending:        return "No rush — we'll tell you the moment they're in."
        case .preferencesComplete:       return "Generating your personalized options now."
        case .generatingDateOptions:     return "This takes just a moment — great things take a little time."
        case .optionsReadyForRanking:    return "Tap \u{201C}Rank\u{201D} to privately rank your favorites."
        case .waitingForPartnerRanking:  return "Waiting for your partner to rank their options."
        case .rankingsComplete:          return "Computing your best match based on both rankings."
        case .finalOptionSelected:       return "Tap \u{201C}Reveal\u{201D} to see your winning plan."
        default:                         return "No rush — we'll tell you the moment they're in."
        }
    }

    private var preferencesGlanceLine: String {
        guard let prefs = userProfileManager.currentUser?.preferences else { return "" }
        var parts: [String] = []
        if !prefs.favoriteCuisines.isEmpty { parts.append(prefs.favoriteCuisines.prefix(2).joined(separator: ", ")) }
        if !prefs.beveragePreferences.isEmpty { parts.append(prefs.beveragePreferences.prefix(1).joined()) }
        if !prefs.favoriteActivities.isEmpty { parts.append(prefs.favoriteActivities.prefix(1).joined()) }
        if !prefs.defaultCity.isEmpty { parts.append(prefs.defaultCity) }
        return parts.joined(separator: " · ")
    }

    private func sendInviteAndShare() {
        if partnerManager.sessionId == nil {
            _ = partnerManager.createSession(inviterName: userProfileManager.currentUser?.firstName)
        }
        var data = QuestionnaireData()
        UserProfileManager.shared.prePopulateQuestionnaireData(&data)
        if let first = proposedDateTimes.first {
            data.dateScheduled = first.date
            data.startTime = first.timeLabel
        }
        if !specialNotes.trimmingCharacters(in: .whitespaces).isEmpty {
            let existing = data.additionalNotes.trimmingCharacters(in: .whitespaces)
            data.additionalNotes = [existing, specialNotes.trimmingCharacters(in: .whitespaces)].filter { !$0.isEmpty }.joined(separator: " ")
        }
        partnerManager.setInviterFilled(data)
        let name = partnerName.trimmingCharacters(in: .whitespacesAndNewlines)
        let email = partnerEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        partnerManager.saveInvite(
            partnerName: name,
            partnerEmail: email,
            message: partnerMessage,
            plannedDate: proposedDateTimes.first?.date,
            plannedTime: proposedDateTimes.first?.timeLabel,
            specialNotes: specialNotes.trimmingCharacters(in: .whitespaces).isEmpty ? nil : specialNotes.trimmingCharacters(in: .whitespaces),
            proposedDateTimes: proposedDateTimes
        )
        let sessionId = partnerManager.sessionId ?? ""
        let plannedDates = proposedDateTimes.map { DBProposedDateTime(date: $0.date, timeLabel: $0.timeLabel) }
        let notes = specialNotes.trimmingCharacters(in: .whitespaces).isEmpty ? nil : specialNotes.trimmingCharacters(in: .whitespaces)
        Task {
            _ = try? await SupabaseService.shared.createOrUpdatePartnerSession(
                sessionId: sessionId,
                inviterName: userProfileManager.currentUser?.firstName ?? "A friend",
                inviterUserId: SupabaseService.shared.currentUser?.id,
                inviterData: data,
                inviterPlannedDates: plannedDates,
                notes: notes
            )
        }
        let customMessage = partnerMessage.isEmpty ? nil : partnerMessage
        DispatchQueue.main.async {
            showingPlanFlow = false
            planStep = 1
            showingInvitedSuccess = true
            presentShareSheet(customMessage: customMessage)
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
                return name.isEmpty ? "your partner" : name
            }()
            Text(waitingTitleForPhase(partnerDisplayName))
                .font(Font.displaySerif(24, weight: .bold))
                .foregroundColor(Color.textPrimary)
                .multilineTextAlignment(.center)
            Text(waitingSubtitleForPhase)
                .font(Font.bodySans(13, weight: .regular))
                .foregroundColor(Color.textPrimary.opacity(0.6))
                .multilineTextAlignment(.center)
            
            Circle()
                .stroke(Color.accentMaroon, lineWidth: 2)
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Color.textPrimary.opacity(0.5))
                )
            
            if canSendReminder {
                // Single gold action for this state.
                Button {
                    DispatchQueue.main.async {
                        presentShareSheet()
                    }
                } label: {
                    Text("Send a reminder")
                        .font(Font.bodySans(15, weight: .semibold))
                        .foregroundColor(Color.backgroundPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.accentGold)
                        .cornerRadius(14)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 24)
            } else {
                Text(reminderCountdown.isEmpty ? "You can send a reminder in 24 hours." : reminderCountdown)
                    .font(Font.bodySans(13, weight: .regular))
                    .foregroundColor(Color.textPrimary.opacity(0.55))
            }
            
            Button {
                access.require(.datePlan) {
                    coordinator.isPartnerPlanningInviter = true
                    coordinator.dismissSheet()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        coordinator.startDatePlanning(mode: .fresh)
                    }
                }
            } label: {
                Text("Fill my preferences")
                    .font(Font.bodySans(14, weight: .medium))
                    .foregroundColor(Color.textPrimary.opacity(0.8))
                    .underline()
            }
            .buttonStyle(.plain)

            Button {
                startNewInvite()
                viewingPendingSessionId = nil
            } label: {
                Text("Send another invite")
                    .font(Font.bodySans(14, weight: .medium))
                    .foregroundColor(Color.textPrimary.opacity(0.8))
                    .underline()
            }
            .buttonStyle(.plain)

            Button {
                cancelCurrentInvite()
                viewingPendingSessionId = nil
            } label: {
                Text("Cancel this invite")
                    .font(Font.bodySans(13, weight: .medium))
                    .foregroundColor(Color.textPrimary.opacity(0.5))
            }
            .buttonStyle(.plain)

            // MARK: Safety (Apple §1.2)
            Divider()
                .background(Color.luxeSurfaceTintStrong)
                .padding(.horizontal, 40)
                .padding(.top, 8)

            Button(role: .destructive) {
                showingUnlinkConfirmation = true
            } label: {
                Label("Block & Unlink Partner", systemImage: "person.crop.circle.badge.xmark")
                    .font(Font.bodySans(13, weight: .medium))
                    .foregroundColor(Color.red.opacity(0.85))
            }
            .buttonStyle(.plain)

            Button {
                showingReportSheet = true
            } label: {
                Label("Report a Concern", systemImage: "exclamationmark.bubble")
                    .font(Font.bodySans(13, weight: .medium))
                    .foregroundColor(Color.luxuryCreamMuted)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.surfaceElevated)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.luxeSurfaceTint, lineWidth: 1)
                )
        )
        .alert("Block & Unlink Partner?", isPresented: $showingUnlinkConfirmation) {
            Button("Block & Unlink", role: .destructive) { blockAndUnlinkCurrentPartner() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will cancel the current session and prevent this partner from sending you future invites.")
        }
        .sheet(isPresented: $showingReportSheet) {
            ReportConcernView()
        }
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

// MARK: - Invited success celebration (confetti + Done)
private struct InvitedSuccessCelebrationView: View {
    let onDone: () -> Void

    private let colors: [Color] = [
        Color.luxuryGold,
        Color.luxuryGoldLight,
        Color.luxuryCream,
        Color.luxuryMaroonLight,
        Color.luxuryGoldDark
    ]

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var confettiPieces: [InvitedConfettiPiece] = []
    @State private var hasAnimated = false

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            ZStack {
                if !reduceMotion {
                    ForEach(confettiPieces) { piece in
                        RoundedRectangle(cornerRadius: 1)
                            .fill(piece.color)
                            .frame(width: piece.w, height: piece.h)
                            .rotationEffect(.degrees(piece.rotation))
                            .position(x: piece.x, y: piece.y)
                            .opacity(piece.opacity)
                    }
                    .accessibilityHidden(true)
                }

                VStack(spacing: 24) {
                    Spacer()
                    Text("Invited!")
                        .font(Font.displaySerif(48, weight: .bold))
                        .foregroundColor(Color.textPrimary)
                    Text("Your partner can open the link to add their preferences.")
                        .font(Font.bodySans(15, weight: .regular))
                        .foregroundColor(Color.textPrimary.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                    Button {
                        onDone()
                    } label: {
                        Text("Done")
                            .font(Font.bodySans(16, weight: .semibold))
                            .foregroundColor(Color.backgroundPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.accentGold)
                            .cornerRadius(16)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 40)
                    .padding(.top, 8)
                    Spacer()
                }
            }
            .onAppear {
                guard !hasAnimated else { return }
                hasAnimated = true
                guard !reduceMotion else { return }
                spawnConfetti(in: size)
                animateConfetti(in: size)
            }
        }
    }

    private func spawnConfetti(in size: CGSize) {
        var pieces: [InvitedConfettiPiece] = []
        for i in 0..<45 {
            pieces.append(InvitedConfettiPiece(
                id: i,
                x: CGFloat.random(in: 0...size.width),
                y: -CGFloat.random(in: 10...40),
                w: CGFloat.random(in: 4...10),
                h: CGFloat.random(in: 3...7),
                color: colors.randomElement() ?? Color.luxuryGold,
                rotation: 0,
                opacity: 0.95
            ))
        }
        confettiPieces = pieces
    }

    private func animateConfetti(in size: CGSize) {
        let duration = 2.2
        withAnimation(.easeIn(duration: duration)) {
            for i in confettiPieces.indices {
                confettiPieces[i].y = size.height + CGFloat.random(in: 20...80)
                confettiPieces[i].x += CGFloat.random(in: -60...60)
                confettiPieces[i].rotation = Double.random(in: 180...720)
            }
        }
        withAnimation(.easeOut(duration: 0.4).delay(duration * 0.7)) {
            for i in confettiPieces.indices {
                confettiPieces[i].opacity = 0.5
            }
        }
    }
}

private struct InvitedConfettiPiece: Identifiable {
    let id: Int
    var x: CGFloat
    var y: CGFloat
    let w: CGFloat
    let h: CGFloat
    let color: Color
    var rotation: Double
    var opacity: Double
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
                .foregroundColor(Color.textPrimary.opacity(0.6))
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(Color.textPrimary.opacity(0.5))
                    .frame(width: 20)
                TextField("", text: $text, prompt: Text(placeholder).foregroundColor(Color.textPrimary.opacity(0.35)))
                    .font(Font.bodySans(16, weight: .regular))
                    .foregroundColor(Color.textPrimary)
                    .keyboardType(keyboardType)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.surfaceElevated)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(text.isEmpty ? Color.luxeSurfaceBorder : Color.luxeSurfaceTintStrong, lineWidth: 1)
            )
        }
    }
}

// MARK: - Spinning ring animation

struct WaitingRingView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var rotation: Double = 0
    var body: some View {
        Circle()
            .trim(from: 0, to: 0.7)
            .stroke(Color.luxuryGold, style: StrokeStyle(lineWidth: 2, lineCap: .round))
            .frame(width: 80, height: 80)
            .rotationEffect(.degrees(rotation))
            .accessibilityHidden(true)
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            }
    }
}

// MARK: - Previews

#Preview("Plan Together") {
    NavigationStack {
        PartnerPlanningSheetView()
            .environmentObject(NavigationCoordinator.shared)
    }
}

#Preview("Waiting ring") {
    ZStack {
        Color.backgroundPrimary.ignoresSafeArea()
        WaitingRingView()
    }
}

// MARK: - Partner Tutorial Banner

private struct PartnerTutorialBannerView: View {
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "person.2.fill")
                    .foregroundColor(Color.accentMaroon)
                Text("How Plan Together works")
                    .font(Font.bodySans(15, weight: .semibold))
                    .foregroundColor(Color.textPrimary)
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color.textPrimary.opacity(0.5))
                        .frame(width: 28, height: 28)
                        .background(Color.luxeSurfaceTint)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Dismiss tutorial")
            }

            VStack(alignment: .leading, spacing: 10) {
                TutorialStep(number: "1", text: "Enter your partner's name — no email needed")
                TutorialStep(number: "2", text: "Share the link via Messages, WhatsApp, or any app")
                TutorialStep(number: "3", text: "You both answer questions separately, then we reveal the best matching date")
            }
        }
        .padding(16)
        .background(Color.surfaceElevated)
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.luxeSurfaceBorder, lineWidth: 1))
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
}

private struct TutorialStep: View {
    let number: String
    let text: String
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle().fill(Color.accentMaroon).frame(width: 22, height: 22)
                Text(number)
                    .font(Font.bodySans(12, weight: .bold))
                    .foregroundColor(Color.textPrimary)
            }
            Text(text)
                .font(Font.bodySans(14, weight: .regular))
                .foregroundColor(Color.textPrimary.opacity(0.6))
            Spacer()
        }
    }
}

