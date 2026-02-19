-- Fix 1: Make date-memories bucket private
UPDATE storage.buckets 
SET public = false 
WHERE id = 'date-memories';

-- Fix 2: Drop existing storage policies for date-memories
DROP POLICY IF EXISTS "Users can view memories" ON storage.objects;
DROP POLICY IF EXISTS "Users can view their own memories" ON storage.objects;
DROP POLICY IF EXISTS "Users can upload memories" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete memories" ON storage.objects;

-- Create proper storage policies for date-memories bucket
CREATE POLICY "Users can view public memories or own memories" 
ON storage.objects FOR SELECT
USING (
  bucket_id = 'date-memories' AND (
    -- Allow owner to view their own memories
    auth.uid()::text = (storage.foldername(name))[1]
    OR
    -- Allow public memories
    EXISTS (
      SELECT 1 FROM public.date_memories dm
      WHERE dm.image_url LIKE '%' || name
      AND dm.is_public = true
    )
  )
);

CREATE POLICY "Users can upload to their own folder" 
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'date-memories' AND 
  auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "Users can update their own files" 
ON storage.objects FOR UPDATE
USING (
  bucket_id = 'date-memories' AND 
  auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "Users can delete their own files" 
ON storage.objects FOR DELETE
USING (
  bucket_id = 'date-memories' AND 
  auth.uid()::text = (storage.foldername(name))[1]
);

-- Fix 4: Add admin-only policy for profiles to protect user_stats view
-- First drop existing policy if it exists
DROP POLICY IF EXISTS "Admins can view all profiles" ON public.profiles;

-- Create policy allowing admins to view all profiles (required for user_stats view)
CREATE POLICY "Admins can view all profiles"
ON public.profiles FOR SELECT
USING (
  auth.uid() = user_id OR
  public.has_role(auth.uid(), 'admin')
);