import { describe, expect, it } from 'vitest'

import { FWG_NAME, FWG_PLAN, THEMEN } from '@/lib/report/elternbericht/fixtures/plaene'
import {
  aktuellePosition,
  findeSchule,
  halbjahrVon,
  klpPlan,
  monatBerlin,
  planFuer,
  schulPlan,
  stufeVon,
} from '@/lib/report/elternbericht/plan'

const SCHULEN = [
  { id: 's1', name: 'Friedrich-Wilhelm-Gymnasium' },
  { id: 's2', name: 'Gesamtschule Holweide' },
  { id: 's3', name: 'Gesamtschule Holweide ' },
]
const ohne = { schuelerSchule: null, leadSchule: null, schulname: null, schulen: SCHULEN }

describe('findeSchule — Schulweg (Entscheidung 2)', () => {
  it('zuerst students.schule_id', () => {
    expect(findeSchule({ ...ohne, schuelerSchule: 'sX', leadSchule: 's1', schulname: 'Gesamtschule Holweide' })).toEqual({
      id: 'sX',
      weg: 'schueler',
    })
  })
  it('dann leads.schule_id über students.lead_id (Batu)', () => {
    expect(findeSchule({ ...ohne, leadSchule: 's1', schulname: 'Friedrich-Wilhelm-Gymnasium' })).toEqual({ id: 's1', weg: 'lead' })
  })
  it('dann der Name, ohne Groß/Klein, genau ein Treffer', () => {
    expect(findeSchule({ ...ohne, schulname: '  friedrich-wilhelm-GYMNASIUM ' })).toEqual({ id: 's1', weg: 'name' })
    // Zwei Treffer (nach Trimmen gleich) → keiner.
    expect(findeSchule({ ...ohne, schulname: 'gesamtschule holweide' })).toBeNull()
  })
  it('sonst keiner', () => {
    expect(findeSchule(ohne)).toBeNull()
    expect(findeSchule({ ...ohne, schulname: 'Unbekannte Schule' })).toBeNull()
    expect(findeSchule({ ...ohne, schulname: 'Friedrich-Wilhelm-Gymnasium', schulen: [] })).toBeNull()
  })
})

describe('Plan oder Kernlehrplan (Entscheidung 3)', () => {
  it('Schulplan der Klasse nach Position, mit nächster Klasse', () => {
    const p = schulPlan(FWG_PLAN, 9, FWG_NAME)!
    expect(p.quelle).toBe('schule')
    expect(p.schulname).toBe(FWG_NAME)
    expect(p.eintraege.map((e) => e.titel)[1]).toBe('Quadratische Funktionen')
    expect(p.naechsteKlasse?.klasse).toBe(10)
    expect(p.naechsteKlasse?.eintraege).toHaveLength(6)
  })
  it('nächste Klasse fehlt, wenn die Schule für Klasse + 1 keinen Plan hat', () => {
    expect(schulPlan(FWG_PLAN, 10, FWG_NAME)!.naechsteKlasse).toBeNull()
  })
  it('ohne Plan für die Klasse: Kernlehrplan der Stufe, ohne nächste Klasse', () => {
    const p = planFuer({ schulZeilen: FWG_PLAN, schulname: FWG_NAME, themen: THEMEN, klasse: 7 })
    expect(p.quelle).toBe('klp')
    expect(p.schulname).toBeNull()
    expect(p.naechsteKlasse).toBeNull()
    expect(p.eintraege.length).toBeGreaterThan(0)
    const erste = THEMEN.filter((t) => t.stufe === 'erste')
    expect(p.eintraege.map((e) => e.themaKey)).toEqual(
      [...erste].sort((a, b) => (a.sort ?? 0) - (b.sort ?? 0)).map((t) => t.themaKey),
    )
  })
  it('ohne Schule: Kernlehrplan', () => {
    expect(planFuer({ schulZeilen: null, schulname: null, themen: THEMEN, klasse: 9 }).quelle).toBe('klp')
  })
  it('Stufen 5/6, 7/8, 9/10', () => {
    expect([5, 6, 7, 8, 9, 10].map(stufeVon)).toEqual(['erprobung', 'erprobung', 'erste', 'erste', 'zweite', 'zweite'])
  })
  it('KLP: ohne Halbjahr und Positionen fortlaufend', () => {
    const p = klpPlan(THEMEN, 9)
    expect(p.eintraege.every((e) => e.halbjahr === null)).toBe(true)
    expect(p.eintraege.map((e) => e.position)).toEqual(p.eintraege.map((_, i) => i + 1))
  })
})

describe('aktuellePosition (Entscheidung 9)', () => {
  const plan = schulPlan(FWG_PLAN, 9, FWG_NAME)!.eintraege
  const mitHj = plan.map((e) => ({ ...e, halbjahr: (e.position <= 3 ? 1 : 2) as 1 | 2 }))
  it('das Thema der Sitzung im Plan', () => {
    expect(aktuellePosition(plan, 'reelle_zahlen', '2026-10-18T13:53:32Z')).toBe(0)
    expect(aktuellePosition(plan, 'pythagoras', null)).toBe(4)
  })
  it('ohne Thema im Plan: erster Eintrag des Halbjahrs (Aug–Jan 1, Feb–Jul 2)', () => {
    expect(aktuellePosition(mitHj, null, '2026-10-18T10:00:00Z')).toBe(0)
    expect(aktuellePosition(mitHj, 'gibt_es_nicht', '2027-03-10T10:00:00Z')).toBe(3)
    expect(aktuellePosition(mitHj, null, '2027-01-31T23:30:00Z')).toBe(3) // Berlin: 1. Februar, 0:30
    expect(aktuellePosition(mitHj, null, '2027-01-31T22:30:00Z')).toBe(0) // Berlin: 31. Januar, 23:30
  })
  it('Plan ohne Halbjahr oder ohne Datum: der Anfang', () => {
    expect(aktuellePosition(plan, null, '2027-03-10T10:00:00Z')).toBe(-1)
    expect(aktuellePosition(mitHj, null, null)).toBe(-1)
  })
  it('Halbjahr und Monat in Europe/Berlin', () => {
    expect(monatBerlin('2026-07-31T22:30:00Z')).toBe(8)
    expect([1, 2, 7, 8, 12].map(halbjahrVon)).toEqual([1, 2, 2, 1, 1])
  })
})

describe('klpPlan im zweiten Jahr einer Stufe (Nachbesserung R7-9, Entscheidung 7)', () => {
  it('Klasse 10 heute: themen.klasse steht für 9/10 überall auf 9 → alle Themen der Stufe', () => {
    const p = klpPlan(THEMEN, 10)
    expect(p.eintraege.length).toBe(THEMEN.filter((t) => t.stufe === 'zweite').length)
  })
  it('Klasse 10 nach der Korrektur von themen.klasse: nur noch die Themen der 10', () => {
    const korrigiert = THEMEN.map((t) => (['trigonometrie', 'exponentialfunktionen', 'sinusfunktion'].includes(t.themaKey) ? { ...t, klasse: 10 } : t))
    expect(klpPlan(korrigiert, 10).eintraege.map((e) => e.themaKey)).toEqual(['trigonometrie', 'exponentialfunktionen', 'sinusfunktion'])
    // Klasse 9 sieht weiter alles der Stufe, in der Reihenfolge nach sort.
    expect(klpPlan(korrigiert, 9).eintraege.length).toBe(THEMEN.filter((t) => t.stufe === 'zweite').length)
  })
})
