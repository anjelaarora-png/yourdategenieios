import SwiftUI

struct DatePlanResultView: View {
    let plan: DatePlan
    var onSave: (() -> Void)?
    var onRegenerate: (() -> Void)?
    var isViewingMode: Bool = false
    
    @Environment(\.dismiss) private var dismiss
    @State private var showPlaylist = false
    @State private var showMap = false
    @State private var selectedStop: DatePlanStop?
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Header Card
                    headerCard
                    
                    // Quick Actions
                    quickActionsRow
                    
                    // Itinerary
                    itinerarySection
                    
                    // Genie's Secret Touch
                    genieSecretSection
                    
                    // Packing List
                    packingListSection
                    
                    // Gift Suggestions
                    if let gifts = plan.giftSuggestions, !gifts.isEmpty {
                        giftSuggestionsSection(gifts: gifts)
                    }
                    
                    // Conversation Starters
                    if let starters = plan.conversationStarters, !starters.isEmpty {
                        conversationStartersSection(starters: starters)
                    }
                }
                .padding(.bottom, 100)
            }
            .background(Color.brandCream)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.brandPrimary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            // Share action
                        } label: {
                            Label("Share Plan", systemImage: "square.and.arrow.up")
                        }
                        
                        Button {
                            // Add to calendar
                        } label: {
                            Label("Add to Calendar", systemImage: "calendar.badge.plus")
                        }
                        
                        Button {
                            // Export PDF
                        } label: {
                            Label("Export PDF", systemImage: "doc.fill")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(.brandPrimary)
                    }
                }
            }
            .overlay(alignment: .bottom) {
                bottomBar
            }
        }
        .sheet(isPresented: $showPlaylist) {
            PlaylistView(planTitle: plan.title)
        }
    }
    
    // MARK: - Header Card
    private var headerCard: some View {
        VStack(spacing: 16) {
            // Title & tagline
            VStack(spacing: 8) {
                if let label = plan.optionLabel {
                    Text(label)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.brandGold)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color.brandGold.opacity(0.15))
                        .cornerRadius(12)
                }
                
                Text(plan.title)
                    .font(.custom("Cormorant-Bold", size: 28, relativeTo: .title))
                    .foregroundColor(Color(UIColor.label))
                    .multilineTextAlignment(.center)
                
                Text(plan.tagline)
                    .font(.system(size: 15))
                    .foregroundColor(Color(UIColor.secondaryLabel))
                    .multilineTextAlignment(.center)
            }
            
            // Stats row
            HStack(spacing: 24) {
                StatBadge(icon: "clock", value: plan.totalDuration, label: "Duration")
                StatBadge(icon: "dollarsign.circle", value: plan.estimatedCost, label: "Budget")
                StatBadge(icon: "mappin.circle", value: "\(plan.stops.count)", label: "Stops")
            }
            
            // Weather note
            if !plan.weatherNote.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "cloud.sun.fill")
                        .foregroundColor(.blue)
                    Text(plan.weatherNote)
                        .font(.system(size: 13))
                        .foregroundColor(Color(UIColor.secondaryLabel))
                }
                .padding(12)
                .frame(maxWidth: .infinity)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(10)
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 10, y: 4)
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }
    
    // MARK: - Quick Actions
    private var quickActionsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                QuickActionButton(icon: "map.fill", title: "Route", color: .blue) {
                    showMap = true
                }
                
                QuickActionButton(icon: "music.note", title: "Playlist", color: .pink) {
                    showPlaylist = true
                }
                
                QuickActionButton(icon: "person.2.fill", title: "Invite", color: .purple) {
                    // Share with partner
                }
                
                QuickActionButton(icon: "calendar", title: "Schedule", color: .orange) {
                    // Add to calendar
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 16)
    }
    
    // MARK: - Itinerary Section
    private var itinerarySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionTitle(icon: "list.bullet", title: "Your Itinerary")
            
            VStack(spacing: 0) {
                ForEach(Array(plan.stops.enumerated()), id: \.element.id) { index, stop in
                    StopCard(stop: stop, isLast: index == plan.stops.count - 1)
                }
            }
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 8, y: 2)
        }
        .padding(.horizontal, 16)
    }
    
    // MARK: - Genie's Secret Touch
    private var genieSecretSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(icon: "sparkles", title: "Genie's Secret Touch")
            
            HStack(alignment: .top, spacing: 16) {
                Text(plan.genieSecretTouch.emoji)
                    .font(.system(size: 36))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(plan.genieSecretTouch.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(UIColor.label))
                    
                    Text(plan.genieSecretTouch.description)
                        .font(.system(size: 14))
                        .foregroundColor(Color(UIColor.secondaryLabel))
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.brandGold.opacity(0.15), Color.brandGold.opacity(0.05)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.brandGold.opacity(0.3), lineWidth: 1)
            )
        }
        .padding(.horizontal, 16)
        .padding(.top, 24)
    }
    
    // MARK: - Packing List
    private var packingListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(icon: "bag.fill", title: "Don't Forget")
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(plan.packingList, id: \.self) { item in
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 18))
                        
                        Text(item)
                            .font(.system(size: 15))
                            .foregroundColor(Color(UIColor.label))
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
            .cornerRadius(16)
        }
        .padding(.horizontal, 16)
        .padding(.top, 24)
    }
    
    // MARK: - Gift Suggestions
    private func giftSuggestionsSection(gifts: [GiftSuggestion]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(icon: "gift.fill", title: "Gift Ideas")
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(gifts) { gift in
                        GiftCard(gift: gift)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 24)
    }
    
    // MARK: - Conversation Starters
    private func conversationStartersSection(starters: [ConversationStarter]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(icon: "bubble.left.and.bubble.right.fill", title: "Conversation Starters")
            
            VStack(spacing: 10) {
                ForEach(starters) { starter in
                    ConversationCard(starter: starter)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 24)
    }
    
    // MARK: - Bottom Bar
    private var bottomBar: some View {
        HStack(spacing: 12) {
            if !isViewingMode, let onRegenerate = onRegenerate {
                Button {
                    onRegenerate()
                } label: {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Regenerate")
                    }
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.brandPrimary)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.brandPrimary.opacity(0.3), lineWidth: 1)
                    )
                }
            }
            
            if let onSave = onSave {
                Button {
                    onSave()
                } label: {
                    HStack {
                        Image(systemName: "bookmark.fill")
                        Text("Save Plan")
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(LinearGradient.goldGradient)
                    .cornerRadius(12)
                    .shadow(color: Color.brandGold.opacity(0.4), radius: 8, y: 4)
                }
            }
        }
        .padding(16)
        .background(
            Color.white
                .shadow(color: Color.black.opacity(0.1), radius: 10, y: -5)
        )
    }
}

// MARK: - Supporting Views
struct StatBadge: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.brandGold)
            
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(UIColor.label))
            
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(Color(UIColor.tertiaryLabel))
        }
    }
}

struct QuickActionButton: View {
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
                    .background(color.opacity(0.1))
                    .cornerRadius(12)
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(UIColor.label))
            }
        }
    }
}

struct SectionTitle: View {
    let icon: String
    let title: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.brandGold)
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color(UIColor.label))
        }
    }
}

struct StopCard: View {
    let stop: DatePlanStop
    let isLast: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Timeline
            VStack(spacing: 0) {
                Circle()
                    .fill(LinearGradient.goldGradient)
                    .frame(width: 36, height: 36)
                    .overlay(
                        Text("\(stop.order)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    )
                
                if !isLast {
                    Rectangle()
                        .fill(Color.brandGold.opacity(0.3))
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                }
            }
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(stop.emoji)
                        .font(.system(size: 24))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(stop.name)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(UIColor.label))
                        
                        Text(stop.venueType)
                            .font(.system(size: 13))
                            .foregroundColor(Color(UIColor.secondaryLabel))
                    }
                    
                    Spacer()
                    
                    Text(stop.timeSlot)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.brandGold)
                }
                
                Text(stop.description)
                    .font(.system(size: 14))
                    .foregroundColor(Color(UIColor.secondaryLabel))
                    .lineLimit(2)
                
                // Romantic tip
                HStack(spacing: 6) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.pink)
                    Text(stop.romanticTip)
                        .font(.system(size: 12))
                        .foregroundColor(.pink)
                        .italic()
                }
                .padding(8)
                .background(Color.pink.opacity(0.1))
                .cornerRadius(8)
                
                // Travel time to next
                if let travelTime = stop.travelTimeFromPrevious {
                    HStack(spacing: 4) {
                        Image(systemName: "car.fill")
                            .font(.system(size: 10))
                        Text(travelTime)
                            .font(.system(size: 11))
                    }
                    .foregroundColor(Color(UIColor.tertiaryLabel))
                }
            }
            .padding(.bottom, isLast ? 16 : 24)
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }
}

struct GiftCard: View {
    let gift: GiftSuggestion
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(gift.emoji)
                    .font(.system(size: 28))
                Spacer()
                Text(gift.priceRange)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.brandGold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.brandGold.opacity(0.1))
                    .cornerRadius(8)
            }
            
            Text(gift.name)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Color(UIColor.label))
            
            Text(gift.description)
                .font(.system(size: 13))
                .foregroundColor(Color(UIColor.secondaryLabel))
                .lineLimit(2)
            
            Text(gift.whereToBuy)
                .font(.system(size: 12))
                .foregroundColor(.brandPrimary)
        }
        .padding(16)
        .frame(width: 200)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 2)
    }
}

struct ConversationCard: View {
    let starter: ConversationStarter
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(starter.emoji)
                .font(.system(size: 24))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(starter.question)
                    .font(.system(size: 15))
                    .foregroundColor(Color(UIColor.label))
                
                Text(starter.category)
                    .font(.system(size: 12))
                    .foregroundColor(Color(UIColor.tertiaryLabel))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(12)
    }
}

// Placeholder views
struct PlaylistView: View {
    let planTitle: String
    var body: some View {
        Text("Playlist for \(planTitle)")
    }
}

#Preview {
    DatePlanResultView(
        plan: DatePlan.sample,
        onSave: { print("Save") },
        onRegenerate: { print("Regenerate") }
    )
}
