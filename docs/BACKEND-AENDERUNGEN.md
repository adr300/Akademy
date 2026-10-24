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
