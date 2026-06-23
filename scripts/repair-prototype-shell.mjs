#!/usr/bin/env node
/** Repair YDG_interactive_prototype.html after bad SCREENS slice — restore HTML shell. */
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const PROTO = path.join(path.dirname(path.dirname(fileURLToPath(import.meta.url))), 'YDG_interactive_prototype.html');
let c = fs.readFileSync(PROTO, 'utf8');

const badStart = c.indexOf('.proto-ph[');
if (badStart === -1) {
  console.log('No corruption marker — nothing to repair.');
  process.exit(0);
}

const cssEnd = c.lastIndexOf('.proto-wrap{display:flex;', badStart) + '.proto-wrap{display:flex;justify-content:center;padding:24px 16px 40px;}'.length;

const arrStart = c.indexOf('[', badStart);
let depth = 0;
let arrEnd = arrStart;
for (let i = arrStart; i < c.length; i++) {
  if (c[i] === '[') depth++;
  if (c[i] === ']') {
    depth--;
    if (depth === 0) {
      arrEnd = i + 1;
      break;
    }
  }
}

const screensJson = c.slice(arrStart, arrEnd);
JSON.parse(screensJson); // validate

const scriptStart = c.indexOf('const screenMap', arrEnd);
const script = c.slice(scriptStart);

const extraCss = `
  .proto-wrap{display:flex;justify-content:center;align-items:flex-start;padding:20px 16px 40px;min-height:calc(100vh - 56px);}
  .proto-wrap .phone{width:262px;flex-shrink:0;transform-origin:top center;}
  @media (max-width:300px){.proto-wrap .phone{transform:scale(calc((100vw - 32px) / 262));}}
  @media (min-width:768px){.proto-wrap{align-items:center;}}
  #screenRoot.screen,.proto-wrap .phone > .screen{padding:0;height:556px;overflow:hidden;}
  #screenRoot .screen-inner{display:flex;flex-direction:column;flex:1;min-height:0;width:100%;padding:14px 15px 0;}
  #screenRoot.ob-welcome .screen-inner,#screenRoot.ob4-sparks-live .screen-inner,#screenRoot.tutorial-screen .screen-inner,#screenRoot.tut-notes-live .screen-inner{padding:0;}
  #screenRoot .screen-inner[style*="padding:0"]{padding:0!important;}
  .screen-scroll-root{overflow-y:auto;-webkit-overflow-scrolling:touch;}
  #screenRoot.screen-scroll-root .screen-inner{flex:1 0 auto;min-height:100%;padding:14px 15px 0;}
  #toast{position:fixed;bottom:24px;left:50%;transform:translateX(-50%);background:#1d1916;border:1px solid #D6AE54;color:#e8ded3;padding:10px 16px;border-radius:10px;font-size:12px;opacity:0;pointer-events:none;transition:opacity .2s;z-index:999;}
  #toast.show{opacity:1;}
`;

const shell = `${extraCss}
</style>
</head>
<body>
<div class="proto-top">
  <div>
    <h1>Your Date Genie — Interactive Prototype</h1>
    <div class="proto-meta"><span id="screenLabel">Splash</span> · <span id="screenMeta"></span></div>
  </div>
  <div style="display:flex;gap:8px;align-items:center;flex-wrap:wrap;">
    <button type="button" class="proto-back" id="btnBack" disabled>← Back</button>
    <select class="proto-jump" id="screenJump" aria-label="Jump to screen"><option value="">Jump to…</option></select>
  </div>
</div>
<div class="proto-wrap">
  <div class="phone">
    <div id="screenRoot" class="screen"></div>
  </div>
</div>
<div id="toast" role="status" aria-live="polite"></div>
<script>
const SCREENS = ${screensJson};
`;

const fixed = c.slice(0, cssEnd) + shell + script;
fs.writeFileSync(PROTO, fixed);
console.log('Repaired prototype:', screensJson.length, 'chars JSON,', JSON.parse(screensJson).length, 'screens');
