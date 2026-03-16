# API Keys Setup

Your Date Genie uses the **same Google API key** for address autocomplete, place details, and geocoding. You only need **one** key from Google Cloud, but you must add it in the right place(s) depending on which part of the app you’re running.

## 1. Get a Google API key

1. Go to [Google Cloud Console](https://console.cloud.google.com/).
2. Create or select a project.
3. Enable these APIs:
   - **Places API** (for autocomplete + place details)
   - **Geocoding API** (for address → coordinates)
4. Go to **APIs & Services → Credentials**, create an **API key**, and (optionally) restrict it by API.

---

## 2. Where to add the key

### iOS app

Put the key in **`ios/Secrets.xcconfig`** (not committed to git):

1. Copy `ios/Secrets.xcconfig.example` to `ios/Secrets.xcconfig`.
2. Set `GOOGLE_PLACES_API_KEY = YOUR_KEY` in `Secrets.xcconfig`.
3. Build and run in Xcode; the app reads the key via Info.plist.

If you don’t have `Secrets.xcconfig`, create it next to `Secrets.xcconfig.example` with the same variable names and your real values.

---

### Web app (Vite)

Put the key in a **`.env`** file at the **project root** (same folder as `package.json`):

```bash
VITE_GOOGLE_MAPS_API_KEY=your_google_api_key_here
```

Restart the dev server after changing `.env`. This is used for the web address autocomplete and map.

---

### Supabase Edge Functions (date plan generation)

If you use the **Supabase** `generate-date-plan` function (venue verification / geocoding on the server), set the key as a **Supabase secret**:

```bash
supabase secrets set GOOGLE_PLACES_API_KEY=your_google_api_key_here
```

Deploy or run your functions after setting secrets.

---

## Summary

| Where you're running | Where to add the key |
|----------------------|----------------------|
| **iOS app** | `ios/Secrets.xcconfig` → `GOOGLE_PLACES_API_KEY` |
| **Web app** | Root `.env` → `VITE_GOOGLE_MAPS_API_KEY` |
| **Supabase** `generate-date-plan` | `supabase secrets set GOOGLE_PLACES_API_KEY=...` |

Use the **same** Google API key in all three if you want address and map features to work in every part of the app.
