import SwiftUI
import Combine

struct QuestionnaireView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var coordinator: NavigationCoordinator
    @EnvironmentObject private var access: AccessManager
    @StateObject private var viewModel = QuestionnaireViewModel()
    @ObservedObject private var generator = DatePlanGeneratorService.shared
    @State private var isGenerating = false
    @State private var showError = false
    @State private var errorTitle = "Generation Error"
    @State private var errorMessage = ""
    @State private var showRetryOption = true
    @State private var showPremiumPaywall = false
    /// True while editing preferences from Profile — avoids stale `LastQuestionnaireStore` and resume-store noise.
    @State private var sessionIsPreferencesOnlyEdit = false
    @State private var showSavedIndicator = false
    @State private var generationTask: Task<Void, Never>?
    
    var onComplete: ((QuestionnaireData) -> Void)?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.ydgBase
                    .ignoresSafeArea()

                // Keep questionnaire mounted — swapping the whole tree on tap crashes SwiftUI on device.
                VStack(spacing: 0) {
                    StepProgressView(currentStep: viewModel.currentStep, totalSteps: 6)
                        .padding(.horizontal, YDGSpace.margin)
                        .padding(.top, YDGSpace.xxs)

                    Text(viewModel.stepHeadline)
                        .ydgText(.title1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, YDGSpace.margin)
                        .padding(.top, YDGSpace.sm)
                        .padding(.bottom, YDGSpace.xxs)
                        .accessibilityAddTraits(.isHeader)
                        .id(viewModel.currentStep)

                    Group {
                        switch viewModel.currentStep {
                        case 1:
                            Step1LocationView(data: $viewModel.data, isPreferencesOnly: coordinator.questionnairePreferencesOnly)
                        case 2:
                            Step2TransportationView(data: $viewModel.data)
                        case 3:
                            Step3VibeView(data: $viewModel.data, isPreferencesOnly: coordinator.questionnairePreferencesOnly)
                        case 4:
                            Step4FoodView(data: $viewModel.data)
                        case 5:
                            Step5DealBreakersView(data: $viewModel.data, isPreferencesOnly: coordinator.questionnairePreferencesOnly)
                        case 6:
                            Step6ExtrasView(data: $viewModel.data, isPreferencesOnly: coordinator.questionnairePreferencesOnly)
                        default:
                            Step1LocationView(data: $viewModel.data, isPreferencesOnly: coordinator.questionnairePreferencesOnly)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)

                    navigationButtons
                }
                .opacity(isGenerating ? 0 : 1)
                .allowsHitTesting(!isGenerating)

                if isGenerating {
                    MagicalLoadingView(generator: generator) {
                        cancelGeneration()
                    }
                    .transition(.opacity)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !isGenerating {
                    ToolbarItem(placement: .principal) {
                        Text(viewModel.stepTitle)
                            .font(Font.ydgSans(15, weight: .semibold))
                            .foregroundColor(Color.ydgTextSecondary)
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            closeQuestionnaireTapped()
                        } label: {
                            Text("Save & exit")
                                .font(Font.ydgSans(16, weight: .semibold))
                                .foregroundColor(Color.ydgAccent)
                                .frame(minHeight: 44)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Save progress and exit")
                    }
                }
            }
            .toolbarBackground(Color.ydgBase, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .sheet(isPresented: $showPremiumPaywall) {
                PremiumDatePlanPaywallView {
                    // Dismiss paywall, then continue generation on the same main-actor turn as the successful purchase/restore.
                    Task { @MainActor in
                        showPremiumPaywall = false
                        generateDatePlan()
                    }
                }
            }
            .alert(errorTitle, isPresented: $showError) {
                if showRetryOption {
                    Button("Try Again") {
                        requestGenerateDatePlan()
                    }
                }
                Button("Cancel", role: .cancel) {
                    isGenerating = false
                }
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                viewModel.isPreferencesOnly = coordinator.questionnairePreferencesOnly
                switch coordinator.planIntent {
                case .fresh, .prefilled:
                    QuestionnaireProgressStore.clear()
                    viewModel.data = QuestionnaireData()
                    UserProfileManager.shared.applySavedPreferences(to: &viewModel.data)
                    viewModel.currentStep = 1
                case .startFresh:
                    QuestionnaireProgressStore.clear()
                    viewModel.data = QuestionnaireData()
                    viewModel.currentStep = 1
                case .useLast:
                    if coordinator.questionnairePreferencesOnly {
                        sessionIsPreferencesOnlyEdit = true
                        // Profile → Edit: must use saved account preferences, not LastQuestionnaireStore (stale draft).
                        QuestionnaireProgressStore.clear()
                        viewModel.data = QuestionnaireData()
                        UserProfileManager.shared.applySavedPreferences(to: &viewModel.data)
                        viewModel.currentStep = 1
                    } else {
                        sessionIsPreferencesOnlyEdit = false
                        if let last = LastQuestionnaireStore.load() {
                            viewModel.data = last
                            viewModel.currentStep = 1
                        }
                    }
                case .repeatLast:
                    sessionIsPreferencesOnlyEdit = false
                    if let last = LastQuestionnaireStore.load() {
                        viewModel.data = last
                        viewModel.currentStep = 1
                    } else {
                        QuestionnaireProgressStore.clear()
                        viewModel.data = QuestionnaireData()
                        UserProfileManager.shared.applySavedPreferences(to: &viewModel.data)
                        viewModel.currentStep = 1
                    }
                case .resume:
                    if let loaded = QuestionnaireProgressStore.load() {
                        viewModel.data = loaded.data
                        viewModel.currentStep = loaded.step
                    }
                }
            }
            .onChange(of: viewModel.currentStep) { _, _ in
                if !coordinator.planIntent.skipsProgressAutoSave && !sessionIsPreferencesOnlyEdit {
                    QuestionnaireProgressStore.save(data: viewModel.data, step: viewModel.currentStep)
                }
                flashSavedIndicator()
            }
            .onDisappear {
                if isGenerating {
                    generationTask?.cancel()
                    generationTask = nil
                    generator.cancelGeneration()
                }
                let prefsOnly = sessionIsPreferencesOnlyEdit
                if prefsOnly {
                    sessionIsPreferencesOnlyEdit = false
                }
                if !coordinator.planIntent.skipsProgressAutoSave && !isGenerating && !prefsOnly {
                    QuestionnaireProgressStore.save(data: viewModel.data, step: viewModel.currentStep)
                }
                if !coordinator.isPresentingInitialPreferencesFlow {
                    coordinator.questionnairePreferencesOnly = false
                }
            }
        }
    }
    
    /// Dismiss or defer: initial prefs → main tabs; preferences sheet → dismiss; plan questionnaire → dismiss sheet.
    private func closeQuestionnaireTapped() {
        if coordinator.isPresentingInitialPreferencesFlow {
            coordinator.deferInitialPreferences()
            return
        }
        if coordinator.questionnairePreferencesOnly {
            coordinator.questionnairePreferencesOnly = false
            coordinator.dismissSheet()
            dismiss()
            return
        }
        coordinator.dismissSheet()
        dismiss()
    }
    
    private var navigationButtons: some View {
        VStack(spacing: YDGSpace.xs) {
            HStack(spacing: 6) {
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .bold))
                Text("Progress saved")
                    .font(Font.ydgSans(12, weight: .medium))
            }
            .foregroundColor(Color.ydgSuccess)
            .opacity(showSavedIndicator ? 1 : 0)
            .animation(.easeInOut(duration: 0.3), value: showSavedIndicator)
            .accessibilityHidden(!showSavedIndicator)

            if showsFullWidthGenerateFooter {
                VStack(spacing: YDGSpace.xxs) {
                    Button {
                        requestGenerateDatePlan()
                    } label: {
                        Label("Plan my date", systemImage: "sparkles")
                    }
                    .buttonStyle(.ydgPrimary)

                    HStack(spacing: YDGSpace.lg) {
                        Button("Back") {
                            withAnimation { viewModel.previousStep() }
                        }
                        .buttonStyle(.ydgTertiary)

                        Button("Save and go home") {
                            goToHomeFromQuestionnaire()
                        }
                        .buttonStyle(.ydgTertiary)
                    }
                }
            } else {
                HStack(spacing: YDGSpace.sm) {
                    if viewModel.currentStep > 1 {
                        Button {
                            withAnimation { viewModel.previousStep() }
                        } label: {
                            Image(systemName: "chevron.left")
                                .accessibilityLabel("Back")
                        }
                        .buttonStyle(YDGButtonStyle(kind: .secondary, fullWidth: false))
                    }

                    Button {
                        if viewModel.currentStep == 6 {
                            if let sessionId = coordinator.partnerJoinSessionId {
                                submitPartnerJoinAndDismiss(sessionId: sessionId)
                            } else if coordinator.questionnairePreferencesOnly {
                                savePreferencesOnly()
                            } else if !UserProfileManager.shared.isLoggedIn {
                                coordinator.requireAuthForPlanGeneration(intent: coordinator.planIntent)
                            } else {
                                requestGenerateDatePlan()
                            }
                        } else {
                            withAnimation { viewModel.nextStep() }
                        }
                    } label: {
                        if viewModel.currentStep == 6 {
                            if coordinator.partnerJoinSessionId != nil {
                                Text("I'm in")
                            } else if coordinator.questionnairePreferencesOnly {
                                Text("Save preferences")
                            } else {
                                Label("Plan my date", systemImage: "sparkles")
                            }
                        } else {
                            Text("Continue")
                        }
                    }
                    .buttonStyle(.ydgPrimary)
                    .disabled(!viewModel.isCurrentStepValid)
                }
            }
        }
        .padding(.horizontal, YDGSpace.margin)
        .padding(.top, YDGSpace.xxs)
        .padding(.bottom, YDGSpace.md)
        .background(
            Color.ydgBase
                .overlay(alignment: .top) {
                    Rectangle().fill(Color.ydgBorder).frame(height: 1)
                }
        )
    }

    /// Extras step in plan mode: full-width Generate (logged-in users only).
    private var showsFullWidthGenerateFooter: Bool {
        viewModel.currentStep == 6
            && coordinator.partnerJoinSessionId == nil
            && !coordinator.questionnairePreferencesOnly
            && UserProfileManager.shared.isLoggedIn
    }

    private func flashSavedIndicator() {
        showSavedIndicator = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { showSavedIndicator = false }
        }
    }

    private func goToHomeFromQuestionnaire() {
        var data = viewModel.data
        data.syncCityFromStartingAddress()
        viewModel.data = data
        LastQuestionnaireStore.save(data)
        QuestionnaireProgressStore.clear()
        UserProfileManager.shared.savePreferencesFromQuestionnaire(data)
        let finishingInitialPrefs = coordinator.isPresentingInitialPreferencesFlow
        if finishingInitialPrefs {
            coordinator.isPresentingInitialPreferencesFlow = false
            coordinator.completePreferences()
        }
        coordinator.currentTab = .home
        coordinator.questionnairePreferencesOnly = false
        if finishingInitialPrefs {
            // Root view replaces InitialPreferencesGateView — do not dismiss (crashes).
            return
        }
        coordinator.dismissSheet()
        dismiss()
    }
    
    private func savePreferencesOnly() {
        var data = viewModel.data
        data.syncCityFromStartingAddress()
        viewModel.data = data
        LastQuestionnaireStore.save(data)
        QuestionnaireProgressStore.clear()
        UserProfileManager.shared.savePreferencesFromQuestionnaire(data)
        let finishingInitialPrefs = coordinator.isPresentingInitialPreferencesFlow
        if finishingInitialPrefs {
            coordinator.isPresentingInitialPreferencesFlow = false
            coordinator.completePreferences()
            // Root view transition handles teardown — dismiss() here crashes.
            return
        }
        coordinator.questionnairePreferencesOnly = false
        coordinator.activeSheet = nil
        dismiss()
    }

    private func submitPartnerJoinAndDismiss(sessionId: String) {
        LastQuestionnaireStore.save(viewModel.data)
        QuestionnaireProgressStore.clear()
        PartnerSessionManager.shared.submitPartnerData(sessionId: sessionId, data: viewModel.data)
        coordinator.partnerJoinSessionId = nil
        dismiss()
        // Route partner to generating screen so they can track progress
        coordinator.activeSheet = .planGenerating(sessionId: sessionId, role: .partner)
    }
    
    /// Presents the premium paywall when needed, then runs generation (signed-in users only).
    private func requestGenerateDatePlan() {
        guard UserProfileManager.shared.isLoggedIn else {
            coordinator.requireAuthForPlanGeneration(intent: coordinator.planIntent)
            return
        }
        guard access.canGenerateDatePlan() else {
            showPremiumPaywall = true
            return
        }
        generateDatePlan()
    }

    /// Plans arrived — hand off to coordinator. Never call `dismiss()` here; sheet transitions
    /// are owned by `completeQuestionnaire` (same crash class as save-preferences on root gate).
    private func handleGenerationSuccess(plans: [DatePlan]) {
        guard isGenerating else { return }
        guard !plans.isEmpty else { return }

        generationTask = nil
        isGenerating = false

        let questionnaireData = viewModel.data
        let finishingInitialPrefs = coordinator.isPresentingInitialPreferencesFlow

        // Defer ObservableObject publishes — mutating @Published during the button-tap /
        // view-update cycle crashes on main thread ("Publishing changes from within view updates").
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 100_000_000)
            generator.generatedPlans = plans
            coordinator.generatedPlans = plans
            coordinator.generatedPlansSelectedIndex = 0
            coordinator.currentDatePlan = plans.first
            LastQuestionnaireStore.save(questionnaireData)
            UserProfileManager.shared.savePreferencesFromQuestionnaire(questionnaireData)
            access.recordDatePlanGenerated()
            QuestionnaireProgressStore.clear()
            if finishingInitialPrefs {
                coordinator.isPresentingInitialPreferencesFlow = false
                coordinator.completePreferences()
            }
            try? await Task.sleep(nanoseconds: 200_000_000)
            onComplete?(questionnaireData)
        }
    }

    private func cancelGeneration() {
        generationTask?.cancel()
        generationTask = nil
        generator.cancelGeneration()
        isGenerating = false
    }

    private func generateDatePlan() {
        guard NetworkMonitor.shared.isConnected else {
            errorTitle = "No Internet Connection"
            errorMessage = "Please check your connection and try again."
            showRetryOption = true
            showError = true
            return
        }
        let address = viewModel.data.startingAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !address.isEmpty else {
            errorTitle = "Starting address required"
            errorMessage = "Go back to Step 1 and enter where you're leaving from so we can build your route."
            showRetryOption = false
            showError = true
            return
        }

        generationTask?.cancel()
        // Only flip local UI state synchronously — mutating ObservableObjects here crashes on main thread.
        isGenerating = true

        var questionnaireData = viewModel.data
        questionnaireData.syncCityFromStartingAddress()

        generationTask = Task { @MainActor in
            await Task.yield()
            try? await Task.sleep(nanoseconds: 80_000_000)
            viewModel.data = questionnaireData
            generator.error = nil
            generator.generatedPlans = []
            LastQuestionnaireStore.save(questionnaireData)
            QuestionnaireProgressStore.clear()
            do {
                let plans = try await generator.generateDatePlan(from: questionnaireData)
                guard !Task.isCancelled else { return }
                guard !plans.isEmpty else {
                    isGenerating = false
                    errorTitle = "Invalid Response"
                    errorMessage = "The server returned no date plans. Please try again."
                    showRetryOption = true
                    showError = true
                    return
                }
                handleGenerationSuccess(plans: plans)
            } catch is CancellationError {
                generator.cancelGeneration()
                isGenerating = false
            } catch {
                isGenerating = false
                if let genError = error as? DatePlanGeneratorService.GenerationError {
                    handleGenerationError(genError)
                } else if let supabaseError = error as? SupabaseError, case .unauthorized = supabaseError {
                    errorTitle = "Authentication Error"
                    errorMessage = "Your session expired. Please sign in again and try generating."
                    showRetryOption = false
                    showError = true
                } else {
                    errorTitle = "Error"
                    errorMessage = error.localizedDescription
                    showRetryOption = true
                    showError = true
                }
            }
        }
    }
    
    private func handleGenerationError(_ error: DatePlanGeneratorService.GenerationError) {
        isGenerating = false
        switch error {
        case .missingAPIKey:
            errorTitle = "Configuration Error"
            errorMessage = "Supabase is not configured. Please check that SUPABASE_URL and SUPABASE_ANON_KEY are set in ios/Secrets.xcconfig and rebuild the app."
            showRetryOption = false
            
        case .timeout:
            errorTitle = "Still Working"
            errorMessage = "This one took longer than expected. Stay on Wi‑Fi and tap Try Again — your answers are saved."
            showRetryOption = true
            
        case .networkError:
            errorTitle = "Connection Interrupted"
            errorMessage = "The plan was still generating but the connection dropped. Stay on Wi‑Fi, keep the app open, and tap Try Again — we automatically retry once."
            showRetryOption = true
            
        case .apiError(let msg):
            if msg.contains("401") {
                errorTitle = "Authentication Error"
                errorMessage = "Session expired. Please sign in again."
                showRetryOption = false
            } else if msg.contains("429") {
                errorTitle = "Rate Limited"
                errorMessage = "Too many requests. Please wait a moment and try again."
                showRetryOption = true
            } else if msg.contains("500") || msg.contains("502") || msg.contains("503") {
                errorTitle = "Server Error"
                errorMessage = "AI service temporarily unavailable. Please try again in a few moments."
                showRetryOption = true
            } else {
                errorTitle = "API Error"
                errorMessage = msg
                showRetryOption = true
            }
            
        case .parsingError:
            errorTitle = "Response Error"
            errorMessage = "We received an unexpected response from the AI. Please try again."
            showRetryOption = true
            
        case .invalidResponse:
            errorTitle = "Invalid Response"
            errorMessage = "The AI returned an invalid response. Please try again."
            showRetryOption = true

        case .unauthorized:
            errorTitle = "Sign In Required"
            errorMessage = "Please sign in to generate date plans."
            showRetryOption = false

        case .rateLimited:
            errorTitle = "Too Many Requests"
            errorMessage = "You've made too many requests. Please wait a minute and try again."
            showRetryOption = true
        }
        
        showError = true
    }
}

// MARK: - Step Progress View
struct StepProgressView: View {
    let currentStep: Int
    let totalSteps: Int
    
    var body: some View {
        HStack(spacing: YDGSpace.sm) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.ydgBorder)
                    Capsule()
                        .fill(Color.ydgAccent)
                        .frame(width: geometry.size.width * CGFloat(currentStep) / CGFloat(totalSteps))
                        .animation(.easeInOut(duration: 0.3), value: currentStep)
                }
            }
            .frame(height: 4)

            Text("\(currentStep) of \(totalSteps)")
                .font(Font.ydgSans(13, weight: .medium))
                .foregroundColor(Color.ydgTextSecondary)
                .monospacedDigit()
        }
        .padding(.vertical, YDGSpace.xs)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Step \(currentStep) of \(totalSteps)")
    }
}

// MARK: - ViewModel
class QuestionnaireViewModel: ObservableObject {
    @Published var currentStep = 1
    @Published var data = QuestionnaireData()
    var isPreferencesOnly: Bool = false
    
    init() {
        prePopulateFromSavedPreferences()
    }
    
    /// Large question shown at the top of each step (Final design).
    var stepHeadline: String {
        switch currentStep {
        case 1: return isPreferencesOnly ? "Where are you based?" : "Where are you planning?"
        case 2: return "How are you getting around?"
        case 3: return "What's the energy?"
        case 4: return "Food & drinks"
        case 5: return "Any deal-breakers?"
        case 6: return "A few extras"
        default: return ""
        }
    }

    var stepTitle: String {
        switch currentStep {
        case 1: return isPreferencesOnly ? "Your Location" : "Location & Date Type"
        case 2: return "Getting Around"
        case 3: return "Vibe & Energy"
        case 4: return "Food & Drinks"
        case 5: return "Deal Breakers"
        case 6: return "Extras"
        default: return ""
        }
    }
    
    var isCurrentStepValid: Bool {
        switch currentStep {
        case 1:
            let addressOk = !data.startingAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            return isPreferencesOnly ? addressOk : (addressOk && !data.dateType.isEmpty)
        case 2: return !data.transportationMode.isEmpty && !data.travelRadius.isEmpty
        case 3: return !data.energyLevel.isEmpty
        case 4: return !data.budgetRange.isEmpty
        case 5: return true
        case 6: return true
        default: return true
        }
    }
    
    func nextStep() {
        if currentStep < 6 {
            currentStep += 1
        }
    }
    
    func previousStep() {
        if currentStep > 1 {
            currentStep -= 1
        }
    }
    
    private func prePopulateFromSavedPreferences() {
        UserProfileManager.shared.applySavedPreferences(to: &data)
    }
}

// MARK: - Preview
#Preview {
    QuestionnaireView()
        .environmentObject(NavigationCoordinator.shared)
        .environmentObject(AccessManager.shared)
}
