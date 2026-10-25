// Testhilfe: der Eltern-Bericht ohne Fahrplan (Bauauftrag V4, V4-2: „ohne Fahrplan
// wie v3“). Die Tests der v3-Seiten prüfen den v3-Pfad auch mit Fällen, die einen
// Schulplan haben und im Bogen deshalb den Fahrplan zeigen würden.
import { render } from '@testing-library/react'

import { Seite } from '@/components/edvance/elternbericht/Seite'
import { Seite1 } from '@/components/edvance/elternbericht/Seite1'
import { Seite2 } from '@/components/edvance/elternbericht/Seite2'
import { Seite3 } from '@/components/edvance/elternbericht/Seite3'
import { Seite4 } from '@/components/edvance/elternbericht/Seite4'
import { Seite5 } from '@/components/edvance/elternbericht/Seite5'
import type { SeitenProps } from '@/components/edvance/elternbericht/seitenProps'
import { Bausteinsatz } from '@/lib/report/bausteine'
import { baueElternbericht } from '@/lib/report/elternbericht/bericht'
import type { EinordnungLayout } from '@/lib/report/elternbericht/berichtKonfig'
import { genitiv } from '@/lib/report/elternbericht/genitiv'
import type { Elternbericht, ReportData, ReportNotes, TierPlan } from '@/types'

const SEITEN = [Seite1, Seite2, Seite3, Seite4, Seite5]

/** Der Bericht wie im Bogen, aber ohne die Felder von v4. */
export function berichtOhneFahrplan(data: ReportData): Elternbericht {
  const b = baueElternbericht({
    kompetenzen: data.erzaehlung.kompetenzen,
    katalog: data.erzaehlung.katalog,
    klasse: data.grade,
    lernweg: { erzaehlung: data.erzaehlung, datum: data.analysedAt },
    klassenarbeit: data.erstgespraech?.klassenarbeit ?? null,
    note: data.erstgespraech?.letzteNote ?? null,
  })!
  return { ...b, fahrplan: null, signale: [], lueckenwegV4: null, lernpfad: [] }
}

/** Alle fünf Seiten im v3-Rahmen; `seite(n)` liefert wie sonst `.eb-seite[data-seite=n]`. */
export function renderOhneFahrplan(
  data: ReportData,
  { notes = null, tiers = [], einordnung }: { notes?: ReportNotes | null; tiers?: TierPlan[]; einordnung?: EinordnungLayout } = {},
) {
  const rufname = data.firstName?.trim() || null
  const name = rufname ? rufname.split(/\s+/)[0] : null
  const props: SeitenProps = {
    data,
    bericht: berichtOhneFahrplan(data),
    satz: new Bausteinsatz(data.erzaehlung.bausteine),
    notes,
    tiers,
    name,
    vollerName: rufname,
    wessen: name ? genitiv(name) : null,
    einordnung,
  }
  const r = render(
    <div className="eb-bogen">
      {SEITEN.map((Inhalt, i) => (
        <Seite key={i + 1} nummer={i + 1} testlauf={data.testlauf} name={rufname}>
          <Inhalt {...props} />
        </Seite>
      ))}
    </div>,
  )
  return { ...r, seite: (n: number) => r.container.querySelector<HTMLElement>(`.eb-seite[data-seite="${n}"]`)! }
}
