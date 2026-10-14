// Die eigene Signaturpruefung gegen die Referenzbibliothek der Spezifikation
// (npm:standardwebhooks, die auch die Supabase-Doku fuer den Send Email Hook
// nimmt). Signiert die Referenz, muss unsere Pruefung annehmen; signieren
// wir, muss die Referenz annehmen. Nur im Test geladen, nicht in der Function.
//
// Lauf:  npx deno@2 test supabase/functions/_shared/standard_webhooks_test.ts

import { assert, assertEquals } from 'https://deno.land/std@0.224.0/assert/mod.ts'
import { Webhook } from 'npm:standardwebhooks@1.0.0'
import { schluesselAusSecret, signaturPruefen, signieren } from './standard_webhooks.ts'

const ROH = btoa('zz-k1-referenzschluessel-fuer-den-test')
const SECRET = `v1,whsec_${ROH}`
const RUMPF = '{"user":{"id":"zz"},"email_data":{"email_action_type":"invite"}}'

Deno.test('Referenz signiert, unsere Pruefung nimmt an', async () => {
  const jetzt = new Date()
  const ref = new Webhook(ROH)
  const sig = ref.sign('msg_zz', jetzt, RUMPF)
  const kopf = new Headers({
    'webhook-id': 'msg_zz',
    'webhook-timestamp': String(Math.floor(jetzt.getTime() / 1000)),
    'webhook-signature': sig,
  })
  assertEquals(await signaturPruefen(kopf, RUMPF, schluesselAusSecret(SECRET)), { ok: true })
  // Ein anderes Secret darf nicht passen.
  const fremd = schluesselAusSecret(`v1,whsec_${btoa('ein-ganz-anderer-schluessel')}`)
  assertEquals((await signaturPruefen(kopf, RUMPF, fremd)).ok, false)
})

Deno.test('wir signieren, die Referenz nimmt an', async () => {
  const zeit = String(Math.floor(Date.now() / 1000))
  const sig = await signieren(schluesselAusSecret(SECRET)!, 'msg_zz2', zeit, RUMPF)
  const ref = new Webhook(ROH)
  const payload = ref.verify(RUMPF, {
    'webhook-id': 'msg_zz2',
    'webhook-timestamp': zeit,
    'webhook-signature': `v1,${sig}`,
  })
  assert(payload)
})

Deno.test('mehrere Signaturen: eine passende genuegt', async () => {
  const zeit = String(Math.floor(Date.now() / 1000))
  const s = schluesselAusSecret(SECRET)!
  const sig = await signieren(s, 'msg_zz3', zeit, RUMPF)
  const kopf = new Headers({
    'webhook-id': 'msg_zz3',
    'webhook-timestamp': zeit,
    'webhook-signature': `v1,${btoa('alt')} v1,${sig}`,
  })
  assertEquals(await signaturPruefen(kopf, RUMPF, s), { ok: true })
})

Deno.test('Secret-Formen', () => {
  assertEquals(schluesselAusSecret(undefined), null)
  assertEquals(schluesselAusSecret(''), null)
  assertEquals(schluesselAusSecret('v1,whsec_'), null)
  assertEquals(schluesselAusSecret('v1,whsec_%%%'), null)
  assertEquals(schluesselAusSecret(SECRET), schluesselAusSecret(`whsec_${ROH}`))
})
