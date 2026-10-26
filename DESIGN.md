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

## Lernskript-Form B (Block `BLUU-TF1`, Module 1.1.2–1.1.5)

Gleicher Rahmen wie 1.1.1 (Leuchtpfad, Werkzeugleiste, Hero, Meta-Chips, Glühwürmchen-Blasen, `.ls-card`), aber ohne handgezeichnete Szene und ohne Mitmach-Rechner: Hero = Modulkachel in weißer Karte + Kapitelreihe (aktuell Lime, geschafft Navy). Reihenfolge der Karte: «Darum geht es» (Maskottchen «erklärt») → «Das Wichtigste» als nummerierte `.ls-sec` mit `.ls-tabelle` und `.ls-reihe` → «Typische Stolperstellen» (Maskottchen «denkt», `<details>` mit ?/✓-Marke) → `.ls-merk` → «Erklär es Dir selbst» (`.ls-mach`, Textarea + `details.ls-loesung`) → «Das kann ich jetzt» → Abschied («freut») → Weiter-Knöpfe. Lernkarten-Screen: Gruppenzeile `.lk-set-gruppe` je Modul (Mono-Chip mit Modulnummer, Titel, Sets-Zähler). Tabellen unter 640 px mit `overflow-wrap:anywhere`.

## Bewegung auf Modul-Icons (Block `BLUU-KANDIS`)

Ausnahme vom «kein Glanz»: auf Wunsch des Users bekommen die geometrischen Modul-Icons beim Hover einen «Candy»-Pop: federndes Heben (`cubic-bezier(.34,1.56,.64,1)`, −4 px, 110 %, −2,5°), weicher Glanzbogen oben links plus kleiner Reflex unten rechts (radiale Verläufe, screen), innerer Lichtrand, Schatten in der Modulfarbe. Gilt nur für `.szene-kachel`-Bilder (Modulkarten, «Meine Module», Modul-Kopf), nicht für Fachbereich-Illustrationen, Abzeichen oder Navigation. Dunkelmodus gedämpft, reduced-motion = nur Glanz.

## Begriffs-Check (Block `BLUU-CHECK`)

Übung ohne Prüfungscharakter, pro Modul. Form «Karten» für Grundlagen (eine Frage, vier Antworten in 2×2, Kennbuchstaben, sofortige Rückmeldung mit Lösung, Tipp und Wiki-Link; Segmentleiste oben: Navy aktuell, Lime richtig, Koralle falsch; Ergebnis als Ring mit Zahl). Form «Bogen» für Marktkommunikation, Messwesen, SAP (nummerierte Fragen auf einem Blatt, klebender Fuß «x von n beantwortet · Auswerten», nach der Auswertung Rahmen Lime/Koralle je Frage). Das Glühwürmchen im Kopf wechselt die Stimmung (neugierig → froh/denkt → stolz). Fragen immer aus vorhandenen Daten (Wiki, Lernkarten), nie erfunden; der Text sagt «Kein Test, keine XP».

## Maskottchen in Lernkarten

Die Kartenvorderseite zeigt das aktuelle Maskottchen (Komponente, 72 px), nie eine eigene Zeichnung. Stimmungen: neugierig → erklärt → stolz / froh / denkt.

## Was nicht erlaubt ist

Emoji als Icons in der Verwaltung, farbige Glows, Gloss-Verläufe auf Abzeichen, Platzhalterzahlen, Versalien im Fließtext, Text unter 11 px, neue Farbwerte außerhalb der Tokens.
