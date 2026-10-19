import { useTranslation } from 'react-i18next'

import type { EbEbene } from '@/types'

import { klassenText } from './Pyramide'

/** Breiten der Balken der Mini-Pyramide von unten nach oben (pt). */
const BALKEN = [16, 12.2, 8.4, 4.6] as const
const BALKEN_HOEHE = 2.9
const BALKEN_ABSTAND = 3.9
const MINI_BREITE = 16

/**
 * „So lesen Sie die Pyramide“ (Maßblatt E7, „Seite 3“): je vorhandener Ebene
 * eine Zeile mit Mini-Pyramide, dann für wen sie gilt und der Hinweis.
 */
export function Lesehilfe({
  ebenen,
  name,
  wessen,
}: {
  ebenen: EbEbene[]
  name: string | null
  wessen: string | null
}): JSX.Element {
  const { t } = useTranslation('elternbericht')

  return (
    <section className="eb-s3-lesen" data-testid="eb-lesehilfe">
      <h2 className="eb-kicker eb-s3-lesen-kicker">{t('s3.lesen.kicker')}</h2>
      <div className="eb-s3-lesen-spalte">
        <ul className="eb-s3-lesen-zeilen">
          {ebenen.map((e, i) => (
            <li key={e.ebene} className="eb-s3-lesen-zeile">
              <Mini anzahl={ebenen.length} eigene={i} />
              <p className="eb-s3-lesen-text">
                <span className="eb-s3-lesen-ebene">
                  {t('s3.lesen.ebene', { ebene: t(`s3.ebene.${e.ebene}`) })}
                </span>{' '}
                <ZeilenText ebene={e} />
              </p>
            </li>
          ))}
        </ul>
        <p className="eb-s3-lesen-nur">
          {name && wessen ? t('s3.lesen.nurFuer', { name, wessen }) : t('s3.lesen.nurFuerOhneName')}
        </p>
        <p className="eb-s3-lesen-hinweis">
          {t(ebenen.length === 1 ? 's3.lesen.hinweisEineEbene' : 's3.lesen.hinweis')}
        </p>
      </div>
    </section>
  )
}

function ZeilenText({ ebene }: { ebene: EbEbene }): JSX.Element {
  const { t, i18n } = useTranslation('elternbericht')

  if (ebene.ebene === 'spaeter' || ebene.ebene === 'aktuell') {
    return <>{t(`s3.lesen.${ebene.ebene}`, { klassen: klassenText(t, ebene.stufen) ?? '' })}</>
  }
  const felder = ebene.gruppen.slice(0, 2).map((g) => t(`feld.${g.feld}`))
  if (felder.length === 0) return <>{t(`s3.lesen.${ebene.ebene}OhneBeispiel`)}</>
  const beispiele = new Intl.ListFormat(i18n.language, { style: 'long', type: 'disjunction' }).format(
    felder,
  )
  return <>{t(`s3.lesen.${ebene.ebene}`, { beispiele })}</>
}

/** So viele Balken wie Ebenen, der eigene navy; oben der schmalste. */
function Mini({ anzahl, eigene }: { anzahl: number; eigene: number }): JSX.Element {
  const hoehe = (anzahl - 1) * BALKEN_ABSTAND + BALKEN_HOEHE
  return (
    <svg
      className="eb-s3-mini"
      viewBox={`0 0 ${MINI_BREITE} ${hoehe}`}
      aria-hidden="true"
      focusable="false"
      data-testid="eb-mini"
    >
      {Array.from({ length: anzahl }, (_, i) => {
        const breite = BALKEN[anzahl - 1 - i]
        return (
          <rect
            key={i}
            className={i === eigene ? 'eb-s3-balken eb-s3-balken-eigen' : 'eb-s3-balken'}
            x={(MINI_BREITE - breite) / 2}
            y={i * BALKEN_ABSTAND}
            width={breite}
            height={BALKEN_HOEHE}
            rx="0.9"
          />
        )
      })}
    </svg>
  )
}
