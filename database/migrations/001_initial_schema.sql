-- YourDateGenie PostgreSQL Database Schema
-- Run this migration to create all required tables

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ===========================================
-- Table 1: users
-- ===========================================
CREATE TABLE users (
  user_id UUID PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash TEXT DEFAULT '',
  gender VARCHAR(50),
  birthday DATE,
  home_address TEXT,
  travel_mode VARCHAR(50),
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_users_email ON users(email);

-- ===========================================
-- Table 2: couples
-- ===========================================
CREATE TABLE couples (
  couple_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id_1 UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  user_id_2 UUID REFERENCES users(user_id) ON DELETE SET NULL,
  relationship_type VARCHAR(100),
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_couples_user1 ON couples(user_id_1);
CREATE INDEX idx_couples_user2 ON couples(user_id_2);

-- ===========================================
-- Table 3: preferences
-- ===========================================
CREATE TABLE preferences (
  preference_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  couple_id UUID REFERENCES couples(couple_id) ON DELETE SET NULL,
  cuisine_types TEXT[],
  activity_types TEXT[],
  drink_preferences TEXT[],
  budget_range VARCHAR(50),
  love_language VARCHAR(100),
  food_allergies TEXT[],
  hard_nos TEXT[],
  accessibility_needs TEXT[],
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_preferences_user ON preferences(user_id);
CREATE INDEX idx_preferences_couple ON preferences(couple_id);

-- ===========================================
-- Table 4: date_plans
-- ===========================================
CREATE TABLE date_plans (
  plan_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  couple_id UUID NOT NULL REFERENCES couples(couple_id) ON DELETE CASCADE,
  scheduled_at TIMESTAMP,
  plan_title VARCHAR(255),
  plan_tagline TEXT,
  selected_option CHAR(1),
  plan_options JSONB,
  /*
    plan_options JSONB structure:
    [
      {
        "option": "A",
        "title": "Classic SoHo Romance",
        "tagline": "Vinyl, Velvet, and Vino in the heart of SoHo",
        "duration_hours": 4.5,
        "budget_range": "$150-$250 per person",
        "venue_count": 3,
        "venues_verified": 3
      }
    ]
  */
  location TEXT,
  activity_type VARCHAR(100),
  budget NUMERIC(10, 2),
  budget_range VARCHAR(50),
  outfit_suggestion TEXT,
  what_to_bring TEXT[],
  weather_note TEXT,
  genies_secret_touch TEXT,
  conversation_starters TEXT[],
  itinerary JSONB,
  /*
    itinerary JSONB structure per stop:
    [
      {
        "stop_number": 1,
        "arrival_time": "3:15 PM",
        "duration_minutes": 60,
        "place_id": "ChIJ...",
        "name": "Housing Works Bookstore",
        "category": "Music & Books",
        "address": "126 Crosby St, New York, NY",
        "phone": "(212) 334-3324",
        "website": "https://...",
        "description": "Start your afternoon by...",
        "why_this_fits": "Combines the requested music interest...",
        "romantic_tip": "Pick out a book or a record...",
        "cost_per_person": "Free (to browse)",
        "verified": true,
        "travel_to_next": {
          "duration": "4 mins",
          "distance": "0.2 mi",
          "mode": "transit"
        }
      }
    ]
  */
  total_travel_time VARCHAR(50),
  venue_count INTEGER,
  route_map_url TEXT,
  status VARCHAR(50) DEFAULT 'planned',
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_date_plans_couple ON date_plans(couple_id);
CREATE INDEX idx_date_plans_status ON date_plans(status);
CREATE INDEX idx_date_plans_scheduled ON date_plans(scheduled_at);

-- ===========================================
-- Table 5: date_memories
-- ===========================================
CREATE TABLE date_memories (
  memory_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  plan_id UUID NOT NULL REFERENCES date_plans(plan_id) ON DELETE CASCADE,
  couple_id UUID NOT NULL REFERENCES couples(couple_id) ON DELETE CASCADE,
  rating INTEGER CHECK (rating >= 1 AND rating <= 5),
  notes TEXT,
  photo_urls TEXT[],
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_date_memories_plan ON date_memories(plan_id);
CREATE INDEX idx_date_memories_couple ON date_memories(couple_id);

-- ===========================================
-- Table 6: gift_suggestions
-- ===========================================
CREATE TABLE gift_suggestions (
  gift_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  plan_id UUID NOT NULL REFERENCES date_plans(plan_id) ON DELETE CASCADE,
  couple_id UUID NOT NULL REFERENCES couples(couple_id) ON DELETE CASCADE,
  name VARCHAR(255),
  price_range VARCHAR(50),
  description TEXT,
  why_it_fits TEXT,
  where_to_buy VARCHAR(100),
  liked BOOLEAN DEFAULT NULL,
  /*
    liked logic:
    - NULL = unseen, eligible to suggest
    - TRUE = liked/hearted by user
    - FALSE = skipped/dismissed, never suggest again
  */
  purchased BOOLEAN DEFAULT FALSE,
  /*
    purchased logic:
    - FALSE = not yet bought
    - TRUE = already purchased, exclude from all future suggestions for this couple
  */
  purchased_at TIMESTAMP,
  purchased_for_plan_id UUID REFERENCES date_plans(plan_id),
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_gift_suggestions_plan ON gift_suggestions(plan_id);
CREATE INDEX idx_gift_suggestions_couple ON gift_suggestions(couple_id);
CREATE INDEX idx_gift_suggestions_fresh ON gift_suggestions(couple_id, purchased, liked) 
  WHERE purchased = FALSE AND (liked IS NULL OR liked = TRUE);

-- ===========================================
-- Table 7: playlists
-- ===========================================
CREATE TABLE playlists (
  playlist_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  plan_id UUID NOT NULL REFERENCES date_plans(plan_id) ON DELETE CASCADE,
  couple_id UUID NOT NULL REFERENCES couples(couple_id) ON DELETE CASCADE,
  title VARCHAR(255),
  description TEXT,
  platform VARCHAR(50),
  external_url TEXT,
  external_playlist_id TEXT,
  tracks JSONB,
  /*
    tracks JSONB structure:
    [
      {
        "track_number": 1,
        "title": "Blue in Green",
        "artist": "Miles Davis",
        "album": "Kind of Blue",
        "duration": "5:37",
        "why_it_fits": "Sets a calm sophisticated tone for the bookstore stop"
      }
    ]
  */
  total_duration_minutes INTEGER,
  generated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_playlists_plan ON playlists(plan_id);
CREATE INDEX idx_playlists_couple ON playlists(couple_id);

-- ===========================================
-- Helper function for updated_at timestamps
-- ===========================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply trigger to preferences table
CREATE TRIGGER update_preferences_updated_at
    BEFORE UPDATE ON preferences
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ===========================================
-- Row Level Security Policies
-- ===========================================

-- Enable RLS on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE couples ENABLE ROW LEVEL SECURITY;
ALTER TABLE preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE date_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE date_memories ENABLE ROW LEVEL SECURITY;
ALTER TABLE gift_suggestions ENABLE ROW LEVEL SECURITY;
ALTER TABLE playlists ENABLE ROW LEVEL SECURITY;

-- Users: can only access own data
CREATE POLICY "Users can view own data" ON users
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own data" ON users
  FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own data" ON users
  FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own data" ON users
  FOR DELETE USING (auth.uid() = user_id);

-- Couples: users can access couples they belong to
CREATE POLICY "Users can view own couples" ON couples
  FOR SELECT USING (auth.uid() = user_id_1 OR auth.uid() = user_id_2);
CREATE POLICY "Users can insert own couples" ON couples
  FOR INSERT WITH CHECK (auth.uid() = user_id_1);
CREATE POLICY "Users can update own couples" ON couples
  FOR UPDATE USING (auth.uid() = user_id_1 OR auth.uid() = user_id_2);

-- Preferences: users can access own preferences
CREATE POLICY "Users can view own preferences" ON preferences
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own preferences" ON preferences
  FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own preferences" ON preferences
  FOR UPDATE USING (auth.uid() = user_id);

-- Date plans: access via couple membership
CREATE POLICY "Users can view couple date plans" ON date_plans
  FOR SELECT USING (
    couple_id IN (SELECT couple_id FROM couples WHERE user_id_1 = auth.uid() OR user_id_2 = auth.uid())
  );
CREATE POLICY "Users can insert couple date plans" ON date_plans
  FOR INSERT WITH CHECK (
    couple_id IN (SELECT couple_id FROM couples WHERE user_id_1 = auth.uid() OR user_id_2 = auth.uid())
  );
CREATE POLICY "Users can update couple date plans" ON date_plans
  FOR UPDATE USING (
    couple_id IN (SELECT couple_id FROM couples WHERE user_id_1 = auth.uid() OR user_id_2 = auth.uid())
  );
CREATE POLICY "Users can delete couple date plans" ON date_plans
  FOR DELETE USING (
    couple_id IN (SELECT couple_id FROM couples WHERE user_id_1 = auth.uid() OR user_id_2 = auth.uid())
  );

-- Date memories: access via couple membership
CREATE POLICY "Users can view couple memories" ON date_memories
  FOR SELECT USING (
    couple_id IN (SELECT couple_id FROM couples WHERE user_id_1 = auth.uid() OR user_id_2 = auth.uid())
  );
CREATE POLICY "Users can insert couple memories" ON date_memories
  FOR INSERT WITH CHECK (
    couple_id IN (SELECT couple_id FROM couples WHERE user_id_1 = auth.uid() OR user_id_2 = auth.uid())
  );
CREATE POLICY "Users can update couple memories" ON date_memories
  FOR UPDATE USING (
    couple_id IN (SELECT couple_id FROM couples WHERE user_id_1 = auth.uid() OR user_id_2 = auth.uid())
  );
CREATE POLICY "Users can delete couple memories" ON date_memories
  FOR DELETE USING (
    couple_id IN (SELECT couple_id FROM couples WHERE user_id_1 = auth.uid() OR user_id_2 = auth.uid())
  );

-- Gift suggestions: access via couple membership
CREATE POLICY "Users can view couple gifts" ON gift_suggestions
  FOR SELECT USING (
    couple_id IN (SELECT couple_id FROM couples WHERE user_id_1 = auth.uid() OR user_id_2 = auth.uid())
  );
CREATE POLICY "Users can insert couple gifts" ON gift_suggestions
  FOR INSERT WITH CHECK (
    couple_id IN (SELECT couple_id FROM couples WHERE user_id_1 = auth.uid() OR user_id_2 = auth.uid())
  );
CREATE POLICY "Users can update couple gifts" ON gift_suggestions
  FOR UPDATE USING (
    couple_id IN (SELECT couple_id FROM couples WHERE user_id_1 = auth.uid() OR user_id_2 = auth.uid())
  );

-- Playlists: access via couple membership
CREATE POLICY "Users can view couple playlists" ON playlists
  FOR SELECT USING (
    couple_id IN (SELECT couple_id FROM couples WHERE user_id_1 = auth.uid() OR user_id_2 = auth.uid())
  );
CREATE POLICY "Users can insert couple playlists" ON playlists
  FOR INSERT WITH CHECK (
    couple_id IN (SELECT couple_id FROM couples WHERE user_id_1 = auth.uid() OR user_id_2 = auth.uid())
  );
CREATE POLICY "Users can update couple playlists" ON playlists
  FOR UPDATE USING (
    couple_id IN (SELECT couple_id FROM couples WHERE user_id_1 = auth.uid() OR user_id_2 = auth.uid())
  );
