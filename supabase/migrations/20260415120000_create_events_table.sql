-- Create the events table for the "Date Experiences" home screen section.
-- Fetched by the iOS app (is_active = true filter, ordered by date_time ASC).

create table if not exists public.events (
    id              uuid primary key default gen_random_uuid(),
    title           text        not null,
    description     text        not null default '',
    date_time       timestamptz not null,
    location        text        not null default '',
    image_url       text        not null default '',
    eventbrite_url  text        not null default '',
    is_active       boolean     not null default true,
    created_at      timestamptz not null default now(),
    updated_at      timestamptz not null default now()
);

-- Auto-update updated_at on row change
create or replace function public.set_events_updated_at()
returns trigger language plpgsql as $$
begin
    new.updated_at = now();
    return new;
end;
$$;

drop trigger if exists trg_events_updated_at on public.events;
create trigger trg_events_updated_at
    before update on public.events
    for each row execute function public.set_events_updated_at();

-- Index for the primary query: active events sorted by date
create index if not exists idx_events_active_date
    on public.events (is_active, date_time asc);

-- Enable Row Level Security
alter table public.events enable row level security;

-- Allow any authenticated or anonymous user to read active events
create policy "Anyone can read active events"
    on public.events
    for select
    using (is_active = true);

-- Only service role (admin) can insert / update / delete
create policy "Service role manages events"
    on public.events
    for all
    using (auth.role() = 'service_role')
    with check (auth.role() = 'service_role');

-- Sample seed data (optional — safe to remove in production)
insert into public.events (title, description, date_time, location, image_url, eventbrite_url, is_active)
values
(
    'Rooftop Jazz & Wine Evening',
    'An intimate evening of live jazz, curated wines, and panoramic city views. Perfect for couples who love music and fine dining under the stars.',
    now() + interval '7 days',
    'The Terrace, Downtown',
    'https://images.unsplash.com/photo-1511379938547-c1f69419868d?w=600&h=400&fit=crop',
    'https://www.eventbrite.com',
    true
),
(
    'Candlelit Art & Champagne',
    'Wander through exclusive gallery rooms lit only by candlelight, with champagne tastings and live acoustic music throughout the night.',
    now() + interval '14 days',
    'The Grand Gallery',
    'https://images.unsplash.com/photo-1536924940846-227afb31e2a5?w=600&h=400&fit=crop',
    'https://www.eventbrite.com',
    true
),
(
    'Sunset Yacht Dinner',
    'A private sunset cruise with a gourmet three-course dinner, signature cocktails, and unobstructed ocean views as the sky turns golden.',
    now() + interval '3 days',
    'Marina Bay Harbor',
    'https://images.unsplash.com/photo-1569263979104-865ab7cd8d13?w=600&h=400&fit=crop',
    'https://www.eventbrite.com',
    true
)
on conflict (id) do nothing;
