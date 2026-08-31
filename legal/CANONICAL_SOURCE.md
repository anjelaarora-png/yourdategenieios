# Which legal documents are canonical?

_Last reconciled: 2026-08-30_

## Canonical: the live WordPress pages

| Document | Canonical URL | WP page |
| --- | --- | --- |
| Terms of Service | https://yourdategenie.com/terms-of-service/ | `68358` |
| Privacy Policy | https://yourdategenie.com/privacy-policy/ | `12954` |

`https://yourdategenie.com/terms` 301-redirects to the Terms page, and `/privacy`
redirects to the Privacy page. Those URLs are what the iOS app links to
(`AuthenticationView`, `PaywallView`, `SettingsSheetView`) and what was given to
App Review, so **they must never be repointed without updating the app.**

The page is one Elementor HTML widget (element id `cce191e`) holding the entire
page — fonts, CSS, nav, and all 32 sections. There are no per-section widgets.

Lineage: `legal/Terms_of_Service_v2.0_*` (2026-06-18) → pasted into WordPress →
edited in place since. The v2.0 files are a historical snapshot, **not** a live mirror.

## Do not use these as a paste source

Three separate lineages exist in this repo and they contradict each other:

| Lineage | Files | Law | Min age | Cap | Forum |
| --- | --- | --- | --- | --- | --- |
| **v2.0 — canonical** | `legal/Terms_of_Service_v2.0_*`, live page | **New Jersey** | **18** | **$25** | AAA |
| NY draft | `wordpress-content/terms-of-use.html`, `src/pages/Terms.tsx` | New York | 17 | $50 | JAMS |
| CA draft | `legal/terms-of-service-draft.md` | California | — | — | AAA |

Superseded and kept only for history: `Terms_of_Service_PREVIEW.html`,
`Terms_of_Service_v1.0_2026-06-18_PUBLISH.html`,
`Your_Date_Genie_Terms_of_Service_v1.0_2026-06-04.docx`.

## Resolved: the React app no longer serves legal pages (2026-08-30)

`src/pages/Terms.tsx` used to be routed at `/terms` in the React app and carried the
New York / 17+ / $50 / JAMS text. It was only shadowed by WordPress on the live
domain, so any Vercel deploy or shared preview URL would have published terms
contradicting the canonical page. Resolved by:

- `vercel.json` — server-level 301 from `/terms` to the canonical page, evaluated
  before the SPA catch-all rewrite
- `src/App.tsx` — `/terms` route and the lazy import removed
- `Footer.tsx` and `PrivacyPolicy.tsx` — client-side `<Link to="/terms">` replaced with
  real `<a href>` anchors (a React Router `Link` never reaches the server, so it would
  have bypassed the redirect)
- `src/pages/Terms.tsx` and `src/pages/PrivacyPolicy.tsx` — deleted; both recoverable
  from git history (last in `e904cc5`)

Verified: `npm run build` succeeds and `dist/` contains neither a `Terms-*.js` nor a
`PrivacyPolicy-*.js` chunk.

The Privacy Policy received the identical treatment the same day:
`src/pages/PrivacyPolicy.tsx` deleted, its `/privacy` and `/privacy-policy` routes
removed, both paths redirected in `vercel.json`, and the Footer link converted to a
real anchor. **The React app no longer serves any legal document.**

## Claims in the Terms that depend on the app (re-verify before each submission)

Verified against the iOS source on 2026-08-30:

| Claim in Terms | Where it lives in code | Status |
| --- | --- | --- |
| Objectionable-language filter on partner invites, messages, notes | `Utilities/ObjectionableContentFilter.swift`, used in `PartnerShareView`, `PartnerJoinView`, `PartnerPlanningSheetView` | verified |
| `Plan Together → Report a Concern` | `PartnerPlanningSheetView.swift:1588` → `Views/Safety/ReportConcernView.swift` | verified |
| `Plan Together → Block & Unlink Partner` | `PartnerPlanningSheetView.swift:1576` | verified |
| `Settings → Support & safety → Report a Concern` | `SettingsSheetView.swift:387,426` | verified |
| No-tolerance statement in EULA before login | `AuthenticationView.swift:230` | verified |
| Review reports within 24 hours, act as warranted | `ReportConcernView.swift:68,194` — matching wording | verified |
| Partner sees a preference summary, not account identifiers | — | **unverified** |

`Settings → Partner → Unlink` was cited in the Terms until 2026-08-30 and **does not
exist**; the real control is `Plan Together → Block & Unlink Partner`. Corrected on
the live page and in `wordpress-content/terms-of-use.html`.
