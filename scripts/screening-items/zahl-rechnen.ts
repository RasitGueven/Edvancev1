// Screening-Item-Entwürfe — Klasse 8, Cluster "Zahl & Rechnen".
// Versioniert (PR-Review) + wird per scripts/seed-screening-items.ts mit
// active=false in DB geseedet; fachliche Freigabe via /admin/screening-items.
//
// Granularität: atomare Mikroskills (Themengebiet → atomarer Skill).
// Autogradebar: NUMERIC (canonical {value:Zahl}) | MC (canonical {index})
// | NORMALIZED (canonical {value:String}, gekürzt "a/b").

export type SeedItem = {
  cluster_name: string
  class_level: number
  topic: string
  skill_code: string
  skill_label: string
  level: 1 | 2 | 3
  curriculum_seq: number
  input_type: 'MC' | 'NUMERIC' | 'MATCHING' | 'FREE_TEXT'
  prompt: string
  payload: unknown | null
  canonical: unknown
  check_type: 'mc_index' | 'numeric' | 'matching_set' | 'normalized'
  tolerance: number | null
  typical_errors: string[]
  explanation: string
}

const C = 'Zahl & Rechnen'
const G = 8

export const ZAHL_RECHNEN_ITEMS: SeedItem[] = [
  // ── Brüche addieren & subtrahieren (normalized, gekürzt "a/b") ──────────
  { cluster_name: C, class_level: G, topic: 'Brüche', skill_code: 'zr_bruch_add_sub', skill_label: 'Brüche addieren & subtrahieren', level: 1, curriculum_seq: 10, input_type: 'NUMERIC', prompt: 'Berechne und kürze vollständig (Form a/b): 1/4 + 1/4', payload: null, canonical: { value: '1/2' }, check_type: 'normalized', tolerance: null, typical_errors: ['Zähler und Nenner addiert', 'nicht gekürzt'], explanation: '1/4 + 1/4 = 2/4 = 1/2.' },
  { cluster_name: C, class_level: G, topic: 'Brüche', skill_code: 'zr_bruch_add_sub', skill_label: 'Brüche addieren & subtrahieren', level: 2, curriculum_seq: 10, input_type: 'NUMERIC', prompt: 'Berechne und kürze vollständig (Form a/b): 2/3 + 1/6', payload: null, canonical: { value: '5/6' }, check_type: 'normalized', tolerance: null, typical_errors: ['Nenner nicht gleichnamig gemacht'], explanation: '2/3 = 4/6; 4/6 + 1/6 = 5/6.' },
  { cluster_name: C, class_level: G, topic: 'Brüche', skill_code: 'zr_bruch_add_sub', skill_label: 'Brüche addieren & subtrahieren', level: 3, curriculum_seq: 10, input_type: 'NUMERIC', prompt: 'Berechne und kürze vollständig (Form a/b): 5/6 - 3/4', payload: null, canonical: { value: '1/12' }, check_type: 'normalized', tolerance: null, typical_errors: ['kgV falsch', 'Subtraktion der Nenner'], explanation: 'kgV(6,4)=12: 10/12 - 9/12 = 1/12.' },

  // ── Brüche multiplizieren & dividieren ─────────────────────────────────
  { cluster_name: C, class_level: G, topic: 'Brüche', skill_code: 'zr_bruch_mul_div', skill_label: 'Brüche multiplizieren & dividieren', level: 1, curriculum_seq: 11, input_type: 'NUMERIC', prompt: 'Berechne und kürze vollständig (Form a/b): 1/2 · 1/3', payload: null, canonical: { value: '1/6' }, check_type: 'normalized', tolerance: null, typical_errors: ['über Kreuz multipliziert'], explanation: 'Zähler·Zähler / Nenner·Nenner = 1/6.' },
  { cluster_name: C, class_level: G, topic: 'Brüche', skill_code: 'zr_bruch_mul_div', skill_label: 'Brüche multiplizieren & dividieren', level: 2, curriculum_seq: 11, input_type: 'NUMERIC', prompt: 'Berechne und kürze vollständig (Form a/b): 3/4 · 2/9', payload: null, canonical: { value: '1/6' }, check_type: 'normalized', tolerance: null, typical_errors: ['nicht gekürzt'], explanation: '6/36 = 1/6.' },
  { cluster_name: C, class_level: G, topic: 'Brüche', skill_code: 'zr_bruch_mul_div', skill_label: 'Brüche multiplizieren & dividieren', level: 3, curriculum_seq: 11, input_type: 'NUMERIC', prompt: 'Berechne und kürze vollständig (Form a/b): 3/5 : 9/10', payload: null, canonical: { value: '2/3' }, check_type: 'normalized', tolerance: null, typical_errors: ['nicht mit Kehrwert multipliziert'], explanation: '3/5 · 10/9 = 30/45 = 2/3.' },

  // ── Bruch ↔ Dezimal ────────────────────────────────────────────────────
  { cluster_name: C, class_level: G, topic: 'Brüche', skill_code: 'zr_bruch_dezimal', skill_label: 'Bruch in Dezimalzahl umwandeln', level: 1, curriculum_seq: 12, input_type: 'NUMERIC', prompt: 'Schreibe als Dezimalzahl: 1/2', payload: null, canonical: { value: 0.5 }, check_type: 'numeric', tolerance: 0, typical_errors: ['0,2 statt 0,5'], explanation: '1 : 2 = 0,5.' },
  { cluster_name: C, class_level: G, topic: 'Brüche', skill_code: 'zr_bruch_dezimal', skill_label: 'Bruch in Dezimalzahl umwandeln', level: 2, curriculum_seq: 12, input_type: 'NUMERIC', prompt: 'Schreibe als Dezimalzahl: 3/4', payload: null, canonical: { value: 0.75 }, check_type: 'numeric', tolerance: 0, typical_errors: ['0,34'], explanation: '3 : 4 = 0,75.' },
  { cluster_name: C, class_level: G, topic: 'Brüche', skill_code: 'zr_bruch_dezimal', skill_label: 'Bruch in Dezimalzahl umwandeln', level: 3, curriculum_seq: 12, input_type: 'NUMERIC', prompt: 'Schreibe als Dezimalzahl (auf 0,01 gerundet): 5/8', payload: null, canonical: { value: 0.63 }, check_type: 'numeric', tolerance: 0.005, typical_errors: ['nicht gerundet'], explanation: '5 : 8 = 0,625 ≈ 0,63.' },

  // ── Prozentwert ────────────────────────────────────────────────────────
  { cluster_name: C, class_level: G, topic: 'Prozentrechnung', skill_code: 'zr_prozentwert', skill_label: 'Prozentwert berechnen', level: 1, curriculum_seq: 20, input_type: 'NUMERIC', prompt: 'Wie viel sind 10 % von 200?', payload: null, canonical: { value: 20 }, check_type: 'numeric', tolerance: 0, typical_errors: ['durch 10 statt ·0,1 ungenau'], explanation: '200 · 0,10 = 20.' },
  { cluster_name: C, class_level: G, topic: 'Prozentrechnung', skill_code: 'zr_prozentwert', skill_label: 'Prozentwert berechnen', level: 2, curriculum_seq: 20, input_type: 'NUMERIC', prompt: 'Wie viel sind 25 % von 84?', payload: null, canonical: { value: 21 }, check_type: 'numeric', tolerance: 0, typical_errors: ['25·84'], explanation: '84 · 0,25 = 21.' },
  { cluster_name: C, class_level: G, topic: 'Prozentrechnung', skill_code: 'zr_prozentwert', skill_label: 'Prozentwert berechnen', level: 3, curriculum_seq: 20, input_type: 'NUMERIC', prompt: 'Ein Pullover kostet 80 €. Im Sale: 15 % Rabatt. Neuer Preis in €?', payload: null, canonical: { value: 68 }, check_type: 'numeric', tolerance: 0, typical_errors: ['nur Rabatt 12 angegeben'], explanation: 'Rabatt 80·0,15=12; 80−12=68 €.' },

  // ── Grundwert ──────────────────────────────────────────────────────────
  { cluster_name: C, class_level: G, topic: 'Prozentrechnung', skill_code: 'zr_grundwert', skill_label: 'Grundwert berechnen', level: 1, curriculum_seq: 21, input_type: 'NUMERIC', prompt: '10 % eines Betrags sind 5 €. Wie groß ist der Grundwert (in €)?', payload: null, canonical: { value: 50 }, check_type: 'numeric', tolerance: 0, typical_errors: ['5·10? unsicher'], explanation: 'G = W / p = 5 / 0,10 = 50 €.' },
  { cluster_name: C, class_level: G, topic: 'Prozentrechnung', skill_code: 'zr_grundwert', skill_label: 'Grundwert berechnen', level: 2, curriculum_seq: 21, input_type: 'NUMERIC', prompt: '20 % eines Betrags sind 36 €. Grundwert in €?', payload: null, canonical: { value: 180 }, check_type: 'numeric', tolerance: 0, typical_errors: ['36·0,2'], explanation: 'G = 36 / 0,20 = 180 €.' },
  { cluster_name: C, class_level: G, topic: 'Prozentrechnung', skill_code: 'zr_grundwert', skill_label: 'Grundwert berechnen', level: 3, curriculum_seq: 21, input_type: 'NUMERIC', prompt: 'Nach 15 % Rabatt zahlt man 68 €. Wie hoch war der ursprüngliche Preis (in €)?', payload: null, canonical: { value: 80 }, check_type: 'numeric', tolerance: 0, typical_errors: ['68·1,15'], explanation: '68 entspricht 85 %: G = 68 / 0,85 = 80 €.' },

  // ── Prozentsatz ────────────────────────────────────────────────────────
  { cluster_name: C, class_level: G, topic: 'Prozentrechnung', skill_code: 'zr_prozentsatz', skill_label: 'Prozentsatz berechnen', level: 1, curriculum_seq: 22, input_type: 'MC', prompt: 'Welcher Anteil sind 25 von 100?', payload: { type: 'mc', options: ['2,5 %', '25 %', '40 %', '75 %'], correct_index: 1 }, canonical: { index: 1 }, check_type: 'mc_index', tolerance: null, typical_errors: ['25/100 falsch gedeutet'], explanation: '25/100 = 25 %.' },
  { cluster_name: C, class_level: G, topic: 'Prozentrechnung', skill_code: 'zr_prozentsatz', skill_label: 'Prozentsatz berechnen', level: 2, curriculum_seq: 22, input_type: 'NUMERIC', prompt: 'Wieviel Prozent sind 18 von 72? (nur Zahl, ohne %)', payload: null, canonical: { value: 25 }, check_type: 'numeric', tolerance: 0, typical_errors: ['72/18'], explanation: '18/72 = 0,25 = 25 %.' },
  { cluster_name: C, class_level: G, topic: 'Prozentrechnung', skill_code: 'zr_prozentsatz', skill_label: 'Prozentsatz berechnen', level: 3, curriculum_seq: 22, input_type: 'NUMERIC', prompt: 'Ein Preis steigt von 40 € auf 50 €. Um wie viel Prozent? (nur Zahl)', payload: null, canonical: { value: 25 }, check_type: 'numeric', tolerance: 0, typical_errors: ['10/50 statt 10/40'], explanation: 'Zuwachs 10 € von 40 € = 25 %.' },

  // ── Jahreszinsen ───────────────────────────────────────────────────────
  { cluster_name: C, class_level: G, topic: 'Zinsrechnung', skill_code: 'zr_jahreszins', skill_label: 'Jahreszinsen berechnen', level: 1, curriculum_seq: 30, input_type: 'NUMERIC', prompt: 'Kapital 100 €, Zinssatz 5 % pro Jahr. Zinsen nach 1 Jahr (in €)?', payload: null, canonical: { value: 5 }, check_type: 'numeric', tolerance: 0, typical_errors: ['105 angegeben'], explanation: '100 · 0,05 = 5 €.' },
  { cluster_name: C, class_level: G, topic: 'Zinsrechnung', skill_code: 'zr_jahreszins', skill_label: 'Jahreszinsen berechnen', level: 2, curriculum_seq: 30, input_type: 'NUMERIC', prompt: 'Kapital 2000 €, 3 % p. a. Jahreszinsen in €?', payload: null, canonical: { value: 60 }, check_type: 'numeric', tolerance: 0, typical_errors: ['2000·3'], explanation: '2000 · 0,03 = 60 €.' },
  { cluster_name: C, class_level: G, topic: 'Zinsrechnung', skill_code: 'zr_jahreszins', skill_label: 'Jahreszinsen berechnen', level: 3, curriculum_seq: 30, input_type: 'NUMERIC', prompt: 'Endkapital nach 1 Jahr bei 1500 € und 4 % p. a. (in €)?', payload: null, canonical: { value: 1560 }, check_type: 'numeric', tolerance: 0, typical_errors: ['nur Zinsen 60'], explanation: '1500 + 1500·0,04 = 1560 €.' },

  // ── Teiljahreszinsen ───────────────────────────────────────────────────
  { cluster_name: C, class_level: G, topic: 'Zinsrechnung', skill_code: 'zr_teiljahreszins', skill_label: 'Monats-/Tageszinsen berechnen', level: 1, curriculum_seq: 31, input_type: 'NUMERIC', prompt: 'Jahreszinsen 120 €. Wie viel sind das pro Monat (in €)?', payload: null, canonical: { value: 10 }, check_type: 'numeric', tolerance: 0, typical_errors: ['120·12'], explanation: '120 / 12 = 10 €.' },
  { cluster_name: C, class_level: G, topic: 'Zinsrechnung', skill_code: 'zr_teiljahreszins', skill_label: 'Monats-/Tageszinsen berechnen', level: 2, curriculum_seq: 31, input_type: 'NUMERIC', prompt: 'Kapital 1200 €, 6 % p. a., Laufzeit 6 Monate. Zinsen in €?', payload: null, canonical: { value: 36 }, check_type: 'numeric', tolerance: 0, typical_errors: ['ganzes Jahr 72'], explanation: '1200·0,06·(6/12) = 36 €.' },
  { cluster_name: C, class_level: G, topic: 'Zinsrechnung', skill_code: 'zr_teiljahreszins', skill_label: 'Monats-/Tageszinsen berechnen', level: 3, curriculum_seq: 31, input_type: 'NUMERIC', prompt: 'Kapital 3000 €, 5 % p. a., 90 Tage (kaufm. 360-Tage-Jahr). Zinsen in €?', payload: null, canonical: { value: 37.5 }, check_type: 'numeric', tolerance: 0, typical_errors: ['365 statt 360', 'ganzes Jahr'], explanation: '3000·0,05·(90/360) = 37,50 €.' },

  // ── Vorzeichen: Addition/Subtraktion ───────────────────────────────────
  { cluster_name: C, class_level: G, topic: 'Rationale Zahlen', skill_code: 'zr_vz_add_sub', skill_label: 'Vorzeichen: Addition/Subtraktion', level: 1, curriculum_seq: 5, input_type: 'NUMERIC', prompt: 'Berechne: -3 + 7', payload: null, canonical: { value: 4 }, check_type: 'numeric', tolerance: 0, typical_errors: ['-10'], explanation: '-3 + 7 = 4.' },
  { cluster_name: C, class_level: G, topic: 'Rationale Zahlen', skill_code: 'zr_vz_add_sub', skill_label: 'Vorzeichen: Addition/Subtraktion', level: 2, curriculum_seq: 5, input_type: 'NUMERIC', prompt: 'Berechne: -8 - (-5)', payload: null, canonical: { value: -3 }, check_type: 'numeric', tolerance: 0, typical_errors: ['-13', 'Doppelminus übersehen'], explanation: '-8 - (-5) = -8 + 5 = -3.' },
  { cluster_name: C, class_level: G, topic: 'Rationale Zahlen', skill_code: 'zr_vz_add_sub', skill_label: 'Vorzeichen: Addition/Subtraktion', level: 3, curriculum_seq: 5, input_type: 'NUMERIC', prompt: 'Berechne: -4 + 9 - 12 - (-6)', payload: null, canonical: { value: -1 }, check_type: 'numeric', tolerance: 0, typical_errors: ['Vorzeichenkette falsch'], explanation: '-4+9-12+6 = -1.' },

  // ── Vorzeichen: Multiplikation/Division ────────────────────────────────
  { cluster_name: C, class_level: G, topic: 'Rationale Zahlen', skill_code: 'zr_vz_mul_div', skill_label: 'Vorzeichen: Multiplikation/Division', level: 1, curriculum_seq: 6, input_type: 'NUMERIC', prompt: 'Berechne: (-4) · 3', payload: null, canonical: { value: -12 }, check_type: 'numeric', tolerance: 0, typical_errors: ['+12'], explanation: 'minus · plus = minus → -12.' },
  { cluster_name: C, class_level: G, topic: 'Rationale Zahlen', skill_code: 'zr_vz_mul_div', skill_label: 'Vorzeichen: Multiplikation/Division', level: 2, curriculum_seq: 6, input_type: 'NUMERIC', prompt: 'Berechne: (-36) : (-9)', payload: null, canonical: { value: 4 }, check_type: 'numeric', tolerance: 0, typical_errors: ['-4'], explanation: 'minus : minus = plus → 4.' },
  { cluster_name: C, class_level: G, topic: 'Rationale Zahlen', skill_code: 'zr_vz_mul_div', skill_label: 'Vorzeichen: Multiplikation/Division', level: 3, curriculum_seq: 6, input_type: 'NUMERIC', prompt: 'Berechne: (-2) · (-3) · (-5)', payload: null, canonical: { value: -30 }, check_type: 'numeric', tolerance: 0, typical_errors: ['+30 (Vorzeichenanzahl)'], explanation: 'Drei Minus → Ergebnis negativ: -30.' },
]
