# Folgepaket S1b — Coach-Lesezugriff auf pädagogische Tabellen

**Stand:** 30.09.2026 · **Anlass:** Consensus-Check zu S1 (PR #174), Befund 4 · **Entscheidung Rasit:** nicht in #174, eigenes Paket, hier noch kein Code.

Nach S1 lesen Coaches `leads`, `parent_student`, `vertraege` und `vertrag_*` nicht mehr. `students` und `profiles` sehen sie nur noch für Kinder mit aktiver Akte. Vier weitere Tabellen sind aber weiter über `*_coach_admin_all`-Policies für **alle** Kinder offen, auch für ruhende und provisorische. Das widerspricht dem Sinn von „Coach sieht nur aktive Akten“ (Anforderung, Rechte-Tabelle).

Die Zeilenangaben beziehen sich auf den Stand von Branch `feat/rasit-schuelerakte-s1-datenmodell`. Policies stehen in `supabase/schema-erwartet.sql`.

## parent_reports

| | |
|---|---|
| Policy heute | `parent_reports_coach_admin_all` (ALL, `get_my_role() in (coach, admin)`) — `schema-erwartet.sql:10272` |
| Coach liest/schreibt | `ReportsPage.tsx:62` → `listReportsForStudent` (`parentReports.ts:35`, SELECT) · `ReportsPage.tsx:114` → `createParentReport` (`parentReports.ts:11`, INSERT) · `ReportsPage.tsx:74,127` → `publishReport` (`parentReports.ts:53`, UPDATE) · `ReportsPage.tsx:90` → Edge Function `generate_parent_report` (Service-Role, von RLS unberührt; prüft nicht, ob der Coach das Kind betreut) |
| Braucht der Coach | Reports für Kinder, die er in Sessions hat, also mit aktiver Akte. Ruhende Kinder braucht er nicht. |
| Vorschlag | Policy teilen: `parent_reports_admin_all` sowie `parent_reports_coach_all` mit `get_my_role() = 'coach' and akte_aktiv(student_id)`. In `generate_parent_report` dieselbe Prüfung vor dem Lesen (`akte_aktiv` per RPC oder direkt). Klären: Bleibt `parent_reports` nach dem Feature Eltern-Reports überhaupt bestehen, oder wird es Arbeitstabelle vor `eltern_reports`? |

## intake_sessions

| | |
|---|---|
| Policy heute | `intake_sessions_coach_admin_all` (ALL) — `schema-erwartet.sql:10084` |
| Coach liest/schreibt | `IntakePage.tsx:81` → `getIntakeByStudent` (`intake.ts:41`, SELECT) · `IntakePage.tsx:129` → `createIntakeSession` (`intake.ts:10`, INSERT mit `student_id`, `lead_id`, `coach_id`) · `IntakePage.tsx:128,146` → `updateIntakeSession` (`intake.ts:65`, UPDATE). Die Kindauswahl kommt aus `listStudentsWithName` und zeigt seit S1 nur noch aktive Akten. |
| Braucht der Coach | Offen. Das Erstgespräch findet vor dem Vertrag statt, also mit einem Lead oder provisorischen Kind. Seit S1 liegt die Lead-Strecke nur beim Admin. Ein Coach kann dort praktisch kein neues Erstgespräch mehr anlegen, nur bestehende zu aktiven Akten lesen. |
| Vorschlag | Fachlich entscheiden, wem das Erstgespräch gehört. **Gehört es dem Admin** (wie Leads): Coach aus der Policy nehmen, Route `/coach/intake` und Kachel entfernen. **Bleibt es beim Coach:** Coach nur für `akte_aktiv(student_id)`; die Spalte `parent_expectations` prüfen, weil sie Elternangaben sind. |

## lead_assessments

| | |
|---|---|
| Policy heute | `lead_assessments_coach_admin_all` (ALL) — `schema-erwartet.sql:10135` |
| Coach liest/schreibt | Direkt keine Stelle mehr. Der LSA-Report liest seit S1 über `lsa_lead_kontext` (RPC, filtert auf aktive Akte oder provisorisch). Geschrieben wird über `leadAssessmentUpsert` (`LeadIntakeForm.tsx:157`, RPC `lead_assessment_upsert`, SECURITY DEFINER, erlaubt `coach, admin`). Die Seite ist seit S1 nur für Admins erreichbar. |
| Braucht der Coach | Nichts direkt. Die Eltern-Einschätzung erreicht ihn im Report über `lsa_lead_kontext`. |
| Vorschlag | Policy auf Admin (`lead_assessments_admin_all`). `lead_assessment_upsert` auf Admin einschränken. Dabei den pgTAP-Test `supabase/tests/s7_lead_lsa.test.sql:315-355` anpassen, der das Coach-Upsert heute prüft. |

## lsa_sessions (und die Folgetabellen)

| | |
|---|---|
| Policy heute | `lsa_sessions_coach_admin_all` (ALL) — `schema-erwartet.sql:10218`; dazu `lsa_responses_coach_admin_read` (`:10196`), `lsa_skill_urteil_coach_admin_read` (`:10238`), `lsa_report_notes_coach_admin_all` (`:10183`) |
| Coach liest | `ReportPage.tsx:45` → `getReportData` (`lsaReport.ts:244`, Route `/admin/report/:sessionId` weiter `admin, coach`) · `lsaReport.ts:107` `listTodaysLsaSessions` (nur `LsaTodayCard` auf der Leads-Seite, seit S1 nur Admin) · `leadLsa.ts:54,134`, `platz.ts:124` (Leads-Seite/PlatzPanel, seit S1 nur Admin) |
| Braucht der Coach | Den LSA-Report der Kinder mit aktiver Akte. In der Akte ist das Report 1 (S2 verlinkt ihn). Laufende oder fremde LSA braucht er nicht, der Kiosk läuft über SECURITY-DEFINER-RPCs. |
| Vorschlag | Coach-Policies auf `akte_aktiv(student_id)` (bei `lsa_responses`/`lsa_skill_urteil`/`lsa_report_notes` über `session_id → lsa_sessions.student_id`, als DEFINER-Hilfsfunktion gegen RLS-Ketten). Klären, ob `/admin/report/:sessionId` für Coaches bleibt oder nur über die Akte (S2) erreichbar ist. `ReportPage.tsx:89` (`backTo="/admin/leads"`) führt einen Coach heute über die Umleitung aufs Dashboard; in S2 auf die Akte zeigen lassen. |

## Befund S2b (30.09.2026): Coach-Kacheln „Erstgespräch-Protokoll“ und „Screening-Ergebnisse“

Die Kachel „Elternreport – erstellen und freigeben“ ist aus dem Coach-Dashboard entfernt (Entscheidung Rasit: Eltern-Reports nur Admin). Die Route `/coach/reports` besteht weiter und ist für Coaches erreichbar; sie gehört in dieses Paket (siehe `parent_reports` oben).

Die beiden anderen Kacheln bleiben unverändert. Sie hängen aber an denselben offenen Lesezugriffen:

| Kachel | Route | liest als Coach | Befund |
|---|---|---|---|
| Erstgespräch-Protokoll | `/coach/intake` (`IntakePage.tsx`) | `students` + `profiles` über `listStudentsWithName` (seit S1 nur aktive Akten), `intake_sessions` lesen/anlegen/ändern (`intake.ts:10,41,65`) | Das Erstgespräch findet vor dem Vertrag statt. Seit S1 bietet die Seite dem Coach aber nur Kinder mit aktiver Akte an, ein neues Erstgespräch zu einem Lead ist dort nicht mehr möglich. Offen: gehört das Erstgespräch dem Admin (wie Leads) oder dem Coach? |
| Screening-Ergebnisse | `/coach/screening-results` (`ScreeningResultsPage.tsx`) | `students` + `profiles` (nur aktive Akten), `screening_tests` (`screening.ts:30`, Policy `screening_tests_coach_admin_all`, ALL) und `screening_item_results` (Policy `screening_item_results_coach_admin_read`) | Die Tabellen sind für Coaches für alle Kinder offen, auch für ruhende und provisorische. Die Seite zeigt nur Kinder mit aktiver Akte, per API ist aber alles lesbar. Vorschlag: Coach-Policies auf `akte_aktiv(student_id)`, wie bei `lsa_sessions`. |

## Weitere Kandidaten (aus dem Consensus-Check, nicht bewertet)

- `student_subscriptions`: Das Paket ist Vertragsinhalt und für Coaches offen.
- `behavior_snapshots`, `xp_events`: Coach liest alle.

Beide gehören vermutlich in dieselbe Runde. Vorher mit der Aufruferliste prüfen.

## Umfang, wenn S1b gebaut wird

- Eine Migration mit Rollback-Datei und Consensus-Check (CLAUDE.md §8), analog `20260929100200_coach_rls.sql`.
- Ein Test nach dem Muster `tests/sql/coach_rls_test.sql`: je Tabelle aktive Akte lesbar, ruhende und provisorische nicht.
- Frontend nur, wenn die Intake-Entscheidung Routen oder Kacheln betrifft.
