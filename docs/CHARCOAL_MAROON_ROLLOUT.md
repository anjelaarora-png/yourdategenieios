# Charcoal Maroon UI Rollout — Your Date Genie iOS

Phased rollout of the **Charcoal Maroon** redesign (itinerary-first Home, competence tone, maroon-as-accent-only).

Reference mockups: `mockups/charcoal-maroon-prototype.html`, `mockups/feature-parity-map.html`

---

## Phases completed (this pass)

| Phase | Scope | Status |
|-------|--------|--------|
| **1** | Theme tokens in `AppTheme.swift` — semantic Charcoal Maroon palette + legacy alias mapping | Done |
| **2** | `HomeTabView` — itinerary hero card, Shortcuts collapsible, section reorder, no particles, Georgia greeting | Done |
| **3** | `ConvoTabView` segment renames, `LuxuryTabBar` maroon underline on charcoal | Done |
| **4** | Copy sweep — Home sublines, `PaywallView`, `AuthenticationView`, `LoveNoteGeneratorView` header | Done |
| **5** | `MagicalLoadingView` — reduced confetti/petals/sparkles, serif title, competence copy | Done |
| **6** | Shell backgrounds — Dates, Profile, Explore, questionnaire, onboarding, result/options screens → `backgroundPrimary` / cream cards | Done |
| **7** | Remove Tangerine from Settings shell, DatePlanResult, ConversationStarters/Sparks, Gifts, Memories, questionnaire section headers | Done |
| **8** | Dates tab — cream itinerary-style plan rows with maroon left border | Done |
| **9** | Profile / You tab — cream stat cards, partner strip, elevated menu rows, ghost footer actions | Done |
| **10** | Swap-stop bottom sheet on hero — placeholder alternates, local plan update (no re-questionnaire) | Done |
| **11** | Global audit (high-traffic pass) — onboarding titles, Love Note, auth, partner, playlist, splash/sign-up shells | Done |
| **12** | Stragglers cleanup — tangerine removal, maroon→charcoal shells, dead code | Done |

### Files changed (phase 12 — stragglers cleanup)

- `ios/YourDateGenie/Theme/AppTheme.swift` — `Font.displaySerif`, magical helpers → Georgia; Tangerine deprecated
- `ios/YourDateGenie/Views/HeroView.swift`
- `ios/YourDateGenie/Views/SignUp/PreferencesSetupView.swift`
- `ios/YourDateGenie/Views/Playbook/PlaybookView.swift`
- `ios/YourDateGenie/Views/Profile/HelpSupportSheetView.swift`
- `ios/YourDateGenie/Views/Safety/ReportConcernView.swift`
- `ios/YourDateGenie/Views/Business/BusinessOnboardingView.swift`
- `ios/YourDateGenie/Views/Business/BusinessApplicationFormView.swift`
- `ios/YourDateGenie/Views/Business/BusinessPortalView.swift`
- `ios/YourDateGenie/Views/Questionnaire/Steps/Step1LocationView.swift`
- `ios/YourDateGenie/Views/Questionnaire/Steps/Step6ExtrasView.swift`
- `ios/YourDateGenie/Views/Onboarding/HomeTutorialOverlayView.swift`
- `ios/YourDateGenie/Views/Playlist/MusicRecordAnimationView.swift` (preview bg)
- `ios/YourDateGenie/Views/Gifts/GiftUnwrapView.swift` (preview bg)
- `ios/YourDateGenie/Views/Gifts/GiftBoxOpenCelebrationView.swift` (modal card)
- `ios/YourDateGenie/Views/Generation/MagicalLoadingView.swift` (`GenerationErrorView` shell)
- `ios/YourDateGenie/Navigation/HomeTabView.swift` — removed dead `FloatingParticlesView`
- `ios/YourDateGenie/Views/Questionnaire/Components/OptionCardView.swift` (preview bg)
- `ios/YourDateGenie/Views/Questionnaire/Components/PlacesAutocompleteField.swift` (preview bg)

### Files changed (phases 9–11)

- `ios/YourDateGenie/Navigation/ProfileTabView.swift`
- `ios/YourDateGenie/Navigation/HomeCharcoalComponents.swift` — `SwapStopSheet`, `SwapStopLogic`, `DatePlan.replacingStop`
- `ios/YourDateGenie/Navigation/HomeTabView.swift`
- `ios/YourDateGenie/Views/Onboarding/OnboardingView.swift`
- `ios/YourDateGenie/Views/LoveNote/LoveNoteGeneratorView.swift`
- `ios/YourDateGenie/Views/Auth/AuthenticationView.swift`
- `ios/YourDateGenie/Views/SignUp/SignUpView.swift`
- `ios/YourDateGenie/Navigation/SplashView.swift`
- `ios/YourDateGenie/Views/LandingView.swift`
- `ios/YourDateGenie/Views/PartnerPlanning/PartnerPlanningSheetView.swift`
- `ios/YourDateGenie/Views/PartnerPlanning/PartnerJoinView.swift`
- `ios/YourDateGenie/Views/PartnerPlanning/PartnerRankingView.swift`
- `ios/YourDateGenie/Views/PartnerPlanning/PlanGeneratingView.swift`
- `ios/YourDateGenie/Views/PartnerPlanning/FinalDateRevealView.swift`
- `ios/YourDateGenie/Views/Playlist/PlaylistWidgetView.swift`
- `ios/YourDateGenie/Views/Playlist/SavedPlaylistsView.swift`
- `ios/YourDateGenie/Views/Playlist/SongSearchView.swift`
- `ios/YourDateGenie/Views/DatePlan/DatePickerSheet.swift`

### Files changed (phases 6–8)

- `ios/YourDateGenie/Navigation/DatesTabView.swift`
- `ios/YourDateGenie/Navigation/ExploreTabView.swift`
- `ios/YourDateGenie/Navigation/GiftsTabView.swift`
- `ios/YourDateGenie/Views/Questionnaire/QuestionnaireView.swift`
- `ios/YourDateGenie/Views/Questionnaire/Components/OptionCardView.swift`
- `ios/YourDateGenie/Views/Onboarding/OnboardingView.swift` *(shell bg only in phase 6; titles in phase 11)*
- `ios/YourDateGenie/Views/DatePlan/DatePlanResultView.swift`
- `ios/YourDateGenie/Views/DatePlan/DatePlanOptionsView.swift`
- `ios/YourDateGenie/Views/Profile/SettingsSheetView.swift`
- `ios/YourDateGenie/Views/ConversationStarters/ConversationStartersView.swift`
- `ios/YourDateGenie/Views/ConversationStarters/SparksDeckView.swift`
- `ios/YourDateGenie/Views/Gifts/GiftFinderView.swift`
- `ios/YourDateGenie/Views/Gifts/StoredGiftRowView.swift`
- `ios/YourDateGenie/Views/Gifts/BigGiftUnwrapView.swift`
- `ios/YourDateGenie/Views/Memories/MemoryGalleryView.swift`

### Files changed (phases 1–5)

- `ios/YourDateGenie/Theme/AppTheme.swift`
- `ios/YourDateGenie/Navigation/HomeCharcoalComponents.swift` *(new)*
- `ios/YourDateGenie/Navigation/HomeTabView.swift`
- `ios/YourDateGenie/Navigation/ConvoTabView.swift`
- `ios/YourDateGenie/Navigation/LuxuryTabBar.swift`
- `ios/YourDateGenie/Navigation/MainAppView.swift`
- `ios/YourDateGenie/Views/Subscription/PaywallView.swift`
- `ios/YourDateGenie/Views/Auth/AuthenticationView.swift`
- `ios/YourDateGenie/Views/LoveNote/LoveNoteGeneratorView.swift`
- `ios/YourDateGenie/Views/Generation/MagicalLoadingView.swift`

---

## Remaining stragglers (low-traffic / post-launch)

Verified in Phase 5 (acceptance pass). Most prior straggler entries were already converted in phases 9–12; the table below reflects current ground truth:

| File | Status (Phase 5 audit) |
|------|--------|
| `ReservationPlatformPickerSheet.swift` | ✅ Already charcoal shell + `displaySerif` title (no maroon shell) |
| `DateExperiencesSection.swift` | ✅ **Resolved Phase 5** — EventDetail/EventCard shells converted maroon → charcoal, hex → tokens |
| `EventImportView.swift` | ✅ **Resolved Phase 5** — maroon shell + toolbar → charcoal, hex → tokens |
| `LockedPremiumTabPlaceholder.swift` | ✅ Already charcoal shell + `displaySerif` title |
| `NotificationViews.swift` | ✅ Already charcoal shell; `C9A84C` accent → `accentGold` (Phase 5). Per-type category accents intentional |
| `PastMagicView.swift` | ✅ Already charcoal shell |
| `PlaylistWidgetView.swift` | Platform brand colors (Spotify/Apple/YouTube) intentional; shell charcoal |
| `ConversationStartersView.swift` | Charcoal shell; topic chips use accent maroon (acceptable accent) |
| `SignUpView.swift` | Charcoal shell; maroon used as accent only |

### Flagged color follow-ups — resolved (Phase 5)

1. **`luxuryMaroonLight` as card/chip fill** — ✅ Verified. Alias maps to `surfaceElevated` (`#242424` charcoal), so every call site renders as a charcoal surface, not maroon. Used in ~200 spots across option cards, plan result chips, Explore filters. No rename needed; behavior is correct.
2. **Swap stop alternates** — ⏭ Re-classified as a **backend follow-up** (not a color issue). Phase 10 uses placeholder venues; wire to Google Places / AI suggestions and persist swap to Supabase in a future pass. See Backend follow-ups.
3. **`Font.tangerine` legacy path** — ✅ Resolved. Zero call sites remained; the deprecated `Font.tangerine(_:weight:)` function and the unused `Color.tangerine` alias were removed from `AppTheme.swift`. `Font.displaySerif` is the sole in-app display face. (Marketing `.ttf` registration in `Info.plist` left untouched — out of scope.)

---

## Design token reference

| Token | Hex / value | Use |
|-------|-------------|-----|
| `backgroundPrimary` | `#1A1A1A` | Screen background (charcoal) |
| `surfaceElevated` | `#242424` | Cards, tab bar segments, raised surfaces |
| `creamCard` | `#F5F0E8` | Itinerary hero card background |
| `accentGold` | `#C9A84C` | Primary CTA, section labels, active tab label |
| `accentMaroon` | `#4A0E0E` | **Accent only** — hero left border, tab underline, partner strip |
| `textPrimary` | `#FAFAF8` | Body text on dark |
| `textOnCard` | `#1A1A1A` | Text on cream cards |
| `textMutedOnCard` | `#888888` | Secondary text on cream cards |
| `maroonBorderTint` | `#4A0E0E` @ 15% | Card borders |

**Legacy aliases** (still in codebase): `luxuryMaroon` → accent maroon, `luxuryMaroonLight` → surface, `luxuryGold` → accent gold, `luxuryCream` → text primary.

**Typography:** Georgia / system serif for display headers on functional screens. **No Tangerine** on Home, Convo, Paywall, Auth headers, loading, Dates, Profile, Settings, plan result shell, gifts hub, memories, conversation cues, onboarding, Love Note, partner planning, playlist, splash, or sign-up.

---

## Manual QA checklist (Anjela)

### Home
- [ ] Background is charcoal `#1A1A1A`, not full-screen maroon
- [ ] No floating particles on Home
- [ ] Greeting uses serif (not Tangerine); subline shows when a plan exists
- [ ] Hero shows cream itinerary card with maroon left border when plan exists
- [ ] Approve saves unsaved plan / opens calendar for saved plan
- [ ] View full plan opens result or options sheet
- [ ] **Swap stop** opens bottom sheet with 2–3 alternates; selecting one updates dinner stop on hero (no questionnaire)
- [ ] **Shortcuts** section expanded by default; Upcoming / Near you / Your story collapsed
- [ ] "Send to partner" shortcut opens partner share

### Profile / You (new)
- [ ] Tab title reads **You**; charcoal shell
- [ ] Stats are cream cards with gold numerals
- [ ] Partner strip shows when `PartnerSessionManager` has active invite/session
- [ ] Menu list on `surfaceElevated`; restore/sign-out are ghost-outline buttons

### Tabs
- [ ] Tab bar charcoal with gold active label + maroon underline
- [ ] Center Plan button gold with charcoal plus icon

### Dates tab
- [ ] Screen bg charcoal; segment picker matches Convo (elevated capsule + maroon underline)
- [ ] Plan rows are cream cards with maroon left border
- [ ] Memories segment embeds updated gallery shell

### Convo
- [ ] Segments read **Note drafts** / **Conversation cues**
- [ ] Conversation cues hub + sparks deck use serif headers

### Paywall & Auth
- [ ] No sparkles icon in paywall header
- [ ] Auth / sign-up / splash use charcoal + serif (no Tangerine titles)

### Partner & playlist (new)
- [ ] Partner planning sheets charcoal; no floating particles
- [ ] Saved playlists + song search charcoal shell

### Regression
- [ ] All shortcuts still reachable and premium gates work
- [ ] Pull-to-refresh on Near you still loads places
- [ ] Build succeeds on device + simulator

---

## Notes for Anjela

1. **Section collapse defaults** use `@AppStorage` keys (`home_*_expanded`). Reset in Settings → delete app or clear keys to test first-run collapse state.
2. **Swap stop** updates local coordinator state; saved plans persist in local store + cloud upload on next save sync. Placeholder venues until Places-backed alternates ship.
3. **`xcodebuild -scheme YourDateGenie -destination 'platform=iOS Simulator,name=iPhone 17' build`** — succeeded 2026-06-22 (phase 12 stragglers pass).
4. No backend, migration, or `Secrets.xcconfig` changes in this pass.

---

*Last updated: 2026-06-22 (phase 12 — rollout complete for launch-critical paths)*
