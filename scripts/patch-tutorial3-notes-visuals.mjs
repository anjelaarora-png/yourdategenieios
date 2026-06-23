#!/usr/bin/env node
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const ROOT = path.dirname(path.dirname(fileURLToPath(import.meta.url)));
const PROTO = path.join(ROOT, 'YDG_interactive_prototype.html');
const DECL = path.join(ROOT, 'YDG_decluttered_mockup.html');

const TUTORIAL3 = `<div class="screen-inner ob-live tutorial-screen tut-notes-live"><div class="tutorial-bg tutorial-bg-notes"></div><div class="tut-notes-sparks ob-sparks-fly" aria-hidden="true"><span class="spark">✨</span><span class="spark">💫</span><span class="spark">✨</span><span class="spark">💌</span><span class="spark">✨</span><span class="spark">🎁</span></div><div class="tutorial-sheet tut-sheet-notes tut-notes-sheet"><div class="tut-progress ob-fade-up"><span class=""></span><span class=""></span><span class="on"></span></div><div class="ob-label ob-fade-up d1">Convo tab</div><div class="h-display tut-notes-headline ob-fade-up d1">Plus on <span class="tut-gold-shimmer">every date</span></div><div class="tut-notes-sub ob-fade-up d2">Three extras that elevate the night</div><div class="muted note tut-notes-lede ob-fade-up d2">In Convo &amp; on your itinerary — ready when you are.</div><div class="tut-tabbar-demo tut-tabbar-animate"><div class="tab"><div class="ic">⌂</div>Home</div><div class="tab"><div class="ic">♥</div>Dates</div><div class="tab on"><div class="ic">✨</div>Convo</div><div class="tab"><div class="ic">◔</div>You</div></div><div class="tut-notes-cards tut-notes-tutorial tut-notes-cards-live"><div class="tut-notes-card" style="--delay:.55s"><span class="ico-wrap">✨</span><span class="tut-notes-copy"><div>Convo starters</div><div class="sub">Swipe questions before dinner</div></span></div><div class="tut-notes-card" style="--delay:.72s"><span class="ico-wrap">💌</span><span class="tut-notes-copy"><div>Love notes</div><div class="sub">Something sweet before they arrive</div></span></div><div class="tut-notes-card" style="--delay:.9s"><span class="ico-wrap">🎁</span><span class="tut-notes-copy"><div>Gift finder</div><div class="sub">Thoughtful picks tied to your stops</div></span></div></div><div class="tut-premium-note ob-fade-up d3">Premium unlocks unlimited nights &amp; all extras.</div><div class="cta tut-cta-glow ob-fade-up d3" data-go="home">Got it!</div></div></div>`;

const DECL_FRAME =
  '<div class="frame"><div class="cap"><b>08c · Tutorial 3/3</b> · Convo tab · animated extras</div><div class="phone"><div class="screen ob-live tutorial-screen tut-notes-live" style="display:flex;flex-direction:column;">' +
  TUTORIAL3.replace('class="screen-inner ob-live tutorial-screen tut-notes-live"', 'class="tutorial-screen tut-notes-live" style="display:flex;flex-direction:column;flex:1;min-height:100%;width:100%;position:relative;"').replace(' data-go="home"', '') +
  '</div></div></div>';

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
const t3 = screens.find((s) => s.id === 'tutorial3');
if (t3) {
  t3.html = TUTORIAL3;
  t3.label = 'Tutorial 3 · Convo tab';
}
fs.writeFileSync(PROTO, c.slice(0, start) + JSON.stringify(screens) + c.slice(i));

let decl = fs.readFileSync(DECL, 'utf8');
decl = decl.replace(
  /<div class="frame"><div class="cap"><b>08c · Tutorial 3\/3<\/b>[\s\S]*?<\/div><\/div><\/div>\s*\n\s*<\/div>/,
  DECL_FRAME + '\n\n  </div>'
);
fs.writeFileSync(DECL, decl);
console.log('Patched tutorial3 animated copy + visuals');
