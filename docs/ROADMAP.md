# Edvance – Roadmap

## Fertig
- Vite + React + TypeScript + Tailwind + shadcn Fundament
- Supabase Auth mit Rollen (student|parent|coach|admin)
- Design-System: EdvanceCard, MasteryBar, XPBar, StatCard, Badges, EmptyState, LoadingPulse
- CLAUDE.md Harness konfiguriert
- Aufgaben-Schema: Tabellen, RLS-Policies, Seed-Script für KMK-Cluster
- NRW Klasse 8 Mathe Taxonomie + Diagnostic-Generator
- **Real-Data-Programm (Branch `feature/real-data-program`, siehe Retro 2026-05-16):**
  - Schema-Migrationen 011–021 (RLS-Fix, leads, intake_sessions, screening_tests/
    screening_ratings, tiers/subscriptions, student_coach, sessions, gamification,
    parent_reports, provision-RPC)
  - Vollständiger Supabase-Lib-Layer + Edge Function `provision_student`
  - Erstgespräch Stufe A `/admin/leads` + Stufe B `/coach/intake`
  - Tarif-Verwaltung `/admin/tiers` (DB-Katalog statt Hardcode)
  - Diagnose-/Screening-Engine de-mockt (echter Generator + Content)
  - Coach-/Student-/Parent-Dashboard auf Echtdaten; alle Mock-Daten entfernt
- **LSA-Backend (Lernstandsanalyse), Vertrag steht — `docs/api/DATENVERTRAG.md`:**
  - **P01 Datenvertrag** (Retro 2026-07-12): `task_solutions` als Server-Only-Zone
    (kein Grant für anon/authenticated), `lsa_question_payload` baut aus einer
    Whitelist, RPCs `lsa_start`/`lsa_submit`/`lsa_hint`/`lsa_finish`/
    `lsa_confirm_focus`. FernUSG-Gate: `lsa_finish` schlägt vor, der Coach setzt.
  - **P02 Multi-Part** (Retro 2026-07-13): `input_type = 'MULTI_PART'`,
    `tasks.parts` (Kompetenz + AFB **je Teilaufgabe**), `lsa_responses.part_nr` —
    eine Zeile pro Teilaufgabe. `result_summary` aggregiert pro Kompetenz, nicht
    pro Item. Noch **nicht deployt**.
  - Beweis: pgTAP 48/48 (`inv1` Mastery-Gate, `inv2` Datenvertrag, `inv3` Multi-Part)

## In Arbeit
- Aufgaben-DB-Befüllung (Diagnostik-Content `is_diagnostic=true` fehlt → Screening leer)
  - **C02 Grounded Rebuild abgeschlossen** (Retro `RETRO-C02.md`): VERA-Pool neu
    aufgebaut, jedes Feld mit `_grounding` belegt. **144 `ready`**, 74 `partial`,
    74 `doc_pending`. Die 216 „fertigen" Items aus C01 waren zu 47 % erfunden und
    sind ersetzt. Der Aufgabenstamm steckt als Text in den EMF-Vektorgrafiken der
    `.docx` — 188 Items wörtlich aus der Quelle, kein OCR.

## Nächste Schritte
- **P02-Migration deployen** (`20260713100000_p02_multipart.sql` — bisher nur lokal verifiziert)
- **C07: Import der 86 MULTI_PART-Items** (Trefferquote im Bestand ~40 % → Sichtung nötig)
- **`est_duration_sec` für die 14 LSA-Bestandsitems pflegen (Lena)** — bis dahin
  schätzt `lsa_start` das Zeitbudget über `estimated_minutes` (Retro 2026-07-13 §2)
- **`.doc` → `.docx` konvertieren (74 Items, Rasit/LibreOffice unter Windows)**,
  danach `bash scripts/content/c02_rebuild.sh` → Projektion **208 `ready`**
- Lena-Review von `data/vera8_review_lena.csv`, Priorität: die 33
  Vision-Transkripte (`stamm_quelle=vision_transkription`)
- Diagnostik-Content seeden (`is_diagnostic=true`) → `/screening` aktiv
- Browser-Verifikation (U4-Conversion, `/screening`-Flow) durch Rasit
- PR #16 — Base-Branch klären (`main` vs `dev`, CLAUDE.md §5) + mergen
- Mathebuch-Import (Lambacher Schweizer 8. Klasse NRW)
- Home-Quest Flow

## Fertig (Nachtrag Real-Data-Programm)
- U4: Onboarding + Lead-Konvertierung an `provisionStudent()` (Edge Function live)
- U5c: `/screening` DB-gestützt + DB-Resume; localStorage komplett raus
  (außer ThemeContext) — Mock-/localStorage-Entfernung abgeschlossen

---

# Feature-Matrix (validiert · Codebase-Audit Mai 2026)

Status: ✅ real & nutzbar · ⚠️ Backend/Schema da, UI fehlt · ❌ komplett offen
Aufwand: `UI` reine Oberfläche auf fertigem Schema · `BE+` kleine Backend-Arbeit ·
`NEU` echter Neubau (Schema + Logik + UI)

## Audit-Korrekturen gegenüber der ursprünglichen Tabelle
- Admin „Aufgaben-Import ✅ (Übersicht fehlt)" ist **umgekehrt**: Übersicht existiert
  (`DiagnosticsPage`, nach Fach/Cluster), **Bulk-Import fehlt** (nur Einzel-Anlage
  `pages/admin/diagnostics/NewTaskForm.tsx`).
- Eltern „nichts live" ist **teilweise falsch**: `ParentDashboard.tsx` existiert und
  zeigt veröffentlichte `parent_reports` + Fortschritt.
- Mehrere 🔴-Welle-1-Punkte sind **reine UI** auf fertigem Schema (Sessions, RLS,
  Lib-Layer existieren bereits) — deutlich billiger als ursprünglich eingestuft.

## Admin
| Feature | Status | Aufwand |
|---|---|---|
| Leads erfassen/kontaktieren/konvertieren/ablehnen | ✅ | — |
| Onboarding-Assistent (5 Schritte) | ✅ | — |
| Tarife anlegen & pflegen | ✅ | — |
| Aufgaben-Übersicht (nach Fach/Cluster) | ✅ | — |
| Screening Item Pool | ✅ | — |
| Aufgaben-**Bulk-Import** | ❌ | NEU |
| Coach anlegen | ✅ | Edge-Function `provision_coach` (Deploy nötig) |
| Stundenplan / Sitzungszuweisung | ✅ | `/admin/schedule` (Welle 1A) |
| Elternreport-Übersicht + Freigabe | ✅ | `/coach/reports`: Bestehende Reports + Freigeben |
| Spotlight-Suche, Quest/Badge-Gesamtübersicht, Coach-KPI, Eskalation | ❌ | NEU |

## Coach
| Feature | Status | Aufwand |
|---|---|---|
| Schülerübersicht (eigene Sessions) | ✅ | — |
| Screening-Ergebnisse einsehen | ✅ | — |
| Erstgespräch/Intake-Protokoll | ✅ | — |
| Tages-/Wochenplan (Filter über bestehende Liste) | ✅ | `/coach` Filter (Welle 1A) |
| Schüler-Kurzprofil pro Session | ✅ | Fortschritt; Klausur/Modus später (Welle 2) |
| Elternreport schreiben & freigeben (KI) | ✅ | Edge `generate_parent_report` (Deploy + Secret) |
| Eingriff-Tracking (Eingegriffen → Dauer → Gelöst) | ✅ | Migration 025 nötig |
| Home-Quest, Badge/XP-Verwaltung, OCR, Übergabe | ❌ | NEU |

## Schüler
| Feature | Status | Aufwand |
|---|---|---|
| Dashboard (Streak/XP/Level) | ✅ | — |
| Lernpfad / Cluster starten | ✅ | — |
| Skill-Tree (Kompetenzen) | ✅ | — |
| Aufgaben suchen | ✅ | — |
| Weitermachen (DB-abgeleitet, nächste offene Aufgabe) | ✅ | localStorage entfernt |
| Nächste Session anzeigen | ✅ | Welle 1A |
| Session-Flow (Check-in→…→Reflexion) | ❌ | NEU (größter Brocken) |
| Hausaufgaben hochladen | ❌ | NEU (Storage+Tabelle+RLS) |
| Klausurkalender, KI-Erklärartikel, Lexikon, Badges, Gruppen | ❌ | NEU |

## Eltern
| Feature | Status | Aufwand |
|---|---|---|
| Veröffentlichte Reports + Kind-Fortschritt ansehen | ✅ | — |
| Nächste Session anzeigen | ✅* | UI fertig (Welle 1A); *Migration 024 ausstehend |
| Elternreport (KI-generiert, alle 2 Wochen) | ✅ | Coach generiert/editiert/gibt frei; Eltern sehen Abschnitte |
| Kind-Daten vor Onboarding, HA/Klausur-Upload, Push, Multi-Kind | ❌ | NEU |

## Welle-Reihenfolge (nach echtem Aufwand neu sortiert)
- **1A — reine UI auf fertigem Schema:** Nächste Session (Schüler+Eltern) →
  Tagesplan Coach (Filter) → Stundenplan/Zuweisung (Admin-UI)
- **1B — kleine Backend-Arbeit:** Coach anlegen (RPC+Edge+UI, Rasit-Freigabe) →
  Eingriff-Tracking (1 Migration) → Schüler-Kurzprofil
- **1C — echte Neubauten:** Session-Flow Schüler → Hausaufgaben-Upload
- **Welle 2:** Elternreport (KI) bombensicher + Freigabeprozess → Home-Quest →
  Klausurkalender → KI-Erklärartikel → Eskalations-Trigger
- **Welle 3:** Gruppen/Community-Badges → Zeitmaschinen-Modus → Coach-KPI →
  globale Spotlight-Suche

## Fortschritt
- **Welle 1A komplett:** Nächste Session (S+E) · Admin-Stundenplan
  (`/admin/schedule`) · Coach-Tagesplan-Filter (`/coach`).
  Migration 024 (`coaching_sessions_parent_read`) ausgeführt ✅ — Eltern
  sehen Sessions.
- **Welle 1B:** Coach anlegen via `/admin/coaches` + Edge-Function
  `provision_coach` (deployt). Eingriff-Tracking: Tabelle `interventions`
  (Migration 025), Lib + „Eingegriffen/Gelöst" pro Schüler im
  Coach-Dashboard (SessionCard ausgelagert).
  Migration 025 (`interventions`) ausgeführt ✅.

- **Welle 1B komplett:** Schüler-Kurzprofil als inline ausklappbares
  Panel pro Schüler in der SessionCard (Level/XP/Streak + Klasse/Schule,
  lazy geladen). Klausurtermine + Modus zurückgestellt (Welle 2 / eigener
  1B-Mittel-Punkt — kein Schema dafür vorhanden).

- **Welle 2 gestartet:** Elternreport KI-gestützt. Edge-Function
  `generate_parent_report` (claude-sonnet-4-6, structured JSON, fail-closed
  Auth, Prompt-Caching System-Prompt) sammelt Fortschritt/Screening/
  Anwesenheit/Eingriffe → Entwurf. Coach editiert in `/coach/reports` und
  gibt frei; Eltern sehen die Abschnitte. Kein Schema-Change (nutzt
  vorhandenes `parent_reports`).
  Deployt + `ANTHROPIC_API_KEY` als Edge-Secret gesetzt ✅.
- **Coach↔Schüler-Zuordnung:** `/admin/assignments` — Schüler einem Coach
  zuweisen/umhängen/entfernen (`setStudentCoach`, ein aktiver Coach pro
  Schüler). Nutzt vorhandenes `student_coach` + RLS `student_coach_admin_all`,
  kein Schema-Change. Schließt die zuvor identifizierte UI-Lücke.
- **XP-/Task-Abschluss geschlossen:** `TaskPlayer` persistiert Abschluss nun
  via RPC `complete_task` (atomar, idempotent, SECURITY DEFINER) → `xp_events`
  → Trigger rechnet `student_progress` fort; positiver XP-Toast. XP-Gewichtung
  pro Inhaltstyp/Schwierigkeit admin-konfigurierbar (`/admin/xp-rules`,
  Tabelle `xp_rules`).
  Migration 026 (`xp_completion`, `xp_rules` + `complete_task`) ausgeführt ✅.

- **Kleine ⚠️-Lücken geschlossen + Matrix entstaubt:**
  - Elternreport-Übersicht: `/coach/reports` listet bestehende Reports des
    gewählten Schülers mit Status (Entwurf/Freigegeben) + „Freigeben" für
    Entwürfe (`listReportsForStudent`/`publishReport`).
  - „Weitermachen" jetzt DB-abgeleitet (`getResumePoint`): zuletzt erledigte
    Aufgabe → Cluster → nächste offene Aufgabe (Deep-Link `/student/task/:id`).
    `lib/lastCluster.ts` + localStorage entfernt (CLAUDE.md: kein localStorage
    außer ThemeContext).
  - Feature-Matrix gegen echten Code-Stand korrigiert (mehrere ⚠️→✅, die
    bereits in Welle 1A/1B erledigt waren).

- **Kosten-Guardrail KI-Elternreport:** Edge-Function
  `generate_parent_report` blockt jetzt fail-closed **vor** dem bezahlten
  Anthropic-Call (Limits per Secret: 30/Coach·Tag, 5/Schüler·7T, 3000/Monat
  global; Anrechnung nur bei Erfolg). Append-only Log `parent_report_generations`
  (Migration 027). Branch von `dev` (main bewusst nicht angefasst — der große
  dev→main-Release bleibt eigener Milestone mit Rasit).
  Migration 027 ausgeführt + verifiziert (RLS/Policy/Indizes) + Function
  deployt ✅.

- **v3 Midnight-Academy Reconciliation** (Branch `feature/v3-design-reconciliation`,
  Retro 2026-06-03): Audit ergab, dass `tokens.css` bereits ~100% spec-konform war.
  Angeglichen wurde die *Implementierung* an die verifizierte v1.0-Spec:
  MasteryBar 4→5 Stufen (API rückwärtskompatibel, `lib/mastery.ts` wiederverwendet),
  Glas-Effekte, 3-Layer-Student-Gradienten + App-BG-Textur, Animations-Timing
  (bounce + Scale + Spec-Dauern). Neue Living-Reference `/demo/v3`. TSC + Build grün.
  Offen: Browser-Check + Merge → `dev`.

- **A01 — Autoren-Tool für die Item-Pflege** (Branch `feat/A01-autorentool`,
  Retro `docs/retros/RETRO-A01.md`): `/admin/authoring` — Liste (Filter über
  Status/Fach/Kompetenz/AFB/Befunde/Asset/Tabelle), Editor (Stamm, Teilaufgaben,
  Tags inkl. **Stoffanker**, Assets mit Alt-Text, Lösung via
  `task_solution_upsert`), Live-Vorschau in der Kind-Ansicht, Freigabe-Gate
  `draft → review → ready` mit Prüfer + Zeitstempel. Read-only-Quellenbeleg
  (`_grounding`) neben dem Editor. Zugriff coach/admin, Schreiben nur Admin.
  TSC + Lint + 85 Tests + Build grün.
  **Blockiert auf Rasit:** `docs/schema/A01-authoring.proposal.sql` prüfen und
  ausführen (3 additive Felder/RPCs — Stoffanker, Lösungs-Lesepfad,
  Freigabe-Audit). Bis dahin läuft das Tool im Degraded-Modus. Danach: `lsa_start`
  auf `curriculum_grade` umstellen (eigener PR, **nach** der Pflege).

- **C08 — Neuextraktion als Draft im Autoren-Tool** (Branch `feat/C08-import-draft`,
  Retro `docs/retros/2026-07-14-C08-import-draft.md`): alle 299 Items aus
  `data/vera8_v2.json` sind als `draft` in `tasks` — **285 neu**, die 14 aus C03
  (`ready`) unangetastet. Lösungen ausschließlich über `task_solution_upsert`,
  kein `curriculum_grade` (Handarbeit), keine Lösung im `question_payload`.
  Idempotent über `(source, source_ref)`. **138 wären nach der Pflege pool-fähig**
  (es fehlen nur Stoffanker + Alt-Texte).
  Zwei Funde: (1) `public/authoring/grounding-vera8.json` wird **ohne Auth**
  ausgeliefert und enthielt die Lösungszitate von 209 Items — jetzt ohne
  Lösungsbelege gebaut, der Beleg liegt gegatet in `task_solutions.solution`;
  (2) `toPatch` hätte die F01-Tabelle von 54 Items beim ersten Speichern verworfen —
  jetzt read-only durchgereicht.
  **Offen:** Tabellen-Editor (54 Items), Pflege der 138.

- **B01 — Quellenbeleg bekommt ein Zuhause + RLS auf `tasks`** (Branch
  `fix/beleg-und-rls`, Retro `docs/retros/2026-07-14-B01-beleg-und-rls.md`):
  Migration `20260714140000_b01_beleg_und_rls.sql` (**noch nicht ausgeführt** —
  Schema-Session mit Rasit). Zwei Blocker vor der ersten Pflegesession:
  (1) `task_solutions.beleg jsonb` trennt den Quellenbeleg vom didaktischen
  Lösungsweg — bisher teilten sie sich `solution`, und wer einen Weg schrieb,
  löschte den Beleg. `task_solution_upsert` patcht jetzt pro Feld, das Tool zeigt
  den Beleg read-only.
  (2) `authenticated_read_tasks` (jeder Eingeloggte las jede Zeile, seit C08 also
  285 Drafts) → `read_tasks_by_role`: coach/admin alles, alle anderen nur `ready`.
  Beweis: `supabase/tests/inv7_draft_nicht_fuer_schueler.test.sql`.
  **Blockiert auf Rasit:** Migration im SQL-Editor ausführen, danach
  `npx supabase test db` (inv6 + inv7).

## Aktiver Slice
- **Welle 2 · weiter:** Home-Quest-Übersicht → Klausurkalender →
  KI-Erklärartikel → Eskalations-Trigger.
