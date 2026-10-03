#!/usr/bin/env node
/**
 * k9-kreis-charge.mjs — erzeugt docs/prefill/k9-kreis.json (Charge-Format von vorlauf-build.mjs).
 *
 *   node tools/k9-kreis-charge.mjs
 *
 * Jede Aufgabe nennt, womit gerechnet wird (π-Taste oder 3,14) und wie gerundet wird. Die
 * Bewertung ist ein exakter Textvergleich (lsa_is_correct, lsa_fehlbild_match). Deshalb
 * rechnet das Skript jeden Wert ZWEIMAL exakt nach — mit π auf 35 Stellen und mit 3,14 —
 * und hinterlegt beide Ergebnisse in allen Schreibweisen (Komma, Punkt, Endnull, Einheit).
 * Keine Toleranz. Liegt ein ungerundeter Wert zu nah an einer Rundungsgrenze, bricht es ab.
 * Die ids stehen in docs/prefill/k9-kreis-ids.json: ein zweiter Lauf erzeugt dieselbe Charge.
 */

import fs from 'node:fs';
import { zahl } from './prefill-rechnen.mjs';

const GEO = '3156b22e-ad3b-46c8-8c76-4155176cc52a'; // Themengebiet „Geometrie & Messen"
const ZEIT = { I: 45, II: 60, III: 90 };
const SACH = 30;
const PI = '3.14159265358979323846264338327950288';
const WEGE = [['pi', PI], ['314', '3.14']];
const SATZ_PI = 'Rechne mit der π-Taste oder mit π ≈ 3,14.';
const SATZ_2 = `${SATZ_PI} Runde das Ergebnis auf zwei Stellen nach dem Komma.`;

// ── Rechnen und Schreibweisen ─────────────────────────────────────────────────
const zehn = (n) => 10n ** BigInt(n);
const ceil = (q) => (q.n % q.d === 0n ? q.n / q.d : q.n / q.d + (q.n > 0n ? 1n : 0n));
const floor = (q) => (q.n % q.d === 0n || q.n > 0n ? q.n / q.d : q.n / q.d - 1n);
/** Wert eines Ausdrucks mit P (= π) fuer einen Rechenweg, gerundet nach modus. */
function wert(expr, p, modus, wo, fehler) {
  const roh = zahl(expr.replaceAll('P', p));
  if (modus === 'auf') return String(ceil(roh));
  if (modus === 'ab') return String(floor(roh));
  // Rundungsgrenze: liegt der Rest zu nah an ,5 der letzten Stelle, ist die Rundung wacklig.
  const skal = roh.mul(zahl(String(zehn(modus))));
  const rest = Number(((skal.n % skal.d) * 1000000n) / skal.d) / 1e6;
  if (Math.abs(Math.abs(rest) - 0.5) < 0.002) fehler.push(`${wo}: ${expr} liegt an einer Rundungsgrenze`);
  const g = roh.round(modus);
  const ganz = (g.n * zehn(modus)) / g.d;
  const neg = ganz < 0n ? '-' : '';
  const s = String(ganz < 0n ? -ganz : ganz).padStart(modus + 1, '0');
  return modus ? `${neg}${s.slice(0, -modus)},${s.slice(-modus)}` : `${neg}${s}`;
}
/**
 * Pruefeintrag fuer verify-prefill: die Rechnung muss EXAKT den Wert ergeben. Bei Stellen-Rundung
 * steht round(…, n) in der Rechnung. Auf-/Abrunden kennt der Parser nicht: dort wird der Wert
 * vor dem Runden (auf 4 Stellen) belegt, die ganze Zahl prueft dieses Skript (ceil/floor oben).
 * rolle null = richtige Antwort (verify-prefill prueft, dass sie in correct_answers steht).
 */
function pruef(expr, p, modus, w, rolle, wo) {
  const e = expr.replaceAll('P', p);
  if (typeof modus === 'number') return { rechnung: `round(${e},${modus})`, antwort: w.replace(',', '.'), ...(rolle ? { rolle } : {}) };
  const vor = wert(expr, p, 4, wo, []);
  return { rechnung: `round(${e},4)`, antwort: vor.replace(',', '.'), rolle: `${rolle ?? 'richtig'}:vor-${modus}runden=${w}` };
}
function formen(w, einheit) {
  const basis = [w];
  if (/,\d*0$/.test(w)) basis.push(w.replace(/0+$/, '').replace(/,$/, ''));
  const out = [];
  for (const b of basis) { out.push(b); if (b.includes(',')) out.push(b.replace(',', '.')); }
  if (einheit) for (const b of basis) out.push(`${b} ${einheit}`, `${b}${einheit}`);
  return [...new Set(out)];
}

// ── Aufgaben ──────────────────────────────────────────────────────────────────
// r: Rechnung mit P fuer π · n: Nachkommastellen oder 'auf' (ganzzahlig aufrunden)
// weg: Loesungsweg mit {A} (π-Taste) und {B} (3,14)
// ke: [Slug, Rechnung, Fehlertext, sokratische Frage, optional eigener Modus]
const A = [];
const def = (o) => A.push(o);

// ─── geo_kreis_umfang (Tiefe 6) ───
const UM = { skill: 'geo_kreis_umfang', n: 2 };
def({ ...UM, ref: 'kreis-umfang-01', titel: 'Umfang · Radius 4 cm', einheit: 'cm', afb: 'I', sach: false,
  afbGrund: 'Reproduzieren: Umfangsformel mit gegebenem Radius, ein Schritt.',
  frage: `Ein Kreis hat den Radius 4 cm.\n\nWie groß ist sein Umfang? ${SATZ_2}`, r: '2*P*4',
  weg: 'U = 2 · π · r = 2 · π · 4 cm ≈ {A} cm (π-Taste).\nMit π ≈ 3,14: U = 2 · 3,14 · 4 cm = {B} cm.',
  ke: [['radius_durchmesser_verwechselt', 'P*4', 'Den Radius wie einen Durchmesser eingesetzt: π · 4.', 'Ist 4 cm der Abstand vom Mittelpunkt zum Rand oder einmal ganz durch den Kreis?'],
    ['pi_vergessen', '2*4', 'π weggelassen: 2 · 4 = 8.', 'Welche Zahl gehört in jede Formel am Kreis?'],
    ['flaeche_statt_umfang', 'P*4^2', 'Mit der Flächenformel gerechnet: π · 4².', 'Ist nach der Länge der Randlinie oder nach der Fläche gefragt?']] });
def({ ...UM, ref: 'kreis-umfang-02', titel: 'Umfang · Durchmesser 10 cm', einheit: 'cm', afb: 'I', sach: false,
  afbGrund: 'Reproduzieren: Umfang aus dem Durchmesser, ein Schritt.',
  frage: `Ein Kreis hat den Durchmesser 10 cm.\n\nWie groß ist sein Umfang? ${SATZ_2}`, r: 'P*10',
  weg: 'U = π · d = π · 10 cm ≈ {A} cm (π-Taste).\nMit π ≈ 3,14: U = 3,14 · 10 cm = {B} cm.',
  ke: [['radius_durchmesser_verwechselt', '2*P*10', 'Den Durchmesser als Radius eingesetzt: 2 · π · 10.', 'Ist 10 cm der Radius oder der Durchmesser?'],
    ['pi_vergessen', '10', 'π weggelassen: Umfang = Durchmesser.', 'Ist der Rand eines Kreises wirklich so lang wie sein Durchmesser?'],
    ['flaeche_statt_umfang', 'P*5^2', 'Mit der Flächenformel gerechnet: π · 5².', 'Ist nach der Randlinie oder nach der Fläche gefragt?']] });
def({ ...UM, ref: 'kreis-umfang-03', titel: 'Umfang · Radius 3,6 m', einheit: 'm', afb: 'II', sach: false,
  afbGrund: 'Anwenden: Dezimalradius, Ergebnis nicht im Kopf überschlagbar.',
  frage: `Ein Kreis hat den Radius 3,6 m.\n\nWie groß ist sein Umfang in Metern? ${SATZ_2}`, r: '2*P*3.6',
  weg: 'U = 2 · π · 3,6 m ≈ {A} m (π-Taste).\nMit π ≈ 3,14: U = 2 · 3,14 · 3,6 m ≈ {B} m.',
  ke: [['radius_durchmesser_verwechselt', 'P*3.6', 'Den Radius wie einen Durchmesser eingesetzt: π · 3,6.', 'Wie viele Radien passen in einen Durchmesser?'],
    ['pi_vergessen', '2*3.6', 'π weggelassen: 2 · 3,6 = 7,2.', 'Welcher Faktor fehlt in deiner Rechnung?'],
    ['flaeche_statt_umfang', 'P*3.6^2', 'Mit der Flächenformel gerechnet: π · 3,6².', 'Kommt bei deiner Formel eine Länge oder eine Fläche heraus?']] });
def({ ...UM, ref: 'kreis-umfang-04', titel: 'Umfang · Radius 45 cm, Ergebnis in Metern', einheit: 'm', afb: 'II', sach: false,
  afbGrund: 'Anwenden: Umfang plus Umrechnung von Zentimetern in Meter.',
  frage: `Ein Kreis hat den Radius 45 cm.\n\nWie groß ist sein Umfang in Metern? ${SATZ_2}`, r: '2*P*0.45',
  weg: 'r = 45 cm = 0,45 m.\nU = 2 · π · 0,45 m ≈ {A} m (π-Taste).\nMit π ≈ 3,14: U = 2 · 3,14 · 0,45 m ≈ {B} m.',
  ke: [['einheit_uebersprungen', '2*P*45', 'Nicht in Meter umgerechnet: der Umfang in Zentimetern.', 'In welcher Einheit ist das Ergebnis gefragt?'],
    ['radius_durchmesser_verwechselt', 'P*0.45', 'Den Radius wie einen Durchmesser eingesetzt: π · 0,45.', 'Ist 45 cm der Radius oder der Durchmesser?'],
    ['pi_vergessen', '2*0.45', 'π weggelassen: 2 · 0,45 = 0,9.', 'Welche Zahl fehlt in der Umfangsformel?']] });
def({ ...UM, ref: 'kreis-umfang-05', titel: 'Umfang · Fahrradrad mit 70 cm Durchmesser', einheit: 'cm', afb: 'II', sach: true,
  afbGrund: 'Anwenden im Sachkontext: Eine Radumdrehung muss als Umfang erkannt werden.',
  frage: `Ein Fahrradrad hat einen Durchmesser von 70 cm.\n\nWie viele Zentimeter legt das Rad bei einer vollen Umdrehung zurück? ${SATZ_2}`, r: 'P*70',
  weg: 'Bei einer Umdrehung rollt der ganze Rand einmal ab: Weg = Umfang.\nU = π · 70 cm ≈ {A} cm (π-Taste).\nMit π ≈ 3,14: U = 3,14 · 70 cm = {B} cm.',
  ke: [['radius_durchmesser_verwechselt', 'P*140', 'Den Durchmesser als Radius eingesetzt: 2 · π · 70.', 'Sind 70 cm der Radius oder der Durchmesser des Rades?'],
    ['pi_vergessen', '70', 'π weggelassen: Weg = Durchmesser.', 'Rollt das Rad bei einer Umdrehung nur so weit, wie es hoch ist?'],
    ['flaeche_statt_umfang', 'P*35^2', 'Die Fläche des Rades berechnet statt seines Umfangs.', 'Ist ein zurückgelegter Weg eine Länge oder eine Fläche?']] });
def({ ...UM, ref: 'kreis-umfang-06', titel: 'Umfang · Umdrehungen für 100 m bei 60 cm Durchmesser', einheit: 'Umdrehungen', afb: 'III', sach: true, n: 'auf',
  afbGrund: 'Problemlösen: Strecke durch Umfang teilen, Einheiten angleichen und sinnvoll aufrunden.',
  frage: `Ein Rad hat einen Durchmesser von 60 cm. Es soll eine Strecke von 100 m zurücklegen.\n\nWie viele volle Umdrehungen muss das Rad mindestens machen? Gib eine ganze Zahl an und runde dafür auf. ${SATZ_PI}`, r: '10000/(P*60)',
  weg: 'U = π · 60 cm ≈ 188,50 cm (mit 3,14: 188,40 cm).\n100 m = 10 000 cm.\n10 000 cm : 188,50 cm ≈ 53,05 (mit 3,14: ≈ 53,08).\nNach 53 Umdrehungen fehlt noch ein Stück, also mindestens {A} Umdrehungen.',
  ke: [['abgeschnitten', '10000/(P*60)', 'Abgerundet: 53 Umdrehungen reichen noch nicht ganz.', 'Kommt das Rad nach 53 Umdrehungen schon ganz bis 100 m?', 'ab'],
    ['radius_durchmesser_verwechselt', '10000/(2*P*60)', 'Den Durchmesser als Radius eingesetzt: Umfang doppelt so groß.', 'Sind 60 cm der Radius oder der Durchmesser?'],
    ['pi_vergessen', '10000/60', 'π weggelassen: durch den Durchmesser statt durch den Umfang geteilt.', 'Wie weit kommt das Rad bei einer Umdrehung?']] });

// ─── geo_kreis_flaeche (Tiefe 6) ───
const FL = { skill: 'geo_kreis_flaeche', n: 2 };
def({ ...FL, ref: 'kreis-flaeche-01', titel: 'Fläche · Radius 6 cm', einheit: 'cm²', afb: 'I', sach: false,
  afbGrund: 'Reproduzieren: Flächenformel mit gegebenem Radius.',
  frage: `Ein Kreis hat den Radius 6 cm.\n\nWie groß ist sein Flächeninhalt? ${SATZ_2}`, r: 'P*6^2',
  weg: 'A = π · r² = π · (6 cm)² = π · 36 cm² ≈ {A} cm² (π-Taste).\nMit π ≈ 3,14: A = 3,14 · 36 cm² = {B} cm².',
  ke: [['umfang_statt_flaeche', '2*P*6', 'Den Umfang berechnet (oder r² als 2 · r): 2 · π · 6.', 'Was bedeutet das Hoch-Zwei bei r²?'],
    ['pi_vergessen', '6^2', 'π weggelassen: 6² = 36.', 'Welcher Faktor fehlt in der Flächenformel?'],
    ['radius_durchmesser_verwechselt', 'P*3^2', 'Den Radius wie einen Durchmesser halbiert: π · 3².', 'Ist 6 cm schon der Radius?']] });
def({ ...FL, ref: 'kreis-flaeche-02', titel: 'Fläche · Durchmesser 10 cm', einheit: 'cm²', afb: 'I', sach: false,
  afbGrund: 'Reproduzieren: Radius aus dem Durchmesser, dann Flächenformel.',
  frage: `Ein Kreis hat den Durchmesser 10 cm.\n\nWie groß ist sein Flächeninhalt? ${SATZ_2}`, r: 'P*5^2',
  weg: 'r = 10 cm : 2 = 5 cm.\nA = π · (5 cm)² = π · 25 cm² ≈ {A} cm² (π-Taste).\nMit π ≈ 3,14: A = 3,14 · 25 cm² = {B} cm².',
  ke: [['radius_durchmesser_verwechselt', 'P*10^2', 'Den Durchmesser als Radius eingesetzt: π · 10².', 'Ist 10 cm der Radius oder der Durchmesser?'],
    ['pi_vergessen', '5^2', 'π weggelassen: 5² = 25.', 'Welcher Faktor fehlt in der Flächenformel?'],
    ['umfang_statt_flaeche', 'P*10', 'Den Umfang berechnet: π · 10.', 'Kommt bei π · d eine Fläche heraus?']] });
def({ ...FL, ref: 'kreis-flaeche-03', titel: 'Fläche · Radius 2,4 m', einheit: 'm²', afb: 'II', sach: false,
  afbGrund: 'Anwenden: Quadrat einer Dezimalzahl in der Flächenformel.',
  frage: `Ein Kreis hat den Radius 2,4 m.\n\nWie groß ist sein Flächeninhalt in Quadratmetern? ${SATZ_2}`, r: 'P*2.4^2',
  weg: 'A = π · (2,4 m)² = π · 5,76 m² ≈ {A} m² (π-Taste).\nMit π ≈ 3,14: A = 3,14 · 5,76 m² ≈ {B} m².',
  ke: [['umfang_statt_flaeche', '2*P*2.4', 'Den Umfang berechnet (oder 2,4² als 2 · 2,4): 2 · π · 2,4.', 'Was ist 2,4² – 2,4 · 2 oder 2,4 · 2,4?'],
    ['pi_vergessen', '2.4^2', 'π weggelassen: 2,4² = 5,76.', 'Welcher Faktor fehlt in der Flächenformel?'],
    ['radius_durchmesser_verwechselt', 'P*1.2^2', 'Den Radius wie einen Durchmesser halbiert: π · 1,2².', 'Ist 2,4 m schon der Radius?']] });
def({ ...FL, ref: 'kreis-flaeche-04', titel: 'Fläche · Radius 80 cm, Ergebnis in m²', einheit: 'm²', afb: 'II', sach: false,
  afbGrund: 'Anwenden: Flächenformel plus Umrechnung in eine Flächeneinheit.',
  frage: `Ein Kreis hat den Radius 80 cm.\n\nWie groß ist sein Flächeninhalt in Quadratmetern? ${SATZ_2}`, r: 'P*0.8^2',
  weg: 'r = 80 cm = 0,8 m.\nA = π · (0,8 m)² = π · 0,64 m² ≈ {A} m² (π-Taste).\nMit π ≈ 3,14: A = 3,14 · 0,64 m² ≈ {B} m².',
  ke: [['einheit_uebersprungen', 'P*80^2', 'Nicht umgerechnet: die Fläche in Quadratzentimetern.', 'In welcher Einheit ist das Ergebnis gefragt?'],
    ['linearer_faktor', 'P*80^2/100', 'Mit 100 statt mit 10 000 umgerechnet.', 'Wie viele Quadratzentimeter hat ein Quadratmeter?'],
    ['pi_vergessen', '0.8^2', 'π weggelassen: 0,8² = 0,64.', 'Welcher Faktor fehlt in der Flächenformel?'],
    ['umfang_statt_flaeche', '2*P*0.8', 'Den Umfang berechnet: 2 · π · 0,8.', 'Kommt bei deiner Formel eine Fläche heraus?']] });
def({ ...FL, ref: 'kreis-flaeche-05', titel: 'Fläche · Pizza mit 30 cm Durchmesser', einheit: 'cm²', afb: 'II', sach: true,
  afbGrund: 'Anwenden im Sachkontext: Der Durchmesser muss als solcher erkannt und halbiert werden.',
  frage: `Eine runde Pizza hat einen Durchmesser von 30 cm.\n\nWie viele Quadratzentimeter ist die Pizza groß? ${SATZ_2}`, r: 'P*15^2',
  weg: 'r = 30 cm : 2 = 15 cm.\nA = π · (15 cm)² = π · 225 cm² ≈ {A} cm² (π-Taste).\nMit π ≈ 3,14: A = 3,14 · 225 cm² = {B} cm².',
  ke: [['radius_durchmesser_verwechselt', 'P*30^2', 'Den Durchmesser als Radius eingesetzt: π · 30².', 'Sind 30 cm der Radius oder der Durchmesser der Pizza?'],
    ['umfang_statt_flaeche', 'P*30', 'Den Rand der Pizza berechnet statt ihrer Fläche.', 'Wird nach dem Rand oder nach der ganzen Pizza gefragt?'],
    ['pi_vergessen', '15^2', 'π weggelassen: 15² = 225.', 'Welcher Faktor fehlt in der Flächenformel?']] });
def({ ...FL, ref: 'kreis-flaeche-06', titel: 'Fläche · eine große Pizza gegen zwei kleine', einheit: 'cm²', afb: 'III', sach: true,
  afbGrund: 'Problemlösen: zwei Flächen modellieren, verdoppeln und vergleichen – Rechenweg selbst wählen.',
  frage: `Eine große Pizza hat einen Durchmesser von 30 cm. Eine kleine Pizza hat einen Durchmesser von 20 cm.\n\nUm wie viele Quadratzentimeter ist die große Pizza größer als zwei kleine Pizzen zusammen? ${SATZ_2}`, r: 'P*15^2-2*P*10^2',
  weg: 'Große Pizza: π · (15 cm)² = π · 225 cm².\nZwei kleine: 2 · π · (10 cm)² = π · 200 cm².\nUnterschied: π · 25 cm² ≈ {A} cm² (π-Taste).\nMit π ≈ 3,14: 706,50 cm² − 628,00 cm² = {B} cm².',
  ke: [['radius_durchmesser_verwechselt', 'P*30^2-2*P*20^2', 'Die Durchmesser als Radien eingesetzt.', 'Sind 30 cm und 20 cm Radien oder Durchmesser?'],
    ['falsche_groesse_beantwortet', 'P*15^2', 'Die Fläche der großen Pizza angegeben statt des Unterschieds.', 'Gefragt ist, um wie viel die große Pizza größer ist – was fehlt noch?'],
    ['pi_vergessen', '15^2-2*10^2', 'π weggelassen: 225 − 200 = 25.', 'Welcher Faktor gehört zu jeder Kreisfläche?']] });

// ─── geo_kreis_rueck (Tiefe 7) ───
const RU = { skill: 'geo_kreis_rueck', n: 2 };
def({ ...RU, ref: 'kreis-rueck-01', titel: 'Rückrichtung · Durchmesser aus 50 cm Umfang', einheit: 'cm', afb: 'I', sach: false,
  afbGrund: 'Reproduzieren: Umfangsformel nach d umstellen, eine Division.',
  frage: `Ein Kreis hat den Umfang 50 cm.\n\nWie groß ist sein Durchmesser? ${SATZ_2}`, r: '50/P',
  weg: 'U = π · d, also d = U : π.\nd = 50 cm : π ≈ {A} cm (π-Taste).\nMit π ≈ 3,14: d = 50 cm : 3,14 ≈ {B} cm.',
  ke: [['radius_durchmesser_verwechselt', '50/(2*P)', 'Den Radius berechnet statt des Durchmessers.', 'Ist nach dem Radius oder nach dem Durchmesser gefragt?'],
    ['multipliziert_statt_dividiert', '50*P', 'Mit π multipliziert statt durch π geteilt.', 'Ist der Durchmesser größer oder kleiner als der Umfang?'],
    ['pi_vergessen', '50', 'π weggelassen: Durchmesser = Umfang.', 'Kann der Durchmesser so lang sein wie der ganze Rand?']] });
def({ ...RU, ref: 'kreis-rueck-02', titel: 'Rückrichtung · Radius aus 40 cm Umfang', einheit: 'cm', afb: 'I', sach: false,
  afbGrund: 'Reproduzieren: Umfangsformel nach r umstellen.',
  frage: `Ein Kreis hat den Umfang 40 cm.\n\nWie groß ist sein Radius? ${SATZ_2}`, r: '40/(2*P)',
  weg: 'U = 2 · π · r, also r = U : (2 · π).\nr = 40 cm : (2 · π) ≈ {A} cm (π-Taste).\nMit π ≈ 3,14: r = 40 cm : 6,28 ≈ {B} cm.',
  ke: [['radius_durchmesser_verwechselt', '40/P', 'Den Durchmesser berechnet statt des Radius.', 'Ist nach dem Radius oder nach dem Durchmesser gefragt?'],
    ['multipliziert_statt_dividiert', '40*2*P', 'Mit 2 · π multipliziert statt dadurch geteilt.', 'Muss der Radius kleiner oder größer als der Umfang sein?'],
    ['pi_vergessen', '40/2', 'π weggelassen: 40 : 2 = 20.', 'Durch welche Zahl musst du neben der 2 noch teilen?']] });
def({ ...RU, ref: 'kreis-rueck-03', titel: 'Rückrichtung · Durchmesser in cm aus 2 m Umfang', einheit: 'cm', afb: 'II', sach: false,
  afbGrund: 'Anwenden: Umstellen und dabei von Metern in Zentimeter umrechnen.',
  frage: `Ein Kreis hat den Umfang 2 m.\n\nWie groß ist sein Durchmesser in Zentimetern? ${SATZ_2}`, r: '200/P',
  weg: 'U = 2 m = 200 cm.\nd = 200 cm : π ≈ {A} cm (π-Taste).\nMit π ≈ 3,14: d = 200 cm : 3,14 ≈ {B} cm.',
  ke: [['einheit_uebersprungen', '2/P', 'Nicht in Zentimeter umgerechnet: der Durchmesser in Metern.', 'In welcher Einheit ist der Durchmesser gefragt?'],
    ['radius_durchmesser_verwechselt', '200/(2*P)', 'Den Radius berechnet statt des Durchmessers.', 'Ist nach dem Radius oder nach dem Durchmesser gefragt?'],
    ['pi_vergessen', '200', 'π weggelassen: Durchmesser = Umfang.', 'Kann der Durchmesser so lang sein wie der ganze Rand?']] });
def({ ...RU, ref: 'kreis-rueck-04', titel: 'Rückrichtung · Radius aus 12,5 m Umfang', einheit: 'm', afb: 'II', sach: false,
  afbGrund: 'Anwenden: Dezimalumfang, Division durch 2π, Rundung erst am Ende.',
  frage: `Ein Kreis hat den Umfang 12,5 m.\n\nWie groß ist sein Radius? ${SATZ_2}`, r: '12.5/(2*P)',
  weg: 'r = U : (2 · π) = 12,5 m : (2 · π) ≈ {A} m (π-Taste).\nMit π ≈ 3,14: r = 12,5 m : 6,28 ≈ {B} m.\n(2 · π nicht vorher auf 6,3 runden.)',
  ke: [['radius_durchmesser_verwechselt', '12.5/P', 'Den Durchmesser berechnet statt des Radius.', 'Ist nach dem Radius oder nach dem Durchmesser gefragt?'],
    ['zu_frueh_gerundet', '12.5/6.3', '2 · π auf 6,3 gerundet und damit weitergerechnet.', 'Was passiert mit dem Ergebnis, wenn du 2 · π vor dem Teilen rundest?'],
    ['pi_vergessen', '12.5/2', 'π weggelassen: 12,5 : 2 = 6,25.', 'Durch welche Zahl musst du neben der 2 noch teilen?']] });
def({ ...RU, ref: 'kreis-rueck-05', titel: 'Rückrichtung · Baumstamm mit 2,20 m Umfang', einheit: 'cm', afb: 'II', sach: true,
  afbGrund: 'Anwenden im Sachkontext: gemessener Umfang, Durchmesser in anderer Einheit gesucht.',
  frage: `Um einen runden Baumstamm wird ein Maßband gelegt. Es zeigt 2,20 m.\n\nWie dick ist der Stamm, also wie groß ist sein Durchmesser in Zentimetern? ${SATZ_2}`, r: '220/P',
  weg: 'Das Maßband misst den Umfang: U = 2,20 m = 220 cm.\nd = 220 cm : π ≈ {A} cm (π-Taste).\nMit π ≈ 3,14: d = 220 cm : 3,14 ≈ {B} cm.',
  ke: [['radius_durchmesser_verwechselt', '110/P', 'Den Radius berechnet statt des Durchmessers.', 'Ist die Dicke des Stamms der Radius oder der Durchmesser?'],
    ['einheit_uebersprungen', '2.2/P', 'Nicht in Zentimeter umgerechnet: der Durchmesser in Metern.', 'In welcher Einheit ist die Dicke gefragt?'],
    ['pi_vergessen', '220', 'π weggelassen: Durchmesser = Umfang.', 'Kann der Stamm so dick sein, wie das Maßband lang ist?']] });
def({ ...RU, ref: 'kreis-rueck-06', titel: 'Rückrichtung · runder Tisch für 8 Personen', einheit: 'cm', afb: 'III', sach: true, n: 'auf',
  afbGrund: 'Problemlösen: den nötigen Umfang erst aus der Situation bilden, dann umstellen und sinnvoll aufrunden.',
  frage: `An einem runden Tisch sollen 8 Personen sitzen. Jede Person braucht am Tischrand 60 cm Platz.\n\nWie groß muss der Durchmesser des Tisches mindestens sein? Gib ganze Zentimeter an und runde dafür auf. ${SATZ_PI}`, r: '480/P',
  weg: 'Nötiger Umfang: 8 · 60 cm = 480 cm.\nd = 480 cm : π ≈ 152,79 cm (mit 3,14: ≈ 152,87 cm).\nAufgerundet: mindestens {A} cm.',
  ke: [['abgeschnitten', '480/P', 'Abgerundet: Mit 152 cm reicht der Rand nicht ganz.', 'Reicht der Rand, wenn du abrundest?', 'ab'],
    ['radius_durchmesser_verwechselt', '480/(2*P)', 'Den Radius berechnet statt des Durchmessers.', 'Ist nach dem Radius oder nach dem Durchmesser gefragt?'],
    ['bedingung_unvollstaendig', '60/P', 'Nur mit dem Platz für eine Person gerechnet.', 'Wie viele Personen sollen am Tisch sitzen?'],
    ['pi_vergessen', '480', 'π weggelassen: Durchmesser = Umfang.', 'Kann der Durchmesser so lang sein wie der ganze Rand?']] });

// ─── geo_kreis_sektor (Tiefe 7) ───
const SE = { skill: 'geo_kreis_sektor', n: 2 };
def({ ...SE, ref: 'kreis-sektor-01', titel: 'Kreisbogen · Radius 6 cm, 90°', einheit: 'cm', afb: 'I', sach: false,
  afbGrund: 'Reproduzieren: Viertel des Umfangs, Anteil direkt erkennbar.',
  frage: `Ein Kreisausschnitt hat den Radius 6 cm und den Mittelpunktswinkel 90°.\n\nWie lang ist der Kreisbogen? ${SATZ_2}`, r: '90/360*2*P*6',
  weg: 'Anteil: 90° von 360° = 1/4.\nb = 1/4 · 2 · π · 6 cm ≈ {A} cm (π-Taste).\nMit π ≈ 3,14: b = 1/4 · 2 · 3,14 · 6 cm ≈ {B} cm.',
  ke: [['kreisanteil_falsch', '2*P*6', 'Den ganzen Umfang angegeben, der Anteil 90°/360° fehlt.', 'Welcher Teil des ganzen Kreises ist der Ausschnitt?'],
    ['kreisanteil_falsch', '360/90*2*P*6', 'Den Anteil umgedreht: mal 4 statt mal 1/4.', 'Ist der Bogen länger oder kürzer als der ganze Umfang?'],
    ['flaeche_statt_umfang', '90/360*P*6^2', 'Die Fläche des Ausschnitts berechnet statt des Bogens.', 'Ist eine Länge oder eine Fläche gefragt?'],
    ['pi_vergessen', '90/360*2*6', 'π weggelassen: 1/4 · 2 · 6 = 3.', 'Welcher Faktor fehlt in der Umfangsformel?']] });
def({ ...SE, ref: 'kreis-sektor-02', titel: 'Kreisausschnitt · Radius 4 cm, 90°', einheit: 'cm²', afb: 'I', sach: false,
  afbGrund: 'Reproduzieren: Viertel der Kreisfläche, Anteil direkt erkennbar.',
  frage: `Ein Kreisausschnitt hat den Radius 4 cm und den Mittelpunktswinkel 90°.\n\nWie groß ist sein Flächeninhalt? ${SATZ_2}`, r: '90/360*P*4^2',
  weg: 'Anteil: 90° von 360° = 1/4.\nA = 1/4 · π · (4 cm)² = 1/4 · π · 16 cm² ≈ {A} cm² (π-Taste).\nMit π ≈ 3,14: A = 1/4 · 3,14 · 16 cm² = {B} cm².',
  ke: [['kreisanteil_falsch', 'P*4^2', 'Die ganze Kreisfläche angegeben, der Anteil 90°/360° fehlt.', 'Welcher Teil des ganzen Kreises ist der Ausschnitt?'],
    ['kreisanteil_falsch', '360/90*P*4^2', 'Den Anteil umgedreht: mal 4 statt mal 1/4.', 'Ist der Ausschnitt größer oder kleiner als der ganze Kreis?'],
    ['umfang_statt_flaeche', '90/360*2*P*4', 'Den Kreisbogen berechnet statt der Fläche.', 'Ist eine Länge oder eine Fläche gefragt?'],
    ['pi_vergessen', '90/360*4^2', 'π weggelassen: 1/4 · 16 = 4.', 'Welcher Faktor fehlt in der Flächenformel?']] });
def({ ...SE, ref: 'kreis-sektor-03', titel: 'Kreisbogen · Radius 9 cm, 120°', einheit: 'cm', afb: 'II', sach: false,
  afbGrund: 'Anwenden: Anteil 120°/360° = 1/3, als Dezimalzahl nicht abbrechend.',
  frage: `Ein Kreisausschnitt hat den Radius 9 cm und den Mittelpunktswinkel 120°.\n\nWie lang ist der Kreisbogen? ${SATZ_2}`, r: '120/360*2*P*9',
  weg: 'Anteil: 120° von 360° = 1/3 (nicht als 0,33 runden).\nb = 1/3 · 2 · π · 9 cm = 6 · π cm ≈ {A} cm (π-Taste).\nMit π ≈ 3,14: b = 6 · 3,14 cm = {B} cm.',
  ke: [['zu_frueh_gerundet', '0.33*2*P*9', 'Den Anteil 1/3 auf 0,33 gerundet und damit weitergerechnet.', 'Was passiert, wenn du 1/3 als Bruch stehen lässt?'],
    ['kreisanteil_falsch', '2*P*9', 'Den ganzen Umfang angegeben, der Anteil 120°/360° fehlt.', 'Welcher Teil des ganzen Kreises ist der Ausschnitt?'],
    ['flaeche_statt_umfang', '120/360*P*9^2', 'Die Fläche des Ausschnitts berechnet statt des Bogens.', 'Ist eine Länge oder eine Fläche gefragt?'],
    ['pi_vergessen', '120/360*2*9', 'π weggelassen: 1/3 · 18 = 6.', 'Welcher Faktor fehlt in der Umfangsformel?']] });
def({ ...SE, ref: 'kreis-sektor-04', titel: 'Kreisausschnitt · Radius 5 m, 72°', einheit: 'm²', afb: 'II', sach: false,
  afbGrund: 'Anwenden: Anteil 72°/360° muss erst gekürzt werden (1/5).',
  frage: `Ein Kreisausschnitt hat den Radius 5 m und den Mittelpunktswinkel 72°.\n\nWie groß ist sein Flächeninhalt? ${SATZ_2}`, r: '72/360*P*5^2',
  weg: 'Anteil: 72° von 360° = 1/5.\nA = 1/5 · π · (5 m)² = 5 · π m² ≈ {A} m² (π-Taste).\nMit π ≈ 3,14: A = 5 · 3,14 m² = {B} m².',
  ke: [['kreisanteil_falsch', 'P*5^2', 'Die ganze Kreisfläche angegeben, der Anteil 72°/360° fehlt.', 'Welcher Teil des ganzen Kreises ist der Ausschnitt?'],
    ['kreisanteil_falsch', '360/72*P*5^2', 'Den Anteil umgedreht: mal 5 statt mal 1/5.', 'Ist der Ausschnitt größer oder kleiner als der ganze Kreis?'],
    ['umfang_statt_flaeche', '72/360*2*P*5', 'Den Kreisbogen berechnet statt der Fläche.', 'Ist eine Länge oder eine Fläche gefragt?'],
    ['pi_vergessen', '72/360*5^2', 'π weggelassen: 1/5 · 25 = 5.', 'Welcher Faktor fehlt in der Flächenformel?']] });
def({ ...SE, ref: 'kreis-sektor-05', titel: 'Kreisausschnitt · Tortenstück, 26 cm Durchmesser, 12 Stücke', einheit: 'cm²', afb: 'II', sach: true,
  afbGrund: 'Anwenden im Sachkontext: Anteil aus der Stückzahl, Radius aus dem Durchmesser.',
  frage: `Eine runde Torte hat einen Durchmesser von 26 cm. Sie wird in 12 gleich große Stücke geschnitten.\n\nWie groß ist die Oberseite eines Stücks in Quadratzentimetern? ${SATZ_2}`, r: '1/12*P*13^2',
  weg: 'r = 26 cm : 2 = 13 cm. Ein Stück ist 1/12 der Torte (30° von 360°).\nA = 1/12 · π · (13 cm)² = 1/12 · π · 169 cm² ≈ {A} cm² (π-Taste).\nMit π ≈ 3,14: A = 1/12 · 3,14 · 169 cm² ≈ {B} cm².',
  ke: [['radius_durchmesser_verwechselt', '1/12*P*26^2', 'Den Durchmesser als Radius eingesetzt: π · 26².', 'Sind 26 cm der Radius oder der Durchmesser der Torte?'],
    ['kreisanteil_falsch', 'P*13^2', 'Die ganze Torte berechnet, der Anteil 1/12 fehlt.', 'Wie viel von der Torte ist ein Stück?'],
    ['zu_frueh_gerundet', '0.08*P*13^2', 'Den Anteil 1/12 auf 0,08 gerundet und damit weitergerechnet.', 'Was passiert, wenn du 1/12 als Bruch stehen lässt?'],
    ['pi_vergessen', '1/12*13^2', 'π weggelassen: 169 : 12.', 'Welcher Faktor fehlt in der Flächenformel?']] });
def({ ...SE, ref: 'kreis-sektor-06', titel: 'Kreisausschnitt · Winkel aus 12,56 cm Bogen bei Radius 10 cm', einheit: '°', afb: 'III', sach: false, n: 0,
  afbGrund: 'Problemlösen: Rückrichtung im Sektor – Anteil aus Bogen und Umfang bilden, dann in Grad umrechnen.',
  frage: `Ein Kreisbogen gehört zu einem Kreis mit dem Radius 10 cm. Der Bogen ist 12,56 cm lang.\n\nWie groß ist der Mittelpunktswinkel? ${SATZ_PI} Runde auf ganze Grad.`, r: '12.56/(2*P*10)*360',
  weg: 'Umfang: U = 2 · π · 10 cm ≈ 62,83 cm (mit 3,14: 62,8 cm).\nAnteil: 12,56 : 62,83 ≈ 0,2 (mit 3,14: genau 0,2).\nα = 0,2 · 360° ≈ {A}°.',
  ke: [['falsche_groesse_beantwortet', '12.56/(2*P*10)', 'Den Anteil angegeben statt des Winkels.', 'Ist nach dem Anteil oder nach dem Winkel in Grad gefragt?', 2],
    ['radius_durchmesser_verwechselt', '12.56/(P*10)*360', 'Den Radius als Durchmesser eingesetzt: Umfang nur π · 10.', 'Ist 10 cm der Radius oder der Durchmesser?'],
    ['pi_vergessen', '12.56/20*360', 'π weggelassen: Umfang als 2 · 10 gerechnet.', 'Welcher Faktor fehlt in der Umfangsformel?']] });

// ── stabile ids ────────────────────────────────────────────────────────────────
const IDS_PFAD = 'docs/prefill/k9-kreis-ids.json';
const IDS = fs.existsSync(IDS_PFAD) ? JSON.parse(fs.readFileSync(IDS_PFAD, 'utf8')) : {};
for (const a of A) IDS[a.ref] ??= crypto.randomUUID();
fs.writeFileSync(IDS_PFAD, JSON.stringify(IDS, null, 1) + '\n');

// ── Charge bauen ───────────────────────────────────────────────────────────────
const fehler = [];
const slugsVerwendet = new Map();
const aufgaben = A.map((a, i) => {
  const wo = a.ref;
  const richtig = Object.fromEntries(WEGE.map(([k, p]) => [k, wert(a.r, p, a.n, wo, fehler)]));
  const correct = [...new Set([...formen(richtig.pi, a.einheit), ...formen(richtig['314'], a.einheit)])];
  const known = {};
  const pruefung = WEGE.map(([k, p]) => pruef(a.r, p, a.n, richtig[k], null, wo));
  for (const [slug, expr, , , modus] of a.ke) {
    for (const [k, p] of WEGE) {
      const w = wert(expr, p, modus ?? a.n, `${wo} ${slug}`, fehler);
      pruefung.push(pruef(expr, p, modus ?? a.n, w, `fehlbild:${slug}:${k}`, wo));
      for (const f of formen(w, a.einheit)) {
        if (correct.includes(f)) fehler.push(`${wo}: falscher Wert ${f} (${slug}) ist eine richtige Antwort`);
        if (known[f] && known[f] !== slug) fehler.push(`${wo}: Wert ${f} mit zwei Slugs (${known[f]}, ${slug})`);
        known[f] = slug;
      }
    }
    if (!slugsVerwendet.has(slug)) slugsVerwendet.set(slug, new Set());
    slugsVerwendet.get(slug).add(a.ref);
  }
  const weg = a.weg.replaceAll('{A}', richtig.pi).replaceAll('{B}', richtig['314']);
  const prozess = a.afb === 'III' ? 'Problemlösen, Operieren' : a.sach ? 'Modellieren, Operieren' : 'Operieren';
  return {
    nr: i + 1,
    id: IDS[a.ref],
    titel: a.titel,
    basis: { skill_key: a.skill, source_ref: a.ref, input_type: 'NUMERIC', unit: a.einheit, frage: a.frage, known_errors: known },
    felder: {
      afb: { wert: a.afb, sicher: 'mittel', grund: a.afbGrund },
      est_duration_sec: { wert: ZEIT[a.afb] + (a.sach ? SACH : 0), sicher: 'mittel', grund: `Zeitregel: AFB ${a.afb}${a.sach ? ' + Sachkontext' : ', kein Sachkontext'}.` },
      curriculum_grade: { wert: 9, sicher: 'hoch', grund: 'Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Geo-3/Geo-4.' },
      cluster_id: { wert: GEO, sicher: 'hoch', grund: 'Geometrie & Messen wie geo_umfang und geo_flaeche_* im Bestand.' },
      competency_content: { wert: 'geometrie', sicher: 'hoch', grund: 'Inhaltsfeld Geometrie (Geo-3).' },
      competency_process: { wert: prozess, sicher: 'mittel', grund: a.afb === 'III' ? 'Lösungsweg selbst finden, dann rechnen.'
        : a.sach ? 'Sachsituation in eine Kreisformel übersetzen, dann rechnen.' : 'Rechnen nach festem Verfahren.' },
      needs_image: { wert: false, sicher: 'hoch', grund: 'Alle Angaben stehen im Text, keine Abbildung nötig.' },
    },
    loesung: {
      correct_answers: { wert: correct, sicher: 'hoch', grund: 'Exakt nachgerechnet mit π-Taste und mit 3,14; Schreibweisen mit Komma/Punkt, Endnull und Einheit.' },
      solution: { wert: weg, sicher: 'hoch', grund: 'Nachgerechnet.' },
      typical_errors: { wert: a.ke.map(([, , error, socratic_question]) => ({ error, socratic_question })), sicher: 'hoch',
        grund: `Aus acceptance.known_errors (${[...new Set(a.ke.map((k) => k[0]))].join(', ')}).` },
    },
    leer: { hints: 'Auftrag W1-3: ohne Hilfe lösbar (LSA), keine Hinweise.' },
    pruefung,
  };
});

const NEU = ['radius_durchmesser_verwechselt', 'pi_vergessen', 'kreisanteil_falsch'];
for (const s of NEU) if ((slugsVerwendet.get(s)?.size ?? 0) < 3) fehler.push(`Fehlbild ${s} in weniger als drei Aufgaben`);
if (fehler.length) { console.error('Charge abgelehnt:\n  ' + [...new Set(fehler)].join('\n  ')); process.exit(1); }

const charge = {
  batch: 'k9-kreis',
  kopf: [
    `K9 Kreis, Migration 2 von 2 — ${aufgaben.length} Aufgaben: je sechs zu geo_kreis_umfang, _flaeche, _rueck und _sektor.`,
    'Erzeugt von tools/vorlauf-build.mjs aus docs/prefill/k9-kreis.json (Quelle: tools/k9-kreis-charge.mjs) — nicht von Hand editieren.',
    '',
    'Einspiel-Reihenfolge: nach <...>_substrat_k9_kreis.sql (Knoten + Fehlbild-Slugs muessen stehen).',
    'geo_kreis_zusammen bekommt hier KEINE Aufgaben (Abbildungen; Generator specs/active/figur-kreis.md fehlt).',
  ],
  auswahl: 'Je Knoten vier reine Anwendung mit steigender Schwierigkeit und zwei mit Sachkontext oder Rückrichtung (Fahrradrad, Pizza, Baumstamm, runder Tisch, Torte, Winkel aus dem Bogen). Alle ohne Abbildung lösbar. Jede Aufgabe nennt π-Taste oder 3,14 und die Rundung; beide Ergebnisse stehen als Varianten in correct_answers und acceptance.equivalents (exakter Textvergleich, keine Toleranz).',
  source: 'edvance_k9_kreis',
  class_level: 9,
  acceptance_equivalents: true,
  zeitregel: { beschreibung: 'est_duration_sec wie Pilot/Vorlauf/Zins: AFB I 45 s, II 60 s, III 90 s; +30 s bei Sachkontext.', basis: ZEIT, sachkontext_zuschlag: SACH },
  aufgaben,
};
fs.writeFileSync('docs/prefill/k9-kreis.json', JSON.stringify(charge, null, 1) + '\n');
console.log(`docs/prefill/k9-kreis.json: ${aufgaben.length} Aufgaben`);
for (const [s, refs] of [...slugsVerwendet].sort()) console.log(`  ${s}: ${refs.size} Aufgaben`);
