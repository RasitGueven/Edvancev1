// Zwei-Achsen-Kompetenz-Matrix (Migrationen 038 + 040).
// Achse B (Prozesskompetenz) als Referenzdaten + Mastery-Zustand pro
// (Schüler × Mikroskill × Prozesskompetenz). Das Schema ist eingefroren —
// diese Types spiegeln es 1:1; nicht erweitern ohne Foundation-Freigabe.

// Die 6 KMK-Prozesskompetenzen (process_competencies.code, Migration 038).
export type CompetencyCode = 'Ope' | 'Mod' | 'Pro' | 'Arg' | 'Kom' | 'Wkz'

// Eine Referenzzeile aus public.process_competencies.
export type ProcessCompetency = {
  id: string
  code: CompetencyCode
  name: string
  sort_order: number
}

// Abgeleitete 5-Stufen-Anzeige aus public.mastery_stage(score) (Migration 033).
// Schwellen: < 40 introduced, ≥ 40 developing, ≥ 60 progressing,
// ≥ 75 proficient, ≥ 85 mastered.
export type MasteryStage =
  | 'introduced'
  | 'developing'
  | 'progressing'
  | 'proficient'
  | 'mastered'

// Eine Zeile aus public.student_competency_mastery (Migration 040).
// `stage` ist eine generated column (read-only). `mastered` setzt strukturell
// nur der Coach-Gate-Trigger trg_enforce_mastery_gate (FernUSG) — ebenso
// `mastered_by` / `mastered_at`.
export type StudentCompetencyMastery = {
  student_id: string
  microskill_id: string
  competency_id: string
  score: number
  mastered: boolean
  mastered_by: string | null
  mastered_at: string | null
  updated_at: string
  stage: MasteryStage
}
