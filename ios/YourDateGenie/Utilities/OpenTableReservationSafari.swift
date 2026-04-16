import SafariServices
import SwiftUI
import UIKit

/// Opens OpenTable and Resy searches in the system Safari browser.
enum OpenTableReservationSafari {
    // MARK: - OpenTable

    /// `https://www.opentable.com/s?covers=2&dateTime=yyyy-MM-dd'T'HH:mm&term=VenueName`
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
        comp.queryItems = [
            URLQueryItem(name: "covers", value: "\(partySize)"),
            URLQueryItem(name: "dateTime", value: dateTimeString),
            URLQueryItem(name: "term", value: venueName.trimmingCharacters(in: .whitespacesAndNewlines)),
        ]
        return comp.url
    }

    /// Opens the OpenTable search page in the system Safari browser.
    static func openSearch(venueName: String, partySize: Int = 2) {
        guard let url = makeSearchURL(venueName: venueName, partySize: partySize) else { return }
        UIApplication.shared.open(url)
    }

    // MARK: - Resy

    /// `https://resy.com/?query=VenueName&date=yyyy-MM-dd&seats=2`
    /// Uses the Resy root so there is no city-slug path that could 404.
    static func makeResySearchURL(venueName: String, partySize: Int = 2) -> URL? {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = TimeZone.current
        let dateString = df.string(from: Date())
        var comp = URLComponents()
        comp.scheme = "https"
        comp.host = "resy.com"
        comp.path = "/"
        comp.queryItems = [
            URLQueryItem(name: "query", value: venueName.trimmingCharacters(in: .whitespacesAndNewlines)),
            URLQueryItem(name: "date", value: dateString),
            URLQueryItem(name: "seats", value: "\(partySize)"),
        ]
        return comp.url
    }

    /// Opens the Resy search page in the system Safari browser.
    static func openResySearch(venueName: String, partySize: Int = 2) {
        guard let url = makeResySearchURL(venueName: venueName, partySize: partySize) else { return }
        UIApplication.shared.open(url)
    }

    // MARK: - Phone

    /// Returns a value suitable for `tel:` (digits, or `+` plus digits for international numbers).
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

    // MARK: - In-app Safari (kept for other features that need it)

    static func openInSafari(_ url: URL) {
        let safari = SFSafariViewController(url: url)
        safari.preferredBarTintColor = UIColor(Color.luxuryMaroon)
        safari.preferredControlTintColor = UIColor(Color.luxuryGold)
        DispatchQueue.main.async {
            if let presenter = topPresenter() {
                presenter.present(safari, animated: true)
            } else {
                UIApplication.shared.open(url)
            }
        }
    }

    /// Walks the active window scene to find the topmost VC that is ready to present.
    /// Skips any VC that is currently being dismissed so we never attempt to present on
    /// a sheet that is mid-animation (which silently fails and looks like nothing happened).
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
        if let presented = vc.presentedViewController, !presented.isBeingDismissed {
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
