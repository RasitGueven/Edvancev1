// Attrappe für den Supabase-Client in der Vorschau „Archiv“ (MSA-1 M3). Tabelle tasks im Speicher mit echten Filtern
// (eq, in, is, not … is null), RPCs wie in der Datenbank: pruef_board ohne inaktive Aufgaben (pruef_ausschluss),
// pruef_admin_liste ohne archivierte, task_archiv nur archivierte, task_wiederherstellen ändert nur Archiv-Felder.
import { TASKS, type Zeile } from './daten'

type Filter = (z: Zeile) => boolean
type Ergebnis = { data: unknown; error: null; count?: number }

function abfrage(tabelle: string): Record<string, unknown> {
  const filter: Filter[] = []
  let kopf = false
  let einzeln = false
  const zeilen = (): Zeile[] => (tabelle === 'tasks' ? TASKS : []).filter((z) => filter.every((f) => f(z)))
  const q: Record<string, unknown> = new Proxy({}, {
    get: (_z, name) => {
      if (name === 'then') {
        return (fertig: (w: Ergebnis) => unknown) => {
          const r = zeilen()
          const w: Ergebnis = kopf ? { data: null, error: null, count: r.length }
            : { data: einzeln ? (r[0] ?? null) : r, error: null, count: r.length }
          return Promise.resolve(fertig(w))
        }
      }
      if (name === 'select') return (_c?: string, o?: { head?: boolean }) => ((kopf = Boolean(o?.head)), q)
      if (name === 'eq') return (c: string, v: unknown) => (filter.push((z) => z[c] === v), q)
      if (name === 'in') return (c: string, v: unknown[]) => (filter.push((z) => v.includes(z[c])), q)
      if (name === 'is') return (c: string, v: unknown) => (filter.push((z) => (z[c] ?? null) === v), q)
      if (name === 'not') return (c: string, op: string, v: unknown) => (filter.push((z) => !(op === 'is' && (z[c] ?? null) === v)), q)
      if (name === 'single' || name === 'maybeSingle') return () => ((einzeln = true), q)
      return () => q
    },
  })
  return q
}

const boardZeile = (z: Zeile): Record<string, unknown> => ({
  task_id: z.id, stufe: 'erprobung', thema_key: 'brueche', thema_label: 'Brüche', thema_sort: 1, skill_key: z.skill_key,
  skill_label: 'Brüche addieren', kurztitel: z.title, reihenfolge: 1, lena_status: z.status === 'ready' ? 'freigegeben' : 'offen',
  geaendert: false, letzte_dauer_sek: null, anlaesse: ['batu_lsa'], hat_hinweise: false, pool: 'lsa',
})

function rpc(name: string, args?: Record<string, unknown>): Promise<Ergebnis> {
  const ok = (data: unknown): Promise<Ergebnis> => Promise.resolve({ data, error: null })
  if (name === 'pruef_board') return ok(TASKS.filter((z) => z.is_active).map(boardZeile))
  if (name === 'pruef_admin_liste') {
    return ok(TASKS.filter((z) => !z.archiviert_am).map((z) => ({ task_id: z.id, lena_status: 'offen', ausschluss: null, pilot: true })))
  }
  if (name === 'task_archiv') {
    return ok(TASKS.filter((z) => z.archiviert_am).map((z) => ({
      id: z.id, kurztext: z.title, skill_key: z.skill_key, skill_label: 'Brüche addieren', status: z.status,
      input_type: z.input_type, einsatz: z.einsatz, grund: z.archiviert_grund, archiviert_am: z.archiviert_am, archiviert_von: null,
    })))
  }
  if (name === 'task_wiederherstellen') {
    const ids = (args?.p_ids as string[]) ?? []
    let n = 0
    for (const z of TASKS) {
      if (ids.includes(z.id) && z.archiviert_am) {
        Object.assign(z, { is_active: true, archiviert_am: null, archiviert_grund: null, archiviert_von: null })
        n += 1
      }
    }
    return ok(n)
  }
  return ok([])
}

export const supabase = new Proxy({}, {
  get: (_z, name) => {
    if (name === 'auth') {
      return {
        getSession: async () => ({ data: { session: null }, error: null }),
        onAuthStateChange: () => ({ data: { subscription: { unsubscribe: () => undefined } } }),
      }
    }
    if (name === 'from') return (t: string) => abfrage(t)
    if (name === 'rpc') return (n: string, a?: Record<string, unknown>) => rpc(n, a)
    return () => abfrage('')
  },
})
export default supabase
