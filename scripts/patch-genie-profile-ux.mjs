#!/usr/bin/env node
/** Align Genie Profile copy: 8 steps, not "6 questions" / global prototype step count. */
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const ROOT = path.dirname(path.dirname(fileURLToPath(import.meta.url)));
const PROTO = path.join(ROOT, 'YDG_interactive_prototype.html');
const DECL = path.join(ROOT, 'YDG_decluttered_mockup.html');

const GENIE_STEPS = {
  'pref-vibe': 1,
  'pref-scene': 2,
  'pref-food': 3,
  'pref-activities': 4,
  'pref-hardnos': 5,
  partner: 6,
  'pref-dates': 7,
  'pref-energy': 8,
};

const GENIE_IDS = ['hero', ...Object.keys(GENIE_STEPS), 'partner-joined'];

const HERO_OLD =
  '6 quick questions about vibe, food &amp; budget. Then Home shows finished plans to approve.';
const HERO_NEW =
  '8 quick steps — vibe, scene, food &amp; more. One-time Genie Profile, then Home shows finished plans to approve.';

const RENDER_OLD = `  document.getElementById('screenLabel').textContent = s.label;
  const idx = SCREENS.findIndex(x => x.id === id) + 1;
  document.getElementById('screenMeta').textContent = 'Step ' + idx + ' of ' + SCREENS.length + ' · ' + id;`;

const RENDER_NEW = `  document.getElementById('screenLabel').textContent = s.label;
  const gpStep = { hero: 'intro', 'partner-joined': 'partner joined', ...Object.fromEntries(Object.entries({ 'pref-vibe':1,'pref-scene':2,'pref-food':3,'pref-activities':4,'pref-hardnos':5,partner:6,'pref-dates':7,'pref-energy':8 })) };
  let meta = 'Step ' + (SCREENS.findIndex(x => x.id === id) + 1) + ' of ' + SCREENS.length + ' · ' + id;
  if (id in gpStep && id !== 'hero' && id !== 'partner-joined') meta = 'Genie Profile · ' + gpStep[id] + ' of 8';
  else if (id === 'hero') meta = 'Genie Profile · intro';
  else if (id === 'partner-joined') meta = 'Genie Profile · partner joined';
  else if (id === 'questionnaire' || id === 'questionnaire-fresh') meta = 'Date questionnaire · uses your Genie Profile';
  document.getElementById('screenMeta').textContent = meta;`;

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
  const hero = screens.find((s) => s.id === 'hero');
  if (hero?.html.includes(HERO_OLD)) hero.html = hero.html.replace(HERO_OLD, HERO_NEW);

  const labels = {
    hero: 'Genie Profile · intro',
    'pref-vibe': 'Genie Profile · 1 of 8 · vibe',
    'pref-scene': 'Genie Profile · 2 of 8 · scene',
    'pref-food': 'Genie Profile · 3 of 8 · food',
    'pref-activities': 'Genie Profile · 4 of 8 · activities',
    'pref-hardnos': 'Genie Profile · 5 of 8 · hard nos',
    partner: 'Genie Profile · 6 of 8 · partner',
    'partner-joined': 'Genie Profile · partner joined',
    'pref-dates': 'Genie Profile · 7 of 8 · dates',
    'pref-energy': 'Genie Profile · 8 of 8 · preferences',
  };

  for (const [id, step] of Object.entries(GENIE_STEPS)) {
    const s = screens.find((x) => x.id === id);
    if (!s) continue;
    s.html = s.html.replace(/<span>(\d+) of 8<\/span>/, `<span>Genie Profile · $1 of 8</span>`);
    if (labels[id]) s.label = labels[id];
    if (id === 'pref-scene' && !s.html.includes('One-time setup')) {
      s.html = s.html.replace(
        '<div class="h-display" style="font-size:21px;margin:18px 0 14px;">Set the scene</div>',
        '<div class="h-display" style="font-size:21px;margin:18px 0 6px;">Set the scene</div><div class="muted note" style="margin-bottom:10px;line-height:1.4;">One-time setup — saved to your profile, not asked again each date.</div>'
      );
    }
    if (id === 'pref-vibe' && !s.html.includes('One-time setup')) {
      s.html = s.html.replace(
        '<div class="muted note" style="margin-bottom:18px;">Pick a few — change it any night.</div>',
        '<div class="muted note" style="margin-bottom:6px;">Genie Profile · one-time setup</div><div class="muted note" style="margin-bottom:14px;">Pick a few — change anytime in You.</div>'
      );
    }
  }
});

let proto = fs.readFileSync(PROTO, 'utf8');
if (proto.includes(RENDER_OLD)) proto = proto.replace(RENDER_OLD, RENDER_NEW);
fs.writeFileSync(PROTO, proto);

let decl = fs.readFileSync(DECL, 'utf8');
decl = decl.replace(/6 quick questions about vibe, food &amp; budget/g, HERO_NEW.replace(/&amp;/g, '&'));
for (let n = 1; n <= 8; n++) {
  decl = decl.replace(new RegExp(`<span>← back</span><span>${n} of 8</span>`, 'g'), `<span>← back</span><span>Genie Profile · ${n} of 8</span>`);
}
if (!decl.includes('One-time setup — saved to your profile')) {
  decl = decl.replace(
    '<div class="h-display" style="font-size:21px;margin:18px 0 14px;">Set the scene</div>',
    '<div class="h-display" style="font-size:21px;margin:18px 0 6px;">Set the scene</div><div class="muted note" style="margin-bottom:10px;line-height:1.4;">One-time setup — saved to your profile, not asked again each date.</div>'
  );
}
fs.writeFileSync(DECL, decl);

console.log('Patched Genie Profile UX — 8 steps, clear vs date questionnaire');
