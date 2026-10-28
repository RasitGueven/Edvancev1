import { useCurrentFrame, useVideoConfig } from 'remotion'

import { anstieg, einblenden } from '../bewegung'
import { text, type BausteinProps } from './typen'

export function Titelkarte({ beat, ruhig }: BausteinProps): JSX.Element {
  const frame = useCurrentFrame()
  const { fps } = useVideoConfig()
  const a = einblenden(frame, fps, 0, 0.6, ruhig)
  const b = einblenden(frame, fps, 0.4, 0.6, ruhig)
  return (
    <div className="sv-mitte">
      <div className="sv-titel" style={{ opacity: a, transform: anstieg(a) }}>
        {text(beat.params, 'titel')}
      </div>
      {text(beat.params, 'untertitel') && (
        <div className="sv-unter" style={{ opacity: b, transform: anstieg(b) }}>
          {text(beat.params, 'untertitel')}
        </div>
      )}
    </div>
  )
}
