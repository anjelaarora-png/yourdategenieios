#!/usr/bin/env node
/** Fix profile / business / Genie Profile text sizing disconnect. */
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const ROOT = path.dirname(path.dirname(fileURLToPath(import.meta.url)));
const PROTO = path.join(ROOT, 'YDG_interactive_prototype.html');
const DECL = path.join(ROOT, 'YDG_decluttered_mockup.html');

const TYPE_CSS = `
  .profile-name{font-size:15px;font-weight:500;line-height:1.25;color:var(--cream);}
  .row-title{font-size:12px;font-weight:500;line-height:1.3;color:var(--cream);}
  .field-hint,.radius-hint{font-size:10px;line-height:1.45;color:var(--dim);margin:-4px 0 8px;}`;

const PROFILE_SCREEN_IDS = ['you', 'you-business', 'settings', 'for-business', 'genie-profile'];

function injectCss(html, marker) {
  if (html.includes('.profile-name{')) return html;
  return html.replace(marker, TYPE_CSS + marker);
}

function fixProfileHtml(html, { name } = {}) {
  if (name) {
    html = html.replace(/<div class="cream">(John &amp; Maya|Your venue)<\/div>/g, '<div class="profile-name">$1</div>');
  }
  html = html.replace(/<span class="cream note">/g, '<span class="row-title">');
  html = html.replace(/<div class="cream note"/g, '<div class="row-title"');
  html = html.replace(/class="row-title" style="font-size:12px;"/g, 'class="row-title"');
  html = html.replace(/class="row-title" style="font-size:12px;"/g, 'class="row-title"');
  return html;
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

let proto = fs.readFileSync(PROTO, 'utf8');
proto = injectCss(proto, '  .profile-mode-seg{');
fs.writeFileSync(PROTO, proto);

patchScreens((screens) => {
  for (const id of PROFILE_SCREEN_IDS) {
    const s = screens.find((x) => x.id === id);
    if (!s) continue;
    s.html = fixProfileHtml(s.html, { name: id === 'you' || id === 'you-business' });
  }

  const scene = screens.find((s) => s.id === 'pref-scene');
  if (scene && !scene.html.includes('field-hint')) {
    scene.html = scene.html.replace(
      '<div class="radius-hint">Select your comfort zone',
      '<div class="radius-hint field-hint">Select your comfort zone'
    );
  }

  const splash = screens.find((s) => s.id === 'splash');
  if (splash) {
    splash.html = splash.html.replace(' style="margin-top:10px;font-size:12px;"', ' style="margin-top:10px;"');
  }
});

let decl = fs.readFileSync(DECL, 'utf8');
decl = injectCss(decl, '  .profile-mode-seg{');

// Frame 22 · Couple — swap inline sizes for tokens
decl = decl.replace(
  /<div class="cream" style="font-size:15px;">John &amp; Maya<\/div>/g,
  '<div class="profile-name">John &amp; Maya</div>'
);
decl = decl.replace(/<div class="cream" style="font-size:12\.5px;">/g, '<div class="row-title">');
decl = decl.replace(/<div class="cream" style="font-size:12px;">/g, '<div class="row-title">');
decl = decl.replace(/<span class="cream" style="font-size:12px;">/g, '<span class="row-title">');

// Frame 22b · Business
decl = decl.replace(
  '<div class="cream">Your venue</div>',
  '<div class="profile-name">Your venue</div>'
);
decl = decl.replace(
  /<div class="cream note">(Request featured placement|Promotion &amp; ad space)<\/div>/g,
  '<div class="row-title">$1</div>'
);

// Settings business frame + WEB for-business benefit titles
decl = decl.replace(/<div class="cream note" style="font-size:12px;">/g, '<div class="row-title">');

fs.writeFileSync(DECL, decl);

console.log('Patched profile type scale — 15px name · 12px row titles · 10px hints');
