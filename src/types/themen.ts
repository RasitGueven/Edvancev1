// Themenkatalog, Schulplaene und Themen je Lead (Migration 20261001114732).

/** KLP-Stufe: erprobung (5/6), erste (7/8), zweite (9/10). */
export type Stufe = 'erprobung' | 'erste' | 'zweite'

export type Thema = {
  thema_key: string
  fach: string
  stufe: Stufe
  label: string
  schlagworte: string[]
  sort: number | null
}

/**
 * Heimat-Thema eines Skills (skill_thema + themen, Migration 20261003104615):
 * das Thema, in dem der Stoff im KLP eingefuehrt wird. Gliedert das
 * Freigabe-Board der Item-Pflege.
 */
export type SkillThema = {
  skill_key: string
  thema_key: string
  label: string
  stufe: Stufe
  sort: number | null
}

/** Eine Zeile aus schul_themenplan; thema_key null = nicht zuordenbar. */
export type SchulPlanZeile = {
  klasse: number
  position: number
  thema_key: string | null
  stand: string | null
}

export type LeadThemaStatus = 'aktuell' | 'behandelt'
export type LeadThemaQuelle = 'gespraech' | 'schulplan'

export type LeadThema = {
  thema_key: string
  fach: string
  status: LeadThemaStatus
  quelle: LeadThemaQuelle
}
