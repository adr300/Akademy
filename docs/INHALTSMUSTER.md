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
