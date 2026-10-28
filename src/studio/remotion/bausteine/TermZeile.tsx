import { useCurrentFrame, useVideoConfig } from 'remotion'

import { anstieg, einblenden } from '../bewegung'
import { Formel } from '../formel'
import { liste, type BausteinProps } from './typen'

/** Term-Zeile: Terme nacheinander, Hervorhebung und Durchstreichen je Schritt, optional Umkehrpfeil. */
export function TermZeile({ beat, ruhig }: BausteinProps): JSX.Element {
  const frame = useCurrentFrame()
  const { fps, durationInFrames } = useVideoConfig()
  const terme = liste<string>(beat.params, 'terme')
  const hervor = liste<number>(beat.params, 'hervorheben')
  const durch = liste<number>(beat.params, 'durchstreichen')
  const abstand = Math.min(1.2, (durationInFrames / fps) / Math.max(1, terme.length + 0.5))
  return (
    <div className="sv-mitte">
      {terme.map((t, i) => {
        const a = einblenden(frame, fps, i * abstand, 0.5, ruhig)
        return (
          <div key={i} className="sv-zeile" style={{ opacity: a, transform: anstieg(a) }}>
            {i === 1 && beat.params.umkehrpfeil === true && <span className="sv-pfeil">⇅</span>}
            <span className={`${hervor.includes(i) ? 'sv-akzent' : ''} ${durch.includes(i) ? 'sv-strich' : ''}`}>
              <Formel tex={t} gross={terme.length === 1} />
            </span>
          </div>
        )
      })}
    </div>
  )
}
