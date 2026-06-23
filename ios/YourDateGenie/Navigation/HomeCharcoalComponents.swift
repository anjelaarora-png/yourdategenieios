import SwiftUI

// MARK: - Collapsible home section (Charcoal Maroon IA)

struct CollapsibleHomeSection<Content: View>: View {
    let title: String
    var subtitle: String? = nil
    @Binding var isExpanded: Bool
    @ViewBuilder var content: () -> Content

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

// MARK: - Itinerary hero card (cream card, maroon left border)

struct ItineraryHeroCard: View {
    let plan: DatePlan
    var partnerName: String?
    var onApprove: () -> Void
    var onSwap: () -> Void
    var onView: () -> Void

    private var locationLabel: String {
        let loc = MapURLHelper.cityStateOrRegionFromAddress(plan.stops.first?.address)
        return loc.isEmpty ? plan.title : loc
    }

    private var scheduleLabel: String {
        if let d = plan.scheduledDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return formatter.string(from: d)
        }
        return plan.tagline
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                LinearGradient(
                    colors: [Color(hex: "5C3A2E"), Color(hex: "8B5E4A"), Color(hex: "4A3028")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(height: 72)

                Text("\(locationLabel) · \(scheduleLabel)")
                    .font(Font.bodySans(10, weight: .semibold))
                    .tracking(0.6)
                    .textCase(.uppercase)
                    .foregroundColor(Color.white.opacity(0.85))
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)
            }

            VStack(alignment: .leading, spacing: 6) {
                if let partner = partnerName, !partner.isEmpty {
                    Text("For you & \(partner)")
                        .font(Font.bodySans(11, weight: .regular))
                        .foregroundColor(Color.textMutedOnCard)
                }
                Text(plan.title)
                    .font(Font.bodySerif(17, weight: .regular))
                    .foregroundColor(Color.textOnCard)
                Text(metaLine)
                    .font(Font.bodySans(11, weight: .regular))
                    .foregroundColor(Color.textMutedOnCard)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            ForEach(Array(plan.stops.prefix(3))) { stop in
                stopRow(stop)
            }

            if !footerLine.isEmpty {
                Text(footerLine)
                    .font(Font.bodySans(12, weight: .regular))
                    .foregroundColor(Color(hex: "9A9690"))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .overlay(alignment: .top) {
                        Rectangle().fill(Color.black.opacity(0.06)).frame(height: 1)
                    }
            }

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
        .padding(.horizontal, 20)
    }

    private var metaLine: String {
        let time = plan.stops.first?.timeSlot ?? ""
        let stops = "\(plan.stops.count) stop\(plan.stops.count == 1 ? "" : "s")"
        let cost = plan.estimatedCost.isEmpty ? "" : " · \(plan.estimatedCost) est."
        if time.isEmpty { return "\(stops)\(cost)" }
        return "\(time) · \(stops)\(cost)"
    }

    private var footerLine: String {
        var parts: [String] = []
        if !plan.totalDuration.isEmpty { parts.append("Est. \(plan.totalDuration)") }
        if !plan.weatherNote.isEmpty { parts.append(plan.weatherNote) }
        return parts.joined(separator: " · ")
    }

    @ViewBuilder
    private func stopRow(_ stop: DatePlanStop) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(stop.timeSlot)
                .font(Font.bodySans(12, weight: .semibold))
                .foregroundColor(Color.textOnCard)
                .frame(minWidth: 38, alignment: .leading)
            VStack(alignment: .leading, spacing: 2) {
                Text(stop.name)
                    .font(Font.bodySans(13, weight: .medium))
                    .foregroundColor(Color.textOnCard)
                Text(stopDetail(stop))
                    .font(Font.bodySans(11, weight: .regular))
                    .foregroundColor(Color.textMutedOnCard)
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 9)
        .overlay(alignment: .top) {
            Rectangle().fill(Color.black.opacity(0.06)).frame(height: 1)
        }
    }

    private func stopDetail(_ stop: DatePlanStop) -> String {
        if !stop.description.isEmpty && stop.description.count < 72 {
            return stop.description
        }
        if !stop.venueType.isEmpty { return stop.venueType }
        if let travel = stop.travelTimeFromPrevious, !travel.isEmpty {
            return "\(travel) · next stop"
        }
        return stop.address ?? ""
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

    static func alternatives(for stop: DatePlanStop) -> [SwapStopAlternative] {
        let area = MapURLHelper.cityStateOrRegionFromAddress(stop.address)
        let current = SwapStopAlternative(
            id: "current",
            name: stop.name,
            venueType: stop.venueType.isEmpty ? "Restaurant" : stop.venueType,
            address: stop.address ?? area,
            detail: formattedDetail(venueType: stop.venueType, address: stop.address, tag: "current"),
            isCurrent: true
        )
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

            ForEach(SwapStopLogic.alternatives(for: stop)) { option in
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
                    .background(Color.white.opacity(0.03))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
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
            address: alternative.address
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
