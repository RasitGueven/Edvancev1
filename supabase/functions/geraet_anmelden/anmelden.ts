// Logik der Edge Function geraet_anmelden (Reihe 1 · D1), ohne supabase-js: Die Dienste kommen von aussen,
// damit sich der Ablauf ohne Netz pruefen laesst (anmelden_test.ts).
//
// Ablauf: Eingabe pruefen → geraet_einloesen (service_role; Code, Sperre, Vertrag, Geraete) → Magic-Link
// fuer das EIGENE Konto des Kindes erzeugen und sofort serverseitig einloesen (es geht keine Mail raus) →
// Session-ID aus dem Access-Token am Geraet eintragen → Tokens an die App.
// Schlaegt das Einloesen des Links fehl, gibt geraet_session_setzen(…, null) den Platz wieder frei und eine schon
// entstandene Auth-Session wird geloescht.

export type Einloesung = {
  ergebnis: 'ok' | 'falsch' | 'kein_vertrag' | 'zu_viele_geraete' | 'gesperrt'
  warte_sek: number | null
  email: string | null
  geraet_id: string | null
}

export type Dienste = {
  einloesen: (p: {
    p_code: string
    p_name: string
    p_plattform: string
    p_installation_hash: string
    p_ip_hash: string | null
  }) => Promise<Einloesung>
  magicLinkHash: (email: string) => Promise<string>
  linkEinloesen: (tokenHash: string) => Promise<{ access_token: string; refresh_token: string; expires_at: number | null }>
  sessionSetzen: (geraetId: string, sessionId: string | null) => Promise<void>
  sessionLoeschen: (sessionId: string) => Promise<void>
  /** HMAC-SHA-256 mit dem Pepper der Function (Hex). Ein reiner Hash ueber den IPv4-Raum waere umkehrbar. */
  hmac: (text: string) => Promise<string>
}

export type Antwort =
  | { status: 200; body: { ergebnis: 'ok'; access_token: string; refresh_token: string; expires_at: number | null } }
  | { status: 200; body: { ergebnis: Exclude<Einloesung['ergebnis'], 'ok'>; warte_sek: number | null } }
  | { status: 400 | 500; body: { ergebnis: 'eingabe' | 'fehler' } }

const PLATTFORMEN = new Set(['ios', 'android', 'web'])

/** session_id aus dem Payload eines Supabase-Access-Tokens (JWT, base64url). */
export function sessionIdAusToken(token: string): string | null {
  const teil = token.split('.')[1]
  if (!teil) return null
  try {
    const json = atob(teil.replace(/-/g, '+').replace(/_/g, '/').padEnd(Math.ceil(teil.length / 4) * 4, '='))
    const id = (JSON.parse(json) as { session_id?: unknown }).session_id
    return typeof id === 'string' && /^[0-9a-f-]{36}$/i.test(id) ? id : null
  } catch {
    return null
  }
}

export async function anmelden(
  body: Record<string, unknown>,
  ip: string | null,
  d: Dienste,
): Promise<Antwort> {
  const code = typeof body.code === 'string' ? body.code.slice(0, 40) : ''
  const name = typeof body.name === 'string' ? body.name.slice(0, 60) : ''
  const plattform = typeof body.plattform === 'string' ? body.plattform : ''
  const installation = typeof body.installation === 'string' ? body.installation : ''
  // Ohne Client-IP keine IP-Sperre: dann gar nicht erst pruefen.
  if (!code || !ip || !PLATTFORMEN.has(plattform) || installation.length < 16 || installation.length > 128) {
    return { status: 400, body: { ergebnis: 'eingabe' } }
  }

  // Weder Installations-ID noch IP landen im Klartext in der Datenbank.
  const e = await d.einloesen({
    p_code: code,
    p_name: name,
    p_plattform: plattform,
    p_installation_hash: await d.hmac('geraet:' + installation),
    p_ip_hash: await d.hmac('ip:' + ip),
  })
  if (e.ergebnis !== 'ok') return { status: 200, body: { ergebnis: e.ergebnis, warte_sek: e.warte_sek } }
  if (!e.email || !e.geraet_id) return { status: 500, body: { ergebnis: 'fehler' } }

  let sessionId: string | null = null
  try {
    const session = await d.linkEinloesen(await d.magicLinkHash(e.email))
    sessionId = sessionIdAusToken(session.access_token)
    if (!sessionId) throw new Error('session_id fehlt im Token')
    await d.sessionSetzen(e.geraet_id, sessionId)
    return { status: 200, body: { ergebnis: 'ok', ...session } }
  } catch (err) {
    console.error('geraet_anmelden: Session nicht erzeugt', err instanceof Error ? err.message : err)
    // Aufraeumen: keine Auth-Session ohne Geraet, kein offener Platz. Bleibt die Zeile trotzdem offen,
    // gibt geraet_einloesen sie nach zwei Minuten frei.
    if (sessionId) await d.sessionLoeschen(sessionId).catch(() => undefined)
    await d.sessionSetzen(e.geraet_id, null).catch(() => undefined)
    return { status: 500, body: { ergebnis: 'fehler' } }
  }
}
