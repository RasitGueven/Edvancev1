import { platzhalterDauerMs } from '../stimme/anbieter'
import type { Skript } from '../skript/typen'
import type { VideoBeat, VideoDaten } from './zeitplan'

/** Audio je Beat für eine Welt: signierte URL und Dauer, oder nichts (noch nicht vertont). */
export type BeatAudio = Record<string, { url: string; dauerMs: number } | undefined>

/**
 * Baut die Eingabedaten der Komposition für eine Welt: Sprechtext und Bildparameter der Welt, sonst das
 * Skelett; Dauer aus dem Audio, sonst die geschätzte Dauer des Platzhalters (stumm).
 */
export function videoDatenAus(skript: Skript, welt: string, audio: BeatAudio, ruhig = false): VideoDaten {
  const beats: VideoBeat[] = skript.beats.map((b) => {
    const satz = b.text[welt] ?? b.text.skelett
    const a = audio[b.id]
    return {
      key: b.id,
      titel: b.titel,
      baustein: b.baustein,
      params: b.params,
      bild: b.bild?.[welt] ?? {},
      text: satz,
      audioUrl: a?.url ?? null,
      dauerMs: a?.dauerMs ?? platzhalterDauerMs(satz),
    }
  })
  return { titel: skript.titel, welt, beats, ruhig }
}
