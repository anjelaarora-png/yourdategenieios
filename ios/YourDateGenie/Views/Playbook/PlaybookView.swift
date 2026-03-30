import SwiftUI

// MARK: - Playbook Sheet (grid + category detail with shuffle)
struct PlaybookView: View {
    @EnvironmentObject var coordinator: NavigationCoordinator
    @State private var selectedCategory: PlaybookCategory?
    @State private var displayedTips: [String] = []
    @State private var shuffledOrder: [String] = []
    @State private var currentTipIndex: Int = 0

    private var preferences: DatePreferences {
        UserProfileManager.shared.currentUser?.preferences ?? DatePreferences()
    }

    private var comboKey: PlaybookComboKey {
        PlaybookComboKey.from(userGender: preferences.gender, partnerGender: preferences.partnerGender)
    }

    private var tipsForSelectedCategory: [String] {
        guard let cat = selectedCategory else { return [] }
        return PlaybookContent.tips(categoryId: cat.id, comboKey: comboKey)
    }

    private var tipsToShow: [String] {
        if shuffledOrder.isEmpty { return tipsForSelectedCategory }
        return shuffledOrder
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.luxuryMaroon
                    .ignoresSafeArea()

                if selectedCategory == nil {
                    categoryGrid
                } else {
                    categoryDetailView
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.luxuryMaroon, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if selectedCategory != nil {
                        Button {
                            selectedCategory = nil
                            shuffledOrder = []
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "chevron.left")
                                    .symbolRenderingMode(.monochrome)
                                Text("Back")
                            }
                            .font(Font.bodySans(15, weight: .medium))
                            .foregroundColor(Color.luxuryGold)
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        coordinator.dismissSheet()
                    } label: {
                        Text("Done")
                            .font(Font.bodySans(15, weight: .semibold))
                            .foregroundColor(Color.luxuryGold)
                    }
                }
            }
        }
    }

    private var categoryGrid: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                Text("DATING TIPS")
                    .font(Font.bodySans(12, weight: .semibold))
                    .tracking(2)
                    .foregroundColor(Color.luxuryGold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 4)
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("Find the tip made for ")
                        .font(Font.header(26, weight: .regular))
                        .foregroundColor(Color.luxuryCream)
                    Text("you")
                        .font(Font.tangerine(38, weight: .bold))
                        .italic()
                        .foregroundColor(Color.luxuryGold)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 4)
                Text("Pick a category. Personalised to your situation.")
                    .font(Font.bodySans(14, weight: .regular))
                    .foregroundColor(Color.luxuryCreamMuted)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 4)
                    .padding(.top, -4)
                    .padding(.bottom, 8)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(PlaybookContent.categories) { category in
                        Button {
                            selectedCategory = category
                            shuffledOrder = []
                            currentTipIndex = 0
                        } label: {
                            VStack(spacing: 10) {
                                Image(systemName: category.sfSymbol)
                                    .font(.system(size: 26))
                                    .symbolRenderingMode(.monochrome)
                                    .foregroundColor(Color.luxuryGold)
                                Text(category.title)
                                    .font(Font.bodySans(13, weight: .semibold))
                                    .foregroundColor(Color.luxuryCream)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(Color.luxuryMaroonLight)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.luxuryGold.opacity(0.25), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 24)
        }
    }

    private var categoryDetailView: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let cat = selectedCategory {
                HStack {
                    Text("• \(cat.title.uppercased())")
                        .font(Font.bodySans(12, weight: .semibold))
                        .tracking(2)
                        .foregroundColor(Color.luxuryGold)
                    Spacer()
                    Button {
                        shuffledOrder = tipsForSelectedCategory.shuffled()
                        currentTipIndex = 0
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "shuffle")
                                .symbolRenderingMode(.monochrome)
                            Text("Shuffle")
                        }
                        .font(Font.bodySans(13, weight: .medium))
                        .foregroundColor(Color.luxuryGold)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 4)

                Text("Swipe left or right for next tip")
                    .font(Font.bodySans(12, weight: .regular))
                    .foregroundColor(Color.luxuryCreamMuted)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
            }

            if !tipsToShow.isEmpty {
                TabView(selection: $currentTipIndex) {
                    ForEach(Array(tipsToShow.enumerated()), id: \.offset) { index, tip in
                        playbookTipCard(index: index + 1, tip: tip, total: tipsToShow.count)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .automatic))
                .indexViewStyle(.page(backgroundDisplayMode: .always))
            }
        }
    }

    private func playbookTipCard(index: Int, tip: String, total: Int) -> some View {
        let categoryLabel = selectedCategory?.title.uppercased() ?? "TIP"
        return VStack(spacing: 0) {
            VStack(spacing: 16) {
                Text("Tip \(index) of \(total)")
                    .font(Font.bodySans(11, weight: .regular))
                    .tracking(2)
                    .foregroundColor(Color.luxuryMuted)
                Text("• \(categoryLabel)")
                    .font(Font.bodySans(11, weight: .semibold))
                    .tracking(2.5)
                    .foregroundColor(Color.luxuryGold)
                Text(tip)
                    .font(Font.bodySans(16, weight: .regular))
                    .foregroundColor(Color.luxuryCream)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 8)
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.luxuryMaroonLight.opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.luxuryGold.opacity(0.35), lineWidth: 1)
                )
                .overlay(
                    VStack(spacing: 0) {
                        RoundedRectangle(cornerRadius: 19)
                            .fill(
                                LinearGradient(
                                    colors: [Color.luxuryGold.opacity(0.35), Color.luxuryGold.opacity(0.08), Color.clear],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(height: 5)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 2)
                        Spacer(minLength: 0)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                )
        )
        .padding(.horizontal, 20)
    }
}
