#!/usr/bin/env node
/**
 * k9-quadrgl-charge.mjs — erzeugt docs/prefill/k9-quadrgl.json (Charge-Format von vorlauf-build.mjs).
 *
 *   node tools/k9-quadrgl-charge.mjs
 *
 * Thema quadrgl (Quadratische Gleichungen, KLP Ari-8, Zweite Stufe): je sechs Aufgaben zu
 * gleichung_quadr_wurzel, _faktor, _formel und _anzahl. Zwei Lösungen werden immer als
 * MULTI_PART abgefragt (Teil 1 = kleinere, Teil 2 = größere Lösung); eine Lösung als NUMERIC.
 * Jeder Wert wird über die Ausdrücke von tools/k9-rest-lib.mjs exakt gerechnet, nie getippt.
 * Die ids stehen in docs/prefill/k9-quadrgl-ids.json: ein zweiter Lauf erzeugt dieselbe Charge.
 */

import { baueCharge, CLUSTER } from './k9-rest-lib.mjs';

const EXAKT = 'Gib die Lösungen exakt an.';
const EXAKT1 = 'Gib das Ergebnis exakt an.';
const RUND2 = 'Runde die Lösungen auf zwei Stellen nach dem Komma.';
const KLEIN = 'kleinere Lösung';
const GROSS = 'größere Lösung';

const BASIS = {
  inhalt: 'arithmetik_algebra',
  inhaltGrund: 'Inhaltsfeld Arithmetik/Algebra (Ari-8: quadratische Gleichungen).',
  cluster: CLUSTER.algebra,
  clusterGrund: 'Themengebiet „Algebra & Funktionen" (wie Binom und lineare Gleichungen).',
  stoff: 9,
  stoffGrund: 'KLP Mathematik NRW, Zweite Stufe Ari-8: quadratische Gleichungen lösen (Klasse 9).',
};

const A = [];
const def = (o) => A.push({ ...BASIS, ...o });

// ─── gleichung_quadr_wurzel (Tiefe 7) ───
const WU = { skill: 'gleichung_quadr_wurzel' };
def({ ...WU, ref: 'quadrgl-wurzel-01', titel: 'Wurzelziehen · x² = 49', afb: 'I', sach: false,
  afbGrund: 'Reproduzieren: reine Quadratgleichung, Wurzel einer Quadratzahl, beide Vorzeichen.',
  frage: `Löse die Gleichung x² = 49.\n\n${EXAKT}`,
  weg: 'x² = 49 hat zwei Lösungen: x = √49 oder x = −√49.\n√49 = 7.\nKleinere Lösung: {1}. Größere Lösung: {2}.',
  teile: [
    { prompt: KLEIN, r: '-W(49)', n: 'exakt',
      ke: [['negative_loesung_vergessen', 'W(49)', 'Nur die positive Lösung 7 gefunden, die negative fehlt.', 'Welche Zahl ergibt mit sich selbst multipliziert ebenfalls 49?'],
        ['wurzel_vergessen', '-49', 'Die Wurzel nicht gezogen: −49.', 'Ist x selbst 49 oder ist x² gleich 49?']] },
    { prompt: GROSS, r: 'W(49)', n: 'exakt',
      ke: [['wurzel_vergessen', '49', 'Die Wurzel nicht gezogen: 49.', 'Ergibt 49 · 49 wirklich 49?']] },
  ] });
def({ ...WU, ref: 'quadrgl-wurzel-02', titel: 'Wurzelziehen · 2x² − 18 = 0', afb: 'I', sach: false,
  afbGrund: 'Reproduzieren: erst nach x² umstellen (zwei Schritte), dann Wurzel einer Quadratzahl.',
  frage: `Löse die Gleichung 2x² − 18 = 0.\n\n${EXAKT}`,
  weg: '2x² − 18 = 0 | + 18\n2x² = 18 | : 2\nx² = 9\nx = −√9 oder x = √9.\nKleinere Lösung: {1}. Größere Lösung: {2}.',
  teile: [
    { prompt: KLEIN, r: '-W(18/2)', n: 'exakt',
      ke: [['negative_loesung_vergessen', 'W(18/2)', 'Nur die positive Lösung 3 gefunden, die negative fehlt.', 'Welche zweite Zahl ergibt quadriert ebenfalls 9?'],
        ['falsche_gegenoperation', '-W(18*2)', 'Mit 2 multipliziert statt durch 2 geteilt: x² = 36.', 'Wie macht man ein „mal 2" rückgängig?'],
        ['wurzel_vergessen', '-18/2', 'Bei x² = 9 aufgehört, die Wurzel nicht gezogen.', 'Steht nach dem Umstellen schon x oder noch x² da?']] },
    { prompt: GROSS, r: 'W(18/2)', n: 'exakt',
      ke: [['falsche_gegenoperation', 'W(18*2)', 'Mit 2 multipliziert statt durch 2 geteilt: x² = 36.', 'Wie macht man ein „mal 2" rückgängig?'],
        ['wurzel_vergessen', '18/2', 'Bei x² = 9 aufgehört, die Wurzel nicht gezogen.', 'Steht nach dem Umstellen schon x oder noch x² da?']] },
  ] });
def({ ...WU, ref: 'quadrgl-wurzel-03', titel: 'Wurzelziehen · (x − 2)² = 25', afb: 'II', sach: false,
  afbGrund: 'Anwenden: Wurzel aus der Klammer ziehen, zwei Fälle getrennt nach x auflösen.',
  frage: `Löse die Gleichung (x − 2)² = 25.\n\n${EXAKT}`,
  weg: '(x − 2)² = 25\nx − 2 = 5 oder x − 2 = −5 | + 2\nx = 7 oder x = −3.\nKleinere Lösung: {1}. Größere Lösung: {2}.',
  teile: [
    { prompt: KLEIN, r: '2-W(25)', n: 'exakt',
      ke: [['vorzeichen_aus_klammer', '-2-W(25)', 'Die 2 aus der Klammer mit falschem Vorzeichen verrechnet: x + 2 = −5.', 'Welche Zahl musst du zu x − 2 addieren, damit nur x übrig bleibt?'],
        ['negative_loesung_vergessen', '2+W(25)', 'Nur den Fall x − 2 = 5 gerechnet, der Fall x − 2 = −5 fehlt.', 'Welche zweite Zahl ergibt quadriert ebenfalls 25?'],
        ['wurzel_vergessen', '2-25', 'Die Wurzel nicht gezogen: x − 2 = −25.', 'Ist x − 2 gleich 25 oder ist das Quadrat von x − 2 gleich 25?']] },
    { prompt: GROSS, r: '2+W(25)', n: 'exakt',
      ke: [['vorzeichen_aus_klammer', '-2+W(25)', 'Die 2 aus der Klammer mit falschem Vorzeichen verrechnet: x + 2 = 5.', 'Welche Zahl musst du zu x − 2 addieren, damit nur x übrig bleibt?'],
        ['wurzel_vergessen', '2+25', 'Die Wurzel nicht gezogen: x − 2 = 25.', 'Ist x − 2 gleich 25 oder ist das Quadrat von x − 2 gleich 25?']] },
  ] });
def({ ...WU, ref: 'quadrgl-wurzel-04', titel: 'Wurzelziehen · 3x² = 60, gerundet', afb: 'II', sach: false,
  afbGrund: 'Anwenden: Koeffizient abdividieren, Wurzel einer Nicht-Quadratzahl, runden.',
  frage: `Löse die Gleichung 3x² = 60.\n\n${RUND2}`,
  weg: '3x² = 60 | : 3\nx² = 20\nx = −√20 oder x = √20, √20 ≈ 4,472.\nKleinere Lösung: {1}. Größere Lösung: {2}.',
  teile: [
    { prompt: KLEIN, r: '-W(60/3)', n: 2,
      ke: [['negative_loesung_vergessen', 'W(60/3)', 'Nur die positive Lösung gefunden, die negative fehlt.', 'Welche zweite Zahl ergibt quadriert ebenfalls 20?'],
        ['division_vergessen', '-W(60)', 'Nicht durch 3 geteilt: die Wurzel aus 60 gezogen.', 'Steht vor x² noch ein Faktor, wenn du die Wurzel ziehst?'],
        ['wurzel_vergessen', '-60/3', 'Bei x² = 20 aufgehört, die Wurzel nicht gezogen.', 'Ist x gleich 20 oder ist x² gleich 20?']] },
    { prompt: GROSS, r: 'W(60/3)', n: 2,
      ke: [['division_vergessen', 'W(60)', 'Nicht durch 3 geteilt: die Wurzel aus 60 gezogen.', 'Steht vor x² noch ein Faktor, wenn du die Wurzel ziehst?'],
        ['wurzel_vergessen', '60/3', 'Bei x² = 20 aufgehört, die Wurzel nicht gezogen.', 'Ist x gleich 20 oder ist x² gleich 20?']] },
  ] });
def({ ...WU, ref: 'quadrgl-wurzel-05', titel: 'Wurzelziehen · Rechteck doppelt so lang wie breit, 98 m²', afb: 'II', sach: true,
  einheit: 'm', r: 'W(98/2)', n: 'exakt',
  afbGrund: 'Anwenden im Sachkontext: Gleichung 2x² = 98 aufstellen, nur die positive Lösung ist eine Länge.',
  frage: `Ein rechteckiges Beet ist doppelt so lang wie breit. Sein Flächeninhalt beträgt 98 m².\n\nWie breit ist das Beet? Als Breite ist nur eine positive Lösung sinnvoll. ${EXAKT1}`,
  weg: 'Breite x, Länge 2x: x · 2x = 98\n2x² = 98 | : 2\nx² = 49\nx = 7 oder x = −7; eine Breite ist positiv.\nDas Beet ist {A} m breit.',
  ke: [['division_vergessen', 'W(98)', 'Nicht durch 2 geteilt: die Wurzel aus 98 gezogen (≈ 9,90).', 'Wie viele Breiten stecken im Flächeninhalt, wenn die Länge 2x ist?', 2],
    ['wurzel_vergessen', '98/2', 'Bei x² = 49 aufgehört, die Wurzel nicht gezogen.', 'Ist die Breite 49 m oder ist das Quadrat der Breite 49?'],
    ['falsche_gegenoperation', 'W(98*2)', 'Mit 2 multipliziert statt durch 2 geteilt: x² = 196.', 'Wie macht man ein „mal 2" rückgängig?']] });
def({ ...WU, ref: 'quadrgl-wurzel-06', titel: 'Wurzelziehen · Quadratseite um 3 cm verlängert, 121 cm²', afb: 'III', sach: true,
  einheit: 'cm', r: 'W(121)-3', n: 'exakt',
  afbGrund: 'Problemlösen: Gleichung (x + 3)² = 121 selbst aufstellen, lösen und die sinnvolle Lösung wählen.',
  frage: `Verlängert man jede Seite eines Quadrats um 3 cm, so hat das neue Quadrat einen Flächeninhalt von 121 cm².\n\nWie lang war eine Seite des ursprünglichen Quadrats? ${EXAKT1}`,
  weg: 'Ursprüngliche Seite x: (x + 3)² = 121\nx + 3 = 11 oder x + 3 = −11 | − 3\nx = 8 oder x = −14; eine Seitenlänge ist positiv.\nDie Seite war {A} cm lang.',
  ke: [['vorzeichen_aus_klammer', 'W(121)+3', 'Die 3 aus der Klammer mit falschem Vorzeichen verrechnet: 11 + 3.', 'War das ursprüngliche Quadrat kleiner oder größer als das neue?'],
    ['falsche_groesse_beantwortet', 'W(121)', 'Die Seite des neuen Quadrats angegeben, nicht die des ursprünglichen.', 'Nach welchem der beiden Quadrate ist gefragt?'],
    ['quadrat_gliedweise', 'W(121-9)', 'Die Klammer gliedweise quadriert: x² + 9 = 121 (≈ 10,58).', 'Was ergibt (x + 3) · (x + 3) ausmultipliziert?', 2],
    ['wurzel_vergessen', '121-3', 'Die Wurzel nicht gezogen: x + 3 = 121.', 'Ist die neue Seite 121 cm lang oder ist ihr Quadrat 121?']] });

// ─── gleichung_quadr_faktor (Tiefe 8) ───
const FA = { skill: 'gleichung_quadr_faktor' };
def({ ...FA, ref: 'quadrgl-faktor-01', titel: 'Ausklammern · x² − 5x = 0', afb: 'I', sach: false,
  afbGrund: 'Reproduzieren: x ausklammern, Satz vom Nullprodukt, ganzzahlige Lösungen.',
  frage: `Löse die Gleichung x² − 5x = 0.\n\n${EXAKT}`,
  weg: 'x ausklammern: x · (x − 5) = 0.\nEin Produkt ist null, wenn ein Faktor null ist: x = 0 oder x − 5 = 0, also x = 5.\nKleinere Lösung: {1}. Größere Lösung: {2}.',
  teile: [
    { prompt: KLEIN, r: '0', n: 'exakt',
      ke: [['loesung_null_verloren', '5', 'Durch x geteilt und dabei die Lösung x = 0 verloren.', 'Was ergibt die linke Seite, wenn du x = 0 einsetzt?'],
        ['vorzeichen_aus_klammer', '-5', 'Aus (x − 5) den Wert −5 abgelesen statt 5.', 'Für welches x wird x − 5 wirklich null?']] },
    { prompt: GROSS, r: '5', n: 'exakt',
      ke: [['vorzeichen_aus_klammer', '0', 'Aus (x − 5) den Wert −5 abgelesen; dann wäre 0 die größere Lösung.', 'Setze −5 in x − 5 ein: Kommt null heraus?']] },
  ] });
def({ ...FA, ref: 'quadrgl-faktor-02', titel: 'Nullprodukt · (x − 3)(x + 5) = 0', afb: 'I', sach: false,
  afbGrund: 'Reproduzieren: Gleichung liegt schon als Produkt vor, Faktoren einzeln null setzen.',
  frage: `Löse die Gleichung (x − 3)(x + 5) = 0.\n\n${EXAKT}`,
  weg: 'Ein Produkt ist null, wenn ein Faktor null ist.\nx − 3 = 0, also x = 3, oder x + 5 = 0, also x = −5.\nKleinere Lösung: {1}. Größere Lösung: {2}.',
  teile: [
    { prompt: KLEIN, r: '-5', n: 'exakt',
      ke: [['vorzeichen_aus_klammer', '-3', 'Die Werte aus den Klammern mit falschem Vorzeichen abgelesen: 5 und −3.', 'Für welches x wird x + 5 null?']] },
    { prompt: GROSS, r: '3', n: 'exakt',
      ke: [['vorzeichen_aus_klammer', '5', 'Die Werte aus den Klammern mit falschem Vorzeichen abgelesen: 5 und −3.', 'Setze 5 in x + 5 ein: Kommt null heraus?']] },
  ] });
def({ ...FA, ref: 'quadrgl-faktor-03', titel: 'Ausklammern · 3x² = 12x', afb: 'II', sach: false,
  afbGrund: 'Anwenden: erst auf null bringen, dann 3x ausklammern; Versuchung, durch x zu teilen.',
  frage: `Löse die Gleichung 3x² = 12x.\n\n${EXAKT}`,
  weg: '3x² = 12x | − 12x\n3x² − 12x = 0\n3x ausklammern: 3x · (x − 4) = 0.\n3x = 0, also x = 0, oder x − 4 = 0, also x = 4.\nKleinere Lösung: {1}. Größere Lösung: {2}.',
  teile: [
    { prompt: KLEIN, r: '0', n: 'exakt',
      ke: [['loesung_null_verloren', '12/3', 'Durch x geteilt (3x = 12) und dabei die Lösung x = 0 verloren.', 'Stimmt die Gleichung auch für x = 0?']] },
    { prompt: GROSS, r: '12/3', n: 'exakt',
      ke: [['division_vergessen', '12', 'Nicht durch 3 geteilt: x = 12.', 'Setze 12 ein: Ist 3 · 12² gleich 12 · 12?']] },
  ] });
def({ ...FA, ref: 'quadrgl-faktor-04', titel: 'Nullprodukt · x(2x − 7) = 0', afb: 'II', sach: false,
  afbGrund: 'Anwenden: zweiter Faktor mit Koeffizient, Lösung als Dezimalzahl.',
  frage: `Löse die Gleichung x · (2x − 7) = 0.\n\n${EXAKT}`,
  weg: 'Ein Produkt ist null, wenn ein Faktor null ist.\nx = 0 oder 2x − 7 = 0 | + 7, : 2, also x = 3,5.\nKleinere Lösung: {1}. Größere Lösung: {2}.',
  teile: [
    { prompt: KLEIN, r: '0', n: 'exakt',
      ke: [['loesung_null_verloren', '7/2', 'Nur den Faktor 2x − 7 betrachtet, die Lösung x = 0 verloren.', 'Was ergibt x · (2x − 7), wenn x = 0 ist?'],
        ['vorzeichen_aus_klammer', '-7/2', 'Aus 2x − 7 den Wert −3,5 abgelesen statt 3,5.', 'Setze −3,5 in 2x − 7 ein: Kommt null heraus?']] },
    { prompt: GROSS, r: '7/2', n: 'exakt',
      ke: [['division_vergessen', '7', 'Aus 2x = 7 nicht durch 2 geteilt: x = 7.', 'Wie kommst du von 2x = 7 zu x?'],
        ['vorzeichen_aus_klammer', '0', 'Aus 2x − 7 den Wert −3,5 abgelesen; dann wäre 0 die größere Lösung.', 'Setze −3,5 in 2x − 7 ein: Kommt null heraus?']] },
  ] });
def({ ...FA, ref: 'quadrgl-faktor-05', titel: 'Nullprodukt · Ball landet wieder, h = 20t − 5t²', afb: 'II', sach: true,
  einheit: 's', r: '20/5', n: 'exakt',
  afbGrund: 'Anwenden im Sachkontext: h = 0 setzen, t ausklammern, die sinnvolle Lösung t > 0 wählen.',
  frage: `Ein Ball wird vom Boden aus senkrecht nach oben geworfen. Seine Höhe in Metern nach t Sekunden ist h = 20t − 5t².\n\nNach wie vielen Sekunden ist der Ball wieder am Boden? ${EXAKT1}`,
  weg: 'Am Boden ist h = 0: 20t − 5t² = 0.\nt ausklammern: t · (20 − 5t) = 0.\nt = 0 (Abwurf) oder 20 − 5t = 0 | + 5t, : 5, also t = 4.\nDer Ball ist nach {A} s wieder am Boden.',
  ke: [['division_vergessen', '20', 'Aus 20 = 5t nicht durch 5 geteilt: t = 20.', 'Wie kommst du von 5t = 20 zu t?'],
    ['vorzeichen_beim_umstellen', '-20/5', 'Beim Umstellen von 20 − 5t = 0 das Minus mitgenommen: t = −4.', 'Kann eine Zeit nach dem Abwurf negativ sein?']] });
def({ ...FA, ref: 'quadrgl-faktor-06', titel: 'Nullprodukt rückwärts · 2x² + bx = 0 mit Lösung 3', afb: 'III', sach: false,
  r: '-2*3', n: 'exakt',
  afbGrund: 'Problemlösen: Rückrichtung – aus einer bekannten Lösung den Koeffizienten b bestimmen.',
  frage: 'Die Gleichung 2x² + bx = 0 hat die Lösungen x = 0 und x = 3.\n\nWelchen Wert hat b? Gib das Ergebnis exakt an.',
  weg: 'x ausklammern: x · (2x + b) = 0.\nDie Lösung 3 macht den zweiten Faktor null: 2 · 3 + b = 0, also b = −6.\nProbe: 2x² − 6x = 2x · (x − 3), Lösungen 0 und 3.\nb = {A}.',
  ke: [['vorzeichen_aus_klammer', '2*3', 'Das Vorzeichen aus dem Faktor falsch übernommen: b = 6.', 'Setze b = 6 ein: Ist 3 dann eine Lösung von 2x² + 6x = 0?'],
    ['division_vergessen', '-2*3^2', 'x = 3 eingesetzt (18 + 3b = 0), aber nicht durch 3 geteilt: b = −18.', 'Wie kommst du von 3b = −18 zu b?']] });

// ─── gleichung_quadr_formel (Tiefe 8) ───
const FO = { skill: 'gleichung_quadr_formel' };
def({ ...FO, ref: 'quadrgl-formel-01', titel: 'p-q-Formel · x² + 2x − 15 = 0', afb: 'I', sach: false,
  afbGrund: 'Reproduzieren: Normalform, p und q direkt ablesbar, Wurzel aus einer Quadratzahl.',
  frage: `Löse die Gleichung x² + 2x − 15 = 0.\n\n${EXAKT}`,
  weg: 'p = 2, q = −15.\nx = −p/2 ± √((p/2)² − q) = −1 ± √(1 + 15) = −1 ± 4.\nKleinere Lösung: {1}. Größere Lösung: {2}.',
  teile: [
    { prompt: KLEIN, r: '-(2)/2 - W((2/2)^2+15)', n: 'exakt',
      ke: [['pq_vorzeichen', '(2)/2 - W((2/2)^2+15)', 'p mit falschem Vorzeichen eingesetzt: 1 ± 4.', 'Welches Vorzeichen hat der erste Summand −p/2, wenn p = 2 ist?'],
        ['wurzel_vergessen', '-(2)/2 - ((2/2)^2+15)', 'Die Wurzel nicht gezogen: −1 − 16.', 'Was ist mit dem Term unter der Wurzel zu tun?']] },
    { prompt: GROSS, r: '-(2)/2 + W((2/2)^2+15)', n: 'exakt',
      ke: [['pq_vorzeichen', '(2)/2 + W((2/2)^2+15)', 'p mit falschem Vorzeichen eingesetzt: 1 ± 4.', 'Welches Vorzeichen hat der erste Summand −p/2, wenn p = 2 ist?'],
        ['wurzel_vergessen', '-(2)/2 + ((2/2)^2+15)', 'Die Wurzel nicht gezogen: −1 + 16.', 'Was ist mit dem Term unter der Wurzel zu tun?']] },
  ] });
def({ ...FO, ref: 'quadrgl-formel-02', titel: 'p-q-Formel · x² − 6x + 5 = 0', afb: 'I', sach: false,
  afbGrund: 'Reproduzieren: Normalform mit negativem p, Wurzel aus einer Quadratzahl.',
  frage: `Löse die Gleichung x² − 6x + 5 = 0.\n\n${EXAKT}`,
  weg: 'p = −6, q = 5.\nx = −p/2 ± √((p/2)² − q) = 3 ± √(9 − 5) = 3 ± 2.\nKleinere Lösung: {1}. Größere Lösung: {2}.',
  teile: [
    { prompt: KLEIN, r: '-(-6)/2 - W((6/2)^2-5)', n: 'exakt',
      ke: [['pq_vorzeichen', '(-6)/2 - W((6/2)^2-5)', 'p mit falschem Vorzeichen eingesetzt: −3 ± 2.', 'Was ergibt −p/2, wenn p = −6 ist?'],
        ['wurzel_vergessen', '-(-6)/2 - ((6/2)^2-5)', 'Die Wurzel nicht gezogen: 3 − 4.', 'Was ist mit dem Term unter der Wurzel zu tun?']] },
    { prompt: GROSS, r: '-(-6)/2 + W((6/2)^2-5)', n: 'exakt',
      ke: [['pq_vorzeichen', '(-6)/2 + W((6/2)^2-5)', 'p mit falschem Vorzeichen eingesetzt: −3 ± 2.', 'Was ergibt −p/2, wenn p = −6 ist?'],
        ['wurzel_vergessen', '-(-6)/2 + ((6/2)^2-5)', 'Die Wurzel nicht gezogen: 3 + 4.', 'Was ist mit dem Term unter der Wurzel zu tun?']] },
  ] });
def({ ...FO, ref: 'quadrgl-formel-03', titel: 'p-q-Formel · 2x² − 4x − 6 = 0', afb: 'II', sach: false,
  afbGrund: 'Anwenden: erst durch 2 auf Normalform bringen, dann p-q-Formel mit zwei negativen Koeffizienten.',
  frage: `Löse die Gleichung 2x² − 4x − 6 = 0.\n\n${EXAKT}`,
  weg: 'Durch 2 teilen: x² − 2x − 3 = 0, also p = −2, q = −3.\nx = 1 ± √(1 + 3) = 1 ± 2.\nKleinere Lösung: {1}. Größere Lösung: {2}.',
  teile: [
    { prompt: KLEIN, r: '-(-2)/2 - W((2/2)^2+3)', n: 'exakt',
      ke: [['pq_vorzeichen', '(-2)/2 - W((2/2)^2+3)', 'p mit falschem Vorzeichen eingesetzt: −1 ± 2.', 'Was ergibt −p/2, wenn p = −2 ist?'],
        ['division_vergessen', '-(-4)/2 - W((4/2)^2+6)', 'Nicht durch 2 geteilt: mit p = −4 und q = −6 gerechnet (2 − √10 ≈ −1,16).', 'Steht vor x² eine 1, wenn du die p-q-Formel benutzt?', 2]] },
    { prompt: GROSS, r: '-(-2)/2 + W((2/2)^2+3)', n: 'exakt',
      ke: [['pq_vorzeichen', '(-2)/2 + W((2/2)^2+3)', 'p mit falschem Vorzeichen eingesetzt: −1 ± 2.', 'Was ergibt −p/2, wenn p = −2 ist?'],
        ['division_vergessen', '-(-4)/2 + W((4/2)^2+6)', 'Nicht durch 2 geteilt: mit p = −4 und q = −6 gerechnet (2 + √10 ≈ 5,16).', 'Steht vor x² eine 1, wenn du die p-q-Formel benutzt?', 2]] },
  ] });
def({ ...FO, ref: 'quadrgl-formel-04', titel: 'p-q-Formel · x² + 4x − 1 = 0, gerundet', afb: 'II', sach: false,
  afbGrund: 'Anwenden: Wurzel aus einer Nicht-Quadratzahl, Lösungen runden.',
  frage: `Löse die Gleichung x² + 4x − 1 = 0.\n\n${RUND2}`,
  weg: 'p = 4, q = −1.\nx = −2 ± √(4 + 1) = −2 ± √5, √5 ≈ 2,236.\nKleinere Lösung: {1}. Größere Lösung: {2}.',
  teile: [
    { prompt: KLEIN, r: '-(4)/2 - W((4/2)^2+1)', n: 2,
      ke: [['pq_vorzeichen', '(4)/2 - W((4/2)^2+1)', 'p mit falschem Vorzeichen eingesetzt: 2 ± √5.', 'Welches Vorzeichen hat −p/2, wenn p = 4 ist?'],
        ['wurzel_vergessen', '-(4)/2 - ((4/2)^2+1)', 'Die Wurzel nicht gezogen: −2 − 5.', 'Was ist mit dem Term unter der Wurzel zu tun?']] },
    { prompt: GROSS, r: '-(4)/2 + W((4/2)^2+1)', n: 2,
      ke: [['pq_vorzeichen', '(4)/2 + W((4/2)^2+1)', 'p mit falschem Vorzeichen eingesetzt: 2 ± √5.', 'Welches Vorzeichen hat −p/2, wenn p = 4 ist?'],
        ['wurzel_vergessen', '-(4)/2 + ((4/2)^2+1)', 'Die Wurzel nicht gezogen: −2 + 5.', 'Was ist mit dem Term unter der Wurzel zu tun?']] },
  ] });
def({ ...FO, ref: 'quadrgl-formel-05', titel: 'p-q-Formel · Rechteck 4 cm länger als breit, 60 cm²', afb: 'II', sach: true,
  einheit: 'cm', r: '-(4)/2 + W((4/2)^2+60) + 4', n: 'exakt',
  afbGrund: 'Anwenden im Sachkontext: Gleichung x(x + 4) = 60 aufstellen, lösen, sinnvolle Lösung wählen, Länge bilden.',
  frage: `Ein Rechteck ist 4 cm länger als breit. Sein Flächeninhalt beträgt 60 cm².\n\nWie lang ist die längere Seite des Rechtecks? ${EXAKT1}`,
  weg: 'Breite x, Länge x + 4: x · (x + 4) = 60\nx² + 4x − 60 = 0, p = 4, q = −60.\nx = −2 ± √(4 + 60) = −2 ± 8, also x = 6 oder x = −10; eine Breite ist positiv.\nBreite 6 cm, längere Seite 6 cm + 4 cm = {A} cm.',
  ke: [['pq_vorzeichen', '(4)/2 + W((4/2)^2+60) + 4', 'p mit falschem Vorzeichen eingesetzt: Breite 2 + 8 = 10, Länge 14.', 'Setze deine Breite ein: Ist Breite · (Breite + 4) wirklich 60?'],
    ['falsche_groesse_beantwortet', '-(4)/2 + W((4/2)^2+60)', 'Die Breite angegeben, nicht die längere Seite.', 'Ist nach der Breite oder nach der längeren Seite gefragt?'],
    ['wurzel_vergessen', '-(4)/2 + ((4/2)^2+60) + 4', 'Die Wurzel nicht gezogen: Breite −2 + 64.', 'Was ist mit dem Term unter der Wurzel zu tun?']] });
def({ ...FO, ref: 'quadrgl-formel-06', titel: 'p-q-Formel · Weg um ein Beet 20 m × 15 m, 500 m²', afb: 'III', sach: true,
  einheit: 'm', r: '-(35/2)/2 + W(((35/2)/2)^2+50)', n: 'exakt',
  afbGrund: 'Problemlösen: Modell (20 + 2x)(15 + 2x) = 500 selbst aufstellen, auf Normalform bringen, Formel anwenden, sinnvolle Lösung wählen.',
  frage: `Ein rechteckiges Beet ist 20 m lang und 15 m breit. Rundherum wird ein Weg angelegt, der überall gleich breit ist. Beet und Weg zusammen bedecken 500 m².\n\nWie breit ist der Weg? ${EXAKT1}`,
  weg: 'Wegbreite x: (20 + 2x) · (15 + 2x) = 500\n300 + 70x + 4x² = 500\n4x² + 70x − 200 = 0 | : 4\nx² + 17,5x − 50 = 0, p = 17,5, q = −50.\nx = −8,75 ± √(76,5625 + 50) = −8,75 ± 11,25, also x = 2,5 oder x = −20; eine Breite ist positiv.\nDer Weg ist {A} m breit.',
  ke: [['pq_vorzeichen', '(35/2)/2 + W(((35/2)/2)^2+50)', 'p mit falschem Vorzeichen eingesetzt: 8,75 + 11,25 = 20.', 'Setze 20 ein: Ist (20 + 40) · (15 + 40) gleich 500?'],
    ['division_vergessen', '-(70)/2 + W((70/2)^2+200)', 'Nicht durch 4 geteilt: mit p = 70 und q = −200 gerechnet (≈ 2,75).', 'Steht vor x² eine 1, wenn du die p-q-Formel benutzt?', 2]] });

// ─── gleichung_quadr_anzahl (Tiefe 9) ───
const AN = { skill: 'gleichung_quadr_anzahl' };
def({ ...AN, ref: 'quadrgl-anzahl-01', titel: 'Anzahl der Lösungen · x² + 4x + 5 = 0', afb: 'I', sach: false,
  r: '0', n: 'exakt',
  afbGrund: 'Reproduzieren: Diskriminante mit ablesbarem p und q, Vorzeichen deuten.',
  frage: 'Wie viele Lösungen hat die Gleichung x² + 4x + 5 = 0?\n\nGib die Anzahl als ganze Zahl an (0, 1 oder 2).',
  weg: 'p = 4, q = 5.\nD = (p/2)² − q = 2² − 5 = −1.\nD < 0: Unter der Wurzel stünde eine negative Zahl, es gibt keine Lösung.\nAnzahl: {A}.',
  ke: [['halbieren_vergessen', '2', 'p nicht halbiert: D = 16 − 5 = 11 > 0, also zwei Lösungen.', 'Was steckt in der Klammer von (p/2)²?']] });
def({ ...AN, ref: 'quadrgl-anzahl-02', titel: 'Diskriminante · x² − 6x + 8 = 0', afb: 'I', sach: false,
  r: '(-6/2)^2-8', n: 'exakt',
  afbGrund: 'Reproduzieren: Diskriminante nach Formel berechnen, p negativ.',
  frage: 'Berechne die Diskriminante D = (p/2)² − q der Gleichung x² − 6x + 8 = 0.\n\nGib das Ergebnis exakt an.',
  weg: 'p = −6, q = 8.\nD = (−6/2)² − 8 = (−3)² − 8 = 9 − 8.\nD = {A}.',
  ke: [['vorzeichen_potenz', '0-(6/2)^2-8', '(−3)² als −9 gerechnet: D = −9 − 8.', 'Ist eine Zahl mal sich selbst je negativ?'],
    ['halbieren_vergessen', '6^2-8', 'p nicht halbiert: D = 36 − 8.', 'Was steckt in der Klammer von (p/2)²?']] });
def({ ...AN, ref: 'quadrgl-anzahl-03', titel: 'Diskriminante · x² − 5x − 6 = 0', afb: 'II', sach: false,
  r: '(-5/2)^2+6', n: 'exakt',
  afbGrund: 'Anwenden: p/2 als Dezimalzahl, q negativ – zwei Vorzeichen sind zu beachten.',
  frage: 'Berechne die Diskriminante D = (p/2)² − q der Gleichung x² − 5x − 6 = 0.\n\nGib das Ergebnis exakt an.',
  weg: 'p = −5, q = −6.\nD = (−2,5)² − (−6) = 6,25 + 6.\nD = {A}.',
  ke: [['vorzeichen_potenz', '0-(5/2)^2+6', '(−2,5)² als −6,25 gerechnet: D = −6,25 + 6.', 'Ist eine Zahl mal sich selbst je negativ?'],
    ['halbieren_vergessen', '5^2+6', 'p nicht halbiert: D = 25 + 6.', 'Was steckt in der Klammer von (p/2)²?']] });
def({ ...AN, ref: 'quadrgl-anzahl-04', titel: 'Anzahl der Lösungen · 2x² − 8x + 8 = 0', afb: 'II', sach: false,
  r: '1', n: 'exakt',
  afbGrund: 'Anwenden: erst auf Normalform bringen, dann Diskriminante null erkennen.',
  frage: 'Wie viele Lösungen hat die Gleichung 2x² − 8x + 8 = 0?\n\nGib die Anzahl als ganze Zahl an (0, 1 oder 2).',
  weg: 'Durch 2 teilen: x² − 4x + 4 = 0, p = −4, q = 4.\nD = (−2)² − 4 = 0.\nD = 0: Es gibt genau eine Lösung (x = 2).\nAnzahl: {A}.',
  ke: [['division_vergessen', '2', 'Nicht durch 2 geteilt: D = (−4)² − 8 = 8 > 0, also zwei Lösungen.', 'Steht vor x² eine 1, wenn du p und q abliest?'],
    ['vorzeichen_potenz', '0', '(−2)² als −4 gerechnet: D = −8 < 0, also keine Lösung.', 'Ist eine Zahl mal sich selbst je negativ?']] });
def({ ...AN, ref: 'quadrgl-anzahl-05', titel: 'Anzahl der Lösungen · Zaun 20 m, Fläche 25 m²', afb: 'II', sach: true,
  r: '1', n: 'exakt',
  afbGrund: 'Anwenden im Sachkontext: gegebene Gleichung auf Normalform bringen, Diskriminante deuten.',
  frage: 'Ein rechteckiges Feld wird mit 20 m Zaun eingezäunt und soll 25 m² Fläche haben. Für seine Breite x in Metern gilt x · (10 − x) = 25.\n\nWie viele Lösungen hat diese Gleichung? Gib die Anzahl als ganze Zahl an (0, 1 oder 2).',
  weg: 'x · (10 − x) = 25\n10x − x² = 25 | + x² − 10x\n0 = x² − 10x + 25, also p = −10, q = 25.\nD = (−5)² − 25 = 0.\nD = 0: genau eine Lösung (x = 5, das Feld ist ein Quadrat).\nAnzahl: {A}.',
  ke: [['vorzeichen_potenz', '0', '(−5)² als −25 gerechnet: D = −50 < 0, also keine Lösung.', 'Ist eine Zahl mal sich selbst je negativ?'],
    ['halbieren_vergessen', '2', 'p nicht halbiert: D = 100 − 25 > 0, also zwei Lösungen.', 'Was steckt in der Klammer von (p/2)²?']] });
def({ ...AN, ref: 'quadrgl-anzahl-06', titel: 'Diskriminante rückwärts · x² + 6x + q = 0 mit genau einer Lösung', afb: 'III', sach: false,
  r: '(6/2)^2', n: 'exakt',
  afbGrund: 'Problemlösen: Rückrichtung – Bedingung D = 0 aufstellen und nach q auflösen.',
  frage: 'Für welchen Wert von q hat die Gleichung x² + 6x + q = 0 genau eine Lösung?\n\nGib q exakt an.',
  weg: 'Genau eine Lösung heißt D = 0.\nD = (6/2)² − q = 9 − q = 0, also q = 9.\nProbe: x² + 6x + 9 = (x + 3)², einzige Lösung x = −3.\nq = {A}.',
  ke: [['betrag_fehler', '0-(6/2)^2', 'Aus 9 − q = 0 den Wert q = −9 gemacht.', 'Setze q = −9 ein: Ist 9 − (−9) gleich null?'],
    ['halbieren_vergessen', '6^2', 'p nicht halbiert: q = 6² = 36.', 'Was steckt in der Klammer von (p/2)²?']] });

baueCharge({
  thema: 'quadrgl',
  batch: 'k9-quadrgl',
  source: 'edvance_k9_quadrgl',
  idsPfad: 'docs/prefill/k9-quadrgl-ids.json',
  kopf: [
    `K9-Rest, Thema quadrgl — ${A.length} Aufgaben: je sechs zu gleichung_quadr_wurzel, _faktor, _formel und _anzahl.`,
    'Erzeugt von tools/vorlauf-build.mjs aus docs/prefill/k9-quadrgl.json (Quelle: tools/k9-quadrgl-charge.mjs) — nicht von Hand editieren.',
    '',
    'Einspiel-Reihenfolge: nach 20261003105854_substrat_k9_quadrgl.sql (Knoten + Fehlbild-Slugs muessen stehen).',
  ],
  auswahl: 'Je Knoten vier reine Anwendung mit steigender Schwierigkeit, eine mit Sachkontext (Beet, Ball, Rechteck, Zaun) und eine Problemlöse- oder Rückrichtungsaufgabe. Zwei Lösungen immer als MULTI_PART (Teil 1 kleinere, Teil 2 größere Lösung), eine Lösung als NUMERIC. Alle ohne Abbildung lösbar; jede Aufgabe nennt „exakt" oder die Rundung (exakter Textvergleich, keine Toleranz).',
  aufgaben: A,
});
