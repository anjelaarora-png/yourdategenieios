import SwiftUI

/// Shown at the top of the app when the device has no network connection.
struct OfflineBannerView: View {
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color.luxuryCream)
            Text("No internet connection")
                .font(Font.bodySans(14, weight: .medium))
                .foregroundColor(Color.luxuryCream)
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(Color.luxuryMaroonLight)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.luxuryGold.opacity(0.3)),
            alignment: .bottom
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No internet connection. Some features may not be available.")
    }
}
