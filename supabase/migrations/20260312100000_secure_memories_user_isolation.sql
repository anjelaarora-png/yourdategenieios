-- =============================================================================
-- Secure memories: ensure photos never leak across accounts
-- =============================================================================
-- Problem: "Users can view public memories" and storage "public memories" bypass
-- allowed other users' memories to be visible. Fix: strict isolation by user_id.
-- =============================================================================

-- 1. Remove policy that let any user see other users' "public" memories.
--    Only the owner may SELECT their own rows (admin policy unchanged).
DROP POLICY IF EXISTS "Users can view public memories" ON public.date_memories;

-- 2. Storage: only allow reading objects in the current user's folder.
--    Drop the policy that allowed reading others' files via "public" memory rows.
DROP POLICY IF EXISTS "Users can view public memories or own memories" ON storage.objects;

CREATE POLICY "Users can view only own memory files"
ON storage.objects FOR SELECT
USING (
  bucket_id = 'date-memories'
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- 3. Ensure RLS is enabled (idempotent)
ALTER TABLE public.date_memories ENABLE ROW LEVEL SECURITY;
