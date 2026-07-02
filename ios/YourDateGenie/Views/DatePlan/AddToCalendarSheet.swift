import SwiftUI

/// Stable add-to-calendar sheet with local date state so parent re-renders
/// (home hero updates, coordinator sync) do not reset the graphical DatePicker.
struct AddToCalendarSheet: View {
    let plan: DatePlan
    let onDismiss: () -> Void
    let onResult: (CalendarService.AddResult, Date) -> Void

    @State private var selectedDate: Date
    @State private var isSubmitting = false

    init(
        plan: DatePlan,
        onDismiss: @escaping () -> Void,
        onResult: @escaping (CalendarService.AddResult, Date) -> Void
    ) {
        self.plan = plan
        self.onDismiss = onDismiss
        self.onResult = onResult

        let today = Calendar.current.startOfDay(for: Date())
        let seed = plan.scheduledDate ?? Date()
        let normalized = max(Calendar.current.startOfDay(for: seed), today)
        _selectedDate = State(initialValue: normalized)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Choose the date for your plan")
                    .font(Font.bodySans(15, weight: .medium))
                    .foregroundColor(Color.luxuryCreamMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)

                CreamGraphicalDatePicker(selection: $selectedDate)
                    .padding(.horizontal, 12)

                Button(action: submit) {
                    HStack(spacing: 10) {
                        if isSubmitting {
                            ProgressView()
                                .tint(Color.luxuryMaroon)
                        } else {
                            Image(systemName: "calendar.badge.plus")
                                .font(.system(size: 16))
                        }
                        Text("Add to Calendar")
                            .font(Font.bodySans(16, weight: .semibold))
                    }
                    .foregroundColor(Color.luxuryMaroon)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(LinearGradient.goldShimmer)
                    .cornerRadius(16)
                }
                .disabled(isSubmitting)
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
            }
            .padding(.top, 16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Color.backgroundPrimary)
            .navigationTitle("Add to Calendar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel", action: onDismiss)
                        .foregroundColor(Color.luxuryGold)
                        .disabled(isSubmitting)
                }
            }
            .toolbarBackground(Color.backgroundPrimary, for: .navigationBar)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled(isSubmitting)
    }

    private func submit() {
        guard !isSubmitting else { return }
        isSubmitting = true
        Task {
            let result = await CalendarSyncManager.shared.addDatePlan(plan, on: selectedDate)
            await MainActor.run {
                isSubmitting = false
                onResult(result, selectedDate)
            }
        }
    }
}
