import SwiftUI

/// Reusable "When's your date?" sheet that gates plan saving behind an explicit
/// date selection. Pre-selects the nearest upcoming Saturday. Past dates are
/// blocked by constraining the DatePicker range to today and forward.
struct DatePickerSheet: View {
    let planTitle: String
    let onConfirm: (Date) -> Void
    let onCancel: () -> Void

    @State private var selectedDate: Date

    init(planTitle: String,
         onConfirm: @escaping (Date) -> Void,
         onCancel: @escaping () -> Void) {
        self.planTitle = planTitle
        self.onConfirm = onConfirm
        self.onCancel = onCancel
        self._selectedDate = State(initialValue: DatePickerSheet.nextSaturday())
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.luxuryMaroon.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 28) {
                        headerView
                        datePicker
                        actionButtons
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.luxuryMaroon, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: onCancel) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color.luxuryGold)
                    }
                }
            }
        }
    }

    // MARK: - Subviews

    private var headerView: some View {
        VStack(spacing: 6) {
            Text("When's your date?")
                .font(Font.tangerine(32, weight: .bold))
                .italic()
                .foregroundColor(Color.luxuryGold)
            Text("Pick the day you'll go on \"\(planTitle)\"")
                .font(Font.bodySans(14, weight: .regular))
                .foregroundColor(Color.luxuryCreamMuted)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
    }

    private var datePicker: some View {
        DatePicker(
            "Date",
            selection: $selectedDate,
            in: Calendar.current.startOfDay(for: Date())...,
            displayedComponents: .date
        )
        .datePickerStyle(.graphical)
        .tint(Color.luxuryGold)
        .padding(.horizontal)
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                onConfirm(selectedDate)
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "bookmark.fill")
                        .font(.system(size: 16))
                    Text("Confirm & Save Plan")
                        .font(Font.bodySans(16, weight: .semibold))
                }
                .foregroundColor(Color.luxuryMaroon)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Capsule().fill(LinearGradient.goldShimmer))
            }

            Button(action: onCancel) {
                Text("Cancel")
                    .font(Font.bodySans(15, weight: .medium))
                    .foregroundColor(Color.luxuryGold.opacity(0.8))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        Capsule()
                            .stroke(Color.luxuryGold.opacity(0.35), lineWidth: 1)
                    )
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 32)
    }

    // MARK: - Next Saturday Helper

    /// Returns the nearest upcoming Saturday, skipping today even if it is Saturday.
    static func nextSaturday(from date: Date = Date()) -> Date {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        // weekday: 1=Sun, 2=Mon, ..., 7=Sat
        let daysUntilSaturday = (7 - weekday + 7) % 7
        let offset = daysUntilSaturday == 0 ? 7 : daysUntilSaturday
        return calendar.date(byAdding: .day, value: offset, to: calendar.startOfDay(for: date)) ?? date
    }
}
