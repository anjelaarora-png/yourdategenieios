-- Remove seed / placeholder events inserted by 20260415120000_create_events_table.sql.
-- Those rows used eventbrite_url = 'https://www.eventbrite.com' as a placeholder.
-- Real events imported via the import-eventbrite-event function will have full URLs.

DELETE FROM public.events
WHERE eventbrite_url = 'https://www.eventbrite.com';
