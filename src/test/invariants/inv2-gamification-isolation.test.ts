import { beforeEach, describe, expect, it, vi } from 'vitest'

/**
 * INV-2 — Gamification-Abschluss ohne Lernpfad-/Mastery-Einfluss (FernUSG).
 *
 * Hinweis zur Repo-Realität: Ein benanntes „Home Quest"-Feature existiert im
 * Code (noch) NICHT (Discovery: keine home_quest/Quest-Symbole; alle „quest"-
 * Treffer sind `parseQuestion`). Der reale Gamification-Abschluss-Pfad ist die
 * XP-Vergabe `awardXp` in src/lib/supabase/progress.ts. Diese Suite testet die
 * dahinterliegende Invariante direkt am realen Symbol: ein Gamification-Write
 * verändert AUSSCHLIESSLICH Gamification-Daten (xp_events) — niemals
 * student_competency_mastery, Mastery-Felder oder Lernpfad-Zustand.
 *
 * Server-seitig aktualisiert der Trigger `apply_xp_event` (Migration 019)
 * student_progress aus xp_events — der Client kann Totals nicht fälschen und
 * schreibt keine Mastery-Tabelle.
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

  const makeBuilder = (table: string): Builder => {
    const rec = (op: string, payload: unknown): Builder => {
      writes.push({ table, op, payload })
      return builder
    }
    const result = async (): Promise<QueryResult> => ({
      data: { id: 'xp-1' },
      error: null,
    })
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

  return { tracker: { writes, tables }, supabaseMock: { supabase } }
})

vi.mock('@/lib/supabase/client', () => supabaseMock)

import { awardXp } from '@/lib/supabase/progress'

// Tabellen, die ein Gamification-Write niemals berühren darf.
const FORBIDDEN_TABLES = ['student_competency_mastery', 'student_focus_areas', 'sessions']

beforeEach(() => {
  tracker.writes.length = 0
  tracker.tables.length = 0
})

describe('INV-2 — Gamification berührt keine Mastery-/Lernpfad-Daten', () => {
  it('awardXp schreibt ausschließlich xp_events', async () => {
    await awardXp('s1', 10, 'task_correct', 't1')
    expect(tracker.tables).toEqual(['xp_events'])
    expect(tracker.writes.map((w) => w.op)).toEqual(['insert'])
  })

  it('berührt keine Mastery-/Lernpfad-Tabelle', async () => {
    await awardXp('s1', 10, 'task_correct', 't1')
    for (const table of FORBIDDEN_TABLES) {
      expect(tracker.tables).not.toContain(table)
    }
  })

  it('Payload enthält nur Gamification-Felder, keine Mastery-Felder', async () => {
    await awardXp('s1', 10, 'task_correct', 't1')
    const payload = tracker.writes[0]?.payload as Record<string, unknown>
    expect(Object.keys(payload).sort()).toEqual(['reason', 'student_id', 'task_id', 'xp'])
    expect(payload).not.toHaveProperty('mastered')
    expect(payload).not.toHaveProperty('mastery')
    expect(payload).not.toHaveProperty('level')
  })
})
