import SwiftUI

// MARK: - Shared row (style 2: gold chips on dark maroon)

/// OpenTable / Resy / Call chips — shared by the single-venue sheet and the multi-venue reserve list.
///
/// Visibility rules:
/// - **OpenTable**: always shown for any restaurant (OpenTable operates in US/CA/UK/AU).
/// - **Resy**: shown only when (a) `reservationPlatforms` explicitly contains "resy",
///   OR (b) platforms is unknown/empty AND the address resolves to a city in Resy's network.
/// - **Call**: always shown; dials directly when a phone number is available, otherwise
///   opens a Google search for the venue's number so the chip is never missing.
struct ReservationPlatformActionRow: View {
    let venueName: String
    let phoneNumber: String?
    /// Full address used to detect whether Resy operates in this city.
    var address: String? = nil
    /// Confirmed booking platforms from AI / Google Places. nil = unknown (use city-based fallback).
    var reservationPlatforms: [String]? = nil
    /// Called after OpenTable, Resy, or Call (e.g. dismiss sheet).
    var onAction: () -> Void = {}

    // Resy is shown when explicitly confirmed, or when the city is in Resy's network and
    // platforms are unknown (never hidden just because we couldn't detect them).
    private var showResy: Bool {
        if let platforms = reservationPlatforms, !platforms.isEmpty {
            return platforms.contains("resy")
        }
        return OpenTableReservationSafari.isResySupported(for: address)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(venueName)
                .font(Font.inter(15, weight: .semibold))
                .foregroundColor(Color.luxuryCream)
                .fixedSize(horizontal: false, vertical: true)
            Text("Choose how you\'d like to book:")
                .font(Font.bodySans(13, weight: .regular))
                .foregroundColor(Color.luxuryMuted)

            VStack(spacing: 10) {
                Button {
                    OpenTableReservationSafari.openSearch(venueName: venueName)
                    onAction()
                } label: {
                    ResRowLabel(title: "OpenTable", detail: "Book online instantly", icon: "calendar.badge.plus")
                }
                .buttonStyle(ResOptionButtonStyle())
                .accessibilityLabel("Book on OpenTable")

                if showResy {
                    Button {
                        OpenTableReservationSafari.openResySearch(venueName: venueName)
                        onAction()
                    } label: {
                        ResRowLabel(title: "Resy", detail: "Alternative online booking", icon: "calendar.badge.plus")
                    }
                    .buttonStyle(ResOptionButtonStyle())
                    .accessibilityLabel("Book on Resy")
                }

                Button {
                    if let tel = OpenTableReservationSafari.sanitizedPhoneForTel(phoneNumber) {
                        if let url = URL(string: "tel:\(tel)") {
                            UIApplication.shared.open(url)
                        }
                    } else {
                        let query = "\(venueName) phone number"
                            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                        if let url = URL(string: "https://www.google.com/search?q=\(query)") {
                            UIApplication.shared.open(url)
                        }
                    }
                    onAction()
                } label: {
                    ResRowLabel(title: "Call", detail: "Speak directly with the restaurant", icon: "phone.fill")
                }
                .buttonStyle(ResOptionButtonStyle())
                .accessibilityLabel("Call the restaurant")
            }
        }
    }
}

// MARK: - Single-venue sheet (replaces system confirmationDialog)

/// Dark maroon sheet with the same styling as the multi-venue reserve picker.
struct ReservationPlatformPickerSheet: View {
    let payload: ReservationPlatformPickerPayload
    var onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                Color.luxuryMaroon.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Book via a reservation platform or call the restaurant directly.")
                            .font(Font.inter(14, weight: .medium))
                            .foregroundColor(Color.luxuryCreamMuted)
                            .fixedSize(horizontal: false, vertical: true)
                        ReservationPlatformActionRow(
                            venueName: payload.venueName,
                            phoneNumber: payload.phoneNumber,
                            address: payload.address,
                            reservationPlatforms: payload.reservationPlatforms,
                            onAction: onDismiss
                        )
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.luxuryMaroonLight.opacity(0.5))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.luxuryGold.opacity(0.28), lineWidth: 1)
                        )
                    }
                    .padding(20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Reserve")
                        .font(Font.tangerine(36, weight: .bold))
                        .foregroundColor(Color.luxuryGold)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { onDismiss() }
                        .foregroundColor(Color.luxuryGold)
                }
            }
            .toolbarBackground(Color.luxuryMaroon, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
}

// MARK: - Reservation row helpers

private struct ResRowLabel: View {
    let title: String
    let detail: String
    let icon: String
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color.luxuryGold)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Font.bodySans(15, weight: .semibold))
                    .foregroundColor(Color.luxuryCream)
                Text(detail)
                    .font(Font.bodySans(12, weight: .regular))
                    .foregroundColor(Color.luxuryMuted)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundColor(Color.luxuryMuted)
        }
    }
}

private struct ResOptionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(Color.luxuryMaroonLight.opacity(configuration.isPressed ? 0.9 : 0.7))
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.luxuryGold.opacity(0.3), lineWidth: 1))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
    }
}

