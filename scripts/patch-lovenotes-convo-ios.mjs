#!/usr/bin/env node
/**
 * Align love notes + convo starters mockups with iOS LoveNoteGeneratorView
 * and ConversationStartersView / SparksDeckView.
 */
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const ROOT = path.dirname(path.dirname(fileURLToPath(import.meta.url)));
const DECL = path.join(ROOT, 'YDG_decluttered_mockup.html');
const PROTO = path.join(ROOT, 'YDG_interactive_prototype.html');

const FEATURE_CSS = `
  /* Love notes + convo starters — iOS parity */
  .cs-kicker{font-size:10px;font-weight:600;letter-spacing:2px;color:var(--gold);margin-bottom:6px;}
  .step-bar{display:flex;gap:5px;height:4px;margin:10px 0 6px;}
  .step-bar span{flex:1;height:4px;border-radius:2px;background:rgba(154,113,96,.35);}
  .step-bar span.on{background:var(--gold);flex:1.35;}
  .step-meta{font-size:10px;font-weight:600;letter-spacing:2px;color:var(--dim);margin-bottom:10px;}
  .new-session{display:flex;gap:12px;align-items:center;padding:14px;border-radius:16px;border:1px solid rgba(214,174,84,.38);background:rgba(89,22,32,.92);margin:14px 0 18px;}
  .new-session .plus{width:42px;height:42px;border-radius:50%;border:1.5px solid rgba(214,174,84,.5);display:flex;align-items:center;justify-content:center;color:var(--gold);font-size:20px;flex-shrink:0;}
  .stage-grid{display:grid;grid-template-columns:1fr 1fr;gap:8px;margin-bottom:12px;}
  .stage-card{padding:11px;border-radius:14px;border:1px solid rgba(214,174,84,.28);background:var(--surface);text-align:left;}
  .stage-card.on{background:linear-gradient(180deg,var(--gold-hi),var(--gold-mid));border-color:transparent;}
  .stage-card.on .cream,.stage-card.on .dim{color:#3a0a0d;}
  .vibe-row{display:flex;gap:10px;align-items:flex-start;padding:12px;border-radius:14px;border:1px solid rgba(214,174,84,.28);background:var(--surface);margin-bottom:8px;}
  .vibe-row.on{background:linear-gradient(180deg,var(--gold-hi),var(--gold-mid));border-color:transparent;}
  .vibe-row.on .cream,.vibe-row.on .dim{color:#3a0a0d;}
  .vibe-ico{width:24px;text-align:center;color:var(--gold);flex-shrink:0;font-size:14px;}
  .vibe-row.on .vibe-ico{color:#3a0a0d;}
  .spark-card{border:1px solid rgba(214,174,84,.4);border-radius:18px;padding:18px 16px;background:var(--surface2);text-align:center;margin:16px 0 10px;box-shadow:0 8px 20px rgba(0,0,0,.28);}
  .spark-card .count{font-size:9px;letter-spacing:2px;color:var(--dim);margin-bottom:10px;}
  .spark-card .tag{font-size:9px;font-weight:600;letter-spacing:2.2px;color:var(--gold);margin-bottom:12px;}
  .spark-dots{display:flex;gap:5px;justify-content:center;margin:8px 0 4px;}
  .spark-dots span{width:6px;height:6px;border-radius:3px;background:rgba(214,174,84,.22);}
  .spark-dots span.on{width:18px;background:var(--gold);}
  .spark-hint{font-size:9px;letter-spacing:1.5px;color:rgba(214,174,84,.35);margin:6px 0 10px;}
  .deck-actions{display:flex;gap:8px;margin-top:12px;}
  .deck-actions .ghost,.deck-actions .cta{flex:1;font-size:11px;min-height:34px;}
  .love-title{font-family:'Playfair Display',serif;font-style:italic;color:var(--gold);font-size:26px;text-align:center;line-height:1.15;margin:6px 0 8px;}
  .love-section{font-family:'Playfair Display',serif;font-style:italic;color:var(--gold);font-size:17px;margin:12px 0 6px;}
  .love-letter{background:linear-gradient(165deg,#f4e7d2 0%,#ead9c4 100%);border-radius:12px;padding:14px;color:#3d2c2c;min-height:88px;border:1px solid rgba(214,174,84,.25);}
  .love-letter-hdr{display:flex;justify-content:space-between;align-items:center;margin-bottom:8px;padding-bottom:6px;border-bottom:1px solid rgba(89,22,32,.12);}
  .love-letter-hdr .sign{font-family:'Playfair Display',serif;font-style:italic;color:#591620;font-size:15px;}
  .saved-note-scroll{display:flex;gap:8px;overflow-x:auto;padding-bottom:4px;margin-bottom:4px;}
  .saved-note-mini{min-width:110px;max-width:120px;padding:10px;border-radius:10px;background:rgba(244,231,210,.12);border:1px solid rgba(214,174,84,.22);}
  .writer-box{min-height:72px;padding:10px 12px;border-radius:14px;border:1px solid rgba(214,174,84,.35);background:rgba(89,22,32,.75);}
  .input-field{padding:10px 12px;border-radius:12px;border:1px solid rgba(214,174,84,.28);background:rgba(89,22,32,.75);}
  .session-card{padding:12px;border-radius:14px;border:1px solid rgba(214,174,84,.28);background:rgba(89,22,32,.88);margin-bottom:8px;text-align:left;}
  .fav-card{padding:12px;border-radius:14px;border:1px solid rgba(214,174,84,.28);background:rgba(89,22,32,.88);margin-bottom:8px;}
`;

function injectCss(html) {
  const marker = '  /* Love notes + convo starters — iOS parity */';
  if (html.includes(marker)) return html;
  const anchor = '  /* —— Design system v2: sleek buttons + typography —— */';
  return html.replace(anchor, FEATURE_CSS + anchor);
}

function parseScreens(content) {
  const c = content;
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
  return { screens: JSON.parse(c.slice(start, i)), arrayStart: start, arrayEnd: i };
}

function writeScreens(fileContent, arrayStart, arrayEnd, screens) {
  return fileContent.slice(0, arrayStart) + JSON.stringify(screens) + fileContent.slice(arrayEnd);
}

const tabNotes = `<div class="tabbar" data-tabs="1"><div class="tab" data-go="home" data-tab="home"><div class="ic">⌂</div>Home</div><div class="tab" data-go="dates" data-tab="dates"><div class="ic">♥</div>Dates</div><div class="tab on" data-go="notes" data-tab="notes"><div class="ic">✨</div>Convo</div><div class="tab" data-go="you" data-tab="you"><div class="ic">◔</div>You</div></div>`;

const SCREENS = {
  notes: `<div class="screen-inner screen-scroll"><div class="stat"><span class="nav-brand"><img src="mockup-assets/app-icon-transparent.png" class="app-icon sm" alt=""></span><span data-go="notifications">🔔</span></div><div class="cs-kicker">CONVO STARTERS</div><div class="h-display" style="font-size:18px;line-height:1.25;margin-bottom:4px;">Find the tip made for <span class="serif" style="color:var(--gold);font-style:italic;">you</span></div><div class="muted note" style="margin-bottom:4px;">2 taps. Personalised instantly.</div><div class="new-session" data-go="sparks-gen"><div class="plus">+</div><div style="flex:1;"><div class="cream" style="font-size:13px;font-weight:600;">New session</div><div class="dim note" style="margin-top:2px;">Pick your vibe, get your questions.</div></div><span style="color:var(--gold);">›</span></div><div class="love-section" style="margin-top:4px;">Your favorites</div><div class="fav-card"><div class="cream note" style="line-height:1.45;font-size:11px;">What's something you're secretly proud of that you've never said out loud?</div><div class="dim note" style="margin-top:6px;line-height:1.35;">And what would need to be true for you to say it tonight?</div><div style="display:flex;justify-content:space-between;align-items:center;margin-top:8px;"><span class="dim note">Deep · Bold</span><span style="color:var(--gold);font-size:12px;">📋 ♥</span></div></div><div class="love-section">Past sessions</div><div class="session-card" data-go="sparks-deck"><div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:4px;"><span class="cream note" style="font-size:11px;font-weight:600;">● Growing Bond · Deep &amp; curious</span><span class="pill" style="font-size:8px;padding:2px 6px;">1 saved</span></div><div class="dim note">Today · 10 questions</div><div class="muted note" style="margin-top:6px;line-height:1.4;">If you could live an entirely different life for one year…</div><span class="link" style="font-size:10px;margin-top:6px;display:inline-block;">Tap to view all →</span></div><div style="flex:1;min-height:0;"></div><div class="screen-foot">${tabNotes}</div></div>`,

  'sparks-gen': `<div class="screen-inner screen-scroll"><div class="stat"><span data-go="notes">←</span><span>Convo starters</span><span data-go="notes">Done</span></div><div class="cs-kicker">CONVO STARTERS</div><div class="h-display" style="font-size:17px;margin-bottom:2px;">Find the tip made for <span class="serif" style="color:var(--gold);font-style:italic;">you</span></div><div class="muted note" style="margin-bottom:8px;">2 taps. Personalised instantly.</div><div class="step-bar"><span class="on"></span><span></span><span></span></div><div class="step-meta">STEP 1 OF 3</div><div class="step-meta" style="color:var(--muted);margin-bottom:6px;">WHERE ARE YOU?</div><div class="muted note" style="margin-bottom:10px;">Choose what best describes your connection</div><div class="stage-grid"><div class="stage-card"><div class="dim note" style="margin-bottom:4px;">○</div><div class="cream note" style="font-weight:600;">New Flame</div><div class="dim note" style="margin-top:3px;line-height:1.3;">Early days, getting to know each other</div></div><div class="stage-card on"><div class="dim note" style="margin-bottom:4px;">✓</div><div class="cream note" style="font-weight:600;">Growing Bond</div><div class="dim note" style="margin-top:3px;line-height:1.3;">A few months in, things are blooming</div></div><div class="stage-card"><div class="dim note" style="margin-bottom:4px;">○</div><div class="cream note" style="font-weight:600;">Deeply Rooted</div><div class="dim note" style="margin-top:3px;line-height:1.3;">A year or more, real depth</div></div><div class="stage-card"><div class="dim note" style="margin-bottom:4px;">○</div><div class="cream note" style="font-weight:600;">Life Partners</div><div class="dim note" style="margin-top:3px;line-height:1.3;">In it for the long haul</div></div></div><div style="flex:1;"></div><div class="screen-foot"><div class="cta" data-go="sparks-gen-2">Continue →</div></div></div>`,

  'sparks-gen-2': `<div class="screen-inner screen-scroll"><div class="stat"><span data-go="sparks-gen">←</span><span>Convo starters</span><span data-go="notes">Done</span></div><div class="step-bar"><span class="on"></span><span class="on"></span><span></span></div><div class="step-meta">STEP 2 OF 3</div><div class="step-meta" style="color:var(--muted);margin-bottom:6px;">WHAT DO YOU NEED?</div><div class="muted note" style="margin-bottom:10px;">We'll match your starters to the mood.</div><div class="vibe-row"><div class="vibe-ico">😄</div><div><div class="cream note" style="font-weight:600;">Playful &amp; light</div><div class="dim note">Fun, teasing, laughing all night</div></div><span style="margin-left:auto;color:var(--gold);">○</span></div><div class="vibe-row"><div class="vibe-ico">💕</div><div><div class="cream note" style="font-weight:600;">Romantic &amp; slow</div><div class="dim note">Soft, intimate, savoring every moment</div></div><span style="margin-left:auto;color:var(--gold);">○</span></div><div class="vibe-row on"><div class="vibe-ico">💭</div><div><div class="cream note" style="font-weight:600;">Deep &amp; curious</div><div class="dim note">Real talk, going beneath the surface</div></div><span style="margin-left:auto;color:#3a0a0d;">✓</span></div><div class="vibe-row"><div class="vibe-ico">✨</div><div><div class="cream note" style="font-weight:600;">Adventurous &amp; bold</div><div class="dim note">Daring questions, no filter tonight</div></div><span style="margin-left:auto;color:var(--gold);">○</span></div><div style="flex:1;"></div><div class="screen-foot"><div class="cta" data-go="sparks-gen-3">Continue →</div></div></div>`,

  'sparks-gen-3': `<div class="screen-inner screen-scroll"><div class="stat"><span data-go="sparks-gen-2">←</span><span>Convo starters</span><span data-go="notes">Done</span></div><div class="step-bar"><span class="on"></span><span class="on"></span><span class="on"></span></div><div class="step-meta">STEP 3 OF 3</div><div class="step-meta" style="color:var(--muted);margin-bottom:6px;">OPTIONAL</div><div class="muted note" style="margin-bottom:10px;">Tap any topics that feel right — or skip ahead.</div><div class="chips" style="gap:6px;margin-bottom:12px;"><span class="chip">📖 Childhood</span><span class="chip">✈️ Travel</span><span class="chip on">🎯 Ambitions</span><span class="chip">💫 Desires</span><span class="chip">👨‍👩‍👧 Family</span><span class="chip">🫂 Fears</span></div><div style="flex:1;"></div><div class="screen-foot"><div class="cta" data-go="sparks-deck">Reveal my sparks ✦</div></div></div>`,

  'sparks-deck': `<div class="screen-inner" style="text-align:center;"><div class="stat"><span data-go="notes">←</span><span>Convo starters</span><span data-go="notes">Done</span></div><div class="love-title" style="font-size:28px;margin-top:4px;">Convo starters</div><div class="cream note" style="font-size:12px;margin-bottom:4px;">Growing Bond · Deep &amp; curious</div><div class="spark-dots"><span></span><span></span><span class="on"></span><span></span><span></span><span></span><span></span><span></span><span></span><span></span></div><div class="spark-card"><div class="count">3 OF 10</div><div class="tag">• DEEP · BOLD · AMBITIONS</div><div class="cream" style="font-size:13px;line-height:1.5;">If you could live an entirely different life for one year — different career, city, everything — what would you choose, and why haven't you?</div></div><div class="spark-hint">← swipe to explore →</div><div class="ghost" style="margin:0 0 8px;">🔖 Save to favorites</div><div class="deck-actions"><div class="ghost" data-go="sparks-gen">← Back</div><div class="cta">Next spark →</div></div></div>`,

  'love-notes': `<div class="screen-inner screen-scroll"><div class="stat"><span data-go="you">←</span><span>Love Notes</span><span data-go="you">Done</span></div><div class="love-title">Write a Love Note</div><div class="muted note center" style="margin-bottom:10px;line-height:1.45;">Write your feelings, pick a style to rewrite, then save as a love letter to send.</div><div class="love-section" style="font-size:15px;">Saved Love Notes</div><div class="muted note" style="margin-bottom:6px;">Tap to view or save to photos again.</div><div class="saved-note-scroll"><div class="saved-note-mini"><div class="cream note" style="font-size:9px;line-height:1.35;">Can't wait for Saturday — gallery, pasta, and you.</div><div class="dim note" style="margin-top:4px;">— John</div></div><div class="saved-note-mini"><div class="cream note" style="font-size:9px;line-height:1.35;">You make ordinary Tuesdays feel like a date.</div><div class="dim note" style="margin-top:4px;">— John</div></div></div><div class="love-section">Need inspiration?</div><div class="chips" style="gap:5px;margin-bottom:10px;"><span class="chip on">What do you love most?</span><span class="chip">A moment you'll never forget</span><span class="chip">Why they make you smile</span></div><div class="love-section">Your words</div><div class="writer-box" style="margin-bottom:10px;"><span class="dim note">Tell them what makes your heart skip…</span></div><div class="love-section">Rewrite style</div><div class="chips" style="gap:5px;margin-bottom:10px;"><span class="chip on">💕 Romantic</span><span class="chip">✨ Poetic</span><span class="chip">😄 Funny</span><span class="chip">🍬 Sweet</span><span class="chip">🎉 Playful</span></div><div class="cta" style="margin-bottom:10px;">Rewrite</div><div class="love-section">Sign as</div><div class="input-field" style="margin-bottom:10px;"><span class="cream note">John</span></div><div class="love-section">Love letter preview</div><div class="love-letter"><div class="love-letter-hdr"><span style="color:#591620;">♥</span><span class="sign">— John</span></div><span class="note" style="color:#6e4a3a;line-height:1.5;">Your words will appear here…</span></div><div class="love-section">Save or send</div><div class="cta" style="margin-bottom:8px;">Save love note</div><div class="cta" style="margin-bottom:8px;">Save as photo</div><div class="cta" style="margin-bottom:14px;">Send to partner</div></div>`,

  'love-note': null, // alias to love-notes
};

// Decluttered frame replacements (inner screen content only)
const FRAME_20 = `<div class="stat"><span class="nav-brand"><img src="mockup-assets/app-icon-transparent.png" class="app-icon sm" alt=""></span><span class="ico">🔔</span></div><div class="cs-kicker">CONVO STARTERS</div><div class="h-display" style="font-size:18px;line-height:1.25;margin-bottom:4px;">Find the tip made for <span class="serif" style="color:var(--gold);font-style:italic;">you</span></div><div class="muted note" style="margin-bottom:4px;">2 taps. Personalised instantly.</div><div class="new-session"><div class="plus">+</div><div style="flex:1;"><div class="cream" style="font-size:13px;font-weight:600;">New session</div><div class="dim note" style="margin-top:2px;">Pick your vibe, get your questions.</div></div><span style="color:var(--gold);">›</span></div><div class="love-section" style="margin-top:4px;">Your favorites</div><div class="fav-card"><div class="cream note" style="line-height:1.45;font-size:11px;">What's something you're secretly proud of that you've never said out loud?</div><div class="dim note" style="margin-top:6px;line-height:1.35;">And what would need to be true for you to say it tonight?</div><div style="display:flex;justify-content:space-between;align-items:center;margin-top:8px;"><span class="dim note">Deep · Bold</span><span style="color:var(--gold);font-size:12px;">📋 ♥</span></div></div><div class="love-section">Past sessions</div><div class="session-card"><div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:4px;"><span class="cream note" style="font-size:11px;font-weight:600;">● Growing Bond · Deep &amp; curious</span><span class="pill" style="font-size:8px;padding:2px 6px;">1 saved</span></div><div class="dim note">Today · 10 questions</div><span class="link" style="font-size:10px;margin-top:6px;display:inline-block;">Tap to view all →</span></div><div class="tabbar"><div class="tab"><div class="ic">⌂</div>Home</div><div class="tab"><div class="ic">♥</div>Dates</div><div class="tab on"><div class="ic">✨</div>Convo</div><div class="tab"><div class="ic">◔</div>You</div></div>`;

const FRAME_21 = `<div class="stat"><span>Done</span><span>Love Notes</span><span></span></div><div class="love-title">Write a Love Note</div><div class="muted note center" style="margin-bottom:8px;line-height:1.45;">Write your feelings, pick a style to rewrite, then save as a love letter to send.</div><div class="love-section" style="font-size:15px;">Need inspiration?</div><div class="chips" style="gap:5px;margin-bottom:8px;"><span class="chip on">What do you love most?</span><span class="chip">A moment you'll never forget</span></div><div class="love-section">Your words</div><div class="writer-box" style="margin-bottom:8px;"><span class="dim note">Tell them what makes your heart skip…</span></div><div class="love-section">Rewrite style</div><div class="chips" style="gap:5px;margin-bottom:8px;"><span class="chip on">💕 Romantic</span><span class="chip">✨ Poetic</span><span class="chip">😄 Funny</span><span class="chip">🍬 Sweet</span><span class="chip">🎉 Playful</span></div><div class="cta" style="margin-bottom:8px;">Rewrite</div><div class="love-section">Sign as</div><div class="input-field" style="margin-bottom:8px;"><span class="cream note">John</span></div><div class="love-section">Love letter preview</div><div class="love-letter" style="margin-bottom:8px;"><div class="love-letter-hdr"><span style="color:#591620;">♥</span><span class="sign">— John</span></div><span class="note" style="color:#6e4a3a;">Your words will appear here…</span></div><div class="cta" style="margin-bottom:8px;">Save love note</div><div class="cta" style="margin-bottom:8px;">Save as photo</div><div class="cta" style="margin-bottom:13px;">Send to partner</div>`;

const FRAME_F5 = `<div class="stat"><span>←</span><span>Convo starters</span><span>Done</span></div><div class="love-title" style="font-size:28px;margin-top:4px;">Convo starters</div><div class="cream note" style="font-size:12px;margin-bottom:4px;">Growing Bond · Deep &amp; curious</div><div class="spark-dots"><span></span><span></span><span class="on"></span><span></span><span></span></div><div class="spark-card"><div class="count">3 OF 10</div><div class="tag">• DEEP · BOLD · AMBITIONS</div><div class="cream" style="font-size:13px;line-height:1.5;">If you could live an entirely different life for one year — different career, city, everything — what would you choose?</div></div><div class="spark-hint">← swipe to explore →</div><div class="ghost" style="margin-bottom:8px;">🔖 Save to favorites</div><div class="deck-actions"><div class="ghost">← Back</div><div class="cta">Next spark →</div></div>`;

const FRAME_F14 = FRAME_21;

const FRAME_F15 = `<div class="stat"><span>←</span><span>Convo starters</span><span>Done</span></div><div class="step-bar"><span class="on"></span><span></span><span></span></div><div class="step-meta">STEP 1 OF 3 · WHERE ARE YOU?</div><div class="muted note" style="margin-bottom:8px;">Choose what best describes your connection</div><div class="stage-grid"><div class="stage-card"><div class="cream note" style="font-weight:600;">New Flame</div><div class="dim note" style="margin-top:3px;">Early days</div></div><div class="stage-card on"><div class="cream note" style="font-weight:600;">Growing Bond</div><div class="dim note" style="margin-top:3px;">Things are blooming</div></div><div class="stage-card"><div class="cream note" style="font-weight:600;">Deeply Rooted</div><div class="dim note" style="margin-top:3px;">Real depth</div></div><div class="stage-card"><div class="cream note" style="font-weight:600;">Life Partners</div><div class="dim note" style="margin-top:3px;">Long haul</div></div></div><div class="cta" style="margin-top:auto;margin-bottom:13px;">Continue →</div>`;

function replaceFrameInner(declHtml, capPattern, newInner) {
  const capRe = new RegExp(`(<div class="cap"><b>${capPattern}<\\/b>[^<]*<\\/div><div class="phone"><div class="screen[^"]*">)[\\s\\S]*?(<\\/div><\\/div><\\/div>)`);
  return declHtml.replace(capRe, `$1${newInner}$2`);
}

// Patch decluttered
let decl = fs.readFileSync(DECL, 'utf8');
decl = injectCss(decl);
decl = replaceFrameInner(decl, '20 · Convo starters', FRAME_20);
decl = replaceFrameInner(decl, '21 · Love notes', FRAME_21);
decl = replaceFrameInner(decl, 'F5 · Convo starter deck', FRAME_F5);
decl = replaceFrameInner(decl, 'F14 · Love note writer', FRAME_F14);
decl = replaceFrameInner(decl, 'F15 · New convo deck', FRAME_F15);
// Update IA copy
decl = decl.replace(
  '2 taps. Pick your depth — public-safe or deep.',
  '2 taps. Personalised instantly.'
);
decl = decl.replace(
  '<div><b>Convo starters</b> → Convo tab (screen 20)</div>',
  '<div><b>Convo starters</b> → Convo tab · hub + 3-step session + swipe deck (20, F15, F5)</div>'
);
decl = decl.replace(
  '<div><b>Love Notes</b> → Convo tab (21)</div>',
  '<div><b>Love Notes</b> → You tab · full writer with rewrite styles + letter preview (21, F14)</div>'
);
fs.writeFileSync(DECL, decl);

// Patch prototype (parse + write same in-memory string so offsets stay valid)
let proto = fs.readFileSync(PROTO, 'utf8');
proto = injectCss(proto);
const { screens, arrayStart, arrayEnd } = parseScreens(proto);
const byId = Object.fromEntries(screens.map((s) => [s.id, s]));

for (const [id, html] of Object.entries(SCREENS)) {
  if (id === 'love-note' || html == null) continue;
  if (byId[id]) {
    byId[id].html = html;
  } else {
    const label =
      id === 'sparks-gen-2'
        ? 'Convo · Step 2'
        : id === 'sparks-gen-3'
          ? 'Convo · Step 3'
          : id.replace(/-/g, ' ');
    screens.push({ id, label, html });
    byId[id] = screens[screens.length - 1];
  }
}
if (byId['love-note'] && byId['love-notes']) {
  byId['love-note'].html = byId['love-notes'].html;
}

proto = writeScreens(proto, arrayStart, arrayEnd, screens);
if (proto.includes("'Main app': ['home'")) {
  proto = proto.replace(
    /'Main app': \[[^\]]+\]/,
    "'Main app': ['home', 'itinerary', 'dates', 'notes', 'sparks-gen', 'sparks-gen-2', 'sparks-gen-3', 'sparks-deck', 'love-notes', 'you', 'settings', 'for-business']"
  );
}

fs.writeFileSync(PROTO, proto);
console.log('Patched decluttered + prototype for iOS-parity love notes & convo starters.');
