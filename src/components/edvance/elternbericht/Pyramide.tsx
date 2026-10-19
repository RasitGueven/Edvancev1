import type { TFunction } from 'i18next'
import { useTranslation } from 'react-i18next'

import { klassenAngabe } from '@/lib/report/elternbericht/einordnung'
import type { EbEbene, EbGruppe, Stufe } from '@/types'

/** Höchstens so viele Themenfelder nebeneinander, dann eine neue Reihe. */
export const GRUPPEN_JE_REIHE = 4
/** Höchstens so viele Einträge je Gruppe; der Rest steht als „+n weitere“. */
export const EINTRAEGE_JE_GRUPPE = 6

/** „Klasse 7/8“ bzw. „Klasse 7–10“ aus den Stufen einer Ebene. */
export function klassenText(t: TFunction<'elternbericht'>, stufen: readonly Stufe[]): string | null {
  const angabe = klassenAngabe(stufen)
  if (!angabe) return null
  return 'stufe' in angabe ? t(`stufe.${angabe.stufe}`) : t('stufe.spanne', angabe)
}

/**
 * Die Pyramide auf Seite 3 (Maßblatt E7, „Seite 3“): je Ebene ein Kasten, von
 * oben nach unten, nur die vorhandenen. Die unterste ist 507 pt breit, jede
 * darüber 56 pt schmaler — als feste Klasse je Position von unten
 * (`eb-s3-ebene-p0` … `p3`), nie als Inline-Breite.
 */
export function Pyramide({ ebenen }: { ebenen: EbEbene[] }): JSX.Element {
  return (
    <div className="eb-s3-pyramide" data-testid="eb-pyramide">
      {ebenen.map((e, i) => (
        <Ebene key={e.ebene} ebene={e} position={ebenen.length - 1 - i} />
      ))}
    </div>
  )
}

function Ebene({ ebene, position }: { ebene: EbEbene; position: number }): JSX.Element {
  const { t } = useTranslation('elternbericht')
  const klassen = klassenText(t, ebene.stufen)
  const zaehlung = [
    ...(ebene.sicher > 0 ? [t('s3.zaehlung.sicher', { count: ebene.sicher })] : []),
    ...(ebene.uebung > 0 ? [t('s3.zaehlung.uebung', { count: ebene.uebung })] : []),
  ].join(' · ')

  const reihen: EbGruppe[][] = []
  for (let i = 0; i < ebene.gruppen.length; i += GRUPPEN_JE_REIHE) {
    reihen.push(ebene.gruppen.slice(i, i + GRUPPEN_JE_REIHE))
  }

  return (
    <section
      className={`eb-s3-ebene eb-s3-ebene-p${position}`}
      data-ebene={ebene.ebene}
      data-testid="eb-ebene"
    >
      <h3 className="eb-s3-ebene-kopf">
        <span className="eb-s3-ebene-name">{t(`s3.ebene.${ebene.ebene}`)}</span>
        {klassen && <span className="eb-s3-ebene-klassen">{klassen}</span>}
        <span className="eb-s3-ebene-zaehlung">{zaehlung}</span>
      </h3>
      {reihen.map((reihe, r) => (
        <div key={r} className="eb-s3-reihe" data-testid="eb-reihe">
          {reihe.map((g) => (
            <Gruppe key={g.feld} gruppe={g} />
          ))}
        </div>
      ))}
    </section>
  )
}

function Gruppe({ gruppe }: { gruppe: EbGruppe }): JSX.Element {
  const { t } = useTranslation('elternbericht')
  const rest = gruppe.eintraege.length - EINTRAEGE_JE_GRUPPE

  return (
    <div className="eb-s3-gruppe" data-testid="eb-gruppe">
      <h4 className="eb-s3-gruppe-name">{t(`feld.${gruppe.feld}`)}</h4>
      <ul className="eb-s3-eintraege">
        {gruppe.eintraege.slice(0, EINTRAEGE_JE_GRUPPE).map((b) => {
          const zustand = b.sicher ? 'sicher' : 'uebung'
          return (
            <li
              key={b.skillKey}
              className={`eb-s3-eintrag eb-s3-eintrag-${zustand}`}
              aria-label={t('s3.eintragAria', { label: b.label, zustand: t(`zustand.${zustand}`) })}
            >
              {b.label}
            </li>
          )
        })}
        {rest > 0 && <li className="eb-s3-weitere">{t('s3.weitere', { count: rest })}</li>}
      </ul>
    </div>
  )
}
