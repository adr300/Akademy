# Testplan Lerninhalte, Fortschritt, XP und Rechte (26.10.2026)

## Automatisch (ohne Datenbank) – `npm test`

| Datei | Prüft |
|---|---|
| `tests/inhalt.test.js` | Modul ↔ Lernskript ↔ Lernkarten ↔ Begriffs-Check; eindeutige IDs/Set-Schlüssel/Abzeichen-Schlüssel; Karten vollständig; Erklären-Karten sind Fragen; importierte Kurstitel landen im richtigen Modul |
| `tests/import.test.js` | Import-Dateien in der Form von `confirmImport`; Fragen in den Grenzen der Renderer (≤ 4 Optionen, Lösung im Bereich, Zuordnung ohne doppelte Ziele, Reihenfolge als Permutation); je Kapitel eine Übungs-Lektion, je Modul Wissenstest und Praxisfall; Titelmuster des Lernskript-Knopfs |
| `tests/sync.test.js` | `bluuLsMerge`: monotone Häkchen, jüngeres Kapitel, Eingaben ohne Verlust, Idempotenz |

Dazu Syntaxprüfung aller Script-Blöcke (`node --check`), `node build.js` und der Screenshot-Harness (`akademy-shot.js`, ohne Backend).

## Mit echter Datenbank – noch nicht ausgeführt (braucht Testkonten und Adrians Freigabe der Migrationen)

Vor dem Test: Migrationen 01–04 in einer **Staging-Kopie** einspielen; drei Testkonten (Lernende, Manager, Admin).

### Inhalte
1. Admin importiert `content/import/1.1.2/*` in der Reihenfolge A…I, Wissenstest, Praxisfall → Modulseite 1.1.2 zeigt 11 Lektionen in dieser Reihenfolge; Katalogkarte zählt sie.
2. Dieselbe Datei erneut importieren → Meldung «existiert bereits», kein zweiter Kurs.
3. Lernskript 1.1.2 Kapitel A → «Zu den Übungen A» öffnet «1.1.2 Übungen A – …»; Kapitel ohne Kurs → Knopf deaktiviert mit Hinweis.
4. Übungen A durchspielen: Zuordnung, Mehrfachauswahl, Richtig/Falsch, Reihenfolge rendern und werten; Feedback erscheint; Abschluss mit ≥ 70 % setzt `user_progress`.

### Fortschritt
5. Lernskript 1.1.3: Häkchen setzen, Eingabe tippen → `lernskript_progress` hat die Zeile (`chapter`, `completed_chapters`, `stand`, `updated_at`); Statuszeile «Stand gespeichert».
6. Zweites Gerät / Inkognito mit demselben Konto → Kapitel und Häkchen sind da; dort weitere Eingabe → erstes Gerät nach Neuladen hat beides (Merge).
7. Veralteter Stand: in Gerät A offline ein Häkchen entfernen ist nicht möglich (monoton) – prüfen, dass eine ältere Zeile (`updated_at` in der Vergangenheit) ein neueres `completed_chapters` nicht überschreibt (Trigger).
8. Ohne Tabelle (Staging vor Migration 02): Lernskript funktioniert, Status «Stand nur in diesem Browser», keine Konsolenfehler außer der einen 404/42P01-Meldung.
9. Lernkarten-Set 1.1.4 B abschließen → `lernkarten_progress(module='1.1.4', set_key='114-B')`; Netz trennen und Set abschließen → Popup nennt den Speicherfehler, Set bleibt offen.

### XP und Abzeichen
10. Vor Migration 03: `user_xp` wird vom Browser geschrieben (wie bisher). Nach Migration 03: Netzwerk-Tab zeigt `rpc/award_xp`, `user_xp` stimmt mit Summe überein, Level nach `l²·100`.
11. Nach 3b (Rechte entzogen): direktes `upsert` auf `user_xp` aus der Konsole wird mit 42501 abgelehnt; XP über die App funktionieren weiter.
12. Set abschließen → Abzeichen `lk-114-B` genau einmal in `user_badges`; erneut abschließen → kein zweites, aber Karten-XP erneut (bestehendes Verhalten, dokumentiert).
13. `award_xp(-5)` und `award_xp(100000)` aus der Konsole → Fehler 22023.

### Rechte (RLS)
14. Lernende A versucht per Konsole `lernkarten_progress`/`lernskript_progress` von Lernende B zu lesen oder zu schreiben → 0 Zeilen bzw. 42501.
15. Lernende kann keine `courses`/`slides`/`questions` schreiben; Manager und Admin wie bisher.
16. Manager sieht keine `lernskript_progress`-Zeilen anderer (es sei denn, eine Auswertungs-Policy wurde bewusst ergänzt).

### Oberfläche
17. Fehlerzustände: Speichern fehlgeschlagen (Lernskript-Status rot; Lernkarten-Popup), Import-Dublette, deaktivierter Übungen-Knopf.
18. Bildschirmleser: Statuszeile (`role="status"`), Popup-Fehler (`role="alert"`), Zuordnungs-Selects beschriftet.

Ergebnisse bitte in `docs/BERICHT-2026-10-24.md` als Nachtrag festhalten.
