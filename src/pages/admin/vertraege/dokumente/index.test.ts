import { describe, expect, it } from 'vitest'
import { DOKUMENTE, fillDokument } from './index'

describe('fillDokument', () => {
  it('setzt Werte ein und markiert Luecken mit —', () => {
    expect(fillDokument('{{a}} / {{b}} / {{c}}', { a: 'eins', b: ' ' })).toBe('eins / — / —')
  })
})

describe('Dokumentregister', () => {
  it('kennt alle sechs Dokumente aus vertrag_dokumente', () => {
    expect(Object.keys(DOKUMENTE).sort()).toEqual([
      'agb',
      'datenschutz_vertrag',
      'einwilligung_fotos',
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

  it('haelt die Vertrags-Datenschutzhinweise getrennt von der LSA-Einwilligung', () => {
    expect(DOKUMENTE.datenschutz_vertrag.text).toContain('Datenschutzhinweise zum Vertrag')
  })
})
