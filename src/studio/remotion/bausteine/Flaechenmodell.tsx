import { useCurrentFrame, useVideoConfig } from 'remotion'

import { einblenden } from '../bewegung'
import { Formel } from '../formel'
import { zahlText } from '../parabel'
import { text, zahl, type BausteinProps } from './typen'

const S = 440
const RAND = 80

/**
 * Raster als Flächenmodell für die quadratische Ergänzung (B7, V4): Quadrat x · x, zwei Streifen b/2 · x rechts und
 * unten, das fehlende Eckquadrat (b/2)² gestrichelt; mit `zeigen = ecke` wird es eingeblendet. Die Streifenbreite ist
 * maßstäblich zu x = 4 (nur zur Anschauung, die Beschriftung trägt die Mathematik).
 */
export function Flaechenmodell({ beat, ruhig }: BausteinProps): JSX.Element {
  const frame = useCurrentFrame()
  const { fps } = useVideoConfig()
  const p = beat.params
  const halb = zahl(p, 'b', 2) / 2
  const w = Math.max(70, Math.min(260, (S * halb) / 4))
  const x = text(p, 'x_beschriftung') ?? 'x'
  const zeigen = text(p, 'zeigen') ?? 'quadrat'
  const streifen = zeigen === 'streifen' || zeigen === 'ecke' ? einblenden(frame, fps, 0.3, 0.7, ruhig) : 0
  const ecke = zeigen === 'ecke' ? einblenden(frame, fps, 1.2, 0.7, ruhig) : 0
  const quadrat = einblenden(frame, fps, 0, 0.6, ruhig)
  const g = text(p, 'gleichung')
  const breite = RAND + S + w + RAND / 2
  const hoehe = RAND + S + w + RAND / 2

  return (
    <div className="sv-mitte">
      <svg className="sv-ks" width={breite} height={hoehe} viewBox={`0 0 ${breite} ${hoehe}`}>
        <g transform={`translate(${RAND} ${RAND})`}>
          <rect className="sv-fm-quadrat" width={S} height={S} rx={10} style={{ opacity: quadrat }} />
          <text className="sv-fm-text" x={S / 2} y={S / 2 + 16} textAnchor="middle" style={{ opacity: quadrat }}>
            {x}²
          </text>
          <g style={{ opacity: streifen }}>
            <rect className="sv-fm-streifen" x={S} width={w} height={S} rx={10} />
            <rect className="sv-fm-streifen" y={S} width={S} height={w} rx={10} />
            <text className="sv-fm-text" x={S + w / 2} y={S / 2 + 16} textAnchor="middle">{`${zahlText(halb)}${x}`}</text>
            <text className="sv-fm-text" x={S / 2} y={S + w / 2 + 16} textAnchor="middle">{`${zahlText(halb)}${x}`}</text>
            <text className="sv-fm-mass" x={S + w / 2} y={-22} textAnchor="middle">{zahlText(halb)}</text>
            <text className="sv-fm-mass" x={-22} y={S + w / 2 + 14} textAnchor="end">{zahlText(halb)}</text>
          </g>
          {zeigen !== 'quadrat' && <rect className="sv-fm-ecke-leer" x={S} y={S} width={w} height={w} rx={10} style={{ opacity: streifen }} />}
          <g style={{ opacity: ecke }}>
            <rect className="sv-fm-ecke" x={S} y={S} width={w} height={w} rx={10} />
            <text className="sv-fm-text sv-fm-auf-akzent" x={S + w / 2} y={S + w / 2 + 16} textAnchor="middle">{zahlText(halb * halb)}</text>
          </g>
          <rect className="sv-fm-rand" width={S} height={S} rx={10} style={{ opacity: quadrat }} />
          <text className="sv-fm-mass" x={S / 2} y={-22} textAnchor="middle" style={{ opacity: quadrat }}>{x}</text>
          <text className="sv-fm-mass" x={-22} y={S / 2 + 14} textAnchor="end" style={{ opacity: quadrat }}>{x}</text>
        </g>
      </svg>
      {g && <Formel tex={g} />}
    </div>
  )
}
