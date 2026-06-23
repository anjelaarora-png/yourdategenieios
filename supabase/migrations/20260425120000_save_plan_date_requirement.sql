-- Enforce "Save Plan with Date Requirement" feature.
--
-- Rules:
--   status = 'draft'  → plan is saved locally but has no planned date yet
--   status = 'saved'  → plan has a confirmed planned date (date_scheduled IS NOT NULL)
--
-- Migration tasks:
--   1. Backfill existing rows so status is consistent with date_scheduled presence.
--   2. Add a check constraint that prevents status='saved' without a date.
--   3. Leave all other statuses (completed, scheduled, confirmed) untouched.

-- ─── 1. Backfill existing rows ────────────────────────────────────────────────

-- "generated" without a date → draft
update public.date_plans
set status = 'draft'
where status = 'generated'
  and date_scheduled is null;

-- "generated" with a date → saved
update public.date_plans
set status = 'saved'
where status = 'generated'
  and date_scheduled is not null;

-- "planned" with a date → saved
update public.date_plans
set status = 'saved'
where status = 'planned'
  and date_scheduled is not null;

-- "planned" without a date → draft
update public.date_plans
set status = 'draft'
where status = 'planned'
  and date_scheduled is null;

-- ─── 2. Check constraint ──────────────────────────────────────────────────────
-- A plan cannot have status='saved' without a planned date.
-- Using "not valid" so it only applies to future inserts/updates and does not
-- re-scan historical rows already handled above (safe for zero-downtime deploys).

alter table public.date_plans
  drop constraint if exists chk_saved_requires_date;

alter table public.date_plans
  add constraint chk_saved_requires_date
  check (
    status <> 'saved' or date_scheduled is not null
  )
  not valid;

-- Validate the constraint against current rows (fast after the backfill above).
alter table public.date_plans
  validate constraint chk_saved_requires_date;

-- ─── 3. Index to speed up "drafts" query (plans without a date) ───────────────
create index if not exists idx_date_plans_drafts
  on public.date_plans (user_id, status)
  where status = 'draft';
