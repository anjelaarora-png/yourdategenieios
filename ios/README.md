# Your Date Genie - iOS App

Native SwiftUI iOS app for Your Date Genie.

## Setup

### Requirements
- Xcode 15.0+
- iOS 17.0+
- macOS Ventura or later
- Supabase project

### Getting Started

1. Open Xcode
2. Create a new iOS App project:
   - Product Name: `YourDateGenie`
   - Organization Identifier: `com.yourdategenie`
   - Interface: SwiftUI
   - Language: Swift

3. Copy the files from this directory into your Xcode project

4. Set up Supabase (see Supabase Setup section below)

5. Configure environment variables (see Configuration section)

6. Add the custom fonts (optional):
   - **Tangerine** (accent text like "Memories", "magical") from [Google Fonts](https://fonts.google.com/specimen/Tangerine) — add `Tangerine-Regular.ttf` and `Tangerine-Bold.ttf` to `YourDateGenie/Fonts/` and ensure they're in the app target. These must be listed in Info.plist `UIAppFonts` (already there).
   - **Inter** is not required; body text uses the system font (SF Pro) if Inter is not in the bundle. To use Inter, add the .ttf files and add their names to `UIAppFonts` in Info.plist.
   After adding or changing fonts, do a **Clean Build** (Product → Clean Build Folder) then rebuild.

## Supabase Setup

### 1. Create a Supabase Project

1. Go to [supabase.com](https://supabase.com) and create a new project
2. Note your project URL and anon key from Settings > API

### 2. Run Database Migrations

In the Supabase SQL Editor, run the migration from `database/migrations/001_initial_schema.sql`

This creates the following tables:
- `users` - User accounts
- `couples` - Couple relationships
- `preferences` - User/couple preferences
- `date_plans` - Date plan details with itinerary
- `date_memories` - Memories from completed dates
- `gift_suggestions` - Gift ideas with like/purchase tracking
- `playlists` - Generated playlists for dates

### 3. Configure Storage

1. Go to Storage in your Supabase dashboard
2. Create a new bucket called `memories`
3. Set the bucket to public or configure RLS policies as needed

### 4. Configure Authentication

1. Go to Authentication > Providers
2. Ensure Email provider is enabled
3. Configure email templates if desired

### 5. Set Up Row Level Security (Optional)

Add RLS policies to restrict data access:

```sql
-- Users can only access their own data
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own data" ON users
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can update own data" ON users
  FOR UPDATE USING (auth.uid() = user_id);

-- Similar policies for other tables...
```

## Configuration

### Environment Variables

Set the following environment variables in your scheme or Info.plist:

| Variable | Description |
|----------|-------------|
| `SUPABASE_URL` | Your Supabase project URL |
| `SUPABASE_ANON_KEY` | Your Supabase anon/public key |
| `OPENAI_API_KEY` | OpenAI API key for date plan generation |
| `GOOGLE_PLACES_API_KEY` | Google API key for address autocomplete, place details, and geocoding. Enable **Places API** (autocomplete + details) and **Geocoding API** in Google Cloud Console. |

See `ENV_TEMPLATE.txt` for a template.

### Adding to Info.plist

```xml
<key>SUPABASE_URL</key>
<string>$(SUPABASE_URL)</string>
<key>SUPABASE_ANON_KEY</key>
<string>$(SUPABASE_ANON_KEY)</string>
<key>OPENAI_API_KEY</key>
<string>$(OPENAI_API_KEY)</string>
<key>GOOGLE_PLACES_API_KEY</key>
<string>$(GOOGLE_PLACES_API_KEY)</string>
```

Then set the actual values in your Xcode scheme's environment variables.

## Project Structure

```
YourDateGenie/
├── YourDateGenieApp.swift      # App entry point
├── Config.swift                # Environment configuration
├── Managers/
│   ├── SupabaseService.swift   # Unified Supabase service (auth, db, storage)
│   ├── KeychainManager.swift   # Secure credential storage
│   └── ...
├── Models/
│   ├── DatabaseModels.swift    # Supabase table models
│   ├── UserProfileModels.swift # User profile models
│   ├── DatePlanModels.swift    # Date plan models
│   └── ...
├── Views/
│   ├── Auth/                   # Authentication views
│   ├── Onboarding/             # Onboarding flow
│   ├── Questionnaire/          # Date questionnaire
│   ├── DatePlan/               # Date plan display
│   ├── Memories/               # Memory gallery
│   └── ...
└── Theme/
    └── AppTheme.swift          # Brand colors, gradients, styles
```

## Brand Colors

| Color   | Hex       | Usage                    |
|---------|-----------|--------------------------|
| Maroon  | `#8C383A` | Primary brand color      |
| Gold    | `#C7A677` | Accents, CTAs, highlights|
| Cream   | `#FAF8F3` | Backgrounds              |

## Architecture

### Data Layer - Supabase

All data is stored in Supabase which provides:
- **PostgreSQL Database** - Structured data (users, plans, memories, etc.)
- **Authentication** - Email/password auth with JWT tokens
- **Storage** - Image storage for memory photos
- **Keychain** - Local secure credential storage

### SupabaseService

A unified service that handles:
- Authentication (sign up, sign in, sign out, password reset)
- Database CRUD operations for all 7 tables
- Storage operations (upload, get URL, delete)
- Session management with automatic token refresh

### Image Storage

- Images are uploaded to Supabase Storage `memories` bucket
- Only the storage path is stored in the database (`photo_urls` column)
- Public URLs or signed URLs are generated on-demand

## Database Schema

### Tables

| Table | Description |
|-------|-------------|
| `users` | User accounts with profile info |
| `couples` | Couple relationships |
| `preferences` | User/couple date preferences |
| `date_plans` | Full date plans with JSONB itinerary |
| `date_memories` | Memories with ratings and photos |
| `gift_suggestions` | Gift ideas with like/purchase state |
| `playlists` | Generated playlists with tracks |

### Key Features

- **Gift Suggestions**: 
  - `liked = NULL` → Unseen, eligible to suggest
  - `liked = TRUE` → Liked by user
  - `liked = FALSE` → Skipped, never suggest again
  - `purchased = TRUE` → Already bought, exclude from future suggestions

- **Date Plans**:
  - `plan_options` JSONB stores A/B/C options summary
  - `itinerary` JSONB stores detailed stops with travel info
  - `status` tracks plan state (planned, completed, cancelled)

## Security

- Auth tokens stored in iOS Keychain, never UserDefaults
- Tokens automatically refresh before expiration
- Supabase RLS policies can restrict data access
- Never commit credentials to version control
