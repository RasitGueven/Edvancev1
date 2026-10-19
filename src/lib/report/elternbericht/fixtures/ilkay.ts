// Ilkays echte Analyse vom 20.09.2026 (Sitzung 6d868c5f…, Klasse 10, testlauf
// false) als Fixture für den Eltern-Bericht R7. Nur von Tests und der Vorschau
// importiert.
//
// Gelesen am 19.10.2026 über dbread, Auswahl über die ID (genau eine Zeile).
// Urteile, Probenzahl und offen wörtlich aus lsa_skill_urteil (belegt_direkt),
// Label, Tiefe und klasse_herkunft aus skills. Der Themenraum ist der
// nachgetragene aus result_summary (W5-d). Ersetzt: die Sitzungs-ID durch einen
// festen Platzhalter. Keine weiteren personenbezogenen Daten — Rufname wie im
// Muster, Schulform als Art, keine Schule, keine Mail der Familie.

import { datenAus, u, type SitzungRoh } from '@/lib/report/elternbericht/fixtures/basis'
import { themenraumFuer } from '@/lib/report/themenraum'
import type { ReportData } from '@/types'

export const ILKAY_SESSION = '00000000-0000-4000-8000-0000000000e7'

/** lsa_skill_urteil × skills: key, label, tiefe, klasse, zustand, proben, offen. */
export const ILKAY_URTEILE = [
  u('bruch_add', 'Brüche addieren', 2, 6, 'traegt_nicht', 2, false),
  u('bruch_dezimal', 'Bruch in Dezimalzahl', 4, 6, 'traegt', 1, false),
  u('bruch_div', 'Brüche dividieren', 3, 6, 'traegt_nicht', 2, false),
  u('bruch_kuerzen', 'Brüche kürzen', 1, 6, 'traegt', 1, false),
  u('bruch_mult', 'Brüche multiplizieren', 2, 6, 'traegt_nicht', 2, false),
  u('geo_flaeche_dreieck', 'Fläche von Dreieck und Parallelogramm', 4, 7, 'traegt_nicht', 2, false),
  u('geo_flaeche_rechteck', 'Fläche von Rechteck und Quadrat', 3, 5, 'traegt', 1, false),
  u('geo_massstab', 'Maßstab', 5, 6, 'traegt_nicht', 2, false),
  u('geo_umfang', 'Umfang von Rechteck und Dreieck', 3, 5, 'traegt_nicht', 2, false),
  u('geo_volumen_quader', 'Volumen und Oberfläche des Quaders', 4, 6, 'traegt_nicht', 2, false),
  u('geo_winkel_summe', 'Winkelsummen im Dreieck und Viereck', 3, 7, 'traegt_nicht', 2, false),
  u('gleichung_modellieren', 'Gleichungen aufstellen (Sachkontext)', 8, 8, 'traegt', 1, false),
  u('gleichung_neg_koeffizient', 'Gleichungen mit negativem Koeffizienten', 7, 7, 'traegt', 1, false),
  u('groessen_flaechen', 'Flächeneinheiten', 5, 6, 'traegt_nicht', 2, false),
  u('groessen_gemischt', 'Gemischte Schreibweise', 5, 6, 'traegt', 1, false),
  u('groessen_laengen', 'Längen umrechnen', 3, 5, 'traegt', 1, false),
  u('groessen_massen', 'Massen umrechnen', 3, 5, 'traegt', 1, false),
  u('groessen_volumen', 'Volumeneinheiten', 6, 6, 'traegt_nicht', 2, false),
  u('potenzen', 'Potenzen und Quadratzahlen', 4, 7, 'traegt', 1, false),
  u('prozent_grundwert', 'Grundwert berechnen', 7, 7, 'traegt_nicht', 2, false),
  u('prozent_prozentsatz', 'Prozentsatz berechnen', 7, 7, 'traegt_nicht', 2, false),
  u('prozent_prozentwert', 'Prozentwert berechnen', 6, 7, 'traegt', 1, false),
  u('prozent_veraenderung', 'Prozentuale Veränderung', 8, 7, 'traegt_teilweise', 2, false),
  u('runden_ueberschlag', 'Runden und Überschlag', 2, 5, 'traegt', 1, false),
  u('term_ausklammern', 'Ausklammern', 7, 7, 'traegt_nicht', 2, false),
  u('term_minusklammer', 'Minusklammer auflösen', 6, 7, 'traegt_nicht', 2, false),
  u('vorzeichen_vorrang', 'Vorrangregeln mit Vorzeichen', 4, 7, 'traegt_teilweise', 2, false),
]

const RAUM = themenraumFuer({
  themaKey: 'terme_gleichungen',
  gespeichert: {
    stand: 'nachgetragen',
    thema_key: 'terme_gleichungen',
    einstieg: ['gleichung_modellieren'],
    darunter: [
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
    ],
  },
  einstieg: [],
  kanten: [],
})

export const ILKAY_ROH: SitzungRoh = {
  sessionId: ILKAY_SESSION,
  firstName: 'Ilkay',
  grade: 10,
  analysedAt: '2026-09-20T15:51:33.261Z',
  aufgaben: 43,
  testlauf: false,
  schulform: 'Gesamtschule',
  // leads.current_topic_cluster_id → skill_clusters.name
  naechstesThema: 'Algebra & Funktionen',
  weakTopics: ['Konzentration'],
  urteile: ILKAY_URTEILE,
  // lsa_fehlbild_auswertung liefert für diese Sitzung keine Zeile.
  fehlbilder: [],
  themaLabel: 'Terme und Gleichungen',
  raum: RAUM,
}

export const ilkay: ReportData = datenAus(ILKAY_ROH)
