/**
 * k8-stoch-aufgaben.mjs — die 30 Aufgaben des Laufs K8-Rest, Thema Daten und Wahrscheinlichkeit.
 * Gebaut wird die Charge von tools/k8-stoch-charge.mjs; dort wird jede Zahl exakt nachgerechnet
 * und jede Schreibweise (Bruch gekürzt/ungekürzt, Dezimal, Prozent) erzeugt.
 *
 * Felder je Aufgabe:
 *   ref, skill, titel, frage, einheit?, afb, afbGrund, sach (Sachkontext: +30 s), prozess,
 *   art ('p' = Wahrscheinlichkeit, Bruch/Dezimal/Prozent; 'z' = Zahl), antwort, r (Rechnung),
 *   roh (Nenner, unter denen der ungekürzte Bruch entsteht; nur art 'p'), weg,
 *   ke: [falscher Wert, Slug, Rechnung, Fehlertext, sokratische Frage, roh?]
 * Rechnungen: Punkt als Dezimaltrenner, "/" für Brüche (exakt, prefill-rechnen).
 */

export const A = [];
const def = (o) => A.push(o);
const PB = 'Gib die Wahrscheinlichkeit als Bruch an.';
const PA = 'Gib die Wahrscheinlichkeit als Bruch, als Dezimalzahl oder in Prozent an.';

// ─── stoch_kenngroessen (Tiefe 4) ────────────────────────────────────────────
// Quartil-Reihen so gewählt, dass alle Schul-Definitionen denselben Wert liefern
// (gleiche Werte an den Rängen n/4 und n/4 + 1 bzw. 3n/4 und 3n/4 + 1).
const K = { skill: 'stoch_kenngroessen', art: 'z' };
def({ ...K, ref: 'stoch-kenngroessen-01', titel: 'Median · ungerade Anzahl',
  frage: 'Gegeben ist die Datenreihe\n8, 3, 11, 5, 18\n\nBestimme den Median.',
  afb: 'I', afbGrund: 'Reproduzieren: fünf Werte ordnen und den mittleren ablesen.',
  sach: false, prozess: 'Operieren', antwort: '8', r: '8',
  weg: 'Geordnet: 3, 5, 8, 11, 18.\nBei fünf Werten steht der Median an der dritten Stelle: Median = 8.',
  ke: [
    ['11', 'median_ohne_sortieren', '11', 'Den mittleren Wert der ungeordneten Liste genommen: 11.', 'Stehen die Werte schon der Größe nach da?'],
    ['9', 'mittelwert_statt_median', '(8+3+11+5+18)/5', 'Den Durchschnitt berechnet: 45 : 5 = 9.', 'Ist nach dem Wert in der Mitte gefragt oder nach dem Durchschnitt?'],
  ] });
def({ ...K, ref: 'stoch-kenngroessen-02', titel: 'Median · gerade Anzahl',
  frage: 'Gegeben ist die Datenreihe\n14, 9, 21, 12, 17, 11\n\nBestimme den Median.',
  afb: 'I', afbGrund: 'Reproduzieren: sechs Werte ordnen, Mittelwert der beiden mittleren Werte.',
  sach: false, prozess: 'Operieren', antwort: '13', r: '(12+14)/2',
  weg: 'Geordnet: 9, 11, 12, 14, 17, 21.\nBei sechs Werten liegt der Median zwischen dem dritten und vierten Wert: (12 + 14) : 2 = 13.',
  ke: [
    ['16,5', 'median_ohne_sortieren', '(21+12)/2', 'Die beiden mittleren Werte der ungeordneten Liste gemittelt: (21 + 12) : 2 = 16,5.', 'Hast du die Werte vor dem Abzählen der Größe nach geordnet?'],
    ['14', 'mittelwert_statt_median', '(14+9+21+12+17+11)/6', 'Den Durchschnitt berechnet: 84 : 6 = 14.', 'Ist nach dem Wert in der Mitte gefragt oder nach dem Durchschnitt?'],
  ] });
def({ ...K, ref: 'stoch-kenngroessen-03', titel: 'Unteres Quartil · acht Werte',
  frage: 'Gegeben ist die Datenreihe\n11, 6, 18, 4, 15, 9, 6, 15\n\nBestimme das untere Quartil.',
  afb: 'II', afbGrund: 'Anwenden: ordnen, Median bestimmen, dann den Median der unteren Hälfte.',
  sach: false, prozess: 'Operieren', antwort: '6', r: '(6+6)/2',
  weg: 'Geordnet: 4, 6, 6, 9, 11, 15, 15, 18.\nUntere Hälfte: 4, 6, 6, 9. Ihr Median ist (6 + 6) : 2 = 6.\nDas untere Quartil ist 6.',
  ke: [
    ['10', 'falsche_groesse_beantwortet', '(9+11)/2', 'Den Median der ganzen Reihe statt des unteren Quartils angegeben.', 'Teilt dein Wert die Daten in zwei Hälften oder ein Viertel ab?'],
    ['15', 'falsche_groesse_beantwortet', '(15+15)/2', 'Das obere statt des unteren Quartils angegeben.', 'Liegt das untere Quartil bei den kleinen oder bei den großen Werten?'],
    ['12', 'median_ohne_sortieren', '(6+18)/2', 'Die ersten vier Werte ungeordnet genommen und deren Mitte gebildet: (6 + 18) : 2 = 12.', 'Hast du die Werte vor dem Halbieren der Größe nach geordnet?'],
  ] });
def({ ...K, ref: 'stoch-kenngroessen-04', titel: 'Oberes Quartil · neun Werte',
  frage: 'Gegeben ist die Datenreihe\n10, 5, 2, 12, 8, 3, 10, 7, 5\n\nBestimme das obere Quartil.',
  afb: 'II', afbGrund: 'Anwenden: ungerade Anzahl ordnen, Median, dann Median der oberen Hälfte.',
  sach: false, prozess: 'Operieren', antwort: '10', r: '(10+10)/2',
  weg: 'Geordnet: 2, 3, 5, 5, 7, 8, 10, 10, 12.\nDer Median ist 7. Obere Hälfte: 8, 10, 10, 12. Ihr Median ist (10 + 10) : 2 = 10.\nDas obere Quartil ist 10.',
  ke: [
    ['7', 'falsche_groesse_beantwortet', '7', 'Den Median der ganzen Reihe statt des oberen Quartils angegeben.', 'Teilt dein Wert die Daten in zwei Hälften oder ein Viertel ab?'],
    ['8,5', 'median_ohne_sortieren', '(10+7)/2', 'Die letzten vier Werte ungeordnet genommen und deren Mitte gebildet: (10 + 7) : 2 = 8,5.', 'Hast du die Werte vor dem Halbieren der Größe nach geordnet?'],
  ] });
def({ ...K, ref: 'stoch-kenngroessen-05', titel: 'Spannweite · Sachkontext · Morgentemperaturen',
  frage: 'An sieben Tagen wurde jeweils um 7 Uhr die Temperatur gemessen (in °C):\n3, −2, 5, −5, 1, 0, 7\n\nBestimme die Spannweite der Messwerte.',
  einheit: '°C', afb: 'II', afbGrund: 'Anwenden: größten und kleinsten Wert finden, Differenz mit negativer Zahl.',
  sach: true, prozess: 'Modellieren', antwort: '12', r: '7-(-5)',
  weg: 'Größter Wert: 7 °C, kleinster Wert: −5 °C.\nSpannweite = 7 − (−5) = 12 °C.',
  ke: [
    ['-12', 'seiten_verwechselt', '-5-7', 'Kleinster minus größter Wert gerechnet: −5 − 7 = −12.', 'Kann ein Abstand zwischen zwei Werten negativ sein?'],
  ] });
def({ ...K, ref: 'stoch-kenngroessen-06', titel: 'Median · Sachkontext · Tore mit Ausreißer',
  frage: 'Eine Handballmannschaft hat in zehn Spielen folgende Anzahlen an Toren erzielt:\n12, 7, 15, 9, 30, 11, 8, 14, 10, 13\n\nBestimme den Median der Torzahlen.',
  afb: 'II', afbGrund: 'Anwenden: zehn Werte ordnen, Median zwischen zwei Werten, Ausreißer im Datensatz.',
  sach: true, prozess: 'Modellieren', antwort: '11,5', r: '(11+12)/2',
  weg: 'Geordnet: 7, 8, 9, 10, 11, 12, 13, 14, 15, 30.\nBei zehn Werten liegt der Median zwischen dem fünften und sechsten Wert: (11 + 12) : 2 = 11,5.',
  ke: [
    ['12,9', 'mittelwert_statt_median', '(12+7+15+9+30+11+8+14+10+13)/10', 'Den Durchschnitt berechnet: 129 : 10 = 12,9.', 'Ist nach dem Wert in der Mitte gefragt oder nach dem Durchschnitt?'],
    ['20,5', 'median_ohne_sortieren', '(30+11)/2', 'Die beiden mittleren Werte der ungeordneten Liste gemittelt: (30 + 11) : 2 = 20,5.', 'Hast du die Werte vor dem Abzählen der Größe nach geordnet?'],
  ] });

// ─── stoch_laplace (Tiefe 5) ─────────────────────────────────────────────────
const L = { skill: 'stoch_laplace', art: 'p' };
def({ ...L, ref: 'stoch-laplace-01', titel: 'Laplace · Würfel · größer als vier',
  frage: `Ein fairer Würfel wird einmal geworfen.\n\nWie groß ist die Wahrscheinlichkeit, eine Zahl größer als 4 zu werfen? ${PB}`,
  afb: 'I', afbGrund: 'Reproduzieren: günstige und mögliche Ergebnisse abzählen, Bruch bilden.',
  sach: false, prozess: 'Operieren', antwort: '1/3', r: '2/6', roh: [6],
  weg: 'Günstig sind 5 und 6, also 2 von 6 möglichen Ergebnissen.\nP = 2/6 = 1/3.',
  ke: [
    ['1/2', 'verhaeltnis_statt_anteil', '2/4', 'Die günstigen durch die übrigen Ergebnisse geteilt: 2/4.', 'Wie viele Ergebnisse sind insgesamt möglich?', [4]],
    ['3', 'umgekehrt_geteilt', '6/2', 'Mögliche durch günstige Ergebnisse geteilt: 6 : 2 = 3.', 'Kann eine Wahrscheinlichkeit größer als 1 sein?'],
  ] });
def({ ...L, ref: 'stoch-laplace-02', titel: 'Laplace · Urne · rote Kugel',
  frage: `In einer Urne liegen 3 rote und 2 blaue Kugeln. Eine Kugel wird zufällig gezogen.\n\nWie groß ist die Wahrscheinlichkeit, eine rote Kugel zu ziehen? ${PA}`,
  afb: 'I', afbGrund: 'Reproduzieren: Anteil der roten Kugeln an allen Kugeln.',
  sach: false, prozess: 'Operieren', antwort: '3/5', r: '3/(3+2)', roh: [5],
  weg: 'Insgesamt 3 + 2 = 5 Kugeln, davon 3 rote.\nP(rot) = 3/5 = 0,6 = 60 %.',
  ke: [
    ['3/2', 'verhaeltnis_statt_anteil', '3/2', 'Rote durch blaue Kugeln geteilt: 3/2.', 'Wie viele Kugeln liegen insgesamt in der Urne?', [2]],
    ['5/3', 'umgekehrt_geteilt', '5/3', 'Alle Kugeln durch die roten geteilt: 5/3.', 'Kann eine Wahrscheinlichkeit größer als 1 sein?', [3]],
  ] });
def({ ...L, ref: 'stoch-laplace-03', titel: 'Laplace · Glücksrad · Primzahl',
  frage: `Ein Glücksrad hat 12 gleich große Felder mit den Zahlen 1 bis 12. Es wird einmal gedreht.\n\nWie groß ist die Wahrscheinlichkeit, dass es auf einer Primzahl stehen bleibt? ${PB}`,
  afb: 'II', afbGrund: 'Anwenden: günstige Ergebnisse erst bestimmen (Primzahlen bis 12), dann Anteil bilden.',
  sach: false, prozess: 'Operieren', antwort: '5/12', r: '5/12', roh: [12],
  weg: 'Primzahlen bis 12: 2, 3, 5, 7, 11, also 5 günstige von 12 Feldern.\nP = 5/12.',
  ke: [
    ['5/7', 'verhaeltnis_statt_anteil', '5/(12-5)', 'Die günstigen durch die übrigen Felder geteilt: 5/7.', 'Wie viele Felder hat das Glücksrad insgesamt?', [7]],
    ['12/5', 'umgekehrt_geteilt', '12/5', 'Alle Felder durch die günstigen geteilt: 12/5.', 'Kann eine Wahrscheinlichkeit größer als 1 sein?', [5]],
  ] });
def({ ...L, ref: 'stoch-laplace-04', titel: 'Laplace · Lostrommel · Niete',
  frage: `In einer Lostrommel liegen 40 Lose: 6 Hauptgewinne, 10 Trostpreise und sonst nur Nieten. Ein Los wird zufällig gezogen.\n\nWie groß ist die Wahrscheinlichkeit, eine Niete zu ziehen? ${PA}`,
  afb: 'II', afbGrund: 'Anwenden: Zahl der günstigen Ergebnisse erst aus dem Rest bestimmen, dann kürzen.',
  sach: false, prozess: 'Operieren', antwort: '3/5', r: '(40-6-10)/40', roh: [40],
  weg: 'Nieten: 40 − 6 − 10 = 24.\nP(Niete) = 24/40 = 3/5 = 0,6 = 60 %.',
  ke: [
    ['3/2', 'verhaeltnis_statt_anteil', '24/16', 'Nieten durch die übrigen Lose geteilt: 24/16.', 'Durch welche Zahl teilst du: durch alle Lose oder durch die Gewinnlose?', [16]],
    ['5/3', 'umgekehrt_geteilt', '40/24', 'Alle Lose durch die Nieten geteilt: 40/24.', 'Kann eine Wahrscheinlichkeit größer als 1 sein?', [24]],
  ] });
def({ ...L, ref: 'stoch-laplace-05', titel: 'Laplace · Sachkontext · Tombola in Prozent',
  frage: 'Bei einer Tombola werden 150 Lose verkauft, 30 davon sind Gewinne. Ein Los wird zufällig gekauft.\n\nWie groß ist die Wahrscheinlichkeit für einen Gewinn? Gib das Ergebnis in Prozent an.',
  afb: 'II', afbGrund: 'Anwenden: Laplace-Wahrscheinlichkeit bilden und in Prozent umrechnen.',
  sach: true, prozess: 'Modellieren', antwort: '20 %', r: '30/150', roh: [150],
  weg: 'P(Gewinn) = 30/150 = 1/5 = 0,2 = 20 %.',
  ke: [
    ['25 %', 'verhaeltnis_statt_anteil', '30/120', 'Gewinne durch Nieten geteilt: 30/120 = 25 %.', 'Wie viele Lose gibt es insgesamt?', [120]],
    ['5', 'umgekehrt_geteilt', '150/30', 'Alle Lose durch die Gewinne geteilt: 150 : 30 = 5.', 'Kann eine Wahrscheinlichkeit größer als 1 sein?'],
  ] });
def({ ...L, ref: 'stoch-laplace-06', titel: 'Laplace · Rückrichtung · Gesamtzahl der Kugeln',
  frage: 'In einer Urne liegen nur rote und blaue Kugeln. 6 Kugeln sind rot. Die Wahrscheinlichkeit, zufällig eine rote Kugel zu ziehen, beträgt 2/5.\n\nWie viele Kugeln liegen insgesamt in der Urne?',
  afb: 'II', afbGrund: 'Anwenden in Rückrichtung: aus Anteil und Zahl der günstigen die Gesamtzahl bestimmen.',
  sach: false, prozess: 'Problemlösen', art: 'z', antwort: '15', r: '6/(2/5)',
  weg: '6 rote Kugeln sind 2/5 aller Kugeln.\n1/5 sind 6 : 2 = 3 Kugeln, alle Kugeln 5 · 3 = 15.',
  ke: [
    ['21', 'verhaeltnis_statt_anteil', '6+6*5/2', '2/5 als Verhältnis rot zu blau gelesen: 15 blaue, zusammen 21.', 'Bedeutet 2/5 hier „2 von 5 Kugeln“ oder „2 rote auf 5 blaue“?'],
    ['2,4', 'multipliziert_statt_dividiert', '6*2/5', 'Die 6 mit 2/5 malgenommen statt durch 2/5 geteilt.', 'Müssen insgesamt mehr oder weniger Kugeln in der Urne liegen als rote?'],
  ] });

// ─── stoch_gegenereignis (Tiefe 6) ───────────────────────────────────────────
const G = { skill: 'stoch_gegenereignis', art: 'p' };
def({ ...G, ref: 'stoch-gegenereignis-01', titel: 'Gegenereignis · Würfel · keine Sechs',
  frage: `Ein fairer Würfel wird einmal geworfen.\n\nWie groß ist die Wahrscheinlichkeit, keine Sechs zu werfen? ${PB}`,
  afb: 'I', afbGrund: 'Reproduzieren: P(nicht E) = 1 − P(E) mit einem einfachen Bruch.',
  sach: false, prozess: 'Operieren', antwort: '5/6', r: '1-1/6', roh: [6],
  weg: 'P(Sechs) = 1/6.\nP(keine Sechs) = 1 − 1/6 = 5/6.',
  ke: [
    ['1/6', 'gegenereignis_nicht_abgezogen', '1/6', 'Die Wahrscheinlichkeit für eine Sechs angegeben statt für keine Sechs.', 'Nach welchem Ereignis war gefragt?'],
  ] });
def({ ...G, ref: 'stoch-gegenereignis-02', titel: 'Gegenereignis · Dezimalzahl',
  frage: `Für ein Ereignis E gilt P(E) = 0,35.\n\nBerechne die Wahrscheinlichkeit des Gegenereignisses von E. ${PA}`,
  afb: 'I', afbGrund: 'Reproduzieren: Gegenwahrscheinlichkeit mit einer Dezimalzahl.',
  sach: false, prozess: 'Operieren', antwort: '0,65', r: '1-0.35', roh: [20, 100],
  weg: 'P(nicht E) = 1 − 0,35 = 0,65 = 65 %.',
  ke: [
    ['0,35', 'gegenereignis_nicht_abgezogen', '0.35', 'P(E) selbst angegeben statt der Gegenwahrscheinlichkeit.', 'Nach welchem Ereignis ist gefragt: E oder „nicht E“?', [20, 100]],
  ] });
def({ ...G, ref: 'stoch-gegenereignis-03', titel: 'Gegenereignis · Urne · keine blaue Kugel',
  frage: `In einer Urne liegen 4 rote, 5 blaue und 3 grüne Kugeln. Eine Kugel wird zufällig gezogen.\n\nWie groß ist die Wahrscheinlichkeit, keine blaue Kugel zu ziehen? ${PB}`,
  afb: 'II', afbGrund: 'Anwenden: drei Farben, Gegenereignis „blau“ erkennen und von 1 abziehen.',
  sach: false, prozess: 'Operieren', antwort: '7/12', r: '1-5/12', roh: [12],
  weg: 'Insgesamt 4 + 5 + 3 = 12 Kugeln, P(blau) = 5/12.\nP(keine blaue) = 1 − 5/12 = 7/12.',
  ke: [
    ['5/12', 'gegenereignis_nicht_abgezogen', '5/12', 'Die Wahrscheinlichkeit für eine blaue Kugel angegeben.', 'Nach welchem Ereignis war gefragt?'],
    ['7/5', 'verhaeltnis_statt_anteil', '7/5', 'Nicht-blaue durch blaue Kugeln geteilt: 7/5.', 'Wie viele Kugeln liegen insgesamt in der Urne?', [5]],
  ] });
def({ ...G, ref: 'stoch-gegenereignis-04', titel: 'Gegenereignis · Glücksrad · weder rot noch blau',
  frage: `Ein Glücksrad hat rote, blaue und gelbe Felder. Es bleibt mit der Wahrscheinlichkeit 1/4 auf Rot und mit der Wahrscheinlichkeit 1/8 auf Blau stehen.\n\nWie groß ist die Wahrscheinlichkeit, dass es auf Gelb stehen bleibt? ${PA}`,
  afb: 'II', afbGrund: 'Anwenden: zwei Wahrscheinlichkeiten addieren (Hauptnenner), dann Gegenwahrscheinlichkeit.',
  sach: false, prozess: 'Operieren', antwort: '5/8', r: '1-(1/4+1/8)', roh: [8],
  weg: 'P(rot oder blau) = 1/4 + 1/8 = 2/8 + 1/8 = 3/8.\nP(gelb) = 1 − 3/8 = 5/8 = 0,625 = 62,5 %.',
  ke: [
    ['3/8', 'gegenereignis_nicht_abgezogen', '1/4+1/8', 'P(rot oder blau) angegeben, nicht von 1 abgezogen.', 'Ist 3/8 die Wahrscheinlichkeit für Gelb oder für das Gegenteil?', [8]],
    ['3/4', 'bedingung_unvollstaendig', '1-1/4', 'Nur Rot von 1 abgezogen, Blau vergessen.', 'Welche Felder gehören nicht zu Gelb?', [4]],
    ['7/8', 'bedingung_unvollstaendig', '1-1/8', 'Nur Blau von 1 abgezogen, Rot vergessen.', 'Welche Felder gehören nicht zu Gelb?', [8]],
    ['5/6', 'nenner_addiert', '1-2/12', 'Beim Addieren die Nenner addiert: 1/4 + 1/8 = 2/12, dann 1 − 2/12.', 'Wie addierst du zwei Brüche mit verschiedenen Nennern?', [6, 12]],
  ] });
def({ ...G, ref: 'stoch-gegenereignis-05', titel: 'Gegenereignis · Sachkontext · keine Niete',
  frage: `In einer Lostrommel liegen 200 Lose. 30 davon sind Gewinne, 50 sind Trostpreise, alle übrigen sind Nieten. Ein Los wird zufällig gezogen.\n\nWie groß ist die Wahrscheinlichkeit, keine Niete zu ziehen? ${PA}`,
  afb: 'II', afbGrund: 'Anwenden: Ereignis „keine Niete“ als Gegenereignis oder als Summe bestimmen.',
  sach: true, prozess: 'Modellieren', antwort: '2/5', r: '(30+50)/200', roh: [200],
  weg: 'Nieten: 200 − 30 − 50 = 120, P(Niete) = 120/200.\nP(keine Niete) = 1 − 120/200 = 80/200 = 2/5 = 0,4 = 40 %.',
  ke: [
    ['3/5', 'gegenereignis_nicht_abgezogen', '120/200', 'P(Niete) angegeben statt P(keine Niete).', 'Nach welchem Ereignis war gefragt?', [200]],
    ['2/3', 'verhaeltnis_statt_anteil', '80/120', 'Die Lose ohne Niete durch die Nieten geteilt: 80/120.', 'Wie viele Lose liegen insgesamt in der Trommel?', [120]],
  ] });
def({ ...G, ref: 'stoch-gegenereignis-06', titel: 'Gegenereignis · Rückrichtung · Zahl der roten Kugeln',
  frage: 'In einer Urne liegen 30 Kugeln. Die Wahrscheinlichkeit, zufällig keine rote Kugel zu ziehen, beträgt 0,7.\n\nWie viele rote Kugeln liegen in der Urne?',
  afb: 'II', afbGrund: 'Anwenden in Rückrichtung: P(rot) über das Gegenereignis, dann Anzahl.',
  sach: false, prozess: 'Problemlösen', art: 'z', antwort: '9', r: '30*(1-0.7)',
  weg: 'P(rot) = 1 − 0,7 = 0,3.\nRote Kugeln: 0,3 · 30 = 9.',
  ke: [
    ['21', 'gegenereignis_nicht_abgezogen', '30*0.7', 'Mit 0,7 gerechnet: das ist die Zahl der nicht roten Kugeln.', 'Gehört 0,7 zu den roten Kugeln oder zu den übrigen?'],
    ['100', 'umgekehrt_geteilt', '30/(1-0.7)', 'Durch 0,3 geteilt statt mit 0,3 malgenommen.', 'Können mehr rote Kugeln in der Urne liegen, als es Kugeln gibt?'],
  ] });
