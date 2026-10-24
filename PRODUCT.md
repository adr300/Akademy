# Bluuakademie – Produktkontext

Lernplattform der Bluu Energy für die Energiewirtschaft (Grundlagen, Marktkommunikation, Messwesen, SAP IS-U, interne Themen).
Eine einzige Datei `index.html` (Vanilla JS, Supabase-Client, jsPDF), gebaut mit `node build.js` nach `dist/`, gehostet auf Vercel.
Serverless-Funktionen unter `api/` (KI-Chat, Nutzer löschen mit serverseitiger Admin-Prüfung).

## Wer die Plattform nutzt

| Rolle | Erkennung | Was sie sieht |
|---|---|---|
| Lernende | Standard | Übersicht, Katalog (Fachbereiche → Module → Lektionen), Lernskript, Lernkarten, Quiz, Wiki, Erfolge, KI-Begleiter |
| Manager | Tabelle `managers` | zusätzlich «Manager»: Inhalte, Personen, Auswertung (ohne Rollenvergabe/Löschen) |
| Admin | Tabelle `admins` | wie Manager, zusätzlich Rollen, Einladungen, Nutzer löschen («Nur für Admins») |

Die Rolle wird clientseitig nur zur Anzeige ausgewertet; Berechtigungen setzt Supabase (RLS) bzw. `api/delete-user.js`.

## Informationsarchitektur Verwaltung (Admin & Manager)

A. **Überblick** – Stand aus den geladenen Daten, häufige Aufgaben, Fristen der nächsten 14 Tage.
B. **Inhalte** – Module, Kurse (Lektionen), Lernpfade, Simulatoren, Struktur; Untergruppe «Anlegen & Import» (KI-Import, HTML-Import).
C. **Personen** – Nutzer & Rollen, Teams, Pflicht-Kurse, Onboarding.
D. **Auswertung** – Fortschritt, Analytics, Leaderboard, Meldungen, Reflexionen.

Alle Reiter-IDs (`atab-*`), Funktionen (`adminTab`, `loadSuperAdmin`, …) und Datenflüsse sind unverändert; nur Reihenfolge, Gruppierung, Titel und Darstellung wurden konsolidiert.

## Nicht verhandelbar (Stand 24.10.2026)

Keine Änderungen an Supabase-Schema, Auth, Rollen, API-Verträgen, Abschluss-/Bestehensregeln, XP/Level/Streak-Logik, Zertifikaten, `course_index`, KI-Chat, Import, Simulatoren, Routen oder Nutzeraktionen.
Keine erfundenen Inhalte oder Kennzahlen; Leerzustände statt Platzhalterdaten. Backend-Wünsche stehen in `docs/BACKEND-AENDERUNGEN.md`.
