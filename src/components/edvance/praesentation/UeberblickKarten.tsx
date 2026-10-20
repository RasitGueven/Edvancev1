import { useTranslation } from 'react-i18next'

import type { TpUeberblick } from '@/types'

/**
 * Die zwei Karten „Schon gelungen" und „Gezielt üben" in Station 01
 * (Entscheidung 6). Ab 800 px Breite liegen sie im Bild mit Kreisen und Kugel
 * wie im Dummy, darunter stehen sie ohne Bild unter dem Leitsatz. Beide sind
 * Pflichtteile: Sie fallen nie weg.
 */
export function UeberblickKarten({ ueberblick }: { ueberblick: TpUeberblick }): JSX.Element {
  const { t, i18n } = useTranslation('praesentation')
  const { t: tb } = useTranslation('elternbericht')
  const liste = new Intl.ListFormat(i18n.language, { style: 'long', type: 'conjunction' })
  const felder = (keys: readonly string[]): string => liste.format(keys.map((k) => tb(`feld.${k}`)))

  const { gelungen, ueben, beispielSicher, beispielUebung } = ueberblick
  let textGelungen: string
  if (gelungen.length > 0) textGelungen = felder(gelungen)
  else if (beispielSicher)
    textGelungen = t('s1.sicherEinzeln', { count: beispielSicher.anzahl, bereich: beispielSicher.label })
  else textGelungen = tb('s1.blick.keinSicher')

  let textUeben: string
  if (ueben.length > 0) textUeben = felder(ueben)
  else if (beispielUebung)
    textUeben = t('s1.uebungEinzeln', { count: beispielUebung.anzahl, bereich: beispielUebung.label })
  else textUeben = tb('s1.blick.keineUebung')

  return (
    <div className="tp-s1-bild tp-reveal">
      <div className="tp-s1-kreise" aria-hidden="true">
        <i className="tp-s1-bahn tp-s1-bahn-aussen" />
        <i className="tp-s1-bahn" />
        <i className="tp-s1-kugel" />
      </div>
      <div className="tp-s1-karte tp-s1-karte-gelungen" data-tp-pflicht="" data-testid="tp-s1-gelungen">
        <h3>{t('s1.gelungen')}</h3>
        <p>{textGelungen}</p>
      </div>
      <div className="tp-s1-karte tp-s1-karte-ueben" data-tp-pflicht="" data-testid="tp-s1-ueben">
        <h3>{t('s1.ueben')}</h3>
        <p>{textUeben}</p>
      </div>
    </div>
  )
}
