import SwiftUI

struct HeroView: View {
    @State private var isAnimated = false
    
    // Brand colors matching the React app
    private let primaryColor = Color(red: 0.55, green: 0.22, blue: 0.24) // Maroon
    private let goldColor = Color(red: 0.78, green: 0.65, blue: 0.47) // Gold
    private let backgroundColor = Color(red: 0.98, green: 0.97, blue: 0.95) // Cream
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Hero Image
                heroImage
                
                // Content Section
                contentSection
            }
        }
        .background(backgroundColor)
        .ignoresSafeArea(edges: .top)
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                isAnimated = true
            }
        }
    }
    
    // MARK: - Hero Image
    private var heroImage: some View {
        GeometryReader { geometry in
            AsyncImage(url: URL(string: "https://images.unsplash.com/photo-1529634806980-85c3dd6d34ac?q=80&w=1000&auto=format&fit=crop")) { phase in
                switch phase {
                case .empty:
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .overlay(
                            ProgressView()
                                .tint(primaryColor)
                        )
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                case .failure:
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .overlay(
                            Image(systemName: "photo")
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                        )
                @unknown default:
                    EmptyView()
                }
            }
        }
        .frame(height: UIScreen.main.bounds.height * 0.5)
        .overlay(
            // Gradient overlay for text readability
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.clear,
                    backgroundColor.opacity(0.3),
                    backgroundColor
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    // MARK: - Content Section
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Title
            titleSection
                .opacity(isAnimated ? 1 : 0)
                .offset(y: isAnimated ? 0 : 20)
            
            // Description paragraphs
            descriptionSection
                .opacity(isAnimated ? 1 : 0)
                .offset(y: isAnimated ? 0 : 20)
                .animation(.easeOut(duration: 0.8).delay(0.1), value: isAnimated)
            
            // CTA Button
            ctaButton
                .opacity(isAnimated ? 1 : 0)
                .offset(y: isAnimated ? 0 : 20)
                .animation(.easeOut(duration: 0.8).delay(0.3), value: isAnimated)
        }
        .padding(.horizontal, 24)
        .padding(.top, -40)
        .padding(.bottom, 40)
    }
    
    // MARK: - Title Section
    private var titleSection: some View {
        HStack(spacing: 8) {
            Text("About")
                .font(.custom("Cormorant-Bold", size: 32, relativeTo: .title))
                .foregroundColor(Color(UIColor.label))
            
            Text("Us")
                .font(.custom("Cormorant-Italic", size: 32, relativeTo: .title))
                .foregroundColor(primaryColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Description Section
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Your Date Genie was created for people who love with intention but juggle full-demanding lives. For those who care deeply, yet often find themselves thinking, \"I want to plan something special... I just don't know where to begin.\" When days get crowded and routines take over, romance can slip into the background without anyone meaning to let it.")
                .font(.system(size: 17, weight: .regular))
                .foregroundColor(Color(UIColor.secondaryLabel))
                .lineSpacing(6)
            
            Text("That's where your Genie steps in. We take the details that define you, your pace, your preferences, your partner's little quirks, the rhythm of your week and shape them into moments that feel thoughtful, easy, and beautifully personal.")
                .font(.system(size: 17, weight: .regular))
                .foregroundColor(Color(UIColor.secondaryLabel))
                .lineSpacing(6)
        }
    }
    
    // MARK: - CTA Button
    private var ctaButton: some View {
        NavigationLink(destination: SignUpView()) {
            HStack(spacing: 8) {
                Text("Plan Your Date")
                    .font(.system(size: 18, weight: .semibold))
                
                Image(systemName: "arrow.right")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        goldColor,
                        goldColor.opacity(0.85)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
            .shadow(color: goldColor.opacity(0.4), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Scale Button Style
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

// MARK: - Placeholder SignUpView
struct SignUpView: View {
    var body: some View {
        Text("Sign Up")
            .navigationTitle("Get Started")
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        HeroView()
    }
}
