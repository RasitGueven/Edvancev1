import { useCurrentFrame, useVideoConfig } from 'remotion'

import { einblenden } from '../bewegung'
import { Formel } from '../formel'
import { abbildung, mischen, NORMALPARABEL, nullstellen, parabelPfad, parabelY, scheitel, schnitt, zahlText, type Parabel } from '../parabel'
import { liste, text, type BausteinProps } from './typen'

const BREITE = 1040
const HOEHE = 860

const paar = (p: Record<string, unknown>, k: string, d: [number, number]): [number, number] => {
  const l = liste<number>(p, k)
  return l.length === 2 && l[0] < l[1] ? [l[0], l[1]] : d
}
const parabel = (p: Record<string, unknown>, k: string): Parabel | null => {
  const l = liste<number>(p, k)
  return l.length === 3 ? [l[0], l[1], l[2]] : null
}

/**
 * Koordinatensystem mit Parabel (B7): Achsen, Raster, Parabel y = a·(x − d)² + e, ruhig animiert von `parabel` zu
 * `parabel_ziel` (strecken, stauchen, spiegeln, verschieben), Scheitel und Nullstellen, Gerade y = c mit Schnitt-
 * punkten (x² = c), Punkte und Wertetabelle daneben. Bei reduzierter Bewegung steht der Endzustand.
 */
export function Koordinatensystem({ beat, ruhig }: BausteinProps): JSX.Element {
  const frame = useCurrentFrame()
  const { fps, durationInFrames } = useVideoConfig()
  const p = beat.params
  const xb = paar(p, 'x_bereich', [-5, 5])
  const yb = paar(p, 'y_bereich', [-2, 8])
  const m = abbildung(xb, yb, BREITE, HOEHE)
  const start = parabel(p, 'parabel')
  const ziel = parabel(p, 'parabel_ziel')
  const dauerS = durationInFrames / fps
  const t = einblenden(frame, fps, 0.4, Math.max(0.6, dauerS * 0.6), ruhig)
  const jetzt = start && ziel ? mischen(start, ziel, t) : (start ?? ziel)
  const zeichnen = einblenden(frame, fps, 0, 0.8, ruhig)
  const marken = einblenden(frame, fps, Math.min(dauerS * 0.7, 1.2), 0.5, ruhig)
  const c = typeof p.gerade_y === 'number' ? p.gerade_y : null
  const tabelle = liste<number>(p, 'wertetabelle')
  const gleichung = text(p, 'gleichung')

  const feld = `ks-feld-${beat.key}`
  const ticks = (von: number, bis: number) => Array.from({ length: Math.floor(bis) - Math.ceil(von) + 1 }, (_, i) => Math.ceil(von) + i)

  return (
    <div className="sv-zeile">
      <div className="sv-mitte">
        <svg className="sv-ks" width={BREITE} height={HOEHE} viewBox={`0 0 ${BREITE} ${HOEHE}`}>
          <defs>
            <clipPath id={feld}>
              <rect width={BREITE} height={HOEHE} />
            </clipPath>
          </defs>
          {p.raster !== false &&
            ticks(xb[0], xb[1]).map((x) => <line key={`gx${x}`} className="sv-ks-raster" x1={m.x(x)} x2={m.x(x)} y1={0} y2={HOEHE} />)}
          {p.raster !== false &&
            ticks(yb[0], yb[1]).map((y) => <line key={`gy${y}`} className="sv-ks-raster" x1={0} x2={BREITE} y1={m.y(y)} y2={m.y(y)} />)}
          <line className="sv-ks-achse" x1={0} x2={BREITE} y1={m.y(0)} y2={m.y(0)} />
          <line className="sv-ks-achse" x1={m.x(0)} x2={m.x(0)} y1={0} y2={HOEHE} />
          {ticks(xb[0], xb[1])
            .filter((x) => x !== 0)
            .map((x) => (
              <text key={`tx${x}`} className="sv-ks-zahl" x={m.x(x)} y={m.y(0) + 34} textAnchor="middle">
                {zahlText(x)}
              </text>
            ))}
          {ticks(yb[0], yb[1])
            .filter((y) => y !== 0)
            .map((y) => (
              <text key={`ty${y}`} className="sv-ks-zahl" x={m.x(0) - 14} y={m.y(y) + 9} textAnchor="end">
                {zahlText(y)}
              </text>
            ))}
          {p.normalparabel === true && <path className="sv-ks-normal" clipPath={`url(#${feld})`} d={parabelPfad(NORMALPARABEL, xb, yb, BREITE, HOEHE)} />}
          {c !== null && <line className="sv-ks-gerade" x1={0} x2={BREITE} y1={m.y(c)} y2={m.y(c)} style={{ opacity: zeichnen }} />}
          {jetzt && (
            <path className="sv-ks-parabel" clipPath={`url(#${feld})`} d={parabelPfad(jetzt, xb, yb, BREITE, HOEHE)} pathLength={1}
              style={{ strokeDasharray: 1, strokeDashoffset: 1 - zeichnen }} />
          )}
          {jetzt && p.scheitel_markieren === true && (
            <g style={{ opacity: marken }}>
              <circle className="sv-ks-punkt" cx={m.x(scheitel(jetzt)[0])} cy={m.y(scheitel(jetzt)[1])} r={14} />
              <text className="sv-ks-text" x={m.x(scheitel(jetzt)[0]) + 22} y={m.y(scheitel(jetzt)[1]) + (jetzt[0] >= 0 ? 44 : -22)}>
                S({zahlText(scheitel(jetzt)[0])} | {zahlText(scheitel(jetzt)[1])})
              </text>
            </g>
          )}
          {jetzt && p.nullstellen_markieren === true &&
            nullstellen(jetzt).map((x) => (
              <circle key={`n${x}`} className="sv-ks-punkt-leer" cx={m.x(x)} cy={m.y(0)} r={14} style={{ opacity: marken }} />
            ))}
          {jetzt && c !== null && p.schnitt_markieren === true &&
            schnitt(jetzt, c).map((x) => (
              <g key={`s${x}`} style={{ opacity: marken }}>
                <circle className="sv-ks-punkt" cx={m.x(x)} cy={m.y(c)} r={14} />
                <text className="sv-ks-text" x={m.x(x)} y={m.y(c) - 26} textAnchor="middle">
                  {zahlText(x)}
                </text>
              </g>
            ))}
          {liste<[number, number]>(p, 'punkte').map(([x, y], i) => (
            <circle key={`p${i}`} className="sv-ks-punkt" cx={m.x(x)} cy={m.y(y)} r={12}
              style={{ opacity: einblenden(frame, fps, 0.3 + i * 0.35, 0.3, ruhig) }} />
          ))}
        </svg>
        {gleichung && <Formel tex={gleichung} />}
      </div>
      {jetzt && tabelle.length > 0 && (
        <div className="sv-tabelle">
          <div className="sv-tabelle-kopf">x</div>
          <div className="sv-tabelle-kopf">y</div>
          {tabelle.map((x, i) => {
            const a = einblenden(frame, fps, 0.4 + i * 0.4, 0.3, ruhig)
            return [
              <div key={`x${i}`} className="sv-tabelle-zelle" style={{ opacity: a }}>{zahlText(x)}</div>,
              <div key={`y${i}`} className="sv-tabelle-zelle" style={{ opacity: a }}>{zahlText(parabelY(jetzt, x))}</div>,
            ]
          })}
        </div>
      )}
    </div>
  )
}
