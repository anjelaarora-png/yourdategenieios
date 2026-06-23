#!/usr/bin/env node
/** Separate business login on auth — auth-business + auth-business-signup. */
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const ROOT = path.dirname(path.dirname(fileURLToPath(import.meta.url)));
const PROTO = path.join(ROOT, 'YDG_interactive_prototype.html');
const DECL = path.join(ROOT, 'YDG_decluttered_mockup.html');

const MODE_COUPLE =
  '<div class="profile-mode-seg" style="margin-bottom:10px;"><span class="profile-mode on">Individual</span><span class="profile-mode" data-go="auth-business">Business</span></div>';

const MODE_COUPLE_SIGNUP =
  '<div class="profile-mode-seg" style="margin-bottom:10px;"><span class="profile-mode on">Individual</span><span class="profile-mode" data-go="auth-business-signup">Business</span></div>';

const MODE_BUSINESS =
  '<div class="profile-mode-seg" style="margin-bottom:10px;"><span class="profile-mode" data-go="auth">Individual</span><span class="profile-mode on">Business</span></div>';

const AUTH_BUSINESS_HTML =
  '<div class="screen-inner screen-scroll">' +
  '<div class="icon-center" style="margin-top:4px;"><div class="avatar avatar-md" style="background:var(--surface2);display:flex;align-items:center;justify-content:center;font-size:22px;margin:0 auto 10px;border:1px solid rgba(214,174,84,.25);">🏪</div></div>' +
  '<div class="h-display center" style="font-size:19px;margin:0 0 6px;">Venue partner sign in</div>' +
  '<div class="muted note center" style="margin-bottom:12px;line-height:1.45;">Manage featured placement &amp; ad requests</div>' +
  MODE_BUSINESS +
  '<div class="seg" style="margin-bottom:8px;display:flex;gap:20px;justify-content:center;">' +
  '<span class="seg-tab on">Sign In</span><span class="seg-tab off" data-go="auth-business-signup">Create Account</span></div>' +
  '<div class="input-field"><span class="placeholder">Business email</span></div>' +
  '<div class="input-field"><span class="placeholder">Password</span></div>' +
  '<div class="cta" style="margin-bottom:10px;" data-go="you-business">Sign In</div>' +
  '<div class="link center" style="font-size:11px;" data-go="for-business">New partner? Apply for placement →</div>' +
  '<div class="link center" style="margin-top:8px;font-size:11px;" data-go="auth">← Individual app sign in</div>' +
  '</div>';

const AUTH_BUSINESS_SIGNUP_HTML =
  '<div class="screen-inner screen-scroll">' +
  '<div class="icon-center" style="margin-top:4px;"><div class="avatar avatar-md" style="background:var(--surface2);display:flex;align-items:center;justify-content:center;font-size:22px;margin:0 auto 10px;border:1px solid rgba(214,174,84,.25);">🏪</div></div>' +
  '<div class="h-display center" style="font-size:19px;margin:0 0 6px;">Create business account</div>' +
  '<div class="muted note center" style="margin-bottom:12px;line-height:1.45;">For venue owners &amp; date-night partners</div>' +
  MODE_BUSINESS.replace('data-go="auth">Individual', 'data-go="auth-signup">Individual') +
  '<div class="seg" style="margin-bottom:8px;display:flex;gap:20px;justify-content:center;">' +
  '<span class="seg-tab off" data-go="auth-business">Sign In</span><span class="seg-tab on">Create Account</span></div>' +
  '<div class="input-field"><span class="placeholder">Business name</span></div>' +
  '<div style="display:flex;gap:8px;margin-bottom:8px;"><div class="input-field" style="flex:1;margin-bottom:0;"><span class="placeholder">Your name</span></div>' +
  '<div class="input-field" style="flex:1;margin-bottom:0;"><span class="placeholder">City</span></div></div>' +
  '<div class="input-field"><span class="placeholder">Work email</span></div>' +
  '<div class="input-field"><span class="placeholder">Password</span></div>' +
  '<div class="input-field"><span class="placeholder">Confirm password</span></div>' +
  '<div class="cta" style="margin-bottom:10px;" data-go="you-business">Create business account</div>' +
  '<div class="link center" style="font-size:11px;" data-go="auth-business">Already have an account? Sign in</div>' +
  '</div>';

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
  const auth = screens.find((s) => s.id === 'auth');
  if (auth) {
    auth.html = auth.html.replace(
      /<div class="profile-mode-seg"[^>]*>[\s\S]*?<\/div>/,
      MODE_COUPLE
    );
  }
  const signup = screens.find((s) => s.id === 'auth-signup');
  if (signup) {
    signup.html = signup.html.replace(
      /<div class="profile-mode-seg"[^>]*>[\s\S]*?<\/div>/,
      MODE_COUPLE_SIGNUP
    );
  }

  for (const [id, label, html] of [
    ['auth-business', 'Auth · Business sign in', AUTH_BUSINESS_HTML],
    ['auth-business-signup', 'Auth · Business create account', AUTH_BUSINESS_SIGNUP_HTML],
  ]) {
    const existing = screens.find((s) => s.id === id);
    if (existing) {
      existing.label = label;
      existing.html = html;
    } else {
      screens.push({ id, label, html });
    }
  }

  const fb = screens.find((s) => s.id === 'for-business');
  if (fb && fb.html.includes('data-go="you-business"')) {
    fb.html = fb.html.replace('data-go="you-business"', 'data-go="auth-business"');
  }

  const splash = screens.find((s) => s.id === 'splash');
  if (splash && splash.html.includes('data-go="for-business"')) {
    splash.html = splash.html.replace(
      'data-go="for-business"',
      'data-go="auth-business"'
    );
  }
});

let proto = fs.readFileSync(PROTO, 'utf8');
proto = proto.replace(
  "'Auth': ['auth', 'auth-signup', 'verify', 'profile-photo'],",
  "'Auth · Individual': ['auth', 'auth-signup', 'verify', 'profile-photo'],\n  'Auth · Business': ['auth-business', 'auth-business-signup'],"
);
if (!proto.includes("id === 'auth-business'")) {
  proto = proto.replace(
    "else if (id === 'for-business') meta = 'For Business · featured placement apply';",
    "else if (id === 'auth-business') meta = 'Business login · venue partners';\n  else if (id === 'auth-business-signup') meta = 'Business login · create account';\n  else if (id === 'for-business') meta = 'For Business · featured placement apply';"
  );
}
fs.writeFileSync(PROTO, proto);

let decl = fs.readFileSync(DECL, 'utf8');
decl = decl.replace(
  '<div class="profile-mode-seg"><span class="profile-mode on">Individual</span><span class="profile-mode">Business</span></div>\n          <div style="display:flex;gap:20px;justify-content:center;margin-bottom:12px;">',
  '<div class="profile-mode-seg"><span class="profile-mode on">Individual</span><span class="profile-mode">Business → separate login</span></div>\n          <div style="display:flex;gap:20px;justify-content:center;margin-bottom:12px;">'
);

if (!decl.includes('00c-biz · Auth')) {
  const bizFrame = `
    <div class="frame">
      <div class="cap"><b>00c-biz · Auth</b> · Business sign in (separate from couple)</div>
      <div class="phone"><div class="screen" style="padding:14px 15px 13px;">
        <div style="display:flex;flex-direction:column;height:100%;">
          <div class="icon-center" style="margin-bottom:8px;"><div style="width:40px;height:40px;border-radius:50%;background:var(--surface2);display:flex;align-items:center;justify-content:center;font-size:20px;margin:0 auto;border:1px solid rgba(214,174,84,.25);">🏪</div></div>
          <div class="h-display center" style="font-size:19px;margin:0 0 6px;">Venue partner sign in</div>
          <div class="muted note center" style="margin-bottom:12px;">Manage ads &amp; featured placement</div>
          <div class="profile-mode-seg"><span class="profile-mode">Individual</span><span class="profile-mode on">Business</span></div>
          <div style="display:flex;gap:20px;justify-content:center;margin-bottom:12px;"><span class="seg-tab on">Sign In</span><span class="seg-tab off">Create Account</span></div>
          <div class="input-field" style="margin-bottom:8px;"><span class="placeholder">Business email</span></div>
          <div class="input-field" style="margin-bottom:10px;"><span class="placeholder">Password</span></div>
          <div class="cta" style="margin-bottom:8px;">Sign In</div>
          <div class="link center" style="font-size:11px;">New partner? Apply for placement →</div>
        </div>
      </div></div>
    </div>`;
  decl = decl.replace(
    '    <div class="frame"><div class="cap"><b>00d · Verify email</b>',
    bizFrame + '\n    <div class="frame"><div class="cap"><b>00d · Verify email</b>'
  );
}

if (decl.includes('data-go="for-business"') && decl.includes('Own a date spot')) {
  decl = decl.replace(
    '<div class="link center" style="margin-top:12px;font-size:11px;">Own a date spot? List your venue →</div>',
    '<div class="link center" style="margin-top:12px;font-size:11px;">Own a date spot? Business sign in →</div>'
  );
}

fs.writeFileSync(DECL, decl);

console.log('Added separate business login — auth-business + auth-business-signup');
