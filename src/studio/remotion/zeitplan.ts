/**
 * Zeitplan eines Erklärvideos: Jeder Beat dauert so lange wie sein Satz (Audiodauer) plus eine kurze Pause.
 * Eine Quelle für Vorschau (B3), Render, Kapitel und Untertitel (B4) — deshalb stimmen sie überein.
 */

export const FPS = 30
export const BREITE = 1920
export const HOEHE = 1080
/** Ruhe nach jedem Satz, bevor der nächste Beat beginnt. */
export const PAUSE_MS = 350

export type VideoBeat = {
  key: string
  titel: string
  baustein: string
  params: Record<string, unknown>
  bild: Record<string, unknown>
  text: string
  /** signierte Audio-URL; null = noch nicht vertont (Vorschau mit geschätzter Dauer, stumm). */
  audioUrl: string | null
  dauerMs: number
}

export type VideoDaten = { titel: string; welt: string; beats: VideoBeat[]; ruhig: boolean }

export type BeatZeit = { key: string; titel: string; vonFrame: number; frames: number; startS: number; endeS: number }

export function beatFrames(dauerMs: number, fps = FPS): number {
  return Math.max(1, Math.ceil(((dauerMs + PAUSE_MS) / 1000) * fps))
}

export function zeitplan(beats: Pick<VideoBeat, 'key' | 'titel' | 'dauerMs'>[], fps = FPS): { beats: BeatZeit[]; frames: number } {
  let von = 0
  const liste = beats.map((b) => {
    const frames = beatFrames(b.dauerMs, fps)
    const z = { key: b.key, titel: b.titel, vonFrame: von, frames, startS: von / fps, endeS: (von + frames) / fps }
    von += frames
    return z
  })
  return { beats: liste, frames: Math.max(1, von) }
}

/** kapitel.json: Start jedes Beats in Sekunden (auf Millisekunden gerundet) und Sprungmarke. */
export function kapitel(beats: Pick<VideoBeat, 'key' | 'titel' | 'dauerMs'>[], fps = FPS): { beat: string; start: number; titel: string }[] {
  return zeitplan(beats, fps).beats.map((z) => ({ beat: z.key, start: Math.round(z.startS * 1000) / 1000, titel: z.titel }))
}

const vttZeit = (s: number): string => {
  const ms = Math.round(s * 1000)
  const h = Math.floor(ms / 3600000)
  const m = Math.floor((ms % 3600000) / 60000)
  const sek = Math.floor((ms % 60000) / 1000)
  const p = (n: number, l = 2) => String(n).padStart(l, '0')
  return `${p(h)}:${p(m)}:${p(sek)}.${p(ms % 1000, 3)}`
}

/** untertitel.vtt aus den Sätzen und Beat-Zeiten (Satz läuft bis zum Ende seines Audios, ohne Pause). */
export function untertitel(beats: Pick<VideoBeat, 'key' | 'titel' | 'dauerMs' | 'text'>[], fps = FPS): string {
  const z = zeitplan(beats, fps).beats
  const teile = beats.map((b, i) => `${b.key}\n${vttZeit(z[i].startS)} --> ${vttZeit(z[i].startS + b.dauerMs / 1000)}\n${b.text}`)
  return `WEBVTT\n\n${teile.join('\n\n')}\n`
}

/** Frame des Beats `key` (für Sprünge in der Vorschau). */
export function frameVonBeat(beats: Pick<VideoBeat, 'key' | 'titel' | 'dauerMs'>[], key: string, fps = FPS): number {
  return zeitplan(beats, fps).beats.find((b) => b.key === key)?.vonFrame ?? 0
}
