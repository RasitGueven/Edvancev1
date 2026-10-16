// Themenliste mit Sollzahlen (P2): Restbedarf im Reiter, "X von Y noetig" und "reicht fuer die LSA" je Thema,
// aufgeklappt Knoten mit Soll, gezaehlt und "mind. 1 ohne Multiple Choice"; ohne Soll wie bisher.

import { describe, expect, it, vi } from 'vitest'
import { render, screen, within } from '@testing-library/react'
import '@/i18n'
import type { LenaStatus, PruefBoardZeile, PruefSollZeile } from '@/types'
import { Themenliste } from './Uebersicht'

function zeile(id: string, n: number, over: Partial<PruefBoardZeile> = {}, status: LenaStatus = 'offen'): PruefBoardZeile {
  return {
    task_id: id, stufe: 'zweite', thema_key: 'reelle_zahlen', thema_label: 'Reelle Zahlen', thema_sort: 410,
    skill_key: 'zahl_wurzel_quadrat', skill_label: 'Quadratwurzeln', kurztitel: `Aufgabe ${id}`, reihenfolge: n,
    lena_status: status, geaendert: false, letzte_dauer_sek: null, anlaesse: ['batu_lsa'], hat_hinweise: false, ...over,
  }
}

function soll(skill: string, over: Partial<PruefSollZeile> = {}): PruefSollZeile {
  return {
    skill_key: skill, skill_label: skill, thema_key: 'reelle_zahlen', thema_label: 'Reelle Zahlen', thema_sort: 410,
    stufe: 'zweite', sort: 110, anlaesse: ['batu_lsa'], soll: 2, min_ohne_mc: 1, im_board: 2, gezaehlt: 0,
    gezaehlt_ohne_mc: 0, rest: 2, reicht: false, ...over,
  }
}

const board = [
  zeile('t1', 1, {}, 'passt'),
  zeile('t2', 2, {}, 'freigegeben'),
  zeile('t3', 3, { skill_key: 'zahl_wurzel_gesetze', skill_label: 'Wurzelgesetze' }),
  zeile('t4', 4, { skill_key: 'zahl_wurzel_gesetze', skill_label: 'Wurzelgesetze' }),
  zeile('t5', 5, { thema_key: 'kreis', thema_label: 'Kreis', thema_sort: 500, skill_key: 'geo_kreis', skill_label: 'Kreis' }),
  zeile('t6', 6, { stufe: 'erste', thema_key: 'terme', thema_label: 'Terme', skill_key: 'term', skill_label: 'Term' }),
]
const sollZeilen = [
  soll('zahl_wurzel_quadrat', { skill_label: 'Quadratwurzeln', sort: 150, gezaehlt: 2, gezaehlt_ohne_mc: 1, rest: 0, reicht: true }),
  soll('zahl_wurzel_gesetze', { skill_label: 'Wurzelgesetze', sort: 140, rest: 2 }),
]

function liste(offen: string[], s: PruefSollZeile[] = sollZeilen) {
  return render(
    <Themenliste board={board} soll={s} stufen={['erste', 'zweite']} aktiv="zweite" offen={new Set(offen)}
      onReiter={vi.fn()} onThema={vi.fn()} onPruefen={vi.fn()} onAufgabe={vi.fn()} />,
  )
}

describe('Themenliste mit Sollzahlen', () => {
  it('Reiter: "noch X zu pruefen" mit Soll, sonst gepruefte von gesamt', () => {
    liste([])
    expect(screen.getByRole('tab', { name: /Klasse 9\/10/ })).toHaveTextContent('noch 2 zu prüfen')
    expect(screen.getByRole('tab', { name: /Klasse 7\/8/ })).toHaveTextContent('0 / 1')
  })

  it('Thema: "X von Y noetig", Soll-Themen zuerst; ohne Soll keine Angabe', () => {
    liste([])
    const knoepfe = screen.getAllByRole('button', { name: /aufklappen/ })
    expect(knoepfe.map((k) => k.textContent)).toEqual(['Reelle Zahlen2 von 4 nötig', 'Kreis'])
    expect(screen.queryByText('reicht für die LSA')).toBeNull()
  })

  it('reicht fuer die LSA, wenn alle Knoten des Themas reichen', () => {
    liste([], [sollZeilen[0]])
    expect(screen.getByText('reicht für die LSA')).toBeInTheDocument()
  })

  it('aufgeklappt: Knoten nach sort mit Soll, gezaehlt und MC-Bedingung; fertig ausgegraut, nicht versteckt', () => {
    liste(['reelle_zahlen'])
    const gesetze = screen.getByTestId('knoten-zahl_wurzel_gesetze')
    const quadrat = screen.getByTestId('knoten-zahl_wurzel_quadrat')
    expect(gesetze.compareDocumentPosition(quadrat) & Node.DOCUMENT_POSITION_FOLLOWING).toBeTruthy()
    expect(gesetze).toHaveTextContent('Soll 2 · 0 gezählt')
    expect(gesetze).toHaveTextContent('mind. 1 ohne Multiple Choice: offen')
    expect(gesetze).not.toHaveClass('opacity-60')
    expect(quadrat).toHaveTextContent('Soll 2 · 2 gezählt')
    expect(quadrat).toHaveTextContent('mind. 1 ohne Multiple Choice: erfüllt')
    expect(quadrat).toHaveTextContent('reicht')
    expect(quadrat).toHaveClass('opacity-60')
    expect(within(quadrat).getAllByRole('button')).toHaveLength(2)
    // Nummern wie im Thema (Board-Reihenfolge), nicht je Knoten neu.
    expect(within(gesetze).getByRole('button', { name: /3\. Aufgabe t3/ })).toBeInTheDocument()
  })

  it('Thema ohne Soll klappt wie bisher als flache Liste auf', () => {
    liste(['kreis'])
    expect(screen.queryByTestId('knoten-geo_kreis')).toBeNull()
    expect(screen.getByRole('button', { name: /1\. Aufgabe t5/ })).toBeInTheDocument()
  })
})

describe('Themenliste ohne Reiter (Session-Bereich)', () => {
  it('alle Themen aller Stufen, keine Reiter, aufgeklappt nach Knoten, mit Kennzeichnung', () => {
    render(
      <Themenliste board={board} soll={[]} stufen={['erste', 'zweite']} aktiv="erste" offen={new Set(['kreis'])}
        onReiter={vi.fn()} onThema={vi.fn()} onPruefen={vi.fn()} onAufgabe={vi.fn()} reiter={false}
        zusatz={(z) => (z.task_id === 't5' ? 'auch LSA' : null)} />,
    )
    expect(screen.queryByRole('tab')).toBeNull()
    const knoepfe = screen.getAllByRole('button', { name: /aufklappen|zuklappen/ })
    expect(knoepfe.map((k) => k.textContent)).toEqual(['Terme', 'Reelle Zahlen', 'Kreis'])
    expect(screen.getByTestId('knoten-geo_kreis')).toHaveTextContent('auch LSA')
  })

  it('"reicht" mit dem Text des Bereichs', () => {
    render(
      <Themenliste board={board} soll={[sollZeilen[0]]} stufen={['zweite']} aktiv="zweite" offen={new Set()}
        onReiter={vi.fn()} onThema={vi.fn()} onPruefen={vi.fn()} onAufgabe={vi.fn()} reiter={false} reichtText="reicht für die Session" />,
    )
    expect(screen.getByText('reicht für die Session')).toBeInTheDocument()
    expect(screen.queryByText('reicht für die LSA')).toBeNull()
  })
})
