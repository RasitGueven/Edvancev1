// Formularzustand des Vertrags: alles als String fuer die Inputs, beim
// Speichern zurueck in den VertragPatch (leer -> null).

import type { Vertrag, VertragPatch } from '@/types'

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
  }
}

export function toPatch(form: VertragFormState): VertragPatch {
  const patch = Object.fromEntries(
    TEXT_FELDER.map((f) => [f, form[f].trim() === '' ? null : form[f].trim()]),
  ) as VertragPatch
  patch.klasse = form.klasse === '' ? null : Number(form.klasse)
  patch.laufzeit_monate = form.laufzeit_monate === '' ? null : (Number(form.laufzeit_monate) as 6 | 12)
  return patch
}

/** Hat das Formular Aenderungen gegenueber dem gespeicherten Vertrag? */
export function isDirty(form: VertragFormState, v: Vertrag): boolean {
  const saved = toFormState(v)
  return (Object.keys(saved) as (keyof VertragFormState)[]).some((k) => saved[k] !== form[k])
}
