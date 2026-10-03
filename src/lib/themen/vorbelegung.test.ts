import { describe, expect, it } from 'vitest'
import type { LeadThema, SchulPlanZeile } from '@/types'
import { TEST_KATALOG } from './katalog.fixture'
import { abgleichBehandelt, chipGruppen, planStand, vorbelegungBehandelt } from './vorbelegung'

const z = (klasse: number, position: number, thema_key: string | null): SchulPlanZeile => ({
  klasse,
  position,
  thema_key,
  stand: '08/2021',
})

// Ein Plan wie aus schul_themenplan: Klassen 5–9, mit einer Wiederholung und
// einem nicht zuordenbaren Vorhaben (thema_key null).
const PLAN: SchulPlanZeile[] = [
  z(5, 1, 'rechnen_natuerliche_zahlen'),
  z(5, 2, 'daten_streumasse'),
  z(6, 1, 'brueche'),
  z(6, 2, null),
  z(7, 1, 'rationale_zahlen'),
  z(7, 2, 'zinsrechnung'),
  z(7, 3, 'lineare_funktionen'),
  z(7, 4, 'zinsrechnung'),
  z(8, 1, 'terme_binomische_formeln'),
  z(9, 1, 'reelle_zahlen'),
]

describe('vorbelegungBehandelt', () => {
  it('mit Plan: niedrigere Klassen plus eigene Klasse vor dem aktuellen Thema', () => {
    expect(vorbelegungBehandelt(PLAN, 7, 'lineare_funktionen')).toEqual([
      'rechnen_natuerliche_zahlen',
      'daten_streumasse',
      'brueche',
      'rationale_zahlen',
      'zinsrechnung',
    ])
  })

  it('kommt das Thema mehrfach vor, zaehlt sein erstes Vorhaben', () => {
    expect(vorbelegungBehandelt(PLAN, 7, 'zinsrechnung')).toEqual([
      'rechnen_natuerliche_zahlen',
      'daten_streumasse',
      'brueche',
      'rationale_zahlen',
    ])
  })

  it('Thema nicht im Plan der Klasse: nur die niedrigeren Klassen', () => {
    expect(vorbelegungBehandelt(PLAN, 7, 'thales_konstruktionen')).toEqual([
      'rechnen_natuerliche_zahlen',
      'daten_streumasse',
      'brueche',
    ])
  })

  it('ohne aktuelles Thema: nur die niedrigeren Klassen', () => {
    expect(vorbelegungBehandelt(PLAN, 6, null)).toEqual([
      'rechnen_natuerliche_zahlen',
      'daten_streumasse',
    ])
  })

  it('ohne Plan: nichts', () => {
    expect(vorbelegungBehandelt([], 7, 'lineare_funktionen')).toEqual([])
  })

  it('ohne Klasse: nichts', () => {
    expect(vorbelegungBehandelt(PLAN, null, 'lineare_funktionen')).toEqual([])
  })

  it('Klasse 5: keine niedrigeren Klassen, nur die Vorhaben davor', () => {
    expect(vorbelegungBehandelt(PLAN, 5, 'daten_streumasse')).toEqual([
      'rechnen_natuerliche_zahlen',
    ])
    expect(vorbelegungBehandelt(PLAN, 5, 'rechnen_natuerliche_zahlen')).toEqual([])
    expect(vorbelegungBehandelt(PLAN, 5, 'reelle_zahlen')).toEqual([])
  })

  it('das aktuelle Thema ist nie vorbelegt, auch wenn es frueher schon dran war', () => {
    expect(vorbelegungBehandelt(PLAN, 9, 'brueche')).not.toContain('brueche')
  })
})

describe('planStand', () => {
  it('nimmt den ersten gesetzten Stand', () => {
    expect(planStand(PLAN)).toBe('08/2021')
    expect(planStand([])).toBeNull()
  })
})

describe('abgleichBehandelt', () => {
  const lt = (thema_key: string, status: LeadThema['status'], quelle: LeadThema['quelle']): LeadThema => ({
    thema_key,
    fach: 'mathematik',
    status,
    quelle,
  })

  it('legt Fehlendes an und raeumt veraltete Schulplan-Zeilen weg, Gespraech bleibt', () => {
    const vorhanden = [
      lt('brueche', 'behandelt', 'schulplan'),
      lt('kreis', 'behandelt', 'schulplan'),
      lt('thales_konstruktionen', 'behandelt', 'gespraech'),
      lt('lineare_funktionen', 'aktuell', 'gespraech'),
    ]
    expect(abgleichBehandelt(vorhanden, ['brueche', 'rationale_zahlen'])).toEqual({
      anlegen: ['rationale_zahlen'],
      entfernen: ['kreis'],
    })
  })
})

describe('chipGruppen', () => {
  it('ohne Plan: eine Gruppe in Katalog-Reihenfolge', () => {
    const g = chipGruppen(TEST_KATALOG, 'zweite', [])
    expect(g).toHaveLength(1)
    expect(g[0].klasse).toBeNull()
    expect(g[0].themen[0].thema_key).toBe('reelle_zahlen')
  })

  it('mit Plan: je Klasse in Plan-Reihenfolge, Rest der Stufe am Ende', () => {
    const g = chipGruppen(TEST_KATALOG, 'erste', PLAN)
    expect(g.map((x) => x.klasse)).toEqual([7, 8, null])
    expect(g[0].themen.map((t) => t.thema_key)).toEqual([
      'rationale_zahlen',
      'zinsrechnung',
      'lineare_funktionen',
    ])
    expect(g[2].themen.map((t) => t.thema_key)).toContain('thales_konstruktionen')
  })
})
