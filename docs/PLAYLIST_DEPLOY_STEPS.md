# Step-by-Step: Deploy Playlist (Last.fm) and Fix "Function Not Found"

Your app calls the **generate-playlist** Edge Function on Supabase. Right now that function is not deployed on the project your app uses, so you see "requested function not found." Follow these steps in order.

---

## Prerequisites

- Terminal (Mac: Terminal.app or iTerm).
- Supabase CLI installed. If not:
  ```bash
  brew install supabase/tap/supabase
  ```
- You are in the project folder: `yourdategenie-main`.

---

## Step 1: Open Terminal and go to the project folder

```bash
cd /Users/anjelaarora/Downloads/yourdategenie-main
```

Check you’re in the right place (you should see `supabase`, `ios`, etc.):

```bash
ls
```

You should see folders like `supabase`, `ios`, `docs`.

---

## Step 2: Log in to Supabase (if needed)

```bash
supabase login
```

A browser window opens. Sign in with your Supabase account.  
If you’re already logged in, this may do nothing or confirm you’re logged in.

---

## Step 3: Link this repo to the correct Supabase project

Your **app** uses this project: **jhpwacmsocjmzhimtbxj**.  
We need the CLI to use the same project so deploys go to the right place.

Run:

```bash
supabase link --project-ref jhpwacmsocjmzhimtbxj
```

- If it asks for the **database password**, use the password you set for that Supabase project (not your Supabase account password). You can reset it in: Dashboard → Project Settings → Database.
- When it succeeds you’ll see something like “Linked to project jhpwacmsocjmzhimtbxj”.

---

## Step 4: Deploy the generate-playlist function

Deploy only the playlist function:

```bash
supabase functions deploy generate-playlist
```

- Wait until it finishes. You should see a line like “Deployed Function generate-playlist”.
- If you get an error about “project not linked”, go back to Step 3.

---

## Step 5: Set the Last.fm API key in Supabase

The function needs your Last.fm API key as a **secret** so it can call Last.fm.

1. Open: [https://supabase.com/dashboard](https://supabase.com/dashboard)
2. Click the project **jhpwacmsocjmzhimtbxj** (the one your app uses).
3. In the left sidebar, go to: **Project Settings** (gear icon at the bottom).
4. Click **Edge Functions** in the left menu under Project Settings.
5. Find the **Secrets** or **Function Secrets** section.
6. Add a new secret:
   - **Name:** `LASTFM_API_KEY`
   - **Value:** `cc9e8317733e45fdc5f8322299fc74aa`  
     (or your own Last.fm API key if you use a different one.)
7. Save.

---

## Step 6: Test in the app

1. Open the **YourDateGenie** app on the simulator or device.
2. Go to the screen where you create a playlist (e.g. from a date plan → Date Playlist / Mood Music).
3. Pick energy, genre/vibe, and tap **Generate [Genre] Playlist**.
4. Wait a few seconds.

- If it works: you see a playlist with tracks (from Last.fm).
- If you still see an error:
  - “LASTFM_API_KEY not configured” → repeat Step 5 and make sure the secret name is exactly `LASTFM_API_KEY`.
  - “requested function not found” → repeat Step 4 and confirm you’re linked to **jhpwacmsocjmzhimtbxj** (Step 3).

---

## Quick reference

| Step | What you’re doing |
|------|-------------------|
| 1    | `cd` into `yourdategenie-main` |
| 2    | `supabase login` |
| 3    | `supabase link --project-ref jhpwacmsocjmzhimtbxj` |
| 4    | `supabase functions deploy generate-playlist` |
| 5    | In Dashboard → Project Settings → Edge Functions → add secret `LASTFM_API_KEY` |
| 6    | Generate a playlist in the app and confirm it works |

---

## If something goes wrong

- **“Project not linked”**  
  Run Step 3 again and use project ref `jhpwacmsocjmzhimtbxj`. Make sure you’re in the `yourdategenie-main` folder.

- **“Invalid database password”**  
  In Supabase Dashboard → Project Settings → Database, reset the database password, then run Step 3 again with the new password.

- **App still says “function not found”**  
  Confirm the app’s Supabase URL is for **jhpwacmsocjmzhimtbxj** (in the app’s config / `Config.swift`). Then run Step 4 again after Step 3.

- **“LASTFM_API_KEY not configured”**  
  The secret must be named exactly `LASTFM_API_KEY` (no spaces, correct spelling). Add it under Project Settings → Edge Functions → Secrets and save.
