// V4-S (docs/report/v4/Bauauftrag-V4-S.md, Entscheidung 1): Die anstehende Arbeit zeigt nur bei 'bevorstehend',
// was dafür sitzt und was fehlt. Bei 'geschrieben' und ohne Stand bleibt der Bericht genau wie vorher: Die
// Snapshots entstanden vor der Änderung und dürfen sich nicht bewegen.

import { describe, expect, it } from 'vitest'

import { batuMitNote, batuOhneStatus, batuV4 } from '@/lib/report/elternbericht/fixtures/batuV4'
import { berichtVon } from '@/lib/report/elternbericht/fixtures/berichtV4Hilfe'

describe('V4-S: unverändert ohne anstehende Arbeit', () => {
  it('Batu, geschrieben', () => {
    expect(berichtVon(batuV4)).toMatchSnapshot()
  })

  it('Batu, geschrieben mit Note', () => {
    expect(berichtVon(batuMitNote)).toMatchSnapshot()
  })

  it('Batu, ohne Stand (null)', () => {
    expect(berichtVon(batuOhneStatus)).toMatchSnapshot()
  })
})
