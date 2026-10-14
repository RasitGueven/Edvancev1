import { describe, expect, it } from 'vitest'
import { DOKUMENTE, fillDokument } from './index'

describe('fillDokument', () => {
  it('setzt Werte ein und markiert Luecken mit —', () => {
    expect(fillDokument('{{a}} / {{b}} / {{c}}', { a: 'eins', b: ' ' })).toBe('eins / — / —')
  })
})

describe('Dokumentregister', () => {
  it('kennt alle sieben Dokumente aus vertrag_dokumente', () => {
    expect(Object.keys(DOKUMENTE).sort()).toEqual([
      'agb',
      'datenschutz_vertrag',
      'einwilligung_fotos',
      'pilotvereinbarung',
      'sepa_mandat',
      'vertrag',
      'widerruf',
    ])
  })

  it('setzt im Vertrag und im SEPA-Mandat die Formulardaten ein', () => {
    expect(DOKUMENTE.vertrag.text).toContain('{{kind_name}}')
    expect(DOKUMENTE.sepa_mandat.text).toContain('{{iban}}')
    expect(DOKUMENTE.sepa_mandat.text).toContain('{{mandatsreferenz}}')
  })

  it('Pilotvereinbarung: Platzhalter-Hinweis, Zeitraum, Einheiten, ohne Preis, SEPA und Widerruf', () => {
    const text = DOKUMENTE.pilotvereinbarung.text
    expect(text).toContain('PLATZHALTER — NOCH KEIN RECHTSTEXT')
    for (const platzhalter of ['{{kind_name}}', '{{vertragsbeginn}}', '{{vertragsende}}', '{{einheiten}}']) {
      expect(text).toContain(platzhalter)
    }
    expect(text).toContain('ohne Entgelt')
    expect(text).toContain('10 Uhr')
    for (const fehlt of ['{{preis}}', '{{beitraege}}', '{{gesamtpreis}}', '{{iban}}', 'SEPA', 'Widerruf']) {
      expect(text).not.toContain(fehlt)
    }
  })

  it('haelt die Vertrags-Datenschutzhinweise getrennt von der LSA-Einwilligung', () => {
    expect(DOKUMENTE.datenschutz_vertrag.text).toContain('Datenschutzhinweise zum Vertrag')
  })
})
