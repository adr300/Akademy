// Gemeinsame Hilfen für die Tests: Blöcke aus index.html lesen und ohne Browser auswerten.
const fs = require('fs'), path = require('path'), vm = require('vm');
const WURZEL = path.join(__dirname, '..');
const INDEX = path.join(WURZEL, 'index.html');
const html = () => fs.readFileSync(INDEX, 'utf8').replace(/\r\n/g, '\n');

/* Script-Inhalt zwischen zwei HTML-Kommentar-Markern, z. B. BLUU-TF1 */
function block(name) {
  const h = html();
  const a = h.indexOf('<!-- ' + name + ':START -->'), b = h.indexOf('<!-- ' + name + ':ENDE -->');
  if (a < 0 || b < 0) throw new Error('Block ' + name + ' fehlt');
  return h.slice(a, b).replace(/^[\s\S]*?<script>/, '').replace(/<\/script>[\s\S]*$/, '');
}

/* Datenblöcke in einem leeren «window» ausführen */
function daten() {
  const ctx = { window: {} }; ctx.window.window = ctx.window;
  vm.runInNewContext(block('BLUU-TF1'), ctx);
  /* 1.1.1: Lernskript-Daten und Adrians Sets liegen in anderen Blöcken; hier nur die TF1-Module */
  return { lernskripte: ctx.window.BLUU_LERNSKRIPTE, lernkarten: ctx.window.BLUU_LERNKARTEN };
}

/* BLUU_MODULE-Literal aus dem Plattform-Block (Klammern zählen, dann auswerten) */
function moduleListe() {
  const h = html();
  const start = h.indexOf('window.BLUU_MODULE = window.BLUU_MODULE || [');
  if (start < 0) throw new Error('BLUU_MODULE fehlt');
  let i = h.indexOf('[', start), tiefe = 0, inStr = null;
  for (let j = i; j < h.length; j++) {
    const c = h[j];
    if (inStr) { if (c === '\\') { j++; continue; } if (c === inStr) inStr = null; continue; }
    if (c === "'" || c === '"') { inStr = c; continue; }
    if (c === '/' && h[j + 1] === '*') { j = h.indexOf('*/', j) + 1; continue; }
    if (c === '[') tiefe++;
    if (c === ']') { tiefe--; if (tiefe === 0) return vm.runInNewContext('(' + h.slice(i, j + 1) + ')', {}); }
  }
  throw new Error('BLUU_MODULE nicht abschließbar');
}

/* Merge-Funktion des Sync-Blocks */
function merge() {
  const h = html();
  const a = h.indexOf('/* BLUU-LS-MERGE:START */'), b = h.indexOf('/* BLUU-LS-MERGE:ENDE */');
  const ctx = { window: {} };
  vm.runInNewContext(h.slice(a, b), ctx);
  return ctx.window.bluuLsMerge;
}

/* Import-Dateien (content/import) lesen */
function importe() {
  const dir = path.join(WURZEL, 'content', 'import'); const out = [];
  fs.readdirSync(dir).forEach((d) => {
    const p = path.join(dir, d); if (!fs.statSync(p).isDirectory()) return;
    fs.readdirSync(p).filter((f) => f.endsWith('.html')).forEach((f) => {
      const t = fs.readFileSync(path.join(p, f), 'utf8');
      const m = t.match(/<!--ENERGYACADEMY_COURSE-->([\s\S]*?)<!--\/ENERGYACADEMY_COURSE-->/);
      out.push({ modul: d, datei: f, kurs: m ? JSON.parse(m[1]) : null });
    });
  });
  return out;
}

module.exports = { html, block, daten, moduleListe, merge, importe, WURZEL };
