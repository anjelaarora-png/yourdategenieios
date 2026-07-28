# YDG Scroll-Animation Hero — Build Kit
**Turn the 4-act loop into a scroll-scrubbed website hero** · 2026-06-10

> Goal: as the visitor scrolls the top of the landing page, the 3D loop plays through act-by-act (phone → conjure → real date → back to phone + logo). Apple-product-page style.

---

## THE DECISION
Build it as a **scroll-scrubbed master video**: stitch the 4 acts into ONE MP4, pin it full-screen, and tie its playback position to scroll progress. One file, one snippet. Not four separate videos, not a heavy 3D engine in the browser.

**Why this over alternatives:**
- 4 separate scroll triggers = sync nightmare + jank. One master = one clean timeline.
- Real-time 3D (Three.js) in-browser = weeks of work + slow on phones. The video is already rendered — just scrub it.

---

## 3 WAYS TO DO IT — ranked by effort-to-return

| Tier | What it is | Effort | The effect |
|---|---|---|---|
| 🟢 **1. Scroll-scrub (recommended)** | Scroll position drives video frame. | Low — 1 snippet | Premium, "Apple" feel |
| 🟡 2. Sticky autoplay | Section pins, loop autoplays once on scroll-in. | Lowest | Nice, less wow |
| 🔴 3. Image-sequence on canvas | Frames drawn to canvas per scroll. | High | Smoothest on mobile, heavy build |

Start with Tier 1. If mobile scrubbing ever feels choppy, fall back to Tier 2 (dead simple) — covered below.

---

## STEP 1 — Stitch the master (the final assembly)
Order: **Act 1 → Act 2 → Act 3 → Act 4 → End card.** Overlay the real logo onto the clean phone screens in Acts 1 & 4. Output ~22s, 1080×1920.

```bash
# 1) concat the acts (after logo overlays are baked into act1/act4)
ffmpeg -f concat -safe 0 -i list.txt -c copy ydg_master_raw.mp4
#    list.txt:
#      file 'act1_logo.mp4'
#      file 'act2.mp4'
#      file 'act3.mp4'
#      file 'act4_logo.mp4'
#      file 'endcard_3s.mp4'

# 2) RE-ENCODE FOR SCRUBBING — this is the #1 thing people skip.
#    -g 1 makes every frame a keyframe so scroll-scrubbing is buttery (no stutter).
ffmpeg -i ydg_master_raw.mp4 -an -vf "scale=1080:-2,format=yuv420p" \
  -c:v libx264 -profile:v high -crf 23 -g 1 -movflags +faststart ydg_master.mp4

# 3) optional WebM for wider support
ffmpeg -i ydg_master.mp4 -an -c:v libvpx-vp9 -crf 32 -b:v 0 ydg_master.webm
```
**Gotcha:** without `-g 1` (dense keyframes), scrub stutters because the player can't jump to arbitrary frames. This single flag is the difference between "premium" and "broken."

Then host `ydg_master.mp4` (WordPress Media Library or a CDN) and copy its URL.

---

## STEP 2 — Paste-ready scroll code (Tier 1)
Drop this into an **Elementor → HTML widget** (or a "Custom HTML" block) at the top of the page. Replace `MASTER_URL`.

```html
<section class="ydg-hero">
  <div class="ydg-sticky">
    <video id="ydgVideo" src="MASTER_URL" muted playsinline preload="auto"></video>
    <div class="ydg-scrim"></div>
  </div>
</section>

<style>
  .ydg-hero{ position:relative; height:420vh; background:#3c1117; } /* taller = slower scrub */
  .ydg-sticky{ position:sticky; top:0; height:100vh; overflow:hidden; }
  #ydgVideo{ width:100%; height:100%; object-fit:cover; display:block; }
  .ydg-scrim{ position:absolute; inset:0; pointer-events:none;
    background:radial-gradient(120% 80% at 50% 30%, transparent 60%, rgba(60,17,23,.5)); }
  @media (prefers-reduced-motion: reduce){ .ydg-hero{ height:100vh; } }
</style>

<script src="https://cdnjs.cloudflare.com/ajax/libs/gsap/3.12.5/gsap.min.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/gsap/3.12.5/ScrollTrigger.min.js"></script>
<script>
  gsap.registerPlugin(ScrollTrigger);
  const v = document.getElementById('ydgVideo');
  v.pause();
  function wire(){
    if(!v.duration) return;
    // reduced-motion: just loop it, no scrub
    if(matchMedia('(prefers-reduced-motion: reduce)').matches){ v.loop=true; v.play(); return; }
    ScrollTrigger.create({
      trigger: '.ydg-hero', start: 'top top', end: 'bottom bottom', scrub: 0.4,
      onUpdate: s => { v.currentTime = s.progress * (v.duration || 0); }
    });
  }
  v.addEventListener('loadedmetadata', wire);
  if(v.readyState >= 1) wire();
</script>
```
Tune the feel with `height:420vh` (taller = more scroll per second of video) and `scrub:0.4` (smoothing).

---

## STEP 2 (alt) — Tier 2 fallback (simplest, no scrub)
If you want it live in 10 minutes with zero fuss: pin the section and autoplay the loop once.

```html
<section style="position:relative;height:100vh;overflow:hidden;background:#3c1117">
  <video src="MASTER_URL" autoplay muted playsinline loop
         style="width:100%;height:100%;object-fit:cover"></video>
</section>
```

---

## STEP 3 — WordPress placement
1. Media → Upload `ydg_master.mp4` (and `.webm`). Copy the file URL.
2. Edit the homepage in Elementor → drag an **HTML** widget to the very top (above the fold).
3. Paste the Tier-1 snippet, swap `MASTER_URL` for your file URL.
4. Preview on desktop + phone. Adjust `height:420vh` until the pace feels right.
5. Keep your existing headline/CTA in a normal section *below* the hero.

---

## WHAT MOST PEOPLE MISS
- **Dense keyframes (`-g 1`)** — without it, scrub stutters. Biggest single mistake.
- **Muted + playsinline** — required or iOS won't play/scrub at all.
- **File size** — keep the master tight (aim < 8 MB). It must load fast or the hero feels broken on first scroll. Add a `poster` frame for instant first paint.
- **Don't pin the whole page** — only the hero section scrubs; the rest scrolls normally.
- **Reduced-motion** — the snippet already falls back to a gentle loop for accessibility.

---

## ✅ NEXT STEP (test in days)
Once the master MP4 exists, drop it in WordPress with the **Tier-2** snippet first (10 min, proves it loads and looks right on mobile). If it feels good, switch to the **Tier-1** scroll-scrub snippet and tune the height. Ship the simple version same-day; upgrade to the scroll effect once you've seen it live.

> North-star tie: the hero's only job is to make a first-time visitor *feel the moment* in the first scroll — the strongest possible top-of-funnel for the $1M target.
