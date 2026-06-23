#!/usr/bin/env node
/** Patch OB3 + OB4 in YDG_interactive_prototype.html */
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const ROOT = path.dirname(path.dirname(fileURLToPath(import.meta.url)));
const PROTO = path.join(ROOT, 'YDG_interactive_prototype.html');

const OB3_EXTRAS = `<div class="ob-extras-label ob-fade-up d2">Plus on every date</div><div class="tut-notes-cards ob-onboard-extras ob-fade-up d2"><div class="tut-notes-card" style="--delay:.5s"><span class="ico">✨</span><span><div>Convo starters</div><div class="sub">Questions when small talk runs dry</div></span></div><div class="tut-notes-card" style="--delay:.65s"><span class="ico">💌</span><span><div>Love notes</div><div class="sub">Something sweet before they arrive</div></span></div><div class="tut-notes-card" style="--delay:.8s"><span class="ico">🎁</span><span><div>Gift finder</div><div class="sub">Thoughtful picks tied to your stops</div></span></div></div><div class="muted note center ob-fade-up d2" style="margin:8px 0;font-size:10px;line-height:1.4;">Real venues · verified · full itinerary included</div>`;

const OB3_HTML = `<div class="screen-inner ob-live screen-scroll"><div class="stat"><span data-go="ob2">←</span><span>3 of 4</span><span></span></div><div class="onboard-dots"><span class="off"></span><span class="off"></span><span class="on"></span><span class="off"></span></div><div class="ob-label ob-fade-up">What you get</div><div class="h-display ob-fade-up d1" style="font-size:17px;margin-bottom:8px;">One tap on <span style="color:var(--gold)">Home</span></div><div class="ob-home-demo slim ob-fade-up d1"><div class="ob-home-phone"><div class="ob-home-screen"><div class="mini-stat"><span>Home</span><span>🔔</span></div><div style="font-size:7px;color:var(--muted);margin-bottom:2px;">Tonight, for you &amp; Maya</div><div class="ob-home-card"><div class="cream" style="font-size:8px;line-height:1.3;">Pasta · gallery · gelato</div><div style="font-size:7px;color:var(--gold);margin-top:3px;">Lock it in →</div></div></div></div><div class="ob-actions-row"><div class="ob-feature-chip" style="--delay:.55s"><span class="ico">🍽</span><span class="lbl">Reserve</span></div><div class="ob-feature-chip" style="--delay:.7s"><span class="ico">🗺</span><span class="lbl">Route</span></div><div class="ob-feature-chip" style="--delay:.85s"><span class="ico">💬</span><span class="lbl">Share</span></div><div class="ob-feature-chip" style="--delay:1s"><span class="ico">🎵</span><span class="lbl">Playlist</span></div></div></div><div class="ob-itin ob-anim-card" style="margin-top:6px;"><div class="ob-itin-hd"><div><div class="cream note" style="font-size:12px;">Romantic Italian Night</div><div class="dim note">Sat · 3 stops · ~$150</div></div><span style="color:var(--gold);">✦</span></div><div class="ob-itin-timeline"><div class="ob-stop ob-anim d1"><div><div class="t">7:00 PM</div><div class="n">Wine bar · start with reds</div></div></div><div class="ob-stop ob-anim d2"><div><div class="t">8:30 PM</div><div class="n">Trattoria · truffle pasta</div></div></div><div class="ob-stop ob-anim d3"><div><div class="t">10:30 PM</div><div class="n">Rooftop · nightcap</div></div></div></div></div>${OB3_EXTRAS}<div class="screen-foot"><div class="cta" data-go="ob4">Next</div></div></div>`;

const OB4_HTML = `<div class="screen-inner ob-live screen-scroll"><div class="stat"><span data-go="ob3">←</span><span>4 of 4</span><span></span></div><div class="onboard-dots"><span class="off"></span><span class="off"></span><span class="off"></span><span class="on"></span></div><div class="ob-label center ob-fade-up" style="margin-top:4px;">Let the sparks fly</div><div class="h-display center ob-fade-up d1" style="font-size:18px;margin-bottom:6px;">Ready for <span style="color:var(--gold)">better dates?</span></div><div class="muted note center ob-fade-up d2" style="margin-bottom:6px;line-height:1.45;">Three little extras on <span style="color:var(--gold-soft)">every date</span> — in Convo &amp; on your itinerary.</div><div class="ob-sparks-fly ob-fade-up d2"><span class="spark" aria-hidden="true">✨</span><span class="spark" aria-hidden="true">💫</span><span class="spark" aria-hidden="true">✨</span><span class="spark" aria-hidden="true">💛</span><span class="spark" aria-hidden="true">✦</span><span class="spark" aria-hidden="true">✨</span><div class="tut-notes-cards ob-onboard-extras"><div class="tut-notes-card" style="--delay:.35s"><span class="ico">✨</span><span><div>Convo starters</div><div class="sub">Swipe questions before dinner</div></span></div><div class="tut-notes-card" style="--delay:.55s"><span class="ico">💌</span><span><div>Love notes</div><div class="sub">Write something sweet between dates</div></span></div><div class="tut-notes-card" style="--delay:.75s"><span class="ico">🎁</span><span><div>Gift finder</div><div class="sub">Picks for each stop — not random links</div></span></div></div></div><div class="ob-benefit ob-anim d1"><span class="ck">✓</span> Quick setup — then Home plans for you</div><div class="ob-benefit ob-anim d2"><span class="ck">✓</span> Real venues, verified · tailored to you two</div><div class="ob-disclosure">Free plan included · Premium unlocks unlimited nights &amp; memories</div><div class="screen-foot"><div class="cta" data-go="auth">Begin Your Journey</div></div></div>`;

const c = fs.readFileSync(PROTO, 'utf8');
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
screens.find((s) => s.id === 'ob3').html = OB3_HTML;
screens.find((s) => s.id === 'ob4').html = OB4_HTML;
screens.find((s) => s.id === 'ob4').label = 'Let the sparks fly';
fs.writeFileSync(PROTO, c.slice(0, start) + JSON.stringify(screens) + c.slice(i));
console.log('Patched ob3 + ob4 in prototype');
