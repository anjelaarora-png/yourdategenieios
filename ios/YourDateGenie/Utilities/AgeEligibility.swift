import Foundation

/// 18+ eligibility for Your Date Genie (Terms + App Store age rating).
enum AgeEligibility {
    static let minimumAge = 18
    static let userDefaultsKey = "dateGenie_confirmedAge18"
    /// Persists Terms checkbox so remounts / authRequired sheet don't ask again this install.
    static let termsAcceptedKey = "dateGenie_agreedToTerms"

    /// Device has completed the age gate as an adult.
    static var hasConfirmedAdult: Bool {
        UserDefaults.standard.bool(forKey: userDefaultsKey)
    }

    static func markConfirmedAdult() {
        UserDefaults.standard.set(true, forKey: userDefaultsKey)
    }

    static var hasAcceptedTerms: Bool {
        UserDefaults.standard.bool(forKey: termsAcceptedKey)
    }

    static func markAcceptedTerms(_ value: Bool = true) {
        UserDefaults.standard.set(value, forKey: termsAcceptedKey)
    }

    /// Whole years of age as of `asOf` (defaults to now).
    static func age(from dateOfBirth: Date, asOf: Date = Date()) -> Int {
        Calendar.current.dateComponents([.year], from: dateOfBirth, to: asOf).year ?? 0
    }

    static func isAtLeastMinimumAge(_ dateOfBirth: Date, asOf: Date = Date()) -> Bool {
        age(from: dateOfBirth, asOf: asOf) >= minimumAge
    }

    /// Latest birthday that still qualifies as `minimumAge` today.
    static var maximumEligibleBirthDate: Date {
        Calendar.current.date(byAdding: .year, value: -minimumAge, to: Date()) ?? Date()
    }

    /// Sensible default for the DOB picker (~25 years old).
    static var defaultBirthDateSuggestion: Date {
        Calendar.current.date(byAdding: .year, value: -25, to: Date()) ?? maximumEligibleBirthDate
    }
}
