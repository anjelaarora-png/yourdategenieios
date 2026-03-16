import SwiftUI
import Combine

struct QuestionnaireView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var coordinator: NavigationCoordinator
    @StateObject private var viewModel = QuestionnaireViewModel()
    @StateObject private var generator = DatePlanGeneratorService.shared
    @State private var isGenerating = false
    @State private var showError = false
    @State private var errorTitle = "Generation Error"
    @State private var errorMessage = ""
    @State private var showRetryOption = true
    
    var onComplete: ((QuestionnaireData) -> Void)?
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Luxurious background
                Color.luxuryMaroon
                    .ignoresSafeArea()
                
                if isGenerating {
                    MagicalLoadingView(generator: generator)
                } else {
                    VStack(spacing: 0) {
                        // Progress indicator
                        StepProgressView(currentStep: viewModel.currentStep, totalSteps: 6)
                            .padding(.horizontal)
                            .padding(.top, 8)
                        
                        // Step content
                        TabView(selection: $viewModel.currentStep) {
                            Step1LocationView(data: $viewModel.data)
                                .tag(1)
                            Step2TransportationView(data: $viewModel.data)
                                .tag(2)
                            Step3VibeView(data: $viewModel.data)
                                .tag(3)
                            Step4FoodView(data: $viewModel.data)
                                .tag(4)
                            Step5DealBreakersView(data: $viewModel.data)
                                .tag(5)
                            Step6ExtrasView(data: $viewModel.data, isPreferencesOnly: coordinator.questionnairePreferencesOnly)
                                .tag(6)
                        }
                        .tabViewStyle(.page(indexDisplayMode: .never))
                        .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)
                        
                        // Navigation buttons
                        navigationButtons
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !isGenerating {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            dismiss()
                        }
                        .font(Font.bodySans(16, weight: .medium))
                        .foregroundColor(Color.luxuryGold)
                    }
                    
                    ToolbarItem(placement: .principal) {
                        Text(viewModel.stepTitle)
                            .font(Font.tangerine(24, weight: .bold))
                            .italic()
                            .foregroundColor(Color.luxuryGold)
                    }
                }
            }
            .toolbarBackground(Color.luxuryMaroon, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .alert(errorTitle, isPresented: $showError) {
                if showRetryOption {
                    Button("Try Again") {
                        generateDatePlan()
                    }
                }
                Button("Cancel", role: .cancel) {
                    isGenerating = false
                }
            } message: {
                Text(errorMessage)
            }
            .onChange(of: generator.generatedPlans) { _, plans in
                if !plans.isEmpty && isGenerating {
                    LastQuestionnaireStore.save(viewModel.data)
                    onComplete?(viewModel.data)
                    dismiss()
                }
            }
            .onChange(of: generator.error) { _, error in
                if let error = error {
                    handleGenerationError(error)
                }
            }
            .onAppear {
                switch coordinator.planIntent {
                case .fresh:
                    QuestionnaireProgressStore.clear()
                    viewModel.data = QuestionnaireData()
                    viewModel.currentStep = 1
                case .useLast:
                    if let last = LastQuestionnaireStore.load() {
                        viewModel.data = last
                        viewModel.currentStep = 1
                    }
                    // ViewModel init already prefills from UserProfileManager; last data takes precedence
                case .resume:
                    if let loaded = QuestionnaireProgressStore.load() {
                        viewModel.data = loaded.data
                        viewModel.currentStep = loaded.step
                    }
                }
            }
            .onChange(of: viewModel.currentStep) { _, _ in
                if coordinator.planIntent != .fresh {
                    QuestionnaireProgressStore.save(data: viewModel.data, step: viewModel.currentStep)
                }
            }
            .onDisappear {
                if coordinator.planIntent != .fresh && !isGenerating {
                    QuestionnaireProgressStore.save(data: viewModel.data, step: viewModel.currentStep)
                }
                coordinator.questionnairePreferencesOnly = false
            }
        }
    }
    
    private var navigationButtons: some View {
        HStack(spacing: 16) {
            // Back button
            if viewModel.currentStep > 1 {
                Button {
                    withAnimation {
                        viewModel.previousStep()
                    }
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
            
            // Next/Submit button
            Button {
                if viewModel.currentStep == 6 {
                    if coordinator.questionnairePreferencesOnly {
                        savePreferencesOnly()
                    } else {
                        generateDatePlan()
                    }
                } else {
                    withAnimation {
                        viewModel.nextStep()
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    if viewModel.currentStep == 6 {
                        if coordinator.questionnairePreferencesOnly {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Save preferences")
                        } else {
                            Image(systemName: "sparkles")
                            Text("Create Plan")
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
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            Color.luxuryMaroon
                .shadow(color: Color.black.opacity(0.3), radius: 10, y: -5)
        )
    }
    
    private func savePreferencesOnly() {
        LastQuestionnaireStore.save(viewModel.data)
        QuestionnaireProgressStore.clear()
        UserProfileManager.shared.savePreferencesFromQuestionnaire(viewModel.data)
        coordinator.questionnairePreferencesOnly = false
        coordinator.activeSheet = nil
        dismiss()
    }
    
    private func generateDatePlan() {
        LastQuestionnaireStore.save(viewModel.data)
        QuestionnaireProgressStore.clear()
        withAnimation {
            isGenerating = true
        }
        
        Task {
            do {
                let _ = try await generator.generateDatePlan(from: viewModel.data)
            } catch {
                await MainActor.run {
                    if let genError = error as? DatePlanGeneratorService.GenerationError {
                        handleGenerationError(genError)
                    } else {
                        errorTitle = "Error"
                        errorMessage = error.localizedDescription
                        showRetryOption = true
                        showError = true
                    }
                }
            }
        }
    }
    
    private func handleGenerationError(_ error: DatePlanGeneratorService.GenerationError) {
        switch error {
        case .missingAPIKey:
            errorTitle = "API Key Required"
            errorMessage = "OpenAI API key is not configured.\n\nTo fix this:\n1. Open Xcode\n2. Go to Product > Scheme > Edit Scheme\n3. Select Run > Arguments\n4. Add OPENAI_API_KEY to Environment Variables\n5. Set its value to your OpenAI API key"
            showRetryOption = false
            
        case .networkError:
            errorTitle = "Network Error"
            errorMessage = "Unable to connect to the server. Please check your internet connection and try again."
            showRetryOption = true
            
        case .apiError(let msg):
            if msg.contains("401") {
                errorTitle = "Invalid API Key"
                errorMessage = "Your OpenAI API key appears to be invalid. Please verify your key at platform.openai.com."
                showRetryOption = false
            } else if msg.contains("429") {
                errorTitle = "Rate Limited"
                errorMessage = "Too many requests. Please wait a moment and try again."
                showRetryOption = true
            } else if msg.contains("500") || msg.contains("502") || msg.contains("503") {
                errorTitle = "Server Error"
                errorMessage = "OpenAI's servers are temporarily unavailable. Please try again in a few moments."
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
    
    init() {
        prePopulateFromSavedPreferences()
    }
    
    var stepTitle: String {
        switch currentStep {
        case 1: return "Location & Date Type"
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
        case 1: return !data.city.isEmpty && !data.startingAddress.isEmpty && !data.dateType.isEmpty
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
        UserProfileManager.shared.prePopulateQuestionnaireData(&data)
    }
}

// MARK: - Preview
#Preview {
    QuestionnaireView()
        .environmentObject(NavigationCoordinator.shared)
}
