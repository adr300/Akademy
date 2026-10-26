# Backend- und Datenmodell-Wünsche (zur Freigabe durch Adrian)

Nichts davon wurde umgesetzt. Alles unten ist nur Vorschlag; die Frontend-Konsolidierung vom 24.10.2026 funktioniert ohne diese Änderungen.

## 1. Lernkarten an Module/Lektionen binden
Heute: `LERNKARTEN_SETS` (fest im Code) + fragen-abgeleitete Karten (`BLUU-INHALT`), Fortschritt in `localStorage` (`bluu-lernkarten-<uid>`, `lernkarten_progress`).
Wunsch: Tabelle `lernkarten_sets (id, module_code, course_id nullable, title, order)` + `lernkarten (set_id, front, back, order)` + `lernkarten_progress (user_id, card_id, status, updated_at)` mit RLS wie `progress`. Dann sind Karten je Modul auffindbar und geräteübergreifend.

## 2. Kurs-Metadaten für Katalog und Überblick
Wunsch: Spalten `courses.module_code` (Zuordnung zu `BLUU_MODULE`), `courses.difficulty` (1–3) und `courses.is_published` als verbindliches Feld (der Überblick liest `is_published !== false`, d. h. fehlendes Feld = veröffentlicht). Ohne `module_code` bleibt die Modul-Zuordnung im Frontend (`BLUU_MODULE[].kurse` / Titel-Heuristik).

## 3. Wiki-Beziehungen
Heute: `WIKI_ENTRIES` fest im Code; «Verwandt»-Chips werden zur Laufzeit aus Erwähnungen anderer Abkürzungen im Beschreibungstext abgeleitet (kein Datenfeld). Wunsch: Tabelle `wiki_entries` + Feld `related text[]`, pflegbar in der Verwaltung.

## 4. Offene Meldungen im Überblick
Der Überblick zeigt «–» bis «Meldungen» einmal geladen wurde (`#report-badge`). Ein leichter Zähl-Endpunkt (`select count(*) from reports where status='open'`, RLS für Manager/Admin) würde die Zahl sofort liefern.

## 5. KI-Import auf das Inhaltsmuster ausrichten
Prompt in `api/chat.js` / KI-Import so ergänzen, dass die erzeugten Slides die Elemente aus `docs/INHALTSMUSTER.md` verwenden (`.kasten`, `.formel`, `figure`, `dl`, `.quelle`).

## 6. Nutzer einladen für Manager
Der Button «+ Nutzer einladen» ist für Manager sichtbar und schreibt in `pending_roles`. Ob RLS das für Manager erlaubt, ist aus dem Frontend nicht ersichtlich. Bitte klären; falls nein, Button clientseitig für Manager ausblenden **und** RLS so belassen (Ausblenden ist keine Autorisierung).

## 7. Lernkarten und Lernskripte 1.1.2–1.1.5 (TF1, 26.10.2026)
- `lernkarten_progress`: das Frontend schreibt jetzt auch `module = '1.1.2' … '1.1.5'` (Set-Schlüssel `112-A` …) und liest alle fünf Module. Bitte prüfen, ob RLS/Constraints den Wert zulassen (bisher nur `'1.1.1'`).
- Abzeichen: die 30 neuen Sets haben kein Abzeichen (`badge:null`). Wenn gewünscht, je Untermodul ein `badges`-Eintrag wie bei 1.1.1 («Stromläufer» …) – die Schlüssel kann das Frontend dann in `BLUU_LERNKARTEN[modul][i].badge` eintragen.
- XP je Kartentyp (Erklären 10 · Merksatz 10 · Stolperstelle 20 · Erklär es Dir selbst 30) ist ein Frontend-Vorschlag; die Word-Dateien nennen keine Werte. XP-Vergabe läuft unverändert über `awardXP`.
- Kursinhalte aus dem Zip, die nicht in die App gehören (Adrian, Supabase `courses`): Übungen A–I je Modul, Wissenstest, Praxisfall, Reflexion, Live-Arbeitsblätter, Sprechertexte. Ein Kurs «Übungen» im Lernpfad des Moduls wird vom Lernskript-Knopf «Zu den Übungen» automatisch gefunden (Titel beginnt mit «Übungen»); Lernpfad-/Kurstitel sollten mit «1.1.2 …» oder dem Modultitel beginnen, damit `BLUU_MODULE[].pfade/kurse` greifen.
- Wunsch wie in 1.: Lernskript-Stand (`bluu-ls-<modul>-<uid>` im Browser) in eine Tabelle `lernskript_progress (user_id, module, chapter, done, inputs jsonb)` – dann wandert der Stand mit dem Konto.
