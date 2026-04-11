-- Persist the in-progress love note draft to Supabase so it survives reinstalls
-- and roams across devices alongside the rest of the user_ios_sync_payload.
ALTER TABLE public.user_ios_sync_payload
  ADD COLUMN IF NOT EXISTS love_note_draft jsonb;
