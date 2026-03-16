import Foundation

/// Currency display based on the user's region (device locale).
/// Used so date costs and price levels show in the currency of the country where the date is being searched / user is located.
enum CurrencyHelper {
    
    /// Currency code for the current region (e.g. USD, INR, GBP).
    static var currencyCode: String {
        Locale.current.currency?.identifier ?? "USD"
    }
    
    /// Symbol to use when displaying costs (e.g. $, ₹, £, €).
    /// Matches the mapping used in DatePlanGeneratorService so generated plans and UI stay consistent.
    static var symbol: String {
        switch currencyCode {
        case "INR": return "₹"
        case "GBP": return "£"
        case "EUR": return "€"
        case "AUD": return "A$"
        case "CAD": return "C$"
        case "JPY", "CNY": return "¥"
        case "SGD": return "S$"
        case "AED", "SAR": return currencyCode
        default: return "$"
        }
    }
    
    /// Format a price level (e.g. Google Places 0–3) as a repeated symbol string for display.
    /// e.g. level 1 → "$$", level 2 → "₹₹₹" in India.
    static func formattedPriceLevel(_ level: Int?) -> String {
        let count = level.map { min($0 + 1, 4) } ?? 2
        return String(repeating: symbol, count: count)
    }
}
