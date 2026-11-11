// Attrappe für useAuth in der Vorschau (SP-1): stabile Objekte (sonst laden Effekte bei jedem Render neu).
const rolle = new URLSearchParams(window.location.search).get('rolle') === 'admin' ? 'admin' : 'coach'
const WERT = { user: { id: 'vorschau-lena' }, role: rolle, loading: false, signOut: async () => undefined }
export const useAuth = (): typeof WERT => WERT
export const useAuthContext = useAuth
