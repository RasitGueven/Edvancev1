import { AbsoluteFill, Audio, Sequence } from 'remotion'

import { BAUSTEIN_KOMPONENTEN } from './bausteine'
import { weltKlasse } from './welten'
import { zeitplan, type VideoDaten } from './zeitplan'
import './video.css'

/**
 * Die Komposition eines Erklärvideos (Anforderung Studio §6–7): Jeder Beat ist eine Sequence, deren Länge aus
 * der Audiodatei kommt (zeitplan.ts). Die Welt ist ein Skin (CSS-Klasse), Mathematik und Reihenfolge kommen
 * aus dem Skelett. Dieselbe Komposition läuft im Player des Studios und im Renderer.
 */
export function Erklaervideo({ welt, beats, ruhig }: VideoDaten): JSX.Element {
  const plan = zeitplan(beats)
  return (
    <AbsoluteFill className={weltKlasse(welt)}>
      {beats.map((b, i) => {
        const Baustein = BAUSTEIN_KOMPONENTEN[b.baustein]
        const z = plan.beats[i]
        return (
          <Sequence key={b.key} from={z.vonFrame} durationInFrames={z.frames} name={`${b.key} · ${b.titel}`}>
            <div className="sv-buehne">{Baustein ? <Baustein beat={b} ruhig={ruhig} /> : null}</div>
            {b.audioUrl && <Audio src={b.audioUrl} />}
          </Sequence>
        )
      })}
    </AbsoluteFill>
  )
}
