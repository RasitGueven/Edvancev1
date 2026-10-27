// geraet_anmelden ohne Netz: Datenbank und Auth sind Attrappen.
//
// Geprueft (Bauauftrag D, D1.3):
//   - fehlende oder kaputte Eingabe -> 400, ohne Datenbankaufruf
//   - ohne Client-IP -> 400 (sonst gaebe es keine IP-Sperre)
//   - Installations-ID und IP gehen nur als HMAC an die Datenbank, der Code unveraendert (die DB normalisiert)
//   - falsch / gesperrt / zu_viele_geraete / kein_vertrag -> 200 mit Ergebnis, kein Magic-Link
//   - ok -> Magic-Link fuer die E-Mail des Kindes, Session-ID aus dem Token am Geraet, Tokens in der Antwort
//   - Link scheitert -> 500 und das Geraet wird freigegeben (sessionSetzen mit null)
//
// Lauf:  npx deno@2 test supabase/functions/geraet_anmelden/

import { assertEquals } from 'https://deno.land/std@0.224.0/assert/mod.ts'
import { anmelden, sessionIdAusToken, type Dienste, type Einloesung } from './anmelden.ts'

const SESSION = '3f6b1c1e-1111-4a2b-9c3d-000000000001'
const b64 = (o: unknown) => btoa(JSON.stringify(o)).replace(/=+$/, '').replace(/\+/g, '-').replace(/\//g, '_')
const TOKEN = `${b64({ alg: 'HS256' })}.${b64({ sub: 'kind', session_id: SESSION })}.sig`
const RUMPF = { code: 'edv-k7m2-qx9a', name: 'Batus iPhone', plattform: 'ios', installation: 'inst-0123456789abcdef' }

function dienste(e: Partial<Einloesung>, linkFehler = false, sessionFehler = false) {
  const log: string[] = []
  const d: Dienste = {
    hmac: async (t) => `h(${t})`,
    einloesen: async (p) => {
      log.push(`einloesen ${p.p_code} ${p.p_installation_hash} ${p.p_ip_hash}`)
      return { ergebnis: 'ok', warte_sek: null, email: 'kind@test.local', geraet_id: 'g1', ...e }
    },
    magicLinkHash: async (email) => {
      log.push(`link ${email}`)
      return 'hash1'
    },
    linkEinloesen: async (h) => {
      log.push(`verify ${h}`)
      if (linkFehler) throw new Error('kaputt')
      return { access_token: TOKEN, refresh_token: 'r1', expires_at: 1 }
    },
    sessionSetzen: async (g, s) => {
      log.push(`session ${g} ${s}`)
      if (s && sessionFehler) throw new Error('db weg')
    },
    sessionLoeschen: async (s) => {
      log.push(`loeschen ${s}`)
    },
  }
  return { d, log }
}

Deno.test('Eingabe fehlt oder kaputt, oder keine Client-IP: 400 ohne Datenbank', async () => {
  for (const [b, ip] of [[{}, '1.2.3.4'], [{ ...RUMPF, plattform: 'windows' }, '1.2.3.4'], [{ ...RUMPF, installation: 'kurz' }, '1.2.3.4'],
                         [{ ...RUMPF, code: 7 }, '1.2.3.4'], [RUMPF, null]] as const) {
    const { d, log } = dienste({})
    const a = await anmelden(b as Record<string, unknown>, ip, d)
    assertEquals(a.status, 400)
    assertEquals(log, [])
  }
})

Deno.test('HMAC statt Klartext für Installation und IP', async () => {
  const { d, log } = dienste({ ergebnis: 'falsch' })
  await anmelden(RUMPF, '1.2.3.4', d)
  assertEquals(log, ['einloesen edv-k7m2-qx9a h(geraet:inst-0123456789abcdef) h(ip:1.2.3.4)'])
})

Deno.test('Abgelehnt: Ergebnis ohne Magic-Link', async () => {
  for (const ergebnis of ['falsch', 'gesperrt', 'zu_viele_geraete', 'kein_vertrag'] as const) {
    const { d, log } = dienste({ ergebnis, warte_sek: ergebnis === 'gesperrt' ? 900 : null })
    const a = await anmelden(RUMPF, '1.2.3.4', d)
    assertEquals(a, { status: 200, body: { ergebnis, warte_sek: ergebnis === 'gesperrt' ? 900 : null } })
    assertEquals(log.length, 1)
  }
})

Deno.test('ok: Link für das Kind, Session am Gerät, Tokens zurück', async () => {
  const { d, log } = dienste({})
  const a = await anmelden(RUMPF, '1.2.3.4', d)
  assertEquals(a, { status: 200, body: { ergebnis: 'ok', access_token: TOKEN, refresh_token: 'r1', expires_at: 1 } })
  assertEquals(log.slice(1), ['link kind@test.local', 'verify hash1', `session g1 ${SESSION}`])
})

Deno.test('Link scheitert: 500 und Gerät frei', async () => {
  const { d, log } = dienste({}, true)
  const a = await anmelden(RUMPF, '1.2.3.4', d)
  assertEquals(a.status, 500)
  assertEquals(log.at(-1), 'session g1 null')
  assertEquals(log.some((l) => l.startsWith('loeschen')), false)
})

Deno.test('Session entstanden, Eintragen scheitert: Session wird gelöscht, Gerät frei', async () => {
  const { d, log } = dienste({}, false, true)
  const a = await anmelden(RUMPF, '1.2.3.4', d)
  assertEquals(a.status, 500)
  assertEquals(log.slice(-2), [`loeschen ${SESSION}`, 'session g1 null'])
})

Deno.test('sessionIdAusToken', () => {
  assertEquals(sessionIdAusToken(TOKEN), SESSION)
  assertEquals(sessionIdAusToken('kaputt'), null)
  assertEquals(sessionIdAusToken(`${b64({})}.${b64({ session_id: 'nein' })}.x`), null)
})
