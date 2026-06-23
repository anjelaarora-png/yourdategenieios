import SwiftUI

// MARK: - Shared row (style 2: gold chips on dark maroon)

/// OpenTable / Resy / Call chips — shared by the single-venue sheet and the multi-venue reserve list.
///
/// Visibility rules:
/// - **OpenTable**: shown only when `reservationPlatforms` contains "opentable", OR when
///   `bookingUrl` is an OpenTable URL. Never shown speculatively — this prevents the
///   OpenTable app from intercepting the URL and displaying a generic "near you" home screen.
/// - **Resy**: shown only when `reservationPlatforms` contains "resy", OR when `bookingUrl`
///   is a Resy URL.
/// - **Call**: always shown; dials directly when a phone number is available, otherwise
///   opens a Google search for the venue\'s number so the chip is never missing.
struct ReservationPlatformActionRow: View {
    let venueName: String
    let phoneNumber: String?
    /// Full address (kept for display purposes).
    var address: String? = nil
    /// Confirmed booking platforms from AI / Google Places. Buttons are only shown for listed platforms.
    var reservationPlatforms: [String]? = nil
    /// Direct booking URL (OpenTable restref, Resy venue page, etc.).
    var bookingUrl: String? = nil
    /// Called after any action (e.g. dismiss sheet).
    var onAction: () -> Void = {}

    private func platformFromUrl(_ url: String?) -> String? {
        guard let url = url?.lowercased() else { return nil }
        if url.contains("opentable.") { return "opentable" }
        if url.contains("resy.com") { return "resy" }
        return nil
    }

    /// Show OpenTable only when we have confirmed evidence the restaurant is listed there.
    private var showOpenTable: Bool {
        if let platforms = reservationPlatforms, !platforms.isEmpty {
            return platforms.contains("opentable")
        }
        return platformFromUrl(bookingUrl) == "opentable"
    }

    /// Show Resy only when we have confirmed evidence the restaurant is listed there.
    private var showResy: Bool {
        if let platforms = reservationPlatforms, !platforms.isEmpty {
            return platforms.contains("resy")
        }
        return platformFromUrl(bookingUrl) == "resy"
    }

    /// Opens the direct booking URL via in-app Safari when it matches the platform,
    /// otherwise falls back to a pre-filled search — also via in-app Safari so the
    /// platform app cannot intercept and ignore the search parameters.
    private func openPlatform(_ platformId: String) {
        let directPlatform = platformFromUrl(bookingUrl)
        if directPlatform == platformId, let urlStr = bookingUrl, let url = URL(string: urlStr) {
            OpenTableReservationSafari.openInSafari(url)
        } else if platformId == "opentable" {
            OpenTableReservationSafari.openSearch(venueName: venueName)
        } else if platformId == "resy" {
            OpenTableReservationSafari.openResySearch(venueName: venueName)
        }
        onAction()
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
                if showOpenTable {
                    Button {
                        openPlatform("opentable")
                    } label: {
                        ResRowLabel(title: "OpenTable", detail: "Book online", icon: "calendar.badge.plus")
                    }
                    .buttonStyle(ResOptionButtonStyle())
                    .accessibilityLabel("Book on OpenTable")
                }

                if showResy {
                    Button {
                        openPlatform("resy")
                    } label: {
                        ResRowLabel(title: "Resy", detail: "Book online", icon: "calendar.badge.plus")
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
                Color.backgroundPrimary.ignoresSafeArea()
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
                            bookingUrl: payload.bookingUrl,
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
                        .font(Font.displaySerif(22, weight: .bold))
                        .foregroundColor(Color.luxuryGold)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { onDismiss() }
                        .foregroundColor(Color.luxuryGold)
                }
            }
            .toolbarBackground(Color.backgroundPrimary, for: .navigationBar)
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

