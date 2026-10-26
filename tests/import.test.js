// Import-Dateien (content/import): Form wie confirmImport() sie erwartet, Fragen in den Grenzen der Renderer.
const test = require('node:test');
const assert = require('node:assert/strict');
const H = require('./hilfen');

const DATEIEN = H.importe();
const TYPEN = new Set(['multiple_choice', 'true_false', 'match', 'sort']);
const opts = (q) => ['opt_a', 'opt_b', 'opt_c', 'opt_d'].map((k) => q[k]).filter(Boolean);
const matches = (q) => ['match_a', 'match_b', 'match_c', 'match_d'].map((k) => q[k]).filter((x) => x != null);

test('jede Datei trägt genau einen Kurs mit Titel «<Modul> …», Slides und Fragen', () => {
  assert.ok(DATEIEN.length >= 49, 'zu wenige Import-Dateien: ' + DATEIEN.length);
  const titel = new Set();
  DATEIEN.forEach(({ modul, datei, kurs }) => {
    assert.ok(kurs, datei + ': kein Kurs-JSON');
    assert.ok(kurs.title.startsWith(modul + ' '), datei + ': Titel beginnt nicht mit ' + modul);
    assert.ok(!titel.has(kurs.title), 'Kurstitel doppelt: ' + kurs.title); titel.add(kurs.title);
    assert.ok(Array.isArray(kurs.slides) && kurs.slides.length, datei + ': keine Slides');
    kurs.slides.forEach((s) => assert.ok(s.title && typeof s.content === 'string', datei + ': Slide ohne Titel/Inhalt'));
  });
});

test('Fragen passen zu den Renderern (Optionen ≤ 4, Lösung im Bereich, Typen bekannt)', () => {
  let n = 0;
  DATEIEN.forEach(({ datei, kurs }) => (kurs.questions || []).forEach((q, i) => {
    n++; const wo = datei + ' Frage ' + (i + 1);
    assert.ok(q.question && q.question.trim(), wo + ': leer');
    assert.ok(TYPEN.has(q.question_type), wo + ': Typ ' + q.question_type);
    const o = opts(q); assert.ok(o.length >= 2 && o.length <= 4, wo + ': ' + o.length + ' Optionen');
    if (q.question_type === 'multiple_choice') {
      if (q.correct_index >= 0) assert.ok(q.correct_index < o.length, wo + ': correct_index außerhalb');
      else { assert.ok(Array.isArray(q.correct_multi) && q.correct_multi.length, wo + ': Mehrfachauswahl ohne Lösung'); q.correct_multi.forEach((c) => assert.ok(c >= 0 && c < o.length, wo + ': correct_multi außerhalb')); }
    }
    if (q.question_type === 'true_false') { const m = matches(q); assert.equal(m.length, o.length, wo + ': Lösungen ≠ Aussagen'); m.forEach((x) => assert.ok(x === 'true' || x === 'false', wo + ': Lösung ' + x)); }
    if (q.question_type === 'match') { const m = matches(q); assert.equal(m.length, o.length, wo + ': Paare unvollständig'); assert.deepEqual(q.correct_order, o.map((_, j) => j), wo + ': correct_order'); }
    if (q.question_type === 'sort') { assert.ok(o.length >= 2, wo + ': Reihenfolge braucht ≥ 2'); assert.deepEqual([...q.correct_order].sort(), o.map((_, j) => j), wo + ': correct_order keine Permutation'); }
  }));
  assert.ok(n > 300, 'zu wenige Fragen insgesamt: ' + n);
});

test('je Lernskript-Kapitel gibt es eine Übungs-Lektion, je Modul Wissenstest und Praxisfall', () => {
  const { lernskripte } = H.daten();
  const titel = DATEIEN.map((d) => d.kurs.title);
  Object.keys(lernskripte).forEach((id) => {
    lernskripte[id].kapitel.forEach((k) => assert.ok(titel.some((t) => new RegExp('^' + id.replace(/\./g, '\\.') + ' Übungen ' + k.key + ' ').test(t)), id + ' ' + k.key + ': keine Übungs-Lektion'));
    const wt = DATEIEN.find((d) => d.kurs.title.startsWith(id + ' Wissenstest'));
    assert.ok(wt, id + ': kein Wissenstest');
    assert.ok(wt.kurs.is_final_exam === true && wt.kurs.pass_threshold >= 50 && wt.kurs.pass_threshold <= 100, id + ': Wissenstest ohne Bestehensschwelle');
    assert.ok(titel.some((t) => t.startsWith(id + ' Praxisfall')), id + ': kein Praxisfall');
  });
});

test('Lernskript-Knopf findet die Übungs-Lektion zum Kapitel (Titelmuster)', () => {
  const re = (k) => new RegExp('^(?:\\d+(?:\\.\\d+)*\\s+)?Übungen\\s+' + k + '(?![A-Za-z0-9])', 'i');
  assert.ok(re('A').test('1.1.2 Übungen A – Unbundling: Warum so viele Beteiligte?'));
  assert.ok(!re('A').test('1.1.2 Übungen AB – x'));
  assert.ok(!re('B').test('1.1.2 Übungen A – x'));
  assert.ok(re('C').test('Übungen C'));
});
