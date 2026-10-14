// K1b: Beim Vertragsabschluss entsteht nur das Schuelerkonto, kein Eltern-Konto.
//
// Geprueft:
//   - schuelerkontoAnlegen legt genau ein Konto an: bestaetigt, mit Passwort,
//     Adresse student.<uuid>@edvance.invalid — nie die Elternadresse
//   - abschlussParameter schickt p_parent_uid und p_parent_email immer als null,
//     reicht alle uebrigen Felder durch (vor Ort und Papier)
//   - ohne neues Konto (Folgevertrag) gehen auch die Schueler-Parameter als null
//
// Lauf:  npx deno@2 test supabase/functions/vertrag_abschluss/

import { assert, assertEquals, assertMatch } from 'https://deno.land/std@0.224.0/assert/mod.ts'
import type { SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { abschlussParameter, schuelerkontoAnlegen, type AbschlussBody } from './konten.ts'

type Anlage = { email: string; password?: string; email_confirm?: boolean }

function attrappe(fehler: string | null = null) {
  const angelegt: Anlage[] = []
  const admin = {
    auth: {
      admin: {
        createUser: async (a: Anlage) => {
          angelegt.push(a)
          return fehler
            ? { data: { user: null }, error: { message: fehler } }
            : { data: { user: { id: `uid-${angelegt.length}` } }, error: null }
        },
      },
    },
  } as unknown as Pick<SupabaseClient, 'auth'>
  return { admin, angelegt }
}

Deno.test('schuelerkontoAnlegen: genau ein Konto, bestaetigt, mit Passwort, keine Elternadresse', async () => {
  const { admin, angelegt } = attrappe()
  const r = await schuelerkontoAnlegen(admin)
  assert(!('fehler' in r))
  assertEquals(angelegt.length, 1)
  assertMatch(angelegt[0].email, /^student\.[0-9a-f-]{36}@edvance\.invalid$/)
  assertEquals(angelegt[0].email_confirm, true)
  assert((angelegt[0].password ?? '').length >= 40, 'Zufallspasswort gesetzt')
  assertEquals(r, { uid: 'uid-1', email: angelegt[0].email })
})

Deno.test('schuelerkontoAnlegen: Fehler der Auth-API wird gemeldet', async () => {
  const { admin } = attrappe('Database error creating new user')
  assertEquals(await schuelerkontoAnlegen(admin), { fehler: 'Schueler-Account: Database error creating new user' })
})

const VOR_ORT: AbschlussBody = {
  vertrag_id: 'v-1',
  weg: 'vor_ort',
  zustimmungen: [{ schluessel: 'pilotvereinbarung', version: 'platzhalter-v1' }],
  signatur_vertrag: 'sig',
}

const PAPIER: AbschlussBody = {
  vertrag_id: 'v-2',
  weg: 'papier',
  unterschrieben_am: '2027-10-20',
  eingang_datum: '2027-10-22',
  scan_pfad: 'v-2/scan.pdf',
  abweichung_vermerk: 'Telefonnummer korrigiert',
}

Deno.test('abschlussParameter vor Ort: Eltern null, Schuelerkonto und Felder durchgereicht', () => {
  const p = abschlussParameter(VOR_ORT, { uid: 'uid-1', email: 'student.x@edvance.invalid' })
  assertEquals(p.p_parent_uid, null)
  assertEquals(p.p_parent_email, null)
  assertEquals(p.p_student_uid, 'uid-1')
  assertEquals(p.p_student_email, 'student.x@edvance.invalid')
  assertEquals(p.p_weg, 'vor_ort')
  assertEquals(p.p_signatur_vertrag, 'sig')
  assertEquals(p.p_signatur_sepa, null)
  assertEquals(p.p_zustimmungen, VOR_ORT.zustimmungen)
})

Deno.test('abschlussParameter Papier: Eltern null, Scan und Daten durchgereicht', () => {
  const p = abschlussParameter(PAPIER, { uid: 'uid-2', email: 'student.y@edvance.invalid' })
  assertEquals(p.p_parent_uid, null)
  assertEquals(p.p_parent_email, null)
  assertEquals(
    [p.p_unterschrieben_am, p.p_eingang_datum, p.p_scan_pfad, p.p_abweichung_vermerk],
    ['2027-10-20', '2027-10-22', 'v-2/scan.pdf', 'Telefonnummer korrigiert'],
  )
  assertEquals(p.p_zustimmungen, [])
})

Deno.test('abschlussParameter ohne neues Konto (Folgevertrag): alle Konto-Parameter null', () => {
  const p = abschlussParameter(VOR_ORT, null)
  assertEquals([p.p_student_uid, p.p_student_email, p.p_parent_uid, p.p_parent_email], [null, null, null, null])
})

Deno.test('abschlussParameter: genau die 16 Parameter von vertrag_abschliessen', () => {
  assertEquals(Object.keys(abschlussParameter(PAPIER, null)).sort(), [
    'p_abweichung_vermerk', 'p_eingang_datum', 'p_laufzeit_monate', 'p_parent_email', 'p_parent_uid',
    'p_scan_pfad', 'p_signatur_sepa', 'p_signatur_vertrag', 'p_student_email', 'p_student_uid',
    'p_tier_id', 'p_unterschrieben_am', 'p_vertrag_id', 'p_vertragsbeginn', 'p_weg', 'p_zustimmungen',
  ])
})
