import SwiftUI
import Combine

struct QuestionnaireView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = QuestionnaireViewModel()
    
    var onComplete: ((QuestionnaireData) -> Void)?
    
    var body: some View {
        NavigationStack {
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
            .background(Color.brandCream)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.brandPrimary)
                }
                
                ToolbarItem(placement: .principal) {
                    Text(viewModel.stepTitle)
                        .font(.headline)
                        .foregroundColor(.brandPrimary)
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
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.brandPrimary)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.brandPrimary.opacity(0.3), lineWidth: 1)
                    )
                }
            } else {
                Spacer()
            }
            
            // Next/Submit button
            Button {
                if viewModel.currentStep == 6 {
                    onComplete?(viewModel.data)
                    dismiss()
                } else {
                    withAnimation {
                        viewModel.nextStep()
                    }
                }
            } label: {
                HStack {
                    if viewModel.currentStep == 6 {
                        Image(systemName: "sparkles")
                        Text("Create Plan")
                    } else {
                        Text("Next")
                        Image(systemName: "chevron.right")
                    }
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: viewModel.currentStep == 1 ? .infinity : nil)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(
                    viewModel.isCurrentStepValid
                        ? LinearGradient.goldGradient
                        : LinearGradient(colors: [Color.gray.opacity(0.5)], startPoint: .leading, endPoint: .trailing)
                )
                .cornerRadius(12)
                .shadow(color: viewModel.isCurrentStepValid ? Color.brandGold.opacity(0.4) : .clear, radius: 8, y: 4)
            }
            .disabled(!viewModel.isCurrentStepValid)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.white)
    }
}

// MARK: - Step Progress View
struct StepProgressView: View {
    let currentStep: Int
    let totalSteps: Int
    
    private let stepLabels = ["Location", "Travel", "Vibe", "Food", "Avoid", "Extras"]
    
    var body: some View {
        VStack(spacing: 8) {
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 4)
                        .cornerRadius(2)
                    
                    Rectangle()
                        .fill(LinearGradient.goldGradient)
                        .frame(width: geometry.size.width * CGFloat(currentStep) / CGFloat(totalSteps), height: 4)
                        .cornerRadius(2)
                        .animation(.easeInOut(duration: 0.3), value: currentStep)
                }
            }
            .frame(height: 4)
            
            // Step indicators
            HStack {
                ForEach(1...totalSteps, id: \.self) { step in
                    VStack(spacing: 4) {
                        Circle()
                            .fill(step <= currentStep ? Color.brandGold : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                        
                        if step == currentStep {
                            Text(stepLabels[step - 1])
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.brandPrimary)
                        }
                    }
                    
                    if step < totalSteps {
                        Spacer()
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - ViewModel
class QuestionnaireViewModel: ObservableObject {
    @Published var currentStep = 1
    @Published var data = QuestionnaireData()
    
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
}

// MARK: - Preview
#Preview {
    QuestionnaireView()
}
