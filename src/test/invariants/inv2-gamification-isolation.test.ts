import { beforeEach, describe, expect, it, vi } from 'vitest'

/**
 * INV-2 — Gamification-Abschluss ohne Lernpfad-/Mastery-Einfluss (FernUSG).
 *
 * Hinweis zur Repo-Realität: Ein benanntes „Home Quest"-Feature existiert im
 * Code (noch) NICHT (Discovery: keine home_quest/Quest-Symbole; alle „quest"-
 * Treffer sind `parseQuestion`). Der reale Gamification-Abschluss-Pfad ist die
 * XP-Vergabe `awardXp` in src/lib/supabase/progress.ts. Diese Suite testet die
 * dahinterliegende Invariante direkt am realen Symbol: ein Gamification-Write
 * geht AUSSCHLIESSLICH über die RPC `xp_buchen` (seit X0 kein direkter
 * Tabellen-Write mehr) — niemals student_competency_mastery, Mastery-Felder
 * oder Lernpfad-Zustand.
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
  const rpcs: { name: string; args: Record<string, unknown> }[] = []

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
    rpc: async (name: string, args: Record<string, unknown>): Promise<QueryResult> => {
      rpcs.push({ name, args })
      return { data: true, error: null }
    },
  }

  return { tracker: { writes, tables, rpcs }, supabaseMock: { supabase } }
})

vi.mock('@/lib/supabase/client', () => supabaseMock)

import { awardXp } from '@/lib/supabase/progress'

// Tabellen, die ein Gamification-Write niemals berühren darf.
const FORBIDDEN_TABLES = ['student_competency_mastery', 'student_focus_areas', 'sessions']

beforeEach(() => {
  tracker.writes.length = 0
  tracker.tables.length = 0
  tracker.rpcs.length = 0
})

describe('INV-2 — Gamification berührt keine Mastery-/Lernpfad-Daten', () => {
  it('awardXp bucht ausschließlich über die RPC xp_buchen, ohne Tabellen-Write', async () => {
    const r = await awardXp('s1', 10, 'task_correct', 'quest:q1', 't1')
    expect(r).toEqual({ data: { gebucht: true }, error: null })
    expect(tracker.rpcs.map((c) => c.name)).toEqual(['xp_buchen'])
    expect(tracker.tables).toEqual([])
    expect(tracker.writes).toEqual([])
  })

  it('berührt keine Mastery-/Lernpfad-Tabelle', async () => {
    await awardXp('s1', 10, 'task_correct', 'quest:q1', 't1')
    for (const table of FORBIDDEN_TABLES) {
      expect(tracker.tables).not.toContain(table)
    }
  })

  it('Argumente enthalten nur Gamification-Felder, keine Mastery-Felder', async () => {
    await awardXp('s1', 10, 'task_correct', 'quest:q1', 't1')
    const args = tracker.rpcs[0]?.args ?? {}
    expect(Object.keys(args).sort()).toEqual([
      'p_grund',
      'p_schluessel',
      'p_student_id',
      'p_task_id',
      'p_xp',
    ])
    expect(args).not.toHaveProperty('mastered')
    expect(args).not.toHaveProperty('level')
  })
})
