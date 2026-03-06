import SwiftUI
import Combine

struct QuestionnaireView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = QuestionnaireViewModel()
    @StateObject private var generator = DatePlanGeneratorService.shared
    @State private var isGenerating = false
    @State private var showError = false
    
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
                            Step6ExtrasView(data: $viewModel.data)
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
                            .font(Font.subheader(17, weight: .semibold))
                            .foregroundColor(Color.luxuryGold)
                    }
                }
            }
            .toolbarBackground(Color.luxuryMaroon, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .alert("Generation Error", isPresented: $showError) {
                Button("Try Again") {
                    generateDatePlan()
                }
                Button("Cancel", role: .cancel) {
                    isGenerating = false
                }
            } message: {
                Text(generator.error?.localizedDescription ?? "Something went wrong. Please try again.")
            }
            .onChange(of: generator.generatedPlans) { plans in
                if !plans.isEmpty && isGenerating {
                    onComplete?(viewModel.data)
                    dismiss()
                }
            }
            .onChange(of: generator.error) { error in
                if error != nil {
                    showError = true
                }
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
                    generateDatePlan()
                } else {
                    withAnimation {
                        viewModel.nextStep()
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    if viewModel.currentStep == 6 {
                        Image(systemName: "sparkles")
                        Text("Create Plan")
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
    
    private func generateDatePlan() {
        withAnimation {
            isGenerating = true
        }
        
        Task {
            do {
                let _ = try await generator.generateDatePlan(from: viewModel.data)
            } catch {
                await MainActor.run {
                    showError = true
                }
            }
        }
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
        case 1: return !data.city.isEmpty && !data.dateType.isEmpty
        case 2: return !data.transportationMode.isEmpty && !data.travelRadius.isEmpty
        case 3: return !data.energyLevel.isEmpty && !data.timeOfDay.isEmpty
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
}
