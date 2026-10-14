// Formularzustand des Vertrags: alles als String fuer die Inputs, beim
// Speichern zurueck in den VertragPatch (leer -> null).

import type { PilotVorschlag } from '@/lib/supabase/vertragEnde'
import type { Vertrag, Vertragsart, VertragPatch } from '@/types'

export const TEXT_FELDER = [
  'eltern_vorname',
  'eltern_nachname',
  'strasse',
  'hausnummer',
  'plz',
  'ort',
  'eltern_telefon',
  'eltern_email',
  'kind_vorname',
  'kind_nachname',
  'kind_geburtsdatum',
  'fach',
  'schule',
  'schule_id',
  'tier_id',
  'vertragsbeginn',
  'kontoinhaber',
] as const

type TextFeld = (typeof TEXT_FELDER)[number]

export type VertragFormState = Record<TextFeld, string> & {
  klasse: string
  laufzeit_monate: string
  /** Neu eingegebene IBAN; leer = hinterlegte bleibt. */
  iban: string
  /** V5: Vertragsart; beim Pilot gibt der Admin Ende und Einheiten vor. */
  vertragsart: Vertragsart
  vertrag_ende: string
  einheiten: string
}

export function toFormState(v: Vertrag): VertragFormState {
  const state = Object.fromEntries(TEXT_FELDER.map((f) => [f, v[f] ?? ''])) as Record<
    TextFeld,
    string
  >
  return {
    ...state,
    klasse: v.klasse !== null ? String(v.klasse) : '',
    laufzeit_monate: v.laufzeit_monate !== null ? String(v.laufzeit_monate) : '',
    iban: '',
    vertragsart: v.vertragsart ?? 'regulaer',
    // Beim regulaeren Vertrag rechnet die Datenbank Ende und Einheiten — das Formular fasst sie nicht an.
    vertrag_ende: v.vertragsart === 'pilot' ? (v.vertrag_ende ?? '') : '',
    einheiten: v.vertragsart === 'pilot' && v.einheiten !== null ? String(v.einheiten) : '',
  }
}

export function toPatch(form: VertragFormState): VertragPatch {
  const patch = Object.fromEntries(
    TEXT_FELDER.map((f) => [f, form[f].trim() === '' ? null : form[f].trim()]),
  ) as VertragPatch
  patch.klasse = form.klasse === '' ? null : Number(form.klasse)
  patch.laufzeit_monate = form.laufzeit_monate === '' ? null : (Number(form.laufzeit_monate) as 6 | 12)
  patch.vertragsart = form.vertragsart
  if (form.vertragsart === 'pilot') {
    // Pilot: kein Paket, keine Laufzeit (der Guard in der Datenbank haelt das ebenso fest).
    patch.tier_id = null
    patch.laufzeit_monate = null
    patch.vertrag_ende = form.vertrag_ende === '' ? null : form.vertrag_ende
    patch.einheiten = form.einheiten.trim() === '' ? null : Number(form.einheiten)
  }
  return patch
}

/**
 * Den Vorschlag (vertrag_pilot_vorschlag) ins Formular uebernehmen — automatisch
 * nur, solange Ende und Einheiten leer sind; eine Eingabe des Admins bleibt stehen.
 */
export function pilotVorschlagFuellen(
  form: VertragFormState,
  vorschlag: PilotVorschlag | null,
): Partial<VertragFormState> | null {
  if (form.vertragsart !== 'pilot' || !vorschlag) return null
  if (form.vertrag_ende !== '' || form.einheiten !== '') return null
  return { vertrag_ende: vorschlag.ende, einheiten: String(vorschlag.einheiten) }
}

/** Einheiten sind eine ganze Zahl groesser 0. */
export function einheitenGueltig(wert: string): boolean {
  return /^\d+$/.test(wert.trim()) && Number(wert) > 0
}

/** Hat das Formular Aenderungen gegenueber dem gespeicherten Vertrag? */
export function isDirty(form: VertragFormState, v: Vertrag): boolean {
  const saved = toFormState(v)
  return (Object.keys(saved) as (keyof VertragFormState)[]).some((k) => saved[k] !== form[k])
}
