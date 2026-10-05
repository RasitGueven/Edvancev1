// Lenas Bearbeitungsstand auf der Pruefkarte: Ableitung aus der Sicht des Servers, Vergleich mit
// der Ausgangsfassung ("geaendert ↺"), Ruecksetzen je Feld und der Entwurf fuer pruef_speichern.
// Massgeblich fuer das Protokoll bleibt die serverseitige Aenderungsliste (pruef_aenderungen);
// lokaleAenderungen spiegelt sie, damit Marken und Zaehler sofort beim Tippen stimmen.

import type {
  Afb,
  PruefAenderung,
  PruefAufgabe,
  PruefEntwurf,
  PruefFehlerWert,
  PruefSicht,
} from '@/types'

export type FehlerZeile = {
  slug: string
  werte: PruefFehlerWert[]
  text: string | null
  /** "Entfernen": durchgestrichen, "Wieder rein" holt sie zurueck. */
  raus: boolean
  /** Von Lena ergaenzt: Entfernen loescht die Zeile ganz. */
  neu: boolean
}

export type Bearbeitung = {
  werte: { teil: number | null; werte: string[] }[]
  mc: string | null
  regel: { art: 'wert' | 'bereich'; mitte: string | null; toleranz: string | null; einheit_pflicht: boolean } | null
  fehler: FehlerZeile[]
  skill_key: string | null
  afb: Afb | null
}

export type Feld = 'antwort' | 'regel' | 'fehler' | 'fertigkeit' | 'afb'

type SichtTeil = Pick<PruefSicht, 'werte' | 'mc' | 'regel' | 'fehler' | 'skill_key' | 'afb'>

export function bearbeitungAus(s: SichtTeil): Bearbeitung {
  return {
    werte: s.werte.map((t) => ({ teil: t.teil, werte: t.werte.map((w) => w.wert) })),
    mc: s.mc,
    regel: s.regel
      ? {
          art: s.regel.art,
          mitte: s.regel.mitte,
          toleranz: s.regel.toleranz === null ? null : String(s.regel.toleranz).replace('.', ','),
          einheit_pflicht: s.regel.einheit_pflicht,
        }
      : null,
    fehler: s.fehler.map((f) => ({ slug: f.slug, werte: f.werte, text: f.text, raus: false, neu: false })),
    skill_key: s.skill_key,
    afb: s.afb,
  }
}

/** Die Ausgangsfassung als Bearbeitung; ohne gespeicherte Ausgangsfassung der jetzige Stand. */
export function ausgangAus(a: PruefAufgabe): Bearbeitung {
  return bearbeitungAus(a.ausgang ?? { ...a, skill_key: a.fertigkeit?.key ?? null })
}

/** Entfernte Zeilen fallen weg, Zeilen mit demselben Fehlbild werden zusammengefuehrt. */
function fehlerFuerEntwurf(zeilen: FehlerZeile[]): PruefEntwurf['fehler'] {
  const nachSlug = new Map<string, { slug: string; werte: PruefFehlerWert[]; text: string | null }>()
  for (const z of zeilen) {
    if (z.raus) continue
    const g = nachSlug.get(z.slug) ?? { slug: z.slug, werte: [], text: null }
    for (const w of z.werte) {
      if (!g.werte.some((x) => x.teil === w.teil && x.wert === w.wert)) g.werte.push(w)
    }
    g.text = g.text ?? (z.text?.trim() ? z.text.trim() : null)
    nachSlug.set(z.slug, g)
  }
  return [...nachSlug.values()]
}

/** Der Entwurf fuer pruef_speichern / pruef_wertung_testen. Leere Antworten fallen weg. */
export function zuEntwurf(b: Bearbeitung): PruefEntwurf {
  // Bei "Bereich" ersetzt der Wert in der Mitte die Liste (Dummy v2: statt der Antwortfelder).
  const bereich = b.regel?.art === 'bereich' && b.regel.mitte?.trim()
  return {
    werte: bereich
      ? [{ teil: null, werte: [b.regel?.mitte?.trim() ?? ''] }]
      : b.werte.map((t) => ({ teil: t.teil, werte: t.werte.map((w) => w.trim()).filter(Boolean) })),
    mc: b.mc,
    regel: b.regel,
    fehler: fehlerFuerEntwurf(b.fehler),
    skill_key: b.skill_key,
    afb: b.afb,
  }
}

const fehlerSchluessel = (b: Bearbeitung): string =>
  JSON.stringify(
    fehlerFuerEntwurf(b.fehler)
      .map((f) => ({
        slug: f.slug,
        text: f.text,
        werte: [...f.werte].sort((x, y) => `${x.teil}|${x.wert}`.localeCompare(`${y.teil}|${y.wert}`)),
      }))
      .sort((x, y) => x.slug.localeCompare(y.slug)),
  )

const regelSchluessel = (b: Bearbeitung): string =>
  JSON.stringify(
    b.regel
      ? { art: b.regel.art, mitte: b.regel.art === 'bereich' ? zahlVon(b.regel.mitte) : null,
          toleranz: b.regel.art === 'bereich' ? zahlVon(b.regel.toleranz) : null }
      : null,
  )

/** Welche Felder weichen von der Ausgangsfassung ab? */
export function geaenderteFelder(ausgang: Bearbeitung, jetzt: Bearbeitung): Set<Feld> {
  const aus = zuEntwurf(ausgang)
  const neu = zuEntwurf(jetzt)
  const felder = new Set<Feld>()
  if (JSON.stringify(aus.werte) !== JSON.stringify(neu.werte) || aus.mc !== neu.mc) felder.add('antwort')
  if (regelSchluessel(ausgang) !== regelSchluessel(jetzt)
      || (ausgang.regel?.einheit_pflicht ?? false) !== (jetzt.regel?.einheit_pflicht ?? false)) felder.add('regel')
  if (fehlerSchluessel(ausgang) !== fehlerSchluessel(jetzt)) felder.add('fehler')
  if (aus.skill_key !== neu.skill_key) felder.add('fertigkeit')
  if (aus.afb !== neu.afb) felder.add('afb')
  return felder
}

/** Die Aenderungsliste wie pruef_aenderungen, nur lokal. */
export function lokaleAenderungen(ausgang: Bearbeitung, jetzt: Bearbeitung): PruefAenderung[] {
  const aus = zuEntwurf(ausgang)
  const neu = zuEntwurf(jetzt)
  const liste: PruefAenderung[] = []
  const teile = new Set([...aus.werte, ...neu.werte].map((t) => t.teil))
  for (const teil of teile) {
    const v = aus.werte.find((t) => t.teil === teil)?.werte ?? []
    const n = neu.werte.find((t) => t.teil === teil)?.werte ?? []
    const vMc = aus.mc !== null && teil === null ? [aus.mc] : v
    const nMc = neu.mc !== null && teil === null ? [neu.mc] : n
    if (JSON.stringify(vMc) !== JSON.stringify(nMc)) liste.push({ feld: 'richtige_antwort', teil, vorher: vMc, nachher: nMc })
  }
  if (regelSchluessel(ausgang) !== regelSchluessel(jetzt)) {
    const r = (b: Bearbeitung) => (b.regel ? { art: b.regel.art, mitte: b.regel.mitte, toleranz: b.regel.toleranz } : null)
    liste.push({ feld: 'wertung', teil: null, vorher: r(ausgang), nachher: r(jetzt) })
  }
  if ((ausgang.regel?.einheit_pflicht ?? false) !== (jetzt.regel?.einheit_pflicht ?? false)) {
    liste.push({ feld: 'einheit_pflicht', teil: null, vorher: ausgang.regel?.einheit_pflicht ?? false,
                 nachher: jetzt.regel?.einheit_pflicht ?? false })
  }
  const slugs = new Set([...aus.fehler, ...neu.fehler].map((f) => f.slug))
  for (const slug of [...slugs].sort()) {
    const v = aus.fehler.find((f) => f.slug === slug) ?? null
    const n = neu.fehler.find((f) => f.slug === slug) ?? null
    const key = (f: typeof v) => (f ? JSON.stringify({ t: f.text, w: [...f.werte].map((x) => `${x.teil}|${x.wert}`).sort() }) : '')
    if (key(v) !== key(n)) liste.push({ feld: 'typischer_fehler', teil: null, vorher: v, nachher: n })
  }
  if (aus.skill_key !== neu.skill_key) liste.push({ feld: 'fertigkeit', teil: null, vorher: aus.skill_key, nachher: neu.skill_key })
  if (aus.afb !== neu.afb) liste.push({ feld: 'anforderungsbereich', teil: null, vorher: aus.afb, nachher: neu.afb })
  return liste
}

/** ↺: ein Feld auf die Ausgangsfassung zuruecksetzen. */
export function feldZuruecksetzen(jetzt: Bearbeitung, ausgang: Bearbeitung, feld: Feld): Bearbeitung {
  switch (feld) {
    case 'antwort':
      return { ...jetzt, werte: ausgang.werte.map((t) => ({ ...t, werte: [...t.werte] })), mc: ausgang.mc }
    case 'regel':
      return { ...jetzt, regel: ausgang.regel ? { ...ausgang.regel } : null,
               werte: ausgang.regel?.art !== jetzt.regel?.art ? ausgang.werte : jetzt.werte }
    case 'fehler':
      return { ...jetzt, fehler: ausgang.fehler.map((f) => ({ ...f })) }
    case 'fertigkeit':
      return { ...jetzt, skill_key: ausgang.skill_key }
    case 'afb':
      return { ...jetzt, afb: ausgang.afb }
  }
}

/** Zahl aus Lenas Eingabe: Komma oder Punkt, Plus, Unicode-Minus, Bruch. */
export function zahlVon(s: string | null | undefined): number | null {
  if (s === null || s === undefined) return null
  const t = s.trim().replace(/[−–]/g, '-').replace(/^([-+])\s+/, '$1').replace(',', '.')
  const m = t.match(/^([-+]?\d+(?:\.\d+)?)(?:\/(\d+))?(?:\s*[^\d\s].*)?$/)
  if (!m) return null
  const v = m[2] ? parseFloat(m[1]) / parseFloat(m[2]) : parseFloat(m[1])
  return Number.isFinite(v) ? v : null
}

/** Vorschlag beim Umstellen auf "Bereich": um den hinterlegten Wert (wie im Dummy v2). */
export function bereichVorschlag(wert: string | undefined): { mitte: string | null; toleranz: string | null } {
  const m = zahlVon(wert)
  if (m === null) return { mitte: null, toleranz: null }
  const a = Math.abs(m)
  const tol = a <= 5 ? 0.5 : a <= 20 ? 1 : Math.round(a * 0.05 * 10) / 10
  return { mitte: String(m).replace('.', ','), toleranz: String(tol).replace('.', ',') }
}

export type Sperrgrund = 'antwort_fehlt' | 'teil_fehlt' | 'bereich_ungueltig'

/** Warum "Passt" gesperrt ist (Entscheidung 34), oder null. */
export function sperrgrund(inputType: PruefAufgabe['aufgabe']['input_type'], b: Bearbeitung): Sperrgrund | null {
  if (inputType === 'MC') return b.mc ? null : 'antwort_fehlt'
  if (b.regel?.art === 'bereich') {
    const mitte = zahlVon(b.regel.mitte)
    const tol = zahlVon(b.regel.toleranz)
    return mitte === null || tol === null || tol <= 0 || tol > Math.max(Math.abs(mitte), 1) ? 'bereich_ungueltig' : null
  }
  const leer = b.werte.filter((t) => t.werte.every((w) => !w.trim()))
  if (leer.length === 0 && b.werte.length > 0) return null
  return inputType === 'MULTI_PART' ? 'teil_fehlt' : 'antwort_fehlt'
}

/** "+ Fehler ergaenzen": an eine bestehende Zeile desselben Fehlbilds anhaengen, sonst neue Zeile. */
export function fehlerErgaenzen(
  b: Bearbeitung,
  neu: { slug: string; teil: number | null; wert: string; text: string | null },
): Bearbeitung {
  const wert = { teil: neu.teil, wert: neu.wert.trim() }
  const i = b.fehler.findIndex((f) => f.slug === neu.slug && !f.raus)
  if (i >= 0) {
    const fehler = b.fehler.map((f, k) =>
      k === i ? { ...f, werte: [...f.werte, wert], text: f.text ?? (neu.text?.trim() || null) } : f)
    return { ...b, fehler }
  }
  return { ...b, fehler: [...b.fehler, { slug: neu.slug, werte: [wert], text: neu.text?.trim() || null, raus: false, neu: true }] }
}

/** "Entfernen" / "Wieder rein". Eine ergaenzte Zeile verschwindet beim Entfernen ganz. */
export function fehlerUmschalten(b: Bearbeitung, index: number): Bearbeitung {
  const z = b.fehler[index]
  if (!z) return b
  if (z.neu && !z.raus) return { ...b, fehler: b.fehler.filter((_, k) => k !== index) }
  return { ...b, fehler: b.fehler.map((f, k) => (k === index ? { ...f, raus: !f.raus } : f)) }
}
