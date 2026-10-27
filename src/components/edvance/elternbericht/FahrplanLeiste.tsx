import { useTranslation } from 'react-i18next'

import type { EbFahrplan } from '@/types'

import { folgeBekannt, stationAria, tonVon } from './fahrplanText'

/** Welche Chips der Leiste hervorgehoben sind: alle (Seite 2, 5) oder nur die kommenden (Seite 3, 4). */
export type LeistenHervorhebung = 'alle' | 'kommende'

/**
 * Die Klassenarbeits-Leiste unter der Kopflinie der Seiten 2–5 (Bauauftrag V4,
 * V4-2 Entscheidung 1): ein Chip je Station mit Nummer bzw. Haken in Signalfarbe
 * und dem Titel, der in der schmalen Leiste mit Ellipse endet. Die volle
 * Bezeichnung steht als Vorlesetext. Höhe 16 pt. L5: Ohne bekannte Folge heißt die Leiste „Themen“, und die Punkte
 * tragen keine Ziffer.
 */
export function FahrplanLeiste({
  fahrplan,
  hervor,
}: {
  fahrplan: EbFahrplan
  hervor: LeistenHervorhebung
}): JSX.Element {
  const { t } = useTranslation('elternbericht')
  const label = t(folgeBekannt(fahrplan) ? 'v4.leiste.label' : 'v4.leiste.labelThema')
  return (
    <div className="eb-leiste" data-testid="eb-leiste">
      <span className="eb-leiste-label" aria-hidden="true">
        {label}
      </span>
      <ol className="eb-leiste-liste" aria-label={label}>
        {fahrplan.stationen.map((s) => {
          const an = hervor === 'alle' || s.nummer > 1 || s.stand === 'naechste' || s.stand === 'steht'
          return (
            <li
              key={s.nummer}
              className={`eb-leiste-chip eb-ton-${tonVon(s)}${an ? ' eb-leiste-an' : ''}`}
              data-testid="eb-leiste-chip"
            >
              <span className="sr-only">{stationAria(t, s)}</span>
              <span className="eb-leiste-punkt" aria-hidden="true">
                {s.stand === 'geschrieben' ? (
                  <svg viewBox="0 0 10 10">
                    <path d="M2.2 5.2 L4.3 7.2 L7.9 2.9" />
                  </svg>
                ) : (
                  s.ka
                )}
              </span>
              <span className="eb-leiste-titel" aria-hidden="true">
                {s.titel}
              </span>
            </li>
          )
        })}
      </ol>
    </div>
  )
}
