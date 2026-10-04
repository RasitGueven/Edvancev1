// Testdaten für den gespeicherten Themenraum (W5-d). Nur von Tests und dem
// Screenshot-Lauf importiert.
//
//   a) Sitzung mit gespeichertem Themenraum, danach geänderte Kanten
//   b) alte Sitzung ohne gespeicherten Themenraum (berechnet wie #189)
//   c) Sitzung ohne Thema
//   d) Reelle Zahlen: Wurzelknoten als Thema, Brüche/Dezimalzahlen/Potenzen
//      darunter, ein Flächen-Skill unter „außerdem angesehen"
//
// Für d) stammen Einstieg, darunter, Labels, Klasse und Tiefe aus Prod
// (lsa_themenraum('reelle_zahlen') bzw. skills, Stand 04.10.2026). Die Urteile
// sind gesetzt, nicht beobachtet — eine echte Reelle-Zahlen-LSA gibt es noch nicht.

import { KANTEN, THEMA_GLEICHUNGEN } from '@/lib/report/suche.fixtures'
import type { SucheKante } from '@/lib/report/themenraum'
import type { SucheSkill } from '@/types'

const s = (
  skillKey: string,
  label: string,
  klasseHerkunft: number,
  fundamentTiefe: number,
  zustand: string,
  proben = 2,
): SucheSkill => ({ skillKey, label, fundamentTiefe, klasseHerkunft, zustand, proben, offen: false })

// ── a) gespeichert, danach geänderte Kanten ────────────────────────────────

/** So hätte lsa_finish den Raum der Sitzung 143215f5 gespeichert. */
export const GESPEICHERT_GLEICHUNGEN = {
  thema_key: 'terme_gleichungen',
  einstieg: THEMA_GLEICHUNGEN.raum.einstieg,
  darunter: THEMA_GLEICHUNGEN.raum.darunter,
  stand: '2026-09-28T09:41:12.000+00:00',
}

/**
 * Kanten nach einem späteren Inhalts-Lauf: Volumeneinheiten hängen jetzt unter
 * dem Modellieren, die beidseitigen Gleichungen nicht mehr. Gerechnet würde der
 * Report sich damit verschieben.
 */
export const KANTEN_SPAETER: SucheKante[] = [
  ...KANTEN.filter(
    (k) => !(k.skillKey === 'gleichung_modellieren' && k.voraussetzt === 'gleichung_beidseitig'),
  ),
  { skillKey: 'gleichung_modellieren', voraussetzt: 'groessen_volumen' },
]

/** Sitzung 143215f5 mit „Grundlagen fehlen" — dieselben Urteile wie FALL_A. */
export const WEAK_A = ['Grundlagen fehlen']

// ── d) Reelle Zahlen ───────────────────────────────────────────────────────

/** Prod: lsa_themenraum('reelle_zahlen') + stand, wie lsa_finish ihn schreibt. */
export const GESPEICHERT_REELLE_ZAHLEN = {
  thema_key: 'reelle_zahlen',
  einstieg: ['zahl_wurzel_irrational', 'zahl_wurzel_naeherung', 'zahl_wurzel_teilweise'],
  darunter: [
    'bruch_dezimal',
    'bruch_kuerzen',
    'dezimal_add_sub',
    'dezimal_div',
    'dezimal_mult',
    'potenzen',
    'runden_ueberschlag',
    'vorzeichen_add_sub',
    'vorzeichen_mult_div',
    'zahl_wurzel_gesetze',
    'zahl_wurzel_quadrat',
  ],
  stand: '2026-10-06T14:05:00.000+00:00',
}

export const THEMA_LABEL_REELLE_ZAHLEN = 'Reelle Zahlen und Wurzeln'

/**
 * Klasse 9, Thema Reelle Zahlen. Die Fläche liegt mit Tiefe 3 unter dem
 * Einstieg (Tiefe 6–7) — nach der alten Ebenen-Logik wäre sie als
 * „darunter geprüft" gezählt worden und hätte „Grundlagen fehlen" bestätigt.
 */
export const SITZUNG_REELLE_ZAHLEN: SucheSkill[] = [
  s('zahl_wurzel_teilweise', 'Teilweise die Wurzel ziehen', 9, 7, 'traegt_nicht'),
  s('zahl_wurzel_naeherung', 'Wurzeln abschätzen und Näherungswerte', 9, 6, 'traegt'),
  s('zahl_wurzel_irrational', 'Rationale und irrationale Zahlen', 9, 6, 'traegt_nicht'),
  s('zahl_wurzel_quadrat', 'Quadratwurzel als Umkehrung des Quadrierens', 9, 5, 'traegt'),
  s('potenzen', 'Potenzen und Quadratzahlen', 7, 4, 'traegt'),
  s('bruch_dezimal', 'Bruch in Dezimalzahl', 6, 4, 'traegt'),
  s('dezimal_div', 'Dezimalzahlen dividieren', 6, 3, 'traegt'),
  s('geo_flaeche_rechteck', 'Fläche von Rechteck und Quadrat', 5, 3, 'traegt_nicht'),
]
