// Mailversand ueber Microsoft Graph, Client-Credentials-Flow.
//
// Kein SMTP-Passwort, kein Postfach-Login: die Edge Function meldet sich als
// registrierte Anwendung an und darf per Exchange-Richtlinie ausschliesslich
// aus hello@edvanceacademy.de senden. Faellt das Secret in falsche Haende,
// ist der Schaden auf genau dieses eine Postfach begrenzt — und die
// Berechtigung laesst sich in Entra entziehen, ohne ein Passwort zu aendern,
// das anderswo auch gilt.
//
// Secrets: MS_TENANT_ID, MS_CLIENT_ID, MS_CLIENT_SECRET. Sie stehen in den
// Supabase-Secrets und werden nirgends geloggt.

export const ABSENDER = 'hello@edvanceacademy.de'

const SCOPE = 'https://graph.microsoft.com/.default'

export type Anhang = { name: string; contentType: string; bytes: Uint8Array }

/**
 * Das Zugriffstoken, im Modul gehalten.
 *
 * Eine Edge-Function-Instanz bedient mehrere Anfragen; das Token eine Stunde
 * lang jedes Mal neu zu holen waere ein zusaetzlicher Netzweg je Mail, der
 * scheitern kann. 60 Sekunden Sicherheitsabstand, damit kein Token benutzt
 * wird, das waehrend des Versands ablaeuft.
 */
let token: { wert: string; gueltigBis: number } | null = null

async function zugriffstoken(): Promise<string> {
  const jetzt = Date.now()
  if (token && token.gueltigBis > jetzt + 60_000) return token.wert

  const tenant = Deno.env.get('MS_TENANT_ID')
  const client = Deno.env.get('MS_CLIENT_ID')
  const secret = Deno.env.get('MS_CLIENT_SECRET')
  if (!tenant || !client || !secret) {
    throw new Error('Mailversand ist nicht eingerichtet (MS_TENANT_ID/MS_CLIENT_ID/MS_CLIENT_SECRET)')
  }

  const antwort = await fetch(`https://login.microsoftonline.com/${tenant}/oauth2/v2.0/token`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      client_id: client,
      client_secret: secret,
      scope: SCOPE,
      grant_type: 'client_credentials',
    }),
  })

  if (!antwort.ok) {
    // Bewusst nur Statuscode und Fehlerkennung, nicht der ganze Rumpf: dort
    // steht unter Umstaenden das mitgeschickte Secret.
    const roh = (await antwort.text().catch(() => '')).slice(0, 400)
    const kennung = /"error"\s*:\s*"([^"]+)"/.exec(roh)?.[1] ?? 'unbekannt'
    throw new Error(`Anmeldung bei Microsoft fehlgeschlagen (${antwort.status}, ${kennung})`)
  }

  const daten = (await antwort.json()) as { access_token: string; expires_in: number }
  token = { wert: daten.access_token, gueltigBis: jetzt + daten.expires_in * 1000 }
  return daten.access_token
}

function base64(bytes: Uint8Array): string {
  // Stueckweise, weil String.fromCharCode(...bytes) bei einem PDF von einigen
  // Kilobyte den Aufrufstapel sprengt.
  let roh = ''
  const schritt = 0x8000
  for (let i = 0; i < bytes.length; i += schritt) {
    roh += String.fromCharCode(...bytes.subarray(i, i + schritt))
  }
  return btoa(roh)
}

/**
 * Eine Mail aus dem Postfach hello@ verschicken.
 *
 * saveToSentItems bleibt an: was an Eltern rausgeht, soll im Postfach stehen
 * und nicht nur in unserer Datenbank.
 */
export async function mailSenden(opts: {
  an: string
  betreff: string
  text: string
  anhaenge?: Anhang[]
}): Promise<void> {
  const zugriff = await zugriffstoken()

  const nachricht = {
    message: {
      subject: opts.betreff,
      body: { contentType: 'Text', content: opts.text },
      toRecipients: [{ emailAddress: { address: opts.an } }],
      attachments: (opts.anhaenge ?? []).map((a) => ({
        '@odata.type': '#microsoft.graph.fileAttachment',
        name: a.name,
        contentType: a.contentType,
        contentBytes: base64(a.bytes),
      })),
    },
    saveToSentItems: true,
  }

  const antwort = await fetch(
    `https://graph.microsoft.com/v1.0/users/${encodeURIComponent(ABSENDER)}/sendMail`,
    {
      method: 'POST',
      headers: { Authorization: `Bearer ${zugriff}`, 'Content-Type': 'application/json' },
      body: JSON.stringify(nachricht),
    },
  )

  if (!antwort.ok) {
    const roh = (await antwort.text().catch(() => '')).slice(0, 400)
    const meldung = /"message"\s*:\s*"([^"]+)"/.exec(roh)?.[1] ?? roh
    throw new Error(`Graph sendMail ${antwort.status}: ${meldung}`)
  }
}
