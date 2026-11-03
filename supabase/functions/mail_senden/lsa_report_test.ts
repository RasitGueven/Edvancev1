// Der LSA-Report per Mail auf der Edge-Seite — mit gemocktem Versand (LR-2).
//
// fetch ist gestubbt wie in termin_test.ts: Anmeldung bei Microsoft und sendMail
// laufen gegen eine Attrappe, keine Mail verlaesst die Maschine. Die Supabase-
// Clients sind Attrappen mit genau den Aufrufen, die lsa_report.ts und
// zugang.ts machen.
//
// Geprueft: fremder Pfad, nicht auswertbar, Lead ohne Mail → 400 ohne Versand
// und ohne Protokoll; Nicht-Admin → 403; Erfolg → Anhang, Empfaenger aus dem
// Lead, Protokoll mit SHA-256; Graph-Fehler → 502 und trotzdem protokolliert;
// Testlauf → "[Test] " im Betreff.
//
// Lauf:  npx deno test --allow-env --allow-net supabase/functions/mail_senden/lsa_report_test.ts

import { assert, assertEquals, assertStringIncludes } from 'https://deno.land/std@0.224.0/assert/mod.ts'
import type { SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { lsaReport } from './lsa_report.ts'
import { nurAdmin } from './zugang.ts'

const SID = '0f0e0d0c-0b0a-4908-8706-050403020100'
const ANDERE = '1f1e1d1c-1b1a-4918-8716-151413121110'
const PFAD = `${SID}/20261103-101500.pdf`
const PDF = new TextEncoder().encode('%PDF-1.3 ZZ')
// sha256('%PDF-1.3 ZZ')
const PDF_SHA = '2956b59aeae6a0ae980de9b114247a43b1615f857b5709a68b3e632d8acbf5d5'

const SITZUNG = {
  id: SID,
  student_id: 'ZZ_student',
  status: 'completed',
  auswertbar: true,
  testlauf: false,
  completed_at: '2026-10-24T08:30:00.000Z',
  started_at: '2026-10-24T08:00:00.000Z',
  created_at: '2026-10-24T07:55:00.000Z',
}
const LEAD = { id: 'ZZ_lead', full_name: 'ZZ_Ilkay Beispiel', first_name: 'ZZ_Ilkay', contact_email: 'zz@example.org' }

type Gesendet = { an: string; betreff: string; text: string; anhaenge: { name: string; contentType: string }[] }

function attrappen(
  over: { sitzung?: Record<string, unknown> | null; lead?: Record<string, unknown> | null; datei?: boolean; rolle?: string } = {},
) {
  const sitzung = over.sitzung === undefined ? SITZUNG : over.sitzung
  const lead = over.lead === undefined ? LEAD : over.lead
  const protokoll: Record<string, unknown>[] = []
  const zeile = (wert: unknown) => Promise.resolve(wert ? { data: wert, error: null } : { data: null, error: { message: 'x' } })
  const admin = {
    from: (tabelle: string) => {
      const wert = tabelle === 'lsa_sessions' ? sitzung : tabelle === 'leads' ? lead : { role: over.rolle ?? 'admin' }
      const q = { select: () => q, eq: () => q, single: () => zeile(wert), maybeSingle: () => zeile(wert) }
      return q
    },
    rpc: () => Promise.resolve({ data: lead ? 'ZZ_lead' : null, error: null }),
    storage: {
      from: () => ({
        download: () =>
          Promise.resolve(over.datei === false ? { data: null, error: { message: 'Object not found' } } : { data: new Blob([PDF]), error: null }),
      }),
    },
  } as unknown as SupabaseClient
  const caller = {
    rpc: (name: string, args: Record<string, unknown>) => {
      protokoll.push({ name, ...args })
      return Promise.resolve({ data: 'ZZ_id', error: null })
    },
    auth: { getUser: () => Promise.resolve({ data: { user: { id: 'ZZ_user' } }, error: null }) },
  } as unknown as SupabaseClient
  return { admin, caller, protokoll }
}

function graphStub(sendStatus: number): { gesendet: Gesendet[]; zurueck: () => void } {
  const gesendet: Gesendet[] = []
  const echt = globalThis.fetch
  Deno.env.set('MS_TENANT_ID', 'zz')
  Deno.env.set('MS_CLIENT_ID', 'zz')
  Deno.env.set('MS_CLIENT_SECRET', 'zz')
  globalThis.fetch = ((url: string | URL, init?: RequestInit) => {
    const u = String(url)
    if (u.includes('login.microsoftonline.com')) {
      return Promise.resolve(new Response(JSON.stringify({ access_token: 'zz', expires_in: 3600 })))
    }
    const m = JSON.parse(String(init?.body)).message
    gesendet.push({
      an: m.toRecipients[0].emailAddress.address,
      betreff: m.subject,
      text: m.body.content,
      anhaenge: (m.attachments ?? []).map((a: { name: string; contentType: string }) => ({ name: a.name, contentType: a.contentType })),
    })
    return Promise.resolve(new Response(sendStatus === 202 ? null : '{"message":"ZZ verweigert"}', { status: sendStatus }))
  }) as typeof fetch
  return { gesendet, zurueck: () => { globalThis.fetch = echt } }
}

function ohneVersand(
  fall: string,
  over: Parameters<typeof attrappen>[0],
  pfad: string,
  meldung: string,
): void {
  Deno.test(`${fall} → 400, ohne Versand und ohne Protokoll`, async () => {
    const { admin, caller, protokoll } = attrappen(over)
    const g = graphStub(202)
    try {
      const r = await lsaReport(admin, caller, SID, pfad)
      assertEquals(r.status, 400)
      assertStringIncludes(String(r.payload.error), meldung)
      assertEquals(g.gesendet.length + protokoll.length, 0)
    } finally {
      g.zurueck()
    }
  })
}

ohneVersand('fremder Pfad (andere Sitzung)', {}, `${ANDERE}/20261103-101500.pdf`, 'nicht zu dieser Sitzung')
ohneVersand('Pfad mit ..', {}, `${SID}/../${ANDERE}/20261103-101500.pdf`, 'nicht zu dieser Sitzung')
ohneVersand('nicht auswertbar', { sitzung: { ...SITZUNG, auswertbar: false } }, PFAD, 'nicht auswertbar')
ohneVersand('nicht abgeschlossen', { sitzung: { ...SITZUNG, status: 'in_progress' } }, PFAD, 'nicht abgeschlossen')
ohneVersand('Lead ohne Mail', { lead: { ...LEAD, contact_email: '  ' } }, PFAD, 'Keine Eltern-Mail')
ohneVersand('ohne Lead', { lead: null }, PFAD, 'kein Lead')
ohneVersand('Datei fehlt im Bucket', { datei: false }, PFAD, 'nicht im Speicher')

Deno.test('Nicht-Admin → 403', async () => {
  const { admin, caller } = attrappen({ rolle: 'coach' })
  assertEquals(await nurAdmin(admin, caller), { status: 403, error: 'Nur Admin darf versenden' })
  const adminRolle = attrappen({ rolle: 'admin' })
  assertEquals(await nurAdmin(adminRolle.admin, adminRolle.caller), null)
})

Deno.test('sendet das PDF an die Eltern-Mail des Leads und protokolliert mit SHA-256', async () => {
  const { admin, caller, protokoll } = attrappen()
  const g = graphStub(202)
  try {
    const r = await lsaReport(admin, caller, SID, PFAD)
    assertEquals(r.status, 200)
    assertEquals(r.payload.an, 'zz@example.org')
    assertEquals(r.payload.bytes, PDF.length)
    assertEquals(g.gesendet.length, 1)
    const m = g.gesendet[0]
    assertEquals(m.an, 'zz@example.org')
    assertEquals(m.betreff, 'Lernstandsanalyse von ZZ_Ilkay – Ihr Bericht')
    assertStringIncludes(m.text, 'Bericht zur Lernstandsanalyse von ZZ_Ilkay vom 24.10.2026.')
    assertStringIncludes(m.text, 'antworten Sie einfach auf diese Mail')
    assertEquals(m.anhaenge, [{ name: 'Edvance LSA-Report ZZ_Ilkay 24.10.2026.pdf', contentType: 'application/pdf' }])
    assertEquals(protokoll.length, 1)
    assertEquals(protokoll[0].name, 'lead_mail_protokollieren')
    assertEquals(protokoll[0].p_lead_id, 'ZZ_lead')
    assertEquals(protokoll[0].p_anlass, 'lsa_report')
    assertEquals(protokoll[0].p_lsa_session_id, SID)
    assertEquals(protokoll[0].p_anhang_pfad, PFAD)
    assertEquals(protokoll[0].p_anhang_sha256, PDF_SHA)
    assertEquals(protokoll[0].p_fehler, null)
    assertEquals('p_ort' in protokoll[0], false)
  } finally {
    g.zurueck()
  }
})

Deno.test('Graph-Fehler → 502, trotzdem protokolliert', async () => {
  const { admin, caller, protokoll } = attrappen()
  const g = graphStub(403)
  try {
    const r = await lsaReport(admin, caller, SID, PFAD)
    assertEquals(r.status, 502)
    assertEquals(protokoll.length, 1)
    assert(String(protokoll[0].p_fehler).includes('403'))
    assertEquals(protokoll[0].p_anhang_sha256, PDF_SHA)
  } finally {
    g.zurueck()
  }
})

Deno.test('Testlauf: Versand erlaubt, Betreff mit [Test]', async () => {
  const { admin, caller } = attrappen({ sitzung: { ...SITZUNG, testlauf: true } })
  const g = graphStub(202)
  try {
    const r = await lsaReport(admin, caller, SID, PFAD)
    assertEquals(r.status, 200)
    assertEquals(g.gesendet[0].betreff, '[Test] Lernstandsanalyse von ZZ_Ilkay – Ihr Bericht')
  } finally {
    g.zurueck()
  }
})
