import SwiftUI

// MARK: - Home app header (logo + notifications — inline, not system toolbar)

struct HomeAppHeaderBar: View {
    @ObservedObject var notificationManager: NotificationManager

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image("Logo")
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .padding(4)
                .background(Color.surfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.accentMaroon.opacity(0.35), lineWidth: 1)
                )
                .accessibilityLabel("Your Date Genie")

            Spacer(minLength: 0)

            NotificationBellButton(notificationManager: notificationManager)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }
}

// MARK: - Collapsible home section (Charcoal Maroon IA)

struct CollapsibleHomeSection<Content: View, Trailing: View>: View {
    let title: String
    var subtitle: String? = nil
    @Binding var isExpanded: Bool
    @ViewBuilder var headerTrailing: () -> Trailing
    @ViewBuilder var content: () -> Content

    init(
        title: String,
        subtitle: String? = nil,
        isExpanded: Binding<Bool>,
        @ViewBuilder headerTrailing: @escaping () -> Trailing = { EmptyView() },
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self._isExpanded = isExpanded
        self.headerTrailing = headerTrailing
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Rectangle()
                .fill(Color.accentGold.opacity(0.12))
                .frame(height: 1)
                .padding(.horizontal, 20)
                .padding(.bottom, 18)

            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title.uppercased())
                            .font(Font.bodySans(13, weight: .semibold))
                            .tracking(1.2)
                            .foregroundColor(Color.accentGold)
                        if let subtitle, !subtitle.isEmpty {
                            Text(subtitle)
                                .font(Font.bodySans(11, weight: .regular))
                                .foregroundColor(Color.textPrimary.opacity(0.5))
                        }
                    }
                    Spacer(minLength: 8)
                    headerTrailing()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color.accentGold.opacity(0.7))
                }
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)

            content()
                .opacity(isExpanded ? 1 : 0)
                .frame(height: isExpanded ? nil : 0)
                .clipped()
        }
    }
}

// MARK: - Shared cream itinerary card (Home hero + plan detail)

enum ItineraryPlanFormatting {
    static func locationLabel(for plan: DatePlan) -> String {
        let loc = MapURLHelper.cityStateOrRegionFromAddress(plan.stops.first?.address)
        return loc.isEmpty ? plan.title : loc
    }

    static func scheduleLabel(for plan: DatePlan) -> String {
        if let d = plan.scheduledDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return formatter.string(from: d)
        }
        return plan.tagline
    }

    static func metaLine(for plan: DatePlan) -> String {
        let time = plan.stops.first?.timeSlot ?? ""
        let stops = "\(plan.stops.count) stop\(plan.stops.count == 1 ? "" : "s")"
        let cost = plan.estimatedCost.isEmpty ? "" : " · \(plan.estimatedCost) est."
        if time.isEmpty { return "\(stops)\(cost)" }
        return "\(time) · \(stops)\(cost)"
    }

    static func footerLine(for plan: DatePlan) -> String {
        var parts: [String] = []
        if !plan.totalDuration.isEmpty { parts.append("Est. \(plan.totalDuration)") }
        if !plan.weatherNote.isEmpty { parts.append(plan.weatherNote) }
        return parts.joined(separator: " · ")
    }

    static func stopDetail(_ stop: DatePlanStop) -> String {
        if !stop.description.isEmpty && stop.description.count < 72 {
            return stop.description
        }
        if !stop.venueType.isEmpty { return stop.venueType }
        if let travel = stop.travelTimeFromPrevious, !travel.isEmpty {
            return "\(travel) · next stop"
        }
        return stop.address ?? ""
    }

    static func itineraryStops(for plan: DatePlan) -> [DatePlanStop] {
        plan.stops.filter { $0.venueType != "Starting point" && $0.name != "Your location" }
    }

    static func isReservable(_ stop: DatePlanStop) -> Bool {
        let types = ["restaurant", "bar", "cafe", "lounge", "bistro", "dining"]
        return types.contains { stop.venueType.lowercased().contains($0) }
    }

    static func packingIcon(for item: String) -> String {
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

struct ItineraryCreamCardChrome<Content: View>: View {
    var edgePadding: CGFloat = 20
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content()
        }
        .background(Color.creamCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.maroonBorderTint, lineWidth: 1)
        )
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 1.5)
                .fill(Color.accentMaroon)
                .frame(width: 3)
                .padding(.vertical, 1)
        }
        .padding(.horizontal, edgePadding)
    }
}

struct ItineraryGradientBanner: View {
    let plan: DatePlan

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: [Color(hex: "5C3A2E"), Color(hex: "8B5E4A"), Color(hex: "4A3028")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: 72)

            Text("\(ItineraryPlanFormatting.locationLabel(for: plan)) · \(ItineraryPlanFormatting.scheduleLabel(for: plan))")
                .font(Font.bodySans(10, weight: .semibold))
                .tracking(0.6)
                .textCase(.uppercase)
                .foregroundColor(Color.creamParchmentLight.opacity(0.85))
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
        }
    }
}

struct ItineraryPlanHeaderBlock: View {
    let plan: DatePlan
    var partnerName: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let partner = partnerName, !partner.isEmpty {
                Text("For you & \(partner)")
                    .font(Font.bodySans(11, weight: .regular))
                    .foregroundColor(Color.textMutedOnCard)
            }
            Text(plan.title)
                .font(Font.bodySerif(17, weight: .regular))
                .foregroundColor(Color.textOnCard)
            Text(ItineraryPlanFormatting.metaLine(for: plan))
                .font(Font.bodySans(11, weight: .regular))
                .foregroundColor(Color.textMutedOnCard)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

struct ItineraryCreamStopRow: View {
    let stop: DatePlanStop
    var showsTopDivider: Bool = true
    var onReserve: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                Text(stop.timeSlot)
                    .font(Font.bodySans(12, weight: .semibold))
                    .foregroundColor(Color.textOnCard)
                    .frame(minWidth: 38, alignment: .leading)
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 5) {
                        Text(stop.name)
                            .font(Font.bodySans(13, weight: .medium))
                            .foregroundColor(Color.textOnCard)
                        if stop.isVerified {
                            VerifiedBadge()
                        }
                    }
                    Text(ItineraryPlanFormatting.stopDetail(stop))
                        .font(Font.bodySans(11, weight: .regular))
                        .foregroundColor(Color.textMutedOnCard)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                    if let onReserve {
                        Button(action: onReserve) {
                            HStack(spacing: 4) {
                                Image(systemName: "fork.knife.circle")
                                    .font(.system(size: 10))
                                Text("Reserve")
                                    .font(Font.bodySans(11, weight: .semibold))
                            }
                            .foregroundColor(Color.accentMaroon)
                        }
                        .buttonStyle(.plain)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 9)
        }
        .overlay(alignment: .top) {
            if showsTopDivider {
                Rectangle().fill(Color.black.opacity(0.06)).frame(height: 1)
            }
        }
    }
}

struct ItineraryCreamTravelLeg: View {
    let travelMode: String?
    let timeText: String
    let distanceText: String?

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: TravelModeIcon.sfSymbol(for: travelMode, inferFromTimeText: timeText))
                .font(.system(size: 10))
                .foregroundColor(Color.textMutedOnCard)
            Text(timeText)
                .font(Font.bodySans(11, weight: .medium))
                .foregroundColor(Color.textMutedOnCard)
            if let distanceText, !distanceText.isEmpty {
                Text("·")
                    .foregroundColor(Color.textMutedOnCard)
                Text(distanceText)
                    .font(Font.bodySans(11, weight: .regular))
                    .foregroundColor(Color.textMutedOnCard)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ItineraryPlanFooterBlock: View {
    let plan: DatePlan

    var body: some View {
        let line = ItineraryPlanFormatting.footerLine(for: plan)
        if !line.isEmpty {
            Text(line)
                .font(Font.bodySans(12, weight: .regular))
                .foregroundColor(Color(hex: "9A9690"))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .overlay(alignment: .top) {
                    Rectangle().fill(Color.black.opacity(0.06)).frame(height: 1)
                }
        }
    }
}

struct ItineraryCreamInsetSection<Content: View, Trailing: View>: View {
    let title: String
    let icon: String
    @ViewBuilder var trailing: () -> Trailing
    @ViewBuilder var content: () -> Content

    init(
        title: String,
        icon: String,
        @ViewBuilder trailing: @escaping () -> Trailing = { EmptyView() },
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.icon = icon
        self.trailing = trailing
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                Text(title)
                    .font(Font.bodySans(11, weight: .semibold))
                    .textCase(.uppercase)
                    .tracking(0.4)
                Spacer(minLength: 8)
                trailing()
            }
            .foregroundColor(Color.textMutedOnCard)
            content()
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.black.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

struct ItineraryStartingPointCreamSection: View {
    let startingPoint: StartingPoint
    let firstStop: DatePlanStop?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(Color.accentMaroon)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Starting point")
                        .font(Font.bodySans(12, weight: .semibold))
                        .foregroundColor(Color.textOnCard)
                    Text(startingPoint.address)
                        .font(Font.bodySans(11, weight: .regular))
                        .foregroundColor(Color.textMutedOnCard)
                }
                Spacer(minLength: 0)
            }
            if let firstStop, let url = MapURLHelper.directionsURL(origin: startingPoint, destination: firstStop) {
                Button {
                    UIApplication.shared.open(url)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                            .font(.system(size: 11))
                        Text("Get to stop 1: \(firstStop.name)")
                            .font(Font.bodySans(12, weight: .medium))
                    }
                    .foregroundColor(Color.accentMaroon)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .overlay(alignment: .top) {
            Rectangle().fill(Color.black.opacity(0.06)).frame(height: 1)
        }
    }
}

struct ItineraryGenieSecretCreamSection: View {
    let touch: GenieSecretTouch

    var body: some View {
        if !touch.description.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    if !touch.emoji.isEmpty {
                        Text(touch.emoji)
                            .font(.system(size: 14))
                    }
                    Text("Genie's secret touch")
                        .font(Font.bodySans(11, weight: .semibold))
                        .foregroundColor(Color.textMutedOnCard)
                        .textCase(.uppercase)
                        .tracking(0.5)
                }
                if !touch.title.isEmpty {
                    Text(touch.title)
                        .font(Font.bodySans(13, weight: .semibold))
                        .foregroundColor(Color.textOnCard)
                }
                Text(touch.description)
                    .font(Font.bodySans(13, weight: .regular))
                    .foregroundColor(Color.textOnCard)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(alignment: .top) {
                Rectangle().fill(Color.black.opacity(0.06)).frame(height: 1)
            }
        }
    }
}

struct ItineraryCreamPlanDetailContent: View {
    let plan: DatePlan
    var partnerName: String? = nil
    var onReserveStop: ((DatePlanStop) -> Void)? = nil
    var onOpenRoute: (() -> Void)? = nil
    var onGetMoreGiftIdeas: (() -> Void)? = nil
    var canAccessGiftIdeas: Bool = true

    private var itineraryStops: [DatePlanStop] {
        ItineraryPlanFormatting.itineraryStops(for: plan)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ItineraryGradientBanner(plan: plan)
            ItineraryPlanHeaderBlock(plan: plan, partnerName: partnerName)

            if let start = plan.startingPoint {
                ItineraryStartingPointCreamSection(
                    startingPoint: start,
                    firstStop: itineraryStops.first
                )
            }

            ForEach(Array(itineraryStops.enumerated()), id: \.element.id) { index, stop in
                if index > 0, let time = stop.travelTimeFromPrevious, !time.isEmpty {
                    ItineraryCreamTravelLeg(
                        travelMode: stop.travelMode,
                        timeText: time,
                        distanceText: stop.travelDistanceFromPrevious
                    )
                }
                ItineraryCreamStopRow(
                    stop: stop,
                    onReserve: (onReserveStop != nil && ItineraryPlanFormatting.isReservable(stop))
                        ? { onReserveStop?(stop) }
                        : nil
                )
            }

            ItineraryPlanFooterBlock(plan: plan)
            ItineraryGenieSecretCreamSection(touch: plan.genieSecretTouch)
            conversationStartersSection
            giftSuggestionsSection
            packingChips
            routeSection
        }
    }

    @ViewBuilder
    private var conversationStartersSection: some View {
        if let starters = plan.conversationStarters, !starters.isEmpty {
            ItineraryCreamInsetSection(title: "Conversation Starters", icon: "bubble.left.fill") {
                ForEach(starters) { starter in
                    Text("\"\(starter.question)\"")
                        .font(Font.bodySerif(14, weight: .regular))
                        .italic()
                        .foregroundColor(Color.textOnCard)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    @ViewBuilder
    private var giftSuggestionsSection: some View {
        if let gifts = plan.giftSuggestions, !gifts.isEmpty {
            ItineraryCreamInsetSection(title: "Gift Suggestions", icon: "gift.fill") {
                if onGetMoreGiftIdeas != nil {
                    Button(action: { onGetMoreGiftIdeas?() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 10))
                            Text("Get More Ideas")
                                .font(Font.bodySans(11, weight: .semibold))
                        }
                        .foregroundColor(Color.accentMaroon)
                        .opacity(canAccessGiftIdeas ? 1 : 0.5)
                    }
                    .buttonStyle(.plain)
                }
            } content: {
                ForEach(gifts) { gift in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .top) {
                            Text(gift.emoji)
                                .font(.system(size: 16))
                            Text(gift.name)
                                .font(Font.bodySans(13, weight: .semibold))
                                .foregroundColor(Color.textOnCard)
                            Spacer(minLength: 8)
                            Text(gift.priceRange)
                                .font(Font.bodySans(11, weight: .medium))
                                .foregroundColor(Color.textMutedOnCard)
                        }
                        Text(gift.description)
                            .font(Font.bodySans(12, weight: .regular))
                            .foregroundColor(Color.textMutedOnCard)
                            .fixedSize(horizontal: false, vertical: true)
                        if !gift.whereToBuy.isEmpty {
                            Text("Where: \(gift.whereToBuy)")
                                .font(Font.bodySans(11, weight: .regular))
                                .foregroundColor(Color.textMutedOnCard)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    @ViewBuilder
    private var packingChips: some View {
        if !plan.packingList.isEmpty {
            ItineraryCreamInsetSection(title: "Pack", icon: "bag.fill") {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(plan.packingList.prefix(6), id: \.self) { item in
                            HStack(spacing: 5) {
                                Image(systemName: ItineraryPlanFormatting.packingIcon(for: item))
                                    .font(.system(size: 10))
                                Text(item)
                                    .font(Font.bodySans(11, weight: .medium))
                            }
                            .foregroundColor(Color.textOnCard)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.black.opacity(0.05))
                            .clipShape(Capsule())
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var routeSection: some View {
        if let onOpenRoute, !itineraryStops.isEmpty {
            Button(action: onOpenRoute) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                        .font(.system(size: 12))
                    Text("View full route")
                        .font(Font.bodySans(13, weight: .semibold))
                    Spacer(minLength: 0)
                    Text("\(itineraryStops.count) stops")
                        .font(Font.bodySans(11, weight: .regular))
                        .foregroundColor(Color.textMutedOnCard)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color.textMutedOnCard)
                }
                .foregroundColor(Color.accentMaroon)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .buttonStyle(.plain)
            .overlay(alignment: .top) {
                Rectangle().fill(Color.black.opacity(0.06)).frame(height: 1)
            }
        }
    }
}

struct ItineraryCreamPlanPreviewCard: View {
    let plan: DatePlan
    var partnerName: String? = nil
    var maxStops: Int = 4
    var edgePadding: CGFloat = 0

    private var itineraryStops: [DatePlanStop] {
        ItineraryPlanFormatting.itineraryStops(for: plan)
    }

    var body: some View {
        ItineraryCreamCardChrome(edgePadding: edgePadding) {
            VStack(alignment: .leading, spacing: 0) {
                ItineraryGradientBanner(plan: plan)
                ItineraryPlanHeaderBlock(plan: plan, partnerName: partnerName)
                ForEach(Array(itineraryStops.prefix(maxStops).enumerated()), id: \.element.id) { index, stop in
                    if index > 0, let time = stop.travelTimeFromPrevious, !time.isEmpty {
                        ItineraryCreamTravelLeg(
                            travelMode: stop.travelMode,
                            timeText: time,
                            distanceText: stop.travelDistanceFromPrevious
                        )
                    }
                    ItineraryCreamStopRow(stop: stop)
                }
                if itineraryStops.count > maxStops {
                    Text("+ \(itineraryStops.count - maxStops) more stop\(itineraryStops.count - maxStops == 1 ? "" : "s")")
                        .font(Font.bodySans(11, weight: .medium))
                        .foregroundColor(Color.textMutedOnCard)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                }
                ItineraryPlanFooterBlock(plan: plan)
            }
        }
    }
}

// MARK: - Love note cream card (matches itinerary chrome)

struct LoveNoteGradientBanner: View {
    var subtitle: String = "For your partner"

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: [Color(hex: "5C3A2E"), Color(hex: "8B5E4A"), Color(hex: "4A3028")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: 44)
            HStack(spacing: 6) {
                Image(systemName: "heart.text.square.fill")
                    .font(.system(size: 10))
                    .foregroundColor(Color.creamParchmentLight.opacity(0.9))
                Text("Love Note · \(subtitle)")
                    .font(Font.bodySans(10, weight: .semibold))
                    .tracking(0.6)
                    .textCase(.uppercase)
                    .foregroundColor(Color.creamParchmentLight.opacity(0.85))
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 8)
        }
    }
}

struct LoveNoteCreamCard<Content: View>: View {
    var edgePadding: CGFloat = 0
    var bannerSubtitle: String = "For your partner"
    @ViewBuilder var content: () -> Content

    var body: some View {
        ItineraryCreamCardChrome(edgePadding: edgePadding) {
            VStack(alignment: .leading, spacing: 0) {
                LoveNoteGradientBanner(subtitle: bannerSubtitle)
                content()
            }
        }
    }
}

// MARK: - Itinerary hero card (cream card, maroon left border)

struct ItineraryHeroCard: View {
    let plan: DatePlan
    var partnerName: String?
    var onApprove: () -> Void
    var onSwap: () -> Void
    var onView: () -> Void

    var body: some View {
        ItineraryCreamCardChrome {
            VStack(alignment: .leading, spacing: 0) {
                ItineraryGradientBanner(plan: plan)
                ItineraryPlanHeaderBlock(plan: plan, partnerName: partnerName)

                ForEach(Array(plan.stops.prefix(3))) { stop in
                    ItineraryCreamStopRow(stop: stop)
                }

                ItineraryPlanFooterBlock(plan: plan)

                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Button(action: onApprove) {
                            Text("Approve")
                                .font(Font.bodySans(14, weight: .semibold))
                                .foregroundColor(Color.backgroundPrimary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.accentGold)
                                .cornerRadius(10)
                        }
                        .buttonStyle(.plain)

                        Button(action: onSwap) {
                            Text("Swap stop")
                                .font(Font.bodySans(13, weight: .medium))
                                .foregroundColor(Color.textOnCard)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.textOnCard.opacity(0.2), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }

                    Button(action: onView) {
                        Text("View full plan")
                            .font(Font.bodySans(13, weight: .medium))
                            .foregroundColor(Color.textMutedOnCard)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 14)
            }
        }
    }
}

// MARK: - Swap stop sheet (hero card — no full re-plan)

struct SwapStopContext: Identifiable {
    let id = UUID()
    let plan: DatePlan
    let stopIndex: Int
}

struct SwapStopAlternative: Identifiable {
    let id: String
    let name: String
    let venueType: String
    let address: String
    let detail: String
    let isCurrent: Bool
    var placeId: String? = nil
    var latitude: Double? = nil
    var longitude: Double? = nil
    var imageUrl: String? = nil
}

enum SwapStopLogic {
    static func dinnerStopIndex(in plan: DatePlan) -> Int? {
        let dinnerHints = ["restaurant", "dinner", "dining", "bistro", "steakhouse", "italian", "pizzeria", "eatery", "grill", "tavern"]
        if let idx = plan.stops.firstIndex(where: { stop in
            let hay = "\(stop.venueType) \(stop.name) \(stop.description)".lowercased()
            return dinnerHints.contains { hay.contains($0) }
        }) {
            return idx
        }
        return plan.stops.isEmpty ? nil : 0
    }

    /// The "keep current" row, always shown first.
    static func currentAlternative(for stop: DatePlanStop) -> SwapStopAlternative {
        let area = MapURLHelper.cityStateOrRegionFromAddress(stop.address)
        return SwapStopAlternative(
            id: "current",
            name: stop.name,
            venueType: stop.venueType.isEmpty ? "Restaurant" : stop.venueType,
            address: stop.address ?? area,
            detail: formattedDetail(venueType: stop.venueType, address: stop.address, tag: "current"),
            isCurrent: true
        )
    }

    /// Map a real Google Places result into a swap alternative, carrying place_id/coords/photo
    /// so the swapped stop stays verified and routable.
    static func alternative(from place: GooglePlacesService.PlaceSearchResult, venueType: String, index: Int) -> SwapStopAlternative {
        var parts: [String] = []
        if !venueType.isEmpty { parts.append(venueType) }
        if let rating = place.rating { parts.append(String(format: "%.1f★", rating)) }
        if !place.address.isEmpty { parts.append(place.address) }
        return SwapStopAlternative(
            id: place.placeId.isEmpty ? "alt-\(index)" : place.placeId,
            name: place.name,
            venueType: venueType,
            address: place.address,
            detail: parts.joined(separator: " · "),
            isCurrent: false,
            placeId: place.placeId.isEmpty ? nil : place.placeId,
            latitude: place.latitude,
            longitude: place.longitude,
            imageUrl: place.photoUrl
        )
    }

    /// Heuristic fallback list used only when Google Places returns nothing (e.g. key not configured).
    static func alternatives(for stop: DatePlanStop) -> [SwapStopAlternative] {
        let current = currentAlternative(for: stop)
        let placeholders: [(String, String, String, String)] = [
            ("Minetta Tavern", "Steakhouse", "113 MacDougal St", "Reservation recommended"),
            ("Joe's Pizza", "Casual", "7 Carmine St", "Walk-in · casual backup"),
            ("The Spotted Pig", "Gastropub", "314 W 11th St", "Same time slot · nearby")
        ]
        var alts = [current]
        for (i, row) in placeholders.enumerated() where row.0.caseInsensitiveCompare(stop.name) != .orderedSame {
            alts.append(SwapStopAlternative(
                id: "alt-\(i)",
                name: row.0,
                venueType: row.1,
                address: row.2,
                detail: formattedDetail(venueType: row.1, address: row.2, tag: nil),
                isCurrent: false
            ))
            if alts.count >= 3 { break }
        }
        return alts
    }

    private static func formattedDetail(venueType: String, address: String?, tag: String?) -> String {
        var parts: [String] = []
        if !venueType.isEmpty { parts.append(venueType) }
        if let address, !address.isEmpty { parts.append(address) }
        if tag == "current" { parts.append("current") }
        return parts.joined(separator: " · ")
    }
}

struct SwapStopSheet: View {
    let plan: DatePlan
    let stopIndex: Int
    var onSelect: (SwapStopAlternative) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var alternatives: [SwapStopAlternative] = []
    @State private var isLoading = true

    private var stop: DatePlanStop {
        plan.stops[stopIndex]
    }

    private var areaLabel: String {
        let loc = MapURLHelper.cityStateOrRegionFromAddress(stop.address)
        return loc.isEmpty ? "Same time slot" : "Same time slot · \(loc)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Capsule()
                .fill(Color.luxuryMuted.opacity(0.35))
                .frame(width: 36, height: 4)
                .frame(maxWidth: .infinity)
                .padding(.top, 10)
                .padding(.bottom, 18)

            Text("Swap dinner stop")
                .font(Font.bodySerif(17, weight: .regular))
                .foregroundColor(Color.textPrimary)
            Text(areaLabel)
                .font(Font.bodySans(12, weight: .regular))
                .foregroundColor(Color.luxuryMuted)
                .padding(.top, 4)
                .padding(.bottom, 16)

            if isLoading {
                HStack(spacing: 8) {
                    ProgressView().tint(Color.luxuryMuted)
                    Text("Finding nearby spots…")
                        .font(Font.bodySans(12, weight: .regular))
                        .foregroundColor(Color.luxuryMuted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 12)
            }

            ForEach(alternatives) { option in
                Button {
                    onSelect(option)
                    dismiss()
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(option.name)
                            .font(Font.bodySans(14, weight: .semibold))
                            .foregroundColor(Color.textPrimary)
                        Text(option.detail)
                            .font(Font.bodySans(11, weight: .regular))
                            .foregroundColor(Color.luxuryMuted)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(Color.luxeSurfaceTint)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.luxeSurfaceTintStrong, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .padding(.bottom, 8)
            }

            Button("Cancel") { dismiss() }
                .font(Font.bodySans(13, weight: .regular))
                .foregroundColor(Color.luxuryMuted)
                .frame(maxWidth: .infinity)
                .padding(.top, 8)
                .buttonStyle(.plain)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.surfaceElevated)
        .task(id: stop.id) { await loadAlternatives() }
    }

    /// Load real nearby alternatives from Google Places; fall back to the heuristic list
    /// only when Places returns nothing so the sheet always offers options.
    private func loadAlternatives() async {
        let current = SwapStopLogic.currentAlternative(for: stop)
        let venueLabel = stop.venueType.isEmpty ? "Restaurant" : stop.venueType
        let real = (try? await GooglePlacesService.shared.fetchSwapAlternatives(for: stop, limit: 3)) ?? []
        let mapped = real.enumerated().map { idx, place in
            SwapStopLogic.alternative(from: place, venueType: venueLabel, index: idx)
        }
        await MainActor.run {
            alternatives = mapped.isEmpty ? SwapStopLogic.alternatives(for: stop) : ([current] + mapped)
            isLoading = false
        }
    }
}

extension DatePlan {
    func replacingStop(at index: Int, with alternative: SwapStopAlternative) -> DatePlan {
        guard index >= 0, index < stops.count else { return self }
        let old = stops[index]
        let newStop = DatePlanStop(
            order: old.order,
            name: alternative.name,
            venueType: alternative.venueType,
            timeSlot: old.timeSlot,
            duration: old.duration,
            description: alternative.detail,
            whyItFits: old.whyItFits,
            romanticTip: old.romanticTip,
            emoji: old.emoji,
            travelTimeFromPrevious: old.travelTimeFromPrevious,
            travelDistanceFromPrevious: old.travelDistanceFromPrevious,
            travelMode: old.travelMode,
            validated: alternative.placeId != nil ? true : old.validated,
            placeId: alternative.placeId ?? old.placeId,
            address: alternative.address,
            latitude: alternative.latitude ?? old.latitude,
            longitude: alternative.longitude ?? old.longitude,
            imageUrl: alternative.imageUrl ?? old.imageUrl
        )
        var newStops = stops
        newStops[index] = newStop
        return DatePlan(
            id: id,
            optionLabel: optionLabel,
            title: title,
            tagline: tagline,
            totalDuration: totalDuration,
            estimatedCost: estimatedCost,
            stops: newStops,
            startingPoint: startingPoint,
            genieSecretTouch: genieSecretTouch,
            packingList: packingList,
            weatherNote: weatherNote,
            giftSuggestions: giftSuggestions,
            conversationStarters: conversationStarters,
            scheduledDate: scheduledDate,
            createdAt: createdAt
        )
    }
}
