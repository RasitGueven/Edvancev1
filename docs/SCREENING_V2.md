# Edvance — Screening v2 (AFB + Phasen + manuelle Bewertung)

> **Status:** Spec-Draft, parallel zur Migration 028 entstanden.
> Algorithmische Details an den als **TBD** markierten Stellen
> brauchen vor Code-Beginn eine Entscheidung von Rasit.
> v1 (`docs/screening.md`, adaptive L1/L2/L3-Treppe) bleibt parallel
> aktiv, bis der v2-Pool ausreichend gefüllt ist (Coexistenz, kein
> Big-Bang-Cutover).

## 1. Warum v2

v1 misst **Schwierigkeit** über `level` (L1/L2/L3) — eine eindimensionale
Treppe. Coaches und Eltern lesen den Bericht aber kognitiv: *„Hat das
Kind reproduziert, transferiert oder selbstständig problemgelöst?"*
Das ist der **AFB-Begriff der KMK** (Anforderungsbereich I/II/III) und
unabhängig von Schwierigkeit. v2 entkoppelt beide Dimensionen, lässt die
Item-Bank in **zwei Phasen** laufen (kurze Sprint-Erhebung +
tiefergehende Fragen, die der Coach manuell bewertet) und produziert pro
Skill ein **erreichtes AFB-Niveau** statt eines reinen Level-Scores.

## 2. Was bleibt, was ändert sich (Brownfield)

| Element | v1 | v2 |
|---|---|---|
| `screening_items.level` | Primärsignal | bleibt, optional, wird vom v2-Aggregator nicht mehr ausgewertet |
| `screening_items.afb` | – | **neu**, nullable; v2-Pool-Filter |
| `screening_items.phase` | – | **neu** (`sprint` \| `tiefe`); v2-Pool-Filter |
| `input_type` | MC/NUMERIC/MATCHING/STEPS_FINAL | + `OPEN` |
| `check_type` | mc_index/numeric/matching_set/normalized | + `manual` |
| `screening_item_results.correct` | `not null` | nullable (OPEN: NULL bis Coach bewertet) |
| `screening_item_ratings` | – | **neu**: append-only Coach-Bewertung pro offener Antwort |
| Adaptiver Controller | clientseitige Treppe | **TBD** (siehe §3) |

**Regel zur Coexistenz:** v2-Selektion filtert hart auf
`afb IS NOT NULL AND phase IS NOT NULL AND active = true`. v1-Items
bleiben unangetastet im Legacy-Pfad nutzbar. Kein Backfill.

## 3. Phasen-Flow

Ein Screening-Lauf läuft in **zwei Phasen** sequentiell. Beide Phasen
sind weiterhin **still** für das Kind (CLAUDE §6 — kein
richtig/falsch-Feedback).

### 3.1 Phase „Sprint" (autogradebar)

- **Items:** `phase = 'sprint'`, `input_type ∈ {MC, NUMERIC, MATCHING,
  STEPS_FINAL}`, `check_type ≠ 'manual'`.
- **Zweck:** schnelles Abdeckungssignal über alle Cluster, primär
  **AFB I + II**.
- **Bewertung:** Auto-Grader (`src/lib/screening/grade.ts`),
  `screening_item_results.correct` wird sofort gesetzt.
- **Dauer-Ziel:** ~8–12 Min.
- **Selektion:** TBD-A (siehe §6).

### 3.2 Phase „Tiefe" (manuell)

- **Items:** `phase = 'tiefe'`, `input_type = 'OPEN'`,
  `check_type = 'manual'`. Cross-Constraint auf DB-Ebene erzwungen.
- **Zweck:** **AFB II + III**, Reasoning sichtbar machen, Transfer und
  Problemlösen erfassen — typischerweise offene Aufgaben (Begründungen,
  Mehrschritter, Modellierung).
- **Antwort:** Kind tippt Freitext (kein Feedback). Insert in
  `screening_item_results` mit `answer = {text}`, `correct = NULL`.
- **Bewertung:** **post-hoc durch Coach** im Coach-Dashboard. Coach
  vergibt `reached_afb ∈ {I, II, III}` (NULL = unter I, nicht erreicht)
  + optional `note`. Append-only: Korrektur = neuer Eintrag in
  `screening_item_ratings`, „letzte gilt" via `created_at DESC`.
- **Dauer-Ziel:** ~5–8 Min im Test selbst; Coach-Review davon entkoppelt.
- **Selektion:** TBD-B.

### 3.3 Übergang

- Sprint endet bei Zeit- oder Fragenbudget → unmittelbar Tiefe.
- Tiefe endet bei Zeit- oder Fragenbudget.
- Test ist „eingegeben", aber erst **„auswertbar"** wenn alle
  `phase='tiefe'`-Results eine aktuellste Rating in
  `screening_item_ratings` haben. UI-Status dafür: TBD-C.

## 4. AFB-Aggregator

Ziel: pro `(student_id, skill_code)` ein **erreichtes AFB** ableiten.

### 4.1 Regel (Vorschlag, TBD-D)

1. Pro Skill alle Results des aktuellen Tests sammeln.
2. Pro Result das **„nachgewiesene AFB"** bestimmen:
   - Sprint, `correct = true` → AFB des Items als nachgewiesen.
   - Sprint, `correct = false` → kein Nachweis (NULL).
   - Tiefe → letztes `screening_item_ratings.reached_afb` (NULL = unter
     I, nicht erreicht).
3. **Erreichtes AFB des Skills = höchstes AFB**, das mindestens einmal
   nachgewiesen wurde. Reihenfolge: III > II > I > „nicht erreicht".
4. Falls für einen Skill keine Items beantwortet wurden → „nicht
   abgedeckt" (kein Aggregat, kein Crash, EmptyState im Report).

### 4.2 Cluster-Rollup (TBD-E)

Vom Skill aufs Cluster: Mehrheits-AFB? Niedrigstes? Durchschnitt? —
inhaltlich zu entscheiden, hat Auswirkung auf den Elternreport. Default-
Vorschlag: **Median über die abgedeckten Skills im Cluster**.

### 4.3 Persistenz

Aggregat lebt in `screening_tests.result_summary` (JSON), parallel zum
v1-Aggregat. Keine neue Tabelle. Schema des JSON: TBD-F (Schlüssel
`per_skill: { [skill_code]: 'I'|'II'|'III'|null }`,
`per_cluster: { [cluster_id]: 'I'|'II'|'III'|null }`).

## 5. Item-Selektion

### 5.1 Pool

```sql
select * from screening_items
where active = true
  and afb is not null
  and phase is not null
  and cluster_id = $cluster
  and phase = $phase                 -- 'sprint' oder 'tiefe'
  and class_level = $class_level
  and skill_code not in ($excluded_topics)  -- aus intake_sessions
```

Index `screening_items_v2_pool_idx` deckt das.

### 5.2 Heuristik Sprint (TBD-A)

Default-Vorschlag: pro Cluster je **1 Item AFB I + 1 Item AFB II**,
gewichtet nach `known_weak_topics` aus dem Intake. AFB III gehört in die
Tiefe und nicht in den Sprint (sonst kein Reasoning-Nachweis möglich).

### 5.3 Heuristik Tiefe (TBD-B)

Default-Vorschlag: pro Cluster **1 Item AFB II + 1 Item AFB III**, klein
gehalten — manuelle Bewertung ist teuer. Alternativ: nur Cluster mit
schwachem Sprint-Signal vertiefen (dynamisch). Inhaltliche Entscheidung
notwendig.

## 6. Offene Punkte (vor Code zu klären)

- **TBD-A**: exakte Sprint-Heuristik (Items pro Cluster, AFB-Mix,
  Gewichtung Intake).
- **TBD-B**: Tiefe statisch (fester Mix) oder dynamisch (nur schwache
  Cluster vertiefen)?
- **TBD-C**: UI-Zustand „wartet auf Coach-Rating" — gehört in
  `screening_tests.status`? Neue Werte (`pending_rating`,
  `complete`)? Schema-Änderung folgt erst nach Entscheidung.
- **TBD-D**: Aggregator-Regel (Vorschlag: höchstes nachgewiesenes AFB)
  bestätigen — alternativ „dominante AFB" oder „erforderliche Kette
  I→II→III".
- **TBD-E**: Cluster-Rollup (Median / Mehrheit / Minimum).
- **TBD-F**: JSON-Schema in `result_summary` festschreiben.
- **TBD-G**: Resume-Verhalten bei Tiefe-Phase (Freitext-Eingaben sind
  länger – Auto-Save pro Item nötig?).

## 7. Sicherheits- und RLS-Hinweise

- `screening_item_ratings`: Coach + Admin schreiben/lesen. Schüler und
  Eltern lesen **nicht direkt** (auch nicht über Joins) — Bewertungen
  würden sonst indirekt Auto-Grade-Ergebnisse leaken (CLAUDE §6). Eltern
  sehen Aggregate ausschließlich über den vom Coach kuratierten Bericht.
- Ratings sind **append-only** (keine UPDATE/DELETE-Policy). Korrektur =
  neuer Eintrag.
- v2-Pool-Filter wird im Frontend **und** im Selection-Lib gleichzeitig
  angewendet — nie nur clientseitig.

## 8. Implementations-Reihenfolge (vorgeschlagen)

1. ✅ Migration 028 (Schema) — committet, wartet auf Rasit zur
   Ausführung im Supabase SQL Editor.
2. Spec-Punkte TBD-A bis TBD-G entscheiden (dieses Dokument
   nachschärfen).
3. Lib-Schicht: `src/lib/screening/v2/` mit `selectSprintPool`,
   `selectTiefePool`, `aggregateAfb` — rein deterministisch, testbar.
4. Coach-UI: Bewertungsmaske für offene Antworten (neue Route in
   `/coach/...`), schreibt nach `screening_item_ratings`.
5. Schüler-UI: Phasen-Flow erweitern (`OPEN`-Input-Komponente, Tiefe-
   Phase nach Sprint-Phase).
6. Aggregator in `result_summary`; Elternreport-Anbindung.
7. Seed-Items: ein Cluster pilotweise vollständig in v2 anlegen,
   Coach + Rasit reviewen, dann Bank ausrollen.
