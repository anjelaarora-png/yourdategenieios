import Foundation

/// Lightweight client-side filter for partner free-text (Apple §1.2).
/// Rejects common abuse / hate / sexual-solicitation terms before they are shared.
enum ObjectionableContentFilter {
    /// User-facing message when text fails the filter.
    static let rejectionMessage =
        "That message contains language we don’t allow. Please revise it — Your Date Genie has no tolerance for objectionable content or abusive behavior."

    /// Returns `nil` if text is allowed; otherwise a user-facing rejection message.
    static func rejectionReason(for text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return nil }

        let normalized = normalize(trimmed)
        for term in blockedTerms {
            if normalized.contains(term) {
                return rejectionMessage
            }
        }
        return nil
    }

    /// `true` when the text may be posted.
    static func isAllowed(_ text: String) -> Bool {
        rejectionReason(for: text) == nil
    }

    // MARK: - Private

    private static func normalize(_ text: String) -> String {
        text
            .lowercased()
            .replacingOccurrences(of: #"[\s_\-\.]+"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: #"([a-z])\1{2,}"#, with: "$1$1", options: .regularExpression)
    }

    /// Conservative blocklist for partner-facing free text. Not exhaustive; v1 review bar.
    private static let blockedTerms: [String] = [
        "kill yourself", "kys",
        "rape", "rapist",
        "nigger", "nigga",
        "faggot", "fag ",
        "retard", "retarded",
        "slut", "whore",
        "send nudes", "nude pics", "sex tape",
        "child porn", "cp ",
        "go die", "die bitch",
        "beat you", "i will hurt you",
        "terrorist",
    ]
}
