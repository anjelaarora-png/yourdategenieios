#!/usr/bin/env node
/** Individual | Business profile toggle + you-business hub for venue ad/promotion requests. */
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const ROOT = path.dirname(path.dirname(fileURLToPath(import.meta.url)));
const PROTO = path.join(ROOT, 'YDG_interactive_prototype.html');
const DECL = path.join(ROOT, 'YDG_decluttered_mockup.html');

const PROFILE_MODE_CSS = `
  .profile-mode-seg{display:flex;background:var(--surface2);border-radius:10px;padding:3px;margin-bottom:12px;gap:2px;}
  .profile-mode{flex:1;text-align:center;padding:8px 6px;font-size:12px;font-weight:500;border-radius:8px;color:var(--dim);cursor:default;font-family:'Inter',sans-serif;}
  .profile-mode.on{background:var(--surface);color:var(--gold);box-shadow:0 1px 4px rgba(0,0,0,.25);}
  .profile-mode[data-go]{cursor:pointer;}`;

const YOU_TOGGLE =
  '<div class="profile-mode-seg"><span class="profile-mode on">Individual</span><span class="profile-mode" data-go="you-business">Business</span></div>';

const TABBAR_YOU =
  '<div class="tabbar" data-tabs="1"><div class="tab" data-go="home" data-tab="home"><div class="ic">⌂</div>Home</div><div class="tab" data-go="dates" data-tab="dates"><div class="ic">♥</div>Dates</div><div class="tab" data-go="notes" data-tab="notes"><div class="ic">✨</div>Convo</div><div class="tab on" data-go="you" data-tab="you"><div class="ic">◔</div>You</div></div>';

const YOU_BUSINESS_HTML =
  '<div class="screen-inner screen-scroll"><div class="stat"><span class="nav-brand"><img src="mockup-assets/app-icon-transparent.png" class="app-icon sm" alt=""></span><span data-go="settings">⚙</span></div>' +
  '<div class="profile-mode-seg"><span class="profile-mode" data-go="you">Individual</span><span class="profile-mode on">Business</span></div>' +
  '<div style="display:flex;align-items:center;gap:10px;margin:0 0 14px;"><div class="avatar avatar-md" style="background:var(--surface2);display:flex;align-items:center;justify-content:center;font-size:22px;border:1px solid rgba(214,174,84,.25);">🏪</div><div><div class="cream">Your venue</div><div class="dim note">Restaurant · bar · experience</div></div></div>' +
  '<div class="pill" style="margin-bottom:12px;">Venue partner · apply to go live</div>' +
  '<div class="card" style="margin-bottom:8px;display:flex;justify-content:space-between;align-items:center;padding:10px 12px;" data-go="for-business"><div><div class="cream note">Request featured placement</div><div class="dim note">Show up inside AI date itineraries</div></div><span class="link">apply →</span></div>' +
  '<div class="card" style="margin-bottom:8px;display:flex;justify-content:space-between;align-items:center;padding:10px 12px;" data-go="for-business"><div><div class="cream note">Promotion &amp; ad space</div><div class="dim note">Launch partner rates · city &amp; category match</div></div><span class="link">request →</span></div>' +
  '<div class="card" style="margin-bottom:8px;padding:10px 12px;"><div class="cream note" style="font-size:12px;">How it works</div><div class="dim note" style="margin-top:4px;line-height:1.45;">Individuals plan dates with Genie — when your vibe and city match, your spot can appear as a featured stop.</div></div>' +
  '<div style="flex:1;min-height:0;"></div><div class="screen-foot">' +
  TABBAR_YOU +
  '</div></div>';

const AUTH_TOGGLE =
  '<div class="profile-mode-seg" style="margin-bottom:10px;"><span class="profile-mode on">Individual</span><span class="profile-mode" data-go="for-business">Business</span></div>';

const SPLASH_LINK =
  '<div class="link center" style="margin-top:10px;font-size:12px;" data-go="for-business">Own a date spot? List your venue →</div>';

function injectCss(html, marker, css) {
  if (html.includes('.profile-mode-seg')) return html;
  return html.replace(marker, css + marker);
}

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

// --- Prototype CSS ---
let proto = fs.readFileSync(PROTO, 'utf8');
proto = injectCss(proto, '  .seg-tab{font-size:13px', PROFILE_MODE_CSS);
fs.writeFileSync(PROTO, proto);

// --- Screens ---
patchScreens((screens) => {
  const you = screens.find((s) => s.id === 'you');
  if (you && !you.html.includes('profile-mode-seg')) {
    you.html = you.html.replace(
      '<div style="display:flex;align-items:center;gap:8px;margin:14px 0 16px;">',
      YOU_TOGGLE + '<div style="display:flex;align-items:center;gap:8px;margin:0 0 16px;">'
    );
  }

  if (!screens.some((s) => s.id === 'you-business')) {
    screens.push({ id: 'you-business', label: 'You · Business profile', html: YOU_BUSINESS_HTML });
  }

  for (const id of ['auth', 'auth-signup']) {
    const s = screens.find((x) => x.id === id);
    if (s && !s.html.includes('profile-mode-seg')) {
      s.html = s.html.replace(
        '<div class="seg" style="margin-bottom:8px;display:flex;gap:20px;justify-content:center;">',
        AUTH_TOGGLE + '<div class="seg" style="margin-bottom:8px;display:flex;gap:20px;justify-content:center;">'
      );
    }
  }

  const splash = screens.find((s) => s.id === 'splash');
  if (splash && !splash.html.includes('Own a date spot')) {
    splash.html = splash.html.replace(
      '<div class="cta" data-go="ob1">Get started</div></div></div>',
      '<div class="cta" data-go="ob1">Get started</div>' + SPLASH_LINK + '</div></div>'
    );
  }

  const fb = screens.find((s) => s.id === 'for-business');
  if (fb) {
    fb.html = fb.html.replace('data-go="settings"', 'data-go="you-business"');
    if (!fb.label.includes('Business')) fb.label = 'For Business · apply';
  }
});

// --- Prototype JS: jump menu + meta ---
proto = fs.readFileSync(PROTO, 'utf8');
proto = proto.replace(
  "'Main app': ['home', 'itinerary', 'dates', 'notes', 'sparks-gen', 'sparks-gen-2', 'sparks-gen-3', 'sparks-deck', 'love-notes', 'you', 'settings', 'for-business']",
  "'Main app': ['home', 'itinerary', 'dates', 'notes', 'sparks-gen', 'sparks-gen-2', 'sparks-gen-3', 'sparks-deck', 'love-notes', 'you', 'you-business', 'settings', 'for-business']"
);
if (!proto.includes("id === 'you-business'")) {
  proto = proto.replace(
    "else if (id === 'questionnaire' || id === 'questionnaire-fresh') meta = 'Date questionnaire · uses your Genie Profile';",
    "else if (id === 'questionnaire' || id === 'questionnaire-fresh') meta = 'Date questionnaire · uses your Genie Profile';\n  else if (id === 'you-business') meta = 'Business profile · venue partners';\n  else if (id === 'for-business') meta = 'For Business · featured placement apply';"
  );
}
fs.writeFileSync(PROTO, proto);

// --- Decluttered mockup ---
let decl = fs.readFileSync(DECL, 'utf8');
decl = injectCss(decl, '  .seg-tab{font-size:13px', PROFILE_MODE_CSS);

if (!decl.includes('22b · You · Business')) {
  decl = decl.replace(
    '<div class="stat"><span class="nav-brand"><img src="mockup-assets/app-icon-transparent.png" class="app-icon sm" alt="Your Date Genie app icon"></span><span class="ico">⚙</span></div>\n        <div style="display:flex;align-items:center;gap:8px;margin:16px 0 16px;">',
    '<div class="stat"><span class="nav-brand"><img src="mockup-assets/app-icon-transparent.png" class="app-icon sm" alt="Your Date Genie app icon"></span><span class="ico">⚙</span></div>\n        <div class="profile-mode-seg"><span class="profile-mode on">Individual</span><span class="profile-mode">Business</span></div>\n        <div style="display:flex;align-items:center;gap:8px;margin:0 0 16px;">'
  );

  const youBizFrame = `
    <div class="frame">
      <div class="cap"><b>22b · You · Business profile</b> · toggle + ad / promotion requests</div>
      <div class="phone"><div class="screen screen-scroll">
        <div class="stat"><span class="nav-brand"><img src="mockup-assets/app-icon-transparent.png" class="app-icon sm" alt=""></span><span class="ico">⚙</span></div>
        <div class="profile-mode-seg"><span class="profile-mode">Individual</span><span class="profile-mode on">Business</span></div>
        <div style="display:flex;align-items:center;gap:10px;margin:0 0 14px;"><div class="avatar avatar-md" style="background:var(--surface2);display:flex;align-items:center;justify-content:center;font-size:22px;border:1px solid rgba(214,174,84,.25);">🏪</div><div><div class="cream">Your venue</div><div class="dim note">Restaurant · bar · experience</div></div></div>
        <div class="pill" style="margin-bottom:12px;">Venue partner · apply to go live</div>
        <div class="card" style="margin-bottom:8px;display:flex;justify-content:space-between;align-items:center;padding:10px 12px;"><div><div class="cream note">Request featured placement</div><div class="dim note">Inside AI date itineraries</div></div><span class="link">apply →</span></div>
        <div class="card" style="margin-bottom:8px;display:flex;justify-content:space-between;align-items:center;padding:10px 12px;"><div><div class="cream note">Promotion &amp; ad space</div><div class="dim note">Launch partner rates</div></div><span class="link">request →</span></div>
        <div class="tabbar"><div class="tab"><div class="ic">⌂</div>Home</div><div class="tab"><div class="ic">♥</div>Dates</div><div class="tab"><div class="ic">✨</div>Convo</div><div class="tab on"><div class="ic">◔</div>You</div></div>
      </div></div>
    </div>`;

  decl = decl.replace(
    '      <div class="cap"><b>22 · You</b> · profile + every preference editable</div>',
    '      <div class="cap"><b>22 · You</b> · Individual profile · toggle to Business</div>'
  );
  decl = decl.replace('    </div>\n\n  </div>\n\n  <!-- ============ ACT 5 : MONETIZE ============ -->', `${youBizFrame}\n    </div>\n\n  </div>\n\n  <!-- ============ ACT 5 : MONETIZE ============ -->`);
}

if (!decl.includes('Individual</span><span class="profile-mode">Business</span></div>\n          <div class="input-field"')) {
  decl = decl.replace(
    '<div class="h-display center" style="font-size:19px;margin:0 0 10px;">Welcome Back</div>\n          <div style="display:flex;gap:20px;justify-content:center;margin-bottom:12px;">',
    '<div class="h-display center" style="font-size:19px;margin:0 0 10px;">Welcome Back</div>\n          <div class="profile-mode-seg"><span class="profile-mode on">Individual</span><span class="profile-mode">Business</span></div>\n          <div style="display:flex;gap:20px;justify-content:center;margin-bottom:12px;">'
  );
}

if (!decl.includes('Own a date spot')) {
  decl = decl.replace(
    '<div class="muted" style="font-size:12px;margin-top:8px;">Date nights, <span style="color:var(--gold)">planned</span> for you.</div></div></div></div></div>',
    '<div class="muted" style="font-size:12px;margin-top:8px;">Date nights, <span style="color:var(--gold)">planned</span> for you.</div><div class="link center" style="margin-top:12px;font-size:11px;">Own a date spot? List your venue →</div></div></div></div></div>'
  );
}

fs.writeFileSync(DECL, decl);

console.log('Patched business profile toggle — You, Auth, Splash, you-business screen');
