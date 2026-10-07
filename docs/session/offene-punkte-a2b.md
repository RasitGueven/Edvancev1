# Offene Punkte A2b (Tablet-Daten, XP in der Session, Prüffrage aufs Tablet)

Stand 07.10.2026 · Branch `feat/rasit-session-a2b-tablet` · Entscheidungen 29 bis 36 (Rasit, 06./07.10.)

## Widersprüche zwischen Code und Entscheidung

1. **Erledigt (Rasit 07.10.): „Kein zweiter Versuch an derselben Aufgabe“ (29) erzwingt der Server.**
   `antwort_abgeben` lehnt jede zweite Antwort zu derselben Ausgabe und demselben Teil mit P0001 ab (Hinweis
   `schon_beantwortet`), auch nach einer falschen ersten. Die Prüfung steht vor der Bewertung, es entsteht keine
   Antwort, kein Beleg und kein Ereignis (`20261009104120_a2b_ein_versuch.sql`, pgTAP E).
   - Die R1-Tests 6 bis 8 haben jetzt je Versuch eine eigene Aufgabe (t3, t4). Sie prüfen weiter Fehlbild-Klartext,
     Hinweisstufen der Reihe nach und das Signal nach Fehlversuchen in Folge, jetzt über Aufgaben hinweg.
   - Das Signal „hängt“ und „nochmal erklären“ (F6) lösen auch über Aufgaben hinweg aus (pgTAP E).
2. **Erledigt (Rasit 07.10.): „Hinweise nur vor dem Abgeben“ (32) erzwingt der Server.** `hinweis_abrufen` lehnt mit
   P0001 ab (Hinweis `hinweis_nach_antwort`), sobald zu dieser Ausgabe eine Antwort vorliegt. Hinweise hängen in
   `task_solutions.hints` an der Aufgabe, nicht am Teil. Deshalb zählt bei MULTI_PART die erste Antwort auf
   irgendeinen Teil. „Dieselbe Ausgabe“ ist die jüngste Zeile in `session_ausgegeben` für Kind und Aufgabe.

## Auslegungen

3. **Ziel der Stunde vor der Wahl des Coaches.** `session_ziel_kind` liefert `fall: null`, kein Thema und keine
   Fertigkeiten, bis der Coach den Fall gewählt hat (Entscheidung 3: Vorschlag und Entscheidung getrennt; das Kind
   sieht nur die Entscheidung). Das Datum der Klassenarbeit, das das Kind selbst eingegeben hat, kommt immer mit.
4. **Ziel bei erreichtem Ziel.** Ist kein Skill mehr offen, beginnt die Liste beim letzten Skill (wie die
   „Vertiefung“ in A2, F7).
5. **„neu“ in `session_ziel_kind`:** keine Antwort in irgendeiner Session und kein Lernpfad-Beleg zum Skill. Im
   Testlauf, der keine Belege bucht, zählen die Antworten.
6. **Welche Prüffrage auf dem Tablet steht.** Gibt es zu einem Skill mehrere freigegebene Prüfungen, zeigt das Tablet
   die erste nach `angelegt` (dieselbe Reihenfolge wie `skill_pruefung_lesen` beim Coach). Eine bestimmte Frage
   wählen kann der Coach nicht; dafür bräuchte das Ereignis die `id` der Prüfung (C2).
7. **Prüffrage braucht ein aktives Tablet.** `pruefung_aufs_tablet` lehnt ohne Tablet mit P0001 (`kein_tablet`) ab.
   Ist das Kind kein Mastery-Kandidat, geht es trotzdem; ob die Oberfläche den Knopf nur bei Kandidaten zeigt,
   entscheidet C2.
8. **Abschluss nach `session_abschliessen`.** Der Coach-Abschluss gibt die Tablets frei. Danach liefert
   `session_abschluss_kind` 42501. Die App zeigt den Abschluss, solange `art = fertig` steht.
9. **XP und Sessions von vor A2b.** Eine Session, die vor dem Einspielen gestartet wurde, hat
   `session_xp_je_aufgabe` nicht im Snapshot; dann gilt der Wert aus `session_einstellungen` (`session_wert`).
   dbread 07.10.: keine laufende Session in Prod.
10. **XP: was „bearbeitet“ heißt.** Gezählt werden Schritte mit `art` aufgabe und exit, deren Aufgabe in jedem Teil
    eine Antwort hat (F4). Eingemischte Aufgaben zählen mit, Beispiele und Checks der Erklärsequenz nicht. Obergrenze
    1.000 XP je Buchung (`xp_buchen_intern`). Grund in `xp_events.reason`: `session` (Muster `home_quest`).
11. **Quest B setzt das System**, laut Entscheidung und Datenvertrag. Den Aufruf von `quest_erzeugen` und das
    Vorbelegen baut Q2; heute legt niemand Quests aus der Session an (offene-punkte-q1 3). Das Tablet bekommt den
    Tag in `session_kind_kontext.quest_termine.quest_b` nur zur Anzeige.
12. **Vorname des Coaches** ist das erste Wort aus `profiles.full_name` (dieselbe Quelle wie `coach_raum_live`).
13. **`tablet_stand.aufgabe`** bleibt im Ergebnis (R1). Laut Vertrag ist es nicht zur Anzeige da (Befund 6 aus A2).

## Consensus-Check (CLAUDE.md §8)

Zweite, unabhängige Instanz (Review-Agent, statisch über `git diff origin/dev..HEAD -- supabase/migrations`). Kein
Blocker, kein Rechte-Leck. Geprüft wurden:
- die Rechte der Tablet- und Coach-Funktionen sowie die NULL-Sicherheit;
- dass Prüffrage, Exit-Antwort und Schritt sparsam ans Tablet gehen;
- dass XP nur einmal gebucht werden (Schlüssel, Testlauf);
- dass in den ersetzten Funktionen außer den kommentierten Ergänzungen nichts verloren ging (diff gegen R1/A2);
- die Constraint-Änderung (Obermenge).

Befunde:

| Befund | Umgang |
|---|---|
| XP zählten Schrittzeilen statt Aufgaben (mittel) | behoben: `count(distinct task_id)` |
| Nach dem ersten „fertig“ erledigte Aufgaben werden nicht nachgebucht (niedrig) | so gewollt: gebucht wird einmal am Ende (Entscheidung 30); nach „fertig“ gibt die Engine keine Aufgabe mehr |
| `session_abschluss_kind` nach `session_abschliessen` 42501 (mittel) | Punkt 8; R2 hält den Abschluss, solange `fertig` steht |
| Prüffrage auch ohne Kandidatenstatus (niedrig) | Punkt 7, Entscheidung C2 |
| Sessions ohne Snapshot-Schlüssel nehmen den Live-Wert (niedrig) | Punkt 9 |
| Drop/Add des Check-Constraints sperrt kurz (niedrig) | in einer Transaktion, 0 laufende Sessions in Prod |

## Folgen für bestehende Dateien

14. **`docs/session/a2-durchlauf.sql`:** Ein Hinweis im Warm-up ist nach Entscheidung 32 nicht mehr möglich; die
    Zeile ruft jetzt ohne Hinweis.
15. **`supabase/tests/session_r1.test.sql`, Test 1** zählt jetzt 29 statt 28 Stellschrauben.
16. **`docs/api/DATENVERTRAG.md`** hat mit dem neuen Abschnitt 619 Zeilen. Der Auftrag verlangt den Abschnitt in
    dieser Datei; aufgeteilt ist sie deshalb nicht.

## Für C2

17. **Pruefrage am Coach:** `coach_raum_live.kinder[].pruefung_auf_tablet {skill_key, seit}`, dazu
    `pruefung_aufs_tablet`/`pruefung_vom_tablet` in `src/lib/supabase/sessionPruefung.ts`.
18. **Sessions, die nach ihrem Ende nicht abgeschlossen sind**, anzeigen (aus A2, offene-punkte-a2 16).
