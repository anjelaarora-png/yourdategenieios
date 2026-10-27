import SwiftUI

// MARK: - Your Date Genie design system (Final design, Oct 2026)
// Source of truth: Paper file "date genie", page "Final design", board "0 · Foundations".
// Rules: gold marks only what is tappable or selected. Headings are cream. Rose is for
// celebratory moments (rewards, love notes). Depth on dark = lighter surface + hairline,
// no drop shadows. One signature gradient, saved for the partner plan reveal.

extension Color {
    // Surfaces
    static let ydgBase = Color(hex: "161412")
    static let ydgRaised = Color(hex: "221F1C")
    static let ydgOverlay = Color(hex: "2B2724")
    static let ydgBorder = Color(hex: "3A342E")
    /// Outline for secondary buttons (3.2:1 against base).
    static let ydgBorderStrong = Color(hex: "5A5148")

    // Text
    static let ydgTextPrimary = Color(hex: "F5F0E8")   // 16.2:1 on base
    static let ydgTextSecondary = Color(hex: "B5AC9F") // 8.2:1
    static let ydgTextTertiary = Color(hex: "8F877C")  // 5.2:1
    static let ydgTextOnAccent = Color(hex: "161412")

    // Accent (gold = tappable or selected)
    static let ydgAccent = Color(hex: "C9A84C")
    static let ydgAccentPressed = Color(hex: "B39440")
    static let ydgAccentSubtle = Color(hex: "2B2418")
    static let ydgDisabledFill = Color(hex: "3A3326")
    static let ydgDisabledLabel = Color(hex: "ABA294")  // 4.9:1 on disabled fill

    // Highlight (rose)
    static let ydgHighlight = Color(hex: "D98A8C")
    static let ydgHighlightSubtle = Color(hex: "2E2222")

    // Icon tiles (warm circle + cream glyph, from the original app)
    static let ydgIconTile = Color(hex: "453A32")
    static let ydgIconCream = Color(hex: "D0B99A")     // 5.9:1 on tile

    // Status
    static let ydgSuccess = Color(hex: "7DBE7E")
    static let ydgWarning = Color(hex: "D9A84C")
    static let ydgDanger = Color(hex: "E06B6B")
}

// MARK: - Spacing & shape (4-pt grid, 20-pt screen margin)

enum YDGSpace {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let margin: CGFloat = 20
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

enum YDGRadius {
    static let chip: CGFloat = 8
    static let card: CGFloat = 14
    static let sheet: CGFloat = 24
}

// MARK: - Typography (Playfair Display headings, Inter everything else; scales with Dynamic Type)

enum YDGFontFamily {
    static let display = "Playfair Display"
    static let sans = "Inter"
}

enum YDGTextStyle {
    case display, title1, title2, title3, headline, body, callout, subhead, footnote, caption

    var size: CGFloat {
        switch self {
        case .display: return 40
        case .title1: return 34
        case .title2: return 22
        case .title3: return 20
        case .headline, .body: return 17
        case .callout: return 16
        case .subhead: return 15
        case .footnote: return 13
        case .caption: return 12
        }
    }

    /// Extra leading on top of the font's own line height. Playfair already runs tall,
    /// so display styles add none; Inter body text gets a little air.
    var lineSpacing: CGFloat {
        switch self {
        case .display, .title1, .title2: return 0
        case .title3, .headline: return 1
        case .body: return 3
        case .callout, .subhead, .footnote: return 2
        case .caption: return 0
        }
    }

    var relativeTo: Font.TextStyle {
        switch self {
        case .display, .title1: return .largeTitle
        case .title2: return .title2
        case .title3: return .title3
        case .headline: return .headline
        case .body: return .body
        case .callout: return .callout
        case .subhead: return .subheadline
        case .footnote: return .footnote
        case .caption: return .caption
        }
    }

    var isDisplay: Bool {
        switch self {
        case .display, .title1, .title2: return true
        default: return false
        }
    }

    var defaultWeight: Font.Weight {
        switch self {
        case .display, .title1, .title2, .title3, .headline, .caption: return .semibold
        case .subhead: return .medium
        default: return .regular
        }
    }

    var tracking: CGFloat {
        switch self {
        case .display, .title1: return -0.02 * size
        case .caption: return 0.08 * size
        default: return 0
        }
    }
}

extension Font {
    static func ydg(_ style: YDGTextStyle, weight: Font.Weight? = nil) -> Font {
        let family = style.isDisplay ? YDGFontFamily.display : YDGFontFamily.sans
        return .custom(family, size: style.size, relativeTo: style.relativeTo)
            .weight(weight ?? style.defaultWeight)
    }

    /// Playfair Display at an arbitrary size (scales with Dynamic Type).
    static func ydgDisplay(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .custom(YDGFontFamily.display, size: size, relativeTo: ydgTextStyle(for: size)).weight(weight)
    }

    /// Inter at an arbitrary size (scales with Dynamic Type).
    static func ydgSans(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .custom(YDGFontFamily.sans, size: size, relativeTo: ydgTextStyle(for: size)).weight(weight)
    }

    static func ydgTextStyle(for size: CGFloat) -> Font.TextStyle {
        switch size {
        case 28...: return .largeTitle
        case 22..<28: return .title2
        case 20..<22: return .title3
        case 17..<20: return .body
        case 16..<17: return .callout
        case 15..<16: return .subheadline
        case 13..<15: return .footnote
        case 12..<13: return .caption
        default: return .caption2
        }
    }
}

extension View {
    /// Applies a type style. Captions are uppercase overlines.
    func ydgText(_ style: YDGTextStyle, weight: Font.Weight? = nil, color: Color? = nil) -> some View {
        self
            .font(.ydg(style, weight: weight))
            .tracking(style.tracking)
            .lineSpacing(style.lineSpacing)
            .textCase(style == .caption ? .uppercase : nil)
            .foregroundStyle(color ?? (style == .caption ? Color.ydgTextSecondary : Color.ydgTextPrimary))
    }

    /// Raised card: lighter surface + hairline, no shadow.
    func ydgCard(padding: CGFloat = YDGSpace.md, fill: Color = .ydgRaised) -> some View {
        self
            .padding(padding)
            .background(fill, in: RoundedRectangle(cornerRadius: YDGRadius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: YDGRadius.card, style: .continuous)
                    .stroke(Color.ydgBorder, lineWidth: 1)
            )
    }

    /// Flat screen background used by every screen.
    func ydgScreenBackground() -> some View {
        background(Color.ydgBase.ignoresSafeArea())
    }
}

// MARK: - YDGButton (one component, every state)

struct YDGButtonStyle: ButtonStyle {
    /// `accentOutline`: gold label + gold hairline, for an in-card action that isn't the screen's primary.
    enum Kind { case primary, secondary, tertiary, destructive, accentOutline }

    var kind: Kind = .primary
    var isLoading: Bool = false
    var fullWidth: Bool = true
    /// 44pt height and subhead label, for actions inside cards.
    var compact: Bool = false
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        HStack(spacing: YDGSpace.xs) {
            if isLoading {
                ProgressView()
                    .tint(labelColor)
                    .controlSize(.small)
            }
            configuration.label
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .font(compact ? .ydg(.subhead, weight: .semibold) : .ydg(.headline))
        .foregroundStyle(labelColor)
        .padding(.horizontal, kind == .tertiary ? YDGSpace.xs : (compact ? YDGSpace.md : YDGSpace.lg))
        .frame(maxWidth: fullWidth && kind != .tertiary ? .infinity : nil)
        .frame(minHeight: kind == .tertiary || compact ? 44 : 54)
        .background(background(pressed: pressed))
        .overlay(border)
        .contentShape(Capsule())
        .scaleEffect(pressed ? 0.98 : 1)
        .animation(.easeOut(duration: 0.12), value: pressed)
        .sensoryFeedback(.impact(weight: .light), trigger: pressed) { _, isPressed in isPressed }
    }

    private var labelColor: Color {
        guard isEnabled else { return kind == .primary ? .ydgDisabledLabel : .ydgTextTertiary }
        switch kind {
        case .primary: return .ydgTextOnAccent
        case .secondary: return .ydgTextPrimary
        case .tertiary: return .ydgAccent
        case .destructive: return .ydgDanger
        case .accentOutline: return .ydgAccent
        }
    }

    @ViewBuilder
    private func background(pressed: Bool) -> some View {
        switch kind {
        case .primary:
            Capsule().fill(isEnabled ? (pressed ? Color.ydgAccentPressed : Color.ydgAccent) : Color.ydgDisabledFill)
        case .secondary, .destructive, .accentOutline:
            Capsule().fill(pressed ? Color.ydgRaised : Color.clear)
        case .tertiary:
            Color.clear
        }
    }

    @ViewBuilder
    private var border: some View {
        switch kind {
        case .secondary:
            Capsule().stroke(Color.ydgBorderStrong, lineWidth: 1)
        case .destructive:
            Capsule().stroke(Color.ydgDanger.opacity(0.7), lineWidth: 1)
        case .accentOutline:
            Capsule().stroke(isEnabled ? Color.ydgAccent : Color.ydgBorder, lineWidth: 1)
        default:
            EmptyView()
        }
    }
}

extension ButtonStyle where Self == YDGButtonStyle {
    static var ydgPrimary: YDGButtonStyle { YDGButtonStyle(kind: .primary) }
    static var ydgSecondary: YDGButtonStyle { YDGButtonStyle(kind: .secondary) }
    static var ydgTertiary: YDGButtonStyle { YDGButtonStyle(kind: .tertiary) }
    static var ydgDestructive: YDGButtonStyle { YDGButtonStyle(kind: .destructive) }
}

// MARK: - Chip (selectable pill)

struct YDGChip: View {
    let title: String
    var isSelected: Bool
    var showsCheckmark: Bool = true
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if isSelected && showsCheckmark {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                }
                Text(title)
                    .font(.ydg(.subhead, weight: isSelected ? .semibold : .medium))
            }
            .foregroundStyle(isSelected ? Color.ydgAccent : Color.ydgTextPrimary)
            .padding(.horizontal, YDGSpace.md)
            .frame(minHeight: 44)
            .background(
                Capsule().fill(isSelected ? Color.ydgAccentSubtle : Color.ydgRaised)
            )
            .overlay(
                Capsule().stroke(isSelected ? Color.ydgAccent : Color.ydgBorder, lineWidth: isSelected ? 1.5 : 1)
            )
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Icon tile (cream glyph on a warm circle)

struct YDGIconTile: View {
    let systemName: String
    var size: CGFloat = 56

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: size * 0.39, weight: .regular))
            .foregroundStyle(Color.ydgIconCream)
            .frame(width: size, height: size)
            .background(Circle().fill(Color.ydgIconTile))
            .accessibilityHidden(true)
    }
}

/// Icon tile with a label underneath, as used for Home shortcuts and quick-send rows.
struct YDGShortcutButton: View {
    let title: String
    let systemName: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: YDGSpace.xs) {
                YDGIconTile(systemName: systemName)
                Text(title)
                    .font(.ydg(.footnote, weight: .medium))
                    .foregroundStyle(Color.ydgTextPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}

// MARK: - Row with trailing chevron (lists, settings, You tab)

struct YDGChevronRow<Leading: View>: View {
    let title: String
    var subtitle: String? = nil
    var value: String? = nil
    @ViewBuilder var leading: () -> Leading

    var body: some View {
        HStack(spacing: YDGSpace.sm + 2) {
            leading()
            VStack(alignment: .leading, spacing: 2) {
                Text(title).ydgText(.callout)
                if let subtitle {
                    Text(subtitle).ydgText(.footnote, color: .ydgTextSecondary)
                }
            }
            Spacer(minLength: YDGSpace.xs)
            if let value {
                Text(value).ydgText(.callout, color: .ydgTextSecondary)
            }
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.ydgTextTertiary)
        }
        .frame(minHeight: 52)
        .contentShape(Rectangle())
    }
}

extension YDGChevronRow where Leading == EmptyView {
    init(title: String, subtitle: String? = nil, value: String? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.value = value
        self.leading = { EmptyView() }
    }
}

// MARK: - Large screen title (tab roots)

struct YDGLargeTitle: View {
    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: YDGSpace.xxs) {
            Text(title)
                .ydgText(.title1)
                .accessibilityAddTraits(.isHeader)
            if let subtitle {
                Text(subtitle).ydgText(.body, color: .ydgTextSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, YDGSpace.margin)
        .padding(.top, YDGSpace.sm)
    }
}

// MARK: - Segmented control (gold = selected)

struct YDGSegmentedControl<Option: Hashable>: View {
    let options: [Option]
    @Binding var selection: Option
    let title: (Option) -> String

    var body: some View {
        HStack(spacing: 0) {
            ForEach(options, id: \.self) { option in
                let isSelected = option == selection
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) { selection = option }
                } label: {
                    Text(title(option))
                        .font(.ydg(.subhead, weight: isSelected ? .semibold : .medium))
                        .foregroundStyle(isSelected ? Color.ydgAccent : Color.ydgTextSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                        .frame(maxWidth: .infinity, minHeight: 36)
                        .background(
                            RoundedRectangle(cornerRadius: YDGRadius.chip, style: .continuous)
                                .fill(isSelected ? Color.ydgAccentSubtle : Color.clear)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: YDGRadius.chip, style: .continuous)
                                .stroke(isSelected ? Color.ydgAccent : Color.clear, lineWidth: 1)
                        )
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
            }
        }
        .padding(3)
        .background(Color.ydgRaised, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

// MARK: - Empty state (left-aligned: icon, title, message, one action)

struct YDGEmptyState: View {
    let systemName: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: YDGSpace.sm) {
            Image(systemName: systemName)
                .font(.system(size: 30, weight: .regular))
                .foregroundStyle(Color.ydgHighlight)
                .accessibilityHidden(true)
                .padding(.bottom, YDGSpace.xs)
            Text(title).ydgText(.title3)
            Text(message)
                .ydgText(.body, color: .ydgTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(YDGButtonStyle(kind: .primary, fullWidth: false))
                    .padding(.top, YDGSpace.sm)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, YDGSpace.xl)
    }
}

// MARK: - Grouped list (raised card with inset hairlines)

struct YDGListDivider: View {
    var leadingInset: CGFloat = 54

    var body: some View {
        Rectangle()
            .fill(Color.ydgBorder)
            .frame(height: 1)
            .padding(.leading, leadingInset)
    }
}

extension View {
    func ydgGroupedList() -> some View {
        self
            .background(Color.ydgRaised, in: RoundedRectangle(cornerRadius: YDGRadius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: YDGRadius.card, style: .continuous)
                    .stroke(Color.ydgBorder, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: YDGRadius.card, style: .continuous))
    }
}

#Preview("Design system") {
    ScrollView {
        VStack(alignment: .leading, spacing: YDGSpace.lg) {
            Text("Friday's wide open.").ydgText(.display)
            Text("Your dates").ydgText(.title1)
            Text("This month").ydgText(.caption)
            Text("Tell us the vibe and we'll build the plan.").ydgText(.body, color: .ydgTextSecondary)
            Button("Plan my next date") {}.buttonStyle(.ydgPrimary)
            Button("Send to Jordan") {}.buttonStyle(.ydgSecondary)
            Button("Another idea") {}.buttonStyle(.ydgTertiary)
            Button("Rewrite note") {}.buttonStyle(.ydgPrimary).disabled(true)
            Button("Planning…") {}.buttonStyle(YDGButtonStyle(kind: .primary, isLoading: true))
            HStack {
                YDGChip(title: "Italian", isSelected: true) {}
                YDGChip(title: "Museums", isSelected: false) {}
            }
            HStack {
                YDGShortcutButton(title: "Gifts", systemName: "gift") {}
                YDGShortcutButton(title: "Playlists", systemName: "music.note.list") {}
                YDGShortcutButton(title: "Talk sparks", systemName: "bubble.left.and.bubble.right") {}
                YDGShortcutButton(title: "Together", systemName: "person.2") {}
            }
            Text("0 of 4 date nights").ydgText(.headline).frame(maxWidth: .infinity, alignment: .leading).ydgCard()
        }
        .padding(YDGSpace.margin)
    }
    .ydgScreenBackground()
}
