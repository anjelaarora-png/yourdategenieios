import SwiftUI

struct Step3VibeView: View {
    @Binding var data: QuestionnaireData
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                // Energy Level
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(
                        emoji: "⚡",
                        title: "What's the energy?",
                        subtitle: "Set the pace for your date"
                    )
                    
                    VStack(spacing: 10) {
                        ForEach(QuestionnaireOptions.energyLevels) { level in
                            MultiSelectOptionCard(
                                item: level,
                                isSelected: data.energyLevel == level.value,
                                onTap: { data.energyLevel = level.value }
                            )
                        }
                    }
                }
                
                // Duration
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(emoji: "⏱️", title: "How long?")
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ForEach(QuestionnaireOptions.durations) { duration in
                            OptionCardView(
                                item: duration,
                                isSelected: data.duration == duration.value,
                                onTap: { data.duration = duration.value }
                            )
                        }
                    }
                }
                
                // Activities
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(
                        emoji: "🎯",
                        title: "What activities interest you?",
                        subtitle: "Select all that apply"
                    )
                    
                    FlowLayout(spacing: 10) {
                        ForEach(QuestionnaireOptions.activities) { activity in
                            ChipOptionView(
                                item: activity,
                                isSelected: data.activityPreferences.contains(activity.value),
                                onTap: {
                                    toggleSelection(activity.value, in: &data.activityPreferences)
                                }
                            )
                        }
                    }
                }
            }
            .padding(20)
        }
    }
    
    private func toggleSelection(_ value: String, in array: inout [String]) {
        if let index = array.firstIndex(of: value) {
            array.remove(at: index)
        } else {
            array.append(value)
        }
    }
}

// MARK: - Flow Layout for Chips
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                      y: bounds.minY + result.positions[index].y),
                          proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
                
                self.size.width = max(self.size.width, x)
            }
            
            self.size.height = y + rowHeight
        }
    }
}

#Preview {
    Step3VibeView(data: .constant(QuestionnaireData()))
        .background(Color.luxuryMaroon)
}
