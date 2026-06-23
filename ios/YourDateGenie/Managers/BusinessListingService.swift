import Foundation
import FirebaseFirestore

@MainActor
final class BusinessListingService: ObservableObject {
    static let shared = BusinessListingService()

    @Published private(set) var status: BusinessListingSubmitStatus = .idle

    private init() {}

    func resetStatus() {
        status = .idle
    }

    func submit(_ application: BusinessListingApplication, source: String) async {
        guard Config.isFirebaseConfigured else {
            status = .error("Firebase is not configured. Add GoogleService-Info.plist to the app target and rebuild.")
            return
        }

        FirebaseBootstrap.configureIfNeeded()
        status = .submitting

        let email = application.email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let venueCategoryOther = application.venueCategory == .other
            ? application.venueCategoryOther.trimmingCharacters(in: .whitespacesAndNewlines)
            : nil
        let promotionOther = application.promotionInterest == .other
            ? application.promotionOther.trimmingCharacters(in: .whitespacesAndNewlines)
            : nil

        var payload: [String: Any] = [
            "businessName": application.businessName.trimmingCharacters(in: .whitespacesAndNewlines),
            "contactName": application.contactName.trimmingCharacters(in: .whitespacesAndNewlines),
            "email": email,
            "phone": application.phone.trimmingCharacters(in: .whitespacesAndNewlines),
            "streetAddress": application.streetAddress.trimmingCharacters(in: .whitespacesAndNewlines),
            "city": application.city.trimmingCharacters(in: .whitespacesAndNewlines),
            "state": application.state.trimmingCharacters(in: .whitespacesAndNewlines),
            "venueCategory": application.venueCategory.rawValue,
            "venueType": application.venueCategory.legacyVenueType,
            "aboutVenue": application.aboutVenue.trimmingCharacters(in: .whitespacesAndNewlines),
            "coupleExperience": application.coupleExperience.trimmingCharacters(in: .whitespacesAndNewlines),
            "promotionInterest": application.promotionInterest.rawValue,
            "budgetRange": application.budgetRange.rawValue,
            "source": source,
            "status": "new",
            "applicationType": "advertising",
            "createdAt": FieldValue.serverTimestamp(),
            "userAgent": "YourDateGenie-iOS/\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")",
        ]

        let contactRole = application.contactRole.trimmingCharacters(in: .whitespacesAndNewlines)
        if !contactRole.isEmpty { payload["contactRole"] = contactRole }

        let website = application.website.trimmingCharacters(in: .whitespacesAndNewlines)
        if !website.isEmpty { payload["website"] = website }

        let zip = application.zip.trimmingCharacters(in: .whitespacesAndNewlines)
        if !zip.isEmpty { payload["zip"] = zip }

        if let venueCategoryOther, !venueCategoryOther.isEmpty {
            payload["venueCategoryOther"] = venueCategoryOther
        }
        if let promotionOther, !promotionOther.isEmpty {
            payload["promotionOther"] = promotionOther
        }

        let notes = application.additionalNotes.trimmingCharacters(in: .whitespacesAndNewlines)
        if !notes.isEmpty {
            payload["additionalNotes"] = notes
            payload["notes"] = notes
        }

        do {
            try await Firestore.firestore()
                .collection("business_listings")
                .document(email)
                .setData(payload)
            status = .success
        } catch {
            let nsError = error as NSError
            if nsError.domain == FirestoreErrorDomain, nsError.code == FirestoreErrorCode.permissionDenied.rawValue {
                status = .duplicate
                return
            }
            AppLogger.error("Business listing submit failed: \(error.localizedDescription)")
            status = .error(error.localizedDescription)
        }
    }
}
