// Eine Aenderung (task_pruefungen.aenderungen bzw. lokaleAenderungen) als Satz fuer Lena und Admins:
// "Richtige Antwort: −24 → 24". Texte aus pruefen.json; die Uebersetzung kommt als Funktion rein.

import type { PruefAenderung } from '@/types'

type T = (key: string, opts?: Record<string, unknown>) => string

export type Namen = {
  fehlbild: (slug: string) => string
  fertigkeit: (key: string) => string
  option: (id: string) => string
}

const minus = (s: string): string => s.replace(/-/g, '−')
const teilLabel = (nr: number | null): string => (nr === null ? '' : `${String.fromCharCode(96 + nr)})`)

function liste(t: T, v: unknown, namen: Namen, mc: boolean): string {
  const werte = Array.isArray(v) ? (v as string[]) : []
  if (werte.length === 0) return t('antwort.keine')
  return werte.map((w) => (mc ? namen.option(w) : minus(w))).join(' / ')
}

type Regel = { art?: string; mitte?: string | null; toleranz?: string | number | null } | null

function regel(t: T, r: Regel): string {
  if (!r || r.art !== 'bereich') return t('aenderungen.wertungWert')
  const m = Number(String(r.mitte ?? '').replace(/[−–]/g, '-').replace(',', '.'))
  const tol = Number(String(r.toleranz ?? '').replace(',', '.'))
  if (!Number.isFinite(m) || !Number.isFinite(tol)) return t('aenderungen.wertungWert')
  const fmt = (n: number): string => minus(String(Math.round(n * 1000) / 1000).replace('.', ','))
  return t('aenderungen.wertungBereich', { von: fmt(m - tol), bis: fmt(m + tol) })
}

type Fehler = { slug: string; werte?: { teil: number | null; wert: string }[] } | null

const fehlerWerte = (f: Fehler, namen: Namen, mc: boolean): string =>
  (f?.werte ?? []).map((w) => `${w.teil !== null ? `${teilLabel(w.teil)} ` : ''}${mc ? namen.option(w.wert) : minus(w.wert)}`).join(' / ')

export function aenderungText(t: T, a: PruefAenderung, namen: Namen, mc = false): string {
  switch (a.feld) {
    case 'richtige_antwort':
      return a.teil === null
        ? t('aenderungen.richtigeAntwort', { vorher: liste(t, a.vorher, namen, mc), nachher: liste(t, a.nachher, namen, mc) })
        : t('aenderungen.richtigeAntwortTeil', { teil: teilLabel(a.teil), vorher: liste(t, a.vorher, namen, mc), nachher: liste(t, a.nachher, namen, mc) })
    case 'wertung':
      return t('aenderungen.wertung', { vorher: regel(t, a.vorher as Regel), nachher: regel(t, a.nachher as Regel) })
    case 'einheit_pflicht':
      return t('aenderungen.einheit', {
        vorher: t(a.vorher ? 'aenderungen.ja' : 'aenderungen.nein'),
        nachher: t(a.nachher ? 'aenderungen.ja' : 'aenderungen.nein'),
      })
    case 'typischer_fehler': {
      const v = a.vorher as Fehler
      const n = a.nachher as Fehler
      if (!n && v) return t('aenderungen.fehlerEntfernt', { name: namen.fehlbild(v.slug), werte: fehlerWerte(v, namen, mc) })
      if (n && !v) return t('aenderungen.fehlerErgaenzt', { name: namen.fehlbild(n.slug), werte: fehlerWerte(n, namen, mc) })
      return t('aenderungen.fehlerGeaendert', { name: namen.fehlbild(n?.slug ?? ''), werte: fehlerWerte(n, namen, mc) })
    }
    case 'fertigkeit':
      return t('aenderungen.fertigkeit', { vorher: namen.fertigkeit(String(a.vorher ?? '')), nachher: namen.fertigkeit(String(a.nachher ?? '')) })
    case 'anforderungsbereich':
      return t('aenderungen.afb', { vorher: String(a.vorher ?? ''), nachher: String(a.nachher ?? '') })
    case 'hinweis':
      if (a.vorher === null) return t('aenderungen.hinweisNeu', { stufe: a.teil, nachher: String(a.nachher ?? '') })
      if (a.nachher === null) return t('aenderungen.hinweisWeg', { stufe: a.teil, vorher: String(a.vorher) })
      return t('aenderungen.hinweis', { stufe: a.teil, vorher: String(a.vorher), nachher: String(a.nachher) })
    case 'hinweis_status':
      return t('aenderungen.hinweisStatus', {
        stufe: a.teil, vorher: t(`hinweise.status.${String(a.vorher)}`), nachher: t(`hinweise.status.${String(a.nachher)}`),
      })
  }
}
