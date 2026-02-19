-- Add rating column to date_plans for tracking user satisfaction
ALTER TABLE public.date_plans 
ADD COLUMN rating integer CHECK (rating >= 1 AND rating <= 5),
ADD COLUMN rating_notes text;