// Der Kern des Send Email Hooks — ohne Deno.serve, ohne Netz. index.ts gibt
// Versand und Protokoll hinein; die Tests geben Attrappen hinein.
//
// Ablauf je Aufruf:
//   1. Signatur pruefen (Standard Webhooks). Ohne gueltige Signatur 401 und
//      KEIN Protokoll — sonst koennte jeder die Tabelle fuellen.
//   2. Art bestimmen. Unbekannte Art: 400, gesperrte Art (email_change): 403,
//      beide mit definiertem Fehler und protokolliert, keine Mail.
//   3. Mail(s) bauen. Die Links zeigen auf eigene Seiten der App, nie direkt
//      auf /auth/v1/verify: Die Seite loest den Token erst nach einem Klick ein,
//      damit Mail-Scanner (Safe Links), die Links vorab oeffnen, ihn nicht
//      verbrauchen.
//   4. Versenden und protokollieren — jeden Versuch, ohne Token und ohne Link.
//
// Antwort an Supabase Auth: 200 {} bei Erfolg, sonst {error:{http_code,message}}.
// Auth bricht dann den Vorgang ab (eine Einladung ohne Mail entsteht nicht).

import { signaturPruefen } from '../_shared/standard_webhooks.ts'
import { ARTEN, GESPERRT, GUELTIG, TEXTE, type GesperrteArt, type MailArt } from './texte.ts'

export type HookNutzer = {
  id: string
  email?: string
  user_metadata?: { full_name?: unknown }
}

export type HookDaten = {
  token?: string
  token_hash?: string
  token_new?: string
  token_hash_new?: string
  redirect_to?: string
  email_action_type?: string
  site_url?: string
}

export type Mail = { an: string; betreff: string; text: string }

export type ProtokollZeile = {
  art: MailArt | GesperrteArt | 'unbekannt'
  empfaenger: string
  user_id: string | null
  fehler: string | null
}

export type Abhaengigkeiten = {
  schluessel: Uint8Array | null
  /** APP_URL; fehlt sie, gilt site_url aus dem Aufruf. */
  appUrl: string | undefined
  senden: (mail: Mail) => Promise<void>
  protokollieren: (zeile: ProtokollZeile) => Promise<void>
  jetztSekunden?: number
}

/** Die Seite der App je Art. reauthentication hat keinen Link, nur einen Code. */
const SEITE: Record<Exclude<MailArt, 'reauthentication'>, string> = {
  invite: '/auth/einladung',
  recovery: '/auth/neues-passwort',
  signup: '/auth/bestaetigen',
  magiclink: '/auth/bestaetigen',
}

function antwort(status: number, payload: unknown): Response {
  return new Response(JSON.stringify(payload), {
    status,
    headers: { 'Content-Type': 'application/json' },
  })
}

function fehlerAntwort(status: number, message: string): Response {
  return antwort(status, { error: { http_code: status, message } })
}

/** Nur der Ursprung (Schema, Host, Port) einer http(s)-Adresse, sonst null. */
export function ursprung(url: string | undefined): string | null {
  if (!url) return null
  try {
    const u = new URL(url)
    if (u.protocol !== 'https:' && u.protocol !== 'http:') return null
    return u.origin
  } catch {
    return null
  }
}

export function linkFuer(basis: string, art: Exclude<MailArt, 'reauthentication'>, tokenHash: string): string {
  const q = new URLSearchParams({ token_hash: tokenHash, type: art })
  return `${basis}${SEITE[art]}?${q.toString()}`
}

function einsetzen(vorlage: string, werte: Record<string, string>): string {
  return vorlage.replace(/\{\{(\w+)\}\}/g, (_, k: string) => werte[k] ?? '')
}

function anrede(nutzer: HookNutzer): string {
  const name = typeof nutzer.user_metadata?.full_name === 'string' ? nutzer.user_metadata.full_name.trim() : ''
  return name ? `Guten Tag ${name}` : 'Guten Tag'
}

/** Die Mail zu einem Aufruf (je Aufruf genau eine). */
export function mailsBauen(art: MailArt, nutzer: HookNutzer, daten: HookDaten, basis: string): Mail[] {
  const vorlage = TEXTE[art]
  const fertig = (an: string, werte: Record<string, string>): Mail => ({
    an,
    betreff: vorlage.betreff,
    text: einsetzen(vorlage.text, { anrede: anrede(nutzer), gueltig: GUELTIG, ...werte }),
  })

  if (art === 'reauthentication') {
    if (!nutzer.email || !daten.token) throw new Error('reauthentication ohne Adresse oder Code')
    return [fertig(nutzer.email, { code: daten.token })]
  }

  if (!nutzer.email || !daten.token_hash) throw new Error(`${art} ohne Adresse oder Token`)
  return [fertig(nutzer.email, { link: linkFuer(basis, art, daten.token_hash) })]
}

function istGesperrt(x: unknown): x is GesperrteArt {
  return typeof x === 'string' && (GESPERRT as readonly string[]).includes(x)
}

function istArt(x: unknown): x is MailArt {
  return typeof x === 'string' && (ARTEN as readonly string[]).includes(x)
}

/** Fehlertext fuers Protokoll: nie mit Token oder Link (die stehen nur in der Mail). */
function sauber(meldung: string, daten: HookDaten): string {
  let m = meldung
  for (const geheim of [daten.token, daten.token_hash, daten.token_new, daten.token_hash_new]) {
    if (geheim) m = m.split(geheim).join('[…]')
  }
  return m.replace(/https?:\/\/\S+/g, '[Link]').replace(/token_hash=[^&\s]+/g, '[…]').slice(0, 500)
}

export async function hookBearbeiten(req: Request, deps: Abhaengigkeiten): Promise<Response> {
  if (req.method !== 'POST') return fehlerAntwort(405, 'Method not allowed')

  const rumpf = await req.text()
  const pruefung = await signaturPruefen(req.headers, rumpf, deps.schluessel, deps.jetztSekunden)
  if (!pruefung.ok) {
    console.warn('auth_mail: rejected request', pruefung.grund)
    return fehlerAntwort(401, 'Ungueltige Signatur')
  }

  let nutzer: HookNutzer
  let daten: HookDaten
  try {
    const roh = JSON.parse(rumpf) as { user?: HookNutzer; email_data?: HookDaten }
    if (!roh.user?.id || !roh.email_data) throw new Error('user oder email_data fehlt')
    nutzer = roh.user
    daten = roh.email_data
  } catch {
    return fehlerAntwort(400, 'Ungueltiger Rumpf')
  }

  const artRoh = daten.email_action_type
  if (istGesperrt(artRoh)) {
    const fehler = `${artRoh} ist gesperrt: Adressaenderung nur ueber den Admin`
    await deps.protokollieren({ art: artRoh, empfaenger: nutzer.email ?? '', user_id: nutzer.id, fehler })
    return fehlerAntwort(403, fehler)
  }
  if (!istArt(artRoh)) {
    const fehler = `unbekannte Mailart: ${String(artRoh).slice(0, 40)}`
    await deps.protokollieren({ art: 'unbekannt', empfaenger: nutzer.email ?? '', user_id: nutzer.id, fehler })
    return fehlerAntwort(400, fehler)
  }

  const basis = ursprung(deps.appUrl) ?? ursprung(daten.site_url)
  if (!basis) return fehlerAntwort(500, 'Keine App-Adresse (APP_URL) eingerichtet')

  let mails: Mail[]
  try {
    mails = mailsBauen(artRoh, nutzer, daten, basis)
  } catch (err) {
    const fehler = sauber(err instanceof Error ? err.message : 'Mail nicht baubar', daten)
    await deps.protokollieren({ art: artRoh, empfaenger: nutzer.email ?? '', user_id: nutzer.id, fehler })
    return fehlerAntwort(400, fehler)
  }

  let ersterFehler: string | null = null
  for (const mail of mails) {
    let fehler: string | null = null
    try {
      await deps.senden(mail)
    } catch (err) {
      fehler = sauber(err instanceof Error ? err.message : 'Versand fehlgeschlagen', daten)
      console.error('auth_mail: send failed', artRoh, fehler)
    }
    await deps.protokollieren({ art: artRoh, empfaenger: mail.an, user_id: nutzer.id, fehler })
    ersterFehler ??= fehler
  }

  if (ersterFehler) return fehlerAntwort(502, ersterFehler)
  return antwort(200, {})
}
