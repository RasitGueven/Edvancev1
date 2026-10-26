// Bericht v4, V4-2: Seite 3 mit einem Block je Klassenarbeit.
import { within } from '@testing-library/react'
import { describe, expect, it } from 'vitest'
import '@/i18n'

import de from '@/i18n/locales/de/elternbericht.json'
import { bogenV4, MIT_FAHRPLAN } from '@/test/elternberichtV4'

const bloecke = (el: HTMLElement): HTMLElement[] => within(el).queryAllByTestId('eb-s3-block')

describe('Seite 3 mit Fahrplan', () => {
  it('batuV4: ein Block je kommender Arbeit mit Signal, mit Nummer, Titel, Stand und Signal-Chip', () => {
    const b = bogenV4('batuV4')
    const f = b.bericht.fahrplan!
    const mitSignal = f.stationen.filter((s) => s.signal === 'fehlt' || s.signal === 'erfuellt')
    const bl = bloecke(b.seite(3))
    expect(bl).toHaveLength(mitSignal.length)
    bl.forEach((block, i) => {
      const s = mitSignal[i]
      expect(block.querySelector('h2')!.textContent).toBe(`Klassenarbeit ${s.nummer} · ${s.titel}`)
      expect(block.querySelector('.eb-s3v4-nr')).toHaveTextContent(String(s.nummer))
      expect(block.querySelector('[data-testid="eb-s3-signal"]')).toHaveTextContent(de.v4.signal[s.signal!])
    })
    expect(bl[0]).toHaveTextContent('nächste Arbeit')
    expect(bl[1]).toHaveTextContent('voraussichtlich')
  })

  it('batuV4: Sitzt schon / Fehlt noch aus bericht.lueckenwegV4, ohne „betrifft auch“, Pfeil und „Kommt noch“', () => {
    const b = bogenV4('batuV4')
    const lw = b.bericht.lueckenwegV4!
    bloecke(b.seite(3)).forEach((block, i) => {
      const liste = (art: string): string[] =>
        [...block.querySelectorAll(`[data-testid="eb-s3-${art}"] .eb-s3v4-bereiche li`)].map((li) => li.textContent!)
      expect(liste('sitzt')).toEqual(lw.themen[i].sitzt.map((z) => z.label))
      expect(liste('fehlt')).toEqual(lw.themen[i].fehlt.map((z) => z.label))
    })
    const s3 = b.seite(3).textContent!
    expect(s3).not.toMatch(/betrifft auch/)
    expect(b.seite(3).querySelector('.eb-s3v3-pfeil')).toBeNull()
    expect(s3).not.toContain('Kommt noch')
  })

  it('ein Bereich kann in mehreren Blöcken stehen', () => {
    const b = bogenV4('batuV4')
    const alle = bloecke(b.seite(3)).flatMap((bl) => [...bl.querySelectorAll('.eb-s3v4-bereiche li')].map((li) => li.textContent))
    expect(alle.length).toBeGreaterThan(new Set(alle).size) // „Werte in Terme einsetzen“ in Block 2 und 3
  })

  for (const fall of MIT_FAHRPLAN) {
    it(`${fall}: kein geprüfter Bereich geht verloren (ein Block oder eine der Restgruppen)`, () => {
      const b = bogenV4(fall)
      const s3 = b.seite(3)
      const gezeigt = new Set(
        [...s3.querySelectorAll('.eb-s3v4-bereiche li, .eb-s3v4-chips li')].map((li) => li.textContent),
      )
      const alle = [...b.bericht.sicherListe, ...b.bericht.uebungListe].map((x) => x.label)
      for (const label of alle) expect(gezeigt.has(label), `${fall}: ${label}`).toBe(true)
    })
  }

  // LSA-L4 Teil D: der Satz nach dem Stand der Klassenarbeit (kaSatz), je Fall ein Fixture.
  it('Einstieg „geschrieben, Note offen“ (batuV4): sicher/unsicher und der Abgleich', () => {
    const e = within(bogenV4('batuV4').seite(3)).getByTestId('eb-s3-einstieg')
    expect(e).toHaveAttribute('data-ka', 'offen')
    expect(e.textContent).toMatch(/^Die Analyse zeigt für Reelle Zahlen( und Wurzeln)?: sicher war(en)? .+, noch unsicher .+\./)
    expect(e.textContent).toContain('Sobald Sie die Note kennen, gleichen wir das gemeinsam ab.')
    expect(e.textContent).toContain('Diese Übersicht beginnt mit Klassenarbeit 2.')
    expect(e.textContent).not.toMatch(/Deshalb/)
    expect(e.querySelector('b')).toHaveTextContent('Reelle Zahlen')
  })

  it('Einstieg „geschrieben, Note bekannt“ (batuMitNote): Note, „dazu passt“, kommende Arbeit', () => {
    const e = within(bogenV4('batuMitNote').seite(3)).getByTestId('eb-s3-einstieg')
    expect(e).toHaveAttribute('data-ka', 'note')
    expect(e.textContent).toMatch(/ist mit Note 4 zurückgekommen\. Dazu passt, was die Analyse zeigt: .+ (war|waren) noch unsicher\./)
    expect(e.textContent).toMatch(/(wird|werden) bei Klassenarbeit \d+ wieder gebraucht\./)
    expect(e.textContent).not.toMatch(/\bweil\b|tr(ä|ae)gt/)
  })

  it('Einstieg „steht an“ und „unbekannt“: derselbe Satz', () => {
    for (const fall of ['batuBevorstehend', 'batuOhneStatus'] as const) {
      const e = within(bogenV4(fall).seite(3)).getByTestId('eb-s3-einstieg')
      expect(e, fall).toHaveAttribute('data-ka', 'steht')
      expect(e.textContent, fall).toMatch(/^Die Arbeit zu Reelle Zahlen( und Wurzeln)? steht noch an\. Darauf bereiten wir zuerst vor\./)
      expect(e.textContent, fall).toContain('Für die Arbeiten danach steht hier')
    }
  })

  it('„Weitere Stärken“ (mint, weiße Chips) und „Wird später wichtig“ (Chips)', () => {
    const b = bogenV4('batuV4')
    const lw = b.bericht.lueckenwegV4!
    const s3 = within(b.seite(3))
    const staerken = [...s3.getByTestId('eb-s3-weitere-staerken').querySelectorAll('li')].map((li) => li.textContent)
    expect(staerken).toEqual(lw.weitereStaerken)
    const spaeter = [...s3.getByTestId('eb-s3-weitere').querySelectorAll('.eb-s3v4-chips li')].map((li) => li.textContent)
    expect(spaeter).toEqual(lw.weitere.flatMap((g) => g.labels))
    expect(s3.getByTestId('eb-s3-weitere')).toHaveTextContent(de.v4.s3.spaeterIntro)
  })

  it('die Fußnote zur Quelle bleibt', () => {
    expect(bogenV4('batuV4').seite(3).querySelector('.eb-s3-hinweis')).toHaveTextContent('Schulplan des Friedrich-Wilhelm-Gymnasiums')
  })

  it('Layout A bleibt, wie es ist (v3-Kästen aus bericht.lueckenweg)', () => {
    const b = bogenV4('batuV4', { einordnung: 'A' })
    expect(within(b.seite(3)).getByTestId('eb-s3')).toHaveAttribute('data-layout', 'A')
    expect(within(b.seite(3)).queryAllByTestId('eb-s3-block')).toHaveLength(0)
  })

  it('ohnePlan: Seite 3 wie v3', () => {
    const b = bogenV4('ohnePlan')
    expect(within(b.seite(3)).queryAllByTestId('eb-s3-block')).toHaveLength(0)
    expect(within(b.seite(3)).queryByTestId('eb-s3-einstieg')).toBeNull()
  })
})
