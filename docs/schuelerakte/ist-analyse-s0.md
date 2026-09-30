# Ist-Analyse Schülerakte (Paket S0)

Stand: 2026-09-25. Rein lesend. Repo `Edvancev1` (Branch `feat/rasit-vertraege-p3b-ui`, Working Tree enthält fremde, unkommittierte P3b-Arbeit), mitgelesen `edvance-app`.

**DB-Zugriff:** `dbcheck` → `PROD OK`. Alle Abfragen liefen mit `PGOPTIONS='-c default_transaction_read_only=on'` (Transaktion schreibgeschützt), nur `SELECT` auf `information_schema`, `pg_catalog`, `pg_policies`, `supabase_migrations.schema_migrations`, `storage.buckets` und Zählabfragen. Kein DDL, keine Personendaten ausgegeben.

Kürzel: **[DB]** = Abfrage gegen Prod, Ausgabe zitiert. Dateipfade relativ zu `/home/rasit/Edvancev1`, sofern nicht anders angegeben.

---

## 1. LSA und Report am Lead

**Befund**
- Die LSA hängt **nicht direkt am Lead**, sondern an einem **provisorischen Schüler**: `lead_lsa_freigeben` legt `students(is_provisional=true, lead_id=<lead>)` an und startet `lsa_start(v_student_id, …)`.
  [DB] `pg_get_functiondef('lead_lsa_freigeben')`: `insert into students (profile_id, class_level, school_name, school_type, is_provisional, lead_id) values (null, …, true, p_lead_id)` … `v_result := public.lsa_start(v_student_id, p_grade, p_subject);`
- Tabellen: `lsa_sessions(student_id → students ON DELETE CASCADE, subject, grade, status, result_summary jsonb, uebernommen_zu_student_id, uebernommen_am)`, `lsa_responses`, `lsa_skill_urteil`, `lsa_ausgegeben`, `lsa_report_notes(session_id, zielbild, empfehlung, paket, updated_by)`, `lead_assessments(lead_id)`.
  [DB] Spalten und FKs: `lsa_sessions_student_id_fkey FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE`, `lsa_report_notes_session_id_fkey … REFERENCES lsa_sessions(id)`, `lead_assessments_lead_id_fkey … REFERENCES leads(id)`.
  Constraint `students_provisional_lead_ck CHECK ((is_provisional = (lead_id IS NOT NULL)))`.
- Report zum Lead finden: `src/lib/supabase/leadLsa.ts:106-141` (`listReportSessionsByLead`): `students.lead_id IN leadIds`, dann `lsa_sessions` mit `status='completed'`, sortiert nach `completed_at`. Die neueste Sitzung gewinnt. Aufruf `src/pages/admin/LeadsPage.tsx:56`, Link `src/pages/admin/leads/LeadCard.tsx:140` → `/admin/report/:sessionId`. Der Reportinhalt löst den Lead ebenfalls über `students.lead_id` auf (`src/lib/supabase/lsaReport.ts:47-61, 135-148, 208-220`).
- **Übergabe beim Vertragsabschluss (P2 ist eingespielt):** `vertrag_abschliessen` **übernimmt dieselbe `students`-Zeile**, statt zu kopieren: `profile_id` wird gesetzt, `is_provisional=false`, `lead_id=null`, danach `leads.converted_student_id = v_student`.
  [DB] `pg_get_functiondef('vertrag_abschliessen')`: `-- Der provisorische Schueler aus lead_lsa_freigeben traegt die LSA-Historie.` / `select id into v_student from public.students where lead_id = v.lead_id;` … `update public.students set profile_id = p_student_uid, is_provisional = false, lead_id = null, …` … `update public.leads set status = 'converted', converted_student_id = v_student`.
  Repo: `supabase/migrations/20260925140000_vertraege_abschluss.sql:485-486, 513-521, 533-535`.
- `lsa_uebernahme(session, student)` (Coach/Admin) erzeugt Fokus-Vorschläge in `student_focus_areas` aus `lsa_skill_urteil` und setzt `lsa_sessions.uebernommen_zu_student_id`. `vertrag_abschliessen` ruft sie **nicht** auf.
  [DB] `select proname from pg_proc where prosrc ilike '%lsa_uebernahme%'` → nur `lsa_uebernahme` selbst. [DB] Zählung `lsa_uebernommen = 0` von `lsa_sessions = 27`.

**Folge für den Bau**
- Weder verknüpfen noch kopieren ist nötig: `lsa_sessions.student_id` zeigt nach dem Abschluss bereits auf den echten Schüler. Die Akte liest `lsa_sessions where student_id = <akte>`. Das ist die billigste Lösung, ohne neue Tabelle.
- **Lücke:** Nach dem Abschluss ist `students.lead_id = null`. Die Lead-seitige Suche (`leadLsa.ts:106-141`, `lsaReport.ts`) findet die LSA und die Elterneinschätzung (`lead_assessments` hängt am Lead) dann nicht mehr. Die Akte braucht für die Lead-Daten den Rückweg über `leads.converted_student_id` (in `src/` bisher ungenutzt, grep findet nur `leads.ts:65`, `types/domain.ts:55`).

## 2. Anwesenheit je Session

**Befund**
- Die Spalte ist `session_students.attendance text NOT NULL DEFAULT 'unknown'` mit den Zuständen `present | absent | unknown`.
  [DB] `session_students_attendance_check CHECK ((attendance = ANY (ARRAY['present','absent','unknown'])))`. Repo: `supabase/migrations/20250101000000_baseline.sql:872-881`.
- `coaching_sessions.status` ist `upcoming | active | done` ([DB] `coaching_sessions_status_check`).
- Schreiber: `src/lib/supabase/sessions.ts:118-128` `setAttendance` (`.update({ attendance })`), einziger Aufrufer `src/pages/coach/CoachDashboard.tsx:164`. RLS: Coach nur für eigene Sessions (`session_students_coach_rw` über `session_ids_fuer_coach()`), Admin alles.
- Keine DB-Funktion schreibt die Anwesenheit ([DB] `prosrc ilike '%attendance%'` → 0 rows).
- Leser: `supabase/functions/generate_parent_report/index.ts:316-355` zählt present und absent.
- Prod-Daten: [DB] `session_students = 2`, Verteilung `unknown | 2`.

**Folge:** **"entschuldigt" und "unentschuldigt" fehlen.** S1 muss den Check erweitern, z. B. `absent` → `absent_excused` / `absent_unexcused` oder eine eigene Spalte. `generate_parent_report` und `src/types/session.ts:3` sind mitzuziehen. Wegen nur 2 Zeilen (beide `unknown`) ist die Migration risikoarm.

## 3. Fächer eines Kindes

**Befund, alle Kandidaten:**

| Quelle | Form | Beleg |
|---|---|---|
| `student_subjects(student_id, subject_id)` → `subjects(name)` | m:n, kanonisch | [DB] FKs `student_subjects_*_fkey`; `baseline.sql:219-223`; Prod: `subjects` = Deutsch, Englisch, Mathematik; 5 Zeilen `student_subjects` |
| `vertraege.fach text` | **ein** Fach je Vertrag | [DB] Spalte 27; `20260922120000_vertraege_prozess.sql:170`; Prod: `Mathematik | 3` |
| `leads.subjects text[]` | Wunsch aus dem Lead | [DB] Spalte 9; `vertrag_starten` übernimmt `subjects[1]` → `fach` (`vertraege_abschluss.sql:198`) |
| `lsa_sessions.subject text` | Fach der Diagnose | [DB] Spalte 4 |
| `skill_clusters.subject_id`, `skills.fach`, `themen.fach` | Lernpfad-Inhalt | `baseline.sql:243`; `20260722130000_a14_skill_substrat.sql:86,112` |
| `student_focus_areas.cluster_id / skill_key` | Lernpfad des Kindes | [DB] Spalten 4, 9 |
| `tiers`, `tier_laufzeiten` | **kein** Fach | [DB] Spalten `tiers(name, price_cents, features jsonb, sort_order, active)`, `tier_laufzeiten(tier_id, laufzeit_monate, preis_cents, einheiten)` |

- `vertrag_abschliessen` schreibt `v.fach` nach `student_subjects`, allerdings **nur beim Erstvertrag** (Zweig `v.student_id is null`). [DB] Funktionsdefinition, Block `if v.fach is not null then … insert into public.student_subjects`.
- edvance-app liest `student_subjects(subjects(name))`: `/home/rasit/edvance-app/src/lib/queries/student.ts:42`.

**Folge:** Die Akte nimmt `student_subjects` als Quelle, weil beide Apps sie schon lesen. Ein Fachwechsel bei einem Folgevertrag wird heute nicht nachgezogen. Das ist offen und für S1 zu entscheiden.

## 4. Versendete Reports — feste Fassung?

**Befund:** **Es gibt keine feste Fassung.**
- LSA-Elternreport `/admin/report/:sessionId`: wird bei jedem Aufruf aus den Live-Tabellen neu erzeugt (`lsaReport.ts:243ff` `getReportData`). Ausgabe nur über `window.print()` (`src/pages/admin/ReportPage.tsx:96`). Der Mail-Button ist deaktiviert, Kommentar `ReportPage.tsx:101-103`: "Es gibt im Projekt keine Mail-Infrastruktur". Gespeichert wird nur der Coach-Freitext in `lsa_report_notes`.
- Periodischer Report `parent_reports(summary jsonb, coach_note, status draft|published, published_at)`. [DB] Spalten und `parent_reports_status_check`. Es gibt kein Versanddatum und keinen Freigebenden (kein `published_by`). Prod: [DB] `parent_reports = 0`. Veröffentlichen: `src/lib/supabase/parentReports.ts:54` (`status: 'published', published_at`).
- `parent_report_generations(coach_id, student_id, model, created_at)` protokolliert nur KI-Aufrufe, nicht den Inhalt.
- Storage-Buckets: [DB] `screening-uploads (privat)`, `task-assets (öffentlich)`, `vertraege (privat)`. Keiner ist für Reports.
- grep `sent_at|versand_datum|versendet_am|report_snapshot` in migrations und `src/lib` findet nichts Report-Bezogenes.

**Folge:** S1 muss eine Snapshot-Ablage neu bauen, z. B. `report_versand(student_id, art, inhalt jsonb/html, versendet_am, versendet_von, empfaenger)` oder einen privaten Bucket. Das Muster dafür existiert bereits in `vertrag_versand(weg, anlass, empfaenger, erfolgt_at, erfolgt_von)` ([DB]). `parent_reports.summary` taugt als Inhalt der Eltern-Reports, braucht aber `published_by`.

## 5. Lernpfad-Stand und bestätigte Badges

**Befund**
- **Gleiches Supabase-Projekt.** Ref `ztcppihxqcphlqaguhma` in `/home/rasit/edvance-app/supabase/.temp/linked-project.json` und im URL-Präfix von edvance-app `.env:1`. Edvancev1 hat denselben Ref: `supabase/.temp/project-ref` und `.env:1`. Nur Präfixe geprüft, keine Schlüssel ausgegeben.
- Lernpfad: `student_focus_areas(student_id, cluster_id, skill_key, herkunfts_session_id, zustand, belegt_direkt, status default 'vorgeschlagen', active, coach_id, source)` [DB]. Fortschritt: `student_task_progress`, `student_progress(xp_total, level, presence_streak_*, home_streak_*)` [DB].
- Mastery mit Coach-Bestätigung: `student_competency_mastery(mastered bool, mastered_by → profiles, mastered_at, score, stage)`. [DB] Spalten und FK `student_competency_mastery_mastered_by_fkey`; Trigger-Funktion `enforce_mastery_gate` existiert ([DB] Funktionsliste). Prod: `mastered = 0`.
- Badges: `student_badges(student_id, badge_id, awarded_at)`. **Keine Spalte für den Vergebenden** ([DB] Spalten). Prod: 0 Zeilen.
- RLS: Coach und Admin lesen `student_competency_mastery` (`scm_coach_admin_read`) und `student_badges` (`student_badges_self_read` enthält `get_my_role() IN (coach, admin)`) [DB].
- edvance-app liest `student_focus_areas` selbst nicht (grep rc=1). Ihre `src/types/database.ts:1401` ist veraltet und kennt `skill_key`, `status` usw. noch nicht.

**Folge:** **Keine eigene Schnittstelle nötig.** Edvancev1 liest direkt über `src/lib`. "Vom Coach bestätigt" mit Coach und Datum gibt es nur auf Kompetenzebene (`mastered_by`, `mastered_at`), nicht bei Badges. Soll die Akte bestätigte Badges zeigen, braucht `student_badges` die Spalten `awarded_by` und ggf. `confirmed_at`. Alternativ zeigt die Akte die bestätigte Mastery statt der Badges.

## 6. Rollen und RLS für Coaches

**Befund**
- `get_my_role()`: `SECURITY DEFINER`, `select role from profiles where id = auth.uid() limit 1` [DB].
- Rollenwerte: [DB] `profiles_role_check CHECK (role = ANY (ARRAY['student','parent','coach','admin']))`. Prod-Verteilung: admin 2, coach 2, parent 4, student 6. Frontend-Typ `src/types/auth.ts:3`.
- **Die Rolle "coach" existiert.** Was ein Coach heute sieht [DB `pg_policies`]:

| Tabelle | Coach heute | Policy |
|---|---|---|
| `students` | **ALL, alle Zeilen** (auch provisorische und ruhende) | `students_coach_admin_all` (`get_my_role() IN (coach, admin)`) |
| `vertraege` | nein | nur `vertraege_admin_select`, `vertraege_admin_update_vorbereitung` |
| `vertrag_bankdaten / _dokumente / _einstellungen / _unterschriften / _versand / _zustimmungen` | nein | nur `*_admin_*` |
| `vertraege_aktuell` (View) | nein | `security_invoker=true` [DB reloptions] → greift RLS von `vertraege` |
| `leads` | **ALL, alle Zeilen** (inkl. `contact_email`, `contact_phone`) | `leads_coach_admin_all` |
| `parent_student` | **ALL** | `parent_student_coach_admin_all` |
| `lead_assessments`, `lsa_sessions`, `lsa_report_notes`, `intake_sessions`, `parent_reports`, `student_subjects` | ALL | `*_coach_admin_all` |
| `coaching_sessions` | nur eigene (`coach_id = auth.uid()`) | `coaching_sessions_coach_rw` |
| `session_students` | nur für eigene Sessions | `session_students_coach_rw` |
| `platz_assignments`, `platz_devices` | nein (nur Admin bzw. das Gerät selbst) | `platz_*_admin_all`, `*_select_own_*` |
| `schulen` | nein | `schulen_admin_all` |
| `ferien_nrw` | ja, lesen (alle Authentifizierten) | `ferien_nrw_authenticated_read` |

- Frontend: `src/components/edvance/ProtectedRoute.tsx:18` `allowedRoles.includes(role)`. Die Rolle kommt aus `src/context/AuthContext.tsx:49` → `src/lib/supabase/profiles.ts:11-17`. `get_my_role` wird im Frontend nicht aufgerufen (grep in `src` leer).

**Folge:** Die Anforderung (Coach sieht nur aktive Akten, keine Vertrags- und keine Elterndaten, auch nicht über die URL) ist **heute nicht erfüllt**:
- Coaches lesen alle `students`, alle `leads` samt Elternkontakt und `parent_student`.
- Es gibt keinen "aktiv/ruhend"-Zustand am Schüler. Ableitbar wäre er über `hat_zugang(student_id, datum)` [DB Funktionsdefinition], das `vertraege` mit `SECURITY DEFINER` liest.

S1 braucht eine Coach-Sicht oder RPC (`SECURITY DEFINER`, gefiltert über `hat_zugang`, ohne Vertrags- und Elternspalten) und die Verschärfung von `students_coach_admin_all` / `leads_coach_admin_all`. Das ist eine **RLS-Änderung**, also Freigabe durch Rasit und Consensus-Trigger (CLAUDE.md §4, §8). Achtung: bestehende Coach-Flächen (`/admin/leads` für Coach, `src/App.tsx:128`) hängen an `leads_coach_admin_all`.

## 7. Wo eine Wortliste gepflegt werden könnte

**Befund**
- Einzige Einstellungstabelle: `vertrag_einstellungen(id boolean PK CHECK(id), glaeubiger_id, updated_at)`, eine Zeile [DB]. Repo `20260922120000_vertraege_prozess.sql:98-104`. RLS nur Admin (`vertrag_einstellungen_admin_select/_update`).
- Tabellen mit Listencharakter: `vertrag_dokumente(schluessel, version, titel, pflicht, aktiv, sort_order)`, `report_bausteine`, `report_anlass_zuordnung`, `fehlbild_labels`, `fehlbild_familien` [DB Tabellenliste].
- grep `create table.*(einstellung|setting|config|konfig)` in migrations trifft nur `vertrag_einstellungen`.

**Folge:** `vertrag_einstellungen` ist fachlich falsch verortet (Vertrag, Admin-only) und als Einzeilen-Tabelle ungeeignet für eine Liste. Empfehlung: eigene kleine Tabelle `akte_wortliste(begriff, aktiv, created_at, created_by)` nach dem Muster von `vertrag_dokumente`, Admin schreibt, Coach liest. Die Prüfung sollte serverseitig im Speicher-RPC der Notiz laufen, damit sie nicht umgehbar ist.

## 8. Zeitgesteuertes Löschen

**Befund:** **Kein Mechanismus vorhanden.**
- [DB] `pg_extension`: `pg_stat_statements, pgcrypto, plpgsql, supabase_vault, uuid-ossp`, **kein `pg_cron`, kein `pg_net`**. [DB] Schemas `cron`, `pgmq`, `net`: 0 rows.
- grep `pg_cron|cron\.|cron.schedule|loeschfrist|löschfrist|retention` über `supabase/` findet nichts. `config.toml` hat keinen Schedule. Keine der 4 Edge Functions ist zeitgesteuert.
- Die Verträge-Pakete haben Cron bewusst vermieden (Status ist abgeleitet): `20260925181700_vertraege_menue_db.sql:7-10`, `docs/vertraege/Bauauftrag-Vertraege.md:216,235`.
- Verwandt: `lead_delete` verweigert konvertierte Leads ("Aufbewahrungspflicht"), `20260716100000_s7_lead_lsa.sql:363-366`.
- Kaskaden-Risiko: `students` → `lsa_sessions`, `session_students`, `student_*`, `parent_reports` sind `ON DELETE CASCADE`, aber `vertraege_student_id_fkey … ON DELETE RESTRICT` [DB FKs]. Ein Schüler mit Vertrag lässt sich also nicht löschen, ohne den Vertrag zu behandeln.

**Folge:** Muss gebaut werden. Optionen: `pg_cron` aktivieren (Extension-Änderung, Freigabe nötig) oder, im Stil der Verträge, ein **abgeleiteter Status "löschfällig"** plus eine manuell ausgelöste Lösch-RPC mit `audit_log`-Eintrag (`audit_log_schreiben` existiert [DB]). Die Frist selbst ist fachlich offen (Anforderung, fachliche Frage 13).

## 9. Stand Verträge-Pakete

**Befund**
- Eingespielte Migrationen in Prod: [DB] `supabase_migrations.schema_migrations`, neueste zuerst: `20260925181700 vertraege_menue_db` (= **P3a**), `20260925140000 vertraege_abschluss` (= **P2**), `20260925120000 vertraege_erweiterung` (= **P1**), `20260924120000 tarife_laufzeiten`, … insgesamt 65.
- Git: `9fb3b01 feat(db): Menue Vertraege — abgeleiteter Status statt Cronjob (#166)`, `83bf5d6 Vertraege P2: Abschlussstrecke (#165)`, `d2e6216 Vertraege P1: Datenmodell … (#164)`.
- **Nicht eingespielt:** `supabase/migrations/20260926090000_laufzeit_monat_vor_beginn.sql` liegt nur untracked im Working Tree (`git status`: `??`). Sie ändert `laufzeit_monat` auf NULL vor Vertragsbeginn. In Prod liefert die View noch die alte Formel ([DB] viewdef: `CASE WHEN v.vertragsbeginn IS NULL THEN NULL ELSE 1 + … END`).
- **P3b (UI)** ist in Arbeit, unkommittiert: `src/pages/admin/vertraege/menue/`, `src/lib/supabase/vertraegeMenue.ts`, `src/components/edvance/EdvanceTable.tsx` (`git status`).
- Einzelobjekte [DB]:
  - `schulen`: vorhanden (id, name, ort, created_at, created_by), 1 Zeile
  - `ferien_nrw`: vorhanden (id, art, name, von, bis), 17 Zeilen
  - `vertraege.student_id`: vorhanden, FK `REFERENCES students(id) ON DELETE RESTRICT`; alle 3 Verträge haben `student_id`
  - `vertraege.vertrag_status`: vorhanden, Check `im_widerruf | aktiv | gekuendigt | ausgelaufen | widerrufen`, dazu `vertraege_vertrag_status_nach_abschluss CHECK ((status = 'abgeschlossen') = (vertrag_status IS NOT NULL))`. Prod: 3× `abgeschlossen / im_widerruf`
- **View `public.vertraege_aktuell`** (`security_invoker=true`, nur `status='abgeschlossen'`). Spalten: alle 61 Spalten von `vertraege` sowie
  - `wirksamer_status` (= `vertrag_wirksamer_status(widerrufen_am, gekuendigt_zum, vertrag_ende, widerruf_bis)`: widerrufen > gekuendigt > ausgelaufen > im_widerruf > aktiv)
  - `laufzeit_monat`
  - `ist_aktueller_vertrag` (`row_number() OVER (PARTITION BY COALESCE(student_id, id) ORDER BY vertragsbeginn DESC …) = 1`)
  - `beitrag_diesen_monat_cents`
  - `zugangscode_gueltig`
  - `endet_in_tagen`
- Dazu `hat_zugang(p_student_id, p_datum)` (`SECURITY DEFINER`): wahr bei einem wirksamen Vertrag `im_widerruf/aktiv` oder in der Lücke zwischen Vorgänger und Folgevertrag [DB Funktionsdefinition].

**Folge:** P1, P2 und P3a (DB) sind live, P3b (UI) nicht. S1 kann "aktive Akte" direkt aus `hat_zugang` oder `vertraege_aktuell.wirksamer_status` ableiten. Wegen `security_invoker` sieht ein Coach die View aber nicht; der Zugriff muss über eine `SECURITY DEFINER`-Funktion laufen.

## 10. Tabelle `students`

**Befund:** [DB] alle Spalten:
- `id uuid PK default gen_random_uuid()`
- `profile_id uuid NULL → profiles(id) ON DELETE CASCADE`
- `class_level int NULL CHECK 5..13`
- `school_name text NULL`
- `school_type text NULL CHECK (Gymnasium|Gesamtschule|Realschule|Hauptschule)`
- `is_provisional bool NOT NULL default false`
- `lead_id uuid NULL → leads(id) ON DELETE CASCADE`, mit `students_provisional_lead_ck`

- **Klasse:** ja, `class_level`, eine Zahl ohne Schuljahr und ohne Historie.
- **Schule:** nur als Freitext `school_name`. **Kein `schule_id`** an `students`; die FK-Referenz `schule_id → schulen` gibt es nur an `vertraege` [DB FKs].
- Anbindung an `auth.users`: `students.profile_id → profiles.id`, `profiles_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE` [DB]. Provisorische Schüler haben `profile_id = null`. Prod: 17 Schüler, davon 12 provisorisch.
- Keine Spalten für Name (Name über `profiles.full_name`), Geburtsdatum (nur `vertraege.kind_geburtsdatum`), Status/ruhend oder Löschfrist.
- Trigger `students_guard_provisional_trg` (BEFORE INSERT/UPDATE) [DB].

**Folge:** Für Klassenwechsel und Schuljahr (fachliche Frage 14) und für den Aktenstatus braucht S1 neue Spalten oder eine Historientabelle. Für die Schule empfiehlt sich `students.schule_id → schulen`.

## 11. Routing und Menü in Edvancev1

**Befund**
- Alle Routen liegen in einem `<Routes>`-Block in `src/App.tsx:44-299`, jede in `ProtectedRoute allowedRoles=[…]` gekapselt. Admin z. B. `/admin` :120, `/admin/vertraege` :137, `/admin/vertraege/:id` :145, `/admin/report/:sessionId` :207 (admin, coach); Coach `/coach` :72, `/coach/reports` :96.
- **Kein zentrales Menü-Array** (grep `sidebar|navItems|NAV_ITEMS|menuItems` in `src` leer). Hauptpunkte sind Dashboard-Kacheln:
  - Admin: `src/pages/admin/AdminDashboard.tsx:65` (`/admin/leads`), `:78` (`/admin/schedule`), `:95` (`/admin/coaches`), `:111` (`/admin/authoring`), `:117` (`/admin/vertraege`). Die Kacheln "Schülerakte", "Eltern-Reports" und "LSA-Ergebnisse" sind bereits als Platzhalter ohne `to` vorgesehen (Kommentar `AdminDashboard.tsx:86`).
  - Coach: Kachel-Array `src/pages/coach/CoachDashboard.tsx:210-234`.
  - Gemeinsam: `src/components/edvance/DashboardTiles.tsx`, `AdminHeader.tsx:44` (`backTo`).
- Rollenprüfung: `ProtectedRoute.tsx:18`, `AuthContext.tsx:49`, Login-Weiterleitung `src/pages/Login.tsx:113-114` (`ROLE_ROUTES[role]`). Einzelne Pages lesen `useAuth().role` direkt: `ItemBoardPage:38`, `AuthoringEditorPage:61`, `PflegeWizardPage:70`, `ContentHealthPage:65`.

**Folge:** Die Akte bekommt Routen in `App.tsx` (z. B. `/admin/akten`, `/admin/akten/:studentId` für admin und coach) und hängt sich in die vorhandene Platzhalter-Kachel in `AdminDashboard.tsx` sowie in das Kachel-Array in `CoachDashboard.tsx`. Die Rollenprüfung im Frontend ist nur UI; der eigentliche Schutz muss in RLS/RPC liegen (siehe 6).

---

## Was S1 neu bauen muss / was S1 wiederverwenden kann

| Bereich | Wiederverwenden (Beleg) | Neu bauen |
|---|---|---|
| Stammdaten Akte | `students` + `profiles.full_name` (Frage 10), `vertraege_aktuell` für Vertragsdaten (Admin) | Aktenstatus aktiv/ruhend (abgeleitet über `hat_zugang`), `students.schule_id`, Klassen- und Schuljahr-Historie |
| LSA in der Akte | `lsa_sessions.student_id` bleibt nach `vertrag_abschliessen` erhalten; `lsaReport.ts`-Loader | Lead-Rückweg über `leads.converted_student_id` (heute bricht die Suche über `students.lead_id=null`); ggf. automatischer `lsa_uebernahme`-Aufruf |
| Anwesenheit | `session_students.attendance`, `setAttendance` (`sessions.ts:118`) | Zustände entschuldigt/unentschuldigt (Check und Typ erweitern), Einheiten-Zählung gegen `vertraege.einheiten` |
| Fächer | `student_subjects` / `subjects` (beide Apps lesen es) | Nachziehen des Fachs bei Folgevertrag (heute nur Erstvertrag) |
| Versendete Reports | `parent_reports` (Inhalt), Muster `vertrag_versand` | Feste Fassung mit `versendet_am`/`versendet_von`/`empfaenger` (Tabelle oder privater Bucket); `published_by` |
| Lernpfad und Mastery | `student_focus_areas`, `student_competency_mastery.mastered_by/_at`, `student_progress`, gleiches Supabase-Projekt, keine Schnittstelle nötig | lib-Loader in Edvancev1; `awarded_by` an `student_badges`, falls Badges bestätigt angezeigt werden sollen |
| Coach-Zugriff | Rolle `coach`, `get_my_role()`, `ProtectedRoute` | Coach-RPC/-Sicht nur für aktive Akten ohne Vertrags- und Elterndaten; RLS von `students`, `leads`, `parent_student` einschränken (**Freigabe Rasit + Consensus**) |
| Wortliste | Muster `vertrag_dokumente` (aktiv, sort_order) | Tabelle `akte_wortliste` + Admin-Pflege + serverseitige Prüfung im Notiz-RPC; Notizfeld selbst |
| Löschfrist | `audit_log_schreiben`, abgeleiteter-Status-Muster aus P3a | Löschfälligkeit + Lösch-RPC (oder `pg_cron`, Freigabe nötig); Umgang mit `vertraege … ON DELETE RESTRICT` |
| Routing und Menü | `App.tsx`-Muster, Platzhalter-Kachel "Schülerakte" in `AdminDashboard.tsx`, Coach-Kacheln | Routen `/admin/akten(/:id)`, Pages, i18n-Namespace |
| Vertragsdaten | P1, P2, P3a live (`vertraege_aktuell`, `hat_zugang`, `vertrag_wirksamer_status`) | nichts; aber `20260926090000_laufzeit_monat_vor_beginn.sql` ist noch nicht eingespielt |
