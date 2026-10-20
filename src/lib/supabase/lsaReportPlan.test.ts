// Lesepfad des Lernwegs (R7-9): Schulweg, Plan der Klasse und Klasse + 1,
// Kernlehrplan als Rückfall. Der Supabase-Client ist gemockt.
import { beforeEach, describe, expect, it, vi } from 'vitest'

type Antwort = { data: unknown; error: { message: string } | null }
let tabellen: Record<string, Antwort> = {}
let filter: { tabelle: string; spalte: string; wert: unknown }[] = []

vi.mock('@/lib/supabase/client', () => {
  const bau = (tabelle: string) => {
    const q = {
      select: () => q,
      eq: (spalte: string, wert: unknown) => {
        filter.push({ tabelle, spalte, wert })
        return q
      },
      in: (spalte: string, wert: unknown) => {
        filter.push({ tabelle, spalte, wert })
        return q
      },
      maybeSingle: () => Promise.resolve(tabellen[tabelle] ?? { data: null, error: null }),
      then: (ok: (a: Antwort) => unknown) => Promise.resolve(tabellen[tabelle] ?? { data: [], error: null }).then(ok),
    }
    return q
  }
  return { supabase: { from: (t: string) => bau(t) } }
})

const { loadPlan, loadHeimatThemen } = await import('@/lib/supabase/lsaReportPlan')

const THEMEN = [
  { thema_key: 'reelle_zahlen', klasse: 9, label: 'Reelle Zahlen', stufe: 'zweite', sort: 1 },
  { thema_key: 'potenzen', klasse: 9, label: 'Potenzen', stufe: 'zweite', sort: 2 },
  { thema_key: 'ohne_label', klasse: 9, label: null, stufe: 'zweite', sort: 3 },
]
const PLAN = [
  { klasse: 9, position: 1, thema_key: 'reelle_zahlen', uv_titel: 'Reelle Zahlen', halbjahr: null },
  { klasse: 9, position: 2, thema_key: 'quadratische_funktionen', uv_titel: 'Quadratische Funktionen', halbjahr: null },
  { klasse: 10, position: 1, thema_key: 'aehnlichkeit', uv_titel: 'Ähnlichkeit', halbjahr: null },
]

beforeEach(() => {
  filter = []
  tabellen = {
    lsa_sessions: { data: { student_id: 'st1', grade: 9 }, error: null },
    students: { data: { schule_id: null, lead_id: 'l1', school_name: 'Friedrich-Wilhelm-Gymnasium' }, error: null },
    leads: { data: { schule_id: 'fwg' }, error: null },
    schulen: { data: [{ id: 'fwg', name: 'Friedrich-Wilhelm-Gymnasium' }], error: null },
    themen: { data: THEMEN, error: null },
    schul_themenplan: { data: PLAN, error: null },
  }
})

describe('loadPlan (Entscheidungen 2 und 3)', () => {
  it('Batu: Schule über den Lead, Schulplan Klasse 9 mit nächster Klasse', async () => {
    const p = (await loadPlan('s1'))!
    expect(p.quelle).toBe('schule')
    expect(p.schulname).toBe('Friedrich-Wilhelm-Gymnasium')
    expect(p.eintraege.map((e) => e.titel)).toEqual(['Reelle Zahlen', 'Quadratische Funktionen'])
    expect(p.naechsteKlasse?.klasse).toBe(10)
    expect(filter).toContainEqual({ tabelle: 'schul_themenplan', spalte: 'schule_id', wert: 'fwg' })
    expect(filter).toContainEqual({ tabelle: 'schul_themenplan', spalte: 'fach', wert: 'mathematik' })
    expect(filter).toContainEqual({ tabelle: 'schul_themenplan', spalte: 'klasse', wert: [9, 10] })
  })

  it('ohne Leserecht für leads und schulen (Coach): Kernlehrplan, keine Schule', async () => {
    tabellen.leads = { data: null, error: { message: 'rls' } }
    tabellen.schulen = { data: [], error: null }
    const p = (await loadPlan('s1'))!
    expect(p.quelle).toBe('klp')
    expect(p.schulname).toBeNull()
    // Themen ohne Label tauchen nicht auf.
    expect(p.eintraege.map((e) => e.titel)).toEqual(['Reelle Zahlen', 'Potenzen'])
  })

  it('students.schule_id gilt auch ohne lesbaren Namen', async () => {
    tabellen.students = { data: { schule_id: 'fwg', lead_id: null, school_name: null }, error: null }
    tabellen.schulen = { data: [], error: null }
    const p = (await loadPlan('s1'))!
    expect(p.quelle).toBe('schule')
    expect(p.schulname).toBeNull()
  })

  it('Schule ohne Plan für die Klasse: Kernlehrplan', async () => {
    tabellen.schul_themenplan = { data: PLAN.filter((z) => z.klasse === 10), error: null }
    expect((await loadPlan('s1'))!.quelle).toBe('klp')
  })

  it('Sitzung nicht lesbar: null', async () => {
    tabellen.lsa_sessions = { data: null, error: { message: 'weg' } }
    expect(await loadPlan('s1')).toBeNull()
  })
})

describe('loadHeimatThemen', () => {
  it('liest skill_thema; bei Fehler leer', async () => {
    tabellen.skill_thema = { data: [{ skill_key: 'a', thema_key: 't' }], error: null }
    expect(await loadHeimatThemen()).toEqual([{ skillKey: 'a', themaKey: 't' }])
    const warn = vi.spyOn(console, 'warn').mockImplementation(() => {})
    tabellen.skill_thema = { data: null, error: { message: 'x' } }
    expect(await loadHeimatThemen()).toEqual([])
    warn.mockRestore()
  })
})
