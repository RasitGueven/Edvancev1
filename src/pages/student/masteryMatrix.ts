// Lokale Präsentations-Helfer für die Zwei-Achsen-Kompetenz-Matrix im
// Schüler-Bereich (Achse B = Prozesskompetenz). NUR Darstellung + Aggregation:
// keine Logik-/Schema-/lib-Änderung, kein Schreiben. Der FernUSG-Anzeigeguard
// (Hard Rule §6) lebt bewusst HIER lokal und NICHT in shared lib — Ownership
// des Student-Fensters. Würde Parent ihn später brauchen, wandert er separat
// ins Foundation-Fenster.

import { masteryStage, type MasteryStage } from '@/lib/mastery'
import type { StudentCompetencyMastery } from '@/types'

// Ergebnis des Anzeigeguards: die anzuzeigende Stufe + ob sie an der
// „mastered"-Schwelle steht und auf die Coach-Bestätigung wartet (Anticipation).
export type MasteryDisplay = {
  // Niemals 'mastered' ohne Backend-Bestätigung (FernUSG-Invariante unten).
  stage: MasteryStage
  // score ≥ 85, aber (noch) nicht jede beitragende Zelle ist `mastered`.
  awaitingConfirmation: boolean
  // 0..100 für die Balkenbreite (Durchschnitt der beitragenden Zellen).
  score: number
}

/**
 * FernUSG-Anzeigeguard (Hard Rule §6) über eine oder mehrere Matrix-Zellen.
 *
 * Die angezeigte Stufe wird NICHT direkt aus dem Score abgeleitet, sondern aus
 * dem Backend-Feld `mastered`:
 *  · `mastered === true` für JEDE Zelle  → Stufe „mastered" (Gemeistert erlaubt).
 *  · berechnete Stufe wäre „mastered" (Ø score ≥ 85), aber nicht bestätigt
 *      → auf „proficient" gedeckelt + awaitingConfirmation (flippt nicht von
 *        allein, wird in der Session bestätigt).
 *  · sonst → die berechnete Stufe (≤ proficient) normal.
 *
 * INVARIANTE: `stage === 'mastered'` wird ausschließlich zurückgegeben, wenn
 * `rows.every(r => r.mastered)`. Für eine einzelne Zelle ist das exakt der
 * Per-Zell-Guard `row.mastered === true`.
 */
export function aggregateMastery(
  rows: StudentCompetencyMastery[],
): MasteryDisplay | null {
  if (rows.length === 0) return null
  const avg = rows.reduce((sum, r) => sum + r.score, 0) / rows.length
  const raw = masteryStage(avg)

  if (raw === 'mastered') {
    if (rows.every((r) => r.mastered)) {
      return { stage: 'mastered', awaitingConfirmation: false, score: avg }
    }
    return { stage: 'proficient', awaitingConfirmation: true, score: avg }
  }
  return { stage: raw, awaitingConfirmation: false, score: avg }
}

// Matrix-Zeilen nach competency_id bündeln (für die Achse-B-Aufschlüsselung).
export function groupByCompetency(
  rows: StudentCompetencyMastery[],
): Map<string, StudentCompetencyMastery[]> {
  const grouped = new Map<string, StudentCompetencyMastery[]>()
  for (const row of rows) {
    const list = grouped.get(row.competency_id)
    if (list) list.push(row)
    else grouped.set(row.competency_id, [row])
  }
  return grouped
}

// Balkenbreite in Prozent, sauber auf 0..100 geklemmt.
export function masteryWidthPct(score: number): number {
  return Math.round(Math.min(100, Math.max(0, score)))
}

/**
 * Warme, defizit-vermeidende Mikrocopy zu einer Stufe (lokale Schwäche statt
 * globalem Versagen — nie „du kannst X nicht"). Bewusst hart-deutsch wie der
 * Rest der Schüler-Surfaces (ClusterView/ClusterGrid sind noch nicht i18n).
 */
export function stageCaption(display: MasteryDisplay): string {
  if (display.awaitingConfirmation) {
    return 'Fast geschafft – wird in der Session bestätigt'
  }
  switch (display.stage) {
    case 'mastered':
      return 'Von deinem Coach bestätigt'
    case 'proficient':
      return 'Sicher unterwegs'
    case 'progressing':
      return 'Auf gutem Weg'
    case 'developing':
      return 'Noch im Aufbau'
    case 'introduced':
      return 'Gerade gestartet'
  }
}
