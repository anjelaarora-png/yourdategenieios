import SwiftUI

struct LandingView: View {
    @EnvironmentObject var coordinator: NavigationCoordinator
    @EnvironmentObject private var access: AccessManager
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Deep maroon background
                Color.luxuryMaroon
                    .ignoresSafeArea()
                
                // Subtle vignette overlay
                RadialGradient.maroonVignette
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Hero Section
                        heroSection
                        
                        // About Section
                        aboutSection
                        
                        // How It Works Section
                        howItWorksSection
                        
                        // Features Section
                        featuresSection
                        
                        // CTA Section
                        ctaSection
                    }
                }
            }
            .ignoresSafeArea(edges: .top)
        }
    }
    
    // MARK: - Hero Section
    private var heroSection: some View {
        GeometryReader { geo in
            heroContent(heroHeight: geo.size.height * 0.6 > 300 ? geo.size.height * 0.6 : 420)
        }
        .frame(height: 520)
    }

    private func heroContent(heroHeight: CGFloat) -> some View {
        ZStack(alignment: .bottom) {
            // Background Image with overlay
            AsyncImage(url: URL(string: "https://images.unsplash.com/photo-1529333166437-7750a6dd5a70?w=800&h=600&fit=crop")) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .empty, .failure:
                    Rectangle()
                        .fill(Color.luxuryMaroonLight)
                @unknown default:
                    EmptyView()
                }
            }
            .frame(height: heroHeight)
            .clipped()
            .overlay(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.luxuryMaroon.opacity(0.3),
                        Color.luxuryMaroon.opacity(0.6),
                        Color.luxuryMaroon
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            
            // Hero Content
            VStack(spacing: 20) {
                // Logo
                Image("Logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 160, height: 160)
                    .shadow(color: Color.luxuryGold.opacity(0.3), radius: 20)
                
                // Tagline
                HStack(spacing: 6) {
                    Text("Date nights,")
                        .font(Font.header(20, weight: .regular))
                        .foregroundColor(Color.luxuryCream.opacity(0.9))
                    Text("planned")
                        .font(Font.tangerine(32, weight: .bold))
                        .italic()
                        .foregroundColor(Color.luxuryGold)
                    Text("for you.")
                        .font(Font.header(20, weight: .regular))
                        .foregroundColor(Color.luxuryCream.opacity(0.9))
                }
                
                // CTA Button
                Button {
                    access.require(.datePlan) {
                        coordinator.startDatePlanning()
                    }
                } label: {
                    HStack(spacing: 10) {
                        Text("Begin Your Journey")
                            .font(Font.bodySans(16, weight: .semibold))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .semibold))
                    }
                }
                .buttonStyle(LuxuryGoldButtonStyle())
                .padding(.top, 8)
            }
            .padding(.bottom, 60)
        }
    }
    
    // MARK: - About Section
    private var aboutSection: some View {
        VStack(spacing: 28) {
            // Section Title
            HStack(spacing: 12) {
                Rectangle()
                    .fill(Color.luxuryGold)
                    .frame(width: 40, height: 1)
                
                HStack(spacing: 6) {
                    Text("About")
                        .font(Font.header(26, weight: .regular))
                        .foregroundColor(Color.luxuryCream)
                    Text("Us")
                        .font(Font.tangerine(40, weight: .bold))
                        .italic()
                        .foregroundColor(Color.luxuryGold)
                }
                
                Rectangle()
                    .fill(Color.luxuryGold)
                    .frame(width: 40, height: 1)
            }
            
            // Image
            AsyncImage(url: URL(string: "https://images.unsplash.com/photo-1529634806980-85c3dd6d34ac?q=80&w=1000&auto=format&fit=crop")) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 260)
                        .clipped()
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.luxuryGold.opacity(0.3), lineWidth: 1)
                        )
                case .empty, .failure:
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.luxuryMaroonLight)
                        .frame(height: 260)
                @unknown default:
                    EmptyView()
                }
            }
            .shadow(color: Color.black.opacity(0.4), radius: 20, y: 10)
            
            // Description
            VStack(spacing: 16) {
                Text("Your Date Genie was created for people who love with intention but juggle full-demanding lives.")
                    .font(Font.bodySans(15, weight: .regular))
                    .foregroundColor(Color.luxuryCreamMuted)
                    .lineSpacing(6)
                
                HStack(spacing: 4) {
                    Text("That's where your")
                        .font(Font.bodySans(15, weight: .regular))
                        .foregroundColor(Color.luxuryCreamMuted)
                    Text("Genie")
                        .font(Font.tangerine(32, weight: .bold))
                        .italic()
                        .foregroundColor(Color.luxuryGold)
                    Text("steps in.")
                        .font(Font.bodySans(15, weight: .regular))
                        .foregroundColor(Color.luxuryCreamMuted)
                }
                
                Text("We take the details that define you and shape them into moments that feel thoughtful, easy, and beautifully personal.")
                    .font(Font.bodySans(15, weight: .regular))
                    .foregroundColor(Color.luxuryCreamMuted)
                    .lineSpacing(6)
            }
            .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 56)
    }
    
    // MARK: - How It Works Section
    private var howItWorksSection: some View {
        VStack(spacing: 36) {
            // Section Title
            HStack(spacing: 6) {
                Text("How It")
                    .font(Font.header(26, weight: .regular))
                    .foregroundColor(Color.luxuryCream)
                Text("Works")
                    .font(Font.tangerine(40, weight: .bold))
                    .italic()
                    .foregroundColor(Color.luxuryGold)
            }
            
            VStack(spacing: 20) {
                LuxuryStepCard(
                    number: "1",
                    title: "Tell Us Your Vibe",
                    description: "Answer a few quick questions about your preferences, budget, and what you're in the mood for.",
                    icon: "sparkles"
                )
                
                LuxuryStepCard(
                    number: "2",
                    title: "We Plan Everything",
                    description: "Our AI creates a personalized itinerary with venues, timing, and insider tips.",
                    icon: "wand.and.stars"
                )
                
                LuxuryStepCard(
                    number: "3",
                    title: "Enjoy Your Date",
                    description: "Show up and make memories. We handle the planning so you can focus on each other.",
                    icon: "heart.fill"
                )
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 56)
        .background(Color.luxuryMaroonMedium.opacity(0.5))
    }
    
    // MARK: - Features Section
    private var featuresSection: some View {
        VStack(spacing: 36) {
            HStack(spacing: 6) {
                Text("Everything")
                    .font(Font.tangerine(40, weight: .bold))
                    .italic()
                    .foregroundColor(Color.luxuryGold)
                Text("You Need")
                    .font(Font.header(26, weight: .regular))
                    .foregroundColor(Color.luxuryCream)
            }
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                LuxuryFeatureCard(icon: "map.fill", title: "Verified Venues")
                LuxuryFeatureCard(icon: "gift.fill", title: "Gift Ideas")
                LuxuryFeatureCard(icon: "bubble.left.and.bubble.right.fill", title: "Conversation Starters")
                LuxuryFeatureCard(icon: "music.note", title: "Date Playlists")
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 56)
    }
    
    // MARK: - CTA Section
    private var ctaSection: some View {
        VStack(spacing: 24) {
            // Decorative sparkle
            Image(systemName: "sparkle")
                .font(.system(size: 32))
                .foregroundColor(Color.luxuryGold)
            
            HStack(spacing: 6) {
                Text("Ready for")
                    .font(Font.header(26, weight: .regular))
                    .foregroundColor(Color.luxuryCream)
                Text("Better Dates?")
                    .font(Font.tangerine(40, weight: .bold))
                    .italic()
                    .foregroundColor(Color.luxuryGold)
            }
            
            Text("Join couples planning stress-free date nights")
                .font(Font.bodySans(15, weight: .regular))
                .foregroundColor(Color.luxuryCreamMuted)
            
            Button {
                access.require(.datePlan) {
                    coordinator.startDatePlanning()
                }
            } label: {
                Text("Start Planning Free")
            }
            .buttonStyle(LuxuryGoldButtonStyle())
            .padding(.top, 8)
            
            Text("No credit card required")
                .font(Font.bodySans(12, weight: .regular))
                .foregroundColor(Color.luxuryMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
        .padding(.horizontal, 24)
        .background(
            ZStack {
                Color.luxuryMaroonLight.opacity(0.5)
                RadialGradient.goldGlow.opacity(0.3)
            }
        )
    }
}

// MARK: - Luxury Step Card
struct LuxuryStepCard: View {
    let number: String
    let title: String
    let description: String
    let icon: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Number with gold circle
            ZStack {
                Circle()
                    .fill(LinearGradient.goldShimmer)
                    .frame(width: 48, height: 48)
                
                Text(number)
                    .font(Font.header(20, weight: .bold))
                    .foregroundColor(Color.luxuryMaroon)
            }
            .shadow(color: Color.luxuryGold.opacity(0.3), radius: 10)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(Font.header(17, weight: .bold))
                    .foregroundColor(Color.luxuryCream)
                
                Text(description)
                    .font(Font.bodySans(14, weight: .regular))
                    .foregroundColor(Color.luxuryMuted)
                    .lineSpacing(4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .luxuryCard()
    }
}

// MARK: - Luxury Feature Card
struct LuxuryFeatureCard: View {
    let icon: String
    let title: String
    
    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundStyle(LinearGradient.goldShimmer)
                .frame(width: 56, height: 56)
                .background(Color.luxuryMaroonLight)
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.luxuryGold.opacity(0.3), lineWidth: 1)
                )
            
            Text(title)
                .font(Font.bodySans(13, weight: .medium))
                .foregroundColor(Color.luxuryCream)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .luxuryCard()
    }
}

// MARK: - Preview
#Preview {
    LandingView()
        .environmentObject(NavigationCoordinator.shared)
        .environmentObject(AccessManager.shared)
}
