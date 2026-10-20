import type { CSSProperties } from 'react'
import { useTranslation } from 'react-i18next'

import { anzeigeZahlen } from '@/lib/report/praesentation/praesentation'
import type { TpAnzeige, TpAnzeigeZahlen, TpEbene } from '@/types'

import { useKlassen } from './useKlassen'

/** Lücke zwischen den Segmenten: 4 px bis 16, 2 px bis 30, darüber 1 px (Entscheidung 8). */
export function lueckenKlasse(segmente: number): string {
  if (segmente <= 16) return 'tp-s3-luecke-weit'
  if (segmente <= 30) return 'tp-s3-luecke-mittel'
  return 'tp-s3-luecke-eng'
}

/**
 * Breite je Position von unten: die unterste 100 %, jede darüber 19 Punkte
 * schmaler. Feste Klassen statt Inline-Breite (INV-4.12).
 */
export const breitenKlasse = (vonUnten: number): string => `tp-s3-breite-${Math.min(vonUnten, 3)}`

type Art = 'sicher' | 'uebung' | 'ueber'

/** Je Bereich ein Segment: erst sicher, dann Übungsbedarf, dann übersprungen. */
function segmente(e: TpEbene): Art[] {
  return [
    ...Array<Art>(e.sicher).fill('sicher'),
    ...Array<Art>(e.uebung).fill('uebung'),
    ...Array<Art>(e.uebersprungen).fill('ueber'),
  ]
}

/** Zählung einer Ebene je Zählweise, nur Teile ungleich null. */
function Zaehlung({ z }: { z: TpAnzeigeZahlen }): JSX.Element {
  const { t } = useTranslation('praesentation')
  return (
    <p className="tp-s3-zaehlung">
      {z.sicher > 0 && <span className="tp-s3-z-sicher">{t('zaehlung.sicher', { count: z.sicher })}</span>}
      {z.uebung > 0 && <span className="tp-s3-z-uebung">{t('zaehlung.uebung', { count: z.uebung })}</span>}
      {z.dritte && (
        <span className={z.dritte.art === 'davon' ? 'tp-s3-z-davon' : 'tp-s3-z-ueber'}>
          {t(z.dritte.art === 'davon' ? 'zaehlung.davonUebersprungen' : 'zaehlung.uebersprungen', {
            count: z.dritte.wert,
          })}
        </span>
      )}
    </p>
  )
}

/**
 * Die Pyramide in Station 03 (Entscheidung 8): Ebenen aus p.pyramide von oben
 * nach unten, je Bereich ein Segment, keine Namen. Aufbau beim ersten Besuch
 * von unten nach oben (--reihe zählt von unten).
 */
export function Pyramide({ ebenen, anzeige }: { ebenen: TpEbene[]; anzeige: TpAnzeige }): JSX.Element {
  const { t } = useTranslation('praesentation')
  const { t: tb } = useTranslation('elternbericht')
  const klassen = useKlassen()

  return (
    <ul className={`tp-s3-pyramide tp-s3-${anzeige}`} aria-label={t('s3.pyramideAria')}>
      {ebenen.map((e, i) => {
        const vonUnten = ebenen.length - 1 - i
        const ebeneKey = e.ebene
        const name = tb(`s3.ebene.${ebeneKey}`)
        const angabe = klassen(e.stufen)
        const z = anzeigeZahlen(e, anzeige)
        const aria = z.dritte
          ? t(anzeige === 'kombiniert' ? 's3.ebeneAriaKombiniert' : 's3.ebeneAriaGetrennt', {
              ebene: name,
              klassen: angabe,
              sicher: z.sicher,
              uebung: z.uebung,
              uebersprungen: z.dritte.wert,
            })
          : t('s3.ebeneAria', { ebene: name, klassen: angabe, sicher: z.sicher, uebung: z.uebung })
        const teile = segmente(e)
        return (
          <li
            key={e.ebene}
            className={`tp-s3-ebene ${breitenKlasse(vonUnten)}`}
            style={{ '--reihe': vonUnten } as CSSProperties}
            data-tp-ebene={e.ebene}
          >
            <div className="tp-s3-kopf">
              <h3>{name}</h3>
              <span className="tp-s3-pille">{angabe}</span>
            </div>
            <div className={`tp-s3-spur ${lueckenKlasse(teile.length)}`} role="img" aria-label={aria}>
              {teile.map((art, k) => (
                <i key={k} className={`tp-s3-seg tp-s3-seg-${art}`} style={{ '--k': k } as CSSProperties} />
              ))}
            </div>
            <Zaehlung z={z} />
          </li>
        )
      })}
    </ul>
  )
}
