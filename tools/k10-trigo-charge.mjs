#!/usr/bin/env node
/**
 * k10-trigo-charge.mjs — erzeugt docs/prefill/k10-trigo.json (Charge-Format von vorlauf-build.mjs).
 *
 *   node tools/k10-trigo-charge.mjs
 *
 * Lauf "K10-Rest", Thema trigo (Trigonometrie, KLP G9 NRW Geo-7 bis Geo-10, Zweite Stufe, Klasse 10).
 * Je sechs Aufgaben zu geo_trigo_verhaeltnis, _seite, _winkel, _anwendung und _kosinussatz.
 * Jeder Wert (richtig und falsch) und jede Zwischenzahl im Lösungsweg wird über die Ausdrücke von
 * tools/k10-rest-lib.mjs gerechnet (S/C/T im Gradmaß, SR/CR/TR im Bogenmaß für den Modusfehler,
 * AS/AC/AT mit Ergebnis in Grad), nie von Hand. Dreiecke stehen als Text mit fester Benennung
 * (docs/k10-rest/phase1.md e); keine Abbildung (kein passender Generator).
 * Die ids stehen in docs/prefill/k10-trigo-ids.json: ein zweiter Lauf erzeugt dieselbe Charge.
 */

import { baueCharge, CLUSTER, wert } from './k10-rest-lib.mjs';

const BASIS = {
  inhalt: 'geometrie', cluster: CLUSTER.geo, stoff: 10,
  stoffGrund: 'Stoffanker Klasse 10: KLP G9 NRW, Zweite Stufe, Geo-7 bis Geo-10 (Trigonometrie); alle 25 Kölner Schulpläne legen das Thema in Klasse 10.',
  clusterGrund: 'Geometrie & Messen wie geo_pythagoras_* und geo_aehnlich_* im Bestand.',
  inhaltGrund: 'Inhaltsfeld Geometrie (Geo-7 bis Geo-10, Trigonometrie).',
};
const A = [];
const def = (o) => A.push({ ...BASIS, ...o });
/** Zwischenwert für Lösungsweg und Fehlertext, gerechnet wie die Antworten (Standard: vier Stellen). */
const z = (expr, n = 4) => wert(expr, n).haupt.replace('-', '−');

const EXAKT = 'Gib das Ergebnis exakt an.';
const R1 = 'Runde auf eine Stelle nach dem Komma.';
const R2 = 'Runde auf zwei Stellen nach dem Komma.';
const R4 = 'Runde auf vier Stellen nach dem Komma.';
const DR = 'Im Dreieck ABC ist der Winkel bei C ein rechter Winkel. Die Seite a liegt der Ecke A gegenüber, b der Ecke B, c ist die Hypotenuse. α ist der Winkel bei A.';
const DRB = `${DR} β ist der Winkel bei B.`;
const KO = 'Im Dreieck ABC liegt die Seite a der Ecke A gegenüber, b der Ecke B und c der Ecke C. γ ist der Winkel bei C. Das Dreieck hat keinen rechten Winkel.';
const GRAD = 'Winkel sind im Gradmaß angegeben.';
const WG = 'Gib den Winkel im Gradmaß an.';

// ─── geo_trigo_verhaeltnis (Tiefe 7) ───
const VE = { skill: 'geo_trigo_verhaeltnis' };
def({ ...VE, ref: 'trigo-verhaeltnis-01', titel: 'Sinus als Seitenverhältnis · a = 3 cm, c = 5 cm', afb: 'I', sach: false,
  afbGrund: 'Reproduzieren: sin α = Gegenkathete : Hypotenuse mit allen drei gegebenen Seiten.',
  frage: `${DR}\n\nGegeben sind a = 3 cm, b = 4 cm und c = 5 cm.\n\nBestimme sin α als Seitenverhältnis. ${EXAKT}`,
  r: '3/5', n: 'exakt',
  weg: 'Für α ist a die Gegenkathete und c die Hypotenuse.\nsin α = a : c = 3 : 5 = {A}.',
  ke: [['sin_cos_vertauscht', '4/5', 'Ankathete statt Gegenkathete genommen: b : c = 0,8 ist cos α.', 'Welche Seite liegt dem Winkel α gegenüber?'],
    ['tangens_verwechselt', '3/4', 'Durch die Kathete b statt durch die Hypotenuse geteilt: a : b = 0,75 ist tan α.', 'Welche Seite steht beim Sinus im Nenner?']] });
def({ ...VE, ref: 'trigo-verhaeltnis-02', titel: 'Sinuswert · sin 35° mit dem Taschenrechner', afb: 'I', sach: false,
  afbGrund: 'Reproduzieren: einen Sinuswert im Gradmaß mit dem Taschenrechner bestimmen und runden.',
  frage: `Berechne sin 35° mit dem Taschenrechner. ${GRAD}\n\n${R4}`,
  r: 'S(35)', n: 4,
  weg: 'Taschenrechner auf Gradmaß (DEG) stellen.\nsin 35° ≈ {A}.',
  ke: [['bogenmass_modus', 'SR(35)', `Der Taschenrechner stand auf Bogenmaß: sin(35) ≈ ${z('SR(35)')}.`, 'Kann der Sinus eines spitzen Winkels negativ sein?'],
    ['sin_cos_vertauscht', 'C(35)', `cos 35° ≈ ${z('C(35)')} statt sin 35° berechnet.`, 'Welche Taste hast du gedrückt: sin oder cos?'],
    ['tangens_verwechselt', 'T(35)', `tan 35° ≈ ${z('T(35)')} statt sin 35° berechnet.`, 'Welche Taste hast du gedrückt: sin oder tan?']] });
def({ ...VE, ref: 'trigo-verhaeltnis-03', titel: 'Tangens · erst die fehlende Kathete, a = 9 cm, c = 15 cm', afb: 'II', sach: false,
  afbGrund: 'Anwenden: fehlende Kathete mit dem Satz des Pythagoras, dann tan α als Kathetenverhältnis.',
  frage: `${DR}\n\nGegeben sind a = 9 cm und c = 15 cm.\n\nBestimme tan α. ${EXAKT}`,
  r: '9/W(15^2-9^2)', n: 'exakt',
  weg: 'Fehlende Kathete: b = √(c² − a²) = √(225 − 81) = √144 = 12 cm.\ntan α = Gegenkathete : Ankathete = a : b = 9 : 12 = {A}.',
  ke: [['tangens_verwechselt', '9/15', 'Durch die Hypotenuse statt durch die Ankathete geteilt: a : c = 0,6 ist sin α.', 'Welche zwei Seiten setzt der Tangens ins Verhältnis?'],
    ['sin_cos_vertauscht', 'W(15^2-9^2)/9', 'Gegenkathete und Ankathete vertauscht: b : a = 12 : 9.', 'Welche Kathete liegt dem Winkel α gegenüber?', 2],
    ['hypotenuse_verwechselt', '9/W(15^2+9^2)', 'Für b die Quadrate addiert statt subtrahiert: b = √306.', 'Kann die Kathete b länger sein als die Hypotenuse c?', 2]] });
def({ ...VE, ref: 'trigo-verhaeltnis-04', titel: 'Kosinus von β · a = 5 cm, b = 12 cm, c = 13 cm', afb: 'II', sach: false,
  afbGrund: 'Anwenden: Gegen- und Ankathete für den Winkel β neu zuordnen, Bruch runden.',
  frage: `${DRB}\n\nGegeben sind a = 5 cm, b = 12 cm und c = 13 cm.\n\nBestimme cos β. ${R4}`,
  r: '5/13', n: 4,
  weg: 'Für β liegt b gegenüber (Gegenkathete), a liegt an β an (Ankathete).\ncos β = Ankathete : Hypotenuse = a : c = 5 : 13 ≈ {A}.',
  ke: [['sin_cos_vertauscht', '12/13', 'Die Rollen von α übernommen: b : c ist sin β, nicht cos β.', 'Welche Kathete liegt am Winkel β an?'],
    ['tangens_verwechselt', '5/12', 'Durch die Kathete b statt durch die Hypotenuse geteilt: 5 : 12.', 'Welche Seite steht beim Kosinus im Nenner?']] });
def({ ...VE, ref: 'trigo-verhaeltnis-05', titel: 'Ähnliche Dreiecke · gleicher Sinus, c\' = 12 cm', einheit: 'cm', afb: 'II', sach: false,
  afbGrund: 'Rückrichtung: Das Seitenverhältnis bleibt in ähnlichen Dreiecken gleich; aus ihm eine Seite des zweiten Dreiecks bestimmen.',
  frage: `${DR}\n\nEs ist a = 3 cm und c = 5 cm.\n\nEin zweites Dreieck A'B'C' hat ebenfalls bei C' einen rechten Winkel und bei A' denselben Winkel α. Die Seite a' liegt der Ecke A' gegenüber, die Hypotenuse ist c' = 12 cm.\n\nWie lang ist a'? ${EXAKT}`,
  r: '12*3/5', n: 'exakt',
  weg: 'Gleicher Winkel α, also gleiches Verhältnis: sin α = a : c = 3 : 5 = 0,6.\na\' = c\' · sin α = 12 cm · 0,6 = {A} cm.',
  ke: [['sin_cos_vertauscht', '12*W(5^2-3^2)/5', 'Mit b : c = 4 : 5 gerechnet, also mit cos α: 12 · 0,8.', 'Welche Seite liegt dem Winkel α gegenüber?'],
    ['tangens_verwechselt', '12*3/W(5^2-3^2)', 'Mit a : b = 3 : 4 gerechnet, also mit tan α: 12 · 0,75.', 'Welches Verhältnis verbindet a mit der Hypotenuse?'],
    ['additiv_statt_multiplikativ', '3+(12-5)', 'Die Hypotenuse wächst um 7 cm, also a um 7 cm: 3 + 7.', 'Bleibt in ähnlichen Dreiecken der Unterschied oder das Verhältnis der Seiten gleich?']] });
def({ ...VE, ref: 'trigo-verhaeltnis-06', titel: 'Aus tan α = 0,75 und c = 20 cm die Seite a', einheit: 'cm', afb: 'III', sach: false,
  afbGrund: 'Problemlösen: Rückrichtung vom Verhältnis zu den Seiten; Seitenverhältnis 3 : 4 erkennen, mit Pythagoras auf die Hypotenuse schließen.',
  frage: `${DR}\n\nEs ist tan α = 0,75 und c = 20 cm.\n\nWie lang ist die Seite a? ${EXAKT}`,
  r: '20*3/W(3^2+4^2)', n: 'exakt',
  weg: 'tan α = a : b = 0,75 = 3 : 4, also a = 3k und b = 4k.\nPythagoras: c = √((3k)² + (4k)²) = 5k = 20 cm, also k = 4 cm.\na = 3 · 4 cm = {A} cm.',
  ke: [['tangens_verwechselt', '0.75*20', 'tan α wie sin α benutzt: a = 0,75 · 20 cm.', 'Steht beim Tangens die Hypotenuse im Verhältnis?'],
    ['sin_cos_vertauscht', '20*4/W(3^2+4^2)', 'Die Ankathete b = 4k berechnet statt der Gegenkathete a.', 'Welche Kathete liegt dem Winkel α gegenüber?']] });

// ─── geo_trigo_seite (Tiefe 8) ───
const SE = { skill: 'geo_trigo_seite' };
def({ ...SE, ref: 'trigo-seite-01', titel: 'Gegenkathete · α = 35°, c = 10 cm', einheit: 'cm', afb: 'I', sach: false,
  afbGrund: 'Reproduzieren: a = c · sin α, gesuchte Seite im Zähler.',
  frage: `${DR}\n\nGegeben sind α = 35° und c = 10 cm.\n\nWie lang ist die Seite a? ${R2}`,
  r: '10*S(35)', n: 2,
  weg: `sin α = a : c, also a = c · sin α.\na = 10 cm · sin 35° ≈ 10 cm · ${z('S(35)')} ≈ {A} cm.`,
  ke: [['sin_cos_vertauscht', '10*C(35)', 'Mit cos 35° gerechnet: Das ist die Ankathete b.', 'Liegt a dem Winkel α gegenüber oder an ihm an?'],
    ['tangens_verwechselt', '10*T(35)', 'Mit tan 35° gerechnet, obwohl die Hypotenuse gegeben ist.', 'Welches Verhältnis enthält die Hypotenuse und die Gegenkathete?'],
    ['bogenmass_modus', '10*SR(35)', 'Der Taschenrechner stand auf Bogenmaß: sin(35) ist negativ.', 'Kann eine Seite negativ lang sein?']] });
def({ ...SE, ref: 'trigo-seite-02', titel: 'Gegenkathete über den Tangens · α = 40°, b = 6 cm', einheit: 'cm', afb: 'I', sach: false,
  afbGrund: 'Reproduzieren: a = b · tan α, zwei Katheten im Verhältnis.',
  frage: `${DR}\n\nGegeben sind α = 40° und b = 6 cm.\n\nWie lang ist die Seite a? ${R2}`,
  r: '6*T(40)', n: 2,
  weg: `tan α = a : b, also a = b · tan α.\na = 6 cm · tan 40° ≈ 6 cm · ${z('T(40)')} ≈ {A} cm.`,
  ke: [['sin_cos_vertauscht', '6/T(40)', 'Gegen- und Ankathete vertauscht: tan α = b : a, also a = b : tan α.', 'Welche Kathete liegt dem Winkel α gegenüber?'],
    ['tangens_verwechselt', '6*S(40)', 'Mit sin 40° gerechnet, als wäre b die Hypotenuse.', 'Ist b eine Kathete oder die Hypotenuse?'],
    ['bogenmass_modus', '6*TR(40)', 'Der Taschenrechner stand auf Bogenmaß: tan(40) ist negativ.', 'Kann eine Seite negativ lang sein?']] });
def({ ...SE, ref: 'trigo-seite-03', titel: 'Hypotenuse im Nenner · α = 28°, a = 4,5 cm', einheit: 'cm', afb: 'II', sach: false,
  afbGrund: 'Anwenden: Die gesuchte Seite steht im Nenner; sin α = a : c nach c umstellen.',
  frage: `${DR}\n\nGegeben sind α = 28° und a = 4,5 cm.\n\nWie lang ist die Hypotenuse c? ${R2}`,
  r: '4.5/S(28)', n: 2,
  weg: `sin α = a : c, also c = a : sin α.\nc = 4,5 cm : sin 28° ≈ 4,5 cm : ${z('S(28)')} ≈ {A} cm.`,
  ke: [['multipliziert_statt_dividiert', '4.5*S(28)', 'a · sin α statt a : sin α gerechnet.', 'Kann die Hypotenuse kürzer sein als die Kathete a?'],
    ['sin_cos_vertauscht', '4.5/C(28)', 'Mit cos 28° gerechnet, als läge a am Winkel α an.', 'Liegt a dem Winkel α gegenüber oder an ihm an?'],
    ['tangens_verwechselt', '4.5/T(28)', 'Mit tan 28° gerechnet: Das ergibt die Kathete b, nicht die Hypotenuse.', 'Welches Verhältnis enthält die Hypotenuse?'],
    ['bogenmass_modus', '4.5/SR(28)', 'Der Taschenrechner stand auf Bogenmaß.', 'Hast du DEG oder RAD in der Anzeige?']] });
def({ ...SE, ref: 'trigo-seite-04', titel: 'Ankathete · α = 52°, c = 8,4 cm', einheit: 'cm', afb: 'II', sach: false,
  afbGrund: 'Anwenden: Ankathete erkennen, Kosinus wählen, ohne gerundeten Zwischenwert rechnen.',
  frage: `${DR}\n\nGegeben sind α = 52° und c = 8,4 cm.\n\nWie lang ist die Seite b? Rechne ohne gerundete Zwischenergebnisse. ${R2}`,
  r: '8.4*C(52)', n: 2,
  weg: `b liegt am Winkel α an (Ankathete): cos α = b : c, also b = c · cos α.\nb = 8,4 cm · cos 52° ≈ 8,4 cm · ${z('C(52)')} ≈ {A} cm.`,
  ke: [['sin_cos_vertauscht', '8.4*S(52)', 'Mit sin 52° gerechnet: Das ist die Gegenkathete a.', 'Liegt b dem Winkel α gegenüber oder an ihm an?'],
    ['zu_frueh_gerundet', '8.4*0.62', 'cos 52° auf 0,62 gerundet und damit weitergerechnet.', 'Wie stark ändert sich das Ergebnis, wenn du cos 52° vorher rundest?'],
    ['bogenmass_modus', '8.4*CR(52)', 'Der Taschenrechner stand auf Bogenmaß: cos(52) ist negativ.', 'Kann eine Seite negativ lang sein?']] });
def({ ...SE, ref: 'trigo-seite-05', titel: 'Rampe · 0,8 m Höhe unter 6°', einheit: 'm', afb: 'II', sach: true,
  afbGrund: 'Anwenden im Sachkontext: Rampe als Hypotenuse erkennen, gesuchte Länge im Nenner.',
  frage: `Eine Rampe steigt gleichmäßig unter einem Winkel von 6° gegen die Waagerechte an. ${GRAD} Sie überwindet einen Höhenunterschied von 0,8 m.\n\nWie lang ist die schräge Fläche der Rampe? ${R2}`,
  r: '0.8/S(6)', n: 2,
  weg: `Höhenunterschied, waagerechte Strecke und Rampe bilden ein rechtwinkliges Dreieck. Die Rampe ist die Hypotenuse, die Höhe liegt dem 6°-Winkel gegenüber.\nsin 6° = 0,8 m : Rampe, also Rampe = 0,8 m : sin 6° ≈ 0,8 m : ${z('S(6)')} ≈ {A} m.`,
  ke: [['multipliziert_statt_dividiert', '0.8*S(6)', '0,8 · sin 6° statt 0,8 : sin 6° gerechnet.', 'Kann die Rampe kürzer sein als der Höhenunterschied?'],
    ['tangens_verwechselt', '0.8/T(6)', 'Mit tan 6° gerechnet: Das ist die waagerechte Strecke, nicht die Rampe.', 'Ist die Rampe eine Kathete oder die Hypotenuse?'],
    ['bogenmass_modus', '0.8/SR(6)', 'Der Taschenrechner stand auf Bogenmaß: sin(6) ist negativ.', 'Kann eine Länge negativ sein?']] });
def({ ...SE, ref: 'trigo-seite-06', titel: 'Flächeninhalt · α = 38°, c = 12 cm', einheit: 'cm²', afb: 'III', sach: false,
  afbGrund: 'Problemlösen: beide Katheten über Sinus und Kosinus bestimmen und den Flächeninhalt bilden.',
  frage: `${DR}\n\nGegeben sind α = 38° und c = 12 cm.\n\nBerechne den Flächeninhalt des Dreiecks. Rechne ohne gerundete Zwischenergebnisse. ${R2}`,
  r: '1/2*12*S(38)*12*C(38)', n: 2,
  weg: `a = c · sin α = 12 cm · sin 38° ≈ ${z('12*S(38)')} cm.\nb = c · cos α = 12 cm · cos 38° ≈ ${z('12*C(38)')} cm.\nDie Katheten stehen senkrecht aufeinander: A = ½ · a · b ≈ {A} cm².`,
  ke: [['halbieren_vergessen', '12*S(38)*12*C(38)', 'a · b ohne den Faktor ½ gerechnet.', 'Welcher Anteil des Rechtecks aus a und b ist das Dreieck?'],
    ['zu_frueh_gerundet', '1/2*12*0.62*12*0.79', 'sin 38° ≈ 0,62 und cos 38° ≈ 0,79 gerundet und damit weitergerechnet.', 'Wie stark ändert sich das Ergebnis, wenn du die Werte vorher rundest?'],
    ['bogenmass_modus', '1/2*12*SR(38)*12*CR(38)', 'Der Taschenrechner stand auf Bogenmaß.', 'Hast du DEG oder RAD in der Anzeige?']] });

// ─── geo_trigo_winkel (Tiefe 8) ───
const WI = { skill: 'geo_trigo_winkel' };
def({ ...WI, ref: 'trigo-winkel-01', titel: 'Winkel über den Sinus · a = 3 cm, c = 5 cm', einheit: '°', afb: 'I', sach: false,
  afbGrund: 'Reproduzieren: sin α aus zwei Seiten, dann α mit sin⁻¹.',
  frage: `${DR}\n\nGegeben sind a = 3 cm und c = 5 cm.\n\nBerechne den Winkel α. ${WG} ${R1}`,
  r: 'AS(3/5)', n: 1,
  weg: 'sin α = a : c = 3 : 5 = 0,6.\nα = sin⁻¹(0,6) ≈ {A}°.',
  ke: [['umkehrfunktion_vergessen', '3/5', 'Den Sinuswert 0,6 als Winkel angegeben.', 'Ist dein Ergebnis ein Winkel oder ein Seitenverhältnis?', 'exakt'],
    ['sin_cos_vertauscht', 'AC(3/5)', 'cos⁻¹ statt sin⁻¹ genommen: Das ist der Winkel β.', 'Liegt a dem Winkel α gegenüber oder an ihm an?'],
    ['tangens_verwechselt', 'AT(3/5)', 'tan⁻¹ genommen, obwohl die Hypotenuse gegeben ist.', 'Welches Verhältnis enthält die Hypotenuse?'],
    ['bogenmass_modus', 'AS(3/5)*P/180', 'Der Taschenrechner stand auf Bogenmaß: Der Winkel kommt im Bogenmaß heraus.', 'Passt ein Winkel unter 1° zu einem Dreieck mit den Seiten 3 cm und 5 cm?', 2]] });
def({ ...WI, ref: 'trigo-winkel-02', titel: 'Winkel über den Tangens · a = 4 cm, b = 9 cm', einheit: '°', afb: 'I', sach: false,
  afbGrund: 'Reproduzieren: tan α aus zwei Katheten, dann α mit tan⁻¹.',
  frage: `${DR}\n\nGegeben sind a = 4 cm und b = 9 cm.\n\nBerechne den Winkel α. ${WG} ${R1}`,
  r: 'AT(4/9)', n: 1,
  weg: `tan α = a : b = 4 : 9 ≈ ${z('4/9')}.\nα = tan⁻¹(4 : 9) ≈ {A}°.`,
  ke: [['umkehrfunktion_vergessen', '4/9', 'Den Tangenswert 4 : 9 als Winkel angegeben.', 'Ist dein Ergebnis ein Winkel oder ein Seitenverhältnis?'],
    ['sin_cos_vertauscht', 'AT(9/4)', 'Gegen- und Ankathete vertauscht: tan⁻¹(9 : 4) ist der Winkel β.', 'Welche Kathete liegt dem Winkel α gegenüber?'],
    ['tangens_verwechselt', 'AS(4/9)', 'sin⁻¹ genommen, als wäre b die Hypotenuse.', 'Ist b eine Kathete oder die Hypotenuse?']] });
def({ ...WI, ref: 'trigo-winkel-03', titel: 'Winkel über den Kosinus · b = 6,5 cm, c = 9 cm', einheit: '°', afb: 'II', sach: false,
  afbGrund: 'Anwenden: Ankathete erkennen, Kosinus wählen, Dezimalzahlen.',
  frage: `${DR}\n\nGegeben sind b = 6,5 cm und c = 9 cm.\n\nBerechne den Winkel α. ${WG} ${R1}`,
  r: 'AC(6.5/9)', n: 1,
  weg: `b liegt am Winkel α an: cos α = b : c = 6,5 : 9 ≈ ${z('6.5/9')}.\nα = cos⁻¹(6,5 : 9) ≈ {A}°.`,
  ke: [['sin_cos_vertauscht', 'AS(6.5/9)', 'sin⁻¹ statt cos⁻¹ genommen: Das ist der Winkel β.', 'Liegt b dem Winkel α gegenüber oder an ihm an?'],
    ['tangens_verwechselt', 'AT(6.5/9)', 'tan⁻¹ genommen, als wäre c eine Kathete.', 'Ist c eine Kathete oder die Hypotenuse?'],
    ['umkehrfunktion_vergessen', '6.5/9', 'Den Kosinuswert als Winkel angegeben.', 'Ist dein Ergebnis ein Winkel oder ein Seitenverhältnis?'],
    ['bogenmass_modus', 'AC(6.5/9)*P/180', 'Der Taschenrechner stand auf Bogenmaß: Der Winkel kommt im Bogenmaß heraus.', 'Passt ein Winkel unter 1° zu diesem Dreieck?']] });
def({ ...WI, ref: 'trigo-winkel-04', titel: 'Beide spitzen Winkel · a = 5 cm, c = 8 cm', afb: 'II', sach: false,
  afbGrund: 'Anwenden: α mit sin⁻¹, dann β über die Winkelsumme als 90° − α.',
  frage: `${DRB}\n\nGegeben sind a = 5 cm und c = 8 cm.\n\nBerechne die Winkel α und β. Gib die Winkel im Gradmaß an. ${R1}`,
  teile: [{ prompt: 'Winkel α in Grad', r: 'AS(5/8)', n: 1, einheit: '°',
    afbGrund: 'Anwenden: sin α aus zwei Seiten, dann sin⁻¹.',
    ke: [['umkehrfunktion_vergessen', '5/8', 'Den Sinuswert 0,625 als Winkel angegeben.', 'Ist dein Ergebnis ein Winkel oder ein Seitenverhältnis?', 'exakt'],
      ['sin_cos_vertauscht', 'AC(5/8)', 'cos⁻¹ statt sin⁻¹ genommen: Das ist der Winkel β.', 'Liegt a dem Winkel α gegenüber oder an ihm an?']] },
  { prompt: 'Winkel β in Grad', r: '90-AS(5/8)', n: 1, einheit: '°',
    afbGrund: 'Anwenden: zweiter spitzer Winkel über 90° − α.',
    ke: [['bogenmass_modus', '90-AS(5/8)*P/180', 'α im Bogenmaß berechnet und von 90 abgezogen.', 'Passt ein Winkel von fast 90° zu den Seiten 5 cm und 8 cm?']] }],
  weg: `sin α = a : c = 5 : 8 = 0,625.\nα = sin⁻¹(0,625) ≈ {1}°.\nWinkelsumme: α + β = 180° − 90° = 90°, also β = 90° − α ≈ {2}°.` });
def({ ...WI, ref: 'trigo-winkel-05', titel: 'Dachneigung · Sparren 5,2 m, Höhe 2,4 m', einheit: '°', afb: 'II', sach: true,
  afbGrund: 'Anwenden im Sachkontext: Sparren als Hypotenuse und Dachhöhe als Gegenkathete erkennen.',
  frage: `Ein Dachsparren ist 5,2 m lang. Er reicht von der waagerechten Decke bis zum First, der 2,4 m senkrecht über der Decke liegt.\n\nUnter welchem Winkel ist der Sparren gegen die Waagerechte geneigt? ${WG} ${R1}`,
  r: 'AS(2.4/5.2)', n: 1,
  weg: `Sparren, Höhe und waagerechte Strecke bilden ein rechtwinkliges Dreieck; der Sparren ist die Hypotenuse, die Höhe liegt dem Neigungswinkel gegenüber.\nsin α = 2,4 : 5,2 ≈ ${z('2.4/5.2')}.\nα = sin⁻¹(2,4 : 5,2) ≈ {A}°.`,
  ke: [['sin_cos_vertauscht', 'AC(2.4/5.2)', 'cos⁻¹ genommen: Das ist der Winkel am First.', 'Liegt die Höhe dem gesuchten Winkel gegenüber oder an ihm an?'],
    ['tangens_verwechselt', 'AT(2.4/5.2)', 'tan⁻¹ genommen, als wäre der Sparren die waagerechte Kathete.', 'Ist der Sparren eine Kathete oder die Hypotenuse?'],
    ['umkehrfunktion_vergessen', '2.4/5.2', 'Den Sinuswert als Winkel angegeben.', 'Ist dein Ergebnis ein Winkel oder ein Seitenverhältnis?']] });
def({ ...WI, ref: 'trigo-winkel-06', titel: 'Winkel aus Flächeninhalt · a = 6 cm, A = 27 cm²', einheit: '°', afb: 'III', sach: false,
  afbGrund: 'Problemlösen: Rückrichtung über den Flächeninhalt zur zweiten Kathete, dann Winkel mit tan⁻¹.',
  frage: `${DR}\n\nDie Seite a ist 6 cm lang, der Flächeninhalt des Dreiecks beträgt 27 cm².\n\nBerechne den Winkel α. ${WG} ${R1}`,
  r: 'AT(6/(2*27/6))', n: 1,
  weg: `Die Katheten stehen senkrecht aufeinander: A = ½ · a · b, also b = 2 · 27 cm² : 6 cm = ${z('2*27/6', 'exakt')} cm.\ntan α = a : b = 6 : 9.\nα = tan⁻¹(6 : 9) ≈ {A}°.`,
  ke: [['halbieren_vergessen', 'AT(6/(27/6))', 'Den Faktor ½ im Flächeninhalt vergessen: b = 27 : 6 = 4,5 cm.', 'Welcher Anteil des Rechtecks aus a und b ist das Dreieck?'],
    ['tangens_verwechselt', 'AS(6/(2*27/6))', 'sin⁻¹(6 : 9) genommen, als wäre b die Hypotenuse.', 'Ist b eine Kathete oder die Hypotenuse?'],
    ['umkehrfunktion_vergessen', '6/(2*27/6)', 'Den Tangenswert 6 : 9 als Winkel angegeben.', 'Ist dein Ergebnis ein Winkel oder ein Seitenverhältnis?']] });

// ─── geo_trigo_anwendung (Tiefe 9) ───
const AN = { skill: 'geo_trigo_anwendung', sach: true };
def({ ...AN, ref: 'trigo-anwendung-01', titel: 'Steigungswinkel · Straße mit 12 % Steigung', einheit: '°', afb: 'I',
  afbGrund: 'Reproduzieren: Steigung in Prozent als tan α lesen, Winkel mit tan⁻¹.',
  frage: `Ein Verkehrsschild zeigt für eine Straße 12 % Steigung. Das heißt: Auf 100 m waagerechter Strecke steigt die Straße um 12 m.\n\nUnter welchem Winkel steigt die Straße gegen die Waagerechte an? ${WG} ${R1}`,
  r: 'AT(12/100)', n: 1,
  weg: 'Steigung = Höhenunterschied : waagerechte Strecke = tan α.\ntan α = 12 : 100 = 0,12.\nα = tan⁻¹(0,12) ≈ {A}°.',
  ke: [['umkehrfunktion_vergessen', '12/100', 'Den Tangenswert 0,12 als Winkel angegeben.', 'Ist dein Ergebnis ein Winkel oder ein Seitenverhältnis?', 'exakt'],
    ['tangens_verwechselt', 'AS(12/100)', 'sin⁻¹ genommen, als wären die 100 m die Länge der Straße selbst.', 'Sind die 100 m waagerecht oder entlang der Straße gemessen?']] });
def({ ...AN, ref: 'trigo-anwendung-02', titel: 'Turmhöhe · 40 m Entfernung, Höhenwinkel 38°', einheit: 'm', afb: 'I',
  afbGrund: 'Reproduzieren: Höhe = Entfernung · tan(Höhenwinkel), Standardsituation.',
  frage: `Ein Punkt am Boden ist 40 m waagerecht vom Fuß eines senkrechten Turms entfernt. Von diesem Punkt aus sieht man die Turmspitze unter einem Winkel von 38° gegen die Waagerechte. ${GRAD}\n\nWie hoch ist der Turm? ${R1}`,
  r: '40*T(38)', n: 1,
  weg: `Boden, Turm und Sichtlinie bilden ein rechtwinkliges Dreieck mit dem rechten Winkel am Fuß des Turms.\nDer Turm liegt dem 38°-Winkel gegenüber, die 40 m liegen an ihm an: tan 38° = h : 40 m.\nh = 40 m · tan 38° ≈ 40 m · ${z('T(38)')} ≈ {A} m.`,
  ke: [['tangens_verwechselt', '40*S(38)', 'Mit sin 38° gerechnet, als wäre die Entfernung die Sichtlinie.', 'Sind die 40 m eine Kathete oder die Hypotenuse?'],
    ['sin_cos_vertauscht', '40/T(38)', 'Gegen- und Ankathete vertauscht: h = 40 m : tan 38°.', 'Welche Seite liegt dem 38°-Winkel gegenüber?'],
    ['bogenmass_modus', '40*TR(38)', 'Der Taschenrechner stand auf Bogenmaß.', 'Hast du DEG oder RAD in der Anzeige?']] });
def({ ...AN, ref: 'trigo-anwendung-03', titel: 'Steigung in Prozent · Steigungswinkel 8°', einheit: '%', afb: 'II',
  afbGrund: 'Anwenden: Rückrichtung vom Winkel zur Steigung, tan α in Prozent umrechnen.',
  frage: `Ein Weg steigt gleichmäßig unter einem Winkel von 8° gegen die Waagerechte an. ${GRAD}\n\nWie viel Prozent Steigung hat der Weg? Die Steigung in Prozent gibt an, um wie viele Meter der Weg auf 100 m waagerechter Strecke ansteigt. ${R1}`,
  r: 'T(8)*100', n: 1,
  weg: `Steigung = Höhenunterschied : waagerechte Strecke = tan 8° ≈ ${z('T(8)')}.\nAuf 100 m waagerecht: ${z('T(8)')} · 100 ≈ {A} m, also {A} %.`,
  ke: [['tangens_verwechselt', 'S(8)*100', 'Mit sin 8° gerechnet, als wären die 100 m entlang des Weges gemessen.', 'Ist die waagerechte Strecke eine Kathete oder die Hypotenuse?'],
    ['bogenmass_modus', 'TR(8)*100', 'Der Taschenrechner stand auf Bogenmaß: tan(8) ist negativ.', 'Kann ein ansteigender Weg eine negative Steigung haben?']] });
def({ ...AN, ref: 'trigo-anwendung-04', titel: 'Entfernung vom Leuchtturm · 25 m hoch, Sichtwinkel 9°', einheit: 'm', afb: 'II',
  afbGrund: 'Anwenden: Wechselwinkel erkennen, gesuchte Strecke im Nenner (Entfernung = Höhe : tan).',
  frage: `Ein Beobachter steht oben auf einem 25 m hohen Leuchtturm. Die Sichtlinie von dort zu einem Boot auf dem Wasser bildet mit der Waagerechten einen Winkel von 9°. ${GRAD}\n\nWie weit ist das Boot waagerecht vom Fuß des Leuchtturms entfernt? Runde auf ganze Meter.`,
  r: '25/T(9)', n: 0,
  weg: `Die Sichtlinie bildet auch mit der Wasserfläche beim Boot einen Winkel von 9° (Wechselwinkel).\nDort liegt der Turm (25 m) gegenüber, die gesuchte Entfernung e an: tan 9° = 25 m : e.\ne = 25 m : tan 9° ≈ 25 m : ${z('T(9)')} ≈ {A} m.`,
  ke: [['multipliziert_statt_dividiert', '25*T(9)', '25 · tan 9° statt 25 : tan 9° gerechnet.', 'Kann das Boot näher sein als der Turm hoch ist, wenn man so flach hinabschaut?'],
    ['tangens_verwechselt', '25/S(9)', 'Mit sin 9° gerechnet: Das ist die Länge der Sichtlinie, nicht die waagerechte Entfernung.', 'Ist die gesuchte Entfernung eine Kathete oder die Hypotenuse?'],
    ['bogenmass_modus', '25/TR(9)', 'Der Taschenrechner stand auf Bogenmaß: tan(9) ist negativ.', 'Kann eine Entfernung negativ sein?']] });
def({ ...AN, ref: 'trigo-anwendung-05', titel: 'Leiter · 6 m lang, 70° zum Boden', einheit: 'm', afb: 'II',
  afbGrund: 'Anwenden im Sachkontext: Leiter als Hypotenuse, Höhe an der Wand als Gegenkathete.',
  frage: `Eine 6 m lange Leiter lehnt an einer senkrechten Hauswand. Sie bildet mit dem waagerechten Boden einen Winkel von 70°. ${GRAD}\n\nIn welcher Höhe berührt die Leiter die Wand? ${R2}`,
  r: '6*S(70)', n: 2,
  weg: `Leiter, Wand und Boden bilden ein rechtwinkliges Dreieck; die Leiter ist die Hypotenuse, die Höhe liegt dem 70°-Winkel gegenüber.\nh = 6 m · sin 70° ≈ 6 m · ${z('S(70)')} ≈ {A} m.`,
  ke: [['sin_cos_vertauscht', '6*C(70)', 'Mit cos 70° gerechnet: Das ist der Abstand des Fußes von der Wand.', 'Liegt die Höhe dem 70°-Winkel gegenüber oder an ihm an?'],
    ['tangens_verwechselt', '6*T(70)', 'Mit tan 70° gerechnet, als wäre die Leiter eine Kathete.', 'Kann die Höhe größer sein als die Leiter lang ist?'],
    ['bogenmass_modus', '6*SR(70)', 'Der Taschenrechner stand auf Bogenmaß.', 'Hast du DEG oder RAD in der Anzeige?']] });
def({ ...AN, ref: 'trigo-anwendung-06', titel: 'Höhengewinn · 500 m Straße mit 8 % Steigung', einheit: 'm', afb: 'III',
  afbGrund: 'Problemlösen: Steigung zuerst in einen Winkel umrechnen, dann mit der Straßenlänge als Hypotenuse die Höhe bestimmen.',
  frage: `Eine Straße hat 8 % Steigung: Auf 100 m waagerechter Strecke steigt sie um 8 m. Ein Wagen fährt 500 m entlang der Straße bergauf.\n\nWie viele Meter Höhe gewinnt er dabei? Rechne ohne gerundete Zwischenergebnisse. ${R1}`,
  r: '500*S(AT(8/100))', n: 1,
  weg: `Steigungswinkel: tan α = 8 : 100 = 0,08, also α = tan⁻¹(0,08) ≈ ${z('AT(8/100)')}°.\nDie 500 m sind die Hypotenuse (entlang der Straße), die Höhe liegt α gegenüber.\nh = 500 m · sin α ≈ 500 m · ${z('S(AT(8/100))')} ≈ {A} m.`,
  ke: [['tangens_verwechselt', '500*8/100', 'Die 500 m wie eine waagerechte Strecke behandelt: 500 · 0,08.', 'Sind die 500 m waagerecht oder entlang der Straße gemessen?'],
    ['zu_frueh_gerundet', '500*S(4.6)', 'Den Steigungswinkel auf 4,6° gerundet und damit weitergerechnet.', 'Wie stark ändert sich das Ergebnis, wenn du den Winkel vorher rundest?'],
    ['umkehrfunktion_vergessen', '500*S(8/100)', 'Den Tangenswert 0,08 als Winkel in den Sinus eingesetzt.', 'Ist dein Ergebnis ein Winkel oder ein Seitenverhältnis?']] });

// ─── geo_trigo_kosinussatz (Tiefe 9) ───
const KS = { skill: 'geo_trigo_kosinussatz' };
def({ ...KS, ref: 'trigo-kosinussatz-01', titel: 'Dritte Seite · a = 5 cm, b = 7 cm, γ = 50°', einheit: 'cm', afb: 'I', sach: false,
  afbGrund: 'Reproduzieren: Kosinussatz c² = a² + b² − 2ab · cos γ direkt anwenden.',
  frage: `${KO}\n\nGegeben sind a = 5 cm, b = 7 cm und γ = 50°.\n\nWie lang ist die Seite c? ${R2}`,
  r: 'W(5^2+7^2-2*5*7*C(50))', n: 2,
  weg: `Kosinussatz: c² = a² + b² − 2ab · cos γ.\nc² = 25 + 49 − 70 · cos 50° ≈ ${z('5^2+7^2-2*5*7*C(50)')} cm².\nc ≈ {A} cm.`,
  ke: [['kosinussatz_vorzeichen', 'W(5^2+7^2+2*5*7*C(50))', 'Den Term 2ab · cos γ addiert statt abgezogen.', 'Was bleibt vom Kosinussatz übrig, wenn γ = 90° ist?'],
    ['pythagoras_ohne_rechten_winkel', 'W(5^2+7^2)', 'Mit dem Satz des Pythagoras gerechnet: c = √74.', 'Hat das Dreieck einen rechten Winkel?'],
    ['wurzel_vergessen', '5^2+7^2-2*5*7*C(50)', 'c² ausgerechnet, aber die Wurzel nicht gezogen.', 'Hast du schon c ausgerechnet oder erst c²?']] });
def({ ...KS, ref: 'trigo-kosinussatz-02', titel: 'Dritte Seite · a = 6 cm, b = 9 cm, γ = 72°', einheit: 'cm', afb: 'I', sach: false,
  afbGrund: 'Reproduzieren: Kosinussatz mit anderen Zahlen, Taschenrechner im Gradmaß.',
  frage: `${KO}\n\nGegeben sind a = 6 cm, b = 9 cm und γ = 72°.\n\nWie lang ist die Seite c? ${R2}`,
  r: 'W(6^2+9^2-2*6*9*C(72))', n: 2,
  weg: `Kosinussatz: c² = a² + b² − 2ab · cos γ.\nc² = 36 + 81 − 108 · cos 72° ≈ ${z('6^2+9^2-2*6*9*C(72)')} cm².\nc ≈ {A} cm.`,
  ke: [['kosinussatz_vorzeichen', 'W(6^2+9^2+2*6*9*C(72))', 'Den Term 2ab · cos γ addiert statt abgezogen.', 'Muss c bei einem spitzen Winkel γ kürzer oder länger sein als beim rechten Winkel?'],
    ['pythagoras_ohne_rechten_winkel', 'W(6^2+9^2)', 'Mit dem Satz des Pythagoras gerechnet: c = √117.', 'Hat das Dreieck einen rechten Winkel?'],
    ['bogenmass_modus', 'W(6^2+9^2-2*6*9*CR(72))', 'Der Taschenrechner stand auf Bogenmaß.', 'Hast du DEG oder RAD in der Anzeige?']] });
def({ ...KS, ref: 'trigo-kosinussatz-03', titel: 'Winkel aus drei Seiten · 7 cm, 8 cm, 10 cm', einheit: '°', afb: 'II', sach: false,
  afbGrund: 'Anwenden: Kosinussatz nach cos γ umstellen, dann cos⁻¹.',
  frage: `${KO}\n\nGegeben sind a = 7 cm, b = 8 cm und c = 10 cm.\n\nBerechne den Winkel γ. ${WG} ${R1}`,
  r: 'AC((7^2+8^2-10^2)/(2*7*8))', n: 1,
  weg: `Kosinussatz nach cos γ umgestellt: cos γ = (a² + b² − c²) : (2ab).\ncos γ = (49 + 64 − 100) : 112 = 13 : 112 ≈ ${z('13/112')}.\nγ = cos⁻¹(13 : 112) ≈ {A}°.`,
  ke: [['kosinussatz_vorzeichen', 'AC((10^2-7^2-8^2)/(2*7*8))', 'Mit c² = a² + b² + 2ab · cos γ umgestellt: cos γ = −13 : 112.', 'Welches Rechenzeichen steht vor 2ab · cos γ?'],
    ['umkehrfunktion_vergessen', '(7^2+8^2-10^2)/(2*7*8)', 'Den Kosinuswert als Winkel angegeben.', 'Ist dein Ergebnis ein Winkel oder ein Seitenverhältnis?'],
    ['bogenmass_modus', 'AC((7^2+8^2-10^2)/(2*7*8))*P/180', 'Der Taschenrechner stand auf Bogenmaß: Der Winkel kommt im Bogenmaß heraus.', 'Passt ein Winkel von gut 1° zu diesem Dreieck?']] });
def({ ...KS, ref: 'trigo-kosinussatz-04', titel: 'Dritte Seite bei stumpfem Winkel · γ = 115°', einheit: 'cm', afb: 'II', sach: false,
  afbGrund: 'Anwenden: stumpfer Winkel, cos γ ist negativ; das Minus im Kosinussatz macht c länger.',
  frage: `${KO}\n\nGegeben sind a = 4 cm, b = 6,5 cm und γ = 115°.\n\nWie lang ist die Seite c? Rechne ohne gerundete Zwischenergebnisse. ${R2}`,
  r: 'W(4^2+6.5^2-2*4*6.5*C(115))', n: 2,
  weg: `Kosinussatz: c² = a² + b² − 2ab · cos γ.\ncos 115° ≈ ${z('C(115)')} ist negativ, das Minus macht daraus ein Plus.\nc² = 16 + 42,25 − 52 · cos 115° ≈ ${z('4^2+6.5^2-2*4*6.5*C(115)')} cm².\nc ≈ {A} cm.`,
  ke: [['kosinussatz_vorzeichen', 'W(4^2+6.5^2+2*4*6.5*C(115))', 'Den Term 2ab · cos γ addiert statt abgezogen.', 'Muss c gegenüber einem stumpfen Winkel länger oder kürzer sein als beim rechten Winkel?'],
    ['pythagoras_ohne_rechten_winkel', 'W(4^2+6.5^2)', 'Mit dem Satz des Pythagoras gerechnet: c = √58,25.', 'Hat das Dreieck einen rechten Winkel?'],
    ['zu_frueh_gerundet', 'W(4^2+6.5^2-2*4*6.5*(0-0.4))', 'cos 115° auf −0,4 gerundet und damit weitergerechnet.', 'Wie stark ändert sich das Ergebnis, wenn du cos 115° vorher rundest?'],
    ['wurzel_vergessen', '4^2+6.5^2-2*4*6.5*C(115)', 'c² ausgerechnet, aber die Wurzel nicht gezogen.', 'Hast du schon c ausgerechnet oder erst c²?']] });
def({ ...KS, ref: 'trigo-kosinussatz-05', titel: 'Breite eines Sees · 320 m, 450 m, 64°', einheit: 'm', afb: 'II', sach: true,
  afbGrund: 'Anwenden im Sachkontext: Messpunkt als Ecke C mit eingeschlossenem Winkel erkennen, Kosinussatz.',
  frage: `Die Punkte A und B liegen an gegenüberliegenden Ufern eines Sees. Von einem Messpunkt C an Land misst man: C ist 320 m von A und 450 m von B entfernt, der Winkel bei C zwischen den beiden Richtungen beträgt 64°. ${GRAD} Das Dreieck ABC hat keinen rechten Winkel.\n\nWie weit sind A und B voneinander entfernt? Runde auf ganze Meter.`,
  r: 'W(320^2+450^2-2*320*450*C(64))', n: 0,
  weg: `Im Dreieck ABC sind die Seiten an C bekannt: 320 m und 450 m, eingeschlossener Winkel γ = 64°.\nKosinussatz: AB² = 320² + 450² − 2 · 320 · 450 · cos 64° ≈ ${z('320^2+450^2-2*320*450*C(64)', 0)} m².\nAB ≈ {A} m.`,
  ke: [['kosinussatz_vorzeichen', 'W(320^2+450^2+2*320*450*C(64))', 'Den Term 2ab · cos γ addiert statt abgezogen.', 'Was bleibt vom Kosinussatz übrig, wenn γ = 90° ist?'],
    ['pythagoras_ohne_rechten_winkel', 'W(320^2+450^2)', 'Mit dem Satz des Pythagoras gerechnet, obwohl der Winkel bei C 64° beträgt.', 'Hat das Dreieck einen rechten Winkel?'],
    ['wurzel_vergessen', '320^2+450^2-2*320*450*C(64)', 'AB² ausgerechnet, aber die Wurzel nicht gezogen.', 'Kann der See über 100 km breit sein?']] });
def({ ...KS, ref: 'trigo-kosinussatz-06', titel: 'Größter Winkel · Seiten 5 cm, 6 cm, 9 cm', einheit: '°', afb: 'III', sach: false,
  afbGrund: 'Problemlösen: den größten Winkel der längsten Seite gegenüber erkennen, Kosinussatz umstellen, negativer Kosinuswert.',
  frage: `${KO}\n\nGegeben sind a = 5 cm, b = 6 cm und c = 9 cm.\n\nBerechne den größten Winkel des Dreiecks. ${WG} ${R1}`,
  r: 'AC((5^2+6^2-9^2)/(2*5*6))', n: 1,
  weg: `Der größte Winkel liegt der längsten Seite c gegenüber, also γ.\ncos γ = (a² + b² − c²) : (2ab) = (25 + 36 − 81) : 60 = −20 : 60 ≈ ${z('(0-20)/60')}.\nγ = cos⁻¹(−1/3) ≈ {A}°.`,
  ke: [['kosinussatz_vorzeichen', 'AC((9^2-5^2-6^2)/(2*5*6))', 'Mit c² = a² + b² + 2ab · cos γ umgestellt: cos γ = 20 : 60.', 'Welches Rechenzeichen steht vor 2ab · cos γ?'],
    ['falsche_groesse_beantwortet', 'AC((6^2+9^2-5^2)/(2*6*9))', 'Den Winkel α gegenüber der kürzesten Seite berechnet.', 'Welcher Seite liegt der größte Winkel gegenüber?'],
    ['umkehrfunktion_vergessen', '(5^2+6^2-9^2)/(2*5*6)', 'Den Kosinuswert als Winkel angegeben.', 'Ist dein Ergebnis ein Winkel oder ein Seitenverhältnis?']] });

// ── Charge ─────────────────────────────────────────────────────────────────────
baueCharge({
  thema: 'trigo',
  batch: 'k10-trigo',
  source: 'edvance_k10_trigo',
  idsPfad: 'docs/prefill/k10-trigo-ids.json',
  kopf: [
    `K10-Rest, Thema trigo — ${A.length} Aufgaben: je sechs zu geo_trigo_verhaeltnis, _seite, _winkel, _anwendung und _kosinussatz.`,
    'Erzeugt von tools/vorlauf-build.mjs aus docs/prefill/k10-trigo.json (Quelle: tools/k10-trigo-charge.mjs) — nicht von Hand editieren.',
    '',
    'Einspiel-Reihenfolge: nach 20261003121329_substrat_k10_trigo.sql (Knoten + Fehlbild-Slugs muessen stehen).',
  ],
  auswahl: 'Je Knoten vier reine Anwendung mit steigender Schwierigkeit und zwei mit Sachkontext oder Rückrichtung (ähnliche Dreiecke, Rampe, Dach, Turm, Leuchtturm, Leiter, Straße, See); geo_trigo_anwendung ist durchgehend Sachkontext. Dreiecke als Text mit fester Benennung (rechter Winkel bei C, α bei A), keine Abbildung. Jede Aufgabe nennt Rundung und Gradmaß; Werte exakt nachgerechnet (Winkelfunktionen auf 40 Stellen).',
  aufgaben: A,
});
