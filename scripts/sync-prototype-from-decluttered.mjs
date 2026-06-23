#!/usr/bin/env node
/**
 * Sync YDG_interactive_prototype.html SCREENS from YDG_decluttered_mockup.html frames.
 * Uses bracket matching — never regex to first ];
 */
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const ROOT = path.dirname(path.dirname(fileURLToPath(import.meta.url)));
const DECL = path.join(ROOT, 'YDG_decluttered_mockup.html');
const PROTO = path.join(ROOT, 'YDG_interactive_prototype.html');

function parseScreens(file) {
  const c = fs.readFileSync(file, 'utf8');
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
  return { screens: JSON.parse(c.slice(start, i)), fileContent: c, arrayStart: start, arrayEnd: i };
}

function extractFrameKey(capHtml) {
  const m = capHtml.match(/<b>([^<]+)<\/b>/);
  if (!m) return null;
  const full = m[1].trim();
  const key = full.split(' · ')[0].trim();
  return { key, label: full };
}

function extractScreenInner(html, frameStart) {
  const phoneIdx = html.indexOf('<div class="phone">', frameStart);
  if (phoneIdx === -1) return null;
  const screenOpen = html.indexOf('<div class="screen', phoneIdx);
  if (screenOpen === -1) return null;
  const gt = html.indexOf('>', screenOpen);
  let depth = 1;
  let i = gt + 1;
  for (; i < html.length; i++) {
    if (html[i] === '<' && /^<div[\s>]/i.test(html.slice(i, i + 5))) depth++;
    if (html.slice(i, i + 6) === '</div>') {
      depth--;
      if (depth === 0) {
        return html.slice(gt + 1, i);
      }
    }
  }
  return null;
}

function buildFrameMap(declHtml) {
  const map = {};
  const capRe = /<div class="cap"><b>[^<]+<\/b>[^<]*<\/div>/g;
  let m;
  const caps = [];
  while ((m = capRe.exec(declHtml)) !== null) {
    const info = extractFrameKey(m[0]);
    if (info) caps.push({ ...info, index: m.index });
  }
  for (let i = 0; i < caps.length; i++) {
    const inner = extractScreenInner(declHtml, caps[i].index);
    if (inner) map[caps[i].key] = { ...caps[i], inner: inner.trim() };
  }
  return map;
}

function esc(s) {
  return s.replace(/\\/g, '\\\\').replace(/"/g, '\\"');
}

function wrap(inner, cls = 'screen-inner', extra = '') {
  return `<div class="${cls}"${extra ? ' ' + extra : ''}>${inner}</div>`;
}

function navBack(html, target) {
  return html.replace(/<span>←[^<]*<\/span>/, `<span data-go="${target}">←</span>`);
}

function navSpan(html, from, to) {
  return html.replace(new RegExp(`<span>${from}</span>`, 'g'), `<span data-go="${to}">${from}</span>`);
}

function addCtaNav(html, text, target) {
  const re = new RegExp(`(<div class="cta"[^>]*>)(${text.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')})`);
  return html.replace(re, `$1 data-go="${target}"$2`);
}

function tabbar(html, active, nav = true) {
  const tabs = [
    ['home', '⌂', 'Home'],
    ['dates', '♥', 'Dates'],
    ['notes', '✨', 'Convo'],
    ['you', '◔', 'You'],
  ];
  const tb = tabs
    .map(([id, ic, lbl]) => {
      const on = id === active ? ' on' : '';
      const go = nav ? ` data-go="${id}" data-tab="${id}"` : '';
      return `<div class="tab${on}"${go}><div class="ic">${ic}</div>${lbl}</div>`;
    })
    .join('');
  const inner = html.replace(/<div class="tabbar">[\s\S]*?<\/div>/, '');
  return inner.replace(/(<\/div>\s*)$/, `<div style="flex:1;min-height:0;"></div><div class="screen-foot"><div class="tabbar" data-tabs="1">${tb}</div></div></div>`);
}

/** Frame key → prototype screen builder */
const BUILDERS = {
  '14': (f) => {
    let h = f.inner;
    h = navBack(h, 'itinerary');
    h = h.replace('<span class="pill">🎁 Add a gift</span>', '<span class="pill" data-go="gifts">🎁 Add a gift</span>');
    h = addCtaNav(h, 'Save this night', 'itinerary');
    h = h.replace('<div class="cta" style="margin-top:auto;margin-bottom:13px;">', '<div class="cta" style="margin-top:auto;margin-bottom:13px;" data-go="itinerary">');
    return wrap(h, 'screen-inner', 'style="padding:0;display:flex;flex-direction:column;"');
  },
  '23': (f) => {
    let h = f.inner;
    h = h.replace('<span>✕</span>', `<span data-go="locked-in">✕</span>`);
    h = h.replace('<span class="cta-sm">7-day free trial</span>', `<span class="cta-sm" data-go="dates">7-day free trial</span>`);
    h = h.replace('<span class="ghost">Choose</span>', `<span class="ghost" data-go="dates">Choose</span>`);
    h = h.replace('<span class="link">Maybe later</span>', `<span class="link" data-go="dates">Maybe later</span>`);
    return wrap(h, 'screen-inner screen-scroll');
  },
  '24': (f) => {
    let h = f.inner;
    h = h.replace('<span>✕</span>', `<span data-go="stop-detail">✕</span>`);
    h = addCtaNav(h, '✦ Find gift ideas', 'gifts');
    return wrap(h, 'screen-inner screen-scroll');
  },
  '24b': (f) => {
    let h = f.inner;
    h = navBack(h, 'gifts');
    return wrap(h, 'screen-inner screen-scroll');
  },
  '17': (f) => {
    let h = f.inner;
    h = addCtaNav(h, 'Add a photo', 'memories');
    h = h.replace('<span class="link">Maybe later</span>', `<span class="link" data-go="dates">Maybe later</span>`);
    return wrap(h, 'screen-inner center', 'style="text-align:center;justify-content:center;"');
  },
  '10': (f) => {
    let h = f.inner;
    h = navBack(h, 'home');
    h = addCtaNav(h, 'Lock in the night in', 'locked-in');
    return wrap(h, 'screen-inner screen-scroll');
  },
  '11b': (f) => {
    let h = f.inner;
    h = h.replace('<span>✕</span>', `<span data-go="home">✕</span>`);
    h = addCtaNav(h, 'Build 3 options →', 'partner-rank');
    return wrap(h, 'screen-inner screen-scroll');
  },
  '11c': (f) => {
    let h = f.inner;
    h = navBack(h, 'partner-plan');
    h = addCtaNav(h, 'Send 3 to Maya →', 'partner-reveal');
    return wrap(h, 'screen-inner screen-scroll');
  },
  '11d': (f) => {
    let h = f.inner;
    h = addCtaNav(h, 'Choose Saturday 💛', 'locked-in');
    return wrap(h, 'screen-inner screen-scroll');
  },
  '16': (f) => {
    let h = f.inner;
    h = addCtaNav(h, 'See the night', 'itinerary');
    return wrap(h, 'screen-inner center', 'style="text-align:center;justify-content:center;"');
  },
  'G3': (f) => {
    let h = f.inner;
    h = navBack(h, 'you');
    h = addCtaNav(h, 'Plan a night → +180 XP', 'questionnaire');
    return wrap(h, 'screen-inner screen-scroll');
  },
  '25': (f) => {
    let h = f.inner;
    h = navBack(h, 'you');
    h = h.replace('Date preferences', 'Date preferences');
    h = h.replace('<div class="card" style="margin-bottom:8px;"><span class="cream note">Date preferences</span>', `<div class="card" style="margin-bottom:8px;display:flex;justify-content:space-between;align-items:center;padding:10px 12px;" data-go="genie-profile"><span class="cream note">Date preferences</span>`);
    h = h.replace('<div class="ghost" style="margin-top:auto;margin-bottom:13px;">Restore Purchases</div>', `<div class="ghost" style="margin-top:8px;" data-go="signout">Sign Out</div>`);
    h = h.replace('<div class="card" style="margin-bottom:8px;"><span class="cream note">Report a Concern</span></div>', `<div class="card" style="margin-bottom:8px;padding:10px 12px;"><span class="cream note">Report a Concern</span></div><div class="card" style="margin-bottom:8px;padding:10px 12px;" data-go="delete-account"><span class="cream note">Delete account</span></div>`);
    return wrap(h, 'screen-inner screen-scroll');
  },
  '27': (f) => {
    let h = f.inner;
    h = h.replace('<div class="cta" style="margin-bottom:9px;background:#8a3030;color:#fff;">Sign Out</div>', `<div class="cta" style="margin-bottom:9px;background:#8a3030;color:#fff;" data-go="splash">Sign Out</div>`);
    h = h.replace('<div class="ghost" style="margin-bottom:13px;">Cancel</div>', `<div class="ghost" style="margin-bottom:13px;" data-go="you">Cancel</div>`);
    return wrap(h, 'screen-inner center', 'style="text-align:center;justify-content:center;"');
  },
  '28': (f) => {
    let h = f.inner;
    h = h.replace('<div class="cta" style="margin-bottom:9px;background:#6a1515;color:#fff;">Delete Account</div>', `<div class="cta" style="margin-bottom:9px;background:#6a1515;color:#fff;" data-go="splash">Delete Account</div>`);
    h = h.replace('<div class="ghost" style="margin-bottom:13px;">Cancel</div>', `<div class="ghost" style="margin-bottom:13px;" data-go="settings">Cancel</div>`);
    return wrap(h, 'screen-inner center', 'style="text-align:center;justify-content:center;"');
  },
  '18': (f) => {
    let h = f.inner;
    h = navBack(h, 'home');
    h = h.replace('<span class="nav-brand">', `<span class="nav-brand" data-go="home">`);
    h = addCtaNav(h, 'Plan our anniversary', 'questionnaire');
    h = h.replace('<span class="link">Remind me in a few days</span>', `<span class="link" data-go="home">Remind me in a few days</span>`);
    return wrap(h, 'screen-inner');
  },
  '05b': (f) => {
    let h = f.inner;
    h = addCtaNav(h, 'Continue', 'pref-dates');
    return wrap(h, 'screen-inner center', 'style="text-align:center;"');
  },
  'F27': (f) => {
    let h = f.inner;
    h = h.replace('<span>✕</span>', `<span data-go="itinerary">←</span>`);
    h = `<div class="h-display center" style="font-size:18px;text-align:center;margin:12px 0 8px;">Share with your date</div><div class="muted note center" style="margin-bottom:14px;line-height:1.45;">Send tonight's itinerary by text, email, or copy.</div>` + h;
    h = h.replace('📋 Copy</div>', `📋 Copy to clipboard</div><div class="link center" data-go="love-notes">Add a love note first →</div>`);
    return wrap(h, 'screen-inner screen-scroll');
  },
};

const FRAME_TO_ID = {
  '14': 'stop-detail',
  '23': 'paywall',
  '24': 'gifts',
  '17': 'memory',
  '10': 'lowkey',
  '11b': 'partner-plan',
  '11c': 'partner-rank',
  '11d': 'partner-reveal',
  '16': 'invite-received',
  'G3': 'journey',
  '25': 'settings',
  '27': 'signout',
  '28': 'delete-account',
  '18': 'nudge',
  '05b': 'partner-joined',
  'F27': 'share-plan',
};

const declHtml = fs.readFileSync(DECL, 'utf8');
const frames = buildFrameMap(declHtml);
const { screens, fileContent, arrayStart, arrayEnd } = parseScreens(PROTO);
const byId = Object.fromEntries(screens.map((s) => [s.id, s]));

const updated = [];
const added = [];

for (const [frameKey, screenId] of Object.entries(FRAME_TO_ID)) {
  const frame = frames[frameKey];
  const builder = BUILDERS[frameKey];
  if (!frame || !builder) {
    console.warn('Skip (missing):', frameKey, screenId);
    continue;
  }
  const html = builder(frame);
  if (byId[screenId]) {
    byId[screenId].html = html;
    updated.push(screenId);
  } else {
    const label = frame.label.split(' · ').slice(1).join(' · ') || frame.label;
    const newScreen = { id: screenId, label: label.trim() || screenId, html };
    screens.push(newScreen);
    byId[screenId] = newScreen;
    added.push(screenId);
  }
}

// Fix share-plan love note link
if (byId['share-plan']) {
  byId['share-plan'].html = byId['share-plan'].html.replace(
    'data-go="love-note"',
    'data-go="love-notes"'
  );
}

// Wire partner → partner-joined optional branch (Send invite stays → pref-dates; add solo path)
if (byId['partner'] && !byId['partner'].html.includes('partner-joined')) {
  // optional: partner screen can navigate to partner-joined on send - skip for now
}

// Fix notes tab active state
if (byId['notes']) {
  byId['notes'].html = byId['notes'].html.replace(
    'data-tab="notes" style="color:var(--dim);"',
    'data-tab="notes" class="on"'
  );
  byId['notes'].html = byId['notes'].html.replace(
    '<div class="tab" data-go="notes" data-tab="notes" style="color:var(--dim);">',
    '<div class="tab on" data-go="notes" data-tab="notes">'
  );
}

const newJson = JSON.stringify(screens);
const out = fileContent.slice(0, arrayStart) + newJson + fileContent.slice(arrayEnd);

// Update jump menu for partner-joined
let finalOut = out;
if (added.includes('partner-joined')) {
  finalOut = finalOut.replace(
    "'partner', 'pref-dates', 'pref-energy'",
    "'partner', 'partner-joined', 'pref-dates', 'pref-energy'"
  );
}

fs.writeFileSync(PROTO, finalOut);
console.log('Updated:', updated.join(', '));
if (added.length) console.log('Added:', added.join(', '));
console.log('Total screens:', screens.length);
