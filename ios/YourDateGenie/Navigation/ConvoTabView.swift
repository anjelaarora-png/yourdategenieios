import SwiftUI

/// "Convo" tab — nurture connection between dates: Love Notes · Conversation Starters.
struct ConvoTabView: View {
    @EnvironmentObject var coordinator: NavigationCoordinator
    @EnvironmentObject private var access: AccessManager
    @State private var segment: Segment = .notes

    enum Segment: String, CaseIterable, Identifiable {
        case notes = "Love notes"
        case sparks = "Talk sparks"
        var id: String { rawValue }
    }

    var body: some View {
        ZStack {
            Color.ydgBase
                .ignoresSafeArea()

            VStack(spacing: 0) {
                YDGLargeTitle(title: "Notes")
                    .padding(.bottom, YDGSpace.md)
                segmentPicker
                    .padding(.horizontal, YDGSpace.margin)
                    .padding(.bottom, YDGSpace.xs)

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
                        ConversationStartersView(isEmbeddedInTab: true)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private var segmentPicker: some View {
        YDGSegmentedControl(options: Segment.allCases, selection: $segment) { $0.rawValue }
    }
}
