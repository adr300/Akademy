# Bluuakademie – Designsystem (wie ausgeliefert)

Abgeleitet aus `index.html`, Schicht `BLUU-SYSTEM` (Tokens) + `BLUU-VERWALTUNG` (Verwaltung, Leerzustände, Inhaltsmuster). Ältere Token-Schichten (`--bg`, `--green`, `--teal`, …) bleiben aus Kompatibilität bestehen; neue Regeln verwenden ausschließlich die Tokens unten.

## Farben

| Token | Wert (hell) | Rolle |
|---|---|---|
| `--ia-bg` | Navy `#243A4C` | Marke, Primärbuttons, Hero |
| Hero-Verlauf, Schatten-Tönung `--e-*` | Dunkles Navy `#1B2E3E` | Tiefe |
| `--ak` | Lime `#B7C21B` / Text `#8C9412` | Akzent, Fortschritt, Hervorhebung – sparsam |
| Sekundär im Hero | Stahlblau `#6F93B1` | Ruhe, Links auf Navy |
| `--sf-0` / `--sf-1` / `--sf-2` | `#F7F8F9` / weiß / Vertiefung | Seite / Karten / Felder |
| `--fg` / `--fg-2` / `--fg-3` | Text | Primär / Sekundär / Meta |
| `--ln` / `--ln-2` | Linien | Rahmen / betonte Rahmen |
| `--sel-bg` / `--sel-ln` / `--focus` | Auswahl | aktiver Reiter, Fokusring |

Dunkles Thema über `applyTheme('dark')` (`:root` ist dunkel, `[data-theme="light"]` überschreibt). Jede neue Regel muss in beiden Themen funktionieren; Farben nur über Tokens.

Fachbereiche haben je einen eigenen Ton (9 Töne, `BLUU_MODULE`), Abzeichen sind flach (kein Gloss, keine Facetten).

## Typografie

- Display: `Archivo` (`--disp`), 600–700, enge Laufweite: Seitentitel 26 px (Verwaltung), Hero bis 44 px, Karten-Titel 18 px.
- Text: `IBM Plex Sans` 14–16 px, Zeilenhöhe 1.5–1.6.
- Meta/Kicker/Tabellenköpfe: `IBM Plex Mono` 11 px, Versalien, Laufweite .06–.08 em – nur für kurze Labels, nie für Fließtext.
- Skala: `--fs-display / --fs-h3 / --fs-titel / --fs-body / --fs-small / --fs-meta`.

## Form & Raum

- Radien: Flächen `--r-surface` 10 px, Felder `--r-field` 8 px, Steuerelemente `--r-control` (Pille).
- Elevation: `--e-1` Ruhe, `--e-2` beim Heben (Buttons, Aufgabenkarten, Lernkarten-Sets, Modal). Keine farbigen Glows.
- Abstände `--sp-1 … --sp-8` (4-px-Raster). Sidebar 208 px, Inhalt `minmax(0,1fr)`.
- Bewegung: `--d-fast / --d-base / --d-slow`, `--ease-out`; Heben 2 px; `prefers-reduced-motion` schaltet Transformationen ab.

## Bausteine Verwaltung

- **Sidebar**: vier Gruppen mit Mono-Label, Strich-Icons 18 px (`bvIcon`), aktiver Eintrag `--sel-bg` + 3-px-Innenkante; Untergruppe «Anlegen & Import» mit Chevron; ≤ 768 px als Chip-Reihen (Untergruppe dann offen, Toggle ausgeblendet).
- **Abschnittskopf** `.sec-head > .sec-kopf (.sec-title + .sec-lead)` + Primäraktion rechts (`.btn-add`, Navy-Pille 40 px).
- **Kennzahlen** `.sa-stat-card / .an-kpi-card / .inhalt-kpi`: Zahl Archivo 28 px, Label Mono; «–» wenn nicht geladen, nie 0 erfinden.
- **Tabellen** `.inhalt-tabelle / .progress-table`: Mono-Kopf, 1-px-Linien, Zeilenhöhe 44 px, `.tabelle-scroll` bei Enge.
- **Filter-Chips** `.sa-filter / .rp-filter / .an-tab`: Pille, aktiv Navy.
- **Buttons**: `.btn-add` (primär), `.btn-sec` (sekundär), `.btn-sm/.btn-edit/.btn-del` (Zeilenaktionen 30 px); sichtbarer Fokusring `--focus`.
- **Leerzustände** `.bv-leer` und `:empty::before`: gestrichelter Rahmen, ein Satz, nächster Schritt benannt.

## Übersicht-Hero, Rang-Hover, Katalog (Feinschliff 24.10.2026)

- **Hero Übersicht** (`#bluu-hero`): Gruß links, «Heute dran» in der Mitte, Rang (Emblem 64 px + Level + XP) rechts mit `margin-left:auto`. Unter 900 px: Gruß und Rang in der ersten Zeile, «Heute dran» darunter. Der Hero bleibt so ein schmales Band.
- **Rang-Hover nach Level** (`bluuRangTier(lvl)`): Level 1 = `t0` (keine Bewegung), 2 = `t1`, 3 = `t2`, 4–5 = `t3` (Ring), 6–7 = `t4` (Doppelring). Gilt für Hero-Emblem, Profil-Emblem, XP-Leiste und Titel-Liste (gesperrte Titel `t0`). Abzeichen behalten ihre Stufe (gesperrt `t0`, Trophäe mindestens `t2`).
- **Katalog** (Block `BLUU-KATALOG2`): kompakter Navy-Kopf mit Titel «Katalog.», einem Satz, Suchfeld und Format-Reitern (Module · Programme · Lektionen). Darunter zwei Spalten: links die Fachbereiche als Filter-Liste (Glyph, Name, Zähler; aktiv = `--sel-bg` + 3-px-Kante), rechts das aktive Panel. Unter 1024 px wird die Liste eine horizontal scrollende Chip-Reihe. Jeder Fachbereich ist ein **Kasten** (Wunsch des Users: Illustration 64 px, Titel + Zähler, Satz, Link «Nur …»; 1 px `--ln`, `--sf-1`, Radius `--r-surface`, `--e-1`, keine farbige Kante); die Modulkarten darin liegen auf `--sf-0`, damit der Kasten die Gruppe trennt, ohne wie Karte-in-Karte zu wirken. Die Suche filtert das aktive Panel (Module/Programme per Text, Lektionen über `bluuLektionen`) und hat Leerzustände mit «Suche löschen».
- **Icon-Ebenen** (Entscheidung 24.10.2026, dritte Fassung): zwei Bildwelten, je Ebene eine.
  - **Fachbereiche** (Hauptebene): runde, gemalte Illustration aus dem ersten Katalog-Mockup (`BILDER`, Schlüssel `fach:<key>`): Gruppenkopf 64 px, Fachbereichsseite 72 px, Ring 1 px Navy 14 %. «Bluu intern» hat noch keine (flache Kachel).
  - **Module**: abgerundete Quadrate (Radius 23 %) im geometrisch-editorialen Stil des zweiten Mockups (Neoplastizismus/Futurismus: Flächen in Navy, Stahlblau, Lime, weiße Silhouette, kein Glanz, keine Zylinder): `BILDER` Schlüssel `modul:<code>`, WebP 128 px, Korn geglättet (Gauss 0.9 bei 2×), Sättigung 92 %, Kontrast 104 %, ≈ 59 KB für 13 Module. Modulkarten 56 px, «Meine Module» 56 px, Modul-Kopf 72 px; «in Vorbereitung» leicht gedämpft (Opacity .92, Sättigung 85 %), «fertig» mit Lime-Haken. Bibliothek aller 29 Kacheln (auch künftige Themen wie Recht & Regulierung, GeLi Gas, Netzwirtschaft) in `docs/bilder-module/`.
  - **Unterhalb des Moduls** (Lektionen, Kapitel, Sets, Programme): flache Kachel `PfadIcon` nach dem Canvas-Icon-System (Kontur + ein Akzent, Farbe des Fachbereichs; `leise` Tönung ohne Rand, `neu` gestrichelt, `voll`, `aktiv` mit Fortschrittslinie, `fertig` Lime-Haken). `bluuSzene(motiv, status, px, schluessel, fortschritt)` wählt Bild oder Kachel; `bluuGlyph(motiv, px)` liefert den Linien-Glyph für die Seitenleiste.
- **Modulkarte** `.modul-karte`: Icon 44 px mit eigenem Zeichen je Modul (`PfadIcon`-Motive `energie, edm, podcast, gpke, mabis, wim, smartmeter, steuerbox, isu, sim, dsgvo, sicherheit, ablage`; Farbe = Fachbereich), Titel Archivo 18 px, Zugang-Chip unter dem Titel, Beschreibung, Stand, Fortschrittslinie, Fuß nur wenn es Stand oder Aktion gibt. Geplante Module: gleiche Karte, Titel in `--fg-2`, kein Hover. Hover klickbarer Karten: 2 px heben, `--e-2`, Rahmen zur Modulfarbe gemischt. Raster `minmax(280px,1fr)`, `align-items:start`.

## Wiki (Glossar, Block `BLUU-WIKI2`, 24.10.2026)

Nach Canvas-Seite «Wiki» (Artefakt, Seite dcb81aee8d83): Navy-Band mit der Headline «Energie-Vokabular, einfach erklärt.» (Archivo 800, bis 56 px, «erklärt.» in Lime) und der weißen Suche (54 px, max. 760 px, Trefferzahl im Feld). Darunter klebt die A–Z-Leiste als **Filter** («Alle» + Buchstaben, leere deaktiviert, aktiv Navy). Links die Kategorien aus den Daten (`cat`) mit Farbquadrat und Zähler, rechts das Register in zwei Spalten ab 1240 px: Karte = großes Kürzel (Archivo 800, 28 px, Kategoriefarbe) · Kategorie-Chip (Tönung) · voller Name (600) · erster Satz der Definition; Klick/Enter klappt die ganze Definition und «Verwandt»-Chips auf (Pfeil oben rechts nur, wenn es mehr gibt). Buchstabenmarken über die ganze Breite, klebend. Suche: Kürzel exakt > Kürzel beginnt > Name > Erklärung, Treffer hervorgehoben, alle Treffer offen, ohne Buchstabenmarken. Leerzustand: gestrichelter Kasten mit «Suche und Filter zurücksetzen» und KI-Frage. Unter 900 px: Kategorien und A–Z als scrollende Chip-Reihen, eine Spalte.

## Inhaltsmuster (Lektionen & Lernskript)

Siehe `docs/INHALTSMUSTER.md`: `.ls-text` / `.slide-text` mit h2–h4, p, Listen, Tabellen (`.tabelle-scroll`, `caption`), `figure` + `figcaption`, `.kasten.definition|.beispiel|.hinweis|.warnung|.merke`, `.formel`, `blockquote` + `cite`, `dl`, `sup.fn` + `.fussnoten`, `.quelle`.

## Lernskript, ruhige Fassung (Block `BLUU-RUHIG`, 26.10.2026)

Ton: Universität, nicht Kinder-App. Maskottchen nur bei der Begrüßung (Startseite, 1.1.1-Kapitelanfang) und beim Kapitel-Häkchen; sonst keine Figur. Karten `.ls-card` 1 px Linie, Radius 12 px, Flächen `--ls-seite`/`--ls-ice`; Abschnittslabels (`.ls-tag`, `.ls-h2b`, Merksatz-Label) als IBM Plex Mono 11 px Versalien in `--ls-muted`; keine Navy-Pillen, kein Lime-Glühen (`--ls-glow` = Ice), keine Nummernkacheln, Merksatz ohne farbige Kante. Buttons ohne Heben, Hover nur per Farbe. Kapitel-Chips mono, Rahmen statt Füllung. Modulkacheln: Icon-System v3 (Linie × Geometrie, getönt, Radius 23 %), Fachbereiche weiter gemalt rund.

## Lernskript-Form B (Block `BLUU-TF1`, Module 1.1.2–1.1.5)

Gleicher Rahmen wie 1.1.1 (Leuchtpfad, Werkzeugleiste, Hero, Meta-Chips, Glühwürmchen-Blasen, `.ls-card`), aber ohne handgezeichnete Szene und ohne Mitmach-Rechner: Hero = Modulkachel in weißer Karte + Kapitelreihe (aktuell Lime, geschafft Navy). Reihenfolge der Karte: «Darum geht es» (Maskottchen «erklärt») → «Das Wichtigste» als nummerierte `.ls-sec` mit `.ls-tabelle` und `.ls-reihe` → «Typische Stolperstellen» (Maskottchen «denkt», `<details>` mit ?/✓-Marke) → `.ls-merk` → «Erklär es Dir selbst» (`.ls-mach`, Textarea + `details.ls-loesung`) → «Das kann ich jetzt» → Abschied («freut») → Weiter-Knöpfe. Lernkarten-Screen: Gruppenzeile `.lk-set-gruppe` je Modul (Mono-Chip mit Modulnummer, Titel, Sets-Zähler). Tabellen unter 640 px mit `overflow-wrap:anywhere`.

## Lernskript, Ausstrahlung (Block `BLUU-GLANZ`, 26.10.2026)

Baut auf der ruhigen Fassung auf, ohne sie zurückzunehmen. Titelbild je Kapitel: Himmel und Hügel im Fachbereichston (`--ls-ton`, nur bestehende Palettenwerte: Grundlagen Stahlblau `#6F93B1`, Marktkommunikation `#3F74A6`, Messwesen `#4A7A53`, Systeme Navy, intern `#4F6B82`), Wasserzeichen mit Kapitelbuchstabe bzw. Modulnummer (Archivo, 18 %), Motiv aus dem Kapiteltitel (Motivbibliothek `MOTIV_B`: Entflechtung, Kette, Rollen, Kunde, Paragraf, Zeitstrahl, Strom/Gas, Rechnung, Zähler, ID-Karte, Daten, Waage, Pipeline, Steuerung, Schild, Karte, Landschaft). Beschriftungen im Bild nur aus den Zeilenköpfen der ersten Tabelle des Kapitels, nie erfunden. Kapitelbuchstabe als getöntes Quadrat vor dem Titel; Kartenlabels mit 26-px-Icon-Anker (Ton, bei «Denk kurz nach»/«Erklär es Dir selbst» Lime); Abschnittstitel mit 3-px-Tonkante; Tabellen mit Rahmen, Radius 12, Kopf auf `--ls-seite`, Zeilenmarke vor dem Zeilenkopf; Reihen als Stepper mit Verbindungslinie; Merksatz als Navy-Karte mit Lime-Kante, Lime-Label und Anführungszeichen; Leuchtpfad mit Fortschrittsbalken; Lesebalken (3 px Lime, fixiert oben); Karten blenden gestaffelt ein (40 ms, `prefers-reduced-motion` schaltet ab). Dunkles Thema: Titelbild bleibt hell (Papier), Merksatz `#1B2E3E`.

## Lumi, das Maskottchen, und der Rundgang (Block `BLUU-LUMI`, 26.10.2026)

Das Glühwürmchen heißt Lumi (Komponente `Maskottchen`, Look `team`). Stimmung «erklaert» ist fröhlich: keine halben Lider, Brauen oben, Blick nach vorn, lachender offener Sprechmund (animierte Öffnung), Wangen. Begrüßungsrundgang: Lumi fliegt als `position:fixed`-Figur (92 px, mobil 64 px) auf einer kubischen Bézier-Kurve per `requestAnimationFrame` (`translate3d`, Drehung in Flugrichtung bis 16°, Flügelschlag im Flug schneller, Abheben/Landen als kurze Skalierung) zu den echten Elementen mit `data-tour-target` (uebersicht, weiter, module, lernkarten, katalog, wiki, erfolge, assistent). Platzwahl aus dem Zielrechteck: bei breiten Zielen innen rechts, sonst rechts → links → unten → oben, nie über anderen Zielmarken, Eingabefeldern oder außerhalb des Viewports. Sprechblase (weiß/Navy-Rahmen, Radius 14, Spitze zur Figur, Archivo-Name, Mono-Zähler, Schreibmaschinentext) auf der dem Ziel abgewandten Seite; Ziel bekommt Lime-Umriss (`.lumi-ziel`). Kein Overlay, die Seite bleibt bedienbar. Mobil: Blase als Leiste unten mit Lumi links darin, Ziele nur markiert und angescrollt. Zustände idle → flying → explaining → waiting → completed; Steuerung Weiter, Zurück, Überspringen, Schließen, Tour erneut starten, Tastatur (Pfeile, Esc). Verschwindet das Ziel (Ansichtswechsel), parkt Lumi unten rechts und wartet; reduced-motion ersetzt Flüge durch Sprünge und Tippen durch Sofortanzeige. Persistenz je Nutzer in `localStorage` (`bluu-lumi-<uid>` = fertig/abgebrochen); Neustart über «Rundgang mit Lumi» im Nutzermenü. Weitere Schritte: Eintrag in `SCHRITTE` plus `data-tour-target` am Element.

## Szenen im Stil der Vorlagen und Übungen Screen für Screen (Blöcke `BLUU-SZENEN`, `BLUU-UEBEN`, 26.10.2026)

Szenen (`szeneSvg`, 1000×400): getönter Himmel, zwei Hügel, Bodenlinie, Wolken, runde Bäume und Büsche (`#A9D18C`/`#9CCB80`), Motiv aus der Bibliothek um 1,115 skaliert, Häuser mit Lime-Fenstern, Pillen hellblau (`#DCE8F3`) mit Icon (Blitz, Mast, Haus), letzte Station Lime, Leuchtspur gepunktet in Lime mit Pfeilspitzen. Gilt für das Lernskript-Titelbild aller Module (auch 1.1.1 mit seinen Kapitelszenen). Der Modul-Hero bleibt das ursprüngliche Navy-Band ohne Szene (vom User so entschieden); der Überblick des Moduls ist unverändert.

Übungen (Reiter «Übungen», Daten `window.BLUU_UEBEN` aus den Word-Dokumenten): gleicher Rahmen wie das Lernskript (`.ls.ueben`): Leuchtpfad links (Startseite, Auffrischer R, Untermodule A–I, gesperrt bis das vorige abgeschlossen ist, Fortschrittsbalken), rechts Startseite (Titel, Untertitel, Einleitung, Fortschritt, Auffrischer-Karte, Untermodul-Liste mit Ergebnis und Richtzeit) oder Untermodul-Screen (Werkzeugzeile «Screen n von m», Titel mit Buchstabenquadrat, Chips Richtzeit/Ergebnis/Folie, Segmentleiste, eine `.ls-card` je Screen mit Mono-Label «Aufgabe · Zuordnung · B2»). Aufgaben: Optionen `.ub-opt` mit Kennbuchstaben, Zeilen `.ub-zeile` mit Chips (Richtig/Falsch, Zuordnung), Reihenfolge mit Pfeiltasten, Mehrfachauswahl mit Kästchen; «Antwort prüfen» → Feedback-Kasten (Lime-Grün richtig, Koralle falsch), Korrektur möglich, ab dem zweiten Fehlversuch Lumi-Tipp als `.ls-bub`, ab dem dritten «Lösung zeigen». Selbstcheck: Textfeld, «Musterantwort zeigen», Selbsteinschätzung als Chips, bei «noch nicht» Hinweis mit Link ins Lernskript-Kapitel, Merksatz als Navy-Zitat, Lumi-Abschied. Keine Punkte, keine Rangliste; Stand je Nutzer in `localStorage`.

## Lernskript-Kapitelseite nach der Vorlage (Block `BLUU-DREI`, 26.10.2026)

Drei Spalten ab 1280 px (232 / Inhalt / 264 px), darunter Seitenleiste als Kartenreihe unter dem Inhalt. Links: Karte «Dein Fortschritt» (Ring 72 px in Lime, «n von m Kapiteln abgeschlossen», Balken, Links «Was Du lernst», «Alle Kapitel», «Zum Modul», «Begriffe im Wiki»), dann der Leuchtpfad, unten der Tipp-Kasten (hellblau, Lampe: «Du kannst das Lernskript jederzeit unterbrechen …»). Mitte: Chip «Kapitel n von m» und Zeit rechts, Titel mit Buchstabenquadrat, Intro (Darum geht es bzw. Lead), Szene, Meta-Chips, «Inhalte dieses Kapitels» (Abschnittstitel mit Play-Marke), danach der bekannte Inhalt; der Weiter-Knopf heißt «Weiterlernen · Kapitel X» und ist Lime. Rechts: «Was Du in diesem Kapitel lernst» (die Kann-Sätze), «Nächster Schritt» (Übungen K mit Richtzeit, sonst nächstes Kapitel oder Lernkarten), «Dein Ziel» (Lime-Karte; Programm-Zertifikat nur, wenn ein Programm existiert). Keine Schrittkarten, kein Hero-Band (vom User ausgeschlossen). Die Übungen (`.ls.ueben`) nutzen dieselben Bausteine: Fortschrittskarte, Tipp, Seitenleiste mit Ergebnis, nächstem Untermodul und Ziel.

Szenen (Ergänzung zu `BLUU-SZENEN`): Berge und Stadtsilhouette hinten, grüne Wiesen vorn, Sonne, Windräder mit Lime-Bewegungsbögen, Haus mit Solardach, Gebäude mit Fenstern, Pillen hellblau mit runder Marke (Lime bei der ersten Station) und Verbindungslinien.

## Navigation in den Lernbildschirmen (Block `BLUU-AUDIT`, 26.10.2026)

Ein Rückweg je Bildschirm, keine schwebende Zweitleiste: Der Zurück-Knopf der Lektions-Chrome (Folien, Test) heißt «← Zum Modul», sobald die Lektion aus einem Modul gestartet wurde, sonst «← Zurück» (Übersicht); der Ergebnis-Knopf heißt dann «Zum Modul». Lernkarten aus dem Modul kehren in den Reiter «Lernkarten» zurück, «← Sets» bleibt die Ebene darüber. Logo und Markenzeile oben links führen zur Übersicht (`role="link"`, Tastatur, Label «Zur Übersicht»; das Easter Egg bei fünf Klicks bleibt). Kopfzeile der Chrome umbricht (Titel maximal zwei Zeilen), Ergebnis-Knöpfe stapeln sich unter 640 px, Tabellen-Zeilenköpfe in Folien und Lernskript umbrechen (Silbentrennung), Lernkarten wachsen mit dem Inhalt (Mindesthöhe 280 px, Figur 84 px hoch über dem Text). Lumi-Rundgang: Abschluss schließt nur, keine Navigation; Zielklicks sind normale Navigation und parken den Rundgang.

## Lesefassung für alle Lernskripte und die Übungen (Block `BLUU-LESEFASSUNG`, 27.10.2026)

Die Lesefassung aus `BLUU-REDAKTION` gilt jetzt für jedes Kapitel jedes Moduls (1.1.1–1.1.5 und Entwürfe) und für «Bevor es losgeht»: Text steht direkt auf der Seite wie im Reiter «Überblick» (IBM Plex Sans, `--rd-text`, Mono-Etiketten), ohne Papierfläche, ohne getönte Kästen, ohne Kacheln. Trennung nur durch Linien und Weißraum. Form-B-Kapitel: «Darum geht es» als Einstieg, «Das Wichtigste» als Teile mit Tabellen und Reihen, Merksatz und Stolperstellen in «Auf einen Blick», Denk kurz nach, Mitten im Job, Erklär es Dir selbst, Das kann ich jetzt in «Jetzt bist Du dran». Startseite: Kapiteltabelle mit Sprung ins Kapitel. Interaktive Grafiken als Zeilen mit Linien, Auswahl durch Lime-Unterstreichung statt Fläche; Fortschritt links ohne Rahmen; Tipp ohne Fläche. Übungen im selben Rahmen ohne rechte Spalte: Kopf mit Kicker, Titel, Meta-Zeile; Antwortoptionen als Liste mit Kennbuchstaben im Kreis statt grauer Karten; Rückmeldung als Zeile mit farbigem Wort (Grün/Koralle), keine Farbfläche. Steuerelemente (Knöpfe, Eingabefelder, Wahl-Chips) behalten ihre Rahmen.

## Abbildungen und lebendige interaktive Grafiken im Lernskript (Blöcke `BLUU-LSBILDER`, `BLUU-ILLU`, 27.10.2026)

Abbildungen: Vorlagen des Users (WebP, eingebettet, Titelzeile beschnitten, weil der Abschnittstitel darüber steht; Untertitel als Bildunterschrift «Abbildung n.»). Im hellen Thema `mix-blend-mode:multiply`, damit das Bildweiß im Seitenhintergrund aufgeht; im dunklen Thema als helle Tafel mit Radius 10. Zuordnung in `window.BLUU_LS_BILDER[modul][kapitel]`: `kopf` (unter dem Kapitelkopf), `teile[Abschnittstitel]` (nach dem ersten Absatz), `alltag` (vor der Alltag-Grafik), `synthese` (unter «Zusammenfassung», derzeit nicht genutzt: keine Wiederholung der drei Stationen).
Kette A-1: vier Stationen mit Beispielsymbolen (42 px, bei vier Stationen 36 px) unter dem Titel; Abbildungen, die dasselbe zeigen, gehören in die Grafik statt daneben. Interaktive Grafiken (Kette, Spannungsebenen, Gasweg, Energieformen, Bildfolge): je Station eine Szene im Stil der Vorlagen in einem hellen Kreis (Navy-Kontur 1,3–2, Weiß, Solarblau `#2F5384`, Grün `#9BCB7C`/`#76AE5C`, Lime-Akzente), darunter Nummer im Lime-Punkt, Titel in Archivo, Untertitel. Lime-Pfeile zwischen den Stationen. Kein Rahmen um Text. Hover: Szene hebt sich 6 px, Kreis wächst, Rotoren drehen, Dampf zieht, Fenster leuchten, Titel bekommt die Lime-Unterstreichung. Klick: gewählte Station springt (Pop), Kreis wird Lime-hell mit Lime-Ring, Nummer wird Navy, Erklärung gleitet ein. «Strom fließen lassen»: Leitungen und Pfeile laufen gestrichelt in Lime, Kreise pulsieren nacheinander. Spannungsebenen mit Skala «sehr hohe → niedrige Spannung». Unter 640 px stehen Nummer und Titel untereinander, Pfeile entfallen, vier Stationen 2 × 2. `prefers-reduced-motion`: keine Bewegung. Dunkles Thema: Szenen und Beispielsymbole auf heller Tafel (#F3F7FA, Radius 14), Kreise hell, damit Kontur, Boden und Leitungen lesbar bleiben.

## Bewegung auf Modul-Icons (Block `BLUU-KANDIS`)

Ausnahme vom «kein Glanz»: auf Wunsch des Users bekommen die geometrischen Modul-Icons beim Hover einen «Candy»-Pop: federndes Heben (`cubic-bezier(.34,1.56,.64,1)`, −4 px, 110 %, −2,5°), weicher Glanzbogen oben links plus kleiner Reflex unten rechts (radiale Verläufe, screen), innerer Lichtrand, Schatten in der Modulfarbe. Gilt nur für `.szene-kachel`-Bilder (Modulkarten, «Meine Module», Modul-Kopf), nicht für Fachbereich-Illustrationen, Abzeichen oder Navigation. Dunkelmodus gedämpft, reduced-motion = nur Glanz.

## Begriffs-Check (Block `BLUU-CHECK`)

Übung ohne Prüfungscharakter, pro Modul. Form «Karten» für Grundlagen (eine Frage, vier Antworten in 2×2, Kennbuchstaben, sofortige Rückmeldung mit Lösung, Tipp und Wiki-Link; Segmentleiste oben: Navy aktuell, Lime richtig, Koralle falsch; Ergebnis als Ring mit Zahl). Form «Bogen» für Marktkommunikation, Messwesen, SAP (nummerierte Fragen auf einem Blatt, klebender Fuß «x von n beantwortet · Auswerten», nach der Auswertung Rahmen Lime/Koralle je Frage). Das Glühwürmchen im Kopf wechselt die Stimmung (neugierig → froh/denkt → stolz). Fragen immer aus vorhandenen Daten (Wiki, Lernkarten), nie erfunden; der Text sagt «Kein Test, keine XP».

## Maskottchen in Lernkarten

Die Kartenvorderseite zeigt das aktuelle Maskottchen (Komponente, 72 px), nie eine eigene Zeichnung. Stimmungen: neugierig → erklärt → stolz / froh / denkt.

## Bewegung des Maskottchens

Lumi bewegt sich weich und nie mechanisch: Spline-Easing für alle SMIL-Animationen, Schweben als liegende Acht, Fühler schwingen verzögert nach, Blinzeln einzeln und doppelt, kurze Blicke zur Seite. Strecken und Stauchen höchstens 1,5 % im Ruhezustand und 4,5 % im Flug. Abheben mit Ausholen, Landung mit Nachfedern. Bei «Bewegung reduzieren» und unter 44 px ist alles statisch.

Keine Spurlinien hinter Lumi: Das Licht des Glühwürmchens ist das Motiv (Schein im Flug, Lichtblitz beim Erscheinen, Aufleuchten der berührten Karte, Lichtwelle bei der Landung). Flüge laufen als Bogen über `translate`/`rotate`/`scale`, nie über `left`/`top`.

## Hero der Übersicht

Navy-Band mit Trasse und Windpark (wie ausgeliefert). Glas als Schicht über dem ganzen Band (durchscheinender Lichtverlauf, helle Ober- und Unterkante), nie als Kasten um Inhalte. Präsentationsmodus `?praesentation=1` hält die Landschaft an.

## Was nicht erlaubt ist

Emoji als Icons in der Verwaltung, farbige Glows, Gloss-Verläufe auf Abzeichen, Platzhalterzahlen, Versalien im Fließtext, Text unter 11 px, neue Farbwerte außerhalb der Tokens.
