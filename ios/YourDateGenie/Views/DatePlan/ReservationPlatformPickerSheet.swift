import SwiftUI

// MARK: - Shared row (style 2: gold chips on dark maroon)

/// OpenTable / Resy / Call chips — shared by the single-venue sheet and the multi-venue reserve list.
struct ReservationPlatformActionRow: View {
    let venueName: String
    let phoneNumber: String?
    /// Called after OpenTable, Resy, or Call (e.g. dismiss sheet).
    var onAction: () -> Void = {}

    /// Dismissing the reservation sheet in the same run loop as `present(SFSafariViewController)` cancels the in-app Safari presentation.
    private func dismissAfterOpeningPlatformLink() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            onAction()
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(venueName)
                .font(Font.inter(15, weight: .semibold))
                .foregroundColor(Color.luxuryCream)
                .fixedSize(horizontal: false, vertical: true)
            HStack(alignment: .center, spacing: 8) {
                Button {
                    OpenTableReservationSafari.openSearch(venueName: venueName)
                    dismissAfterOpeningPlatformLink()
                } label: {
                    Text("OpenTable")
                }
                .buttonStyle(LuxuryReservationPlatformButtonStyle())
                Button {
                    OpenTableReservationSafari.openResySearch(venueName: venueName)
                    dismissAfterOpeningPlatformLink()
                } label: {
                    Text("Resy")
                }
                .buttonStyle(LuxuryReservationPlatformButtonStyle())
                if OpenTableReservationSafari.sanitizedPhoneForTel(phoneNumber) != nil {
                    Button {
                        OpenTableReservationSafari.openPhoneCall(phoneNumber: phoneNumber ?? "")
                        dismissAfterOpeningPlatformLink()
                    } label: {
                        Text("Call")
                    }
                    .buttonStyle(LuxuryReservationPlatformButtonStyle())
                }
            }
        }
    }
}

// MARK: - Single-venue sheet (replaces system confirmationDialog)

/// Dark maroon sheet with the same styling as the multi-venue reserve picker.
struct ReservationPlatformPickerSheet: View {
    let payload: ReservationPlatformPickerPayload
    var onDismiss: () -> Void

    private var helperText: String {
        if OpenTableReservationSafari.sanitizedPhoneForTel(payload.phoneNumber) != nil {
            return "Search on OpenTable or Resy, or call the restaurant."
        }
        return "Search for a table on OpenTable or Resy."
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.luxuryMaroon.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text(helperText)
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
                        .font(Font.tangerine(22, weight: .bold))
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
