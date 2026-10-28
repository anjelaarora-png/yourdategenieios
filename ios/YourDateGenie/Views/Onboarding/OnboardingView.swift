import SwiftUI

// MARK: - Intro (final design 1.3)
//
// One screen instead of a carousel: the promise, a sample of what a finished
// night looks like, and two ways forward.
struct MobileOnboardingView: View {
    @EnvironmentObject var coordinator: NavigationCoordinator
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    var body: some View {
        ZStack {
            Color.ydgBase
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: YDGSpace.lg) {
                        Image(systemName: "person.2")
                            .font(.system(size: 26, weight: .regular))
                            .foregroundColor(Color.ydgAccent)
                            .accessibilityHidden(true)

                        VStack(alignment: .leading, spacing: YDGSpace.sm) {
                            Text("Date night, without the group chat.")
                                .ydgText(.title1)
                                .fixedSize(horizontal: false, vertical: true)
                                .accessibilityAddTraits(.isHeader)
                            Text("Tell us the vibe. We plan the whole night: venues that are open, timing that works, and a route between them.")
                                .ydgText(.body, color: .ydgTextSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        sampleNightCard
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 12)
                    }
                    .padding(.horizontal, YDGSpace.margin)
                    .padding(.top, YDGSpace.xl)
                    .padding(.bottom, YDGSpace.lg)
                }

                VStack(spacing: YDGSpace.xs) {
                    Button("Plan my first date") {
                        coordinator.completeOnboarding()
                    }
                    .buttonStyle(.ydgPrimary)

                    Button("I already have an account") {
                        coordinator.completeOnboarding()
                        coordinator.consumePreferSignUpTab()
                    }
                    .buttonStyle(.ydgTertiary)
                }
                .padding(.horizontal, YDGSpace.margin)
                .padding(.bottom, YDGSpace.xs)
            }
        }
        .onAppear {
            if reduceMotion {
                appeared = true
            } else {
                withAnimation(.easeOut(duration: 0.5).delay(0.15)) { appeared = true }
            }
        }
    }

    // MARK: Sample itinerary — what you get

    private struct SampleStop: Identifiable {
        let id = UUID()
        let time: String
        let name: String
        let detail: String
    }

    private let sampleStops: [SampleStop] = [
        SampleStop(time: "7:00 PM", name: "Lilia", detail: "Pasta, Williamsburg"),
        SampleStop(time: "8:45 PM", name: "Westlight", detail: "Rooftop cocktails · 8 min walk"),
        SampleStop(time: "10:15 PM", name: "Domino Park", detail: "Skyline walk · 6 min walk")
    ]

    private var sampleNightCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Friday · Oct 30")
                    .ydgText(.caption)
                Spacer()
                Text("3.4 hours")
                    .ydgText(.footnote, color: .ydgTextSecondary)
            }
            .padding(.bottom, YDGSpace.sm)

            ForEach(sampleStops) { stop in
                Rectangle().fill(Color.ydgBorder).frame(height: 1)
                HStack(alignment: .center, spacing: YDGSpace.md) {
                    Text(stop.time)
                        .ydgText(.subhead, weight: .medium)
                        .frame(width: 72, alignment: .leading)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(stop.name)
                            .ydgText(.body, weight: .medium)
                        Text(stop.detail)
                            .ydgText(.footnote, color: .ydgTextSecondary)
                    }
                    Spacer(minLength: 0)
                }
                .padding(.vertical, YDGSpace.sm)
            }
        }
        .ydgCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Example plan: Lilia at 7 PM, Westlight at 8:45, Domino Park at 10:15.")
    }
}

#Preview {
    MobileOnboardingView()
        .environmentObject(NavigationCoordinator.shared)
}
