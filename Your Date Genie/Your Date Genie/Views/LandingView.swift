import SwiftUI

struct LandingView: View {
    @EnvironmentObject var coordinator: NavigationCoordinator
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Hero Section
                    heroSection
                    
                    // About Section (from Hero.tsx)
                    aboutSection
                    
                    // How It Works Section
                    howItWorksSection
                    
                    // Features Section
                    featuresSection
                    
                    // CTA Section
                    ctaSection
                }
            }
            .background(Color.brandCream)
            .ignoresSafeArea(edges: .top)
        }
    }
    
    // MARK: - Hero Section
    private var heroSection: some View {
        ZStack(alignment: .bottom) {
            // Background Image
            AsyncImage(url: URL(string: "https://images.unsplash.com/photo-1529333166437-7750a6dd5a70?w=800&h=600&fit=crop")) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .empty, .failure:
                    Rectangle()
                        .fill(Color.brandPrimary.opacity(0.3))
                @unknown default:
                    EmptyView()
                }
            }
            .frame(height: UIScreen.main.bounds.height * 0.6)
            .clipped()
            
            // Gradient Overlay
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.clear,
                    Color.black.opacity(0.3),
                    Color.black.opacity(0.7)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Hero Content
            VStack(spacing: 16) {
                // Logo
                Image(systemName: "sparkles")
                    .font(.system(size: 40))
                    .foregroundColor(.brandGold)
                
                Text("Your Date Genie")
                    .font(.custom("Cormorant-Bold", size: 36, relativeTo: .largeTitle))
                    .foregroundColor(.white)
                
                Text("Date nights, planned for you.")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                
                // CTA Button
                Button {
                    coordinator.startDatePlanning()
                } label: {
                    HStack {
                        Text("Get Started")
                            .font(.system(size: 17, weight: .semibold))
                        Image(systemName: "arrow.right")
                    }
                    .foregroundColor(.brandPrimary)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(Color.brandGold)
                    .cornerRadius(30)
                    .shadow(color: Color.brandGold.opacity(0.5), radius: 10, y: 5)
                }
                .padding(.top, 8)
            }
            .padding(.bottom, 60)
        }
    }
    
    // MARK: - About Section
    private var aboutSection: some View {
        VStack(spacing: 24) {
            // Section Title
            HStack(spacing: 8) {
                Text("About")
                    .font(.custom("Cormorant-Bold", size: 28, relativeTo: .title))
                    .foregroundColor(Color(UIColor.label))
                
                Text("Us")
                    .font(.custom("Cormorant-Italic", size: 28, relativeTo: .title))
                    .foregroundColor(.brandPrimary)
            }
            
            // Image
            AsyncImage(url: URL(string: "https://images.unsplash.com/photo-1529634806980-85c3dd6d34ac?q=80&w=1000&auto=format&fit=crop")) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 280)
                        .clipped()
                        .cornerRadius(16)
                case .empty, .failure:
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 280)
                @unknown default:
                    EmptyView()
                }
            }
            
            // Description
            VStack(alignment: .leading, spacing: 16) {
                Text("Your Date Genie was created for people who love with intention but juggle full-demanding lives. For those who care deeply, yet often find themselves thinking, \"I want to plan something special... I just don't know where to begin.\"")
                    .font(.system(size: 16))
                    .foregroundColor(Color(UIColor.secondaryLabel))
                    .lineSpacing(5)
                
                Text("That's where your Genie steps in. We take the details that define you and shape them into moments that feel thoughtful, easy, and beautifully personal.")
                    .font(.system(size: 16))
                    .foregroundColor(Color(UIColor.secondaryLabel))
                    .lineSpacing(5)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 48)
    }
    
    // MARK: - How It Works Section
    private var howItWorksSection: some View {
        VStack(spacing: 32) {
            Text("How It Works")
                .font(.custom("Cormorant-Bold", size: 28, relativeTo: .title))
                .foregroundColor(Color(UIColor.label))
            
            VStack(spacing: 24) {
                StepCard(
                    number: "1",
                    title: "Tell Us Your Vibe",
                    description: "Answer a few quick questions about your preferences, budget, and what you're in the mood for.",
                    icon: "sparkles"
                )
                
                StepCard(
                    number: "2",
                    title: "We Plan Everything",
                    description: "Our AI creates a personalized itinerary with venues, timing, and insider tips.",
                    icon: "wand.and.stars"
                )
                
                StepCard(
                    number: "3",
                    title: "Enjoy Your Date",
                    description: "Show up and make memories. We handle the planning so you can focus on each other.",
                    icon: "heart.fill"
                )
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 48)
        .background(Color.white)
    }
    
    // MARK: - Features Section
    private var featuresSection: some View {
        VStack(spacing: 32) {
            Text("Everything You Need")
                .font(.custom("Cormorant-Bold", size: 28, relativeTo: .title))
                .foregroundColor(Color(UIColor.label))
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                FeatureCard(icon: "map.fill", title: "Verified Venues", color: .blue)
                FeatureCard(icon: "gift.fill", title: "Gift Ideas", color: .pink)
                FeatureCard(icon: "bubble.left.and.bubble.right.fill", title: "Conversation Starters", color: .purple)
                FeatureCard(icon: "music.note", title: "Date Playlists", color: .orange)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 48)
    }
    
    // MARK: - CTA Section
    private var ctaSection: some View {
        VStack(spacing: 20) {
            Text("Ready for Better Dates?")
                .font(.custom("Cormorant-Bold", size: 28, relativeTo: .title))
                .foregroundColor(.white)
            
            Text("Join 500+ couples planning stress-free date nights")
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
            
            Button {
                coordinator.startDatePlanning()
            } label: {
                Text("Start Planning Free")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.brandPrimary)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 16)
                    .background(Color.brandGold)
                    .cornerRadius(30)
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
        .padding(.horizontal, 24)
        .background(Color.brandPrimary)
    }
}

// MARK: - Step Card
struct StepCard: View {
    let number: String
    let title: String
    let description: String
    let icon: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Number circle
            ZStack {
                Circle()
                    .fill(Color.brandGold)
                    .frame(width: 44, height: 44)
                
                Text(number)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(UIColor.label))
                
                Text(description)
                    .font(.system(size: 15))
                    .foregroundColor(Color(UIColor.secondaryLabel))
                    .lineSpacing(3)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Feature Card
struct FeatureCard: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(color)
                .frame(width: 56, height: 56)
                .background(color.opacity(0.1))
                .cornerRadius(12)
            
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(UIColor.label))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 10, y: 4)
    }
}


// MARK: - Preview
#Preview {
    LandingView()
        .environmentObject(NavigationCoordinator.shared)
}
