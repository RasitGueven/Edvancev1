import { useTranslation } from 'react-i18next'

import type { TpUeberblick } from '@/types'

/** Höchstens zwei Einträge je Karte, dann „+n weitere" (PS-1, Entscheidung 6). */
const JE_KARTE = 2

function Eintraege({ zeilen, ersatz }: { zeilen: string[]; ersatz: string }): JSX.Element {
  const { t: tb } = useTranslation('elternbericht')
  if (zeilen.length === 0) return <p>{ersatz}</p>
  const rest = zeilen.length - JE_KARTE
  return (
    <ul>
      {zeilen.slice(0, JE_KARTE).map((z) => (
        <li key={z}>{z}</li>
      ))}
      {rest > 0 && <li className="tp-s1-weitere">{tb('s1.blick.weitere', { count: rest })}</li>}
    </ul>
  )
}

/**
 * Die zwei Karten „Schon gelungen" und „Gezielt üben" in Station 01
 * (Entscheidung 6, PS-1 Entscheidung 6): je Karte höchstens zwei kurze Zeilen
 * untereinander, dann „+n weitere". Mit Thema-Schwerpunkt steht die
 * Startstelle in „Gezielt üben" zuerst. Ohne Feld die Ersatztexte wie bisher.
 * Ab 800 px Breite liegen die Karten im Bild mit Kreisen und Kugel, darunter
 * stehen sie ohne Bild. Beide sind Pflichtteile: Sie fallen nie weg.
 */
export function UeberblickKarten({ ueberblick, start }: { ueberblick: TpUeberblick; start: string | null }): JSX.Element {
  const { t } = useTranslation('praesentation')
  const { t: tb } = useTranslation('elternbericht')
  const feld = (k: string): string => tb(`feld.${k}`)

  const { gelungen, ueben, beispielSicher, beispielUebung } = ueberblick
  const ersatzGelungen = beispielSicher
    ? t('s1.sicherEinzeln', { count: beispielSicher.anzahl, bereich: beispielSicher.label })
    : tb('s1.blick.keinSicher')
  const ersatzUeben = beispielUebung
    ? t('s1.uebungEinzeln', { count: beispielUebung.anzahl, bereich: beispielUebung.label })
    : tb('s1.blick.keineUebung')
  const zeilenUeben = ueben.length > 0 && start ? [start, ...ueben.map(feld)] : ueben.map(feld)

  return (
    <div className="tp-s1-bild tp-reveal">
      <div className="tp-s1-kreise" aria-hidden="true">
        <i className="tp-s1-bahn tp-s1-bahn-aussen" />
        <i className="tp-s1-bahn" />
        <i className="tp-s1-kugel" />
      </div>
      <div className="tp-s1-karte tp-s1-karte-gelungen" data-tp-pflicht="" data-testid="tp-s1-gelungen">
        <h3>{t('s1.gelungen')}</h3>
        <Eintraege zeilen={gelungen.map(feld)} ersatz={ersatzGelungen} />
      </div>
      <div className="tp-s1-karte tp-s1-karte-ueben" data-tp-pflicht="" data-testid="tp-s1-ueben">
        <h3>{t('s1.ueben')}</h3>
        <Eintraege zeilen={zeilenUeben} ersatz={ersatzUeben} />
      </div>
    </div>
  )
}
