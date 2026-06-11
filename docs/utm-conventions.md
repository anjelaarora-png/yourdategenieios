# UTM Parameter Conventions — Your Date Genie

Plausible auto-captures UTM params on every pageview. Use these conventions so
the Sources tab stays clean and comparable across launches.

## Format

```
https://yourdategenie.com/?utm_source=<source>&utm_medium=<medium>&utm_campaign=<campaign>
```

## Locked sources

| Channel | `utm_source` | `utm_medium` | Example link |
|---------|-------------|-------------|-------------|
| Instagram bio link | `instagram_bio` | `social` | `?utm_source=instagram_bio&utm_medium=social` |
| Instagram story swipe-up | `instagram_story` | `social` | `?utm_source=instagram_story&utm_medium=social` |
| TikTok bio link | `tiktok_bio` | `social` | `?utm_source=tiktok_bio&utm_medium=social` |
| TikTok video | `tiktok_video` | `social` | `?utm_source=tiktok_video&utm_medium=social&utm_campaign=<video_title>` |
| Reddit post/comment | `reddit` | `social` | `?utm_source=reddit&utm_medium=social&utm_campaign=r_dating` |
| In-person event (QR code) | `event` | `offline` | `?utm_source=event&utm_medium=offline&utm_campaign=poker_night_2026_05` |
| Email newsletter | `email` | `email` | `?utm_source=email&utm_medium=email&utm_campaign=launch_week` |
| Direct / unknown | *(omit UTM — Plausible shows "Direct")* | — | — |

## Funnel goals to configure in Plausible UI

Go to **Site Settings → Goals** and add:

| Goal name | Type |
|-----------|------|
| `Waitlist Signup` | Custom event |
| `App Store Click` | Custom event |
| `Pricing Viewed` | Custom event |
| `Waitlist Form Started` | Custom event |

**Recommended funnel:**
`Pageview /` → `Pricing Viewed` → `Waitlist Form Started` → `Waitlist Signup`

## Notes

- Plausible strips UTM params from the URL after capturing them — no ugly
  shareable links.
- `utm_content` is optional and not tracked by default; skip for v1.
- Never use UTM params on internal links (e.g. nav, CTA → /signup); they
  pollute source attribution.
