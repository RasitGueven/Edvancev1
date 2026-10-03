// Eltern-Report — Lehrplanstufe und Inhaltsbereich je Skill (W2-7).
//
// Beides ist reine Zuordnung, keine Datenbank. Die Stufe folgt aus
// skills.klasse_herkunft, geprüft gegen den Kernlehrplan G9 NRW
// (docs/report/stufen-pruefung.md). Kürzel dort: E-Fkt (2) = Erprobungsstufe,
// Funktionen, Erwartung (2); S1 = Erste Stufe; S2 = Zweite Stufe.

import type { Stufe } from '@/types'

/** Kl. 5/6 Erprobungsstufe, 7/8 Erste Stufe, 9/10 Zweite Stufe. */
export function stufeAusKlasse(klasse: number): Stufe {
  if (klasse <= 6) return 'erprobung'
  if (klasse <= 8) return 'erste'
  return 'zweite'
}

/** Anzeigereihenfolge: die höhere Stufe zuerst, also näher am Thema. */
export const STUFEN_ABSTEIGEND: readonly Stufe[] = ['zweite', 'erste', 'erprobung']

/**
 * Die Inhaltsbereiche in Anzeigereihenfolge. Anzeige über i18n
 * (report:suche.bereich.<key>), nie der Schlüssel selbst.
 */
export const INHALTSBEREICHE = [
  'brueche',
  'dezimalzahlen',
  'negative_zahlen',
  'groessen',
  'geometrie',
  'terme',
  'gleichungen',
  'prozent',
  'zuordnungen',
  'potenzen',
  'funktionen',
  'zahlen',
  'weitere',
] as const
export type Inhaltsbereich = (typeof INHALTSBEREICHE)[number]

/**
 * skill_key-Familie (Teil vor dem ersten Unterstrich) → Inhaltsbereich.
 *
 * `prozent_zins_*` landet über die Familie bei Prozent: Zinsen sind
 * Prozentwerte (S1-Fkt (8)). `geo_massstab` bleibt bei Geometrie, obwohl der
 * KLP den Maßstab unter Funktionen führt (E-Fkt (4)) — Eltern suchen ihn dort.
 */
const FAMILIE: Readonly<Record<string, Inhaltsbereich>> = {
  bruch: 'brueche',
  dezimal: 'dezimalzahlen',
  vorzeichen: 'negative_zahlen',
  groessen: 'groessen',
  geo: 'geometrie',
  term: 'terme',
  gleichung: 'gleichungen',
  prozent: 'prozent',
  fkt: 'funktionen',
}

/** Skills, deren Schlüssel keine Familie trägt. */
const AUSNAHMEN: Readonly<Record<string, Inhaltsbereich>> = {
  proportionalitaet: 'zuordnungen',
  potenzen: 'potenzen',
  runden_ueberschlag: 'zahlen',
}

/** Unbekannte Skills fallen auf 'weitere' — nie auf den rohen Schlüssel. */
export function inhaltsbereich(skillKey: string): Inhaltsbereich {
  return AUSNAHMEN[skillKey] ?? FAMILIE[skillKey.split('_')[0]] ?? 'weitere'
}
