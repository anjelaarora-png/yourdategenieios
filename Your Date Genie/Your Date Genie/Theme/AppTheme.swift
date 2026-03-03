import SwiftUI

// MARK: - Luxurious Dark Theme Colors
// A magical, romantic color palette inspired by candlelit evenings and fine wine

extension Color {
    // Primary Colors
    static let luxuryMaroon = Color(hex: "4A0E0E")           // Deep burgundy background
    static let luxuryMaroonLight = Color(hex: "6B1A1A")      // Lighter maroon for cards
    static let luxuryMaroonMedium = Color(hex: "5A1212")     // Medium maroon for surfaces
    
    // Accent Colors
    static let luxuryGold = Color(hex: "C7A677")             // Primary gold
    static let luxuryGoldLight = Color(hex: "D4B896")        // Light gold for highlights
    static let luxuryGoldDark = Color(hex: "A68B5B")         // Dark gold for depth
    
    // Text Colors
    static let luxuryCream = Color(hex: "FFF8F0")            // Primary text on dark
    static let luxuryCreamMuted = Color(hex: "E8DDD0")       // Secondary text
    static let luxuryMuted = Color(hex: "B8A090")            // Muted/tertiary text
    
    // Functional Colors
    static let luxurySuccess = Color(hex: "7CB87C")          // Muted green
    static let luxuryError = Color(hex: "C75050")            // Muted red
    static let luxuryWarning = Color(hex: "D4A84B")          // Warm yellow
    
    // Legacy aliases for backward compatibility
    static let brandPrimary = luxuryMaroon
    static let brandGold = luxuryGold
    static let brandCream = luxuryCream
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
    
    // Maroon depth gradient
    static let maroonDepth = LinearGradient(
        gradient: Gradient(colors: [Color.luxuryMaroonLight, Color.luxuryMaroon]),
        startPoint: .top,
        endPoint: .bottom
    )
    
    // Card background gradient
    static let cardGradient = LinearGradient(
        gradient: Gradient(colors: [
            Color.luxuryMaroonLight.opacity(0.8),
            Color.luxuryMaroonMedium.opacity(0.6)
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

/// Solid gold button with dark text
struct LuxuryGoldButtonStyle: ButtonStyle {
    var isSmall: Bool = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Font.inter(isSmall ? 14 : 16, weight: .semibold))
            .foregroundColor(Color.luxuryMaroon)
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

// MARK: - Typography Helpers

/// Brand Font Families:
/// - Header: Times New Roman / Serif - For main headings and titles
/// - Subheader: Playfair Display - For subheadings and card titles  
/// - Special: Tangerine - For magical/special accent words
/// - Body: Georgia (serif) or Inter (sans-serif) - For readable body text

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
    
    // MARK: - Subheader Font (Playfair Display)
    /// Subheader font - Playfair Display for elegant subheadings
    static func subheader(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let weightName: String
        switch weight {
        case .regular: weightName = "PlayfairDisplay-Regular"
        case .medium: weightName = "PlayfairDisplay-Medium"
        case .semibold: weightName = "PlayfairDisplay-SemiBold"
        case .bold: weightName = "PlayfairDisplay-Bold"
        default: weightName = "PlayfairDisplay-Regular"
        }
        return .custom(weightName, size: size)
    }
    
    static func subheaderItalic(_ size: CGFloat) -> Font {
        .custom("PlayfairDisplay-Italic", size: size)
    }
    
    // MARK: - Special Font (Tangerine)
    /// Special accent font - Tangerine for magical/romantic words
    static func special(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let weightName: String
        switch weight {
        case .bold: weightName = "Tangerine-Bold"
        default: weightName = "Tangerine-Regular"
        }
        return .custom(weightName, size: size)
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
    
    // MARK: - Body Font (Sans-Serif - Inter)
    /// Body sans-serif font - Inter for clean UI text
    static func bodySans(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let weightName: String
        switch weight {
        case .regular: weightName = "Inter-Regular"
        case .medium: weightName = "Inter-Medium"
        case .semibold: weightName = "Inter-SemiBold"
        case .bold: weightName = "Inter-Bold"
        default: weightName = "Inter-Regular"
        }
        return .custom(weightName, size: size)
    }
    
    // MARK: - Legacy Support (Keeping old names for compatibility)
    
    static func cormorant(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        header(size, weight: weight)
    }
    
    static func cormorantItalic(_ size: CGFloat) -> Font {
        headerItalic(size)
    }
    
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
    
    /// Card titles - Subheader SemiBold 18pt (Playfair)
    static func cardTitle() -> Font {
        .subheader(18, weight: .semibold)
    }
    
    /// Elegant body text - Subheader 16pt (Playfair)
    static func elegantBody() -> Font {
        .subheader(16, weight: .regular)
    }
    
    /// Standard body text - Body Sans 15pt (Inter)
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
    
    /// Special magical text - Tangerine 28pt
    static func magical(_ size: CGFloat = 28) -> Font {
        .special(size, weight: .regular)
    }
    
    /// Special magical text bold - Tangerine Bold 32pt
    static func magicalBold(_ size: CGFloat = 32) -> Font {
        .special(size, weight: .bold)
    }
    
    // Legacy support
    static func displayFont(size: CGFloat) -> Font {
        .header(size, weight: .bold)
    }
    
    static func displayItalic(size: CGFloat) -> Font {
        .headerItalic(size)
    }
}

// MARK: - Special Text View for Magical Words
/// A view that renders text in the special Tangerine font
struct MagicalText: View {
    let text: String
    var size: CGFloat = 28
    var color: Color = .luxuryGold
    
    var body: some View {
        Text(text)
            .font(Font.special(size))
            .foregroundColor(color)
    }
}

/// A view for inline magical text within a sentence
struct MagicalInlineText: View {
    let prefix: String
    let magical: String
    let suffix: String
    var magicalSize: CGFloat = 32
    var regularFont: Font = .subheader(18, weight: .regular)
    var color: Color = .luxuryCream
    var magicalColor: Color = .luxuryGold
    
    var body: some View {
        HStack(spacing: 4) {
            Text(prefix)
                .font(regularFont)
                .foregroundColor(color)
            
            Text(magical)
                .font(Font.special(magicalSize, weight: .bold))
                .foregroundColor(magicalColor)
            
            Text(suffix)
                .font(regularFont)
                .foregroundColor(color)
        }
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
