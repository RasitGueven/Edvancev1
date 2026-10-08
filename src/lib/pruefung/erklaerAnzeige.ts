// Erklaersequenzen pruefen (L6): reine Anzeige-Logik ohne React — Formeln als SVG oder Quelltext,
// Gruppen nach Thema, Admin-Filter, Texte fuer „was fehlt zur Freigabe“.

import type { ErklaerFehlt, ErklaerGrund, ErklaerListenZeile, ErklaerSchritt, ErklaerVariante } from '@/types/erklaerPruefung'

export const ERKLAER_GRUENDE: ErklaerGrund[] = [
  'fachlich_falsch', 'unklar', 'zu_lang', 'sprache_klassenstufe', 'formel_bild_fehlerhaft',
  'variante_fehlbild', 'check_passt_nicht', 'sonstiges',
]

/** Dasselbe Muster wie erklaer_formel_anzahl in SQL: $…$ ohne $ dazwischen. */
const FORMEL = /\$[^$]+\$/g

/** Anker fuer eine Formel ohne SVG; die Kinderansicht zeigt dort den Quelltext mit Hinweis. */
export const FORMEL_FEHLT = '#formel-fehlt'

function alsAlt(quelle: string): string {
  return quelle.replace(/[\\[\]]/g, '\\$&')
}

/**
 * Ersetzt die i-te Formel durch ein Markdown-Bild mit der i-ten SVG-URL. Fehlt die SVG (noch nicht erzeugt
 * oder Text geaendert), steht dort ein Bild mit dem Anker FORMEL_FEHLT; der Quelltext ist der Alt-Text.
 */
export function mitFormelBildern(inhalt: string, formeln: string[]): { markdown: string; fehlen: number } {
  let i = 0
  let fehlen = 0
  const markdown = inhalt.replace(FORMEL, (treffer) => {
    const quelle = treffer.slice(1, -1).trim()
    const url = formeln[i++]
    if (!url) fehlen++
    return `![${alsAlt(quelle)}](${url ?? FORMEL_FEHLT})`
  })
  return { markdown, fehlen }
}

export function formelAnzahl(inhalt: string): number {
  return inhalt.match(FORMEL)?.length ?? 0
}

/** Varianten, die es gibt, in Reihenfolge A, B, C. */
export function variantenVon(schritte: ErklaerSchritt[]): ErklaerVariante[] {
  return (['A', 'B', 'C'] as const).filter((v) => schritte.some((s) => s.variante === v))
}

export type ThemenGruppe = { key: string; label: string | null; zeilen: ErklaerListenZeile[] }

/** Gruppen nach Thema in der Reihenfolge des ersten Auftretens; innen bleibt die Server-Reihenfolge (offen zuerst). */
export function nachThema(zeilen: ErklaerListenZeile[]): ThemenGruppe[] {
  const gruppen = new Map<string, ThemenGruppe>()
  for (const z of zeilen) {
    const key = z.thema_key ?? `skill:${z.skill_key}`
    const g = gruppen.get(key) ?? { key, label: z.thema_label, zeilen: [] }
    g.zeilen.push(z)
    gruppen.set(key, g)
  }
  return [...gruppen.values()]
}

export type AdminFilter = 'alle' | 'bereit' | 'rueckfragen'

export function filtereErklaer(zeilen: ErklaerListenZeile[], filter: AdminFilter): ErklaerListenZeile[] {
  if (filter === 'bereit') return zeilen.filter((z) => z.bereit)
  if (filter === 'rueckfragen') return zeilen.filter((z) => z.rueckfrage)
  return zeilen
}

export function zaehleFilter(zeilen: ErklaerListenZeile[]): Record<AdminFilter, number> {
  return {
    alle: zeilen.length,
    bereit: zeilen.filter((z) => z.bereit).length,
    rueckfragen: zeilen.filter((z) => z.rueckfrage).length,
  }
}

/** Naechste offene Kernidee nach der aktuellen (sonst die erste offene), fuer „weiter“ nach einer Entscheidung. */
export function naechsteOffeneKernidee(zeilen: ErklaerListenZeile[], aktuell: string | null): string | null {
  const offen = zeilen.filter((z) => z.stand === 'offen' && z.kernidee_id !== aktuell)
  const ab = aktuell ? zeilen.findIndex((z) => z.kernidee_id === aktuell) : -1
  return (offen.find((z) => zeilen.indexOf(z) > ab) ?? offen[0])?.kernidee_id ?? null
}

/** i18n-Schluessel und Werte fuer einen Eintrag aus erklaer_freigabe_fehlt. */
export function fehltText(f: ErklaerFehlt): { key: string; werte: Record<string, string | number> } {
  if (f.was === 'checks') return { key: 'fehlt.checks', werte: { soll: f.soll, ist: f.ist, count: f.soll - f.ist } }
  if ('variante' in f) return { key: `fehlt.${f.was}`, werte: { variante: f.variante, art: f.art } }
  return { key: `fehlt.${f.was}`, werte: {} }
}

/** Badge-Variante je Status einer Kernidee oder eines Schritts. */
export const STATUS_VARIANTE = { entwurf: 'muted', geprueft: 'primary', freigegeben: 'strength' } as const

/** Textfarbe je Stand in der Liste (gruen = gut, gelb = aufmerksam, rot = handeln). */
export const STAND_FARBE: Record<string, string> = {
  offen: 'text-[var(--color-text-secondary)]',
  unsicher: 'text-[var(--color-warning)]',
  passt_nicht: 'text-[var(--color-destructive)]',
  passt: 'text-[var(--color-success)]',
  freigegeben: 'text-[var(--color-success)]',
}

/** Zeitpunkt fuer Protokoll und Liste: Datum und Uhrzeit in Europe/Berlin (CLAUDE.md §10, §12). */
export function berlinZeit(iso: string, sprache: string): string {
  return new Intl.DateTimeFormat(sprache, {
    timeZone: 'Europe/Berlin', day: '2-digit', month: '2-digit', year: 'numeric', hour: '2-digit', minute: '2-digit',
  }).format(new Date(iso))
}
