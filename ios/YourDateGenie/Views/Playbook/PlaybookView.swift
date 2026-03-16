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
                VStack(spacing: 6) {
                    Text("Date Tips")
                        .font(Font.tangerine(32, weight: .bold))
                        .italic()
                        .foregroundColor(Color.luxuryGold)
                    Text("Opinionated date advice for your situation")
                        .font(Font.bodySans(14, weight: .regular))
                        .foregroundColor(Color.luxuryCreamMuted)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 8)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(PlaybookContent.categories) { category in
                        Button {
                            selectedCategory = category
                            shuffledOrder = []
                            currentTipIndex = 0
                        } label: {
                            VStack(spacing: 10) {
                                Text(category.emoji)
                                    .font(.system(size: 28))
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
                    Text(cat.emoji)
                        .font(.system(size: 24))
                    Text(cat.title)
                        .font(Font.header(18, weight: .semibold))
                        .foregroundColor(Color.luxuryCream)
                    Spacer()
                    Button {
                        shuffledOrder = tipsForSelectedCategory.shuffled()
                        currentTipIndex = 0
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "shuffle")
                            Text("Shuffle")
                        }
                        .font(Font.bodySans(13, weight: .medium))
                        .foregroundColor(Color.luxuryGold)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 8)

                Text("Swipe left or right for next tip")
                    .font(Font.bodySans(12, weight: .regular))
                    .foregroundColor(Color.luxuryCreamMuted)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
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
        VStack(spacing: 16) {
            Text("Tip \(index) of \(total)")
                .font(Font.bodySans(12, weight: .medium))
                .foregroundColor(Color.luxuryGold)

            Text(tip)
                .font(Font.bodySans(16, weight: .regular))
                .foregroundColor(Color.luxuryCream)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 28)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.luxuryMaroonLight.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.luxuryGold.opacity(0.25), lineWidth: 1)
                )
        )
        .padding(.horizontal, 20)
    }
}
