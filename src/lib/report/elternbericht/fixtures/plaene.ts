// Themen des Kernlehrplans und der Schulplan des Friedrich-Wilhelm-Gymnasiums für den Lernweg (R7-9).
// Stand Prod 20.10.2026, dbread nur lesend:
//   select thema_key, klasse, label, stufe, sort from themen where fach = 'mathematik'
//   select klasse, position, thema_key, uv_titel, halbjahr from schul_themenplan
//     where schule_id = <FWG> and klasse in (9, 10)
// Nur von Tests und der Vorschau importiert.

import type { KlpThema, SchulplanZeile } from '@/lib/report/elternbericht/plan'

/** [thema_key, klasse, label, stufe, sort] */
const THEMEN_ROH: readonly (readonly [string, number, string, KlpThema['stufe'], number | null])[] = [
  ['natuerliche_zahlen', 5, 'Natürliche Zahlen und Größen', 'erprobung', 10],
  ['rechnen_natuerliche_zahlen', 5, 'Rechnen mit natürlichen Zahlen', 'erprobung', 20],
  ['daten_streumasse', 5, 'Daten, Diagramme und Kenngrößen', 'erprobung', 30],
  ['geometrische_grundbegriffe', 5, 'Geometrische Grundbegriffe und Figuren', 'erprobung', 40],
  ['symmetrie', 5, 'Symmetrie und Abbildungen', 'erprobung', 50],
  ['teilbarkeit', 5, 'Teilbarkeit und Primzahlen', 'erprobung', 60],
  ['flaeche_umfang', 5, 'Flächen und Umfang', 'erprobung', 70],
  ['koerper_quader', 5, 'Körper, Netze und Quadervolumen', 'erprobung', 80],
  ['brueche', 5, 'Brüche und Anteile', 'erprobung', 90],
  ['rechnen_brueche_dezimalzahlen', 5, 'Rechnen mit Brüchen und Dezimalzahlen', 'erprobung', 100],
  ['winkel', 5, 'Winkel und Kreise', 'erprobung', 110],
  ['ganze_zahlen_groessen', 5, 'Negative Zahlen, Zuordnungen und Dreisatz', 'erprobung', 120],
  ['rationale_zahlen', 7, 'Rationale Zahlen', 'erste', 210],
  ['zuordnungen', 7, 'Proportionale und antiproportionale Zuordnungen', 'erste', 220],
  ['zinsrechnung', 7, 'Prozent- und Zinsrechnung', 'erste', 230],
  ['terme_gleichungen', 7, 'Terme und Gleichungen', 'erste', 240],
  ['winkel_dreiecke', 7, 'Winkelsätze, Dreiecke und Konstruktionen', 'erste', 250],
  ['lineare_funktionen', 7, 'Lineare Funktionen', 'erste', 260],
  ['terme_binomische_formeln', 7, 'Terme mit mehreren Variablen und binomische Formeln', 'erste', 270],
  ['zufallsexperimente', 7, 'Zufall und Wahrscheinlichkeit', 'erste', 280],
  ['flaechen_vielecke', 7, 'Flächen von Dreiecken und Vierecken', 'erste', 290],
  ['lineare_gleichungen_lgs', 7, 'Lineare Gleichungssysteme', 'erste', 300],
  ['thales_konstruktionen', 7, 'Kreise und Dreiecke: Thales und besondere Linien', 'erste', 310],
  ['reelle_zahlen', 9, 'Reelle Zahlen und Wurzeln', 'zweite', 410],
  ['potenzen', 9, 'Potenzen', 'zweite', 420],
  ['quadratische_funktionen', 9, 'Quadratische Funktionen', 'zweite', 430],
  ['quadratische_gleichungen', 9, 'Quadratische Gleichungen', 'zweite', 440],
  ['pythagoras', 9, 'Satz des Pythagoras', 'zweite', 450],
  ['aehnlichkeit', 9, 'Ähnlichkeit und zentrische Streckung', 'zweite', 460],
  ['kreis', 9, 'Kreis: Umfang und Fläche', 'zweite', 470],
  ['prismen_zylinder', 9, 'Prismen und Zylinder', 'zweite', 480],
  ['koerper_pyramide_kegel_kugel', 9, 'Pyramide, Kegel und Kugel', 'zweite', 490],
  ['trigonometrie', 9, 'Trigonometrie', 'zweite', 500],
  ['exponentialfunktionen', 9, 'Exponentielles Wachstum', 'zweite', 510],
  ['sinusfunktion', 9, 'Sinusfunktion und periodische Vorgänge', 'zweite', 520],
  ['bedingte_wahrscheinlichkeit', 9, 'Bedingte Wahrscheinlichkeit', 'zweite', 530],
  ['statistik_beurteilen', 9, 'Statistische Erhebungen beurteilen', 'zweite', 540],
]

export const THEMEN: readonly KlpThema[] = THEMEN_ROH.map(([themaKey, klasse, label, stufe, sort]) => ({
  themaKey,
  klasse,
  label,
  stufe,
  sort,
}))

export const FWG_NAME = 'Friedrich-Wilhelm-Gymnasium'

/** [klasse, position, thema_key, uv_titel, halbjahr] */
const FWG_ROH: readonly (readonly [number, number, string | null, string, 1 | 2 | null])[] = [
  [9, 1, 'reelle_zahlen', 'Reelle Zahlen', null],
  [9, 2, 'quadratische_funktionen', 'Quadratische Funktionen', null],
  [9, 3, 'kreis', 'Kreise, Prismen und Zylinder', null],
  [9, 4, 'potenzen', 'Potenzen und Potenzgesetze', null],
  [9, 5, 'pythagoras', 'Der Satz des Pythagoras und Berechnungen in Körpern', null],
  [9, 6, 'bedingte_wahrscheinlichkeit', 'Daten und Wahrscheinlichkeit', null],
  [10, 1, 'bedingte_wahrscheinlichkeit', 'Daten und Wahrscheinlichkeit', null],
  [10, 2, 'quadratische_gleichungen', 'Quadratische Funktionen und Gleichungen', null],
  [10, 3, 'aehnlichkeit', 'Ähnlichkeit', null],
  [10, 4, 'exponentialfunktionen', 'Exponentialfunktionen', null],
  [10, 5, 'trigonometrie', 'Trigonometrie', null],
  [10, 6, 'sinusfunktion', 'Trigonometrische Funktionen', null],
]

export const FWG_PLAN: readonly SchulplanZeile[] = FWG_ROH.map(([klasse, position, themaKey, titel, halbjahr]) => ({
  klasse,
  position,
  themaKey,
  titel,
  halbjahr,
}))
