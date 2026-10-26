# Datenmodell und Datenfluss der Lerninhalte (Stand 26.10.2026)

Ergebnis der Bestandsaufnahme von `index.html` (Supabase-Client `sb`, 20 Inline-Script-Blöcke) und der Backend-Integration vom 26.10.2026. Es gibt im Repo keine SQL-Dateien von Adrian; die Tabellen unten sind aus den Zugriffen im Frontend abgeleitet. Alles, was «vermutet» heißt, muss Adrian an der echten Datenbank bestätigen.

## 1. Tabellen, die das Frontend benutzt

| Tabelle | Schlüssel (laut Zugriffen) | Wer schreibt | Zweck |
|---|---|---|---|
| `courses` | `id` (uuid), `sort_order`, `title`, `icon*`, `tag_*`, `btn_color`, `video_url`, `is_published` | Admin (Formular, Import, KI-Import) | Lektion |
| `slides` | `course_id`, `sort_order`, `tag`, `title`, `content` (HTML), `stat*` | Admin | Seiten einer Lektion |
| `questions` | `course_id`, `sort_order`, `question`, `opt_a..d`, `correct_index`, `question_type`, `correct_order` (JSON-Text), `match_a..d`, `scenario`, `feedback` | Admin | Testfragen (`multiple_choice`, Mehrfachauswahl = `correct_index -1` + `correct_order`, `true_false` mit `match_* = 'true'/'false'`, `match`, `sort`, `deadline`) |
| `learning_paths`, `path_courses` | `path_id`, `course_id` | Admin | Programm (Lernpfad) mit Zertifikat |
| `user_progress` | **`user_id`, `course_index`** (Position des Kurses in `courses` nach `sort_order`), `completed`, `score` | Lernende (Browser) | Lektion abgeschlossen (bestanden ab 70 %) |
| `user_xp` | `user_id`, `total_xp`, `level` | Lernende (Browser, `awardXP`) | XP und Level (`level = größtes l mit l²·100 ≤ xp`) |
| `badges`, `user_badges` | `badges.key`, `user_badges.user_id + badge_id` | Lernende (Browser, insert) | Abzeichen |
| `lernkarten_progress` | `user_id`, `module`, `set_key` | Lernende (Browser, upsert) | Lernkarten-Set abgeschlossen |
| `lernskript_progress` (neu, Migration 02) | `user_id`, `module` | Lernende (Browser, Block `BLUU-LS-SYNC`) | Lernskript-Stand geräteübergreifend |
| `profiles`, `admins`, `managers`, `teams`, `course_assignments`, `learning_sessions`, `daily_completions`, `reports`, `app_settings`, `chat_usage`, `ai_usage`, `video_reflections`, `onboarding_plans`, `pending_roles` | – | – | unverändert, nicht Teil dieser Integration |

Es gibt **keine RPC-Funktionen**; alle Mutationen laufen direkt aus dem Browser mit dem Anon-Key und der Session des Nutzers. Was ein Lernender darf, entscheidet allein die RLS in Supabase (aus dem Repo nicht einsehbar).

## 2. Beziehungen (so, wie sie heute wirklich sind)

```
Fachbereich (BLUU_FACHBEREICHE, im Code)
  └─ Modul (BLUU_MODULE, im Code: code, lernskript, lernkarten, pfade/kurse = Titelmuster)
       ├─ Lernskript (im Code: BLUU_LERNSKRIPT_111 bzw. BLUU_LERNSKRIPTE[modul]) ── Kapitel A–I
       │     └─ Stand: localStorage bluu-ls-<modul>-<uid>  (+ lernskript_progress, wenn Tabelle vorhanden)
       ├─ Lernkarten (im Code: LERNKARTEN_SETS bzw. BLUU_LERNKARTEN[modul]) ── Sets A–I (set_key '112-A' …, badge 'lk-112-A')
       │     └─ Stand: lernkarten_progress(user_id, module, set_key)
       └─ Lektionen (courses, über Titelmuster zugeordnet: '^1[.]1[.]2' …)
             ├─ Übungen A–I  (Kurs «1.1.2 Übungen A – …», Slides + Fragen)
             ├─ Wissenstest  (Kurs «1.1.2 Wissenstest – …», 20–24 Fragen)
             ├─ Praxisfall   (Kurs «1.1.2 Praxisfall – …», Slides + Zuordnungen)
             └─ Stand: user_progress(user_id, course_index) → XP (user_xp) → Abzeichen (user_badges)
```

Die Zuordnung Lektion → Modul ist **nicht** in der Datenbank, sondern ein Titelmuster in `BLUU_MODULE` (Backend-Wunsch 2: Spalte `courses.module_code`). Reflexionen (Tagesstart, Mentorgespräch) sind Trainermaterial und werden nicht importiert.

## 3. Datenfluss und seine Lücken

`Inhalt → Modul → Lektion → Aktivität → Prüfung → Fortschritt → XP/Abzeichen → Persistenz → UI`

| Schritt | Stand | Lücke / Risiko |
|---|---|---|
| Inhalt → Lektion | Import-Dateien in `content/import/` (Admin: «Kurs importieren») | Import war nicht dublettensicher → jetzt Titelprüfung im Frontend (`confirmImport`). Ein DB-Unique auf `courses.title` wäre robuster (Adrian). |
| Lektion → Modul | Titelmuster | Umbenennen eines Kurses löst die Zuordnung. |
| Aktivität → Prüfung | Fragen werden im Browser geprüft (`pick`, `renderSortQ` …) | Lösungen liegen im Client (`questions` wird komplett geladen). Für Übungen vertretbar; für Prüfungen mit Zertifikat Backend-Thema. |
| Fortschritt | `user_progress.course_index` ist **positional** | Löschen/Umsortieren eines Kurses verschiebt den Fortschritt aller Lernenden auf andere Kurse. Nicht geändert (Vorgabe); Vorschlag unten. |
| XP | Browser rechnet und schreibt `user_xp` | Jeder Lernende kann sich XP setzen. Migration 03: `award_xp()` serverseitig, Frontend nutzt sie automatisch, wenn vorhanden. XP werden bei Wiederholungen erneut vergeben (bestehendes Verhalten, auch 1.1.1). |
| Abzeichen | Browser prüft «schon vergeben» und fügt in `user_badges` ein | Doppelvergabe nur durch Client-Check verhindert → Unique (`user_id, badge_id`) in der DB empfohlen. Abzeichen für 1.1.2–1.1.5: Migration 04 (Namen zur Freigabe). |
| Lernkarten-Stand | Upsert auf `lernkarten_progress`; Fehler wurden verschluckt | Jetzt sichtbar im Abschluss-Popup; Migration 01 für Modulwerte/Unique/RLS. |
| Lernskript-Stand | nur Browser | Block `BLUU-LS-SYNC` + Migration 02 (Tabelle). Ohne Tabelle bleibt alles wie bisher. |
| UI | `slides.content` per innerHTML | Jetzt `bluuSanitize` (Skripte, Event-Attribute, fremde iframes raus). |

## 4. Lernskript-Stand: Datenvertrag und Zusammenführung

Browser-Stand `S` (unverändert): `{ kapitel: 'start'|'A'…, fs: 0..2, t: ms, k: { A: { e: {feld: text}, kann: [bool…], gemerkt, gemeldet, t: ms } } }`. Neu sind die Zeitstempel `t` (gesamt und je Kapitel), gesetzt bei jedem Speichern.

Serverzeile `lernskript_progress`: `user_id, module, chapter (= S.kapitel), completed_chapters (Kapitel mit allen Häkchen), stand (= S als jsonb), updated_at (= S.t)`.

Regeln `bluuLsMerge(lokal, server)` (getestet in `tests/sync.test.js`):
1. Häkchen `kann[i]`, `gemerkt`, `gemeldet`: ODER – eine Fertigstellung geht nie verloren, auch nicht durch einen älteren Browser-Stand.
2. Eingaben je Feld: nicht-leer schlägt leer; sind beide gefüllt, gewinnt das Kapitel mit dem jüngeren `t`.
3. Zuletzt besuchtes Kapitel und Schriftgröße: der jüngere Gesamtstand (`S.t`).
4. Kapitel, die nur auf einer Seite existieren, bleiben.
5. Idempotent: `merge(merge(a,b), b) = merge(a,b)`.

Ablauf: Beim Öffnen eines Lernskripts einmal je Sitzung Serverzeile lesen → zusammenführen → Browser aktualisieren (Neuzeichnen) → zusammengeführten Stand hochladen. Jede Änderung: 700 ms entprellt hochladen, `updated_at = S.t`; der DB-Trigger verwirft Updates mit älterem `updated_at` (stale writes). Fehler: Status «Speichern fehlgeschlagen – Stand bleibt im Browser»; fehlt die Tabelle (42P01/PGRST205), wird der Sync für die Sitzung abgeschaltet und «Stand nur in diesem Browser» gezeigt. Beim Verlassen der Seite wird ein offener Stand noch geschrieben (best effort).

## 5. XP und Abzeichen: Regeln, Status

- XP je Lernkarte beim ersten «Gewusst» einer Sitzung: 1.1.1 laut Dokument 10/20/30 nach Leuchtstufe; 1.1.2–1.1.5 **Vorschlag** Erklären 10 · Merksatz 10 · Stolperstelle 20 · Mitten im Job 20 · Erklär es Dir selbst 30 (Konfiguration: `XP` in `scratchpad/tf1_port.js` → Felder `level/xp` je Karte im Block `BLUU-TF1`). Status: **nicht freigegeben**.
- Wiederholung eines Sets vergibt erneut XP (bestehendes Verhalten in `lkAssess`). Idempotenz wäre: Karten-XP nur, solange das Set nicht `isDoneLK` ist. Nicht geändert, weil es auch 1.1.1 betrifft → Entscheidung Adrian/Antonia.
- Abzeichen je Set: 1.1.1 aus dem Dokument; 1.1.2–1.1.5 Schlüssel `lk-<modul>-<Set>`; vergeben nur, wenn `badges` die Zeile hat (Migration 04, Namen = Set-Titel, 50 XP – Vorschlag). Kein Abzeichen → kein Hinweis im Popup.
- Abschluss-Reihenfolge im Frontend: `markDoneLK` (Server) → bei Erfolg Abzeichen prüfen/einfügen → XP. Schlägt das Speichern fehl, wird der Set-Schlüssel nicht als fertig markiert und das Popup nennt den Fehler; XP der Karten sind dann bereits vergeben (kein Rollback möglich ohne RPC – siehe Backend-Wunsch 9).

## 6. Vorschlag für später: Fortschritt an `course_id` binden

`user_progress.course_index` sollte durch `course_id uuid` ersetzt werden: neue Spalte, Backfill `course_id = (select id from courses order by sort_order offset course_index limit 1)` **zum Zeitpunkt der Migration**, Unique `(user_id, course_id)`, Frontend liest beides (Übergang). Nicht vorbereitet, weil das Backfill nur stimmt, wenn seit den Einträgen nichts umsortiert wurde – das muss Adrian anhand der Historie beurteilen.
