import { describe, expect, it } from 'vitest'
import { CC_BY_40_URL, buildAttribution } from './attribution'
import type { GroundingRecord } from '@/types'

const vera = { source: 'VERA8_IQB' }

const record = (over: Partial<GroundingRecord> = {}): GroundingRecord => ({
  id: 'r1',
  titel: '20 Prozent',
  quelle: 'VERA8_IQB',
  iqb_urls: {
    aufgabe: 'https://www.iqb.hu-berlin.de/media/exercise_files/VERA-8_Mathematik/20prozent_Aufgabe.docx',
  },
  ...over,
})

describe('buildAttribution', () => {
  it('baut die volle TASL-Form aus Titel, Fach und URL', () => {
    const text = buildAttribution(vera, record())
    expect(text).toContain('„20 Prozent“')
    expect(text).toContain('Institut zur Qualitätsentwicklung im Bildungswesen (IQB)')
    expect(text).toContain('VERA-8 Mathematik')
    expect(text).toContain('20prozent_Aufgabe.docx')
    expect(text).toContain(`CC BY 4.0 (${CC_BY_40_URL})`)
  })

  it('faellt ohne Beleg auf die rechtssichere Mindestform zurueck', () => {
    const text = buildAttribution(vera, null)
    expect(text).not.toContain('„')
    expect(text).toContain('VERA-8.')
    expect(text).toContain('IQB')
    expect(text).toContain('CC BY 4.0')
  })

  it('laesst das Fach weg, wenn die URL es nicht hergibt', () => {
    const text = buildAttribution(vera, record({ titel: undefined, iqb_urls: undefined }))
    expect(text).toContain('VERA-8.')
    expect(text).not.toContain('VERA-8 ')
  })

  it('gibt null zurueck, wenn die Quelle keinen bekannten Rechteinhaber hat', () => {
    expect(buildAttribution({ source: 'eigenbau' }, null)).toBeNull()
  })
})
