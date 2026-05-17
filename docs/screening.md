# Edvance — Adaptives Screening (Konzept, festgeschrieben)

Dieses Dokument hält die vereinbarte Screening-Logik dauerhaft fest
(überlebt `/clear`/Session-Wechsel). Quelle der Wahrheit für die
Umsetzung.

## Ziel

Adaptiver, **vom System auto-bewerteter**, **stiller** Test (~20 Min,
spielhaft), der das Können eines Kindes **pro Kompetenz-Cluster**
einsortiert. Das Kind sieht **nie** richtig/falsch (CLAUDE.md §6) —
Auswertung nur intern für Coach/Report.

## Item-Modell (`screening_items`, Migration 022)

- Eigene **Original-Item-Bank**, getrennt von `tasks` (Lerninhalte).
  Rechtssicher: NRW-KLP/VERA nur als Kompetenz-Gerüst, **kein** fremder
  Ausdruck (kein Lambacher-Paraphrasieren).
- Granularität: **atomare Mikroskills** — Cluster → Themengebiet →
  atomarer Skill (z. B. *Algebra & Funktionen → Brüche → Brüche
  auflösen*). Felder: `cluster_id`, `topic`, `skill_code`, `skill_label`.
- Pro atomarem Skill je **Stufe L1/L2/L3** (`level`).
- Autogradebar: `input_type` ∈ MC | NUMERIC | MATCHING | STEPS_FINAL;
  `check_type` ∈ mc_index | numeric (`tolerance`) | matching_set |
  normalized; `canonical` = Sollantwort. Auto-Grader:
  `src/lib/screening/grade.ts` (rein, deterministisch, clientseitig).
- `curriculum_seq` = Lambacher-Kapitel-Proxy (Jahresverlauf
  Anfang/Mitte/Ende).
- `active=false` bis fachlicher Review; Schüler sehen nur `active=true`.

## Adaptiver Ablauf (clientseitiger Controller, kein Server-Roundtrip)

1. **Setup**: Schüler + Klasse/Fach; Erstgespräch (`intake_sessions`):
   `excluded_topics` → **harter Pool-Filter**, `known_weak_topics` +
   `goal` → **Gewichtung**.
2. **Warm-up (~5–7 Min)**: je Cluster 1 Item auf **L1** → grobe Baseline.
3. **Fokus (~13 Min)**: pro Cluster **Treppe**, Start **L2**:
   richtig → L+1, falsch → L−1; interne Fähigkeits­schätzung;
   2–4 Items je Cluster; Restbudget in unsicherste/schwächste Cluster;
   Stopp bei stabilem Niveau, Zeit- oder Fragenbudget (~20 Min gesamt).
4. **Robust**: fehlende Stufe/fehlendes Cluster-Item → überspringen,
   Cluster als „nicht abgedeckt" markieren (kein Crash; EmptyState bei 0).
5. **Ergebnis**: Cluster → erreichtes Niveau → Skill-Level (1–10)/Mastery
   (Aggregationsmuster aus `buildDiagnosisResult`) →
   `screening_tests.result_summary`; pro Item ein Eintrag in
   `screening_item_results` (append-only).
6. **Coach = Beobachter** (kein Coach-Rating mehr fürs Screening).
   Resume aus persistiertem Pfad.

## Scope & Entscheidungen

- **Klasse 8** zuerst (einzige Taxonomie). Volle Abdeckung
  **clusterweise** generiert + reviewt (Batch ~30–45 Items), ~150–180
  Items gesamt (≈ 50–60 atomare Skills × L1/L2/L3).
- Review/Freigabe: **DB (`active=false`) + Admin-UI**
  (`/admin/screening-items`).
- Item-Entwürfe werden generiert, **fachlicher Review Pflicht** vor
  `active=true`.
- Engine baut robust auch bei dünnem Pool; Bank wächst iterativ.
- Klasse 9/10 = separater Strang (Taxonomie + Items fehlen).
- Branch-Strategie: feature → **dev** → main (immer erst dev).

## Status

Siehe `/root/.claude/plans/…` (Phasenplan) bzw. `docs/retros/`. P1 =
Schema (Migration 022) + Lib (`screeningItems.ts`, `grade.ts`) + diese
Doku.
