import SwiftUI

/// "Convo" tab — nurture connection between dates: Love Notes · Conversation Starters.
struct ConvoTabView: View {
    @EnvironmentObject var coordinator: NavigationCoordinator
    @EnvironmentObject private var access: AccessManager
    @State private var segment: Segment = .notes

    enum Segment: String, CaseIterable, Identifiable {
        case notes = "Love Notes"
        case sparks = "Conversation Starters"
        var id: String { rawValue }
    }

    var body: some View {
        ZStack {
            CharcoalMaroonBackground()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                segmentPicker
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 8)

                Group {
                    switch segment {
                    case .notes:
                        if access.canAccess(.loveNotes) {
                            LoveNoteGeneratorView()
                        } else {
                            LockedPremiumTabPlaceholder(
                                feature: .loveNotes,
                                title: "Love Notes",
                                subtitle: "Write heartfelt Love Notes and AI-enhanced messages for your partner."
                            )
                        }
                    case .sparks:
                        ConversationStartersView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private var segmentPicker: some View {
        HStack(spacing: 6) {
            ForEach(Segment.allCases) { item in
                let isSelected = segment == item
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) { segment = item }
                } label: {
                    Text(item.rawValue)
                        .font(Font.bodySans(13, weight: isSelected ? .semibold : .regular))
                        .foregroundColor(isSelected ? Color.textPrimary : Color.luxuryCreamMuted)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(
                            isSelected
                                ? AnyShapeStyle(Color.accentMaroon.opacity(0.35))
                                : AnyShapeStyle(Color.clear)
                        )
                        .overlay(alignment: .bottom) {
                            if isSelected {
                                Rectangle()
                                    .fill(Color.accentMaroon)
                                    .frame(height: 2)
                                    .padding(.horizontal, 8)
                            }
                        }
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Color.surfaceElevated)
        .clipShape(Capsule())
        .overlay(
            Capsule().stroke(Color.accentGold.opacity(0.2), lineWidth: 1)
        )
    }
}
