import SwiftUI

// MARK: - Brand Colors
extension Color {
    static let brandPrimary = Color(red: 0.55, green: 0.22, blue: 0.24)      // Maroon #8C383A
    static let brandGold = Color(red: 0.78, green: 0.65, blue: 0.47)         // Gold #C7A677
    static let brandCream = Color(red: 0.98, green: 0.97, blue: 0.95)        // Cream #FAF8F3
    static let brandMuted = Color(red: 0.45, green: 0.42, blue: 0.40)        // Muted text
}

// MARK: - Brand Gradients
extension LinearGradient {
    static let goldGradient = LinearGradient(
        gradient: Gradient(colors: [Color.brandGold, Color.brandGold.opacity(0.85)]),
        startPoint: .leading,
        endPoint: .trailing
    )
    
    static let maroonGradient = LinearGradient(
        gradient: Gradient(colors: [Color.brandPrimary, Color.brandPrimary.opacity(0.85)]),
        startPoint: .top,
        endPoint: .bottom
    )
}

// MARK: - Custom Button Styles
struct GoldButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 32)
            .padding(.vertical, 16)
            .background(LinearGradient.goldGradient)
            .cornerRadius(12)
            .shadow(color: Color.brandGold.opacity(0.4), radius: 12, x: 0, y: 6)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

struct OutlineButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .semibold))
            .foregroundColor(Color.brandPrimary)
            .padding(.horizontal, 32)
            .padding(.vertical, 16)
            .background(Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.brandPrimary, lineWidth: 2)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

// MARK: - Custom View Modifiers
struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
}

// MARK: - Typography Helpers
extension Font {
    static func displayFont(size: CGFloat) -> Font {
        .custom("Cormorant-Bold", size: size, relativeTo: .title)
    }
    
    static func displayItalic(size: CGFloat) -> Font {
        .custom("Cormorant-Italic", size: size, relativeTo: .title)
    }
}

// MARK: - Animation Constants
struct AppAnimation {
    static let standard = Animation.easeOut(duration: 0.3)
    static let slow = Animation.easeOut(duration: 0.6)
    static let spring = Animation.spring(response: 0.4, dampingFraction: 0.7)
}
