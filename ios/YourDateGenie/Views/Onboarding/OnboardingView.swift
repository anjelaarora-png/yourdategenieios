import SwiftUI

// MARK: - Main Onboarding View
struct MobileOnboardingView: View {
    @EnvironmentObject var coordinator: NavigationCoordinator
    @State private var currentSlide = 0
    @State private var showContent = false
    @State private var hasSwipedOnce = false
    
    private let totalSlides = 6
    
    var body: some View {
        ZStack {
            // Luxurious background
            Color.backgroundPrimary
                .ignoresSafeArea()
            
            // Subtle gold vignette
            RadialGradient.goldGlow
                .opacity(0.15)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top bar: back chevron (left) · progress dots (centre) · balance spacer (right)
                HStack(alignment: .center) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentSlide -= 1
                            hasSwipedOnce = true
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(Color.luxuryGold)
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                    .opacity(currentSlide > 0 ? 1 : 0)
                    .disabled(currentSlide == 0)
                    .animation(.easeInOut(duration: 0.2), value: currentSlide)

                    Spacer()

                    HStack(spacing: 12) {
                        ForEach(0..<totalSlides, id: \.self) { index in
                            Capsule()
                                .fill(index == currentSlide ? Color.luxuryGold : Color.luxuryMuted.opacity(0.4))
                                .frame(width: index == currentSlide ? 28 : 10, height: 10)
                                .animation(.spring(response: 0.4), value: currentSlide)
                        }
                    }

                    Spacer()

                    // Invisible balance element so dots stay perfectly centred
                    Color.clear
                        .frame(width: 44, height: 44)
                }
                .padding(.top, 56)
                .padding(.horizontal, 16)
                .padding(.bottom, 0)
                
                // Swipe affordance hint — fades out after first swipe
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 11, weight: .medium))
                    Text("Swipe to explore")
                        .font(Font.bodySans(12, weight: .regular))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundColor(Color.luxuryMuted.opacity(0.7))
                .opacity(hasSwipedOnce ? 0 : 1)
                .animation(.easeOut(duration: 0.4), value: hasSwipedOnce)
                .hintPulse()
                .padding(.bottom, 8)
                
                // Main content
                TabView(selection: $currentSlide) {
                    LuxurySlideWelcome(showContent: showContent)
                        .tag(0)
                    LuxurySlideChaos(showContent: showContent)
                        .tag(1)
                    LuxurySlideItinerary(showContent: showContent)
                        .tag(2)
                    LuxurySlideHomeFlow(showContent: showContent)
                        .tag(3)
                    LuxurySlideExtras(showContent: showContent)
                        .tag(4)
                    LuxurySlideGetStarted(showContent: showContent)
                        .tag(5)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: currentSlide)
                
                // Bottom actions
                VStack(spacing: 12) {
                    // Free vs paid disclosure on last slide
                    if currentSlide == totalSlides - 1 {
                        Text("About 2 minutes · skip anything you want")
                            .font(Font.bodySans(13, weight: .regular))
                            .foregroundColor(Color.luxuryCreamMuted)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 8)
                            .transition(.opacity)
                    }
                    
                    Button {
                        if currentSlide < totalSlides - 1 {
                            withAnimation {
                                currentSlide += 1
                                hasSwipedOnce = true
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
                    .pulseGlow()
                    
                    if currentSlide < totalSlides - 1 {
                        Button {
                            coordinator.completeOnboarding()
                        } label: {
                            Text("Skip intro")
                                .font(Font.bodySans(15, weight: .semibold))
                                .foregroundColor(Color.luxuryGold)
                                .frame(maxWidth: .infinity)
                                .frame(minHeight: 44)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color.luxuryGold.opacity(0.6), lineWidth: 1.5)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 44)
                .animation(.easeInOut(duration: 0.25), value: currentSlide)
            }
        }
        .onChange(of: currentSlide) { _, _ in
            hasSwipedOnce = true
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
                            .kenBurns(maxScale: 1.06, duration: 10)
                    case .empty, .failure:
                        Rectangle()
                            .fill(Color.luxuryMaroonLight)
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(height: UIScreen.main.bounds.height * 0.36)
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
                // Logo with glow effect
                ZStack {
                    Image("Logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 140, height: 140)
                        .blur(radius: glowPulse ? 15 : 10)
                        .opacity(0.3)
                    
                    Image("Logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 120, height: 120)
                }
                .opacity(showContent ? 1 : 0)
                .scaleEffect(showContent ? 1 : 0.5)
                .animation(.spring(response: 0.6).delay(0.2), value: showContent)
                
                // Title
                VStack(spacing: 8) {
                    HStack(spacing: 6) {
                        Text("Date nights,")
                            .font(Font.header(32, weight: .regular))
                            .foregroundColor(Color.luxuryCream)
                    }
                    
                    HStack(spacing: 6) {
                        Text("planned")
                            .font(Font.bodySerif(48, weight: .bold))
                            .italic()
                            .foregroundStyle(LinearGradient.goldShimmer)
                            .goldShimmer()
                        Text("for you.")
                            .font(Font.header(32, weight: .regular))
                            .foregroundColor(Color.luxuryCream)
                    }
                }
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)
                .animation(.easeOut(duration: 0.5).delay(0.4), value: showContent)
                
                // Description
                Text("Tell us what you love once. We build a complete evening — venues, timing, route & every detail handled.")
                    .font(Font.bodySans(15, weight: .regular))
                    .foregroundColor(Color.luxuryCreamMuted)
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
                    .padding(.horizontal, 20)
                    .opacity(showContent ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(0.5), value: showContent)

                // Reassurance pills
                HStack(spacing: 8) {
                    OnboardingPill(text: "Real venues")
                    OnboardingPill(text: "Full itinerary")
                    OnboardingPill(text: "Every detail handled")
                }
                .opacity(showContent ? 1 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.65), value: showContent)
            }
            .padding(.top, -20)
            
            Spacer()
        }
        .onAppear {
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
                SectionLabel(text: "Sound familiar?", color: Color.luxuryMuted)
                
                HStack(spacing: 6) {
                    Text("Friday night.")
                        .font(Font.header(26, weight: .regular))
                        .foregroundColor(Color.luxuryCream)
                    Text("No plan.")
                        .font(Font.bodySerif(40, weight: .bold))
                        .italic()
                        .foregroundColor(Color.luxuryGold)
                        .goldShimmer()
                }
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
                            .fill(Color.backgroundPrimary)
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
                    .font(Font.bodySans(15, weight: .regular))
                    .foregroundColor(Color.luxuryCreamMuted)
                
                HStack(spacing: 4) {
                    Text("After work,")
                        .font(Font.bodySans(15, weight: .regular))
                        .foregroundColor(Color.luxuryCreamMuted)
                    Text("who has time?")
                        .font(Font.bodySerif(28, weight: .bold))
                        .italic()
                        .foregroundColor(Color.luxuryGold)
                }
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
                SectionLabel(text: "Your night, planned", color: Color.luxuryMuted)
                
                HStack(spacing: 6) {
                    Text("Ready on")
                        .font(Font.header(26, weight: .regular))
                        .foregroundColor(Color.luxuryCream)
                    Text("Home")
                        .font(Font.bodySerif(40, weight: .bold))
                        .italic()
                        .foregroundColor(Color.luxuryGold)
                        .goldShimmer()
                }

                Text("Real venues · verified · timing & route included")
                    .font(Font.bodySans(12, weight: .regular))
                    .foregroundColor(Color.luxuryMuted)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 12)
            .opacity(showContent ? 1 : 0)
            .animation(.easeOut(duration: 0.4), value: showContent)
            
            // Itinerary card
            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 4) {
                            Text("Romantic")
                                .font(Font.bodySerif(28, weight: .bold))
                                .italic()
                                .foregroundColor(Color.luxuryGold)
                            Text("Italian Night")
                                .font(Font.header(18, weight: .regular))
                                .foregroundColor(Color.luxuryGold)
                        }
                        
                        Text("Sat · 3 stops · ~$150")
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
                        name: "Wine bar",
                        emoji: "🍷",
                        tip: "start with reds",
                        isActive: timelineProgress >= 0,
                        showContent: showContent,
                        delay: 0.3
                    )
                    
                    OnboardingItineraryStop(
                        time: "8:30 PM",
                        name: "Trattoria",
                        emoji: "🍝",
                        tip: "truffle pasta",
                        isActive: timelineProgress >= 0.5,
                        showContent: showContent,
                        delay: 0.5
                    )
                    
                    OnboardingItineraryStop(
                        time: "10:30 PM",
                        name: "Rooftop",
                        emoji: "🌃",
                        tip: "nightcap",
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
                        OnboardingFeatureBadge(text: "Reserve")
                        OnboardingFeatureBadge(text: "Route")
                        OnboardingFeatureBadge(text: "Share")
                        OnboardingFeatureBadge(text: "Playlist")
                    }
                    .padding(.horizontal, 18)
                }
                .padding(.bottom, 18)
                .opacity(showContent ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(0.9), value: showContent)
            }
            .luxuryCard()
            .cardShine(delay: 1.0)
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 30)
            .animation(.easeOut(duration: 0.5).delay(0.2), value: showContent)
            
            Spacer()
        }
        .onChange(of: showContent) { _, newValue in
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
                    .font(Font.header(15, weight: .bold))
                    .foregroundColor(Color.luxuryCream)
                
                Text(tip)
                    .font(Font.bodySerif(20, weight: .bold))
                    .italic()
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

/// Small reassurance pill used on the welcome slide (Real venues · Full itinerary · …).
struct OnboardingPill: View {
    let text: String

    var body: some View {
        Text(text)
            .font(Font.bodySans(10, weight: .medium))
            .foregroundColor(Color.luxuryGold)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.luxuryGold.opacity(0.1))
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(Color.luxuryGold.opacity(0.22), lineWidth: 1)
            )
    }
}

// MARK: - Slide 4: Home flow (interactive — tap to lock in)
/// Ports the prototype's interactive "How Home works" tutorial: a planned date card appears,
/// the user taps the gold "Lock it in" CTA, the card flips to a confirmed/green state and the
/// action chips (Reserve · Route · Text plan · Calendar) pop in with a staggered spring.
/// Auto-plays once on appear so non-tappers still see the payoff; tapping the button again replays.
struct LuxurySlideHomeFlow: View {
    let showContent: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var locked = false
    @State private var userInteracted = false

    private let actions: [(emoji: String, label: String)] = [
        ("🍽", "Reserve"),
        ("🗺", "Route"),
        ("💬", "Text plan"),
        ("📅", "Calendar")
    ]

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.top, 12)
                .opacity(showContent ? 1 : 0)
                .animation(.easeOut(duration: 0.4), value: showContent)

            // Planned-date card
            VStack(spacing: 0) {
                AsyncImage(url: URL(string: "https://images.unsplash.com/photo-1481931098730-318b6f776db0?w=600&h=320&fit=crop")) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .kenBurns(maxScale: 1.06, duration: 11)
                    case .empty, .failure:
                        Rectangle().fill(Color.luxuryMaroonLight)
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(height: 100)
                .clipped()

                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Tonight · for you & Maya")
                            .font(Font.bodySans(11, weight: .medium))
                            .foregroundColor(Color.luxuryMuted)
                        Text("Pasta · gallery · gelato")
                            .font(Font.header(16, weight: .bold))
                            .foregroundColor(Color.luxuryCream)
                        Text("romantic · ~$90 · 7–11 PM")
                            .font(Font.bodySans(11, weight: .regular))
                            .foregroundColor(Color.luxuryMuted.opacity(0.8))
                    }

                    lockButton

                    // Payoff zone — lives INSIDE the card so it can't be pushed below the
                    // clipped TabView page. Fixed height keeps the card from jumping between
                    // states. Idle: tap hint. Locked: the four action chips pop in (staggered).
                    ZStack {
                        Text("↑ Tap the gold button")
                            .font(Font.bodySans(11, weight: .medium))
                            .foregroundColor(Color.luxuryGold.opacity(0.85))
                            .opacity(locked ? 0 : 1)
                            .hintPulse()

                        actionChips
                            .opacity(locked ? 1 : 0)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 74)
                }
                .padding(16)
            }
            .luxuryCard()
            .cardShine(delay: 1.6)
            .padding(.horizontal, 24)
            .padding(.top, 18)
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 30)
            .animation(.easeOut(duration: 0.5).delay(0.2), value: showContent)

            Spacer()
        }
        .onAppear { scheduleAutoPlay() }
    }

    // MARK: Header (swaps copy on lock)
    @ViewBuilder private var header: some View {
        VStack(spacing: 6) {
            SectionLabel(text: "How Home works", color: Color.luxuryMuted)

            if locked {
                HStack(spacing: 6) {
                    Text("You're")
                        .font(Font.header(26, weight: .regular))
                        .foregroundColor(Color.luxuryCream)
                    Text("locked in")
                        .font(Font.bodySerif(40, weight: .bold))
                        .italic()
                        .foregroundColor(Color.luxuryGold)
                        .goldShimmer()
                }
                Text("Reserve · route · text · calendar")
                    .font(Font.bodySans(12, weight: .medium))
                    .foregroundColor(Color.luxuryGold.opacity(0.85))
                    .transition(.opacity)
            } else {
                HStack(spacing: 6) {
                    Text("Open the app.")
                        .font(Font.header(24, weight: .regular))
                        .foregroundColor(Color.luxuryCream)
                    Text("Tonight's ready")
                        .font(Font.bodySerif(36, weight: .bold))
                        .italic()
                        .foregroundColor(Color.luxuryGold)
                }
                Text("Tap Lock it in — reserve, route & share unlock after.")
                    .font(Font.bodySans(12, weight: .regular))
                    .foregroundColor(Color.luxuryMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
                    .transition(.opacity)
            }
        }
    }

    // MARK: Lock-in CTA (gold → green)
    @ViewBuilder private var lockButton: some View {
        let button = Button {
            userInteracted = true
            if locked {
                withAnimation(.easeInOut(duration: 0.3)) { locked = false }
            } else {
                lockIn()
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: locked ? "checkmark.circle.fill" : "sparkles")
                    .font(.system(size: 13, weight: .semibold))
                Text(locked ? "Locked in" : "Lock it in")
                    .font(Font.inter(14, weight: .semibold))
            }
            .foregroundColor(locked ? .white : Color.luxuryMaroon)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(
                Group {
                    if locked {
                        LinearGradient(
                            colors: [Color(hex: "3d8a5a"), Color(hex: "2d6a44")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    } else {
                        LinearGradient.goldShimmer
                    }
                }
            )
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)

        if locked {
            button
        } else {
            button.pulseGlow(cornerRadius: 22)
        }
    }

    // MARK: Action chips (staggered pop)
    private var actionChips: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                chip(index: 0)
                chip(index: 1)
            }
            HStack(spacing: 8) {
                chip(index: 2)
                chip(index: 3)
            }
        }
    }

    private func chip(index: Int) -> some View {
        let item = actions[index]
        return HStack(spacing: 5) {
            Text(item.emoji)
                .font(.system(size: 12))
            Text(item.label)
                .font(Font.bodySans(11, weight: .medium))
        }
        .foregroundColor(Color.luxuryGold)
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(Color.luxuryGold.opacity(0.1))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Color.luxuryGold.opacity(0.28), lineWidth: 1))
        .scaleEffect(locked ? 1 : 0.4)
        .opacity(locked ? 1 : 0)
        .animation(
            reduceMotion
                ? nil
                : .spring(response: 0.42, dampingFraction: 0.6).delay(locked ? Double(index) * 0.12 + 0.05 : 0),
            value: locked
        )
    }

    // MARK: Interaction
    private func lockIn() {
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.35)) {
            locked = true
        }
    }

    /// Auto-play the lock-in once shortly after the slide appears, unless the user already tapped.
    /// With Reduce Motion on, jump straight to the locked payoff with no animation.
    private func scheduleAutoPlay() {
        guard !locked, !userInteracted else { return }
        if reduceMotion {
            locked = true
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.7) {
            if !userInteracted && !locked {
                lockIn()
            }
        }
    }
}

// MARK: - Slide 5: Plus on every date (the three extras)
struct LuxurySlideExtras: View {
    let showContent: Bool

    private struct Extra: Identifiable {
        let id = UUID()
        let emoji: String
        let title: String
        let blurb: String
        let location: String
    }

    private let extras: [Extra] = [
        Extra(emoji: "✨", title: "Convo starters", blurb: "Swipe questions matched to your relationship", location: "Convo tab"),
        Extra(emoji: "💌", title: "Love notes", blurb: "AI-drafted sweet notes you send before the date", location: "On your itinerary"),
        Extra(emoji: "🎁", title: "Gift finder", blurb: "Gift ideas from their profile & budget", location: "Add from any stop")
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 6) {
                SectionLabel(text: "Plus on every date", color: Color.luxuryMuted)

                HStack(spacing: 6) {
                    Text("Three extras on")
                        .font(Font.header(24, weight: .regular))
                        .foregroundColor(Color.luxuryCream)
                    Text("every plan")
                        .font(Font.bodySerif(38, weight: .bold))
                        .italic()
                        .foregroundColor(Color.luxuryGold)
                        .goldShimmer()
                }

                Text("Not separate apps — talk, text & gifts are part of the date Genie builds.")
                    .font(Font.bodySans(13, weight: .regular))
                    .foregroundColor(Color.luxuryCreamMuted)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, 28)
                    .padding(.top, 2)
            }
            .padding(.top, 12)
            .opacity(showContent ? 1 : 0)
            .animation(.easeOut(duration: 0.4), value: showContent)

            // Included card
            VStack(spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("What's included")
                            .font(Font.header(16, weight: .bold))
                            .foregroundColor(Color.luxuryCream)
                        Text("3 extras · built into every date plan")
                            .font(Font.bodySans(12, weight: .regular))
                            .foregroundColor(Color.luxuryMuted)
                    }
                    Spacer()
                    Image(systemName: "sparkles")
                        .foregroundStyle(LinearGradient.goldShimmer)
                }
                .padding(18)
                .background(Color.luxuryMaroonLight.opacity(0.8))

                VStack(spacing: 14) {
                    ForEach(Array(extras.enumerated()), id: \.element.id) { index, extra in
                        HStack(alignment: .top, spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.luxuryGold.opacity(0.14))
                                    .frame(width: 40, height: 40)
                                Text(extra.emoji)
                                    .font(.system(size: 18))
                            }
                            .iconWiggle()

                            VStack(alignment: .leading, spacing: 3) {
                                Text(extra.title)
                                    .font(Font.header(15, weight: .bold))
                                    .foregroundColor(Color.luxuryCream)
                                Text(extra.blurb)
                                    .font(Font.bodySans(12.5, weight: .regular))
                                    .foregroundColor(Color.luxuryCreamMuted)
                                    .fixedSize(horizontal: false, vertical: true)
                                Text(extra.location)
                                    .font(Font.bodySans(11, weight: .medium))
                                    .foregroundColor(Color.luxuryGold)
                            }
                            Spacer(minLength: 0)
                        }
                        .opacity(showContent ? 1 : 0)
                        .offset(x: showContent ? 0 : -20)
                        .animation(.easeOut(duration: 0.4).delay(Double(index) * 0.12 + 0.3), value: showContent)
                    }
                }
                .padding(18)
            }
            .luxuryCard()
            .cardShine(delay: 1.2)
            .padding(.horizontal, 24)
            .padding(.top, 18)
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 30)
            .animation(.easeOut(duration: 0.5).delay(0.2), value: showContent)

            Text("Premium · unlimited plans & all extras")
                .font(Font.bodySans(12, weight: .medium))
                .foregroundColor(Color.luxuryMuted)
                .padding(.top, 14)
                .opacity(showContent ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(0.7), value: showContent)

            Spacer()
        }
    }
}

// MARK: - Slide 6: Get Started
struct LuxurySlideGetStarted: View {
    let showContent: Bool
    @State private var benefitChecks = [false, false, false]
    @State private var counterValue = 0
    @State private var counterTimer: Timer?
    
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
                            .kenBurns(maxScale: 1.07, duration: 12)
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
                        .font(Font.bodySerif(32, weight: .bold))
                        .italic()
                        .foregroundColor(Color.luxuryGold)
                    Text("evenings")
                        .font(Font.header(14, weight: .regular))
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
                HStack(spacing: 6) {
                    Text("Ready for")
                        .font(Font.header(26, weight: .regular))
                        .foregroundColor(Color.luxuryCream)
                    Text("better dates?")
                        .font(Font.bodySerif(42, weight: .bold))
                        .italic()
                        .foregroundColor(Color.luxuryGold)
                        .goldShimmer()
                }
                
                Text("Quick Genie Profile — then your first plan waits on Home.")
                    .font(Font.bodySans(15, weight: .regular))
                    .foregroundColor(Color.luxuryCreamMuted)
                    .padding(.horizontal, 28)
            }
            .multilineTextAlignment(.center)
            .padding(.top, 24)
            .opacity(showContent ? 1 : 0)
            .animation(.easeOut(duration: 0.4).delay(0.2), value: showContent)
            
            // Benefits
            VStack(spacing: 14) {
                OnboardingBenefitRow(text: "Free plan included — no card to start", isChecked: benefitChecks[0])
                OnboardingBenefitRow(text: "Real venues, verified · tailored to you two", isChecked: benefitChecks[1])
                OnboardingBenefitRow(text: "About 2 minutes · skip anything you want", isChecked: benefitChecks[2])
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
        .onChange(of: showContent) { _, newValue in
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
                counterTimer?.invalidate()
                counterTimer = Timer.scheduledTimer(withTimeInterval: 0.015, repeats: true) { [self] timer in
                    if counterValue < 500 {
                        counterValue += 8
                    } else {
                        timer.invalidate()
                        counterTimer = nil
                    }
                }
            }
        }
        .onDisappear {
            counterTimer?.invalidate()
            counterTimer = nil
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
                .font(Font.bodySans(15, weight: .regular))
                .foregroundColor(isChecked ? Color.luxuryCream : Color.luxuryMuted)
            
            Spacer()
        }
        .animation(.spring(response: 0.3), value: isChecked)
    }
}

// MARK: - Ambient animation modifiers (ported from YDG_interactive_prototype.html)
//
// These mirror the looping CSS micro-animations in the web prototype:
//   • kenBurns      → obKenBurns (slow hero zoom)
//   • goldShimmer   → tutGoldShimmer (light sweep across gold text)
//   • cardShine     → tutCardShine / obCardShine (diagonal sheen over cards)
//   • iconWiggle    → tutIconWiggle (periodic emoji wiggle)
//   • pulseGlow     → tutLockPulse (expanding ring on the primary CTA)
//   • hintPulse     → tutHintPulse (breathing opacity on the swipe hint)
// Every loop honors Reduce Motion (the prototype's @media prefers-reduced-motion).

/// Slow, continuous zoom on hero imagery. Apply to the resizable image *before* `.frame().clipped()`
/// so the zoom is clipped to the frame.
private struct KenBurnsModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var zoomed = false
    var maxScale: CGFloat = 1.06
    var duration: Double = 9

    func body(content: Content) -> some View {
        content
            .scaleEffect(reduceMotion ? 1.0 : (zoomed ? maxScale : 1.0))
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true)) {
                    zoomed = true
                }
            }
    }
}

/// Bright light sweep that travels left→right across the masked content (use on gold headline text).
private struct GoldShimmerModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase: CGFloat = -1
    var duration: Double = 2.6

    func body(content: Content) -> some View {
        content
            .overlay {
                if !reduceMotion {
                    GeometryReader { geo in
                        let w = geo.size.width
                        LinearGradient(
                            colors: [.clear, Color.white.opacity(0.9), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: w * 0.55)
                        .offset(x: phase * (w + w * 0.55))
                        .blendMode(.screen)
                    }
                    .mask { content }
                    .allowsHitTesting(false)
                }
            }
            .onAppear {
                guard !reduceMotion else { return }
                phase = -1
                withAnimation(.linear(duration: duration).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

/// Diagonal gold sheen that sweeps across a card. Clips to the card's corner radius (20).
private struct CardShineModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var move = false
    var delay: Double = 0.9
    var cornerRadius: CGFloat = 20

    func body(content: Content) -> some View {
        content
            .overlay {
                if !reduceMotion {
                    GeometryReader { geo in
                        let w = geo.size.width
                        LinearGradient(
                            colors: [.clear, Color.luxuryGold.opacity(0.16), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(width: w * 0.35)
                        .rotationEffect(.degrees(20))
                        .offset(x: move ? w * 1.2 : -w * 1.2)
                    }
                    .allowsHitTesting(false)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.easeInOut(duration: 3.8).repeatForever(autoreverses: false).delay(delay)) {
                    move = true
                }
            }
    }
}

/// Periodic playful wiggle for emoji icons — long calm hold, then a quick two-beat wiggle.
private struct IconWiggleModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        if reduceMotion {
            content
        } else {
            content.phaseAnimator([0, 1, 2, 3]) { view, phase in
                view
                    .rotationEffect(.degrees(phase == 1 ? -8 : (phase == 2 ? 6 : 0)))
                    .scaleEffect(phase == 1 ? 1.12 : (phase == 2 ? 1.06 : 1.0))
            } animation: { phase in
                phase == 0 ? .easeInOut(duration: 2.6) : .easeInOut(duration: 0.16)
            }
        }
    }
}

/// Expanding, fading ring behind the primary CTA to draw the eye (matches tutLockPulse).
private struct PulseGlowModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pulse = false
    var cornerRadius: CGFloat = 14

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.luxuryGold.opacity(pulse ? 0 : 0.55), lineWidth: 3)
                    .scaleEffect(pulse ? 1.08 : 1.0)
                    .opacity(reduceMotion ? 0 : 1)
            )
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.easeOut(duration: 2.2).repeatForever(autoreverses: false)) {
                    pulse = true
                }
            }
    }
}

/// Gentle breathing opacity for the swipe hint (matches tutHintPulse).
private struct HintPulseModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var dim = false

    func body(content: Content) -> some View {
        content
            .opacity(reduceMotion ? 1 : (dim ? 0.55 : 1))
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    dim = true
                }
            }
    }
}

extension View {
    func kenBurns(maxScale: CGFloat = 1.06, duration: Double = 9) -> some View {
        modifier(KenBurnsModifier(maxScale: maxScale, duration: duration))
    }
    func goldShimmer(duration: Double = 2.6) -> some View {
        modifier(GoldShimmerModifier(duration: duration))
    }
    func cardShine(delay: Double = 0.9, cornerRadius: CGFloat = 20) -> some View {
        modifier(CardShineModifier(delay: delay, cornerRadius: cornerRadius))
    }
    func iconWiggle() -> some View {
        modifier(IconWiggleModifier())
    }
    func pulseGlow(cornerRadius: CGFloat = 14) -> some View {
        modifier(PulseGlowModifier(cornerRadius: cornerRadius))
    }
    func hintPulse() -> some View {
        modifier(HintPulseModifier())
    }
}

// MARK: - Preview
#Preview {
    MobileOnboardingView()
        .environmentObject(NavigationCoordinator.shared)
}
