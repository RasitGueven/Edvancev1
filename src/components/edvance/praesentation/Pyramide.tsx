import { useTranslation } from 'react-i18next'

import { stufenKlasse, stufenUrteil } from '@/components/edvance/elternbericht/berichtSaetze'
import type { EbStufeKey, EbStufenZeile } from '@/types'

/** Oben der aktuelle Stoff, unten die Grundlagen. */
const OBEN_NACH_UNTEN: readonly EbStufeKey[] = ['aktuell', 'weiterfuehrend', 'grundlagen']

/**
 * Die Stufen-Pyramide in Station 01 (V4): dieselben Zeilen und Kurzsätze wie
 * „Auf einen Blick“ auf Seite 1. Weiße Karten; Farbe nur im Kurzsatz und in den
 * Punkten (sicher grün, Übungsbedarf rosé mit reduzierter Deckkraft). Die Breite
 * hängt an der Stelle von unten (data-ebene), nicht an Inline-Styles.
 */
export function Pyramide({ stufen }: { stufen: readonly EbStufenZeile[] }): JSX.Element {
  const { t } = useTranslation('elternbericht')
  const zeilen = OBEN_NACH_UNTEN.flatMap((k) => stufen.filter((z) => z.stufe === k))
  return (
    <ul className="tp-s1v-pyramide tp-reveal" data-testid="tp-s1-pyramide">
      {zeilen.map((z, i) => (
        <li
          key={z.stufe}
          className={`tp-s1v-ebene tp-s1v-ebene-${z.urteil}`}
          data-ebene={zeilen.length - 1 - i}
          data-tp-pflicht=""
          aria-label={t('s1.stufen.aria', { stufe: stufenKlasse(t, z), sicher: z.sicher, uebung: z.uebung })}
        >
          <span className="tp-s1v-ebene-kopf">
            <b>{t(`s1.stufen.name.${z.stufe}`)}</b>
            <small>{stufenKlasse(t, z)}</small>
          </span>
          <span className="tp-s1v-punkte" aria-hidden="true">
            {Array.from({ length: z.sicher }, (_, k) => (
              <i key={`s${k}`} className="tp-s1v-punkt tp-s1v-punkt-sicher" />
            ))}
            {Array.from({ length: z.uebung }, (_, k) => (
              <i key={`u${k}`} className="tp-s1v-punkt tp-s1v-punkt-uebung" />
            ))}
          </span>
          <span className="tp-s1v-urteil">{stufenUrteil(t, z)}</span>
        </li>
      ))}
    </ul>
  )
}
