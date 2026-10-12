# Offene Punkte T3: Im Testlauf Inhalte wie freigegeben

Stand: 12.10.2026 · Branch `feat/rasit-session-t3-testlauf-inhalte` · Migrationen `20261013151236` (Hilfen),
`20261013151305` (Session), `20261013151404` (LSA) · Beweis: `supabase/tests/session_t3.test.sql`,
`src/pages/coach/live/LiveKopf.test.tsx`

**Regel (Rasit, 08.10.):** In einer Testlauf-Session (`coaching_sessions.testlauf`) und in einer LSA eines Testkontos
gilt jeder Inhalt, der die Prüfung des Lena-Boards besteht, als freigegeben. Massstab ist die Aufgabe:
`testlauf_inhalt_sichtbar(task)` = Status `ready`, `draft`, `review` oder `rueckfrage` **und** `pruef_ausschluss` leer.
Ob die Regel gilt, steht in der Session (`coaching_sessions.testlauf`) bzw. in der LSA (`lsa_testinhalte(lsa)`:
Testlauf oder `students.ist_test`, wie F1 E2), nie in einem Parameter vom Client. Ein Hinweis braucht zusätzlich
Text; ein geprüfter Hinweis derselben Stufe geht vor.

## Bestand

Quelle: `pg_get_functiondef` aller 468 Funktionen in `public` per dbread (12.10.2026, Prod nach SL1), durchsucht nach
`status`, `freigegeben`, `geprueft`, `testlauf`, `pruef_ausschluss`, `hints`, `fehlbild_labels`, `solution`,
`task_figures`, `formeln`. Gelesen wurde jede Funktion, die die Oberfläche ruft, und deren Hilfen.

| Fläche | Funktion | Filter nach Freigabe/Prüfung | Testlauf heute | Nach T3 |
|---|---|---|---|---|
| Tablet | `tablet_stand` | `aufgabe`: keiner. `pruefung.frage`: `skill_pruefung.status = 'freigegeben'` (`session_pruefung_frage`) | Prüffrage nur freigegeben | unverändert (Punkt 3) |
| Tablet | `session_kind_kontext`, `checkin_kind_speichern`, `session_ziel_kind`, `quest_termin_setzen`, `session_abschluss_kind` | keiner (Labels, Termine, XP) | – | unverändert |
| Tablet | `session_naechster_schritt` → `session_schritt_oeffentlich` | Auswahl über `session_im_pool(t, testlauf)`; Payload `lsa_question_payload` und `loesungsweg` (`task_solutions.solution`) ohne Filter; Figuren `lsa_task_assets` ohne Filter | Entwürfe, Lösungsweg und Figuren kommen | unverändert (nicht anfassen) |
| Tablet | `antwort_abgeben` | Fehlbild-Satz nur mit `fehlbild_labels.freigegeben_am` | Satz fehlt (in Prod 29 von 153 freigegeben) | **Klartext** (Migration …151305) |
| Tablet | `hinweis_abrufen` | Hinweis nur `status = 'geprueft'` | immer „nicht verfügbar“ (Prod: 0 von 186 Hinweisen geprüft) | **Text** (…151305) |
| Tablet | `erklaer_start`, `erklaer_check_abgeben` (`erklaer_zeigen`, `_varianten`, `_checks`, `_naechste_kernidee`, `_schritte_json`) | `erklaer_status_ok(status, testlauf)`, Checks `ready` oder Testlauf ohne `pruef_ausschluss` | Entwurf kommt (A2) | unverändert |
| Tablet | `erklaer_schritt_json` (Formeln, Bilder) | keiner | sichtbar | unverändert |
| Tablet | `erklaer_nachlesen` | Kernidee nur `status = 'freigegeben'` | nur Freigegebenes | **Entwurf** am Tablet einer Testlauf-Session (…151305) |
| Coach | `coach_raum_live`, `raum_signale`, `session_signale_intern`, `session_briefing`, `satz_vorschlaege` | kein Inhaltsfilter (Briefing trennt nur Testlauf-Sessions) | – | unverändert |
| Coach | `coach_kind_detail` | Musterlösung, `correct_answers`, Fehlbild-Klartext ohne Freigabefilter; Hinweistext ohne Status, aber nur für gelieferte Hinweise | Hinweise fehlen, weil keiner geliefert wird | zeigt die jetzt gelieferten Hinweise (ohne Änderung, Test 1) |
| Coach | `session_kind_live` | `pruefung_vorhanden`: Prüffrage freigegeben; Kernideen `erklaer_status_ok(…, testlauf)` | Prüffrage nur freigegeben | unverändert (Punkt 3) |
| Coach | `pruefung_aufs_tablet` | Prüffrage freigegeben, sonst P0002 | – | unverändert (Punkt 3) |
| Exit | `session_plan_checkout` (Planer) | `session_im_pool(t, testlauf)` | Entwürfe kommen | unverändert (nicht anfassen) |
| Quest | `quest_erzeugen` → `quest_aufgaben_waehlen` | nur `status = 'ready'` und Einsatz `quest` | keine Entwürfe | unverändert (Punkt 4) |
| Quest | `quest_inhalt` | keiner (Lösungsweg nur bei offener Quest) | – | unverändert |
| LSA | `lsa_start`, `lsa_select_next_core` | `lsa_im_pool(t, testlauf bzw. Testkonto)` | Entwürfe kommen (F1 E2) | unverändert (nicht anfassen, Punkt 2) |
| LSA | `platz_state`, `lsa_submit`, `lsa_finish` | keiner (keine Rückmeldung ans Kind) | – | unverändert |
| LSA | `lsa_hint` | Hinweis nur `status = 'geprueft'` | „nicht verfügbar“ | **Text** für Testkonten (…151404) |
| LSA-Report | `lsa_fehlbild_report` | Klartext nur mit `freigegeben_am` | Klartext `null` | **Klartext** für Testkonten (…151404) |
| LSA-Report | `lsa_fehlbild_auswertung` | Familien-Elterntext nur mit `fehlbild_familien.freigegeben_am` | `null` | unverändert (Punkt 5) |
| LSA-Report | `src/lib/supabase/reportBausteine.ts` | `report_bausteine.freigegeben_am is not null` (Client) | nur freigegeben | unverändert (Punkt 5) |

Gegenprobe: `session_t3` (60 Zusagen) gegen die alten Prod-Definitionen der fünf Funktionen ist genau bei den elf
Zusagen „1 … Testlauf/Testkonto“ rot (5, 7, 8, 11, 13, 14, 15, 17, 43, 44, 50); alle Zusagen zu „unverändert“,
Prüfung (2), Rechte (3), echtem Kind (4) und Hilfen (H) bleiben grün.

Zweitprüfung (CLAUDE.md §8, unabhängige Instanz, nur lesend): „freigeben“, kein Befund hoch oder mittel. Daraus
übernommen: Tests für Hinweise ohne `status`-Schlüssel, Status `review`/`beanstandet` und gelösten Platz.

## Offene Punkte

1. **Batu: keine Hinweise in Prod (Inhaltspflege).** dbread 12.10.: Die Session-Aufgaben (je 6, bei `vorzeichen_add_sub` 7) von
   `gleichung_quadr_faktor`, `…_wurzel`, `…_formel`, `gleichung_einschrittig`, `…_zweischrittig`, `term_ausklammern`
   und `vorzeichen_add_sub` haben `hints = []`. T3 macht vorhandene Hinweise sichtbar, legt aber keine an. Im
   Szenario Batu bleibt „Hinweis“ deshalb „nicht verfügbar“. Die Einspiel-Prüfung „für die Aufgaben von
   gleichung_quadr_faktor liefert hinweis_abrufen Text“ kann so nicht grün werden; belegt wird stattdessen an einer
   Aufgabe mit Hinweisen (93 in Prod, alle ungeprüft, PR-Text). Wer: Inhaltspflege (Hinweise schreiben).
   **Rasit 12.10.:** Einspiel-Prüfung an einer Aufgabe mit Hinweisen belegen.
2. **Die Regel steht noch an vier Stellen inline.** `session_im_pool`, `lsa_im_pool`, `erklaer_checks`
   (`status = 'ready' or (p_testlauf and status in (…) and pruef_ausschluss is null)`) und `lsa_select_next_core`
   (`v_pool := testlauf or ist_test`) bleiben unverändert, weil der Auftrag die Auswahl ausnimmt. Gleichwertig wäre
   `status = 'ready' or (p_testlauf and testlauf_inhalt_sichtbar(t.id))` bzw. `v_pool := lsa_testinhalte(id)`.
   **Rasit 12.10.: geht an T4.**
3. **Prüffragen (`skill_pruefung`) nur freigegeben, auch im Testlauf.** `tablet_stand.pruefung`,
   `session_kind_live.pruefung_vorhanden`, `pruefung_aufs_tablet`. Prüffragen stehen nicht in der Liste der
   Entscheidung, das Lena-Board prüft sie nicht, und sie hängen am Mastery-Weg (T2). Wer: Rasit, falls die Prüffrage
   im Testlauf auch ungeprüft kommen soll. **Rasit 12.10.: Prüffragen im Testlauf wie freigegeben, geht an T4.**
4. **Quest-Aufgaben im Testlauf nur `ready`.** `quest_aufgaben_waehlen` ist Auswahl, und Home Quests sind aus
   (FernUSG). **Rasit 12.10.: bleibt bei „nur freigegeben“.**
5. **Elternreport: Familien-Elterntext und Report-Bausteine nur freigegeben**, auch für Testkonten
   (`lsa_fehlbild_auswertung`, `reportBausteine.ts`). Beides ist Elterntext ohne Bezug zur Aufgabenprüfung und steht
   nicht in der Entscheidung. **Rasit 12.10.: bleibt bei „nur freigegeben“.**
6. **Coach-Sicht: Hinweistext bei zwei Hinweisen derselben Stufe.** `coach_kind_detail` nimmt den ersten Hinweis der
   Stufe ohne Reihenfolge, `hinweis_abrufen` den geprüften, sonst den alphabetisch ersten. Bei zwei Hinweisen auf
   einer Stufe könnte der Coach einen anderen Text sehen als das Tablet. Prod: 0 Aufgaben mit doppelter Stufe
   (dbread 12.10.). Nicht geändert.
7. **`erklaer_nachlesen` für Coach und Admin** bleibt bei Freigegebenem, auch für ein Kind einer Testlauf-Session: Die
   Funktion kennt dann keine Session. Am Tablet (Datenvertrag 8) gilt der Testlauf.
8. **Kennzeichen.** Die Live-Sicht zeigt den Satz im Kopf (`LiveKopf`, alle Phasen) im Stil von
   `TestlaufBanner`. `TestlaufBanner` selbst ist Admin-Fläche mit eigenem Text („Zählt in keiner Kennzahl …“) und
   bleibt unverändert; die Pille im Raster („Testlauf · zählt nicht in Akten“) ebenso. Am Tablet nichts.
9. **Grants der Hilfen in Prod.** Lokal sind `testlauf_inhalt_sichtbar` und `lsa_testinhalte` nur für `postgres`
   ausführbar. Prod vergibt für neue Funktionen ggf. per Default Rechte an `service_role`; nach dem Einspielen per
   dbread prüfen (`proacl`), `anon`/`authenticated` dürfen nicht darin stehen.
