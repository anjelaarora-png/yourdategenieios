import SwiftUI

/// First-launch 18+ gate. Shown after splash and before onboarding / auth.
/// Under-18 users are blocked with no path into the app.
struct AgeGateView: View {
    var onConfirmed: () -> Void

    @State private var birthDate = AgeEligibility.defaultBirthDateSuggestion
    @State private var showUnderageBlock = false

    var body: some View {
        ZStack {
            Color.ydgBase
                .ignoresSafeArea()

            if showUnderageBlock {
                underageContent
            } else {
                gateContent
            }
        }
    }

    private var gateContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: YDGSpace.xs) {
                Text("Age verification")
                    .ydgText(.caption)
                Text("When's your birthday?")
                    .ydgText(.title1)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                Text("Your Date Genie is for adults only. You must be \(AgeEligibility.minimumAge) or older to continue.")
                    .ydgText(.body, color: .ydgTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, YDGSpace.xxl)

            DatePicker(
                "Date of birth",
                selection: $birthDate,
                in: ...Date(),
                displayedComponents: .date
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .colorScheme(.dark)
            .frame(maxWidth: .infinity)
            .padding(.top, YDGSpace.xl)

            Spacer(minLength: YDGSpace.lg)

            Button("Continue") {
                confirmAge()
            }
            .buttonStyle(.ydgPrimary)

            Text("By continuing, you confirm your date of birth is accurate.")
                .ydgText(.footnote, color: .ydgTextTertiary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.top, YDGSpace.sm)
        }
        .padding(.horizontal, YDGSpace.margin)
        .padding(.bottom, YDGSpace.md)
    }

    private var underageContent: some View {
        VStack(alignment: .leading, spacing: YDGSpace.md) {
            Spacer()

            Image(systemName: "hand.raised")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(Color.ydgHighlight)
                .frame(width: 56, height: 56)
                .background(Circle().fill(Color.ydgHighlightSubtle))
                .accessibilityHidden(true)

            Text("Sorry, you must be \(AgeEligibility.minimumAge) or older")
                .ydgText(.title1)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)

            Text("Your Date Genie is only available to people who are \(AgeEligibility.minimumAge) or older. Please come back when you're eligible.")
                .ydgText(.body, color: .ydgTextSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()

            Button("Go back") {
                withAnimation(.easeInOut(duration: 0.25)) {
                    showUnderageBlock = false
                }
            }
            .buttonStyle(.ydgSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, YDGSpace.margin)
        .padding(.bottom, YDGSpace.md)
    }

    private func confirmAge() {
        if AgeEligibility.isAtLeastMinimumAge(birthDate) {
            AgeEligibility.markConfirmedAdult()
            onConfirmed()
        } else {
            withAnimation(.easeInOut(duration: 0.25)) {
                showUnderageBlock = true
            }
        }
    }
}

#Preview {
    AgeGateView(onConfirmed: {})
}
