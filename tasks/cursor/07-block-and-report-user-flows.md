# Cursor Task — Add Block + Report user flows (Apple §1.2 dating app requirement)

**Owner:** Anjela (executing in Cursor)
**Specced by:** ios-developer agent + backend-developer agent
**Priority:** P0 — Apple §1.2 explicitly requires this for any app where users interact with each other
**Estimated effort:** 3–4 hours

---

## Context for Cursor

Apple App Store Review Guideline §1.2 (User-Generated Content / Social) requires that any app facilitating user-to-user interaction must provide:

1. **A method for filtering objectionable content**
2. **A mechanism to report offensive content and timely responses to concerns**
3. **The ability to block abusive users from the service**
4. **Published contact information so users can easily reach you**

Your Date Genie has a Couple Plan feature — once two partners are linked, they can interact. While the surface area is much smaller than a Tinder/Bumble (only one paired partner, not strangers), Apple still expects these mechanisms to exist on any user-to-user app. The Couple Plan invite/accept flow is where this matters most.

---

## Goal

The app provides:
- A "Block this partner" / "Unlink couple" action that severs the couple relationship and prevents future invites from that partner
- A "Report a concern" action that opens a mailto: link or in-app form sending to a moderation inbox
- Published contact: `hello@yourdategenie.com` (already in app metadata; verify it's also in-app)

Backend:
- A `blocked_users` table that tracks block relationships
- RLS policies that prevent blocked users from sending new couple invites or seeing the blocker's profile

---

## Locked decisions to use

- **Support / moderation contact:** `hello@yourdategenie.com`
- **Legal entity:** Your Date Genie LLC

---

## Task breakdown

### Step 1 — Database: create `blocked_users` table

New migration: `supabase/migrations/<timestamp>_blocked_users_table.sql`

```sql
CREATE TABLE public.blocked_users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    blocker_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    blocked_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    reason TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(blocker_id, blocked_id)
);

CREATE INDEX idx_blocked_users_blocker ON public.blocked_users(blocker_id);
CREATE INDEX idx_blocked_users_blocked ON public.blocked_users(blocked_id);

ALTER TABLE public.blocked_users ENABLE ROW LEVEL SECURITY;

-- Users can see their own block list
CREATE POLICY "Users can view their own blocks"
    ON public.blocked_users
    FOR SELECT
    USING (auth.uid() = blocker_id);

-- Users can create blocks for themselves
CREATE POLICY "Users can create blocks"
    ON public.blocked_users
    FOR INSERT
    WITH CHECK (auth.uid() = blocker_id);

-- Users can delete (unblock) their own blocks
CREATE POLICY "Users can unblock"
    ON public.blocked_users
    FOR DELETE
    USING (auth.uid() = blocker_id);
```

### Step 2 — Update couple_invites RLS to respect blocks

Add a policy or update existing policy on `couple_invites` (or whatever the invite table is called) so a user cannot send an invite to someone who has blocked them, and cannot accept an invite from someone they've blocked.

```sql
-- Prevent invite to blocked user
CREATE POLICY "Cannot invite blocked users"
    ON public.couple_invites
    FOR INSERT
    WITH CHECK (
        NOT EXISTS (
            SELECT 1 FROM public.blocked_users
            WHERE blocker_id = NEW.invitee_id AND blocked_id = auth.uid()
        )
    );
```

(Adjust column names to match the actual `couple_invites` schema — read the existing migration first.)

### Step 3 — Add a Reports table

`supabase/migrations/<timestamp>_user_reports_table.sql`:

```sql
CREATE TABLE public.user_reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reporter_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE SET NULL,
    reported_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    category TEXT NOT NULL CHECK (category IN ('harassment', 'inappropriate_content', 'spam', 'safety', 'other')),
    description TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'reviewed', 'resolved', 'dismissed')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    reviewed_at TIMESTAMPTZ
);

ALTER TABLE public.user_reports ENABLE ROW LEVEL SECURITY;

-- Users can create reports
CREATE POLICY "Users can create reports"
    ON public.user_reports
    FOR INSERT
    WITH CHECK (auth.uid() = reporter_id);

-- Users can see their own reports
CREATE POLICY "Users can view own reports"
    ON public.user_reports
    FOR SELECT
    USING (auth.uid() = reporter_id);
```

### Step 4 — Edge Function: `submit-report`

`supabase/functions/submit-report/index.ts`:

Accepts POST with `{ reportedId?: string, category: string, description: string }`. Verifies bearer JWT. Inserts into `user_reports`. Sends an email to `hello@yourdategenie.com` with the report contents (use Resend or whatever the project uses for `notify-new-signup`).

Mirror the structure of `notify-new-signup/index.ts` (already in the repo) for the email send.

### Step 5 — iOS: Add UI to Couple settings screen

In whatever view shows the linked partner / couple settings (likely something like `CoupleSettingsView.swift` or in the main `SettingsView.swift`), add two action buttons:

```swift
Section("Safety") {
    Button(role: .destructive) {
        showingUnlinkConfirmation = true
    } label: {
        Label("Unlink Partner", systemImage: "person.crop.circle.badge.xmark")
    }

    Button {
        showingReportSheet = true
    } label: {
        Label("Report a Concern", systemImage: "exclamationmark.bubble")
    }
}
```

The "Unlink Partner" action should:
1. Confirm via alert
2. Call a Supabase RPC or direct table update to break the couple relationship
3. Insert a row into `blocked_users` (so they can't re-invite)
4. Pop back to the unpaired state

### Step 6 — iOS: Report sheet

Create `ios/YourDateGenie/Views/Safety/ReportConcernView.swift`:

```swift
import SwiftUI

struct ReportConcernView: View {
    @Environment(\.dismiss) var dismiss
    @State private var category: ReportCategory = .other
    @State private var description: String = ""
    @State private var isSubmitting = false
    @State private var submitError: String?

    enum ReportCategory: String, CaseIterable, Identifiable {
        case harassment = "Harassment"
        case inappropriateContent = "Inappropriate content"
        case spam = "Spam"
        case safety = "Safety concern"
        case other = "Other"
        var id: String { rawValue }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Category") {
                    Picker("Category", selection: $category) {
                        ForEach(ReportCategory.allCases) { cat in
                            Text(cat.rawValue).tag(cat)
                        }
                    }
                }

                Section("Describe what happened") {
                    TextEditor(text: $description)
                        .frame(minHeight: 120)
                }

                Section {
                    Button("Submit Report") {
                        submit()
                    }
                    .disabled(description.isEmpty || isSubmitting)
                }

                if let error = submitError {
                    Text(error).foregroundColor(.red)
                }
            }
            .navigationTitle("Report a Concern")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func submit() {
        isSubmitting = true
        Task {
            do {
                try await SupabaseService.shared.submitReport(
                    category: category.rawValue.lowercased(),
                    description: description
                )
                dismiss()
            } catch {
                submitError = error.localizedDescription
                isSubmitting = false
            }
        }
    }
}
```

Add `submitReport(category:description:)` method to `SupabaseService.swift` calling the Edge Function.

### Step 7 — Add a "Contact Us" link in Settings

In `SettingsView.swift`, add:

```swift
Section("Support") {
    Link(destination: URL(string: "mailto:hello@yourdategenie.com")!) {
        Label("Contact Support", systemImage: "envelope")
    }
}
```

### Step 8 — Document moderation response SLA

Create `docs/moderation-policy.md` (internal) committing to a 48-hour response time on reports. App Store reviewers may ask about your moderation process; having this internal doc helps.

---

## Verification checklist

- [ ] `blocked_users` migration applies cleanly: `supabase db push`
- [ ] `user_reports` migration applies cleanly
- [ ] `submit-report` Edge Function deploys: `supabase functions deploy submit-report`
- [ ] Submitting a report from the iOS app inserts a row into `user_reports`
- [ ] Submitting a report sends an email to `hello@yourdategenie.com`
- [ ] "Unlink Partner" successfully breaks the couple relationship
- [ ] After unlinking, the unlinked partner cannot send a new invite (RLS rejects)
- [ ] "Contact Support" mailto: link opens Mail app pre-filled to `hello@yourdategenie.com`
- [ ] Reports table is hidden from the reported user (RLS — only reporter can see their own reports)
- [ ] All UI strings are user-friendly (no "JWT" / "RLS" / "RPC" jargon visible to users)

## Out of scope

- Admin moderation dashboard (we'll review reports manually via Supabase dashboard for v1)
- Auto-blocking after N reports (manual review only for v1)
- Web app version of these flows (web app doesn't have couple interaction yet)

## When you're done

Tell me ("chief-of-staff, block and report done") and I'll add this as resolved P0+ (it was missed on the original P0 list — explicitly required by §1.2).
