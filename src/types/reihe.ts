// Reihe 1 C1: Reihenplan aus reihe_coach_lesen (Konzept Sessionreihe 1 §2). Systemvorschlag und
// Coach-Änderungen kommen getrennt; plan ist der wirksame Plan (Vorschlag + gültige Änderungen).

export type ReiheKernidee = {
  skill_key: string
  kernidee_key: string
  stand: 'neu' | 'gesehen'
  minuten: number
  coach?: boolean
}

export type ReiheSession = {
  nr: number
  datum: string
  art: 'normal' | 'generalprobe'
  kernideen: ReiheKernidee[]
  skills: string[]
  transfer: boolean
  minuten: number
}

export type ReiheEntfallen = { art: 'kernidee'; skill_key: string; kernidee_key: string } | { art: 'transfer' }

export type ReihePlan = {
  modus: 'klassenarbeit' | 'rollierend'
  ka_datum: string | null
  sessions_bisher: number
  sessions: ReiheSession[]
  warnung: { passt: boolean; sessions: number; entfallen: ReiheEntfallen[] }
  version?: number
  bestaetigt?: boolean
  aenderungen?: { id: string; aktion: 'verschieben' | 'bestaetigen'; skill_key: string | null; ziel_datum: string | null; gueltig: boolean }[]
}

export type ReiheCoach = {
  reihe_id: string
  thema_keys: string[]
  ka_datum: string | null
  plan: ReihePlan
  system: ReihePlan
  vorher: ReihePlan | null
  sessions_gesamt: number
  labels: Record<string, string>
  kernideen: Record<string, string>
}
