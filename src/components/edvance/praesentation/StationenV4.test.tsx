// V4-3: Stationsliste mit und ohne Fahrplan, Station 01 (Pyramide, Fahrplan,
// keine Eckdaten), Station 02 (Eckdaten, „Wichtig für“) und Station 03
// (Klassenarbeiten). Daten aus PRAESENTATION_FAELLE (batuV4 u. a.).
import { cleanup, fireEvent, render, screen, within } from '@testing-library/react'
import { afterEach, describe, expect, it, vi } from 'vitest'
import '@/i18n'

import { PRAESENTATION_FAELLE } from '@/lib/report/praesentation/fixtures'

import { Praesentation } from './Praesentation'
import { Station2 } from './Station2'
import { Station1V4 } from './Station1V4'
import { StationKlassenarbeiten } from './StationKlassenarbeiten'
import { baueV4 } from './v4Daten'
import { zeigeStation } from './testStation'
import { zeigeV4 } from './testV4'

const F = PRAESENTATION_FAELLE

afterEach(cleanup)

function oeffne(fall: string): void {
  const f = F[fall]
  render(
    <Praesentation
      data={f.data}
      notes={f.notes}
      tiers={f.tiers}
      tiersFehler={false}
      sessionId={f.data.sessionId}
      laden={false}
      onSchliessen={vi.fn()}
    />,
  )
}

const leiste = (): string[] =>
  within(screen.getByRole('navigation', { name: 'Stationen direkt anwählen' }))
    .getAllByRole('button')
    .map((b) => b.textContent ?? '')

describe('Stationsliste', () => {
  it('batuV4: vier Stationen Überblick · Lernstand · Klassenarbeiten · Förderansatz', () => {
    oeffne('batuV4')
    expect(leiste()).toEqual(['01Überblick', '02Lernstand', '03Klassenarbeiten', '04Förderansatz'])
    expect(document.querySelectorAll('.tp-station')).toHaveLength(4)
    expect(screen.getByTestId('tp-fahrplan')).toBeInTheDocument()
    expect(screen.getByTestId('tp-ka-raster')).toBeInTheDocument()
    expect(screen.getByTestId('tp-s4v-kasten')).toBeInTheDocument()
  })

  it('ohnePlan: ohne Fahrplan gilt die bisherige Zuordnung (Einordnung bleibt Station 03)', () => {
    expect(baueV4(F.ohnePlan.data, F.ohnePlan.notes)).toBeNull()
    oeffne('ohnePlan')
    expect(leiste()).toEqual(['01Überblick', '02Lernstand', '03Lernweg', '04Förderansatz'])
    expect(screen.queryByTestId('tp-fahrplan')).toBeNull()
    expect(screen.queryByTestId('tp-ka-raster')).toBeNull()
    expect(screen.queryByTestId('tp-s4v-kasten')).toBeNull()
    expect(screen.getByTestId('tp-s1-gelungen')).toBeInTheDocument()
  })

  it('zeigt nirgends einen Preis oder eine Fehlerbilder-Liste', () => {
    for (const fall of ['batuV4', 'fahrplanLang', 'allesErfuellt']) {
      oeffne(fall)
      const text = document.body.textContent ?? ''
      expect(text, fall).not.toContain('€')
      expect(text, fall).not.toMatch(/Fehlermuster|Fehlerbild/)
      cleanup()
    }
  })
})

describe('Station 01 · Überblick (V4)', () => {
  it('batuV4: Pyramide rechts, Fahrplan darunter mit Satz, keine Eckdaten', () => {
    const { v4 } = zeigeV4(Station1V4, 'batuV4')
    expect(within(screen.getByTestId('tp-s1-pyramide')).getAllByRole('listitem')).toHaveLength(v4.bericht.stufen?.length ?? -1)
    const stationen = screen.getAllByTestId('tp-fp-station')
    expect(stationen).toHaveLength(v4.fahrplan.stationen.length)
    expect(screen.getAllByTestId('tp-fp-punkt')).toHaveLength(v4.fahrplan.stationen.length)
    expect(stationen[0]).toHaveTextContent('geschrieben')
    expect(stationen[1]).toHaveTextContent('nächste Arbeit')
    expect(stationen[1]).toHaveTextContent('Voraussetzungen fehlen noch')
    expect(screen.getByTestId('tp-fp-satz')).toHaveTextContent('Vieles sitzt schon.')
    // Eckdaten stehen in Station 02.
    expect(screen.queryByTestId('tp-s2-eckdaten')).toBeNull()
    expect(screen.queryByText('Aufgaben bearbeitet')).toBeNull()
  })

  it('batuV4: Leitsatz mit dem Sorgfalt-Satz, ohne einzelne Voraussetzungen', () => {
    const { v4, container } = zeigeV4(Station1V4, 'batuV4')
    expect(v4.muster?.sorgfalt).toBe(true)
    expect(screen.getByTestId('tp-s1-leitsatz')).toHaveTextContent(/findet meist den richtigen Weg.*fehlende Sorgfalt/)
    const alle = (v4.bericht.signale ?? []).flatMap((s) => [...s.sitzt, ...s.fehlt]).map((b) => b.label)
    expect(alle.length).toBeGreaterThan(0)
    // Die Pyramide nennt keine Bereiche, der Fahrplan nur Titel und Signal.
    for (const label of new Set(alle)) {
      const treffer = [...container.querySelectorAll('*')].filter(
        (el) => el.children.length === 0 && el.textContent === label,
      )
      expect(treffer, label).toHaveLength(0)
    }
  })

  it('allesErfuellt: der Satz „Voraussetzungen sitzen“; ohne Satz bei nur grauen Stationen entfällt er', () => {
    const { v4 } = zeigeV4(Station1V4, 'allesErfuellt')
    expect(v4.fahrplan.satz).toBe('erfuellt')
    expect(screen.getByTestId('tp-fp-satz')).toHaveTextContent('sitzen die geprüften Voraussetzungen')
  })

  it('fahrplanLang: höchstens vier kommende Stationen und „+n weitere“', () => {
    const { v4 } = zeigeV4(Station1V4, 'fahrplanLang')
    expect(v4.fahrplan.stationen).toHaveLength(5)
    expect(screen.getByTestId('tp-fp-weitere')).toHaveTextContent(`+${v4.fahrplan.weitere} weitere Themen`)
  })

  it('fahrplanAuffuellen: Trenner „Klasse 8“ vor der ersten Station des nächsten Schuljahrs', () => {
    const { v4, container } = zeigeV4(Station1V4, 'fahrplanAuffuellen')
    expect(v4.fahrplan.klassenTrenner).toBe(8)
    expect(container.querySelector('.tp-fp-trenner')).toHaveTextContent('Klasse 8')
  })

  it('batuMitNote: „Note 4“ an der geschriebenen Station', () => {
    zeigeV4(Station1V4, 'batuMitNote')
    expect(screen.getAllByTestId('tp-fp-station')[0]).toHaveTextContent('Note 4')
  })
})

describe('Station 02 · Lernstand (V4)', () => {
  it('batuV4: vier Eckdaten über dem Profil, Titel mit Genitiv', () => {
    const { v4 } = zeigeV4(Station2, 'batuV4')
    const eck = screen.getByTestId('tp-s2-eckdaten')
    expect(within(eck).getByText('Aufgaben bearbeitet')).toBeInTheDocument()
    expect(within(eck).getByText('Bereiche geprüft')).toBeInTheDocument()
    expect(within(eck).getByText('sicher')).toBeInTheDocument()
    expect(within(eck).getByText('Übungsbedarf')).toBeInTheDocument()
    expect(screen.getByTestId('tp-s2-eck-aufgaben')).toHaveTextContent(String(v4.aufgaben))
    expect(screen.getByTestId('tp-s2-eck-bereiche')).toHaveTextContent(/\d+/)
    expect(screen.getByRole('heading', { level: 2 })).toHaveTextContent(/s Kompetenzprofil\.$/)
    // Die Zahl der Kästchen je Zeile ist die Zahl der geprüften Bereiche.
    const kaesten = screen.getAllByTestId('tp-s2-kasten').length
    expect(kaesten).toBe(Number(screen.getByTestId('tp-s2-eck-bereiche').querySelector('strong')?.textContent))
  })

  it('Felder aufsteigend nach Klassenstufe, mit Klassenangabe', () => {
    zeigeV4(Station2, 'batuV4')
    const zeilen = [...document.querySelectorAll('[data-tp-zeile] .tp-s2-feld small')].map((e) => e.textContent ?? '')
    expect(zeilen.length).toBeGreaterThan(1)
    const klasse = (s: string): number => Number(s.match(/\d+/)?.[0])
    expect(zeilen.map(klasse)).toEqual([...zeilen.map(klasse)].sort((a, b) => a - b))
  })

  it('im Detail die Spalte „Wichtig für“ mit Nummer und Titel, nächste Arbeit hervorgehoben', () => {
    zeigeV4(Station2, 'batuV4')
    const knoepfe = [...document.querySelectorAll<HTMLElement>('[data-tp-zeile] [aria-expanded]')]
    let gefunden = 0
    for (const k of knoepfe) {
      fireEvent.click(k)
      const spalte = screen.queryAllByTestId('tp-s2-wichtig')
      gefunden += spalte.length
    }
    expect(gefunden).toBeGreaterThan(0)
    const marken = [...document.querySelectorAll('.tp-s2-marke')]
    expect(marken.length).toBeGreaterThan(0)
    for (const m of marken) expect(m.querySelector('b')?.textContent).toMatch(/^\d+$/)
    expect(document.querySelector('.tp-s2-marke-naechste')).toHaveTextContent('nächste Arbeit')
    // Bereiche ohne Thema: „wird in späteren Schuljahren wichtig“
    expect(document.body.textContent).toContain('wird in späteren Schuljahren wichtig')
  })

  it('ohne Fahrplan: Station 02 bleibt wie vor V4 (keine Eckdaten, Balken statt Kästchen)', () => {
    zeigeStation(Station2, 'ilkay')
    expect(screen.queryByTestId('tp-s2-eckdaten')).toBeNull()
    expect(screen.queryAllByTestId('tp-s2-kasten')).toHaveLength(0)
    expect(screen.getAllByTestId('tp-s2-anteil').length).toBeGreaterThan(0)
  })
})

describe('Station 03 · Klassenarbeiten', () => {
  it('batuV4: eine Karte je Station, Signale und Listen nach V4-1', () => {
    const { v4 } = zeigeV4(StationKlassenarbeiten, 'batuV4')
    const karten = screen.getAllByTestId('tp-ka-karte')
    expect(karten).toHaveLength(v4.fahrplan.stationen.length)
    expect(within(karten[0]).getByTestId('tp-ka-chip')).toHaveTextContent('geschrieben')
    expect(karten[0].className).toContain('tp-ka-geschrieben')
    expect(within(karten[1]).getByTestId('tp-ka-chip')).toHaveTextContent('nächste Arbeit')
    expect(karten[1]).toHaveTextContent('Voraussetzungen fehlen noch')
    expect(within(karten[1]).getByTestId('tp-ka-sitzt')).toBeInTheDocument()
    expect(within(karten[1]).getByTestId('tp-ka-fehlt')).toBeInTheDocument()
    // Jede Karte mit Signal fehlt/erfüllt hat höchstens drei Einträge je Liste plus „+n weitere“.
    for (const li of screen.queryAllByTestId('tp-ka-fehlt')) {
      expect(li.querySelectorAll('li:not(.tp-ka-weitere)').length).toBeLessThanOrEqual(3)
    }
    // „ohne“ grau mit dem Text und ohne Listen
    const ohne = karten.filter((k) => k.className.includes('tp-ka-ohne'))
    for (const k of ohne) {
      expect(k).toHaveTextContent('dazu noch nichts geprüft')
      expect(k.querySelector('ul')).toBeNull()
    }
    expect(screen.getByTestId('tp-ka-offen')).toHaveTextContent('war noch unsicher')
    expect(screen.getByTestId('tp-ka-quelle')).toHaveTextContent('Schulplan des Friedrich-Wilhelm-Gymnasiums')
    expect(screen.getByTestId('tp-ka-satz')).toHaveTextContent('Vieles sitzt schon.')
  })

  it('fahrplanLang: fünf Karten und „+n weitere“', () => {
    const { v4 } = zeigeV4(StationKlassenarbeiten, 'fahrplanLang')
    expect(screen.getAllByTestId('tp-ka-karte')).toHaveLength(5)
    expect(screen.getByText(`+${v4.fahrplan.weitere} weitere Themen bis zum Schuljahresende`)).toBeInTheDocument()
  })

  it('fahrplanAuffuellen: Karten des nächsten Schuljahrs tragen „Klasse 8“', () => {
    zeigeV4(StationKlassenarbeiten, 'fahrplanAuffuellen')
    const karten = screen.getAllByTestId('tp-ka-karte')
    expect(karten.filter((k) => k.textContent?.includes('Klasse 8'))).toHaveLength(2)
  })

  it('allesErfuellt: Signal „Voraussetzungen sitzen“, kein „fehlt“, Untertitel nach dem Satz', () => {
    zeigeV4(StationKlassenarbeiten, 'allesErfuellt')
    expect(screen.queryByText('Voraussetzungen fehlen noch')).toBeNull()
    expect(screen.getAllByText('Voraussetzungen sitzen').length).toBeGreaterThan(0)
    expect(screen.getByTestId('tp-ka-satz')).toHaveTextContent('sitzen die geprüften Voraussetzungen')
    expect(screen.queryAllByTestId('tp-ka-fehlt')).toHaveLength(0)
  })
})
