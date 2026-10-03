#!/usr/bin/env node
/**
 * k9-wurzel-charge.mjs — erzeugt docs/prefill/k9-wurzel.json (Charge-Format von vorlauf-build.mjs).
 *
 *   node tools/k9-wurzel-charge.mjs
 *
 * Thema wurzel (KLP Ari-2/6/7): Quadratwurzeln, Näherungswerte, rationale/irrationale Zahlen,
 * Wurzelgesetze, teilweises Wurzelziehen. Je Knoten sechs Aufgaben (01 I, 02 I, 03 II, 04 II,
 * 05 II Sachkontext, 06 III). Antworten sind immer Zahlen (das Tablet kann kein √ eingeben).
 * Jeder Wert wird über k9-rest-lib.mjs exakt nachgerechnet; W(x) = Quadratwurzel.
 * Abschneiden statt Runden wird als W(x) − 0,5·10⁻ⁿ, gerundet auf n Stellen, gerechnet
 * (gleich dem abgeschnittenen Wert, solange keine Rundungsgrenze getroffen wird — die Bibliothek prüft das).
 * Die ids stehen in docs/prefill/k9-wurzel-ids.json: ein zweiter Lauf erzeugt dieselbe Charge.
 */

import { baueCharge, CLUSTER } from './k9-rest-lib.mjs';

const GEMEINSAM = {
  inhalt: 'arithmetik_algebra',
  inhaltGrund: 'Inhaltsfeld Arithmetik/Algebra (Ari-2, Ari-6, Ari-7).',
  cluster: CLUSTER.zahl,
  clusterGrund: 'Zahl & Rechnen wie potenzen (Quadratwurzeln) im Bestand.',
  stoff: 9,
  stoffGrund: 'Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Ari-2/Ari-6/Ari-7 (Quadratwurzeln, reelle Zahlen).',
};
const EXAKT = 'Gib das Ergebnis exakt an.';
const ANZAHL = 'Gib die Anzahl als ganze Zahl an.';

const A = [];
const def = (o) => A.push({ ...GEMEINSAM, ...o });

// ─── zahl_wurzel_quadrat (Tiefe 5) ───
const QU = { skill: 'zahl_wurzel_quadrat', n: 'exakt' };
def({ ...QU, ref: 'wurzel-quadrat-01', titel: 'Quadratwurzel · Zahl, die quadriert 225 ergibt', afb: 'I', sach: false,
  afbGrund: 'Reproduzieren: Wurzel aus einer bekannten Quadratzahl, ein Schritt.',
  frage: `Welche positive Zahl ergibt quadriert 225?\n\n${EXAKT}`, r: 'W(225)',
  weg: 'Gesucht ist √225, also die positive Zahl, deren Quadrat 225 ist.\n15 · 15 = 225, also √225 = {A}.',
  ke: [['falsche_gegenoperation', '225^2', 'Quadriert statt die Wurzel zu ziehen: 225² = 50625.', 'Welche Rechnung macht das Quadrieren wieder rückgängig?'],
    ['wurzel_halbiert', '225/2', 'Die Zahl halbiert statt die Wurzel zu ziehen: 225 : 2 = 112,5.', 'Was kommt heraus, wenn du 112,5 mit sich selbst malnimmst?']] });
def({ ...QU, ref: 'wurzel-quadrat-02', titel: 'Quadratwurzel · √0,49', afb: 'I', sach: false,
  afbGrund: 'Reproduzieren: Wurzel aus einer Dezimalzahl, die zu einer bekannten Quadratzahl gehört.',
  frage: `Berechne √0,49.\n\n${EXAKT}`, r: 'W(0.49)',
  weg: '0,7 · 0,7 = 0,49, also √0,49 = {A}.',
  ke: [['kommastellen_zu_viel', '0.07', 'Das Komma falsch gesetzt: 0,07 statt 0,7.', 'Was ergibt 0,07 · 0,07 – wie viele Stellen nach dem Komma hat das Ergebnis?'],
    ['kommastellen_zu_wenig', '7', 'Das Komma weggelassen: √49 = 7 gerechnet.', 'Ist 7 · 7 gleich 0,49?'],
    ['wurzel_halbiert', '0.49/2', 'Halbiert statt die Wurzel gezogen: 0,49 : 2 = 0,245.', 'Was ergibt 0,245 · 0,245 ungefähr?']] });
def({ ...QU, ref: 'wurzel-quadrat-03', titel: 'Quadratwurzel · √(9/16)', afb: 'II', sach: false, bruch: true,
  afbGrund: 'Anwenden: Wurzel aus einem Bruch, Zähler und Nenner getrennt.',
  frage: `Berechne √(9/16).\n\n${EXAKT} Du kannst einen Bruch oder eine Dezimalzahl eingeben.`, r: 'W(9/16)',
  weg: '√(9/16) = √9 / √16 = 3/4.\nAls Dezimalzahl: {A}.',
  ke: [['klammer_vergessen', 'W(9)/16', 'Die Wurzel nur aus dem Zähler gezogen, als stünde √9 / 16 da: 3/16.', 'Steht nur die 9 oder der ganze Bruch unter der Wurzel?'],
    ['wurzel_halbiert', '9/16/2', 'Halbiert statt die Wurzel gezogen: 9/32.', 'Was ergibt 3/4 · 3/4?']] });
def({ ...QU, ref: 'wurzel-quadrat-04', titel: 'Quadratwurzel · √0,0016', afb: 'II', sach: false,
  afbGrund: 'Anwenden: Wurzel aus einer kleinen Dezimalzahl, Kommastellen müssen stimmen.',
  frage: `Berechne √0,0016.\n\n${EXAKT}`, r: 'W(0.0016)',
  weg: '0,0016 hat vier Stellen nach dem Komma, die Wurzel daraus zwei.\n0,04 · 0,04 = 0,0016, also √0,0016 = {A}.',
  ke: [['kommastellen_zu_wenig', '0.4', 'Das Komma falsch gesetzt: 0,4 statt 0,04.', 'Was ergibt 0,4 · 0,4?'],
    ['kommastellen_zu_viel', '0.004', 'Zu viele Stellen nach dem Komma: 0,004.', 'Wie viele Stellen nach dem Komma hat 0,004 · 0,004?'],
    ['wurzel_halbiert', '0.0016/2', 'Halbiert statt die Wurzel gezogen: 0,0008.', 'Ist die Wurzel aus einer Zahl zwischen 0 und 1 kleiner oder größer als die Zahl?']] });
def({ ...QU, ref: 'wurzel-quadrat-05', titel: 'Quadratwurzel · Seite eines Quadrats mit 2,25 m²', einheit: 'cm', afb: 'II', sach: true,
  afbGrund: 'Anwenden im Sachkontext: Seitenlänge als Wurzel der Fläche erkennen und umrechnen.',
  frage: `Eine quadratische Tischplatte hat einen Flächeninhalt von 2,25 m².\n\nWie lang ist eine Seite der Tischplatte in Zentimetern? ${EXAKT}`, r: 'W(2.25)*100',
  weg: 'Seitenlänge = √(2,25 m²) = 1,5 m, denn 1,5 · 1,5 = 2,25.\n1,5 m = {A} cm.',
  ke: [['einheit_uebersprungen', 'W(2.25)', 'Nicht in Zentimeter umgerechnet: die Seitenlänge in Metern.', 'In welcher Einheit ist die Seitenlänge gefragt?'],
    ['kommastellen_zu_viel', '0.15*100', 'Das Komma falsch gesetzt: √2,25 als 0,15 gerechnet, also 15 cm.', 'Ergibt 0,15 · 0,15 wirklich 2,25?'],
    ['wurzel_halbiert', '2.25/2*100', 'Die Fläche halbiert statt die Wurzel gezogen: 1,125 m.', 'Welche Zahl ergibt mit sich selbst malgenommen 2,25?']] });
def({ ...QU, ref: 'wurzel-quadrat-06', titel: 'Quadratwurzel · Zaun um einen Platz mit 1296 m²', einheit: 'm', afb: 'III', sach: true,
  afbGrund: 'Problemlösen: aus der Fläche erst die Seite bestimmen, dann den Umfang bilden.',
  frage: `Ein quadratischer Platz hat einen Flächeninhalt von 1296 m². Er soll ringsum eingezäunt werden.\n\nWie viele Meter Zaun werden gebraucht? ${EXAKT}`, r: '4*W(1296)',
  weg: 'Seitenlänge: √1296 m = 36 m, denn 36 · 36 = 1296.\nZaun = Umfang = 4 · 36 m = {A} m.',
  ke: [['falsche_groesse_beantwortet', 'W(1296)', 'Nur die Seitenlänge angegeben, nicht den ganzen Zaun.', 'Wie viele Seiten hat der Platz, die eingezäunt werden?'],
    ['wurzel_halbiert', '4*1296/2', 'Die Fläche halbiert statt die Wurzel gezogen.', 'Welche Zahl ergibt mit sich selbst malgenommen 1296?']] });

// ─── zahl_wurzel_naeherung (Tiefe 6) ───
const NA = { skill: 'zahl_wurzel_naeherung' };
def({ ...NA, ref: 'wurzel-naeherung-01', titel: 'Näherung · √50 zwischen zwei ganzen Zahlen', afb: 'I', sach: false,
  afbGrund: 'Reproduzieren: benachbarte Quadratzahlen 49 und 64 erkennen.',
  frage: '√50 liegt zwischen zwei aufeinanderfolgenden ganzen Zahlen.\n\nGib beide Zahlen an.',
  teile: [
    { prompt: 'Kleinere Zahl', r: 'W(49)', n: 'exakt',
      ke: [['falsche_groesse_beantwortet', '49', 'Die Quadratzahl 49 angegeben statt ihrer Wurzel.', 'Liegt √50 wirklich in der Nähe von 49?'],
        ['wurzel_halbiert', '50/2', '√50 als 50 : 2 = 25 genommen.', 'Was ergibt 25 · 25 – liegt das in der Nähe von 50?']] },
    { prompt: 'Größere Zahl', r: 'W(64)', n: 'exakt',
      ke: [['falsche_groesse_beantwortet', '64', 'Die Quadratzahl 64 angegeben statt ihrer Wurzel.', 'Liegt √50 wirklich in der Nähe von 64?'],
        ['wurzel_halbiert', '50/2+1', '√50 als 50 : 2 = 25 genommen, dann 26 als nächste Zahl.', 'Was ergibt 26 · 26 – liegt das in der Nähe von 50?']] },
  ],
  weg: 'Benachbarte Quadratzahlen: 7² = 49 < 50 < 64 = 8².\nAlso liegt √50 zwischen {1} und {2}.' });
def({ ...NA, ref: 'wurzel-naeherung-02', titel: 'Näherung · √10 auf eine Stelle', afb: 'I', sach: false, n: 1,
  afbGrund: 'Reproduzieren: Näherungswert einer Wurzel bestimmen und auf eine Stelle runden.',
  frage: 'Berechne √10.\n\nRunde auf eine Stelle nach dem Komma.', r: 'W(10)',
  weg: '√10 ≈ 3,162…\nDie zweite Stelle nach dem Komma ist eine 6, also aufrunden: √10 ≈ {A}.',
  ke: [['abgeschnitten', 'W(10)-0.05', 'Abgeschnitten statt gerundet: 3,1.', 'Welche Ziffer steht nach der ersten Stelle – wird auf- oder abgerundet?'],
    ['wurzel_halbiert', '10/2', 'Halbiert statt die Wurzel gezogen: 10 : 2 = 5.', 'Was ergibt 5 · 5 – ist das 10?']] });
def({ ...NA, ref: 'wurzel-naeherung-03', titel: 'Näherung · √30 auf zwei Stellen', afb: 'II', sach: false, n: 2,
  afbGrund: 'Anwenden: Wurzel ohne nahe Quadratzahl, auf zwei Stellen runden.',
  frage: 'Berechne √30.\n\nRunde auf zwei Stellen nach dem Komma.', r: 'W(30)',
  weg: '√30 ≈ 5,4772…\nDie dritte Stelle nach dem Komma ist eine 7, also aufrunden: √30 ≈ {A}.\nProbe: 5² = 25 < 30 < 36 = 6².',
  ke: [['abgeschnitten', 'W(30)-0.005', 'Abgeschnitten statt gerundet: 5,47.', 'Welche Ziffer steht an der dritten Stelle nach dem Komma?'],
    ['wurzel_halbiert', '30/2', 'Halbiert statt die Wurzel gezogen: 30 : 2 = 15.', 'Zwischen welchen Quadratzahlen liegt 30 – passt 15 dazu?']] });
def({ ...NA, ref: 'wurzel-naeherung-04', titel: 'Näherung · √0,9 auf zwei Stellen', afb: 'II', sach: false, n: 2,
  afbGrund: 'Anwenden: Wurzel aus einer Zahl zwischen 0 und 1 ist größer als die Zahl; auf zwei Stellen runden.',
  frage: 'Berechne √0,9.\n\nRunde auf zwei Stellen nach dem Komma.', r: 'W(0.9)',
  weg: '√0,9 ≈ 0,9486…\nDie dritte Stelle nach dem Komma ist eine 8, also aufrunden: √0,9 ≈ {A}.\nDie Wurzel aus einer Zahl zwischen 0 und 1 ist größer als die Zahl selbst.',
  ke: [['wurzel_halbiert', '0.9/2', 'Halbiert statt die Wurzel gezogen: 0,9 : 2 = 0,45.', 'Was ergibt 0,45 · 0,45 – ist das 0,9?'],
    ['abgeschnitten', 'W(0.9)-0.005', 'Abgeschnitten statt gerundet: 0,94.', 'Welche Ziffer steht an der dritten Stelle nach dem Komma?']] });
def({ ...NA, ref: 'wurzel-naeherung-05', titel: 'Näherung · Seite eines Beets mit 11 m²', einheit: 'm', afb: 'II', sach: true, n: 2,
  afbGrund: 'Anwenden im Sachkontext: Seitenlänge als Wurzel der Fläche, auf Zentimeter runden.',
  frage: 'Ein quadratisches Beet hat einen Flächeninhalt von 11 m².\n\nWie lang ist eine Seite des Beets? Runde auf zwei Stellen nach dem Komma.', r: 'W(11)',
  weg: 'Seitenlänge = √(11 m²) ≈ 3,3166… m.\nAuf zwei Stellen gerundet: {A} m.',
  ke: [['abgeschnitten', 'W(11)-0.005', 'Abgeschnitten statt gerundet: 3,31 m.', 'Welche Ziffer steht an der dritten Stelle nach dem Komma?'],
    ['wurzel_halbiert', '11/2', 'Die Fläche halbiert statt die Wurzel gezogen: 5,5 m.', 'Wie groß wäre ein Beet mit 5,5 m Seitenlänge?'],
    ['kommastellen_zu_wenig', 'W(11)', 'Nur auf eine Stelle gerundet: 3,3 m.', 'Auf wie viele Stellen nach dem Komma sollst du runden?', 1]] });
def({ ...NA, ref: 'wurzel-naeherung-06', titel: 'Näherung · Teppich mit 6 m², Seite in ganzen Zentimetern', einheit: 'cm', afb: 'III', sach: true, n: 'auf',
  afbGrund: 'Problemlösen: Wurzel ziehen, in Zentimeter umrechnen und sinnvoll aufrunden.',
  frage: 'Ein quadratischer Teppich soll einen Flächeninhalt von mindestens 6 m² haben.\n\nWie lang muss eine Seite mindestens sein? Gib ganze Zentimeter an und runde dafür auf.', r: 'W(6)*100',
  weg: 'Seitenlänge = √(6 m²) ≈ 2,4495 m = 244,95 cm.\nMit 244 cm wäre der Teppich zu klein, also mindestens {A} cm.',
  ke: [['abgeschnitten', 'W(6)*100', 'Abgerundet: Mit 244 cm sind es weniger als 6 m².', 'Reicht die Fläche, wenn du abrundest?', 'ab'],
    ['einheit_uebersprungen', 'W(6)', 'Nicht in Zentimeter umgerechnet: die Seitenlänge in Metern.', 'In welcher Einheit ist die Seitenlänge gefragt?', 2],
    ['wurzel_halbiert', '6/2*100', 'Die Fläche halbiert statt die Wurzel gezogen: 3 m.', 'Wie groß wäre ein Teppich mit 3 m Seitenlänge?']] });

// ─── zahl_wurzel_irrational (Tiefe 6) ───
const IR = { skill: 'zahl_wurzel_irrational', n: 'exakt' };
def({ ...IR, ref: 'wurzel-irrational-01', titel: 'Irrational · Anzahl unter fünf Zahlen', afb: 'I', sach: false,
  afbGrund: 'Reproduzieren: Wurzeln aus Nicht-Quadratzahlen als irrational erkennen.',
  frage: `Wie viele der folgenden Zahlen sind irrational?\n\n√2;   √9;   0,5;   √5;   3/7\n\n${ANZAHL}`, r: '1+1',
  weg: '√9 = 3, 0,5 und 3/7 sind Brüche, also rational.\n√2 und √5 sind Wurzeln aus Zahlen, die keine Quadratzahlen sind: irrational.\nAnzahl: {A}.',
  ke: [['irrational_verwechselt', '1+1+1', '√9 auch für irrational gehalten, obwohl √9 = 3.', 'Welche ganze Zahl ergibt quadriert 9?'],
    ['irrational_verwechselt', '1+1+1+1', '√9 und 3/7 für irrational gehalten; 3/7 ist ein Bruch und damit rational.', 'Lässt sich 3/7 als Bruch schreiben?']] });
def({ ...IR, ref: 'wurzel-irrational-02', titel: 'Rational · 0,375 als gekürzter Bruch', afb: 'I', sach: false,
  afbGrund: 'Reproduzieren: abbrechende Dezimalzahl als Bruch schreiben und vollständig kürzen.',
  frage: 'Schreibe 0,375 als vollständig gekürzten Bruch.\n\nGib den Nenner an.', r: '1000/125',
  weg: '0,375 = 375/1000.\nggT(375; 1000) = 125, also 375/1000 = 3/8.\nNenner: {A}.',
  ke: [['teilgekuerzt', '1000', 'Gar nicht gekürzt: 375/1000.', 'Haben 375 und 1000 noch einen gemeinsamen Teiler?'],
    ['teilgekuerzt', '1000/5', 'Nur durch 5 gekürzt: 75/200.', 'Lässt sich 75/200 noch weiter kürzen?'],
    ['teilgekuerzt', '1000/25', 'Nur durch 25 gekürzt: 15/40.', 'Lässt sich 15/40 noch weiter kürzen?']] });
def({ ...IR, ref: 'wurzel-irrational-03', titel: 'Rational · 0,4545… als gekürzter Bruch', afb: 'II', sach: false,
  afbGrund: 'Anwenden: periodische Dezimalzahl als Bruch schreiben (Periode durch 99) und kürzen.',
  frage: 'Die Zahl 0,454545… (Periode 45) ist rational.\n\nSchreibe sie als vollständig gekürzten Bruch und gib den Nenner an.', r: '99/9',
  weg: '0,454545… (Periode 45) = 45/99.\nggT(45; 99) = 9, also 45/99 = 5/11.\nNenner: {A}.',
  ke: [['teilgekuerzt', '99', 'Nicht gekürzt: 45/99.', 'Haben 45 und 99 noch einen gemeinsamen Teiler?'],
    ['abgeschnitten', '100/5', 'Die Periode abgeschnitten: 0,45 = 45/100 = 9/20.', 'Ist 0,45 genau gleich 0,454545…?']] });
def({ ...IR, ref: 'wurzel-irrational-04', titel: 'Rational · Anzahl unter sechs Zahlen', afb: 'II', sach: false,
  afbGrund: 'Anwenden: Wurzeln, periodische Dezimalzahl, π und negative Zahl sicher zuordnen.',
  frage: `Wie viele der folgenden Zahlen sind rational?\n\n√16;   √12;   0,333… (Periode 3);   π;   √0,25;   −5\n\n${ANZAHL}`, r: '1+1+1+1',
  weg: 'Rational: √16 = 4, 0,333… (Periode 3) = 1/3, √0,25 = 0,5 und −5.\nIrrational: √12 (12 ist keine Quadratzahl) und π.\nAnzahl: {A}.',
  ke: [['irrational_verwechselt', '1+1+1', 'Die periodische Zahl 0,333… für irrational gehalten, obwohl sie 1/3 ist.', 'Lässt sich 0,333… (Periode 3) als Bruch schreiben?'],
    ['irrational_verwechselt', '1+1', 'Die periodische Zahl und √0,25 für irrational gehalten.', 'Welche Zahl ergibt quadriert 0,25?'],
    ['irrational_verwechselt', '1+1+1+1+1', 'π für rational gehalten, weil man oft mit 3,14 rechnet.', 'Ist 3,14 der genaue Wert von π oder nur ein Näherungswert?']] });
def({ ...IR, ref: 'wurzel-irrational-05', titel: 'Irrational · Fliesen mit rationaler Seitenlänge', afb: 'II', sach: true,
  afbGrund: 'Anwenden im Sachkontext: aus Flächeninhalten entscheiden, ob die Seitenlänge rational ist.',
  frage: `Ein Betrieb stellt quadratische Fliesen mit diesen Flächeninhalten her (in cm²):\n\n49;   50;   2,25;   8;   0,64;   12,1\n\nBei wie vielen dieser Fliesen ist die Seitenlänge in cm eine rationale Zahl? ${ANZAHL}`, r: '1+1+1',
  weg: 'Seitenlänge = Wurzel aus dem Flächeninhalt.\nRational: √49 = 7, √2,25 = 1,5, √0,64 = 0,8.\nIrrational: √50, √8 und √12,1 (12,1 ist kein Quadrat einer Dezimalzahl, 3,4² = 11,56 und 3,5² = 12,25).\nAnzahl: {A}.',
  ke: [['irrational_verwechselt', '1+1+1+1', '√12,1 für rational gehalten, weil 121 = 11² ist; 11² = 121, aber 1,1² = 1,21.', 'Welche Zahl ergibt quadriert 12,1 – gibt es dafür eine abbrechende Dezimalzahl?'],
    ['irrational_verwechselt', '1', 'Die Wurzeln aus den Dezimalzahlen 2,25 und 0,64 für irrational gehalten.', 'Was ergibt 1,5 · 1,5?']] });
def({ ...IR, ref: 'wurzel-irrational-06', titel: 'Irrational · rationale Wurzeln von 1 bis 60', afb: 'III', sach: false,
  afbGrund: 'Problemlösen: erkennen, dass √n für natürliches n genau bei Quadratzahlen rational ist, dann zählen.',
  frage: `Für wie viele natürliche Zahlen n von 1 bis 60 (jeweils einschließlich) ist √n eine rationale Zahl?\n\n${ANZAHL}`, r: 'W(49)',
  weg: '√n ist für eine natürliche Zahl n genau dann rational, wenn n eine Quadratzahl ist.\nQuadratzahlen von 1 bis 60: 1, 4, 9, 16, 25, 36, 49 (64 ist schon zu groß).\nAnzahl: {A}.',
  ke: [['falsche_groesse_beantwortet', '60-W(49)', 'Die irrationalen Wurzeln gezählt statt der rationalen.', 'Wurde nach den rationalen oder nach den irrationalen Wurzeln gefragt?'],
    ['irrational_verwechselt', '0', 'Alle Wurzeln für irrational gehalten, auch √1, √4, √9 …', 'Ist √4 = 2 eine irrationale Zahl?']] });

// ─── zahl_wurzel_gesetze (Tiefe 6) ───
const GE = { skill: 'zahl_wurzel_gesetze', n: 'exakt' };
def({ ...GE, ref: 'wurzel-gesetze-01', titel: 'Wurzelgesetz · √2 · √8', afb: 'I', sach: false,
  afbGrund: 'Reproduzieren: Produktgesetz √a · √b = √(a · b), Ergebnis eine Quadratzahl.',
  frage: `Berechne √2 · √8.\n\n${EXAKT}`, r: 'W(2*8)',
  weg: '√2 · √8 = √(2 · 8) = √16 = {A}.',
  ke: [['falsche_groesse_beantwortet', '2*8', 'Nur 2 · 8 = 16 gerechnet, die Wurzel aus 16 nicht gezogen.', 'Steht 16 noch unter der Wurzel?'],
    ['wurzel_halbiert', '2*8/2', '√16 als 16 : 2 = 8 genommen.', 'Was ergibt 8 · 8?']] });
def({ ...GE, ref: 'wurzel-gesetze-02', titel: 'Wurzelgesetz · √50 : √2', afb: 'I', sach: false,
  afbGrund: 'Reproduzieren: Quotientengesetz √a : √b = √(a : b), Ergebnis eine Quadratzahl.',
  frage: `Berechne √50 : √2.\n\n${EXAKT}`, r: 'W(50/2)',
  weg: '√50 : √2 = √(50 : 2) = √25 = {A}.',
  ke: [['falsche_groesse_beantwortet', '50/2', 'Nur 50 : 2 = 25 gerechnet, die Wurzel aus 25 nicht gezogen.', 'Steht 25 noch unter der Wurzel?'],
    ['wurzel_halbiert', '50/2/2', '√25 als 25 : 2 = 12,5 genommen.', 'Was ergibt 12,5 · 12,5?']] });
def({ ...GE, ref: 'wurzel-gesetze-03', titel: 'Wurzel einer Summe · √(36 + 64)', afb: 'II', sach: false,
  afbGrund: 'Anwenden: erkennen, dass es für die Summe kein Wurzelgesetz gibt; erst addieren, dann Wurzel ziehen.',
  frage: `Berechne √(36 + 64).\n\n${EXAKT}`, r: 'W(36+64)',
  weg: 'Für Summen gibt es kein Wurzelgesetz: erst unter der Wurzel rechnen.\n√(36 + 64) = √100 = {A}.',
  ke: [['wurzel_gliedweise', 'W(36)+W(64)', 'Die Wurzel gliedweise gezogen: √36 + √64 = 6 + 8 = 14.', 'Was ergibt 14 · 14 – ist das 36 + 64?'],
    ['falsche_groesse_beantwortet', '36+64', 'Nur 36 + 64 = 100 gerechnet, die Wurzel nicht gezogen.', 'Steht 100 noch unter der Wurzel?'],
    ['wurzel_halbiert', '(36+64)/2', '√100 als 100 : 2 = 50 genommen.', 'Was ergibt 50 · 50?']] });
def({ ...GE, ref: 'wurzel-gesetze-04', titel: 'Wurzel einer Summe · √(1,44 + 0,81)', afb: 'II', sach: false,
  afbGrund: 'Anwenden: Summe mit Dezimalzahlen unter der Wurzel, gliedweises Wurzelziehen ist verlockend.',
  frage: `Berechne √(1,44 + 0,81).\n\n${EXAKT}`, r: 'W(1.44+0.81)',
  weg: 'Erst unter der Wurzel addieren: 1,44 + 0,81 = 2,25.\n√2,25 = {A}, denn 1,5 · 1,5 = 2,25.',
  ke: [['wurzel_gliedweise', 'W(1.44)+W(0.81)', 'Die Wurzel gliedweise gezogen: √1,44 + √0,81 = 1,2 + 0,9 = 2,1.', 'Was ergibt 2,1 · 2,1 – ist das 2,25?'],
    ['falsche_groesse_beantwortet', '1.44+0.81', 'Nur 1,44 + 0,81 = 2,25 gerechnet, die Wurzel nicht gezogen.', 'Steht 2,25 noch unter der Wurzel?'],
    ['wurzel_halbiert', '(1.44+0.81)/2', '√2,25 als 2,25 : 2 = 1,125 genommen.', 'Was ergibt 1,125 · 1,125?']] });
def({ ...GE, ref: 'wurzel-gesetze-05', titel: 'Wurzelgesetz · Rechteck √8 m mal √18 m', einheit: 'm²', afb: 'II', sach: true,
  afbGrund: 'Anwenden im Sachkontext: Flächeninhalt als Produkt zweier Wurzeln, Produktgesetz nutzen.',
  frage: `Ein rechteckiges Feld ist √8 m lang und √18 m breit.\n\nWie groß ist sein Flächeninhalt in Quadratmetern? ${EXAKT}`, r: 'W(8*18)',
  weg: 'A = √8 m · √18 m = √(8 · 18) m² = √144 m² = {A} m².',
  ke: [['falsche_groesse_beantwortet', '8*18', 'Nur 8 · 18 = 144 gerechnet, die Wurzel nicht gezogen.', 'Steht 144 noch unter der Wurzel?'],
    ['umfang_statt_flaeche', '2*(W(8)+W(18))', 'Den Umfang berechnet statt des Flächeninhalts: etwa 14,14 m.', 'Ist nach dem Rand oder nach der Fläche des Feldes gefragt?', 2],
    ['plus_statt_mal', 'W(8+18)', 'Unter der Wurzel addiert statt multipliziert: √26 ≈ 5,10.', 'Wie berechnet man den Flächeninhalt eines Rechtecks?', 2]] });
def({ ...GE, ref: 'wurzel-gesetze-06', titel: 'Wurzel einer Summe · ein Beet so groß wie zwei', einheit: 'm', afb: 'III', sach: true,
  afbGrund: 'Problemlösen: Flächen addieren und erst danach die Wurzel ziehen; die Seiten dürfen nicht addiert werden.',
  frage: `Zwei quadratische Beete haben die Flächeninhalte 9 m² und 16 m². Sie sollen durch ein einziges quadratisches Beet ersetzt werden, das genau so groß ist wie beide zusammen.\n\nWie lang ist eine Seite des neuen Beets? ${EXAKT}`, r: 'W(9+16)',
  weg: 'Fläche des neuen Beets: 9 m² + 16 m² = 25 m².\nSeitenlänge: √25 m = {A} m.\n(Nicht 3 m + 4 m: ein Quadrat mit 7 m Seite hätte 49 m².)',
  ke: [['wurzel_gliedweise', 'W(9)+W(16)', 'Die Seitenlängen addiert: √9 + √16 = 3 + 4 = 7.', 'Wie groß wäre ein quadratisches Beet mit 7 m Seitenlänge?'],
    ['falsche_groesse_beantwortet', '9+16', 'Den Flächeninhalt 25 angegeben statt der Seitenlänge.', 'Wurde nach der Fläche oder nach der Seite gefragt?'],
    ['wurzel_halbiert', '(9+16)/2', '√25 als 25 : 2 = 12,5 genommen.', 'Was ergibt 12,5 · 12,5?']] });

// ─── zahl_wurzel_teilweise (Tiefe 7) ───
const TW = { skill: 'zahl_wurzel_teilweise', n: 'exakt' };
const NAT = 'a ist eine natürliche Zahl. Gib a exakt an.';
def({ ...TW, ref: 'wurzel-teilweise-01', titel: 'Teilweise Wurzel ziehen · √72 = a · √2', afb: 'I', sach: false,
  afbGrund: 'Reproduzieren: Quadratzahl-Faktor 36 abspalten, Form vorgegeben.',
  frage: `Es gilt √72 = a · √2.\n\nBestimme a. ${NAT}`, r: 'W(72/2)',
  weg: '72 = 36 · 2, also √72 = √36 · √2 = 6 · √2.\na = {A}.',
  ke: [['faktor_ohne_wurzel', '72/2', 'Den Faktor 36 herausgezogen, ohne aus ihm die Wurzel zu ziehen.', 'Was ergibt (36 · √2)² – ist das 72?'],
    ['wurzel_halbiert', '72/2/2', '√36 als 36 : 2 = 18 genommen.', 'Was ergibt 18 · 18?'],
    ['falsche_groesse_beantwortet', 'W(72)', 'Den Näherungswert von √72 angegeben statt a.', 'Nach welcher Zahl ist gefragt: nach √72 oder nach dem Faktor vor √2?', 2]] });
def({ ...TW, ref: 'wurzel-teilweise-02', titel: 'Teilweise Wurzel ziehen · √48 = a · √3', afb: 'I', sach: false,
  afbGrund: 'Reproduzieren: Quadratzahl-Faktor 16 abspalten, Form vorgegeben.',
  frage: `Es gilt √48 = a · √3.\n\nBestimme a. ${NAT}`, r: 'W(48/3)',
  weg: '48 = 16 · 3, also √48 = √16 · √3 = 4 · √3.\na = {A}.',
  ke: [['faktor_ohne_wurzel', '48/3', 'Den Faktor 16 herausgezogen, ohne aus ihm die Wurzel zu ziehen.', 'Was ergibt (16 · √3)² – ist das 48?'],
    ['wurzel_halbiert', '48/3/2', '√16 als 16 : 2 = 8 genommen.', 'Was ergibt 8 · 8?'],
    ['falsche_groesse_beantwortet', 'W(48)', 'Den Näherungswert von √48 angegeben statt a.', 'Nach welcher Zahl ist gefragt: nach √48 oder nach dem Faktor vor √3?', 2]] });
def({ ...TW, ref: 'wurzel-teilweise-03', titel: 'Teilweise Wurzel ziehen · √200 = a · √2', afb: 'II', sach: false,
  afbGrund: 'Anwenden: großer Radikand, der Quadratzahl-Faktor 100 muss erst gefunden werden.',
  frage: `Es gilt √200 = a · √2.\n\nBestimme a. ${NAT}`, r: 'W(200/2)',
  weg: '200 = 100 · 2, also √200 = √100 · √2 = 10 · √2.\na = {A}.',
  ke: [['faktor_ohne_wurzel', '200/2', 'Den Faktor 100 herausgezogen, ohne aus ihm die Wurzel zu ziehen.', 'Was ergibt (100 · √2)² – ist das 200?'],
    ['falsche_groesse_beantwortet', 'W(200)', 'Den Näherungswert von √200 angegeben statt a.', 'Nach welcher Zahl ist gefragt: nach √200 oder nach dem Faktor vor √2?', 2]] });
def({ ...TW, ref: 'wurzel-teilweise-04', titel: 'Teilweise Wurzel ziehen · √18 · √6 = a · √3', afb: 'II', sach: false,
  afbGrund: 'Anwenden: erst das Produktgesetz, dann teilweise die Wurzel ziehen.',
  frage: `Es gilt √18 · √6 = a · √3.\n\nBestimme a. ${NAT}`, r: 'W(18*6/3)',
  weg: '√18 · √6 = √108.\n108 = 36 · 3, also √108 = √36 · √3 = 6 · √3.\na = {A}.',
  ke: [['faktor_ohne_wurzel', '18*6/3', 'Den Faktor 36 herausgezogen, ohne aus ihm die Wurzel zu ziehen.', 'Was ergibt (36 · √3)² – ist das 108?'],
    ['wurzel_halbiert', '18*6/3/2', '√36 als 36 : 2 = 18 genommen.', 'Was ergibt 18 · 18?'],
    ['falsche_groesse_beantwortet', 'W(18*6)', 'Den Näherungswert von √108 angegeben statt a.', 'Nach welcher Zahl ist gefragt: nach dem Produkt oder nach dem Faktor vor √3?', 2]] });
def({ ...TW, ref: 'wurzel-teilweise-05', titel: 'Teilweise Wurzel ziehen · Spielplatz mit 180 m²', afb: 'II', sach: true,
  afbGrund: 'Anwenden im Sachkontext: Seitenlänge als Wurzel der Fläche, dann teilweise die Wurzel ziehen.',
  frage: `Ein quadratischer Spielplatz hat einen Flächeninhalt von 180 m². Seine Seitenlänge lässt sich exakt als a · √5 m schreiben.\n\nBestimme a. ${NAT}`, r: 'W(180/5)',
  weg: 'Seitenlänge = √180 m.\n180 = 36 · 5, also √180 = √36 · √5 = 6 · √5.\na = {A}.',
  ke: [['faktor_ohne_wurzel', '180/5', 'Den Faktor 36 herausgezogen, ohne aus ihm die Wurzel zu ziehen.', 'Was ergibt (36 · √5)² – ist das 180?'],
    ['wurzel_halbiert', '180/5/2', '√36 als 36 : 2 = 18 genommen.', 'Was ergibt 18 · 18?'],
    ['falsche_groesse_beantwortet', 'W(180)', 'Die Seitenlänge als Näherungswert angegeben statt a.', 'Nach welcher Zahl ist gefragt: nach der Seitenlänge oder nach dem Faktor vor √5?', 2]] });
def({ ...TW, ref: 'wurzel-teilweise-06', titel: 'Rückrichtung · 6 · √3 = √b', afb: 'III', sach: false,
  afbGrund: 'Problemlösen: Rückrichtung – den Faktor quadrieren und unter die Wurzel bringen.',
  frage: 'Es gilt 6 · √3 = √b.\n\nBestimme b. b ist eine natürliche Zahl. Gib b exakt an.', r: '6^2*3',
  weg: '6 = √36, also 6 · √3 = √36 · √3 = √(36 · 3) = √108.\nb = {A}.',
  ke: [['faktor_ohne_wurzel', '6*3', 'Den Faktor 6 unter die Wurzel gebracht, ohne ihn zu quadrieren: √18.', 'Was ergibt √18 ungefähr – ist das so viel wie 6 · √3?'],
    ['mal_exponent', '2*6*3', '6² als 2 · 6 = 12 gerechnet: √36.', 'Was ergibt 6 · 6?']] });

baueCharge({
  thema: 'wurzel',
  batch: 'k9-wurzel',
  source: 'edvance_k9_wurzel',
  idsPfad: 'docs/prefill/k9-wurzel-ids.json',
  kopf: [
    `K9-Rest, Thema wurzel — ${A.length} Aufgaben: je sechs zu zahl_wurzel_quadrat, _naeherung, _irrational, _gesetze und _teilweise.`,
    'Erzeugt von tools/vorlauf-build.mjs aus docs/prefill/k9-wurzel.json (Quelle: tools/k9-wurzel-charge.mjs) — nicht von Hand editieren.',
    '',
    'Einspiel-Reihenfolge: nach 20261003105852_substrat_k9_wurzel.sql (Knoten + Fehlbild-Slugs muessen stehen).',
  ],
  auswahl: 'Je Knoten vier reine Anwendung mit steigender Schwierigkeit und zwei mit Sachkontext oder Rückrichtung (Tischplatte, eingezäunter Platz, Beet, Teppich, Fliesen, Feld, Spielplatz; Rückrichtung 6·√3 = √b). Alle ohne Abbildung lösbar, Antworten sind Zahlen (kein √ als Eingabe). Jede Aufgabe nennt, ob exakt oder auf wie viele Stellen gerundet wird; exakter Textvergleich, alle gleichwertigen Schreibweisen in correct_answers.',
  aufgaben: A,
});
