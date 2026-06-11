# Cursor Task — Fix Info.plist UIRequiredDeviceCapabilities (armv7 → arm64)

**Owner:** Anjela (executing in Cursor)
**Specced by:** ios-developer agent
**Priority:** P0 — Apple will reject submission with this in place
**Estimated effort:** 2 minutes

---

## Context for Cursor

`ios/Info.plist` line 81 declares `UIRequiredDeviceCapabilities` as `armv7`. Apple deprecated 32-bit `armv7` in iOS 11 (2017). Modern apps must declare `arm64`. App Store Connect validation will reject the build at upload with error: "Invalid Required Architecture - The bundle's UIRequiredDeviceCapabilities key contains an architecture that is not supported on iOS."

This is a one-line fix.

---

## Goal

`ios/Info.plist` declares `arm64` as the required device capability. Build, upload, validation passes.

---

## Task breakdown

### Step 1 — Open `ios/Info.plist`

Find the `UIRequiredDeviceCapabilities` key. The current XML looks like:

```xml
<key>UIRequiredDeviceCapabilities</key>
<array>
    <string>armv7</string>
</array>
```

### Step 2 — Replace `armv7` with `arm64`

```xml
<key>UIRequiredDeviceCapabilities</key>
<array>
    <string>arm64</string>
</array>
```

That's the entire change.

### Step 3 — Verify minimum deployment target is iOS 13+

While you're in the project settings, confirm `IPHONEOS_DEPLOYMENT_TARGET` is `13.0` or higher. iOS 12 was the last OS to support 32-bit; if we're targeting iOS 13+ (which we should be — SwiftUI requires it), `arm64` is correct and `armv7` was a copy-paste error from a template.

Check `ios/YourDateGenie.xcodeproj/project.pbxproj` for `IPHONEOS_DEPLOYMENT_TARGET` lines.

---

## Verification checklist

- [ ] `Info.plist` shows `<string>arm64</string>` inside `UIRequiredDeviceCapabilities`
- [ ] No occurrence of `armv7` anywhere in `ios/`
- [ ] `IPHONEOS_DEPLOYMENT_TARGET` is 13.0 or higher in project settings
- [ ] `xcodebuild -scheme YourDateGenie build` succeeds
- [ ] Archive + upload to App Store Connect (or `xcodebuild -exportArchive`) succeeds without "Invalid Required Architecture" error

## Out of scope

- Bumping the minimum deployment target if it's already 13+
- Any other Info.plist cleanup (separate tasks)

## When you're done

Tell me ("chief-of-staff, arm64 fixed") and I'll mark P0 #2 as complete.
