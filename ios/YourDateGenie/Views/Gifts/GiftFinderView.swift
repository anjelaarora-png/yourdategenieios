import SwiftUI
import CoreLocation

private enum GiftFinderTab: String, CaseIterable {
    case find = "Find a Gift"
    case saved = "Saved"
    case bought = "Bought"
}

// MARK: - Gift Finder (screens 24 / 24b / 24c) — Charcoal Maroon
// Full parity with src/components/gifts/GiftFinderDialog.tsx:
// occasion · budget · love languages · interests · "tell us about them" ·
// "+ More" (style / brands / sizes / identity) · multi-retailer Shop Now · ship-by + wrap + attach.
struct GiftFinderView: View {
    var datePlan: DatePlan?
    var dateLocation: String?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var selectedTab: GiftFinderTab = .find

    // Core inputs (24)
    @State private var selectedOccasion: String = ""
    @State private var selectedBudget: String = ""
    @State private var interests: String = ""
    @State private var partnerDescription: String = ""
    @State private var selectedLoveLanguages: Set<LoveLanguage> = []

    // "+ More" advanced inputs
    @State private var showMore = false
    @State private var selectedGiftStyles: Set<String> = []
    @State private var favoriteBrands: String = ""
    @State private var recipientSizes: String = ""
    @State private var recipientIdentity: String = ""
    @State private var selectedRecipient: String = "partner"

    // Pre-fill
    @State private var hasPrefilledOnce = false
    @State private var prefilledFromPartner = false
    @State private var prefillPartnerName: String = ""

    // Results (24b)
    @State private var resultBudgetFilter: String = ""
    @State private var isLoading = false
    @State private var gifts: [GiftSuggestion] = []
    @State private var showResults = false
    @State private var nearbyStores: [NearbyStore] = []
    @State private var giftLoadError: String?

    // Detail (24c)
    @State private var detailGift: GiftSuggestion?
    @State private var attachedGiftNames: Set<String> = []

    // Intro + celebration animations
    @State private var showUnwrapAnimation = true
    @State private var showBoxOpenCelebration = false
    @State private var celebrationMessage = "Gift saved!"

    @ObservedObject private var giftStore = GiftStorageManager.shared

    private var effectiveLocation: String {
        if let location = dateLocation, !location.isEmpty {
            return location
        }
        if let firstStop = datePlan?.stops.first, let address = firstStop.address {
            return address
        }
        let fromProfile = UserProfileManager.resolvedLocationForDiscovery()
        if !fromProfile.isEmpty { return fromProfile }
        return ""
    }

    private var effectiveLocationDisplay: String {
        if effectiveLocation.isEmpty { return "Near me" }
        let parsed = MapURLHelper.cityStateOrRegionFromAddress(effectiveLocation)
        return parsed.isEmpty ? effectiveLocation : parsed
    }

    private var mapSearchLocation: String {
        effectiveLocation.isEmpty ? "me" : effectiveLocationDisplay
    }

    private let occasionOptions = [
        ("anniversary", "Anniversary", "💕"),
        ("birthday", "Birthday", "🎂"),
        ("valentines", "Valentine's Day", "❤️"),
        ("just-because", "Just Because", "💝"),
        ("holiday", "Holiday", "🎄"),
        ("date-night", "Date Night", "🌙"),
    ]

    private let budgetOptions = [
        ("under-25", "Under $25"),
        ("25-50", "$25-50"),
        ("50-100", "$50-100"),
        ("100-200", "$100-200"),
        ("200-plus", "$200+"),
    ]

    private let recipientOptions = [
        ("partner", "Partner"),
        ("friend", "Friend"),
        ("family", "Family"),
        ("other", "Other"),
    ]

    private let styleOptions = [
        ("luxe", "Luxe"),
        ("casual", "Casual"),
        ("experiences", "Experiences"),
        ("understated", "Understated"),
    ]

    private var filteredGifts: [GiftSuggestion] {
        guard !resultBudgetFilter.isEmpty else { return gifts }
        return gifts.filter { gift in
            let p = gift.priceRange.lowercased()
            switch resultBudgetFilter {
            case "under-25": return p.contains("under")
            case "25-50": return (p.contains("25") && p.contains("50")) || (p.contains("25") && p.contains("-"))
            case "50-100": return (p.contains("50") && p.contains("100")) || (p.contains("50") && p.contains("-"))
            case "100-200": return (p.contains("100") && p.contains("200")) || (p.contains("100") && p.contains("-"))
            case "200-plus": return p.contains("200") || p.contains("+") || p.contains("300") || p.contains("over") || p.contains("luxury")
            default: return true
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.ydgBase
                    .ignoresSafeArea()

                if showUnwrapAnimation {
                    BigGiftUnwrapView {
                        animate { showUnwrapAnimation = false }
                    }
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            if !(selectedTab == .find && showResults) {
                                headerSection
                                    .padding(.bottom, YDGSpace.lg)
                            }

                            switch selectedTab {
                            case .find:
                                if !showResults {
                                    inputFormSection
                                } else {
                                    resultsSection
                                }
                            case .saved:
                                savedTabContent
                            case .bought:
                                boughtTabContent
                            }
                        }
                        .padding(.bottom, 40)
                    }
                }

                if showBoxOpenCelebration {
                    GiftBoxOpenCelebrationView(message: celebrationMessage) {
                        showBoxOpenCelebration = false
                    }
                    .transition(.opacity)
                    .zIndex(2)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    if !showUnwrapAnimation {
                        giftFinderTabBar
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Color.ydgTextPrimary)
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel("Close")
                }
            }
            .toolbarBackground(Color.ydgBase, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .onAppear {
                if reduceMotion { showUnwrapAnimation = false }
                prefillFromProfile()
                #if DEBUG
                if ScreenshotDemo.isActive && ScreenshotDemo.scene == .giftFinder {
                    showUnwrapAnimation = false
                    selectedOccasion = "Anniversary"
                    selectedBudget = "$50–$100"
                    interests = "Italian food, wine, cozy nights in"
                    gifts = ScreenshotDemo.sampleGiftSuggestions
                    showResults = true
                }
                #endif
            }
            .sheet(item: $detailGift) { gift in
                GiftDetailSheet(
                    gift: gift,
                    datePlan: datePlan,
                    location: mapSearchLocation,
                    isAttached: attachedGiftNames.contains(normalize(gift.name)),
                    onShop: { openShop(for: gift) },
                    onAttach: { attach(gift: gift) }
                )
                .presentationDetents([.large])
            }
        }
    }

    // MARK: - Tab switcher (lives in the nav bar)
    private var giftFinderTabBar: some View {
        YDGSegmentedControl(
            options: GiftFinderTab.allCases,
            selection: Binding(get: { selectedTab }, set: { tab in animate { selectedTab = tab } }),
            title: { $0 == .find ? "Ideas" : $0.rawValue }
        )
        .frame(width: 230)
    }

    // MARK: - Header
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: YDGSpace.xs) {
            Text(selectedTab == .find ? "Find the perfect gift" : (selectedTab == .saved ? "Saved gifts" : "Gifts you bought"))
                .ydgText(.title1)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)

            if selectedTab == .find {
                Text("Thoughtful picks for your person, tuned to the occasion.")
                    .ydgText(.body, color: .ydgTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if prefilledFromPartner && selectedTab == .find && !showResults {
                Label("Pre-filled from \(prefillPartnerName.isEmpty ? "your profile" : prefillPartnerName)", systemImage: "sparkles")
                    .font(.ydg(.footnote, weight: .semibold))
                    .foregroundColor(Color.ydgHighlight)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.ydgHighlightSubtle))
                    .padding(.top, YDGSpace.xxs)
            }

            if let plan = datePlan, selectedTab == .find {
                dateContextBadge(plan: plan)
                    .padding(.top, YDGSpace.xs)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, YDGSpace.margin)
        .padding(.top, YDGSpace.xs)
    }

    private func dateContextBadge(plan: DatePlan) -> some View {
        HStack(spacing: YDGSpace.sm) {
            YDGIconTile(systemName: "calendar", size: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text("For your date")
                    .ydgText(.caption)
                Text(plan.title)
                    .ydgText(.subhead, weight: .semibold)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
            Button {
                openInAppleMaps(query: "gift shop", near: mapSearchLocation)
            } label: {
                Label(effectiveLocationDisplay, systemImage: "mappin")
                    .font(.ydg(.footnote, weight: .medium))
                    .foregroundColor(Color.ydgTextSecondary)
                    .lineLimit(1)
                    .frame(minHeight: 44)
            }
            .buttonStyle(.plain)
            .accessibilityHint("Opens gift shops near you in Maps")
        }
        .ydgCard(padding: YDGSpace.sm)
    }

    // MARK: - Input Form (24) — core picks + the two open boxes up top, advanced behind "+ More"
    private var inputFormSection: some View {
        VStack(spacing: 24) {
            // Occasion (required)
            sectionContainer(icon: "heart.fill", title: "What's the occasion? *") {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(occasionOptions, id: \.0) { occasion in
                        GiftOccasionCard(
                            emoji: occasion.2,
                            title: occasion.1,
                            isSelected: selectedOccasion == occasion.0,
                            action: { selectedOccasion = occasion.0 }
                        )
                    }
                }
            }

            // Budget
            sectionContainer(icon: "dollarsign.circle", title: "Your budget") {
                chipRow(budgetOptions, selected: selectedBudget) { value in
                    selectedBudget = selectedBudget == value ? "" : value
                }
            }

            // Love languages (parity field)
            sectionContainer(icon: "heart.text.square", title: "Their love languages") {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(LoveLanguage.allCases, id: \.self) { lang in
                            GiftChip(
                                text: "\(lang.emoji) \(lang.displayName)",
                                isSelected: selectedLoveLanguages.contains(lang)
                            ) {
                                if selectedLoveLanguages.contains(lang) {
                                    selectedLoveLanguages.remove(lang)
                                } else {
                                    selectedLoveLanguages.insert(lang)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 1)
                }
            }

            // Their interests (open box 1)
            sectionContainer(icon: "sparkles", title: "Their interests") {
                giftTextField(
                    placeholder: "e.g., cooking, travel, photography, books…",
                    text: $interests
                )
            }

            // Tell us about them (open box 2)
            sectionContainer(icon: "text.bubble", title: "Tell us about them") {
                giftTextEditor(
                    placeholder: "e.g., loves surprises, prefers experiences over things…",
                    text: $partnerDescription
                )
            }

            // "+ More" progressive disclosure
            moreSection

            // Single gold element on this screen: the primary CTA
            Button {
                generateGifts()
            } label: {
                Label(selectedOccasion.isEmpty ? "Pick an occasion to start" : "Find gift ideas", systemImage: "sparkles")
            }
            .buttonStyle(YDGButtonStyle(kind: .primary, isLoading: isLoading))
            .disabled(isLoading || selectedOccasion.isEmpty)
            .padding(.horizontal, YDGSpace.margin)
        }
    }

    private var moreSection: some View {
        VStack(spacing: 16) {
            Button {
                animate { showMore.toggle() }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: showMore ? "minus.circle" : "plus.circle")
                        .font(.system(size: 15))
                    Text(showMore ? "Fewer details" : "More details (optional)")
                        .font(Font.bodySans(14, weight: .semibold))
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .rotationEffect(.degrees(showMore ? 180 : 0))
                }
                .foregroundColor(Color.textPrimary)
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity)
                .background(Color.ydgRaised)
                .cornerRadius(14)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.ydgBorder, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)

            if showMore {
                VStack(spacing: 24) {
                    // Who is this for? (recipient / identity)
                    sectionContainer(icon: "person.fill", title: "Who is this for?") {
                        chipRow(recipientOptions, selected: selectedRecipient) { value in
                            selectedRecipient = value
                        }
                    }

                    // Gift style / vibe
                    sectionContainer(icon: "sparkle", title: "Gift style or vibe") {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(styleOptions, id: \.0) { option in
                                    GiftChip(
                                        text: option.1,
                                        isSelected: selectedGiftStyles.contains(option.0)
                                    ) {
                                        if selectedGiftStyles.contains(option.0) {
                                            selectedGiftStyles.remove(option.0)
                                        } else {
                                            selectedGiftStyles.insert(option.0)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 1)
                        }
                    }

                    // Favourite brands / stores
                    sectionContainer(icon: "bag", title: "Favourite brands or stores") {
                        giftTextField(
                            placeholder: "e.g., Lululemon, Aesop, local bookshop…",
                            text: $favoriteBrands
                        )
                    }

                    // Recipient sizes
                    sectionContainer(icon: "ruler", title: "Sizes (if relevant)") {
                        giftTextField(
                            placeholder: "e.g., M tops, size 9 shoe, ring size 6…",
                            text: $recipientSizes
                        )
                    }

                    // Recipient / identity
                    sectionContainer(icon: "person.text.rectangle", title: "About the recipient") {
                        giftTextField(
                            placeholder: "e.g., she/her, late 20s, minimalist…",
                            text: $recipientIdentity
                        )
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    // MARK: - Results (24b)
    private var resultsSection: some View {
        VStack(spacing: 20) {
            if let error = giftLoadError {
                errorCard(error)
            }

            // Header with Refine + New Search
            VStack(alignment: .leading, spacing: YDGSpace.xxs) {
                Text(filteredGifts.isEmpty && giftLoadError != nil
                     ? "Gift ideas"
                     : "\(filteredGifts.count) ideas\(prefillPartnerName.isEmpty ? "" : " for \(prefillPartnerName)")")
                    .ydgText(.title1)
                    .accessibilityAddTraits(.isHeader)

                HStack(spacing: YDGSpace.sm) {
                    Text(resultsMetaLine)
                        .ydgText(.subhead, weight: .regular, color: .ydgTextSecondary)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                    Button("Refine") { animate { showResults = false } }
                        .buttonStyle(.ydgTertiary)
                }
            }
            .padding(.horizontal, YDGSpace.margin)
            .padding(.top, YDGSpace.xs)

            if !nearbyStores.isEmpty {
                nearbyStoresSection
            }

            // Gift cards
            VStack(spacing: YDGSpace.sm) {
                ForEach(filteredGifts) { gift in
                    GiftResultCard(
                        gift: gift,
                        isSaved: giftStore.isSaved(gift),
                        isBought: giftStore.isBought(gift),
                        onOpenDetail: { detailGift = gift },
                        onSave: { saveGift(gift) },
                        onShop: { openShop(for: gift) },
                        onFindNearby: { openStoreNearby(for: gift) }
                    )
                }
            }
            .padding(.horizontal, 20)

            // Single gold element on this screen: Get More Ideas (excludes already-bought)
            Button {
                generateGifts()
            } label: {
                Label("Get more ideas", systemImage: "sparkles")
            }
            .buttonStyle(YDGButtonStyle(kind: .primary, isLoading: isLoading))
            .disabled(isLoading)
            .padding(.horizontal, YDGSpace.margin)

            Button("Start a new search") { resetSearch() }
                .buttonStyle(.ydgTertiary)
        }
    }

    /// "Anniversary · $50–$100 · Italian food" — what these ideas were tuned for.
    private var resultsMetaLine: String {
        let interestBits = interests.split(separator: ",").prefix(2).map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
        let parts = [selectedOccasion, selectedBudget, interestBits.joined(separator: ", ")].filter { !$0.isEmpty }
        if parts.isEmpty {
            return effectiveLocation.isEmpty ? "With stores near you" : "With stores near \(effectiveLocationDisplay)"
        }
        return parts.joined(separator: " · ")
    }

    private func errorCard(_ error: String) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "wifi.exclamationmark")
                    .font(.system(size: 18))
                Text("Couldn't load gift ideas")
                    .font(Font.ydgDisplay(16))
            }
            .foregroundColor(Color.textPrimary)
            Text("Check your connection and tap Try again for AI-powered suggestions.")
                .font(Font.bodySans(12, weight: .regular))
                .foregroundColor(Color.luxuryCreamMuted)
                .multilineTextAlignment(.center)
            Button {
                generateGifts()
            } label: {
                Label("Try again", systemImage: "arrow.clockwise")
            }
            .buttonStyle(YDGButtonStyle(kind: .secondary, compact: true))
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .goldHighlightMaroonAccent(cornerRadius: 16)
        .padding(.horizontal, 20)
    }

    // MARK: - Nearby Stores
    private var nearbyStoresSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            ExtrasSectionHeader(icon: "mappin.and.ellipse", title: effectiveLocation.isEmpty ? "Stores near you" : "Stores near your date")
                .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(nearbyStores) { store in
                        NearbyStoreCard(store: store, location: mapSearchLocation)
                    }
                }
                .padding(.horizontal, 20)
            }

            Button {
                openInAppleMaps(query: "gift shop", near: mapSearchLocation)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "map.fill")
                        .font(.system(size: 13))
                    Text("View all gift shops on map")
                        .font(Font.bodySans(14, weight: .semibold))
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 11))
                }
                .foregroundColor(Color.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.ydgRaised)
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.luxeSurfaceBorder, lineWidth: 1))
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Saved / Bought tabs
    private var savedTabContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            if giftStore.savedOnly.isEmpty {
                GiftListEmptyState(
                    icon: "heart.circle.fill",
                    title: "No saved gifts yet",
                    subtitle: "Save ideas from your search results to keep them here"
                )
                .padding(.top, 40)
            } else {
                VStack(spacing: 10) {
                    ForEach(giftStore.savedOnly) { stored in
                        StoredGiftRowView(
                            stored: stored,
                            onShop: { openStoredShop(stored: stored) },
                            onNewLink: { openStoredSearch(name: stored.name) },
                            onMarkBought: { giftStore.markAsBought(storedToGiftSuggestion(stored)) }
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    private var boughtTabContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            if giftStore.boughtOnly.isEmpty {
                GiftListEmptyState(
                    icon: "checkmark.circle.fill",
                    title: "No bought gifts yet",
                    subtitle: "Mark an idea as bought so we won't suggest it again"
                )
                .padding(.top, 40)
            } else {
                VStack(spacing: 10) {
                    ForEach(giftStore.boughtOnly) { stored in
                        StoredGiftRowView(
                            stored: stored,
                            onShop: { openStoredShop(stored: stored) },
                            onNewLink: { openStoredSearch(name: stored.name) },
                            onMarkBought: nil
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - Reusable building blocks

    private func sectionContainer<Content: View>(icon: String, title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            ExtrasSectionHeader(icon: icon, title: title)
            content()
        }
        .padding(.horizontal, 20)
    }

    private func chipRow(_ options: [(String, String)], selected: String, action: @escaping (String) -> Void) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(options, id: \.0) { option in
                    GiftChip(text: option.1, isSelected: selected == option.0) {
                        action(option.0)
                    }
                }
            }
            .padding(.horizontal, 1)
        }
    }

    private func ghostPill(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
        }
        .buttonStyle(YDGButtonStyle(kind: .secondary, fullWidth: false, compact: true))
    }

    private func giftTextField(placeholder: String, text: Binding<String>) -> some View {
        TextField("", text: text, prompt: Text(placeholder).foregroundColor(Color.ydgTextTertiary))
            .font(.ydg(.body))
            .foregroundColor(Color.ydgTextPrimary)
            .padding(16)
            .luxeInsetSurface(cornerRadius: 14)
    }

    private func giftTextEditor(placeholder: String, text: Binding<String>) -> some View {
        TextEditor(text: text)
            .font(.ydg(.body))
            .foregroundColor(Color.ydgTextPrimary)
            .scrollContentBackground(.hidden)
            .frame(height: 80)
            .padding(14)
            .luxeInsetSurface(cornerRadius: 14)
            .overlay(
                Group {
                    if text.wrappedValue.isEmpty {
                        Text(placeholder)
                            .font(.ydg(.body))
                            .foregroundColor(Color.ydgTextTertiary)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 22)
                            .allowsHitTesting(false)
                    }
                },
                alignment: .topLeading
            )
    }

    // MARK: - Actions

    private func animate(_ body: () -> Void) {
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.3), body)
    }

    private func normalize(_ s: String) -> String {
        s.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private func saveGift(_ gift: GiftSuggestion) {
        giftStore.addSaved(gift)
        celebrationMessage = "Gift saved!"
        if !reduceMotion { showBoxOpenCelebration = true }
    }

    private func attach(gift: GiftSuggestion) {
        giftStore.addSaved(gift)
        attachedGiftNames.insert(normalize(gift.name))
        celebrationMessage = "Attached to your date!"
        if !reduceMotion { showBoxOpenCelebration = true }
        detailGift = nil
    }

    /// Pre-fill every input from the saved partner/gift profile (only once, into empty fields).
    private func prefillFromProfile() {
        guard !hasPrefilledOnce else { return }
        defer { hasPrefilledOnce = true }
        guard let prefs = UserProfileManager.shared.currentUser?.preferences else { return }
        var didPrefill = false

        if selectedBudget.isEmpty {
            if !prefs.giftBudget.isEmpty {
                selectedBudget = mapBudget(prefs.giftBudget)
                didPrefill = didPrefill || !selectedBudget.isEmpty
            } else if !prefs.defaultBudget.isEmpty {
                selectedBudget = mapBudget(prefs.defaultBudget)
                didPrefill = didPrefill || !selectedBudget.isEmpty
            }
        }

        if selectedOccasion.isEmpty {
            if !prefs.giftOccasion.isEmpty {
                selectedOccasion = prefs.giftOccasion
                didPrefill = true
            } else if let title = datePlan?.title, title.lowercased().contains("date night") {
                selectedOccasion = "date-night"
            }
        }

        if interests.isEmpty {
            if !prefs.giftInterests.isEmpty {
                interests = prefs.giftInterests.joined(separator: ", ")
                didPrefill = true
            } else if !prefs.favoriteActivities.isEmpty {
                let labels = prefs.favoriteActivities.compactMap { value in
                    QuestionnaireOptions.activities.first(where: { $0.value == value })?.label
                }
                if !labels.isEmpty { interests = labels.joined(separator: ", ") }
            }
        }

        if partnerDescription.isEmpty, !prefs.giftNotes.isEmpty {
            partnerDescription = prefs.giftNotes
            didPrefill = true
        }

        if selectedLoveLanguages.isEmpty {
            let langs = prefs.partnerLoveLanguages.isEmpty ? prefs.loveLanguages : prefs.partnerLoveLanguages
            if !langs.isEmpty {
                selectedLoveLanguages = Set(langs)
                didPrefill = true
            }
        }

        if !prefs.giftRecipient.isEmpty { selectedRecipient = prefs.giftRecipient }
        if recipientIdentity.isEmpty, !prefs.giftRecipientIdentity.isEmpty {
            recipientIdentity = prefs.giftRecipientIdentity
            didPrefill = true
        }
        if selectedGiftStyles.isEmpty, !prefs.giftStyle.isEmpty {
            selectedGiftStyles = Set(prefs.giftStyle)
            didPrefill = true
        }
        if favoriteBrands.isEmpty, !prefs.giftFavoriteBrands.isEmpty {
            favoriteBrands = prefs.giftFavoriteBrands
            didPrefill = true
        }
        if recipientSizes.isEmpty, !prefs.giftSizes.isEmpty {
            recipientSizes = prefs.giftSizes
            didPrefill = true
        }

        // Surface the "+ More" section automatically if it holds prefilled data
        if !selectedGiftStyles.isEmpty || !favoriteBrands.isEmpty || !recipientSizes.isEmpty || !recipientIdentity.isEmpty {
            showMore = true
        }

        prefilledFromPartner = didPrefill
        prefillPartnerName = resolvePartnerName()
    }

    private func resolvePartnerName() -> String {
        let mgr = PartnerSessionManager.shared
        guard mgr.partnerState != .none else { return "" }
        if let invite = mgr.inviteInfo?.partnerName.trimmingCharacters(in: .whitespacesAndNewlines), !invite.isEmpty {
            return invite
        }
        if let inviter = mgr.inviterName?.trimmingCharacters(in: .whitespacesAndNewlines), !inviter.isEmpty {
            return inviter
        }
        return ""
    }

    private func mapBudget(_ raw: String) -> String {
        switch raw {
        case "budget": return "25-50"
        case "moderate": return "50-100"
        case "upscale": return "100-200"
        case "luxury": return "200-plus"
        default:
            // Pass through values that already match our tiers.
            return budgetOptions.contains(where: { $0.0 == raw }) ? raw : ""
        }
    }

    private func generateGifts() {
        giftLoadError = nil
        isLoading = true
        let occasion = selectedOccasion
        let budget = selectedBudget
        let interestsText = interests
        // Fold love-language + advanced "+ More" context into the partnerDescription string,
        // which the edge function reads verbatim (we don't widen SupabaseService here).
        let notesText = composedNotes()
        let loc = effectiveLocation
        let planTitle: String? = {
            if let title = datePlan?.title, !title.isEmpty { return title }
            if occasion.isEmpty { return nil }
            let label = occasionOptions.first(where: { $0.0 == occasion })?.1 ?? occasion
            return "Gift Ideas for \(label)"
        }()
        let recipient = selectedRecipient
        let style = selectedGiftStyles.isEmpty ? nil : Array(selectedGiftStyles)

        var existingNames = gifts.map(\.name)
        let boughtNames = giftStore.purchasedGiftNames
        existingNames = Array(Set(existingNames + boughtNames))
        // Pass love languages (dedicated field) and the user's hard-nos so the gift
        // service tailors style and never suggests a dealbreaker item.
        let loveLanguageRaws = selectedLoveLanguages.isEmpty
            ? (UserProfileManager.shared.currentUser?.preferences.loveLanguages.map(\.rawValue) ?? [])
            : selectedLoveLanguages.map(\.rawValue)
        let hardNos = UserProfileManager.shared.currentUser?.preferences.hardNos ?? []
        Task {
            do {
                let result = try await SupabaseService.shared.generateMoreGifts(
                    occasion: occasion.isEmpty ? "just because" : occasion,
                    budget: budget.isEmpty ? nil : budget,
                    interests: interestsText.isEmpty ? nil : interestsText,
                    notes: notesText.isEmpty ? nil : notesText,
                    location: loc.isEmpty ? nil : loc,
                    planTitle: planTitle,
                    existingGiftNames: existingNames,
                    count: 6,
                    recipient: recipient.isEmpty ? nil : recipient,
                    giftStyle: style,
                    loveLanguages: loveLanguageRaws.isEmpty ? nil : loveLanguageRaws,
                    hardNos: hardNos.isEmpty ? nil : hardNos
                )
                await MainActor.run {
                    self.gifts = result
                    self.nearbyStores = self.generateNearbyStores()
                    self.giftLoadError = nil
                    self.isLoading = false
                    withAnimation(reduceMotion ? nil : .spring(response: 0.5)) { self.showResults = true }
                }
            } catch {
                await MainActor.run {
                    self.giftLoadError = error.localizedDescription
                    self.isLoading = false
                    withAnimation(reduceMotion ? nil : .spring(response: 0.5)) { self.showResults = true }
                }
            }
        }
    }

    /// Builds the partnerDescription payload, appending love languages and advanced fields
    /// so they reach the edge function (it parses these from the description/context).
    private func composedNotes() -> String {
        var parts: [String] = []
        let base = partnerDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        if !base.isEmpty { parts.append(base) }
        if !selectedLoveLanguages.isEmpty {
            let langs = selectedLoveLanguages.map { $0.displayName }.joined(separator: ", ")
            parts.append("Love languages: \(langs).")
        }
        let identity = recipientIdentity.trimmingCharacters(in: .whitespacesAndNewlines)
        if !identity.isEmpty { parts.append("Recipient: \(identity).") }
        let brands = favoriteBrands.trimmingCharacters(in: .whitespacesAndNewlines)
        if !brands.isEmpty { parts.append("Favourite brands/stores: \(brands).") }
        let sizes = recipientSizes.trimmingCharacters(in: .whitespacesAndNewlines)
        if !sizes.isEmpty { parts.append("Sizes: \(sizes).") }
        return parts.joined(separator: " ")
    }

    private func resetSearch() {
        animate {
            showResults = false
            gifts = []
            nearbyStores = []
            giftLoadError = nil
        }
    }

    // MARK: - Shop / link helpers

    /// Resolve the best purchase URL: explicit purchaseUrl, else a retailer-specific search
    /// (Amazon/Etsy/Target/Walmart/Nordstrom/Sephora), else Google Shopping.
    private func openShop(for gift: GiftSuggestion) {
        if let s = gift.purchaseUrl, !s.isEmpty, let url = URL(string: s),
           url.scheme == "http" || url.scheme == "https" {
            UIApplication.shared.open(url)
            return
        }
        if let url = URL(string: GiftRetailer.searchURL(giftName: gift.name, whereToBuy: gift.whereToBuy)) {
            UIApplication.shared.open(url)
        }
    }

    private func openStoreNearby(for gift: GiftSuggestion) {
        let query = gift.storeSearchQuery ?? gift.whereToBuy
        openInAppleMaps(query: query, near: mapSearchLocation)
    }

    private func openStoredShop(stored: StoredGift) {
        if let s = stored.purchaseUrl, !s.isEmpty, let url = URL(string: s),
           url.scheme == "http" || url.scheme == "https" {
            UIApplication.shared.open(url)
        } else {
            openStoredSearch(name: stored.name)
        }
    }

    private func openStoredSearch(name: String) {
        let query = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? name
        if let url = URL(string: "https://www.google.com/search?tbm=shop&q=\(query)") {
            UIApplication.shared.open(url)
        }
    }

    private func storedToGiftSuggestion(_ stored: StoredGift) -> GiftSuggestion {
        GiftSuggestion(
            name: stored.name,
            description: stored.description,
            priceRange: stored.priceRange,
            whereToBuy: stored.whereToBuy,
            purchaseUrl: stored.purchaseUrl,
            whyItFits: stored.whyItFits,
            emoji: stored.emoji,
            storeSearchQuery: stored.storeSearchQuery,
            imageUrl: stored.imageUrl
        )
    }

    private func openInAppleMaps(query: String, near location: String) {
        let searchQuery = "\(query) near \(location)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        if let url = URL(string: "maps://?q=\(searchQuery)") {
            UIApplication.shared.open(url)
        }
    }

    // MARK: - Nearby stores model
    private func generateNearbyStores() -> [NearbyStore] {
        var stores: [NearbyStore] = [
            NearbyStore(name: "Jewelry Stores", category: "Fine Jewelry & Watches", searchQuery: "jewelry store", emoji: "💎", giftIdeas: ["Necklaces", "Bracelets", "Watches"]),
            NearbyStore(name: "Florists", category: "Fresh Flowers & Arrangements", searchQuery: "florist flower shop", emoji: "💐", giftIdeas: ["Bouquets", "Roses", "Arrangements"]),
            NearbyStore(name: "Gift Shops", category: "Unique & Curated Gifts", searchQuery: "gift shop boutique", emoji: "🎁", giftIdeas: ["Candles", "Home Decor", "Personalized"]),
            NearbyStore(name: "Wine & Spirits", category: "Fine Wine & Champagne", searchQuery: "wine shop liquor store", emoji: "🍾", giftIdeas: ["Wine", "Champagne", "Gift Sets"]),
            NearbyStore(name: "Chocolatiers", category: "Artisan Chocolates & Sweets", searchQuery: "chocolate shop chocolatier", emoji: "🍫", giftIdeas: ["Truffles", "Gift Boxes", "Bars"]),
            NearbyStore(name: "Bookstores", category: "Books & Journals", searchQuery: "bookstore", emoji: "📚", giftIdeas: ["Books", "Journals", "Accessories"]),
        ]

        if let plan = datePlan {
            for stop in plan.stops {
                let venueType = stop.venueType.lowercased()
                if venueType.contains("spa") || venueType.contains("wellness"),
                   !stores.contains(where: { $0.searchQuery.contains("spa") }) {
                    stores.append(NearbyStore(name: "Spa & Beauty", category: "Wellness & Self-Care", searchQuery: "spa beauty supply skincare", emoji: "🧴", giftIdeas: ["Bath Products", "Skincare", "Aromatherapy"]))
                }
                if venueType.contains("art") || venueType.contains("gallery") || venueType.contains("museum"),
                   !stores.contains(where: { $0.searchQuery.contains("art") }) {
                    stores.append(NearbyStore(name: "Art & Craft Stores", category: "Art Supplies & Prints", searchQuery: "art supply store gallery", emoji: "🎨", giftIdeas: ["Art Prints", "Supplies", "Frames"]))
                }
            }
        }
        return stores
    }
}

// MARK: - Retailer deep-link mapping (parity with web RETAILER_CONFIGS)
enum GiftRetailer {
    private static let configs: [(key: String, base: String)] = [
        ("amazon", "https://www.amazon.com/s?k="),
        ("etsy", "https://www.etsy.com/search?q="),
        ("target", "https://www.target.com/s?searchTerm="),
        ("walmart", "https://www.walmart.com/search?q="),
        ("nordstrom", "https://www.nordstrom.com/sr?keyword="),
        ("sephora", "https://www.sephora.com/search?keyword="),
    ]

    static func searchURL(giftName: String, whereToBuy: String) -> String {
        let query = giftName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? giftName
        let lower = whereToBuy.lowercased()
        for config in configs where lower.contains(config.key) {
            return "\(config.base)\(query)"
        }
        return "https://www.google.com/search?tbm=shop&q=\(query)"
    }
}

// MARK: - Models
struct NearbyStore: Identifiable {
    let id = UUID()
    let name: String
    let category: String
    let searchQuery: String
    let emoji: String
    let giftIdeas: [String]
}

// MARK: - Occasion Card
struct GiftOccasionCard: View {
    let emoji: String
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: YDGSpace.xs) {
                Text(emoji)
                    .font(.system(size: 26))
                    .accessibilityHidden(true)
                Text(title)
                    .font(.ydg(.footnote, weight: isSelected ? .semibold : .medium))
                    .foregroundColor(isSelected ? Color.ydgAccent : Color.ydgTextPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, YDGSpace.sm)
            .background(isSelected ? Color.ydgAccentSubtle : Color.ydgRaised,
                        in: RoundedRectangle(cornerRadius: YDGRadius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: YDGRadius.card, style: .continuous)
                    .stroke(isSelected ? Color.ydgAccent : Color.ydgBorder, lineWidth: isSelected ? 1.5 : 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Selectable chip (Home questionnaire parity)
struct GiftChip: View {
    let text: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        YDGChip(title: text, isSelected: isSelected, showsCheckmark: false, action: action)
    }
}

// MARK: - Filter chip (results budget filter)
private struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        YDGChip(title: title, isSelected: isSelected, showsCheckmark: false, action: action)
    }
}

// MARK: - Nearby Store Card
struct NearbyStoreCard: View {
    let store: NearbyStore
    let location: String

    var body: some View {
        Button {
            openInAppleMaps(query: store.searchQuery, near: location)
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    Text(store.emoji)
                        .font(.system(size: 26))
                        .frame(width: 44, height: 44)
                        .background(Color.ydgOverlay, in: RoundedRectangle(cornerRadius: YDGRadius.chip, style: .continuous))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(store.name)
                            .ydgText(.subhead, weight: .semibold)
                        Text(store.category)
                            .ydgText(.footnote, color: .ydgTextSecondary)
                            .lineLimit(1)
                    }
                }

                HStack(spacing: 4) {
                    ForEach(store.giftIdeas.prefix(3), id: \.self) { idea in
                        Text(idea)
                            .font(.ydg(.caption))
                            .foregroundColor(Color.ydgTextPrimary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.ydgOverlay, in: RoundedRectangle(cornerRadius: 4))
                    }
                }

                HStack(spacing: 4) {
                    Image(systemName: "map.fill")
                        .font(.system(size: 10))
                    Text("Open in Maps")
                        .font(.ydg(.footnote, weight: .semibold))
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 9))
                }
                .foregroundColor(Color.ydgTextSecondary)
            }
            .frame(width: 180, alignment: .leading)
            .ydgCard(padding: YDGSpace.sm)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private func openInAppleMaps(query: String, near location: String) {
        let searchQuery = "\(query) near \(location)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        if let url = URL(string: "maps://?q=\(searchQuery)") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Gift Result Card (24b)
struct GiftResultCard: View {
    let gift: GiftSuggestion
    var isSaved: Bool = false
    var isBought: Bool = false
    var onOpenDetail: () -> Void
    var onSave: () -> Void
    var onShop: () -> Void
    var onFindNearby: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: YDGSpace.sm) {
            Button(action: onOpenDetail) {
                VStack(alignment: .leading, spacing: YDGSpace.sm) {
                    HStack(alignment: .top, spacing: YDGSpace.sm) {
                        Text(gift.emoji)
                            .font(.system(size: 32))
                            .frame(width: 72, height: 72)
                            .background(Color.ydgOverlay, in: RoundedRectangle(cornerRadius: YDGRadius.chip, style: .continuous))
                            .accessibilityHidden(true)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(gift.name)
                                .ydgText(.headline)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                            Text(isBought ? "Bought" : gift.priceRange)
                                .ydgText(.subhead, weight: .semibold, color: isBought ? .ydgSuccess : .ydgTextPrimary)
                            if !gift.whereToBuy.isEmpty {
                                Text(gift.whereToBuy)
                                    .ydgText(.footnote, color: .ydgTextSecondary)
                                    .lineLimit(1)
                            }
                        }
                        Spacer(minLength: 0)
                    }

                    Text(gift.whyItFits.isEmpty ? gift.description : gift.whyItFits)
                        .ydgText(.subhead, weight: .regular, color: .ydgTextSecondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint("Shows details")

            HStack(spacing: YDGSpace.xs) {
                Button(isSaved ? "Saved" : "Save", action: onSave)
                    .buttonStyle(YDGButtonStyle(kind: .secondary, fullWidth: false, compact: true))
                    .disabled(isSaved)
                Button(action: onFindNearby) {
                    Image(systemName: "mappin")
                }
                .buttonStyle(YDGButtonStyle(kind: .secondary, fullWidth: false, compact: true))
                .accessibilityLabel("Find nearby")
                Button("Shop now", action: onShop)
                    .buttonStyle(YDGButtonStyle(kind: .accentOutline, compact: true))
            }
            .padding(.top, YDGSpace.xxs)
        }
        .ydgCard()
    }
}

// MARK: - Gift Detail Sheet (24c) — ship-by + gift wrap + attach to date
struct GiftDetailSheet: View {
    let gift: GiftSuggestion
    let datePlan: DatePlan?
    let location: String
    var isAttached: Bool
    var onShop: () -> Void
    var onAttach: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var giftWrap = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.backgroundPrimary.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        // Hero
                        HStack(alignment: .top, spacing: 16) {
                            Text(gift.emoji)
                                .font(.system(size: 44))
                                .frame(width: 72, height: 72)
                                .background(Color.ydgRaised)
                                .cornerRadius(16)
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.ydgBorder, lineWidth: 1))
                            VStack(alignment: .leading, spacing: 6) {
                                Text(gift.name)
                                    .ydgText(.title2)
                                    .fixedSize(horizontal: false, vertical: true)
                                Text(gift.priceRange)
                                    .ydgText(.subhead, weight: .semibold)
                            }
                            Spacer()
                        }

                        if !gift.description.isEmpty {
                            Text(gift.description)
                                .font(Font.bodySans(15, weight: .regular))
                                .foregroundColor(Color.luxuryCreamMuted)
                        }

                        if !gift.whyItFits.isEmpty {
                            detailBlock(title: "Why it fits", body: gift.whyItFits)
                        }
                        if !gift.whereToBuy.isEmpty {
                            detailBlock(title: "Where to buy", body: gift.whereToBuy)
                        }

                        // Ship-by relative to the planned date
                        shippingBlock

                        // Gift wrap toggle
                        Toggle(isOn: $giftWrap) {
                            HStack(spacing: 8) {
                                Image(systemName: "gift")
                                    .foregroundColor(Color.ydgTextSecondary)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Add gift wrap")
                                        .font(Font.bodySans(15, weight: .semibold))
                                        .foregroundColor(Color.textPrimary)
                                    Text("Most retailers offer wrap at checkout")
                                        .font(Font.bodySans(12, weight: .regular))
                                        .foregroundColor(Color.luxuryCreamMuted)
                                }
                            }
                        }
                        .tint(Color.ydgAccent)
                        .padding(16)
                        .background(Color.ydgRaised)
                        .cornerRadius(14)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.ydgBorder, lineWidth: 1))

                        // Attach to date (maroon outline) + Shop Now (the one gold CTA)
                        if let plan = datePlan {
                            Button(action: onAttach) {
                                Label(isAttached ? "Attached to \(plan.title)" : "Attach to \(plan.title)",
                                      systemImage: isAttached ? "checkmark" : "paperclip")
                            }
                            .buttonStyle(.ydgSecondary)
                            .disabled(isAttached)
                        }

                        Button("Shop now", action: onShop)
                            .buttonStyle(.ydgPrimary)
                    }
                    .padding(20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Gift details")
                        .ydgText(.headline)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.ydg(.body, weight: .semibold))
                        .foregroundColor(Color.ydgAccent)
                }
            }
            .toolbarBackground(Color.ydgBase, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }

    private func detailBlock(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .ydgText(.caption)
            Text(body)
                .font(Font.bodySans(15, weight: .regular))
                .foregroundColor(Color.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.ydgRaised)
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.ydgBorder, lineWidth: 1))
    }

    @ViewBuilder
    private var shippingBlock: some View {
        let info = shippingInfo()
        HStack(spacing: 10) {
            Image(systemName: info.systemImage)
                .font(.system(size: 18))
                .foregroundColor(Color.ydgTextSecondary)
            VStack(alignment: .leading, spacing: 2) {
                Text("Shipping")
                    .ydgText(.caption)
                Text(info.text)
                    .font(Font.bodySans(14, weight: .semibold))
                    .foregroundColor(Color.textPrimary)
            }
            Spacer()
        }
        .padding(16)
        .background(Color.ydgRaised)
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.ydgBorder, lineWidth: 1))
    }

    /// Estimate delivery relative to the planned date (standard shipping ≈ 5 days).
    private func shippingInfo() -> (text: String, systemImage: String) {
        guard let date = datePlan?.scheduledDate else {
            return ("Add a date to your plan to see arrival estimates", "shippingbox")
        }
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: Date()), to: calendar.startOfDay(for: date)).day ?? 0
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        let weekday = formatter.string(from: date)
        if days < 0 {
            return ("Your date has passed — order anytime", "shippingbox")
        } else if days >= 5 {
            return ("Order now and it arrives before \(weekday)", "shippingbox")
        } else if days >= 1 {
            return ("Tight — choose expedited shipping to arrive before \(weekday)", "exclamationmark.triangle")
        } else {
            return ("Date is today — buy in store or choose a digital gift", "bolt")
        }
    }
}

#Preview {
    GiftFinderView(datePlan: DatePlan.sample, dateLocation: "San Francisco, CA")
}
