import SwiftUI

// MARK: - Report a Concern (Apple §1.2)

struct ReportConcernView: View {
    @Environment(\.dismiss) private var dismiss

    var reportedUserId: String? = nil

    @State private var category: ReportCategory = .other
    @State private var description: String = ""
    @State private var isSubmitting = false
    @State private var submitError: String?
    @State private var didSucceed = false

    enum ReportCategory: String, CaseIterable, Identifiable {
        case harassment          = "harassment"
        case inappropriateContent = "inappropriate_content"
        case spam                = "spam"
        case safety              = "safety"
        case other               = "other"

        var id: String { rawValue }

        var displayLabel: String {
            switch self {
            case .harassment:           return "Harassment"
            case .inappropriateContent: return "Inappropriate content"
            case .spam:                 return "Spam"
            case .safety:               return "Safety concern"
            case .other:                return "Other"
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.backgroundPrimary.ignoresSafeArea()

                if didSucceed {
                    successView
                } else {
                    formView
                }
            }
            .navigationTitle("Report a Concern")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.backgroundPrimary, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .font(Font.bodySans(15, weight: .medium))
                        .foregroundColor(Color.luxuryGold)
                }
            }
        }
    }

    // MARK: - Form

    private var formView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Context note
                Text("Your report is confidential. We review all reports within 48 hours and take appropriate action.")
                    .font(Font.bodySans(13, weight: .regular))
                    .foregroundColor(Color.luxuryCreamMuted)
                    .fixedSize(horizontal: false, vertical: true)

                // Category picker
                VStack(alignment: .leading, spacing: 10) {
                    Text("What best describes your concern?")
                        .font(Font.bodySans(14, weight: .semibold))
                        .foregroundColor(Color.luxuryGold)

                    VStack(spacing: 0) {
                        ForEach(ReportCategory.allCases) { cat in
                            Button {
                                category = cat
                            } label: {
                                HStack {
                                    Text(cat.displayLabel)
                                        .font(Font.bodySans(15, weight: .regular))
                                        .foregroundColor(Color.luxuryCream)
                                    Spacer()
                                    if category == cat {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(Color.luxuryGold)
                                    } else {
                                        Image(systemName: "circle")
                                            .foregroundColor(Color.luxuryMuted)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                            }
                            .buttonStyle(.plain)

                            if cat != ReportCategory.allCases.last {
                                Divider()
                                    .background(Color.luxuryGold.opacity(0.15))
                            }
                        }
                    }
                    .background(Color.luxuryMaroonLight)
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.luxuryGold.opacity(0.25), lineWidth: 1)
                    )
                }

                // Description field
                VStack(alignment: .leading, spacing: 10) {
                    Text("Describe what happened")
                        .font(Font.bodySans(14, weight: .semibold))
                        .foregroundColor(Color.luxuryGold)

                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $description)
                            .font(Font.bodySans(15, weight: .regular))
                            .foregroundColor(Color.luxuryCream)
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 120)
                            .padding(12)
                            .background(Color.luxuryMaroonLight)
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(description.isEmpty ? Color.luxuryGold.opacity(0.25) : Color.luxuryGold.opacity(0.5), lineWidth: 1)
                            )

                        if description.isEmpty {
                            Text("Please describe what happened so we can investigate…")
                                .font(Font.bodySans(15, weight: .regular))
                                .foregroundColor(Color.luxuryMuted.opacity(0.5))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 20)
                                .allowsHitTesting(false)
                        }
                    }
                }

                // Error message
                if let error = submitError {
                    Text(error)
                        .font(Font.bodySans(13, weight: .regular))
                        .foregroundColor(Color.red.opacity(0.9))
                        .fixedSize(horizontal: false, vertical: true)
                }

                // Submit button
                Button {
                    submitReport()
                } label: {
                    HStack {
                        if isSubmitting {
                            ProgressView()
                                .tint(Color.luxuryMaroon)
                                .padding(.trailing, 4)
                        }
                        Text(isSubmitting ? "Submitting…" : "Submit Report")
                            .font(Font.bodySans(16, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmitting
                        ? Color.luxuryGold.opacity(0.35)
                        : Color.luxuryGold)
                    .foregroundColor(Color.luxuryMaroon)
                    .cornerRadius(14)
                }
                .buttonStyle(.plain)
                .disabled(description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmitting)
            }
            .padding(20)
        }
    }

    // MARK: - Success

    private var successView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 54))
                .foregroundColor(Color.luxuryGold)
            Text("Report submitted")
                .font(Font.header(22, weight: .semibold))
                .foregroundColor(Color.luxuryCream)
            Text("Thank you. We'll review your report within 48 hours and take appropriate action.")
                .font(Font.bodySans(14, weight: .regular))
                .foregroundColor(Color.luxuryCreamMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button("Done") { dismiss() }
                .font(Font.bodySans(16, weight: .semibold))
                .foregroundColor(Color.luxuryMaroon)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.luxuryGold)
                .cornerRadius(14)
                .padding(.horizontal, 40)
                .padding(.top, 8)
                .buttonStyle(.plain)
            Spacer()
        }
    }

    // MARK: - Submit

    private func submitReport() {
        let trimmed = description.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        isSubmitting = true
        submitError = nil
        Task {
            do {
                try await SupabaseService.shared.submitReport(
                    reportedUserId: reportedUserId,
                    category: category.rawValue,
                    description: trimmed
                )
                await MainActor.run {
                    isSubmitting = false
                    didSucceed = true
                }
            } catch {
                await MainActor.run {
                    submitError = "Something went wrong. Please try again or email hello@yourdategenie.com."
                    isSubmitting = false
                }
            }
        }
    }
}

#Preview {
    ReportConcernView()
}
