-- Add columns for gift suggestions and conversation starters
ALTER TABLE public.date_plans
ADD COLUMN gift_suggestions jsonb DEFAULT '[]'::jsonb,
ADD COLUMN conversation_starters jsonb DEFAULT '[]'::jsonb;