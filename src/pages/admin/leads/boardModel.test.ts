import { describe, expect, it } from 'vitest'
import type { Lead, LeadStatus } from '@/types'
import {
  BOARD_COLUMNS,
  DONE_COLUMN,
  EMPTY_FILTERS,
  daysWaiting,
  leadsForColumn,
  matchesFilters,
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

  it('fasst contacted und onboarding_scheduled in "Im Gespraech" zusammen', () => {
    const leads = [
      lead({ id: 'c', status: 'contacted' }),
      lead({ id: 'o', status: 'onboarding_scheduled' }),
      lead({ id: 'n', status: 'new' }),
    ]
    expect(leadsForColumn(leads, gespraech, EMPTY_FILTERS).map((l) => l.id).sort()).toEqual(
      ['c', 'o'],
    )
  })

  it('haelt converted und rejected aus den vier Standardspalten heraus', () => {
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
