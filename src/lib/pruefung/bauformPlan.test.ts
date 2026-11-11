// M1: Gruppierung der Muster nach Session, Fortschritt je Session, Bedingung fuer „Session n freigeben“.
import { describe, expect, it } from 'vitest'
import type { BauformPlanZeile } from '@/types/bauformPruefung'
import { bauformTitel, filterFuer, freigebbar, nachSessions, naechsteZuPruefen, passtZuFilter, pruefFortschritt } from './bauformPlan'

const z = (schluessel: string, session_nr: number | null, over: Partial<BauformPlanZeile> = {}): BauformPlanZeile =>
  ({
    bauform_id: schluessel, schluessel, skill_key: 's', skill_label: 'Skill', reihe: 'r', format: 'mc', rollen: ['uebung'],
    version: 1, status: 'zur_pruefung', gruen: 8, letzte_entscheidung: null, letzte_notiz: null, geprueft_am: null,
    session_nr, session_titel: session_nr ? `Titel ${session_nr}` : null, kernidee_key: null, kernidee_titel: null,
    ist_voraussetzung: false, ...over,
  }) as BauformPlanZeile

describe('nachSessions', () => {
  it('ordnet nach Session, nicht zugeordnete ans Ende, Voraussetzungen zuerst', () => {
    const g = nachSessions([
      z('SCH-1', 2), z('BIN-1', null, { ist_voraussetzung: true }), z('PAR-1', 1), z('KO-1', 1, { ist_voraussetzung: true }),
    ])
    expect(g.map((x) => x.nr)).toEqual([1, 2, null])
    expect(g[0].zeilen.map((x) => x.schluessel)).toEqual(['KO-1', 'PAR-1'])
    expect(g[0].titel).toBe('Titel 1')
    expect(g[2].nurVoraussetzungen).toBe(true)
  })

  it('zaehlt geprueft = zur Freigabe + freigegeben je Session', () => {
    const [s1] = nachSessions([
      z('A-1', 1, { status: 'zur_freigabe' }), z('A-2', 1, { status: 'freigegeben' }), z('A-3', 1), z('A-4', 1, { status: 'rueckfrage' }),
    ])
    expect(s1.stand).toEqual({ total: 4, geprueft: 2, freigegeben: 1 })
  })
})

describe('freigebbar', () => {
  it('liefert die Muster zur Freigabe', () => {
    const [g] = nachSessions([z('A-1', 1, { status: 'zur_freigabe' }), z('A-2', 1), z('A-3', 1, { status: 'freigegeben' })])
    expect(freigebbar(g)).toEqual(['A-1'])
  })
  it('nichts, solange ein Muster in Rueckfrage steht', () => {
    const [g] = nachSessions([z('A-1', 1, { status: 'zur_freigabe' }), z('A-2', 1, { status: 'rueckfrage' })])
    expect(freigebbar(g)).toEqual([])
  })
  it('nichts, wenn keines zur Freigabe steht', () => {
    const [g] = nachSessions([z('A-1', 1), z('A-2', 1, { status: 'freigegeben' })])
    expect(freigebbar(g)).toEqual([])
  })
})

it('passtZuFilter', () => {
  expect(passtZuFilter('rueckfrage', 'alle')).toBe(true)
  expect(passtZuFilter('rueckfrage', 'rueckfrage')).toBe(true)
  expect(passtZuFilter('zur_pruefung', 'freigegeben')).toBe(false)
})

describe('SP-1 Liste', () => {
  it('bauformTitel: eigener Titel, sonst Kernidee, Voraussetzung mit Skill', () => {
    expect(bauformTitel(z('A-1', 1, { titel: 'Werte einsetzen' }))).toBe('Werte einsetzen')
    expect(bauformTitel(z('A-1', 1, { kernidee_titel: 'K' }))).toBe('K')
    expect(bauformTitel(z('A-1', 1, { kernidee_titel: 'K', ist_voraussetzung: true }))).toBe('Skill')
  })
  it('pruefFortschritt: geprueft = nicht mehr zu pruefen, Aufgaben zur Freigabe summiert', () => {
    expect(pruefFortschritt([z('A-1', 1), z('A-2', 1, { status: 'rueckfrage' }), z('A-3', 1, { status: 'zur_freigabe', gruen: 5 })]))
      .toEqual({ total: 3, geprueft: 2, aufgabenZurFreigabe: 5 })
  })
  it('naechsteZuPruefen: in Listenreihenfolge nach der aktuellen, sonst von vorn, sonst null', () => {
    const l = [z('A-1', 1), z('A-2', 1, { status: 'zur_freigabe' }), z('B-1', 2), z('C-1', 3)]
    expect(naechsteZuPruefen(l, 'A-1')?.schluessel).toBe('B-1')
    expect(naechsteZuPruefen(l, 'C-1')?.schluessel).toBe('A-1')
    expect(naechsteZuPruefen([z('A-1', 1)], 'A-1')).toBeNull()
  })
  it('filterFuer: Freigegeben nur fuer Admins', () => {
    expect(filterFuer(false)).not.toContain('freigegeben')
    expect(filterFuer(true)).toContain('freigegeben')
  })
})
