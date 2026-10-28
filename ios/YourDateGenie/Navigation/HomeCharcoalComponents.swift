import SwiftUI

// MARK: - Home app header (logo + notifications — inline, not system toolbar)

struct HomeAppHeaderBar: View {
    @ObservedObject var notificationManager: NotificationManager

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            DateNightMarkView(side: 36)

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

    /// The final design shows every Home section open, so `isExpanded` is kept only for call-site compatibility.
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .ydgText(.title2)
                        .accessibilityAddTraits(.isHeader)
                    if let subtitle, !subtitle.isEmpty {
                        Text(subtitle)
                            .ydgText(.footnote, color: .ydgTextSecondary)
                    }
                }
                Spacer(minLength: 8)
                headerTrailing()
            }
            .padding(.horizontal, YDGSpace.margin)

            content()
                .padding(.top, 14)
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

/// Plan card frame. The Final design moved itineraries onto a dark raised card;
/// `.cream` is kept for love notes and playlist cards, whose content uses on-card colors.
struct ItineraryCreamCardChrome<Content: View>: View {
    /// `.plain`: no card at all — the itinerary sits straight on the screen (plan detail, design 3.7).
    enum Surface { case raised, cream, plain }

    var edgePadding: CGFloat = 20
    var surface: Surface = .raised
    @ViewBuilder var content: () -> Content

    var body: some View {
        if surface == .plain {
            VStack(alignment: .leading, spacing: 0) {
                content()
            }
            .padding(.horizontal, edgePadding - YDGSpace.md)
        } else {
            VStack(alignment: .leading, spacing: 0) {
                content()
            }
            .background(surface == .cream ? Color.creamCard : Color.ydgRaised,
                        in: RoundedRectangle(cornerRadius: YDGRadius.card, style: .continuous))
            .clipShape(RoundedRectangle(cornerRadius: YDGRadius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: YDGRadius.card, style: .continuous)
                    .stroke(surface == .cream ? Color.maroonBorderTint : Color.ydgBorder, lineWidth: 1)
            )
            .padding(.horizontal, edgePadding)
        }
    }
}

/// Rose overline: "WILLIAMSBURG · FRIDAY". (Was a brown gradient banner.)
struct ItineraryGradientBanner: View {
    let plan: DatePlan

    var body: some View {
        Text("\(ItineraryPlanFormatting.locationLabel(for: plan)) · \(ItineraryPlanFormatting.scheduleLabel(for: plan))")
            .ydgText(.caption, color: .ydgHighlight)
            .lineLimit(1)
            .padding(.horizontal, YDGSpace.md)
            .padding(.top, YDGSpace.md)
    }
}

struct ItineraryPlanHeaderBlock: View {
    let plan: DatePlan
    var partnerName: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(plan.title)
                .font(.ydgDisplay(26))
                .tracking(-0.3)
                .foregroundColor(Color.ydgTextPrimary)
                .fixedSize(horizontal: false, vertical: true)
            Text(ItineraryPlanFormatting.metaLine(for: plan))
                .ydgText(.subhead, weight: .regular, color: .ydgTextSecondary)
            if let partner = partnerName, !partner.isEmpty {
                Text("For you & \(partner)")
                    .ydgText(.footnote, color: .ydgTextSecondary)
            }
        }
        .padding(.horizontal, YDGSpace.md)
        .padding(.top, YDGSpace.xs)
        .padding(.bottom, YDGSpace.md)
    }
}

/// Timeline rail: dot + connecting line. First stop is a filled dot.
private struct ItineraryRail: View {
    var isFirst: Bool
    var isLast: Bool

    var body: some View {
        VStack(spacing: 0) {
            Circle()
                .fill(isFirst ? Color.ydgAccent : Color.ydgRaised)
                .overlay(Circle().stroke(Color.ydgAccent, lineWidth: 2))
                .frame(width: 14, height: 14)
                .padding(.top, 3)
            Rectangle()
                .fill(isLast ? Color.clear : Color.ydgBorder)
                .frame(width: 2)
                .frame(maxHeight: .infinity)
        }
        .frame(width: 14)
        .accessibilityHidden(true)
    }
}

struct ItineraryCreamStopRow: View {
    let stop: DatePlanStop
    var showsTopDivider: Bool = true
    var onReserve: (() -> Void)? = nil
    var isFirst: Bool = false
    var isLast: Bool = false
    /// Day the plan happens on, to pick that day's opening hours; nil = today.
    var planDate: Date? = nil

    /// Google's weekday line for the plan's day, e.g. "Friday: 5:00 – 11:00 PM".
    private var hoursLine: String? {
        guard let lines = stop.openingHours, !lines.isEmpty else { return nil }
        let f = DateFormatter(); f.locale = Locale(identifier: "en_US"); f.dateFormat = "EEEE"
        let day = f.string(from: planDate ?? Date())
        return lines.first { $0.hasPrefix(day) }
    }

    var body: some View {
        HStack(alignment: .top, spacing: YDGSpace.md) {
            ItineraryRail(isFirst: isFirst, isLast: isLast)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    Text(stop.timeSlot)
                        .font(.ydg(.subhead, weight: .semibold))
                        .foregroundColor(Color.ydgTextPrimary)
                    if !stop.duration.isEmpty {
                        Text("· \(stop.duration)")
                            .font(.ydg(.subhead))
                            .foregroundColor(Color.ydgTextTertiary)
                    }
                }
                Text(stop.name)
                    .font(.ydgDisplay(21))
                    .foregroundColor(Color.ydgTextPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                let detail = ItineraryPlanFormatting.stopDetail(stop)
                if !detail.isEmpty {
                    Text(detail)
                        .ydgText(.subhead, weight: .regular, color: .ydgTextSecondary)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
                statusLine
                if let onReserve {
                    Button(action: onReserve) {
                        Label("Check reservation times", systemImage: "fork.knife")
                            .font(.ydg(.subhead, weight: .semibold))
                            .foregroundColor(Color.ydgAccent)
                            .frame(minHeight: 36)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.bottom, isLast ? YDGSpace.xs : YDGSpace.md)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, YDGSpace.md)
        .accessibilityElement(children: .contain)
    }

    /// Hours we actually have from Google, a verified-venue line, or an honest "check" note.
    @ViewBuilder
    private var statusLine: some View {
        if let hoursLine {
            Label {
                Text(hoursLine).ydgText(.footnote, color: .ydgTextSecondary)
            } icon: {
                Image(systemName: "checkmark").font(.system(size: 11, weight: .bold)).foregroundColor(Color.ydgSuccess)
            }
        } else if stop.isVerified {
            Label {
                Text("Verified venue · check hours before you go").ydgText(.footnote, color: .ydgTextSecondary)
            } icon: {
                Image(systemName: "checkmark").font(.system(size: 11, weight: .bold)).foregroundColor(Color.ydgSuccess)
            }
        } else {
            Label {
                Text("Hours not listed · worth a quick check").ydgText(.footnote, color: .ydgTextSecondary)
            } icon: {
                Image(systemName: "clock").font(.system(size: 11, weight: .semibold)).foregroundColor(Color.ydgWarning)
            }
        }
    }
}

struct ItineraryCreamTravelLeg: View {
    let travelMode: String?
    let timeText: String
    let distanceText: String?

    var body: some View {
        HStack(alignment: .center, spacing: YDGSpace.md) {
            Rectangle()
                .fill(Color.ydgBorder)
                .frame(width: 2)
                .frame(width: 14)
                .frame(maxHeight: .infinity)
                .accessibilityHidden(true)
            HStack(spacing: 6) {
                Image(systemName: TravelModeIcon.sfSymbol(for: travelMode, inferFromTimeText: timeText))
                    .font(.system(size: 12))
                Text(timeText)
                if let distanceText, !distanceText.isEmpty {
                    Text("· \(distanceText)")
                }
            }
            .font(.ydg(.footnote))
            .foregroundColor(Color.ydgTextTertiary)
            .padding(.vertical, 6)
            Spacer(minLength: 0)
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(.horizontal, YDGSpace.md)
        .padding(.bottom, YDGSpace.xs)
    }
}

struct ItineraryPlanFooterBlock: View {
    let plan: DatePlan

    var body: some View {
        let line = ItineraryPlanFormatting.footerLine(for: plan)
        if !line.isEmpty {
            Text(line)
                .ydgText(.footnote, color: .ydgTextTertiary)
                .padding(.horizontal, YDGSpace.md)
                .padding(.vertical, YDGSpace.sm)
                .frame(maxWidth: .infinity, alignment: .leading)
                .overlay(alignment: .top) {
                    Rectangle().fill(Color.ydgBorder).frame(height: 1)
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
        VStack(alignment: .leading, spacing: YDGSpace.sm) {
            HStack(spacing: 6) {
                Text(title)
                    .ydgText(.caption)
                Spacer(minLength: 8)
                trailing()
            }
            content()
        }
        .padding(YDGSpace.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.ydgOverlay, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .padding(.horizontal, YDGSpace.md)
        .padding(.vertical, 6)
    }
}

struct ItineraryStartingPointCreamSection: View {
    let startingPoint: StartingPoint
    let firstStop: DatePlanStop?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: YDGSpace.sm) {
                Image(systemName: "house")
                    .font(.system(size: 15))
                    .foregroundColor(Color.ydgTextSecondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Starting point")
                        .ydgText(.subhead, weight: .semibold)
                    Text(startingPoint.address)
                        .ydgText(.footnote, color: .ydgTextSecondary)
                }
                Spacer(minLength: 0)
            }
            if let firstStop, let url = MapURLHelper.directionsURL(origin: startingPoint, destination: firstStop) {
                Button {
                    UIApplication.shared.open(url)
                } label: {
                    Label("Directions to \(firstStop.name)", systemImage: "arrow.triangle.turn.up.right.diamond")
                        .font(.ydg(.subhead, weight: .semibold))
                        .foregroundColor(Color.ydgAccent)
                        .frame(minHeight: 36)
                }
                .buttonStyle(.plain)
                .padding(.leading, 27)
            }
        }
        .padding(.horizontal, YDGSpace.md)
        .padding(.vertical, YDGSpace.sm)
        .overlay(alignment: .top) {
            Rectangle().fill(Color.ydgBorder).frame(height: 1)
        }
        .padding(.bottom, YDGSpace.sm)
    }
}

/// "A little extra": rose-tinted note (Genie's secret touch).
struct ItineraryGenieSecretCreamSection: View {
    let touch: GenieSecretTouch

    var body: some View {
        if !touch.description.isEmpty {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: "sparkle")
                    .font(.system(size: 17))
                    .foregroundColor(Color.ydgHighlight)
                VStack(alignment: .leading, spacing: 4) {
                    Text(touch.title.isEmpty ? "A little extra" : touch.title)
                        .ydgText(.subhead, weight: .semibold)
                    Text(touch.description)
                        .ydgText(.subhead, weight: .regular, color: .ydgTextSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(YDGSpace.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.ydgHighlightSubtle, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .padding(.horizontal, YDGSpace.md)
            .padding(.vertical, 6)
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
                        : nil,
                    isFirst: index == 0,
                    isLast: index == itineraryStops.count - 1,
                    planDate: plan.scheduledDate
                )
            }

            ItineraryPlanFooterBlock(plan: plan)
            ItineraryGenieSecretCreamSection(touch: plan.genieSecretTouch)
            conversationStartersSection
            giftSuggestionsSection
            packingChips
            routeSection
        }
        .padding(.bottom, YDGSpace.xs)
    }

    @ViewBuilder
    private var conversationStartersSection: some View {
        if let starters = plan.conversationStarters, !starters.isEmpty {
            ItineraryCreamInsetSection(title: "Talk sparks", icon: "bubble.left") {
                ForEach(starters) { starter in
                    Text("\u{201C}\(starter.question)\u{201D}")
                        .font(.ydgDisplay(16, weight: .regular).italic())
                        .foregroundColor(Color.ydgTextPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    @ViewBuilder
    private var giftSuggestionsSection: some View {
        if let gifts = plan.giftSuggestions, !gifts.isEmpty {
            ItineraryCreamInsetSection(
                title: "Gift ideas",
                icon: "gift",
                trailing: {
                    if onGetMoreGiftIdeas != nil {
                        Button("More ideas") { onGetMoreGiftIdeas?() }
                            .font(.ydg(.footnote, weight: .semibold))
                            .foregroundColor(Color.ydgAccent)
                            .opacity(canAccessGiftIdeas ? 1 : 0.5)
                            .buttonStyle(.plain)
                    }
                },
                content: {
                    ForEach(gifts) { gift in
                        VStack(alignment: .leading, spacing: 3) {
                            HStack(alignment: .firstTextBaseline) {
                                Text(gift.name)
                                    .ydgText(.subhead, weight: .semibold)
                                Spacer(minLength: 8)
                                Text(gift.priceRange)
                                    .ydgText(.footnote, color: .ydgTextSecondary)
                            }
                            Text(gift.description)
                                .ydgText(.footnote, color: .ydgTextSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                            if !gift.whereToBuy.isEmpty {
                                Text("Where: \(gift.whereToBuy)")
                                    .ydgText(.footnote, color: .ydgTextTertiary)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            )
        }
    }

    @ViewBuilder
    private var packingChips: some View {
        if !plan.packingList.isEmpty {
            ItineraryCreamInsetSection(title: "Bring along", icon: "bag") {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(plan.packingList.prefix(6), id: \.self) { item in
                            HStack(spacing: 5) {
                                Image(systemName: ItineraryPlanFormatting.packingIcon(for: item))
                                    .font(.system(size: 11))
                                Text(item)
                                    .font(.ydg(.footnote, weight: .medium))
                            }
                            .foregroundColor(Color.ydgTextPrimary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(Color.ydgRaised))
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
                    Image(systemName: "map")
                        .font(.system(size: 15))
                    Text("View the route")
                        .font(.ydg(.callout, weight: .semibold))
                    Spacer(minLength: 0)
                    Text("\(itineraryStops.count) stops")
                        .ydgText(.footnote, color: .ydgTextSecondary)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color.ydgTextTertiary)
                }
                .foregroundColor(Color.ydgAccent)
                .padding(.horizontal, YDGSpace.md)
                .frame(minHeight: 52)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .overlay(alignment: .top) {
                Rectangle().fill(Color.ydgBorder).frame(height: 1)
            }
            .padding(.top, YDGSpace.xs)
        }
    }
}

/// Compact plan summary (share sheet, partner screens): header + time/name rows.
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
                ItineraryCompactStopList(stops: Array(itineraryStops.prefix(maxStops)))
                if itineraryStops.count > maxStops {
                    Text("+ \(itineraryStops.count - maxStops) more stop\(itineraryStops.count - maxStops == 1 ? "" : "s")")
                        .ydgText(.footnote, color: .ydgTextSecondary)
                        .padding(.horizontal, YDGSpace.md)
                        .padding(.vertical, YDGSpace.xs)
                }
                ItineraryPlanFooterBlock(plan: plan)
            }
        }
    }
}

/// Time | name + type rows with hairlines (pick-a-plan and preview cards).
struct ItineraryCompactStopList: View {
    let stops: [DatePlanStop]

    var body: some View {
        VStack(spacing: 0) {
            ForEach(stops) { stop in
                HStack(alignment: .top, spacing: YDGSpace.sm) {
                    Text(stop.timeSlot)
                        .font(.ydg(.footnote, weight: .semibold))
                        .foregroundColor(Color.ydgTextPrimary)
                        .monospacedDigit()
                        .frame(width: 66, alignment: .leading)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(stop.name)
                            .ydgText(.subhead, weight: .semibold)
                        if !stop.venueType.isEmpty {
                            Text(stop.venueType)
                                .ydgText(.footnote, color: .ydgTextSecondary)
                        }
                    }
                    Spacer(minLength: 0)
                }
                .padding(.vertical, 10)
                .overlay(alignment: .top) {
                    Rectangle().fill(Color.ydgBorder).frame(height: 1)
                }
            }
        }
        .padding(.horizontal, YDGSpace.md)
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
        ItineraryCreamCardChrome(edgePadding: edgePadding, surface: .cream) {
            VStack(alignment: .leading, spacing: 0) {
                LoveNoteGradientBanner(subtitle: bannerSubtitle)
                content()
            }
        }
    }
}

// MARK: - Itinerary hero card (Home: tonight's plan)

struct ItineraryHeroCard: View {
    let plan: DatePlan
    var partnerName: String?
    var onApprove: () -> Void
    var onSwap: () -> Void
    var onView: () -> Void

    private var itineraryStops: [DatePlanStop] {
        ItineraryPlanFormatting.itineraryStops(for: plan)
    }

    private var previewStops: [DatePlanStop] {
        Array(itineraryStops.prefix(3))
    }

    var body: some View {
        ItineraryCreamCardChrome {
            VStack(alignment: .leading, spacing: 0) {
                ItineraryGradientBanner(plan: plan)
                ItineraryPlanHeaderBlock(plan: plan, partnerName: partnerName)
                ItineraryCompactStopList(stops: previewStops)

                if itineraryStops.count > previewStops.count {
                    Text("+ \(itineraryStops.count - previewStops.count) more stop\(itineraryStops.count - previewStops.count == 1 ? "" : "s")")
                        .ydgText(.footnote, color: .ydgTextSecondary)
                        .padding(.horizontal, YDGSpace.md)
                        .padding(.vertical, YDGSpace.xs)
                }

                ItineraryPlanFooterBlock(plan: plan)

                VStack(spacing: YDGSpace.xs) {
                    HStack(spacing: YDGSpace.xs) {
                        Button("Swap a stop", action: onSwap)
                            .buttonStyle(YDGButtonStyle(kind: .secondary))
                        Button("Approve", action: onApprove)
                            .buttonStyle(.ydgPrimary)
                    }
                    Button("View full plan", action: onView)
                        .buttonStyle(.ydgTertiary)
                }
                .padding(.horizontal, YDGSpace.md)
                .padding(.top, YDGSpace.xs)
                .padding(.bottom, YDGSpace.sm)
            }
        }
    }
}

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
