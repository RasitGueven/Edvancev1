#!/usr/bin/env node
/**
 * k10-exp-charge.mjs — erzeugt docs/prefill/k10-exp.json (Charge-Format von vorlauf-build.mjs).
 *
 *   node tools/k10-exp-charge.mjs
 *
 * Lauf "K10-Rest", Thema exp (Exponentialfunktionen; KLP G9 NRW Fkt-10, Fkt-12, Ari-10, Ari-11).
 * Jeder Wert (richtig und falsch) wird ueber Ausdruecke der Bibliothek exakt gerechnet:
 * L(x) = ln (log c : log b ist von der Basis unabhaengig), H(b;x) = bˣ fuer gebrochene x.
 * Negative Hochzahlen als 1/2^3, negative Zahlen als (0-2). Jede Aufgabe nennt die Rundung.
 * Terme f(x) = a·bˣ werden ueber zwei MULTI_PART-Teile (a, b) abgefragt; Abbildungen nur als
 * Punkte (koordinatensystem kann keine Exponentialkurve), Koordinaten nicht im Text.
 * Die ids stehen in docs/prefill/k10-exp-ids.json: ein zweiter Lauf erzeugt dieselbe Charge.
 */

import { baueCharge, CLUSTER } from './k10-rest-lib.mjs';

const BASIS = {
  inhalt: 'funktionen', cluster: CLUSTER.algebra, stoff: 10,
  stoffGrund: 'Stoffanker Klasse 10: KLP G9 NRW, Zweite Stufe, Fkt-10/Fkt-12 (exponentielles Wachstum, Exponentialfunktionen) und Ari-10/Ari-11 (Exponentialgleichungen); alle 25 Kölner Schulpläne legen das Thema in Klasse 10.',
  clusterGrund: 'Algebra & Funktionen wie lineare und quadratische Funktionen im Bestand.',
  inhaltGrund: 'Inhaltsfeld Funktionen (exponentielle Zu- und Abnahme, f(x) = a·bˣ).',
};
const EXAKT = 'Gib das Ergebnis exakt an.';
const R2 = 'Runde auf zwei Stellen nach dem Komma.';
const ALT = (namen) => `Koordinatensystem mit Gitter und den Punkten ${namen}.`;

const A = [];
const def = (o) => A.push({ ...BASIS, ...o });

// ─── fkt_exp_wachstum (Tiefe 10) ───
const WA = { skill: 'fkt_exp_wachstum' };
def({ ...WA, ref: 'exp-wachstum-01', titel: 'Wachstumsfaktor · Zunahme um 4 %', afb: 'I', sach: false,
  afbGrund: 'Reproduzieren: Wachstumsfaktor q = 1 + p/100 aus einem ganzzahligen Prozentsatz bilden.',
  frage: `Ein Bestand nimmt in jedem Jahr um 4 % zu.\n\nMit welchem Faktor wird der Bestand jedes Jahr multipliziert? ${EXAKT}`,
  r: '1+4/100', n: 'exakt',
  weg: 'Zunahme um 4 %: zum Ganzen (100 % = 1) kommen 4 % = 0,04 dazu.\nq = 1 + 0,04 = {A}.',
  ke: [['wachstumsfaktor_falsch', '1+4/10', 'Den Prozentsatz als Zehntel angehängt: 1,4 statt 1,04.', 'Wie viel ist 4 % als Dezimalzahl – 0,4 oder 0,04?'],
    ['wachstumsfaktor_falsch', '4/100', 'Nur den Zuwachs 0,04 angegeben, die 1 für den alten Bestand fehlt.', 'Was passiert mit dem Bestand, wenn du ihn mit 0,04 multiplizierst?']] });
def({ ...WA, ref: 'exp-wachstum-02', titel: 'Abnahmefaktor · Abnahme um 15 %', afb: 'I', sach: false,
  afbGrund: 'Reproduzieren: Faktor q = 1 − p/100 bei prozentualer Abnahme bilden.',
  frage: `Ein Bestand nimmt in jedem Jahr um 15 % ab.\n\nMit welchem Faktor wird der Bestand jedes Jahr multipliziert? ${EXAKT}`,
  r: '1-15/100', n: 'exakt',
  weg: 'Abnahme um 15 %: Vom Ganzen (100 %) bleiben 100 % − 15 % = 85 % übrig.\nq = 1 − 0,15 = {A}.',
  ke: [['abnahmefaktor_falsch', '15/100', 'Den Anteil genommen, der wegfällt: 0,15 statt 0,85.', 'Wie viel Prozent des Bestands sind nach einem Jahr noch da?'],
    ['abnahmefaktor_falsch', '1+15/100', 'Die 15 % zum Ganzen addiert, obwohl der Bestand abnimmt: 1,15.', 'Wird der Bestand größer oder kleiner, wenn du mit 1,15 multiplizierst?']] });
def({ ...WA, ref: 'exp-wachstum-03', titel: 'Fortschreiben · 500 bei 6 % Zunahme, 4 Schritte', afb: 'II', sach: false,
  afbGrund: 'Anwenden: Wachstumsfaktor bilden und als Potenz über mehrere Schritte anwenden.',
  frage: `Eine Größe hat den Anfangswert 500. Sie nimmt in jedem Schritt um 6 % zu.\n\nWelchen Wert hat sie nach 4 Schritten? ${R2}`,
  r: '500*1.06^4', n: 2,
  weg: 'Wachstumsfaktor q = 1,06.\nNach 4 Schritten: 500 · 1,06⁴ ≈ 500 · 1,26248 ≈ {A}.',
  ke: [['prozente_addiert', '500+4*500*6/100', 'Jeden Schritt 6 % vom Anfangswert addiert: 500 + 4 · 30 = 620.', 'Wovon werden im zweiten Schritt die 6 % berechnet?', 'exakt'],
    ['mal_exponent', '500*1.06*4', '1,06⁴ als 1,06 · 4 gerechnet.', 'Was bedeutet die kleine 4 an 1,06?', 'exakt'],
    ['wachstumsfaktor_falsch', '500*1.6^4', 'Mit dem Faktor 1,6 statt 1,06 gerechnet.', 'Wie viel ist 6 % als Dezimalzahl?']] });
def({ ...WA, ref: 'exp-wachstum-04', titel: 'Exponentiell fortsetzen · 40, 60, 90, …', afb: 'II', sach: false,
  afbGrund: 'Anwenden: konstanten Quotienten statt konstanter Differenz erkennen und zwei Schritte weiterrechnen.',
  frage: `Die Werte 40, 60, 90, … wachsen exponentiell: Von einem Wert zum nächsten wird immer mit demselben Faktor multipliziert.\n\nWelcher Wert steht zwei Schritte nach 90? ${EXAKT}`,
  r: '90*(60/40)^2', n: 'exakt',
  weg: 'Faktor: 60 : 40 = 1,5 (auch 90 : 60 = 1,5).\nNächster Wert: 90 · 1,5 = 135, danach 135 · 1,5 = {A}.',
  ke: [['linear_statt_exponentiell', '90+2*(90-60)', 'Linear fortgeschrieben: zweimal 30 addiert, 90 + 60 = 150.', 'Ist der Abstand 40 → 60 derselbe wie 60 → 90 – oder bleibt etwas anderes gleich?'],
    ['mal_exponent', '90*(60/40)*2', '1,5² als 1,5 · 2 gerechnet: 90 · 3 = 270.', 'Was bedeutet es, zweimal hintereinander mit 1,5 zu multiplizieren?']] });
def({ ...WA, ref: 'exp-wachstum-05', titel: 'Prozentsatz aus Faktor · Wert einer Maschine, Faktor 0,88', einheit: '%', afb: 'II', sach: true,
  afbGrund: 'Anwenden in der Rückrichtung: aus dem Abnahmefaktor die prozentuale Abnahme ablesen.',
  frage: `Der Wert einer Maschine wird jedes Jahr mit dem Faktor 0,88 multipliziert.\n\nUm wie viel Prozent nimmt der Wert jedes Jahr ab? ${EXAKT}`,
  r: '(1-0.88)*100', n: 'exakt',
  weg: 'Faktor 0,88 heißt: 88 % des Werts bleiben übrig.\nAbnahme: 100 % − 88 % = {A} %.',
  ke: [['rate_aus_faktor_falsch', '0.88*100', 'Den Faktor 0,88 als 88 % Abnahme gelesen.', 'Wie viel Prozent des Werts sind nach einem Jahr noch da – und wie viel fehlen?']] });
def({ ...WA, ref: 'exp-wachstum-06', titel: 'Zinseszins gegen einfache Zinsen · 2000 € zu 3 %, 5 Jahre', einheit: '€', afb: 'III', sach: true,
  afbGrund: 'Problemlösen: exponentielles und lineares Fortschreiben selbst aufstellen und den Unterschied bilden.',
  frage: `Ein Kapital von 2000 € wird 5 Jahre lang mit 3 % Zinseszins verzinst: Die Zinsen werden jedes Jahr mitverzinst. Zum Vergleich gibt es bei einer anderen Anlage jedes Jahr nur 3 % des Startkapitals als Zinsen, die nicht mitverzinst werden.\n\nUm wie viel Euro ist das Kapital nach 5 Jahren mit Zinseszins größer als bei der anderen Anlage? ${R2}`,
  r: '2000*1.03^5-(2000+5*2000*3/100)', n: 2,
  weg: 'Mit Zinseszins: 2000 € · 1,03⁵ ≈ 2318,55 €.\nOhne Zinseszins: jedes Jahr 60 €, also 2000 € + 5 · 60 € = 2300 €.\nUnterschied: 2318,55 € − 2300 € ≈ {A} €.\n(Erst am Ende runden.)',
  ke: [['falsche_groesse_beantwortet', '2000*1.03^5', 'Das Endkapital mit Zinseszins angegeben statt des Unterschieds.', 'Gefragt ist, um wie viel es mehr ist – was fehlt noch?'],
    ['falsche_groesse_beantwortet', '2000*1.03^5-2000', 'Die Zinsen mit Zinseszins angegeben statt des Unterschieds zur anderen Anlage.', 'Womit sollst du das Kapital mit Zinseszins vergleichen?'],
    ['wachstumsfaktor_falsch', '2000*1.3^5-(2000+5*2000*3/100)', 'Mit dem Faktor 1,3 statt 1,03 gerechnet.', 'Wie viel ist 3 % als Dezimalzahl?']] });

// ─── fkt_exp_term (Tiefe 11) ───
const TE = { skill: 'fkt_exp_term' };
def({ ...TE, ref: 'exp-term-01', titel: 'Term lesen · f(x) = 250 · 1,08ˣ', afb: 'I', sach: false,
  afbGrund: 'Reproduzieren: Anfangswert und Wachstumsrate aus dem Funktionsterm ablesen.',
  frage: `Gegeben ist die Exponentialfunktion f(x) = 250 · 1,08ˣ.\n\nGib den Anfangswert an und um wie viel Prozent der Funktionswert zunimmt, wenn x um 1 größer wird. ${EXAKT}`,
  teile: [{ prompt: 'Anfangswert f(0)', r: '250', n: 'exakt',
    ke: [['anfangswert_faktor_vertauscht', '1.08', 'Den Wachstumsfaktor 1,08 als Anfangswert genommen.', 'Welchen Wert hat f(x) für x = 0?']] },
  { prompt: 'Zunahme in Prozent, wenn x um 1 größer wird', r: '(1.08-1)*100', n: 'exakt',
    ke: [['rate_aus_faktor_falsch', '1.08*100', 'Den Faktor 1,08 als 108 % Zunahme gelesen.', 'Wenn 108 % des alten Werts da sind – um wie viel Prozent ist er gewachsen?']] }],
  weg: 'f(x) = a · bˣ: a ist der Anfangswert, b der Wachstumsfaktor.\nf(0) = 250 · 1,08⁰ = {1}.\nb = 1,08 = 108 %, also Zunahme um 108 % − 100 % = {2} %.' });
def({ ...TE, ref: 'exp-term-02', titel: 'Term aufstellen · Anfangswert 200, Abnahme 10 %', afb: 'I', sach: false,
  afbGrund: 'Reproduzieren: a und b aus Anfangswert und prozentualer Abnahme bestimmen.',
  frage: `Eine Exponentialfunktion f(x) = a · bˣ hat an der Stelle x = 0 den Wert 200. Wenn x um 1 größer wird, nimmt der Funktionswert jeweils um 10 % ab.\n\nGib a und b an. ${EXAKT}`,
  teile: [{ prompt: 'a', r: '200', n: 'exakt',
    ke: [['anfangswert_faktor_vertauscht', '1-10/100', 'Anfangswert und Faktor vertauscht: a = 0,9.', 'Welche Zahl in a · bˣ ist der Wert bei x = 0?']] },
  { prompt: 'b', r: '1-10/100', n: 'exakt',
    ke: [['abnahmefaktor_falsch', '10/100', 'Den Anteil genommen, der wegfällt: b = 0,1.', 'Wie viel Prozent des Werts bleiben bei jedem Schritt übrig?'],
      ['abnahmefaktor_falsch', '1+10/100', 'Die 10 % addiert, obwohl der Wert abnimmt: b = 1,1.', 'Wird der Wert größer oder kleiner, wenn du mit 1,1 multiplizierst?'],
      ['anfangswert_faktor_vertauscht', '200', 'Anfangswert und Faktor vertauscht: b = 200.', 'Welche Zahl wird bei jedem Schritt erneut multipliziert?']] }],
  weg: 'f(0) = a · b⁰ = a, also a = {1}.\nAbnahme um 10 %: Es bleiben 90 %, also b = 1 − 0,1 = {2}.\nf(x) = 200 · 0,9ˣ.' });
def({ ...TE, ref: 'exp-term-03', titel: 'Funktionswert · f(−2) bei f(x) = 80 · 0,5ˣ', afb: 'II', sach: false,
  afbGrund: 'Anwenden: negative Hochzahl als Kehrwert deuten und mit dem Anfangswert multiplizieren.',
  frage: `Gegeben ist die Funktion f(x) = 80 · 0,5ˣ.\n\nBerechne f(−2). ${EXAKT}`,
  r: '80*1/0.5^2', n: 'exakt',
  weg: '0,5⁻² = 1 : 0,5² = 1 : 0,25 = 4.\nf(−2) = 80 · 4 = {A}.',
  ke: [['negativer_exponent_negativ', '80*(0-0.5^2)', 'Die negative Hochzahl als Minus vor dem Ergebnis gelesen: 0,5⁻² = −0,25.', 'Was bedeutet eine negative Hochzahl: ein negatives Ergebnis oder der Kehrwert?'],
    ['mal_exponent', '80*0.5*(0-2)', '0,5⁻² als 0,5 · (−2) gerechnet.', 'Was bedeutet die Hochzahl −2 an 0,5?']] });
def({ ...TE, ref: 'exp-term-04', titel: 'Punkte ablesen · f(3) aus zwei Punkten des Graphen', afb: 'II', sach: false,
  afbGrund: 'Anwenden: Anfangswert und Faktor aus zwei abgelesenen Punkten bestimmen, dann auswerten.',
  frage: `Die Punkte P und Q in der Abbildung liegen auf dem Graphen von f(x) = a · bˣ. P liegt auf der y-Achse. Beide Punkte haben ganzzahlige Koordinaten.\n\nLies ihre Koordinaten ab und berechne f(3). ${EXAKT}`,
  figur: { params: { x_min: -1, x_max: 4, y_min: -1, y_max: 8, punkte: [{ x: 0, y: 2, label: 'P' }, { x: 1, y: 6, label: 'Q' }] }, alt_text: ALT('P und Q') },
  r: '2*3^3', n: 'exakt',
  weg: 'Ablesen: P(0|2) und Q(1|6).\nP auf der y-Achse: a = f(0) = 2.\nQ: f(1) = 2 · b = 6, also b = 3.\nf(3) = 2 · 3³ = 2 · 27 = {A}.',
  ke: [['anfangswert_faktor_vertauscht', '3*2^3', 'Anfangswert und Faktor vertauscht: f(x) = 3 · 2ˣ.', 'Welcher der beiden Punkte zeigt den Wert bei x = 0?'],
    ['linear_statt_exponentiell', '2+3*(6-2)', 'Linear fortgeschrieben: bei jedem Schritt 4 addiert.', 'Wird bei f(x) = a · bˣ in jedem Schritt addiert oder multipliziert?'],
    ['mal_exponent', '2*3*3', '3³ als 3 · 3 gerechnet.', 'Was bedeutet die kleine 3 an der 3?']] });
def({ ...TE, ref: 'exp-term-05', titel: 'Term aus zwei Punkten · Abbildung, Punkte bei x = 1 und x = 3', afb: 'II', sach: false,
  afbGrund: 'Anwenden in der Rückrichtung: aus zwei Punkten den Faktor über zwei Schritte und daraus a bestimmen.',
  frage: `Die Punkte P und Q in der Abbildung liegen auf dem Graphen von f(x) = a · bˣ mit b > 0. Beide Punkte haben ganzzahlige Koordinaten.\n\nLies ihre Koordinaten ab und bestimme a und b. ${EXAKT}`,
  figur: { params: { x_min: -1, x_max: 4, y_min: -1, y_max: 13, punkte: [{ x: 1, y: 3, label: 'P' }, { x: 3, y: 12, label: 'Q' }] }, alt_text: ALT('P und Q') },
  teile: [{ prompt: 'a', r: '3/W(12/3)', n: 'exakt', bruch: true,
    ke: [['wurzel_vergessen', '3/(12/3)', 'b² = 4 als b genommen und deshalb a = 3 : 4 gerechnet.', 'Liegen zwischen P und Q ein oder zwei Schritte in x-Richtung?'],
      ['anfangswert_faktor_vertauscht', 'W(12/3)', 'Anfangswert und Faktor vertauscht: a = 2.', 'Welche Zahl in a · bˣ wird bei jedem Schritt erneut multipliziert?']] },
  { prompt: 'b', r: 'W(12/3)', n: 'exakt',
    ke: [['wurzel_vergessen', '12/3', 'b² = 4 ausgerechnet, aber die Wurzel nicht gezogen.', 'Von x = 1 bis x = 3 wird zweimal mit b multipliziert – was ist dann 12 : 3?'],
      ['linear_statt_exponentiell', '(12-3)/(3-1)', 'Wie bei einer Geraden die Steigung berechnet: 9 : 2.', 'Wird bei f(x) = a · bˣ in jedem Schritt addiert oder multipliziert?'],
      ['anfangswert_faktor_vertauscht', '3/W(12/3)', 'Anfangswert und Faktor vertauscht: b = 1,5.', 'Welche Zahl in a · bˣ ist der Wert bei x = 0?']] }],
  weg: 'Ablesen: P(1|3) und Q(3|12).\nVon x = 1 bis x = 3 wird zweimal mit b multipliziert: b² = 12 : 3 = 4, b = {2}.\nf(1) = a · 2 = 3, also a = 3 : 2 = {1}.\nf(x) = 1,5 · 2ˣ.' });
def({ ...TE, ref: 'exp-term-06', titel: 'Term aufstellen · Bakterien nach 2 und 4 Stunden', afb: 'III', sach: true,
  afbGrund: 'Problemlösen: aus zwei Messwerten den Faktor über zwei Schritte und den Anfangswert durch Zurückrechnen bestimmen.',
  frage: `In einer Bakterienkultur werden nach 2 Stunden 360 Bakterien und nach 4 Stunden 810 Bakterien gezählt. Die Anzahl wächst exponentiell und wird durch f(x) = a · bˣ beschrieben (x in Stunden seit Beginn der Beobachtung).\n\nBestimme a und b. ${EXAKT}`,
  teile: [{ prompt: 'a (Anzahl zu Beginn)', r: '360/(W(810/360))^2', n: 'exakt',
    ke: [['linear_statt_exponentiell', '360-(810-360)', 'Linear zurückgerechnet: 360 − 450 = −90.', 'Wird die Anzahl in jeder Stunde um denselben Betrag größer oder mit demselben Faktor?'],
      ['anfangswert_faktor_vertauscht', 'W(810/360)', 'Anfangswert und Faktor vertauscht: a = 1,5.', 'Welche Zahl in a · bˣ ist die Anzahl bei x = 0?']] },
  { prompt: 'b (Wachstumsfaktor pro Stunde)', r: 'W(810/360)', n: 'exakt',
    ke: [['wurzel_vergessen', '810/360', 'b² = 2,25 ausgerechnet, aber die Wurzel nicht gezogen.', 'Wie viele Stunden liegen zwischen den beiden Zählungen – und wie oft wird dabei mit b multipliziert?'],
      ['anfangswert_faktor_vertauscht', '360/(W(810/360))^2', 'Anfangswert und Faktor vertauscht: b = 160.', 'Welche Zahl in a · bˣ wird jede Stunde erneut multipliziert?']] }],
  weg: 'Von x = 2 bis x = 4 wird zweimal mit b multipliziert: b² = 810 : 360 = 2,25, b = {2}.\nZurückrechnen: f(2) = a · 1,5² = 360, also a = 360 : 2,25 = {1}.\nf(x) = 160 · 1,5ˣ.' });

// ─── fkt_exp_halbwert (Tiefe 11) ───
const HW = { skill: 'fkt_exp_halbwert' };
def({ ...HW, ref: 'exp-halbwert-01', titel: 'Halbwertszeit · 64 g, 5 Jahre, nach 15 Jahren', einheit: 'g', afb: 'I', sach: false,
  afbGrund: 'Reproduzieren: Anzahl der Halbwertszeiten bestimmen und entsprechend oft halbieren.',
  frage: `Ein Stoff hat eine Halbwertszeit von 5 Jahren. Zu Beginn sind 64 g vorhanden.\n\nWie viel Gramm sind nach 15 Jahren noch vorhanden? ${EXAKT}`,
  r: '64*H(0.5;15/5)', n: 'exakt',
  weg: '15 Jahre sind 15 : 5 = 3 Halbwertszeiten.\n64 g · 0,5³ = 64 g : 8 = {A} g.',
  ke: [['zeit_statt_perioden', '64*0.5^15', 'Die 15 Jahre direkt als Hochzahl genommen: 64 · 0,5¹⁵.', 'Wie oft halbiert sich die Menge in 15 Jahren, wenn sie sich alle 5 Jahre halbiert?'],
    ['mal_exponent', '64*0.5*3', '0,5³ als 0,5 · 3 gerechnet: 64 · 1,5 = 96.', 'Kann nach drei Halbierungen mehr übrig sein als am Anfang?']] });
def({ ...HW, ref: 'exp-halbwert-02', titel: 'Verdopplungszeit · 300, alle 4 Stunden, nach 12 Stunden', afb: 'I', sach: false,
  afbGrund: 'Reproduzieren: Anzahl der Verdopplungszeiten bestimmen und entsprechend oft verdoppeln.',
  frage: `Ein Bestand von 300 verdoppelt sich alle 4 Stunden.\n\nWie groß ist der Bestand nach 12 Stunden? ${EXAKT}`,
  r: '300*H(2;12/4)', n: 'exakt',
  weg: '12 Stunden sind 12 : 4 = 3 Verdopplungszeiten.\n300 · 2³ = 300 · 8 = {A}.',
  ke: [['zeit_statt_perioden', '300*2^12', 'Die 12 Stunden direkt als Hochzahl genommen: 300 · 2¹².', 'Wie oft verdoppelt sich der Bestand in 12 Stunden?'],
    ['linear_statt_exponentiell', '300+3*300', 'Bei jeder Verdopplungszeit nur 300 addiert: 300 + 3 · 300.', 'Was wird verdoppelt: der Anfangsbestand oder der jeweils aktuelle Bestand?'],
    ['mal_exponent', '300*2*3', '2³ als 2 · 3 gerechnet: 300 · 6.', 'Was ergibt 2 · 2 · 2?']] });
def({ ...HW, ref: 'exp-halbwert-03', titel: 'Zeit aus Menge · 400 mg auf 25 mg, Halbwertszeit 8 Tage', einheit: 'Tage', afb: 'II', sach: false,
  afbGrund: 'Anwenden: Verhältnis als Zweierpotenz erkennen, Anzahl der Halbwertszeiten in Zeit umrechnen.',
  frage: `Ein Stoff hat eine Halbwertszeit von 8 Tagen. Zu Beginn sind 400 mg vorhanden.\n\nNach wie vielen Tagen sind nur noch 25 mg vorhanden? ${EXAKT}`,
  r: '8*4', n: 'exakt',
  weg: '400 mg : 25 mg = 16 = 2⁴: Die Menge hat sich 4-mal halbiert (400 → 200 → 100 → 50 → 25).\n4 Halbwertszeiten: 4 · 8 Tage = {A} Tage.',
  ke: [['falsche_groesse_beantwortet', '4', 'Die Anzahl der Halbwertszeiten angegeben statt der Tage.', 'Gefragt sind Tage – wie lang dauert eine Halbwertszeit?']] });
def({ ...HW, ref: 'exp-halbwert-04', titel: 'Verdopplung durch Probieren · 12 % pro Jahr', einheit: 'Jahre', afb: 'II', sach: false,
  afbGrund: 'Anwenden: Potenzen des Wachstumsfaktors probieren (oder logarithmieren) und die erste ganze Zahl über der Grenze wählen.',
  frage: `Ein Bestand wächst in jedem Jahr um 12 %.\n\nGib die Anzahl der ganzen Jahre an, nach denen sich der Bestand erstmals mindestens verdoppelt hat.`,
  r: 'L(2)/L(1.12)', n: 'auf',
  weg: 'Gesucht ist das kleinste ganze n mit 1,12ⁿ ≥ 2.\n1,12⁶ ≈ 1,974 < 2, aber 1,12⁷ ≈ 2,211 ≥ 2.\n(Oder: log 2 : log 1,12 ≈ 6,12, also aufrunden.)\nNach {A} Jahren.',
  ke: [['prozente_addiert', '100/12', 'Jedes Jahr nur 12 % vom Anfangsbestand addiert: 100 % : 12 % ≈ 8,3, also 9 Jahre.', 'Wovon werden im zweiten Jahr die 12 % berechnet?', 'auf'],
    ['wachstumsfaktor_falsch', 'L(2)/L(1.2)', 'Mit dem Faktor 1,2 statt 1,12 gerechnet.', 'Wie viel ist 12 % als Dezimalzahl, und wie heißt dann der Faktor?', 'auf']] });
def({ ...HW, ref: 'exp-halbwert-05', titel: 'Halbwertszeit bestimmen · Medikament, 12,5 % nach 12 Stunden', einheit: 'h', afb: 'II', sach: true,
  afbGrund: 'Anwenden in der Rückrichtung: aus dem Restanteil die Anzahl der Halbierungen und daraus die Halbwertszeit bestimmen.',
  frage: `Ein Medikament wird im Körper abgebaut; die Menge halbiert sich immer in derselben Zeit. 12 Stunden nach der Einnahme sind noch 12,5 % der eingenommenen Menge im Körper.\n\nWie groß ist die Halbwertszeit in Stunden? ${EXAKT}`,
  r: '12/3', n: 'exakt',
  weg: '12,5 % = 0,125 = 1/8 = (1/2)³: In 12 Stunden hat sich die Menge 3-mal halbiert (100 % → 50 % → 25 % → 12,5 %).\nHalbwertszeit: 12 h : 3 = {A} h.',
  ke: [['falsche_groesse_beantwortet', '3', 'Die Anzahl der Halbierungen angegeben statt der Halbwertszeit.', 'Gefragt ist eine Zeit in Stunden – wie viele Stunden dauert eine Halbierung?'],
    ['linear_statt_exponentiell', '12*50/87.5', 'Linear gerechnet: 87,5 % Abbau in 12 Stunden, 50 % Abbau also in 12 · 50 : 87,5 Stunden.', 'Wird in jeder Stunde dieselbe Menge abgebaut oder derselbe Anteil?', 2]] });
def({ ...HW, ref: 'exp-halbwert-06', titel: 'Verdopplungszeit · Population 500, alle 3 Jahre, nach 10 Jahren', afb: 'III', sach: true,
  afbGrund: 'Problemlösen: nicht ganzzahlige Anzahl von Verdopplungszeiten als gebrochene Hochzahl einsetzen.',
  frage: `Eine Tierpopulation von 500 Tieren verdoppelt sich alle 3 Jahre.\n\nWie viele Tiere sind es nach 10 Jahren? Runde auf ganze Tiere.`,
  r: '500*H(2;10/3)', n: 0,
  weg: '10 Jahre sind 10 : 3 Verdopplungszeiten.\n500 · 2^(10/3) ≈ 500 · 10,0794 ≈ 5039,7.\nGerundet: {A} Tiere.\n(Die Hochzahl 10/3 nicht vorher runden.)',
  ke: [['zeit_statt_perioden', '500*2^10', 'Die 10 Jahre direkt als Hochzahl genommen: 500 · 2¹⁰.', 'Wie oft verdoppelt sich die Population in 10 Jahren, wenn sie sich alle 3 Jahre verdoppelt?'],
    ['linear_statt_exponentiell', '500+500*10/3', 'Linear gerechnet: alle 3 Jahre 500 Tiere dazu.', 'Was wird verdoppelt: die Anfangszahl oder die jeweils aktuelle Zahl?'],
    ['zu_frueh_gerundet', '500*H(2;3.33)', 'Die Hochzahl 10/3 vorher auf 3,33 gerundet.', 'Was passiert mit dem Ergebnis, wenn du 10/3 vor dem Potenzieren rundest?']] });

// ─── fkt_exp_gleichung (Tiefe 7) ───
const GL = { skill: 'fkt_exp_gleichung' };
def({ ...GL, ref: 'exp-gleichung-01', titel: 'Probieren · 3ˣ = 81', afb: 'I', sach: false,
  afbGrund: 'Reproduzieren: ganzzahlige Lösung durch Potenzen der Basis finden.',
  frage: `Löse die Gleichung 3ˣ = 81. ${EXAKT}`,
  r: '4', n: 'exakt',
  weg: 'Potenzen von 3: 3¹ = 3, 3² = 9, 3³ = 27, 3⁴ = 81.\nx = {A}.',
  ke: [['log_falsch_geteilt', '81/3', 'c durch b geteilt: 81 : 3 = 27.', 'Setze 27 ein: Ist 3²⁷ wirklich 81?']] });
def({ ...GL, ref: 'exp-gleichung-02', titel: 'Probieren mit negativer Lösung · 2ˣ = 1/8', bruch: true, afb: 'I', sach: false,
  afbGrund: 'Reproduzieren: Kehrwert einer Zweierpotenz als negative Hochzahl erkennen.',
  frage: `Löse die Gleichung 2ˣ = 1/8. ${EXAKT}`,
  r: '0-3', n: 'exakt',
  weg: '2³ = 8, also 1/8 = 1/2³ = 2⁻³.\nx = {A}.',
  ke: [['betrag_fehler', '3', 'Die Hochzahl ohne Minus angegeben: 2³ = 8, nicht 1/8.', 'Ist 2³ gleich 8 oder gleich 1/8?'],
    ['log_falsch_geteilt', '1/8/2', 'c durch b geteilt: 1/8 : 2 = 1/16.', 'Setze dein Ergebnis ein: Ergibt 2 hoch diese Zahl wirklich 1/8?']] });
def({ ...GL, ref: 'exp-gleichung-03', titel: 'Logarithmus · Bakterien verzwanzigfachen sich, 1,5ˣ = 20', afb: 'II', sach: true,
  afbGrund: 'Anwenden im Sachkontext: Gleichung bˣ = c mit x = log c : log b lösen und runden.',
  frage: `Eine Bakterienzahl wächst jede Stunde mit dem Faktor 1,5. Nach x Stunden hat sie sich verzwanzigfacht; dafür gilt 1,5ˣ = 20.\n\nBestimme x mit dem Logarithmus. ${R2}`,
  r: 'L(20)/L(1.5)', n: 2,
  weg: 'x = log 20 : log 1,5 ≈ 1,30103 : 0,17609 ≈ {A}.\nNach etwa {A} Stunden.',
  ke: [['log_falsch_geteilt', '20/1.5', 'c durch b geteilt statt log c durch log b: 20 : 1,5.', 'Setze dein Ergebnis ein: Ist 1,5 hoch diese Zahl wirklich 20?'],
    ['umgekehrt_geteilt', 'L(1.5)/L(20)', 'Umgekehrt geteilt: log 1,5 : log 20.', 'Welcher Logarithmus gehört in den Zähler – der von c oder der von b?']] });
def({ ...GL, ref: 'exp-gleichung-04', titel: 'Logarithmus · 2,5 · 1,04ˣ = 4', afb: 'II', sach: false,
  afbGrund: 'Anwenden: erst durch den Vorfaktor teilen, dann logarithmieren und runden.',
  frage: `Löse die Gleichung 2,5 · 1,04ˣ = 4. ${R2}`,
  r: 'L(4/2.5)/L(1.04)', n: 2,
  weg: 'Durch 2,5 teilen: 1,04ˣ = 4 : 2,5 = 1,6.\nx = log 1,6 : log 1,04 ≈ 0,20412 : 0,01703 ≈ {A}.',
  ke: [['vorrang_ignoriert', 'L(4)/L(2.5*1.04)', 'Erst 2,5 · 1,04 = 2,6 gerechnet und dann 2,6ˣ = 4 gelöst.', 'Wird in 2,5 · 1,04ˣ zuerst potenziert oder zuerst multipliziert?'],
    ['log_falsch_geteilt', '4/2.5/1.04', 'Nach dem Teilen c durch b geteilt: 1,6 : 1,04.', 'Setze dein Ergebnis ein: Ist 1,04 hoch diese Zahl wirklich 1,6?']] });
def({ ...GL, ref: 'exp-gleichung-05', titel: 'Rückrichtung · 2ˣ = c hat die Lösung x = −4', bruch: true, afb: 'II', sach: false,
  afbGrund: 'Anwenden in der Rückrichtung: aus der Lösung den Wert c als Potenz mit negativer Hochzahl berechnen.',
  frage: `Die Gleichung 2ˣ = c hat die Lösung x = −4.\n\nWie groß ist c? ${EXAKT} Du kannst auch einen Bruch eingeben.`,
  r: '1/2^4', n: 'exakt',
  weg: 'c = 2⁻⁴ = 1 : 2⁴ = 1/16 = {A}.',
  ke: [['negativer_exponent_negativ', '0-2^4', 'Die negative Hochzahl als Minus vor dem Ergebnis gelesen: 2⁻⁴ = −16.', 'Kann eine Potenz von 2 negativ sein?'],
    ['mal_exponent', '2*(0-4)', '2⁻⁴ als 2 · (−4) gerechnet.', 'Was bedeutet die Hochzahl −4 an der 2?']] });
def({ ...GL, ref: 'exp-gleichung-06', titel: 'Erst teilen, dann probieren · 3 · 2ˣ = 3/32', bruch: true, afb: 'III', sach: false,
  afbGrund: 'Problemlösen: Vorfaktor abspalten, Bruch als Zweierpotenz mit negativer Hochzahl erkennen.',
  frage: `Löse die Gleichung 3 · 2ˣ = 3/32. ${EXAKT}`,
  r: '0-5', n: 'exakt',
  weg: 'Durch 3 teilen: 2ˣ = 1/32.\n2⁵ = 32, also 1/32 = 2⁻⁵.\nx = {A}.',
  ke: [['betrag_fehler', '5', 'Die Hochzahl ohne Minus angegeben: 2⁵ = 32, nicht 1/32.', 'Ist 2⁵ gleich 32 oder gleich 1/32?'],
    ['vorrang_ignoriert', 'L(3/32)/L(3*2)', 'Erst 3 · 2 = 6 gerechnet und dann 6ˣ = 3/32 gelöst.', 'Wird in 3 · 2ˣ zuerst potenziert oder zuerst multipliziert?', 2],
    ['log_falsch_geteilt', '1/32/2', 'Nach dem Teilen c durch b geteilt: 1/32 : 2.', 'Setze dein Ergebnis ein: Ergibt 2 hoch diese Zahl wirklich 1/32?']] });

// ─── fkt_exp_anwendung (Tiefe 12) ───
const AN = { skill: 'fkt_exp_anwendung', sach: true };
def({ ...AN, ref: 'exp-anwendung-01', titel: 'Kapital · 1000 € zu 5 %, erstmals mindestens 1500 €', einheit: 'Jahre', afb: 'I', n: 'auf',
  afbGrund: 'Reproduzieren: Zinseszins-Gleichung aufstellen und die kleinste ganze Jahreszahl über der Grenze bestimmen.',
  frage: `Ein Kapital von 1000 € wird mit 5 % pro Jahr verzinst; die Zinsen werden mitverzinst.\n\nGib die Anzahl der ganzen Jahre an, nach denen das Kapital erstmals mindestens 1500 € beträgt.`,
  r: 'L(1500/1000)/L(1.05)',
  weg: '1000 · 1,05ⁿ ≥ 1500, also 1,05ⁿ ≥ 1,5.\nlog 1,5 : log 1,05 ≈ 8,31; ganze Jahre: aufrunden.\nProbe: 1,05⁸ ≈ 1,477 < 1,5 und 1,05⁹ ≈ 1,551 ≥ 1,5.\nNach {A} Jahren.',
  ke: [['prozente_addiert', '(1500-1000)/(1000*5/100)', 'Jedes Jahr nur 50 € (5 % vom Startkapital) gerechnet: 500 : 50 = 10.', 'Wovon werden im zweiten Jahr die 5 % berechnet?', 'exakt'],
    ['wachstumsfaktor_falsch', 'L(1500/1000)/L(1.5)', 'Mit dem Faktor 1,5 statt 1,05 gerechnet.', 'Wie viel ist 5 % als Dezimalzahl, und wie heißt dann der Faktor?']] });
def({ ...AN, ref: 'exp-anwendung-02', titel: 'Abbau · 80 mg, 15 % pro Stunde, höchstens 20 mg', einheit: 'h', afb: 'I', n: 'auf',
  afbGrund: 'Reproduzieren: Abnahmefaktor bilden, Gleichung lösen und auf ganze Stunden aufrunden.',
  frage: `Von einem Stoff sind zu Beginn 80 mg im Blut. Die Menge nimmt jede Stunde um 15 % ab.\n\nGib die Anzahl der ganzen Stunden an, nach denen erstmals höchstens 20 mg im Blut sind.`,
  r: 'L(20/80)/L(1-15/100)',
  weg: '80 · 0,85ⁿ ≤ 20, also 0,85ⁿ ≤ 0,25.\nlog 0,25 : log 0,85 ≈ 8,53; ganze Stunden: aufrunden.\nProbe: 0,85⁸ ≈ 0,272 > 0,25 und 0,85⁹ ≈ 0,232 ≤ 0,25.\nNach {A} Stunden.',
  ke: [['abnahmefaktor_falsch', 'L(20/80)/L(15/100)', 'Mit dem Faktor 0,15 statt 0,85 gerechnet.', 'Wie viel Prozent der Menge sind nach einer Stunde noch da?'],
    ['prozente_addiert', '(80-20)/(80*15/100)', 'Jede Stunde 15 % der Anfangsmenge (12 mg) abgezogen: 60 : 12 = 5.', 'Wovon werden in der zweiten Stunde die 15 % berechnet?', 'exakt']] });
def({ ...AN, ref: 'exp-anwendung-03', titel: 'Bestand · Fische, jedes Jahr auf 80 %, unter 500', einheit: 'Jahre', afb: 'II', n: 'auf',
  afbGrund: 'Anwenden: „auf 80 %" als Faktor 0,8 deuten, Gleichung lösen, auf ganze Jahre aufrunden.',
  frage: `In einem See leben 2000 Fische. Der Bestand sinkt jedes Jahr auf 80 % des Vorjahres.\n\nGib die Anzahl der ganzen Jahre an, nach denen erstmals weniger als 500 Fische im See leben.`,
  r: 'L(500/2000)/L(0.8)',
  weg: '2000 · 0,8ⁿ < 500, also 0,8ⁿ < 0,25.\nlog 0,25 : log 0,8 ≈ 6,21; ganze Jahre: aufrunden.\nProbe: 0,8⁶ ≈ 0,262 ≥ 0,25 und 0,8⁷ ≈ 0,210 < 0,25.\nNach {A} Jahren.',
  ke: [['rate_aus_faktor_falsch', 'L(500/2000)/L(0.2)', '„Auf 80 %" als Abnahme um 80 % gelesen und mit dem Faktor 0,2 gerechnet.', 'Heißt „sinkt auf 80 %", dass 80 % übrig bleiben oder dass 80 % wegfallen?'],
    ['linear_statt_exponentiell', '(2000-500)/(2000-0.8*2000)', 'Jedes Jahr 400 Fische abgezogen: 1500 : 400 = 3,75, also 4 Jahre.', 'Sinkt der Bestand jedes Jahr um dieselbe Anzahl oder auf denselben Anteil?', 'auf']] });
def({ ...AN, ref: 'exp-anwendung-04', titel: 'Zerfall · Halbwertszeit 6 Stunden, unter 10 %', einheit: 'h', afb: 'II', n: 'auf',
  afbGrund: 'Anwenden: Zeit über die Halbwertszeit in die Hochzahl einbauen, logarithmieren und aufrunden.',
  frage: `Ein radioaktiver Stoff hat eine Halbwertszeit von 6 Stunden.\n\nGib die Anzahl der ganzen Stunden an, nach denen erstmals weniger als 10 % der Anfangsmenge vorhanden sind.`,
  r: '6*L(0.1)/L(0.5)',
  weg: 'Nach t Stunden ist der Anteil 0,5^(t/6).\n0,5^(t/6) < 0,1 ergibt t/6 > log 0,1 : log 0,5 ≈ 3,32, also t > 6 · 3,32 ≈ 19,93.\nGanze Stunden: aufrunden, nach {A} Stunden.',
  ke: [['zeit_statt_perioden', 'L(0.1)/L(0.5)', 'Die Stunden direkt als Hochzahl genommen: 0,5ᵗ < 0,1.', 'Halbiert sich die Menge jede Stunde oder alle 6 Stunden?'],
    ['linear_statt_exponentiell', '6*0.9/0.5', 'Linear gerechnet: alle 6 Stunden 50 % der Anfangsmenge weg, für 90 % also 10,8 Stunden.', 'Wird in jeder Halbwertszeit dieselbe Menge abgebaut oder derselbe Anteil?']] });
def({ ...AN, ref: 'exp-anwendung-05', titel: 'Einwohner · Gemeinde 8000, 1,5 % pro Jahr, Jahreszahl', afb: 'II', n: 'auf',
  afbGrund: 'Anwenden: Zeitpunkt berechnen und als Jahreszahl angeben (Anzahl der Jahre zum Startjahr addieren).',
  frage: `Am Ende des Jahres 2020 hat eine Gemeinde 8000 Einwohner. Die Einwohnerzahl wächst jedes Jahr um 1,5 %.\n\nAm Ende welchen Jahres hat die Gemeinde erstmals mehr als 9000 Einwohner? Rechne mit ganzen Jahren und gib die Jahreszahl an.`,
  r: '2020+L(9000/8000)/L(1.015)',
  weg: '8000 · 1,015ⁿ > 9000, also 1,015ⁿ > 1,125.\nlog 1,125 : log 1,015 ≈ 7,91; ganze Jahre: n = 8.\nProbe: 1,015⁷ ≈ 1,110 < 1,125 und 1,015⁸ ≈ 1,126 > 1,125.\n2020 + 8 = {A}.',
  ke: [['falsche_groesse_beantwortet', 'L(9000/8000)/L(1.015)', 'Die Anzahl der Jahre angegeben statt der Jahreszahl.', 'Gefragt ist ein Jahr – in welchem Jahr ist das?'],
    ['prozente_addiert', '2020+(9000-8000)/(8000*1.5/100)', 'Jedes Jahr nur 1,5 % der Anfangszahl (120 Einwohner) addiert: 1000 : 120 ≈ 8,3, also 9 Jahre.', 'Wovon werden im zweiten Jahr die 1,5 % berechnet?']] });
def({ ...AN, ref: 'exp-anwendung-06', titel: 'Zwei Anlagen · 2000 € zu 8 % überholt 5000 € zu 3 %', einheit: 'Jahre', afb: 'III', n: 'auf',
  afbGrund: 'Problemlösen: zwei exponentielle Modelle gleichsetzen, durch Umformen auf bˣ = c bringen, logarithmieren und aufrunden.',
  frage: `Anlage A: 2000 € werden mit 8 % pro Jahr verzinst. Anlage B: 5000 € werden mit 3 % pro Jahr verzinst. Bei beiden werden die Zinsen mitverzinst.\n\nGib die Anzahl der ganzen Jahre an, nach denen Anlage A erstmals mehr Geld enthält als Anlage B.`,
  r: 'L(5000/2000)/L(1.08/1.03)',
  weg: '2000 · 1,08ⁿ > 5000 · 1,03ⁿ, also (1,08 : 1,03)ⁿ > 5000 : 2000 = 2,5.\nn > log 2,5 : log(1,08 : 1,03) ≈ 0,39794 : 0,02059 ≈ 19,33.\nGanze Jahre: aufrunden, nach {A} Jahren.\n(Den Quotienten 1,08 : 1,03 nicht vorher runden.)',
  ke: [['zu_frueh_gerundet', 'L(2.5)/L(1.05)', 'Den Quotienten 1,08 : 1,03 ≈ 1,0485 auf 1,05 gerundet.', 'Was passiert mit dem Ergebnis, wenn du den Faktor vor dem Logarithmieren rundest?'],
    ['prozente_addiert', '(5000-2000)/(2000*8/100-5000*3/100)+1', 'Jedes Jahr gleiche Zinsen gerechnet: A + 160 €, B + 150 €, also erst nach 301 Jahren.', 'Bleiben die Zinsen jedes Jahr gleich, wenn sie mitverzinst werden?', 'exakt']] });

// ── Charge ─────────────────────────────────────────────────────────────────────
baueCharge({
  thema: 'exp',
  batch: 'k10-exp',
  source: 'edvance_k10_exp',
  idsPfad: 'docs/prefill/k10-exp-ids.json',
  kopf: [
    `K10-Rest, Thema exp — ${A.length} Aufgaben: je sechs zu fkt_exp_wachstum, _term, _halbwert, _gleichung und _anwendung.`,
    'Erzeugt von tools/vorlauf-build.mjs aus docs/prefill/k10-exp.json (Quelle: tools/k10-exp-charge.mjs) — nicht von Hand editieren.',
    '',
    'Einspiel-Reihenfolge: nach 20261003121328_substrat_k10_exp.sql (Knoten + Fehlbild-Slugs muessen stehen).',
  ],
  auswahl: 'Je Knoten vier reine Anwendung mit steigender Schwierigkeit und zwei mit Sachkontext oder Rückrichtung (Maschine, Zinseszins, Bakterien, Medikament, Tierpopulation, Fische, Zerfall, Gemeinde, zwei Anlagen). Terme f(x) = a·bˣ über zwei Teile a und b (MULTI_PART). Zwei Term-Aufgaben mit Abbildung (Koordinatensystem, nur Punkte des Graphen ablesen), alle übrigen ohne Abbildung lösbar. Jede Aufgabe nennt die Rundung; Logarithmen und gebrochene Hochzahlen auf 60 Stellen nachgerechnet.',
  aufgaben: A,
});
