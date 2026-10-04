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
  'wurzeln',
  'funktionen',
  'stochastik',
  'zahlen',
  'weitere',
] as const
export type Inhaltsbereich = (typeof INHALTSBEREICHE)[number]

/**
 * skill_key-Präfix → Inhaltsbereich. Der LÄNGSTE passende Präfix gewinnt
 * (`zahl_wurzel` vor `zahl`), gemessen an ganzen Segmenten.
 *
 * Die zweistelligen Familien stehen ausdrücklich da, auch wenn ihr erstes
 * Segment schon reichen würde: Wer eine neue Familie anlegt, sieht hier, wo
 * die Nachbarn liegen. `prozent_zins_*` landet bei Prozent: Zinsen sind
 * Prozentwerte (S1-Fkt (8)). `geo_massstab` bleibt bei Geometrie, obwohl der
 * KLP den Maßstab unter Funktionen führt (E-Fkt (4)) — Eltern suchen ihn dort.
 * `zahl_potenz_*` gehört zu Potenzen, `zahl_wurzel_*` bekommt einen eigenen
 * Bereich (S2-Ari (1)–(3)): „Zahlen und Rechnen" ist die Erprobungsstufe.
 * Vollständigkeit gegen Prod: inhaltsbereiche.test.ts mit skillBestand.ts.
 */
const PRAEFIX: Readonly<Record<string, Inhaltsbereich>> = {
  bruch: 'brueche',
  dezimal: 'dezimalzahlen',
  vorzeichen: 'negative_zahlen',
  groessen: 'groessen',
  geo: 'geometrie',
  geo_flaeche: 'geometrie',
  geo_winkel: 'geometrie',
  geo_koerper: 'geometrie',
  geo_kreis: 'geometrie',
  geo_aehnlich: 'geometrie',
  geo_pythagoras: 'geometrie',
  geo_trigo: 'geometrie',
  term: 'terme',
  gleichung: 'gleichungen',
  gleichung_lgs: 'gleichungen',
  gleichung_quadr: 'gleichungen',
  prozent: 'prozent',
  prozent_zins: 'prozent',
  fkt: 'funktionen',
  fkt_linear: 'funktionen',
  fkt_quadr: 'funktionen',
  fkt_exp: 'funktionen',
  fkt_sinus: 'funktionen',
  zahl: 'zahlen',
  zahl_potenz: 'potenzen',
  zahl_wurzel: 'wurzeln',
  stoch: 'stochastik',
  stoch_bedingt: 'stochastik',
  stoch_pfad: 'stochastik',
}

/** Skills, deren Schlüssel keine Familie trägt. */
const AUSNAHMEN: Readonly<Record<string, Inhaltsbereich>> = {
  proportionalitaet: 'zuordnungen',
  potenzen: 'potenzen',
  runden_ueberschlag: 'zahlen',
}

/** Unbekannte Skills fallen auf 'weitere' — nie auf den rohen Schlüssel. */
export function inhaltsbereich(skillKey: string): Inhaltsbereich {
  if (AUSNAHMEN[skillKey]) return AUSNAHMEN[skillKey]
  const teile = skillKey.split('_')
  for (let n = teile.length - 1; n >= 1; n--) {
    const bereich = PRAEFIX[teile.slice(0, n).join('_')]
    if (bereich) return bereich
  }
  return 'weitere'
}
