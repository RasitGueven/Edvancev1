# Offene Punkte A2 (Session-Engine)

Stand 06.10.2026 · Branch `feat/rasit-session-a2-engine` · Entscheidungen A bis O (Rasit, 06.10.)

## Annahmen für Fatih

Die Annahmen bleiben für Fatih offen (Rasit 06.10.). Als Annahme markiert waren G und H. Die übrigen Punkte hat A2 selbst festgelegt, weil die Entscheidungen sie offen
lassen. Jeder Punkt nennt die Stelle im Code.

| Nr. | Annahme | Wo |
|---|---|---|
| F1 | **Fenster der Steuerung (H):** ausgewertet werden die letzten 5 erledigten Aufgaben des Skills in dieser Session seit der letzten Auswertung. Nach jeder Auswertung (+1, −1 oder „hängt“) beginnt das Fenster neu. Auf Stufe 5 bleibt es bei 5. | `session_niveau` |
| F2 | **Startniveau (H):** Schwierigkeit der zuletzt richtig gelösten Aufgabe des Skills aus einer früheren Session oder der LSA (ohne Testlauf), sonst 2. | `session_niveau` |
| F3 | **„hängt“ (H):** Auf Stufe 1 und weiter unter der Zielquote geht je Auswertung ein Signal an den Coach. Daneben bleibt das R1-Signal nach `signal_fehlversuche` Fehlversuchen in Folge. | `session_plan_kern` |
| F4 | **Erfolg einer Aufgabe:** alle Teile beim ersten Versuch richtig, ohne Hinweis. Eine Aufgabe ist **erledigt**, sobald jeder Teil eine Antwort hat. Danach gibt die Engine die nächste Aufgabe, einen zweiten Versuch über die Engine gibt es nicht. **Seit A2b auf dem Server erzwungen (Rasit 07.10.):** `antwort_abgeben` lehnt eine zweite Antwort ab, `hinweis_abrufen` jeden Hinweis nach der Antwort. Ändert Fatih die Annahme, müssen Server und App beide angepasst werden. | `session_aufgabe_stand`, `antwort_abgeben` |
| F5 | **Modus (G):** geführt, bis das Kind irgendwann eine Aufgabe des Skills richtig ohne Hinweis gelöst hat (über alle Sessions), danach selbstständig. | `session_modus` |
| F6 | **„Nochmal erklären“ (G):** nur, wenn der Skill eine freigegebene Erklärsequenz hat. Gezählt werden Fehlversuche in Folge seit dem letzten Angebot bzw. der letzten Erklärung. Lehnt das Kind ab (nächster Aufruf ohne Sequenz-Start), kommt das nächste Angebot erst nach neuen Fehlversuchen. War die Sequenz in dieser Session schon durch, heißt der Weg `nachlesen` (`erklaer_nachlesen`, Variante A ohne Checks): E1 startet eine abgeschlossene Sequenz in derselben Session nicht neu. | `session_plan_kern` |
| F7 | **Heute sicher:** Ein Skill zählt in der Session als sicher, wenn er so oft richtig ohne Hinweis gelöst wurde wie `mastery_richtig_ohne_hinweis` (Regel 2 in `lernpfad_beleg_core`). Dann rückt der aktuelle Skill weiter. Das gilt auch im Testlauf, der keine Belege bucht. Sind alle Skills des Ziels sicher, übt das Kind den letzten weiter („Vertiefung“). | `session_heute_sicher`, `session_schritt_planen` |
| F8 | **Warm-up-Fehler machen den Pfad nicht von selbst tiefer.** Eine Voraussetzung, deren Lernpfad-Stand sich erst in dieser Session geändert hat (Warm-up-Belege machen sie `noch_nicht_sicher` bzw. `aktiv`), bleibt zurückgestellt, bis der Coach „eine Stufe tiefer“ entscheidet (Entscheidung 10). | `session_zielliste` |
| F9 | **Warm-up:** bleibt beim Skill der vorigen Warm-up-Aufgabe, solange er Aufgaben hat. Nach `warmup_aufgaben` Aufgaben beginnt die Kernarbeit sofort, auch vor dem Ende des Warm-ups laut Uhr. Ist ein Entscheidungssignal offen, wartet das Kind, aber höchstens bis die Uhr die Kernarbeit beginnt; danach geht es beim Plan weiter. | `session_plan_warmup` |
| F10 | **Check-in kommt immer zuerst**, auch beim späten Kind. Die Engine antwortet bis dahin mit `warten`. Wer den Check-in vor Minute 5 fertig hat, beginnt sofort mit dem Warm-up (Dummy: „startet von selbst“). | `session_schritt_planen` |
| F11 | **Reihenfolge im Pool:** zuerst die Schwierigkeit, die am nächsten liegt, dann ungesehen vor gesehen, dann die am längsten nicht gesehene (J nennt nur „ungesehen vor gesehen“, H verlangt die Stufe). | `session_aufgabe_waehlen` |
| F12 | **Ein Beispiel ist gesehen**, sobald das Tablet den nächsten Schritt holt. Ein Beispiel-Item kommt bei diesem Kind nie als Aufgabe, auch nicht in späteren Sessions. | `session_plan_kern`, `session_aufgabe_waehlen` |
| F13 | **Mischen:** Kandidaten sind sichere Skills aus dem Lernpfad (in der ersten Session die LSA-Urteile „trägt“), Voraussetzungen des Ziels zuerst, dann die am längsten nicht geübten. Einführungsaufgaben nach einem Beispiel zählen nicht im Zähler. Findet sich kein Kandidat mit Aufgabe, bekommt der Platz eine normale Aufgabe. | `session_misch_kandidaten`, `session_plan_kern` |
| F14 | **Exit-Aufgaben:** zum zuletzt in der Kernarbeit geübten Skill (nicht eingemischt), sonst zum aktuellen Skill. Ergebnis = Exit-Aufgaben mit richtiger Antwort von allen gegebenen. | `session_plan_checkout` |
| F16 | **Schwierigkeit aus dem AFB (Rasit 06.10.):** In der Auswahl gilt `coalesce(difficulty, AFB I → 2, II → 3, III → 4, sonst 2)`. Die Daten bleiben unverändert. dbread 06.10.: `difficulty` bei 0 von 1.183 gefüllt, `afb` bei 1.018 (86 %). Auch das Startniveau (F2) rechnet so. | `session_schwierigkeit` |
| F15 | **Lernpfad-Fall:** Das Ziel ist genau ein Skill (`naechste_luecke`). `ziel_thema_key` zeigt nur zur Anzeige dessen Thema. | `session_zielliste`, `session_checkin_ableiten` |

## Widersprüche und Befunde

1. **`tasks.difficulty` ist in Prod überall leer.** dbread 06.10.: 1.183 von 1.183 Aufgaben ohne `difficulty`,
   `afb` bei 1.018 gefüllt (I 491, II 442, III 85). **Entschieden (Rasit 06.10.):** Rückfall auf den AFB in der
   Auswahl (F16). 165 Aufgaben ohne AFB zählen als Stufe 2; Pflege der Schwierigkeiten bleibt Inhaltsarbeit.
2. **In Prod gibt es keine freigegebene Session-Aufgabe mit Skill.** dbread 06.10.: 13 Aufgaben `ready`, alle ohne
   `skill_key`. 870 Entwürfe haben einen Skill. Außerhalb des Testlaufs antwortet die Engine deshalb mit
   `warten` / `pool_leer`. Im Testlauf laufen Entwürfe mit leerem `pruef_ausschluss`.
3. **Keine Erklärsequenz in Prod** (dbread: 0 Kernideen). Bis Inhalte freigegeben sind, beginnt jeder neue Skill mit
   Beispiel und Aufgabe, und der Grund nennt „keine Erklärung vorhanden“.
4. **`ka_tage` und Mischen. Erledigt (Rasit 06.10.):** Text in `session_einstellungen`
   (`20261008124415_a2_ka_tage_text.sql`) und in der Stellschrauben-Tabelle des Bauauftrags: „Klassenarbeit zählt, wenn
   sie höchstens so viele Tage entfernt ist (einschließlich); gemischt wird dann nur im Thema der Klassenarbeit“.
5. **`phase_setzen` durch den Coach** schreibt weiter ein Phasen-Ereignis. Die Engine richtet sich beim nächsten
   Schritt aber nach der Uhr (C). Ob der Coach die Phase eines Kindes übersteuern darf, ist nicht entschieden.
6. **`tablet_stand`** zeigt beim Beispiel noch die vorige Aufgabe, weil ein Beispiel keine Ausgabe in
   `session_ausgegeben` ist. Die App nimmt den Schritt aus `session_naechster_schritt` (R2).
7. **Mehrere Mastery-Kandidaten je Kind:** A2 meldet je Skill ein Ereignis. `raum_signale` fasst je Kind zusammen
   (offene-punkte-r1 25). `coach_raum_live.mastery_kandidat` zeigt den ältesten fälligen.
8. **Q1-Funktionen ersetzt** (`quest_einstellung`, `quest_einstellung_zahl`, `home_quests_aktiv` per drop/create mit
   neuem Parameter). Ihre Kommentare aus Q1 sind dabei entfallen (Datei an der 400-Zeilen-Grenze); Inhalt steht im
   Kopf von `20261008124413_a2_verdrahtung_q1.sql`.
9. **Migrationsversionen** `20261008121014`–`…124413` liegen im Bauauftrags-Bereich und damit in der Zukunft
   (CLAUDE.md §10 verlangt `date -u`). Vor dem PR per dbread geprüft: alle frei.
10. **Lokale pgTAP-Altlasten:** `inv1_mastery_gate` und `inv10_lsa_thema_auswahl` sind in der Wegwerf-DB rot,
    identisch auch ohne die A2-Migrationen (Vergleichs-DB). Nicht in `bekannt-rot.txt`; vermutlich Seed-Daten der CI.
11. **E1-Test 5d** erwartete beim Löschen einer Session den Fremdschlüssel von `erklaer_fortschritt`. Seit A2 schreibt
    `erklaer_check_abgeben` auch `session_ereignisse`; welcher restrict-Schlüssel zuerst greift, ist nicht festgelegt.
    Der Test akzeptiert beide.

12. **Belege je Teil.** Bei MULTI_PART bucht jede Teil-Antwort einen Beleg (Entscheidung L: „jede Antwort“). A1 zählt
    für den Mastery-Kandidaten Belege, nicht Aufgaben; eine Aufgabe mit zwei Teilen kann so allein zwei Belege liefern.
    Die Engine selbst zählt „heute sicher“ je Aufgabe (Consensus-Check, Befund 2). Ob A1 je Aufgabe zählen soll,
    entscheidet Rasit.
13. **Einsatz `check` und bestehende Inhalte.** `erklaer_checks` nimmt nur noch Aufgaben mit `check` im Einsatz.
    dbread 06.10.: 0 Zeilen in `erklaer_check`, es fällt also nichts weg. Neue Check-Aufgaben brauchen `{check}`.
14. **Testläufe und frühere Antworten.** Modus, Startniveau und „neuer Skill“ lesen Antworten aus allen Sessions des
    Kindes, auch aus Testläufen. Testläufe gibt es nur mit Testkonten (Entscheidung 27), echte Kinder sind nicht
    betroffen.
15. **Polling ohne Bestätigung.** Ein Beispiel und ein Erklärungsangebot gelten beim nächsten Aufruf als erledigt (F6,
    F12). Lädt die App neu, bevor das Kind das Beispiel gesehen hat, ist es übersprungen. Ein eigener
    Bestätigungsaufruf wäre robuster; Entscheidung mit R2.

16. **Zeitbindung der Coach-Entscheidungen (zweiter Consensus-Check, Commit 40e97ce, kein Blocker).**
    - **Erledigt (Rasit 06.10.):** „Laufend“ zählt nur bis zum geplanten Ende plus 30 Minuten Nachbereitung, danach nur
      noch „heute abgeschlossen“. Geplantes Ende = `scheduled_at` + 60 Minuten: `coaching_sessions` hat keine Dauer-
      oder End-Spalte (dbread 06.10.: Spaltenliste; `slots` hat nur `start_time`, 0 von 72 Sessions mit Slot), die
      Dauer kommt aus Entscheidung 1 („Eine Session dauert 60 Minuten“), wie bei `session_uhr_phase`. Sollen Sessions
      eine eigene Dauer bekommen, braucht es eine Spalte.
    - **Offen für C2 (Rasit 06.10.):** Sessions, die nach ihrem Ende nicht abgeschlossen sind, auf der
      Admin-Startseite und in der Coach-Sicht anzeigen.
    - `lernpfad_beleg` (manueller Beleg durch den Coach) hängt an derselben Bindung.
    - `erklaer_nachlesen` zeigt auch am Tablet im Testlauf nur freigegebene Inhalte (zuhause-Funktion, bewusst so).

## Consensus-Check (CLAUDE.md §8)

Zweite, unabhängige Instanz (Review-Agent, statisch über `git diff origin/dev..HEAD -- supabase/migrations`).
Ergebnis: kein Rechte-Befund; alle neuen Funktionen außer `session_naechster_schritt` sind gesperrt, die
Vorschau schreibt nichts, Lösungen nur beim Beispiel. Befunde und Umgang:

| Nr. | Befund | Umgang |
|---|---|---|
| 1 | Tablet bekam `grund` und `schwierigkeit` (Quoten, Fehlversuche, Exit-Ergebnis): Richtig/Falsch-Feedback ans Kind (CLAUDE.md §6) | behoben: nur noch in der Vorschau; pgTAP 1 prüft das |
| 2 | „heute sicher“ zählte Teil-Antworten | behoben (je Aufgabe); Belege siehe Befund 12 |
| 3 | Pool des aktuellen Skills leer → Kind wartet bis zum Check-out | behoben: nächster offener Skill des Ziels |
| 4 | Termin nur über `session_kind_abschluss` erkannt, nicht über `quests.termin` | behoben (`session_termin_gewaehlt`) |
| 5 | `offen` konnte NULL sein | behoben (`coalesce`) |
| 6 | Polling legte bei laufender Erklärung neue Zeilen an; Beispiel bei Reload übersprungen | Zeilen behoben (dedupliziert); Beispiel siehe Befund 15 |
| 7 | `home_quests_aktiv` per Cast statt über die Q1-Funktion | behoben |
| 8 | Einsatz `check` blendet bestehende Checks aus | geprüft, Befund 13 |
| 9 | `mein_lernpfad` bei mehreren aktiven Plätzen; Testlauf-Antworten in Modus/Niveau | erstes behoben (`limit 1`), zweites Befund 14 |

## Verdrahtung (Punkte aus offene-punkte-r1/-a1/-e1/-q1)

| Punkt | Paket | Stand |
|---|---|---|
| r1-13 Testlauf: Notizen/Flags im Abschluss, `session_flags_offen`, Belege | R1 | erledigt (`session_abschliessen`, `session_flags_offen`, `antwort_abgeben`); Einheiten schließt X0 schon aus (`einheiten_stand_intern`) |
| r1-14 Einsatz in `aufgabe_ausgeben` | R1 | erledigt (`session_im_pool`) |
| r1-15 Auswahl, Ziel Lernpfad, Stufe 4, `pfad_entscheiden`, Belege, Kandidaten, Platzhalter | R1/A1 | erledigt |
| r1-16 Signal der Erklärsequenz | R1/E1 | erledigt (`check`-Ereignisse aus `erklaer_check_abgeben`) |
| r1-17, r1-28 Hinweis-Status | R1/E1 | war mit E1 erledigt (`geprueft`), keine Änderung |
| r1-18 Quest-Termin lesen | Q1 | offen für Q2 (Entscheidung O) |
| r1-19 Briefing | C2 | offen für C2 |
| r1-22 Kiosk-Weiche in der App | App | offen für R2 |
| r1-25 Kandidaten je Kind | R1 | siehe Befund 7 |
| r1-27 Tablet wechselt die Phase selbst | R1 | erledigt (`phase_setzen` nur Coach/Admin) |
| a1-1 Stellschrauben aus R1 | A1 | erledigt (`lernpfad_stellschraube` über `session_wert`) |
| a1-3 Session-Verdrahtung | A1 | erledigt |
| a1-4 Badges bei „gemeistert“ | A1 | entschieden (Rasit 06.10.): vorerst kein Abzeichen; offener Punkt für das Badge-System |
| a1-9 Akte und Eltern auf `stand_coach` | A1 | offen: Funktionen der Schülerakte, nicht Session-Pakete |
| a1-10 Kind am Tablet (`mein_lernpfad`) | A1 | erledigt |
| a1-15 Session-Status bei Coach-Entscheidungen | A1 | erledigt (Rasit 06.10.): `mastery_entscheiden`, `pfad_tiefer` und Eingriff Stufe 4 nur in der laufenden Session des Kindes (bis geplantes Ende + 30 Minuten) oder am selben Tag nach dem Abschluss (`lernpfad_coach_der_session`, `eingriff_notieren`); pgTAP N, A1-Fixture angepasst |
| a1-17 Test: LSA-Testlauf erzeugt keine Lernpfad-Zeile | A1 | offen: kein Bestandteil dieses Auftrags, Filter greift laut A1 seit X0 |
| e1-1 `erklaerrunden_bis_signal` | E1 | erledigt (Snapshot) |
| e1-2 Einsatz `check` | E1 | erledigt (Filter in `erklaer_checks`, E1-Fixture angepasst) |
| e1-3 Testlauf für Erklärinhalte | E1 | erledigt (Rasit 06.10.): im Testlauf auch entwurf/geprueft, Check-Aufgaben wie Aufgaben ohne `pruef_ausschluss`; sonst nie (`20261008124414_a2_erklaer_testlauf.sql`, pgTAP N) |
| e1-4 Signal an den Coach | E1 | erledigt |
| e1-5 Nach dem Signal | E1 | erledigt: Kind wartet, bis der Coach das Signal „hängt“ erledigt (Annahme, F9-artig) |
| e1-6 Tablet-Zugang, Session läuft | E1 | erledigt |
| e1-7 Live-Sicht der Sequenz | E1 | erledigt (`coach_raum_live.erklaersequenz`) |
| q1-1 Stellschrauben | Q1 | erledigt (Snapshot, Entscheidung B) |
| q1-3 Aufruf aus dem Check-out | Q1 | offen für Q2 (Entscheidung O) |
| q1-5 Tablet setzt den Quest-Termin | Q1 | erledigt |
| q1-6 Mischen aus dem Lernpfad | Q1 | offen für Q2: wirkt erst mit `quest_erzeugen` |
| q1-9 Zwei `quest_termin_setzen` | Q1 | offen für Q2 |
| X0b-Befunde (`erklaer_nachlesen`, `erklaer_zugang`, `lernpfad_coach_der_session`) | A1/E1 | erledigt, pgTAP X; A2-Ausnahmen im Wächter gestrichen |

## X0b-Wächter

**Erledigt:** #219 ist in `dev` und hereingemergt. Die A2-Familien sind aus `pg_temp.ausgenommen` gestrichen; es
bleiben nur die L5-Familien. `session_x0b.test.sql` lokal 28/28 grün, Diagnose „ausgenommen (L5, noch offen): keine“.

Probe 06.10. (Abfrage `pg_temp.unsichere_rollenpruefungen` aus #219 gegen die Wegwerf-DB mit allen A2-Migrationen,
ohne die X0b-Migrationen): 11 Treffer, alle außerhalb der A2-Familien und genau die Funktionen, die X0b selbst
umstellt (`audit_log_schreiben`, `enforce_mastery_gate`, `lead_assessment_upsert`, `lead_delete`, `notiz_anlegen`,
`platz_assign`, `platz_release`, `slot_assign`, `slot_release`, `task_preview_payload`, `task_solution_get`). Für die
A2-Familien bleibt der Wächter leer; ihr Teil der Ausnahmeliste kann also ganz entfallen.

Zweite Probe 06.10., nachdem die beiden X0b-Migrationen (`20261008100000`, `20261008100100`, in Prod bereits
eingespielt) zusätzlich in der Wegwerf-DB liefen: **0 Treffer**. Die pgTAP-Dateien `session_a2`, `session_r1`,
`session_a1`, `session_e1` bleiben damit grün.
