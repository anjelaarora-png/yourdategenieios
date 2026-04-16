import SwiftUI
import UIKit

// MARK: - DateExperienceViewModel

@MainActor
final class DateExperienceViewModel: ObservableObject {
    @Published private(set) var experiences: [DateExperience] = []
    @Published private(set) var isLoading = false
    @Published private(set) var fetchError: String? = nil

    func fetchExperiences() async {
        guard !isLoading else { return }
        isLoading = true
        fetchError = nil

        do {
            let results: [DateExperience] = try await SupabaseManager.shared.client
                .from("events")
                .select()
                .eq("is_active", value: true)
                .order("date_time", ascending: true)
                .execute()
                .value
            experiences = results
        } catch {
            fetchError = error.localizedDescription
        }

        isLoading = false
    }
}

// MARK: - Shimmer Modifier

private struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: .clear, location: max(0, phase - 0.3)),
                            .init(color: Color.white.opacity(0.18), location: phase),
                            .init(color: .clear, location: min(1, phase + 0.3))
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geo.size.width * 2)
                    .offset(x: -geo.size.width + geo.size.width * 2 * phase)
                }
                .clipped()
            )
            .onAppear {
                withAnimation(
                    Animation.linear(duration: 1.4)
                        .repeatForever(autoreverses: false)
                ) {
                    phase = 1.2
                }
            }
    }
}

private extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

// MARK: - Skeleton Card (loading state)

private struct EventSkeletonCard: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 18)
            .fill(Color(hex: "5B0A0A").opacity(0.8))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color(hex: "E8C27D").opacity(0.2), lineWidth: 1)
            )
            .frame(width: 280, height: 160)
            .shimmer()
    }
}

// MARK: - Event Card

struct EventCardView: View {
    let experience: DateExperience
    let onTap: () -> Void

    @State private var isPressed = false
    @State private var appeared = false

    var body: some View {
        Button {
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            onTap()
        } label: {
            cardContent
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.96 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 14)
        .onAppear {
            withAnimation(.easeOut(duration: 0.45)) {
                appeared = true
            }
        }
        // Subtle gold glow
        .shadow(color: Color(hex: "E8C27D").opacity(0.22), radius: 14, x: 0, y: 6)
    }

    private var cardContent: some View {
        ZStack(alignment: .bottom) {
            // Background image
            AsyncImage(url: URL(string: experience.imageUrl)) { phase in
                switch phase {
                case .success(let img):
                    img.resizable().aspectRatio(contentMode: .fill)
                case .empty, .failure:
                    LinearGradient(
                        colors: [Color(hex: "5B0A0A"), Color(hex: "7A0F0F")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                @unknown default:
                    EmptyView()
                }
            }
            .frame(width: 280, height: 160)
            .clipped()

            // Dark card overlay
            Color.black.opacity(0.35)

            // Bottom-heavy gradient for text legibility
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: .clear, location: 0),
                    .init(color: .clear, location: 0.35),
                    .init(color: Color.black.opacity(0.75), location: 1.0)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )

            // Bottom-left: title + date/location
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(experience.title)
                        .font(Font.header(15, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("\(experience.formattedDate) · \(experience.location)")
                        .font(Font.bodySans(11, weight: .regular))
                        .foregroundColor(Color(hex: "EADBC8"))
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                // Bottom-right CTA
                Text(experience.ctaLabel)
                    .font(Font.bodySans(12, weight: .semibold))
                    .foregroundColor(Color(hex: "1A0A0A"))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "E8C27D"), Color(hex: "F3D9A4")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 12)
        }
        .frame(width: 280, height: 160)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color(hex: "E8C27D").opacity(0.25), lineWidth: 1)
        )
        // Top-right badge
        .overlay(alignment: .topTrailing) {
            Text(experience.badgeLabel)
                .font(Font.bodySans(10, weight: .semibold))
                .tracking(0.8)
                .foregroundColor(Color(hex: "1A0A0A"))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "E8C27D"), Color(hex: "F3D9A4")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
                .padding(.top, 12)
                .padding(.trailing, 12)
        }
    }
}

// MARK: - Date Experiences Section

struct DateExperiencesSection: View {
    @StateObject private var viewModel = DateExperienceViewModel()
    @State private var selectedExperience: DateExperience? = nil
    @State private var showImportSheet = false
    @State private var appeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader
            scrollContent
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                appeared = true
            }
            Task { await viewModel.fetchExperiences() }
        }
        .sheet(item: $selectedExperience) { experience in
            EventDetailView(experience: experience)
        }
        .sheet(isPresented: $showImportSheet) {
            EventImportView {
                // Refresh the section after a new event is saved
                Task { await viewModel.fetchExperiences() }
            }
        }
    }

    // MARK: Section Header

    private var sectionHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .center, spacing: 0) {
                HStack(spacing: 6) {
                    Text("Date")
                        .font(Font.tangerine(32, weight: .bold))
                        .italic()
                        .foregroundColor(Color.luxuryGold)
                    Text("Experiences")
                        .font(Font.tangerine(32, weight: .bold))
                        .italic()
                        .foregroundColor(Color.luxuryGold)
                }

                Spacer(minLength: 8)

                // Import button — tap to add an event from an Eventbrite link
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    showImportSheet = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .semibold))
                        Text("Add")
                            .font(Font.bodySans(12, weight: .semibold))
                    }
                    .foregroundColor(Color(hex: "1A0A0A"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "E8C27D"), Color(hex: "F3D9A4")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }

            Text("Curated evenings designed for unforgettable connections")
                .font(Font.bodySans(13, weight: .regular))
                .foregroundColor(Color.luxuryCreamMuted)
        }
        .padding(.horizontal, 20)
    }

    // MARK: Scroll Content

    @ViewBuilder
    private var scrollContent: some View {
        if viewModel.isLoading {
            loadingCards
        } else if let errorMessage = viewModel.fetchError {
            errorState(message: errorMessage)
        } else if viewModel.experiences.isEmpty {
            emptyState
        } else {
            liveCards
        }
    }

    private var loadingCards: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                ForEach(0..<3, id: \.self) { _ in
                    EventSkeletonCard()
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private var liveCards: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                ForEach(viewModel.experiences) { experience in
                    EventCardView(experience: experience) {
                        selectedExperience = experience
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 4)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Text("No date experiences yet ✨")
                .font(Font.header(17, weight: .semibold))
                .foregroundColor(Color(hex: "E8C27D"))
                .multilineTextAlignment(.center)

            Text("Check back soon for something special.")
                .font(Font.bodySans(14, weight: .regular))
                .foregroundColor(Color(hex: "EADBC8"))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .padding(.horizontal, 24)
    }

    private func errorState(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 28))
                .foregroundColor(Color(hex: "E8C27D").opacity(0.7))

            Text("Couldn't load experiences")
                .font(Font.header(15, weight: .semibold))
                .foregroundColor(Color(hex: "E8C27D"))
                .multilineTextAlignment(.center)

            Text("Check your connection and try again.")
                .font(Font.bodySans(13, weight: .regular))
                .foregroundColor(Color(hex: "EADBC8").opacity(0.8))
                .multilineTextAlignment(.center)

            Button {
                Task { await viewModel.fetchExperiences() }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Retry")
                        .font(Font.bodySans(13, weight: .semibold))
                }
                .foregroundColor(Color(hex: "1A0A0A"))
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "E8C27D"), Color(hex: "F3D9A4")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .padding(.horizontal, 24)
    }
}

// MARK: - Event Detail View

struct EventDetailView: View {
    let experience: DateExperience
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                // Background
                LinearGradient(
                    colors: [Color(hex: "5B0A0A"), Color(hex: "3A0606")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        heroImage
                        contentArea
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(hex: "E8C27D"))
                    }
                }
            }
            .toolbarBackground(Color(hex: "5B0A0A"), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }

    // MARK: Hero Image

    private var heroImage: some View {
        ZStack(alignment: .bottom) {
            AsyncImage(url: URL(string: experience.imageUrl)) { phase in
                switch phase {
                case .success(let img):
                    img.resizable().aspectRatio(contentMode: .fill)
                case .empty, .failure:
                    LinearGradient(
                        colors: [Color(hex: "7A0F0F"), Color(hex: "5B0A0A")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                @unknown default:
                    EmptyView()
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 320)
            .clipped()

            // Bottom gradient fade
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: .clear, location: 0),
                    .init(color: Color(hex: "5B0A0A").opacity(0.9), location: 1.0)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 160)
        }
    }

    // MARK: Content Area

    private var contentArea: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Title
            Text(experience.title)
                .font(Font.header(28, weight: .bold))
                .foregroundColor(.white)
                .fixedSize(horizontal: false, vertical: true)

            // Date + location row
            HStack(spacing: 16) {
                Label(experience.formattedDate, systemImage: "calendar")
                    .font(Font.bodySans(13, weight: .medium))
                    .foregroundColor(Color(hex: "EADBC8"))

                Label(experience.location, systemImage: "location.fill")
                    .font(Font.bodySans(13, weight: .medium))
                    .foregroundColor(Color(hex: "EADBC8"))
            }

            // Divider
            Rectangle()
                .fill(Color(hex: "E8C27D").opacity(0.2))
                .frame(height: 1)

            // Description
            Text(experience.description)
                .font(Font.bodySans(15, weight: .regular))
                .foregroundColor(Color(hex: "EADBC8"))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)

            // CTA Button
            if !experience.eventbriteUrl.isEmpty {
                ctaButton
            }
        }
        .padding(.horizontal, 22)
        .padding(.top, 20)
    }

    private var ctaButton: some View {
        Button {
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            if let url = URL(string: experience.eventbriteUrl) {
                UIApplication.shared.open(url)
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 16))
                Text("Reserve Your Spot ✨")
                    .font(Font.bodySans(16, weight: .semibold))
            }
            .foregroundColor(Color(hex: "1A0A0A"))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [Color(hex: "E8C27D"), Color(hex: "F3D9A4"), Color(hex: "E8C27D")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(Capsule())
            // Subtle gold glow
            .shadow(color: Color(hex: "E8C27D").opacity(0.45), radius: 18, x: 0, y: 6)
        }
        .buttonStyle(.plain)
        .padding(.top, 4)
    }
}
