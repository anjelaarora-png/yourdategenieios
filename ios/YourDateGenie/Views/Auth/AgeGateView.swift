import SwiftUI

/// First-launch 18+ gate. Shown after splash and before onboarding / auth.
/// Under-18 users are blocked with no path into the app.
struct AgeGateView: View {
    var onConfirmed: () -> Void

    @State private var birthDate = AgeEligibility.defaultBirthDateSuggestion
    @State private var showUnderageBlock = false

    var body: some View {
        ZStack {
            Color.backgroundPrimary
                .ignoresSafeArea()

            RadialGradient.goldGlow
                .opacity(0.15)
                .ignoresSafeArea()

            if showUnderageBlock {
                underageContent
            } else {
                gateContent
            }
        }
    }

    private var gateContent: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 24)

            Image("Logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 96, height: 96)
                .shadow(color: Color.luxuryGold.opacity(0.35), radius: 16)

            Text("Age verification")
                .font(Font.bodySerif(28, weight: .bold))
                .foregroundColor(Color.luxuryGold)
                .padding(.top, 20)

            Text("Your Date Genie is for adults only. You must be \(AgeEligibility.minimumAge) or older to continue.")
                .font(Font.bodySans(15, weight: .regular))
                .foregroundColor(Color.luxuryCreamMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.top, 10)

            VStack(alignment: .leading, spacing: 10) {
                Text("Date of birth")
                    .font(Font.bodySans(13, weight: .medium))
                    .foregroundColor(Color.luxuryMuted)

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
                .frame(height: 140)
                .clipped()
            }
            .padding(18)
            .background(Color.luxeSurfaceTint)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.luxuryGold.opacity(0.25), lineWidth: 1)
            )
            .padding(.horizontal, 24)
            .padding(.top, 28)

            Button {
                confirmAge()
            } label: {
                Text("Continue")
                    .font(Font.bodySans(16, weight: .semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(LuxuryGoldButtonStyle())
            .padding(.horizontal, 24)
            .padding(.top, 24)

            Text("By continuing, you confirm your date of birth is accurate.")
                .font(Font.bodySans(12, weight: .regular))
                .foregroundColor(Color.luxuryMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.top, 14)

            Spacer(minLength: 40)
        }
    }

    private var underageContent: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "hand.raised.fill")
                .font(.system(size: 44))
                .foregroundColor(Color.luxuryGold)

            Text("Sorry — you must be \(AgeEligibility.minimumAge)+")
                .font(Font.bodySerif(26, weight: .bold))
                .foregroundColor(Color.luxuryGold)
                .multilineTextAlignment(.center)

            Text("Your Date Genie is only available to users who are \(AgeEligibility.minimumAge) years of age or older. Please come back when you’re eligible.")
                .font(Font.bodySans(15, weight: .regular))
                .foregroundColor(Color.luxuryCreamMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    showUnderageBlock = false
                }
            } label: {
                Text("Go back")
                    .font(Font.bodySans(15, weight: .medium))
                    .foregroundColor(Color.luxuryGold)
            }
            .padding(.top, 8)

            Spacer()
        }
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
