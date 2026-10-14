// Der Kern von coach_einladen — ohne Deno.serve und ohne supabase-js.
// index.ts gibt die Dienste hinein, die Tests geben Attrappen hinein.
//
// Autorisierung wie provision_coach (fail-closed): Bearer == Service-Role-Key
// ODER gueltiges User-JWT mit Rolle admin. Alles andere: 401/403.
//
// Aktion "neu":   Vor-/Nachname + E-Mail. Gibt es die Adresse schon (auth.users
//                 oder profiles), 409 email_vergeben — kein zweites Konto, keine
//                 Mail. Sonst inviteUserByEmail (redirectTo /auth/einladung,
//                 full_name in den Metadaten), danach profiles-Upsert mit
//                 role 'coach'. Scheitert der Upsert, wird das Konto geloescht.
// Aktion "erneut": coach_id eines Coach-Kontos, das die Einladung noch nicht
//                 angenommen hat (E-Mail unbestaetigt). Sonst 409 schon_aktiv.
//
// Der Admin vergibt kein Passwort. Das setzt der Coach selbst.

export type Konto = { id: string; email: string; bestaetigt: boolean; name: string }

export type Dienste = {
  serviceKey: string
  appUrl: string | undefined
  /** Nutzer zum JWT oder null. */
  aufrufer: (authHeader: string) => Promise<{ id: string } | null>
  rolle: (uid: string) => Promise<string | null>
  emailVorhanden: (email: string) => Promise<boolean>
  einladen: (
    email: string,
    opts: { redirectTo: string; data: { full_name: string } },
  ) => Promise<{ id: string } | { fehler: string; code?: string }>
  profilSchreiben: (p: { id: string; email: string; role: 'coach'; full_name: string }) => Promise<string | null>
  loeschen: (uid: string) => Promise<void>
  konto: (uid: string) => Promise<Konto | null>
}

export type Antwort = { status: number; payload: Record<string, unknown> }

const EMAIL_RE = /^[^@\s]+@[^@\s]+\.[^@\s]+$/
const NAME_MAX = 100

function fehler(status: number, code: string, error: string): Antwort {
  return { status, payload: { code, error } }
}

/** redirectTo fuer die Einladung: immer die Seite /auth/einladung. */
export function einladungsZiel(appUrl: string | undefined, ausRumpf: unknown): string | null {
  const kandidat = appUrl || (typeof ausRumpf === 'string' ? ausRumpf : '')
  try {
    const u = new URL(kandidat)
    if (u.protocol !== 'https:' && u.protocol !== 'http:') return null
    return `${u.origin}/auth/einladung`
  } catch {
    return null
  }
}

async function autorisieren(authHeader: string, d: Dienste): Promise<Antwort | null> {
  const bearer = authHeader.replace(/^Bearer\s+/i, '').trim()
  if (bearer !== '' && bearer === d.serviceKey) return null
  if (bearer === '') return fehler(401, 'nicht_angemeldet', 'Nicht authentifiziert')
  const nutzer = await d.aufrufer(authHeader)
  if (!nutzer) return fehler(401, 'nicht_angemeldet', 'Nicht authentifiziert')
  const rolle = await d.rolle(nutzer.id)
  if (rolle !== 'admin') return fehler(403, 'kein_admin', 'Nur Admin darf Coaches einladen')
  return null
}

export async function einladenBearbeiten(
  authHeader: string,
  body: Record<string, unknown>,
  d: Dienste,
): Promise<Antwort> {
  const verweigert = await autorisieren(authHeader, d)
  if (verweigert) return verweigert

  const redirectTo = einladungsZiel(d.appUrl, body.redirect_to)
  if (!redirectTo) return fehler(400, 'eingabe', 'Keine gueltige App-Adresse fuer den Link')

  if (body.aktion === 'erneut') {
    const id = typeof body.coach_id === 'string' ? body.coach_id : ''
    if (id === '') return fehler(400, 'eingabe', 'coach_id erforderlich')
    const [konto, rolle] = await Promise.all([d.konto(id), d.rolle(id)])
    if (!konto || rolle !== 'coach') return fehler(404, 'nicht_gefunden', 'Coach-Konto nicht gefunden')
    if (konto.bestaetigt) return fehler(409, 'schon_aktiv', 'Die Einladung ist schon angenommen')
    const r = await d.einladen(konto.email, { redirectTo, data: { full_name: konto.name } })
    if ('fehler' in r) return fehler(502, 'einladung_fehlgeschlagen', r.fehler)
    return { status: 200, payload: { coach_id: id, aktion: 'erneut' } }
  }

  if (body.aktion !== 'neu') return fehler(400, 'eingabe', 'aktion muss neu oder erneut sein')

  const vorname = typeof body.vorname === 'string' ? body.vorname.trim() : ''
  const nachname = typeof body.nachname === 'string' ? body.nachname.trim() : ''
  const email = typeof body.email === 'string' ? body.email.trim().toLowerCase() : ''
  if (vorname === '' || nachname === '') return fehler(400, 'eingabe', 'Vor- und Nachname erforderlich')
  if (vorname.length > NAME_MAX || nachname.length > NAME_MAX) return fehler(400, 'eingabe', 'Name zu lang')
  if (!EMAIL_RE.test(email)) return fehler(400, 'eingabe', 'Ungueltige E-Mail')
  const fullName = `${vorname} ${nachname}`

  if (await d.emailVorhanden(email)) {
    return fehler(409, 'email_vergeben', 'Mit dieser Adresse gibt es schon ein Konto')
  }

  const r = await d.einladen(email, { redirectTo, data: { full_name: fullName } })
  if ('fehler' in r) {
    if (r.code === 'email_exists' || r.code === 'user_already_exists') {
      return fehler(409, 'email_vergeben', 'Mit dieser Adresse gibt es schon ein Konto')
    }
    return fehler(502, 'einladung_fehlgeschlagen', r.fehler)
  }

  const profilFehler = await d.profilSchreiben({ id: r.id, email, role: 'coach', full_name: fullName })
  if (profilFehler) {
    await d.loeschen(r.id)
    return fehler(500, 'profil_fehlgeschlagen', profilFehler)
  }

  return { status: 200, payload: { coach_id: r.id, aktion: 'neu' } }
}
