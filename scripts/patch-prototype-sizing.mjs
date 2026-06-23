#!/usr/bin/env node
/**
 * Fix interactive prototype sizing: one padding layer, promote layout classes to #screenRoot.
 */
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const PROTO = path.join(path.dirname(path.dirname(fileURLToPath(import.meta.url))), 'YDG_interactive_prototype.html');
let html = fs.readFileSync(PROTO, 'utf8');

const OLD_PROTO_CSS = `  .proto-wrap{display:flex;justify-content:center;padding:24px 16px 40px;}
  .screen-scroll-root{overflow-y:auto;-webkit-overflow-scrolling:touch;}
  .screen-inner{display:flex;flex-direction:column;flex:1;min-height:0;width:100%;}`;

const NEW_PROTO_CSS = `  .proto-wrap{display:flex;justify-content:center;align-items:flex-start;padding:20px 16px 40px;min-height:calc(100vh - 56px);}
  .proto-wrap .phone{width:262px;flex-shrink:0;transform-origin:top center;}
  @media (max-width:300px){.proto-wrap .phone{transform:scale(calc((100vw - 32px) / 262));}}
  @media (min-width:768px){.proto-wrap{align-items:center;}}
  /* Prototype canvas: bleed outer shell, padded inner (matches decluttered frames) */
  #screenRoot.screen,.proto-wrap .phone > .screen{padding:0;height:556px;overflow:hidden;}
  #screenRoot .screen-inner{display:flex;flex-direction:column;flex:1;min-height:0;width:100%;padding:14px 15px 0;}
  #screenRoot.ob-welcome .screen-inner,
  #screenRoot.ob4-sparks-live .screen-inner,
  #screenRoot.tutorial-screen .screen-inner,
  #screenRoot.tut-notes-live .screen-inner{padding:0;}
  #screenRoot .screen-inner[style*="padding:0"]{padding:0!important;}
  .screen-scroll-root{overflow-y:auto;-webkit-overflow-scrolling:touch;}
  #screenRoot.screen-scroll-root .screen-inner{flex:1 0 auto;min-height:100%;padding:14px 15px 0;}`;

if (!html.includes(OLD_PROTO_CSS)) {
  if (html.includes('#screenRoot.screen,.proto-wrap .phone > .screen{padding:0')) {
    console.log('Prototype sizing patch already applied.');
  } else {
    console.error('Could not find proto CSS block to patch.');
    process.exit(1);
  }
} else {
  html = html.replace(OLD_PROTO_CSS, NEW_PROTO_CSS);
}

const OLD_RENDER = `  const inner = root.querySelector('.screen-inner');
  let cls = 'screen';
  if (inner && inner.classList.contains('ob-live')) cls += ' ob-live';
  if (inner && inner.classList.contains('ob-welcome')) cls += ' ob-welcome';
  if (inner && inner.classList.contains('screen-scroll')) cls += ' screen-scroll-root';
  root.className = cls;`;

const NEW_RENDER = `  const inner = root.querySelector('.screen-inner');
  const rootClasses = ['ob-live', 'ob-welcome', 'screen-scroll', 'ob3-fit', 'ob4-sparks-live', 'tut-notes-live', 'tutorial-screen', 'splash-screen'];
  let cls = 'screen';
  if (inner) {
    rootClasses.forEach(c => {
      if (inner.classList.contains(c)) cls += c === 'screen-scroll' ? ' screen-scroll-root' : ' ' + c;
    });
  }
  root.className = cls;`;

if (html.includes(OLD_RENDER)) {
  html = html.replace(OLD_RENDER, NEW_RENDER);
} else if (!html.includes("const rootClasses = ['ob-live'")) {
  console.error('Could not find render() class block to patch.');
  process.exit(1);
}

fs.writeFileSync(PROTO, html);
console.log('Patched prototype sizing + render class promotion.');
