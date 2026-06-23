#!/usr/bin/env node
/** Business post-login flow: onboarding → detailed apply → profile. */
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const ROOT = path.dirname(path.dirname(fileURLToPath(import.meta.url)));
const PROTO = path.join(ROOT, 'YDG_interactive_prototype.html');
const DECL = path.join(ROOT, 'YDG_decluttered_mockup.html');

const DOTS = (n, total = 3) =>
  Array.from({ length: total }, (_, i) => `<span class="${i < n ? 'on' : 'off'}"></span>`).join('');

const BIZ_OB1 =
  '<div class="screen-inner screen-scroll">' +
  '<div class="stat"><span data-go="auth-business">←</span><span>Partner · 1 of 3</span><span></span></div>' +
  `<div class="onboard-dots" style="margin:8px 0 14px;">${DOTS(1)}</div>` +
  '<div class="pill" style="margin-bottom:10px;">Why join our platform</div>' +
  '<div class="h-display" style="font-size:17px;margin:0 0 10px;line-height:1.35;">Couples are already planning tonight</div>' +
  '<div class="muted note" style="margin-bottom:14px;line-height:1.5;">Your Date Genie builds full date nights — not random banner ads. When a couple searches your city and vibe, your spot can appear as a featured stop in their itinerary.</div>' +
  '<div class="card" style="padding:10px 12px;margin-bottom:12px;"><div class="row-title">The problem we solve</div><div class="dim note" style="margin-top:4px;line-height:1.45;">Empty weeknights &amp; slow discovery — couples want great local spots but don\'t know you exist mid-plan.</div></div>' +
  '<div class="cta" data-go="biz-ob2">Next</div>' +
  '<div class="link center" style="margin-top:10px;font-size:11px;" data-go="biz-apply">Skip intro → apply now</div>' +
  '</div>';

const BIZ_OB2 =
  '<div class="screen-inner screen-scroll">' +
  '<div class="stat"><span data-go="biz-ob1">←</span><span>Partner · 2 of 3</span><span></span></div>' +
  `<div class="onboard-dots" style="margin:8px 0 14px;">${DOTS(2)}</div>` +
  '<div class="pill" style="margin-bottom:10px;">Intent-rich traffic</div>' +
  '<div class="h-display" style="font-size:17px;margin:0 0 10px;line-height:1.35;">Reach couples mid-plan, not mid-scroll</div>' +
  '<div class="muted note" style="margin-bottom:14px;line-height:1.5;">These are couples who picked cozy cocktails, live music, adventure, or a quiet dinner — and are ready to book.</div>' +
  '<div class="card" style="padding:10px 12px;margin-bottom:12px;"><div class="row-title">Every category welcome</div><div class="dim note" style="margin-top:4px;">Jazz bar, brewery, spa, mini-golf, boutique hotel, gift shop — not cuisine-specific.</div></div>' +
  '<div class="cta" data-go="biz-ob3">Next</div>' +
  '<div class="link center" style="margin-top:10px;font-size:11px;" data-go="biz-apply">Skip intro → apply now</div>' +
  '</div>';

const BIZ_OB3 =
  '<div class="screen-inner screen-scroll">' +
  '<div class="stat"><span data-go="biz-ob2">←</span><span>Partner · 3 of 3</span><span></span></div>' +
  `<div class="onboard-dots" style="margin:8px 0 14px;">${DOTS(3)}</div>` +
  '<div class="pill" style="margin-bottom:10px;">Launch partner advantage</div>' +
  '<div class="h-display" style="font-size:17px;margin:0 0 10px;line-height:1.35;">Shape date-night ads in your city</div>' +
  '<div class="muted note" style="margin-bottom:14px;line-height:1.5;">Early venues get featured placement pricing before we open self-serve ads. Join now to advertise to couples planning tonight.</div>' +
  '<div class="card" style="padding:10px 12px;margin-bottom:12px;border-color:rgba(214,174,84,.35);"><div class="row-title">Next step</div><div class="dim note" style="margin-top:4px;">Short application → stored in Firebase <code>business_listings</code>. We email placement options within a few days.</div></div>' +
  '<div class="cta" data-go="biz-apply">Start application</div>' +
  '</div>';

const BIZ_APPLY =
  '<div class="screen-inner screen-scroll">' +
  '<div class="stat"><span data-go="biz-ob3">←</span><span>Advertising application</span><span></span></div>' +
  '<div class="muted note" style="margin:8px 0 12px;line-height:1.45;">Detailed submission for featured placement. All categories welcome.</div>' +
  '<div class="label" style="margin-bottom:6px;">Business</div>' +
  '<div class="input-field" style="margin-bottom:8px;"><span class="placeholder">Business name *</span></div>' +
  '<div style="display:flex;gap:8px;margin-bottom:8px;"><div class="input-field" style="flex:1;margin-bottom:0;"><span class="placeholder">Contact name *</span></div>' +
  '<div class="input-field" style="flex:1;margin-bottom:0;"><span class="placeholder">Role (optional)</span></div></div>' +
  '<div class="input-field" style="margin-bottom:8px;"><span class="placeholder">Work email *</span></div>' +
  '<div class="input-field" style="margin-bottom:8px;"><span class="placeholder">Phone *</span></div>' +
  '<div class="input-field" style="margin-bottom:12px;"><span class="placeholder">Website (optional)</span></div>' +
  '<div class="label" style="margin-bottom:6px;">Location</div>' +
  '<div class="input-field" style="margin-bottom:8px;"><span class="placeholder">Street address *</span></div>' +
  '<div style="display:flex;gap:8px;margin-bottom:12px;"><div class="input-field" style="flex:1;margin-bottom:0;"><span class="placeholder">City *</span></div>' +
  '<div class="input-field" style="flex:0.6;margin-bottom:0;"><span class="placeholder">State *</span></div></div>' +
  '<div class="label" style="margin-bottom:6px;">Venue category *</div>' +
  '<div class="input-field" style="margin-bottom:8px;background:var(--surface2);"><span class="placeholder" style="color:var(--text);">Restaurant ▾</span></div>' +
  '<div class="dim note" style="margin:-4px 0 8px;font-size:10px;line-height:1.35;">Bar &amp; lounge · Café · Wine bar · Activity · Entertainment · Spa · Hotel · Retail · Event venue · Other</div>' +
  '<div class="input-field" style="margin-bottom:12px;"><span class="placeholder">If Other — describe category *</span></div>' +
  '<div class="label" style="margin-bottom:6px;">About your venue *</div>' +
  '<div class="input-field" style="min-height:52px;margin-bottom:8px;align-items:flex-start;padding-top:10px;"><span class="placeholder">What makes your spot great for date night?</span></div>' +
  '<div class="label" style="margin-bottom:6px;">Couple experience *</div>' +
  '<div class="input-field" style="min-height:52px;margin-bottom:12px;align-items:flex-start;padding-top:10px;"><span class="placeholder">What should couples expect when they visit?</span></div>' +
  '<div class="label" style="margin-bottom:6px;">Promotion interest *</div>' +
  '<div class="input-field" style="margin-bottom:8px;background:var(--surface2);"><span class="placeholder" style="color:var(--text);">Featured stop in AI itineraries ▾</span></div>' +
  '<div class="input-field" style="margin-bottom:12px;"><span class="placeholder">If Other — describe promotion *</span></div>' +
  '<div class="label" style="margin-bottom:6px;">Monthly budget *</div>' +
  '<div class="input-field" style="margin-bottom:12px;background:var(--surface2);"><span class="placeholder" style="color:var(--text);">Not sure yet — send options ▾</span></div>' +
  '<div class="input-field" style="min-height:44px;margin-bottom:12px;align-items:flex-start;padding-top:10px;"><span class="placeholder">Additional notes (optional)</span></div>' +
  '<div class="cta" data-go="you-business">Submit application</div>' +
  '<div class="dim note center" style="margin-top:10px;font-size:10px;line-height:1.4;">Saved to Firebase <code>business_listings</code> · yourdategenie.com/for-business/apply</div>' +
  '</div>';

const FOR_BUSINESS_HTML =
  '<div class="screen-inner screen-scroll">' +
  '<div class="stat"><span data-go="auth-business">←</span><span>For Business</span><span></span></div>' +
  '<div class="pill" style="margin:10px 0;">Venue partners · launching 2026</div>' +
  '<div class="h-display" style="font-size:18px;margin:0 0 8px;line-height:1.3;">Put your date spot in front of <span style="color:var(--gold)">couples ready to go</span></div>' +
  '<div class="muted note" style="margin-bottom:12px;line-height:1.45;">Featured placement for every date-night category — restaurants, bars, experiences, retail &amp; more.</div>' +
  '<div class="label" style="margin-bottom:6px;">Why list with us</div>' +
  '<div class="card" style="padding:9px 11px;margin-bottom:8px;"><div class="row-title">Inside AI itineraries</div><div class="dim note" style="margin-top:3px;">When Genie matches your city, vibe &amp; category — jazz bar, brewery, spa, mini-golf — you can show up.</div></div>' +
  '<div class="card" style="padding:9px 11px;margin-bottom:8px;"><div class="row-title">Intent-rich traffic</div><div class="dim note" style="margin-top:3px;">Not banner ads — users already planning tonight.</div></div>' +
  '<div class="card" style="padding:9px 11px;margin-bottom:12px;"><div class="row-title">Launch partner rates</div><div class="dim note" style="margin-top:3px;">Early venues get featured pricing before self-serve ads.</div></div>' +
  '<div class="cta" style="margin-bottom:8px;" data-go="auth-business">Partner sign in</div>' +
  '<div class="cta" style="background:transparent;border:1px solid rgba(214,174,84,.4);color:var(--gold-soft);margin-bottom:12px;" data-go="biz-ob1">Apply for advertising</div>' +
  '<div class="dim note center" style="font-size:10px;line-height:1.4;">Portal: onboarding → detailed application → Firebase tracking</div>' +
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
  for (const [id, label, html] of [
    ['biz-ob1', 'Partner onboarding · 1', BIZ_OB1],
    ['biz-ob2', 'Partner onboarding · 2', BIZ_OB2],
    ['biz-ob3', 'Partner onboarding · 3', BIZ_OB3],
    ['biz-apply', 'Partner application', BIZ_APPLY],
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
  if (fb) fb.html = FOR_BUSINESS_HTML;

  for (const id of ['auth-business', 'auth-business-signup']) {
    const s = screens.find((x) => x.id === id);
    if (s) {
      s.html = s.html.replace(/data-go="you-business"/g, 'data-go="biz-ob1"');
      if (id === 'auth-business') {
        s.html = s.html.replace(
          'data-go="for-business">New partner? Apply for placement →',
          'data-go="biz-ob1">New partner? Apply for advertising →'
        );
      }
    }
  }
});

let proto = fs.readFileSync(PROTO, 'utf8');

if (!proto.includes("'Business partner flow'")) {
  proto = proto.replace(
    "'Auth · Business': ['auth-business', 'auth-business-signup'],",
    "'Auth · Business': ['auth-business', 'auth-business-signup'],\n  'Business partner flow': ['biz-ob1', 'biz-ob2', 'biz-ob3', 'biz-apply', 'you-business'],"
  );
}

for (const [needle, insert] of [
  [
    "else if (id === 'for-business') meta = 'For Business · featured placement apply';",
    "else if (id === 'biz-ob1') meta = 'Business onboarding · couples planning tonight';\n  else if (id === 'biz-ob2') meta = 'Business onboarding · intent-rich traffic';\n  else if (id === 'biz-ob3') meta = 'Business onboarding · launch partner rates';\n  else if (id === 'biz-apply') meta = 'Business application · Firebase business_listings';\n  else if (id === 'for-business') meta = 'For Business · featured placement apply';",
  ],
]) {
  if (!proto.includes("id === 'biz-ob1'")) {
    proto = proto.replace(needle, insert);
  }
}

fs.writeFileSync(PROTO, proto);

let decl = fs.readFileSync(DECL, 'utf8');

const bizObFrames = `
    <div class="frame">
      <div class="cap"><b>00d-biz · Onboarding</b> · Why advertise to couples (3 slides)</div>
      <div class="phone"><div class="screen" style="padding:14px 15px 13px;">
        <div style="display:flex;flex-direction:column;height:100%;">
          <div class="muted note" style="margin-bottom:8px;">Partner · 1 of 3</div>
          <div class="h-display" style="font-size:16px;margin:0 0 8px;">Couples are already planning tonight</div>
          <div class="dim note" style="margin-bottom:12px;line-height:1.45;">Full date nights — your spot as a featured stop in AI itineraries.</div>
          <div class="card" style="padding:9px 11px;margin-bottom:auto;"><div class="row-title">Problem we solve</div><div class="dim note" style="margin-top:3px;">Slow discovery — couples mid-plan don\'t know your venue exists.</div></div>
          <div class="cta" style="margin-top:12px;">Next → onboarding 2–3 → application</div>
        </div>
      </div></div>
    </div>
    <div class="frame">
      <div class="cap"><b>00e-biz · Application</b> · Category dropdown + Other · Firebase <code>business_listings</code></div>
      <div class="phone"><div class="screen" style="padding:14px 15px 13px;">
        <div style="display:flex;flex-direction:column;height:100%;overflow-y:auto;">
          <div class="h-display" style="font-size:15px;margin:0 0 8px;">Advertising application</div>
          <div class="input-field" style="margin-bottom:6px;"><span class="placeholder">Business name *</span></div>
          <div class="input-field" style="margin-bottom:6px;"><span class="placeholder">Venue category ▾ Restaurant</span></div>
          <div class="input-field" style="margin-bottom:6px;"><span class="placeholder">If Other — describe *</span></div>
          <div class="input-field" style="margin-bottom:6px;min-height:40px;"><span class="placeholder">About your venue *</span></div>
          <div class="input-field" style="margin-bottom:6px;"><span class="placeholder">Promotion interest ▾</span></div>
          <div class="cta" style="margin-top:8px;">Submit → business profile</div>
        </div>
      </div></div>
    </div>`;

if (!decl.includes('00d-biz · Onboarding')) {
  decl = decl.replace(
    '    <div class="frame"><div class="cap"><b>00d · Verify email</b>',
    bizObFrames + '\n    <div class="frame"><div class="cap"><b>00d · Verify email</b>'
  );
}

if (decl.includes('00c-biz · Auth') && !decl.includes('→ biz onboarding')) {
  decl = decl.replace(
    '<div class="cta" style="margin-bottom:8px;">Sign In</div>',
    '<div class="cta" style="margin-bottom:8px;">Sign In → onboarding → apply</div>'
  );
}

fs.writeFileSync(DECL, decl);

console.log('Business portal flow wired — biz-ob1..3 → biz-apply → you-business');
