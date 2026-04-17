import SwiftUI

// MARK: - FAQ data model (file-private)
private struct FAQItem: Identifiable {
    let id = UUID()
    let question: String
    let answer: String
}

// MARK: - Help & Support Sheet

struct HelpSupportSheetView: View {
    @Environment(\.dismiss) private var dismiss

    private let faqs: [FAQItem] = [
        FAQItem(question: "How do I plan a date?",
                answer: "Tap \'Plan My Next Date\' on the home screen. Answer a few quick questions about location, vibe, food, and budget. The app then builds a complete multi-stop evening for you in seconds."),
        FAQItem(question: "Can I save a date plan and use it later?",
                answer: "Yes! After the app generates your plans, tap the gold Save button on any option. Saved plans appear on your home screen and in Profile > Saved Plans."),
        FAQItem(question: "How does Partner Planning work?",
                answer: "Tap \'Plan Together\' on the home screen. Enter your partner\'s name. They receive a link — no account needed. You both answer questions separately, then the app shows you the best matching date."),
        FAQItem(question: "How do I make a reservation?",
                answer: "Open any saved date plan and tap the Reserve button at the bottom. You can book via OpenTable, Resy, or call the restaurant directly."),
        FAQItem(question: "What does Premium include?",
                answer: "Premium unlocks Love Notes (write heartfelt messages), Gift Finder (personalized gift ideas), and Memories (a photo timeline of your dates). Date planning is always free."),
        FAQItem(question: "How do I cancel my subscription?",
                answer: "Go to iPhone Settings > tap your name > Subscriptions > Your Date Genie. You can cancel or manage your plan there at any time."),
    ]

    @State private var expandedFAQId: UUID?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.luxuryMaroon.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Frequently Asked Questions")
                                .font(Font.header(18, weight: .bold))
                                .foregroundColor(Color.luxuryCream)
                                .padding(.bottom, 8)

                            ForEach(faqs) { faq in
                                FAQRowView(item: faq, isExpanded: expandedFAQId == faq.id) {
                                    withAnimation(.easeInOut(duration: 0.25)) {
                                        expandedFAQId = expandedFAQId == faq.id ? nil : faq.id
                                    }
                                }
                            }
                        }
                        .padding(20)
                        .luxuryCard()

                        Link(destination: URL(string: "mailto:hello@yourdategenie.com")!) {
                            HStack(spacing: 14) {
                                Image(systemName: "envelope.fill")
                                    .foregroundColor(Color.luxuryGold)
                                    .frame(width: 24)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Email Us")
                                        .font(Font.bodySans(15, weight: .semibold))
                                        .foregroundColor(Color.luxuryCream)
                                    Text("hello@yourdategenie.com")
                                        .font(Font.bodySans(13, weight: .regular))
                                        .foregroundColor(Color.luxuryMuted)
                                }
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color.luxuryMuted)
                            }
                            .padding(.horizontal, 18)
                            .padding(.vertical, 14)
                            .frame(minHeight: 56)
                            .background(Color.luxuryMaroonLight.opacity(0.7))
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.luxuryGold.opacity(0.3), lineWidth: 1))
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle("Help & Support")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.luxuryMaroon, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Color.luxuryGold)
                }
            }
        }
    }
}

// MARK: - FAQ Row

private struct FAQRowView: View {
    let item: FAQItem
    let isExpanded: Bool
    let onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: onTap) {
                HStack(spacing: 12) {
                    Text(item.question)
                        .font(Font.bodySans(15, weight: .medium))
                        .foregroundColor(Color.luxuryCream)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color.luxuryMuted)
                }
                .padding(.vertical, 16)
                .frame(minHeight: 44)
            }
            .buttonStyle(.plain)

            if isExpanded {
                Text(item.answer)
                    .font(Font.bodySans(14, weight: .regular))
                    .foregroundColor(Color.luxuryCreamMuted)
                    .lineSpacing(4)
                    .padding(.bottom, 14)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            Divider()
                .background(Color.luxuryGold.opacity(0.15))
        }
    }
}
