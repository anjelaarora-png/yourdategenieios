import SwiftUI

// MARK: - Charcoal Maroon Theme (dark-first; maroon = accent only)
// Screen backgrounds use charcoal. Maroon appears on hero borders, active tabs, partner strip.

extension Color {
    // Semantic tokens — Charcoal Maroon redesign
    static let backgroundPrimary = Color(hex: "1A1A1A")
    static let surfaceElevated = Color(hex: "242424")
    static let creamCard = Color(hex: "F5F0E8")
    static let creamParchmentLight = Color(hex: "FDF8F0")
    static let creamParchmentMid = Color(hex: "F5EDE0")
    static let creamParchmentDeep = Color(hex: "F0E6D8")
    /// Warm cream tint on charcoal surfaces — never stark white overlays.
    static let luxeSurfaceTint = Color(hex: "F5F0E8").opacity(0.08)
    static let luxeSurfaceTintStrong = Color(hex: "F5F0E8").opacity(0.12)
    static let luxeSurfaceBorder = Color(hex: "F5F0E8").opacity(0.16)
    static let accentGold = Color(hex: "C9A84C")
    static let accentMaroon = Color(hex: "4A0E0E")
    static let textPrimary = Color(hex: "FAFAF8")
    static let textOnCard = Color(hex: "1A1A1A")
    static let textMutedOnCard = Color(hex: "888888")
    static let maroonBorderTint = Color(hex: "4A0E0E").opacity(0.15)

    // Legacy aliases (mapped to Charcoal Maroon tokens)
    static let luxuryMaroon = accentMaroon
    static let luxuryMaroonLight = surfaceElevated
    static let luxuryMaroonMedium = Color(hex: "2E2E2E")
    static let luxuryGold = accentGold
    static let luxuryGoldLight = Color(hex: "D4B896")
    static let luxuryGoldDark = Color(hex: "A68B5B")
    static let luxuryCream = textPrimary
    static let luxuryCreamMuted = Color(hex: "FAFAF8").opacity(0.65)
    static let luxuryMuted = Color(hex: "888888")
    
    // Functional Colors
    static let luxurySuccess = Color(hex: "7CB87C")          // Muted green
    static let luxuryError = Color(hex: "C75050")            // Muted red
    static let luxuryWarning = Color(hex: "D4A84B")          // Warm yellow
    
    // Polaroid/Memory Colors
    static let polaroidWhite = Color(hex: "FFFDF7")          // Warm white for polaroid frame
    static let polaroidCream = Color(hex: "FAF6F0")          // Cream tint for inner area
    static let polaroidCaption = Color(hex: "2C2C2C")        // Dark charcoal for caption text
    static let polaroidShadow = Color(hex: "1A0808")         // Deep shadow for polaroid
    
    // Brand aliases
    static let brandPrimary = accentMaroon
    static let brandGold = accentGold
    static let brandCream = textPrimary
    static let brandMuted = luxuryMuted
}

// MARK: - Hex Color Initializer
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Luxurious Gradients
extension LinearGradient {
    // Gold shimmer gradient
    static let goldShimmer = LinearGradient(
        gradient: Gradient(colors: [
            Color.luxuryGoldDark,
            Color.luxuryGold,
            Color.luxuryGoldLight,
            Color.luxuryGold
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // Subtle gold gradient for buttons
    static let goldGradient = LinearGradient(
        gradient: Gradient(colors: [Color.luxuryGold, Color.luxuryGoldDark]),
        startPoint: .top,
        endPoint: .bottom
    )
    
    // Surface depth gradient (charcoal surfaces)
    static let maroonDepth = LinearGradient(
        gradient: Gradient(colors: [Color.surfaceElevated, Color.backgroundPrimary]),
        startPoint: .top,
        endPoint: .bottom
    )
    
    // Card background gradient
    static let cardGradient = LinearGradient(
        gradient: Gradient(colors: [
            Color.surfaceElevated.opacity(0.95),
            Color.luxuryMaroonMedium.opacity(0.85)
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Warm parchment gradient for Love Notes, polaroids, and luxe cream cards.
    static let creamParchment = LinearGradient(
        gradient: Gradient(colors: [
            Color.creamParchmentLight,
            Color.creamParchmentMid,
            Color.creamParchmentDeep
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Charcoal-to-maroon depth for inset panels on dark screens.
    static let charcoalMaroonInset = LinearGradient(
        gradient: Gradient(colors: [
            Color.surfaceElevated,
            Color.backgroundPrimary,
            Color.accentMaroon.opacity(0.18)
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // Magical sparkle overlay
    static let magicalOverlay = LinearGradient(
        gradient: Gradient(colors: [
            Color.luxuryGold.opacity(0.1),
            Color.clear,
            Color.luxuryGold.opacity(0.05)
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Radial Gradients
extension RadialGradient {
    static let goldGlow = RadialGradient(
        gradient: Gradient(colors: [
            Color.luxuryGold.opacity(0.3),
            Color.luxuryGold.opacity(0.1),
            Color.clear
        ]),
        center: .center,
        startRadius: 0,
        endRadius: 150
    )
    
    static let maroonVignette = RadialGradient(
        gradient: Gradient(colors: [
            Color.clear,
            Color.black.opacity(0.3)
        ]),
        center: .center,
        startRadius: 100,
        endRadius: 400
    )
}

// MARK: - Charcoal Maroon screen backdrop (subtle maroon glow at edges — accent only)

struct CharcoalMaroonBackground: View {
    var body: some View {
        ZStack {
            Color.backgroundPrimary

            LinearGradient(
                colors: [
                    Color.accentMaroon.opacity(0.24),
                    Color.backgroundPrimary,
                    Color(hex: "141010"),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [Color.accentMaroon.opacity(0.16), Color.clear],
                center: UnitPoint(x: 0.88, y: 0.06),
                startRadius: 0,
                endRadius: 300
            )

            RadialGradient(
                colors: [Color.accentMaroon.opacity(0.12), Color.clear],
                center: UnitPoint(x: 0.1, y: 0.94),
                startRadius: 0,
                endRadius: 280
            )
        }
    }
}

extension View {
    /// Full-screen charcoal base with subtle maroon edge glow (Charcoal Maroon design system).
    func charcoalMaroonScreenBackground() -> some View {
        background {
            CharcoalMaroonBackground()
                .ignoresSafeArea()
        }
    }
}

// MARK: - Luxurious Button Styles

/// Gold outline button with gold text on dark background
struct LuxuryOutlineButtonStyle: ButtonStyle {
    var isSmall: Bool = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Font.inter(isSmall ? 14 : 16, weight: .semibold))
            .foregroundColor(Color.luxuryGold)
            .padding(.horizontal, isSmall ? 20 : 28)
            .padding(.vertical, isSmall ? 12 : 16)
            .background(Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: isSmall ? 10 : 14)
                    .stroke(Color.luxuryGold, lineWidth: 1.5)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.8 : 1)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

/// Solid gold button with dark or light label (e.g. onboarding: white text)
struct LuxuryGoldButtonStyle: ButtonStyle {
    var isSmall: Bool = false
    /// Use .textPrimary or .white for onboarding; default charcoal on gold CTA.
    var labelColor: Color = Color.backgroundPrimary

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Font.inter(isSmall ? 14 : 16, weight: .semibold))
            .foregroundColor(labelColor)
            .padding(.horizontal, isSmall ? 20 : 28)
            .padding(.vertical, isSmall ? 12 : 16)
            .background(
                LinearGradient.goldShimmer
                    .opacity(configuration.isPressed ? 0.8 : 1)
            )
            .cornerRadius(isSmall ? 10 : 14)
            .shadow(color: Color.luxuryGold.opacity(0.3), radius: configuration.isPressed ? 4 : 12, y: configuration.isPressed ? 2 : 6)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

/// Maroon button with gold text (secondary)
struct LuxuryMaroonButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Font.inter(16, weight: .semibold))
            .foregroundColor(Color.luxuryGold)
            .padding(.horizontal, 28)
            .padding(.vertical, 16)
            .background(Color.luxuryMaroonLight)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.luxuryGold.opacity(0.3), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

/// Compact OpenTable / Resy / Call controls on dark maroon lists (high contrast gold border + label).
struct LuxuryReservationPlatformButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Font.inter(13, weight: .semibold))
            .foregroundColor(Color.luxuryGold)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .frame(minHeight: 44)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.luxuryMaroonLight.opacity(configuration.isPressed ? 0.85 : 0.65))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.luxuryGold.opacity(0.95), lineWidth: 1.5)
            )
            .shadow(color: Color.luxuryGold.opacity(0.12), radius: configuration.isPressed ? 2 : 4, y: 1)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.92 : 1)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// Legacy button styles
struct GoldButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Font.inter(17, weight: .semibold))
            .foregroundColor(Color.luxuryMaroon)
            .padding(.horizontal, 32)
            .padding(.vertical, 16)
            .background(LinearGradient.goldShimmer)
            .cornerRadius(12)
            .shadow(color: Color.luxuryGold.opacity(0.4), radius: 12, x: 0, y: 6)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

struct OutlineButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Font.inter(17, weight: .semibold))
            .foregroundColor(Color.luxuryGold)
            .padding(.horizontal, 32)
            .padding(.vertical, 16)
            .background(Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.luxuryGold, lineWidth: 1.5)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

// MARK: - Luxurious Card Styles

struct LuxuryCardModifier: ViewModifier {
    var hasBorder: Bool = true
    
    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    Color.luxuryMaroonLight.opacity(0.7)
                    LinearGradient.magicalOverlay
                }
            )
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            colors: [Color.luxuryGold.opacity(0.4), Color.luxuryGold.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: hasBorder ? 1 : 0
                    )
            )
            .shadow(color: Color.black.opacity(0.3), radius: 15, y: 8)
    }
}

extension View {
    func luxuryCard(hasBorder: Bool = true) -> some View {
        modifier(LuxuryCardModifier(hasBorder: hasBorder))
    }
    
    func cardStyle() -> some View {
        luxuryCard()
    }
}

// MARK: - Charcoal Maroon highlight boxes (website parity: gold boxes + maroon pops)

/// Subtle gold fill + gold border — use on charcoal for callouts, nudges, and grouped content.
struct GoldHighlightBoxModifier: ViewModifier {
    var cornerRadius: CGFloat = 14

    func body(content: Content) -> some View {
        content
            .background(Color.accentGold.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.accentGold.opacity(0.35), lineWidth: 1)
            )
    }
}

/// 3pt maroon rail on the leading edge — accent pop only, never a full maroon fill.
struct MaroonLeadingAccentModifier: ViewModifier {
    var width: CGFloat = 3

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .leading) {
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(Color.accentMaroon)
                    .frame(width: width)
                    .padding(.vertical, 6)
            }
    }
}

extension View {
    func goldHighlightBox(cornerRadius: CGFloat = 14) -> some View {
        modifier(GoldHighlightBoxModifier(cornerRadius: cornerRadius))
    }

    func maroonLeadingAccent(width: CGFloat = 3) -> some View {
        modifier(MaroonLeadingAccentModifier(width: width))
    }

    /// Cream card + maroon border tint + leading maroon rail (itinerary rows, stats).
    func creamCardMaroonAccent(cornerRadius: CGFloat = 14) -> some View {
        background(Color.creamCard)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.maroonBorderTint, lineWidth: 1)
            )
            .maroonLeadingAccent()
    }

    /// Gold highlight box on charcoal + maroon leading rail (nudges, partner strip, paywall blocks).
    func goldHighlightMaroonAccent(cornerRadius: CGFloat = 14) -> some View {
        modifier(GoldHighlightBoxModifier(cornerRadius: cornerRadius))
            .maroonLeadingAccent()
    }

    /// Cream card with gold highlight border + maroon rail (success states on plan cards).
    func creamGoldHighlightMaroonAccent(cornerRadius: CGFloat = 14) -> some View {
        background(Color.creamCard)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.accentGold.opacity(0.45), lineWidth: 1)
            )
            .maroonLeadingAccent()
    }

    /// Parchment-style cream surface with gold + maroon accents (Love Notes, letter cards).
    func creamParchmentMaroonAccent(cornerRadius: CGFloat = 16) -> some View {
        background(LinearGradient.creamParchment)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [Color.accentGold.opacity(0.55), Color.accentMaroon.opacity(0.25)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .maroonLeadingAccent()
    }

    /// Charcoal inset with cream border tint — form fields on dark screens.
    func luxeInsetSurface(cornerRadius: CGFloat = 14) -> some View {
        background(LinearGradient.charcoalMaroonInset)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.luxeSurfaceBorder, lineWidth: 1)
            )
            .maroonLeadingAccent(width: 2)
    }
}

// MARK: - Typography Helpers

/// Brand Font Families:
/// - Header: Times New Roman / Serif - For main headings and titles
/// - Subheader: Times New Roman - For subheadings and card titles (same as header)
/// - Display: Georgia serif (`displaySerif`) — functional screen headers
/// - Legacy: Tangerine — marketing-only; prefer `displaySerif` on in-app screens
/// - Body: Inter (sans-serif) - For all body text app-wide. Same font as questionnaire "What time works best?" buttons.

extension Font {
    // MARK: - Header Font (Times New Roman / Serif)
    /// Primary header font - Times New Roman or system serif
    static func header(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let weightName: String
        switch weight {
        case .regular: weightName = "TimesNewRomanPSMT"
        case .bold: weightName = "TimesNewRomanPS-BoldMT"
        case .semibold: weightName = "TimesNewRomanPS-BoldMT"
        default: weightName = "TimesNewRomanPSMT"
        }
        return .custom(weightName, size: size)
    }
    
    static func headerItalic(_ size: CGFloat) -> Font {
        .custom("TimesNewRomanPS-ItalicMT", size: size)
    }
    
    // MARK: - Subheader Font (Times New Roman)
    /// Subheader font - Times New Roman for subheadings (consistent with app)
    static func subheader(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let weightName: String
        switch weight {
        case .regular: weightName = "TimesNewRomanPSMT"
        case .medium: weightName = "TimesNewRomanPSMT"
        case .semibold: weightName = "TimesNewRomanPS-BoldMT"
        case .bold: weightName = "TimesNewRomanPS-BoldMT"
        default: weightName = "TimesNewRomanPSMT"
        }
        return .custom(weightName, size: size)
    }
    
    static func subheaderItalic(_ size: CGFloat) -> Font {
        .custom("TimesNewRomanPS-ItalicMT", size: size)
    }
    
    // MARK: - Display Serif (functional headers)
    /// Georgia serif for display titles on charcoal screens (replaces Tangerine in-app).
    static func displaySerif(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        bodySerif(size, weight: weight)
    }
    
    /// Special accent font — maps to display serif (legacy Tangerine fully removed in-app).
    static func special(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        displaySerif(size, weight: weight)
    }
    
    // MARK: - Body Font (Serif - Georgia)
    /// Body serif font - Georgia for elegant readable text
    static func bodySerif(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let weightName: String
        switch weight {
        case .bold: weightName = "Georgia-Bold"
        case .semibold: weightName = "Georgia-Bold"
        default: weightName = "Georgia"
        }
        return .custom(weightName, size: size)
    }
    
    static func bodySerifItalic(_ size: CGFloat) -> Font {
        .custom("Georgia-Italic", size: size)
    }
    
    // MARK: - Body Font (Sans-Serif - System / Inter when bundled)
    /// Body sans-serif - system font (SF Pro) when Inter not in bundle; add Inter .ttf + UIAppFonts to use Inter
    static func bodySans(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight)
    }
    
    // MARK: - Legacy Support (Keeping old names for compatibility)
    
    static func playfair(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        subheader(size, weight: weight)
    }
    
    static func playfairItalic(_ size: CGFloat) -> Font {
        subheaderItalic(size)
    }
    
    static func inter(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        bodySans(size, weight: weight)
    }
    
    // MARK: - Semantic Font Styles
    
    /// Hero/splash titles - Header Bold 36pt (Times New Roman)
    static func heroTitle() -> Font {
        .header(36, weight: .bold)
    }
    
    /// Main display titles - Header Bold 32pt (Times New Roman)
    static func displayTitle() -> Font {
        .header(32, weight: .bold)
    }
    
    /// Section headings - Header Bold 24pt (Times New Roman)
    static func sectionTitle() -> Font {
        .header(24, weight: .bold)
    }
    
    /// Card titles - Subheader SemiBold 18pt (Times New Roman)
    static func cardTitle() -> Font {
        .subheader(18, weight: .semibold)
    }
    
    /// Elegant body text - Body Sans 16pt (Inter, same as questionnaire time buttons)
    static func elegantBody() -> Font {
        .bodySans(16, weight: .regular)
    }
    
    /// Standard body text - Body Sans 15pt (Inter). Use for all body copy app-wide.
    static func bodyText() -> Font {
        .bodySans(15, weight: .regular)
    }
    
    /// Serif body text - Body Serif 15pt (Georgia)
    static func bodyTextSerif() -> Font {
        .bodySerif(15, weight: .regular)
    }
    
    /// Button text - Body Sans SemiBold 16pt (Inter)
    static func buttonText() -> Font {
        .bodySans(16, weight: .semibold)
    }
    
    /// Small button text - Body Sans SemiBold 14pt (Inter)
    static func smallButtonText() -> Font {
        .bodySans(14, weight: .semibold)
    }
    
    /// Labels - Body Sans Medium 12pt (Inter)
    static func label() -> Font {
        .bodySans(12, weight: .medium)
    }
    
    /// Captions - Body Sans 13pt (Inter)
    static func caption() -> Font {
        .bodySans(13, weight: .regular)
    }
    
    /// Tiny text - Body Sans 11pt (Inter)
    static func tiny() -> Font {
        .bodySans(11, weight: .regular)
    }
    
    /// Display serif accent — Georgia (was Tangerine magical 28pt)
    static func magical(_ size: CGFloat = 28) -> Font {
        .displaySerif(size, weight: .regular)
    }
    
    /// Display serif accent bold — Georgia (was Tangerine Bold 32pt)
    static func magicalBold(_ size: CGFloat = 32) -> Font {
        .displaySerif(size, weight: .bold)
    }
    
    // Legacy support
    static func displayFont(size: CGFloat) -> Font {
        .header(size, weight: .bold)
    }
    
    static func displayItalic(size: CGFloat) -> Font {
        .headerItalic(size)
    }
}

// MARK: - Special Text Views for Mixed Typography

/// Accent display text in Georgia serif (legacy name kept for call sites).
struct MagicalText: View {
    let text: String
    var size: CGFloat = 28
    var color: Color = .luxuryGold
    
    var body: some View {
        Text(text)
            .font(Font.displaySerif(size, weight: .bold))
            .foregroundColor(color)
    }
}

/// A view for inline magical text within a sentence
struct MagicalInlineText: View {
    let prefix: String
    let magical: String
    let suffix: String
    var magicalSize: CGFloat = 32
    var regularFont: Font = .header(18, weight: .regular)
    var color: Color = .luxuryCream
    var magicalColor: Color = .luxuryGold
    
    var body: some View {
        HStack(spacing: 4) {
            if !prefix.isEmpty {
                Text(prefix)
                    .font(regularFont)
                    .foregroundColor(color)
            }
            
            Text(magical)
                .font(Font.displaySerif(magicalSize, weight: .bold))
                .foregroundColor(magicalColor)
            
            if !suffix.isEmpty {
                Text(suffix)
                    .font(regularFont)
                    .foregroundColor(color)
            }
        }
    }
}

/// Header with serif accent word — "Get Early Access - Join The Waitlist!" style
struct HeaderWithMagical: View {
    let headerText: String
    let magicalText: String
    var headerSize: CGFloat = 24
    var magicalSize: CGFloat = 36
    var headerColor: Color = .luxuryCream
    var magicalColor: Color = .luxuryGold
    var separator: String = " - "
    var showSeparator: Bool = true
    
    var body: some View {
        HStack(spacing: 4) {
            Text(headerText)
                .font(Font.header(headerSize, weight: .regular))
                .foregroundColor(headerColor)
            
            if showSeparator {
                Text(separator)
                    .font(Font.header(headerSize, weight: .regular))
                    .foregroundColor(headerColor)
            }
            
            Text(magicalText)
                .font(Font.displaySerif(magicalSize, weight: .bold))
                .foregroundColor(magicalColor)
        }
    }
}

/// Multi-line header with mixed fonts — serif accent segments use Georgia
struct MixedStyleHeader: View {
    let segments: [TextSegment]
    var alignment: HorizontalAlignment = .center
    
    struct TextSegment {
        let text: String
        let isMagical: Bool
        var newLine: Bool = false
        
        static func regular(_ text: String, newLine: Bool = false) -> TextSegment {
            TextSegment(text: text, isMagical: false, newLine: newLine)
        }
        
        static func magical(_ text: String, newLine: Bool = false) -> TextSegment {
            TextSegment(text: text, isMagical: true, newLine: newLine)
        }
    }
    
    var body: some View {
        VStack(alignment: alignment, spacing: 4) {
            flowLayout
        }
    }
    
    @ViewBuilder
    private var flowLayout: some View {
        let lines = groupIntoLines()
        ForEach(Array(lines.enumerated()), id: \.offset) { _, lineSegments in
            HStack(spacing: 4) {
                ForEach(Array(lineSegments.enumerated()), id: \.offset) { _, segment in
                    if segment.isMagical {
                        Text(segment.text)
                            .font(Font.displaySerif(36, weight: .bold))
                            .foregroundColor(.luxuryGold)
                    } else {
                        Text(segment.text)
                            .font(Font.header(20, weight: .regular))
                            .foregroundColor(.luxuryCream)
                    }
                }
            }
        }
    }
    
    private func groupIntoLines() -> [[TextSegment]] {
        var lines: [[TextSegment]] = [[]]
        for segment in segments {
            if segment.newLine && !lines.last!.isEmpty {
                lines.append([segment])
            } else {
                lines[lines.count - 1].append(segment)
            }
        }
        return lines
    }
}

/// Section label in uppercase sans-serif
struct SectionLabel: View {
    let text: String
    var color: Color = .luxuryGold
    
    var body: some View {
        Text(text.uppercased())
            .font(Font.bodySans(12, weight: .semibold))
            .tracking(2)
            .foregroundColor(color)
    }
}

// MARK: - Book Flip Transition (page-turn effect for date plan options)
struct BookFlipModifier: ViewModifier {
    let angle: Double
    func body(content: Content) -> some View {
        content
            .rotation3DEffect(.degrees(angle), axis: (x: 0, y: 1, z: 0), perspective: 0.4)
    }
}

extension AnyTransition {
    static var bookFlip: AnyTransition {
        .asymmetric(
            insertion: .modifier(active: BookFlipModifier(angle: 90), identity: BookFlipModifier(angle: 0)),
            removal: .modifier(active: BookFlipModifier(angle: -90), identity: BookFlipModifier(angle: 0))
        )
    }
}

// MARK: - Animation Constants
struct AppAnimation {
    static let standard = Animation.easeOut(duration: 0.3)
    static let slow = Animation.easeOut(duration: 0.6)
    static let spring = Animation.spring(response: 0.4, dampingFraction: 0.7)
    static let magical = Animation.spring(response: 0.6, dampingFraction: 0.8)
}

// MARK: - Shadow Styles
extension View {
    func softShadow() -> some View {
        self.shadow(color: Color.black.opacity(0.3), radius: 12, x: 0, y: 6)
    }
    
    func goldGlow() -> some View {
        self.shadow(color: Color.luxuryGold.opacity(0.4), radius: 16, x: 0, y: 8)
    }
    
    func luxuryShadow() -> some View {
        self.shadow(color: Color.black.opacity(0.4), radius: 20, x: 0, y: 10)
    }
}

// MARK: - Magical Sparkle Effect
struct SparkleModifier: ViewModifier {
    @State private var isAnimating = false
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    ForEach(0..<5, id: \.self) { index in
                        Image(systemName: "sparkle")
                            .font(.system(size: CGFloat.random(in: 8...14)))
                            .foregroundColor(Color.luxuryGold.opacity(0.6))
                            .position(
                                x: CGFloat.random(in: 0...geometry.size.width),
                                y: CGFloat.random(in: 0...geometry.size.height)
                            )
                            .opacity(isAnimating ? 1 : 0)
                            .scaleEffect(isAnimating ? 1 : 0.5)
                            .animation(
                                Animation.easeInOut(duration: Double.random(in: 1.5...2.5))
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(index) * 0.3),
                                value: isAnimating
                            )
                    }
                }
            )
            .onAppear {
                isAnimating = true
            }
    }
}

extension View {
    func withSparkles() -> some View {
        modifier(SparkleModifier())
    }
}

// MARK: - Polaroid Styles
struct PolaroidModifier: ViewModifier {
    var rotation: Double = 0
    
    func body(content: Content) -> some View {
        content
            .background(LinearGradient.creamParchment)
            .cornerRadius(4)
            .shadow(color: Color.polaroidShadow.opacity(0.3), radius: 8, x: 2, y: 4)
            .shadow(color: Color.black.opacity(0.15), radius: 20, x: 5, y: 10)
            .rotationEffect(.degrees(rotation))
    }
}

extension View {
    func polaroidStyle(rotation: Double = 0) -> some View {
        modifier(PolaroidModifier(rotation: rotation))
    }
}

// MARK: - Timeline Gradient
extension LinearGradient {
    static let timelineGold = LinearGradient(
        gradient: Gradient(colors: [
            Color.luxuryGold.opacity(0.3),
            Color.luxuryGold,
            Color.luxuryGoldLight,
            Color.luxuryGold,
            Color.luxuryGold.opacity(0.3)
        ]),
        startPoint: .top,
        endPoint: .bottom
    )
}
