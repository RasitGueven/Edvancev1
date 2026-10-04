// Testdaten für „Wie wir gesucht haben" (W2-7). Nur von Tests importiert.
//
// Fall a) ist die echte Sitzung 143215f5 vom 28.09.2026 — die aus dem
// Screenshot, in der Volumeneinheiten und Brüche „unter" den Gleichungen
// standen. Urteile, Probenzahl und offen wörtlich aus lsa_skill_urteil;
// klasse_herkunft nach der Stufen-Migration 20261003092318.

import type { SucheEingabe } from '@/lib/report/suche'
import { berechneThemenraum, type SucheKante } from '@/lib/report/themenraum'
import type { SucheSkill } from '@/types'

const s = (
  skillKey: string,
  label: string,
  klasseHerkunft: number,
  zustand: string,
  proben = 1,
  offen = false,
): SucheSkill => ({ skillKey, label, fundamentTiefe: 1, klasseHerkunft, zustand, proben, offen })

/** skill_kante unterhalb von gleichung_modellieren, Stand Prod 03.10.2026. */
export const KANTEN: SucheKante[] = [
  ['dezimal_mult', 'dezimal_add_sub'],
  ['dezimal_div', 'dezimal_mult'],
  ['vorzeichen_mult_div', 'vorzeichen_add_sub'],
  ['term_zusammenfassen', 'vorzeichen_add_sub'],
  ['term_ausmultiplizieren', 'term_zusammenfassen'],
  ['term_ausmultiplizieren', 'vorzeichen_mult_div'],
  ['gleichung_einschrittig', 'vorzeichen_add_sub'],
  ['gleichung_einschrittig', 'dezimal_div'],
  ['gleichung_zweischrittig', 'gleichung_einschrittig'],
  ['gleichung_beidseitig', 'gleichung_zweischrittig'],
  ['gleichung_beidseitig', 'term_zusammenfassen'],
  ['gleichung_modellieren', 'gleichung_zweischrittig'],
  ['gleichung_modellieren', 'gleichung_beidseitig'],
  ['gleichung_modellieren', 'term_ausmultiplizieren'],
  // Kanten der übrigen geprüften Skills — sie führen NICHT in den Abschluss.
  ['bruch_div', 'bruch_mult'],
  ['groessen_volumen', 'groessen_flaechen'],
  ['prozent_veraenderung', 'prozent_prozentwert'],
  ['prozent_veraenderung', 'prozent_grundwert'],
  ['geo_flaeche_dreieck', 'geo_flaeche_rechteck'],
  ['geo_flaeche_dreieck', 'dezimal_div'],
].map(([skillKey, voraussetzt]) => ({ skillKey, voraussetzt }))

/** Prod: lsa_abschluss('gleichung_modellieren'), sortiert. */
export const ABSCHLUSS_MODELLIEREN = [
  'dezimal_add_sub',
  'dezimal_div',
  'dezimal_mult',
  'gleichung_beidseitig',
  'gleichung_einschrittig',
  'gleichung_zweischrittig',
  'term_ausmultiplizieren',
  'term_zusammenfassen',
  'vorzeichen_add_sub',
  'vorzeichen_mult_div',
]

/** Thema der Gleichungen, Raum berechnet aus KANTEN (alte Sitzung ohne gespeicherten Raum). */
export const THEMA_GLEICHUNGEN = {
  themaLabel: 'Terme und Gleichungen',
  raum: berechneThemenraum('terme_gleichungen', ['gleichung_modellieren'], KANTEN),
}

const SITZUNG_143215F5: SucheSkill[] = [
  s('gleichung_modellieren', 'Gleichungen aufstellen (Sachkontext)', 8, 'traegt_nicht', 2),
  s('prozent_veraenderung', 'Prozentuale Veränderung', 7, 'traegt'),
  s('gleichung_beidseitig', 'Beidseitige Gleichungen', 7, 'traegt'),
  s('term_ausmultiplizieren', 'Ausmultiplizieren', 7, 'traegt'),
  s('groessen_volumen', 'Volumeneinheiten', 6, 'traegt_nicht', 2),
  s('groessen_flaechen', 'Flächeneinheiten', 6, 'traegt_teilweise', 2),
  s('groessen_gemischt', 'Gemischte Schreibweise', 6, 'traegt'),
  s('geo_flaeche_dreieck', 'Fläche von Dreieck und Parallelogramm', 7, 'traegt_nicht', 2),
  s('geo_flaeche_rechteck', 'Fläche von Rechteck und Quadrat', 5, 'traegt_teilweise', 2),
  s('bruch_div', 'Brüche dividieren', 6, 'traegt_nicht', 2),
  s('bruch_mult', 'Brüche multiplizieren', 6, 'traegt_nicht', 2),
  s('bruch_kuerzen', 'Brüche kürzen', 6, 'traegt'),
]

/** a) die echte Sitzung, mit Thema der Gleichungen. */
export const FALL_A: SucheEingabe = {
  skills: SITZUNG_143215F5,
  ...THEMA_GLEICHUNGEN,
}

/** b) dieselbe Sitzung als alte Sitzung: thema_key NULL. */
export const FALL_B: SucheEingabe = {
  skills: SITZUNG_143215F5,
  themaLabel: null,
  raum: null,
}

/** c) Thema sofort sicher, danach nur Breite. */
export const FALL_C: SucheEingabe = {
  skills: [
    s('gleichung_modellieren', 'Gleichungen aufstellen (Sachkontext)', 8, 'traegt'),
    s('prozent_grundwert', 'Grundwert berechnen', 7, 'traegt'),
    s('bruch_add', 'Brüche addieren', 6, 'traegt_nicht', 2),
    // Provisorisch: MC richtig, Zweitprobe stand aus.
    s('groessen_laengen', 'Längen umrechnen', 5, 'traegt', 1, true),
  ],
  ...THEMA_GLEICHUNGEN,
}

/** d) Thema gewählt, für das noch kein Einstiegsknoten hinterlegt ist. */
export const FALL_D: SucheEingabe = {
  skills: [
    s('proportionalitaet', 'Dreisatz, proportional und antiproportional', 7, 'traegt'),
    s('bruch_kuerzen', 'Brüche kürzen', 6, 'traegt'),
    s('dezimal_mult', 'Dezimalzahlen multiplizieren', 6, 'traegt_nicht', 1, true),
  ],
  themaLabel: 'Proportionale und antiproportionale Zuordnungen',
  raum: berechneThemenraum('zuordnungen', [], KANTEN),
}
