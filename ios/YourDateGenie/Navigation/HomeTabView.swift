import SwiftUI

// Wrapper so we can use sheet(item:) with DatePlan.
private struct IdentifiablePlan: Identifiable {
    let plan: DatePlan
    var id: UUID { plan.id }
}

// MARK: - Luxury Home Tab View
struct LuxuryHomeTabView: View {
    @EnvironmentObject var coordinator: NavigationCoordinator
    @StateObject private var notificationManager = NotificationManager.shared
    @State private var pulseAnimation = false
    @State private var planForCalendar: DatePlan?
    @State private var calendarDate = Date()
    @State private var calendarMessage: String?
    @State private var showCalendarAlert = false
    
    var body: some View {
        NavigationStack(path: $coordinator.navigationPath) {
            ZStack {
                Color.luxuryMaroon
                    .ignoresSafeArea()
                
                FloatingParticlesView()
                    .ignoresSafeArea()
                    .opacity(0.6)
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 28) {
                        headerSection
                        magicalCTASection
                        upcomingExperiencesSection
                        upcomingMagicSection
                        quickActionsSection
                        featuresSection
                    }
                    .padding(.bottom, 120)
                }
                .scrollBounceBehavior(.basedOnSize)
            }
            .onAppear {
                coordinator.refreshPreferencesState()
            }
            .sheet(item: Binding(
                get: { planForCalendar.map { IdentifiablePlan(plan: $0) } },
                set: { planForCalendar = $0?.plan }
            )) { wrapper in
                addToCalendarSheet(plan: wrapper.plan)
            }
            .alert("Calendar", isPresented: $showCalendarAlert) {
                Button("OK") { calendarMessage = nil }
            } message: {
                if let msg = calendarMessage { Text(msg) }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack(spacing: 6) {
                        Image("Logo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 36, height: 36)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    NotificationBellButton(notificationManager: notificationManager)
                }
            }
            .toolbarBackground(Color.luxuryMaroon, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .sheet(isPresented: $notificationManager.showNotificationsSheet) {
                NotificationsSheetView(notificationManager: notificationManager)
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text(greeting)
                .font(Font.bodySans(14, weight: .regular))
                .foregroundColor(Color.luxuryMuted)
            
            if magicalGreeting == "Time for something magical" {
                HStack(spacing: 6) {
                    Text("Time for something")
                        .font(Font.header(26, weight: .regular))
                        .foregroundColor(Color.luxuryCream)
                    Text("magical")
                        .font(Font.tangerine(46, weight: .bold))
                        .italic()
                        .foregroundColor(Color.luxuryGold)
                }
                .frame(maxWidth: .infinity)
            } else {
                Text(magicalGreeting)
                    .font(Font.header(26, weight: .regular))
                    .foregroundColor(Color.luxuryCream)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
    
    private var magicalCTASection: some View {
        let showUseLast = LastQuestionnaireStore.hasLastData || coordinator.hasCompletedPreferences
        let showResume = QuestionnaireProgressStore.hasValidProgress
        
        return ZStack {
                AsyncImage(url: URL(string: "https://images.unsplash.com/photo-1517457373958-b7bdd4587205?w=600&h=300&fit=crop")) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .empty, .failure:
                        Color.luxuryMaroonLight
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(height: 180)
                .clipped()
                
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.luxuryMaroon.opacity(0.3),
                        Color.luxuryMaroon.opacity(0.85)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                VStack(spacing: 16) {
                    Spacer()
                    
                    HStack(spacing: 8) {
                        ForEach(0..<3, id: \.self) { i in
                            Image(systemName: "sparkle")
                                .font(.system(size: 14))
                                .foregroundColor(Color.luxuryGold)
                                .opacity(pulseAnimation ? 1 : 0.5)
                                .scaleEffect(pulseAnimation ? 1.2 : 0.8)
                                .animation(
                                    .easeInOut(duration: 1)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(i) * 0.3),
                                    value: pulseAnimation
                                )
                        }
                    }
                    
                    HStack(spacing: 6) {
                        Text("Create Your Next")
                            .font(Font.header(22, weight: .regular))
                            .foregroundColor(Color.luxuryCream)
                        Text("Adventure")
                            .font(Font.tangerine(36, weight: .bold))
                            .italic()
                            .foregroundColor(Color.luxuryGold)
                    }
                    
                    HStack(spacing: 4) {
                        Text("Let your")
                            .font(Font.bodySans(14, weight: .regular))
                            .foregroundColor(Color.luxuryCreamMuted)
                        Text("Genie")
                            .font(Font.tangerine(26, weight: .bold))
                            .italic()
                            .foregroundColor(Color.luxuryGold)
                        Text("craft an unforgettable experience")
                            .font(Font.bodySans(14, weight: .regular))
                            .foregroundColor(Color.luxuryCreamMuted)
                    }
                    
                    VStack(spacing: 10) {
                        Button {
                            coordinator.startDatePlanning(mode: .fresh)
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "wand.and.stars")
                                    .font(.system(size: 16))
                                Text("Start Fresh")
                                    .font(Font.bodySans(15, weight: .semibold))
                            }
                            .foregroundColor(Color.luxuryMaroon)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(LinearGradient.goldShimmer)
                            .cornerRadius(25)
                            .shadow(color: Color.luxuryGold.opacity(0.4), radius: 12, y: 4)
                        }
                        .buttonStyle(.plain)
                        
                        if showUseLast {
                            Button {
                                coordinator.startDatePlanning(mode: .useLast)
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "arrow.clockwise.circle.fill")
                                        .font(.system(size: 16))
                                    Text("Use & Generate from Last Plan")
                                        .font(Font.bodySans(14, weight: .semibold))
                                }
                                .foregroundColor(Color.luxuryGold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.luxuryGold.opacity(0.2))
                                .cornerRadius(20)
                            }
                            .buttonStyle(.plain)
                        }
                        
                        if showResume {
                            Button {
                                coordinator.startDatePlanning(mode: .resume)
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "bookmark.fill")
                                        .font(.system(size: 14))
                                    Text("Pick Up Where You Left Off")
                                        .font(Font.bodySans(14, weight: .semibold))
                                }
                                .foregroundColor(Color.luxuryCream)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.luxuryCream.opacity(0.15))
                                .cornerRadius(20)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
                .padding(.horizontal, 20)
            }
            .frame(height: showResume || showUseLast ? 320 : 280)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(
                        LinearGradient(
                            colors: [Color.luxuryGold.opacity(0.6), Color.luxuryGold.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
            .shadow(color: Color.luxuryGold.opacity(0.2), radius: 20, y: 10)
        .padding(.horizontal, 20)
        .onAppear {
            pulseAnimation = true
        }
    }
    
    // MARK: - Experiences Waiting (unsaved generated plans — tap to open options & save)
    private var upcomingExperiencesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 6) {
                Image(systemName: "calendar.badge.clock")
                    .foregroundColor(Color.luxuryGold)
                Text("Experiences")
                    .font(Font.header(17, weight: .regular))
                    .foregroundColor(Color.luxuryCream)
                Text("Waiting")
                    .font(Font.tangerine(28, weight: .bold))
                    .italic()
                    .foregroundColor(Color.luxuryGold)
            }
            .padding(.horizontal, 20)
            
            Text("Unsaved plans — tap to choose one and save it to Upcoming Magic.")
                .font(Font.bodySans(13, weight: .regular))
                .foregroundColor(Color.luxuryCreamMuted)
                .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    if !coordinator.generatedPlans.isEmpty {
                        ForEach(Array(coordinator.generatedPlans.enumerated()), id: \.element.id) { index, plan in
                            Button {
                                coordinator.generatedPlansSelectedIndex = index
                                coordinator.currentDatePlan = plan
                                coordinator.activeSheet = .datePlanOptions
                            } label: {
                                ExperienceCard(
                                    title: plan.title,
                                    subtitle: plan.tagline,
                                    emoji: plan.stops.first?.emoji ?? "✨",
                                    imageUrl: "https://images.unsplash.com/photo-1517457373958-b7bdd4587205?w=200&h=200&fit=crop"
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    } else {
                        ExperienceCard(
                            title: "Rooftop Sunset",
                            subtitle: "This Weekend",
                            emoji: "🌅",
                            imageUrl: "https://images.unsplash.com/photo-1514933651103-005eec06c04b?w=200&h=200&fit=crop"
                        )
                        ExperienceCard(
                            title: "Jazz & Wine",
                            subtitle: "Perfect for evenings",
                            emoji: "🎷",
                            imageUrl: "https://images.unsplash.com/photo-1415201364774-f6f0bb35f28f?w=200&h=200&fit=crop"
                        )
                        ExperienceCard(
                            title: "Starlit Picnic",
                            subtitle: "Under the stars",
                            emoji: "✨",
                            imageUrl: "https://images.unsplash.com/photo-1528495612343-9ca9f4a4de28?w=200&h=200&fit=crop"
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }
    
    private var magicalGreeting: String {
        let greetings = [
            "What magic shall we create?",
            "Ready for something wonderful?",
            "Let's make tonight special",
            "Adventure awaits you",
            "Time for something magical"
        ]
        return greetings.randomElement() ?? "What magic shall we create?"
    }
    
    // MARK: - Add to Calendar Sheet (from Upcoming Magic cards)
    private func addToCalendarSheet(plan: DatePlan) -> some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Choose the date for your plan")
                    .font(Font.bodySans(15, weight: .medium))
                    .foregroundColor(Color.luxuryCreamMuted)
                
                DatePicker("Date", selection: $calendarDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .tint(Color.luxuryGold)
                    .padding(.horizontal)
                
                Button {
                    Task {
                        let result = await CalendarService.addDatePlan(plan, on: calendarDate)
                        await MainActor.run {
                            switch result {
                            case .success:
                                coordinator.updateScheduledDate(for: plan.id, date: calendarDate)
                                calendarMessage = "Added to your calendar."
                                showCalendarAlert = true
                                planForCalendar = nil
                            case .denied:
                                calendarMessage = "Calendar access was denied. Enable it in Settings to add date plans."
                                showCalendarAlert = true
                            case .failed(let msg):
                                calendarMessage = "Could not add: \(msg)"
                                showCalendarAlert = true
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "calendar.badge.plus")
                            .font(.system(size: 16))
                        Text("Add to Calendar")
                            .font(Font.bodySans(16, weight: .semibold))
                    }
                    .foregroundColor(Color.luxuryMaroon)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(LinearGradient.goldShimmer)
                    .cornerRadius(16)
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .padding(.top, 24)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.luxuryMaroon)
            .navigationTitle("Add to Calendar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        planForCalendar = nil
                    }
                    .foregroundColor(Color.luxuryGold)
                }
            }
            .toolbarBackground(Color.luxuryMaroon, for: .navigationBar)
        }
    }
    
    // MARK: - Upcoming Magic (saved & booked date plans — persisted)
    private var upcomingMagicSection: some View {
        Group {
            if !coordinator.savedPlans.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(Color.luxuryGold.opacity(0.2))
                                .frame(width: 36, height: 36)
                            Image(systemName: "sparkles")
                                .font(.system(size: 18))
                                .foregroundStyle(LinearGradient.goldShimmer)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Upcoming")
                                .font(Font.header(17, weight: .regular))
                                .foregroundColor(Color.luxuryCream)
                            Text("Magic")
                                .font(Font.tangerine(28, weight: .bold))
                                .italic()
                                .foregroundColor(Color.luxuryGold)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Text("Saved & booked date plans — tap to view details.")
                        .font(Font.bodySans(13, weight: .regular))
                        .foregroundColor(Color.luxuryCreamMuted)
                        .padding(.horizontal, 20)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 14) {
                            ForEach(coordinator.savedPlans) { plan in
                                BookedDateCard(plan: plan, onTap: {
                                    coordinator.currentDatePlan = plan
                                    coordinator.activeSheet = .datePlanResult
                                }, onAddToCalendar: {
                                    planForCalendar = plan
                                    calendarDate = plan.scheduledDate ?? Date()
                                })
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(Color.luxuryGold.opacity(0.15))
                                .frame(width: 36, height: 36)
                            Image(systemName: "sparkles")
                                .font(.system(size: 18))
                                .foregroundColor(Color.luxuryGold.opacity(0.8))
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Upcoming")
                                .font(Font.header(17, weight: .regular))
                                .foregroundColor(Color.luxuryCream)
                            Text("Magic")
                                .font(Font.tangerine(28, weight: .bold))
                                .italic()
                                .foregroundColor(Color.luxuryGold)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Text("Save a plan from Experiences Waiting and it will appear here.")
                        .font(Font.bodySans(13, weight: .regular))
                        .foregroundColor(Color.luxuryCreamMuted)
                        .padding(.horizontal, 20)
                }
            }
        }
    }
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 6) {
                Text("Quick")
                    .font(Font.header(17, weight: .regular))
                    .foregroundColor(Color.luxuryCream)
                Text("Magic")
                    .font(Font.tangerine(28, weight: .bold))
                    .italic()
                    .foregroundColor(Color.luxuryGold)
            }
            .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    LuxuryQuickTile(icon: "gift.fill", title: "Gift Finder", color: Color.luxuryGold) {
                        coordinator.showGiftFinder(
                            datePlan: coordinator.currentDatePlan,
                            dateLocation: coordinator.currentDatePlan?.stops.first?.address
                        )
                    }
                    
                    LuxuryQuickTile(icon: "music.note.list", title: "Date Playlist", color: Color.luxuryGoldLight) {
                        coordinator.showPlaylist(for: coordinator.currentDatePlan?.title ?? "Date Night")
                    }
                    
                    LuxuryQuickTile(icon: "bubble.left.and.bubble.right.fill", title: "Conversation Starters", color: Color.luxuryGold) {
                        coordinator.showConversationStarters()
                    }
                    
                    LuxuryQuickTile(icon: "clock.fill", title: "Past Magic", color: Color.luxuryGoldLight) {
                        coordinator.showPastMagic()
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 6) {
                Text("Magical")
                    .font(Font.tangerine(28, weight: .bold))
                    .italic()
                    .foregroundColor(Color.luxuryGold)
                Text("Tools")
                    .font(Font.header(17, weight: .regular))
                    .foregroundColor(Color.luxuryCream)
            }
            .padding(.horizontal, 20)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                LuxuryFeatureTile(icon: "wand.and.stars", title: "AI Genie", subtitle: "Personalized magic")
                LuxuryFeatureTile(icon: "map.fill", title: "Journey Map", subtitle: "Navigate your night")
                LuxuryFeatureTile(icon: "music.note", title: "Mood Music", subtitle: "Set the vibe")
                LuxuryFeatureTile(icon: "heart.circle.fill", title: "Share Joy", subtitle: "Send to your love")
            }
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Floating Particles View
struct FloatingParticlesView: View {
    @State private var particles: [Particle] = []
    
    struct Particle: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var size: CGFloat
        var opacity: Double
        var speed: Double
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    Image(systemName: "sparkle")
                        .font(.system(size: particle.size))
                        .foregroundColor(Color.luxuryGold)
                        .opacity(particle.opacity)
                        .position(x: particle.x, y: particle.y)
                }
            }
            .onAppear {
                createParticles(in: geometry.size)
                animateParticles(in: geometry.size)
            }
        }
    }
    
    private func createParticles(in size: CGSize) {
        particles = (0..<15).map { _ in
            Particle(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: 0...size.height),
                size: CGFloat.random(in: 6...14),
                opacity: Double.random(in: 0.1...0.4),
                speed: Double.random(in: 20...60)
            )
        }
    }
    
    private func animateParticles(in size: CGSize) {
        Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 3)) {
                for i in particles.indices {
                    particles[i].y -= CGFloat(particles[i].speed)
                    particles[i].opacity = Double.random(in: 0.1...0.4)
                    
                    if particles[i].y < -20 {
                        particles[i].y = size.height + 20
                        particles[i].x = CGFloat.random(in: 0...size.width)
                    }
                }
            }
        }
    }
}

// MARK: - Experience Card
struct ExperienceCard: View {
    let title: String
    let subtitle: String
    let emoji: String
    let imageUrl: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                AsyncImage(url: URL(string: imageUrl)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .empty, .failure:
                        Color.luxuryMaroonLight
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(width: 140, height: 100)
                .clipped()
                
                LinearGradient(
                    colors: [.clear, Color.luxuryMaroon.opacity(0.8)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                Text(emoji)
                    .font(.system(size: 28))
                    .padding(10)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(Font.header(14, weight: .bold))
                    .foregroundColor(Color.luxuryCream)
                    .lineLimit(1)
                
                Text(subtitle)
                    .font(Font.bodySans(11, weight: .regular))
                    .foregroundColor(Color.luxuryMuted)
                    .lineLimit(1)
            }
            .padding(12)
        }
        .frame(width: 140)
        .background(Color.luxuryMaroonLight)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.luxuryGold.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Booked Date Card (Upcoming Magic — saved plans)
struct BookedDateCard: View {
    let plan: DatePlan
    let onTap: () -> Void
    var onAddToCalendar: (() -> Void)?
    
    private var dateTimeText: String {
        let timeSlot = plan.stops.first?.timeSlot ?? "—"
        if let d = plan.scheduledDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return "\(formatter.string(from: d)) at \(timeSlot)"
        }
        return "\(timeSlot) · No date set"
    }
    
    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .topTrailing) {
                VStack(alignment: .leading, spacing: 0) {
                    Spacer(minLength: 0)
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 4) {
                            ForEach(plan.stops.prefix(3)) { stop in
                                Text(stop.emoji)
                                    .font(.system(size: 16))
                            }
                        }
                        Text(plan.title)
                            .font(Font.header(14, weight: .bold))
                            .foregroundColor(Color.luxuryCream)
                            .lineLimit(2)
                        Text(dateTimeText)
                            .font(Font.bodySans(11, weight: .medium))
                            .foregroundColor(Color.luxuryGold.opacity(0.95))
                            .lineLimit(2)
                        Text("\(plan.stops.count) stops · \(plan.totalDuration)")
                            .font(Font.bodySans(11, weight: .regular))
                            .foregroundColor(Color.luxuryCream.opacity(0.9))
                        if onAddToCalendar != nil {
                            Button {
                                onAddToCalendar?()
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "calendar.badge.plus")
                                        .font(.system(size: 11))
                                    Text("Save to Calendar")
                                        .font(Font.bodySans(11, weight: .semibold))
                                }
                                .foregroundColor(Color.luxuryMaroon)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.luxuryGold.opacity(0.9))
                                .cornerRadius(12)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(14)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .background(
                    ZStack {
                        Color.luxuryMaroonLight
                        LinearGradient(
                            colors: [
                                Color.luxuryGold.opacity(0.08),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    }
                )
                .cornerRadius(18)
                
                Text("Booked")
                    .font(Font.bodySans(10, weight: .semibold))
                    .foregroundColor(Color.luxuryMaroon)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.luxuryGold.opacity(0.95))
                    )
                    .padding(10)
            }
            .frame(width: 160, height: onAddToCalendar != nil ? 170 : 140)
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(
                        LinearGradient(
                            colors: [Color.luxuryGold.opacity(0.5), Color.luxuryGold.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.2
                    )
            )
            .shadow(color: Color.luxuryGold.opacity(0.15), radius: 12, y: 4)
        }
        .buttonStyle(.plain)
    }
}
