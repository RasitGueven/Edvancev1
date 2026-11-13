// IU-1 U2: reine Rechnungen der Inhalte-Übersicht. Adresse (Reiter, Klasse, Detail), Kennzahlen, nächste Schritte
// und Sprungziele. Ohne Texte: die Seite übersetzt die Schlüssel.

import type { InhalteReihe, InhalteThema, ReihenAmpel, ThemaAmpel } from '@/types/inhalte'

export const PRUEFZIEL_MSA = 'msa_zp10'
export const KLASSEN = [8, 9, 10] as const

export type InhalteReiter = 'lsa' | 'reihen'

/** Zustand der Seite aus der Adresse: ?reiter=lsa|reihen&klasse=9&thema=…|ziel=…|reihe=… (teilbar). */
export type InhalteAnsicht = {
  reiter: InhalteReiter
  klasse: number | null
  thema: string | null
  ziel: string | null
  reihe: string | null
}

export function ansichtAusSuche(suche: URLSearchParams): InhalteAnsicht {
  const k = Number(suche.get('klasse'))
  return {
    reiter: suche.get('reiter') === 'reihen' ? 'reihen' : 'lsa',
    klasse: (KLASSEN as readonly number[]).includes(k) ? k : null,
    thema: suche.get('thema'),
    ziel: suche.get('ziel'),
    reihe: suche.get('reihe'),
  }
}

/** Adresse zu einer Ansicht; Reiter und Klasse bleiben beim Öffnen und Schließen eines Details erhalten. */
export function sucheAusAnsicht(a: Partial<InhalteAnsicht> & Pick<InhalteAnsicht, 'reiter'>): URLSearchParams {
  const s = new URLSearchParams({ reiter: a.reiter })
  if (a.klasse) s.set('klasse', String(a.klasse))
  if (a.thema) s.set('thema', a.thema)
  if (a.ziel) s.set('ziel', a.ziel)
  if (a.reihe) s.set('reihe', a.reihe)
  return s
}

export type LsaKennzahlen = { vollstaendig: number; eingeschraenkt: number; nochNicht: number; zuPruefen: number }

export function lsaKennzahlen(themen: InhalteThema[]): LsaKennzahlen {
  const n = (a: ThemaAmpel): number => themen.filter((t) => t.ampel === a).length
  return {
    vollstaendig: n('vollstaendig'),
    eingeschraenkt: n('eingeschraenkt'),
    nochNicht: n('noch_nicht'),
    zuPruefen: themen[0]?.alle_zu_pruefen ?? 0,
  }
}

export type ReihenKennzahlen = { bereit: number; inArbeit: number; inPlanung: number; ohneReihe: number }

export function reihenKennzahlen(reihen: InhalteReihe[], ohneReihe: number): ReihenKennzahlen {
  const n = (a: ReihenAmpel): number => reihen.filter((r) => r.ampel === a).length
  return { bereit: n('bereit'), inArbeit: n('in_arbeit') + n('nicht_bereit'), inPlanung: 0, ohneReihe }
}

/** Wer als Nächstes dran ist. Jede Zeile führt zur Stelle, an der die Arbeit passiert. */
export type Schritt = { wer: 'lena' | 'admin' | 'neu' | 'studio' | 'keiner'; art: string; anzahl: number; ziel: string | null }

/** Lenas Liste „Gezielt prüfen“, optional mit Prüfziel und Kompetenz (U3). */
export function lenaListe(opts: { ziel?: string | null; skill?: string | null } = {}): string {
  const s = new URLSearchParams()
  if (opts.ziel) s.set('ziel', opts.ziel)
  if (opts.skill) s.set('skill', opts.skill)
  const q = s.toString()
  return q ? `/coach/pruefen?${q}` : '/coach/pruefen'
}

export const LSA_FREIGABE = '/admin/lsa-abdeckung'
export const BAUFORMEN_PRUEFEN = '/coach/pruefen/bauformen'
export const STUDIO = '/admin/studio'

type LsaZahlen = { aufgaben_zu_pruefen: number; aufgaben_zur_freigabe: number; aufgaben_fehlen: number }

export function lsaSchritte(z: LsaZahlen, ziel: string | null = null): Schritt[] {
  const s: Schritt[] = []
  if (z.aufgaben_zu_pruefen > 0) s.push({ wer: 'lena', art: 'lenaPrueft', anzahl: z.aufgaben_zu_pruefen, ziel: lenaListe({ ziel }) })
  if (z.aufgaben_zur_freigabe > 0) s.push({ wer: 'admin', art: 'adminGibtFrei', anzahl: z.aufgaben_zur_freigabe, ziel: LSA_FREIGABE })
  if (z.aufgaben_fehlen > 0) s.push({ wer: 'neu', art: 'aufgabenFehlen', anzahl: z.aufgaben_fehlen, ziel: null })
  return s.length ? s : [{ wer: 'keiner', art: 'nichtsOffen', anzahl: 0, ziel: null }]
}

export function reihenSchritte(r: InhalteReihe): Schritt[] {
  const s: Schritt[] = []
  if (r.bf_zu_pruefen > 0) s.push({ wer: 'lena', art: 'lenaPrueftBauformen', anzahl: r.bf_zu_pruefen, ziel: BAUFORMEN_PRUEFEN })
  if (r.bf_zur_freigabe > 0) s.push({ wer: 'admin', art: 'adminGibtBauformenFrei', anzahl: r.bf_zur_freigabe, ziel: BAUFORMEN_PRUEFEN })
  if (r.vid_fehlt + r.vid_in_pruefung > 0)
    s.push({ wer: 'studio', art: 'videosFehlen', anzahl: r.vid_fehlt + r.vid_in_pruefung, ziel: STUDIO })
  return s.length ? s : [{ wer: 'keiner', art: 'nichtsOffen', anzahl: 0, ziel: null }]
}

/** Monatsspanne aus zwei ISO-Daten (Europe/Berlin), z. B. „Nov. bis Jan.“; null ohne Daten. */
export function monate(von: string | null, bis: string | null, locale: string): { von: string; bis: string } | null {
  if (!von || !bis) return null
  const f = new Intl.DateTimeFormat(locale, { month: 'short', timeZone: 'Europe/Berlin' })
  return { von: f.format(new Date(`${von}T12:00:00Z`)), bis: f.format(new Date(`${bis}T12:00:00Z`)) }
}

/** Anteile für einen gestapelten Balken (Prozent, Summe 100; leer → alles 0). */
export function anteile(werte: number[]): number[] {
  const summe = werte.reduce((a, b) => a + b, 0)
  return werte.map((w) => (summe ? (w / summe) * 100 : 0))
}
