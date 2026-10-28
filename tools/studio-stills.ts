// Standbilder eines Skripts in allen Welten (Bauauftrag B3/B7: „Vorschau in allen vier Welten“).
//   npx tsx tools/studio-stills.ts <skript.json> <ausgabe-ordner> [b1,b3,…]
// Browser: CHROME=<Pfad zu headless_shell/chrome>, sonst lädt Remotion seinen eigenen.
// Rendert ohne Audio (geschätzte Dauer) und mit reduzierter Bewegung, damit jeder Beat im Endzustand steht.
import { mkdirSync, readFileSync } from 'node:fs'
import path from 'node:path'
import { bundle } from '@remotion/bundler'
import { renderStill, selectComposition } from '@remotion/renderer'

import { videoDatenAus } from '../src/studio/remotion/daten'
import { frameVonBeat } from '../src/studio/remotion/zeitplan'
import type { Skript } from '../src/studio/skript/typen'

const [datei, aus, beatListe] = process.argv.slice(2)
if (!datei || !aus) {
  console.error('Aufruf: npx tsx tools/studio-stills.ts <skript.json> <ausgabe-ordner> [b1,b3]')
  process.exit(2)
}
const skript = JSON.parse(readFileSync(datei, 'utf8')) as Skript
const browserExecutable = process.env.CHROME || undefined
const serveUrl = await bundle({ entryPoint: path.resolve('remotion/index.ts') })
mkdirSync(aus, { recursive: true })
const beats = beatListe ? beatListe.split(',') : skript.beats.map((b) => b.id)
for (const welt of skript.welten) {
  const inputProps = videoDatenAus(skript, welt, {}, true)
  const composition = await selectComposition({ serveUrl, id: 'Erklaervideo', inputProps, browserExecutable })
  for (const beat of beats) {
    const frame = frameVonBeat(inputProps.beats, beat) + 5
    await renderStill({ composition, serveUrl, output: `${aus}/${welt}-${beat}.png`, frame, inputProps, browserExecutable })
  }
  console.log(`${welt}: ${beats.length} Bilder, ${composition.durationInFrames} Frames`)
}
