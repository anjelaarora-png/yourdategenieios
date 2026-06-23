#!/usr/bin/env node
/** Split onboarding slide 3 into itinerary (OB3) + features (OB4); CTA moves to OB5. */
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const ROOT = path.dirname(path.dirname(fileURLToPath(import.meta.url)));
const PROTO = path.join(ROOT, 'YDG_interactive_prototype.html');

const DOTS = {
  ob1: '<span class="on"></span><span class="off"></span><span class="off"></span><span class="off"></span><span class="off"></span>',
  ob2: '<span class="off"></span><span class="on"></span><span class="off"></span><span class="off"></span><span class="off"></span>',
  ob3: '<span class="off"></span><span class="off"></span><span class="on"></span><span class="off"></span><span class="off"></span>',
  ob4: '<span class="off"></span><span class="off"></span><span class="off"></span><span class="on"></span><span class="off"></span>',
  ob5: '<span class="off"></span><span class="off"></span><span class="off"></span><span class="off"></span><span class="on"></span>',
};

const OB3 = `<div class="screen-inner ob-live ob3-fit"><div class="stat"><span data-go="ob2">←</span><span>3 of 5</span><span></span></div><div class="onboard-dots">${DOTS.ob3}</div><div class="ob-label ob-fade-up">Your night, planned</div><div class="h-display ob-fade-up d1" style="font-size:17px;margin-bottom:4px;">A full evening — ready on <span style="color:var(--gold)">Home</span></div><div class="muted note center ob-fade-up d1" style="font-size:9px;margin-bottom:10px;line-height:1.4;">Real venues · verified · timing &amp; route included</div><div class="ob-itin ob-anim-card ob-fade-up d1"><div class="ob-itin-hd"><div><div class="cream note" style="font-size:12px;">Romantic Italian Night</div><div class="dim note">Sat · 3 stops · ~$150</div></div><span style="color:var(--gold);">✦</span></div><div class="ob-itin-timeline"><div class="ob-stop ob-anim d1"><div><div class="t">7:00 PM</div><div class="n">Wine bar · start with reds</div></div></div><div class="ob-stop ob-anim d2"><div><div class="t">8:30 PM</div><div class="n">Trattoria · truffle pasta</div></div></div><div class="ob-stop ob-anim d3"><div><div class="t">10:30 PM</div><div class="n">Rooftop · nightcap</div></div></div></div></div><div class="ob3-actions ob-fade-up d2"><span class="pill">🍽 Reserve</span><span class="pill">🗺 Route</span><span class="pill">💬 Share</span><span class="pill">🎵 Playlist</span></div><div class="muted note center ob-fade-up d2" style="margin-top:auto;font-size:9px;">Lock it in with one tap — we'll show you on Home.</div><div class="screen-foot"><div class="cta" data-go="ob4">Next</div></div></div>`;

const OB4 = `<div class="screen-inner ob-live ob3-fit"><div class="stat"><span data-go="ob3">←</span><span>4 of 5</span><span></span></div><div class="onboard-dots">${DOTS.ob4}</div><div class="ob-label ob-fade-up">Plus on every date</div><div class="h-display ob-fade-up d1" style="font-size:17px;margin-bottom:4px;">Three extras that <span style="color:var(--gold)">elevate the night</span></div><div class="muted note center ob-fade-up d1" style="font-size:9px;margin-bottom:10px;line-height:1.4;">In Convo &amp; on your itinerary — ready when you are.</div><div class="tut-notes-cards ob-onboard-extras ob-fade-up d1"><div class="tut-notes-card" style="--delay:.35s"><span class="ico">✨</span><span><div>Convo starters</div><div class="sub">Swipe questions before dinner</div></span></div><div class="tut-notes-card" style="--delay:.5s"><span class="ico">💌</span><span><div>Love notes</div><div class="sub">Something sweet before they arrive</div></span></div><div class="tut-notes-card" style="--delay:.65s"><span class="ico">🎁</span><span><div>Gift finder</div><div class="sub">Thoughtful picks tied to your stops</div></span></div></div><div class="muted note center ob-fade-up d2" style="margin-top:auto;font-size:9px;">Premium unlocks unlimited nights &amp; all extras.</div><div class="screen-foot"><div class="cta" data-go="ob5">Next</div></div></div>`;

const OB5 = `<div class="screen-inner ob-live"><div class="stat"><span data-go="ob4">←</span><span>5 of 5</span><span></span></div><div class="onboard-dots">${DOTS.ob5}</div><div class="ob-label center ob-fade-up" style="margin-top:8px;">Almost there</div><div class="h-display center ob-fade-up d1" style="font-size:18px;margin-bottom:8px;">Ready for <span style="color:var(--gold)">better dates?</span></div><div class="muted note center ob-fade-up d2" style="margin-bottom:14px;line-height:1.45;">Quick Genie Profile — then your first plan waits on Home.</div><div class="ob-benefit ob-anim d1"><span class="ck">✓</span> Free plan included — no card to start</div><div class="ob-benefit ob-anim d2"><span class="ck">✓</span> Real venues, verified · tailored to you two</div><div class="ob-disclosure">About 2 minutes · skip anything you want</div><div class="screen-foot"><div class="cta" data-go="auth">Begin Your Journey</div></div></div>`;

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
  const byId = Object.fromEntries(screens.map((s) => [s.id, s]));

  // ob1 ob2: 5 dots + step labels
  byId.ob1.html = byId.ob1.html
    .replace('1 of 4', '1 of 5')
    .replace(
      '<span class="on"></span><span class="off"></span><span class="off"></span><span class="off"></span>',
      DOTS.ob1
    );
  byId.ob2.html = byId.ob2.html
    .replace('2 of 4', '2 of 5')
    .replace(
      '<span class="off"></span><span class="on"></span><span class="off"></span><span class="off"></span>',
      DOTS.ob2
    );

  byId.ob3.html = OB3;
  byId.ob3.label = 'OB3 · Sample itinerary';
  byId.ob4.html = OB4;
  byId.ob4.label = 'OB4 · Feature extras';

  const ob4Idx = screens.findIndex((s) => s.id === 'ob4');
  const ob5Idx = screens.findIndex((s) => s.id === 'ob5');
  if (ob5Idx >= 0) {
    screens[ob5Idx].html = OB5;
    screens[ob5Idx].label = 'OB5 · Almost there';
  } else if (ob4Idx >= 0) {
    screens.splice(ob4Idx + 1, 0, { id: 'ob5', label: 'OB5 · Almost there', html: OB5 });
  }

  fs.writeFileSync(PROTO, c.slice(0, start) + JSON.stringify(screens) + c.slice(i));
  let out = fs.readFileSync(PROTO, 'utf8');
  out = out.replace(
    "'Onboarding · OB1–4': ['splash', 'ob1', 'ob2', 'ob3', 'ob4']",
    "'Onboarding · OB1–5': ['splash', 'ob1', 'ob2', 'ob3', 'ob4', 'ob5']"
  );
  fs.writeFileSync(PROTO, out);
  console.log('Prototype: OB3 itinerary + OB4 features + OB5 CTA');
}

patchProto();
