import SwiftUI

/// A collapsible contextual help card for questionnaire steps.
struct StepHelpCard: View {
    @Binding var isExpanded: Bool
    let hint: String
    let explanation: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "questionmark.circle")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color.luxuryGold)

                    Text(hint)
                        .font(Font.bodySans(14, weight: .medium))
                        .foregroundColor(Color.luxuryGold)

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color.luxuryGold.opacity(0.7))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(minHeight: 44)
            }
            .buttonStyle(.plain)

            if isExpanded {
                Text(explanation)
                    .font(Font.bodySans(14, weight: .regular))
                    .foregroundColor(Color.luxuryCreamMuted)
                    .lineSpacing(4)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 14)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color.luxuryGold.opacity(0.08))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.luxuryGold.opacity(0.25), lineWidth: 1)
        )
    }
}
