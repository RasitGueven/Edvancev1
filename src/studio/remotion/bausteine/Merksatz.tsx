import { useCurrentFrame, useVideoConfig } from 'remotion'

import { anstieg, einblenden } from '../bewegung'
import { Formel } from '../formel'
import { text, type BausteinProps } from './typen'

export function Merksatz({ beat, ruhig }: BausteinProps): JSX.Element {
  const frame = useCurrentFrame()
  const { fps } = useVideoConfig()
  const a = einblenden(frame, fps, 0, 0.6, ruhig)
  const f = text(beat.params, 'formel')
  return (
    <div className="sv-karte sv-mitte" style={{ opacity: a, transform: anstieg(a) }}>
      <div className="sv-text">{text(beat.params, 'text')}</div>
      {f && <Formel tex={f} gross />}
    </div>
  )
}
