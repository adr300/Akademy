# Datenbank-Änderungen ausführen

Die Dateien in `migrations/` sind reine SQL-Skripte. Sie werden **nicht** automatisch eingespielt – das Repo hat keine Supabase-CLI-Konfiguration und keine Zugangsdaten. Ausführen im Supabase-Dashboard: Projekt → **SQL Editor** → Inhalt der Datei einfügen → Run. Vorher die Kontrollabfragen im Kopf jeder Datei laufen lassen.

**Schnellweg (empfohlen):** `ANLEITUNG-ADRIAN.md` – drei Dateien im SQL Editor: `00_vorabpruefung.sql` (nur lesend), `10_alles_einspielen.sql` (01–08 in einer Transaktion, idempotent), `20_kontrolle.sql` (nur lesend). `10_alles_einspielen.sql` wird aus den Einzeldateien erzeugt; nach Änderungen an `migrations/` neu erzeugen.

Reihenfolge und Abhängigkeiten der Einzeldateien:

| Nr. | Datei | Nötig für | Hängt ab von |
|---|---|---|---|
| 01 | `2026-10-26_01_lernkarten_progress_module.sql` | Lernkarten 1.1.2–1.1.5 speichern | – |
| 02 | `2026-10-26_02_lernskript_progress.sql` | Lernskript-Stand auf allen Geräten | – |
| 03 | `2026-10-26_03_award_xp_rpc.sql` | XP serverseitig, einmalige Ereignisse über `xp_events` (Teil 3b erst nach Test) | – |
| 04 | `2026-10-26_04_badges_lernkarten_tf1.sql` | Abzeichen der neuen Sets (Namen/XP sind Vorschlag) | fügt nur vorhandene Spalten von `badges` ein |
| 05 | `2026-10-26_05_user_progress_course_id.sql` | Fortschritt überlebt Umsortieren/Löschen von Kursen | Backup von `user_progress` |
| 06 | `2026-10-26_06_uniques.sql` | keine doppelten Abzeichen/Titel/Fortschrittszeilen | entfernt exakte Dubletten in `user_badges`; überspringt Indizes bei Dubletten in `courses`/`user_progress` |
| 07 | `2026-10-26_07_complete_lernkarten_set.sql` | Set-Abschluss als Transaktion | 01, 03 und 06 |
| 08 | `2026-10-26_08_question_answers.sql` | Antwortprotokoll je Frage (Lernende: Nachsehen; Manager: schwierigste Fragen) | – |

Das Frontend erkennt jede dieser Änderungen zur Laufzeit (fehlende Tabelle/Spalte/Funktion → bisheriges Verhalten). Die Skripte können also in beliebiger Reihenfolge und zeitversetzt eingespielt werden, solange die Spalte «Hängt ab von» eingehalten wird.

Danach: Testplan `docs/TESTPLAN.md` mit einem Lern-, einem Manager- und einem Admin-Konto durchgehen.
