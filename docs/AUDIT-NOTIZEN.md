# Notizen für das nächste Bug-Audit (nicht behoben, nur festgehalten)

Gefunden beim Redesign am 24.10.2026. Keiner dieser Punkte wurde geändert, um Verhalten nicht ungewollt zu verschieben.

## Verwaltung
- `initSidebarVisibility()` (Z. ~6688) hat im Produktivcode keinen Aufrufer; Sichtbarkeit nach Rolle hängt faktisch an `data-role`-Attributen + CSS und an `loadSuperAdmin`. Die Konsolidierung umhüllt die Funktion nur.
- `bluuAdminOrdnen()` (BLUU-PLATTFORM) ordnete die Sidebar zur Laufzeit per DOM-Operationen um; jetzt durch `data-geordnet="1"` am `<nav>` deaktiviert. Der Code und die darin erzeugten Elemente (`sidebar-divider`, Untergruppe) können nach Abnahme entfernt werden.
- `bluuUebersichtOrdnen()` verschiebt «Ihr Stand», `gp-panel` und «Zuletzt» per DOM in das Profil – funktioniert, ist aber fragil gegenüber Markup-Änderungen.
- `#admin-tab-switch` / `.tab-switch` (Legacy) ist noch im Markup, ohne sichtbare Funktion.
- `loadSuperAdmin` setzt den Abschnittstitel selbst; der `adminTab`-Wrapper stellt «Nutzer & Rollen» wieder her. Besser: Titel in `loadSuperAdmin` nicht mehr überschreiben.
- Mehrere Sektionen laden ihre Daten erst beim Öffnen (progress, analytics, reports …); der Überblick zeigt dafür «–». Siehe Backend-Wunsch 4.
- Filter-Chip «Admins» wird für Manager per `style.display` versteckt (Z. ~4681) – reine Anzeige, keine Berechtigung.

## Lernende
- `slides.content` wird per `innerHTML` gerendert – seit 26.10.2026 durch `bluuSanitize` (Block BLUU-SICHER) bereinigt; `questions.question` wird als textContent gesetzt.
- Lernskript-Stand lag nur im `localStorage`; seit 26.10.2026 Sync über `lernskript_progress` (Migration 02, noch nicht eingespielt). Lernkarten-Fortschritt liegt in `lernkarten_progress`.
- Wiki-Daten (`WIKI_ENTRIES`, 212 Einträge) und `LERNKARTEN_SETS` sind im Code hartkodiert.
- Mehrere CSS-Epochen (Legacy-Tokens, «Bluuakademie 1:1», BLUU-*, BLUU-SYSTEM, BLUU-LERNSKRIPT, BLUU-VERWALTUNG) überlagern sich mit `!important`. Nach Abnahme: Legacy-Regeln, die nirgends mehr greifen, entfernen.

## Detektor-Befunde (impeccable detect, Stand nach dem Redesign)
Alle Befunde liegen in älteren Schichten (Login, Onboarding-«Welcome»-Sektion `w-*`, Quiz-Ergebnis), nicht im neuen Block:
- Kontrast: `#5B88AE` auf Navy-Flächen (2.9–4.3:1), `#d97706` auf dunkel (3.2:1) – Legacy-Token `--green`/Quiz-Buttons.
- Farbige Glows: `.w-eyebrow::before`, `.w-hello-sparkle`, `.w-streak-row .sd.on`, `pulseRing`; Navy-getönte `--e-2` auf dunklem Thema (Heuristik, optisch neutral).
- `transition: width` an XP-/Timeline-Balken (Layout-Transition).
- Federnde Easing `cubic-bezier(.2,1.4,.4,1)` (`--ease-spring`) an Abzeichen-Animationen.
- 10-px-Labels in Quiz-Ergebnis-Statistik («Richtig», «Fragen», «XP», …) – unter 11-px-Grenze.
- Onboarding: Kicker über h1, nummerierte Abschnittslabels, Verlaufstext.

## Harness (nur Prüfwerkzeug, nicht im Repo)
- `akademy-shot.js` setzt `isAdmin/isManager` direkt und bricht Supabase-Anfragen ab; datenladende Reiter zeigen daher Leer- oder Ladezustände. Reale Daten wurden nicht geprüft.

## Backend-Integration 26.10.2026 (offen)
- `user_progress.course_index` ist positional: Löschen/Umsortieren eines Kurses verschiebt den Fortschritt aller Lernenden. Nicht geändert (Vorgabe); Vorschlag in `docs/DATENMODELL.md` §6.
- XP werden bei Wiederholung eines Lernkarten-Sets erneut vergeben (auch 1.1.1). Entscheidung offen.
- Lösungen der Fragen liegen im Client (`questions` wird komplett geladen) – für Prüfungen mit Zertifikat Backend-Thema.
- `awardXP` schreibt ohne RPC weiterhin aus dem Browser (bis Migration 03/3b).
