// Die Terminbestaetigung auf der Edge-Seite — mit gemocktem Versand.
//
// fetch ist gestubbt: die Anmeldung bei Microsoft und sendMail laufen gegen
// eine Attrappe, keine Mail verlaesst die Maschine. Die Supabase-Clients sind
// Attrappen mit genau den Aufrufen, die termin.ts macht.
//
// Geprueft: derselbe Text wie in der Vorschau (src/lib/terminBestaetigung.test.ts),
// Empfaenger aus dem Lead, Ort ist Pflicht und steht in Mail und Protokoll,
// Protokoll auch bei Fehler.
//
// Lauf:  npx deno test --allow-env --allow-net supabase/functions/mail_senden/termin_test.ts

import { assert, assertEquals, assertStringIncludes } from 'https://deno.land/std@0.224.0/assert/mod.ts'
import type { SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { terminBestaetigung } from './termin.ts'

const LEAD = {
  id: 'ZZ_lead',
  full_name: 'ZZ_Tim Beispiel',
  first_name: 'ZZ_Tim',
  contact_email: 'zz@example.org',
  erstgespraech_at: '2026-10-08T14:00:00.000Z',
}

type Gesendet = { an: string; betreff: string; text: string }

function attrappen(lead: Record<string, unknown> | null) {
  const protokoll: Record<string, unknown>[] = []
  const admin = {
    from: () => {
      const q = {
        select: () => q,
        eq: () => q,
        single: () => Promise.resolve(lead ? { data: lead, error: null } : { data: null, error: { message: 'x' } }),
      }
      return q
    },
  } as unknown as SupabaseClient
  const caller = {
    rpc: (name: string, args: Record<string, unknown>) => {
      protokoll.push({ name, ...args })
      return Promise.resolve({ data: 'ZZ_id', error: null })
    },
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
    gesendet.push({ an: m.toRecipients[0].emailAddress.address, betreff: m.subject, text: m.body.content })
    return Promise.resolve(new Response(sendStatus === 202 ? null : '{"message":"ZZ verweigert"}', { status: sendStatus }))
  }) as typeof fetch
  return { gesendet, zurueck: () => { globalThis.fetch = echt } }
}

const ORT = 'ZZ_Musterweg 1, 50667 Köln'

for (const [fall, ort] of [['ohne Ort', undefined], ['mit leerem Ort', '   '], ['mit zu langem Ort', 'x'.repeat(301)]] as const) {
  Deno.test(`sperrt ${fall} — ohne Versand, ohne Protokoll`, async () => {
    const { admin, caller, protokoll } = attrappen(LEAD)
    const g = graphStub(202)
    try {
      const r = await terminBestaetigung(admin, caller, 'ZZ_lead', ort)
      assertEquals(r.status, 400)
      assertEquals(g.gesendet.length + protokoll.length, 0)
    } finally {
      g.zurueck()
    }
  })
}

Deno.test('sendet an die Eltern-Mail des Leads und protokolliert Termin und Ort', async () => {
  const { admin, caller, protokoll } = attrappen(LEAD)
  const g = graphStub(202)
  try {
    const r = await terminBestaetigung(admin, caller, 'ZZ_lead', `  ${ORT} `)
    assertEquals(r.status, 200)
    assertEquals(g.gesendet.length, 1)
    const m = g.gesendet[0]
    assertEquals(m.an, 'zz@example.org')
    assertEquals(m.betreff, 'Ihr Erstgespräch bei Edvance am Donnerstag, 8. Oktober 2026')
    assertStringIncludes(m.text, 'Termin: Donnerstag, 8. Oktober 2026, 16:00 Uhr')
    assertStringIncludes(m.text, `Ort: ${ORT}\n`)
    assertStringIncludes(m.text, 'Dauer: etwa 60 Minuten – Gespräch und eine 20-minütige Lernstandsanalyse am Tablet')
    assertStringIncludes(m.text, 'Hausaufgabenheft')
    assertEquals(protokoll[0].name, 'lead_mail_protokollieren')
    assertEquals(protokoll[0].p_ort, ORT)
    assertEquals(protokoll[0].p_termin_at, LEAD.erstgespraech_at)
    assertEquals(protokoll[0].p_fehler, null)
  } finally {
    g.zurueck()
  }
})

Deno.test('ein gescheiterter Versand wird ebenfalls protokolliert, mit Ort', async () => {
  const { admin, caller, protokoll } = attrappen(LEAD)
  const g = graphStub(403)
  try {
    const r = await terminBestaetigung(admin, caller, 'ZZ_lead', ORT)
    assertEquals(r.status, 502)
    assert(String(protokoll[0].p_fehler).includes('403'))
    assertEquals(protokoll[0].p_ort, ORT)
  } finally {
    g.zurueck()
  }
})

Deno.test('ohne Eltern-Mail kein Versand', async () => {
  const { admin, caller, protokoll } = attrappen({ ...LEAD, contact_email: null })
  const g = graphStub(202)
  try {
    const r = await terminBestaetigung(admin, caller, 'ZZ_lead', ORT)
    assertEquals(r.status, 400)
    assertEquals(g.gesendet.length + protokoll.length, 0)
  } finally {
    g.zurueck()
  }
})
