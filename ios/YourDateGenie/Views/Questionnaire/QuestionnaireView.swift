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
                Color.backgroundPrimary
                    .ignoresSafeArea()

                // Keep questionnaire mounted — swapping the whole tree on tap crashes SwiftUI on device.
                VStack(spacing: 0) {
                    StepProgressView(currentStep: viewModel.currentStep, totalSteps: 6)
                        .padding(.horizontal)
                        .padding(.top, 8)

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
                            .font(Font.bodySerif(20, weight: .regular))
                            .foregroundColor(Color.accentGold)
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            closeQuestionnaireTapped()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.circle")
                                    .font(.system(size: 14, weight: .medium))
                                Text("Save & Exit")
                                    .font(Font.inter(14, weight: .medium))
                            }
                            .foregroundColor(Color.luxuryGold)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.luxuryMaroonLight.opacity(0.8))
                            .cornerRadius(20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.luxuryGold.opacity(0.4), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Save progress and exit")
                    }
                }
            }
            .toolbarBackground(Color.backgroundPrimary, for: .navigationBar)
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
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(Color.luxurySuccess)
                Text("Progress saved")
                    .font(Font.bodySans(12, weight: .regular))
                    .foregroundColor(Color.luxurySuccess)
            }
            .opacity(showSavedIndicator ? 1 : 0)
            .animation(.easeInOut(duration: 0.3), value: showSavedIndicator)
            .padding(.top, 6)

            if showsFullWidthGenerateFooter {
                VStack(spacing: 10) {
                    Button {
                        requestGenerateDatePlan()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                            Text("Generate Date Plan")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(LuxuryGoldButtonStyle(isSmall: true))

                    HStack(spacing: 12) {
                        Button {
                            withAnimation { viewModel.previousStep() }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "chevron.left")
                                Text("Back")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(LuxuryOutlineButtonStyle(isSmall: true))

                        Button {
                            goToHomeFromQuestionnaire()
                        } label: {
                            Text("Go to Home")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(LuxuryOutlineButtonStyle(isSmall: true))
                    }
                }
            } else {
                HStack(spacing: 16) {
                    if viewModel.currentStep > 1 {
                        Button {
                            withAnimation { viewModel.previousStep() }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "chevron.left")
                                Text("Back")
                            }
                        }
                        .buttonStyle(LuxuryOutlineButtonStyle(isSmall: true))
                    } else {
                        Spacer()
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
                        HStack(spacing: 8) {
                            if viewModel.currentStep == 6 {
                                if coordinator.partnerJoinSessionId != nil {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("I'm in")
                                } else if coordinator.questionnairePreferencesOnly {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Save preferences")
                                } else {
                                    Image(systemName: "sparkles")
                                    Text("Generate Date Plan")
                                }
                            } else {
                                Text("Next")
                                Image(systemName: "chevron.right")
                            }
                        }
                        .frame(maxWidth: viewModel.currentStep == 1 ? .infinity : nil)
                    }
                    .buttonStyle(LuxuryGoldButtonStyle(isSmall: true))
                    .disabled(!viewModel.isCurrentStepValid)
                    .opacity(viewModel.isCurrentStepValid ? 1 : 0.5)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            Color.backgroundPrimary
                .shadow(color: Color.black.opacity(0.3), radius: 10, y: -5)
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
            
        case .networkError:
            errorTitle = "Network Error"
            errorMessage = "Unable to connect to the server. Please check your internet connection and try again."
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
            
        case .timeout:
            errorTitle = "Request Timed Out"
            errorMessage = "The request took too long to complete. This might be due to high server load. Please try again."
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
    
    private let stepLabels = ["Location", "Travel", "Vibe", "Food", "Avoid", "Extras"]
    
    var body: some View {
        VStack(spacing: 12) {
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.luxuryMuted.opacity(0.3))
                        .frame(height: 4)
                        .cornerRadius(2)
                    
                    Rectangle()
                        .fill(LinearGradient.goldShimmer)
                        .frame(width: geometry.size.width * CGFloat(currentStep) / CGFloat(totalSteps), height: 4)
                        .cornerRadius(2)
                        .animation(.easeInOut(duration: 0.3), value: currentStep)
                }
            }
            .frame(height: 4)
            
            // Step indicators
            HStack {
                ForEach(1...totalSteps, id: \.self) { step in
                    VStack(spacing: 6) {
                        ZStack {
                            Circle()
                                .fill(step <= currentStep ? Color.luxuryGold : Color.luxuryMuted.opacity(0.3))
                                .frame(width: 10, height: 10)
                            
                            if step < currentStep {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 6, weight: .bold))
                                    .foregroundColor(Color.luxuryMaroon)
                            }
                        }
                        
                        if step == currentStep {
                            Text(stepLabels[step - 1])
                                .font(Font.inter(10, weight: .medium))
                                .foregroundColor(Color.luxuryGold)
                        }
                    }
                    
                    if step < totalSteps {
                        Spacer()
                    }
                }
            }
        }
        .padding(.vertical, 12)
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
