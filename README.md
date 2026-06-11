# Your Date Genie — Web App

## Launch-mode feature flag

All landing-page CTAs are controlled by a single environment variable:

| `VITE_LAUNCH_MODE` | CTA behaviour |
|--------------------|---------------|
| `prelaunch` (default) | Shows the waitlist email-capture form |
| `launched` | Shows "Download on App Store" button linking to `VITE_APP_STORE_URL` |

**Day-of-launch action (2026-05-27):**
1. In Vercel/Netlify → Production environment → set `VITE_LAUNCH_MODE=launched`
2. Also update `VITE_APP_STORE_URL` to the real App Store URL once Apple assigns the ID
3. Trigger a redeploy (or Vercel auto-deploys on env-var save)
4. Done — all CTAs flip site-wide, and the "Now live on the App Store" banner appears

**Testing the launched state without a deploy:**
Append `?launchMode=launched` to any URL, e.g. `http://localhost:5173/?launchMode=launched`

**Preview environments:** Set `VITE_LAUNCH_MODE=launched` on preview/staging so PR previews always show the post-launch UI.

---

# Welcome to your Lovable project

## Project info

**URL**: https://lovable.dev/projects/REPLACE_WITH_PROJECT_ID

## How can I edit this code?

There are several ways of editing your application.

**Use Lovable**

Simply visit the [Lovable Project](https://lovable.dev/projects/REPLACE_WITH_PROJECT_ID) and start prompting.

Changes made via Lovable will be committed automatically to this repo.

**Use your preferred IDE**

If you want to work locally using your own IDE, you can clone this repo and push changes. Pushed changes will also be reflected in Lovable.

The only requirement is having Node.js & npm installed - [install with nvm](https://github.com/nvm-sh/nvm#installing-and-updating)

Follow these steps:

```sh
# Step 1: Clone the repository using the project's Git URL.
git clone <YOUR_GIT_URL>

# Step 2: Navigate to the project directory.
cd <YOUR_PROJECT_NAME>

# Step 3: Install the necessary dependencies.
npm i

# Step 4: Start the development server with auto-reloading and an instant preview.
npm run dev
```

**Edit a file directly in GitHub**

- Navigate to the desired file(s).
- Click the "Edit" button (pencil icon) at the top right of the file view.
- Make your changes and commit the changes.

**Use GitHub Codespaces**

- Navigate to the main page of your repository.
- Click on the "Code" button (green button) near the top right.
- Select the "Codespaces" tab.
- Click on "New codespace" to launch a new Codespace environment.
- Edit files directly within the Codespace and commit and push your changes once you're done.

## What technologies are used for this project?

This project is built with:

- Vite
- TypeScript
- React
- shadcn-ui
- Tailwind CSS

## How can I deploy this project?

Simply open [Lovable](https://lovable.dev/projects/REPLACE_WITH_PROJECT_ID) and click on Share -> Publish.

## Can I connect a custom domain to my Lovable project?

Yes, you can!

To connect a domain, navigate to Project > Settings > Domains and click Connect Domain.

Read more here: [Setting up a custom domain](https://docs.lovable.dev/features/custom-domain#custom-domain)
