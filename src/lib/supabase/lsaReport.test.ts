import { describe, expect, it, vi, beforeEach } from 'vitest'

/**
 * Das Thema des Eltern-Reports (R1) — zwei Quellen, eine Rangfolge.
 *
 * Geprüft wird die AUSWAHL zwischen Themencluster (neue Leads aus dem Wizard)
 * und Freitext (Altbestand), nicht Supabase. Der Client ist deshalb gemockt; er
 * ist hier nur Zulieferer. Testdaten tragen das Präfix ZZ_.
 */

type Row = Record<string, unknown> | null
// Der Lead-Kontext kommt aus der RPC lsa_lead_kontext (Lead über
// students.lead_id oder leads.converted_student_id — aufgelöst in SQL).
let leadRow: Row = null
let clusterRow: Row = null
let abgefragt: string[] = []
let rpcFehler: string | null = null

vi.mock('@/lib/supabase/client', () => {
  const bau = (tabelle: string) => {
    abgefragt.push(tabelle)
    const q = {
      select: () => q,
      eq: () => q,
      maybeSingle: () => Promise.resolve({ data: clusterRow, error: null }),
    }
    return q
  }
  const rpc = (name: string) => {
    abgefragt.push(`rpc:${name}`)
    const data = leadRow
      ? [{ student_id: 'ZZ_student_1', rufname: null, eltern_note: null, eltern_weak_topics: [], ...leadRow }]
      : []
    return Promise.resolve(
      rpcFehler ? { data: null, error: { message: rpcFehler } } : { data, error: null },
    )
  }
  return { supabase: { from: (tabelle: string) => bau(tabelle), rpc } }
})

const { loadNaechstesThema } = await import('@/lib/supabase/lsaReport')

beforeEach(() => {
  leadRow = null
  clusterRow = null
  abgefragt = []
  rpcFehler = null
})

describe('loadNaechstesThema — Cluster vor Freitext', () => {
  it('nimmt den Clusternamen, wenn die ID gesetzt und auflösbar ist', async () => {
    leadRow = {
      next_exam_topic: 'ZZ_Freitext Bruchrechnen',
      current_topic_cluster_id: 'ZZ_cluster_1',
    }
    clusterRow = { name: 'ZZ_Binomische Formeln' }

    expect(await loadNaechstesThema('ZZ_student_1')).toBe('ZZ_Binomische Formeln')
    expect(abgefragt).toEqual(['rpc:lsa_lead_kontext', 'skill_clusters'])
  })

  it('fällt auf den Freitext zurück, wenn der Cluster nicht auflösbar ist', async () => {
    // Cluster gelöscht oder für die Rolle nicht lesbar — das ist kein „kein Thema".
    leadRow = {
      next_exam_topic: 'ZZ_Freitext Bruchrechnen',
      current_topic_cluster_id: 'ZZ_cluster_weg',
    }
    clusterRow = null

    expect(await loadNaechstesThema('ZZ_student_1')).toBe('ZZ_Freitext Bruchrechnen')
  })

  it('fällt auch bei leerem Clusternamen auf den Freitext zurück', async () => {
    leadRow = {
      next_exam_topic: 'ZZ_Freitext Bruchrechnen',
      current_topic_cluster_id: 'ZZ_cluster_1',
    }
    clusterRow = { name: '   ' }

    expect(await loadNaechstesThema('ZZ_student_1')).toBe('ZZ_Freitext Bruchrechnen')
  })
})

describe('loadNaechstesThema — Altbestand ohne Cluster', () => {
  it('nimmt den Freitext, wenn keine Cluster-ID gesetzt ist', async () => {
    leadRow = { next_exam_topic: 'ZZ_Freitext Bruchrechnen', current_topic_cluster_id: null }

    expect(await loadNaechstesThema('ZZ_student_1')).toBe('ZZ_Freitext Bruchrechnen')
    // Ohne Cluster-ID entfällt der zweite Roundtrip.
    expect(abgefragt).toEqual(['rpc:lsa_lead_kontext'])
  })

  it('liefert null, wenn weder Cluster noch Freitext belegt sind', async () => {
    leadRow = { next_exam_topic: '   ', current_topic_cluster_id: null }

    expect(await loadNaechstesThema('ZZ_student_1')).toBeNull()
  })

  it('liefert null, wenn zum Kind kein Lead auflösbar ist', async () => {
    leadRow = null

    expect(await loadNaechstesThema('ZZ_student_1')).toBeNull()
    expect(abgefragt).toEqual(['rpc:lsa_lead_kontext'])
  })

  it('reicht einen RPC-Fehler weiter statt ihn zu verschlucken', async () => {
    rpcFehler = 'permission denied'

    await expect(loadNaechstesThema('ZZ_student_1')).rejects.toThrow('lsa_lead_kontext')
  })
})
