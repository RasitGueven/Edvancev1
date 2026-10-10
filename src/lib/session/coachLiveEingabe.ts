// Session-Rahmen F1 (Trockenlauf 08.10., Befund A2/A3): Eingaben des Kindes lesbar fuer die Schublade.
// session_antworten.eingabe ist kanonisch {"text": …} bzw. {"selected": […]}, je Teil eine Zeile
// (Datenvertrag 8.2 antwort_abgeben). Der Coach sieht den Wert („9“), bei Auswahl die gewaehlte Option,
// bei mehreren Teilen „a) … · b) …“. Rein: ohne Supabase, ohne React.

import type { AntwortErgebnis, KindVersuch } from '@/types/sessionLive'

type Option = { id: string; label: string }

const istObjekt = (x: unknown): x is Record<string, unknown> => typeof x === 'object' && x !== null && !Array.isArray(x)

function optionen(payload: Record<string, unknown> | undefined, teil: number | null): Option[] {
  const quelle = teil === null ? payload : (payload?.parts as unknown[] | undefined)?.find((p) => istObjekt(p) && p.nr === teil)
  const o = istObjekt(quelle) ? quelle.options : undefined
  return Array.isArray(o) ? o.filter((x): x is Option => istObjekt(x) && typeof x.id === 'string' && typeof x.label === 'string') : []
}

/** Ein Wert ohne JSON-Huelle: Text, Zahl oder die Labels der gewaehlten Optionen. */
export function eingabeWert(eingabe: unknown, payload?: Record<string, unknown>, teil: number | null = null): string {
  if (eingabe === null || eingabe === undefined) return ''
  if (typeof eingabe === 'string' || typeof eingabe === 'number') {
    const id = String(eingabe)
    return optionen(payload, teil).find((o) => o.id === id)?.label ?? id
  }
  if (Array.isArray(eingabe)) return eingabe.map((x) => eingabeWert(x, payload, teil)).join(', ')
  if (istObjekt(eingabe)) {
    if ('text' in eingabe) return eingabeWert(eingabe.text, payload, teil)
    if ('selected' in eingabe) return eingabeWert(eingabe.selected, payload, teil)
    if ('value' in eingabe) return eingabeWert(eingabe.value, payload, teil)
  }
  return JSON.stringify(eingabe)
}

/** „a)“ fuer Teil 1. */
const teilMarke = (teil: number): string => `${String.fromCharCode(96 + teil)})`

/**
 * Eine Aufgabe, ggf. mit mehreren Teilen: je Teil die juengste Antwort, „a) 3 · b) 5“. Ergebnis: richtig nur,
 * wenn jeder beantwortete Teil richtig ist; teilweise, wenn mindestens einer richtig ist.
 */
export function eingabeDerAufgabe(
  versuche: KindVersuch[],
  payload?: Record<string, unknown>,
): { eingabe: string; ergebnis: AntwortErgebnis; hinweisstufe: number } | null {
  if (versuche.length === 0) return null
  const jeTeil = new Map<number | null, KindVersuch>()
  for (const v of versuche) jeTeil.set(v.teil, v)
  const teile = [...jeTeil.values()].sort((a, b) => (a.teil ?? 0) - (b.teil ?? 0))
  const mehrteilig = teile.some((v) => v.teil !== null)
  const eingabe = teile
    .map((v) => (mehrteilig && v.teil !== null ? `${teilMarke(v.teil)} ${eingabeWert(v.eingabe, payload, v.teil)}` : eingabeWert(v.eingabe, payload, v.teil)))
    .join(' · ')
  const richtig = teile.filter((v) => v.ergebnis === 'richtig').length
  const ergebnis: AntwortErgebnis =
    teile.length === 1 ? teile[0].ergebnis : richtig === teile.length ? 'richtig' : richtig > 0 ? 'teilweise' : 'falsch'
  return { eingabe, ergebnis, hinweisstufe: Math.max(...teile.map((v) => v.hinweisstufe_max)) }
}

/** Falsche Teil-Antworten nur zur aktuellen Aufgabe (wie die Hinweise); fruehere Fehler stehen in „Heute“. */
export function falscheZurAufgabe(
  versuche: KindVersuch[],
  taskId: string | null | undefined,
  payload?: Record<string, unknown>,
): { eingabe: string; fehlbild: string | null }[] {
  if (!taskId) return []
  return versuche
    .filter((v) => v.task_id === taskId && v.ergebnis !== 'richtig')
    .map((v) => ({
      eingabe: v.teil !== null ? `${teilMarke(v.teil)} ${eingabeWert(v.eingabe, payload, v.teil)}` : eingabeWert(v.eingabe, payload, v.teil),
      fehlbild: v.fehlbild_klartext,
    }))
}
