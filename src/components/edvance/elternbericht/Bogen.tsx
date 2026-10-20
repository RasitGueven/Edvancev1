import { useMemo } from 'react'
import { useTranslation } from 'react-i18next'

import { EmptyState } from '@/components/edvance/EmptyState'
import { Bausteinsatz } from '@/lib/report/bausteine'
import { baueElternbericht } from '@/lib/report/elternbericht/bericht'
import { genitiv } from '@/lib/report/elternbericht/genitiv'
import type { ReportData, ReportNotes, TierPlan } from '@/types'

import { NAME_MAX, NamensMessungFertig, useNamensMessung } from './namensMessung'
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
    () => baueElternbericht({ kompetenzen, katalog, klasse: data.grade, lernweg: { erzaehlung: data.erzaehlung, datum: data.analysedAt } }),
    [kompetenzen, katalog, data.grade],
  )
  const satz = useMemo(() => new Bausteinsatz(bausteine), [bausteine])

  // Rufname: über NAME_MAX Zeichen gar nicht, sonst nur, wenn der Bogen mit ihm
  // passt (namensMessung.ts). Sonst überall die Fassungen ohne Namen.
  const rufname = data.firstName?.trim() || null
  const vorab = rufname && [...rufname].length <= NAME_MAX ? rufname : null
  const messung = useNamensMessung(vorab !== null)

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

  const name = messung.nameBleibt ? vorab : null
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
    <div className="eb-bogen" ref={messung.ref} data-ohne-name={(vorab && !name) || undefined}>
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
      <NamensMessungFertig.Provider value={messung.fertig}>
        {SEITEN.map((Inhalt, i) => (
          <Seite key={i + 1} nummer={i + 1} testlauf={data.testlauf} name={name}>
            <Inhalt {...props} />
          </Seite>
        ))}
      </NamensMessungFertig.Provider>
    </div>
  )
}
