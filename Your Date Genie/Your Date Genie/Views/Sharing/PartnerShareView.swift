import SwiftUI

struct PartnerShareView: View {
    let plan: DatePlan
    
    @Environment(\.dismiss) private var dismiss
    @State private var shareMessage = ""
    @State private var showShareSheet = false
    @State private var copiedToClipboard = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Luxurious background
                Color.luxuryMaroon
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        // Header
                        VStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(Color.luxuryGold.opacity(0.1))
                                    .frame(width: 90, height: 90)
                                
                                Image(systemName: "heart.circle.fill")
                                    .font(.system(size: 50))
                                    .foregroundStyle(LinearGradient.goldShimmer)
                            }
                            
                            VStack(spacing: 6) {
                                Text("Share with Your Date")
                                    .font(Font.displayTitle())
                                    .foregroundColor(Color.luxuryGold)
                                
                                Text("Send this evening's plan to your partner")
                                    .font(Font.playfair(15, weight: .regular))
                                    .foregroundColor(Color.luxuryCreamMuted)
                            }
                        }
                        .padding(.top, 20)
                        
                        // Plan preview card
                        VStack(spacing: 18) {
                            HStack(spacing: 8) {
                                ForEach(plan.stops.prefix(4)) { stop in
                                    Text(stop.emoji)
                                        .font(.system(size: 26))
                                }
                            }
                            
                            VStack(spacing: 8) {
                                Text(plan.title)
                                    .font(Font.playfair(20, weight: .bold))
                                    .foregroundColor(Color.luxuryGold)
                                
                                Text(plan.tagline)
                                    .font(Font.playfair(14, weight: .regular))
                                    .foregroundColor(Color.luxuryCreamMuted)
                                    .multilineTextAlignment(.center)
                            }
                            
                            HStack(spacing: 24) {
                                VStack(spacing: 4) {
                                    Text("\(plan.stops.count)")
                                        .font(Font.cormorant(22, weight: .bold))
                                        .foregroundColor(Color.luxuryGold)
                                    Text("stops")
                                        .font(Font.inter(11, weight: .regular))
                                        .foregroundColor(Color.luxuryMuted)
                                }
                                
                                Rectangle()
                                    .fill(Color.luxuryGold.opacity(0.3))
                                    .frame(width: 1, height: 30)
                                
                                VStack(spacing: 4) {
                                    Text(plan.totalDuration)
                                        .font(Font.cormorant(22, weight: .bold))
                                        .foregroundColor(Color.luxuryGold)
                                    Text("duration")
                                        .font(Font.inter(11, weight: .regular))
                                        .foregroundColor(Color.luxuryMuted)
                                }
                                
                                Rectangle()
                                    .fill(Color.luxuryGold.opacity(0.3))
                                    .frame(width: 1, height: 30)
                                
                                VStack(spacing: 4) {
                                    Text(plan.estimatedCost)
                                        .font(Font.cormorant(22, weight: .bold))
                                        .foregroundColor(Color.luxuryGold)
                                    Text("budget")
                                        .font(Font.inter(11, weight: .regular))
                                        .foregroundColor(Color.luxuryMuted)
                                }
                            }
                        }
                        .padding(24)
                        .frame(maxWidth: .infinity)
                        .luxuryCard()
                        .padding(.horizontal, 20)
                        
                        // Personal message
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "quote.bubble")
                                    .foregroundColor(Color.luxuryGold)
                                Text("Add a Personal Note")
                                    .font(Font.playfair(16, weight: .semibold))
                                    .foregroundColor(Color.luxuryCream)
                            }
                            
                            TextEditor(text: $shareMessage)
                                .font(Font.inter(15, weight: .regular))
                                .foregroundColor(Color.luxuryCream)
                                .scrollContentBackground(.hidden)
                                .frame(height: 100)
                                .padding(14)
                                .background(Color.luxuryMaroonLight)
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.luxuryGold.opacity(0.3), lineWidth: 1)
                                )
                                .overlay(
                                    Group {
                                        if shareMessage.isEmpty {
                                            Text("Can't wait to spend this evening with you...")
                                                .font(Font.playfairItalic(15))
                                                .foregroundColor(Color.luxuryMuted.opacity(0.5))
                                                .padding(.horizontal, 18)
                                                .padding(.vertical, 22)
                                                .allowsHitTesting(false)
                                        }
                                    },
                                    alignment: .topLeading
                                )
                        }
                        .padding(.horizontal, 20)
                        
                        // Share options
                        VStack(spacing: 14) {
                            // Primary share button
                            Button {
                                sharePlan()
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: "square.and.arrow.up")
                                    Text("Share Plan")
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(LuxuryGoldButtonStyle())
                            
                            // Copy link
                            Button {
                                copyToClipboard()
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: copiedToClipboard ? "checkmark.circle.fill" : "doc.on.doc")
                                    Text(copiedToClipboard ? "Copied!" : "Copy Link")
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(LuxuryOutlineButtonStyle())
                            
                            // Quick share row
                            HStack(spacing: 20) {
                                ShareButton(icon: "message.fill", label: "iMessage", color: Color(hex: "34C759")) {
                                    shareViaMessages()
                                }
                                
                                ShareButton(icon: "envelope.fill", label: "Email", color: Color.luxuryGold) {
                                    shareViaEmail()
                                }
                                
                                ShareButton(icon: "doc.text.fill", label: "Note", color: Color.luxuryGoldLight) {
                                    shareAsNote()
                                }
                            }
                            .padding(.top, 10)
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Share Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .font(Font.inter(16, weight: .medium))
                    .foregroundColor(Color.luxuryGold)
                }
            }
            .toolbarBackground(Color.luxuryMaroon, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
    
    private var shareText: String {
        var text = "I've planned something special for us!\n\n"
        text += "✨ \(plan.title)\n"
        text += "\"\(plan.tagline)\"\n\n"
        
        for stop in plan.stops {
            text += "\(stop.emoji) \(stop.timeSlot) - \(stop.name)\n"
        }
        
        text += "\nTotal time: \(plan.totalDuration)\n"
        text += "Estimated cost: \(plan.estimatedCost)\n"
        
        if !shareMessage.isEmpty {
            text += "\n\(shareMessage)"
        }
        
        text += "\n\n— Planned with Your Date Genie"
        
        return text
    }
    
    private func sharePlan() {
        let activityController = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(activityController, animated: true)
        }
    }
    
    private func copyToClipboard() {
        UIPasteboard.general.string = shareText
        withAnimation(.spring(response: 0.3)) {
            copiedToClipboard = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation {
                copiedToClipboard = false
            }
        }
    }
    
    private func shareViaMessages() {
        if let encoded = shareText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
           let url = URL(string: "sms:&body=\(encoded)") {
            UIApplication.shared.open(url)
        }
    }
    
    private func shareViaEmail() {
        let subject = "Our Date Plan: \(plan.title)"
        if let subjectEncoded = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
           let bodyEncoded = shareText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
           let url = URL(string: "mailto:?subject=\(subjectEncoded)&body=\(bodyEncoded)") {
            UIApplication.shared.open(url)
        }
    }
    
    private func shareAsNote() {
        UIPasteboard.general.string = shareText
        copiedToClipboard = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            copiedToClipboard = false
        }
    }
}

// MARK: - Share Button
struct ShareButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(color)
                    .frame(width: 54, height: 54)
                    .background(Color.luxuryMaroonLight)
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(color.opacity(0.3), lineWidth: 1)
                    )
                
                Text(label)
                    .font(Font.inter(11, weight: .medium))
                    .foregroundColor(Color.luxuryCream)
            }
        }
    }
}

#Preview {
    PartnerShareView(plan: DatePlan.sample)
}
