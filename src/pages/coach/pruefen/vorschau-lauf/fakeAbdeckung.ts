// Attrappe für @/lib/supabase/lsaAbdeckung in der Vorschau „Lauf mit Prüfziel“ (IU-1b): Liste mit p_pruefziel und
// p_skill wie in der Datenbank (Filter auf die fertige Liste), Stand je Kompetenz, keine Wirkung.
import type { PruefResult, PruefZielStandZeile, PruefZielZeile } from '@/types'
import { LISTE, LISTE_MSA, STAND_MSA } from './speicher'

const ok = <T,>(data: T): Promise<PruefResult<T>> => Promise.resolve({ data, error: null })
export function getPruefZielListe(_f = false, _q: number | null = null, filter: { ziel?: string | null; skill?: string | null } = {}) {
  const l = filter.ziel ? LISTE_MSA : LISTE
  return ok<PruefZielZeile[]>(filter.skill ? l.filter((z) => z.skill_key === filter.skill) : l)
}
export const getPruefZielStand = () => ok<PruefZielStandZeile[]>(STAND_MSA)
export const getLsaWirkung = () => ok([])
export const frischeLsaAbdeckung = () => ok(false)
// Nur, damit der Abhängigkeits-Scan von Vite andere Einstiege auflösen kann; in dieser Vorschau ungenutzt.
export const getLsaAbdeckung = () => ok([])
export const getLsaPaketSkills = () => ok([])
export const getFokusQuartal = () => Promise.resolve(3)
export const setSchuleFokus = () => ok(null)
