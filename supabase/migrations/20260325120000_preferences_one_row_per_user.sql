-- PostgREST upsert requires a UNIQUE (or PRIMARY KEY) constraint on the on_conflict columns.
-- Without this, POST ?on_conflict=user_id fails and the client cannot merge preference rows.
-- Safe when preferences is empty or has at most one row per user; if duplicates exist, dedupe before applying.

CREATE UNIQUE INDEX IF NOT EXISTS preferences_user_id_key ON public.preferences (user_id);
