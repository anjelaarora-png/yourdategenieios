import SwiftUI
import Combine

struct SignUpView: View {
    @EnvironmentObject var coordinator: NavigationCoordinator
    @StateObject private var viewModel = SignUpViewModel()
    @FocusState private var focusedField: SignUpField?
    
    var body: some View {
        ZStack {
            Color.luxuryMaroon
                .ignoresSafeArea()
            
            RadialGradient.goldGlow
                .opacity(0.15)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                signUpHeader
                
                // Progress indicator
                SignUpProgressView(currentStep: viewModel.currentStep, totalSteps: 3)
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                
                // Step content
                TabView(selection: $viewModel.currentStep) {
                    SignUpBasicInfoStep(viewModel: viewModel, focusedField: $focusedField)
                        .tag(1)
                    SignUpContactStep(viewModel: viewModel, focusedField: $focusedField)
                        .tag(2)
                    SignUpLocationStep(viewModel: viewModel, focusedField: $focusedField)
                        .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)
                
                // Navigation buttons
                navigationButtons
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    focusedField = nil
                }
                .foregroundColor(Color.luxuryGold)
            }
        }
    }
    
    private var signUpHeader: some View {
        VStack(spacing: 12) {
            Image("Logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
            
            VStack(spacing: 8) {
                Text("Create Your Account")
                    .font(Font.tangerine(34, weight: .bold))
                    .italic()
                    .foregroundColor(Color.luxuryGold)
                HStack(spacing: 4) {
                    Text("to start planning ")
                        .font(Font.bodySans(14, weight: .regular))
                        .foregroundColor(Color.luxuryCreamMuted)
                    Text("magical")
                        .font(Font.tangerine(26, weight: .bold))
                        .italic()
                        .foregroundColor(Color.luxuryGold)
                    Text(" dates")
                        .font(Font.bodySans(14, weight: .regular))
                        .foregroundColor(Color.luxuryCreamMuted)
                }
            }
            .multilineTextAlignment(.center)
        }
        .padding(.top, 40)
        .padding(.horizontal, 24)
    }
    
    private var navigationButtons: some View {
        HStack(spacing: 16) {
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
            
            Button {
                if viewModel.currentStep == 3 {
                    viewModel.createAccount()
                    coordinator.completeSignUp()
                } else {
                    withAnimation {
                        viewModel.nextStep()
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    if viewModel.currentStep == 3 {
                        Image(systemName: "checkmark")
                        Text("Continue")
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
}

// MARK: - Progress View
struct SignUpProgressView: View {
    let currentStep: Int
    let totalSteps: Int
    
    private let stepLabels = ["About You", "Contact", "Location"]
    
    var body: some View {
        VStack(spacing: 12) {
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

// MARK: - Step 1: Basic Info
struct SignUpBasicInfoStep: View {
    @ObservedObject var viewModel: SignUpViewModel
    var focusedField: FocusState<SignUpField?>.Binding
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                HStack(spacing: 6) {
                    Text("Tell us about")
                        .font(Font.header(20, weight: .regular))
                        .foregroundColor(Color.luxuryCream)
                    Text("yourself")
                        .font(Font.tangerine(32, weight: .bold))
                        .italic()
                        .foregroundColor(Color.luxuryGold)
                }
                
                VStack(spacing: 20) {
                    LuxuryTextField(
                        title: "First Name",
                        placeholder: "Enter your first name",
                        text: $viewModel.firstName,
                        icon: "person.fill"
                    )
                    .focused(focusedField, equals: .firstName)
                    
                    LuxuryTextField(
                        title: "Last Name",
                        placeholder: "Enter your last name",
                        text: $viewModel.lastName,
                        icon: "person.fill"
                    )
                    .focused(focusedField, equals: .lastName)
                    
                    LuxuryDatePicker(
                        title: "Date of Birth",
                        date: $viewModel.dateOfBirth,
                        icon: "calendar"
                    )
                }
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 100)
        }
    }
}

// MARK: - Step 2: Contact
struct SignUpContactStep: View {
    @ObservedObject var viewModel: SignUpViewModel
    var focusedField: FocusState<SignUpField?>.Binding
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                HStack(spacing: 6) {
                    Text("How can we")
                        .font(Font.header(20, weight: .regular))
                        .foregroundColor(Color.luxuryCream)
                    Text("reach you?")
                        .font(Font.tangerine(32, weight: .bold))
                        .italic()
                        .foregroundColor(Color.luxuryGold)
                }
                
                Text("We'll use this to send you date reminders and plan updates")
                    .font(Font.bodySans(14, weight: .regular))
                    .foregroundColor(Color.luxuryMuted)
                
                VStack(spacing: 20) {
                    LuxuryTextField(
                        title: "Email Address",
                        placeholder: "your@email.com",
                        text: $viewModel.email,
                        icon: "envelope.fill",
                        keyboardType: .emailAddress,
                        autocapitalization: .never
                    )
                    .focused(focusedField, equals: .email)
                    
                    LuxuryTextField(
                        title: "Phone Number",
                        placeholder: "(555) 123-4567",
                        text: $viewModel.phoneNumber,
                        icon: "phone.fill",
                        keyboardType: .phonePad
                    )
                    .focused(focusedField, equals: .phone)
                }
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 100)
        }
    }
}

// MARK: - Step 3: Location
struct SignUpLocationStep: View {
    @ObservedObject var viewModel: SignUpViewModel
    var focusedField: FocusState<SignUpField?>.Binding
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                HStack(spacing: 6) {
                    Text("Where are you")
                        .font(Font.header(20, weight: .regular))
                        .foregroundColor(Color.luxuryCream)
                    Text("based?")
                        .font(Font.tangerine(32, weight: .bold))
                        .italic()
                        .foregroundColor(Color.luxuryGold)
                }
                
                Text("This helps us find the best date spots near you")
                    .font(Font.bodySans(14, weight: .regular))
                    .foregroundColor(Color.luxuryMuted)
                
                VStack(spacing: 20) {
                    LuxuryTextField(
                        title: "City",
                        placeholder: "e.g., San Francisco, CA",
                        text: $viewModel.location,
                        icon: "mappin.circle.fill"
                    )
                    .focused(focusedField, equals: .location)
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "lock.shield.fill")
                            .foregroundColor(Color.luxuryGold.opacity(0.7))
                        Text("Your data is private")
                            .font(Font.bodySans(13, weight: .medium))
                            .foregroundColor(Color.luxuryGold.opacity(0.9))
                    }
                    
                    Text("We never share your personal information. Your preferences are used only to create personalized date plans.")
                        .font(Font.bodySans(12, weight: .regular))
                        .foregroundColor(Color.luxuryMuted)
                        .lineSpacing(4)
                }
                .padding(16)
                .background(Color.luxuryMaroonLight.opacity(0.5))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.luxuryGold.opacity(0.2), lineWidth: 1)
                )
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 100)
        }
    }
}

// MARK: - Luxury Text Field
struct LuxuryTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var icon: String? = nil
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .words
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(Font.bodySans(13, weight: .medium))
                .foregroundColor(Color.luxuryGold)
            
            HStack(spacing: 12) {
                if let icon = icon {
                    Image(systemName: icon)
                        .foregroundColor(Color.luxuryGold.opacity(0.7))
                        .frame(width: 20)
                }
                
                TextField("", text: $text, prompt: Text(placeholder).foregroundColor(Color.luxuryMuted.opacity(0.6)))
                    .font(Font.bodySans(16, weight: .regular))
                    .foregroundColor(Color.luxuryCream)
                    .keyboardType(keyboardType)
                    .textInputAutocapitalization(autocapitalization)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.luxuryMaroonLight)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        text.isEmpty ? Color.luxuryGold.opacity(0.2) : Color.luxuryGold.opacity(0.5),
                        lineWidth: 1
                    )
            )
        }
    }
}

// MARK: - Luxury Date Picker
struct LuxuryDatePicker: View {
    let title: String
    @Binding var date: Date?
    var icon: String? = nil
    
    @State private var showPicker = false
    @State private var tempDate = Date()
    
    private var displayText: String {
        if let date = date {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
        return "Select your birthdate"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(Font.bodySans(13, weight: .medium))
                .foregroundColor(Color.luxuryGold)
            
            Button {
                if let existing = date {
                    tempDate = existing
                }
                showPicker = true
            } label: {
                HStack(spacing: 12) {
                    if let icon = icon {
                        Image(systemName: icon)
                            .foregroundColor(Color.luxuryGold.opacity(0.7))
                            .frame(width: 20)
                    }
                    
                    Text(displayText)
                        .font(Font.bodySans(16, weight: .regular))
                        .foregroundColor(date == nil ? Color.luxuryMuted.opacity(0.6) : Color.luxuryCream)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12))
                        .foregroundColor(Color.luxuryGold.opacity(0.7))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color.luxuryMaroonLight)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            date == nil ? Color.luxuryGold.opacity(0.2) : Color.luxuryGold.opacity(0.5),
                            lineWidth: 1
                        )
                )
            }
        }
        .sheet(isPresented: $showPicker) {
            DatePickerSheet(date: $tempDate) {
                date = tempDate
                showPicker = false
            }
            .presentationDetents([.height(350)])
            .presentationDragIndicator(.visible)
        }
    }
}

struct DatePickerSheet: View {
    @Binding var date: Date
    let onConfirm: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color.luxuryMaroon
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                HStack {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(Font.bodySans(16, weight: .medium))
                    .foregroundColor(Color.luxuryMuted)
                    
                    Spacer()
                    
                    Text("Date of Birth")
                        .font(Font.header(17, weight: .bold))
                        .foregroundColor(Color.luxuryGold)
                    
                    Spacer()
                    
                    Button("Done") {
                        onConfirm()
                    }
                    .font(Font.bodySans(16, weight: .semibold))
                    .foregroundColor(Color.luxuryGold)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                DatePicker(
                    "",
                    selection: $date,
                    in: ...Calendar.current.date(byAdding: .year, value: -18, to: Date())!,
                    displayedComponents: .date
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .colorScheme(.dark)
                
                Spacer()
            }
        }
    }
}

// MARK: - Focus Fields
enum SignUpField {
    case firstName, lastName, email, phone, location
}

// MARK: - ViewModel
class SignUpViewModel: ObservableObject {
    @Published var currentStep = 1
    
    @Published var firstName = ""
    @Published var lastName = ""
    @Published var dateOfBirth: Date?
    @Published var email = ""
    @Published var phoneNumber = ""
    @Published var location = ""
    
    var isCurrentStepValid: Bool {
        switch currentStep {
        case 1: return !firstName.isEmpty
        case 2: return !email.isEmpty && email.contains("@")
        case 3: return !location.isEmpty
        default: return true
        }
    }
    
    func nextStep() {
        if currentStep < 3 {
            currentStep += 1
        }
    }
    
    func previousStep() {
        if currentStep > 1 {
            currentStep -= 1
        }
    }
    
    func createAccount() {
        UserProfileManager.shared.createProfile(
            firstName: firstName,
            lastName: lastName,
            email: email,
            phoneNumber: phoneNumber,
            dateOfBirth: dateOfBirth,
            location: location
        )
    }
}

// MARK: - Preview
#Preview {
    SignUpView()
        .environmentObject(NavigationCoordinator.shared)
}
