// Run from the project root: node functions/scripts/sync-shell.js
//
// Copies web/index.html -> functions/app-shell.html. Run this any
// time web/index.html changes (branding, meta tags, PWA config,
// CanvasKit/Wasm loader script, etc.) and redeploy functions
// afterward, or the ssrRouter function will keep serving real users
// an outdated app shell.

const fs = require('fs');
const path = require('path');

const source = path.join(__dirname, '..', '..', 'web', 'index.html');
const dest = path.join(__dirname, '..', 'app-shell.html');

if (!fs.existsSync(source)) {
  console.error(`Could not find ${source}. Run this from the project root.`);
  process.exit(1);
}

fs.copyFileSync(source, dest);
console.log(`Copied ${source} -> ${dest}`);
