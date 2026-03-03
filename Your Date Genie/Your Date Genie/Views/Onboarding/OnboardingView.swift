import SwiftUI

// MARK: - Main Onboarding View
struct MobileOnboardingView: View {
    @EnvironmentObject var coordinator: NavigationCoordinator
    @State private var currentSlide = 0
    @State private var showContent = false
    
    private let totalSlides = 4
    
    var body: some View {
        ZStack {
            // Luxurious background
            Color.luxuryMaroon
                .ignoresSafeArea()
            
            // Subtle gold vignette
            RadialGradient.goldGlow
                .opacity(0.15)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Progress dots
                HStack(spacing: 10) {
                    ForEach(0..<totalSlides, id: \.self) { index in
                        Capsule()
                            .fill(index == currentSlide ? Color.luxuryGold : Color.luxuryMuted.opacity(0.4))
                            .frame(width: index == currentSlide ? 24 : 8, height: 8)
                            .animation(.spring(response: 0.4), value: currentSlide)
                    }
                }
                .padding(.top, 60)
                .padding(.bottom, 12)
                
                // Main content
                TabView(selection: $currentSlide) {
                    LuxurySlideWelcome(showContent: showContent)
                        .tag(0)
                    LuxurySlideChaos(showContent: showContent)
                        .tag(1)
                    LuxurySlideItinerary(showContent: showContent)
                        .tag(2)
                    LuxurySlideGetStarted(showContent: showContent)
                        .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: currentSlide)
                
                // Bottom actions
                VStack(spacing: 12) {
                    Button {
                        if currentSlide < totalSlides - 1 {
                            withAnimation {
                                currentSlide += 1
                            }
                        } else {
                            coordinator.completeOnboarding()
                        }
                    } label: {
                        HStack(spacing: 10) {
                            Text(currentSlide == totalSlides - 1 ? "Begin Your Journey" : "Next")
                            
                            if currentSlide < totalSlides - 1 {
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 14, weight: .semibold))
                            } else {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 14))
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(LuxuryGoldButtonStyle())
                    
                    if currentSlide < totalSlides - 1 {
                        Button {
                            coordinator.completeOnboarding()
                        } label: {
                            Text("Skip")
                                .font(Font.bodySans(14, weight: .regular))
                                .foregroundColor(Color.luxuryMuted)
                        }
                        .padding(.vertical, 8)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 44)
            }
        }
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

// MARK: - Slide 1: Welcome
struct LuxurySlideWelcome: View {
    let showContent: Bool
    @State private var sparkleRotation: Double = 0
    @State private var glowPulse: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Hero image with luxurious overlay
            ZStack(alignment: .bottom) {
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
                .frame(height: UIScreen.main.bounds.height * 0.42)
                .clipped()
                .overlay(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.luxuryMaroon.opacity(0.2),
                            Color.luxuryMaroon.opacity(0.6),
                            Color.luxuryMaroon
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .opacity(showContent ? 1 : 0)
            }
            
            // Content
            VStack(alignment: .center, spacing: 20) {
                // Animated sparkle icon
                ZStack {
                    Image(systemName: "sparkles")
                        .font(.system(size: 50))
                        .foregroundColor(Color.luxuryGold.opacity(0.3))
                        .blur(radius: glowPulse ? 15 : 10)
                    
                    Image(systemName: "sparkles")
                        .font(.system(size: 40))
                        .foregroundStyle(LinearGradient.goldShimmer)
                        .rotationEffect(.degrees(sparkleRotation))
                }
                .opacity(showContent ? 1 : 0)
                .scaleEffect(showContent ? 1 : 0.5)
                .animation(.spring(response: 0.6).delay(0.2), value: showContent)
                
                // Brand text
                VStack(spacing: 6) {
                    Text("Your Date ")
                        .font(Font.header(14, weight: .bold))
                        .foregroundColor(Color.luxuryGold.opacity(0.8))
                    +
                    Text("Genie")
                        .font(Font.special(32, weight: .bold))
                        .foregroundColor(Color.luxuryGold)
                }
                .opacity(showContent ? 1 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.3), value: showContent)
                
                // Title
                VStack(spacing: 8) {
                    Text("Date nights,")
                        .font(Font.header(34, weight: .bold))
                        .foregroundColor(Color.luxuryCream)
                    
                    Text("planned for you.")
                        .font(Font.header(34, weight: .bold))
                        .foregroundStyle(LinearGradient.goldShimmer)
                }
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)
                .animation(.easeOut(duration: 0.5).delay(0.4), value: showContent)
                
                // Description
                Text("Tell us what you love. We'll create a complete evening — venues, timing, and all the details.")
                    .font(Font.subheader(16, weight: .regular))
                    .foregroundColor(Color.luxuryCreamMuted)
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
                    .padding(.horizontal, 20)
                    .opacity(showContent ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(0.5), value: showContent)
            }
            .padding(.top, -20)
            
            Spacer()
        }
        .onAppear {
            withAnimation(.linear(duration: 30).repeatForever(autoreverses: false)) {
                sparkleRotation = 360
            }
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                glowPulse = true
            }
        }
    }
}

// MARK: - Slide 2: The Chaos
struct LuxurySlideChaos: View {
    let showContent: Bool
    @State private var searchProgress: CGFloat = 0
    @State private var showFrustration = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 6) {
                Text("Sound familiar?")
                    .font(Font.bodySans(13, weight: .regular))
                    .foregroundColor(Color.luxuryMuted)
                
                Text("Friday night. No plan.")
                    .font(Font.header(26, weight: .bold))
                    .foregroundColor(Color.luxuryGold)
            }
            .padding(.top, 12)
            .opacity(showContent ? 1 : 0)
            .animation(.easeOut(duration: 0.4), value: showContent)
            
            // Phone mockup with chaos visualization
            ZStack {
                // Phone frame
                RoundedRectangle(cornerRadius: 40)
                    .fill(Color.black)
                    .frame(width: 200, height: 340)
                    .overlay(
                        RoundedRectangle(cornerRadius: 36)
                            .fill(Color(hex: "1a1a1a"))
                            .padding(5)
                    )
                    .overlay(
                        VStack(spacing: 0) {
                            // Notch area
                            HStack {
                                Text("9:41")
                                    .font(Font.inter(11, weight: .semibold))
                                    .foregroundColor(.white)
                                Spacer()
                                Capsule()
                                    .fill(Color.black)
                                    .frame(width: 70, height: 22)
                                Spacer()
                                HStack(spacing: 3) {
                                    Image(systemName: "cellularbars")
                                    Image(systemName: "wifi")
                                    Image(systemName: "battery.100")
                                }
                                .font(.system(size: 10))
                                .foregroundColor(.white)
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 10)
                            
                            // App chaos
                            VStack(spacing: 8) {
                                // Multiple "app" cards
                                ForEach(0..<4, id: \.self) { index in
                                    HStack(spacing: 8) {
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(Color.gray.opacity(0.3))
                                            .frame(width: 36, height: 36)
                                        
                                        VStack(alignment: .leading, spacing: 3) {
                                            RoundedRectangle(cornerRadius: 2)
                                                .fill(Color.white.opacity(0.6))
                                                .frame(width: CGFloat.random(in: 60...100), height: 10)
                                            RoundedRectangle(cornerRadius: 2)
                                                .fill(Color.gray.opacity(0.4))
                                                .frame(width: CGFloat.random(in: 40...80), height: 8)
                                        }
                                        Spacer()
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 8)
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(8)
                                    .opacity(showContent ? 1 : 0)
                                    .offset(x: showContent ? 0 : -50)
                                    .animation(.easeOut(duration: 0.4).delay(Double(index) * 0.1 + 0.3), value: showContent)
                                }
                            }
                            .padding(12)
                            
                            Spacer()
                            
                            // Loading indicator
                            HStack(spacing: 6) {
                                ProgressView()
                                    .tint(Color.luxuryGold)
                                    .scaleEffect(0.7)
                                Text("Still searching...")
                                    .font(Font.inter(10, weight: .regular))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                            .padding(.bottom, 20)
                        }
                        .padding(5)
                    )
                
                // Notification badges
                Circle()
                    .fill(Color.red)
                    .frame(width: 22, height: 22)
                    .overlay(
                        Text("12")
                            .font(Font.inter(10, weight: .bold))
                            .foregroundColor(.white)
                    )
                    .offset(x: 85, y: -150)
                    .opacity(showContent ? 1 : 0)
                    .scaleEffect(showContent ? 1 : 0)
                    .animation(.spring(response: 0.4).delay(0.6), value: showContent)
                
                // Time indicator
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                    Text("45 min searching...")
                        .font(Font.inter(12, weight: .medium))
                        .foregroundColor(Color.luxuryCream)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.luxuryMaroonLight)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.luxuryGold.opacity(0.3), lineWidth: 1)
                )
                .offset(y: 185)
                .opacity(showContent ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(0.8), value: showContent)
            }
            .scaleEffect(0.9)
            .padding(.vertical, 20)
            .opacity(showContent ? 1 : 0)
            .animation(.easeOut(duration: 0.5).delay(0.2), value: showContent)
            
            // Pain point text
            VStack(spacing: 6) {
                Text("Too many apps. Too many reviews.")
                    .font(Font.subheader(15, weight: .regular))
                    .foregroundColor(Color.luxuryCreamMuted)
                
                Text("After work, who has time?")
                    .font(Font.subheaderItalic(15))
                    .foregroundColor(Color.luxuryGold.opacity(0.8))
            }
            .multilineTextAlignment(.center)
            .opacity(showContent ? 1 : 0)
            .animation(.easeOut(duration: 0.4).delay(1.0), value: showContent)
            
            Spacer()
        }
    }
}

// MARK: - Slide 3: The Itinerary
struct LuxurySlideItinerary: View {
    let showContent: Bool
    @State private var timelineProgress: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 6) {
                Text("What you get")
                    .font(Font.bodySans(13, weight: .regular))
                    .foregroundColor(Color.luxuryMuted)
                
                Text("A complete date plan")
                    .font(Font.header(26, weight: .bold))
                    .foregroundColor(Color.luxuryGold)
            }
            .padding(.top, 12)
            .opacity(showContent ? 1 : 0)
            .animation(.easeOut(duration: 0.4), value: showContent)
            
            // Itinerary card
            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Romantic Italian Night")
                            .font(Font.subheader(18, weight: .semibold))
                            .foregroundColor(Color.luxuryGold)
                        
                        Text("Saturday · 3 stops · ~$150")
                            .font(Font.bodySans(12, weight: .regular))
                            .foregroundColor(Color.luxuryMuted)
                    }
                    Spacer()
                    Image(systemName: "sparkles")
                        .foregroundStyle(LinearGradient.goldShimmer)
                }
                .padding(18)
                .background(Color.luxuryMaroonLight.opacity(0.8))
                
                // Timeline
                VStack(spacing: 0) {
                    OnboardingItineraryStop(
                        time: "7:00 PM",
                        name: "Wine Bar",
                        emoji: "🍷",
                        tip: "Start with Italian reds",
                        isActive: timelineProgress >= 0,
                        showContent: showContent,
                        delay: 0.3
                    )
                    
                    OnboardingItineraryStop(
                        time: "8:30 PM",
                        name: "Trattoria",
                        emoji: "🍝",
                        tip: "Try the truffle pasta",
                        isActive: timelineProgress >= 0.5,
                        showContent: showContent,
                        delay: 0.5
                    )
                    
                    OnboardingItineraryStop(
                        time: "10:30 PM",
                        name: "Rooftop",
                        emoji: "🌃",
                        tip: "Nightcap under stars",
                        isActive: timelineProgress >= 1.0,
                        showContent: showContent,
                        delay: 0.7,
                        isLast: true
                    )
                }
                .padding(18)
                
                // Features
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        OnboardingFeatureBadge(text: "Directions")
                        OnboardingFeatureBadge(text: "Tips")
                        OnboardingFeatureBadge(text: "Gifts")
                        OnboardingFeatureBadge(text: "Playlist")
                    }
                    .padding(.horizontal, 18)
                }
                .padding(.bottom, 18)
                .opacity(showContent ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(0.9), value: showContent)
            }
            .luxuryCard()
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 30)
            .animation(.easeOut(duration: 0.5).delay(0.2), value: showContent)
            
            Spacer()
        }
        .onChange(of: showContent) { newValue in
            if newValue {
                withAnimation(.easeInOut(duration: 1.5).delay(0.5)) {
                    timelineProgress = 1.0
                }
            }
        }
    }
}

struct OnboardingItineraryStop: View {
    let time: String
    let name: String
    let emoji: String
    let tip: String
    let isActive: Bool
    let showContent: Bool
    let delay: Double
    var isLast: Bool = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            // Timeline dot
            VStack(spacing: 0) {
                Circle()
                    .fill(isActive ? LinearGradient.goldShimmer : LinearGradient(colors: [Color.luxuryMuted.opacity(0.3)], startPoint: .top, endPoint: .bottom))
                    .frame(width: 28, height: 28)
                    .overlay(
                        Text(emoji)
                            .font(.system(size: 14))
                    )
                
                if !isLast {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color.luxuryGold.opacity(isActive ? 0.6 : 0.2), Color.luxuryGold.opacity(0.1)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 2, height: 40)
                }
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(time)
                    .font(Font.bodySans(11, weight: .medium))
                    .foregroundColor(Color.luxuryGold)
                
                Text(name)
                    .font(Font.subheader(15, weight: .semibold))
                    .foregroundColor(Color.luxuryCream)
                
                Text(tip)
                    .font(Font.subheaderItalic(12))
                    .foregroundColor(Color.luxuryMuted)
            }
            .opacity(isActive ? 1 : 0.5)
            
            Spacer()
        }
        .opacity(showContent ? 1 : 0)
        .offset(x: showContent ? 0 : -20)
        .animation(.easeOut(duration: 0.4).delay(delay), value: showContent)
    }
}

struct OnboardingFeatureBadge: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(Font.bodySans(11, weight: .medium))
            .foregroundColor(Color.luxuryGold)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color.luxuryGold.opacity(0.15))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.luxuryGold.opacity(0.3), lineWidth: 1)
            )
    }
}

// MARK: - Slide 4: Get Started
struct LuxurySlideGetStarted: View {
    let showContent: Bool
    @State private var benefitChecks = [false, false, false]
    @State private var counterValue = 0
    
    private let userImages = [
        "https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=80&h=80&fit=crop&crop=faces",
        "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=80&h=80&fit=crop&crop=faces",
        "https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=80&h=80&fit=crop&crop=faces",
        "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=80&h=80&fit=crop&crop=faces"
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Hero image
            ZStack(alignment: .bottomLeading) {
                AsyncImage(url: URL(string: "https://images.unsplash.com/photo-1559620192-032c4bc4674e?w=600&h=400&fit=crop")) { phase in
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
                .frame(height: 180)
                .clipped()
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.luxuryGold.opacity(0.3), lineWidth: 1)
                )
                .overlay(
                    LinearGradient(
                        gradient: Gradient(colors: [.clear, Color.luxuryMaroon.opacity(0.8)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .cornerRadius(20)
                )
                
                // Rating overlay
                HStack(spacing: 6) {
                    ForEach(0..<5, id: \.self) { index in
                        Image(systemName: "star.fill")
                            .font(.system(size: 12))
                            .foregroundColor(Color.luxuryGold)
                            .opacity(showContent ? 1 : 0)
                            .scaleEffect(showContent ? 1 : 0)
                            .animation(.spring(response: 0.3).delay(Double(index) * 0.1 + 0.4), value: showContent)
                    }
                    
                    Text("Magical")
                        .font(Font.special(24, weight: .bold))
                        .foregroundColor(Color.luxuryGold)
                    Text("evenings")
                        .font(Font.subheaderItalic(13))
                        .foregroundColor(Color.luxuryCream)
                }
                .padding(16)
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
            .opacity(showContent ? 1 : 0)
            .scaleEffect(showContent ? 1 : 0.95)
            .animation(.easeOut(duration: 0.5), value: showContent)
            
            // Title
            VStack(spacing: 8) {
                Text("Ready for better dates?")
                    .font(Font.header(28, weight: .bold))
                    .foregroundColor(Color.luxuryGold)
                
                HStack(spacing: 4) {
                    Text("Answer a few questions. Get")
                        .font(Font.subheader(15, weight: .regular))
                        .foregroundColor(Color.luxuryCreamMuted)
                    Text("magic")
                        .font(Font.special(26, weight: .bold))
                        .foregroundColor(Color.luxuryGold)
                    Text("in seconds.")
                        .font(Font.subheader(15, weight: .regular))
                        .foregroundColor(Color.luxuryCreamMuted)
                }
            }
            .multilineTextAlignment(.center)
            .padding(.top, 24)
            .opacity(showContent ? 1 : 0)
            .animation(.easeOut(duration: 0.4).delay(0.2), value: showContent)
            
            // Benefits
            VStack(spacing: 14) {
                OnboardingBenefitRow(text: "Takes less than 2 minutes", isChecked: benefitChecks[0])
                OnboardingBenefitRow(text: "Tailored to your vibe & budget", isChecked: benefitChecks[1])
                OnboardingBenefitRow(text: "Real venues, verified details", isChecked: benefitChecks[2])
            }
            .padding(.horizontal, 40)
            .padding(.top, 24)
            
            Spacer()
            
            // Social proof
            VStack(spacing: 10) {
                HStack(spacing: -10) {
                    ForEach(userImages.indices, id: \.self) { index in
                        AsyncImage(url: URL(string: userImages[index])) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            case .empty, .failure:
                                Circle()
                                    .fill(Color.luxuryMaroonLight)
                            @unknown default:
                                EmptyView()
                            }
                        }
                        .frame(width: 32, height: 32)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.luxuryMaroon, lineWidth: 2))
                        .opacity(showContent ? 1 : 0)
                        .offset(x: showContent ? 0 : CGFloat(index) * -10)
                        .animation(.spring(response: 0.4).delay(Double(index) * 0.1 + 0.6), value: showContent)
                    }
                    
                    HStack(spacing: 4) {
                        Text("\(counterValue)+")
                            .font(Font.bodySans(14, weight: .bold))
                            .foregroundColor(Color.luxuryGold)
                            .contentTransition(.numericText())
                        
                        Text("couples joined")
                            .font(Font.bodySans(13, weight: .regular))
                            .foregroundColor(Color.luxuryMuted)
                    }
                    .padding(.leading, 14)
                }
                
                Text("Free to start · No credit card")
                    .font(Font.bodySans(11, weight: .regular))
                    .foregroundColor(Color.luxuryMuted.opacity(0.7))
            }
            .padding(.bottom, 12)
            .opacity(showContent ? 1 : 0)
            .animation(.easeOut(duration: 0.4).delay(0.8), value: showContent)
        }
        .onChange(of: showContent) { newValue in
            if newValue {
                // Animate benefit checkmarks
                for i in 0..<3 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5 + Double(i) * 0.25) {
                        withAnimation(.spring(response: 0.3)) {
                            benefitChecks[i] = true
                        }
                    }
                }
                
                // Animate counter
                counterValue = 0
                Timer.scheduledTimer(withTimeInterval: 0.015, repeats: true) { timer in
                    if counterValue < 500 {
                        counterValue += 8
                    } else {
                        timer.invalidate()
                    }
                }
            }
        }
    }
}

struct OnboardingBenefitRow: View {
    let text: String
    let isChecked: Bool
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .stroke(isChecked ? Color.luxuryGold : Color.luxuryMuted.opacity(0.3), lineWidth: 1.5)
                    .frame(width: 24, height: 24)
                
                if isChecked {
                    Circle()
                        .fill(Color.luxuryGold)
                        .frame(width: 24, height: 24)
                        .overlay(
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(Color.luxuryMaroon)
                        )
                        .transition(.scale.combined(with: .opacity))
                }
            }
            
            Text(text)
                .font(Font.subheader(15, weight: .regular))
                .foregroundColor(isChecked ? Color.luxuryCream : Color.luxuryMuted)
            
            Spacer()
        }
        .animation(.spring(response: 0.3), value: isChecked)
    }
}

// MARK: - Preview
#Preview {
    MobileOnboardingView()
        .environmentObject(NavigationCoordinator.shared)
}
