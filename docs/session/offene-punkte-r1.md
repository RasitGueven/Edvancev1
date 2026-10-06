# Offene Punkte R1 (Session-Datenmodell)

Stand 06.10.2026, Branch `feat/rasit-session-r1-datenmodell`. Jeder Punkt: was, warum, wer löst ihn.

## Abweichungen und Entscheidungen im Code

1. **Status-Werte bleiben `upcoming / active / done`.** Der Auftrag nennt „geplant, laeuft, abgeschlossen“ und sagt
   „bestehende Werte erhalten“. dbread 06.10.: done 65, upcoming 7, active 0. Gelesen werden die Werte in
   `src/types/session.ts:14` und `src/lib/coachKennzahlen.ts:15`. R1 benutzt sie mit der Bedeutung
   upcoming = geplant, active = laeuft, done = abgeschlossen (Kommentar in `20261007110200_session_ablauf.sql`).
   Umbenennen nur, wenn Rasit das will; dann mit Datenmigration und den beiden Lesern.
2. **Migrationsversionen** stehen im Bauauftrag-Bereich `2026100711xxxx`. Das widerspricht CLAUDE.md §10
   (`date -u`, keine Zukunftsversionen; heute ist der 06.10.). Der Bauauftrag ist maßgeblich und hält die Pakete
   X0 → R1 → A1 → E1 → Q1 auseinander. Folge: Eine Migration, die nach R1 laufen muss, braucht eine Version ab
   `20261007110801`.
3. **Neues Schulthema aus der Session.** Entscheidung 9 verlangt: altes Thema „behandelt“. Der Weg des
   Erstgesprächs (`lead_thema_setzen`, `20261004001333_lead_thema_setzen.sql:39-43`) **löscht** das alte
   „aktuell“ und ist nur für Admins. R1 ruft ihn deshalb nicht, sondern schreibt in `checkin_coach_setzen`
   denselben Upsert auf `(lead_id, thema_key)` mit `quelle = 'gespraech'` und stellt das alte auf „behandelt“.
   `lead_themen_quelle_check` kennt keine Quelle „session“; eine eigene Quelle wäre eine Constraint-Änderung.
   Zu klären: Soll auch das Erstgespräch das alte Thema auf „behandelt“ setzen statt es zu löschen?
4. **Fach.** `coaching_sessions` hat kein Fach. Das Schulthema eines Kindes ist das jüngste „aktuell“ über alle
   Fächer; beim Schreiben kommt das Fach aus `themen.fach`. In Prod gibt es nur `mathematik` (dbread 06.10.).
5. **Kind → Lead:** `coalesce(students.lead_id, leads.converted_student_id)`. dbread 06.10.: 14 Kinder über
   `lead_id`, 11 über `converted_student_id`, 1 von 26 ohne Lead. Für dieses Kind bricht ein Themenwechsel mit
   `P0002` (`hint kein_lead`) ab; Fall und Check-in gehen trotzdem.
6. **Abschluss setzt `planned` → `unexcused`.** Wer bis zum Abschluss kein Tablet bekam, gilt als nicht
   erschienen und verbraucht nach `einheit_verbraucht` die Einheit (Schülerakte, Entscheidung 4/5). Abgesagte
   Kinder müssen vorher auf `cancelled`/`cancelled_by_us` stehen; dafür gibt es weiter keinen Schreiber (R0
   Frage 5). **Bitte bestätigen.**
7. **Flags und Notiz in der Akte** gehen über `notiz_anlegen` (Wortliste, Coach nur in aktive Akten, audit_log).
   Die Flag-Notiz hat einen festen Text („Session TT.MM.JJJJ: Elternkontakt nötig“ / „…: Pfad passt nicht“).
   Das ist Datenbank-Inhalt, kein Frontend-String. Der offene Zustand der Flags steht in
   `session_kind_abschluss` und kommt über `session_flags_offen()`.
8. **Eingriffe ab Stufe 3** stehen nach dem Abschluss in `session_kind_abschluss.zusammenfassung`, nicht als
   Notiz. Eine Lesefunktion für die Akte (Kachel „Sessions“, `SessionsKachel.tsx:24-26`) fehlt noch: Folgepaket
   Akte bzw. P2.
9. **`interventions` wird nicht benutzt.** Eingriffe sind `session_ereignisse` vom Typ `eingriff` (Auftrag Punkt 7).
   Die Tabelle bleibt mit dem alten CoachDashboard Altlast (C0 Abschnitt 5).
10. **Ergebnis an das Tablet.** `antwort_abgeben` liefert `ergebnis` (Auftrag Punkt 6). CLAUDE.md §6 sagt
    „Kind-seitig niemals visuelles Feedback, ob richtig/falsch“. Wie das Tablet es zeigt, entscheidet P2.
11. **Hinweis-Reihenfolge** (Stufe 2 erst nach Stufe 1) wird nicht erzwungen, nur die Obergrenze `hinweisstufen`.
12. **Satz an das Kind** ist in R1 Freitext des Coaches. Der feste Bausteinkatalog (Entscheidung 12) kommt mit C2.

## Verdrahtung mit anderen Paketen (P2)

13. **X0 Testlauf:** `coaching_sessions.testlauf` gibt es erst mit X0. Dann ausschließen: Notizen und Flags im
    Abschluss, `session_flags_offen`, Einheiten (Anwesenheit), Lernpfad-Belege. Bis dahin offen.
14. **X0 Einsatz:** `aufgabe_ausgeben` prüft nur `status = 'ready'`. Mit X0 zusätzlich `'session' = any(einsatz)`,
    im Testlauf auch draft/review/rueckfrage mit leerem `pruef_ausschluss`.
15. **A1 Auswahl und Lernpfad:** `aufgabe_ausgeben` ist der Platzhalter für die Auswahl (Coach, Admin oder
    Systemaufruf). Ziel bei Fall „lernpfad“ ist `null`, bis `naechste_luecke` (A1) es liefert. Stufe 4 und
    `pfad_entscheiden` schreiben nur `entscheidung_pfad`; `pfad_tiefer` ruft P2. Belege je Antwort
    (`lernpfad_beleg`) ruft P2 aus `antwort_abgeben`. Mastery-Kandidaten meldet A1 über `signal_melden(…,
    'kandidat', …)`; `mastery_kandidat` und `mastery_bestaetigt` in `coach_raum_live` sowie
    `zusammenfassung.mastery_entscheidungen` sind Platzhalter.
16. **E1 Erklärsequenz:** `erklaersequenz` in `coach_raum_live` ist ein Platzhalter. Das Signal
    `erklaerrunden_bis_signal` zählt falsche `check`-Ereignisse je `payload.kernidee`; E1 schreibt
    `erklaer_fortschritt`. P2 muss entweder `check`-Ereignisse schreiben oder die Signal-Abfrage auf
    `erklaer_fortschritt` umstellen.
17. **E1 Hinweis-Status:** `hinweis_abrufen` liefert nur Hinweise mit `status = 'geprueft'`. dbread 06.10.: 0 von
    186 Hinweisen haben einen Status. Bis E1 bekommt ein Kind in Prod also nie einen Hinweis.
18. **Q1 Quests:** `quest_termin` wird nur gespeichert (Zukunft Pflicht). Q1 liest ihn in P2.
19. **C2 Briefing („Vorher“):** Es gibt keine Briefing-Funktion. Die Daten liegen verteilt (lead_themen,
    schueler_notizen, letzter Check-in, Antworten früherer Sessions, A1, Q1). Siehe Dummy-Abgleich.

## Betrieb

20. **Geräte:** In Prod gibt es ein Gerät („Platz 1“, wird Tablet 1). Tablets 2 bis 5 müssen als `platz_devices`
    mit `tablet_nr` angelegt werden. `tablet_nr` ist global, nicht je Raum; zwei Räume gleichzeitig brauchen
    verschiedene Nummern (Spalte erlaubt 1–99, die Session 1–5).
21. **LSA und Session am selben Gerät:** `tablet_zuweisen` lehnt ein Gerät mit laufender LSA-Zuweisung ab.
    Umgekehrt prüft `platz_assign` (LSA, unverändert laut Auftrag) `session_tablets` nicht.
22. **App:** `tablet_stand()` ist die Kiosk-Abfrage für den Session-Modus. Die Weiche in der App (LSA oder Session)
    baut P2. `edvance-app/src/types/database.ts` muss nach dem Einspielen neu erzeugt werden.
23. **Schema-Abzug:** `supabase/schema-erwartet.sql` ist laut Auftrag nicht angefasst. Der CI-Schemavergleich ist
    rot, bis der neue Abzug nach dem Einspielen kommt.

## Aus dem Consensus-Check (CLAUDE.md §8)

Behoben im selben PR: Kaskaden-Löschen von Rohdaten durch den Coach (Lösch-Trigger an `coaching_sessions` und
`session_students`), Abschluss scheitert nicht mehr an einer inaktiven Akte (Kind steht dann in
`nicht_in_akte`), Mastery-Kandidaten nur als Systemaufruf, Hinweisstufen der Reihe nach, Quest-Termin höchstens
14 Tage, `for update` im Abschluss, Guard-Flag nach dem Update zurückgesetzt, Tablet-Nummer 1–5 mit eigener Meldung.

Offen:

24. **`ka_tage` mit `<=`:** Eine Klassenarbeit genau `ka_tage` Tage nach der Session zählt noch (bei 0: nur am
    selben Tag). Die Tabelle sagt „näher liegt als“. Bitte bestätigen oder auf `<` stellen.
25. **Mehrere Kandidaten je Kind** werden in `raum_signale` auf das älteste Signal zusammengefasst
    (`distinct on (student_id, art)`). A1/P2 fächert nach `skill_key` auf.
26. **Snapshot sichtbar:** Schüler und Eltern lesen `coaching_sessions` über die bestehenden Policies mit
    `select *` und sehen damit auch `einstellungen`, `gestartet_am`, `beendet_am`. Inhaltlich harmlos.
27. **Tablet-Robustheit:** Das Kind kann am eigenen Tablet zwischen den Phasen wechseln (`phase_setzen`). Es gibt
    keine Mengenbegrenzung für Ereignisse und Eingaben. Für P2 prüfen.
28. **Hinweis-Status-Schreibweise:** R1 erwartet `status = 'geprueft'` im Hinweis-Objekt. E1 muss genau diese
    Schreibweise setzen.
