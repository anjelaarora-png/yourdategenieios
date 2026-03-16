# Musical animation for playlist / Music tab

Add a polished musical animation (e.g. spinning record with musical notes) to the playlist experience.

## Placement

1. **Music tab empty state** ([PlaylistCollection.tsx](src/components/playlist/PlaylistCollection.tsx))  
   Replace or augment the current static icon (Music in a circle) with a **spinning record + floating musical notes** so the "No Playlists Yet" state feels on-brand and engaging.

2. **Playlist generation loading** ([PlaylistWidget.tsx](src/components/playlist/PlaylistWidget.tsx))  
   When `isGenerating` is true, show a **spinning record** (and optional notes) instead of or alongside the Loader2 spinner for "Curating … songs...".

3. **Optional**: Small decorative record or notes in the Music tab header when there are playlists (subtle, non-distracting).

## Implementation approach

- **Pure CSS + SVG** (no extra deps): Build a vinyl record (dark circle + center label + groove lines) and 2–4 musical note (♪ ♫) elements. Use CSS keyframes for:
  - Record: `transform: rotate(360deg)` on a loop (e.g. 3–5s linear infinite), with `will-change: transform` for smoothness.
  - Notes: gentle float/bob (translateY or small scale) with staggered animation-delay so they feel organic.
- **Reuse patterns** from existing animations in the app: [GeneratingOverlay](src/components/datePlan/GeneratingOverlay.tsx) (pulse, ping, bounce), [index.css](src/index.css) (keyframes like `slide-up`, `pulse-glow`). Add new keyframes in `index.css` (e.g. `record-spin`, `note-float`) and keep classes semantic (e.g. `animate-record-spin`, `animate-note-float`).
- **Component**: Create a small presentational component, e.g. `MusicRecordAnimation` or `VinylSpinner`, in `src/components/playlist/` that renders the SVG record + notes and applies the animation classes. Use it in PlaylistCollection empty state and in PlaylistWidget generating state.
- **Accessibility**: Prefer `prefers-reduced-motion: reduce` to disable or simplify the spin (e.g. slow rotation or static icon) so the UI stays polished but respectful of motion sensitivity.

## Design notes

- Record: classic vinyl look (dark disk, lighter center label, optional subtle grooves).
- Notes: simple ♪/♫ shapes or small SVG paths, 2–4 notes, subtle motion so they don’t compete with the spinning record.
- Colors: use theme tokens (e.g. `primary`, `muted-foreground`) so it works in light/dark and matches the rest of the app.
