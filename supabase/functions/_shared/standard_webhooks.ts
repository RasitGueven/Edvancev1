// Signaturpruefung nach Standard Webhooks (https://www.standardwebhooks.com),
// so wie Supabase Auth den Send Email Hook signiert.
//
// Ohne Fremdpaket: die Pruefung ist ein HMAC-SHA256 ueber
// "<webhook-id>.<webhook-timestamp>.<roher Rumpf>", und genau diese wenigen
// Zeilen sollen lesbar und getestet hier stehen statt in einem Paket von esm.sh.
//
// Fail-closed: jede fehlende oder unlesbare Angabe ist "ungueltig".

/** Wie weit der Zeitstempel von jetzt abweichen darf (wie die Referenz: 5 Minuten). */
export const TOLERANZ_SEKUNDEN = 5 * 60

/**
 * Das Secret, wie das Dashboard es anzeigt: "v1,whsec_<base64>". Auch ohne
 * "v1," oder ohne "whsec_" angenommen. null, wenn danach nichts Lesbares bleibt.
 */
export function schluesselAusSecret(secret: string | undefined | null): Uint8Array | null {
  if (!secret) return null
  const roh = secret.trim().replace(/^v1,/, '').replace(/^whsec_/, '')
  if (roh === '') return null
  try {
    return Uint8Array.from(atob(roh), (c) => c.charCodeAt(0))
  } catch {
    return null
  }
}

function base64(bytes: ArrayBuffer): string {
  return btoa(String.fromCharCode(...new Uint8Array(bytes)))
}

/** Vergleich ohne fruehen Ausstieg, damit die Laufzeit nichts ueber die Signatur verraet. */
function gleich(a: string, b: string): boolean {
  if (a.length !== b.length) return false
  let d = 0
  for (let i = 0; i < a.length; i++) d |= a.charCodeAt(i) ^ b.charCodeAt(i)
  return d === 0
}

export async function signieren(
  schluessel: Uint8Array,
  id: string,
  zeitstempel: string,
  rumpf: string,
): Promise<string> {
  const key = await crypto.subtle.importKey('raw', new Uint8Array(schluessel), { name: 'HMAC', hash: 'SHA-256' }, false, [
    'sign',
  ])
  const sig = await crypto.subtle.sign('HMAC', key, new TextEncoder().encode(`${id}.${zeitstempel}.${rumpf}`))
  return base64(sig)
}

export type Pruefung = { ok: true } | { ok: false; grund: string }

/**
 * Prueft die drei Kopfzeilen gegen den rohen Rumpf. Der Rumpf muss genau der
 * sein, der ankam — vor jedem JSON.parse.
 */
export async function signaturPruefen(
  kopf: Headers,
  rumpf: string,
  schluessel: Uint8Array | null,
  jetztSekunden: number = Math.floor(Date.now() / 1000),
): Promise<Pruefung> {
  if (!schluessel) return { ok: false, grund: 'kein Secret eingerichtet' }
  const id = kopf.get('webhook-id')
  const zeit = kopf.get('webhook-timestamp')
  const signaturen = kopf.get('webhook-signature')
  if (!id || !zeit || !signaturen) return { ok: false, grund: 'Signatur-Kopfzeilen fehlen' }

  if (!/^\d+$/.test(zeit)) return { ok: false, grund: 'Zeitstempel unlesbar' }
  if (Math.abs(jetztSekunden - Number(zeit)) > TOLERANZ_SEKUNDEN) {
    return { ok: false, grund: 'Zeitstempel ausserhalb der Toleranz' }
  }

  const erwartet = await signieren(schluessel, id, zeit, rumpf)
  // Mehrere Signaturen durch Leerzeichen getrennt, je "v1,<base64>".
  for (const teil of signaturen.split(' ')) {
    const [version, wert] = teil.split(',', 2)
    if (version === 'v1' && wert && gleich(wert, erwartet)) return { ok: true }
  }
  return { ok: false, grund: 'Signatur passt nicht' }
}
