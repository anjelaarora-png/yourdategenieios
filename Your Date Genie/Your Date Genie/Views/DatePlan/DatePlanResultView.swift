import SwiftUI

struct DatePlanResultView: View {
    let plan: DatePlan
    var onSave: (() -> Void)?
    var onRegenerate: (() -> Void)?
    var isViewingMode: Bool = false
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var coordinator: NavigationCoordinator
    @State private var showPlaylist = false
    @State private var showMap = false
    @State private var showPartnerShare = false
    @State private var showGiftFinder = false
    @State private var selectedVenue: DatePlanStop?
    @State private var isSaved = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color.luxuryMaroon
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Main scrollable content
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 0) {
                            mainPlanCard
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 100)
                    }
                    .scrollBounceBehavior(.basedOnSize)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color.luxuryGold)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        Button {
                            showPartnerShare = true
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 15))
                                .foregroundColor(Color.luxuryGold)
                        }
                        
                        if isSaved {
                            Image(systemName: "checkmark")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(Color.luxuryGold)
                        }
                    }
                }
            }
            .toolbarBackground(Color.luxuryMaroon, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .safeAreaInset(edge: .bottom) {
                bottomActionBar
            }
        }
        .sheet(isPresented: $showPlaylist) {
            PlaylistWidgetView(planTitle: plan.title)
        }
        .sheet(isPresented: $showMap) {
            NavigationStack {
                RouteMapView(stops: plan.stops)
                    .navigationTitle("Route")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") { showMap = false }
                                .foregroundColor(Color.luxuryGold)
                        }
                    }
            }
        }
        .sheet(isPresented: $showPartnerShare) {
            PartnerShareView(plan: plan)
        }
        .sheet(isPresented: $showGiftFinder) {
            GiftFinderView(datePlan: plan, dateLocation: plan.stops.first?.address)
        }
        .sheet(item: $selectedVenue) { venue in
            ReservationWidgetView(
                venueName: venue.name,
                venueType: venue.venueType,
                address: venue.address,
                phoneNumber: venue.phoneNumber
            )
        }
    }
    
    // MARK: - Main Plan Card
    private var mainPlanCard: some View {
        VStack(spacing: 0) {
            // Header
            cardHeader
            
            Divider()
                .background(Color.luxuryGold.opacity(0.2))
                .padding(.horizontal, 20)
            
            // Title & Tagline
            titleSection
            
            // Timeline Stops
            stopsTimeline
            
            Divider()
                .background(Color.luxuryGold.opacity(0.2))
                .padding(.horizontal, 20)
            
            // Stats Row
            statsRow
            
            // Weather Note
            weatherNote
            
            // Conversation Starter
            if let starters = plan.conversationStarters, let first = starters.first {
                conversationCard(starter: first)
            }
            
            // Packing List
            packingChips
            
            // Page dots placeholder (for multiple plans)
            pageDots
        }
        .background(Color.luxuryMaroonLight.opacity(0.6))
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.luxuryGold.opacity(0.25), lineWidth: 1)
        )
    }
    
    // MARK: - Card Header
    private var cardHeader: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 14))
                    .foregroundColor(Color.luxuryGold)
                
                Text("Your Date Plan")
                    .font(Font.inter(14, weight: .semibold))
                    .foregroundColor(Color.luxuryGold)
            }
            
            Spacer()
            
            if isSaved {
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color.luxuryGold)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    // MARK: - Title Section
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(plan.title)
                .font(Font.cormorant(28, weight: .semibold))
                .foregroundColor(Color.luxuryCream)
            
            Text(plan.tagline)
                .font(Font.playfair(15, weight: .regular))
                .foregroundColor(Color.luxuryGold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    // MARK: - Stops Timeline
    private var stopsTimeline: some View {
        VStack(spacing: 0) {
            ForEach(plan.stops) { stop in
                CompactStopRow(
                    stop: stop,
                    isLast: stop.id == plan.stops.last?.id,
                    onTap: {
                        if isReservable(stop) {
                            selectedVenue = stop
                        }
                    }
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }
    
    // MARK: - Stats Row
    private var statsRow: some View {
        HStack(spacing: 0) {
            // Duration
            HStack(spacing: 6) {
                Image(systemName: "clock")
                    .font(.system(size: 13))
                    .foregroundColor(Color.luxuryGold)
                Text(plan.totalDuration)
                    .font(Font.inter(13, weight: .medium))
                    .foregroundColor(Color.luxuryCream)
            }
            
            Text("·")
                .foregroundColor(Color.luxuryMuted)
                .padding(.horizontal, 12)
            
            // Cost
            Text(plan.estimatedCost)
                .font(Font.inter(13, weight: .medium))
                .foregroundColor(Color.luxuryCream)
            
            Spacer()
            
            // Accessibility badge (if applicable)
            HStack(spacing: 4) {
                Image(systemName: "figure.roll")
                    .font(.system(size: 11))
                Text("Accessible")
                    .font(Font.inter(11, weight: .medium))
            }
            .foregroundColor(Color.luxuryGold)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }
    
    // MARK: - Weather Note
    private var weatherNote: some View {
        Group {
            if !plan.weatherNote.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "sun.max.fill")
                        .font(.system(size: 14))
                        .foregroundColor(Color.luxuryGoldLight)
                    
                    Text(plan.weatherNote)
                        .font(Font.inter(13, weight: .regular))
                        .foregroundColor(Color.luxuryCreamMuted)
                        .lineLimit(2)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.luxuryMaroon.opacity(0.5))
                .cornerRadius(12)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
            }
        }
    }
    
    // MARK: - Conversation Card
    private func conversationCard(starter: ConversationStarter) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "bubble.left.fill")
                    .font(.system(size: 12))
                Text("Conversation Starter")
                    .font(Font.inter(12, weight: .semibold))
            }
            .foregroundColor(Color.luxuryGold)
            
            Text("\"\(starter.question)\"")
                .font(Font.playfairItalic(14))
                .foregroundColor(Color.luxuryCreamMuted)
                .lineLimit(2)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.luxuryMaroon.opacity(0.5))
        .cornerRadius(12)
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }
    
    // MARK: - Packing Chips
    private var packingChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(plan.packingList.prefix(4), id: \.self) { item in
                    HStack(spacing: 6) {
                        Image(systemName: packingIcon(for: item))
                            .font(.system(size: 11))
                        Text(item)
                            .font(Font.inter(12, weight: .medium))
                    }
                    .foregroundColor(Color.luxuryCreamMuted)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.luxuryMaroon.opacity(0.5))
                    .cornerRadius(20)
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 12)
    }
    
    // MARK: - Page Dots
    private var pageDots: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(Color.luxuryMuted.opacity(0.4))
                .frame(width: 6, height: 6)
            
            Capsule()
                .fill(Color.luxuryGold)
                .frame(width: 20, height: 6)
            
            Circle()
                .fill(Color.luxuryMuted.opacity(0.4))
                .frame(width: 6, height: 6)
        }
        .padding(.vertical, 16)
    }
    
    // MARK: - Bottom Action Bar
    private var bottomActionBar: some View {
        VStack(spacing: 12) {
            // Quick Actions
            HStack(spacing: 12) {
                QuickActionButton(icon: "map.fill", label: "Route") {
                    showMap = true
                }
                
                QuickActionButton(icon: "music.note", label: "Playlist") {
                    showPlaylist = true
                }
                
                QuickActionButton(icon: "gift.fill", label: "Gifts") {
                    showGiftFinder = true
                }
                
                QuickActionButton(icon: "camera.fill", label: "Photo") {
                    coordinator.currentTab = .memories
                }
            }
            
            // Main Action Button
            Button {
                if let onSave = onSave {
                    withAnimation(.spring(response: 0.3)) {
                        isSaved = true
                    }
                    onSave()
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 14))
                    Text("AI-Powered Date Planning")
                        .font(Font.inter(14, weight: .semibold))
                }
                .foregroundColor(Color.luxuryGold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    Capsule()
                        .stroke(Color.luxuryGold.opacity(0.5), lineWidth: 1)
                        .background(Capsule().fill(Color.luxuryMaroonLight))
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            Color.luxuryMaroon
                .shadow(color: Color.black.opacity(0.3), radius: 20, y: -5)
                .ignoresSafeArea()
        )
    }
    
    // MARK: - Helpers
    private func isReservable(_ stop: DatePlanStop) -> Bool {
        let types = ["restaurant", "bar", "cafe", "lounge", "bistro", "dining"]
        return types.contains { stop.venueType.lowercased().contains($0) }
    }
    
    private func packingIcon(for item: String) -> String {
        let lower = item.lowercased()
        if lower.contains("shoe") || lower.contains("walking") { return "shoeprints.fill" }
        if lower.contains("jacket") || lower.contains("coat") { return "cloud.fill" }
        if lower.contains("phone") { return "iphone" }
        if lower.contains("camera") { return "camera.fill" }
        if lower.contains("book") || lower.contains("art") { return "book.fill" }
        if lower.contains("umbrella") { return "umbrella.fill" }
        if lower.contains("mint") || lower.contains("breath") { return "leaf.fill" }
        return "bag.fill"
    }
}

// MARK: - Compact Stop Row
struct CompactStopRow: View {
    let stop: DatePlanStop
    let isLast: Bool
    var onTap: (() -> Void)?
    
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            // Icon with line
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .stroke(Color.luxuryGold.opacity(0.4), lineWidth: 1.5)
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: venueIcon)
                        .font(.system(size: 14))
                        .foregroundColor(Color.luxuryGold)
                }
                
                if !isLast {
                    Rectangle()
                        .fill(Color.luxuryGold.opacity(0.25))
                        .frame(width: 1.5, height: 50)
                }
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(stop.name)
                    .font(Font.playfair(16, weight: .semibold))
                    .foregroundColor(Color.luxuryCream)
                
                HStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 10))
                        Text(stop.timeSlot)
                            .font(Font.inter(12, weight: .regular))
                    }
                    .foregroundColor(Color.luxuryMuted)
                    
                    Text("·")
                        .foregroundColor(Color.luxuryMuted)
                    
                    Text(stop.address ?? stop.venueType)
                        .font(Font.inter(12, weight: .regular))
                        .foregroundColor(Color.luxuryMuted)
                        .lineLimit(1)
                }
                
                // Special note (romanticTip as feature)
                HStack(spacing: 4) {
                    Image(systemName: noteIcon)
                        .font(.system(size: 10))
                    Text(stop.romanticTip)
                        .font(Font.inter(11, weight: .medium))
                        .lineLimit(1)
                }
                .foregroundColor(Color.luxuryGold)
                .padding(.top, 2)
            }
            .padding(.bottom, isLast ? 8 : 16)
            .contentShape(Rectangle())
            .onTapGesture {
                onTap?()
            }
        }
    }
    
    private var venueIcon: String {
        let type = stop.venueType.lowercased()
        if type.contains("restaurant") || type.contains("dining") || type.contains("cafe") { return "fork.knife" }
        if type.contains("bar") || type.contains("cocktail") || type.contains("lounge") { return "wineglass.fill" }
        if type.contains("walk") || type.contains("park") || type.contains("garden") { return "figure.walk" }
        if type.contains("museum") || type.contains("gallery") || type.contains("art") { return "building.columns.fill" }
        if type.contains("rooftop") || type.contains("view") { return "building.2.fill" }
        if type.contains("spa") || type.contains("wellness") { return "leaf.fill" }
        if type.contains("movie") || type.contains("cinema") || type.contains("theater") { return "film.fill" }
        if type.contains("music") || type.contains("concert") { return "music.note" }
        return "mappin"
    }
    
    private var noteIcon: String {
        let tip = stop.romanticTip.lowercased()
        if tip.contains("reserv") { return "checkmark.circle.fill" }
        if tip.contains("access") || tip.contains("wheelchair") { return "figure.roll" }
        if tip.contains("vegan") || tip.contains("menu") { return "leaf.fill" }
        return "sparkle"
    }
}

// MARK: - Quick Action Button
struct QuickActionButton: View {
    let icon: String
    let label: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(Color.luxuryGold)
                    .frame(width: 44, height: 44)
                    .background(Color.luxuryMaroonLight)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.luxuryGold.opacity(0.3), lineWidth: 1)
                    )
                
                Text(label)
                    .font(Font.inter(10, weight: .medium))
                    .foregroundColor(Color.luxuryMuted)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Supporting Views (kept for compatibility)
struct LuxuryStatBadge: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(Color.luxuryGold)
            Text(value)
                .font(Font.inter(13, weight: .semibold))
                .foregroundColor(Color.luxuryCream)
            Text(label)
                .font(Font.inter(9, weight: .medium))
                .foregroundColor(Color.luxuryMuted)
        }
    }
}

struct LuxuryQuickAction: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                    .frame(width: 48, height: 48)
                    .background(Color.luxuryMaroonLight)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(color.opacity(0.3), lineWidth: 1)
                    )
                
                Text(title)
                    .font(Font.inter(10, weight: .medium))
                    .foregroundColor(Color.luxuryCream)
            }
        }
    }
}

struct LuxurySectionTitle: View {
    let icon: String
    let title: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(Color.luxuryGold)
            Text(title)
                .font(Font.playfair(16, weight: .semibold))
                .foregroundColor(Color.luxuryGold)
        }
    }
}

struct LuxuryStopCard: View {
    let stop: DatePlanStop
    let isLast: Bool
    var onReserve: (() -> Void)?
    
    var body: some View {
        CompactStopRow(stop: stop, isLast: isLast, onTap: onReserve)
    }
}

struct LuxuryGiftCard: View {
    let gift: GiftSuggestion
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(gift.emoji)
                    .font(.system(size: 28))
                Spacer()
                Text(gift.priceRange)
                    .font(Font.inter(10, weight: .semibold))
                    .foregroundColor(Color.luxuryGold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.luxuryGold.opacity(0.15))
                    .cornerRadius(6)
            }
            
            Text(gift.name)
                .font(Font.playfair(14, weight: .semibold))
                .foregroundColor(Color.luxuryCream)
                .lineLimit(1)
            
            Text(gift.description)
                .font(Font.inter(11, weight: .regular))
                .foregroundColor(Color.luxuryCreamMuted)
                .lineLimit(2)
        }
        .padding(14)
        .frame(width: 160)
        .background(Color.luxuryMaroonLight)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.luxuryGold.opacity(0.25), lineWidth: 1)
        )
    }
}

struct LuxuryConversationCard: View {
    let starter: ConversationStarter
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(starter.emoji)
                .font(.system(size: 24))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(starter.question)
                    .font(Font.playfair(14, weight: .regular))
                    .foregroundColor(Color.luxuryCream)
                
                Text(starter.category)
                    .font(Font.inter(10, weight: .medium))
                    .foregroundColor(Color.luxuryMuted)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.luxuryMaroonLight)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.luxuryGold.opacity(0.25), lineWidth: 1)
        )
    }
}

#Preview {
    DatePlanResultView(
        plan: DatePlan.sample,
        onSave: { },
        onRegenerate: { }
    )
    .environmentObject(NavigationCoordinator.shared)
}
