// coach_einladen ohne Netz: Auth-Admin-API und profiles sind Attrappen, die
// sich wie Supabase verhalten (ein Konto je Adresse, unbestaetigt bis zur Annahme).
//
// Geprueft (Auftrag K1, Test 3):
//   - kein JWT -> 401, Coach-JWT -> 403, ohne Profil -> 403
//   - Admin -> Einladung mit redirectTo /auth/einladung und full_name + Profil role coach
//   - doppelte Mail -> 409 email_vergeben, kein zweites Konto, keine Einladung
//   - Profil-Fehler -> Konto wieder geloescht
//   - erneut: nur fuer unbestaetigte Coach-Konten
//
// Lauf:  npx deno@2 test supabase/functions/coach_einladen/

import { assertEquals } from 'https://deno.land/std@0.224.0/assert/mod.ts'
import { einladenBearbeiten, einladungsZiel, type Dienste, type Konto } from './einladen.ts'

const SERVICE = 'zz-service-key'
const ADMIN_JWT = 'Bearer zz-admin-jwt'
const COACH_JWT = 'Bearer zz-coach-jwt'
const OHNE_JWT = 'Bearer zz-ohne-profil-jwt'

type Einladung = { email: string; redirectTo: string; full_name: string }

function welt(opts: { profilFehler?: string } = {}) {
  const konten = new Map<string, Konto>([
    ['u-admin', { id: 'u-admin', email: 'zz-admin@example.org', bestaetigt: true, name: 'ZZ Admin' }],
    ['u-coach', { id: 'u-coach', email: 'zz-coach@example.org', bestaetigt: true, name: 'ZZ Coach' }],
    ['u-offen', { id: 'u-offen', email: 'zz-offen@example.org', bestaetigt: false, name: 'ZZ Offen' }],
    ['u-ohne', { id: 'u-ohne', email: 'zz-ohne@example.org', bestaetigt: true, name: '' }],
  ])
  const profile = new Map<string, string>([
    ['u-admin', 'admin'],
    ['u-coach', 'coach'],
    ['u-offen', 'coach'],
  ])
  const einladungen: Einladung[] = []
  const geloescht: string[] = []
  let n = 0

  const d: Dienste = {
    serviceKey: SERVICE,
    appUrl: 'https://studio.example.org',
    aufrufer: async (h) =>
      ({ [ADMIN_JWT]: { id: 'u-admin' }, [COACH_JWT]: { id: 'u-coach' }, [OHNE_JWT]: { id: 'u-ohne' } })[h] ?? null,
    rolle: async (uid) => profile.get(uid) ?? null,
    emailVorhanden: async (email) => [...konten.values()].some((k) => k.email === email),
    einladen: async (email, o) => {
      einladungen.push({ email, redirectTo: o.redirectTo, full_name: o.data.full_name })
      const da = [...konten.values()].find((k) => k.email === email)
      if (da?.bestaetigt) return { fehler: 'A user with this email address has already been registered', code: 'email_exists' }
      if (da) return { id: da.id }
      const id = `u-neu-${++n}`
      konten.set(id, { id, email, bestaetigt: false, name: o.data.full_name })
      return { id }
    },
    profilSchreiben: async (p) => {
      if (opts.profilFehler) return opts.profilFehler
      profile.set(p.id, p.role)
      return null
    },
    loeschen: async (uid) => {
      geloescht.push(uid)
      konten.delete(uid)
    },
    konto: async (uid) => konten.get(uid) ?? null,
  }
  return { d, konten, profile, einladungen, geloescht }
}

const NEU = { aktion: 'neu', vorname: ' ZZ Mia ', nachname: 'Beispiel', email: ' ZZ-Mia@Example.org ' }

Deno.test('kein JWT -> 401, nichts eingeladen', async () => {
  const w = welt()
  assertEquals((await einladenBearbeiten('', NEU, w.d)).status, 401)
  assertEquals((await einladenBearbeiten('Bearer unbekannt', NEU, w.d)).status, 401)
  assertEquals(w.einladungen.length, 0)
})

Deno.test('Coach-JWT -> 403, Konto ohne Profil -> 403', async () => {
  const w = welt()
  const r = await einladenBearbeiten(COACH_JWT, NEU, w.d)
  assertEquals(r.status, 403)
  assertEquals(r.payload.code, 'kein_admin')
  assertEquals((await einladenBearbeiten(OHNE_JWT, NEU, w.d)).status, 403)
  assertEquals(w.einladungen.length, 0)
})

Deno.test('Admin -> Einladung mit redirectTo und full_name, Profil role coach', async () => {
  const w = welt()
  const r = await einladenBearbeiten(ADMIN_JWT, NEU, w.d)
  assertEquals(r.status, 200)
  assertEquals(w.einladungen, [
    { email: 'zz-mia@example.org', redirectTo: 'https://studio.example.org/auth/einladung', full_name: 'ZZ Mia Beispiel' },
  ])
  const id = r.payload.coach_id as string
  assertEquals(w.profile.get(id), 'coach')
  assertEquals(w.konten.get(id)?.bestaetigt, false)
})

Deno.test('Service-Role-Bearer ist wie bei provision_coach zugelassen', async () => {
  const w = welt()
  assertEquals((await einladenBearbeiten(`Bearer ${SERVICE}`, NEU, w.d)).status, 200)
})

Deno.test('doppelte Mail -> 409 email_vergeben, kein zweites Konto, keine Einladung', async () => {
  for (const email of ['zz-coach@example.org', 'zz-offen@example.org', 'ZZ-COACH@example.org']) {
    const w = welt()
    const vorher = w.konten.size
    const r = await einladenBearbeiten(ADMIN_JWT, { ...NEU, email }, w.d)
    assertEquals(r.status, 409, email)
    assertEquals(r.payload.code, 'email_vergeben')
    assertEquals(w.konten.size, vorher)
    assertEquals(w.einladungen.length, 0, 'eine unbestaetigte fremde Adresse bekommt keine neue Einladung')
  }
})

Deno.test('Profil-Fehler -> Konto wieder geloescht', async () => {
  const w = welt({ profilFehler: 'profiles: violates check constraint' })
  const vorher = w.konten.size
  const r = await einladenBearbeiten(ADMIN_JWT, NEU, w.d)
  assertEquals(r.status, 500)
  assertEquals(r.payload.code, 'profil_fehlgeschlagen')
  assertEquals(w.geloescht.length, 1)
  assertEquals(w.konten.size, vorher)
})

Deno.test('Eingaben: Name, Mail und Aktion sind Pflicht', async () => {
  const w = welt()
  for (const body of [
    { ...NEU, vorname: '' },
    { ...NEU, nachname: '  ' },
    { ...NEU, email: 'keine-mail' },
    { ...NEU, aktion: undefined },
    { ...NEU, password: 'egal', aktion: 'anlegen' },
  ]) {
    assertEquals((await einladenBearbeiten(ADMIN_JWT, body, w.d)).status, 400)
  }
  assertEquals(w.einladungen.length, 0)
})

Deno.test('erneut: unbestaetigter Coach bekommt eine neue Einladung', async () => {
  const w = welt()
  const r = await einladenBearbeiten(ADMIN_JWT, { aktion: 'erneut', coach_id: 'u-offen' }, w.d)
  assertEquals(r.status, 200)
  assertEquals(w.einladungen, [
    { email: 'zz-offen@example.org', redirectTo: 'https://studio.example.org/auth/einladung', full_name: 'ZZ Offen' },
  ])
})

Deno.test('erneut: aktives Konto -> 409, Nicht-Coach -> 404, Coach-JWT -> 403', async () => {
  const w = welt()
  assertEquals((await einladenBearbeiten(ADMIN_JWT, { aktion: 'erneut', coach_id: 'u-coach' }, w.d)).payload.code, 'schon_aktiv')
  assertEquals((await einladenBearbeiten(ADMIN_JWT, { aktion: 'erneut', coach_id: 'u-admin' }, w.d)).status, 404)
  assertEquals((await einladenBearbeiten(ADMIN_JWT, { aktion: 'erneut', coach_id: 'u-weg' }, w.d)).status, 404)
  assertEquals((await einladenBearbeiten(COACH_JWT, { aktion: 'erneut', coach_id: 'u-offen' }, w.d)).status, 403)
  assertEquals(w.einladungen.length, 0)
})

Deno.test('Ziel der Einladung: immer /auth/einladung am Ursprung', () => {
  assertEquals(einladungsZiel('https://studio.example.org/x?y=1', 'https://boese.example'), 'https://studio.example.org/auth/einladung')
  assertEquals(einladungsZiel(undefined, 'http://localhost:5173/auth/einladung'), 'http://localhost:5173/auth/einladung')
  assertEquals(einladungsZiel(undefined, 'javascript:alert(1)'), null)
  assertEquals(einladungsZiel(undefined, undefined), null)
})
