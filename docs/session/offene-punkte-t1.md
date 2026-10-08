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

## Befunde

1. **Kein Testlauf-Schalter für Coaching-Sessions.** `session_testlauf_setzen` gibt es, eine Oberfläche nicht
   (offene-punkte-x0, Offen 3). Der Trigger `coaching_sessions_testlauf_pruefen` verlangt Admin-Rolle, auch im SQL-Editor.
   Ohne Testlauf bucht der Abschluss XP und verbraucht Einheiten.
2. **Prüffrage im Trockenlauf nicht erreichbar.** Ohne Kandidat kein Knopf; der Lernpfad ist leer, und im Testlauf schreibt
   `antwort_abgeben` keine Belege.
3. **`mastery_entscheiden`, `pfad_tiefer`, `pfad_entscheiden` und `eingriff_notieren` prüfen `testlauf` nicht.** Sie schreiben
   in `lernpfad` bzw. `lernpfad_protokoll` mit der `session_id`. Heute ohne Wirkung (kein Kandidat, nur Testkinder), aber
   „Tiefer gehen“ oder ein Eingriff im Trockenlauf kann eine Lernpfad-Zeile erzeugen. Das Prüfskript meldet das als
   „nicht ok“ (Punkte 5 und 6). Ob die Funktionen den Testlauf ausschließen sollen, gehört in ein Schema-Paket (Entscheidung 27).
4. **Reihenfolge der Zielliste in Prod** beginnt mit der Steigung, weil keine Voraussetzung als sicher gilt (offene-punkte-a2d 1 a
   beschreibt den Fall mit vier sicheren Voraussetzungen). Welcher Skill die Kernarbeit eröffnet, entscheidet der Planer;
   das zeigt erst der Trockenlauf.

## Fragen an Rasit

1. Welche Tablet-Nummern (Vorschlag 2 bis 5)?
2. Prod-URL von Edvancev1 und URL bzw. Build der edvance-app für die Tablets?
3. Coach-Seite als Admin oder als Test-Coach?
4. Welche drei Testkinder?
5. Wie wird die Session zum Testlauf (SQL-Editor mit Admin-Claims oder ein kleines Folgepaket mit Schalter)?
6. Quest-Termin mittesten (`home_quests_aktiv` vorübergehend an)?
7. Prüffrage getrennt testen (Wegwerf-DB) oder Befund 2 so stehen lassen?
