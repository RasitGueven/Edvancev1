import { useCurrentFrame, useVideoConfig } from 'remotion'

import { einblenden } from '../bewegung'
import { liste, text, type BausteinProps } from './typen'

/**
 * Endkarte, Variante B (06.10.): Das Bild schrumpft nach links, rechts stehen Frage und Antwortoptionen.
 * In der App liegt dort die echte Aufgabe; im Video ist es der Übergang.
 */
export function Endkarte({ beat, ruhig }: BausteinProps): JSX.Element {
  const frame = useCurrentFrame()
  const { fps } = useVideoConfig()
  const a = einblenden(frame, fps, 0, 0.8, ruhig)
  return (
    <div className="sv-end">
      <div className="sv-end-links" style={{ opacity: 0.4 + 0.6 * a }}>
        <div className="sv-unter">{beat.titel}</div>
      </div>
      <div className="sv-end-rechts" style={{ opacity: a }}>
        <div className="sv-text">{text(beat.params, 'frage')}</div>
        {liste<string>(beat.params, 'optionen').map((o) => (
          <div key={o} className="sv-option">
            {o}
          </div>
        ))}
      </div>
    </div>
  )
}
