// Der Send Email Hook ohne Netz: Versand und Protokoll sind Attrappen.
//
// Geprueft (Auftrag K1, Test 2):
//   - ohne Signatur, mit falscher Signatur, mit altem Zeitstempel -> 401, kein Versand, kein Protokoll
//   - invite und recovery: Link auf die eigene Seite mit token_hash und type, nie /auth/v1/verify
//   - unbekannte Art -> 400 mit definiertem Fehler, protokolliert
//   - Protokollzeile ohne Token und ohne Link, auch im Fehlerfall
//   - die uebrigen Arten bekommen eine korrekte Mail
//
// Lauf:  npx deno@2 test supabase/functions/auth_mail/

import { assert, assertEquals, assertStringIncludes } from 'https://deno.land/std@0.224.0/assert/mod.ts'
import { schluesselAusSecret, signieren } from '../_shared/standard_webhooks.ts'
import { hookBearbeiten, type Mail, type ProtokollZeile } from './hook.ts'

// Ein Test-Secret im Dashboard-Format; kein echtes.
const SECRET = 'v1,whsec_' + btoa('zz-k1-testschluessel-32-bytes-lang!')
const SCHLUESSEL = schluesselAusSecret(SECRET)!
const JETZT = 1_792_000_000
const TOKEN = '123456'
const HASH = 'pkce_zz0123456789abcdef0123456789abcdef0123456789abcdef'
const HASH_NEU = 'pkce_zzfedcba9876543210fedcba9876543210fedcba9876543210'

function nutzlast(art: string, extra: Record<string, unknown> = {}): string {
  return JSON.stringify({
    user: {
      id: '0c100000-0000-4000-8000-00000000000c',
      email: 'zz-coach@example.org',
      new_email: 'zz-neu@example.org',
      user_metadata: { full_name: 'ZZ Mia Coach' },
    },
    email_data: {
      token: TOKEN,
      token_hash: HASH,
      token_new: '',
      token_hash_new: '',
      redirect_to: 'https://studio.example.org/auth/einladung',
      email_action_type: art,
      site_url: 'https://site.example.org',
      ...extra,
    },
  })
}

async function anfrage(rumpf: string, kopf: 'gut' | 'ohne' | 'falsch' | 'alt' = 'gut'): Promise<Request> {
  const headers = new Headers({ 'Content-Type': 'application/json' })
  if (kopf !== 'ohne') {
    const zeit = String(kopf === 'alt' ? JETZT - 600 : JETZT)
    const sig = await signieren(SCHLUESSEL, 'msg_zz1', zeit, rumpf)
    headers.set('webhook-id', 'msg_zz1')
    headers.set('webhook-timestamp', zeit)
    headers.set('webhook-signature', kopf === 'falsch' ? `v1,${btoa('falsch')}` : `v1,${sig}`)
  }
  return new Request('http://lokal/auth_mail', { method: 'POST', headers, body: rumpf })
}

function aufbau(senden?: (m: Mail) => Promise<void>) {
  const gesendet: Mail[] = []
  const protokoll: ProtokollZeile[] = []
  return {
    gesendet,
    protokoll,
    deps: {
      schluessel: SCHLUESSEL,
      appUrl: 'https://studio.example.org/irgendwas',
      senden: senden ?? (async (m: Mail) => void gesendet.push(m)),
      protokollieren: async (z: ProtokollZeile) => void protokoll.push(z),
      jetztSekunden: JETZT,
    },
  }
}

/** Keine Protokollzeile darf Token, Hash oder Link enthalten. */
function protokollSauber(protokoll: ProtokollZeile[]): void {
  const roh = JSON.stringify(protokoll)
  for (const geheim of [TOKEN, HASH, HASH_NEU, 'token_hash', 'http']) {
    assert(!roh.includes(geheim), `Protokoll enthaelt ${geheim}: ${roh}`)
  }
}

for (const fall of ['ohne', 'falsch', 'alt'] as const) {
  Deno.test(`Signatur ${fall} -> 401, nichts versendet, nichts protokolliert`, async () => {
    const a = aufbau()
    const r = await hookBearbeiten(await anfrage(nutzlast('invite'), fall), a.deps)
    assertEquals(r.status, 401)
    assertEquals(a.gesendet.length, 0)
    assertEquals(a.protokoll.length, 0)
  })
}

Deno.test('Rumpf nach dem Signieren veraendert -> 401', async () => {
  const a = aufbau()
  const echt = await anfrage(nutzlast('invite'))
  const manipuliert = new Request(echt.url, {
    method: 'POST',
    headers: echt.headers,
    body: nutzlast('invite').replace('zz-coach@', 'angreifer@'),
  })
  assertEquals((await hookBearbeiten(manipuliert, a.deps)).status, 401)
  assertEquals(a.gesendet.length, 0)
})

Deno.test('ohne eingerichtetes Secret -> 401 (fail-closed)', async () => {
  const a = aufbau()
  const r = await hookBearbeiten(await anfrage(nutzlast('invite')), { ...a.deps, schluessel: null })
  assertEquals(r.status, 401)
  assertEquals(a.gesendet.length, 0)
})

Deno.test('invite: Link auf /auth/einladung mit token_hash und type, Anrede mit Namen', async () => {
  const a = aufbau()
  const r = await hookBearbeiten(await anfrage(nutzlast('invite')), a.deps)
  assertEquals(r.status, 200)
  assertEquals(a.gesendet.length, 1)
  const m = a.gesendet[0]
  assertEquals(m.an, 'zz-coach@example.org')
  assertEquals(m.betreff, 'Ihr Zugang zu Edvance')
  assertStringIncludes(m.text, 'Guten Tag ZZ Mia Coach,')
  assertStringIncludes(m.text, `https://studio.example.org/auth/einladung?token_hash=${HASH}&type=invite`)
  assert(!m.text.includes('/auth/v1/verify'), 'kein direkter Verify-Link')
  assert(!m.text.includes('site.example.org'), 'APP_URL hat Vorrang vor site_url')
  assertEquals(a.protokoll, [
    { art: 'invite', empfaenger: 'zz-coach@example.org', user_id: '0c100000-0000-4000-8000-00000000000c', fehler: null },
  ])
  protokollSauber(a.protokoll)
})

Deno.test('recovery: Link auf /auth/neues-passwort mit token_hash und type', async () => {
  const a = aufbau()
  const r = await hookBearbeiten(await anfrage(nutzlast('recovery')), a.deps)
  assertEquals(r.status, 200)
  const m = a.gesendet[0]
  assertEquals(m.betreff, 'Neues Passwort für Edvance')
  assertStringIncludes(m.text, `https://studio.example.org/auth/neues-passwort?token_hash=${HASH}&type=recovery`)
  assert(!m.text.includes('/auth/v1/verify'))
  protokollSauber(a.protokoll)
})

Deno.test('ohne APP_URL gilt der Ursprung von site_url', async () => {
  const a = aufbau()
  await hookBearbeiten(await anfrage(nutzlast('recovery')), { ...a.deps, appUrl: undefined })
  assertStringIncludes(a.gesendet[0].text, 'https://site.example.org/auth/neues-passwort?token_hash=')
})

Deno.test('unbekannte Art -> 400 mit definiertem Fehler, protokolliert, nichts versendet', async () => {
  const a = aufbau()
  const r = await hookBearbeiten(await anfrage(nutzlast('sms_otp')), a.deps)
  assertEquals(r.status, 400)
  assertEquals(await r.json(), { error: { http_code: 400, message: 'unbekannte Mailart: sms_otp' } })
  assertEquals(a.gesendet.length, 0)
  assertEquals(a.protokoll.length, 1)
  assertEquals(a.protokoll[0].art, 'unbekannt')
  protokollSauber(a.protokoll)
})

Deno.test('Versandfehler -> 502, Protokoll mit Fehler, aber ohne Token und Link', async () => {
  const a = aufbau(async (m) => {
    // Ein Versandweg, der den Mailtext in die Fehlermeldung schreibt — der schlimmste Fall.
    throw new Error(`Graph sendMail 500: ${m.text}`)
  })
  const r = await hookBearbeiten(await anfrage(nutzlast('recovery')), a.deps)
  assertEquals(r.status, 502)
  assertEquals(a.protokoll.length, 1)
  assert(a.protokoll[0].fehler?.startsWith('Graph sendMail 500'))
  protokollSauber(a.protokoll)
  assert(!(await r.text()).includes(HASH), 'auch die Antwort an Auth traegt den Token nicht')
})

Deno.test('signup und magiclink: Link auf /auth/bestaetigen mit passendem type', async () => {
  for (const art of ['signup', 'magiclink']) {
    const a = aufbau()
    assertEquals((await hookBearbeiten(await anfrage(nutzlast(art)), a.deps)).status, 200)
    assertStringIncludes(a.gesendet[0].text, `/auth/bestaetigen?token_hash=${HASH}&type=${art}`)
    protokollSauber(a.protokoll)
  }
})

Deno.test('reauthentication: nur der Code, kein Link', async () => {
  const a = aufbau()
  assertEquals((await hookBearbeiten(await anfrage(nutzlast('reauthentication')), a.deps)).status, 200)
  assertStringIncludes(a.gesendet[0].text, `    ${TOKEN}\n`)
  assert(!a.gesendet[0].text.includes('http'))
  protokollSauber(a.protokoll)
})

Deno.test('email_change sicher: je eine Mail an alte und neue Adresse mit eigenem Token', async () => {
  const a = aufbau()
  const r = await hookBearbeiten(await anfrage(nutzlast('email_change', { token_hash_new: HASH_NEU })), a.deps)
  assertEquals(r.status, 200)
  assertEquals(a.gesendet.map((m) => m.an), ['zz-coach@example.org', 'zz-neu@example.org'])
  assertStringIncludes(a.gesendet[0].text, `token_hash=${HASH}&type=email_change`)
  assertStringIncludes(a.gesendet[1].text, `token_hash=${HASH_NEU}&type=email_change`)
  assertEquals(a.protokoll.length, 2)
  protokollSauber(a.protokoll)
})

Deno.test('ohne Namen: schlichte Anrede', async () => {
  const a = aufbau()
  const rumpf = nutzlast('recovery').replace('"user_metadata":{"full_name":"ZZ Mia Coach"}', '"user_metadata":{}')
  await hookBearbeiten(await anfrage(rumpf), a.deps)
  assert(a.gesendet[0].text.startsWith('Guten Tag,\n'))
})
