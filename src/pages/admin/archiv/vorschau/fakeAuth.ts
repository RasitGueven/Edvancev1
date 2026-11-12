// Attrappe für useAuth in der Vorschau „Archiv“ (MSA-1 M3): ?rolle=admin|coach, stabile Objekte.
const rolle = new URLSearchParams(window.location.search).get('rolle') === 'coach' ? 'coach' : 'admin'
const WERT = { user: { id: 'vorschau-admin' }, role: rolle, loading: false, signOut: async () => undefined }
export const useAuth = (): typeof WERT => WERT
export const useAuthContext = useAuth
