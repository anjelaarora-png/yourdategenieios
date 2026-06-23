#!/usr/bin/env node
/** Business ads apply to all venue types — not Italian-only examples. */
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const ROOT = path.dirname(path.dirname(fileURLToPath(import.meta.url)));
const PROTO = path.join(ROOT, 'YDG_interactive_prototype.html');
const DECL = path.join(ROOT, 'YDG_decluttered_mockup.html');

const ITALIAN_OLD = 'When couples ask for romantic Italian near Metuchen — you can show up.';
const ITALIAN_NEW =
  'When Genie matches your city, vibe &amp; category — jazz bar, brewery, spa, mini-golf — you can show up.';

const WEB_ITALIAN_OLD = 'Romantic Italian near Metuchen — you show up.';
const WEB_ITALIAN_NEW = 'Cozy cocktails, live music, adventure dates — when you fit, you show up.';

const CHIPS_OLD =
  '<div class="chips" style="gap:5px;margin-bottom:12px;"><span class="chip on">Restaurant</span><span class="chip">Bar</span><span class="chip">Activity</span><span class="chip">Retail</span></div>';
const CHIPS_NEW =
  '<div class="label" style="margin-bottom:6px;">What kind of date spot?</div><div class="chips" style="gap:5px;margin-bottom:12px;"><span class="chip on">Restaurant</span><span class="chip">Bar &amp; lounge</span><span class="chip">Activity</span><span class="chip">Retail</span><span class="chip">Other</span></div>';

const YOU_SUB_OLD = 'Restaurant · bar · experience';
const YOU_SUB_NEW = 'Any date-night category · your city';

function patchScreens(setHtml) {
  const marker = 'const SCREENS = [';
  let c = fs.readFileSync(PROTO, 'utf8');
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
  setHtml(screens);
  fs.writeFileSync(PROTO, c.slice(0, start) + JSON.stringify(screens) + c.slice(i));
}

patchScreens((screens) => {
  const fb = screens.find((s) => s.id === 'for-business');
  if (fb) {
    fb.html = fb.html
      .replace(ITALIAN_OLD, ITALIAN_NEW)
      .replace(
        'Featured placement when Genie matches your city &amp; vibe — restaurants, bars, experiences &amp; more.',
        'Featured placement for every date-night category — restaurants, bars, experiences, retail &amp; more.'
      )
      .replace(CHIPS_OLD, CHIPS_NEW);
  }

  const yb = screens.find((s) => s.id === 'you-business');
  if (yb) {
    yb.html = yb.html.replace(YOU_SUB_OLD, YOU_SUB_NEW);
    if (!yb.html.includes('All categories welcome')) {
      yb.html = yb.html.replace(
        '<div class="pill" style="margin-bottom:12px;">Venue partner · apply to go live</div>',
        '<div class="pill" style="margin-bottom:12px;">All categories welcome · not just restaurants</div>'
      );
    }
  }
});

let decl = fs.readFileSync(DECL, 'utf8');
decl = decl.replace(new RegExp(ITALIAN_OLD.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), 'g'), ITALIAN_NEW);
decl = decl.replace(/Romantic Italian near Metuchen — you show up\./g, WEB_ITALIAN_NEW);
decl = decl.replace(
  /Featured when Genie matches your city &amp; category\./g,
  'Featured for any date-night category in your city.'
);
if (decl.includes('actbiz')) {
  decl = decl.replace(
    '<div class="ssub">Web signup at',
    '<div class="ssub">Restaurants, bars, activities, retail &amp; more — not cuisine-specific. Web signup at'
  );
}

fs.writeFileSync(DECL, decl);

console.log('Patched business ad copy — all venue categories, not Italian-only');
