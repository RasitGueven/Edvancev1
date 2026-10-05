import { describe, expect, it } from 'vitest'
import type { BoardSchueler, Lead, SkillThema, VertragMitLead } from '@/types'
import {
  berlinStunde,
  erstgespraeche,
  freigabeGruppen,
  imRueckstand,
  lsaLeads,
  neueLeads,
  offeneAntraege,
  tageszeit,
  vorname,
} from './heuteModel'

const lead = (id: string, over: Partial<Lead>): Lead =>
  ({ id, full_name: id, created_at: '2026-10-01T08:00:00Z', subjects: [], erstgespraech_at: null, ...over }) as Lead

const schueler = (id: string, over: Partial<BoardSchueler>): BoardSchueler =>
  ({ student_id: id, name: id, zustand: 'aktiv', ampel: 'im_plan', rueckstand: 0, ...over }) as BoardSchueler

describe('heuteModel', () => {
  it('neue Leads: nur status new, älteste zuerst', () => {
    const r = neueLeads([
      lead('b', { status: 'new', created_at: '2026-10-03T08:00:00Z' }),
      lead('a', { status: 'new', created_at: '2026-09-20T08:00:00Z' }),
      lead('x', { status: 'contacted' }),
    ])
    expect(r.map((l) => l.id)).toEqual(['a', 'b'])
  })

  it('Erstgespräche: contacted und onboarding_scheduled mit Termin ab Tagesbeginn, nächster zuerst', () => {
    const r = erstgespraeche(
      [
        lead('spaeter', { status: 'contacted', erstgespraech_at: '2026-10-09T14:00:00Z' }),
        lead('gestern', { status: 'contacted', erstgespraech_at: '2026-10-04T14:00:00Z' }),
        lead('heute', { status: 'contacted', erstgespraech_at: '2026-10-05T07:00:00Z' }),
        lead('ohne', { status: 'contacted' }),
        lead('onboarding', { status: 'onboarding_scheduled', erstgespraech_at: '2026-10-07T09:00:00Z' }),
        lead('onboarding_alt', { status: 'onboarding_scheduled', erstgespraech_at: '2026-10-03T09:00:00Z' }),
        lead('neu', { status: 'new', erstgespraech_at: '2026-10-06T14:00:00Z' }),
      ],
      '2026-10-04T22:00:00.000Z',
    )
    expect(r.map((l) => l.id)).toEqual(['heute', 'onboarding', 'spaeter'])
  })

  it('Lernstandsanalysen: fertige vor freigegebenen', () => {
    const r = lsaLeads([
      lead('frei', { status: 'lsa_freigegeben', lsa_freigegeben_at: '2026-10-01T08:00:00Z' }),
      lead('fertig', { status: 'lsa_fertig', lsa_fertig_at: '2026-10-04T08:00:00Z' }),
      lead('neu', { status: 'new' }),
    ])
    expect(r.map((l) => l.id)).toEqual(['fertig', 'frei'])
  })

  it('offene Anträge ohne abgelehnte und abgeschlossene', () => {
    const v = (id: string, status: string): VertragMitLead => ({ id, status, created_at: '2026-10-01' }) as VertragMitLead
    const r = offeneAntraege([v('a', 'in_vorbereitung'), v('b', 'abgelehnt'), v('c', 'unterschrift_ausstehend'), v('d', 'abgeschlossen')])
    expect(r.map((x) => x.id).sort()).toEqual(['a', 'c'])
  })

  it('Rückstand: deutlich vor leicht, je größter Rückstand zuerst; ruhende und im Plan fallen weg', () => {
    const r = imRueckstand([
      schueler('leicht', { ampel: 'leicht_im_rueckstand', rueckstand: 5 }),
      schueler('deutlich_klein', { ampel: 'deutlich_im_rueckstand', rueckstand: 2 }),
      schueler('deutlich_gross', { ampel: 'deutlich_im_rueckstand', rueckstand: 4 }),
      schueler('plan', { ampel: 'im_plan' }),
      schueler('ruhend', { ampel: 'deutlich_im_rueckstand', zustand: 'ruhend' }),
    ])
    expect(r.map((s) => s.student_id)).toEqual(['deutlich_gross', 'deutlich_klein', 'leicht'])
  })

  it('Freigabe: gruppiert nach Thema über skill_thema, ohne Thema in eigener Gruppe', () => {
    const themen: SkillThema[] = [
      { skill_key: 's1', thema_key: 'bruch', label: 'Brüche', stufe: 'erprobung', sort: 1 },
      { skill_key: 's2', thema_key: 'bruch', label: 'Brüche', stufe: 'erprobung', sort: 1 },
    ]
    const r = freigabeGruppen(
      [
        { id: '1', skill_key: 's1' },
        { id: '2', skill_key: 's2' },
        { id: '3', skill_key: null },
      ],
      themen,
    )
    expect(r).toEqual([
      { themaKey: 'bruch', label: 'Brüche', stufe: 'erprobung', anzahl: 2 },
      { themaKey: null, label: null, stufe: null, anzahl: 1 },
    ])
  })

  it('Berliner Stunde als Zahl, auch im Winter', () => {
    expect(berlinStunde(new Date('2026-10-05T08:10:00Z'))).toBe(10)
    expect(berlinStunde(new Date('2026-12-01T22:30:00Z'))).toBe(23)
    expect(tageszeit(berlinStunde(new Date('2026-10-05T08:10:00Z')))).toBe('morgen')
  })

  it('Gruß und Vorname', () => {
    expect([tageszeit(7), tageszeit(11), tageszeit(17), tageszeit(18)]).toEqual(['morgen', 'tag', 'tag', 'abend'])
    expect(vorname('  Rasit Güven ')).toBe('Rasit')
    expect(vorname('')).toBeNull()
    expect(vorname(null)).toBeNull()
  })
})
