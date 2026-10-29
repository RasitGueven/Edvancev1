# R1 · Lenas Rückfragen – Bericht (29.10.2026)

6 Aufgaben im Status `rueckfrage` (Bestand: `bestand.md`, Begründung: `einordnung.md`). Ergebnis: **3 × A, 1 × B,
2 × C**. A und B sind freigegeben, C wartet auf Rasits Entscheidung. Keine Aufgabe gelöscht, `einsatz` bleibt
überall `{lsa}`.

Eingespielt: `20261029091200_r1_lena_rueckfragen` (Zielprüfung `current_database() = postgres`, Versionsprüfung,
`~/bin/mig`, History-Eintrag in derselben Kette). Freigabe: `tools/r1-freigeben.sql`, eine Transaktion als Rasit
(Claims `sub` = Rasits Profil, `role` authenticated) über `pruef_rueckfrage_klaeren(…, 'freigeben', …)`.
Prüfung danach `~/bin/dbread -f supabase/checks/r1_rueckfragen.PRUEFUNG.sql`: P1–P5 ok.

## Je Aufgabe

| # | id | Lenas Frage | Klasse | Änderung | Status danach |
|---|---|---|---|---|---|
| 1 | `8c4a2d71` | Text: „anhand der binomischen Formeln … für x = 100 ein“ | A | Text „Vereinfache den Term zuerst anhand der binomischen Formeln und setze dann für x den Wert 100 ein.“; „+1029“ in correct_answers und equivalents | ready |
| 2 | `a61e8be9` | Kennen Kinder in 7/8 f(x)? „an der Stelle x = 4“ | C | keine | rueckfrage |
| 3 | `ffc76634` | x und y bei Steigung und Einsetzen vertauscht | A | known_errors: 2/3 dezimal (0,6 / 0,66 / 0,666 / 0,67 / 0,667 / 0,7), 6 / +6 → `steigung_kehrwert`; −18 (3 Schreibweisen) → `koordinaten_vertauscht`; typical_errors: Kehrwert-Text nennt b = 6 und „beides vertauscht“, neuer Eintrag für −18 | ready |
| 4 | `1bbce78e` | wie 2 | C | keine | rueckfrage |
| 5 | `158c874c` | Kind stellt nach y statt nach x um | B | keine | ready |
| 6 | `6274f6a5` | Kind nimmt die Dreiecksformel | A | known_errors: 30, 60 → `teilflaeche_vergessen`; 65, 156 → `falsche_hoehe`, je 6 Schreibweisen (24 Schlüssel); typical_errors: falsche_hoehe-Eintrag erweitert, teilflaeche_vergessen neu | ready |

## Antworten an Lena (stehen in `task_pruefungen.antwort`, von Rasit)

- **8c4a2d71:** Danke, übernommen! Da steht jetzt „Vereinfache den Term zuerst anhand der binomischen Formeln und setze dann für x den Wert 100 ein.“ Aus „für x = 100“ haben wir „für x den Wert 100“ gemacht, das liest sich glatter. Außerdem zählt jetzt auch „+1029“ als richtig. Freigegeben.
- **ffc76634:** Danke, guter Punkt! Vertauscht ein Kind x und y bei der Steigung und beim Einsetzen, kommt m = 1/3 und b = 2/3 heraus (A(1 | 1) bleibt beim Vertauschen gleich). Das war schon als Fehler „Steigung auf dem Kopf“ hinterlegt, jetzt auch dezimal (0,67 usw.). Neu dazu: Nur beim Einsetzen von B vertauscht gibt b = −18 (Fehlerbild „x und y vertauscht“), nur bei der Steigung vertauscht und dann B eingesetzt gibt b = 6. Freigegeben.
- **158c874c:** Danke für den Hinweis! Stellt ein Kind nach y um, kommt trotzdem x = 5 und y = 3 heraus, das Gleichungssystem hat nur diese eine Lösung. Getippt wird nur das Ergebnis, das Kind verliert also nichts. An der Aufgabe ändern wir deshalb nichts. Dein AFB I bleibt. Freigegeben.
- **6274f6a5:** Danke, guter Punkt! Nimmt ein Kind die Dreiecksformel mit beiden Diagonalen (24 · 10 : 2), kommt genau 120 heraus, denn die Raute besteht aus zwei solchen Dreiecken. Neu hinterlegt haben wir: nur ein Dreieck gerechnet (60, bei einem Viertel 30) und die Dreiecksformel mit der Seite 13 (65 oder 156). Dein AFB I bleibt. Freigegeben.

## Klasse C: zur Entscheidung für Rasit

**a61e8be9 (f(4), m = 3, b = −2) und 1bbce78e (f(3), m = −2, b = 5).** Lena fragt, ob Kinder in Klasse 7/8 die
Schreibweise f(x) kennen. Das betrifft nicht nur diese zwei: Im LSA-Bestand der `fkt_linear_*`-Skills nutzen auch
zwei freigegebene Aufgaben und sechs Entwürfe f(…). Deshalb sollte es eine Entscheidung für alle geben.

- **Vorschlag (empfohlen):** f behalten und eine Brücke in den Text setzen: „… und berechne damit f(4), also den
  Funktionswert an der Stelle x = 4.“ Das passt, wenn f(x) im Unterricht der Klasse 8 eingeführt ist (habe ich nicht
  geprüft, Lena kennt die Schulpraxis).
- **Alternative nach Lena:** ohne f, „… und berechne damit den y-Wert an der Stelle x = 4.“
- Beides ändert nur Text (keine Zahl, keine Wertung). Danach `pruef_rueckfrage_klaeren(…, 'freigeben', …)` wie oben.

## Hinweise

- **Bauformen mit Status rueckfrage:** keine (Phase 0).
- **158c874c:** Lenas AFB-Änderung II → I steht in `tasks.afb`, die beiden Teile in `tasks.parts` tragen weiter
  `afb: II`. Nicht Teil von Lenas Frage, in R1 nicht angefasst.
- **Zweitprüfung** (frischer Agent, nur alt/neu und Lenas Notizen): Mathematik und Schlüssel ohne Befund. Zwei
  Hinweise übernommen: ein Eintrag je Fehlbild in typical_errors (falsche_hoehe war doppelt), der Fall „beides
  vertauscht“ steht jetzt im Kehrwert-Text. Nicht übernommen (unkritisch): „+0,67“ usw. mit Plus.
- **Nebenbefund:** „–2“ (Halbgeviertstrich) ist bei ffc76634 im Urteil voll, aber nicht in correct_answers. Das gilt
  für den ganzen Bestand (Konvention `-v`, `−v`, `- v`) und ist keine Sache dieser Rückfrage.
- **Belege:** Wegwerf-DB `tools/r1-wegwerf-db.sh` (Prod-Fixture, eigener Cluster): Migration, Prüfskript, Freigabe,
  zweiter Lauf ändert nichts, Rollback stellt den Inhalt wieder her. Leerer Bestand (CI-Neuaufbau): jeder Block 0 Zeilen.
  Rollback: `supabase/rollback/20261029091200_r1_lena_rueckfragen.sql`.
