// V4-S (docs/report/v4/Bauauftrag-V4-S.md, Entscheidungen 3–5): die anstehende Arbeit in Station 01 und 03 der
// Präsentation sowie auf Seite 1 und 3 des Berichts. Testkind Ida (bevorstehend), Batu (geschrieben) zum Vergleich.
import { cleanup, screen, within } from '@testing-library/react'
import { afterEach, describe, expect, it } from 'vitest'
import '@/i18n'

import de from '@/i18n/locales/de/elternbericht.json'
import { bogenV4 } from '@/test/elternberichtV4'

import { Station1V4 } from './Station1V4'
import { StationKlassenarbeiten } from './StationKlassenarbeiten'
import { zeigeV4 } from './testV4'

afterEach(cleanup)

const texte = (el: Element, sel: string): string[] => [...el.querySelectorAll(sel)].map((x) => x.textContent ?? '')

describe('Station 03, Karte „steht an“ (Ida)', () => {
  const karte = (): HTMLElement => {
    zeigeV4(StationKlassenarbeiten, 'idaBevorstehend')
    return screen.getAllByTestId('tp-ka-karte')[0]
  }

  it('eine Zeile statt der zwei doppelten Sätze, darunter das Signal', () => {
    const k = karte()
    expect(k.querySelector('small')).toHaveTextContent(de.v4.anstehend.vorbereiten)
    expect(k.textContent).not.toContain('Klassenarbeit zu')
    expect(k.textContent).not.toContain('steht noch an')
    expect(within(k).queryByTestId('tp-ka-stand')).toBeNull()
    expect(k.querySelector('.tp-ka-signal')).toHaveTextContent(de.v4.signal.fehlt)
  })

  it('je Gruppe eine Unterzeile, erst sicher, dann Übungsbedarf', () => {
    const k = karte()
    const im = within(k).getByTestId('tp-ka-gruppe-imThema')
    const vo = within(k).getByTestId('tp-ka-gruppe-voraus')
    expect(im.querySelector('.tp-ka-gruppe-titel')).toHaveTextContent(de.v4.anstehend.imThema)
    expect(vo.querySelector('.tp-ka-gruppe-titel')).toHaveTextContent(de.v4.anstehend.voraus)
    expect(texte(im, '.tp-ka-liste-sitzt li')).toEqual(['Streckfaktor und zentrische Streckung'])
    expect(texte(im, '.tp-ka-liste-fehlt li')).toEqual(['Erster Strahlensatz', 'Flächen und Volumen bei Ähnlichkeit', 'Zweiter Strahlensatz'])
    expect(texte(vo, '.tp-ka-liste-sitzt li')).toEqual(['Einschrittige Gleichungen'])
    expect(texte(vo, '.tp-ka-liste-fehlt li')).toEqual(['Potenzen und Quadratzahlen'])
    // sitzt vor fehlt in jeder Gruppe
    for (const g of [im, vo]) expect(g.querySelector('ul')!.className).toBe('tp-ka-liste-sitzt')
  })

  it('Batu (geschrieben): Karte des aktuellen Themas wie vorher, ohne Gruppen und Signal', () => {
    zeigeV4(StationKlassenarbeiten, 'batuV4')
    const k = screen.getAllByTestId('tp-ka-karte')[0]
    expect(k.querySelector('.tp-ka-signal')).toBeNull()
    expect(k.querySelector('.tp-ka-gruppe')).toBeNull()
    expect(within(k).getByTestId('tp-ka-stand')).toBeInTheDocument()
  })

  it('Batu ohne Stand: kein Signal, Satz bleibt', () => {
    zeigeV4(StationKlassenarbeiten, 'batuOhneStatus')
    const k = screen.getAllByTestId('tp-ka-karte')[0]
    expect(k.querySelector('.tp-ka-signal')).toBeNull()
    expect(within(k).getByTestId('tp-ka-stand')).toHaveTextContent('steht noch an')
  })
})

describe('Station 01 und Seite 1: das Signal an der aktuellen Station', () => {
  it('Station 01 (Ida) nennt das Signal an der ersten Station', () => {
    zeigeV4(Station1V4, 'idaBevorstehend')
    expect(screen.getAllByTestId('tp-fp-station')[0]).toHaveTextContent(de.v4.signal.fehlt)
  })

  it('Seite 1 (Ida) nennt das Signal an der ersten Station, Batu nicht', () => {
    const ida = bogenV4('idaBevorstehend')
    expect(within(ida.seite(1)).getAllByTestId('eb-fp-station')[0]).toHaveTextContent(de.v4.signal.fehlt)
    cleanup()
    const batu = bogenV4('batuV4')
    const erste = within(batu.seite(1)).getAllByTestId('eb-fp-station')[0]
    for (const s of Object.values(de.v4.signal)) expect(erste.textContent).not.toContain(s)
  })
})

describe('Seite 3: der erste Block für die anstehende Arbeit', () => {
  it('Ida: zuerst der Block der Arbeit, „Sitzt schon“ / „Fehlt noch“ je Gruppe', () => {
    const s3 = bogenV4('idaBevorstehend').seite(3)
    const block = within(s3).getByTestId('eb-s3-anstehend')
    expect(s3.querySelector('.eb-s3v4-bloecke')!.firstElementChild).toBe(block)
    expect(block.querySelector('h2')).toHaveTextContent('Mit Maßband und Jakobsstab unterwegs: Zentrische Streckungen')
    expect(within(block).getByTestId('eb-s3-signal')).toHaveTextContent(de.v4.signal.fehlt)
    const sitzt = within(block).getByTestId('eb-s3-sitzt')
    const fehlt = within(block).getByTestId('eb-s3-fehlt')
    expect(texte(sitzt, 'h4')).toEqual([de.v4.anstehend.imThema, de.v4.anstehend.voraus])
    expect(texte(fehlt, 'h4')).toEqual([de.v4.anstehend.imThema, de.v4.anstehend.voraus])
    expect(texte(fehlt, 'li')).toEqual(['Erster Strahlensatz', 'Flächen und Volumen bei Ähnlichkeit', 'Zweiter Strahlensatz', 'Potenzen und Quadratzahlen'])
    expect(texte(sitzt, 'li')).toEqual(['Streckfaktor und zentrische Streckung', 'Einschrittige Gleichungen'])
    // Der Einstiegssatz „bevorstehend“ bleibt.
    expect(within(s3).getByTestId('eb-s3-einstieg')).toHaveAttribute('data-ka', 'steht')
  })

  it('Ida: kein geprüfter Bereich geht verloren, auch ohne den neuen Block gezählt', () => {
    const b = bogenV4('idaBevorstehend')
    const s3 = b.seite(3)
    s3.querySelector('[data-testid="eb-s3-anstehend"]')!.remove()
    const gezeigt = new Set(texte(s3, '.eb-s3v4-bereiche li, .eb-s3v4-chips li'))
    for (const x of [...b.bericht.sicherListe, ...b.bericht.uebungListe]) expect(gezeigt.has(x.label), x.label).toBe(true)
  })

  it('Batu (geschrieben, ohne Stand): kein Block für die aktuelle Arbeit', () => {
    for (const fall of ['batuV4', 'batuOhneStatus']) {
      expect(within(bogenV4(fall).seite(3)).queryByTestId('eb-s3-anstehend')).toBeNull()
      cleanup()
    }
  })
})
