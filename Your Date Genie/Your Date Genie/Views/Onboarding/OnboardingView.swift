import SwiftUI

// MARK: - Main Onboarding View
struct MobileOnboardingView: View {
    @EnvironmentObject var coordinator: NavigationCoordinator
    @State private var currentSlide = 0
    @State private var showContent = false
    
    private let totalSlides = 4
    
    var body: some View {
        VStack(spacing: 0) {
            // Progress dots
            HStack(spacing: 8) {
                ForEach(0..<totalSlides, id: \.self) { index in
                    Capsule()
                        .fill(index == currentSlide ? Color.brandGold : Color.gray.opacity(0.3))
                        .frame(width: index == currentSlide ? 20 : 6, height: 6)
                        .animation(.spring(response: 0.5), value: currentSlide)
                }
            }
            .padding(.top, 60)
            .padding(.bottom, 8)
            
            // Main content
            TabView(selection: $currentSlide) {
                SlideWelcome(showContent: showContent)
                    .tag(0)
                SlideChaos(showContent: showContent)
                    .tag(1)
                SlideItinerary(showContent: showContent)
                    .tag(2)
                SlideGetStarted(showContent: showContent)
                    .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.3), value: currentSlide)
            
            // Bottom actions
            VStack(spacing: 8) {
                Button {
                    if currentSlide < totalSlides - 1 {
                        withAnimation {
                            currentSlide += 1
                        }
                    } else {
                        coordinator.completeOnboarding()
                    }
                } label: {
                    HStack(spacing: 8) {
                        Text(currentSlide == totalSlides - 1 ? "Get Started Free" : "Next")
                            .font(.system(size: 16, weight: .semibold))
                        
                        if currentSlide < totalSlides - 1 {
                            Image(systemName: "arrow.right")
                                .font(.system(size: 14, weight: .semibold))
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(LinearGradient.goldGradient)
                    .cornerRadius(14)
                }
                
                if currentSlide < totalSlides - 1 {
                    Button {
                        coordinator.completeOnboarding()
                    } label: {
                        Text("Skip")
                            .font(.system(size: 14))
                            .foregroundColor(Color(UIColor.tertiaryLabel))
                    }
                    .padding(.vertical, 8)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .background(Color.brandCream)
        .onChange(of: currentSlide) { _ in
            showContent = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeOut(duration: 0.5)) {
                    showContent = true
                }
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation {
                    showContent = true
                }
            }
        }
    }
}

// MARK: - Slide 1: Welcome with Floating Sparkles
struct SlideWelcome: View {
    let showContent: Bool
    @State private var animateSparkles = false
    @State private var animateGlow = false
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Hero image
                ZStack(alignment: .bottom) {
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
                    .frame(height: UIScreen.main.bounds.height * 0.42)
                    .clipped()
                    .opacity(showContent ? 1 : 0)
                    
                    // Gradient overlay
                    LinearGradient(
                        gradient: Gradient(colors: [.clear, .clear, Color.brandCream]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
                
                // Content
                VStack(alignment: .leading, spacing: 12) {
                    // Animated brand badge
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 16))
                            .foregroundColor(.brandGold)
                            .scaleEffect(animateSparkles ? 1.2 : 1.0)
                            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: animateSparkles)
                        
                        Text("YOUR DATE GENIE")
                            .font(.system(size: 10, weight: .semibold))
                            .tracking(1.5)
                            .foregroundColor(.brandPrimary)
                    }
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)
                    .animation(.easeOut(duration: 0.5).delay(0.2), value: showContent)
                    
                    // Title with gradient text animation
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Date nights,")
                            .font(.displayTitle())
                            .foregroundColor(Color(UIColor.label))
                        
                        Text("planned for you.")
                            .font(.displayTitle())
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.brandGold, Color.brandGold.opacity(0.7), Color.brandGold],
                                    startPoint: animateGlow ? .leading : .trailing,
                                    endPoint: animateGlow ? .trailing : .leading
                                )
                            )
                            .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animateGlow)
                    }
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)
                    .animation(.easeOut(duration: 0.5).delay(0.3), value: showContent)
                    
                    // Description
                    Text("Tell us what you love. We'll create a complete evening — venues, timing, and all the details.")
                        .font(.system(size: 15))
                        .foregroundColor(Color(UIColor.secondaryLabel))
                        .lineSpacing(4)
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 20)
                        .animation(.easeOut(duration: 0.5).delay(0.4), value: showContent)
                }
                .padding(.horizontal, 24)
                .padding(.top, -32)
                
                Spacer()
            }
            
            // Floating sparkles overlay
            FloatingSparkles(isAnimating: showContent)
        }
        .onAppear {
            animateSparkles = true
            animateGlow = true
        }
    }
}

// MARK: - Floating Sparkles Animation
struct FloatingSparkles: View {
    let isAnimating: Bool
    
    var body: some View {
        ZStack {
            ForEach(0..<8, id: \.self) { index in
                SparkleParticle(
                    delay: Double(index) * 0.3,
                    startX: CGFloat.random(in: 20...UIScreen.main.bounds.width - 20),
                    isAnimating: isAnimating
                )
            }
        }
    }
}

struct SparkleParticle: View {
    let delay: Double
    let startX: CGFloat
    let isAnimating: Bool
    
    @State private var opacity: Double = 0
    @State private var yOffset: CGFloat = 0
    @State private var scale: CGFloat = 0.5
    
    var body: some View {
        Image(systemName: "sparkle")
            .font(.system(size: CGFloat.random(in: 10...18)))
            .foregroundColor(.brandGold.opacity(0.6))
            .scaleEffect(scale)
            .opacity(opacity)
            .offset(x: startX - UIScreen.main.bounds.width / 2, y: yOffset)
            .onAppear {
                guard isAnimating else { return }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    withAnimation(.easeOut(duration: 3).repeatForever(autoreverses: false)) {
                        yOffset = -300
                        opacity = 0
                    }
                    withAnimation(.easeInOut(duration: 0.5)) {
                        opacity = 1
                        scale = 1
                    }
                }
            }
    }
}

// MARK: - Slide 2: The Chaos of Planning with Animations
struct SlideChaos: View {
    let showContent: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("Sound familiar?")
                    .font(.system(size: 13))
                    .foregroundColor(Color(UIColor.secondaryLabel))
                
                Text("Friday night. No plan.")
                    .font(.sectionTitle())
                    .foregroundColor(Color(UIColor.label))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .opacity(showContent ? 1 : 0)
            .animation(.easeOut(duration: 0.4), value: showContent)
            
            // Animated Phone mockup
            AnimatedPhoneMockup(showContent: showContent)
                .padding(.vertical, 16)
            
            // Pain points with typing effect
            AnimatedPainPoints(showContent: showContent)
            
            Spacer()
        }
    }
}

// MARK: - Animated Phone Mockup
struct AnimatedPhoneMockup: View {
    let showContent: Bool
    @State private var showNotification = false
    @State private var typingText = ""
    @State private var showResults = [false, false, false]
    @State private var showTimeIndicator = false
    @State private var searchTime = 0
    
    private let fullSearchText = "romantic restaurants near me..."
    
    var body: some View {
        ZStack {
            // Phone frame
            RoundedRectangle(cornerRadius: 36)
                .fill(Color.black)
                .frame(width: 220, height: 380)
                .overlay(
                    RoundedRectangle(cornerRadius: 32)
                        .fill(Color(hex: "1c1c1e"))
                        .padding(6)
                )
                .overlay(
                    VStack(spacing: 0) {
                        // Status bar
                        HStack {
                            Text("9:41")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Capsule()
                                .fill(Color.black)
                                .frame(width: 80, height: 24)
                            
                            Spacer()
                            
                            HStack(spacing: 4) {
                                Image(systemName: "cellularbars")
                                Image(systemName: "wifi")
                                Image(systemName: "battery.100")
                            }
                            .font(.system(size: 12))
                            .foregroundColor(.white)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        
                        // Animated browser tabs
                        AnimatedBrowserTabs(showContent: showContent)
                        
                        // Animated search bar with typing
                        HStack {
                            Text(typingText)
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.6))
                            
                            if typingText.count < fullSearchText.count {
                                Rectangle()
                                    .fill(Color.white)
                                    .frame(width: 1, height: 14)
                                    .opacity(showContent ? 1 : 0)
                                    .animation(.easeInOut(duration: 0.5).repeatForever(), value: showContent)
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(hex: "1c1c1e"))
                        .cornerRadius(8)
                        .padding(.horizontal, 12)
                        .padding(.top, 8)
                        
                        // Animated search results
                        VStack(spacing: 6) {
                            AnimatedSearchResult(
                                name: "Italian Place Downtown",
                                rating: 4,
                                reviews: 234,
                                price: "$$$",
                                distance: "2.3 mi",
                                isVisible: showResults[0]
                            )
                            
                            AnimatedSearchResult(
                                name: "Wine Bar & Bistro",
                                rating: 5,
                                reviews: 89,
                                price: "$$$$",
                                distance: "4.1 mi",
                                isVisible: showResults[1]
                            )
                            
                            AnimatedSearchResult(
                                name: "The Rooftop...",
                                rating: 0,
                                reviews: 0,
                                price: "",
                                distance: "",
                                isLoading: true,
                                isVisible: showResults[2]
                            )
                        }
                        .padding(.horizontal, 12)
                        .padding(.top, 8)
                        
                        Spacer()
                        
                        // App dock with bounce animation
                        AnimatedAppDock(showContent: showContent)
                        
                        Capsule()
                            .fill(Color.white.opacity(0.3))
                            .frame(width: 100, height: 4)
                            .padding(.bottom, 8)
                    }
                    .padding(6)
                )
            
            // Animated notification badge
            NotificationBadge(count: 12, isVisible: showNotification)
                .offset(x: 100, y: -180)
            
            // Animated time indicator
            TimeIndicator(minutes: searchTime, isVisible: showTimeIndicator)
                .offset(y: 200)
        }
        .scaleEffect(0.85)
        .opacity(showContent ? 1 : 0)
        .animation(.easeOut(duration: 0.5).delay(0.1), value: showContent)
        .onAppear {
            startAnimations()
        }
        .onChange(of: showContent) { newValue in
            if newValue {
                startAnimations()
            }
        }
    }
    
    private func startAnimations() {
        typingText = ""
        showNotification = false
        showResults = [false, false, false]
        showTimeIndicator = false
        searchTime = 0
        
        // Typing animation
        for (index, char) in fullSearchText.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.05 + 0.5) {
                typingText += String(char)
            }
        }
        
        // Show results sequentially
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.spring(response: 0.4)) {
                showResults[0] = true
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
            withAnimation(.spring(response: 0.4)) {
                showResults[1] = true
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) {
            withAnimation(.spring(response: 0.4)) {
                showResults[2] = true
            }
        }
        
        // Show notification
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                showNotification = true
            }
        }
        
        // Show time indicator and count up
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(.spring(response: 0.4)) {
                showTimeIndicator = true
            }
            
            // Count up timer
            Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
                if searchTime < 45 {
                    searchTime += 1
                } else {
                    timer.invalidate()
                }
            }
        }
    }
}

struct AnimatedBrowserTabs: View {
    let showContent: Bool
    @State private var activeTab = 0
    
    var body: some View {
        HStack(spacing: 4) {
            BrowserTab(name: "Yelp", color: Color(hex: "d32323"), isActive: activeTab == 0)
            BrowserTab(name: "Google", color: .blue, isActive: activeTab == 1)
            
            HStack(spacing: 2) {
                Text("+8")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(hex: "3a3a3c"))
            .cornerRadius(4)
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .onAppear {
            // Animate tab switching
            Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
                withAnimation(.easeInOut(duration: 0.3)) {
                    activeTab = activeTab == 0 ? 1 : 0
                }
            }
        }
    }
}

struct AnimatedSearchResult: View {
    let name: String
    let rating: Int
    let reviews: Int
    let price: String
    let distance: String
    var isLoading: Bool = false
    let isVisible: Bool
    
    @State private var loadingDots = ""
    
    var body: some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 40)
                .overlay(
                    Group {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.5)
                                .tint(.gray)
                        }
                    }
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color(UIColor.label))
                    .lineLimit(1)
                
                if isLoading {
                    Text("Loading\(loadingDots)")
                        .font(.system(size: 9))
                        .foregroundColor(Color(UIColor.tertiaryLabel))
                        .onAppear {
                            Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                                loadingDots = loadingDots.count >= 3 ? "" : loadingDots + "."
                            }
                        }
                } else {
                    HStack(spacing: 2) {
                        ForEach(0..<5, id: \.self) { index in
                            Image(systemName: "star.fill")
                                .font(.system(size: 7))
                                .foregroundColor(index < rating ? .red : Color.gray.opacity(0.3))
                        }
                        Text("(\(reviews))")
                            .font(.system(size: 9))
                            .foregroundColor(Color(UIColor.tertiaryLabel))
                    }
                    
                    Text("\(price) · \(distance)")
                        .font(.system(size: 9))
                        .foregroundColor(Color(UIColor.tertiaryLabel))
                }
            }
            
            Spacer()
        }
        .padding(8)
        .background(Color.white)
        .cornerRadius(8)
        .opacity(isLoading ? 0.6 : 1)
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 20)
    }
}

struct AnimatedAppDock: View {
    let showContent: Bool
    @State private var bounceIndex = -1
    
    var body: some View {
        HStack(spacing: 16) {
            AppDockIcon(name: "OpenTable", color: Color(hex: "da3743"), letter: "O", isBouncing: bounceIndex == 0)
            AppDockIcon(name: "Maps", color: .green, letter: "M", isBouncing: bounceIndex == 1)
            AppDockIcon(name: "Resy", color: Color(hex: "1a1a1a"), letter: "R", isBouncing: bounceIndex == 2)
            AppDockIcon(name: "Trip", color: Color(hex: "00af87"), letter: "T", isBouncing: bounceIndex == 3)
        }
        .padding(.vertical, 12)
        .onAppear {
            // Random bounce animation
            Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { _ in
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                    bounceIndex = Int.random(in: 0...3)
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    bounceIndex = -1
                }
            }
        }
    }
}

struct NotificationBadge: View {
    let count: Int
    let isVisible: Bool
    
    @State private var isPulsing = false
    
    var body: some View {
        Circle()
            .fill(Color.red)
            .frame(width: 20, height: 20)
            .overlay(
                Text("\(count)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
            )
            .scaleEffect(isPulsing ? 1.1 : 1.0)
            .opacity(isVisible ? 1 : 0)
            .scaleEffect(isVisible ? 1 : 0.5)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            }
    }
}

struct TimeIndicator: View {
    let minutes: Int
    let isVisible: Bool
    
    @State private var isPulsing = false
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(Color.red)
                .frame(width: 6, height: 6)
                .scaleEffect(isPulsing ? 1.3 : 1.0)
            
            Text("\(minutes) min searching...")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Color(UIColor.label))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.1), radius: 8, y: 4)
        .opacity(isVisible ? 1 : 0)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
        }
    }
}

struct AnimatedPainPoints: View {
    let showContent: Bool
    @State private var showLine1 = false
    @State private var showLine2 = false
    
    var body: some View {
        VStack(spacing: 4) {
            Text("Too many apps. Too many reviews.")
                .font(.system(size: 14))
                .foregroundColor(Color(UIColor.secondaryLabel))
                .opacity(showLine1 ? 1 : 0)
                .offset(y: showLine1 ? 0 : 10)
            
            Text("After work, who has time for this?")
                .font(.system(size: 14))
                .foregroundColor(Color(UIColor.secondaryLabel))
                .opacity(showLine2 ? 1 : 0)
                .offset(y: showLine2 ? 0 : 10)
        }
        .multilineTextAlignment(.center)
        .onChange(of: showContent) { newValue in
            if newValue {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                    withAnimation(.easeOut(duration: 0.4)) {
                        showLine1 = true
                    }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                    withAnimation(.easeOut(duration: 0.4)) {
                        showLine2 = true
                    }
                }
            }
        }
    }
}

struct BrowserTab: View {
    let name: String
    let color: Color
    let isActive: Bool
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            
            Text(name)
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(isActive ? 0.9 : 0.6))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(isActive ? Color(hex: "4a4a4c") : Color(hex: "3a3a3c"))
        .cornerRadius(4)
        .scaleEffect(isActive ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isActive)
    }
}

struct AppDockIcon: View {
    let name: String
    let color: Color
    let letter: String
    var isBouncing: Bool = false
    
    var body: some View {
        VStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 10)
                .fill(color)
                .frame(width: 36, height: 36)
                .overlay(
                    Text(letter)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                )
                .offset(y: isBouncing ? -5 : 0)
            
            Text(name)
                .font(.system(size: 8))
                .foregroundColor(.white.opacity(0.6))
        }
    }
}

// MARK: - Slide 3: The Itinerary Preview with Timeline Animation
struct SlideItinerary: View {
    let showContent: Bool
    @State private var timelineProgress: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("What you get")
                    .font(.system(size: 13))
                    .foregroundColor(Color(UIColor.secondaryLabel))
                
                Text("A complete date plan")
                    .font(.sectionTitle())
                    .foregroundColor(Color(UIColor.label))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .opacity(showContent ? 1 : 0)
            .animation(.easeOut(duration: 0.4), value: showContent)
            
            // Animated Itinerary card
            VStack(spacing: 0) {
                // Header banner with shimmer
                ZStack(alignment: .bottomLeading) {
                    AsyncImage(url: URL(string: "https://images.unsplash.com/photo-1559620192-032c4bc4674e?w=600&h=400&fit=crop")) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .empty, .failure:
                            Rectangle()
                                .fill(Color.brandPrimary.opacity(0.5))
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .frame(height: 80)
                    .clipped()
                    .overlay(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.brandPrimary.opacity(0.8), Color.brandPrimary.opacity(0.4)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .overlay(ShimmerEffect())
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Romantic Italian Night")
                            .font(.cardTitle())
                            .foregroundColor(.white)
                        
                        Text("Saturday · 3 stops · ~$150")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(16)
                }
                
                // Animated Timeline stops
                VStack(spacing: 0) {
                    AnimatedItineraryStop(
                        time: "7:00 PM",
                        name: "The Cellar Wine Bar",
                        tip: "Start with Italian reds",
                        icon: "wineglass.fill",
                        imageUrl: "https://images.unsplash.com/photo-1510812431401-41d2bd2722f3?w=400&h=300&fit=crop",
                        showContent: showContent,
                        delay: 0.2,
                        timelineProgress: timelineProgress,
                        requiredProgress: 0.0
                    )
                    
                    AnimatedItineraryStop(
                        time: "8:30 PM",
                        name: "Trattoria Milano",
                        tip: "Try the truffle pasta",
                        icon: "fork.knife",
                        imageUrl: "https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=400&h=300&fit=crop",
                        showContent: showContent,
                        delay: 0.4,
                        timelineProgress: timelineProgress,
                        requiredProgress: 0.33
                    )
                    
                    AnimatedItineraryStop(
                        time: "10:30 PM",
                        name: "Skyview Rooftop",
                        tip: "Nightcap under the stars",
                        icon: "cup.and.saucer.fill",
                        imageUrl: "https://images.unsplash.com/photo-1470337458703-46ad1756a187?w=400&h=300&fit=crop",
                        showContent: showContent,
                        delay: 0.6,
                        timelineProgress: timelineProgress,
                        requiredProgress: 0.66,
                        isLast: true
                    )
                }
                .padding(16)
                
                // Animated included badges
                AnimatedBadges(showContent: showContent)
                    .padding(.bottom, 16)
            }
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.08), radius: 12, y: 4)
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 20)
            .animation(.easeOut(duration: 0.5).delay(0.1), value: showContent)
            
            Spacer()
        }
        .onChange(of: showContent) { newValue in
            if newValue {
                timelineProgress = 0
                withAnimation(.easeInOut(duration: 2.0).delay(0.5)) {
                    timelineProgress = 1.0
                }
            }
        }
    }
}

struct ShimmerEffect: View {
    @State private var shimmerOffset: CGFloat = -1
    
    var body: some View {
        GeometryReader { geometry in
            LinearGradient(
                colors: [.clear, .white.opacity(0.3), .clear],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: geometry.size.width * 0.5)
            .offset(x: shimmerOffset * geometry.size.width)
            .onAppear {
                withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                    shimmerOffset = 1.5
                }
            }
        }
        .clipped()
    }
}

struct AnimatedItineraryStop: View {
    let time: String
    let name: String
    let tip: String
    let icon: String
    let imageUrl: String
    let showContent: Bool
    let delay: Double
    let timelineProgress: CGFloat
    let requiredProgress: CGFloat
    var isLast: Bool = false
    
    private var isActive: Bool {
        timelineProgress >= requiredProgress
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Animated Timeline
            VStack(spacing: 0) {
                Circle()
                    .fill(isActive ? LinearGradient.goldGradient : LinearGradient(colors: [Color.gray.opacity(0.3)], startPoint: .top, endPoint: .bottom))
                    .frame(width: 28, height: 28)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 12))
                            .foregroundColor(isActive ? .white : .gray)
                    )
                    .scaleEffect(isActive ? 1.0 : 0.8)
                    .animation(.spring(response: 0.4), value: isActive)
                
                if !isLast {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color.brandGold, Color.gray.opacity(0.2)],
                                startPoint: .top,
                                endPoint: UnitPoint(x: 0.5, y: min(1, max(0, (timelineProgress - requiredProgress) / 0.33)))
                            )
                        )
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                }
            }
            .frame(width: 28)
            
            // Content with slide-in
            HStack(spacing: 10) {
                AsyncImage(url: URL(string: imageUrl)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .empty, .failure:
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(width: 56, height: 56)
                .cornerRadius(10)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(time)
                        .font(.system(size: 11))
                        .foregroundColor(Color(UIColor.secondaryLabel))
                    
                    Text(name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(UIColor.label))
                        .lineLimit(1)
                    
                    Text(tip)
                        .font(.system(size: 11))
                        .foregroundColor(.brandPrimary)
                        .italic()
                        .lineLimit(1)
                }
                
                Spacer()
            }
            .padding(.bottom, isLast ? 0 : 12)
            .opacity(isActive ? 1 : 0.5)
        }
        .opacity(showContent ? 1 : 0)
        .offset(x: showContent ? 0 : -20)
        .animation(.easeOut(duration: 0.4).delay(delay), value: showContent)
    }
}

struct AnimatedBadges: View {
    let showContent: Bool
    @State private var visibleBadges: [Bool] = [false, false, false, false]
    
    private let badges = ["Directions", "Tips", "Conversation starters", "Gift ideas"]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(0..<badges.count, id: \.self) { index in
                    Text(badges[index])
                        .font(.system(size: 11))
                        .foregroundColor(Color(UIColor.secondaryLabel))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(20)
                        .opacity(visibleBadges[index] ? 1 : 0)
                        .offset(y: visibleBadges[index] ? 0 : 10)
                }
            }
            .padding(.horizontal, 16)
        }
        .onChange(of: showContent) { newValue in
            if newValue {
                for i in 0..<badges.count {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5 + Double(i) * 0.15) {
                        withAnimation(.spring(response: 0.4)) {
                            visibleBadges[i] = true
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Slide 4: Get Started with Celebration
struct SlideGetStarted: View {
    let showContent: Bool
    @State private var showConfetti = false
    @State private var benefitChecks = [false, false, false]
    @State private var counterValue = 0
    
    private let userImages = [
        "https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=80&h=80&fit=crop&crop=faces",
        "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=80&h=80&fit=crop&crop=faces",
        "https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=80&h=80&fit=crop&crop=faces",
        "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=80&h=80&fit=crop&crop=faces"
    ]
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Image with animated stars
                ZStack(alignment: .bottomLeading) {
                    AsyncImage(url: URL(string: "https://images.unsplash.com/photo-1559620192-032c4bc4674e?w=600&h=400&fit=crop")) { phase in
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
                    .frame(height: 160)
                    .clipped()
                    .cornerRadius(16)
                    
                    LinearGradient(
                        gradient: Gradient(colors: [.clear, Color.black.opacity(0.6)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .cornerRadius(16)
                    
                    HStack(spacing: 4) {
                        ForEach(0..<5, id: \.self) { index in
                            Image(systemName: "star.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.brandGold)
                                .scaleEffect(showContent ? 1 : 0)
                                .animation(.spring(response: 0.3).delay(Double(index) * 0.1 + 0.3), value: showContent)
                        }
                        
                        Text("\"Stress-free date nights\"")
                            .font(.system(size: 13))
                            .foregroundColor(.white)
                            .padding(.leading, 4)
                    }
                    .padding(16)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .opacity(showContent ? 1 : 0)
                .scaleEffect(showContent ? 1 : 0.95)
                .animation(.easeOut(duration: 0.5), value: showContent)
                
                // Content
                VStack(spacing: 8) {
                    Text("Ready for better dates?")
                        .font(.cormorant(26, weight: .bold))
                        .foregroundColor(Color(UIColor.label))
                    
                    Text("Answer a few questions. Get a plan in seconds.")
                        .font(.system(size: 15))
                        .foregroundColor(Color(UIColor.secondaryLabel))
                }
                .multilineTextAlignment(.center)
                .padding(.top, 20)
                .opacity(showContent ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(0.2), value: showContent)
                
                // Animated Benefits
                VStack(spacing: 12) {
                    AnimatedBenefitRow(text: "Takes less than 2 minutes", isChecked: benefitChecks[0])
                    AnimatedBenefitRow(text: "Tailored to your vibe & budget", isChecked: benefitChecks[1])
                    AnimatedBenefitRow(text: "Real venues, verified details", isChecked: benefitChecks[2])
                }
                .padding(.horizontal, 40)
                .padding(.top, 20)
                
                Spacer()
                
                // Animated Social proof with counter
                VStack(spacing: 8) {
                    HStack(spacing: -8) {
                        ForEach(userImages.indices, id: \.self) { index in
                            AsyncImage(url: URL(string: userImages[index])) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                case .empty, .failure:
                                    Circle()
                                        .fill(Color.gray.opacity(0.3))
                                @unknown default:
                                    EmptyView()
                                }
                            }
                            .frame(width: 28, height: 28)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.brandCream, lineWidth: 2))
                            .offset(x: showContent ? 0 : CGFloat(index) * -10)
                            .animation(.spring(response: 0.4).delay(Double(index) * 0.1 + 0.5), value: showContent)
                        }
                        
                        HStack(spacing: 4) {
                            Text("\(counterValue)+")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Color(UIColor.label))
                                .contentTransition(.numericText())
                            
                            Text("couples joined")
                                .font(.system(size: 13))
                                .foregroundColor(Color(UIColor.secondaryLabel))
                        }
                        .padding(.leading, 12)
                    }
                    
                    Text("Free to start · No credit card")
                        .font(.system(size: 11))
                        .foregroundColor(Color(UIColor.tertiaryLabel))
                }
                .padding(.bottom, 8)
                .opacity(showContent ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(0.5), value: showContent)
            }
            
            // Confetti overlay
            if showConfetti {
                ConfettiView()
            }
        }
        .onChange(of: showContent) { newValue in
            if newValue {
                // Animate benefit checkmarks
                for i in 0..<3 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5 + Double(i) * 0.3) {
                        withAnimation(.spring(response: 0.3)) {
                            benefitChecks[i] = true
                        }
                    }
                }
                
                // Animate counter
                counterValue = 0
                Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { timer in
                    if counterValue < 500 {
                        counterValue += 10
                    } else {
                        timer.invalidate()
                    }
                }
                
                // Show confetti
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    showConfetti = true
                }
            }
        }
    }
}

struct AnimatedBenefitRow: View {
    let text: String
    let isChecked: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(isChecked ? Color.green : Color.gray.opacity(0.3), lineWidth: 2)
                    .frame(width: 20, height: 20)
                
                if isChecked {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 20, height: 20)
                        .overlay(
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                        )
                        .transition(.scale.combined(with: .opacity))
                }
            }
            
            Text(text)
                .font(.system(size: 15))
                .foregroundColor(isChecked ? Color(UIColor.label) : Color(UIColor.tertiaryLabel))
            
            Spacer()
        }
        .animation(.spring(response: 0.3), value: isChecked)
    }
}

// MARK: - Confetti View
struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []
    
    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .position(particle.position)
                    .opacity(particle.opacity)
            }
        }
        .onAppear {
            createParticles()
        }
    }
    
    private func createParticles() {
        let colors: [Color] = [.brandGold, .pink, .purple, .blue, .green, .orange]
        
        for _ in 0..<30 {
            let particle = ConfettiParticle(
                color: colors.randomElement()!,
                size: CGFloat.random(in: 4...10),
                position: CGPoint(
                    x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                    y: -20
                ),
                opacity: 1
            )
            particles.append(particle)
        }
        
        // Animate particles falling
        for i in particles.indices {
            let delay = Double.random(in: 0...0.5)
            let duration = Double.random(in: 2...3)
            
            withAnimation(.easeIn(duration: duration).delay(delay)) {
                particles[i].position.y = UIScreen.main.bounds.height + 50
                particles[i].position.x += CGFloat.random(in: -50...50)
            }
            
            withAnimation(.easeIn(duration: duration * 0.8).delay(delay + duration * 0.5)) {
                particles[i].opacity = 0
            }
        }
    }
}

struct ConfettiParticle: Identifiable {
    let id = UUID()
    let color: Color
    let size: CGFloat
    var position: CGPoint
    var opacity: Double
}

// MARK: - Color Extension
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

// MARK: - Preview
#Preview {
    MobileOnboardingView()
        .environmentObject(NavigationCoordinator.shared)
}
