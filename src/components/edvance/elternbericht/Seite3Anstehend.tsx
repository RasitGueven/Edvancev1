import { useTranslation } from 'react-i18next'

import type { EbAnstehend, EbBereich, EbStation } from '@/types'

import { signalText, standZeile, tonVon } from './fahrplanText'

/** Ab dieser Stufe des Ausdünnens höchstens drei Bereiche je Liste, wie in den übrigen Blöcken. */
const JE_LISTE = 3

type Gruppe = { key: 'imThema' | 'voraus'; liste: EbBereich[] }

/**
 * Seite 3, V4-S: der erste Block für die anstehende Arbeit im aktuellen Thema („Sitzt schon“ / „Fehlt noch“), je
 * Spalte unterteilt in „Im Thema selbst“ und „Voraussetzungen“. Eine leere Gruppe entfällt, eine leere Spalte auch.
 * Die Bereiche stehen zusätzlich in den übrigen Gruppen der Seite (kein Bereich geht verloren).
 */
export function Seite3Anstehend({
  a,
  s,
  stufe,
}: {
  a: EbAnstehend
  s: EbStation
  stufe: number
}): JSX.Element {
  const { t, i18n } = useTranslation('elternbericht')
  const ton = tonVon(s)
  const spalten = [
    { art: 'sitzt', klasse: 'eb-s3v4-ja', gruppen: [{ key: 'imThema', liste: a.imThema.sitzt }, { key: 'voraus', liste: a.voraus.sitzt }] },
    { art: 'fehlt', klasse: 'eb-s3v4-nein', gruppen: [{ key: 'imThema', liste: a.imThema.fehlt }, { key: 'voraus', liste: a.voraus.fehlt }] },
  ] as const satisfies readonly { art: string; klasse: string; gruppen: readonly Gruppe[] }[]
  const max = stufe >= 1 ? JE_LISTE : Infinity
  return (
    <section className="eb-s3v4-block" data-testid="eb-s3-anstehend">
      <header className="eb-s3v4-kopf">
        <span className={`eb-s3v4-nr eb-ton-${ton}`} aria-hidden="true">
          {s.ka}
        </span>
        <div className="eb-s3v4-titel">
          <h2>{s.ka !== null ? t('v4.s3.blockTitel', { n: s.ka, thema: a.titel }) : a.titel}</h2>
          <p>{standZeile(t, s, i18n.language)}</p>
        </div>
        <span className={`eb-s3v4-chip eb-ton-${ton}`} data-testid="eb-s3-signal">
          {signalText(t, s)}
        </span>
      </header>
      <div className="eb-s3v4-rumpf">
        {spalten
          .filter((sp) => sp.gruppen.some((g) => g.liste.length > 0))
          .map((sp) => (
            <div key={sp.art} className={`eb-s3v4-spalte ${sp.klasse}`} data-testid={`eb-s3-${sp.art}`}>
              <h3>{t(`v4.s3.${sp.art}`)}</h3>
              {sp.gruppen
                .filter((g) => g.liste.length > 0)
                .map((g) => {
                  const rest = Math.max(0, g.liste.length - max)
                  return (
                    <div key={g.key} className="eb-s3v4-gruppe" data-testid={`eb-s3-gruppe-${g.key}`}>
                      <h4>{t(`v4.anstehend.${g.key}`)}</h4>
                      <ul className="eb-s3v4-bereiche">
                        {g.liste.slice(0, max).map((b) => (
                          <li key={b.skillKey}>{b.label}</li>
                        ))}
                        {rest > 0 && <li className="eb-s3v4-mehr">{t('s3.v2.undWeitere', { count: rest })}</li>}
                      </ul>
                    </div>
                  )
                })}
            </div>
          ))}
      </div>
    </section>
  )
}
