# Offene Punkte A2c (Tablet-Lücken der Session-Familie)

Stand 07.10.2026, Branch `feat/rasit-session-a2c-tablet`. Belege: `supabase/tests/session_a2c.test.sql`,
`docs/session/a2c-tablet-erklaer.sql`, Abgleich der Tablet-Aufrufe im PR.

## Geschlossen in A2c

| Nr | Lücke | Lösung | Beleg |
|---|---|---|---|
| G1 | `erklaer_start` und `erklaer_check_abgeben` verlangten `p_student_id`, das Tablet kennt es nicht. | `p_student_id = null`: Kind aus `session_tablet_platz`, sonst wie bisher `erklaer_zugang`. | Migration `20261010100426`, Tests 1 und 2 |
| G2 | `erklaer_nachlesen(p_student_id, …)` ebenso. | `null`: Kind des aufrufenden Tablets in seiner laufenden Session, sonst 42501. | Migration `20261010100426`, Tests 1 bis 3 |
| G3 | `hinweis_abrufen`: Das Tablet kennt `hinweisstufen` nicht. Ob eine weitere Stufe folgt, sah es nur am Fehler, und der hatte keinen Hint (Vertrag 8.2 sagte anderes). | Antwort mit `weitere`, Fehler mit Hint `stufe_gesperrt`. | Migration `20261010100731`, Test H |
| G4 | Vertrag: `quest_termin_setzen` braucht `p_student_id: null` ausdrücklich. Termin-Tage veralten, wenn Home Quests erst nach der Zuweisung angehen. | Nur Doku (Datenvertrag 8.2). | Audit im PR |
| G5 | Vertrag: Ablehnen eines Erklärungsangebots geschieht implizit; Wiederaufnahme der laufenden Sequenz. | Nur Doku (Datenvertrag 8.1, Punkte 5 und 6). | Audit im PR, Beispiel 26 |
| G6 | Nachtrag R2: Der Warte-Bildschirm braucht die Tablet-Nummer vor der Zuweisung; `tablet_stand` gab nur `{zugewiesen: false}`. | Platz-Konto ohne Zuweisung bekommt `tablet_nr` des eigenen Geräts (oder null), alle anderen Konten nicht. | Migration `20261010100855`, Test T |

## Offen

1. **Kein Default für `p_student_id`.** Der Auftrag wollte „nur ein Default null“. Das geht nicht: Nach
   `p_student_id` folgen Parameter ohne Default (`p_skill_key`, `p_check_task_id`, `p_eingabe`). Ein Default
   würde Defaults für alle folgenden Parameter verlangen, und das würde die Signatur ändern. Das Tablet schickt
   deshalb `p_student_id: null` ausdrücklich mit, wie schon bei `quest_termin_setzen`. Entscheidung Rasit:
   Reicht das, oder soll später eine Tablet-Fassung ohne den Parameter kommen (eine neue Überladung)? Vorsicht
   dabei: siehe Memory „RPC-Name vorher prüfen“, eine Überladung macht bestehende Aufrufe mehrdeutig.
2. **`verfuegbar: false` zählt als abgerufen.** Eine Stufe ohne geprüften Hinweis bucht trotzdem das Ereignis.
   Die nächste Stufe ist also frei. A2c dokumentiert das nur (Vertrag 8.2). Ob eine leere Stufe übersprungen
   werden soll, entscheidet die Pädagogik.
3. **Planer im Testlauf mit Bestandsaufgaben zur Steigung.** Im Beispiel sprang `session_naechster_schritt`
   nach der fertigen Sequenz zu `fkt_linear_steigung` nicht zum Lösungsbeispiel. Stattdessen kam
   `fkt_linear_yabschnitt` mit `pool_leer`. Die 12 Bestandsaufgaben zur Steigung sind `draft`, ohne
   `difficulty`. Mit 15 ZZ-Aufgaben (`ready`) kommt wie erwartet `neu_beispiel`. Die Ursache ist nicht
   untersucht; sie liegt in der Engine (`session_plan_kern`), nicht auf der Tablet-Seite. Für einen ehrlichen
   Testlauf mit echten Inhalten sollte das vor E2a geklärt sein.
4. **Edvancev1-Wrapper für die Erklärsequenz fehlen.** `src/lib/supabase/sessionTablet.ts` hat
   `hinweisAbrufen` (Typ jetzt mit `weitere`), aber keine Wrapper für `erklaer_start`, `erklaer_check_abgeben`
   und `erklaer_nachlesen`. Die App (edvance-app, R2/E2a) ruft direkt; in Edvancev1 braucht sie heute keine
   Oberfläche. Nachziehen erst, wenn eine Edvancev1-Fläche sie braucht.
5. **`erklaer_nachlesen` im Testlauf** zeigt weiter nur freigegebene Inhalte (offene-punkte-a2 Befund, bewusst
   so). Bei einem Testlauf mit Entwürfen bleibt `kernideen` dann leer.
