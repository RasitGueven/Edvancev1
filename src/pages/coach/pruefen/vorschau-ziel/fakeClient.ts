// Attrappe für den Supabase-Client in der Vorschau „Gezielt prüfen mit Prüfziel“ (IU-1 U3). rpc() beantwortet
// pruef_ziel_liste (mit p_pruefziel, p_skill) und pruef_ziel_stand aus daten.json (dbread als Lena, Stand dort).
import daten from './daten.json'

type Zeile = { skill_key: string }
function antwort(fn: string, a: Record<string, unknown> = {}): unknown {
  if (fn === 'pruef_ziel_liste') {
    const l = (a.p_pruefziel ? daten.liste_msa : daten.liste) as Zeile[]
    return a.p_skill ? l.filter((z) => z.skill_key === a.p_skill) : l
  }
  if (fn === 'pruef_ziel_stand') return daten.stand_msa
  return []
}

export const supabase = {
  rpc: (fn: string, args?: Record<string, unknown>) => Promise.resolve({ data: antwort(fn, args), error: null }),
  from: () => ({ select: () => Promise.resolve({ data: [], error: null }) }),
}
