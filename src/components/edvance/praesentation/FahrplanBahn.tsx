import { Fragment, type CSSProperties } from 'react'
import { useTranslation } from 'react-i18next'

import { Check } from 'lucide-react'

import type { EbFahrplan, EbStation } from '@/types'

/** Höhe der Welle je Station (Einheiten der viewBox, 0 … 40), wie im Dummy. */
const WELLE = [24, 10, 30, 16, 22, 12]

const welle = (i: number): number => WELLE[i % WELLE.length]

/** SVG-Pfad der geschwungenen Linie durch die Mitten der Spalten (viewBox 1000 × 40). */
function pfad(n: number): string {
  const mitte = (i: number): number => ((i + 0.5) / n) * 1000
  let d = `M${mitte(0)} ${welle(0)}`
  for (let i = 1; i < n; i++) {
    const [x0, x1] = [mitte(i - 1), mitte(i)]
    const dx = (x1 - x0) / 2
    d += ` C${x0 + dx} ${welle(i - 1)} ${x1 - dx} ${welle(i)} ${x1} ${welle(i)}`
  }
  return d
}

/** Ring und Zahl in der Farbe des Signals; die geschriebene Arbeit hellblau mit Haken. */
function punktKlasse(s: EbStation): string {
  if (s.stand === 'geschrieben') return 'tp-fp-punkt-geschrieben'
  if (s.signal) return `tp-fp-punkt-${s.signal}`
  return s.stand === 'naechste' ? 'tp-fp-punkt-naechste' : 'tp-fp-punkt-aktuell'
}

function standKlasse(s: EbStation): string {
  if (s.stand === 'geschrieben') return 'tp-fp-geschrieben'
  return s.signal ? `tp-fp-${s.signal}` : 'tp-fp-neutral'
}

/**
 * Der Fahrplan der Klassenarbeiten (V4): eine geschwungene Linie mit einem Punkt
 * je Station, darunter Titel, Stand und Signal. Keine einzelnen Voraussetzungen.
 * Die Punkte erscheinen nacheinander (--i im CSS, Zeiten in rahmen.css). Trenner
 * (Halbjahreszeugnis, nächste Klasse) stehen als dünne Linie zwischen zwei Spalten.
 */
export function FahrplanBahn({ fahrplan }: { fahrplan: EbFahrplan }): JSX.Element {
  const { t } = useTranslation('elternbericht')
  const n = fahrplan.stationen.length
  const trenner = fahrplan.stationen.flatMap((s, i) => {
    if (i === 0) return []
    const vor = fahrplan.stationen[i - 1]
    if (s.schuljahr === 'naechstes' && vor.schuljahr === 'dieses' && fahrplan.klassenTrenner !== null) {
      return [{ vor: i, text: t('v4.stand.klasse', { klasse: fahrplan.klassenTrenner }) }]
    }
    if (fahrplan.halbjahrTrenner && vor.halbjahr === 1 && s.halbjahr === 2) {
      return [{ vor: i, text: t('v4.stand.zeugnis') }]
    }
    return []
  })

  return (
    <div className="tp-fp-bahn-teil" style={{ '--n': n } as CSSProperties}>
      <div className="tp-fp-bahn" aria-hidden="true">
        <svg viewBox="0 0 1000 40" preserveAspectRatio="none">
          <path d={pfad(n)} />
        </svg>
        {fahrplan.stationen.map((s, i) => (
          <span
            key={s.nummer}
            className={`tp-fp-punkt ${punktKlasse(s)}`}
            data-testid="tp-fp-punkt"
            style={{ '--i': i, '--spalte': i, '--hoehe': welle(i) } as CSSProperties}
          >
            {s.stand === 'geschrieben' ? <Check strokeWidth={3} /> : s.nummer}
          </span>
        ))}
        {trenner.map((tr) => (
          <span key={tr.text} className="tp-fp-trenner" style={{ '--spalte': tr.vor } as CSSProperties}>
            <i />
            <b>{tr.text}</b>
          </span>
        ))}
      </div>
      <ol className="tp-fp-spalten">
        {fahrplan.stationen.map((s) => (
          <li key={s.nummer} className="tp-fp-spalte" data-testid="tp-fp-station">
            <b>{s.titel}</b>
            <small className={standKlasse(s)}>
              {[
                t(`v4.stand.${s.stand}`),
                s.halbjahr ? t('v4.stand.halbjahr', { halbjahr: s.halbjahr }) : null,
                s.note !== null ? t('v4.stand.note', { note: s.note }) : null,
                s.signal ? t(`v4.signal.${s.signal}`) : null,
              ]
                .filter((x): x is string => x !== null)
                .map((x, i) => (
                  // Das Leerzeichen davor erlaubt den Umbruch zwischen den Teilen.
                  <Fragment key={x}>
                    {i > 0 && ' '}
                    <span>{x}</span>
                  </Fragment>
                ))}
            </small>
          </li>
        ))}
      </ol>
      {fahrplan.weitere > 0 && (
        <p className="tp-fp-weitere" data-testid="tp-fp-weitere">
          {t('v4.stand.weitere', { count: fahrplan.weitere })}
        </p>
      )}
    </div>
  )
}
