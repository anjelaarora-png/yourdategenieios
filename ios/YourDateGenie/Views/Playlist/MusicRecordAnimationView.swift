import SwiftUI

/// Spinning vinyl record with musical notes coming out of it (for Create Your Soundtrack and generating state).
struct MusicRecordAnimationView: View {
    var size: CGFloat = 80
    var showNotes: Bool = true
    
    @State private var isSpinning = true
    @State private var notePhase: CGFloat = 0
    
    var body: some View {
        ZStack {
            if showNotes {
                // Musical notes emanating from the vinyl
                NoteView(size: size, index: 0, phase: notePhase)
                NoteView(size: size, index: 1, phase: notePhase)
                NoteView(size: size, index: 2, phase: notePhase)
                NoteView(size: size, index: 3, phase: notePhase)
                NoteView(size: size, index: 4, phase: notePhase)
                NoteView(size: size, index: 5, phase: notePhase)
                NoteView(size: size, index: 6, phase: notePhase)
                NoteView(size: size, index: 7, phase: notePhase)
            }
            
            // Vinyl record
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.luxuryMuted.opacity(0.5),
                                Color.luxuryCream.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: size, height: size)
                    .overlay(
                        Circle()
                            .stroke(Color.luxuryGold.opacity(0.5), lineWidth: 2)
                    )
                
                // Groove rings
                ForEach([0.92, 0.78, 0.64], id: \.self) { scale in
                    Circle()
                        .stroke(Color.luxuryCream.opacity(0.14), lineWidth: 1)
                        .frame(width: size * scale, height: size * scale)
                }
                
                // Center label
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.luxuryGold.opacity(0.9), Color.luxuryGold.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: size * 0.32, height: size * 0.32)
                    .overlay(Circle().stroke(Color.luxuryGold, lineWidth: 2))
                    .overlay(
                        Circle()
                            .fill(Color.luxuryMaroon.opacity(0.8))
                            .frame(width: size * 0.12, height: size * 0.12)
                    )
            }
            .rotationEffect(.degrees(isSpinning ? 360 : 0))
            .animation(
                .linear(duration: 4).repeatForever(autoreverses: false),
                value: isSpinning
            )
        }
        .frame(width: size * 1.9, height: size * 1.9)
        .onAppear {
            isSpinning = true
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                notePhase = 1
            }
        }
        .accessibilityHidden(true)
    }
}

private struct NoteView: View {
    let size: CGFloat
    let index: Int
    let phase: CGFloat
    var body: some View {
        let angleDeg = Double(index) * 45 + Double(phase) * 25
        let rad = angleDeg * .pi / 180
        let r = size * (0.56 + Double(index % 3) * 0.1)
        let x = cos(rad) * r
        let y = sin(rad) * r
        Text(index.isMultiple(of: 2) ? "♪" : "♫")
            .font(.system(size: size * (0.2 + Double(index % 3) * 0.03)))
            .foregroundStyle(
                LinearGradient(
                    colors: [Color.luxuryGold.opacity(0.9), Color.luxuryGold.opacity(0.5)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .shadow(color: Color.luxuryGold.opacity(0.35), radius: 2)
            .offset(x: x, y: y)
            .opacity(0.9 - Double(index % 2) * 0.2)
    }
}

#Preview {
    ZStack {
        Color.luxuryMaroon.ignoresSafeArea()
        MusicRecordAnimationView(size: 88, showNotes: true)
    }
}
