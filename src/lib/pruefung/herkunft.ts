// Herkunft einer Aenderung in der Admin-Pruefansicht (Bauauftrag B 6): Ein Eintrag traegt „Lena“, wenn
// derselbe Eintrag (feld, teil, nachher) in Lenas letzter Entscheidung steht (task_pruefungen.aenderungen),
// sonst „Team“. Keine neue Spalte; verglichen wird ueber einen Schluessel, der die Schreibweisen von Server
// (pruef_aenderungen) und Client (lokaleAenderungen) angleicht.

import type { PruefAenderung } from '@/types'
import { zahlVon } from './entwurf'

export type Herkunft = 'lena' | 'team'

const minus = (s: unknown): string => String(s ?? '').replace(/[−–]/g, '-').trim()

function nachher(a: PruefAenderung): string {
  const n = a.nachher as unknown
  switch (a.feld) {
    case 'richtige_antwort':
      return JSON.stringify((Array.isArray(n) ? n : []).map(minus))
    case 'wertung': {
      const r = (n ?? null) as { art?: string; mitte?: unknown; toleranz?: unknown } | null
      if (!r || r.art !== 'bereich') return 'wert'
      return `bereich|${zahlVon(minus(r.mitte))}|${zahlVon(String(r.toleranz ?? ''))}`
    }
    case 'typischer_fehler': {
      const f = (n ?? null) as { slug?: string; text?: string | null; werte?: { teil: number | null; wert: string }[] } | null
      if (!f) return 'weg'
      const werte = (f.werte ?? []).map((w) => `${w.teil ?? ''}|${minus(w.wert)}`).sort()
      return JSON.stringify([f.slug ?? '', (f.text ?? '').trim(), werte])
    }
    default:
      return JSON.stringify(n ?? null)
  }
}

/** Vergleichsschluessel einer Aenderung: Feld, Teil, nachher. */
export function aenderungSchluessel(a: PruefAenderung): string {
  const slug = a.feld === 'typischer_fehler'
    ? ((a.nachher ?? a.vorher) as { slug?: string } | null)?.slug ?? ''
    : ''
  return `${a.feld}|${a.teil ?? ''}|${slug}|${nachher(a)}`
}

export function herkunftVon(a: PruefAenderung, lena: PruefAenderung[] | null | undefined): Herkunft {
  const k = aenderungSchluessel(a)
  return (lena ?? []).some((l) => aenderungSchluessel(l) === k) ? 'lena' : 'team'
}
