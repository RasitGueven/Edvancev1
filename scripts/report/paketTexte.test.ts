import { describe, expect, it } from 'vitest'

import { FAZIT, WARUM } from './paketTexte'

/**
 * Die Paket-Prosa darf die Session-Frequenz nicht wiederholen.
 *
 * Anlass: Bis zur Preiskorrektur vom 18.08. stand die Frequenz an zwei Stellen
 * im selben Kasten — als `.freq` aus tiers.features[0] und als Prosa daneben
 * („Zwei Termine pro Woche reichen…"). Als die echten Frequenzen in tiers
 * landeten, widersprach das Dokument sich selbst: eine Zeile nannte einen
 * Termin, die Zeile darunter zwei.
 *
 * Eine Zahl, die an zwei Orten lebt, driftet wieder. Der Test hält deshalb den
 * einen Ort fest, statt sich auf Sorgfalt zu verlassen.
 */
describe('Paket-Prosa nennt keine Terminzahl', () => {
  const ALLE = [...Object.entries(FAZIT), ...Object.entries(WARUM)]

  it('deckt alle drei Pakete in beiden Textsorten ab', () => {
    expect(Object.keys(FAZIT).sort()).toEqual(['Basic', 'Premium', 'Standard'])
    expect(Object.keys(WARUM).sort()).toEqual(['Basic', 'Premium', 'Standard'])
  })

  it('enthält überhaupt keine Ziffer', () => {
    for (const [paket, text] of ALLE) {
      expect(text, `${paket}: ${text}`).not.toMatch(/\d/)
    }
  })

  it('nennt keinen Takt — der steht in der freq-Zeile aus tiers', () => {
    for (const [paket, text] of ALLE) {
      expect(text, `${paket}: ${text}`).not.toMatch(
        /pro Woche|\/Woche|wöchentlich|pro Monat|je Woche/i,
      )
    }
  })

  it('zählt keine Termine oder Sessions aus', () => {
    // Zahlwort unmittelbar vor Termin/Session — genau die Form, die gedriftet
    // ist („Zwei Termine", „Drei Termine").
    const ZAHLWORT =
      /\b(ein|eine|einen|zwei|drei|vier|fünf|sechs|sieben|acht|neun|zehn)\s+(Termin|Termine|Sitzung|Sitzungen|Session|Sessions)\b/i
    for (const [paket, text] of ALLE) {
      expect(text, `${paket}: ${text}`).not.toMatch(ZAHLWORT)
    }
  })

  it('bleibt Elternsprache — siezt und verspricht nichts', () => {
    const DUZEN = /\b(du|dich|dir|dein|deine|deiner|deinem|deinen|deines)\b/i
    for (const [paket, text] of ALLE) {
      expect(text, `${paket}: ${text}`).not.toMatch(DUZEN)
      expect(text, `${paket}: ${text}`).not.toMatch(/garantier|wird .*schaffen/i)
    }
  })
})
