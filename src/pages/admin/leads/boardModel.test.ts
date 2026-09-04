import { describe, expect, it } from 'vitest'
import type { Lead, LeadStatus } from '@/types'
import {
  BOARD_COLUMNS,
  DONE_COLUMN,
  EMPTY_FILTERS,
  ageDisplay,
  daysWaiting,
  leadsForColumn,
  matchesFilters,
  stateTimestamp,
} from './boardModel'

function lead(over: Partial<Lead> & { id: string }): Lead {
  return {
    created_at: '2026-09-01T10:00:00.000Z',
    full_name: 'ZZ_Test Kind',
    first_name: 'ZZ_Mia',
    contact_email: null,
    contact_phone: null,
    class_level: null,
    school_type: null,
    school_name: null,
    subjects: [],
    goal: null,
    known_weak_topics: [],
    source: null,
    status: 'new' as LeadStatus,
    owner_id: null,
    notes: null,
    converted_student_id: null,
    contacted_at: null,
    onboarding_scheduled_at: null,
    lsa_freigegeben_at: null,
    lsa_fertig_at: null,
    birth_date: null,
    last_grade: null,
    grade_trend: null,
    struggling_since: null,
    tried_before: null,
    next_exam_date: null,
    next_exam_topic: null,
    current_topic_cluster_id: null,
    consent_dsgvo_at: null,
    consent_dsgvo_by: null,
    consent_dsgvo_signature: null,
    consent_dsgvo_document_version: null,
    ...over,
  }
}

describe('daysWaiting', () => {
  const now = new Date('2026-09-15T12:00:00.000Z')

  it('zaehlt ganze Tage seit created_at', () => {
    expect(daysWaiting('2026-09-01T12:00:00.000Z', now)).toBe(14)
    expect(daysWaiting('2026-09-08T12:00:00.000Z', now)).toBe(7)
  })

  it('gibt fuer heute angelegte Leads 0 zurueck', () => {
    expect(daysWaiting('2026-09-15T09:00:00.000Z', now)).toBe(0)
  })

  it('wird bei Zukunftsdaten nicht negativ', () => {
    expect(daysWaiting('2026-09-20T12:00:00.000Z', now)).toBe(0)
  })
})

describe('matchesFilters', () => {
  const mia = lead({
    id: 'a',
    first_name: 'ZZ_Mia',
    full_name: 'ZZ_Mia Musterkind',
    subjects: ['Mathematik'],
    class_level: 7,
  })

  it('laesst ohne Filter alles durch', () => {
    expect(matchesFilters(mia, EMPTY_FILTERS)).toBe(true)
  })

  it('sucht in Rufname und vollstaendigem Namen, ohne Gross-/Kleinschreibung', () => {
    expect(matchesFilters(mia, { ...EMPTY_FILTERS, query: 'mia' })).toBe(true)
    expect(matchesFilters(mia, { ...EMPTY_FILTERS, query: 'musterkind' })).toBe(true)
    expect(matchesFilters(mia, { ...EMPTY_FILTERS, query: 'ZZ_Tom' })).toBe(false)
  })

  it('filtert auf Fach und Klasse', () => {
    expect(matchesFilters(mia, { ...EMPTY_FILTERS, subject: 'Mathematik' })).toBe(true)
    expect(matchesFilters(mia, { ...EMPTY_FILTERS, subject: 'Deutsch' })).toBe(false)
    expect(matchesFilters(mia, { ...EMPTY_FILTERS, classLevel: 7 })).toBe(true)
    expect(matchesFilters(mia, { ...EMPTY_FILTERS, classLevel: 8 })).toBe(false)
  })
})

describe('leadsForColumn', () => {
  const neu = BOARD_COLUMNS[0]
  const gespraech = BOARD_COLUMNS[1]

  it('sortiert aelteste zuoberst — wer am laengsten wartet, steht oben', () => {
    const leads = [
      lead({ id: 'neu', created_at: '2026-09-10T10:00:00.000Z' }),
      lead({ id: 'alt', created_at: '2026-09-01T10:00:00.000Z' }),
      lead({ id: 'mittel', created_at: '2026-09-05T10:00:00.000Z' }),
    ]
    expect(leadsForColumn(leads, neu, EMPTY_FILTERS).map((l) => l.id)).toEqual([
      'alt',
      'mittel',
      'neu',
    ])
  })

  it('fasst contacted und onboarding_scheduled in "Termin vereinbart" zusammen', () => {
    const leads = [
      lead({ id: 'c', status: 'contacted' }),
      lead({ id: 'o', status: 'onboarding_scheduled' }),
      lead({ id: 'n', status: 'new' }),
    ]
    expect(leadsForColumn(leads, gespraech, EMPTY_FILTERS).map((l) => l.id).sort()).toEqual(
      ['c', 'o'],
    )
  })

  it('haelt converted und rejected aus den vier Standardspalten heraus (nur Archiv)', () => {
    const leads = [
      lead({ id: 'conv', status: 'converted' }),
      lead({ id: 'rej', status: 'rejected' }),
    ]
    for (const column of BOARD_COLUMNS) {
      expect(leadsForColumn(leads, column, EMPTY_FILTERS)).toHaveLength(0)
    }
    expect(leadsForColumn(leads, DONE_COLUMN, EMPTY_FILTERS)).toHaveLength(2)
  })

  it('wendet die Filter innerhalb der Spalte an', () => {
    const leads = [
      lead({ id: 'mathe', subjects: ['Mathematik'] }),
      lead({ id: 'deutsch', subjects: ['Deutsch'] }),
    ]
    const filtered = leadsForColumn(leads, neu, { ...EMPTY_FILTERS, subject: 'Deutsch' })
    expect(filtered.map((l) => l.id)).toEqual(['deutsch'])
  })
})

describe('stateTimestamp', () => {
  it('liefert den Zeitstempel der Zustaende, die einen haben', () => {
    expect(stateTimestamp(lead({ id: 'n', status: 'new' }))).toBe(
      '2026-09-01T10:00:00.000Z',
    )
    expect(
      stateTimestamp(
        lead({ id: 'c', status: 'contacted', contacted_at: '2026-09-09T10:00:00.000Z' }),
      ),
    ).toBe('2026-09-09T10:00:00.000Z')
    expect(
      stateTimestamp(
        lead({
          id: 'o',
          status: 'onboarding_scheduled',
          onboarding_scheduled_at: '2026-09-11T10:00:00.000Z',
        }),
      ),
    ).toBe('2026-09-11T10:00:00.000Z')
  })

  it('liefert die Zeitstempel der beiden LSA-Zustaende', () => {
    expect(
      stateTimestamp(
        lead({
          id: 'f',
          status: 'lsa_freigegeben',
          lsa_freigegeben_at: '2026-09-12T10:00:00.000Z',
        }),
      ),
    ).toBe('2026-09-12T10:00:00.000Z')
    expect(
      stateTimestamp(
        lead({ id: 'd', status: 'lsa_fertig', lsa_fertig_at: '2026-09-14T10:00:00.000Z' }),
      ),
    ).toBe('2026-09-14T10:00:00.000Z')
  })

  it('liefert null im Archiv und bei Bestandsleads ohne LSA-Zeitstempel', () => {
    for (const status of ['converted', 'rejected'] as const) {
      expect(stateTimestamp(lead({ id: status, status }))).toBeNull()
    }
    // Vor Migration 20260904100000 angelegt: Status gesetzt, Spalte leer.
    expect(stateTimestamp(lead({ id: 'alt', status: 'lsa_freigegeben' }))).toBeNull()
    expect(stateTimestamp(lead({ id: 'alt2', status: 'lsa_fertig' }))).toBeNull()
  })
})

describe('ageDisplay', () => {
  const now = new Date('2026-09-15T12:00:00.000Z')
  const [offen, erfasst, analyse, abgeschlossen] = BOARD_COLUMNS

  it('zeigt in Spalte 1 nur die Hauptzeile — beide Werte waeren identisch', () => {
    const view = ageDisplay(
      lead({ id: 'a', created_at: '2026-09-14T10:00:00.000Z' }),
      offen,
      now,
    )
    expect(view.label).toBe('seit 1 Tag')
    expect(view.createdLabel).toBeNull()
  })

  it('rechnet ab dem Zustands-Zeitstempel und zeigt das Anlagedatum darunter', () => {
    const view = ageDisplay(
      lead({
        id: 'b',
        status: 'contacted',
        created_at: '2026-09-01T12:00:00.000Z',
        contacted_at: '2026-09-13T12:00:00.000Z',
      }),
      erfasst,
      now,
    )
    expect(view.label).toBe('seit 2 Tagen')
    expect(view.createdLabel).toBe('angelegt vor 14 Tagen')
    // 2 Tage im Zustand liegen unter der 7-Tage-Schwelle der Spalte.
    expect(view.accent).toBe(false)
    expect(view.bold).toBe(false)
  })

  it('nutzt in Spalte 1 und 2 die Schwellen 7 und 14', () => {
    const at7 = ageDisplay(
      lead({ id: 'c', created_at: '2026-09-08T12:00:00.000Z' }),
      offen,
      now,
    )
    expect([at7.accent, at7.bold]).toEqual([true, false])
    const at14 = ageDisplay(
      lead({ id: 'd', created_at: '2026-09-01T12:00:00.000Z' }),
      offen,
      now,
    )
    expect([at14.accent, at14.bold]).toEqual([true, true])
  })

  it('nutzt in Spalte 3 und 4 die Schwellen 3 und 7 ab dem LSA-Zeitstempel', () => {
    const view = ageDisplay(
      lead({
        id: 'h',
        status: 'lsa_freigegeben',
        created_at: '2026-09-01T12:00:00.000Z',
        lsa_freigegeben_at: '2026-09-11T12:00:00.000Z',
      }),
      analyse,
      now,
    )
    expect(view.label).toBe('seit 4 Tagen')
    expect(view.createdLabel).toBe('angelegt vor 14 Tagen')
    // 4 Tage liegen ueber der Akzent-Schwelle 3, aber unter der Fett-Schwelle 7.
    expect([view.accent, view.bold]).toEqual([true, false])

    const fertig = ageDisplay(
      lead({
        id: 'i',
        status: 'lsa_fertig',
        created_at: '2026-09-01T12:00:00.000Z',
        lsa_fertig_at: '2026-09-07T12:00:00.000Z',
      }),
      abgeschlossen,
      now,
    )
    expect(fertig.label).toBe('seit 8 Tagen')
    expect([fertig.accent, fertig.bold]).toEqual([true, true])
  })

  it('faellt ohne Zustands-Zeitstempel auf das Anlagedatum mit 7/14 zurueck', () => {
    // Bestandsleads von vor Migration 20260904100000: Status gesetzt, aber
    // lsa_freigegeben_at leer — dann gelten die Rueckfall-Schwellen 7/14
    // statt der 3/7 der Spalte.
    const view = ageDisplay(
      lead({
        id: 'e',
        status: 'lsa_freigegeben',
        created_at: '2026-09-10T12:00:00.000Z',
      }),
      analyse,
      now,
    )
    expect(view.label).toBe('angelegt vor 5 Tagen')
    expect(view.createdLabel).toBeNull()
    expect(view.accent).toBe(false)

    const alt = ageDisplay(
      lead({
        id: 'f',
        status: 'lsa_fertig',
        created_at: '2026-09-07T12:00:00.000Z',
      }),
      abgeschlossen,
      now,
    )
    expect(alt.label).toBe('angelegt vor 8 Tagen')
    expect(alt.accent).toBe(true)
    expect(alt.bold).toBe(false)
  })

  it('faellt auch bei fehlendem contacted_at auf das Anlagedatum zurueck', () => {
    const view = ageDisplay(
      lead({
        id: 'g',
        status: 'contacted',
        contacted_at: null,
        created_at: '2026-09-13T12:00:00.000Z',
      }),
      erfasst,
      now,
    )
    expect(view.label).toBe('angelegt vor 2 Tagen')
    expect(view.createdLabel).toBeNull()
  })
})
