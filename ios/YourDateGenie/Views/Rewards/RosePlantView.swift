import SwiftUI

// MARK: - Rose Plant Illustration (G1 / G2 centerpiece)
//
// Hand-ported from the redesign mockup SVG (YDG_full_app_redesign.html, Act 4).
// Draws on a 146×146 canvas. Two modes:
//   • .blooming(open:total:) — upright stem, `open` rose blooms + remaining buds
//   • .drooping              — bent stem, one faded bloom, a fallen petal
//
// Reduce-Motion aware: a gentle one-shot bloom/sway plays on appear unless the
// user has Reduce Motion enabled, in which case it renders fully open & still.

struct RosePlantView: View {
    enum Mode: Equatable {
        case blooming(open: Int, total: Int)
        case drooping
    }

    let mode: Mode
    var size: CGFloat = 146

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var grow: CGFloat = 0

    private let base: CGFloat = 146

    var body: some View {
        Canvas { context, _ in
            switch mode {
            case let .blooming(open, total):
                drawBlooming(in: context, open: open, total: total, grow: grow)
            case .drooping:
                drawDrooping(in: context, grow: grow)
            }
        }
        .frame(width: size, height: size)
        .scaleEffect(reduceMotion ? 1 : (0.96 + 0.04 * grow))
        .onAppear {
            if reduceMotion {
                grow = 1
            } else {
                withAnimation(.spring(response: 0.9, dampingFraction: 0.7)) { grow = 1 }
            }
        }
        .accessibilityElement()
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        switch mode {
        case let .blooming(open, total): return "Rose with \(open) of \(total) blooms open"
        case .drooping: return "A drooping rose, waiting to be revived"
        }
    }

    private var scale: CGFloat { size / base }
    private func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * scale, y: y * scale) }

    // MARK: Blooming

    private func drawBlooming(in context: GraphicsContext, open: Int, total: Int, grow: CGFloat) {
        let stem = Path { path in
            path.move(to: p(73, 140))
            path.addCurve(to: p(73, 72), control1: p(70, 112), control2: p(70, 96))
        }
        context.stroke(stem, with: .color(.roseStem), style: StrokeStyle(lineWidth: 5 * scale, lineCap: .round))

        // Side branches each carry a bloom/bud.
        let branches = [
            (p(73, 116), p(58, 110), p(50, 102), p(47, 90)),
            (p(73, 104), p(88, 99), p(96, 91), p(99, 80)),
            (p(73, 92), p(66, 84), p(62, 78), p(61, 67))
        ]
        for b in branches {
            let branch = Path { path in
                path.move(to: b.0)
                path.addCurve(to: b.3, control1: b.1, control2: b.2)
            }
            context.stroke(branch, with: .color(.roseStem), style: StrokeStyle(lineWidth: 4 * scale))
        }

        drawLeaf(in: context, center: p(56, 124), rx: 9, ry: 4, rotation: -28)
        drawLeaf(in: context, center: p(92, 114), rx: 9, ry: 4, rotation: 28)

        // Four flower slots; first `open` are blooms, the rest are buds.
        let slots: [(CGPoint, Bool)] = [
            (p(45, 86), 0 < open),
            (p(99, 78), 1 < open),
            (p(61, 61), 2 < open),
            (p(74, 66), 3 < open)
        ]
        let shown = min(total, slots.count)
        for i in 0..<shown {
            let (center, isOpen) = slots[i]
            if isOpen {
                drawBloom(in: context, center: center, grow: grow)
            } else {
                drawBud(in: context, center: center)
            }
        }
    }

    private func drawBloom(in context: GraphicsContext, center: CGPoint, grow: CGFloat) {
        let r = (13 * scale) * (0.6 + 0.4 * grow)
        let outer = Path(ellipseIn: CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2))
        context.fill(outer, with: .color(.rosePetalOuter))

        let r2 = r * (9.0 / 13.0)
        let mid = Path(ellipseIn: CGRect(x: center.x - r2, y: center.y - r2, width: r2 * 2, height: r2 * 2))
        context.fill(mid, with: .color(.rosePetalMid))

        let r3 = r * (4.5 / 13.0)
        let core = Path(ellipseIn: CGRect(x: center.x - r3, y: center.y - r3, width: r3 * 2, height: r3 * 2))
        context.fill(core, with: .color(.rosePetalCore))
    }

    private func drawBud(in context: GraphicsContext, center: CGPoint) {
        let rx = 6.5 * scale
        let ry = 9.5 * scale
        let bud = Path(ellipseIn: CGRect(x: center.x - rx, y: center.y - ry, width: rx * 2, height: ry * 2))
        context.fill(bud, with: .color(.roseBud))

        // Sepal — small triangle at the base.
        let sepal = Path { path in
            path.move(to: CGPoint(x: center.x - 6 * scale, y: center.y + 6 * scale))
            path.addLine(to: CGPoint(x: center.x, y: center.y - 1 * scale))
            path.addLine(to: CGPoint(x: center.x + 6 * scale, y: center.y + 6 * scale))
            path.closeSubpath()
        }
        context.fill(sepal, with: .color(.roseStem))
    }

    private func drawLeaf(in context: GraphicsContext, center: CGPoint, rx: CGFloat, ry: CGFloat, rotation: Double) {
        let rect = CGRect(x: -rx * scale, y: -ry * scale, width: rx * 2 * scale, height: ry * 2 * scale)
        let leaf = Path(ellipseIn: rect)
        var ctx = context
        ctx.translateBy(x: center.x, y: center.y)
        ctx.rotate(by: .degrees(rotation))
        ctx.fill(leaf, with: .color(.roseStem))
    }

    // MARK: Drooping (never dead — softened, waiting)

    private func drawDrooping(in context: GraphicsContext, grow: CGFloat) {
        let stem = Path { path in
            path.move(to: p(73, 138))
            path.addCurve(to: p(92, 92), control1: p(72, 116), control2: p(78, 102))
        }
        context.stroke(stem, with: .color(.roseStemDroop), style: StrokeStyle(lineWidth: 5 * scale, lineCap: .round))

        drawLeaf(in: context, center: p(64, 118), rx: 8, ry: 4, rotation: 35)

        // Single faded, head-bowed bloom.
        let center = p(96, 86)
        let r = 12 * scale
        context.fill(Path(ellipseIn: CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2)),
                     with: .color(.roseDroopCore.opacity(0.6)))
        let r2 = 8 * scale
        context.fill(Path(ellipseIn: CGRect(x: center.x - r2, y: center.y - r2, width: r2 * 2, height: r2 * 2)),
                     with: .color(.roseDroopPetal))
        let r3 = 4 * scale
        context.fill(Path(ellipseIn: CGRect(x: center.x - r3, y: center.y - r3, width: r3 * 2, height: r3 * 2)),
                     with: .color(.roseDroopCore))

        // A drip / bowed sepal line.
        let droopLine = Path { path in
            path.move(to: p(104, 98))
            path.addQuadCurve(to: p(102, 112), control: p(108, 106))
        }
        context.stroke(droopLine, with: .color(.roseDroopPetal), style: StrokeStyle(lineWidth: 2 * scale))

        // A single fallen petal.
        let petalCenter = p(110, 118)
        let petal = Path(ellipseIn: CGRect(x: petalCenter.x - 5 * scale, y: petalCenter.y - 2.5 * scale,
                                           width: 10 * scale, height: 5 * scale))
        context.fill(petal, with: .color(.roseDroopPetal.opacity(0.7)))
    }
}

#if DEBUG
struct RosePlantView_Previews: PreviewProvider {
    static var previews: some View {
        HStack(spacing: 24) {
            RosePlantView(mode: .blooming(open: 2, total: 4))
            RosePlantView(mode: .drooping)
        }
        .padding(40)
        .background(Color.backgroundPrimary)
        .previewLayout(.sizeThatFits)
    }
}
#endif
