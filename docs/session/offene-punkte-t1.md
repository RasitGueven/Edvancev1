# Offene Punkte T1 (Trockenlauf vorbereiten)

Stand 08.10.2026 · Branch `feat/rasit-session-t1-trockenlauf` · Anleitung `docs/session/trockenlauf.md`

## Bestand (dbread 08.10.2026, nur Anzahlen)

| Was | Stand |
|---|---|
| Platz-Konten | 1 (Label „Platz 1“, `tablet_nr` 1, Rolle `student`, keine `students`-Zeile, Auth-User bestätigt, Adresse unter `edvance.invalid`) |
| belegte `tablet_nr` | 1 |
| Schülerzeilen | 26, alle `ist_test`; 0 echte Kinder |
| Testkinder nach Klasse | 16 × Klasse 8, 4 × Klasse 9, 6 × Klasse 10 |
| `fkt_linear_yabschnitt` offen | für alle 26 (Lernpfad in Prod leer) |
| Coach-Konten | 3, davon 1 als Testkonto erkennbar (Name oder Adresse); 2 Admins |
| Testlauf-Sessions | 0 |
| Kernideen (`erklaer_kernidee`) | 0; E2b nicht eingespielt |
| Testlauf-Pool Steigung / y-Achsenabschnitt / Funktionsgleichung | je 6 (echter Pool je 0) |

## Entscheidungen, die vom Wortlaut abweichen oder ihn auslegen

1. **Lesen über dbread, schreiben über die Admin-API.** `tools/platz-konten.mjs` liest den Bestand (belegte Nummern,
   vorhandene Auth-User `platz<n>@edvance.invalid`) über `~/bin/dbread` und schreibt nur über `@supabase/supabase-js` mit dem
   Service-Role-Key. Der Key kommt wie in `tools/verify-tasks.mjs` aus der Umgebung oder aus `.env` im aktuellen Verzeichnis.
2. **Adresse nach dem Muster des vorhandenen Geräts** (`platz<n>@edvance.invalid`): `.invalid` kann keine Mail empfangen. Label
   ist laut Auftrag „Tablet n“, das vorhandene Gerät heißt weiter „Platz 1“.
3. **Halb angelegte Konten** (Auth-User da, `tablet_nr` fehlt) führen zum Abbruch, bevor irgendetwas geschrieben wird.
   Scheitert beim Anlegen `profiles` oder `platz_devices`, nimmt das Werkzeug den gerade angelegten Auth-User zurück.
4. **Prüfskript „Kind n“** statt Namen; gezählt wird jedes Kind, das in einer Session-Tabelle der Session vorkommt, nicht
   nur die gebuchten. XP, Lernpfad und Mastery ohne `session_id` prüft es im Zeitfenster Start bis Ende plus 10 Minuten.
   Das ist streng: Eine fremde Buchung desselben Testkinds im Fenster würde als „nicht ok“ erscheinen.

## Angelegt (08.10.2026, nach „Plätze anlegen“)

- Aufruf aus `~/Edvancev1` (liest die `.env` dort, Key nie ausgegeben): erst `--dry-run 2-5` (4 × „würde anlegen“), dann echt
  (`{"angelegt":4,"uebersprungen":0,"konflikt":0}`).
- dbread danach: 5 Platz-Konten, `tablet_nr` 1–5; Tablet 2 bis 5 je Rolle `student`, ohne Namen, keine `students`-Zeile,
  bestätigt, Anbieter `email`, `profiles.email` gleich Auth-Adresse; Label „Tablet n“. Wie „Platz 1“.
- Zugangsdatei `~/platz-konten/zugaenge.txt`: 4 Zeilen, Datei 600, Ordner 700.
- Zweiter `--dry-run 2-5`: 4 × übersprungen (idempotent).
- Noch offen: Rasit meldet sich auf einem Tablet an und sieht den Warte-Bildschirm mit der Nummer.

## Befunde

1. **Kein Testlauf-Schalter für Coaching-Sessions.** `session_testlauf_setzen` gibt es, eine Oberfläche nicht
   (offene-punkte-x0, Offen 3). Der Trigger `coaching_sessions_testlauf_pruefen` verlangt Admin-Rolle, auch im SQL-Editor.
   **Rasit 08.10.:** für den Trockenlauf im SQL-Editor mit Admin-Claims (Snippet in `trockenlauf.md`, Schritt 6, read-only
   gegen Prod geprüft). Den Schalter im Stundenplan baut **T2** (nach X0c), nicht T1.
2. **Prüffrage im Trockenlauf nicht erreichbar.** Ohne Kandidat kein Knopf; der Lernpfad ist leer, und im Testlauf schreibt
   `antwort_abgeben` keine Belege. **Rasit 08.10.:** so stehen lassen; abgedeckt über die App-Vorschau (`/session/vorschau`)
   und pgTAP `session_a2b`.
3. **`mastery_entscheiden`, `pfad_tiefer`, `pfad_entscheiden` und `eingriff_notieren` prüfen `testlauf` nicht.** Sie schreiben
   in `lernpfad` bzw. `lernpfad_protokoll` mit der `session_id`. Heute ohne Wirkung (kein Kandidat, nur Testkinder), aber
   „Tiefer gehen“ oder ein Eingriff im Trockenlauf kann eine Lernpfad-Zeile erzeugen. Das Prüfskript meldet das als
   „nicht ok“ (Punkte 5 und 6). **Rasit 08.10.:** Ausschluss kommt mit **T2**; die Anleitung sagt „nicht drücken“.
4. **Reihenfolge der Zielliste in Prod** beginnt mit der Steigung, weil keine Voraussetzung als sicher gilt (offene-punkte-a2d 1 a
   beschreibt den Fall mit vier sicheren Voraussetzungen). Welcher Skill die Kernarbeit eröffnet, entscheidet der Planer;
   das zeigt erst der Trockenlauf (Anleitung, Schritt 5: notieren).
5. **Buchbare Testkinder in Klasse 8:** Buchen verlangt einen laufenden Vertrag (`session_platz_zugang`). Von 16 Testkindern
   der Klasse 8 haben genau drei einen (TESTLEAD Drittmann, Test Test `964738af…`, ZZ_S2B Mia Plan). Alle drei haben
   `akte_aktiv`, der Test-Coach sieht also ihre Akten-Daten (Entscheidung 26).
6. **Home Quests:** `home_quests_aktiv` gilt für alle Sessions. Die Anleitung schaltet sie vor dem Start an und als letzten
   Schritt wieder aus; das Prüfskript hat dafür Punkt 10.

## Entscheidungen Rasit (08.10.2026)

1. Tablet-Nummern 2 bis 5 (angelegt). Im Trockenlauf Tablet 2, 3, 4; 5 ist Reserve.
2. URLs: kamen als Platzhalter `<URL EINTRAGEN>` an. **Offen:** in `trockenlauf.md`, Abschnitt 2, eintragen.
3. Coach-Seite als Test-Coach („ZZ Test Coach“), der Coach der Session ist.
4. Drei Testkinder aus Klasse 8 (Befund 5).
5. Testlauf per SQL-Editor mit Admin-Claims; Schalter und Testlauf-Ausschluss (Befund 3) in T2.
6. Quest-Termin mittesten.
7. Prüffrage: Befund 2 bleibt.
