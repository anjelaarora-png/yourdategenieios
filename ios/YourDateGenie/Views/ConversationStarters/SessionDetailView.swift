import SwiftUI

// MARK: - Session detail (list of session's sparks, read-only with saved indicator)
struct SessionDetailView: View {
    let session: SparkSession
    let onDismiss: () -> Void
    @StateObject private var storage = ConversationStarterStorageManager.shared

    private var relationshipLabel: String {
        ConversationOpenerContent.relationshipStages.first(where: { $0.value == session.relationshipStage })?.label ?? session.relationshipStage
    }

    private var vibeLabel: String {
        ConversationOpenerContent.vibeOptions.first(where: { $0.value == session.mood })?.label
            ?? ConversationOpenerContent.moods.first(where: { $0.value == session.mood })?.label
            ?? session.mood
    }

    var body: some View {
        ZStack {
            Color.luxuryMaroon
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Button {
                        onDismiss()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .symbolRenderingMode(.monochrome)
                            Text("Back")
                                .font(Font.bodySans(16, weight: .semibold))
                        }
                        .foregroundColor(Color.luxuryGold)
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 8)

                Text("\(relationshipLabel) · \(vibeLabel)")
                    .font(Font.bodySans(20, weight: .semibold))
                    .foregroundColor(Color.luxuryCream)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(session.sparks) { spark in
                            SessionSparkRow(
                                spark: spark,
                                isSaved: storage.isSaved(openingQuestion: spark.openingQuestion)
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
    }
}

// MARK: - Single spark row (read-only, heart if saved)
private struct SessionSparkRow: View {
    let spark: SparkItem
    let isSaved: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(spark.tagsLabel)
                    .font(Font.bodySans(11, weight: .semibold))
                    .foregroundColor(Color.luxuryMuted)
                Spacer()
                if isSaved {
                    Image(systemName: "heart.fill")
                        .font(Font.bodySans(14, weight: .regular))
                        .symbolRenderingMode(.monochrome)
                        .foregroundColor(Color.luxuryGold)
                }
            }
            Text(spark.openingQuestion)
                .font(Font.bodySans(15, weight: .regular))
                .foregroundColor(Color.luxuryCream)
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
}
