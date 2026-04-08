import SafariServices
import SwiftUI
import UIKit

/// Opens OpenTable search in `SFSafariViewController` with venue, party size, and today at 7:00 PM local time.
enum OpenTableReservationSafari {
    /// `https://www.opentable.com/s?covers=&dateTime=yyyy-MM-dd'T'HH:mm&term=`
    static func makeSearchURL(venueName: String, partySize: Int = 2) -> URL? {
        let calendar = Calendar.current
        let today = Date()
        guard let sevenPm = calendar.date(bySettingHour: 19, minute: 0, second: 0, of: today) else { return nil }
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd'T'HH:mm"
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = TimeZone.current
        let dateTimeString = df.string(from: sevenPm)
        var comp = URLComponents()
        comp.scheme = "https"
        comp.host = "www.opentable.com"
        comp.path = "/s"
        // Percent-encoding is applied by URLComponents when building `url` (venue names with punctuation, etc.).
        comp.queryItems = [
            URLQueryItem(name: "covers", value: "\(partySize)"),
            URLQueryItem(name: "dateTime", value: dateTimeString),
            URLQueryItem(name: "term", value: venueName.trimmingCharacters(in: .whitespacesAndNewlines)),
        ]
        return comp.url
    }

    static func openSearch(venueName: String, partySize: Int = 2) {
        guard let url = makeSearchURL(venueName: venueName, partySize: partySize) else { return }
        openInSafari(url)
    }

    /// `https://resy.com/cities/na/venues?query=&date=yyyy-MM-dd&seats=`
    static func makeResySearchURL(venueName: String, partySize: Int = 2) -> URL? {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = TimeZone.current
        let dateString = df.string(from: Date())
        var comp = URLComponents()
        comp.scheme = "https"
        comp.host = "resy.com"
        comp.path = "/cities/na/venues"
        comp.queryItems = [
            URLQueryItem(name: "query", value: venueName.trimmingCharacters(in: .whitespacesAndNewlines)),
            URLQueryItem(name: "date", value: dateString),
            URLQueryItem(name: "seats", value: "\(partySize)"),
        ]
        return comp.url
    }

    static func openResySearch(venueName: String, partySize: Int = 2) {
        guard let url = makeResySearchURL(venueName: venueName, partySize: partySize) else { return }
        openInSafari(url)
    }

    /// Returns a value suitable for `tel:` (digits, or `+` plus digits when the raw string starts with `+`, e.g. Google Places).
    static func sanitizedPhoneForTel(_ raw: String?) -> String? {
        guard let trimmed = raw?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else { return nil }
        let digits = trimmed.filter(\.isNumber)
        guard !digits.isEmpty else { return nil }
        if trimmed.hasPrefix("+") {
            return "+\(digits)"
        }
        return digits
    }

    static func openPhoneCall(phoneNumber: String) {
        guard let telBody = sanitizedPhoneForTel(phoneNumber) else { return }
        guard let url = URL(string: "tel:\(telBody)") else { return }
        UIApplication.shared.open(url)
    }

    static func openInSafari(_ url: URL) {
        let safari = SFSafariViewController(url: url)
        safari.preferredBarTintColor = UIColor(Color.luxuryMaroon)
        safari.preferredControlTintColor = UIColor(Color.luxuryGold)
        // Defer to the next run loop so SwiftUI has finished the current touch / layout (esp. when a sheet is up).
        DispatchQueue.main.async {
            if let presenter = topPresenter() {
                presenter.present(safari, animated: true)
            } else {
                UIApplication.shared.open(url)
            }
        }
    }

    /// Walks the active window scene to find the topmost VC. Falls back when no window is marked key (common during sheet transitions).
    private static func topPresenter() -> UIViewController? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let windows = scenes.flatMap(\.windows)
        let root: UIViewController?
        if let key = windows.first(where: \.isKeyWindow)?.rootViewController {
            root = key
        } else if let any = windows.first(where: { !$0.isHidden && $0.alpha > 0 && $0.rootViewController != nil })?.rootViewController {
            root = any
        } else {
            root = windows.last?.rootViewController
        }
        guard let root else { return nil }
        return topMost(from: root)
    }

    private static func topMost(from vc: UIViewController) -> UIViewController {
        if let presented = vc.presentedViewController {
            return topMost(from: presented)
        }
        if let nav = vc as? UINavigationController, let visible = nav.visibleViewController {
            return topMost(from: visible)
        }
        if let tab = vc as? UITabBarController, let selected = tab.selectedViewController {
            return topMost(from: selected)
        }
        return vc
    }
}
