# Übungen, Wissenstests und Praxisfälle importieren (TF1 Grundlagen)

Die Dateien in `content/import/<Modul>/` sind Bluuakademie-Kursdateien (HTML mit eingebettetem JSON), die die bestehende Admin-Funktion **Verwaltung → Inhalte → Kurs importieren** einliest. Sie wurden mit `scratchpad/tf1_kurse.js` aus den Word-Dateien des Zips erzeugt; Fragen, Optionen, Lösungen und Feedback stammen wörtlich aus den Dokumenten. Der Erzeugungsbericht steht in `content/import/BERICHT.md`.

## Was eine Datei enthält

| Kurs | Inhalt | Fragen |
|---|---|---|
| `<Modul> Übungen <K> – <Titel>` | Startscreen, Lernkarten (Tabellen), Selbstcheck mit aufklappbarer Musterantwort, Merksatz als Kasten; vor Untermodul A der Auffrischer als Slide mit aufklappbaren Lösungen (im Dokument «ohne Wertung») | Single Choice / Fallentscheidung → `multiple_choice`; Multiple Choice → Mehrfachauswahl; Richtig/Falsch → `true_false` (max. 4 Aussagen je Frage); Zuordnung 1:1 → `match` (max. 4 Paare); Zuordnung in Kategorien → je Aussage eine Single-Choice-Frage; Reihenfolge ≤ 4 Karten → `sort`, sonst Slide mit Lösung |
| `<Modul> Wissenstest – <Titel>` | Einleitung aus «Einsatz und Logik» | alle Fragen des Katalogs mit Feedback; gegen den Lösungsschlüssel geprüft |
| `<Modul> Praxisfall – <Titel>` | Musterrechnungen, Lesehilfe, Ergebnis und Quellen | Aufgaben «Wer steckt hinter …» als Zuordnungen (Vierergruppen ohne doppelte Zielwerte) |

## Reihenfolge und Zuordnung

1. Je Modul in dieser Reihenfolge importieren: Übungen A, B, … I, dann Wissenstest, dann Praxisfall. Der Import hängt jeden Kurs ans Ende (`sort_order`), und die Modulseite zeigt Lektionen in dieser Reihenfolge und schaltet sie nacheinander frei (A → B → … → Wissenstest), wie das Dokument es verlangt.
2. Die Kurse ordnen sich über den Titel dem Modul zu (`BLUU_MODULE[].kurse`: `^1[.]1[.]2` usw.). Titel nicht ändern; sonst verschwindet der Kurs aus dem Modul (er landet im Regal «Noch nicht zugeordnet»).
3. Der Knopf «Zu den Übungen K» im Lernskript findet den Kurs über das Muster `Übungen K` im Titel. Fehlt der Kurs, ist der Knopf deaktiviert und sagt das.
4. 1.1.1: Adrians vorhandener Kurs «Übungen» bleibt der Rückfall für alle Kapitel. Die Dateien unter `content/import/1.1.1/` sind optional; wer sie importiert, sollte den alten Kurs danach archivieren (Titel ändern), damit nicht zwei Übungssätze nebeneinander stehen.

## Schutz vor Dubletten

Der Import bricht ab, wenn ein Kurs mit gleichem Titel existiert (Prüfung im Frontend, `confirmImport`). Ein wiederholter Import legt also nichts doppelt an. Löschen eines Kurses verschiebt den Fortschritt aller Lernenden (`user_progress.course_index` ist positional, siehe `docs/DATENMODELL.md`) – deshalb Kurse lieber umbenennen oder unveröffentlicht lassen als löschen.

## Bekannte Abweichungen vom Dokument

- Bestanden-Grenze: Die Dokumente nennen z. B. «bestanden ab 19 von 24»; die App wertet jede Lektion mit 70 % (`saveProgress`). Das ist eine Backend-/Produktentscheidung (Backend-Wunsch 8).
- Reihenfolge-Aufgaben mit mehr als vier Karten (1.1.1 G6, H5; 1.1.2 G5) und der Auffrischer sind Slides mit aufklappbarer Lösung, keine bewerteten Fragen.
- Richtig/Falsch- und Zuordnungsfragen zeigen das Feedback gesammelt unter der Frage (ein Feedback-Feld je Frage), nicht je Aussage.
- «Ab dem zweiten Fehlversuch erscheint ein Tipp mit Folienverweis», Wiedereinstieg am letzten Screen und die Selbsteinschätzung «Konnte ich erklären / teilweise / noch nicht» gibt es im Lektionsformat der App nicht.

## Neu erzeugen

```
node scratchpad/tf1_kurse.js <Ordner mit den Text-Dumps> content/import
npm test
```

`docx_dump.py` erzeugt die Text-Dumps aus den Word-Dateien (siehe `docs/INHALTSMUSTER.md`). Der Generator meldet jede Stelle, die er nicht 1:1 abbilden kann.
