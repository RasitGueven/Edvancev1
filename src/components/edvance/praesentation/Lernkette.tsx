import { useState, type CSSProperties } from 'react'
import { useTranslation } from 'react-i18next'

import type { TpGlied, TpKette } from '@/types'

import type { Info } from './lernwegInfo'

/** Der Name im Kasten: Bereich oder Thema als Label, das Themenfeld über i18n. */
function useName(): (g: TpGlied) => string {
  const { t: tb } = useTranslation('elternbericht')
  return (g) => {
    if (g.art !== 'feld') return g.label
    const feldKey = g.feld
    return tb(`feld.${feldKey}`)
  }
}

/**
 * Der Satz unter der Kette beim Antippen (PS-1, Entscheidung 13): aus den
 * Infotexten des Lernwegs (s3.weg.info.*), eigene Sätze nur, wo keiner passt.
 */
function useInfo(k: TpKette): (i: number) => Info {
  const { t } = useTranslation('praesentation')
  const { t: tb } = useTranslation('elternbericht')
  const name = useName()
  const glieder = k.glieder
  const nach = (art: TpGlied['art']): TpGlied | undefined => glieder.find((g) => g.art === art)
  const eintrag = (label: string, stand: 'sicher' | 'uebung'): string =>
    t('s3.weg.info.eintrag', { label, stand: tb(`s3.weg.stand.${stand}`) })

  return (i) => {
    const g = glieder[i]
    const start = nach('start')
    const basis = nach('basis')
    const naechster = nach('naechster')
    switch (g.art) {
      case 'basis':
        return {
          titel: eintrag(g.label, 'sicher'),
          text: g.kante && start ? t('s3.weg.info.ziele', { liste: name(start) }) : '',
        }
      case 'start': {
        const saetze: string[] = []
        if (basis && 'kante' in basis && basis.kante) saetze.push(t('s3.weg.info.basis', { basis: name(basis) }))
        if (naechster) saetze.push(t('s3.weg.info.ziele', { liste: name(naechster) }))
        return { titel: eintrag(g.label, 'uebung'), text: saetze.join(' ') || t('s3.kette.info.start') }
      }
      case 'naechster':
        return {
          titel: eintrag(g.label, 'uebung'),
          text: start ? t('s3.kette.info.naechster', { start: name(start) }) : '',
        }
      case 'kommt':
        return { titel: t('s3.weg.info.naechstes', { titel: g.label }), text: '' }
      default:
        return { titel: name(g), text: t(`s3.kette.info.${g.art}`) }
    }
  }
}

/**
 * Station 03 · die Kette (PS-1, Entscheidungen 10, 12 und 13): höchstens fünf
 * Kästen links nach rechts mit Etikett und Bereichsnamen, dazwischen eine
 * goldene Linie. Die Kästen erscheinen nacheinander, danach wächst die Linie
 * in einem Zug (station3-kette.css). Antippen eines Kastens zeigt darunter
 * einen Satz; vorher steht dort der eine Hinweis aufs Antippen.
 * `still`: ohne Aufbau (zurück von der vollen Karte).
 */
export function Lernkette({ k, titelId, still }: { k: TpKette; titelId: string; still: boolean }): JSX.Element {
  const { t } = useTranslation('praesentation')
  const name = useName()
  const info = useInfo(k)
  const [gewaehlt, setGewaehlt] = useState<number | null>(null)
  const aktiv = gewaehlt === null ? null : info(gewaehlt)

  return (
    <div
      className={still ? 'tp-s3-kette tp-s3-kette-still' : 'tp-s3-kette'}
      data-testid="tp-s3-kette"
      data-fall={k.fall}
      style={{ '--glieder': k.glieder.length } as CSSProperties}
    >
      <ol className="tp-s3-kette-reihe" aria-labelledby={titelId}>
        <i className="tp-s3-kette-linie" aria-hidden="true" />
        {k.glieder.map((g, i) => (
          <li key={`${g.art}-${i}`} className="tp-s3-kette-platz" style={{ '--glied': i } as CSSProperties}>
            <button
              type="button"
              className={`tp-s3-glied tp-s3-glied-${g.art}`}
              data-testid="tp-s3-glied"
              data-art={g.art}
              aria-pressed={gewaehlt === i}
              onClick={() => setGewaehlt((v) => (v === i ? null : i))}
            >
              <span className="tp-etikett">{t(`s3.kette.etikett.${g.art}`)}</span>
              <span className="tp-s3-glied-name">{name(g)}</span>
            </button>
          </li>
        ))}
      </ol>
      <p className="tp-s3-kette-info" data-testid="tp-s3-kette-info" aria-live="polite">
        {aktiv ? (
          <>
            {aktiv.titel && <b>{aktiv.titel}</b>} {aktiv.text}
          </>
        ) : (
          <span className="tp-s3-kette-hinweis">{t('s3.weg.info.leer')}</span>
        )}
      </p>
    </div>
  )
}
