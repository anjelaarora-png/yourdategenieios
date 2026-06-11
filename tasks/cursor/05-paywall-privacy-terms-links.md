# Cursor Task — Add Privacy Policy + Terms/EULA links to PaywallView (Apple §3.1.2 compliance)

**Owner:** Anjela (executing in Cursor)
**Specced by:** ios-developer agent
**Priority:** P0 — Apple §3.1.2 will reject paywalls missing these links
**Estimated effort:** 20 minutes

---

## Context for Cursor

Apple App Store Review Guideline §3.1.2 (Subscriptions) requires that any paywall presenting an auto-renewing subscription must visibly display:

1. Subscription name (e.g. "Date Genie Premium")
2. Length of subscription period (e.g. "Monthly", "Yearly")
3. Price per period
4. **Functional links to your Privacy Policy and Terms of Use (EULA)**
5. A "Restore Purchases" button

`ios/YourDateGenie/Views/Subscription/PaywallView.swift` currently shows 1, 2, 3, and 5. **Missing #4** — the privacy and terms links.

This is the single most common §3.1.2 rejection reason. Easy fix.

---

## Goal

`PaywallView.swift` displays tappable "Privacy Policy" and "Terms of Use" links below the price/restore section. Tapping each opens the corresponding URL (in-app `SafariView` is preferred over external Safari for compliance, but external Safari is also acceptable).

---

## Locked decisions to use

- **Legal entity:** Your Date Genie LLC (NOT Inc.)
- **Privacy Policy URL:** `https://yourdategenie.com/privacy` (currently live)
- **Terms of Use URL:** `https://yourdategenie.com/terms` (NOT yet live — see task 13 to publish the redrafted Terms; for now, use this URL and the page will go live before submission)
- **Pricing displayed in paywall:**
  - Monthly: **$14.99/mo**
  - Annual: **$99.99/yr** (~44% off)
  - Free trial: 7 days
  - Free tier (non-paywall context): 3 AI date plans/mo + 5 saved plans

---

## Task breakdown

### Step 1 — Open `ios/YourDateGenie/Views/Subscription/PaywallView.swift`

Identify where the "Restore Purchases" button sits in the view hierarchy. The two new links should sit immediately below it (or in the same legal-disclaimer footer block).

### Step 2 — Add the URL constants

Near the top of the file (or in a small private extension), add:

```swift
private enum LegalURLs {
    static let privacy = URL(string: "https://yourdategenie.com/privacy")!
    static let terms = URL(string: "https://yourdategenie.com/terms")!
}
```

### Step 3 — Add a SafariView wrapper if one doesn't exist

Check if the project already has a `SafariView` SwiftUI wrapper around `SFSafariViewController`. If not, create `ios/YourDateGenie/Views/Common/SafariView.swift`:

```swift
import SwiftUI
import SafariServices

struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}
```

### Step 4 — Add the legal footer to PaywallView

Add state for which legal page is being shown:

```swift
@State private var legalSheetURL: URL?
```

Add a footer block below the Restore Purchases row:

```swift
HStack(spacing: 16) {
    Button("Privacy Policy") {
        legalSheetURL = LegalURLs.privacy
    }
    .font(.footnote)
    .foregroundColor(.secondary)

    Button("Terms of Use") {
        legalSheetURL = LegalURLs.terms
    }
    .font(.footnote)
    .foregroundColor(.secondary)
}
.padding(.top, 8)
```

Add the sheet presentation modifier on the root view:

```swift
.sheet(item: Binding(
    get: { legalSheetURL.map { IdentifiableURL(url: $0) } },
    set: { legalSheetURL = $0?.url }
)) { item in
    SafariView(url: item.url)
}
```

You'll need a small wrapper for URL since URL doesn't conform to Identifiable:

```swift
private struct IdentifiableURL: Identifiable {
    let url: URL
    var id: String { url.absoluteString }
}
```

### Step 5 — Add the auto-renewal disclosure text

Apple also requires a sentence near the subscribe button explaining auto-renewal. Add this above the legal links:

```swift
Text("Subscription automatically renews unless canceled at least 24 hours before the end of the current period. Manage in App Store settings.")
    .font(.caption2)
    .foregroundColor(.secondary)
    .multilineTextAlignment(.center)
    .padding(.horizontal)
```

### Step 6 — Verify pricing strings

Confirm the paywall displays the correct prices ($14.99/mo, $99.99/yr). If hardcoded, update them. If pulled from StoreKit `Product.displayPrice`, verify the products are configured with these prices in App Store Connect (separate task, but flag if you find hardcoded prices that don't match).

---

## Verification checklist

- [ ] Paywall view displays "Privacy Policy" tap target
- [ ] Paywall view displays "Terms of Use" tap target
- [ ] Tapping "Privacy Policy" opens `https://yourdategenie.com/privacy` in Safari sheet (or external Safari)
- [ ] Tapping "Terms of Use" opens `https://yourdategenie.com/terms` in Safari sheet
- [ ] Auto-renewal disclosure text is visible on the paywall
- [ ] Restore Purchases button is still visible and functional
- [ ] Subscription name + period + price are still visible
- [ ] Build passes
- [ ] (Manual QA) Run app on device, open paywall, tap each link, confirm pages load

## Out of scope

- Publishing the Terms of Use page itself (separate task — task 13)
- StoreKit product configuration in App Store Connect (separate task)
- Paywall redesign (only adding compliance elements)

## When you're done

Tell me ("chief-of-staff, paywall links done") and I'll mark P0 #4 as complete.
