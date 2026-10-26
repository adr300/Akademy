# Inhaltsmuster: vom PDF zur erweiterbaren HTML-Lektion

Lektionen (`courses.slides[].content`) und das Lernskript (`BLUU_LERNSKRIPT_*`) sind HTML, das `renderSlide()` bzw. die Lernskript-Logik per `innerHTML` einsetzt. Beide Container (`.slide-text`, `.ls-text`) teilen seit dem 24.10.2026 dieselben Typografie-Regeln (CSS-Block `BLUU-VERWALTUNG`, Abschnitt «Inhaltsmuster»). Ein PDF wird also nicht «eingebettet», sondern in diese Elemente übertragen.

## Unterstützte Elemente

| Element | Wofür | Hinweis |
|---|---|---|
| `h2`, `h3`, `h4` | Kapitel, Abschnitt, Unterpunkt | Archivo; `h2` nur einmal je Slide |
| `p`, `strong`, `em`, `a` | Fließtext | Fachbegriffe werden automatisch mit dem Wiki verknüpft (`linkifyWikiTerms`) |
| `ul`, `ol` | Aufzählung, Ablauf | |
| `div.kasten.definition / .beispiel / .hinweis / .warnung / .merke` | Kästen mit Punktmarke | erstes `strong` ist die Kastenüberschrift |
| `div.formel` + `small` | Formel mit Einheit | Mono, zentriert |
| `div.tabelle-scroll > table > caption/thead/tbody` | Tabellen | `caption` unter der Tabelle als Bildunterschrift; scrollt horizontal statt umzubrechen |
| `figure > img + figcaption` | Abbildungen | `figure.breit` für volle Breite; `alt` pflegen |
| `dl > dt + dd` | Abkürzungen, Begriffe | zweispaltig, einspaltig unter 640 px |
| `blockquote > … + cite` | Zitat mit Quelle | |
| `sup.fn` + `div.fussnoten > ol` | Fußnoten | Nummern von Hand vergeben |
| `p.quelle` | Quellenangabe am Ende | Mono, klein |
| `code`, `hr` | Feldnamen, Trenner | |

## Pilot

Die Prüf-Lektion «Bilanzkreis und Ausgleichsenergie» (Fixture im Screenshot-Harness `akademy-shot.js`, Ansicht `slide:muster`) nutzt alle Elemente und wurde durch den echten `renderSlide()` in beiden Themen gerendert: `akademy-shots/nachher/slide-muster-1440.png` und `slide-muster-dunkel-1440.png`. Sie ist **nicht** in der Datenbank – der Pilot belegt das Muster, nicht einen Inhalt. Das bestehende Lernskript 1.1.1 ist das produktive Beispiel für PDF-abgeleiteten Inhalt.

## Vorgehen für ein neues PDF

1. Kapitel → ein Slide je Kapitel (oder je Abschnitt bei langen Kapiteln), `title` = Kapiteltitel, `tag` = «Kapitel X».
2. Text in `h3/p/ul/ol` übertragen; Definitionen, Beispiele, Warnungen in `.kasten`; Tabellen als Tabellen, nicht als Bild.
3. Abbildungen als `figure` mit `alt` und Bildunterschrift (Quelle nennen).
4. Fußnoten und Quelle ans Ende.
5. Fragen separat in `questions` (unverändert).

## Grenzen

- Inhalte sind admin-verfasstes HTML und werden ungefiltert eingesetzt (bestehender Zustand, siehe `docs/AUDIT-NOTIZEN.md`).
- Keine automatische PDF-Konvertierung außer dem bestehenden KI-Import; dieses Muster beschreibt das Zielformat, das der KI-Import erzeugen sollte (Prompt-Anpassung = Backend-Thema, siehe `docs/BACKEND-AENDERUNGEN.md`).

## Lernskript-Form B und Lernkarten aus Word (TF1, 26.10.2026)

Die Word-Dateien aus «04 Lernplattform» haben eine feste Gliederung, die sich ohne Nacharbeit einlesen lässt (Dump: `docx_dump.py`, Parser: `tf1_port.js`, Eintrag: `tf1_patch.js`, Block `BLUU-TF1`):

| Word | Datenfeld | Darstellung |
|---|---|---|
| Starttabelle «Untermodul · Lesezeit · Danach üben» | `kapitel[].lesezeit`, `danach` | Meta-Chips, Startseite |
| `# A  Titel` | `kapitel[].key/titel` | Kapitel |
| `### Darum geht es` (Absätze) | `darum[]` | Karte mit Glühwürmchen «erklärt» |
| `### Das Wichtigste`: kurze Zeile = Blocktitel, Tabelle, Absatz nach Tabelle = Notiz, «Reihenfolge: …» + `1. A – B` | `wichtig[{titel, tabelle{kopf,zeilen}, notiz, reihe[[A,B]], text}]` | nummerierte Abschnitte, `.ls-tabelle`, `.ls-reihe` |
| `### Typische Stolperstellen` (Tabelle Falsche Annahme · Richtig ist) | `stolper[[falsch, richtig]]` | `<details>` je Zeile |
| einzellige Tabelle «Merksatz: …» | `merksatz` | `.ls-merk` |
| `### Erklär es Dir selbst`: «Frage: …» / «So könnte Deine Antwort lauten: …» | `selbst{frage, antwort}` | Textfeld + Musterantwort |
| Modulbeschreibung, Tabelle «Untermodul · Ergebnis» | `kann[Ergebnis]` | «Das kann ich jetzt» |
| Steckbrief «Darum geht es» | `start.weg`, `BLUU_MODULE[].beschreibung` | Startseite, Katalogkarte |
| Lernkarten: `### 1.1.2-A-01 · Typ` + Tabelle Vorderseite/Rückseite | `cards[{id, type, f, b, level, xp}]` | Lernkarten |

Für ein weiteres Modul: Zip entpacken, die vier Dateien (Lernskript, Lernkarten, Modulbeschreibung, Steckbrief) dumpen, in `tf1_port.js` die Modulzeile ergänzen, Patch laufen lassen; Kachel aus `docs/bilder-module/` wählen. Weicht ein Dokument von der Gliederung ab, meldet der Parser die Zeile («Warnung»).

### Fragen statt Stichwörter (26.10.2026)

Die Word-Lernkarten «Erklären» tragen vorn nur «Blocktitel: Zeile». Für die App bekommt jede dieser Karten eine ausformulierte Frage (`fragen_<modul>.json` → `fronts`), die Rückseite bleibt der Skripttext. Je Kapitel kommen dazu `denk` (Frage + Hinweis vor dem Lesen) und `job` (Situationen mit Tipp und Antwort), die sowohl im Lernskript (Karten «Denk kurz nach», «Mitten im Job», «Und?») als auch als Lernkarten vom Typ «Mitten im Job» erscheinen. Regel beim Schreiben: Antworten nur aus Sätzen des Lernskripts zusammensetzen, keine neuen Zahlen oder Regeln.

## Autorendatei für eigene Lernskripte (Entwürfe, 26.10.2026)

Für Module ohne Word-Vorlage gibt es ein kompaktes JSON (`scratchpad/inhalt/inhalt_<modul>.json`), aus dem `inhalt_build.js` Lernskript (Form B) und Lernkarten erzeugt:

```
{ "id": "2.1.1", "code": "gpke", "titel": "…", "beschreibung": "Entwurf … (Katalog)", "quellen": "…",
  "kapitel": [ { "key": "A", "titel": "…", "lesezeit": "ca. 5 Min.",
    "darum": ["…"], "denk": ["Frage", "Hinweis"],
    "wichtig": [ { "titel": "…", "kopf": ["Begriff", "Erklärung"], "zeilen": [["Begriff", "Erklärung", "Frage für die Lernkarte"]] },
                 { "titel": "… anordnen", "reihe": [["Schritt", "Erklärung"]] } ],
    "stolper": [["Falsche Annahme", "Richtig ist"]], "merksatz": "…", "merkfrage": "…",
    "job": [["Situation", "Tipp", "Antwort"]], "selbst": ["Frage", "Musterantwort"], "kann": "Ergebnis" } ] }
```

Karten entstehen automatisch: Erklären (dritte Spalte → Frage, Erklärung → Rückseite), Stolperstelle, Merksatz (merkfrage), Erklär es Dir selbst, Mitten im Job. Regeln: nur belegbare Aussagen (Gesetz, Festlegung, Branchenregel), Quellen im Feld `quellen` nennen, unsichere Zahlen weglassen statt raten, und jeden Entwurf als solchen kennzeichnen, bis Antonia/Adrian ihn geprüft haben.
