#!/usr/bin/env node
/** OB4 — stock thumbs, clear feature copy (what + where), staggered timeline UX. */
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const ROOT = path.dirname(path.dirname(fileURLToPath(import.meta.url)));
const PROTO = path.join(ROOT, 'YDG_interactive_prototype.html');
const DECL = path.join(ROOT, 'YDG_decluttered_mockup.html');

const IMG = {
  convo: 'mockup-assets/onboarding/ob4-convo-talking.jpg',
  notes: 'mockup-assets/onboarding/ob4-love-note.jpg',
  gift: 'mockup-assets/onboarding/ob4-gift.jpg',
};

const row = (delay, img, alt, title, what, where) =>
  `<div class="ob4-extra-row ob-stop ob-anim ${delay}"><img class="ob4-extra-thumb" src="${img}" alt="${alt}" loading="lazy"><div class="ob4-extra-copy"><div class="t">${title}</div><div class="w">${what}</div><div class="where">${where}</div></div></div>`;

const TIMELINE = `<div class="ob-itin ob-anim-card ob-fade-up d1 ob4-extras-card"><div class="ob-itin-hd"><div><div class="cream note" style="font-size:12px;">What's included</div><div class="dim note">3 extras · built into every date plan</div></div><span style="color:var(--gold);">✦</span></div><div class="ob-itin-timeline ob4-extra-list">${row('d1', IMG.convo, 'Two people talking together', '✨ Convo starters', 'Swipe questions matched to your relationship', 'Convo tab')}${row('d2', IMG.notes, 'Handwritten love note', '💌 Love notes', 'AI-drafted sweet notes you send before the date', 'On your itinerary')}${row('d3', IMG.gift, 'Wrapped gift', '🎁 Gift finder', 'Gift ideas from their profile &amp; budget', 'Add from any stop')}</div></div>`;

const OB4 = `<div class="screen-inner ob-live ob3-fit ob4-fit"><div class="stat"><span data-go="ob3">←</span><span>4 of 5</span><span></span></div><div class="onboard-dots"><span class="off"></span><span class="off"></span><span class="off"></span><span class="on"></span><span class="off"></span></div><div class="ob-label ob-fade-up">Plus on every date</div><div class="h-display ob-fade-up d1" style="font-size:17px;margin-bottom:4px;">Three extras on <span style="color:var(--gold)">every plan</span></div><div class="muted note center ob-fade-up d1" style="font-size:9px;margin-bottom:8px;line-height:1.4;">Not separate apps — talk, text &amp; gifts are part of the date Genie builds</div>${TIMELINE}<div class="muted note center ob-fade-up d2" style="margin-top:auto;font-size:9px;">Premium · unlimited plans &amp; all extras</div><div class="screen-foot"><div class="cta ob-fade-up d3" data-go="ob5">Next</div></div></div>`;

const OB4_INNER = OB4.replace(/^<div class="screen-inner ob-live ob3-fit ob4-fit">/, '').replace(/<\/div>$/, '');
const OB4_DECL = `<div class="frame"><div class="cap"><b>OB4 · Date extras</b> · what + where · 4 of 5</div><div class="phone"><div class="screen ob-live ob3-fit ob4-fit">${OB4_INNER.replace('<span data-go="ob3">←</span>', '<span>←</span>').replace(' data-go="ob5"', '')}</div></div></div>`;

const OB4_CSS = `  /* OB4 — stock thumbs, feature clarity, timeline UX */
  .screen-inner.ob4-fit,.screen.ob4-fit{display:flex;flex-direction:column;min-height:100%;padding-bottom:4px;}
  .ob4-fit .ob4-extras-card{flex:1;margin:0;display:flex;flex-direction:column;min-height:0;}
  .ob4-fit .ob4-extra-list{flex:1;display:flex;flex-direction:column;justify-content:space-evenly;padding:6px 0 4px;}
  .ob4-fit .ob4-extra-row{display:flex;gap:10px;align-items:center;padding:8px 8px 8px 10px;border-bottom:none;border-radius:11px;animation:obSlideIn .45s ease-out both,ob4RowPulse 5s ease-in-out infinite;}
  .ob4-fit .ob4-extra-row.d1{animation-delay:.35s,1.4s;}
  .ob4-fit .ob4-extra-row.d2{animation-delay:.55s,2.1s;}
  .ob4-fit .ob4-extra-row.d3{animation-delay:.75s,2.8s;}
  .ob4-fit .ob4-extra-thumb{width:52px;height:52px;border-radius:11px;object-fit:cover;border:1px solid var(--line);flex-shrink:0;box-shadow:0 4px 12px rgba(0,0,0,.25);}
  .ob4-fit .ob4-extra-copy{min-width:0;flex:1;}
  .ob4-fit .ob4-extra-row .t{font-size:10px;color:var(--cream);font-weight:600;line-height:1.2;}
  .ob4-fit .ob4-extra-row .w{font-size:9px;color:var(--muted);line-height:1.35;margin-top:3px;}
  .ob4-fit .ob4-extra-row .where{display:inline-block;margin-top:4px;font-size:7px;font-weight:600;letter-spacing:.04em;text-transform:uppercase;color:var(--gold-soft);background:rgba(214,174,84,.12);border:1px solid rgba(214,174,84,.22);padding:2px 7px;border-radius:999px;}
  .ob4-fit .ob4-extra-row.ob-stop.ob-anim::before{top:50%;transform:translateY(-50%);animation:obPopIn .4s cubic-bezier(.34,1.4,.64,1) both;}
  .ob4-fit .ob4-extra-row.d1.ob-stop.ob-anim::before{animation-delay:.35s;}
  .ob4-fit .ob4-extra-row.d2.ob-stop.ob-anim::before{animation-delay:.55s;}
  .ob4-fit .ob4-extra-row.d3.ob-stop.ob-anim::before{animation-delay:.75s;}
  @keyframes ob4RowPulse{0%,18%,100%{background:transparent;box-shadow:none;}8%,14%{background:rgba(214,174,84,.07);box-shadow:inset 0 0 0 1px rgba(214,174,84,.16);}}`;

function injectOb4Css(html) {
  const start = html.indexOf('  /* OB4 —');
  if (start !== -1) {
    let end = html.length;
    for (const needle of ['  .ob-onboard-extras', '  @keyframes ob4Stage', '  /* OB4 — filled', '  .ob4-sparks-live']) {
      const i = html.indexOf(needle, start + 12);
      if (i !== -1) end = Math.min(end, i);
    }
    if (end === html.length) {
      const i = html.indexOf('\n  @keyframes ob4RowPulse', start);
      if (i !== -1) {
        end = html.indexOf('\n  ', i + 5);
        if (end === -1) end = html.length;
      }
    }
    return html.slice(0, start) + OB4_CSS + '\n' + html.slice(end);
  }
  return html.replace(
    '.ob3-actions .pill{font-size:8px;padding:3px 7px;}',
    `.ob3-actions .pill{font-size:8px;padding:3px 7px;}\n${OB4_CSS}`
  );
}

function patchScreens(filePath, setHtml) {
  let c = fs.readFileSync(filePath, 'utf8');
  c = injectOb4Css(c);
  const marker = 'const SCREENS = [';
  const start = c.indexOf(marker);
  if (start === -1) {
    fs.writeFileSync(filePath, c);
    return;
  }
  const arrStart = start + marker.length - 1;
  let depth = 0;
  let i = arrStart;
  for (; i < c.length; i++) {
    if (c[i] === '[') depth++;
    if (c[i] === ']') {
      depth--;
      if (depth === 0) {
        i++;
        break;
      }
    }
  }
  const screens = JSON.parse(c.slice(arrStart, i));
  setHtml(screens);
  fs.writeFileSync(filePath, c.slice(0, arrStart) + JSON.stringify(screens) + c.slice(i));
}

patchScreens(PROTO, (screens) => {
  const ob4 = screens.find((s) => s.id === 'ob4');
  if (ob4) {
    ob4.html = OB4;
    ob4.label = 'Plus on every date';
  }
});

let decl = fs.readFileSync(DECL, 'utf8');
decl = injectOb4Css(decl);
decl = decl.replace(
  /<div class="frame"><div class="cap"><b>OB4 ·[\s\S]*?<\/div><\/div><\/div>\s*\n\s*<div class="frame"><div class="cap"><b>OB5/,
  `${OB4_DECL}\n    <div class="frame"><div class="cap"><b>OB5`
);
fs.writeFileSync(DECL, decl);

console.log('Patched OB4 — clarity copy + timeline row animations');
