import { Composition } from 'remotion'

import '../../styles/tokens.css'
import { Erklaervideo } from './Erklaervideo'
import { BREITE, FPS, HOEHE, zeitplan, type VideoDaten } from './zeitplan'

const LEER: VideoDaten = { titel: '', welt: 'skelett', beats: [], ruhig: false }

/** Einstieg für den Renderer (remotion/index.ts): Länge aus den Eingabedaten. */
export function RemotionRoot(): JSX.Element {
  return (
    <Composition
      id="Erklaervideo"
      component={Erklaervideo}
      width={BREITE}
      height={HOEHE}
      fps={FPS}
      durationInFrames={1}
      defaultProps={LEER}
      calculateMetadata={({ props }) => ({ durationInFrames: zeitplan(props.beats).frames })}
    />
  )
}
