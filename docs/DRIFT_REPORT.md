# Drift-Report — Schema-Konsolidierung (Stand 2026-06-22)

Erstellt im Zuge der Konsolidierung von `migrations/001-036` + Basis-/Content-
Schema zu **einem** Single Source of Truth ([`schema.sql`](../schema.sql)).
Dieser Report listet **jede** Abweichung zwischen den Quellen, BEVOR sie
zusammengeführt wurden.

## Quellen-Legende

| Code | Quelle | Status |
|---|---|---|
| **A** | alte `schema.sql` (vor Konsolidierung) | ersetzt durch konsolidierte `schema.sql` |
| **B** | `schema_content.sql` | DEPRECATED markiert (Historie) |
| **C** | alte `docs/SCHEMA.md` | komplett neu geschrieben |
| **D** | `migrations/001_*.sql … 036_*.sql` | **Wahrheit** (Konfliktgewinner) |

**Konflikt-Regel:** Bei Widerspruch gewinnt **D** (Migration). Die konsolidierte
`schema.sql` bildet D ab (für Basis-/Content-Tabellen, die nicht von einer
nummerierten Migration erzeugt werden, gelten A bzw. B als Ausgangsbasis).

**Umfang Endzustand:** 33 Tabellen · 9 Funktionen · 2 Enums · 1 Trigger.

---

## 1. Funktionale Inkonsistenzen (echte latente Bugs)

| ID | Fundort | Befund | Auswirkung | Behandlung im Freeze |
|---|---|---|---|---|
| **D-01** | D (Migr. 019 vs 036) | `apply_xp_event()` liest/schreibt `student_progress.streak_days`; Migr. 036 droppt die Spalte; **keine** spätere Migration definiert die Funktion neu. | **Kritisch:** Beim nächsten `INSERT` in `xp_events` feuert der Trigger und schlägt fehl (`column "streak_days" does not exist`). Damit bricht auch die RPC `complete_task` (insertet `xp_events`). XP-/Task-Abschluss serverseitig defekt. | ✅ **Behoben in Migr. 037** (`037_fix_apply_xp_event.sql`): `apply_xp_event` ohne jede `streak_days`-/Datums-Streak-Logik neu geschrieben. `schema.sql`-Freeze bildet den reparierten Endzustand ab. (Zwei-Streak-Modell presence/home aus 032 bleibt separater Folge-Task.) |
| **D-11** | D (Migr. 022 vs 029) | `screening_item_results.cluster_id` ist `NOT NULL`; `screening_items.cluster_id` wurde in 029 nullable (VERA-8-Items ohne Cluster). | Ergebnisse zu VERA-Items ohne Cluster lassen sich nicht speichern (NOT-NULL-Verletzung), solange kein Ersatz-Cluster gesetzt wird. | Nur dokumentiert (Endzustand abgebildet). Empfehlung in Folge-Migration prüfen. |

---

## 2. Tabellen-Abdeckung pro Quelle

„✓" = Tabelle in Quelle vorhanden/definiert, „—" = fehlt, „(ref)" = nur
referenziert, aber nicht erzeugt.

| Tabelle | A (schema.sql) | B (content) | C (SCHEMA.md) | D (Migr.) | Drift-ID |
|---|:--:|:--:|:--:|:--:|---|
| profiles | ✓ | — | ✓ | (Basis) | — |
| students | ✓ | — | ✓ | (Basis) | — |
| parent_student | ✓ | — | ✓ | (Basis) | — |
| subjects | ✓ (CHECK) | ✓ (ohne CHECK) | ✓ | 006 | D-09 |
| student_subjects | ✓ | — | ✓ | (Basis/011) | — |
| skill_clusters | — | ✓ | ✓ | 001 | D-07 |
| microskills | — | ✓ | ✓ | 005 | D-07 |
| tasks | (ref) | ✓ | ✓ | 002/004/005/006/007/008/009 | D-07 |
| task_coach_metadata | — | ✓ | ✓ | — | D-07, D-10 |
| behavior_snapshots | (ref) | — | ✓ (nur Zusatzspalte) | 003/014 | **D-02** |
| leads | ✓ | — | ✓ | 012 | — |
| intake_sessions | ✓ | — | ✓ | 013 | — |
| screening_tests | ✓ | — | ✓ | 014/023 | — |
| screening_ratings | ✓ | — | ✓ | 014 | — |
| screening_items | ✓ | — | ✓ | 022/028/029 | D-14 |
| screening_item_results | ✓ | — | ✓ | 022/028 | — |
| screening_item_ratings | ✓ | — | **—** | 028 | D-12 |
| tiers | ✓ | — | ✓ | 015 | — |
| student_subscriptions | ✓ | — | ✓ | 015 | — |
| student_coach | ✓ | — | ✓ | 016 | — |
| coaching_sessions | ✓ | — | ✓ | 017/024 | — |
| session_students | ✓ | — | ✓ | 017 | — |
| student_task_progress | ✓ | — | ✓ | 018 | — |
| student_progress | ✓ (mit streak_days) | — | ✓ (mit streak_days) | 019/032/036 | **D-03/D-13** |
| xp_events | ✓ | — | ✓ | 019 | — |
| xp_rules | ✓ | — | **—** | 026 | D-12 |
| interventions | ✓ | — | **—** | 025 | D-12 |
| parent_reports | ✓ | — | ✓ | 020 | — |
| parent_report_generations | **—** | — | ✓ | 027 | **D-04** |
| student_focus_areas | ✓ | — | **—** | 030 | D-12 |
| badge_catalog | **—** | — | **—** | 034 | D-05, D-12 |
| student_badges | **—** | — | **—** | 034 | D-05, D-12 |
| streak_repair_inventory | **—** | — | **—** | 035 | D-05, D-12 |

---

## 3. Strukturelle Drifts: alte `schema.sql` (A) vs. Migrationen (D)

| ID | Befund | Detail |
|---|---|---|
| **D-02** | A erzeugt `behavior_snapshots` **nie**, referenziert sie aber | A enthält `alter table behavior_snapshots add column screening_test_id …` (Migr. 014-Spiegel) und einen FK aus `screening_ratings`, ohne die Tabelle zu erzeugen. → A war als Greenfield-Skript **nicht lauffähig**. Erzeugt nur in Migr. 003. |
| **D-03** | A zeigt `student_progress` mit `streak_days`, ohne Zwei-Streak-Modell | A: `(student_id, xp_total, streak_days, level, last_activity)`. Real (D, nach 032+036): `streak_days` weg; zusätzlich `presence_streak_weeks/_last_week_start/_multiplier`, `home_streak_sessions/_last_completed_at`. |
| **D-04** | A fehlt Tabelle `parent_report_generations` (Migr. 027) | A springt von Migr. 026 direkt zu 028. C kannte die Tabelle, A nicht. |
| **D-05** | A fehlen alle Objekte aus Migr. 032–036 | Zwei-Streak-Spalten (032), Funktionen `calc_presence_multiplier`/`mastery_stage`/`mastery_stage_from_level` (032/033), Enums `badge_rarity`/`badge_form` + `badge_catalog` + `student_badges` (034), `streak_repair_inventory` (035), `drop streak_days` (036). |
| **D-06** | A fehlen die `task-assets`-Storage-Policies (Migr. 010) | A enthält die `screening-uploads`-Policies (031), aber nicht die drei `admin_*_task_assets`-Policies. |
| **D-07** | Content-Tabellen außerhalb A; `subjects` doppelt definiert | `skill_clusters`/`microskills`/`tasks`/`task_coach_metadata` nur in B; A referenziert `tasks` (FK aus `student_task_progress`, `xp_events`). `subjects` ist in A **und** B definiert (mit/ohne CHECK). → Vor Konsolidierung existierte **kein** einzeln lauffähiges Schema-Skript. |

---

## 4. Drifts: `schema_content.sql` (B) vs. Migrationen (D)

| ID | Befund | Detail / Auflösung |
|---|---|---|
| **D-08** | B trägt „Stand: Migration 009 inklusive" und ist ein separates manuelles Greenfield-Skript | Keine nummerierte Migration ändert nach 009 noch die Content-Tabellen, daher strukturell vollständig für ihren Scope — aber als zweite „Wahrheit" Drift-Risiko. **Auflösung:** B als DEPRECATED markiert, Inhalt in `schema.sql` übernommen. |
| **D-09** | `subjects.name` CHECK-Constraint-Konflikt | A: `name text not null CHECK (name in ('Mathematik','Deutsch','Englisch'))`. B: `name text not null` + Hinweis „`alter table subjects drop constraint if exists subjects_name_check;`". **Auflösung:** Effektiver Stand = **ohne** CHECK (B-Anweisung); konsolidierte `schema.sql` definiert `name` ohne CHECK. ⚠️ Real-DB verifizieren (manueller Schritt). |
| **D-10** | `task_coach_metadata`: RLS aktiv, nur Read-Policy, **kein** Write-Policy | Aus B übernommen. Mit aktiver RLS ist damit **kein** Client-Write möglich (analog zum vor Migr. 011 latenten `students`-Bug). Nur dokumentiert, nicht geändert. |

---

## 5. Drifts: alte `docs/SCHEMA.md` (C) vs. Migrationen (D)

| ID | Befund | Detail |
|---|---|---|
| **D-12** | C fehlen 7 Tabellen | `interventions` (025), `xp_rules` (026), `screening_item_ratings` (028), `student_focus_areas` (030), `badge_catalog` + `student_badges` (034), `streak_repair_inventory` (035). |
| **D-13** | C `student_progress` veraltet | gelistet: `xp_total, streak_days, level, last_activity`. Real: kein `streak_days`, dafür Zwei-Streak-Spalten (032/036). |
| **D-14** | C `screening_items` veraltet | C: `input_type(MC|NUMERIC|MATCHING|STEPS_FINAL)`, `check_type(mc_index|numeric|matching_set|normalized)`, ohne `afb`/`phase` (028) und ohne VERA-8-Spalten + `OPEN`/`manual` (029). |
| **D-15** | C Funktions-/Enum-Liste unvollständig | C listet nur die 3 Security-Definer-Helper. Fehlen: `calc_presence_multiplier`, `mastery_stage`, `mastery_stage_from_level`, Enums `badge_rarity`/`badge_form`. (Mastery als Level 1..10 + Funktion war in C gar nicht beschrieben.) |
| **D-16** | C „SQL-Dateien"-Liste endet bei Migr. 027 | Migr. 028–036 nicht gelistet; `schema.sql` als „Auth + Schueler-Tabellen (initial)" beschrieben (längst überholt). |

---

## 6. Type-Drift: `src/types/*.ts` vs. konsolidiertes Schema

> Auftrag: **nur Report**, keine Types automatisch generieren/ändern.
> Legende Richtung: „Type→DB" = Type hat mehr/strenger; „DB→Type" = Schema hat
> Feld, Type fehlt.

| ID | Datei / Typ | Richtung | Befund | Empfehlung |
|---|---|---|---|---|
| **T-01** | `screening.ts` `ScreeningInputType` | Type→DB | Enthält `'CLOZE_DND'`, `'TABLE_LABEL'` — **nicht** im DB-CHECK (`MC|NUMERIC|MATCHING|STEPS_FINAL|OPEN`). | Entweder DB-CHECK erweitern (Migration) oder Type-Werte entfernen. |
| **T-02** | `screening.ts` `ScreeningCheckType` | Type→DB | Enthält `'slot_map'` — **nicht** im DB-CHECK (`mc_index|numeric|matching_set|normalized|manual`). | Wie T-01. |
| **T-03** | `screening.ts` `ScreeningItem` | Type→DB | Felder `cluster_id, topic, skill_code, skill_label, level, prompt, canonical` sind als **non-null** typisiert; DB machte sie in 029 **nullable**. | Type auf `| null` lockern. |
| **T-04** | `screening.ts` `ScreeningItem` | DB→Type | Type kennt nur `kontext`, `teilaufgaben`, `akzeptierte_antworten`. DB-Spalten **fehlen** im Type: `iqb_titel, kompetenzfelder, aufgabe_typ, loesung_pro_ta, kodierung, kommentar_highlights, urls, datei_ext, quelle, fix_anker, meta`. | Optional ergänzen, falls Frontend sie braucht. |
| **T-05** | `session.ts` `StudentProgress` | Type→DB | `streak_days?: number` weiterhin vorhanden (mit Kommentar „bis Migr. 036 in prod"). DB hat die Spalte nach 036 **gedroppt**. | `streak_days` entfernen, sobald 036 produktiv. |
| **T-06** | `diagnosis.ts` `BehaviorSnapshot` | beide | Capture-DTO, nicht 1:1 Row: **fehlen** `id, user_id, submitted_at, screening_test_id`; **extra** `coach_rating` (ist **keine** Spalte von `behavior_snapshots`, sondern `screening_ratings.rating`). | By-Design (Client-Capture). Als bewusst kennzeichnen; kein Row-Type. |
| **T-07** | `content.ts` `TaskCoachMetadata` | DB→Type | DB-Spalte `updated_at` fehlt im Type. | Bei Bedarf ergänzen. |
| **T-08** | — | DB→Type | **Kein** Row-Type für `parent_report_generations`. | Akzeptabel: Tabelle nur Service-Role (Edge Function), kein Frontend-Read mit Row-Mapping. |

**Geprüft ohne Drift** (Beispiele): `domain.ts` (`Lead`/`Student`/`IntakeSession`/
`TierPlan`/`StudentSubscription`/`StudentCoach`), `session.ts`
(`CoachingSession`/`SessionStudent`/`Intervention`/`StudentTaskProgress`/`XpEvent`/
`XpRule`/`ParentReport`), `gamification.ts` (`Badge`/`StudentBadge`/
`StreakRepairInventory`), `content.ts` `Task`/`InputType`/`ContentType`,
`auth.ts` `UserRole`.

---

## 7. Zusammenfassung & Empfehlungen

- **Erledigt (funktional):** **D-01** (kaputter `apply_xp_event`-Trigger, der
  XP/Task-Abschluss blockierte) ist mit `037_fix_apply_xp_event.sql` **behoben**
  und im `schema.sql`-Freeze abgebildet.
- **Datenmodell prüfen:** **D-11** (NOT-NULL `cluster_id` auf
  `screening_item_results` vs. VERA-Items ohne Cluster).
- **Manuell verifizieren:** **D-09** (ist `subjects_name_check` in der Real-DB
  wirklich gedroppt?).
- **RLS-Lücke:** **D-10** (`task_coach_metadata` ohne Write-Policy).
- **Type-Abgleich:** T-01..T-05 sind echte Frontend/DB-Diskrepanzen; T-06..T-08
  sind by-design/akzeptabel.

**Gesamtzahl Einträge in diesem Report: 24** (16 × Schema-Drift `D-01…D-16` +
8 × Type-Drift `T-01…T-08`).
