// Der Katalog für den Eltern-Bericht R7: alle skills mit klasse_herkunft.
// Stand Prod 19.10.2026 (dbread: select skill_key, klasse_herkunft from skills).
// Nur von Tests und der Vorschau importiert. Neue Knoten -> Liste neu ziehen.

import type { KatalogSkill } from '@/types'

const ROH: readonly (readonly [string, number])[] = [
  ['bruch_add', 6], ['bruch_dezimal', 6], ['bruch_div', 6], ['bruch_kuerzen', 6],
  ['bruch_mult', 6], ['dezimal_add_sub', 5], ['dezimal_div', 6], ['dezimal_mult', 6],
  ['fkt_exp_anwendung', 10], ['fkt_exp_gleichung', 10], ['fkt_exp_halbwert', 10],
  ['fkt_exp_term', 10], ['fkt_exp_wachstum', 10], ['fkt_linear_gleichung', 8],
  ['fkt_linear_graph', 8], ['fkt_linear_nullstelle', 8], ['fkt_linear_steigung', 8],
  ['fkt_linear_yabschnitt', 8], ['fkt_quadr_extrem', 9], ['fkt_quadr_normalform', 9],
  ['fkt_quadr_nullstellen', 9], ['fkt_quadr_parabel', 9], ['fkt_quadr_scheitel', 9],
  ['fkt_sinus_bogenmass', 10], ['fkt_sinus_einheitskreis', 10], ['fkt_sinus_graph', 10],
  ['fkt_sinus_parameter', 10], ['fkt_sinus_periodisch', 10], ['geo_aehnlich_flaeche', 9],
  ['geo_aehnlich_strahlen_abschnitt', 9], ['geo_aehnlich_strahlen_parallel', 9],
  ['geo_aehnlich_streckfaktor', 9], ['geo_flaeche_drachen_raute', 8], ['geo_flaeche_dreieck', 7],
  ['geo_flaeche_rechteck', 5], ['geo_flaeche_rueck', 8], ['geo_flaeche_term', 8],
  ['geo_flaeche_trapez', 8], ['geo_flaeche_zusammengesetzt', 8], ['geo_koerper_kegel', 9],
  ['geo_koerper_kugel', 9], ['geo_koerper_prisma', 9], ['geo_koerper_pyramide', 9],
  ['geo_koerper_zylinder', 9], ['geo_koordinaten', 6], ['geo_kreis_flaeche', 9],
  ['geo_kreis_rueck', 9], ['geo_kreis_sektor', 9], ['geo_kreis_umfang', 9],
  ['geo_kreis_zusammen', 9], ['geo_massstab', 6], ['geo_pythagoras_abstand', 9],
  ['geo_pythagoras_anwendung', 9], ['geo_pythagoras_hypotenuse', 9],
  ['geo_pythagoras_kathete', 9], ['geo_pythagoras_umkehrung', 9], ['geo_trigo_anwendung', 10],
  ['geo_trigo_kosinussatz', 10], ['geo_trigo_seite', 10], ['geo_trigo_verhaeltnis', 10],
  ['geo_trigo_winkel', 10], ['geo_umfang', 5], ['geo_volumen_quader', 6],
  ['geo_winkel_dreieck', 8], ['geo_winkel_neben_scheitel', 8], ['geo_winkel_parallelen', 8],
  ['geo_winkel_summe', 7], ['geo_winkel_thales', 8], ['gleichung_beidseitig', 7],
  ['gleichung_einschrittig', 7], ['gleichung_lgs_addition', 8], ['gleichung_lgs_einsetzen', 8],
  ['gleichung_lgs_gleichsetzen', 8], ['gleichung_lgs_grafisch', 8],
  ['gleichung_lgs_sachaufgabe', 8], ['gleichung_modellieren', 8],
  ['gleichung_neg_koeffizient', 7], ['gleichung_quadr_anzahl', 9], ['gleichung_quadr_faktor', 9],
  ['gleichung_quadr_formel', 9], ['gleichung_quadr_wurzel', 9], ['gleichung_zweischrittig', 7],
  ['groessen_flaechen', 6], ['groessen_gemischt', 6], ['groessen_laengen', 5],
  ['groessen_massen', 5], ['groessen_volumen', 6], ['groessen_zeit', 5], ['potenzen', 7],
  ['proportionalitaet', 7], ['prozent_grundwert', 7], ['prozent_prozentsatz', 7],
  ['prozent_prozentwert', 7], ['prozent_veraenderung', 7], ['prozent_zins_jahreszins', 7],
  ['prozent_zins_rueckrechnung', 7], ['prozent_zins_teilzins', 7],
  ['prozent_zins_zinseszins', 7], ['runden_ueberschlag', 5], ['stoch_bedingt_irrefuehrend', 9],
  ['stoch_bedingt_umkehr', 9], ['stoch_bedingt_unabhaengig', 9], ['stoch_bedingt_vierfeld', 9],
  ['stoch_bedingt_wkeit', 9], ['stoch_gegenereignis', 8], ['stoch_kenngroessen', 8],
  ['stoch_laplace', 8], ['stoch_pfad_produkt', 8], ['stoch_pfad_summe', 8],
  ['term_ausklammern', 7], ['term_ausmultiplizieren', 7], ['term_binom_faktorisieren', 8],
  ['term_binom_gemischt', 8], ['term_binom_quadrat', 8], ['term_binom_quadratdifferenz', 8],
  ['term_einsetzen', 7], ['term_minusklammer', 7], ['term_zusammenfassen', 7],
  ['vorzeichen_add_sub', 7], ['vorzeichen_mult_div', 7], ['vorzeichen_vorrang', 7],
  ['zahl_potenz_gesetze', 9], ['zahl_potenz_negativ', 9], ['zahl_potenz_rechnen', 9],
  ['zahl_potenz_zehner', 9], ['zahl_wurzel_gesetze', 9], ['zahl_wurzel_irrational', 9],
  ['zahl_wurzel_naeherung', 9], ['zahl_wurzel_quadrat', 9], ['zahl_wurzel_teilweise', 9],
]

export const KATALOG: readonly KatalogSkill[] = ROH.map(([skillKey, klasse]) => ({ skillKey, klasse }))
