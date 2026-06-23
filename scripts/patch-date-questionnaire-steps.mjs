#!/usr/bin/env node
/** Restore 6-step date questionnaire with pinned Next → Generate (matches iOS). */
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const ROOT = path.dirname(path.dirname(fileURLToPath(import.meta.url)));
const PROTO = path.join(ROOT, 'YDG_interactive_prototype.html');

const foot = (next, label = 'Next →') =>
  '<div style="flex:1;min-height:0;"></div><div class="screen-foot"><div class="cta" data-go="' +
  next +
  '">' +
  label +
  '</div></div>';

const wrap = (back, step, body, next, btnLabel) =>
  '<div class="screen-inner screen-scroll"><div class="stat"><span data-go="' +
  back +
  '">←</span><span>' +
  step +
  ' of 6</span><span></span></div>' +
  body +
  foot(next, btnLabel) +
  '</div>';

const SCREENS_DQ = [
  {
    id: 'dq1',
    label: 'Date Q · 1/6 · Location',
    replaces: 'questionnaire',
    html: wrap(
      'home',
      '1',
      '<div class="pill" style="margin-bottom:10px;">Using Genie Profile · city &amp; radius saved</div>' +
        '<div class="h-display" style="font-size:19px;margin:0 0 10px;">Where are you planning?</div>' +
        '<div class="label" style="margin-bottom:6px;">📍 City or neighborhood</div>' +
        '<div class="card" style="padding:10px 12px;margin-bottom:12px;"><span class="row-title">Metuchen, NJ</span></div>' +
        '<div class="label" style="margin-bottom:6px;">Starting address</div>' +
        '<div class="input-field" style="margin-bottom:6px;"><span class="placeholder">Your starting address (required)</span></div>' +
        '<div class="field-hint">Required for your route and map</div>',
      'dq2'
    ),
  },
  {
    id: 'dq1-fresh',
    label: 'Date Q · 1/6 · Fresh',
    replaces: 'questionnaire-fresh',
    html: wrap(
      'plan-fresh',
      '1',
      '<div class="pill" style="margin-bottom:10px;background:rgba(214,174,84,.12);">Starting fresh · not using saved prefs</div>' +
        '<div class="h-display" style="font-size:19px;margin:0 0 10px;">Where are you planning?</div>' +
        '<div class="label" style="margin-bottom:6px;">📍 City or neighborhood</div>' +
        '<div class="input-field" style="margin-bottom:12px;"><span class="placeholder">City or neighborhood</span></div>' +
        '<div class="label" style="margin-bottom:6px;">Starting address</div>' +
        '<div class="input-field" style="margin-bottom:6px;"><span class="placeholder">Your starting address (required)</span></div>' +
        '<div class="field-hint">Required for your route and map</div>',
      'dq2'
    ),
  },
  {
    id: 'dq2',
    label: 'Date Q · 2/6 · Transport',
    html: wrap(
      'dq1',
      '2',
      '<div class="h-display" style="font-size:19px;margin:0 0 10px;">Getting there</div>' +
        '<div class="label" style="margin-bottom:6px;">🚗 How will you get around?</div>' +
        '<div class="chips" style="margin-bottom:14px;gap:6px;"><span class="chip on">🚗 Drive</span><span class="chip">🚶 Walk</span><span class="chip">🚆 Transit</span><span class="chip">🚕 Rideshare</span></div>' +
        '<div class="label" style="margin-bottom:6px;">How far are you willing to travel?</div>' +
        '<div class="field-hint">Select your comfort zone — we\'ll keep stops within this range.</div>' +
        '<div class="chips" style="margin-bottom:8px;gap:6px;"><span class="chip">👣 Walkable · &lt;1 mi</span><span class="chip on">🏘️ Neighborhood · 1–5 mi</span><span class="chip">🌆 City-wide · 5–15 mi</span><span class="chip">🗺️ Metro · 15+ mi</span></div>',
      'dq3'
    ),
  },
  {
    id: 'dq3',
    label: 'Date Q · 3/6 · Vibe',
    html: wrap(
      'dq2',
      '3',
      '<div class="h-display" style="font-size:19px;margin:0 0 10px;">Set the vibe</div>' +
        '<div class="label" style="margin-bottom:6px;">⚡ Energy tonight</div>' +
        '<div class="chips" style="margin-bottom:14px;gap:6px;"><span class="chip">Chill</span><span class="chip on">Balanced</span><span class="chip">Active</span><span class="chip">High energy</span></div>' +
        '<div class="label" style="margin-bottom:6px;">Date type</div>' +
        '<div class="chips" style="margin-bottom:14px;gap:6px;"><span class="chip">First date</span><span class="chip on">Romantic</span><span class="chip">Casual</span><span class="chip">Adventure</span></div>' +
        '<div class="label" style="margin-bottom:6px;">When</div>' +
        '<div class="card" style="padding:10px 12px;margin-bottom:8px;"><span class="row-title">Sat Jun 14 · 7 PM</span></div>',
      'dq4'
    ),
  },
  {
    id: 'dq4',
    label: 'Date Q · 4/6 · Food',
    html: wrap(
      'dq3',
      '4',
      '<div class="h-display" style="font-size:19px;margin:0 0 10px;">Food &amp; drink</div>' +
        '<div class="label" style="margin-bottom:6px;">💰 Budget for tonight</div>' +
        '<div class="chips" style="margin-bottom:14px;gap:6px;"><span class="chip">$</span><span class="chip on">$$</span><span class="chip">$$$</span><span class="chip">$$$$</span></div>' +
        '<div class="label" style="margin-bottom:6px;">🍽️ Cuisine preferences?</div>' +
        '<div class="field-hint">Select all that sound good</div>' +
        '<div class="chips" style="margin-bottom:14px;gap:6px;"><span class="chip on">🍝 Italian</span><span class="chip on">🍣 Japanese</span><span class="chip">🌮 Mexican</span><span class="chip">🍛 Indian</span><span class="chip">🥐 French</span><span class="chip">🍜 Thai</span></div>' +
        '<div class="label" style="margin-bottom:6px;">🥗 Dietary restrictions</div>' +
        '<div class="chips" style="margin-bottom:8px;gap:6px;"><span class="chip on">🌾 Gluten-free</span><span class="chip">🥬 Vegetarian</span><span class="chip">🌱 Vegan</span><span class="chip">✅ None</span></div>',
      'dq5'
    ),
  },
  {
    id: 'dq5',
    label: 'Date Q · 5/6 · Deal-breakers',
    html: wrap(
      'dq4',
      '5',
      '<div class="h-display" style="font-size:19px;margin:0 0 10px;">Any deal-breakers?</div>' +
        '<div class="muted note" style="margin-bottom:12px;line-height:1.45;">Optional — helps us filter out bad matches.</div>' +
        '<div class="label" style="margin-bottom:6px;">⚠️ Food allergies</div>' +
        '<div class="chips" style="margin-bottom:14px;gap:6px;"><span class="chip on">None</span><span class="chip">Nuts</span><span class="chip">Shellfish</span><span class="chip">Dairy</span><span class="chip">Gluten</span></div>' +
        '<div class="label" style="margin-bottom:6px;">Hard no\'s tonight</div>' +
        '<div class="chips" style="margin-bottom:8px;gap:6px;"><span class="chip">Loud venues</span><span class="chip on">Crowds</span><span class="chip">Heights</span><span class="chip">Late nights</span></div>',
      'dq6'
    ),
  },
  {
    id: 'dq6',
    label: 'Date Q · 6/6 · Extras',
    html: wrap(
      'dq5',
      '6',
      '<div class="h-display" style="font-size:19px;margin:0 0 10px;">Anything else?</div>' +
        '<div class="label" style="margin-bottom:8px;">Add-ons for tonight</div>' +
        '<div class="card" style="margin-bottom:8px;display:flex;justify-content:space-between;align-items:center;padding:10px 12px;"><div><div class="row-title">🎁 Gift suggestions</div><div class="dim note">Ideas between stops</div></div><span class="toggle"></span></div>' +
        '<div class="card" style="margin-bottom:8px;display:flex;justify-content:space-between;align-items:center;padding:10px 12px;"><div><div class="row-title">✨ Convo starters</div><div class="dim note">Questions for the table</div></div><span class="toggle"></span></div>' +
        '<div class="card" style="margin-bottom:8px;padding:10px 12px;"><div class="row-title">Special notes</div><div class="input-field" style="margin:8px 0 0;"><span class="placeholder">Celebrating something? Any must-haves?</span></div></div>',
      'generating',
      '✦ Generate Date Plan'
    ),
  },
];

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
  for (const def of SCREENS_DQ) {
    if (def.replaces) {
      const idx = screens.findIndex((s) => s.id === def.replaces);
      if (idx >= 0) {
        screens[idx] = { id: def.id, label: def.label, html: def.html };
      } else {
        screens.push({ id: def.id, label: def.label, html: def.html });
      }
    } else if (!screens.some((s) => s.id === def.id)) {
      screens.push({ id: def.id, label: def.label, html: def.html });
    } else {
      const s = screens.find((x) => x.id === def.id);
      s.label = def.label;
      s.html = def.html;
    }
  }

  // Rewire entry points
  for (const s of screens) {
    s.html = s.html
      .replace(/data-go="questionnaire"/g, 'data-go="dq1"')
      .replace(/data-go="questionnaire-fresh"/g, 'data-go="dq1-fresh"');
  }

  const pf = screens.find((s) => s.id === 'plan-fresh');
  if (pf) {
    pf.html = pf.html.replace('data-go="questionnaire-fresh"', 'data-go="dq1-fresh"');
  }
});

let proto = fs.readFileSync(PROTO, 'utf8');

if (!proto.includes("'Date questionnaire'")) {
  proto = proto.replace(
    "'Genie Profile · 8 steps': ['hero', 'pref-vibe', 'pref-scene', 'pref-food', 'pref-activities', 'pref-hardnos', 'partner', 'partner-joined', 'pref-dates', 'pref-energy'],",
    "'Genie Profile · 8 steps': ['hero', 'pref-vibe', 'pref-scene', 'pref-food', 'pref-activities', 'pref-hardnos', 'partner', 'partner-joined', 'pref-dates', 'pref-energy'],\n  'Date questionnaire · 6 steps': ['dq1', 'dq1-fresh', 'dq2', 'dq3', 'dq4', 'dq5', 'dq6'],"
  );
}

const metaOld =
  "else if (id === 'questionnaire' || id === 'questionnaire-fresh') meta = 'Date questionnaire · uses your Genie Profile';";
const metaNew = `const dqStep = { dq1: 1, 'dq1-fresh': 1, dq2: 2, dq3: 3, dq4: 4, dq5: 5, dq6: 6 };
  if (id in dqStep) meta = 'Date questionnaire · ' + dqStep[id] + ' of 6';`;

if (proto.includes(metaOld)) {
  proto = proto.replace(metaOld, metaNew);
} else if (!proto.includes('dqStep')) {
  proto = proto.replace(
    "else if (id === 'you-business') meta = 'Business profile · venue partners';",
    metaNew + "\n  else if (id === 'you-business') meta = 'Business profile · venue partners';"
  );
}

fs.writeFileSync(PROTO, proto);

console.log('Restored 6-step date questionnaire with Next → Generate Date Plan');
