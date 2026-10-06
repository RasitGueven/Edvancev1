# Offene Punkte X0 (Sicherheit, Einsatz, LSA-Pool, Testmodus)

Stand 06.10.2026 · Branch `feat/rasit-session-x0-sicherheit` · Bauauftrag `docs/session/Bauauftrag-Session-P1.md`

## Entscheidungen, die vom Wortlaut abweichen oder ihn auslegen

1. **Zugangscode: weder Spaltenrechte noch eigene Tabelle.**
   - Spaltenrechte scheiden aus: Admin, Coach, Eltern und Kind teilen sich die DB-Rolle `authenticated`. Ein `revoke select (zugangscode)` würde den Admin genauso aussperren.
   - Eine eigene Tabelle bringt heute nichts. `vertraege` hat als einzige SELECT-Policy `vertraege_admin_select` (dbread `pg_policies`). `vertraege_aktuell` läuft mit `security_invoker=true` (dbread `pg_class.reloptions`). Kein Definer liefert Vertragszeilen oder den Code an Nicht-Admins (pg_proc-Scan: Rückgabetyp und `v.*`/`to_jsonb(v)` ohne Treffer). Nur vier Funktionen nennen den Code, alle Admin bzw. intern.
   - Festgehalten ist das durch pgTAP Test 5 (Coach und Kind lesen nichts, Admin schon). Mail-Versand und Datenmodell bleiben unverändert.
   - **Risiko:** Eine spätere Eltern-Policy auf `vertraege` würde den Code mitliefern. Dann den Code in eine Admin-Tabelle auslagern.
2. **„Coach nur über einen Platz“** heißt hier Session-Platz. Der Coach muss das Kind (aktive Akte) in einer eigenen, nicht abgeschlossenen `coaching_session` von gestern bis morgen (Berlin) gebucht haben (`session_students`, nicht abgesagt; `coach_hat_platz`). Der Kiosk-Platz (`platz_assign`) bleibt Admin-Sache. Rest-Risiko aus dem Consensus-Check: Per RLS `coaching_sessions_coach_rw` und `session_students_coach_rw` kann ein Coach sich selbst eine Session anlegen und ein Kind mit laufendem Vertrag eintragen. Damit erfüllt er die Bedingung selbst. Das zu schließen gehört zu R1 (Buchung nur durch Admin bzw. Slots, Entscheidung 2).
3. **Testlauf in der Lead-Strecke nur mit Test-Lead.** Ein Test-Lead läuft den Trichter normal durch, damit Platz-Zuweisung und Report-Link funktionieren. Er zählt aber in keinem Lead-Zähler: `adminStats`, Heute-Listen und Board-Spaltenzahl filtern `ist_test`, die Karte zeigt ein Badge.
4. **`lsa_select_next_core` ignoriert `p_status_filter`.** Den Pool bestimmt nur noch `lsa_im_pool` mit `lsa_sessions.testlauf`. Damit ist auch die A0-Lücke zu: `lsa_select_next` hatte den Statusfilter vom Client übernommen. Die Signatur bleibt für die Aufrufer gleich.
5. **`is_active`** zählt im Pool streng (`coalesce(is_active, false)`). Der feste Modus nahm bisher `coalesce(…, true)`. In Prod gibt es keine NULL-Werte (dbread: 0 von 1183).
6. **`xp_buchen`** darf nur der Admin oder ein Systemaufruf ausführen. Der Betrag liegt zwischen 1 und 1000. Je Kind bucht ein Buchungsschlüssel genau einmal (neue Spalte `xp_events.buchungs_schluessel`, unique auf `(student_id, buchungs_schluessel)`). Die Grenze 1000 ist eine Annahme, keine Stellschraube.

7. **NULL-Rollen (Nachtrag Rasit, 06.10.):** Alle Rollenprüfungen in den X0-Migrationen laufen über `coalesce(public.get_my_role(), '')`. `lsa_may_act_for` liefert nie mehr NULL: Der Vergleich `get_my_student_id() = p_student_id` war ohne Schülerzeile NULL, und `if not lsa_may_act_for(…)` hätte das durchgelassen. Laut dbread haben 11 von 30 `auth.users` keine Zeile in `profiles`. pgTAP 9 prüft „angemeldet ohne Profil → 42501“ je Funktion.
8. **Entscheidungen Rasit (06.10.):** Zugangscode ohne Spaltenrechte bleibt. Report-Ausblick für Coaches nur lesend: bestätigt. Test-Leads laufen normal durch und zählen nicht: bestätigt. Die Coach-Selbstbuchung schließt R1.

## Was weiter auf stillgelegte Objekte zeigt (nicht gelöscht)

| Objekt | Zeigt darauf | Wirkung ab X0 |
|---|---|---|
| `src/pages/student/TaskPlayer.tsx` | `completeTask`, `persistBehaviorSnapshot` | nicht mehr geroutet (`App.tsx` → `TaskPlayerStillgelegt`) |
| `src/pages/student/ClusterView.tsx:202,209,216`, `ClusterGrid.tsx:66`, `components/edvance/StudentWidgetGrid.tsx:33` | Links auf `/student/task/:id` | landen auf „nicht mehr verfügbar“ |
| `src/lib/supabase/taskProgress.ts:30` `completeTask` | RPC `complete_task` | 42501 (EXECUTE entzogen) |
| `src/lib/supabase/behavior.ts:7` `persistBehaviorSnapshot` | INSERT `behavior_snapshots` | 42501 |
| `src/lib/supabase/taskProgress.ts:12,63`, `resume.ts:21` | SELECT `student_task_progress` | Lesen unverändert |
| `src/context/DiagnosisContext.tsx` | nur Kommentar und Typ, kein Schreiben | – |
| `scripts/seed-test-student.ts:140-167` | INSERT `xp_events`, UPDATE `student_progress` | Service-Role, unberührt |
| `src/lib/supabase/badges.ts:42` `awardBadge` | INSERT `student_badges` | nur noch Admin (kein Aufrufer außerhalb von lib) |

## Offen für spätere Pakete

1. **edvance-app, Hub-Knopf „Lernstandsanalyse starten“** (`app/(student)/index.tsx:186-187` → `/lsa/intro` → `lsa_start`, `src/lib/queries/lsa.ts:126`). Für Schülerkonten kommt jetzt 42501, so verlangt es Entscheidung 24. Den Knopf und den Browser-Testpfad `app/(student)/lsa/task.tsx` entfernt P2.
2. **App-Banner „Testlauf“**: `platz_state` und `lsa_start` liefern `testlauf` aus. Das Banner selbst baut P2.
3. **`coaching_sessions.testlauf` in der Oberfläche**: Die RPC `session_testlauf_setzen` existiert (nur Admin, nur Testkonten), ein Schalter im Stundenplan fehlt. Kommt mit R1/P2.
4. **R1 muss Testläufe ausschließen**: Neue Session-Tabellen, Live-Sicht und Abschluss sollen `coaching_sessions.testlauf` beachten (siehe R1-Prompt, Punkt 13).
5. **`/coach/reports` (`src/pages/coach/ReportsPage.tsx`)**: Coaches dürfen `parent_reports` nur noch lesen. Die Route ist deshalb jetzt nur für Admins freigegeben (`App.tsx`, Consensus-Befund 4). `generate_parent_report` prüft für Coaches zusätzlich `akte_aktiv` (Befund 3). Ob die alte Seite neben `eltern_reports` ganz wegfällt, ist offen.
6. **Report-Ausblick (`lsa_report_notes`)**: Coaches lesen ihn nur noch, die Felder sind für sie gesperrt (`ReportOutlook nurLesen`). Ob Coaches dort künftig schreiben sollen, entscheidet Rasit.
7. **`lsa_uebernahme` und `lsa_confirm_focus`**: Ein Coach darf sie seit X0 nur für Kinder mit aktiver Akte aufrufen (Consensus-Befund 2, pgTAP 4). A1 löst beide durch `lernpfad_aus_lsa` ab.
8. **`student_competency_mastery`**: Coaches lesen und schreiben weiter für alle Kinder. Die Tabelle ist laut Entscheidung 23 Altlast, das Mastery-Gate bleibt bis A1.
9. **Screening-Tabellen** (`screening_tests`, `screening_item_results`): Coaches lesen weiter alle Kinder (S1b-Liste). Nicht im X0-Umfang.
10. **Identitätstausch am Kiosk** (`platz_submit`/`platz_finish` setzen die Claims des Admins): unverändert, gehört zu R1.
11. **Edge Function `generate_parent_report`**: Der Testlauf-Filter ist im Code (`index.ts`), muss aber eigens mit `supabase functions deploy generate_parent_report` ausgerollt werden.
12. **`schema-erwartet.sql`**: laut Auftrag nicht angefasst. Der CI-Vergleich `neuaufbau` ist deshalb rot, bis nach dem Einspielen `tools/schema-snapshot.sh` gelaufen ist. Gemergt wird erst danach.
13. **Lokale pgTAP-Altlasten**: `a3`, `a4`, `s7`, `s9`, `inv2`, `inv3`, `inv6` und `inv7` sind schon vor X0 rot (`supabase/tests/bekannt-rot.txt`). `lsa_finish_themenraum` bricht lokal am relativen `\ir` ab. Vor und nach X0 identisch.
14. **Rollback** `docs/session/rollback-x0-coach-rechte.sql` setzt nur `20261007100600` zurück. Die Schreib-Revokes aus `100000`/`100100` und die Testmodus-Spalten haben keinen Rollback, weil sie nichts Lesbares wegnehmen.
15. **Eltern-Lesepolicies** auf den LSA-Tabellen filtern `testlauf` nicht. Das ist unkritisch, solange Testläufe nur an Testkonten hängen; Eltern von Testkonten sind Testdaten.
