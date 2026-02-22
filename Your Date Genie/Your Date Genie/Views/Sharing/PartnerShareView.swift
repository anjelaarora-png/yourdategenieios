import SwiftUI

struct PartnerShareView: View {
    let plan: DatePlan
    @Environment(\.dismiss) private var dismiss
    @State private var shareMethod: ShareMethod = .link
    @State private var partnerEmail = ""
    @State private var partnerPhone = ""
    @State private var personalMessage = ""
    @State private var isSharing = false
    @State private var shareSuccess = false
    
    enum ShareMethod: String, CaseIterable {
        case link = "link"
        case email = "email"
        case sms = "sms"
        
        var title: String {
            switch self {
            case .link: return "Copy Link"
            case .email: return "Email"
            case .sms: return "Text"
            }
        }
        
        var icon: String {
            switch self {
            case .link: return "link"
            case .email: return "envelope.fill"
            case .sms: return "message.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .link: return .blue
            case .email: return .orange
            case .sms: return .green
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Plan Preview
                    planPreview
                    
                    // Share Method Selection
                    shareMethodSelection
                    
                    // Share Form
                    shareForm
                    
                    // Share Button
                    shareButton
                }
                .padding(20)
            }
            .background(Color.brandCream)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.brandPrimary)
                }
            }
            .alert("Shared!", isPresented: $shareSuccess) {
                Button("Done") {
                    dismiss()
                }
            } message: {
                Text("Your date plan has been shared with your partner!")
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.pink.opacity(0.15))
                    .frame(width: 72, height: 72)
                
                Image(systemName: "person.2.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.pink)
            }
            
            Text("Invite Your Partner")
                .font(.custom("Cormorant-Bold", size: 26, relativeTo: .title))
                .foregroundColor(Color(UIColor.label))
            
            Text("Share this date plan and make it official!")
                .font(.system(size: 15))
                .foregroundColor(Color(UIColor.secondaryLabel))
                .multilineTextAlignment(.center)
        }
    }
    
    private var planPreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(plan.title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color(UIColor.label))
                    
                    Text(plan.tagline)
                        .font(.system(size: 14))
                        .foregroundColor(Color(UIColor.secondaryLabel))
                        .lineLimit(2)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(plan.totalDuration)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.brandGold)
                    
                    Text("\(plan.stops.count) stops")
                        .font(.system(size: 12))
                        .foregroundColor(Color(UIColor.tertiaryLabel))
                }
            }
            
            // Mini itinerary
            HStack(spacing: 8) {
                ForEach(plan.stops.prefix(4)) { stop in
                    Text(stop.emoji)
                        .font(.system(size: 20))
                        .frame(width: 36, height: 36)
                        .background(Color.white)
                        .cornerRadius(8)
                }
                
                if plan.stops.count > 4 {
                    Text("+\(plan.stops.count - 4)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(UIColor.secondaryLabel))
                        .frame(width: 36, height: 36)
                        .background(Color.white)
                        .cornerRadius(8)
                }
            }
        }
        .padding(16)
        .background(Color.brandGold.opacity(0.1))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.brandGold.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var shareMethodSelection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("How would you like to share?")
                .font(.system(size: 16, weight: .semibold))
            
            HStack(spacing: 12) {
                ForEach(ShareMethod.allCases, id: \.self) { method in
                    ShareMethodCard(
                        method: method,
                        isSelected: shareMethod == method,
                        onTap: { shareMethod = method }
                    )
                }
            }
        }
    }
    
    private var shareForm: some View {
        VStack(alignment: .leading, spacing: 16) {
            switch shareMethod {
            case .link:
                // Link preview
                HStack {
                    Text("yourdategenie.app/plan/abc123")
                        .font(.system(size: 14))
                        .foregroundColor(Color(UIColor.secondaryLabel))
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Button {
                        copyLink()
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .foregroundColor(.brandPrimary)
                    }
                }
                .padding(14)
                .background(Color.white)
                .cornerRadius(12)
                
            case .email:
                VStack(alignment: .leading, spacing: 8) {
                    Text("Partner's email")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(UIColor.secondaryLabel))
                    
                    TextField("email@example.com", text: $partnerEmail)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .padding(14)
                        .background(Color.white)
                        .cornerRadius(12)
                }
                
            case .sms:
                VStack(alignment: .leading, spacing: 8) {
                    Text("Partner's phone")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(UIColor.secondaryLabel))
                    
                    TextField("(555) 123-4567", text: $partnerPhone)
                        .textContentType(.telephoneNumber)
                        .keyboardType(.phonePad)
                        .padding(14)
                        .background(Color.white)
                        .cornerRadius(12)
                }
            }
            
            // Personal message
            if shareMethod != .link {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Add a personal message (optional)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(UIColor.secondaryLabel))
                    
                    TextEditor(text: $personalMessage)
                        .frame(height: 80)
                        .padding(8)
                        .background(Color.white)
                        .cornerRadius(12)
                        .overlay(
                            Group {
                                if personalMessage.isEmpty {
                                    Text("E.g., Can't wait for our date! 💕")
                                        .foregroundColor(Color(UIColor.placeholderText))
                                        .padding(12)
                                        .allowsHitTesting(false)
                                }
                            },
                            alignment: .topLeading
                        )
                }
            }
        }
    }
    
    private var shareButton: some View {
        Button {
            sharePlan()
        } label: {
            HStack {
                if isSharing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: shareMethod.icon)
                }
                Text(shareButtonText)
            }
            .font(.system(size: 17, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                isShareEnabled
                    ? LinearGradient.goldGradient
                    : LinearGradient(colors: [Color.gray.opacity(0.5)], startPoint: .leading, endPoint: .trailing)
            )
            .cornerRadius(14)
            .shadow(color: isShareEnabled ? Color.brandGold.opacity(0.4) : .clear, radius: 10, y: 4)
        }
        .disabled(!isShareEnabled || isSharing)
    }
    
    private var shareButtonText: String {
        switch shareMethod {
        case .link: return "Copy Link"
        case .email: return "Send Email"
        case .sms: return "Send Text"
        }
    }
    
    private var isShareEnabled: Bool {
        switch shareMethod {
        case .link: return true
        case .email: return !partnerEmail.isEmpty && partnerEmail.contains("@")
        case .sms: return !partnerPhone.isEmpty
        }
    }
    
    private func copyLink() {
        UIPasteboard.general.string = "https://yourdategenie.app/plan/abc123"
        // Show feedback
    }
    
    private func sharePlan() {
        isSharing = true
        
        // Simulate sending
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isSharing = false
            
            switch shareMethod {
            case .link:
                copyLink()
                shareSuccess = true
            case .email, .sms:
                shareSuccess = true
            }
        }
    }
}

// MARK: - Share Method Card
struct ShareMethodCard: View {
    let method: PartnerShareView.ShareMethod
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: method.icon)
                    .font(.system(size: 22))
                    .foregroundColor(isSelected ? .white : method.color)
                    .frame(width: 48, height: 48)
                    .background(isSelected ? method.color : method.color.opacity(0.1))
                    .cornerRadius(12)
                
                Text(method.title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(isSelected ? method.color : Color(UIColor.label))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? method.color.opacity(0.1) : Color.white)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? method.color : Color.gray.opacity(0.2), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

#Preview {
    PartnerShareView(plan: DatePlan.sample)
}
