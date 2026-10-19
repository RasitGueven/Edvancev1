import { useMemo } from 'react'
import { useTranslation } from 'react-i18next'

import { EmptyState } from '@/components/edvance/EmptyState'
import { Bausteinsatz } from '@/lib/report/bausteine'
import { baueElternbericht } from '@/lib/report/elternbericht/bericht'
import { genitiv } from '@/lib/report/elternbericht/genitiv'
import type { ReportData, ReportNotes, TierPlan } from '@/types'

import { Seite } from './Seite'
import { Seite1 } from './Seite1'
import { Seite2 } from './Seite2'
import { Seite3 } from './Seite3'
import { Seite4 } from './Seite4'
import { Seite5 } from './Seite5'
import { SCHRAFFUR_ID, type SeitenProps } from './seitenProps'

const SEITEN: ReadonlyArray<(props: SeitenProps) => JSX.Element | null> = [
  Seite1,
  Seite2,
  Seite3,
  Seite4,
  Seite5,
]

/**
 * Der Eltern-Bericht R7 als Druckbogen: fünf A4-Seiten nach Muster E7.
 *
 * Gerechnet wird hier einmal und an alle Seiten gereicht. Liefert die Rechnung
 * nichts (kein direkt geprüfter Bereich, kein Katalog), gibt es keinen Bogen,
 * sondern einen Hinweis am Bildschirm: Eine falsche Zahl auf Papier für Eltern
 * wäre schlimmer als kein Bogen (Bauauftrag R7, Entscheidung 3).
 */
export function ElternberichtBogen({
  data,
  notes,
  tiers,
}: {
  data: ReportData
  notes: ReportNotes | null
  tiers: TierPlan[]
}): JSX.Element {
  const { t } = useTranslation('elternbericht')
  const { kompetenzen, katalog, bausteine } = data.erzaehlung

  const bericht = useMemo(
    () => baueElternbericht({ kompetenzen, katalog, klasse: data.grade }),
    [kompetenzen, katalog, data.grade],
  )
  const satz = useMemo(() => new Bausteinsatz(bausteine), [bausteine])

  if (!bericht) {
    return (
      <div className="print-hide" data-testid="eb-leer">
        <EmptyState
          icon="📄"
          title={t('fassung.zuR7')}
          description={t(kompetenzen.length === 0 ? 'fassung.leer' : 'fassung.keinKatalog')}
        />
      </div>
    )
  }

  const name = data.firstName?.trim() || null
  const props: SeitenProps = {
    data,
    bericht,
    satz,
    notes,
    tiers,
    name,
    wessen: name ? genitiv(name) : null,
  }

  return (
    <div className="eb-bogen">
      {/* Schraffur für „nicht untersucht“ (Seite 2): einmal definiert, nicht
          sichtbar. Nicht display:none — sonst findet url(#…) das Pattern nicht. */}
      <svg className="eb-defs" aria-hidden="true" focusable="false">
        <defs>
          <pattern
            id={SCHRAFFUR_ID}
            patternUnits="userSpaceOnUse"
            width="7"
            height="7"
            patternTransform="rotate(45)"
          >
            <line className="eb-schraffur-linie" x1="0" y1="0" x2="0" y2="7" />
          </pattern>
        </defs>
      </svg>
      {SEITEN.map((Inhalt, i) => (
        <Seite key={i + 1} nummer={i + 1} testlauf={data.testlauf} name={name}>
          <Inhalt {...props} />
        </Seite>
      ))}
    </div>
  )
}
