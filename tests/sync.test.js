// Zusammenführung des Lernskript-Stands (Browser ↔ Server): deterministisch, Häkchen monoton, Eingaben gehen nicht verloren.
const test = require('node:test');
const assert = require('node:assert/strict');
const H = require('./hilfen');

const merge = H.merge();
const gleich = (a, b, msg) => assert.equal(JSON.stringify(a), JSON.stringify(b), msg);
const kap = (kann, e, t, extra) => Object.assign({ kann, e: e || {}, gemerkt: false, gemeldet: false, t }, extra || {});

test('nur Browser-Stand: normalisiert, nichts verloren', () => {
  const l = { kapitel: 'B', fs: 1, t: 10, k: { A: kap([true, false, false], { denk: 'x' }, 10) } };
  const m = merge(l, null);
  assert.equal(m.kapitel, 'B'); assert.equal(m.fs, 1); gleich(m.k.A.kann, [true, false, false]); assert.equal(m.k.A.e.denk, 'x');
  assert.equal(JSON.stringify(merge(l, null)), JSON.stringify(merge(l, null)), 'deterministisch');
});

test('Häkchen sind monoton: ein älterer Browser-Stand nimmt dem Server keine Fertigstellung weg', () => {
  const server = { kapitel: 'C', t: 200, k: { A: kap([true, true, true], {}, 200, { gemeldet: true }) } };
  const lokalAlt = { kapitel: 'A', t: 100, k: { A: kap([true, false, false], {}, 100) } };
  const m = merge(lokalAlt, server);
  gleich(m.k.A.kann, [true, true, true]); assert.equal(m.k.A.gemeldet, true); assert.equal(m.kapitel, 'C', 'jüngerer Stand bestimmt das Kapitel');
});

test('zuletzt besuchtes Kapitel: der jüngere Gesamtstand gewinnt – egal welche Seite', () => {
  assert.equal(merge({ kapitel: 'D', t: 300, k: {} }, { kapitel: 'B', t: 200, k: {} }).kapitel, 'D');
  assert.equal(merge({ kapitel: 'D', t: 100, k: {} }, { kapitel: 'B', t: 200, k: {} }).kapitel, 'B');
});

test('Eingaben: nicht-leer schlägt leer, bei Konflikt das Kapitel mit dem jüngeren Zeitstempel', () => {
  const l = { t: 100, k: { A: kap([false], { denk: 'lokal', selbst: '' }, 100) } };
  const s = { t: 200, k: { A: kap([false], { denk: 'server', selbst: 'nur hier' }, 200) } };
  const m = merge(l, s);
  assert.equal(m.k.A.e.denk, 'server'); assert.equal(m.k.A.e.selbst, 'nur hier');
  const m2 = merge({ t: 300, k: { A: kap([false], { denk: 'lokal' }, 300) } }, s);
  assert.equal(m2.k.A.e.denk, 'lokal'); assert.equal(m2.k.A.e.selbst, 'nur hier');
});

test('Kapitel, die nur auf einer Seite existieren, bleiben erhalten', () => {
  const m = merge({ t: 1, k: { A: kap([true], {}, 1) } }, { t: 2, k: { B: kap([true], { und: 'x' }, 2) } });
  gleich(Object.keys(m.k).sort(), ['A', 'B']); assert.equal(m.k.B.e.und, 'x');
});

test('wiederholtes Zusammenführen ändert nichts mehr (idempotent)', () => {
  const l = { kapitel: 'A', t: 5, k: { A: kap([true, false], { denk: 'a' }, 5) } }, s = { kapitel: 'B', t: 9, k: { A: kap([false, true], {}, 9), B: kap([false], {}, 9) } };
  const m = merge(l, s);
  /* Objekte stammen aus einem vm-Kontext (andere Prototypen) – deshalb über JSON vergleichen */
  assert.equal(JSON.stringify(merge(m, s)), JSON.stringify(m)); assert.equal(JSON.stringify(merge(m, m)), JSON.stringify(m));
});
