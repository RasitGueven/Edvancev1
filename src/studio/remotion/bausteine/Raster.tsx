import { useCurrentFrame, useVideoConfig } from 'remotion'

import { einblenden } from '../bewegung'
import { weltWort } from '../welten'
import { text, zahl, type BausteinProps } from './typen'

const LUECKE = 6

/**
 * Raster (Flächen, Quadratzahlen): Zeilen × Spalten, optional aufbauen, markieren, eine Seite zählen
 * oder beschriften. Die Einheit der Welt („Platten“, „Blöcke“) steht unter dem Raster.
 */
export function Raster({ beat, ruhig }: BausteinProps): JSX.Element {
  const frame = useCurrentFrame()
  const { fps, durationInFrames } = useVideoConfig()
  const p = beat.params
  const zeilen = zahl(p, 'zeilen', 1)
  const spalten = zahl(p, 'spalten', 1)
  const markiert = zahl(p, 'markiert', 0)
  const zaehlen = text(p, 'zaehlen')
  const seite = text(p, 'seite_markieren')
  const zelle = Math.floor(Math.min(720 / zeilen, 1000 / spalten)) - LUECKE
  const gesamt = zeilen * spalten
  const dauerS = durationInFrames / fps
  // Zählen über die ganze Beat-Länge verteilt, eine Zahl je Zelle der gezählten Reihe.
  const zaehlZellen = zaehlen === 'untere_reihe' ? spalten : zaehlen === 'linke_spalte' ? zeilen : zaehlen === 'alle' ? gesamt : 0
  const gezaehlt = ruhig ? zaehlZellen : Math.floor(einblenden(frame, fps, 0.2, Math.max(0.5, dauerS - 0.8), false) * zaehlZellen)
  const zaehlIndex = (i: number): number => {
    const z = Math.floor(i / spalten)
    const s = i % spalten
    if (zaehlen === 'untere_reihe') return z === zeilen - 1 ? s : -1
    if (zaehlen === 'linke_spalte') return s === 0 ? z : -1
    return zaehlen === 'alle' ? i : -1
  }
  const einheit = weltWort(beat.bild, 'einheit', '')
  const beschriftung = text(p, 'beschriftung')
  const b = einblenden(frame, fps, 0.3, 0.5, ruhig)

  return (
    <div className="sv-mitte">
      <div className="sv-zeile">
        {seite === 'links' && <div className="sv-beschriftung">{text(p, 'seite_beschriftung')}</div>}
        <div className="sv-raster" style={{ gridTemplateColumns: `repeat(${spalten}, ${zelle}px)` }}>
          {Array.from({ length: gesamt }, (_, i) => {
            const sichtbar = p.aufbauen === true ? einblenden(frame, fps, (i / gesamt) * 1.2, 0.25, ruhig) : 1
            const zi = zaehlIndex(i)
            const hi = i < markiert || (zi >= 0 && zi < gezaehlt)
            const z = Math.floor(i / spalten)
            return (
              <div
                key={i}
                className={`sv-zelle ${hi ? 'sv-zelle-hi' : (z + (i % spalten)) % 2 ? 'sv-zelle-b' : ''}`}
                style={{ width: zelle, height: zelle, opacity: sichtbar }}
              >
                {zi >= 0 && zi < gezaehlt && zaehlen !== 'alle' && (
                  <div className="sv-zahl" style={{ lineHeight: `${zelle}px` }}>
                    {zi + 1}
                  </div>
                )}
              </div>
            )
          })}
        </div>
      </div>
      {seite === 'unten' && <div className="sv-beschriftung">{text(p, 'seite_beschriftung')}</div>}
      {beschriftung && (
        <div className="sv-beschriftung" style={{ opacity: b }}>
          {beschriftung}
        </div>
      )}
      {einheit && <div className="sv-unter">{einheit}</div>}
    </div>
  )
}
