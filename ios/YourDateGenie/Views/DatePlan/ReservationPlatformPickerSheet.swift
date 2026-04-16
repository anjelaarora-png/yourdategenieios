import SwiftUI

// MARK: - Shared row (style 2: gold chips on dark maroon)

/// OpenTable / Resy / Call chips — shared by the single-venue sheet and the multi-venue reserve list.
/// Call is always shown: dials directly when a phone number is available, otherwise opens a
/// Google search for the venue's number so the chip is never missing.
struct ReservationPlatformActionRow: View {
    let venueName: String
    let phoneNumber: String?
    /// Called after OpenTable, Resy, or Call (e.g. dismiss sheet).
    var onAction: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(venueName)
                .font(Font.inter(15, weight: .semibold))
                .foregroundColor(Color.luxuryCream)
                .fixedSize(horizontal: false, vertical: true)
            HStack(alignment: .center, spacing: 8) {
                Button {
                    OpenTableReservationSafari.openSearch(venueName: venueName)
                    onAction()
                } label: {
                    Text("OpenTable")
                }
                .buttonStyle(LuxuryReservationPlatformButtonStyle())

                Button {
                    OpenTableReservationSafari.openResySearch(venueName: venueName)
                    onAction()
                } label: {
                    Text("Resy")
                }
                .buttonStyle(LuxuryReservationPlatformButtonStyle())

                // Always show Call: dial directly when we have a number, otherwise search Google
                // for the restaurant's phone so the chip is never absent.
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
                    Text("Call")
                }
                .buttonStyle(LuxuryReservationPlatformButtonStyle())
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
                        Text("Search on OpenTable or Resy, or call the restaurant.")
                            .font(Font.inter(14, weight: .medium))
                            .foregroundColor(Color.luxuryCreamMuted)
                            .fixedSize(horizontal: false, vertical: true)
                        ReservationPlatformActionRow(
                            venueName: payload.venueName,
                            phoneNumber: payload.phoneNumber,
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
