import type { Befund, Skript } from '@/studio/skript/typen'

/** Status einer Videosequenz (Anforderung Studio §3). */
export type StudioStatus = 'entwurf' | 'vertont' | 'gerendert' | 'in_pruefung' | 'freigegeben'

/** Zeile aus studio_sequenz. */
export type StudioSequenz = {
  id: string
  skillKey: string
  titel: string
  autorId: string
  status: StudioStatus
  welten: string[]
  version: number
  skript: Skript
  geaendertAm: string
}

/** Stand einer Welt (studio_welt). */
export type StudioWeltStand = {
  welt: string
  version: number
  gesperrt: boolean
  befunde: Befund[]
}

export type StudioErgebnis<T> = { data: T | null; error: { code: string | null; message: string; hint: string | null } | null }
