// Bericht v4, V4-2: Ohne Fahrplan (fahrplan === null) sieht jede Seite aus wie in v3.
//
// Die Snapshots sind vor den Änderungen von V4-2 aus dem v3-Stand erzeugt (ein
// Hash je Seite und Fall; ohnePlan zusätzlich mit dem vollen HTML von Seite 1–5).
// Ein Unterschied hier heißt: Ein Fall ohne Fahrplan sieht anders aus als in v3.
import { createHash } from 'node:crypto'

import { render } from '@testing-library/react'
import { describe, expect, it } from 'vitest'
import '@/i18n'

import { ElternberichtBogen } from '@/components/edvance/elternbericht/Bogen'
import { baueElternbericht } from '@/lib/report/elternbericht/bericht'
import { FAELLE } from '@/lib/report/elternbericht/fixtures'

const ohneFahrplan = Object.entries(FAELLE).filter(([, f]) => {
  const d = f.data
  const b = baueElternbericht({
    kompetenzen: d.erzaehlung.kompetenzen,
    katalog: d.erzaehlung.katalog,
    klasse: d.grade,
    lernweg: { erzaehlung: d.erzaehlung, datum: d.analysedAt },
    klassenarbeit: d.erstgespraech?.klassenarbeit ?? null,
    note: d.erstgespraech?.letzteNote ?? null,
  })
  return b !== null && (b.fahrplan ?? null) === null
})

const seiten = (name: string, layout: 'A' | 'B'): string[] => {
  const f = FAELLE[name]
  const { container, unmount } = render(
    <ElternberichtBogen data={f.data} notes={f.notes} tiers={f.tiers} einordnung={layout} />,
  )
  const html = [...container.querySelectorAll('.eb-seite')].map((s) => s.innerHTML)
  unmount()
  return html
}

const hash = (s: string): string => createHash('sha1').update(s).digest('hex').slice(0, 12)

describe('ohne Fahrplan wie v3', () => {
  it('die Fälle ohne Fahrplan (ohnePlan ist dabei)', () => {
    expect(ohneFahrplan.map(([n]) => n)).toContain('ohnePlan')
    expect(ohneFahrplan.map(([n]) => n)).toMatchSnapshot()
  })

  it('ohnePlan: das volle HTML aller fünf Seiten', () => {
    expect(seiten('ohnePlan', 'B')).toMatchSnapshot()
  })

  for (const [name] of ohneFahrplan) {
    for (const layout of ['A', 'B'] as const) {
      it(`${name} (Layout ${layout}): Hash je Seite`, () => {
        expect(seiten(name, layout).map(hash)).toMatchSnapshot()
      })
    }
  }
})
