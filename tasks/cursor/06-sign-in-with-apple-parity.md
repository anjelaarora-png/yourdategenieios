# Cursor Task — Add Sign in with Apple (Apple §4.8 parity requirement)

**Owner:** Anjela (executing in Cursor)
**Specced by:** ios-developer agent
**Priority:** P0 — Apple §4.8 will reject if any third-party social login is offered without Sign in with Apple as an equally prominent option
**Estimated effort:** 2–3 hours

---

## Context for Cursor

Apple App Store Review Guideline §4.8 requires: if your app offers a third-party or social login option (Google, Facebook, email magic link, etc.), you MUST also offer Sign in with Apple — and it must be presented at least as prominently as the other options.

`ios/YourDateGenie/Views/Auth/AuthenticationView.swift:64-66` (and surrounding code) currently offers email/password and likely a Google sign-in option via Supabase. There is no Sign in with Apple button. Apple will reject.

This is the second-most-common dating-app rejection (after §3.1.2 paywall issues).

---

## Goal

`AuthenticationView.swift` shows a Sign in with Apple button at the top of the auth options stack (or visually equal to Google/email). Tapping it triggers Apple's native ASAuthorizationAppleIDProvider flow. The resulting credential is exchanged via Supabase Auth's `signInWithIdToken` method to create or look up the user.

---

## Existing infrastructure

- Supabase Auth supports Apple as an OAuth provider — already enabled in our Supabase project (verify in dashboard)
- iOS supports `ASAuthorizationAppleIDProvider` natively — no third-party SDK needed
- Need to add the "Sign in with Apple" capability in Xcode project settings

---

## Task breakdown

### Step 1 — Enable Sign in with Apple capability in Xcode

In `ios/YourDateGenie.xcodeproj`:
1. Select target → Signing & Capabilities tab
2. Click "+ Capability"
3. Add "Sign in with Apple"

This adds an entitlements file entry: `com.apple.developer.applesignin = ["Default"]`.

Cursor should verify the entitlements file (`ios/YourDateGenie/YourDateGenie.entitlements` or similar) gets this entry. If not, add it manually:

```xml
<key>com.apple.developer.applesignin</key>
<array>
    <string>Default</string>
</array>
```

### Step 2 — Verify Apple provider is enabled in Supabase

Anjela manual step: In Supabase dashboard → Authentication → Providers → Apple → toggle ON. Configure with:
- Service ID (from Apple Developer portal — needs Sign in with Apple service registered)
- Team ID
- Key ID + private key (.p8 file)

If not yet configured, this is a 30-min manual setup — flag to Anjela.

### Step 3 — Create `AppleSignInButton.swift`

`ios/YourDateGenie/Views/Auth/AppleSignInButton.swift`:

```swift
import SwiftUI
import AuthenticationServices

struct AppleSignInButton: View {
    let onSuccess: (ASAuthorizationAppleIDCredential) -> Void
    let onError: (Error) -> Void

    var body: some View {
        SignInWithAppleButton(
            onRequest: { request in
                request.requestedScopes = [.fullName, .email]
            },
            onCompletion: { result in
                switch result {
                case .success(let authorization):
                    if let credential = authorization.credential as? ASAuthorizationAppleIDCredential {
                        onSuccess(credential)
                    }
                case .failure(let error):
                    onError(error)
                }
            }
        )
        .signInWithAppleButtonStyle(.black)
        .frame(height: 50)
        .cornerRadius(12)
    }
}
```

### Step 4 — Wire up Supabase exchange

In `SupabaseService.swift` (or wherever auth methods live), add:

```swift
func signInWithApple(credential: ASAuthorizationAppleIDCredential) async throws -> Session {
    guard let identityToken = credential.identityToken,
          let tokenString = String(data: identityToken, encoding: .utf8) else {
        throw AuthError.invalidCredential
    }

    let session = try await client.auth.signInWithIdToken(
        credentials: .init(
            provider: .apple,
            idToken: tokenString
        )
    )
    return session
}
```

(Adjust to match the actual `supabase-swift` API — Cursor verifies the exact method signature.)

### Step 5 — Add the button to AuthenticationView

In `ios/YourDateGenie/Views/Auth/AuthenticationView.swift`, add at the top of the auth options stack (before email/Google):

```swift
AppleSignInButton(
    onSuccess: { credential in
        Task {
            do {
                try await SupabaseService.shared.signInWithApple(credential: credential)
                // Navigate to main app
            } catch {
                // Show error
            }
        }
    },
    onError: { error in
        // Show error
    }
)
.padding(.horizontal)
```

Position-wise: place the Apple button ABOVE Google sign-in and email. Apple's guideline says "equally prominent or more" — putting it first satisfies that.

### Step 6 — Handle first-time vs repeat sign-in

Apple only sends `fullName` and `email` on the FIRST sign-in. On subsequent sign-ins, those fields are nil. The Supabase user record persists, so this is fine — but if you ever want to capture the name, do it on first sign-in only.

If first-time, after successful exchange, update the user's profile:

```swift
if let fullName = credential.fullName,
   let givenName = fullName.givenName {
    let displayName = [givenName, fullName.familyName].compactMap { $0 }.joined(separator: " ")
    try await client.auth.update(user: UserAttributes(data: ["full_name": .string(displayName)]))
}
```

### Step 7 — Add nonce for replay protection (recommended by Supabase)

Generate a nonce, hash it with SHA256, send the hash in `request.nonce`, and pass the raw nonce to `signInWithIdToken`:

```swift
// Before showing the button, generate a nonce per attempt
let rawNonce = UUID().uuidString
let hashedNonce = SHA256.hash(data: rawNonce.data(using: .utf8)!).compactMap { String(format: "%02x", $0) }.joined()

// In onRequest:
request.nonce = hashedNonce

// In signInWithApple call:
try await client.auth.signInWithIdToken(
    credentials: .init(provider: .apple, idToken: tokenString, nonce: rawNonce)
)
```

---

## Verification checklist

- [ ] Sign in with Apple capability is enabled in Xcode project
- [ ] Entitlements file contains `com.apple.developer.applesignin`
- [ ] Apple provider is enabled in Supabase dashboard with Service ID + key configured
- [ ] `AppleSignInButton` renders correctly on `AuthenticationView`
- [ ] Apple button is positioned at least as prominently as Google / email options
- [ ] Tapping the button triggers Apple's native auth sheet
- [ ] On success, user is signed into Supabase (verify with `supabase.auth.session?.user.id` non-nil)
- [ ] Building user appears in Supabase dashboard under Authentication → Users with `provider: apple`
- [ ] First-time sign-in captures full name into user profile
- [ ] Repeat sign-in works without requiring name re-entry

## Out of scope

- Account merging (if user signed up with email previously and now uses Apple — separate UX problem)
- Removing Google sign-in (we keep both)
- Web app Sign in with Apple (web auth flow is different — not blocking iOS launch)

## When you're done

Tell me ("chief-of-staff, sign in with apple done") and I'll add it to the workflow as resolved P1 (it was actually missed on the original P0 list — flagging now since it's a known §4.8 rejection vector for dating apps).
