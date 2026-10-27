// Bericht v4, V4-2: Seite 1 mit Fahrplan — ein Signal je Arbeit, keine einzelnen Voraussetzungen.
import { within } from '@testing-library/react'
import { describe, expect, it } from 'vitest'
import '@/i18n'

import de from '@/i18n/locales/de/elternbericht.json'
import { bogenV4, MIT_FAHRPLAN } from '@/test/elternberichtV4'

describe('Seite 1 mit Fahrplan', () => {
  it('batuV4: Stationen in Plan-Reihenfolge, Stand und Signal je Arbeit', () => {
    const b = bogenV4('batuV4')
    const f = b.bericht.fahrplan!
    const spalten = within(b.seite(1)).getAllByTestId('eb-fp-station')
    expect(spalten).toHaveLength(f.stationen.length)
    spalten.forEach((spalte, i) => {
      const s = f.stationen[i]
      expect(spalte.querySelector('.eb-fp-titel')).toHaveTextContent(s.titel)
      if (s.signal) expect(spalte.querySelector('.eb-fp-signal')).toHaveTextContent(de.v4.signal[s.signal])
      else expect(spalte.querySelector('.eb-fp-signal')).toBeNull()
    })
    // L5: Folge unbekannt — das nächste Thema im Unterricht, danach „danach“; keine „nächste Arbeit“.
    expect(spalten[0]).toHaveTextContent('geschrieben')
    expect(spalten[1]).toHaveTextContent('als Nächstes im Unterricht')
    expect(spalten[2]).toHaveTextContent('danach')
    expect(b.seite(1).textContent).not.toMatch(/nächste Arbeit|voraussichtlich/)
  })

  it('batuEigen (L5, Folge bekannt): Ziffern der Arbeiten, Themen der Arbeit, „nächste Arbeit“', () => {
    const b = bogenV4('batuEigen')
    const spalten = within(b.seite(1)).getAllByTestId('eb-fp-station')
    expect(spalten[1]).toHaveTextContent('nächste Arbeit')
    expect(spalten[2].querySelector('.eb-fp-titel')).toHaveTextContent('Kreise, Prismen und Zylinder · Potenzen und Potenzgesetze')
    const ziffern = [...b.seite(1).querySelectorAll('.eb-fp-nr')].map((n) => n.textContent)
    expect(ziffern).toEqual(['2', '3', '4'])
    expect(b.seite(1).querySelector('[data-testid="eb-fahrplan"] h2')).toHaveTextContent('Ilkays Klassenarbeiten in diesem Schuljahr')
    expect(within(b.seite(1)).getByTestId('eb-fp-quelle')).toHaveTextContent('Zuordnung laut Ihren Angaben.')
    expect(within(bogenV4('batuSchule').seite(1)).getByTestId('eb-fp-quelle')).toHaveTextContent(
      'Zuordnung nach Angaben aus der Klasse, ohne Gewähr.',
    )
  })

  it('der Kasten „Wir beginnen mit …“ entfällt, der Fahrplan steht darunter', () => {
    const b = bogenV4('batuV4')
    const s1 = within(b.seite(1))
    expect(s1.queryByTestId('eb-start')).toBeNull()
    expect(s1.getByTestId('eb-blick').compareDocumentPosition(s1.getByTestId('eb-fahrplan'))).toBe(
      Node.DOCUMENT_POSITION_FOLLOWING,
    )
    expect(s1.getByTestId('eb-fahrplan').querySelector('h2')).toHaveTextContent('Was in Mathe dieses Schuljahr noch kommt')
  })

  for (const fall of MIT_FAHRPLAN) {
    it(`${fall}: keine einzelne Voraussetzung (kein Label aus der Einordnung) auf Seite 1`, () => {
      const b = bogenV4(fall)
      const text = b.seite(1).textContent ?? ''
      const labels = (b.bericht.lueckenwegV4?.themen ?? []).flatMap((k) => [...k.sitzt, ...k.fehlt].map((z) => z.label))
      expect(labels.length, fall).toBeGreaterThan(0)
      for (const l of labels) expect(text, `${fall}: ${l}`).not.toContain(l)
    })

    it(`${fall}: der Satz unter dem Fahrplan richtet sich nach den Signalen`, () => {
      const b = bogenV4(fall)
      const satz = within(b.seite(1)).queryByTestId('eb-fp-satz')
      const art = b.bericht.fahrplan!.satz
      if (art === null) expect(satz).toBeNull()
      else {
        const bekannt = b.bericht.fahrplan!.folge !== 'unbekannt'
        const soll = art === 'fehlt'
          ? (bekannt ? de.v4.s1.satzFehlt : de.v4.s1.satzFehltThema)
          : (bekannt ? de.v4.s1.satzErfuellt : de.v4.s1.satzErfuelltThema)
        expect(satz!.textContent).toBe(soll)
      }
    })
  }

  it('allesErfuellt: der Satz „sitzen die geprüften Voraussetzungen“', () => {
    const b = bogenV4('allesErfuellt')
    expect(within(b.seite(1)).getByTestId('eb-fp-satz').textContent).toBe(de.v4.s1.satzErfuelltThema)
  })

  it('der Sorgfalt-Satz steht im Anliegen-Kasten unter „Was die Analyse dazu zeigt“, nicht mehr bei „Auf einen Blick“', () => {
    const b = bogenV4('batuV4')
    const s1 = within(b.seite(1))
    expect(s1.getByTestId('eb-antwort').textContent).toContain('findet meist den richtigen Weg. Fehler entstehen eher durch fehlende Sorgfalt.')
    expect(s1.getByTestId('eb-luecken-satz').textContent).not.toMatch(/Sorgfalt|Rechenweg/)
  })

  it('kein Sorgfalt-Satz ohne Muster', () => {
    const b = bogenV4('allesErfuellt')
    expect(b.seite(1).textContent).not.toContain('fehlende Sorgfalt')
  })

  it('ohnePlan: wie v3, mit „Wir beginnen mit …“ und ohne Fahrplan', () => {
    const b = bogenV4('ohnePlan')
    expect(within(b.seite(1)).queryByTestId('eb-fahrplan')).toBeNull()
    expect(within(b.seite(1)).getByTestId('eb-start')).toBeInTheDocument()
  })
})
