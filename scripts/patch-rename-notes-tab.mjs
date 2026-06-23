#!/usr/bin/env node
/**
 * Rename misleading "Notes" tab → "Convo" (convo starters hub).
 * Keeps route id `notes` for prototype navigation.
 */
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const ROOT = path.dirname(path.dirname(fileURLToPath(import.meta.url)));
const PROTO = path.join(ROOT, 'YDG_interactive_prototype.html');
const DECL = path.join(ROOT, 'YDG_decluttered_mockup.html');
const REDESIGN = path.join(ROOT, 'YDG_full_app_redesign.html');
const SPEC = path.join(ROOT, 'YDG_REDESIGN_BUILD_SPEC.md');

function patchTabCopy(html) {
  return html
    .replace(/<div class="ic">✉<\/div>Notes/g, '<div class="ic">✨</div>Convo')
    .replace(/Notes tab/g, 'Convo tab')
    .replace(/Notes &amp; itinerary/g, 'Convo &amp; itinerary')
    .replace(/Notes & itinerary/g, 'Convo & itinerary')
    .replace(/In Notes &amp; on your itinerary/g, 'In Convo &amp; on your itinerary')
    .replace(/In Notes & on your itinerary/g, 'In Convo & on your itinerary')
    .replace(/in Notes &amp; on your itinerary/g, 'in Convo &amp; on your itinerary')
    .replace(/in Notes & on your itinerary/g, 'in Convo & on your itinerary')
    .replace(/Home · Dates · Notes · You/g, 'Home · Dates · Convo · You')
    .replace(/lock in · Dates · Notes/g, 'lock in · Dates · Convo')
    .replace(/→ Notes tab/g, '→ Convo tab')
    .replace(/Tutorial 3 · Notes tab/g, 'Tutorial 3 · Convo tab')
    .replace(/08c · Tutorial 3\/3<\/b> · Notes tab/g, '08c · Tutorial 3/3</b> · Convo tab')
    .replace(
      /<div class="tab on"><div class="ic">✉<\/div>Notes<\/div>/g,
      '<div class="tab on"><div class="ic">✨</div>Convo</div>'
    );
}

function patchFile(filePath, transform = patchTabCopy) {
  if (!fs.existsSync(filePath)) return false;
  const before = fs.readFileSync(filePath, 'utf8');
  const after = transform(before);
  if (after !== before) fs.writeFileSync(filePath, after);
  return after !== before;
}

// Prototype SCREENS JSON
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
for (const s of screens) {
  if (s.html) s.html = patchTabCopy(s.html);
  if (s.label?.includes('Notes tab')) s.label = s.label.replace('Notes tab', 'Convo tab');
  if (s.id === 'tutorial3') s.label = 'Tutorial 3 · Convo tab';
}
fs.writeFileSync(PROTO, c.slice(0, start) + JSON.stringify(screens) + c.slice(i));

patchFile(DECL);
patchFile(REDESIGN);
patchFile(SPEC, (t) =>
  t
    .replace(/Home · Dates · Notes · You/g, 'Home · Dates · Convo · You')
    .replace(/Notes · Sparks/g, 'Convo tab · Sparks')
);

// Patch helper scripts so re-runs stay consistent
for (const rel of [
  'scripts/patch-ob4-extras.mjs',
  'scripts/patch-tutorial3-notes-visuals.mjs',
  'scripts/patch-lovenotes-convo-ios.mjs',
    'scripts/patch-onboarding-dedupe.mjs',
    'scripts/patch-ob3-ob4.mjs',
    'scripts/patch-ob3-ob4-split.mjs',
]) {
  const p = path.join(ROOT, rel);
  if (!fs.existsSync(p)) continue;
  let t = fs.readFileSync(p, 'utf8');
  const next = patchTabCopy(t);
  if (next !== t) fs.writeFileSync(p, next);
}

console.log('Renamed Notes tab → Convo across mockups + prototype');
