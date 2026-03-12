import SwiftUI
import Combine

struct PreferencesSetupView: View {
    @EnvironmentObject var coordinator: NavigationCoordinator
    @StateObject private var viewModel = PreferencesSetupViewModel()
    
    var body: some View {
        ZStack {
            Color.luxuryMaroon
                .ignoresSafeArea()
            
            RadialGradient.goldGlow
                .opacity(0.15)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                preferencesHeader
                
                // Progress indicator
                PreferencesProgressView(currentStep: viewModel.currentStep, totalSteps: 5)
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                
                // Step content
                TabView(selection: $viewModel.currentStep) {
                    PreferencesPersonalStep(viewModel: viewModel)
                        .tag(1)
                    PreferencesActivitiesStep(viewModel: viewModel)
                        .tag(2)
                    PreferencesLocationStep(viewModel: viewModel)
                        .tag(3)
                    PreferencesCuisineStep(viewModel: viewModel)
                        .tag(4)
                    PreferencesAccessibilityStep(viewModel: viewModel)
                        .tag(5)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)
                
                // Navigation buttons
                navigationButtons
            }
        }
    }
    
    private var preferencesHeader: some View {
        VStack(spacing: 12) {
            Image(systemName: "heart.text.square.fill")
                .font(.system(size: 36))
                .foregroundStyle(LinearGradient.goldShimmer)
            
            HStack(spacing: 6) {
                Text("Your")
                    .font(Font.header(24, weight: .regular))
                    .foregroundColor(Color.luxuryCream)
                Text("Preferences")
                    .font(Font.tangerine(42, weight: .bold))
                    .italic()
                    .foregroundColor(Color.luxuryGold)
            }
            
            Text("Help us create personalized date plans")
                .font(Font.bodySans(14, weight: .regular))
                .foregroundColor(Color.luxuryCreamMuted)
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
                if viewModel.currentStep == 5 {
                    viewModel.savePreferences()
                    coordinator.completePreferences()
                } else {
                    withAnimation {
                        viewModel.nextStep()
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    if viewModel.currentStep == 5 {
                        Image(systemName: "sparkles")
                        Text("Start Planning")
                    } else {
                        Text("Next")
                        Image(systemName: "chevron.right")
                    }
                }
                .frame(maxWidth: viewModel.currentStep == 1 ? .infinity : nil)
            }
            .buttonStyle(LuxuryGoldButtonStyle(isSmall: true))
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
struct PreferencesProgressView: View {
    let currentStep: Int
    let totalSteps: Int
    
    private let stepLabels = ["Personal", "Activities", "Location", "Food", "Needs"]
    
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

// MARK: - Step 1: Personal
struct PreferencesPersonalStep: View {
    @ObservedObject var viewModel: PreferencesSetupViewModel
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                HStack(spacing: 6) {
                    Text("About you &")
                        .font(Font.header(20, weight: .regular))
                        .foregroundColor(Color.luxuryCream)
                    Text("your partner")
                        .font(Font.tangerine(32, weight: .bold))
                        .italic()
                        .foregroundColor(Color.luxuryGold)
                }
                
                // Gender
                VStack(alignment: .leading, spacing: 12) {
                    Text("Your Gender")
                        .font(Font.bodySans(14, weight: .medium))
                        .foregroundColor(Color.luxuryGold)
                    
                    PreferenceSelectionGrid(
                        options: PreferenceOptions.genderOptions,
                        selectedValue: viewModel.gender?.rawValue,
                        onSelect: { value in
                            viewModel.gender = Gender(rawValue: value)
                        }
                    )
                }
                
                // Partner Gender
                VStack(alignment: .leading, spacing: 12) {
                    Text("Partner's Gender")
                        .font(Font.bodySans(14, weight: .medium))
                        .foregroundColor(Color.luxuryGold)
                    
                    PreferenceSelectionGrid(
                        options: PreferenceOptions.genderOptions,
                        selectedValue: viewModel.partnerGender?.rawValue,
                        onSelect: { value in
                            viewModel.partnerGender = Gender(rawValue: value)
                        }
                    )
                }
                
                // Love Language
                VStack(alignment: .leading, spacing: 12) {
                    Text("Your Love Language")
                        .font(Font.bodySans(14, weight: .medium))
                        .foregroundColor(Color.luxuryGold)
                    
                    Text("Select all that resonate — we'll tailor dates to what makes you feel loved")
                        .font(Font.bodySans(12, weight: .regular))
                        .foregroundColor(Color.luxuryMuted)
                    
                    LoveLanguageSelector(
                        selectedLanguages: $viewModel.loveLanguages
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

// MARK: - Step 2: Activities
struct PreferencesActivitiesStep: View {
    @ObservedObject var viewModel: PreferencesSetupViewModel
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                HStack(spacing: 6) {
                    Text("Favorite")
                        .font(Font.tangerine(32, weight: .bold))
                        .italic()
                        .foregroundColor(Color.luxuryGold)
                    Text("Activities")
                        .font(Font.header(20, weight: .regular))
                        .foregroundColor(Color.luxuryCream)
                }
                
                Text("Select all the activities you enjoy on dates")
                    .font(Font.bodySans(14, weight: .regular))
                    .foregroundColor(Color.luxuryMuted)
                
                // Favorite Activities
                VStack(alignment: .leading, spacing: 12) {
                    Text("What do you love to do?")
                        .font(Font.bodySans(14, weight: .medium))
                        .foregroundColor(Color.luxuryGold)
                    
                    MultiSelectGrid(
                        options: QuestionnaireOptions.activities,
                        selectedValues: $viewModel.favoriteActivities
                    )
                }
                
                // Selected summary
                if !viewModel.favoriteActivities.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Selected: \(viewModel.favoriteActivities.count)")
                            .font(Font.bodySans(13, weight: .medium))
                            .foregroundColor(Color.luxuryGold)
                        
                        Text("We'll prioritize these activities when planning your dates")
                            .font(Font.bodySans(12, weight: .regular))
                            .foregroundColor(Color.luxuryMuted)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.luxuryMaroonLight.opacity(0.5))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.luxuryGold.opacity(0.2), lineWidth: 1)
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

// MARK: - Step 3: Location
struct PreferencesLocationStep: View {
    @ObservedObject var viewModel: PreferencesSetupViewModel
    @FocusState private var focusedField: PreferenceField?
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                HStack(spacing: 6) {
                    Text("Default")
                        .font(Font.tangerine(32, weight: .bold))
                        .italic()
                        .foregroundColor(Color.luxuryGold)
                    Text("location settings")
                        .font(Font.header(20, weight: .regular))
                        .foregroundColor(Color.luxuryCream)
                }
                
                Text("These will be pre-filled when you create new date plans")
                    .font(Font.bodySans(14, weight: .regular))
                    .foregroundColor(Color.luxuryMuted)
                
                VStack(spacing: 20) {
                    PlacesAutocompleteField(
                        placeholder: "e.g., San Francisco, CA",
                        text: $viewModel.defaultCity,
                        mode: .city,
                        title: "Default City",
                        icon: "building.2.fill"
                    )
                    
                    PlacesAutocompleteField(
                        placeholder: "e.g., Home address or common meeting spot",
                        text: $viewModel.defaultStartingPoint,
                        mode: .address,
                        title: "Starting Point",
                        icon: "location.fill"
                    )
                    
                    // Default Budget
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Typical Budget")
                            .font(Font.bodySans(14, weight: .medium))
                            .foregroundColor(Color.luxuryGold)
                        
                        PreferenceSelectionGrid(
                            options: QuestionnaireOptions.budgetRanges,
                            selectedValue: viewModel.defaultBudget,
                            onSelect: { value in
                                viewModel.defaultBudget = value
                            },
                            showDescription: true
                        )
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 100)
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
}

// MARK: - Step 4: Cuisine & Beverages
struct PreferencesCuisineStep: View {
    @ObservedObject var viewModel: PreferencesSetupViewModel
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                HStack(spacing: 6) {
                    Text("Food &")
                        .font(Font.header(20, weight: .regular))
                        .foregroundColor(Color.luxuryCream)
                    Text("Drinks")
                        .font(Font.tangerine(32, weight: .bold))
                        .italic()
                        .foregroundColor(Color.luxuryGold)
                }
                
                // Favorite Cuisines
                VStack(alignment: .leading, spacing: 12) {
                    Text("Favorite Cuisines")
                        .font(Font.bodySans(14, weight: .medium))
                        .foregroundColor(Color.luxuryGold)
                    
                    Text("Select all that you enjoy")
                        .font(Font.bodySans(12, weight: .regular))
                        .foregroundColor(Color.luxuryMuted)
                    
                    MultiSelectGrid(
                        options: QuestionnaireOptions.cuisines,
                        selectedValues: $viewModel.favoriteCuisines
                    )
                }
                
                // Beverage Preferences
                VStack(alignment: .leading, spacing: 12) {
                    Text("Preferred Beverages")
                        .font(Font.bodySans(14, weight: .medium))
                        .foregroundColor(Color.luxuryGold)
                    
                    Text("Select all drinks you enjoy")
                        .font(Font.bodySans(12, weight: .regular))
                        .foregroundColor(Color.luxuryMuted)
                    
                    MultiSelectGrid(
                        options: QuestionnaireOptions.drinkPreferences,
                        selectedValues: $viewModel.beveragePreferences
                    )
                }
                
                // Dietary Restrictions
                VStack(alignment: .leading, spacing: 12) {
                    Text("Dietary Restrictions")
                        .font(Font.bodySans(14, weight: .medium))
                        .foregroundColor(Color.luxuryGold)
                    
                    MultiSelectGrid(
                        options: QuestionnaireOptions.dietaryRestrictions,
                        selectedValues: $viewModel.dietaryRestrictions
                    )
                }
                
                // Allergies
                VStack(alignment: .leading, spacing: 12) {
                    Text("Food Allergies")
                        .font(Font.bodySans(14, weight: .medium))
                        .foregroundColor(Color.luxuryGold)
                    
                    MultiSelectGrid(
                        options: QuestionnaireOptions.allergies,
                        selectedValues: $viewModel.allergies
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

// MARK: - Step 5: Accessibility & Hard No's
struct PreferencesAccessibilityStep: View {
    @ObservedObject var viewModel: PreferencesSetupViewModel
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                HStack(spacing: 6) {
                    Text("Comfort &")
                        .font(Font.header(20, weight: .regular))
                        .foregroundColor(Color.luxuryCream)
                    Text("Accessibility")
                        .font(Font.tangerine(32, weight: .bold))
                        .italic()
                        .foregroundColor(Color.luxuryGold)
                }
                
                Text("Help us create dates that work perfectly for you")
                    .font(Font.bodySans(14, weight: .regular))
                    .foregroundColor(Color.luxuryMuted)
                
                // Accessibility Needs
                VStack(alignment: .leading, spacing: 12) {
                    Text("Accessibility Needs")
                        .font(Font.bodySans(14, weight: .medium))
                        .foregroundColor(Color.luxuryGold)
                    
                    MultiSelectGrid(
                        options: PreferenceOptions.accessibilityNeeds,
                        selectedValues: $viewModel.accessibilityNeeds
                    )
                }
                
                // Hard No's
                VStack(alignment: .leading, spacing: 12) {
                    Text("Things to Avoid")
                        .font(Font.bodySans(14, weight: .medium))
                        .foregroundColor(Color.luxuryGold)
                    
                    Text("Select anything you'd rather not have on a date")
                        .font(Font.bodySans(12, weight: .regular))
                        .foregroundColor(Color.luxuryMuted)
                    
                    MultiSelectGrid(
                        options: QuestionnaireOptions.hardNos,
                        selectedValues: $viewModel.hardNos
                    )
                }
                
                // Confirmation message
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(Color.luxurySuccess)
                        Text("You're all set!")
                            .font(Font.bodySans(14, weight: .semibold))
                            .foregroundColor(Color.luxuryCream)
                    }
                    
                    Text("These preferences will be saved and automatically applied to all your future date plans. You can always change them in settings.")
                        .font(Font.bodySans(13, weight: .regular))
                        .foregroundColor(Color.luxuryMuted)
                        .lineSpacing(4)
                }
                .padding(16)
                .background(Color.luxuryMaroonLight.opacity(0.5))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.luxurySuccess.opacity(0.3), lineWidth: 1)
                )
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 100)
        }
    }
}

// MARK: - Preference Selection Grid
struct PreferenceSelectionGrid: View {
    let options: [OptionItem]
    let selectedValue: String?
    let onSelect: (String) -> Void
    var showDescription: Bool = false
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(options) { option in
                PreferenceOptionCard(
                    option: option,
                    isSelected: selectedValue == option.value,
                    showDescription: showDescription,
                    onTap: { onSelect(option.value) }
                )
            }
        }
    }
}

struct PreferenceOptionCard: View {
    let option: OptionItem
    let isSelected: Bool
    var showDescription: Bool = false
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Text(option.emoji)
                    .font(.system(size: 24))
                
                Text(option.label)
                    .font(Font.bodySans(13, weight: .medium))
                    .foregroundColor(isSelected ? Color.luxuryMaroon : Color.luxuryCream)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                if showDescription, let desc = option.desc {
                    Text(desc)
                        .font(Font.bodySans(11, weight: .regular))
                        .foregroundColor(isSelected ? Color.luxuryMaroon.opacity(0.8) : Color.luxuryMuted)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 12)
            .background(
                isSelected ? LinearGradient.goldShimmer : LinearGradient(colors: [Color.luxuryMaroonLight], startPoint: .top, endPoint: .bottom)
            )
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color.clear : Color.luxuryGold.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

// MARK: - Multi-Select Grid
struct MultiSelectGrid: View {
    let options: [OptionItem]
    @Binding var selectedValues: [String]
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(options) { option in
                MultiSelectChip(
                    option: option,
                    isSelected: selectedValues.contains(option.value),
                    onTap: {
                        toggleSelection(option.value)
                    }
                )
            }
        }
    }
    
    private func toggleSelection(_ value: String) {
        if let index = selectedValues.firstIndex(of: value) {
            selectedValues.remove(at: index)
        } else {
            selectedValues.append(value)
        }
    }
}

struct MultiSelectChip: View {
    let option: OptionItem
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Text(option.emoji)
                    .font(.system(size: 16))
                
                Text(option.label)
                    .font(Font.bodySans(12, weight: .medium))
                    .foregroundColor(isSelected ? Color.luxuryMaroon : Color.luxuryCream)
                    .lineLimit(1)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(
                isSelected ? Color.luxuryGold : Color.luxuryMaroonLight
            )
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? Color.clear : Color.luxuryGold.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

// MARK: - Love Language Selector
struct LoveLanguageSelector: View {
    @Binding var selectedLanguages: Set<LoveLanguage>
    
    var body: some View {
        VStack(spacing: 10) {
            ForEach(LoveLanguage.allCases, id: \.self) { language in
                LoveLanguageCard(
                    language: language,
                    isSelected: selectedLanguages.contains(language),
                    onTap: {
                        var updated = selectedLanguages
                        if updated.contains(language) {
                            updated.remove(language)
                        } else {
                            updated.insert(language)
                        }
                        selectedLanguages = updated
                    }
                )
            }
        }
    }
}

struct LoveLanguageCard: View {
    let language: LoveLanguage
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                Text(language.emoji)
                    .font(.system(size: 28))
                    .frame(width: 44, height: 44)
                    .background(
                        isSelected ? Color.luxuryMaroon.opacity(0.3) : Color.luxuryMaroonLight
                    )
                    .cornerRadius(12)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(language.displayName)
                        .font(Font.bodySans(15, weight: .semibold))
                        .foregroundColor(isSelected ? Color.luxuryMaroon : Color.luxuryCream)
                    
                    Text(language.description)
                        .font(Font.bodySans(12, weight: .regular))
                        .foregroundColor(isSelected ? Color.luxuryMaroon.opacity(0.8) : Color.luxuryMuted)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(Color.luxuryMaroon)
                }
            }
            .padding(14)
            .background(
                isSelected ? LinearGradient.goldShimmer : LinearGradient(colors: [Color.luxuryMaroonLight], startPoint: .top, endPoint: .bottom)
            )
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color.clear : Color.luxuryGold.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

// MARK: - Focus Fields
enum PreferenceField {
    case city, startingPoint
}

// MARK: - ViewModel
class PreferencesSetupViewModel: ObservableObject {
    @Published var currentStep = 1
    
    // Personal
    @Published var gender: Gender?
    @Published var partnerGender: Gender?
    @Published var loveLanguages: Set<LoveLanguage> = []
    
    // Activities
    @Published var favoriteActivities: [String] = []
    
    // Location
    @Published var defaultCity = ""
    @Published var defaultStartingPoint = ""
    @Published var defaultBudget = ""
    
    // Cuisine & Beverages
    @Published var favoriteCuisines: [String] = []
    @Published var beveragePreferences: [String] = []
    @Published var dietaryRestrictions: [String] = []
    @Published var allergies: [String] = []
    
    // Accessibility
    @Published var accessibilityNeeds: [String] = []
    @Published var hardNos: [String] = []
    
    init() {
        if let profile = UserProfileManager.shared.currentUser {
            let prefs = profile.preferences
            defaultCity = prefs.defaultCity.isEmpty ? profile.location : prefs.defaultCity
            gender = prefs.gender
            partnerGender = prefs.partnerGender
            loveLanguages = Set(prefs.loveLanguages)
            favoriteActivities = prefs.favoriteActivities
            defaultStartingPoint = prefs.defaultStartingPoint
            defaultBudget = prefs.defaultBudget
            favoriteCuisines = prefs.favoriteCuisines
            beveragePreferences = prefs.beveragePreferences
            dietaryRestrictions = prefs.dietaryRestrictions
            allergies = prefs.allergies
            accessibilityNeeds = prefs.accessibilityNeeds
            hardNos = prefs.hardNos
        }
    }
    
    func nextStep() {
        if currentStep < 5 {
            currentStep += 1
        }
    }
    
    func previousStep() {
        if currentStep > 1 {
            currentStep -= 1
        }
    }
    
    func savePreferences() {
        var preferences = DatePreferences()
        preferences.gender = gender ?? .preferNotToSay
        preferences.partnerGender = partnerGender ?? .preferNotToSay
        preferences.loveLanguages = loveLanguages.isEmpty ? [.qualityTime] : Array(loveLanguages)
        preferences.favoriteActivities = favoriteActivities
        preferences.defaultCity = defaultCity
        preferences.defaultStartingPoint = defaultStartingPoint
        preferences.defaultBudget = defaultBudget
        preferences.favoriteCuisines = favoriteCuisines
        preferences.beveragePreferences = beveragePreferences
        preferences.dietaryRestrictions = dietaryRestrictions
        preferences.allergies = allergies
        preferences.accessibilityNeeds = accessibilityNeeds
        preferences.hardNos = hardNos
        
        UserProfileManager.shared.updatePreferences(preferences)
    }
}

// MARK: - Preview
#Preview {
    PreferencesSetupView()
        .environmentObject(NavigationCoordinator.shared)
}
