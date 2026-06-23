import SwiftUI

/// Detailed advertising application. Submits to Firestore `business_listings` via BusinessListingService.
struct BusinessApplicationFormView: View {
    let source: String
    var defaultEmail: String = ""
    let onSuccess: () -> Void

    @StateObject private var service = BusinessListingService.shared
    @State private var app = BusinessListingApplication()
    @State private var didAttemptSubmit = false
    @FocusState private var focused: Field?

    private enum Field: Hashable {
        case businessName, contactName, contactRole, email, phone, website
        case street, city, state, zip, categoryOther, about, experience, promotionOther, notes
    }

    /// Generous caps so a single application can never bloat the Firestore doc.
    private enum Limit {
        static let short = 120
        static let line = 200
        static let long = 2000
    }

    private var isSubmitting: Bool { service.status == .submitting }
    private var firebaseReady: Bool { Config.isFirebaseConfigured }
    private var errors: [BusinessListingApplication.ValidationField: String] { app.validationErrors }
    private var isValid: Bool { errors.isEmpty }

    var body: some View {
        ZStack {
            Color.backgroundPrimary.ignoresSafeArea()

            switch service.status {
            case .success:
                statusCard(
                    icon: "checkmark.seal.fill",
                    tint: Color.green,
                    title: "Application received",
                    message: "Thanks, \(firstName)! We’ll review \(displayBusinessName) and email you within a few business days with placement options."
                )
            case .duplicate:
                statusCard(
                    icon: "info.circle.fill",
                    tint: Color.blue,
                    title: "We already have your application",
                    message: "\(displayBusinessName) already applied with this email. We’ll be in touch soon."
                )
            default:
                form
            }
        }
        .onAppear {
            if app.email.isEmpty { app.email = defaultEmail }
        }
        .onChange(of: service.status) { _, newValue in
            if newValue == .success { onSuccess() }
        }
        .onDisappear { service.resetStatus() }
    }

    // MARK: - Form

    private var form: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    Text("Tell us about your business so we can match you to couples planning date nights in your area. All categories welcome.")
                        .font(Font.bodySans(14, weight: .regular))
                        .foregroundColor(Color.luxuryCreamMuted)
                        .lineSpacing(2)

                    if !firebaseReady {
                        firebaseNotConfiguredBanner
                    }

                    section("Business details") {
                        validated(.businessName) {
                            LuxuryTextField(title: "Business name *", placeholder: "Your venue", text: clamped($app.businessName, Limit.short), icon: nil)
                                .focused($focused, equals: .businessName)
                        }
                        validated(.contactName) {
                            LuxuryTextField(title: "Contact name *", placeholder: "Your name", text: clamped($app.contactName, Limit.short), icon: nil)
                                .focused($focused, equals: .contactName)
                        }
                        LuxuryTextField(title: "Your role (optional)", placeholder: "Owner, manager…", text: clamped($app.contactRole, Limit.short), icon: nil)
                            .focused($focused, equals: .contactRole)
                    }

                    section("Contact") {
                        validated(.email) {
                            LuxuryTextField(title: "Work email *", placeholder: "you@business.com", text: clamped($app.email, Limit.line), icon: "envelope.fill", keyboardType: .emailAddress, autocapitalization: .never)
                                .focused($focused, equals: .email)
                        }
                        validated(.phone) {
                            LuxuryTextField(title: "Phone *", placeholder: "(555) 123-4567", text: clamped($app.phone, Limit.line), icon: "phone.fill", keyboardType: .phonePad)
                                .focused($focused, equals: .phone)
                        }
                        LuxuryTextField(title: "Website or Instagram (optional)", placeholder: "https://…", text: clamped($app.website, Limit.line), icon: "globe", keyboardType: .URL, autocapitalization: .never)
                            .focused($focused, equals: .website)
                    }

                    section("Location") {
                        validated(.streetAddress) {
                            LuxuryTextField(title: "Street address *", placeholder: "123 Main St", text: clamped($app.streetAddress, Limit.line), icon: nil)
                                .focused($focused, equals: .street)
                        }
                        HStack(alignment: .top, spacing: 12) {
                            validated(.city) {
                                LuxuryTextField(title: "City *", placeholder: "City", text: clamped($app.city, Limit.short), icon: nil)
                                    .focused($focused, equals: .city)
                            }
                            validated(.state) {
                                LuxuryTextField(title: "State *", placeholder: "ST", text: clamped($app.state, Limit.short), icon: nil)
                                    .focused($focused, equals: .state)
                            }
                        }
                        LuxuryTextField(title: "ZIP (optional)", placeholder: "00000", text: clamped($app.zip, Limit.short), icon: nil, keyboardType: .numbersAndPunctuation)
                            .focused($focused, equals: .zip)
                    }

                    section("Category") {
                        LuxurySelectField(
                            title: "What kind of date spot is it? *",
                            selectionLabel: app.venueCategory.label,
                            options: BusinessVenueCategory.allCases.map { ($0.label, $0) },
                            onSelect: { app.venueCategory = $0 }
                        )
                        if app.venueCategory == .other {
                            validated(.venueCategoryOther) {
                                LuxuryTextField(title: "Describe your category *", placeholder: "e.g. axe throwing, pottery studio", text: clamped($app.venueCategoryOther, Limit.line), icon: nil)
                                    .focused($focused, equals: .categoryOther)
                            }
                        }
                    }

                    section("Tell us about your spot") {
                        validated(.aboutVenue) {
                            LuxuryMultilineField(title: "What do you offer? Hours, vibe, price range… *", text: $app.aboutVenue, characterLimit: Limit.long)
                                .focused($focused, equals: .about)
                        }
                        validated(.coupleExperience) {
                            LuxuryMultilineField(title: "Why is it great for couples on a date? *", text: $app.coupleExperience, characterLimit: Limit.long)
                                .focused($focused, equals: .experience)
                        }
                    }

                    section("Advertising interest") {
                        LuxurySelectField(
                            title: "What are you looking for? *",
                            selectionLabel: app.promotionInterest.label,
                            options: BusinessPromotionInterest.allCases.map { ($0.label, $0) },
                            onSelect: { app.promotionInterest = $0 }
                        )
                        if app.promotionInterest == .other {
                            validated(.promotionOther) {
                                LuxuryTextField(title: "Describe what you’re looking for *", placeholder: "Tell us more", text: clamped($app.promotionOther, Limit.line), icon: nil)
                                    .focused($focused, equals: .promotionOther)
                            }
                        }
                        LuxurySelectField(
                            title: "Monthly budget *",
                            selectionLabel: app.budgetRange.label,
                            options: BusinessBudgetRange.allCases.map { ($0.label, $0) },
                            onSelect: { app.budgetRange = $0 }
                        )
                    }

                    section("Anything else?") {
                        LuxuryMultilineField(title: "Additional notes (optional)", text: $app.additionalNotes, characterLimit: Limit.long)
                            .focused($focused, equals: .notes)
                    }

                    if didAttemptSubmit && !isValid {
                        Text("Please fix the highlighted fields above to submit.")
                            .font(Font.bodySans(13, weight: .regular))
                            .foregroundColor(Color.red.opacity(0.9))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    if case let .error(message) = service.status {
                        Text(message)
                            .font(Font.bodySans(13, weight: .regular))
                            .foregroundColor(Color.red.opacity(0.9))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Button {
                        focused = nil
                        submit(proxy: proxy)
                    } label: {
                        HStack(spacing: 10) {
                            if isSubmitting {
                                ProgressView().tint(Color.luxuryMaroon)
                            }
                            Text(isSubmitting ? "Submitting…" : "Submit application")
                                .font(Font.bodySans(16, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(LuxuryGoldButtonStyle())
                    .disabled(isSubmitting || !firebaseReady)
                    .opacity(isSubmitting || !firebaseReady ? 0.5 : 1)

                    Text("Stored securely in Firebase business_listings. We’ll email you within a few business days.")
                        .font(Font.bodySans(11, weight: .regular))
                        .foregroundColor(Color.luxuryMuted)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, 8)
                }
                .padding(20)
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focused = nil }
                    .foregroundColor(Color.luxuryGold)
            }
        }
    }

    // MARK: - Submit

    /// Validates locally first. On failure, reveals inline errors and scrolls/focuses the
    /// first offending field so nothing fails silently at the network layer.
    private func submit(proxy: ScrollViewProxy) {
        didAttemptSubmit = true
        guard firebaseReady else { return }
        guard isValid else {
            if let first = BusinessListingApplication.ValidationField.orderedForDisplay
                .first(where: { errors[$0] != nil }) {
                withAnimation { proxy.scrollTo(first, anchor: .center) }
                focused = focusTarget(for: first)
            }
            return
        }
        Task { await service.submit(app, source: source) }
    }

    private func focusTarget(for field: BusinessListingApplication.ValidationField) -> Field {
        switch field {
        case .businessName: return .businessName
        case .contactName: return .contactName
        case .email: return .email
        case .phone: return .phone
        case .streetAddress: return .street
        case .city: return .city
        case .state: return .state
        case .venueCategoryOther: return .categoryOther
        case .aboutVenue: return .about
        case .coupleExperience: return .experience
        case .promotionOther: return .promotionOther
        }
    }

    // MARK: - Helpers

    /// Wraps a field so it scrolls into view by id and shows its inline error after a submit attempt.
    @ViewBuilder
    private func validated(
        _ field: BusinessListingApplication.ValidationField,
        @ViewBuilder _ content: () -> some View
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            content()
            if didAttemptSubmit, let message = errors[field] {
                Label(message, systemImage: "exclamationmark.circle.fill")
                    .font(Font.bodySans(12, weight: .regular))
                    .foregroundColor(Color.red.opacity(0.9))
                    .labelStyle(.titleAndIcon)
            }
        }
        .id(field)
    }

    /// Binding that truncates input to `limit` characters to guard against runaway pastes.
    private func clamped(_ source: Binding<String>, _ limit: Int) -> Binding<String> {
        Binding(
            get: { source.wrappedValue },
            set: { source.wrappedValue = $0.count > limit ? String($0.prefix(limit)) : $0 }
        )
    }

    private var firebaseNotConfiguredBanner: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(Color.luxuryGold)
            Text("Applications are temporarily unavailable. Please email hello@yourdategenie.com and we’ll get you set up.")
                .font(Font.bodySans(13, weight: .regular))
                .foregroundColor(Color.luxuryCreamMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.luxuryMaroonLight.opacity(0.7))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.luxuryGold.opacity(0.3), lineWidth: 1)
        )
    }

    private var firstName: String {
        app.contactName.split(separator: " ").first.map(String.init) ?? "there"
    }

    private var displayBusinessName: String {
        let trimmed = app.businessName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "your business" : trimmed
    }

    private func section(_ title: String, @ViewBuilder _ content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title.uppercased())
                .font(Font.bodySans(11, weight: .semibold))
                .tracking(1.2)
                .foregroundColor(Color.luxuryGold)
            content()
        }
    }

    private func statusCard(icon: String, tint: Color, title: String, message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 44))
                .foregroundColor(tint)
            Text(title)
                .font(Font.displaySerif(34, weight: .bold))
                .foregroundColor(Color.luxuryGold)
            Text(message)
                .font(Font.bodySans(15, weight: .regular))
                .foregroundColor(Color.luxuryCreamMuted)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.horizontal, 28)
        }
        .padding(28)
    }
}

private extension BusinessListingApplication.ValidationField {
    /// Top-to-bottom field order, used to focus the first error after a submit attempt.
    static let orderedForDisplay: [BusinessListingApplication.ValidationField] = [
        .businessName, .contactName, .email, .phone, .streetAddress, .city, .state,
        .venueCategoryOther, .aboutVenue, .coupleExperience, .promotionOther
    ]
}

// MARK: - Reusable luxury select (dropdown)

struct LuxurySelectField<Value: Hashable>: View {
    let title: String
    let selectionLabel: String
    let options: [(String, Value)]
    let onSelect: (Value) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(Font.bodySans(13, weight: .medium))
                .foregroundColor(Color.luxuryGold)

            Menu {
                ForEach(Array(options.enumerated()), id: \.offset) { _, opt in
                    Button(opt.0) { onSelect(opt.1) }
                }
            } label: {
                HStack {
                    Text(selectionLabel)
                        .font(Font.bodySans(16, weight: .regular))
                        .foregroundColor(Color.luxuryCream)
                        .multilineTextAlignment(.leading)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color.luxuryGold.opacity(0.8))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color.luxuryMaroonLight)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.luxuryGold.opacity(0.3), lineWidth: 1)
                )
            }
        }
    }
}

// MARK: - Reusable multiline field

struct LuxuryMultilineField: View {
    let title: String
    @Binding var text: String
    var characterLimit: Int = 2000

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(Font.bodySans(13, weight: .medium))
                .foregroundColor(Color.luxuryGold)

            TextEditor(text: $text)
                .font(Font.bodySans(16, weight: .regular))
                .foregroundColor(Color.luxuryCream)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 84)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.luxuryMaroonLight)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(text.isEmpty ? Color.luxuryGold.opacity(0.2) : Color.luxuryGold.opacity(0.5), lineWidth: 1)
                )
                .onChange(of: text) { _, newValue in
                    if newValue.count > characterLimit {
                        text = String(newValue.prefix(characterLimit))
                    }
                }
        }
    }
}
