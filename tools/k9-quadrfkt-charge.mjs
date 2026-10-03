#!/usr/bin/env node
/**
 * k9-quadrfkt-charge.mjs — erzeugt docs/prefill/k9-quadrfkt.json (Charge-Format von vorlauf-build.mjs).
 *
 *   node tools/k9-quadrfkt-charge.mjs
 *
 * Thema quadrfkt (Quadratische Funktionen, KLP Fkt-8/9, Zweite Stufe), je sechs Aufgaben zu
 * fkt_quadr_parabel, _scheitel, _normalform, _nullstellen und _extrem. Jeder Wert wird über die
 * Ausdrücke von tools/k9-rest-lib.mjs exakt nachgerechnet. Scheitelpunkte und Nullstellenpaare
 * sind MULTI_PART (der Tablet-Player nimmt nur Zahlen an). Vier Aufgaben haben eine Abbildung
 * (Generator koordinatensystem, Parabel in Normalform a·x² + b·x + c).
 * Die ids stehen in docs/prefill/k9-quadrfkt-ids.json: ein zweiter Lauf erzeugt dieselbe Charge.
 */

import { baueCharge, CLUSTER } from './k9-rest-lib.mjs';

const A = [];
const BASIS = {
  inhalt: 'funktionen',
  cluster: CLUSTER.algebra,
  stoff: 9,
  stoffGrund: 'KLP Mathematik NRW, Klasse 9 (Zweite Stufe), Fkt-8/9: quadratische Funktionen, Scheitelpunktform, Nullstellen, Extremwertprobleme.',
  clusterGrund: 'Quadratische Funktionen gehören wie lineare Funktionen und binomische Formeln zu „Algebra & Funktionen".',
  inhaltGrund: 'Inhaltsbereich Funktionen (Parabeln und ihre Kennzahlen).',
};
const def = (o) => A.push({ ...BASIS, ...o });
const EXAKT = 'Gib das Ergebnis exakt an.';
const GANZ = 'Die gesuchten Werte sind ganzzahlig.';

// ─── fkt_quadr_parabel (Tiefe 6) ───
const PA = { skill: 'fkt_quadr_parabel', n: 'exakt' };
def({ ...PA, ref: 'quadrfkt-parabel-01', titel: 'Funktionswert · f(4) bei f(x) = 2(x − 1)² + 3', afb: 'I', sach: false,
  afbGrund: 'Reproduzieren: eine positive Zahl in die Scheitelpunktform einsetzen.',
  frage: `Gegeben ist die Funktion f(x) = 2(x − 1)² + 3.\n\nBerechne f(4). ${EXAKT}`, r: '2*(4-1)^2+3',
  weg: 'Klammer zuerst: 4 − 1 = 3.\nQuadrieren: 3² = 9.\nMal 2 und plus 3: f(4) = 2 · 9 + 3 = {A}.',
  ke: [['vorrang_ignoriert', '(2*(4-1))^2+3', 'Erst mit 2 multipliziert, dann quadriert: (2 · 3)² + 3 = 39.', 'Was wird zuerst gerechnet: das Quadrat oder das Mal 2?'],
    ['mal_exponent', '2*(2*(4-1))+3', 'Das Quadrat als „mal 2" gerechnet: 3² = 6.', 'Was bedeutet die kleine 2 an der Klammer?']] });
def({ ...PA, ref: 'quadrfkt-parabel-02', titel: 'Verschiebung nach oben · aus der Abbildung', afb: 'I', sach: false,
  afbGrund: 'Reproduzieren: die Verschiebung einer Normalparabel am Gitter ablesen.',
  frage: `Die Abbildung zeigt eine verschobene Normalparabel.\n\nUm wie viele Einheiten ist die Parabel gegenüber der Normalparabel nach oben verschoben? ${GANZ}`, r: '3',
  figur: { params: { x_min: -2, x_max: 6, y_min: -1, y_max: 9, funktionen: [{ typ: 'quadratisch', a: 1, b: -4, c: 7 }] },
    alt_text: 'Koordinatensystem mit Gitter und einer nach oben geöffneten, verschobenen Normalparabel.' },
  weg: 'Der Scheitelpunkt der Normalparabel liegt bei (0|0).\nDer Scheitelpunkt der abgebildeten Parabel liegt bei (2|3).\nDie Parabel ist um {A} Einheiten nach oben (und um 2 nach rechts) verschoben.',
  ke: [['koordinaten_vertauscht', '2', 'Die Verschiebung nach rechts angegeben statt nach oben.', 'Welche Koordinate des Scheitelpunkts sagt etwas über oben und unten?']] });
def({ ...PA, ref: 'quadrfkt-parabel-03', titel: 'Funktionswert · f(−2) bei f(x) = 3(x − 1)² − 5', afb: 'II', sach: false,
  afbGrund: 'Anwenden: negatives Argument, die Klammer wird negativ und muss richtig quadriert werden.',
  frage: `Gegeben ist die Funktion f(x) = 3(x − 1)² − 5.\n\nBerechne f(−2). ${EXAKT}`, r: '3*(-2-1)^2-5',
  weg: 'Klammer zuerst: −2 − 1 = −3.\nQuadrieren: (−3)² = 9.\nMal 3 und minus 5: f(−2) = 3 · 9 − 5 = {A}.',
  ke: [['vorzeichen_potenz', '3*(0-9)-5', 'Das Quadrat einer negativen Zahl negativ gerechnet: (−3)² = −9.', 'Welches Vorzeichen hat das Produkt (−3) · (−3)?'],
    ['vorrang_ignoriert', '(3*(-2-1))^2-5', 'Erst mit 3 multipliziert, dann quadriert: (3 · (−3))² − 5 = 76.', 'Was wird zuerst gerechnet: das Quadrat oder das Mal 3?']] });
def({ ...PA, ref: 'quadrfkt-parabel-04', titel: 'Streckfaktor · Parabel durch P(5|35)', afb: 'II', sach: false,
  afbGrund: 'Anwenden: Punkt einsetzen und die Gleichung nach a umstellen.',
  frage: `Die Parabel y = a · (x − 1)² + 3 geht durch den Punkt P(5|35).\n\nBestimme den Streckfaktor a. ${EXAKT}`, r: '(35-3)/(5-1)^2',
  weg: 'P einsetzen: 35 = a · (5 − 1)² + 3.\n35 = a · 16 + 3, also 32 = 16 · a.\na = 32 : 16 = {A}.',
  ke: [['mal_exponent', '(35-3)/(2*(5-1))', 'Das Quadrat als „mal 2" gerechnet: (5 − 1)² = 8.', 'Was bedeutet die kleine 2 an der Klammer?'],
    ['vorzeichen_beim_umstellen', '(35+3)/(5-1)^2', 'Die 3 beim Umstellen addiert statt subtrahiert: 38 : 16.', 'Wie bringst du das „+ 3" auf die andere Seite?']] });
def({ ...PA, ref: 'quadrfkt-parabel-05', titel: 'Funktionswert · Wasserstrahl 5 m von der Düse', einheit: 'm', afb: 'II', sach: true,
  afbGrund: 'Anwenden im Sachkontext: waagerechten Abstand als x erkennen und einsetzen, negativer Streckfaktor.',
  frage: `Der Wasserstrahl eines Brunnens folgt der Funktion h(x) = −0,5 · (x − 2)² + 5. Dabei ist x der waagerechte Abstand von der Düse in Metern und h(x) die Höhe des Strahls in Metern.\n\nWie hoch ist der Strahl 5 m waagerecht von der Düse entfernt? ${EXAKT}`, r: '-0.5*(5-2)^2+5',
  weg: 'x = 5 einsetzen: 5 − 2 = 3, 3² = 9.\nh(5) = −0,5 · 9 + 5 = −4,5 + 5 = {A} m.',
  ke: [['vorrang_ignoriert', '(-0.5*(5-2))^2+5', 'Erst mit −0,5 multipliziert, dann quadriert: (−1,5)² + 5 = 7,25.', 'Was wird zuerst gerechnet: das Quadrat oder das Mal −0,5?'],
    ['mal_exponent', '-0.5*(2*(5-2))+5', 'Das Quadrat als „mal 2" gerechnet: 3² = 6.', 'Was bedeutet die kleine 2 an der Klammer?']] });
def({ ...PA, ref: 'quadrfkt-parabel-06', titel: 'Streckfaktor · aus Scheitel und Punkt in der Abbildung', afb: 'III', sach: false,
  afbGrund: 'Problemlösen: Scheitelpunkt und zweiten Punkt ablesen, die Scheitelpunktform selbst aufstellen und nach a umstellen.',
  frage: `Die Abbildung zeigt eine Parabel, die aus der Normalparabel durch Strecken und Verschieben entsteht. Eingezeichnet sind ihr Scheitelpunkt S und ein weiterer Punkt P. Beide haben ganzzahlige Koordinaten.\n\nBestimme den Streckfaktor a der Parabel. ${EXAKT}`, r: '(5-(-3))/(5-1)^2',
  figur: { params: { x_min: -4, x_max: 6, y_min: -4, y_max: 6, funktionen: [{ typ: 'quadratisch', a: 0.5, b: -1, c: -2.5 }],
    punkte: [{ x: 1, y: -3, label: 'S' }, { x: 5, y: 5, label: 'P' }] },
    alt_text: 'Koordinatensystem mit Gitter und einer nach oben geöffneten Parabel; ihr Scheitelpunkt S und ein Punkt P sind markiert.' },
  weg: 'Ablesen: S(1|−3) und P(5|5).\nScheitelpunktform: y = a · (x − 1)² − 3.\nP einsetzen: 5 = a · (5 − 1)² − 3, also 8 = 16 · a.\na = 8 : 16 = {A}.',
  ke: [['mal_exponent', '(5-(-3))/(2*(5-1))', 'Das Quadrat als „mal 2" gerechnet: (5 − 1)² = 8.', 'Was bedeutet die kleine 2 an der Klammer?'],
    ['umgekehrt_geteilt', '(5-1)^2/(5-(-3))', 'Umgekehrt geteilt: 16 : 8 statt 8 : 16.', 'Welche Zahl steht in 8 = a · 16 neben a – durch welche musst du teilen?'],
    ['koordinate_vorzeichen_verloren', '(5-3)/(5-1)^2', 'Die y-Koordinate des Scheitels ohne Minus gelesen: S(1|3).', 'Liegt der Scheitelpunkt über oder unter der x-Achse?']] });

// ─── fkt_quadr_scheitel (Tiefe 7) ───
const SC = { skill: 'fkt_quadr_scheitel' };
const T_X = 'x-Koordinate des Scheitelpunkts';
const T_Y = 'y-Koordinate des Scheitelpunkts';
def({ ...SC, ref: 'quadrfkt-scheitel-01', titel: 'Scheitelpunkt · y = (x − 3)² + 1', afb: 'I', sach: false,
  afbGrund: 'Reproduzieren: S(d|e) direkt aus der Scheitelpunktform ablesen.',
  frage: `Gegeben ist die Parabel y = (x − 3)² + 1.\n\nGib die Koordinaten ihres Scheitelpunkts an. ${GANZ}`,
  teile: [{ prompt: T_X, r: '3', n: 'exakt',
    ke: [['vorzeichen_aus_klammer', '-3', 'Das Vorzeichen aus der Klammer übernommen: −3 statt 3.', 'Für welches x wird die Klammer (x − 3) null?']] },
  { prompt: T_Y, r: '1', n: 'exakt',
    ke: [['koordinaten_vertauscht', '3', 'x- und y-Koordinate vertauscht.', 'Welche Zahl steht außerhalb der Klammer?']] }],
  weg: 'Scheitelpunktform y = (x − d)² + e mit S(d|e).\n(x − 3) wird null für x = 3, also d = {1}.\nAußerhalb der Klammer steht + 1, also e = {2}.\nS(3|1).' });
def({ ...SC, ref: 'quadrfkt-scheitel-02', titel: 'Scheitelpunkt · aus der Abbildung ablesen', afb: 'I', sach: false,
  afbGrund: 'Reproduzieren: den tiefsten Punkt einer Parabel am Gitter ablesen.',
  frage: `Die Abbildung zeigt eine nach oben geöffnete Parabel.\n\nLies die Koordinaten ihres Scheitelpunkts ab. ${GANZ}`,
  figur: { params: { x_min: -6, x_max: 2, y_min: -4, y_max: 5, funktionen: [{ typ: 'quadratisch', a: 1, b: 4, c: 1 }] },
    alt_text: 'Koordinatensystem mit Gitter und einer nach oben geöffneten Parabel.' },
  teile: [{ prompt: T_X, r: '-2', n: 'exakt',
    ke: [['koordinaten_vertauscht', '-3', 'x- und y-Koordinate vertauscht.', 'Welche Achse zeigt nach rechts?'],
      ['koordinate_vorzeichen_verloren', '2', 'Das Minus vergessen: Der Scheitel liegt links der y-Achse.', 'Liegt der Scheitelpunkt links oder rechts der y-Achse?']] },
  { prompt: T_Y, r: '-3', n: 'exakt',
    ke: [['koordinaten_vertauscht', '-2', 'x- und y-Koordinate vertauscht.', 'Welche Achse zeigt nach oben?'],
      ['koordinate_vorzeichen_verloren', '3', 'Das Minus vergessen: Der Scheitel liegt unter der x-Achse.', 'Liegt der Scheitelpunkt über oder unter der x-Achse?']] }],
  weg: 'Der tiefste Punkt der Parabel ist der Scheitelpunkt.\nEr liegt 2 Einheiten links der y-Achse: x = {1}.\nEr liegt 3 Einheiten unter der x-Achse: y = {2}.\nS(−2|−3).' });
def({ ...SC, ref: 'quadrfkt-scheitel-03', titel: 'Scheitelpunkt · y = −2(x + 4)² − 5', afb: 'II', sach: false,
  afbGrund: 'Anwenden: Plus in der Klammer und negativer Streckfaktor, der Faktor gehört nicht zum Scheitel.',
  frage: `Gegeben ist die Parabel y = −2(x + 4)² − 5.\n\nGib die Koordinaten ihres Scheitelpunkts an. ${GANZ}`,
  teile: [{ prompt: T_X, r: '-4', n: 'exakt',
    ke: [['vorzeichen_aus_klammer', '4', 'Das Vorzeichen aus der Klammer übernommen: 4 statt −4.', 'Für welches x wird die Klammer (x + 4) null?'],
      ['koordinaten_vertauscht', '-5', 'x- und y-Koordinate vertauscht.', 'Welche Zahl steht in der Klammer?']] },
  { prompt: T_Y, r: '-5', n: 'exakt',
    ke: [['koordinaten_vertauscht', '-4', 'x- und y-Koordinate vertauscht.', 'Welche Zahl steht außerhalb der Klammer?'],
      ['koordinate_vorzeichen_verloren', '5', 'Das Minus vor der 5 nicht übernommen.', 'Welches Rechenzeichen steht vor der 5?']] }],
  weg: 'y = a(x − d)² + e mit S(d|e); der Faktor −2 ändert nur Öffnung und Streckung.\n(x + 4) wird null für x = −4, also d = {1}.\nAußerhalb der Klammer steht − 5, also e = {2}.\nS(−4|−5).' });
def({ ...SC, ref: 'quadrfkt-scheitel-04', titel: 'Scheitelpunkt · y = 4 − 2(x − 6)²', afb: 'II', sach: false,
  afbGrund: 'Anwenden: ungewohnte Reihenfolge, die Scheitelpunktform muss erst erkannt werden.',
  frage: `Gegeben ist die Parabel y = 4 − 2(x − 6)².\n\nGib die Koordinaten ihres Scheitelpunkts an. ${GANZ}`,
  teile: [{ prompt: T_X, r: '6', n: 'exakt',
    ke: [['vorzeichen_aus_klammer', '-6', 'Das Vorzeichen aus der Klammer übernommen: −6 statt 6.', 'Für welches x wird die Klammer (x − 6) null?'],
      ['koordinaten_vertauscht', '4', 'x- und y-Koordinate vertauscht.', 'Welche Zahl steht in der Klammer?']] },
  { prompt: T_Y, r: '4', n: 'exakt',
    ke: [['koordinaten_vertauscht', '6', 'x- und y-Koordinate vertauscht.', 'Welche Zahl steht außerhalb der Klammer?'],
      ['vorrang_ignoriert', '4-2', 'Die 4 mit der −2 verrechnet: 4 − 2 = 2.', 'Gehört die −2 zur 4 oder zur Klammer?']] }],
  weg: 'Umgestellt: y = −2(x − 6)² + 4.\n(x − 6) wird null für x = 6, also d = {1}.\nAußerhalb der Klammer steht + 4, also e = {2}.\nS(6|4).' });
def({ ...SC, ref: 'quadrfkt-scheitel-05', titel: 'Scheitelpunkt · Brückenbogen', afb: 'II', sach: true,
  afbGrund: 'Anwenden im Sachkontext: den höchsten Punkt als Scheitelpunkt erkennen, Dezimalzahlen.',
  frage: `Ein Brückenbogen hat die Form h(x) = −0,02 · (x − 25)² + 12,5. Dabei ist x der waagerechte Abstand vom linken Fußpunkt in Metern und h(x) die Höhe in Metern.\n\nWo liegt der höchste Punkt des Bogens? ${EXAKT}`,
  teile: [{ prompt: 'Abstand des höchsten Punkts vom linken Fußpunkt in m', r: '25', n: 'exakt',
    ke: [['vorzeichen_aus_klammer', '-25', 'Das Vorzeichen aus der Klammer übernommen: −25 statt 25.', 'Für welches x wird die Klammer (x − 25) null?'],
      ['koordinaten_vertauscht', '12.5', 'Die Höhe angegeben statt des Abstands.', 'Welche Zahl gehört zu x, welche zu h?']] },
  { prompt: 'Höhe des höchsten Punkts in m', r: '12.5', n: 'exakt',
    ke: [['koordinaten_vertauscht', '25', 'Den Abstand angegeben statt der Höhe.', 'Welche Zahl gehört zu x, welche zu h?']] }],
  weg: 'Der Faktor −0,02 ist negativ: Die Parabel ist nach unten geöffnet, der Scheitel ist der höchste Punkt.\nS(25|12,5).\nAbstand vom linken Fußpunkt: {1} m. Höhe: {2} m.' });
def({ ...SC, ref: 'quadrfkt-scheitel-06', titel: 'Rückrichtung · c aus dem Scheitel S(2|−1)', afb: 'III', sach: false,
  afbGrund: 'Problemlösen: Rückrichtung – Scheitelpunktform aufstellen und in die Normalform ausmultiplizieren.',
  frage: `Eine nach oben geöffnete Normalparabel (a = 1) hat den Scheitelpunkt S(2|−1). Ihre Gleichung lässt sich als y = x² + bx + c schreiben.\n\nWelchen Wert hat c? ${EXAKT}`, r: '(-2)^2-1', n: 'exakt',
  weg: 'Scheitelpunktform: y = (x − 2)² − 1.\nAusmultiplizieren: (x − 2)² = x² − 4x + 4.\ny = x² − 4x + 4 − 1 = x² − 4x + 3, also c = {A}.',
  ke: [['vorzeichen_potenz', '0-2^2-1', 'Das Quadrat von −2 negativ gerechnet: (−2)² = −4.', 'Welches Vorzeichen hat (−2) · (−2)?'],
    ['koordinate_vorzeichen_verloren', '2^2+1', 'Die y-Koordinate des Scheitels ohne Minus übernommen: + 1 statt − 1.', 'Liegt der Scheitelpunkt über oder unter der x-Achse?']] });

// ─── fkt_quadr_normalform (Tiefe 8) ───
const NF = { skill: 'fkt_quadr_normalform' };
def({ ...NF, ref: 'quadrfkt-normalform-01', titel: 'Quadratische Ergänzung · y = x² − 6x + 5', afb: 'I', sach: false,
  afbGrund: 'Reproduzieren: quadratische Ergänzung mit a = 1 und geradem b.',
  frage: `Gegeben ist die Parabel y = x² − 6x + 5.\n\nBestimme mit quadratischer Ergänzung die Koordinaten ihres Scheitelpunkts. ${GANZ}`,
  teile: [{ prompt: T_X, r: '6/2', n: 'exakt',
    ke: [['vorzeichen_aus_klammer', '-6/2', 'Aus (x − 3)² den Wert −3 abgelesen.', 'Für welches x wird die Klammer (x − 3) null?'],
      ['halbieren_vergessen', '6', 'Die Zahl vor x nicht halbiert: 6 statt 3.', 'Welche Zahl steht in der binomischen Formel (x − ?)² = x² − 6x + …?']] },
  { prompt: T_Y, r: '5-3^2', n: 'exakt',
    ke: [['ergaenzung_vorzeichen', '5+3^2', 'Die Ergänzung 9 addiert statt abgezogen: 5 + 9 = 14.', 'Du hast + 9 ergänzt – was musst du danach tun, damit der Term gleich bleibt?']] }],
  weg: 'Halbe Zahl vor x: 6 : 2 = 3, ihr Quadrat 9.\ny = x² − 6x + 9 − 9 + 5 = (x − 3)² − 4.\nScheitelpunkt: x = {1}, y = {2}, also S(3|−4).' });
def({ ...NF, ref: 'quadrfkt-normalform-02', titel: 'Quadratische Ergänzung · y = x² + 4x + 1', afb: 'I', sach: false,
  afbGrund: 'Reproduzieren: quadratische Ergänzung mit a = 1, positives b.',
  frage: `Gegeben ist die Parabel y = x² + 4x + 1.\n\nBestimme mit quadratischer Ergänzung die Koordinaten ihres Scheitelpunkts. ${GANZ}`,
  teile: [{ prompt: T_X, r: '-4/2', n: 'exakt',
    ke: [['vorzeichen_aus_klammer', '4/2', 'Aus (x + 2)² den Wert 2 abgelesen.', 'Für welches x wird die Klammer (x + 2) null?'],
      ['halbieren_vergessen', '-4', 'Die Zahl vor x nicht halbiert: −4 statt −2.', 'Welche Zahl steht in der binomischen Formel (x + ?)² = x² + 4x + …?']] },
  { prompt: T_Y, r: '1-2^2', n: 'exakt',
    ke: [['ergaenzung_vorzeichen', '1+2^2', 'Die Ergänzung 4 addiert statt abgezogen: 1 + 4 = 5.', 'Du hast + 4 ergänzt – was musst du danach tun, damit der Term gleich bleibt?'],
      ['halbieren_vergessen', '1-4^2', 'Die Zahl vor x nicht halbiert und 4² = 16 ergänzt.', 'Welche Zahl musst du quadrieren: 4 oder die Hälfte davon?']] }],
  weg: 'Halbe Zahl vor x: 4 : 2 = 2, ihr Quadrat 4.\ny = x² + 4x + 4 − 4 + 1 = (x + 2)² − 3.\nScheitelpunkt: x = {1}, y = {2}, also S(−2|−3).' });
def({ ...NF, ref: 'quadrfkt-normalform-03', titel: 'Quadratische Ergänzung · y = 2x² − 8x + 3', afb: 'II', sach: false,
  afbGrund: 'Anwenden: erst den Faktor 2 ausklammern, dann ergänzen; der Faktor wirkt auf die abgezogene Zahl.',
  frage: `Gegeben ist die Parabel y = 2x² − 8x + 3.\n\nBestimme mit quadratischer Ergänzung die Koordinaten ihres Scheitelpunkts. ${GANZ}`,
  teile: [{ prompt: T_X, r: '4/2', n: 'exakt',
    ke: [['vorzeichen_aus_klammer', '-4/2', 'Aus (x − 2)² den Wert −2 abgelesen.', 'Für welches x wird die Klammer (x − 2) null?'],
      ['halbieren_vergessen', '4', 'Die Zahl vor x in der Klammer nicht halbiert: 4 statt 2.', 'Welche Zahl steht in der binomischen Formel (x − ?)² = x² − 4x + …?']] },
  { prompt: T_Y, r: '2*(0-2^2)+3', n: 'exakt',
    ke: [['ergaenzung_vorzeichen', '2*2^2+3', 'Die Ergänzung addiert statt abgezogen: 2 · 4 + 3 = 11.', 'Du hast in der Klammer + 4 ergänzt – was musst du danach abziehen?'],
      ['mal_zwei_vergessen', '3-2^2', 'Die abgezogene 4 nicht mit dem ausgeklammerten Faktor 2 multipliziert: 3 − 4 = −1.', 'Was passiert mit der − 4, wenn du die Klammer mit 2 wieder auflöst?']] }],
  weg: 'Ausklammern: y = 2(x² − 4x) + 3.\nErgänzen: y = 2(x² − 4x + 4 − 4) + 3 = 2(x − 2)² − 8 + 3 = 2(x − 2)² − 5.\nScheitelpunkt: x = {1}, y = {2}, also S(2|−5).' });
def({ ...NF, ref: 'quadrfkt-normalform-04', titel: 'Quadratische Ergänzung · y = x² − 5x + 2', afb: 'II', sach: false,
  afbGrund: 'Anwenden: ungerades b, die Ergänzung ist eine Dezimalzahl.',
  frage: `Gegeben ist die Parabel y = x² − 5x + 2.\n\nBestimme mit quadratischer Ergänzung die Koordinaten ihres Scheitelpunkts. ${EXAKT}`,
  teile: [{ prompt: T_X, r: '5/2', n: 'exakt',
    ke: [['vorzeichen_aus_klammer', '-5/2', 'Aus (x − 2,5)² den Wert −2,5 abgelesen.', 'Für welches x wird die Klammer (x − 2,5) null?'],
      ['halbieren_vergessen', '5', 'Die Zahl vor x nicht halbiert: 5 statt 2,5.', 'Welche Zahl steht in der binomischen Formel (x − ?)² = x² − 5x + …?']] },
  { prompt: T_Y, r: '2-(5/2)^2', n: 'exakt',
    ke: [['ergaenzung_vorzeichen', '2+(5/2)^2', 'Die Ergänzung 6,25 addiert statt abgezogen: 2 + 6,25 = 8,25.', 'Du hast + 6,25 ergänzt – was musst du danach tun, damit der Term gleich bleibt?'],
      ['halbieren_vergessen', '2-5^2', 'Die Zahl vor x nicht halbiert und 5² = 25 ergänzt.', 'Welche Zahl musst du quadrieren: 5 oder die Hälfte davon?']] }],
  weg: 'Halbe Zahl vor x: 5 : 2 = 2,5, ihr Quadrat 6,25.\ny = x² − 5x + 6,25 − 6,25 + 2 = (x − 2,5)² − 4,25.\nScheitelpunkt: x = {1}, y = {2}, also S(2,5|−4,25).' });
def({ ...NF, ref: 'quadrfkt-normalform-05', titel: 'Quadratische Ergänzung · höchster Punkt einer Wurfbahn', afb: 'II', sach: true,
  afbGrund: 'Anwenden im Sachkontext: negativen Dezimalfaktor ausklammern und ergänzen, Scheitel als höchsten Punkt deuten.',
  frage: `Ein Ball fliegt auf der Bahn h(x) = −0,1x² + 2x + 1,5. Dabei ist x der waagerechte Abstand vom Abwurfpunkt in Metern und h(x) die Höhe des Balls in Metern.\n\nBestimme mit quadratischer Ergänzung, wo der Ball am höchsten ist. ${EXAKT}`,
  teile: [{ prompt: 'Waagerechter Abstand vom Abwurfpunkt am höchsten Punkt in m', r: '20/2', n: 'exakt',
    ke: [['vorzeichen_aus_klammer', '-20/2', 'Aus (x − 10)² den Wert −10 abgelesen.', 'Für welches x wird die Klammer (x − 10) null?'],
      ['halbieren_vergessen', '20', 'Die Zahl vor x in der Klammer nicht halbiert: 20 statt 10.', 'Welche Zahl steht in der binomischen Formel (x − ?)² = x² − 20x + …?']] },
  { prompt: 'Größte Höhe des Balls in m', r: '-0.1*(0-10^2)+1.5', n: 'exakt',
    ke: [['ergaenzung_vorzeichen', '-0.1*10^2+1.5', 'In der Klammer + 100 ein zweites Mal addiert statt abgezogen: −10 + 1,5 = −8,5.', 'Du hast in der Klammer + 100 ergänzt – was musst du danach abziehen?'],
      ['halbieren_vergessen', '-0.1*(0-20^2)+1.5', 'Die Zahl vor x nicht halbiert und 20² = 400 ergänzt.', 'Welche Zahl musst du quadrieren: 20 oder die Hälfte davon?']] }],
  weg: 'Ausklammern: h(x) = −0,1(x² − 20x) + 1,5.\nErgänzen: h(x) = −0,1(x² − 20x + 100 − 100) + 1,5 = −0,1(x − 10)² + 10 + 1,5.\nh(x) = −0,1(x − 10)² + 11,5: nach unten geöffnet, Scheitel S(10|11,5).\nAm höchsten {1} m vom Abwurfpunkt entfernt, Höhe {2} m.' });
def({ ...NF, ref: 'quadrfkt-normalform-06', titel: 'Problemlösen · Scheitelhöhe bei bekannter Scheitelstelle', afb: 'III', sach: false,
  afbGrund: 'Problemlösen: aus der Scheitelstelle erst b erschließen, dann ergänzen und den y-Wert bestimmen.',
  frage: `Die Parabel y = x² + bx + 7 hat ihren Scheitelpunkt bei x = 3.\n\nWelche y-Koordinate hat der Scheitelpunkt? ${EXAKT}`, r: '7-3^2', n: 'exakt',
  weg: 'Scheitel bei x = 3 heißt: y = (x − 3)² + e.\n(x − 3)² = x² − 6x + 9, also b = −6.\ny = x² − 6x + 9 − 9 + 7 = (x − 3)² − 2.\nDie y-Koordinate ist {A}.',
  ke: [['ergaenzung_vorzeichen', '7+3^2', 'Die Ergänzung 9 addiert statt abgezogen: 7 + 9 = 16.', 'Du hast + 9 ergänzt – was musst du danach tun, damit der Term gleich bleibt?'],
    ['falsche_groesse_beantwortet', '-6', 'Den Wert von b angegeben statt der y-Koordinate.', 'Ist nach b oder nach der y-Koordinate des Scheitels gefragt?']] });

// ─── fkt_quadr_nullstellen (Tiefe 9) ───
const NS = { skill: 'fkt_quadr_nullstellen' };
const N_KL = 'kleinere Nullstelle';
const N_GR = 'größere Nullstelle';
def({ ...NS, ref: 'quadrfkt-nullstellen-01', titel: 'Nullstellen · f(x) = x² − 2x − 8', afb: 'I', sach: false,
  afbGrund: 'Reproduzieren: p-q-Formel mit ganzzahligen Lösungen.',
  frage: `Gegeben ist die Funktion f(x) = x² − 2x − 8.\n\nBerechne ihre Nullstellen. ${GANZ}`,
  teile: [{ prompt: N_KL, r: '1-W(1+8)', n: 'exakt',
    ke: [['pq_vorzeichen', '-1-W(1+8)', 'p mit falschem Vorzeichen eingesetzt: −1 ± 3, kleinere Lösung −4.', 'Wie lautet −p/2, wenn p = −2 ist?']] },
  { prompt: N_GR, r: '1+W(1+8)', n: 'exakt',
    ke: [['pq_vorzeichen', '-1+W(1+8)', 'p mit falschem Vorzeichen eingesetzt: −1 ± 3, größere Lösung 2.', 'Wie lautet −p/2, wenn p = −2 ist?']] }],
  weg: 'f(x) = 0: x² − 2x − 8 = 0, p = −2, q = −8.\nx = 1 ± √(1 + 8) = 1 ± 3.\nKleinere Nullstelle {1}, größere Nullstelle {2}.' });
def({ ...NS, ref: 'quadrfkt-nullstellen-02', titel: 'Nullstellen · f(x) = (x − 1)² − 4', afb: 'I', sach: false,
  afbGrund: 'Reproduzieren: Nullstellen aus der Scheitelpunktform durch Wurzelziehen.',
  frage: `Gegeben ist die Funktion f(x) = (x − 1)² − 4.\n\nBerechne ihre Nullstellen. ${GANZ}`,
  teile: [{ prompt: N_KL, r: '1-W(4)', n: 'exakt',
    ke: [['vorzeichen_aus_klammer', '-1-W(4)', 'Aus (x − 1) den Wert −1 übernommen: x = −1 ± 2.', 'Für welches x wird die Klammer (x − 1) null?']] },
  { prompt: N_GR, r: '1+W(4)', n: 'exakt',
    ke: [['vorzeichen_aus_klammer', '-1+W(4)', 'Aus (x − 1) den Wert −1 übernommen: x = −1 ± 2.', 'Für welches x wird die Klammer (x − 1) null?']] }],
  weg: 'f(x) = 0: (x − 1)² = 4.\nx − 1 = 2 oder x − 1 = −2.\nx = 3 oder x = −1.\nKleinere Nullstelle {1}, größere Nullstelle {2}.' });
def({ ...NS, ref: 'quadrfkt-nullstellen-03', titel: 'Nullstellen · aus der Abbildung ablesen', afb: 'II', sach: false,
  afbGrund: 'Anwenden: nach unten geöffnete Parabel, Schnittpunkte mit der x-Achse von Scheitel und y-Achsenabschnitt unterscheiden.',
  frage: `Die Abbildung zeigt die Parabel einer quadratischen Funktion f.\n\nLies die Nullstellen von f ab. ${GANZ}`,
  figur: { params: { x_min: -6, x_max: 4, y_min: -2, y_max: 9, funktionen: [{ typ: 'quadratisch', a: -0.5, b: -1, c: 7.5 }] },
    alt_text: 'Koordinatensystem mit Gitter und einer nach unten geöffneten Parabel, die die x-Achse zweimal schneidet.' },
  teile: [{ prompt: N_KL, r: '-5', n: 'exakt',
    ke: [['falsche_groesse_beantwortet', '-1', 'Die x-Koordinate des Scheitelpunkts abgelesen statt einer Nullstelle.', 'Wo schneidet die Parabel die x-Achse?'],
      ['koordinate_vorzeichen_verloren', '5', 'Das Minus vergessen: Die Nullstelle liegt links der y-Achse.', 'Liegt diese Nullstelle links oder rechts der y-Achse?']] },
  { prompt: N_GR, r: '3', n: 'exakt',
    ke: [['koordinate_vorzeichen_verloren', '-3', 'Das Vorzeichen falsch: Die Nullstelle liegt rechts der y-Achse.', 'Liegt diese Nullstelle links oder rechts der y-Achse?'],
      ['koordinaten_vertauscht', '7.5', 'Den Schnittpunkt mit der y-Achse abgelesen statt mit der x-Achse.', 'Auf welcher Achse liegen die Nullstellen?']] }],
  weg: 'Nullstellen sind die Stellen, an denen die Parabel die x-Achse schneidet.\nLinker Schnittpunkt: x = {1}. Rechter Schnittpunkt: x = {2}.' });
def({ ...NS, ref: 'quadrfkt-nullstellen-04', titel: 'Nullstellen · f(x) = 2x² + 4x − 6', afb: 'II', sach: false,
  afbGrund: 'Anwenden: erst durch den Faktor 2 teilen, dann p-q-Formel.',
  frage: `Gegeben ist die Funktion f(x) = 2x² + 4x − 6.\n\nBerechne ihre Nullstellen. ${GANZ}`,
  teile: [{ prompt: N_KL, r: '-1-W(1+3)', n: 'exakt',
    ke: [['pq_vorzeichen', '1-W(1+3)', 'p mit falschem Vorzeichen eingesetzt: 1 ± 2, kleinere Lösung −1.', 'Wie lautet −p/2, wenn p = 2 ist?']] },
  { prompt: N_GR, r: '-1+W(1+3)', n: 'exakt',
    ke: [['pq_vorzeichen', '1+W(1+3)', 'p mit falschem Vorzeichen eingesetzt: 1 ± 2, größere Lösung 3.', 'Wie lautet −p/2, wenn p = 2 ist?']] }],
  weg: 'f(x) = 0, durch 2 teilen: x² + 2x − 3 = 0, p = 2, q = −3.\nx = −1 ± √(1 + 3) = −1 ± 2.\nKleinere Nullstelle {1}, größere Nullstelle {2}.' });
def({ ...NS, ref: 'quadrfkt-nullstellen-05', titel: 'Nullstelle · wann der Ball den Boden trifft', einheit: 's', afb: 'II', sach: true, n: 2,
  afbGrund: 'Anwenden im Sachkontext: Boden als h = 0 deuten, durch −5 teilen, p-q-Formel, negative Lösung verwerfen.',
  frage: `Ein Ball wird geworfen. Seine Höhe über dem Boden ist h(t) = −5t² + 12t + 2 (t in Sekunden nach dem Abwurf, h in Metern).\n\nNach wie vielen Sekunden trifft der Ball auf dem Boden auf? Runde auf zwei Stellen nach dem Komma.`, r: '1.2+W(1.44+0.4)',
  weg: 'Boden: h(t) = 0. Durch −5 teilen: t² − 2,4t − 0,4 = 0, p = −2,4, q = −0,4.\nt = 1,2 ± √(1,44 + 0,4) = 1,2 ± √1,84 ≈ 1,2 ± 1,356.\nDie negative Lösung passt nicht (vor dem Abwurf). Der Ball trifft nach etwa {A} s auf.',
  ke: [['pq_vorzeichen', '-1.2+W(1.44+0.4)', 'p mit falschem Vorzeichen eingesetzt: −1,2 + √1,84 ≈ 0,16.', 'Wie lautet −p/2, wenn p = −2,4 ist?'],
    ['vorzeichen_beim_umstellen', '1.2+W(1.44-0.4)', 'Beim Teilen durch −5 das Vorzeichen von q nicht umgedreht: q = 0,4.', 'Welches Vorzeichen hat 2 : (−5)?']] });
def({ ...NS, ref: 'quadrfkt-nullstellen-06', titel: 'Rückrichtung · Scheitelhöhe aus den Nullstellen', afb: 'III', sach: false,
  afbGrund: 'Problemlösen: Scheitelstelle als Mitte der Nullstellen erkennen und den Funktionsterm selbst aufstellen.',
  frage: `Eine nach oben geöffnete Normalparabel hat die Nullstellen −1 und 5.\n\nWelche y-Koordinate hat ihr Scheitelpunkt? ${EXAKT}`, r: '(2+1)*(2-5)', n: 'exakt',
  weg: 'Funktionsterm aus den Nullstellen: f(x) = (x + 1)(x − 5).\nDer Scheitel liegt in der Mitte der Nullstellen: x = (−1 + 5) : 2 = 2.\nf(2) = 3 · (−3) = {A}.',
  ke: [['falsche_groesse_beantwortet', '(5-1)/2', 'Die x-Koordinate des Scheitels angegeben statt der y-Koordinate.', 'Ist nach der Stelle oder nach dem Funktionswert am Scheitel gefragt?'],
    ['halbieren_vergessen', '(4+1)*(4-5)', 'Die Mitte nicht halbiert: x = 4 statt 2 eingesetzt.', 'Wie findest du die Mitte zwischen −1 und 5?']] });

// ─── fkt_quadr_extrem (Tiefe 9) ───
const EX = { skill: 'fkt_quadr_extrem', n: 'exakt' };
def({ ...EX, ref: 'quadrfkt-extrem-01', titel: 'Größter Funktionswert · f(x) = −(x − 4)² + 7', afb: 'I', sach: false,
  afbGrund: 'Reproduzieren: Extremwert direkt aus der Scheitelpunktform ablesen.',
  frage: `Die Funktion f(x) = −(x − 4)² + 7 hat einen größten Funktionswert.\n\nWie groß ist dieser größte Funktionswert? ${EXAKT}`, r: '7',
  weg: 'Die Parabel ist nach unten geöffnet (Minus vor der Klammer).\nDer größte Wert liegt am Scheitel S(4|7).\nDer größte Funktionswert ist {A}.',
  ke: [['falsche_groesse_beantwortet', '4', 'Die Stelle x = 4 angegeben statt des Funktionswerts.', 'Ist nach der Stelle oder nach dem Funktionswert gefragt?'],
    ['koordinate_vorzeichen_verloren', '-7', 'Das Minus vor der Klammer auf die 7 übertragen.', 'Welches Vorzeichen hat f(4) = −0² + 7?']] });
def({ ...EX, ref: 'quadrfkt-extrem-02', titel: 'Kleinster Funktionswert · f(x) = x² − 8x + 10', afb: 'I', sach: false,
  afbGrund: 'Reproduzieren: quadratische Ergänzung, dann den Extremwert am Scheitel ablesen.',
  frage: `Die Funktion f(x) = x² − 8x + 10 hat einen kleinsten Funktionswert.\n\nWie groß ist dieser kleinste Funktionswert? ${EXAKT}`, r: '10-4^2',
  weg: 'Quadratische Ergänzung: f(x) = x² − 8x + 16 − 16 + 10 = (x − 4)² − 6.\nNach oben geöffnet, der kleinste Wert liegt am Scheitel S(4|−6).\nDer kleinste Funktionswert ist {A}.',
  ke: [['ergaenzung_vorzeichen', '10+4^2', 'Die Ergänzung 16 addiert statt abgezogen: 10 + 16 = 26.', 'Du hast + 16 ergänzt – was musst du danach tun, damit der Term gleich bleibt?'],
    ['falsche_groesse_beantwortet', '4', 'Die Stelle x = 4 angegeben statt des Funktionswerts.', 'Ist nach der Stelle oder nach dem Funktionswert gefragt?']] });
def({ ...EX, ref: 'quadrfkt-extrem-03', titel: 'Größter Funktionswert · f(x) = −2x² + 12x − 5', afb: 'II', sach: false,
  afbGrund: 'Anwenden: negativen Faktor ausklammern, ergänzen, Extremwert bestimmen.',
  frage: `Die Funktion f(x) = −2x² + 12x − 5 hat einen größten Funktionswert.\n\nWie groß ist dieser größte Funktionswert? ${EXAKT}`, r: '-2*(0-3^2)-5',
  weg: 'Ausklammern: f(x) = −2(x² − 6x) − 5.\nErgänzen: f(x) = −2(x² − 6x + 9 − 9) − 5 = −2(x − 3)² + 18 − 5 = −2(x − 3)² + 13.\nNach unten geöffnet, der größte Funktionswert ist {A}.',
  ke: [['ergaenzung_vorzeichen', '-2*3^2-5', 'In der Klammer + 9 ein zweites Mal addiert statt abgezogen: −18 − 5 = −23.', 'Du hast in der Klammer + 9 ergänzt – was musst du danach abziehen?'],
    ['falsche_groesse_beantwortet', '3', 'Die Stelle x = 3 angegeben statt des Funktionswerts.', 'Ist nach der Stelle oder nach dem Funktionswert gefragt?'],
    ['mal_zwei_vergessen', '3^2-5', 'Die abgezogene 9 nicht mit dem ausgeklammerten Faktor −2 multipliziert: 9 − 5 = 4.', 'Was passiert mit der − 9, wenn du die Klammer mit −2 wieder auflöst?']] });
def({ ...EX, ref: 'quadrfkt-extrem-04', titel: 'Zahlenrätsel · Summe 20, größtes Produkt', afb: 'II', sach: false,
  afbGrund: 'Anwenden: Produktfunktion P(x) = x · (20 − x) aufstellen und ihren Scheitel bestimmen.',
  frage: `Zwei Zahlen haben die Summe 20. Ihr Produkt soll so groß wie möglich sein.\n\nWie groß ist das größte mögliche Produkt? ${EXAKT}`, r: '10*(20-10)',
  weg: 'Erste Zahl x, zweite Zahl 20 − x. Produkt P(x) = x · (20 − x) = −x² + 20x.\nErgänzen: P(x) = −(x² − 20x + 100 − 100) = −(x − 10)² + 100.\nDas größte Produkt ist {A} (für x = 10 und 20 − x = 10).',
  ke: [['falsche_groesse_beantwortet', '10', 'Die Zahl x = 10 angegeben statt des Produkts.', 'Ist nach einer der Zahlen oder nach ihrem Produkt gefragt?'],
    ['ergaenzung_vorzeichen', '0-10^2', 'In der Klammer + 100 ein zweites Mal addiert statt abgezogen: P = −100.', 'Kann das Produkt zweier Zahlen mit der Summe 20 negativ sein, wenn beide 10 sind?']] });
def({ ...EX, ref: 'quadrfkt-extrem-05', titel: 'Maximale Höhe · Wurfbahn h(t) = −5t² + 20t + 1', einheit: 'm', afb: 'II', sach: true,
  afbGrund: 'Anwenden im Sachkontext: höchsten Punkt als Scheitel deuten, die Höhe und nicht den Zeitpunkt angeben.',
  frage: `Ein Ball wird senkrecht nach oben geworfen. Seine Höhe ist h(t) = −5t² + 20t + 1 (t in Sekunden nach dem Abwurf, h in Metern).\n\nWelche maximale Höhe erreicht der Ball? ${EXAKT}`, r: '-5*(0-2^2)+1',
  weg: 'Ausklammern: h(t) = −5(t² − 4t) + 1.\nErgänzen: h(t) = −5(t² − 4t + 4 − 4) + 1 = −5(t − 2)² + 20 + 1 = −5(t − 2)² + 21.\nNach 2 s erreicht der Ball die maximale Höhe {A} m.',
  ke: [['falsche_groesse_beantwortet', '2', 'Den Zeitpunkt t = 2 angegeben statt der Höhe.', 'Ist nach dem Zeitpunkt oder nach der Höhe gefragt?'],
    ['ergaenzung_vorzeichen', '-5*2^2+1', 'In der Klammer + 4 ein zweites Mal addiert statt abgezogen: −20 + 1 = −19.', 'Kann die maximale Höhe des Balls negativ sein?'],
    ['vorrang_ignoriert', '(-5*2)^2+20*2+1', 'Beim Einsetzen von t = 2 erst mit −5 multipliziert, dann quadriert: (−10)² + 40 + 1.', 'Was wird in −5t² zuerst gerechnet: das Quadrat oder das Mal −5?']] });
def({ ...EX, ref: 'quadrfkt-extrem-06', titel: 'Größte Fläche · 40 m Zaun an einer Mauer', einheit: 'm²', afb: 'III', sach: true,
  afbGrund: 'Problemlösen: Zielfunktion A(x) aus dem Sachtext selbst aufstellen (Mauer als vierte Seite), Scheitel bestimmen, Fläche angeben.',
  frage: `An einer langen Mauer soll mit 40 m Zaun eine rechteckige Fläche eingezäunt werden. Die Mauer bildet eine Seite des Rechtecks, die anderen drei Seiten werden mit dem Zaun begrenzt. Der ganze Zaun wird verbraucht.\n\nWie groß ist der größtmögliche Flächeninhalt in Quadratmetern? ${EXAKT}`, r: '10*(40-2*10)',
  weg: 'Zwei Seiten senkrecht zur Mauer je x m, die Seite parallel zur Mauer (40 − 2x) m.\nA(x) = x · (40 − 2x) = −2x² + 40x = −2(x² − 20x + 100 − 100) = −2(x − 10)² + 200.\nFür x = 10 m (Seiten 10 m, 20 m, 10 m) ist die Fläche am größten: {A} m².',
  ke: [['falsche_groesse_beantwortet', '10', 'Die Seitenlänge x = 10 angegeben statt der Fläche.', 'Ist nach einer Seitenlänge oder nach dem Flächeninhalt gefragt?'],
    ['bedingung_unvollstaendig', '10*10', 'Die Mauer nicht beachtet: Zaun auf allen vier Seiten, Quadrat 10 m · 10 m.', 'Wie viele Seiten des Rechtecks braucht der Zaun?']] });

baueCharge({
  thema: 'quadrfkt',
  batch: 'k9-quadrfkt',
  source: 'edvance_k9_quadrfkt',
  idsPfad: 'docs/prefill/k9-quadrfkt-ids.json',
  kopf: [
    `K9-Rest, Thema quadrfkt — ${A.length} Aufgaben: je sechs zu fkt_quadr_parabel, _scheitel, _normalform, _nullstellen und _extrem.`,
    'Erzeugt von tools/vorlauf-build.mjs aus docs/prefill/k9-quadrfkt.json (Quelle: tools/k9-quadrfkt-charge.mjs) — nicht von Hand editieren.',
    '',
    'Einspiel-Reihenfolge: nach 20261003105856_substrat_k9_quadrfkt.sql (Knoten + Fehlbild-Slugs muessen stehen).',
    `Vier Aufgaben mit Abbildung (Generator koordinatensystem, task_figures ohne svg_hash; Upload per scripts/figures/upload_figures.py).`,
  ],
  auswahl: 'Je Knoten vier reine Anwendung mit steigender Schwierigkeit, eine mit Sachkontext (Wasserstrahl, Brückenbogen, Wurfbahn, Ball) und eine AFB III (Rückrichtung oder Problemlösen, Zaun an der Mauer). Scheitelpunkte und Nullstellenpaare als MULTI_PART (Eingabe nur Zahlen). Vier Aufgaben mit Parabel im Koordinatensystem, alle übrigen ohne Abbildung lösbar. Jede Aufgabe nennt, ob exakt oder gerundet; alle Werte exakt nachgerechnet.',
  aufgaben: A,
});
