// Attrappe für den Supabase-Client in der Vorschau (SP-1): jede Kette endet in { data: null, error: null }.
type Kette = Record<string, unknown>
const leer = { data: null, error: null, count: 0 }
const kette: Kette = new Proxy({}, {
  get: (_z, name) => {
    if (name === 'then') return (fertig: (w: typeof leer) => unknown) => Promise.resolve(fertig(leer))
    return () => kette
  },
})
export const supabase = new Proxy({}, {
  get: (_z, name) => {
    if (name === 'auth') {
      return {
        getSession: async () => ({ data: { session: null }, error: null }),
        onAuthStateChange: () => ({ data: { subscription: { unsubscribe: () => undefined } } }),
      }
    }
    return () => kette
  },
})
export default supabase
