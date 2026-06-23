#!/usr/bin/env node
/** De-dupe marketing onboarding (OB3/OB4) vs post-setup home tutorials. */
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const ROOT = path.dirname(path.dirname(fileURLToPath(import.meta.url)));
const PROTO = path.join(ROOT, 'YDG_interactive_prototype.html');

const OB3 = `<div class="screen-inner ob-live ob3-fit"><div class="stat"><span data-go="ob2">←</span><span>3 of 4</span><span></span></div><div class="onboard-dots"><span class="off"></span><span class="off"></span><span class="on"></span><span class="off"></span></div><div class="ob-label ob-fade-up">What you get</div><div class="h-display ob-fade-up d1" style="font-size:17px;margin-bottom:6px;">We plan. <span style="color:var(--gold)">You approve.</span></div><div class="muted note center ob-fade-up d1" style="font-size:9px;margin-bottom:14px;line-height:1.45;">Tell us your vibe once — finished evenings show up on Home when you're ready.</div><div class="ob-benefit ob-anim d1"><span class="ck">✓</span> Real venues, verified — not random blogs</div><div class="ob-benefit ob-anim d2"><span class="ck">✓</span> Full itinerary — stops, timing &amp; route</div><div class="ob-benefit ob-anim d3"><span class="ck">✓</span> Lock in with one tap when it feels right</div><div class="muted note center ob-fade-up d2" style="margin-top:auto;font-size:9px;line-height:1.35;">Right after setup, we'll show you Home — tap Lock it in once.</div><div class="screen-foot"><div class="cta" data-go="ob4">Next</div></div></div>`;

const OB4 = `<div class="screen-inner ob-live"><div class="stat"><span data-go="ob3">←</span><span>4 of 4</span><span></span></div><div class="onboard-dots"><span class="off"></span><span class="off"></span><span class="off"></span><span class="on"></span></div><div class="ob-label center ob-fade-up" style="margin-top:8px;">Almost there</div><div class="h-display center ob-fade-up d1" style="font-size:18px;margin-bottom:8px;">Ready for <span style="color:var(--gold)">better dates?</span></div><div class="muted note center ob-fade-up d2" style="margin-bottom:14px;line-height:1.45;">Quick Genie Profile — then your first plan waits on Home.</div><div class="ob-benefit ob-anim d1"><span class="ck">✓</span> Free plan included — no card to start</div><div class="ob-benefit ob-anim d2"><span class="ck">✓</span> Premium unlocks unlimited nights &amp; memories</div><div class="ob-disclosure">About 2 minutes · skip anything you want</div><div class="screen-foot"><div class="cta" data-go="auth">Begin Your Journey</div></div></div>`;

const TUTORIAL1 = `<div class="screen-inner ob-live" style="display:flex;flex-direction:column;"><div class="tutorial-bg"></div><div class="tutorial-sheet"><div class="tut-progress"><span class="on"></span><span class=""></span><span class=""></span></div><div class="ob-label">How Home works</div><div class="h-display tut-headline" style="font-size:17px;margin-bottom:2px;">Open the app. <span style="color:var(--gold)">Tonight is ready.</span></div><div class="muted note tut-sub" style="font-size:10px;margin-bottom:6px;">Tap <strong style="color:var(--gold-soft)">Lock it in</strong> — reserve, route &amp; share unlock after.</div><div class="tut-home-stage"><div class="tut-home-card-wrap"><img src="mockup-assets/onboarding/plan-itinerary.jpg" class="tut-card-hero" alt="Tonight's date plan"><div class="tut-card-body"><div class="eyebrow">Tonight · for you &amp; Maya</div><div class="plan">Pasta · gallery · gelato<div style="font-size:9px;color:var(--dim);margin-top:3px;">romantic · ~$90 · 7–11 PM</div></div><button type="button" class="tut-home-lock" data-tut-lock aria-label="Lock it in">✦ Lock it in</button></div></div><div class="tut-home-actions"><span class="tut-home-action" style="--delay:.15s">🍽 Reserve</span><span class="tut-home-action" style="--delay:.3s">🗺 Route</span><span class="tut-home-action" style="--delay:.45s">💬 Text plan</span><span class="tut-home-action" style="--delay:.6s">📅 Calendar</span></div><div class="tut-tap-hint">↑ Tap the gold button</div></div><div class="cta is-disabled" style="margin-bottom:6px;" data-go="tutorial2" data-tut-next>Next</div><div class="center"><span class="link" data-go="home">Skip intro</span></div></div></div>`;

const TUTORIAL3 = `<div class="screen-inner ob-live" style="display:flex;flex-direction:column;"><div class="tutorial-bg"></div><div class="tutorial-sheet"><div class="tut-progress"><span class=""></span><span class=""></span><span class="on"></span></div><div class="ob-label">Convo tab</div><div class="h-display" style="font-size:17px;margin-bottom:2px;">Three extras for <span style="color:var(--gold)">every date</span></div><div class="muted note" style="font-size:10px;margin-bottom:6px;">Convo starters, love notes &amp; gifts — in Convo &amp; on your itinerary.</div><img src="mockup-assets/onboarding/tutorial-notes.jpg" class="tut-hero-img" alt="Couple connecting on a date"><div class="tut-notes-cards"><div class="tut-notes-card" style="--delay:.35s"><span class="ico">✨</span><span><div>Convo starters</div><div class="sub">Swipe questions before dinner</div></span></div><div class="tut-notes-card" style="--delay:.55s"><span class="ico">💌</span><span><div>Love notes</div><div class="sub">Send something sweet between dates</div></span></div><div class="tut-notes-card" style="--delay:.75s"><span class="ico">🎁</span><span><div>Gift finder</div><div class="sub">Thoughtful picks for each stop</div></span></div></div><div class="muted note center" style="font-size:9px;margin-bottom:8px;line-height:1.4;">Tweak your vibe anytime in You → Genie Profile.</div><div class="cta" style="margin-bottom:6px;" data-go="home">Got it!</div></div></div>`;

function patchProto() {
  let c = fs.readFileSync(PROTO, 'utf8');
  const marker = 'const SCREENS = [';
  const start = c.indexOf(marker) + marker.length - 1;
  let d = 0;
  let i = start;
  for (; i < c.length; i++) {
    if (c[i] === '[') d++;
    if (c[i] === ']') {
      d--;
      if (d === 0) {
        i++;
        break;
      }
    }
  }
  const screens = JSON.parse(c.slice(start, i));
  const map = { ob3: OB3, ob4: OB4, tutorial1: TUTORIAL1, tutorial3: TUTORIAL3 };
  for (const [id, html] of Object.entries(map)) {
    const s = screens.find((x) => x.id === id);
    if (!s) throw new Error(`Missing screen: ${id}`);
    s.html = html;
    if (id === 'tutorial3') s.label = 'Tutorial 3 · Notes extras';
  }
  fs.writeFileSync(PROTO, c.slice(0, start) + JSON.stringify(screens) + c.slice(i));
  console.log('Prototype patched:', Object.keys(map).join(', '));
}

patchProto();
