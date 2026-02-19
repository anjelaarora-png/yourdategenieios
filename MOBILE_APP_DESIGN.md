# YourDateGenie - iOS Mobile App Design

## Overview

A complete iOS-native mobile experience for YourDateGenie, featuring intuitive navigation, optimized user journeys, and native iOS design patterns.

---

## User Journey Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                        APP LAUNCH                                │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
              ┌───────────────────────────────┐
              │     First Time User?           │
              └───────────────────────────────┘
                    │                │
                   YES               NO
                    │                │
                    ▼                ▼
        ┌───────────────────┐   ┌───────────────┐
        │ ONBOARDING JOURNEY│   │  AUTH CHECK   │
        │                   │   └───────────────┘
        │ 1. Splash Screen  │           │
        │    (Animated)     │    ┌──────┴──────┐
        │         ↓         │   YES            NO
        │ 2. Story Slides   │    │              │
        │    (4 slides)     │    ▼              ▼
        │         ↓         │  HOME          AUTH
        │ 3. Feature Slides │
        │    (5 slides)     │
        │         ↓         │
        │ 4. Ready Screen   │
        └───────────────────┘
                │
                ▼
        ┌───────────────┐
        │   AUTH FLOW   │
        └───────────────┘
                │
                ▼
        ┌───────────────┐
        │   HOME TAB    │◄────────────────────────────┐
        │   (Dashboard) │                             │
        └───────────────┘                             │
                │                                     │
    ┌───────────┼───────────────────┐                │
    │           │                   │                │
    ▼           ▼                   ▼                │
┌───────┐ ┌───────────┐    ┌──────────────┐         │
│History│ │ Create    │    │   Profile    │         │
│ Tab   │ │ Plan (+)  │    │     Tab      │         │
└───────┘ └───────────┘    └──────────────┘         │
    │           │                                    │
    │           ▼                                    │
    │   ┌───────────────────────┐                   │
    │   │    QUESTIONNAIRE      │                   │
    │   │    (6 Steps)          │                   │
    │   │                       │                   │
    │   │ 1. Location & When    │                   │
    │   │ 2. Transportation     │                   │
    │   │ 3. Vibe & Energy      │                   │
    │   │ 4. Food Preferences   │                   │
    │   │ 5. Deal Breakers      │                   │
    │   │ 6. Extras (optional)  │                   │
    │   └───────────────────────┘                   │
    │               │                               │
    │               ▼                               │
    │   ┌───────────────────────┐                   │
    │   │    AI GENERATION      │                   │
    │   │    (Loading State)    │                   │
    │   └───────────────────────┘                   │
    │               │                               │
    │               ▼                               │
    │   ┌───────────────────────┐                   │
    │   │   DATE PLAN RESULT    │──────────────────┘
    │   │                       │      (Save/Done)
    │   │ • Plan Selector       │
    │   │ • Timeline View       │
    │   │ • Gifts Sheet         │
    │   │ • Convos Sheet        │
    │   │ • Playlist Sheet      │
    │   └───────────────────────┘
    │
    └────────► View Saved Plan
```

---

## Screen Designs

### 1. Onboarding (Multi-Phase Journey)

**Purpose:** Build emotional connection and clearly explain the app value

#### Phase 1: Splash Screen (Animated Entry)
- Animated logo reveal with gradient glow
- Brand name "Your Date Genie"
- Tagline: "Magic happens here ✨"
- Value prop: "Never stress about planning the perfect date again"
- CTA: "Discover the Magic"

#### Phase 2: Story Slides (Problem → Solution)
Narrative-driven slides that connect emotionally:

| Slide | Emoji | Headline | Story |
|-------|-------|----------|-------|
| 1 | 😩 | Sound familiar? | "What should we do tonight?" - endless scrolling, same restaurants |
| 2 | 🤔 | The struggle is real | Hours researching, checking hours, worrying if they'll like it |
| 3 | 💡 | What if there was a better way? | Imagine a personal assistant who knows your preferences |
| 4 | ✨ | Meet Your Date Genie | AI that gets it - 2 minutes to a complete itinerary |

#### Phase 3: Feature Slides (What You Get)
Interactive previews of key features:

| Feature | Preview | Description |
|---------|---------|-------------|
| 💡 Smart Questionnaire | Quiz chips preview | 2 minutes to magic |
| 📅 Complete Itinerary | Timeline preview | Every detail planned |
| 📍 Verified Venues | Venue card with checkmarks | No surprises |
| 🎁 Thoughtful Extras | Gift/Convo/Music cards | The finishing touches |
| ❤️ Save & Remember | Stats preview | Build your history |

#### Phase 4: Ready Screen (Final CTA)
- Celebration emoji 🎉
- "You're All Set!"
- Benefits checklist with checkmarks
- Social proof: "10,000+ happy couples"
- Star rating: "4.9 on App Store"
- CTA: "Get Started Free"

**Features:**
- Progress bars on each phase
- Animated transitions between screens
- Skip option throughout
- Consistent visual hierarchy

---

### 2. Authentication

**Welcome Screen:**
- Large logo
- Headline: "Your Perfect Date Awaits"
- Two CTAs: "Create Account" (primary), "Sign In" (secondary)

**Sign In / Sign Up Forms:**
- Clean input fields with icons
- Password visibility toggle
- Error handling with inline messages
- "Forgot Password" link
- Toggle between sign in/sign up

---

### 3. Home (Main Dashboard)

**Layout:**
```
┌─────────────────────────────────┐
│ [Logo]                    [👤]  │  ← Header
├─────────────────────────────────┤
│ Hi, {Name} 👋                   │
│ Ready for your next adventure?  │
├─────────────────────────────────┤
│ ┌─────────────────────────────┐ │
│ │ ✨ AI POWERED               │ │
│ │ Plan a New Date          → │ │  ← Quick Create Card
│ │ Tell us your preferences... │ │
│ └─────────────────────────────┘ │
├─────────────────────────────────┤
│  [12]      [3]       [9]        │  ← Stats Row
│  Total    Upcoming  Completed   │
├─────────────────────────────────┤
│ Your Date Plans                 │
│ [All] [Upcoming] [Completed]    │  ← Filter Tabs
├─────────────────────────────────┤
│ ┌─────────────────────────────┐ │
│ │ 🌹 Romantic Dinner       ★4│ │
│ │ A cozy evening...           │ │  ← Plan Cards
│ │ 📍 3 stops • ⏱ 4 hours     │ │
│ └─────────────────────────────┘ │
│                                 │
└─────────────────────────────────┘
│ [🏠] [📋] [+] [🎵] [👤]         │  ← Tab Bar
└─────────────────────────────────┘
```

---

### 4. Questionnaire (6 Steps)

**Step Progression:**
- Progress bar at top
- Step icon and title
- Scrollable content area
- Fixed "Continue" button at bottom

**Step 1: Location & When**
- City input (required)
- Neighborhood input (optional)
- Date type selection (grid of chips)
- Special occasion selection

**Step 2: Transportation**
- Transportation mode (vertical list with descriptions)
- Travel radius selection

**Step 3: Vibe & Energy**
- Energy level (descriptive cards)
- Time of day (grid)
- Duration (grid)
- Activity preferences (multi-select chips)

**Step 4: Food & Drinks**
- Cuisine preferences (multi-select grid)
- Dietary restrictions (multi-select)
- Budget range (single select)

**Step 5: Deal Breakers**
- Allergies (multi-select)
- Hard nos (multi-select)
- Additional notes (textarea)

**Step 6: Extras**
- Gift suggestions toggle
- Conversation starters toggle
- Optional details for gifts

---

### 5. Date Plan Result

**Layout:**
```
┌─────────────────────────────────┐
│ ← Back    Your Date Plan  [↗][♡]│  ← Header
├─────────────────────────────────┤
│        ◀ Option 1 of 3 ▶       │  ← Plan Selector
│        Romantic Dinner          │
├─────────────────────────────────┤
│      ✨ Romantic Dinner         │
│   "A magical evening awaits"    │
│   [⏱ 4 hours] [💰 $150-200]    │
├─────────────────────────────────┤
│ [🎁 Gifts] [💬 Convos] [🎵 Music]│ ← Quick Actions
├─────────────────────────────────┤
│  │ ① 🍷 Moonlight Wine Bar     │
│  │    Wine Bar • 7:00 PM       │  ← Timeline
│  │    Verified ✓               │
│  │                             │
│  │ ② 🍝 Bella Italia           │
│  │    Italian • 8:30 PM        │
│  │    ⏱ 1.5 hours • $50/person │
│  │                             │
│  │ ③ 🌙 Rooftop Lounge         │
│  │    Lounge • 10:00 PM        │
├─────────────────────────────────┤
│ ✨ Genie's Secret Touch         │
│ Surprise them with...           │
├─────────────────────────────────┤
│ 📦 What to Bring                │
│ Camera • Jacket • Card          │
└─────────────────────────────────┘
│    [♡ Save This Date Plan]      │  ← Fixed CTA
└─────────────────────────────────┘
```

**Stop Card Expanded:**
- Full description
- Address with map link
- "Why this fits" explanation
- Romantic tip
- Action buttons: Directions, Call, Website

**Bottom Sheets:**
- Gift Suggestions (draggable sheet)
- Conversation Starters (draggable sheet)
- Playlist (draggable sheet with Spotify links)

---

### 6. History Tab

**Features:**
- Grouped by month
- Swipe-to-reveal actions (Delete, Mark Complete)
- Filter: All / Upcoming / Completed
- Rating display on completed dates

---

### 7. Playlists Tab

**Grid Layout:**
- 2-column grid of playlist cards
- Color-coded by mood
- Song count display
- Tap to open playlist detail sheet

**Playlist Detail Sheet:**
- Playlist header with mood icon
- "Open in Spotify" button
- Scrollable song list
- Like/unlike songs

---

### 8. Profile Tab

**Sections:**
- User avatar and stats
- Preferences (Date Preferences, Notifications, Appearance)
- Account (Subscription, Privacy, Settings)
- Support (Rate App, Share, Help)
- Sign Out

---

## iOS Design Patterns Used

### Navigation
- **Tab Bar:** 5 items with center FAB for create
- **Navigation Bar:** iOS standard with large titles
- **Bottom Sheets:** Draggable modal sheets

### Interactions
- **Haptic Feedback:** On button taps
- **Swipe Gestures:** Horizontal for carousels, swipe-to-delete
- **Pull to Refresh:** On lists

### Visual Design
- **Safe Area Insets:** Proper handling for notch/Dynamic Island
- **Blur Effects:** Frosted glass navigation bars
- **Rounded Corners:** 12px for cards, 100px for pills
- **Gradients:** Primary color gradients for CTAs

### Accessibility
- **Dynamic Type:** Responsive text sizes
- **VoiceOver:** Proper labels and hints
- **Reduced Motion:** Respect system settings

---

## File Structure

```
src/mobile/
├── MobileApp.tsx              # Main app coordinator
├── index.ts                   # Exports
├── styles/
│   └── mobile.css             # iOS-specific styles
├── components/
│   └── MobileTabBar.tsx       # Bottom navigation
└── screens/
    ├── MobileOnboarding.tsx   # Onboarding flow
    ├── MobileAuth.tsx         # Authentication
    ├── MobileHome.tsx         # Home dashboard
    ├── MobileQuestionnaire.tsx# Date planning wizard
    ├── MobileDatePlanResult.tsx# Generated plan view
    ├── MobileHistory.tsx      # Saved plans list
    ├── MobilePlaylists.tsx    # Music playlists
    └── MobileProfile.tsx      # User settings
```

---

## Access the Mobile App

Navigate to `/app` route to access the mobile experience:
- `http://localhost:5173/app`

The mobile app is optimized for:
- iPhone SE (375px) to iPhone Pro Max (428px)
- iOS Safari
- PWA installation

---

## Key UX Optimizations

1. **Reduced Friction:** Quick Generate option for returning users
2. **Progressive Disclosure:** 6-step wizard instead of long form
3. **Visual Feedback:** Loading states, success animations
4. **Offline Support:** LocalStorage for in-progress questionnaires
5. **Thumb-Friendly:** All CTAs in bottom 1/3 of screen
6. **Scannable Content:** Cards with key info visible at glance
