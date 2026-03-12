import SwiftUI

// MARK: - Conversation Starters Sheet
struct ConversationStartersView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var coordinator: NavigationCoordinator

    private var starters: [ConversationStarter] {
        if let plan = coordinator.currentDatePlan, let s = plan.conversationStarters, !s.isEmpty {
            return s
        }
        return ConversationStartersView.defaultStarters
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.luxuryMaroon
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Spark meaningful connection with questions that go beyond small talk.")
                            .font(Font.bodySans(14, weight: .regular))
                            .foregroundColor(Color.luxuryCreamMuted)
                            .padding(.horizontal, 4)

                        ForEach(starters) { starter in
                            ConversationStarterCard(starter: starter)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Conversation Starters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.luxuryMaroon, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                            .font(Font.bodySans(15, weight: .semibold))
                            .foregroundColor(Color.luxuryGold)
                    }
                }
            }
        }
    }
}

// MARK: - Starter Card
private struct ConversationStarterCard: View {
    let starter: ConversationStarter
    @State private var copied = false

    var body: some View {
        Button {
            UIPasteboard.general.string = starter.question
            copied = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                copied = false
            }
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Text(starter.emoji)
                        .font(.system(size: 20))
                    Text(starter.category)
                        .font(Font.bodySans(12, weight: .semibold))
                        .foregroundColor(Color.luxuryGold)
                    Spacer()
                    if copied {
                        Text("Copied!")
                            .font(Font.bodySans(11, weight: .medium))
                            .foregroundColor(Color.luxurySuccess)
                    } else {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 12))
                            .foregroundColor(Color.luxuryMuted)
                    }
                }

                Text(starter.question)
                    .font(Font.playfairItalic(15))
                    .foregroundColor(Color.luxuryCream)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.luxuryMaroonLight.opacity(0.9))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.luxuryGold.opacity(0.25), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Default Starters (when no plan context)
extension ConversationStartersView {
    static let defaultStarters: [ConversationStarter] = [
        ConversationStarter(question: "What’s something you’re really proud of that most people don’t know about?", category: "Dreams", emoji: "✨"),
        ConversationStarter(question: "If you could have dinner with anyone, living or not, who would it be and why?", category: "Connection", emoji: "💭"),
        ConversationStarter(question: "What’s a small moment recently that made you really happy?", category: "Joy", emoji: "🌻"),
        ConversationStarter(question: "What’s a place you’ve always wanted to go, and what would you do there first?", category: "Adventure", emoji: "🗺️"),
        ConversationStarter(question: "What’s something you used to believe that you’ve changed your mind about?", category: "Growth", emoji: "🦋"),
        ConversationStarter(question: "What’s your go-to song or movie when you need to feel better?", category: "Comfort", emoji: "🎵")
    ]
}

#Preview {
    ConversationStartersView()
        .environmentObject(NavigationCoordinator.shared)
}
