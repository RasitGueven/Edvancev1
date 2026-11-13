// Attrappe für useAuth in der Vorschau „Lauf mit Prüfziel“ (IU-1b): Lena (coach mit Prüfrecht).
const WERT = { user: { id: 'vorschau-lena', email: 'lena@vorschau.local' }, role: 'coach', loading: false, signOut: async () => undefined }
export const useAuth = (): typeof WERT => WERT
export const useAuthContext = useAuth
