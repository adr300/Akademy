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
- `slides.content` wird ungefiltert per `innerHTML` gerendert (admin-verfasst). Bei Fremdinhalten (KI-Import) wäre ein Sanitizer sinnvoll.
- Lernkarten-Fortschritt liegt nur im `localStorage`, geht beim Gerätewechsel verloren.
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
