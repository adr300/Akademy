# Datenbank-Update 2026-10-26 – Anleitung

Dauer: etwa 15 Minuten. Alles läuft im Supabase-Dashboard, keine CLI und keine Schlüssel nötig.
Die App funktioniert vor, während und nach dem Update; sie erkennt neue Tabellen und Funktionen von selbst.

## Was das Update bringt

- Lernskript-Stand auf allen Geräten (neue Tabelle `lernskript_progress`)
- Lernkarten 1.1.2–1.1.5 werden gespeichert, inklusive 30 neuer Abzeichen
- XP werden serverseitig vergeben; Kursabschluss, Tagesbonus und Abzeichen bringen XP nur einmal (neue Tabelle `xp_events`)
- Fortschritt hängt an der Kurs-ID statt an der Position (Spalte `user_progress.course_id`)
- Keine doppelten Abzeichen, Kurstitel oder Fortschrittszeilen mehr (eindeutige Indizes)
- Antwortprotokoll je Frage (neue Tabelle `question_answers`)
- Lernende sehen und schreiben überall nur ihre eigenen Zeilen (RLS)

## Schritte

**1. Backup.** Table Editor → je Tabelle → «Export to CSV»:
`user_progress`, `user_xp`, `user_badges`, `lernkarten_progress`, `badges`.
Alternativ: Database → Backups → prüfen, dass ein aktuelles tägliches Backup existiert.

**2. Vorabprüfung.** SQL Editor → New query → Inhalt von `supabase/00_vorabpruefung.sql` einfügen → Run.
Ändert nichts. Ergebnis als CSV exportieren oder Screenshot machen.
Wenn eine Zeile `ok = false` zeigt: kurz melden, bevor Schritt 3 läuft. Exakte Dubletten in `user_badges` und
`lernkarten_progress` räumt Schritt 3 selbst auf (die älteste Zeile bleibt); Dubletten in `courses` oder
`user_progress` werden **nicht** angefasst, nur der jeweilige Index wird dann übersprungen.

**3. Einspielen.** New query → Inhalt von `supabase/10_alles_einspielen.sql` → Run.
Läuft in einer einzigen Transaktion: bei einem Fehler wird nichts übernommen. Die Fehlermeldung dann bitte schicken.
Hinweise (NOTICE) im Ergebnisbereich bitte ebenfalls notieren.

**4. Kontrolle.** New query → `supabase/20_kontrolle.sql` → Run. Alle Zeilen sollten `ok = true` zeigen.
Die Zeilenzahlen in der letzten Zeile mit denen aus Schritt 2 vergleichen.

**5. Kurztest in der App** (mit einem Lernkonto): ein Lernkarten-Set aus 1.1.2 abschließen, das Lernskript öffnen und ein
Häkchen setzen, auf einem zweiten Gerät oder in einem privaten Fenster anmelden → Häkchen und Set sind da.

**6. Rückmeldung** an das Team: Screenshots von Schritt 2 und 4, eventuelle Hinweise oder Fehler.

## Was das Update nicht tut

- Es löscht keine Tabellen und benennt nichts um. Entfernt werden nur exakte Dubletten (siehe Schritt 2).
- Es ändert keine bestehenden Admin- oder Manager-Rechte.
- Teil 3b (Browser darf `user_xp` nicht mehr direkt schreiben) ist **nicht** enthalten. Das kommt erst nach einer
  Woche Betrieb ohne Auffälligkeiten, separat: `revoke insert, update on public.user_xp from authenticated;`

## Rückgängig machen

Jede Einzeldatei in `supabase/migrations/` enthält im Kopf eine Zeile «Rollback». Im Notfall reicht das Backup aus Schritt 1.
