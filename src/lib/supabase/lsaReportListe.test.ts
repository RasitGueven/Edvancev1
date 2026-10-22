import { beforeEach, describe, expect, it, vi } from 'vitest'

/**
 * Liste „LSA-Reports“ (LR-1). Geprüft wird, was listLsaReports aus den Zeilen
 * macht — Filter, Reihenfolge, Kennzeichen, Thema, Namen. Der Client ist
 * gemockt. Testdaten tragen das Präfix ZZ_.
 */

let zeilen: Record<string, unknown>[] = []
let filter: [string, unknown][] = []
let sortierung: unknown[] = []
let auswahl = ''
let rufnamen: Record<string, string | null> = {}
let nichtAuswertbar = new Map<string, unknown>()

// LSA-R2: eigene Abfrage, hier nur ihr Ergebnis.
vi.mock('@/lib/supabase/lsaDurchklick', () => ({
  loadNichtAuswertbar: () => Promise.resolve(nichtAuswertbar),
}))

vi.mock('@/lib/supabase/client', () => {
  const q = {
    select: (cols: string) => ((auswahl = cols), q),
    eq: (spalte: string, wert: unknown) => ((filter.push([spalte, wert])), q),
    order: (...args: unknown[]) => {
      sortierung = args
      // Wie der Server: nur, was den Filter erfüllt.
      const status = filter.find(([s]) => s === 'status')?.[1]
      return Promise.resolve({ data: zeilen.filter((z) => z.status === status), error: null })
    },
  }
  const rpc = (_name: string, args: { p_student_ids: string[] }) =>
    Promise.resolve({
      data: args.p_student_ids
        .filter((id) => id in rufnamen)
        .map((id) => ({ student_id: id, rufname: rufnamen[id], eltern_weak_topics: [] })),
      error: null,
    })
  return { supabase: { from: () => q, rpc } }
})

const { listLsaReports } = await import('@/lib/supabase/lsaReportListe')

const zeile = (id: string, extra: Record<string, unknown> = {}) => ({
  id,
  student_id: `ZZ_kind_${id}`,
  subject: 'Mathematik',
  grade: 7,
  status: 'completed',
  completed_at: '2026-10-20T10:00:00+00:00',
  testlauf: false,
  modus: 'adaptiv',
  thema_key: null,
  students: { ist_test: false },
  themen: null,
  ...extra,
})

beforeEach(() => {
  zeilen = []
  filter = []
  sortierung = []
  auswahl = ''
  rufnamen = {}
  nichtAuswertbar = new Map()
})

describe('listLsaReports', () => {
  it('fragt nur abgeschlossene LSAs ab, abgebrochene und laufende fehlen', async () => {
    zeilen = [zeile('a'), zeile('b', { status: 'aborted' }), zeile('c', { status: 'in_progress' })]
    const res = await listLsaReports()
    expect(filter).toEqual([['status', 'completed']])
    expect(res.data?.map((z) => z.session_id)).toEqual(['a'])
  })

  it('sortiert nach completed_at absteigend', async () => {
    zeilen = [
      zeile('alt', { completed_at: '2026-10-01T08:00:00+00:00' }),
      zeile('neu', { completed_at: '2026-10-21T08:00:00+00:00' }),
      zeile('mitte', { completed_at: '2026-10-10T08:00:00+00:00' }),
    ]
    const res = await listLsaReports()
    expect(sortierung).toEqual(['completed_at', { ascending: false }])
    expect(res.data?.map((z) => z.session_id)).toEqual(['neu', 'mitte', 'alt'])
  })

  it('kennzeichnet Testlauf und Testkonto getrennt', async () => {
    zeilen = [
      zeile('lauf', { testlauf: true, students: { ist_test: true } }),
      zeile('konto', { students: { ist_test: true } }),
      zeile('echt'),
    ]
    const res = await listLsaReports()
    const nach = Object.fromEntries((res.data ?? []).map((z) => [z.session_id, [z.testlauf, z.ist_test]]))
    expect(nach).toEqual({ lauf: [true, true], konto: [false, true], echt: [false, false] })
    // students hat zwei Fremdschlüssel aus lsa_sessions: der Hinweis nimmt student_id.
    expect(auswahl).toContain('students!lsa_sessions_student_id_fkey(ist_test)')
  })

  it('übernimmt das Themen-Label, fehlt es, bleibt das Thema leer', async () => {
    zeilen = [
      zeile('mit', { thema_key: 'ZZ_binom', themen: { label: 'ZZ_Binomische Formeln' } }),
      zeile('ohneLabel', { thema_key: 'ZZ_leer', themen: { label: null } }),
      zeile('ohne'),
    ]
    const res = await listLsaReports()
    const nach = Object.fromEntries((res.data ?? []).map((z) => [z.session_id, z.thema_label]))
    expect(nach).toEqual({ mit: 'ZZ_Binomische Formeln', ohneLabel: null, ohne: null })
  })

  it('kennzeichnet nicht auswertbare LSAs mit Grund, alle anderen sind auswertbar (LSA-R2)', async () => {
    zeilen = [zeile('klick'), zeile('ruhig')]
    const grund = { grund: 'folge', folge_schnell_falsch_max: 5 }
    nichtAuswertbar = new Map([['klick', grund]])
    const res = await listLsaReports()
    const nach = Object.fromEntries(
      (res.data ?? []).map((z) => [z.session_id, [z.auswertbar, z.nicht_auswertbar_grund]]),
    )
    expect(nach).toEqual({ klick: [false, grund], ruhig: [true, null] })
  })

  it('behält Kinder ohne Rufnamen', async () => {
    zeilen = [zeile('a'), zeile('b'), zeile('c')]
    rufnamen = { ZZ_kind_a: 'ZZ_Mia', ZZ_kind_b: null }
    const res = await listLsaReports()
    expect(res.data?.map((z) => z.first_name)).toEqual(['ZZ_Mia', null, null])
  })
})
