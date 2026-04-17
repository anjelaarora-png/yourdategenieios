import SwiftUI

/// A bottom toast that appears for 5 seconds after a plan is deleted, offering an Undo action.
struct UndoSnackbarView: View {
    let message: String
    let onUndo: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "trash.fill")
                .font(.system(size: 16))
                .foregroundColor(Color.luxuryGold.opacity(0.8))

            Text(message)
                .font(Font.bodySans(14, weight: .regular))
                .foregroundColor(Color.luxuryCream)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                onUndo()
            } label: {
                Text("Undo")
                    .font(Font.bodySans(14, weight: .semibold))
                    .foregroundColor(Color.luxuryGold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.luxuryGold.opacity(0.15))
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.luxuryGold.opacity(0.4), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.luxuryMaroonLight)
                .shadow(color: Color.black.opacity(0.3), radius: 12, y: -4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.luxuryGold.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}
