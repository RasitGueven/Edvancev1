// Erzeugen, ablegen, festhalten — in dieser Reihenfolge und ohne Umweg.
//
// Die Reihenfolge ist nicht beliebig. Erst der Upload mit upsert:false, dann
// der Datenbankeintrag. Faellt die Funktion dazwischen aus, liegt eine Datei
// ohne Eintrag im Bucket: sichtbar, erkennbar, von Hand zu bereinigen. Umge-
// kehrt gaebe es einen Eintrag mit Pruefsumme auf eine Datei, die es nicht
// gibt — ein Archiv, das etwas behauptet, was nicht da ist.

import type { SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { FASSUNG, JE_FASSUNG, JE_VERTRAG } from './dokumente/texte.ts'
import { buendelZusammenstellen, type Umschlagstueck } from './vertrag_buendel.ts'
import { markdownZuPdf } from './markdown_pdf.ts'
import {
  VERTRAG_SPALTEN,
  dokumentAusZeile,
  fassungsDokument,
  istPilot,
  sepaAusZeile,
  vertragDokument,
} from './vertrag_dokument.ts'

export { buendelZusammenstellen, type Umschlagstueck }

export const BUCKET = 'vertraege'

export type ErzeugteDatei = { art: string; pfad: string; sha256: string; bytes: number }

async function sha256Hex(bytes: Uint8Array): Promise<string> {
  // Kopie in einen frischen ArrayBuffer: crypto.subtle nimmt keine Sicht auf
  // einen SharedArrayBuffer, und genau das ist der Typ, den pdf.save() liefert.
  const hash = await crypto.subtle.digest('SHA-256', new Uint8Array(bytes))
  return Array.from(new Uint8Array(hash))
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('')
}

async function hochladen(
  admin: SupabaseClient,
  pfad: string,
  bytes: Uint8Array,
  contentType: string,
): Promise<string> {
  // upsert:false ist die eigentliche Zusage: ein archiviertes Dokument wird
  // nicht ersetzt. Die Unique-Constraints in vertrag_dateien und
  // dokument_fassungen sagen dasselbe noch einmal — zwei Schloesser an
  // derselben Tuer, weil Datei und Eintrag getrennt entstehen.
  const { error } = await admin.storage
    .from(BUCKET)
    .upload(pfad, bytes, { upsert: false, contentType })
  if (error) throw new Error(`Upload ${pfad}: ${error.message}`)
  return await sha256Hex(bytes)
}

/** Ein Dokument je Vertrag: hochladen, dann in vertrag_dateien eintragen. */
async function ablegen(
  admin: SupabaseClient,
  rpc: SupabaseClient,
  vertragId: string,
  art: string,
  dateiname: string,
  bytes: Uint8Array,
  contentType: string,
): Promise<ErzeugteDatei> {
  const pfad = `${vertragId}/${dateiname}`
  const sha256 = await hochladen(admin, pfad, bytes, contentType)

  const { error } = await rpc.rpc('vertrag_datei_eintragen', {
    p_vertrag_id: vertragId,
    p_art: art,
    p_pfad: pfad,
    p_sha256: sha256,
    p_bytes: bytes.length,
  })
  if (error) {
    // Der Eintrag fehlt — dann soll auch die Datei nicht liegen bleiben, sonst
    // blockiert sie beim naechsten Versuch den Upload mit upsert:false.
    await admin.storage.from(BUCKET).remove([pfad])
    throw new Error(`Eintrag ${pfad}: ${error.message}`)
  }

  return { art, pfad, sha256, bytes: bytes.length }
}

/**
 * Das Vertrags-PDF und — wenn vor Ort unterschrieben wurde — das
 * Unterschriftsbild als eigene Datei.
 *
 * Die Unterschrift steht damit zweimal da: als Spalte in
 * vertrag_unterschriften und als PNG im Archiv. Das ist Absicht. Die Spalte
 * ist der Beleg, die Datei ist das, was man jemandem zeigen kann, ohne ihm
 * Datenbankzugriff zu geben.
 *
 * `rpc` traegt das JWT des Admins, `admin` den Service-Key: der Eintrag
 * bekommt einen Urheber, der Upload in den privaten Bucket funktioniert.
 */
export async function vertragPdfErzeugen(
  admin: SupabaseClient,
  rpc: SupabaseClient,
  vertragId: string,
): Promise<ErzeugteDatei[]> {
  const dok = await vertragDokument(admin, vertragId)
  const pdf = await markdownZuPdf({
    markdown: dok.markdown,
    fusszeile: dok.fusszeile,
    unterschrift: dok.unterschrift,
  })

  // Was schon liegt, bleibt liegen. Ein Vertrag aus P4a-1 hat sein
  // Vertrags-PDF und braucht nur noch das Mandat — es noch einmal zu erzeugen
  // wuerde am upsert:false scheitern und den ganzen Lauf mitreissen.
  const { data: schonDa } = await admin
    .from('vertrag_dateien')
    .select('art')
    .eq('vertrag_id', vertragId)
  const liegt = new Set((schonDa ?? []).map((d) => d.art as string))

  const raus: ErzeugteDatei[] = []
  if (!liegt.has('vertrag')) {
    raus.push(await ablegen(admin, rpc, vertragId, 'vertrag', 'vertrag.pdf', pdf, 'application/pdf'))
  }

  if (dok.unterschrift && !liegt.has('unterschrift')) {
    raus.push(
      await ablegen(
        admin, rpc, vertragId, 'unterschrift', 'unterschrift.png',
        dok.unterschrift.png, 'image/png',
      ),
    )
  }

  // V5: Eine Pilotvereinbarung hat kein SEPA-Mandat.
  if (istPilot(dok.vertrag)) return raus

  // ---- SEPA-Mandat ---------------------------------------------------------
  // Die volle IBAN kommt ueber vertrag_iban_anzeigen und nicht per direktem
  // SELECT: die RPC schreibt den audit_log-Eintrag. Dass die Kontonummer
  // aufgedeckt wurde, um sie in ein PDF zu setzen, ist genau der Vorgang, den
  // das Protokoll festhalten soll.
  const { data: iban, error: ibanErr } = await rpc.rpc('vertrag_iban_anzeigen', {
    p_vertrag_id: vertragId,
  })
  if (ibanErr) throw new Error(`IBAN: ${ibanErr.message}`)

  const { data: einst } = await admin
    .from('vertrag_einstellungen')
    .select('glaeubiger_id')
    .maybeSingle()

  // Das Mandat traegt eine EIGENE Unterschrift, nicht die des Vertrags:
  // vertrag_unterschriften haelt beide getrennt (art 'vertrag' und
  // 'sepa_mandat'), und der Assistent nimmt sie auch getrennt ab. Die eine
  // fuer die andere einzusetzen hiesse, eine Unterschrift unter ein Dokument
  // zu setzen, das so nie unterschrieben wurde.
  const { data: sepaSig } = await admin
    .from('vertrag_unterschriften')
    .select('signatur')
    .eq('vertrag_id', vertragId)
    .eq('art', 'sepa_mandat')
    .maybeSingle()

  const sepa = sepaAusZeile(
    dok.vertrag,
    (iban as string | null) ?? null,
    (einst?.glaeubiger_id as string | null) ?? null,
    (sepaSig?.signatur as string | null) ?? null,
  )
  if (!liegt.has('sepa_mandat')) {
    const sepaPdf = await markdownZuPdf({
      markdown: sepa.markdown,
      fusszeile: sepa.fusszeile,
      unterschrift: sepa.unterschrift,
    })
    raus.push(
      await ablegen(admin, rpc, vertragId, 'sepa_mandat', 'sepa_mandat.pdf', sepaPdf, 'application/pdf'),
    )
  }

  return raus
}

/**
 * Die Unterlagen, die fuer alle gleich sind — eine Datei je Art und Fassung.
 *
 * Idempotent und geteilt: liegt die Fassung schon, wird sie nicht neu erzeugt.
 * Deshalb steht sie unter fassungen/<art>/<fassung>.pdf und nicht unter jedem
 * Vertrag noch einmal.
 */
export async function fassungenErzeugen(
  admin: SupabaseClient,
  rpc: SupabaseClient,
): Promise<ErzeugteDatei[]> {
  const { data: vorhanden } = await admin.from('dokument_fassungen').select('art, fassung')
  const schon = new Set((vorhanden ?? []).map((r) => `${r.art}/${r.fassung}`))

  const raus: ErzeugteDatei[] = []
  for (const art of JE_FASSUNG) {
    const fassung = FASSUNG[art]
    if (schon.has(`${art}/${fassung}`)) continue

    const dok = fassungsDokument(art)
    const pdf = await markdownZuPdf({ markdown: dok.markdown, fusszeile: dok.fusszeile })
    const pfad = `fassungen/${art}/${fassung}.pdf`
    const sha256 = await hochladen(admin, pfad, pdf, 'application/pdf')

    const { error } = await rpc.rpc('dokument_fassung_eintragen', {
      p_art: art,
      p_fassung: fassung,
      p_pfad: pfad,
      p_sha256: sha256,
      p_bytes: pdf.length,
    })
    if (error) {
      await admin.storage.from(BUCKET).remove([pfad])
      throw new Error(`Eintrag ${pfad}: ${error.message}`)
    }
    raus.push({ art, pfad, sha256, bytes: pdf.length })
  }
  return raus
}

/**
 * Liegt das vollstaendige Buendel im Archiv?
 *
 * Frueher fragte das nur nach vertrag.pdf. Das ging schief, sobald es eine
 * zweite Art gab: Vertraege aus P4a-1 haben ihr Vertrags-PDF, aber kein
 * SEPA-Mandat — und der Nachhol-Knopf blieb aus, weil das eine Stueck ja da
 * war. Gefragt ist, ob etwas FEHLT, nicht ob etwas DA ist.
 */
export async function buendelVollstaendig(
  admin: SupabaseClient,
  vertragId: string,
): Promise<boolean> {
  const [{ data }, { data: v }] = await Promise.all([
    admin.from('vertrag_dateien').select('art').eq('vertrag_id', vertragId),
    admin.from('vertraege').select('vertragsart').eq('id', vertragId).maybeSingle(),
  ])
  const vorhanden = new Set((data ?? []).map((d) => d.art as string))
  // V5: Der Pilot hat nur das Vertragsdokument, kein Mandat.
  const noetig = v && istPilot(v) ? ['vertrag'] : JE_VERTRAG
  return noetig.every((art) => vorhanden.has(art))
}

/**
 * Die Unterlagen zum Ausdrucken — Weg B, bevor irgendetwas unterschrieben ist.
 *
 * Vertrag und SEPA-Mandat liegen in EINER Datei, getrennt durch einen
 * Seitenumbruch. Nicht aus Bequemlichkeit: vertrag_dateien laesst je Vertrag
 * ein Dokument je Art zu, und die Art 'sepa_mandat' ist fuer das
 * unterschriebene Mandat nach dem Abschluss reserviert. Zwei Mandate unter
 * einem Namen abzulegen hiesse, das spaetere gueltige nicht mehr ablegen zu
 * koennen.
 *
 * Vertragsende und Widerrufsfrist stehen vor dem Abschluss noch nicht auf der
 * Zeile — sie kommen aus derselben RPC, die auch der Assistent fuer die
 * Vorschau benutzt. Eine zweite Rechnung gaebe es damit nicht.
 */
export async function unterlagenVersandErzeugen(
  admin: SupabaseClient,
  rpc: SupabaseClient,
  vertragId: string,
): Promise<ErzeugteDatei> {
  const { data: v, error } = await admin
    .from('vertraege')
    .select(VERTRAG_SPALTEN)
    .eq('id', vertragId)
    .single()
  if (error || !v) throw new Error(`Vertrag nicht gefunden: ${error?.message ?? vertragId}`)

  const zeile: Record<string, unknown> = { ...v }

  // Ende, Ferientage und Widerrufsfrist fuer die Vorschau berechnen — aus der
  // Datenbank, nicht hier. Ein Pilot traegt sein Ende schon (V5).
  const pilot = istPilot(v)
  if (!pilot && v.vertragsbeginn && v.laufzeit_monate) {
    const { data: ende } = await rpc
      .rpc('vertrag_ende_berechnen', {
        p_beginn: v.vertragsbeginn,
        p_laufzeit_monate: v.laufzeit_monate,
      })
      .maybeSingle()
    if (ende) {
      zeile.vertrag_ende = (ende as { ende: string }).ende
      zeile.ferientage = (ende as { ferientage: number }).ferientage
    }
    const { data: widerruf } = await rpc.rpc('vertrag_widerruf_bis', {
      p_beginn: v.vertragsbeginn,
    })
    if (widerruf) zeile.widerruf_bis = widerruf as string
  }

  let paket: string | null = null
  if (v.tier_id) {
    const { data: tier } = await admin.from('tiers').select('name').eq('id', v.tier_id).maybeSingle()
    paket = (tier?.name as string | undefined) ?? null
  }

  // Ohne Unterschriftsbild: hier wird von Hand unterschrieben. Ein leeres
  // Feld waere hier richtig, ein eingesetztes Bild eine Faelschung.
  const vertrag = dokumentAusZeile(zeile, paket, null)
  if (pilot) {
    // V5: ohne SEPA-Mandat, also ohne IBAN — nur die Pilotvereinbarung.
    const pilotPdf = await markdownZuPdf({ markdown: vertrag.markdown, fusszeile: vertrag.fusszeile })
    return await ablegen(
      admin, rpc, vertragId, 'unterlagen_versand', 'unterlagen.pdf', pilotPdf, 'application/pdf',
    )
  }

  const { data: iban } = await rpc.rpc('vertrag_iban_anzeigen', { p_vertrag_id: vertragId })
  const { data: einst } = await admin
    .from('vertrag_einstellungen')
    .select('glaeubiger_id')
    .maybeSingle()

  const sepa = sepaAusZeile(
    zeile,
    (iban as string | null) ?? null,
    (einst?.glaeubiger_id as string | null) ?? null,
    null,
  )

  const pdf = await markdownZuPdf({
    markdown: `${vertrag.markdown}\n\n---\n\n${sepa.markdown}`,
    fusszeile: vertrag.fusszeile,
  })

  return await ablegen(
    admin, rpc, vertragId, 'unterlagen_versand', 'unterlagen.pdf', pdf, 'application/pdf',
  )
}

/** Laedt die Belege und stellt daraus den Umschlag zusammen. */
export async function buendelPfade(
  admin: SupabaseClient,
  vertragId: string,
  anlass: 'bestaetigung' | 'unterlagen',
): Promise<Umschlagstueck[]> {
  const [dateien, zust, fassungen, katalog, vertrag] = await Promise.all([
    admin.from('vertrag_dateien').select('art, pfad').eq('vertrag_id', vertragId),
    admin
      .from('vertrag_zustimmungen')
      .select('dokument_schluessel, dokument_version')
      .eq('vertrag_id', vertragId),
    admin.from('dokument_fassungen').select('art, fassung, pfad'),
    admin.from('vertrag_dokumente').select('schluessel, titel'),
    admin.from('vertraege').select('vertragsart').eq('id', vertragId).maybeSingle(),
  ])

  const titel: Record<string, string> = {}
  for (const d of katalog.data ?? []) titel[d.schluessel as string] = d.titel as string

  return buendelZusammenstellen({
    dateien: (dateien.data ?? []) as { art: string; pfad: string }[],
    zustimmungen: (zust.data ?? []) as {
      dokument_schluessel: string
      dokument_version: string
    }[],
    fassungen: (fassungen.data ?? []) as { art: string; fassung: string; pfad: string }[],
    titel,
    anlass,
    pilot: vertrag.data ? istPilot(vertrag.data) : false,
  })
}
