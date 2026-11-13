// Attrappe für den Supabase-Client in der Vorschau „Inhalte-Übersicht“ (IU-1 U2). rpc() beantwortet die
// inhalte_*-Funktionen aus daten.json (per dbread aus Prod gezogen, Stand siehe daten.json); sonst leere Antworten.
import daten from './daten.json'

type D = typeof daten
const nachKlasse = <T,>(m: Record<string, T>, k: unknown): T => m[k === null || k === undefined ? 'alle' : String(k)]

function antwort(fn: string, a: Record<string, unknown> = {}): unknown {
  switch (fn) {
    case 'inhalte_auffrischen': return false
    case 'inhalte_lsa_themen': return nachKlasse(daten.themen as Record<string, unknown>, a.p_klasse) ?? []
    case 'inhalte_lsa_thema': return (daten.thema as Record<string, unknown>)[String(a.p_thema_key)] ?? []
    case 'inhalte_lsa_pruefziel': return daten.pruefziel
    case 'inhalte_session_reihen': return nachKlasse(daten.reihen as Record<string, unknown>, a.p_klasse) ?? []
    case 'inhalte_session_reihe': return (daten.reihe as Record<string, unknown>)[String(a.p_reihe)] ?? []
    case 'inhalte_themen_ohne_reihe': return nachKlasse(daten.ohne as Record<string, unknown>, a.p_klasse) ?? []
    default: return []
  }
}

export const DATEN: D = daten
export const supabase = {
  rpc: (fn: string, args?: Record<string, unknown>) => Promise.resolve({ data: antwort(fn, args), error: null }),
  from: () => ({ select: () => Promise.resolve({ data: [], error: null }) }),
  auth: { getSession: () => Promise.resolve({ data: { session: null }, error: null }), onAuthStateChange: () => ({ data: { subscription: { unsubscribe: () => undefined } } }) },
}
