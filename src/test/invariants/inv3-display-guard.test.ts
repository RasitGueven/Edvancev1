import { describe, expect, it } from 'vitest'

import { aggregateMastery } from '@/pages/student/masteryMatrix'
import type { StudentCompetencyMastery } from '@/types'

/**
 * INV-3 — FernUSG-Display-Guard.
 *
 * Reales Symbol: `aggregateMastery` in src/pages/student/masteryMatrix.ts — der
 * Anzeigeguard, den ClusterView/StudentDashboard konsumieren (Kommentar
 * ClusterView.tsx:227 „Gemeistert erscheint nur über den FernUSG-Guard").
 *
 * Statt schwergewichtiger Component-Tests (die den ganzen Supabase-/Auth-/i18n-/
 * Router-Kontext mocken müssten) wird der Guard direkt getestet — dort lebt die
 * Invariante, und die Render-Schicht leitet die Stufe 1:1 aus seinem Ergebnis ab.
 *
 * INVARIANTE: `stage === 'mastered'` NUR wenn `rows.every(r => r.mastered)` —
 * eine hohe Lösungsquote (score ≥ 85) allein reicht nie.
 */

// Baut eine Matrix-Zelle; nur score + mastered sind für den Guard relevant.
function cell(score: number, mastered: boolean): StudentCompetencyMastery {
  return {
    student_id: 's1',
    microskill_id: 'm1',
    competency_id: 'c1',
    score,
    mastered,
    mastered_by: mastered ? 'coach-1' : null,
    mastered_at: mastered ? '2026-01-01T00:00:00.000Z' : null,
    updated_at: '2026-01-01T00:00:00.000Z',
    stage: 'introduced',
  }
}

describe('INV-3 — Display-Guard: kein "mastered" ohne Coach-Bestätigung', () => {
  it('hohe Lösungsquote ohne Coach-Flag → NICHT mastered (auf proficient gedeckelt)', () => {
    const display = aggregateMastery([cell(95, false)])
    expect(display?.stage).not.toBe('mastered')
    expect(display?.stage).toBe('proficient')
    expect(display?.awaitingConfirmation).toBe(true)
  })

  it('score ≥ 85 aber nicht alle Zellen bestätigt → NICHT mastered', () => {
    const display = aggregateMastery([cell(100, true), cell(90, false)])
    expect(display?.stage).not.toBe('mastered')
    expect(display?.awaitingConfirmation).toBe(true)
  })

  it('mastered nur wenn JEDE beitragende Zelle mastered ist', () => {
    const display = aggregateMastery([cell(90, true), cell(88, true)])
    expect(display?.stage).toBe('mastered')
    expect(display?.awaitingConfirmation).toBe(false)
  })

  it('selbst score 100 mit mastered=false wird nie mastered', () => {
    const display = aggregateMastery([cell(100, false)])
    expect(display?.stage).not.toBe('mastered')
  })

  it('leere Matrix → kein Display (kein Default-mastered)', () => {
    expect(aggregateMastery([])).toBeNull()
  })
})
