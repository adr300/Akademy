// Inhaltsintegrität: Module ↔ Lernskripte ↔ Lernkarten ↔ Begriffs-Check, ohne Datenbank.
const test = require('node:test');
const assert = require('node:assert/strict');
const H = require('./hilfen');

const { lernskripte, lernkarten } = H.daten();
const MODULE = H.moduleListe();
const html = H.html();

test('jedes Modul mit Lernskript/Lernkarten hat die Daten dazu (1.1.1 im eigenen Block)', () => {
  const codes = new Set();
  MODULE.forEach((m) => {
    assert.ok(!codes.has(m.code), 'Modulcode doppelt: ' + m.code); codes.add(m.code);
    if (m.lernskript && m.lernskript !== '1.1.1') assert.ok(lernskripte[m.lernskript], 'Lernskript fehlt: ' + m.lernskript);
    if (m.lernkarten && m.lernkarten !== '1.1.1') assert.ok(lernkarten[m.lernkarten], 'Lernkarten fehlen: ' + m.lernkarten);
  });
  assert.ok(html.includes("window.BLUU_LERNSKRIPT_111 = {"), 'Lernskript 1.1.1 fehlt');
  assert.ok(html.includes('const LERNKARTEN_SETS = ['), 'Lernkarten 1.1.1 fehlen');
});

test('Lernskript-Kapitel und Lernkarten-Sets stimmen je Modul überein', () => {
  Object.keys(lernskripte).forEach((id) => {
    const kap = lernskripte[id].kapitel.map((k) => k.key), sets = (lernkarten[id] || []).map((s) => s.letter);
    assert.deepEqual(sets, kap, id + ': Sets ≠ Kapitel');
    lernskripte[id].kapitel.forEach((k) => {
      assert.ok(k.lesezeit && k.danach && k.darum.length && k.wichtig.length && k.merksatz && k.selbst && k.selbst.antwort, id + ' ' + k.key + ': Kapitel unvollständig');
      assert.ok(k.kann && k.kann.length === 1, id + ' ' + k.key + ': genau ein «Das kann ich jetzt»');
      assert.ok(k.denk && k.denk.frage && k.job && k.job.length, id + ' ' + k.key + ': Denk-kurz-nach und Mitten-im-Job fehlen');
    });
  });
});

test('Lernkarten: eindeutige IDs und Set-Schlüssel, vollständige Karten, bekannte Typen, Fragen statt Stichwörter', () => {
  const ids = new Set(), keys = new Set();
  const TYPEN = new Set(['Erklären', 'Stolperstelle', 'Merksatz', 'Erklär es Dir selbst', 'Mitten im Job']);
  Object.keys(lernkarten).forEach((id) => lernkarten[id].forEach((s) => {
    assert.ok(!keys.has(s.key), 'Set-Schlüssel doppelt: ' + s.key); keys.add(s.key);
    assert.equal(s.modul, id); assert.match(s.badge, /^lk-\d{3}-[A-I]$/);
    assert.equal(s.totalXp, s.cards.reduce((a, c) => a + c.xp, 0), s.key + ': totalXp');
    s.cards.forEach((c) => {
      assert.ok(!ids.has(c.id), 'Karte doppelt: ' + c.id); ids.add(c.id);
      assert.ok(c.f && c.b, c.id + ': Vorder-/Rückseite leer');
      assert.ok(TYPEN.has(c.type), c.id + ': Typ ' + c.type);
      assert.ok(['Funke', 'Leuchten', 'Strahlen'].includes(c.level) && c.xp > 0, c.id + ': Level/XP');
      if (c.type === 'Erklären' || c.type === 'Merksatz') assert.ok(/[?.!]$/.test(c.f) && !/^Merksatz:/.test(c.f) && c.f.includes(' '), c.id + ': Vorderseite ist kein ausformulierter Satz: ' + c.f);
      if (c.type === 'Mitten im Job') assert.ok(c.tip, c.id + ': Job-Karte ohne Tipp');
    });
  }));
});

test('Begriffs-Check kennt jedes Modul mit Lernkarten', () => {
  const a = html.lastIndexOf('const THEMA = {'), b = html.indexOf(String.fromCharCode(10) + '  };', a);
  const thema = html.slice(a, b);
  MODULE.filter((m) => m.lernkarten).forEach((m) => assert.ok(thema.includes("'" + m.code + "'") || thema.includes('"' + m.code + '"') || thema.includes(m.code + ':'), 'THEMA fehlt für ' + m.code));
});

test('Modulzuordnung: importierte Kurse «<Modul> …» landen im richtigen Modul', () => {
  const kurse = H.importe().map((x) => ({ modul: x.modul, titel: x.kurs.title }));
  const regeln = MODULE.map((m) => ({ code: m.code, lernskript: m.lernskript, kurse: (m.kurse || []).map((r) => new RegExp(r, 'i')), pfade: (m.pfade || []).map((r) => new RegExp(r, 'i')) }));
  kurse.forEach((k) => {
    const treffer = regeln.find((r) => r.kurse.some((re) => re.test(k.titel)));
    assert.ok(treffer, 'kein Modul für ' + k.titel);
    assert.equal(treffer.lernskript, k.modul, k.titel + ' → ' + treffer.code);
  });
});
