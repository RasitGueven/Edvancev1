// Der Vertragstext mit eingesetzten Werten — die Vorlage von
// dokumente/vertrag_de.ts, gefuellt aus der Datenbank.
//
// Alles, was gerechnet werden koennte, wird gelesen: vertrag_ende, ferientage
// und widerruf_bis stehen seit dem Abschluss auf der Zeile. Sie hier noch
// einmal auszurechnen hiesse, ein zweites Vertragsende zu erfinden — und das
// im PDF, also genau dort, wo es am teuersten waere, wenn es abweicht.

import type { SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2'
import {
  FERIENKLAUSEL,
  KEINE_FERIENKLAUSEL,
  LAUFZEIT_TEXT,
  VERTRAG_MD,
} from './dokumente/vertrag_de.ts'

const SPALTEN = `
  id, status, eltern_vorname, eltern_nachname, strasse, hausnummer, plz, ort,
  eltern_telefon, eltern_email, kind_vorname, kind_nachname, kind_geburtsdatum,
  klasse, fach, schule, laufzeit_monate, tier_id, preis_cents, einheiten,
  vertragsbeginn, vertrag_ende, ferientage, widerruf_bis, mandatsreferenz,
  abschluss_weg, unterschrieben_am, abgeschlossen_am
`

export type VertragZeile = Record<string, unknown>

export function datum(ymd: string | null | undefined): string | null {
  if (!ymd) return null
  const [j, m, t] = ymd.slice(0, 10).split('-')
  return `${t}.${m}.${j}`
}

export function euro(cents: number | null | undefined): string | null {
  if (cents === null || cents === undefined) return null
  return new Intl.NumberFormat('de-DE', { style: 'currency', currency: 'EUR' }).format(cents / 100)
}

/** Setzt {{schluessel}} ein; Unbekanntes und Leeres wird zu "—" — wie fillDokument. */
export function fuellen(text: string, werte: Record<string, string | null>): string {
  return text.replace(/\{\{(\w+)\}\}/g, (_, k: string) => {
    const w = werte[k]
    return w === undefined || w === null || w.trim() === '' ? '—' : w
  })
}

function einsetzen(vorlage: string, werte: Record<string, string | number>): string {
  return vorlage.replace(/\{\{(\w+)\}\}/g, (_, k: string) => String(werte[k] ?? '—'))
}

export type Dokument = {
  vertrag: VertragZeile
  markdown: string
  fusszeile: string
  unterschrift: { png: Uint8Array; beschriftung: string; ort: string } | null
}

/** Ein data:-URL in Bytes. Alles andere als PNG waere hier ein Fehler. */
function pngAusDataUrl(dataUrl: string): Uint8Array | null {
  const treffer = /^data:image\/png;base64,([A-Za-z0-9+/=]+)$/.exec(dataUrl.trim())
  if (!treffer) return null
  const roh = atob(treffer[1])
  const bytes = new Uint8Array(roh.length)
  for (let i = 0; i < roh.length; i++) bytes[i] = roh.charCodeAt(i)
  return bytes
}

/**
 * Der reine Teil: Zeile rein, Dokument raus. Ohne Datenbank, ohne Netz —
 * damit der Test genau das pruefen kann, was spaeter im PDF steht, und nicht
 * eine Nachbildung davon.
 */
export function dokumentAusZeile(
  v: VertragZeile,
  paket: string | null,
  signaturDataUrl: string | null,
): Dokument {
  const feld = (k: string): string | null => (v[k] as string | null) ?? null
  const zahl = (k: string): number | null => (v[k] as number | null) ?? null

  const eltern = [feld('eltern_vorname'), feld('eltern_nachname')].filter(Boolean).join(' ')
  const strasse = [feld('strasse'), feld('hausnummer')].filter(Boolean).join(' ')
  const ort = [feld('plz'), feld('ort')].filter(Boolean).join(' ')
  const laufzeit = zahl('laufzeit_monate')
  const preis = zahl('preis_cents')

  // Die Ferienklausel steht nur im Halbjahresvertrag (Anforderung B.7).
  const ferienklausel =
    laufzeit === 6
      ? einsetzen(FERIENKLAUSEL, {
          einheiten: zahl('einheiten') ?? '\u2014',
          tage: zahl('ferientage') ?? 0,
          ende: datum(feld('vertrag_ende')) ?? '\u2014',
        })
      : KEINE_FERIENKLAUSEL

  const werte: Record<string, string | null> = {
    eltern_name: eltern || null,
    anschrift: [strasse, ort].filter((x) => x !== '').join('\n') || null,
    eltern_telefon: feld('eltern_telefon'),
    eltern_email: feld('eltern_email'),
    kind_name: [feld('kind_vorname'), feld('kind_nachname')].filter(Boolean).join(' ') || null,
    kind_geburtsdatum: datum(feld('kind_geburtsdatum')),
    klasse: zahl('klasse') !== null ? String(zahl('klasse')) : null,
    fach: feld('fach'),
    schule: feld('schule'),
    paket,
    preis: euro(preis),
    laufzeit: laufzeit !== null ? (LAUFZEIT_TEXT[laufzeit] ?? `${laufzeit} Monate`) : null,
    beitraege: laufzeit !== null ? String(laufzeit) : null,
    gesamtpreis: preis !== null && laufzeit !== null ? euro(preis * laufzeit) : null,
    einheiten: zahl('einheiten') !== null ? String(zahl('einheiten')) : null,
    vertragsbeginn: datum(feld('vertragsbeginn')),
    vertragsende: datum(feld('vertrag_ende')),
    ferienklausel,
  }

  // Das Widerrufsdatum steht nicht in der Vorlage, gehoert aber ins Dokument —
  // sonst muesste das Elternteil die Frist selbst ausrechnen.
  //
  // Bewusst nur das Datum und woher es kommt. Eine Widerrufsbelehrung ist ein
  // Rechtstext mit vorgeschriebenem Wortlaut; den erfindet diese Funktion
  // nicht. Der Platzhalter-Hinweis oben im Dokument gilt auch hier.
  const widerruf = datum(feld('widerruf_bis'))
  const zusatz = widerruf
    ? `\n\n## Widerruf\n\nWiderrufsfrist bis einschließlich **${widerruf}**, berechnet ab Vertragsbeginn.\n`
    : ''

  // Unterschrift nur beim Weg "vor Ort". Auf dem Papierweg liegt sie als Scan
  // im Archiv; ein leeres Unterschriftsfeld waere dort eine Falschaussage.
  let unterschrift: Dokument['unterschrift'] = null
  const png = signaturDataUrl ? pngAusDataUrl(signaturDataUrl) : null
  if (png) {
    const tag = datum(feld('unterschrieben_am')) ?? datum(feld('abgeschlossen_am')) ?? ''
    unterschrift = {
      png,
      beschriftung: `${eltern || 'Erziehungsberechtigte Person'}, gesetzliche Vertretung`,
      ort: tag ? `Köln, ${tag}` : 'Köln',
    }
  }

  return {
    vertrag: v,
    markdown: fuellen(VERTRAG_MD, werte) + zusatz,
    fusszeile: `Vertrag ${feld('mandatsreferenz') ?? String(v.id).slice(0, 8)}`,
    unterschrift,
  }
}

/** Laedt Vertrag, Paketnamen und Unterschrift und baut daraus das Dokument. */
export async function vertragDokument(admin: SupabaseClient, vertragId: string): Promise<Dokument> {
  const { data: v, error } = await admin
    .from('vertraege')
    .select(SPALTEN)
    .eq('id', vertragId)
    .single()
  if (error || !v) throw new Error(`Vertrag nicht gefunden: ${error?.message ?? vertragId}`)
  if (v.status !== 'abgeschlossen') {
    throw new Error(`Vertrag ist nicht abgeschlossen (${v.status})`)
  }

  let paket: string | null = null
  if (v.tier_id) {
    const { data: tier } = await admin.from('tiers').select('name').eq('id', v.tier_id).maybeSingle()
    paket = (tier?.name as string | undefined) ?? null
  }

  const { data: sig } = await admin
    .from('vertrag_unterschriften')
    .select('signatur')
    .eq('vertrag_id', vertragId)
    .eq('art', 'vertrag')
    .maybeSingle()

  return dokumentAusZeile(v as VertragZeile, paket, (sig?.signatur as string | null) ?? null)
}
