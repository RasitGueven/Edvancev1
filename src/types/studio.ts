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

/** Stand des Reiters Freigabe (studio_freigabe_stand). */
export type StudioPruefung = {
  art: 'verstaendlich' | 'fachlich' | 'variante'
  welt: string
  person: string
  ergebnis: 'passt' | 'passt_nicht'
  beat_key: string | null
  kommentar: string | null
  at: string
  aktuell: boolean
}
export type StudioFreigabeWelt = {
  welt: string
  gueltig: { verstaendlich?: boolean; fachlich?: boolean; variante?: boolean }
  fehlt: string[]
  ausgabe: { freigegeben_am: string; version_skelett: number; version_welt: number; zurueckgezogen: boolean } | null
}
export type StudioFreigabeStand = {
  autor: string | null
  autor_id: string
  geschrieben_am: string
  status: StudioStatus
  ich_bin_autor: boolean
  darf: { verstaendlich: boolean; fachlich: boolean; einreichen: boolean; zurueckziehen: boolean }
  pruefungen: StudioPruefung[]
  welten: StudioFreigabeWelt[]
}
