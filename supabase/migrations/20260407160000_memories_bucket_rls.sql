-- Ensure the Memories bucket exists (iOS uploads go here; case-sensitive name required).
-- safe to re-run: INSERT ... ON CONFLICT DO NOTHING
INSERT INTO storage.buckets (id, name, public)
VALUES ('Memories', 'Memories', false)
ON CONFLICT (id) DO NOTHING;

-- Drop any stale versions first so the migration is idempotent
DROP POLICY IF EXISTS "Memories: owner can upload"  ON storage.objects;
DROP POLICY IF EXISTS "Memories: owner can view"    ON storage.objects;
DROP POLICY IF EXISTS "Memories: owner can update"  ON storage.objects;
DROP POLICY IF EXISTS "Memories: owner can delete"  ON storage.objects;

-- INSERT: authenticated user may only upload into their own sub-folder.
-- iOS stores files at {user_id}/{uuid}.jpg so foldername(name)[1] == user_id.
CREATE POLICY "Memories: owner can upload"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'Memories'
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- SELECT: authenticated user may only read their own files
CREATE POLICY "Memories: owner can view"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'Memories'
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- UPDATE: authenticated user may only overwrite their own files
CREATE POLICY "Memories: owner can update"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'Memories'
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- DELETE: authenticated user may only remove their own files
CREATE POLICY "Memories: owner can delete"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'Memories'
  AND auth.uid()::text = (storage.foldername(name))[1]
);
