import { beforeEach, describe, expect, it, vi } from 'vitest'

/**
 * INV-1 — Coach-only Mastery-Gate (FernUSG).
 *
 * Reale Symbole:
 *  · Writer: `grantMastery` in src/lib/supabase/competencyMastery.ts —
 *    der EINZIGE Client-Pfad, der public.student_competency_mastery schreibt
 *    (verifiziert per Discovery: kein weiterer `.from('student_competency_mastery')`
 *    mit insert/upsert/update in src/**).
 *
 * RLS-/Trigger-Abhängigkeit (bewusst server-seitig, NICHT im Client):
 *  · Die Rollen-Ablehnung (student/parent → verboten) erzwingt der DB-Gate-Trigger
 *    `trg_enforce_mastery_gate` / Funktion `enforce_mastery_gate()` aus
 *    migrations/040_competency_mastery.sql (+ schema.sql): setzt `mastered_by`/
 *    `mastered_at` selbst und wirft
 *    `raise exception 'Mastered darf nur durch Coach gesetzt werden (FernUSG)'`,
 *    wenn `get_my_role() not in ('coach','admin')`. Zusätzlich RLS-Policies
 *    `scm_coach_admin_insert` / `scm_coach_admin_update`.
 *  · Der Client hat daher KEINEN eigenen Rollen-Guard (per Design). Diese Suite
 *    testet, was client-seitig belegbar ist: (a) es existiert kein Codepfad, der
 *    die Coach-Identität selbst setzt, und (b) grantMastery respektiert eine
 *    Gate-Ablehnung, statt Erfolg zu fälschen.
 */

type QueryResult = { data: unknown; error: { message: string } | null }

interface Builder {
  insert(payload: unknown): Builder
  upsert(payload: unknown, _opts?: unknown): Builder
  update(payload: unknown): Builder
  delete(): Builder
  select(_cols?: string): Builder
  eq(_col: string, _val: unknown): Builder
  order(_col: string, _opts?: unknown): Builder
  single(): Promise<QueryResult>
  maybeSingle(): Promise<QueryResult>
}

const { tracker, supabaseMock } = vi.hoisted(() => {
  const writes: { table: string; op: string; payload: unknown }[] = []
  const tables: string[] = []
  // Was der DB-Gate simulieren soll: 'ok' → Coach, 'reject' → student/parent.
  const gate = { mode: 'ok' as 'ok' | 'reject' }

  const makeBuilder = (table: string): Builder => {
    const rec = (op: string, payload: unknown): Builder => {
      writes.push({ table, op, payload })
      return builder
    }
    const result = async (): Promise<QueryResult> =>
      gate.mode === 'reject'
        ? {
            data: null,
            error: { message: 'Mastered darf nur durch Coach gesetzt werden (FernUSG)' },
          }
        : { data: { student_id: 's1', mastered: true }, error: null }

    const builder: Builder = {
      insert: (p) => rec('insert', p),
      upsert: (p, _opts) => rec('upsert', p),
      update: (p) => rec('update', p),
      delete: () => rec('delete', null),
      select: (_cols) => builder,
      eq: (_col, _val) => builder,
      order: (_col, _opts) => builder,
      single: result,
      maybeSingle: result,
    }
    return builder
  }

  const supabase = {
    from: (table: string): Builder => {
      tables.push(table)
      return makeBuilder(table)
    },
  }

  return { tracker: { writes, tables, gate }, supabaseMock: { supabase } }
})

vi.mock('@/lib/supabase/client', () => supabaseMock)

// Nach dem Mock importieren, damit grantMastery den Mock-Client bekommt.
import { grantMastery } from '@/lib/supabase/competencyMastery'

const ARGS = { studentId: 's1', microskillId: 'm1', competencyId: 'c1' }

beforeEach(() => {
  tracker.writes.length = 0
  tracker.tables.length = 0
  tracker.gate.mode = 'ok'
})

describe('INV-1 — Coach-only Mastery-Gate', () => {
  it('grantMastery schreibt ausschließlich student_competency_mastery', async () => {
    await grantMastery(ARGS)
    expect(tracker.tables).toEqual(['student_competency_mastery'])
    expect(tracker.writes.map((w) => w.op)).toEqual(['upsert'])
  })

  it('setzt mastered=true, aber niemals mastered_by/mastered_at client-seitig', async () => {
    await grantMastery(ARGS)
    const payload = tracker.writes[0]?.payload as Record<string, unknown>
    expect(payload.mastered).toBe(true)
    // Die Coach-Identität vergibt ausschließlich der Gate-Trigger — nie der Client.
    expect(payload).not.toHaveProperty('mastered_by')
    expect(payload).not.toHaveProperty('mastered_at')
    // Es gibt keinen automatischen Score→mastered-Pfad hier: kein `score`-Write.
    expect(payload).not.toHaveProperty('score')
  })

  it('respektiert eine Gate-Ablehnung (student/parent) statt Erfolg zu fälschen', async () => {
    tracker.gate.mode = 'reject'
    const res = await grantMastery(ARGS)
    expect(res.data).toBeNull()
    expect(res.error).toMatch(/FernUSG/)
  })
})
