import { describe, expect, it, vi, beforeEach } from 'vitest'

/**
 * Das Thema des Eltern-Reports (R1) — zwei Quellen, eine Rangfolge.
 *
 * Geprüft wird die AUSWAHL zwischen Themencluster (neue Leads aus dem Wizard)
 * und Freitext (Altbestand), nicht Supabase. Der Client ist deshalb gemockt; er
 * ist hier nur Zulieferer. Testdaten tragen das Präfix ZZ_.
 */

type Row = Record<string, unknown> | null
let studentRow: Row = null
let leadRow: Row = null
let clusterRow: Row = null
let abgefragt: string[] = []

vi.mock('@/lib/supabase/client', () => {
  const bau = (tabelle: string) => {
    abgefragt.push(tabelle)
    const daten = () =>
      tabelle === 'students' ? studentRow : tabelle === 'leads' ? leadRow : clusterRow
    const q = {
      select: () => q,
      eq: () => q,
      maybeSingle: () => Promise.resolve({ data: daten(), error: null }),
    }
    return q
  }
  return { supabase: { from: (tabelle: string) => bau(tabelle) } }
})

const { loadNaechstesThema } = await import('@/lib/supabase/lsaReport')

beforeEach(() => {
  studentRow = { lead_id: 'ZZ_lead_1' }
  leadRow = null
  clusterRow = null
  abgefragt = []
})

describe('loadNaechstesThema — Cluster vor Freitext', () => {
  it('nimmt den Clusternamen, wenn die ID gesetzt und auflösbar ist', async () => {
    leadRow = {
      next_exam_topic: 'ZZ_Freitext Bruchrechnen',
      current_topic_cluster_id: 'ZZ_cluster_1',
    }
    clusterRow = { name: 'ZZ_Binomische Formeln' }

    expect(await loadNaechstesThema('ZZ_student_1')).toBe('ZZ_Binomische Formeln')
    expect(abgefragt).toEqual(['students', 'leads', 'skill_clusters'])
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
    expect(abgefragt).toEqual(['students', 'leads'])
  })

  it('liefert null, wenn weder Cluster noch Freitext belegt sind', async () => {
    leadRow = { next_exam_topic: '   ', current_topic_cluster_id: null }

    expect(await loadNaechstesThema('ZZ_student_1')).toBeNull()
  })
})
