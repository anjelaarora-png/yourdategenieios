# Cursor Task — Rotate Supabase anon key + remove hardcoded JWT from iOS binary

**Owner:** Anjela (Supabase dashboard) + Cursor (code edits)
**Specced by:** ios-developer agent + backend-developer agent
**Priority:** P0 — must complete before App Store submission 2026-05-18
**Estimated effort:** 30 min Cursor + 15 min Supabase dashboard

---

## Context for Cursor (paste this into Cursor's chat first)

`ios/YourDateGenie/Config.swift` contains a hardcoded fallback for the Supabase anon JWT (line 54). The fallback is the **real production anon key** — it shipped in the binary. Anyone who downloads the IPA can extract it.

Two-part fix:
1. **Anjela (manual):** rotate the anon key in the Supabase dashboard so the leaked one becomes invalid. Project ref: `jhpwacmsocjmzhimtbxj`.
2. **Cursor (this task):** remove the hardcoded fallback so the new key only exists in `Secrets.xcconfig` (which is git-ignored and not committed).

The anon key on its own is meant to be public-ish (it's the key the iOS client uses for unauthenticated requests, gated by Row Level Security). But a hardcoded fallback in source defeats the rotation strategy — once leaked, you can never rotate it without an app update. We want the key to live in `Secrets.xcconfig` only.

---

## Goal

After this task:
- `Config.swift` has no string literal for the Supabase anon JWT
- The anon key reads from Info.plist substitution from `Secrets.xcconfig` only
- If `Secrets.xcconfig` is missing, the app fails fast with a clear error (NOT a silent fallback to a baked-in key)
- The leaked production key (the one currently in `Config.swift:54`) has been rotated in the Supabase dashboard

---

## Existing infrastructure

- `ios/Secrets.xcconfig` — already used for `OPENAI_API_KEY` and `SUPABASE_URL`
- `ios/Info.plist` — already has `<key>SUPABASE_ANON_KEY</key><string>$(SUPABASE_ANON_KEY)</string>` substitution
- `ios/YourDateGenie/Config.swift` — has `static let supabaseAnonKey: String` reading from Info.plist with a fallback string

---

## Task breakdown

### Step 1 — Read `Config.swift` and confirm the leak

Open `ios/YourDateGenie/Config.swift`. Find the property that reads `SUPABASE_ANON_KEY` from `Bundle.main.infoDictionary` and falls back to a hardcoded `eyJhbG...` JWT (around line 54).

Confirm: that JWT decodes to project ref `jhpwacmsocjmzhimtbxj`. (You can paste it into jwt.io to verify — that's the project we're rotating.)

### Step 2 — Remove the hardcoded fallback

Replace the property body so there is no fallback string. Pattern:

```swift
// BEFORE
static let supabaseAnonKey: String = {
    if let key = Bundle.main.infoDictionary?["SUPABASE_ANON_KEY"] as? String, !key.isEmpty {
        return key
    }
    return "eyJhbGciOiJIUzI1NiIs..."  // <-- REMOVE THIS
}()

// AFTER
static let supabaseAnonKey: String = {
    guard let key = Bundle.main.infoDictionary?["SUPABASE_ANON_KEY"] as? String,
          !key.isEmpty,
          key != "$(SUPABASE_ANON_KEY)" else {
        fatalError("SUPABASE_ANON_KEY missing from Info.plist. Set it in ios/Secrets.xcconfig and rebuild.")
    }
    return key
}()
```

The `key != "$(SUPABASE_ANON_KEY)"` check catches the case where xcconfig substitution failed and the literal placeholder string ended up in Info.plist.

Apply the same hardening to `supabaseURL` if it has a fallback too.

### Step 3 — Update `validateConfiguration()`

If `Config.swift` has a `validateConfiguration()` static method that checks for missing keys, make sure it logs a clear error (not just a generic "config invalid") if Supabase keys are missing.

### Step 4 — Manual: Anjela rotates the key in Supabase dashboard

This step is NOT done in Cursor. Anjela does it:

1. Go to https://supabase.com/dashboard/project/jhpwacmsocjmzhimtbxj/settings/api
2. Click "Reset" next to the anon/public key (NOT the service_role key — that's separate)
3. Confirm the rotation
4. Copy the new anon key
5. Paste into `ios/Secrets.xcconfig`:
   ```
   SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiI...new key...
   ```
6. Update GitHub Actions / Xcode Cloud secrets if used
7. Rebuild the app — verify it still talks to Supabase

### Step 5 — Verify .gitignore

Confirm `ios/Secrets.xcconfig` is in `.gitignore` (or `ios/.gitignore`). If not, add it. The `.example` version stays in git as a template.

### Step 6 — Audit git history (separate concern, but flag it)

The leaked key was in git history. Even after rotation, anyone who cloned the repo before now has the old key. Since we're rotating the key, the old one is dead — but flag this to Anjela so she knows the surface area.

If she wants to scrub git history (BFG Repo-Cleaner), that's a separate task. Not required since we're rotating.

---

## Verification checklist

- [ ] No JWT string literal exists anywhere in `ios/YourDateGenie/Config.swift`
- [ ] Grepping the entire `ios/` tree for `eyJhbG` (the JWT prefix) returns zero hits
- [ ] `Secrets.xcconfig` is in `.gitignore`
- [ ] `Secrets.xcconfig.example` exists with placeholder values (not real keys) for new contributors
- [ ] Build with `Secrets.xcconfig` populated → app launches and successfully authenticates with Supabase
- [ ] Build with `SUPABASE_ANON_KEY` removed from `Secrets.xcconfig` → app crashes immediately with the clear error message (NOT silently using the old hardcoded key)
- [ ] Anjela has rotated the anon key in Supabase dashboard
- [ ] New key is in her local `Secrets.xcconfig` and any CI secrets

## Out of scope

- StoreKit receipt validation
- Service-role key (different key, different concern — should never be in iOS at all)
- Git history scrubbing (separate optional task)

## When you're done

Tell me ("chief-of-staff, anon key rotated") and I'll mark P0 #1 as complete.
