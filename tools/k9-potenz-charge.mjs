#!/usr/bin/env node
/**
 * k9-potenz-charge.mjs — erzeugt docs/prefill/k9-potenz.json (Charge-Format von vorlauf-build.mjs).
 *
 *   node tools/k9-potenz-charge.mjs
 *
 * Thema potenz (KLP G9 NRW, Zweite Stufe, Ari-1/Ari-3/Ari-4): Potenzgesetze, negative Hochzahlen,
 * Zehnerpotenzen, Rechnen in wissenschaftlicher Schreibweise. Jeder Wert wird ueber die Ausdruecke
 * der Bibliothek exakt gerechnet (tools/k9-rest-lib.mjs). Die wissenschaftliche Schreibweise wird
 * nie als Eingabe verlangt: gefragt ist die Hochzahl allein oder Vorfaktor und Hochzahl als zwei
 * Teile (MULTI_PART). Die ids stehen in docs/prefill/k9-potenz-ids.json.
 */

import { baueCharge, CLUSTER } from './k9-rest-lib.mjs';

const BASIS = {
  inhalt: 'arithmetik_algebra', cluster: CLUSTER.zahl, stoff: 9,
  stoffGrund: 'Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Ari-1/Ari-3/Ari-4 (Potenzen, Zehnerpotenzen).',
  clusterGrund: 'Zahl & Rechnen wie der Fundament-Knoten potenzen im Bestand.',
  inhaltGrund: 'Inhaltsfeld Arithmetik/Algebra (Ari-1, Ari-3, Ari-4).',
};
const N_GANZ = 'Gib n als ganze Zahl an.';
const EXAKT_BD = 'Gib das Ergebnis exakt als Bruch oder als Dezimalzahl an.';
const FORM = 'Gib das Ergebnis in der Form a · 10ⁿ mit 1 ≤ a < 10 an. Trage den Vorfaktor a und die Hochzahl n getrennt ein, beide exakt.';
const teile = (a, n) => [
  { prompt: 'Vorfaktor a', r: a[0], n: 'exakt', ke: a[1] },
  { prompt: 'Hochzahl n', r: n[0], n: 'exakt', ke: n[1] },
];

const A = [];
const def = (o) => A.push({ ...BASIS, n: 'exakt', ...o });

// ─── zahl_potenz_gesetze (Tiefe 5) ───
const GE = { skill: 'zahl_potenz_gesetze' };
def({ ...GE, ref: 'potenz-gesetze-01', titel: 'Potenzgesetze · 2³ · 2⁴ = 2ⁿ', afb: 'I', sach: false,
  afbGrund: 'Reproduzieren: Produkt gleicher Basen, Hochzahlen addieren.',
  frage: `2³ · 2⁴ = 2ⁿ\n\nBestimme n. ${N_GANZ}`, r: '3+4',
  weg: 'Gleiche Basis beim Malnehmen: Hochzahlen addieren.\n2³ · 2⁴ = 2³⁺⁴ = 2⁷, also n = {A}.',
  ke: [['potenzgesetz_verwechselt', '3*4', 'Die Hochzahlen multipliziert statt addiert: 3 · 4 = 12.', 'Wie viele Zweien stehen in 2³ · 2⁴, wenn du alles ausschreibst?'],
    ['falsche_groesse_beantwortet', '2^7', 'Den Wert 2⁷ = 128 angegeben statt der Hochzahl n.', 'Wird nach dem Wert der Potenz oder nach der Hochzahl n gefragt?']] });
def({ ...GE, ref: 'potenz-gesetze-02', titel: 'Potenzgesetze · (3²)⁴ = 3ⁿ', afb: 'I', sach: false,
  afbGrund: 'Reproduzieren: Potenz einer Potenz, Hochzahlen multiplizieren.',
  frage: `(3²)⁴ = 3ⁿ\n\nBestimme n. ${N_GANZ}`, r: '2*4',
  weg: 'Potenz einer Potenz: Hochzahlen multiplizieren.\n(3²)⁴ = 3² · 3² · 3² · 3² = 3²·⁴ = 3⁸, also n = {A}.',
  ke: [['potenzgesetz_verwechselt', '2+4', 'Die Hochzahlen addiert statt multipliziert: 2 + 4 = 6.', 'Wie oft steht 3² als Faktor in (3²)⁴?'],
    ['falsche_groesse_beantwortet', '3^8', 'Den Wert 3⁸ = 6561 angegeben statt der Hochzahl n.', 'Wird nach dem Wert der Potenz oder nach der Hochzahl n gefragt?']] });
def({ ...GE, ref: 'potenz-gesetze-03', titel: 'Potenzgesetze · (a⁴)³ : a⁵ = aⁿ', afb: 'II', sach: false,
  afbGrund: 'Anwenden: zwei Potenzgesetze nacheinander (Potenz einer Potenz, dann Quotient).',
  frage: `(a⁴)³ : a⁵ = aⁿ   (a ≠ 0)\n\nBestimme n. ${N_GANZ}`, r: '4*3-5',
  weg: '(a⁴)³ = a⁴·³ = a¹².\na¹² : a⁵ = a¹²⁻⁵ = a⁷, also n = {A}.',
  ke: [['potenzgesetz_verwechselt', '4+3-5', 'Bei der Potenz einer Potenz die Hochzahlen addiert: a⁷ : a⁵ = a².', 'Wie oft steht a⁴ als Faktor in (a⁴)³?'],
    ['potenzgesetz_verwechselt', '4*3+5', 'Beim Teilen die Hochzahlen addiert wie beim Malnehmen: a¹²⁺⁵.', 'Werden beim Teilen gleicher Basen die Hochzahlen addiert oder subtrahiert?']] });
def({ ...GE, ref: 'potenz-gesetze-04', titel: 'Potenzgesetze · 2⁵ · 5⁵ = 10ⁿ', afb: 'II', sach: false,
  afbGrund: 'Anwenden: gleiche Hochzahl bei verschiedenen Basen erkennen und die Basen multiplizieren.',
  frage: `2⁵ · 5⁵ = 10ⁿ\n\nBestimme n. ${N_GANZ}`, r: '5',
  weg: 'Gleiche Hochzahl: die Basen multiplizieren.\n2⁵ · 5⁵ = (2 · 5)⁵ = 10⁵, also n = {A}.',
  ke: [['potenzgesetz_verwechselt', '5+5', 'Die Hochzahlen addiert, obwohl die Basen verschieden sind: 10¹⁰.', 'Darfst du Hochzahlen addieren, wenn die Basen 2 und 5 verschieden sind?'],
    ['falsche_groesse_beantwortet', '10^5', 'Den Wert 10⁵ = 100 000 angegeben statt der Hochzahl n.', 'Wird nach dem Wert der Potenz oder nach der Hochzahl n gefragt?']] });
def({ ...GE, ref: 'potenz-gesetze-05', titel: 'Potenzgesetze · Zellkultur verdoppelt sich drei Stunden lang', afb: 'II', sach: true,
  afbGrund: 'Anwenden im Sachkontext: Verdoppeln als Multiplikation mit 2³ erkennen, dann den Wert berechnen.',
  frage: `Eine Zellkultur verdoppelt ihre Zellzahl jede Stunde. Zu Beginn sind es 2⁵ Zellen.\n\nWie viele Zellen sind es nach 3 Stunden? Gib die Anzahl exakt als ganze Zahl an.`, r: '2^5*2^3',
  weg: 'Drei Verdopplungen: mal 2 · 2 · 2 = 2³.\n2⁵ · 2³ = 2⁸ = {A} Zellen.',
  ke: [['potenzgesetz_verwechselt', '2^15', 'Die Hochzahlen multipliziert: 2¹⁵ = 32 768.', 'Wie viele Zweien stehen in 2⁵ · 2³, wenn du alles ausschreibst?'],
    ['mal_exponent', '2*8', 'Die Potenz 2⁸ als 2 · 8 = 16 gerechnet.', 'Was bedeutet die Hochzahl 8 bei 2⁸?'],
    ['falsche_groesse_beantwortet', '8', 'Nur die Hochzahl 8 angegeben statt der Zellzahl.', 'Gefragt ist die Anzahl der Zellen – ist das 8?']] });
def({ ...GE, ref: 'potenz-gesetze-06', titel: 'Potenzgesetze · großer Würfel in kleine Würfel zerlegt', afb: 'III', sach: true,
  afbGrund: 'Problemlösen: Anzahl als Quotient zweier Würfelvolumen modellieren und mit Potenzgesetzen als Zweierpotenz schreiben.',
  frage: `Ein großer Würfel hat die Kantenlänge 16 cm. Er wird vollständig in kleine Würfel mit der Kantenlänge 2 cm zerlegt.\n\nDie Anzahl der kleinen Würfel lässt sich als 2ⁿ schreiben. Bestimme n. ${N_GANZ}`, r: '4*3-3',
  weg: 'Volumen groß: 16³ cm³ = (2⁴)³ cm³ = 2¹² cm³.\nVolumen klein: 2³ cm³.\nAnzahl: 2¹² : 2³ = 2⁹ = 512, also n = {A}.',
  ke: [['linearer_faktor', '3', 'Nur die Würfel entlang einer Kante gezählt: 16 : 2 = 8 = 2³.', 'Wie viele kleine Würfel passen in eine Ebene, wie viele Ebenen gibt es?'],
    ['potenzgesetz_verwechselt', '12/3', 'Die Hochzahlen geteilt statt subtrahiert: 2¹² : 2³ als 2⁴.', 'Werden beim Teilen gleicher Basen die Hochzahlen geteilt oder subtrahiert?'],
    ['falsche_groesse_beantwortet', '2^9', 'Die Anzahl 512 angegeben statt der Hochzahl n.', 'Wird nach der Anzahl oder nach der Hochzahl n gefragt?']] });

// ─── zahl_potenz_negativ (Tiefe 6) ───
const NE = { skill: 'zahl_potenz_negativ', bruch: true };
def({ ...NE, ref: 'potenz-negativ-01', titel: 'Negative Hochzahl · 2⁻³', afb: 'I', sach: false,
  afbGrund: 'Reproduzieren: negative Hochzahl als Kehrwert der Potenz.',
  frage: `Berechne 2⁻³. ${EXAKT_BD}`, r: '1/2^3',
  weg: '2⁻³ = 1/2³ = 1/8 = {A}.',
  ke: [['negativer_exponent_negativ', '0-2^3', 'Die negative Hochzahl als Minuszeichen gelesen: −2³ = −8.', 'Ist 2⁻³ ein Kehrwert oder eine negative Zahl?'],
    ['mal_exponent', '2*(0-3)', 'Die Potenz als 2 · (−3) = −6 gerechnet.', 'Was bedeutet die Hochzahl bei einer Potenz – malnehmen mit 3 oder 3-mal malnehmen?']] });
def({ ...NE, ref: 'potenz-negativ-02', titel: 'Negative Hochzahl · 10⁻²', afb: 'I', sach: false,
  afbGrund: 'Reproduzieren: Zehnerpotenz mit negativer Hochzahl als Dezimalzahl.',
  frage: `Berechne 10⁻². ${EXAKT_BD}`, r: '1/10^2',
  weg: '10⁻² = 1/10² = 1/100 = {A}.',
  ke: [['negativer_exponent_negativ', '0-10^2', 'Die negative Hochzahl als Minuszeichen gelesen: −10² = −100.', 'Ist 10⁻² kleiner als null oder kleiner als eins?'],
    ['mal_exponent', '10*(0-2)', 'Die Potenz als 10 · (−2) = −20 gerechnet.', 'Was bedeutet die Hochzahl bei einer Potenz?'],
    ['faktor_zehn_daneben', '1/10', 'Das Komma nur um eine Stelle verschoben: 0,1.', 'Durch welche Zahl teilst du bei 1/10²?']] });
def({ ...NE, ref: 'potenz-negativ-03', titel: 'Negative Hochzahl · 4⁻¹ · 4³', afb: 'II', sach: false,
  afbGrund: 'Anwenden: Produktgesetz mit einer negativen Hochzahl.',
  frage: `Berechne 4⁻¹ · 4³. ${EXAKT_BD}`, r: '4^2',
  weg: 'Gleiche Basis: Hochzahlen addieren.\n4⁻¹ · 4³ = 4⁻¹⁺³ = 4² = {A}.',
  ke: [['negativer_exponent_negativ', '0-4*4^3', '4⁻¹ als −4 gelesen: (−4) · 64 = −256.', 'Ist 4⁻¹ gleich −4 oder gleich 1/4?'],
    ['potenzgesetz_verwechselt', '1/4^3', 'Die Hochzahlen multipliziert: 4⁻³ = 1/64.', 'Werden beim Malnehmen gleicher Basen die Hochzahlen multipliziert oder addiert?']] });
def({ ...NE, ref: 'potenz-negativ-04', titel: 'Negative Hochzahl · (1/2)⁻² + 5⁰', afb: 'II', sach: false,
  afbGrund: 'Anwenden: Bruch mit negativer Hochzahl und Hochzahl null in einem Term.',
  frage: `Berechne (1/2)⁻² + 5⁰. ${EXAKT_BD}`, r: '2^2+1',
  weg: '(1/2)⁻² = 2² = 4 (Kehrwert, dann quadrieren).\n5⁰ = 1.\n4 + 1 = {A}.',
  ke: [['negativer_exponent_negativ', '0-1/4+1', '(1/2)⁻² als −(1/2)² = −1/4 gelesen: −1/4 + 1 = 3/4.', 'Wird bei einer negativen Hochzahl das Ergebnis negativ oder der Kehrwert gebildet?'],
    ['mal_exponent', '4+0', '5⁰ als 5 · 0 = 0 gerechnet: 4 + 0 = 4.', 'Welchen Wert hat jede Zahl (außer 0) hoch null?'],
    ['mal_exponent', '0-1+0', 'Beide Potenzen als Produkte gerechnet: (1/2) · (−2) + 5 · 0 = −1.', 'Was bedeutet die Hochzahl bei einer Potenz?']] });
def({ ...NE, ref: 'potenz-negativ-05', titel: 'Negative Hochzahl · Halbierung alle 4 Stunden', afb: 'II', sach: true,
  afbGrund: 'Anwenden im Sachkontext: Anzahl der Halbierungen bestimmen, dann 2⁻ⁿ berechnen.',
  frage: `Die Menge eines Stoffes halbiert sich alle 4 Stunden. Nach n Halbierungen ist noch der Anteil 2⁻ⁿ der Anfangsmenge vorhanden.\n\nWelcher Anteil der Anfangsmenge ist nach 20 Stunden noch vorhanden? ${EXAKT_BD}`, r: '1/2^5',
  weg: '20 Stunden : 4 Stunden = 5 Halbierungen.\n2⁻⁵ = 1/2⁵ = 1/32 = {A}.',
  ke: [['negativer_exponent_negativ', '0-2^5', 'Die negative Hochzahl als Minuszeichen gelesen: −2⁵ = −32.', 'Kann ein Anteil, der noch vorhanden ist, negativ sein?'],
    ['mal_exponent', '1/(2*5)', '2⁵ als 2 · 5 = 10 gerechnet: 1/10.', 'Wie oft wird bei 2⁵ mit 2 malgenommen?']] });
def({ ...NE, ref: 'potenz-negativ-06', titel: 'Negative Hochzahl · Faktor zwischen 2³ und 2⁻²', afb: 'III', sach: false,
  afbGrund: 'Problemlösen: den Faktor als Quotient erkennen und mit negativer Hochzahl rechnen.',
  frage: `Um welchen Faktor ist 2³ größer als 2⁻²?\n\nGib den Faktor exakt als ganze Zahl an.`, r: '2^3*2^2',
  weg: 'Faktor = 2³ : 2⁻² = 2³⁻⁽⁻²⁾ = 2⁵ = {A}.\nProbe: 2⁻² = 1/4, und 1/4 · 32 = 8 = 2³.',
  ke: [['potenzgesetz_verwechselt', '2^1', 'Die Hochzahlen addiert statt subtrahiert: 2³⁺⁽⁻²⁾ = 2.', 'Werden beim Teilen gleicher Basen die Hochzahlen addiert oder subtrahiert?'],
    ['negativer_exponent_negativ', '2^3/(0-4)', '2⁻² als −4 gelesen: 8 : (−4) = −2.', 'Ist 2⁻² eine negative Zahl oder ein Bruch?'],
    ['falsche_groesse_beantwortet', '2^3-1/2^2', 'Den Unterschied 8 − 1/4 berechnet statt des Faktors.', 'Fragt „um welchen Faktor" nach einer Differenz oder nach einem Quotienten?']] });

// ─── zahl_potenz_zehner (Tiefe 7) ───
const ZE = { skill: 'zahl_potenz_zehner' };
def({ ...ZE, ref: 'potenz-zehner-01', titel: 'Zehnerpotenz · 3 200 000 = 3,2 · 10ⁿ', afb: 'I', sach: false,
  afbGrund: 'Reproduzieren: große Zahl in wissenschaftlicher Schreibweise, Kommaverschiebung zählen.',
  frage: `3 200 000 = 3,2 · 10ⁿ\n\nBestimme n. ${N_GANZ}`, r: '6',
  weg: 'Das Komma wandert von 3 200 000,0 sechs Stellen nach links bis 3,2.\nAlso 3 200 000 = 3,2 · 10⁶, n = {A}.',
  ke: [['zehnerexponent_vorzeichen', '0-6', 'Bei einer großen Zahl eine negative Hochzahl angegeben.', 'Ist 3 200 000 größer oder kleiner als 1 – welches Vorzeichen braucht n dann?'],
    ['faktor_zehn_daneben', '7', 'Alle sieben Ziffern gezählt statt der Stellen, um die das Komma wandert.', 'Um wie viele Stellen wandert das Komma von 3 200 000 bis 3,2?'],
    ['faktor_zehn_daneben', '5', 'Eine Stelle zu wenig gezählt: 3,2 · 10⁵ = 320 000.', 'Wie groß ist 3,2 · 10⁵ – stimmt das mit 3 200 000 überein?']] });
def({ ...ZE, ref: 'potenz-zehner-02', titel: 'Zehnerpotenz · 0,00045 = 4,5 · 10ⁿ', afb: 'I', sach: false,
  afbGrund: 'Reproduzieren: kleine Zahl in wissenschaftlicher Schreibweise, negative Hochzahl.',
  frage: `0,00045 = 4,5 · 10ⁿ\n\nBestimme n. ${N_GANZ}`, r: '0-4',
  weg: 'Das Komma wandert von 0,00045 vier Stellen nach rechts bis 4,5.\nDie Zahl ist kleiner als 1, die Hochzahl also negativ: 0,00045 = 4,5 · 10⁻⁴, n = {A}.',
  ke: [['zehnerexponent_vorzeichen', '4', 'Bei einer Zahl kleiner als 1 eine positive Hochzahl angegeben.', 'Ist 4,5 · 10⁴ eine große oder eine kleine Zahl?'],
    ['faktor_zehn_daneben', '0-5', 'Eine Stelle zu viel gezählt: 4,5 · 10⁻⁵ = 0,000045.', 'Wie viele Nullen stehen nach dem Komma vor der 4?'],
    ['faktor_zehn_daneben', '0-3', 'Nur die Nullen nach dem Komma gezählt: 4,5 · 10⁻³ = 0,0045.', 'Um wie viele Stellen wandert das Komma, bis es hinter der 4 steht?']] });
def({ ...ZE, ref: 'potenz-zehner-03', titel: 'Zehnerpotenz · 7,2 · 10⁻³ als Dezimalzahl', afb: 'II', sach: false,
  afbGrund: 'Anwenden: Rückrichtung, aus der wissenschaftlichen Schreibweise die Dezimalzahl bilden.',
  frage: 'Schreibe 7,2 · 10⁻³ als Dezimalzahl. Gib die Zahl exakt an.', r: '7.2/10^3',
  weg: '10⁻³ = 0,001: das Komma wandert drei Stellen nach links.\n7,2 · 10⁻³ = {A}.',
  ke: [['zehnerexponent_vorzeichen', '7.2*10^3', 'Das Komma nach rechts verschoben: 7 200.', 'Macht eine negative Hochzahl die Zahl größer oder kleiner?'],
    ['faktor_zehn_daneben', '7.2/10^2', 'Das Komma nur zwei Stellen verschoben: 0,072.', 'Wie viele Stellen muss das Komma bei 10⁻³ wandern?'],
    ['faktor_zehn_daneben', '7.2/10^4', 'Das Komma vier Stellen verschoben: 0,00072.', 'Wie viele Nullen hat 0,001 nach dem Komma, bevor die 1 kommt?'],
    ['negativer_exponent_negativ', '0-7.2*10^3', '10⁻³ als −1 000 gelesen: −7 200.', 'Ist 10⁻³ eine negative Zahl oder ein Tausendstel?']] });
def({ ...ZE, ref: 'potenz-zehner-04', titel: 'Zehnerpotenz · 4,05 · 10⁵ als Zahl', afb: 'II', sach: false,
  afbGrund: 'Anwenden: Rückrichtung mit Null im Vorfaktor, Stellen auffüllen.',
  frage: 'Schreibe 4,05 · 10⁵ als Zahl ohne Zehnerpotenz. Gib die Zahl exakt an.', r: '4.05*10^5',
  weg: 'Das Komma wandert fünf Stellen nach rechts; fehlende Stellen werden mit Nullen gefüllt.\n4,05 · 10⁵ = 405 000, eingegeben als {A}.',
  ke: [['zehnerexponent_vorzeichen', '4.05/10^5', 'Das Komma nach links verschoben: 0,0000405.', 'Macht eine positive Hochzahl die Zahl größer oder kleiner?'],
    ['faktor_zehn_daneben', '4.05*10^4', 'Fünf Ziffern insgesamt geschrieben statt das Komma fünf Stellen zu verschieben: 40 500.', 'Um wie viele Stellen wandert das Komma, und wo steht es danach?'],
    ['faktor_zehn_daneben', '4.05*10^6', 'Das Komma sechs statt fünf Stellen verschoben: 4 050 000.', 'Wie viele Nullen hat 10⁵, und um wie viele Stellen wandert das Komma?'],
    ['mal_exponent', '4.05*10*5', '10⁵ als 10 · 5 = 50 gerechnet: 202,5.', 'Was bedeutet die Hochzahl 5 bei 10⁵?']] });
def({ ...ZE, ref: 'potenz-zehner-05', titel: 'Zehnerpotenz · Durchmesser eines roten Blutkörperchens', afb: 'II', sach: true,
  afbGrund: 'Anwenden im Sachkontext: sehr kleine Länge in wissenschaftlicher Schreibweise angeben.',
  frage: `Ein rotes Blutkörperchen hat einen Durchmesser von etwa 0,0000075 m.\n\nIn wissenschaftlicher Schreibweise ist das 7,5 · 10ⁿ m. Bestimme n. ${N_GANZ}`, r: '0-6',
  weg: 'Das Komma wandert von 0,0000075 sechs Stellen nach rechts bis 7,5.\nDie Zahl ist kleiner als 1: 0,0000075 m = 7,5 · 10⁻⁶ m, n = {A}.',
  ke: [['zehnerexponent_vorzeichen', '6', 'Bei einer winzigen Länge eine positive Hochzahl angegeben.', 'Wäre 7,5 · 10⁶ m eine winzige oder eine riesige Länge?'],
    ['faktor_zehn_daneben', '0-7', 'Eine Stelle zu viel gezählt: 7,5 · 10⁻⁷ m.', 'Um wie viele Stellen wandert das Komma, bis es hinter der 7 steht?'],
    ['faktor_zehn_daneben', '0-5', 'Nur die Nullen nach dem Komma gezählt: 7,5 · 10⁻⁵ m.', 'Muss das Komma bis hinter die 7 oder nur bis vor die 7 wandern?']] });
def({ ...ZE, ref: 'potenz-zehner-06', titel: 'Zehnerpotenz · Viren auf der Länge eines Sandkorns', afb: 'III', sach: true,
  afbGrund: 'Problemlösen: Anzahl als Quotient zweier Längen in Zehnerpotenzen bilden und als Zahl angeben.',
  frage: `Ein Virus ist etwa 1 · 10⁻⁷ m lang, ein Sandkorn etwa 1 · 10⁻³ m.\n\nWie viele solcher Viren passen nebeneinander auf die Länge des Sandkorns? Gib die Anzahl exakt als ganze Zahl an.`, r: '10^7/10^3',
  weg: 'Anzahl = 10⁻³ m : 10⁻⁷ m = 10⁻³⁻⁽⁻⁷⁾ = 10⁴ = {A}.',
  ke: [['zehnerexponent_vorzeichen', '1/10^4', 'Den Quotienten umgedreht: 10⁻⁷ : 10⁻³ = 10⁻⁴ = 0,0001.', 'Kann eine Anzahl von Viren kleiner als 1 sein?'],
    ['faktor_zehn_daneben', '10^3', 'Eine Zehnerpotenz zu wenig: 1 000.', 'Wie viele Zehnerpotenzen liegen zwischen 10⁻⁷ und 10⁻³?'],
    ['faktor_zehn_daneben', '10^5', 'Eine Zehnerpotenz zu viel: 100 000.', 'Wie viele Zehnerpotenzen liegen zwischen 10⁻⁷ und 10⁻³?']] });

// ─── zahl_potenz_rechnen (Tiefe 8) ───
const RE = { skill: 'zahl_potenz_rechnen' };
def({ ...RE, ref: 'potenz-rechnen-01', titel: 'Wissenschaftliche Schreibweise · (3 · 10⁴) · (2 · 10⁻⁶)', afb: 'I', sach: false,
  afbGrund: 'Reproduzieren: Vorfaktoren multiplizieren, Hochzahlen addieren, Ergebnis schon normiert.',
  frage: `Berechne (3 · 10⁴) · (2 · 10⁻⁶).\n\n${FORM}`,
  teile: teile(['3*2', [['plus_statt_mal', '3+2', 'Die Vorfaktoren addiert statt multipliziert: 3 + 2 = 5.', 'Werden die Vorfaktoren addiert oder multipliziert?']]],
    ['4-6', [['potenzgesetz_verwechselt', '4*(0-6)', 'Die Hochzahlen multipliziert: 4 · (−6) = −24.', 'Werden beim Malnehmen von Zehnerpotenzen die Hochzahlen multipliziert oder addiert?'],
      ['zehnerexponent_vorzeichen', '2', 'Positive Hochzahl angegeben, obwohl das Ergebnis 0,06 kleiner als 1 ist.', 'Ist das Ergebnis größer oder kleiner als 1?']]]),
  weg: 'Vorfaktoren: 3 · 2 = 6.\nZehnerpotenzen: 10⁴ · 10⁻⁶ = 10⁴⁺⁽⁻⁶⁾ = 10⁻².\nErgebnis: 6 · 10⁻², also a = {1} und n = {2}.' });
def({ ...RE, ref: 'potenz-rechnen-02', titel: 'Wissenschaftliche Schreibweise · (8 · 10⁶) : (2 · 10²)', afb: 'I', sach: false,
  afbGrund: 'Reproduzieren: Vorfaktoren dividieren, Hochzahlen subtrahieren, Ergebnis schon normiert.',
  frage: `Berechne (8 · 10⁶) : (2 · 10²).\n\n${FORM}`,
  teile: teile(['8/2', [['multipliziert_statt_dividiert', '8*2', 'Die Vorfaktoren multipliziert statt geteilt: 8 · 2 = 16.', 'Welche Rechenart steht zwischen den beiden Klammern?']]],
    ['6-2', [['potenzgesetz_verwechselt', '6/2', 'Die Hochzahlen geteilt statt subtrahiert: 6 : 2 = 3.', 'Werden beim Teilen von Zehnerpotenzen die Hochzahlen geteilt oder subtrahiert?'],
      ['potenzgesetz_verwechselt', '6+2', 'Die Hochzahlen addiert wie beim Malnehmen: 6 + 2 = 8.', 'Werden beim Teilen von Zehnerpotenzen die Hochzahlen addiert oder subtrahiert?']]]),
  weg: 'Vorfaktoren: 8 : 2 = 4.\nZehnerpotenzen: 10⁶ : 10² = 10⁶⁻² = 10⁴.\nErgebnis: 4 · 10⁴, also a = {1} und n = {2}.' });
def({ ...RE, ref: 'potenz-rechnen-03', titel: 'Wissenschaftliche Schreibweise · (5 · 10³) · (4 · 10⁵) normieren', afb: 'II', sach: false,
  afbGrund: 'Anwenden: Produkt mit Vorfaktor über 10, Ergebnis muss normiert werden.',
  frage: `Berechne (5 · 10³) · (4 · 10⁵).\n\n${FORM}`,
  teile: teile(['5*4/10', [['faktor_zehn_daneben', '5*4', 'Nicht normiert: 20 ist kein Vorfaktor zwischen 1 und 10.', 'Liegt 20 zwischen 1 und 10?']]],
    ['3+5+1', [['faktor_zehn_daneben', '3+5', 'Nicht normiert: 20 · 10⁸ ist richtig, aber nicht in der Form a · 10ⁿ mit a < 10.', 'Wenn der Vorfaktor von 20 auf 2 schrumpft, was muss mit der Hochzahl passieren?'],
      ['potenzgesetz_verwechselt', '3*5', 'Die Hochzahlen multipliziert: 3 · 5 = 15.', 'Werden beim Malnehmen von Zehnerpotenzen die Hochzahlen multipliziert oder addiert?']]]),
  weg: 'Vorfaktoren: 5 · 4 = 20. Zehnerpotenzen: 10³ · 10⁵ = 10⁸.\n20 · 10⁸ = 2 · 10¹ · 10⁸ = 2 · 10⁹.\nAlso a = {1} und n = {2}.' });
def({ ...RE, ref: 'potenz-rechnen-04', titel: 'Wissenschaftliche Schreibweise · (3 · 10⁵) : (6 · 10⁻²) normieren', afb: 'II', sach: false,
  afbGrund: 'Anwenden: Quotient mit negativer Hochzahl, Vorfaktor unter 1 muss normiert werden.',
  frage: `Berechne (3 · 10⁵) : (6 · 10⁻²).\n\n${FORM}`,
  teile: teile(['3/6*10', [['faktor_zehn_daneben', '3/6', 'Nicht normiert: 0,5 ist kein Vorfaktor zwischen 1 und 10.', 'Liegt 0,5 zwischen 1 und 10?'],
    ['multipliziert_statt_dividiert', '3*6', 'Die Vorfaktoren multipliziert statt geteilt: 3 · 6 = 18.', 'Welche Rechenart steht zwischen den beiden Klammern?']]],
    ['5+2-1', [['faktor_zehn_daneben', '5+2', 'Nicht normiert: 0,5 · 10⁷ ist richtig, aber a muss mindestens 1 sein.', 'Wenn der Vorfaktor von 0,5 auf 5 wächst, was muss mit der Hochzahl passieren?'],
      ['potenzgesetz_verwechselt', '5-2', 'Die Hochzahlen addiert statt subtrahiert: 10⁵⁺⁽⁻²⁾ = 10³.', 'Was ergibt 5 − (−2)?']]]),
  weg: 'Vorfaktoren: 3 : 6 = 0,5. Zehnerpotenzen: 10⁵ : 10⁻² = 10⁵⁻⁽⁻²⁾ = 10⁷.\n0,5 · 10⁷ = 5 · 10⁻¹ · 10⁷ = 5 · 10⁶.\nAlso a = {1} und n = {2}.' });
def({ ...RE, ref: 'potenz-rechnen-05', titel: 'Wissenschaftliche Schreibweise · Lichtweg in einer Minute', afb: 'II', sach: true,
  afbGrund: 'Anwenden im Sachkontext: Strecke = Geschwindigkeit · Zeit in wissenschaftlicher Schreibweise, Ergebnis normieren.',
  frage: `Licht legt in einer Sekunde etwa 3 · 10⁸ m zurück.\n\nWie viele Meter legt es in einer Minute, also in 6 · 10¹ s, zurück? ${FORM}`,
  teile: teile(['3*6/10', [['faktor_zehn_daneben', '3*6', 'Nicht normiert: 18 ist kein Vorfaktor zwischen 1 und 10.', 'Liegt 18 zwischen 1 und 10?']]],
    ['8+1+1', [['faktor_zehn_daneben', '8+1', 'Nicht normiert: 18 · 10⁹ m ist richtig, aber a muss kleiner als 10 sein.', 'Wenn der Vorfaktor von 18 auf 1,8 schrumpft, was muss mit der Hochzahl passieren?'],
      ['potenzgesetz_verwechselt', '8*1', 'Die Hochzahlen multipliziert: 8 · 1 = 8.', 'Werden beim Malnehmen von Zehnerpotenzen die Hochzahlen multipliziert oder addiert?']]]),
  weg: 'Strecke = Geschwindigkeit · Zeit = (3 · 10⁸ m/s) · (6 · 10¹ s).\n3 · 6 = 18 und 10⁸ · 10¹ = 10⁹: 18 · 10⁹ m = 1,8 · 10¹⁰ m.\nAlso a = {1} und n = {2}.' });
def({ ...RE, ref: 'potenz-rechnen-06', titel: 'Wissenschaftliche Schreibweise · Licht von der Sonne zur Erde', afb: 'III', sach: true,
  afbGrund: 'Problemlösen: Zeit = Strecke : Geschwindigkeit selbst aufstellen, Quotient bilden und normieren.',
  frage: `Die Sonne ist etwa 1,5 · 10¹¹ m von der Erde entfernt. Licht legt in einer Sekunde etwa 3 · 10⁸ m zurück.\n\nWie viele Sekunden braucht das Licht von der Sonne bis zur Erde? ${FORM}`,
  teile: teile(['1.5/3*10', [['faktor_zehn_daneben', '1.5/3', 'Nicht normiert: 0,5 ist kein Vorfaktor zwischen 1 und 10.', 'Liegt 0,5 zwischen 1 und 10?'],
    ['multipliziert_statt_dividiert', '1.5*3', 'Strecke mal Geschwindigkeit gerechnet: 1,5 · 3 = 4,5.', 'Wie erhältst du aus Strecke und Geschwindigkeit die Zeit?']]],
    ['11-8-1', [['faktor_zehn_daneben', '11-8', 'Nicht normiert: 0,5 · 10³ s ist richtig, aber a muss mindestens 1 sein.', 'Wenn der Vorfaktor von 0,5 auf 5 wächst, was muss mit der Hochzahl passieren?'],
      ['multipliziert_statt_dividiert', '11+8', 'Strecke mal Geschwindigkeit gerechnet: 10¹¹ · 10⁸ = 10¹⁹.', 'Wie erhältst du aus Strecke und Geschwindigkeit die Zeit?']]]),
  weg: 'Zeit = Strecke : Geschwindigkeit = (1,5 · 10¹¹ m) : (3 · 10⁸ m/s).\n1,5 : 3 = 0,5 und 10¹¹ : 10⁸ = 10³: 0,5 · 10³ s = 5 · 10² s (500 s).\nAlso a = {1} und n = {2}.' });

baueCharge({
  thema: 'potenz', batch: 'k9-potenz', source: 'edvance_k9_potenz', idsPfad: 'docs/prefill/k9-potenz-ids.json',
  kopf: [
    `K9-Rest, Thema potenz — ${A.length} Aufgaben: je sechs zu zahl_potenz_gesetze, _negativ, _zehner und _rechnen.`,
    'Erzeugt von tools/vorlauf-build.mjs aus docs/prefill/k9-potenz.json (Quelle: tools/k9-potenz-charge.mjs) — nicht von Hand editieren.',
    '',
    'Einspiel-Reihenfolge: nach 20261003105853_substrat_k9_potenz.sql (Knoten + Fehlbild-Slugs muessen stehen).',
  ],
  auswahl: 'Je Knoten vier reine Anwendung mit steigender Schwierigkeit und zwei mit Sachkontext oder Problemlösen (Zellkultur, Würfelzerlegung, Halbierung, Blutkörperchen, Viren und Sandkorn, Lichtweg). Alle ohne Abbildung lösbar, alle exakt. Die wissenschaftliche Schreibweise wird nie als Eingabe verlangt: gefragt ist die Hochzahl allein oder Vorfaktor und Hochzahl als zwei Teile (MULTI_PART). Negative Hochzahlen: Bruch und Dezimalzahl werden beide akzeptiert.',
  aufgaben: A,
});
