# Offene Punkte C2 (Coach-Live-Sicht mit echten Daten, Briefing, Satz-Bausteine, Stellschrauben)

Stand 07.10.2026, Branch `feat/rasit-session-c2-coach-live`. Jeder Punkt: was, warum, wer löst ihn.

## Erledigt aus den Vorgängern

| Herkunft | Punkt | Wie |
|---|---|---|
| c1-3, r1-12 | Bausteinkatalog für den Satz | `session_satz_bausteine` + `satz_vorschlaege` (16 Bausteine, Liste im PR) |
| c1-8, r1-19 | Briefing („Vorher“) | `session_briefing` |
| c1-9 | Detail nur für die offene Schublade | `ladeRaumLive(sessionId, kindId)`; Vitest 6 |
| c1-10 | Fehler-Codes | `coachLiveFehler.ts`: Hinweis-Code vor SQLSTATE, Unbekanntes `allgemein` |
| c1-11 | Einstieg von der Coach-Startseite | `SessionsLive` auf `/coach` (Live-Sicht öffnen, Session starten) |
| a2-16, a2b-18 | Offene Sessions | `sessions_offen` (nur gestartete), Admin- und Coach-Startseite; nie gestartete nur als Zahl (`sessions_nicht_gestartet`) |
| a2b-7 | Prüffrage-Knopf nur bei Kandidaten | Knopf sitzt in der Mastery-Prüfung, die es nur für Kandidaten gibt; Vitest 7 |
| a2b-17 | Prüffrage am Coach | `pruefung_aufs_tablet` / `pruefung_vom_tablet`, Zustand aus `pruefung_auf_tablet` |
| Entscheidung 34 | Satz „… sieht das Abzeichen jetzt auf dem Tablet“ | entfernt (Schlüssel `mastery.siehtAbzeichen` gelöscht) |

## Offen

1. **Bausteine prüfen (Rasit, Fatih).** Die 16 Bausteine sind der Startkatalog (Liste im PR). allgemein/3
   („Rechenweg aufgeschrieben“) ist gestrichen (Rasit 07.10.): Das System weiß davon nichts. Ein CHECK verbietet
   Ziffern, `%`, „Prozent“, „richtig“, „falsch“ und „Fehler“ im Text; Zahlen kommen nur über `{anzahl}`. Ob
   „{anzahl} Aufgaben zu {skill} …“ (Anzahl, keine Quote) und der Mastery-Wortlaut („wirklich verstanden“) so
   bleiben sollen, entscheiden Rasit und Fatih. Eine Pflegeseite für den Katalog gibt es nicht; Änderungen gehen
   heute per SQL durch einen Admin (RLS: nur Admin). Wer: Rasit/Fatih, danach ggf. ein Folgepaket „Bausteine pflegen“.
2. **Satz-Regeln.** Rangfolge der Anlässe: Mastery bestätigt, Erklärsequenz geschafft, drangeblieben (falsch,
   später am selben Skill richtig), Hinweise genutzt bzw. selbstständig, Exit bearbeitet, geübt, allgemein. Innerhalb
   eines Anlasses wählt ein fester Versatz je Kind und Session (`hashtext`), damit nicht alle Kinder denselben Satz
   bekommen. Der Satz wird mit `abschluss_setzen(satz_text)` gespeichert; welcher Baustein es war, wird nicht
   gespeichert. Wer: Rasit, falls die Herkunft für Auswertungen gebraucht wird.
3. **Pfad-Vorschlag mit Zahlen.** Die Schublade zeigte in C1 einen Pfad-Vorschlag mit Warm-up-Zahlen, Fehlbild und
   Ziel-Skill. Das Signal `entscheidung` aus A2 trägt `skill_key`, `ziel_skill_key` und einen Satz, aber keine
   Zahlen. C2 zeigt den Vorschlag deshalb nicht als eigenen Block (`pfadVorschlag: null`); die Entscheidung geht
   weiter über die Warteschlange und die Interventionsleiter (Stufe 4). Wer: A2-Folgepaket liefert die Zahlen im
   Signal, dann bildet C2 sie ab.
4. **„Heute“-Zeilen und Grund des letzten Schritts.** `heute` bleibt leer; der Grund wird nur grob aus `grund_code`
   abgeleitet (über/unter Quote, eingemischt, tiefer). Die A2-Codes sind heute meist `kern`, `warmup` usw. ohne
   diese Unterscheidung. Wer: A2-Folgepaket, wenn die Schublade das braucht.
5. **Erklärsequenz.** `coach_raum_live` liefert nur Titel und Stand der aktuellen Kernidee. Die übrigen Kernideen
   erscheinen als „Kernidee n“. Das Fehlbild je Runde zeigt C2 nicht (nur der Slug liegt vor). Wer: E1/L6, falls
   gewünscht (Pflege der Erklärsequenz gehört L6; nicht selbst geändert).
6. **Mastery-Belege.** Die Belege kommen aus `lernpfad.belege` (direkt gelesen, RLS wie die Akte). Ohne Session-Belege
   steht keine Zeile. Ein Warm-up-Beleg von heute (Dummy: „Warm-up heute 3 von 3“) fehlt. Wer: C2-Folgepaket.
7. **Fach im Kopf** ist fest „Mathe“: `coaching_sessions` hat kein Fach, in Prod gibt es nur `mathematik`
   (offene-punkte-r1 Nr. 4). Wer: wenn ein zweites Fach kommt.
8. **Zeitpunkt der Seite** folgt der Uhr wie `session_uhr_phase` (Start plus Phasen aus dem Snapshot, nach 60
   Minuten „Danach“). Die Phasen im Kopf sind antippbar, „Abschluss“ springt nach „Danach“, „Live folgen“ zurück.
   Damit ersetzt eine kleine Ansichtswahl die Beispielleiste; der Coach kann Check-out und Abschluss vorziehen. Die
   Phasen der Kinder setzt weiter das Tablet. Wer: Rasit bestätigt beim Durchlauf.
9. **Nie gestartete Sessions (Rasit 07.10.).** „Offen geblieben“ zeigt nur gestartete Sessions (`active`) nach
   geplantem Ende plus 30 Minuten. Vergangene, nie gestartete Sessions zwingen niemanden zum Abschließen (das würde
   Einheiten verbrauchen); sie stehen nur auf der Admin-Startseite als Zeile „Nicht gestartet (n)“ mit Link zum
   Stundenplan, ohne Aktion (`sessions_nicht_gestartet`, nur Admin).
   **Testlauf-Regel (Rasit 07.10., wie X0 für die Zähler der Admin-Startseite):** Beide Listen lassen Sessions weg,
   die `testlauf = true` haben, kein gebuchtes Kind haben oder nur Testkonten (`ist_test`) gebucht haben; das gilt
   auch für die Coach-Startseite. Eine Session mit einem echten und einem Testkind zählt. **Die 7 Altfälle sind damit
   erledigt:** dbread 07.10. nach dieser Regel 0 (alle gebuchten Kinder sind Testkonten, eine Session ist leer).
10. **Testläufe** erscheinen weder unter „Offen geblieben“ noch unter „Nicht gestartet“ (Punkt 9). Einen
    vergessenen Testlauf sieht man nur im Stundenplan bzw. über den Link der Coach-Startseite am selben Tag.
11. **Quests der Woche im Briefing** zählen `verfallen` als „offen“ (Eltern sehen nur „erledigt“ oder „offen“,
    Entscheidung 21). Fenster: Termin bzw. Fälligkeit in den letzten sieben Tagen bis jetzt.
12. **Briefing ohne laufenden Vertrag** gilt auch für Admins: Das Briefing ist Akten-Lesen (Entscheidung 26). Ein
    Kind ohne Vertrag steht in der Live-Sicht, aber ohne Briefing-Zeilen.
13. **Satzvorschläge und Briefing im Zwischenspeicher** (60 s je Session bzw. je Kind), damit nicht alle 4 s fünf
    Aufrufe laufen. Nach „gemeistert“ wird der Satz des Kindes neu geladen.
14. **„Nicht erschienen“** bleibt Client-Zustand wie in C1 (offene-punkte-c1 Nr. 4): Er geht beim Neuladen der Seite
    verloren; der Server setzt beim Abschluss ohnehin jedes Kind ohne Tablet auf `unexcused`.
15. **Schema-Abzug.** `supabase/schema-erwartet.sql` ist laut Auftrag nicht angefasst. Der CI-Schemavergleich ist
    rot, bis der Abzug nach dem Einspielen kommt (Muster R1, offene-punkte-r1 Nr. 23).
16. **Migrationsversionen** `20261010110100`–`110400` liegen im Auftragsbereich und damit in der Zukunft (CLAUDE.md §10
    verlangt `date -u`). Vor dem PR per dbread geprüft: alle frei, `session_satz_bausteine`, `session_briefing`,
    `satz_vorschlaege`, `sessions_offen` gibt es in Prod nicht.
17. **`sessionRpc` gibt jetzt `code` und `hint` mit** (nur wenn die Datenbank sie liefert). `lernpfad.ts` ruft über
    `sessionRpc`. Andere Aufrufer sehen unverändert `{ data, error }`.
18. **CoachDashboard:** Beim Einbau von „Heute im Raum“ wurden die hartcodierten Texte nach `coach.json` verschoben
    (CLAUDE.md §12, gleicher Commit). Die übrigen Altlasten der Seite (Interventionen, Kurzprofil) sind unverändert.

## Consensus-Check (CLAUDE.md §8)

Zweite, unabhängige Instanz (Review-Agent, statisch über die Migrationen). Kein Blocker, kein Rechte-Leck.

| Befund | Umgang |
|---|---|
| Katalog ohne DB-Schutz gegen Quoten/Richtig-Lob (mittel) | CHECK `session_satz_bausteine_ohne_quote`; „richtig Arbeit“ umformuliert |
| Testlauf-Leck im Briefing nicht getestet (mittel) | pgTAP: abgeschlossener Testlauf mit Flag erscheint nicht |
| `verfallen` zählt als offen (mittel) | so gewollt, Punkt 11 |
| `abs(hashtext())` bei int-Minimum (niedrig) | `::bigint` |
| leerer Vorname (niedrig) | `nullif(btrim(...))` |
| `v_a` doppelt benutzt (niedrig) | eigene Variable `v_mastery` |
| `quest_b` je 4-s-Abfrage (niedrig) | Indizes vorhanden, höchstens 5 Kinder; beobachten |
| `naechste_luecke_core … limit 1` ohne `order by` (niedrig) | die Funktion liefert höchstens eine Zeile (jede Verzweigung `limit 1`, Prod-Definition) |
