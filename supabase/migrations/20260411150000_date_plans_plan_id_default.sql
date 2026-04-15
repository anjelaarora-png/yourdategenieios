-- Ensure plan_id always auto-generates on INSERT so new iOS-originated rows
-- (which only send the `id` field, not `plan_id`) succeed without a NOT NULL violation.
-- Safe to run more than once — SET DEFAULT is idempotent.

ALTER TABLE public.date_plans
  ALTER COLUMN plan_id SET DEFAULT gen_random_uuid();
