// Testhilfe: der Eltern-Bericht mit Fahrplan (Bauauftrag V4, V4-2).
import { render } from '@testing-library/react'

import { ElternberichtBogen } from '@/components/edvance/elternbericht/Bogen'
import { baueElternbericht } from '@/lib/report/elternbericht/bericht'
import type { EinordnungLayout } from '@/lib/report/elternbericht/berichtKonfig'
import { FAELLE, NOTIZEN_ZIELE } from '@/lib/report/elternbericht/fixtures'
import type { Elternbericht, ReportData, ReportNotes, TierPlan } from '@/types'

/** Die Fälle aus V4-1 mit Fahrplan. */
export const MIT_FAHRPLAN = [
  'batuV4',
  'batuBevorstehend',
  'batuOhneStatus',
  'batuMitNote',
  'fahrplanKlp',
  'fahrplanHalbjahr',
  'fahrplanLang',
  'fahrplanAuffuellen',
  'allesErfuellt',
] as const

/** Ziele im Gespräch bestätigt, ohne Zielbild des Coachs. */
export { NOTIZEN_ZIELE }

/** Der Bericht, wie ihn der Bogen rechnet. */
export function berichtV4(data: ReportData): Elternbericht {
  return baueElternbericht({
    kompetenzen: data.erzaehlung.kompetenzen,
    katalog: data.erzaehlung.katalog,
    klasse: data.grade,
    lernweg: { erzaehlung: data.erzaehlung, datum: data.analysedAt },
    klassenarbeit: data.erstgespraech?.klassenarbeit ?? null,
    note: data.erstgespraech?.letzteNote ?? null,
  })!
}

export function bogenV4(
  name: string,
  opt: {
    notes?: ReportNotes | null
    tiers?: TierPlan[]
    preise?: boolean
    einordnung?: EinordnungLayout
    /** Andere Daten als die des Falls (z. B. ohne Rufnamen). */
    data?: ReportData
  } = {},
) {
  const fall = FAELLE[name]
  const data = opt.data ?? fall.data
  const r = render(
    <ElternberichtBogen
      data={data}
      notes={opt.notes === undefined ? fall.notes : opt.notes}
      tiers={opt.tiers ?? fall.tiers}
      preise={opt.preise}
      einordnung={opt.einordnung}
    />,
  )
  return {
    ...r,
    data,
    bericht: berichtV4(data),
    seite: (n: number) => r.container.querySelector<HTMLElement>(`.eb-seite[data-seite="${n}"]`)!,
  }
}
