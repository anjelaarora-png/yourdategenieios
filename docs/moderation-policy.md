# Your Date Genie LLC — Moderation Policy (Internal)

**Version:** 1.0  
**Effective:** 2026-05-18 (App Store launch)  
**Owner:** Anjela Arora, Your Date Genie LLC  
**Contact:** hello@yourdategenie.com

---

## Why this document exists

Apple App Store Review Guideline §1.2 requires that apps with user-to-user interaction maintain:
- A mechanism for reporting offensive content
- A published contact method
- Timely responses to concerns

This document describes how Your Date Genie handles reports for v1.

---

## Scope

Your Date Genie's user-to-user surface is limited to the Couple Plan feature: one user sends a partner invite link; the recipient (exactly one person) accepts and contributes their date preferences. There are no open forums, group chats, or public profiles. However, Apple still expects the mechanisms below to be in place.

---

## Reporting mechanisms

Users can report a concern via two paths:

1. **In-app Report form** — "Report a Concern" in Settings → Support & Safety, or "Report a Concern" in the Plan Together waiting screen. Submits to `user_reports` table and triggers an email to hello@yourdategenie.com.
2. **Email** — Contact Support at hello@yourdategenie.com directly.

Reports are stored in the `user_reports` Supabase table with status: `pending | reviewed | resolved | dismissed`.

---

## Response SLA

| Report type | Response commitment |
|---|---|
| Safety concern (physical harm, threats) | Within 24 hours |
| Harassment | Within 48 hours |
| Inappropriate content | Within 48 hours |
| Spam | Within 72 hours |
| Other | Within 72 hours |

"Response" means the report status is updated in Supabase. The reporter is not automatically notified in v1 (manual review).

---

## Review process (v1 — manual)

1. Receive email notification at hello@yourdategenie.com.
2. Open Supabase Dashboard → Table Editor → `user_reports`.
3. Review the description and category. Look up `reporter_id` and `reported_id` in `auth.users` if needed.
4. Take one of these actions:
   - **Warn**: Email the reported user from hello@yourdategenie.com.
   - **Suspend**: Disable the user's account in Supabase Auth → Users.
   - **Dismiss**: Mark report `dismissed` with a note if unfounded.
   - **Resolve**: Mark report `resolved` after action taken.
5. Update `status` and `reviewed_at` in the `user_reports` table.

---

## Block feature

Users can Block & Unlink a partner session. Blocking:
- Cancels the current partner session.
- Inserts a row in `blocked_users` preventing the blocked user from creating new partner sessions where they would interact with the blocker.

Blocks are user-initiated and self-managed (users cannot see who has blocked them).

---

## Escalation

If a report involves credible threats of violence or illegal activity, forward to local law enforcement and respond to the user within 24 hours.

---

## Post-launch improvements (planned)

- Automated email confirmation to reporter when report is received.
- Admin dashboard for reviewing reports.
- Auto-block after N confirmed reports (v2).
