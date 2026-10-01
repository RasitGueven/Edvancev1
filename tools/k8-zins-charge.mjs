#!/usr/bin/env node
/**
 * k8-zins-charge.mjs — erzeugt docs/prefill/k8-zins.json (Charge-Format von vorlauf-build.mjs)
 * aus den Aufgabendefinitionen unten. Jede Antwort und jeder falsche Wert wird vor dem Schreiben
 * mit prefill-rechnen exakt nachgerechnet; weicht etwas ab, bricht das Skript ab.
 *
 *   node tools/k8-zins-charge.mjs            # schreibt die Charge (ids bleiben stabil)
 *
 * Die ids stehen fest in IDS unten: ein zweiter Lauf erzeugt dieselbe Charge.
 */

import fs from 'node:fs';
import { zahl } from './prefill-rechnen.mjs';

const ZAHL_RECHNEN = 'e7108c9a-d19e-4021-8499-55b4f3d5d70c'; // Themengebiet „Zahl & Rechnen"
const ZEIT = { I: 45, II: 60, III: 90 };
const SACH = 30;

// ── Schreibweisen ──────────────────────────────────────────────────────────────
// Bewertung (lsa_grade mit canonical) vergleicht Zahlen; lsa_fehlbild_match und der
// Rueckfall lsa_is_correct vergleichen Text (trim, Komma->Punkt, lower). Deshalb je Wert:
// mit/ohne Endnull bei Cent, mit Punkt, mit Einheit (mit und ohne Leerzeichen).
const komma = (s) => s.replace('.', ',');
function formen(wert, einheit) {
  const s = komma(String(wert));
  const basis = [s];
  const m = s.match(/^(\d+),(\d)0$/);
  if (m) basis.push(`${m[1]},${m[2]}`);               // 44,10 -> 44,1
  if (/^\d+,\d$/.test(s) && einheit === '€') basis.push(`${s}0`); // 44,1 -> 44,10
  const out = [];
  for (const b of basis) {
    out.push(b);
    if (b.includes(',')) out.push(b.replace(',', '.'));
  }
  if (einheit) for (const b of basis) out.push(`${b} ${einheit}`, `${b}${einheit}`);
  return [...new Set(out)];
}

// ── Aufgaben ───────────────────────────────────────────────────────────────────
// r: Rechnung zur richtigen Antwort (Punkt als Dezimaltrenner, round(x,2) = kaufmaennisch)
// ke: [falscher Wert, Slug, Rechnung, Fehlertext, sokratische Frage]
const A = [];
const def = (o) => A.push(o);

// ─── prozent_zins_jahreszins (Tiefe 7) ───
def({ ref: 'zins-jahreszins-01', skill: 'prozent_zins_jahreszins', titel: 'Jahreszinsen · Guthaben 600 € zu 3 %',
  frage: 'Ein Guthaben von 600 € wird ein Jahr lang mit einem Zinssatz von 3 % verzinst.\n\nWie viel Euro Zinsen gibt es nach einem Jahr?',
  einheit: '€', afb: 'I', afbGrund: 'Reproduzieren: Prozentwert mit ganzzahligem Zinssatz, ein Schritt.',
  sach: false, prozess: 'Operieren', antwort: '18', r: '600*3/100',
  weg: 'Jahreszinsen = Kapital · p/100\nZ = 600 € · 3/100 = 18 €.',
  ke: [
    ['1800', 'dezimalverschiebung', '600*3', 'Mit 3 statt mit 3/100 gerechnet: 600 · 3 = 1800.', 'Wie viel sind 3 % – 3 Ganze oder 3 Hundertstel?'],
    ['618', 'falsche_groesse_beantwortet', '600+600*3/100', 'Neuen Kontostand statt der Zinsen angegeben: 600 + 18 = 618.', 'Gefragt sind die Zinsen – ist das der ganze Kontostand oder nur der Teil, der dazukommt?'],
  ] });
def({ ref: 'zins-jahreszins-02', skill: 'prozent_zins_jahreszins', titel: 'Jahreszinsen · Guthaben 850 € zu 2 %',
  frage: 'Ein Guthaben von 850 € wird ein Jahr lang mit einem Zinssatz von 2 % verzinst.\n\nWie viel Euro Zinsen gibt es nach einem Jahr?',
  einheit: '€', afb: 'I', afbGrund: 'Reproduzieren: Prozentwert, ein Schritt; Kapital nicht rund.',
  sach: false, prozess: 'Operieren', antwort: '17', r: '850*2/100',
  weg: 'Z = 850 € · 2/100 = 17 €.',
  ke: [
    ['1700', 'dezimalverschiebung', '850*2', 'Mit 2 statt mit 2/100 gerechnet: 850 · 2 = 1700.', 'Wie viel sind 2 % von 100 €? Passt das zu deinem Ergebnis?'],
    ['867', 'falsche_groesse_beantwortet', '850+850*2/100', 'Neuen Kontostand statt der Zinsen angegeben: 850 + 17 = 867.', 'Gefragt sind die Zinsen – welcher Teil deiner Rechnung ist neu dazugekommen?'],
  ] });
def({ ref: 'zins-jahreszins-03', skill: 'prozent_zins_jahreszins', titel: 'Jahreszinsen · Guthaben 640 € zu 2,5 %',
  frage: 'Ein Guthaben von 640 € wird ein Jahr lang mit einem Zinssatz von 2,5 % verzinst.\n\nWie viel Euro Zinsen gibt es nach einem Jahr?',
  einheit: '€', afb: 'II', afbGrund: 'Anwenden: Zinssatz als Dezimalzahl, Prozentwert nicht im Kopf ablesbar.',
  sach: false, prozess: 'Operieren', antwort: '16', r: '640*2.5/100',
  weg: 'Z = 640 € · 2,5/100 = 640 € · 0,025 = 16 €.',
  ke: [
    ['1600', 'dezimalverschiebung', '640*2.5', 'Mit 2,5 statt mit 2,5/100 gerechnet: 640 · 2,5 = 1600.', 'Was bedeutet „Prozent" – von wie vielen Teilen ist die Rede?'],
    ['656', 'falsche_groesse_beantwortet', '640+640*2.5/100', 'Neuen Kontostand statt der Zinsen angegeben: 640 + 16 = 656.', 'Sind die Zinsen der ganze Betrag auf dem Konto oder nur das, was dazukommt?'],
  ] });
def({ ref: 'zins-jahreszins-04', skill: 'prozent_zins_jahreszins', titel: 'Jahreszinsen · Kontostand nach einem Jahr · 480 € zu 3,5 %',
  frage: 'Auf ein Sparkonto werden 480 € eingezahlt. Der Zinssatz beträgt 3,5 % pro Jahr. Die Zinsen werden nach einem Jahr dem Konto gutgeschrieben.\n\nWie viel Euro sind nach einem Jahr auf dem Konto?',
  einheit: '€', afb: 'II', afbGrund: 'Anwenden: zwei Schritte (Zinsen, dann Kontostand); Ergebnis mit Cent.',
  sach: false, prozess: 'Operieren', antwort: '496,80', r: '480+480*3.5/100',
  weg: 'Zinsen: 480 € · 3,5/100 = 16,80 €.\nKontostand: 480 € + 16,80 € = 496,80 €.\n(Oder in einem Schritt: 480 € · 1,035 = 496,80 €.)',
  ke: [
    ['16,80', 'nur_prozentwert', '480*3.5/100', 'Nur die Zinsen angegeben (16,80 €), nicht den Kontostand.', 'Was steht nach einem Jahr auf dem Konto – nur die Zinsen oder auch das eingezahlte Geld?'],
    ['2160', 'dezimalverschiebung', '480+480*3.5', 'Mit 3,5 statt mit 3,5/100 gerechnet: 480 + 480 · 3,5 = 2160.', 'Kann das Geld in einem Jahr mit 3,5 % auf mehr als das Vierfache wachsen?'],
  ] });
def({ ref: 'zins-jahreszins-05', skill: 'prozent_zins_jahreszins', titel: 'Jahreszinsen · Kredit 900 € zu 6 % · Rückzahlung',
  frage: 'Für einen Kredit über 900 € verlangt ein Händler 6 % Zinsen pro Jahr. Nach einem Jahr wird der Kredit zusammen mit den Zinsen auf einmal zurückgezahlt.\n\nWie viel Euro werden insgesamt zurückgezahlt?',
  einheit: '€', afb: 'II', afbGrund: 'Anwenden im Sachkontext Kredit: Rückzahlung = Kredit + Zinsen, die Situation muss übersetzt werden.',
  sach: true, prozess: 'Modellieren, Operieren', antwort: '954', r: '900+900*6/100',
  weg: 'Zinsen: 900 € · 6/100 = 54 €.\nRückzahlung: 900 € + 54 € = 954 €.',
  ke: [
    ['54', 'nur_prozentwert', '900*6/100', 'Nur die Zinsen angegeben (54 €), nicht den ganzen Rückzahlungsbetrag.', 'Was muss nach einem Jahr zurückgegeben werden – nur die Zinsen oder auch das geliehene Geld?'],
    ['6300', 'dezimalverschiebung', '900+900*6', 'Mit 6 statt mit 6/100 gerechnet: 900 + 900 · 6 = 6300.', 'Wären 6 % Zinsen mehr als das Sechsfache des Kredits?'],
  ] });
def({ ref: 'zins-jahreszins-06', skill: 'prozent_zins_jahreszins', titel: 'Jahreszinsen · zwei Sparangebote vergleichen · 750 €',
  frage: 'Für 750 € gibt es zwei Sparangebote für ein Jahr:\nAngebot A: 2 % Zinsen.\nAngebot B: 1,5 % Zinsen und zusätzlich 5 € Bonus.\n\nUm wie viel Euro bringt das bessere Angebot mehr als das andere?',
  einheit: '€', afb: 'III', afbGrund: 'Problemlösen: zwei Angebote modellieren, den Bonus einbeziehen, vergleichen und die Differenz bilden – Rechenweg selbst wählen.',
  sach: true, prozess: 'Problemlösen, Modellieren', antwort: '1,25', r: '(750*1.5/100+5)-(750*2/100)',
  weg: 'Angebot A: 750 € · 2/100 = 15 €.\nAngebot B: 750 € · 1,5/100 + 5 € = 11,25 € + 5 € = 16,25 €.\nB bringt mehr: 16,25 € − 15 € = 1,25 €.',
  ke: [
    ['3,75', 'bedingung_unvollstaendig', '750*2/100-750*1.5/100', 'Bonus nicht berücksichtigt: 15 − 11,25 = 3,75.', 'Welche Angabe zu Angebot B hast du noch nicht verwendet?'],
    ['16,25', 'falsche_groesse_beantwortet', '750*1.5/100+5', 'Den Ertrag von Angebot B angegeben statt des Unterschieds.', 'Gefragt ist, um wie viel B mehr bringt – was musst du dafür noch rechnen?'],
  ] });

// ─── prozent_zins_teilzins (Tiefe 8) ───
def({ ref: 'zins-teilzins-01', skill: 'prozent_zins_teilzins', titel: 'Teilzinsen · 600 € zu 4 % für 3 Monate',
  frage: 'Ein Guthaben von 600 € wird mit einem Zinssatz von 4 % pro Jahr verzinst. Das Geld bleibt nur 3 Monate auf dem Konto.\n\nWie viel Euro Zinsen gibt es für diese 3 Monate?',
  einheit: '€', afb: 'I', afbGrund: 'Reproduzieren: Jahreszinsen, dann ein glatter Zeitanteil (ein Viertel Jahr).',
  sach: false, prozess: 'Operieren', antwort: '6', r: '600*4/100*3/12',
  weg: 'Jahreszinsen: 600 € · 4/100 = 24 €.\n3 Monate sind 3/12 = 1/4 Jahr.\nZinsen: 24 € · 3/12 = 6 €.',
  ke: [
    ['24', 'zeitfaktor_vergessen', '600*4/100', 'Zinsen für ein ganzes Jahr angegeben: 24 €.', 'Für wie lange gilt der Zinssatz von 4 % – und wie lange liegt das Geld auf dem Konto?'],
    ['0,72', 'zinszeit_falsch_umgerechnet', '600*4/100*3/100', 'Monate durch 100 statt durch 12 geteilt: 24 · 3/100 = 0,72.', 'Wie viele Monate hat ein Jahr?'],
  ] });
def({ ref: 'zins-teilzins-02', skill: 'prozent_zins_teilzins', titel: 'Teilzinsen · 800 € zu 3 % für 5 Monate',
  frage: 'Ein Guthaben von 800 € wird mit einem Zinssatz von 3 % pro Jahr verzinst. Das Geld bleibt 5 Monate auf dem Konto.\n\nWie viel Euro Zinsen gibt es für diese 5 Monate?',
  einheit: '€', afb: 'I', afbGrund: 'Reproduzieren: wie Teilzins-01, Zeitanteil 5/12 ergibt glatt 10 €.',
  sach: false, prozess: 'Operieren', antwort: '10', r: '800*3/100*5/12',
  weg: 'Jahreszinsen: 800 € · 3/100 = 24 €.\nZinsen für 5 Monate: 24 € · 5/12 = 10 €.',
  ke: [
    ['24', 'zeitfaktor_vergessen', '800*3/100', 'Zinsen für ein ganzes Jahr angegeben: 24 €.', 'Liegt das Geld ein ganzes Jahr auf dem Konto?'],
    ['120', 'zinszeit_falsch_umgerechnet', '800*3/100*5', 'Mit 5 Jahren statt 5 Monaten gerechnet: 24 · 5 = 120.', 'Sind 5 Monate mehr oder weniger als ein Jahr?'],
    ['1,2', 'zinszeit_falsch_umgerechnet', '800*3/100*5/100', 'Monate durch 100 statt durch 12 geteilt: 24 · 5/100 = 1,2.', 'Welcher Teil eines Jahres sind 5 Monate?'],
  ] });
def({ ref: 'zins-teilzins-03', skill: 'prozent_zins_teilzins', titel: 'Teilzinsen · 720 € zu 5 % für 40 Tage',
  frage: 'Ein Guthaben von 720 € wird mit einem Zinssatz von 5 % pro Jahr verzinst. Das Geld bleibt 40 Tage auf dem Konto.\nRechne wie bei Banken üblich: 1 Monat = 30 Tage, 1 Jahr = 360 Tage.\n\nWie viel Euro Zinsen gibt es für diese 40 Tage?',
  einheit: '€', afb: 'II', afbGrund: 'Anwenden: Zeitanteil in Tagen nach der 360-Tage-Konvention.',
  sach: false, prozess: 'Operieren', antwort: '4', r: '720*5/100*40/360',
  weg: 'Jahreszinsen: 720 € · 5/100 = 36 €.\n40 Tage sind 40/360 Jahr.\nZinsen: 36 € · 40/360 = 4 €.',
  ke: [
    ['36', 'zeitfaktor_vergessen', '720*5/100', 'Zinsen für ein ganzes Jahr angegeben: 36 €.', 'Für welchen Zeitraum gilt der Zinssatz – und wie lange liegt das Geld auf dem Konto?'],
    ['14,40', 'zinszeit_falsch_umgerechnet', '720*5/100*40/100', 'Tage durch 100 statt durch 360 geteilt: 36 · 40/100 = 14,40.', 'Wie viele Tage hat ein Zinsjahr laut Aufgabe?'],
    ['1440', 'zinszeit_falsch_umgerechnet', '720*5/100*40', 'Mit 40 Jahren statt 40 Tagen gerechnet: 36 · 40 = 1440.', 'Sind 40 Tage mehr oder weniger als ein Jahr?'],
  ] });
def({ ref: 'zins-teilzins-04', skill: 'prozent_zins_teilzins', titel: 'Teilzinsen · 900 € zu 2,5 % für 8 Monate',
  frage: 'Ein Guthaben von 900 € wird mit einem Zinssatz von 2,5 % pro Jahr verzinst. Das Geld bleibt 8 Monate auf dem Konto.\n\nWie viel Euro Zinsen gibt es für diese 8 Monate?',
  einheit: '€', afb: 'II', afbGrund: 'Anwenden: Dezimal-Zinssatz und Zeitanteil 8/12, der als Dezimalzahl nicht aufgeht.',
  sach: false, prozess: 'Operieren', antwort: '15', r: '900*2.5/100*8/12',
  weg: 'Jahreszinsen: 900 € · 2,5/100 = 22,50 €.\nZinsen für 8 Monate: 22,50 € · 8/12 = 15 €.\n(Den Zeitanteil 8/12 als Bruch stehen lassen, nicht vorher runden.)',
  ke: [
    ['22,50', 'zeitfaktor_vergessen', '900*2.5/100', 'Zinsen für ein ganzes Jahr angegeben: 22,50 €.', 'Wie lange liegt das Geld auf dem Konto – und für wie lange gilt der Zinssatz?'],
    ['1,80', 'zinszeit_falsch_umgerechnet', '900*2.5/100*8/100', 'Monate durch 100 statt durch 12 geteilt: 22,50 · 8/100 = 1,80.', 'Welcher Bruchteil eines Jahres sind 8 Monate?'],
    ['15,08', 'zu_frueh_gerundet', 'round(900*2.5/100*0.67,2)', 'Zeitanteil 8/12 auf 0,67 gerundet und weitergerechnet: 22,50 · 0,67 = 15,08 (gerundet).', 'Was passiert mit dem Ergebnis, wenn du 8/12 vor dem Multiplizieren rundest?'],
  ] });
def({ ref: 'zins-teilzins-05', skill: 'prozent_zins_teilzins', titel: 'Teilzinsen · überzogenes Konto · 500 € zu 12 % für 50 Tage',
  frage: 'Ein Girokonto ist 50 Tage lang um 500 € überzogen. Für die Überziehung verlangt die Bank 12 % Zinsen pro Jahr.\nRechne wie bei Banken üblich: 1 Monat = 30 Tage, 1 Jahr = 360 Tage. Runde das Ergebnis auf Cent.\n\nWie viel Euro Zinsen muss man für die 50 Tage zahlen?',
  einheit: '€', afb: 'II', afbGrund: 'Anwenden im Sachkontext Überziehung: Situation übersetzen, Tage-Konvention, Rundung erst am Ende.',
  sach: true, prozess: 'Modellieren, Operieren', antwort: '8,33', r: 'round(500*12/100*50/360,2)',
  weg: 'Jahreszinsen: 500 € · 12/100 = 60 €.\nZinsen für 50 Tage: 60 € · 50/360 = 8,333… €.\nAuf Cent gerundet: 8,33 €.',
  ke: [
    ['60', 'zeitfaktor_vergessen', '500*12/100', 'Zinsen für ein ganzes Jahr angegeben: 60 €.', 'Wie lange war das Konto überzogen?'],
    ['30', 'zinszeit_falsch_umgerechnet', '500*12/100*50/100', 'Tage durch 100 statt durch 360 geteilt: 60 · 50/100 = 30.', 'Wie viele Tage zählt ein Zinsjahr laut Aufgabe?'],
    ['8,40', 'zu_frueh_gerundet', '500*12/100*0.14', 'Zeitanteil 50/360 auf 0,14 gerundet: 60 · 0,14 = 8,40.', 'Wann solltest du runden – beim Zeitanteil oder erst beim Ergebnis?'],
  ] });
def({ ref: 'zins-teilzins-06', skill: 'prozent_zins_teilzins', titel: 'Teilzinsen · Fahrrad finanziert · 840 € zu 9 % für 7 Monate',
  frage: 'Ein Fahrrad kostet 840 €. Der Händler bietet an, den Preis erst später zu bezahlen. Dafür verlangt er 9 % Zinsen pro Jahr. Nach 7 Monaten wird alles auf einmal bezahlt.\n\nWie viel Euro werden insgesamt bezahlt?',
  einheit: '€', afb: 'III', afbGrund: 'Problemlösen im Sachkontext Ratenkauf: Teilzinsen mit Zeitanteil 7/12, danach zum Preis addieren; mehrere Schritte selbst ordnen.',
  sach: true, prozess: 'Modellieren, Operieren', antwort: '884,10', r: '840+840*9/100*7/12',
  weg: 'Jahreszinsen: 840 € · 9/100 = 75,60 €.\nZinsen für 7 Monate: 75,60 € · 7/12 = 44,10 €.\nGesamt: 840 € + 44,10 € = 884,10 €.',
  ke: [
    ['44,10', 'nur_prozentwert', '840*9/100*7/12', 'Nur die Zinsen angegeben (44,10 €), nicht den Gesamtbetrag.', 'Was wird nach 7 Monaten bezahlt – nur die Zinsen oder auch das Fahrrad?'],
    ['915,60', 'zeitfaktor_vergessen', '840+840*9/100', 'Zinsen für ein ganzes Jahr gerechnet: 840 + 75,60 = 915,60.', 'Für wie viele Monate fallen Zinsen an?'],
    ['883,85', 'zu_frueh_gerundet', '840+round(840*9/100*0.58,2)', 'Zeitanteil 7/12 auf 0,58 gerundet: 75,60 · 0,58 ≈ 43,85, also 883,85.', 'Was ändert sich, wenn du 7/12 als Bruch stehen lässt?'],
  ] });

// ─── prozent_zins_rueckrechnung (Tiefe 8) ───
def({ ref: 'zins-rueckrechnung-01', skill: 'prozent_zins_rueckrechnung', titel: 'Rückrechnung · Kapital aus 28 € Zinsen bei 4 %',
  frage: 'Ein Guthaben bringt bei einem Zinssatz von 4 % in einem Jahr 28 € Zinsen.\n\nWie viel Euro beträgt das Guthaben?',
  einheit: '€', afb: 'I', afbGrund: 'Reproduzieren: Grundwert aus Prozentwert und glattem Prozentsatz.',
  sach: false, prozess: 'Operieren', antwort: '700', r: '28*100/4', probe: 'A*4/100', probeSoll: '28',
  weg: '4 % des Guthabens sind 28 €.\n1 % sind 28 € : 4 = 7 €.\n100 % sind 7 € · 100 = 700 €.\nProbe: 700 € · 4/100 = 28 €.',
  ke: [
    ['1,12', 'multipliziert_statt_dividiert', '28*4/100', 'Multipliziert statt dividiert: 28 · 4/100 = 1,12.', 'Ist das Guthaben größer oder kleiner als die Zinsen?'],
    ['7', 'faktor_100_vergessen', '28/4', 'Nur 1 % ausgerechnet: 28 : 4 = 7.', 'Für wie viel Prozent steht dein Ergebnis?'],
  ] });
def({ ref: 'zins-rueckrechnung-02', skill: 'prozent_zins_rueckrechnung', titel: 'Rückrechnung · Zinssatz aus 15 € Zinsen bei 500 €',
  frage: 'Ein Guthaben von 500 € bringt in einem Jahr 15 € Zinsen.\n\nWie hoch ist der Zinssatz in Prozent?',
  einheit: '%', afb: 'I', afbGrund: 'Reproduzieren: Prozentsatz aus zwei glatten Werten.',
  sach: false, prozess: 'Operieren', antwort: '3', r: '15/500*100',
  weg: 'p % = Zinsen : Kapital = 15 € : 500 € = 0,03 = 3 %.',
  ke: [
    ['0,03', 'faktor_100_vergessen', '15/500', 'Als Dezimalzahl stehen gelassen: 0,03 statt 3 %.', 'Wie schreibst du 0,03 in Prozent?'],
    ['33,33', 'bezug_vertauscht', 'round(500/15,2)', 'Kapital durch Zinsen geteilt: 500 : 15 ≈ 33,33.', 'Welcher Betrag ist der Anteil und welcher das Ganze?'],
    ['33,3', 'bezug_vertauscht', 'round(500/15,1)', 'Kapital durch Zinsen geteilt: 500 : 15 ≈ 33,3.', 'Welcher Betrag ist der Anteil und welcher das Ganze?'],
  ] });
def({ ref: 'zins-rueckrechnung-03', skill: 'prozent_zins_rueckrechnung', titel: 'Rückrechnung · Kapital aus 21 € Zinsen bei 3,5 %',
  frage: 'Ein Guthaben bringt bei einem Zinssatz von 3,5 % in einem Jahr 21 € Zinsen.\n\nWie viel Euro beträgt das Guthaben?',
  einheit: '€', afb: 'II', afbGrund: 'Anwenden: Grundwert mit Dezimal-Zinssatz, Dreisatz nicht im Kopf.',
  sach: false, prozess: 'Operieren', antwort: '600', r: '21*100/3.5', probe: 'A*3.5/100', probeSoll: '21',
  weg: 'Kapital = Zinsen : p/100 = 21 € : 0,035 = 600 €.\nProbe: 600 € · 3,5/100 = 21 €.',
  ke: [
    ['0,735', 'multipliziert_statt_dividiert', '21*3.5/100', 'Multipliziert statt dividiert: 21 · 3,5/100 = 0,735.', 'Muss das Guthaben größer oder kleiner sein als 21 €?'],
    ['73,5', 'multipliziert_statt_dividiert', '21*3.5', 'Multipliziert statt dividiert: 21 · 3,5 = 73,5.', 'Wenn du die Probe machst: Ergeben 3,5 % von deinem Ergebnis wirklich 21 €?'],
    ['6', 'faktor_100_vergessen', '21/3.5', 'Nur 1 % ausgerechnet: 21 : 3,5 = 6.', 'Für wie viel Prozent steht dein Ergebnis?'],
  ] });
def({ ref: 'zins-rueckrechnung-04', skill: 'prozent_zins_rueckrechnung', titel: 'Rückrechnung · Zinssatz aus 20,80 € Zinsen bei 640 €',
  frage: 'Ein Guthaben von 640 € bringt in einem Jahr 20,80 € Zinsen.\n\nWie hoch ist der Zinssatz in Prozent?',
  einheit: '%', afb: 'II', afbGrund: 'Anwenden: Prozentsatz mit Cent-Betrag, Ergebnis ist ein Dezimal-Zinssatz.',
  sach: false, prozess: 'Operieren', antwort: '3,25', r: '20.8/640*100',
  weg: 'p % = 20,80 € : 640 € = 0,0325 = 3,25 %.',
  ke: [
    ['0,0325', 'faktor_100_vergessen', '20.8/640', 'Als Dezimalzahl stehen gelassen: 0,0325 statt 3,25 %.', 'Wie wird aus 0,0325 eine Prozentangabe?'],
    ['30,77', 'bezug_vertauscht', 'round(640/20.8,2)', 'Kapital durch Zinsen geteilt: 640 : 20,80 ≈ 30,77.', 'Welcher Betrag ist der Grundwert?'],
    ['30,8', 'bezug_vertauscht', 'round(640/20.8,1)', 'Kapital durch Zinsen geteilt: 640 : 20,80 ≈ 30,8.', 'Welcher Betrag ist der Grundwert?'],
  ] });
def({ ref: 'zins-rueckrechnung-05', skill: 'prozent_zins_rueckrechnung', titel: 'Rückrechnung · Einzahlung aus Kontostand 765 € bei 2 %',
  frage: 'Auf einem Sparkonto stehen nach einem Jahr 765 €. Die Zinsen von 2 % sind darin schon enthalten.\n\nWie viel Euro wurden am Anfang eingezahlt?',
  einheit: '€', afb: 'III', afbGrund: 'Problemlösen: Rückrichtung über den Wachstumsfaktor 1,02 – der naheliegende Weg (2 % vom Endbetrag abziehen) ist falsch und muss erkannt werden.',
  sach: true, prozess: 'Problemlösen, Operieren', antwort: '750', r: '765/1.02', probe: 'A*1.02', probeSoll: '765',
  weg: 'Der Kontostand ist 102 % der Einzahlung: Einzahlung · 1,02 = 765 €.\nEinzahlung = 765 € : 1,02 = 750 €.\nProbe: 750 € + 2 % von 750 € = 750 € + 15 € = 765 €.',
  ke: [
    ['749,70', 'grundwert_verwechselt', '765-765*2/100', '2 % vom Endbetrag abgezogen: 765 − 15,30 = 749,70.', 'Von welchem Betrag wurden die 2 % Zinsen berechnet – vom Anfangs- oder vom Endbetrag?'],
    ['780,30', 'multipliziert_statt_dividiert', '765*1.02', 'Mit 1,02 multipliziert statt dividiert: 765 · 1,02 = 780,30.', 'War am Anfang mehr oder weniger Geld auf dem Konto als nach einem Jahr?'],
  ] });
def({ ref: 'zins-rueckrechnung-06', skill: 'prozent_zins_rueckrechnung', titel: 'Rückrechnung · Zinssatz eines Kredits · 400 € geliehen, 428 € zurück',
  frage: 'Für einen Kredit über 400 € müssen nach einem Jahr 428 € zurückgezahlt werden.\n\nWie hoch ist der Zinssatz in Prozent?',
  einheit: '%', afb: 'II', afbGrund: 'Anwenden im Sachkontext Kredit: erst die Zinsen als Differenz bestimmen, dann den Prozentsatz.',
  sach: true, prozess: 'Modellieren, Operieren', antwort: '7', r: '(428-400)/400*100',
  weg: 'Zinsen: 428 € − 400 € = 28 €.\nZinssatz: 28 € : 400 € = 0,07 = 7 %.',
  ke: [
    ['107', 'falsche_groesse_beantwortet', '428/400*100', 'Rückzahlung als Prozent des Kredits angegeben (107 %) statt des Zinssatzes.', 'Welcher Teil der 107 % sind die Zinsen?'],
    ['0,07', 'faktor_100_vergessen', '28/400', 'Als Dezimalzahl stehen gelassen: 0,07 statt 7 %.', 'Wie schreibst du 0,07 in Prozent?'],
    ['6,54', 'grundwert_verwechselt', 'round(28/428*100,2)', 'Zinsen auf den Rückzahlungsbetrag bezogen: 28 : 428 ≈ 6,54 %.', 'Auf welchen Betrag bezieht sich der Zinssatz – das Geliehene oder das Zurückgezahlte?'],
  ] });

// ─── prozent_zins_zinseszins (Tiefe 9) ───
def({ ref: 'zins-zinseszins-01', skill: 'prozent_zins_zinseszins', titel: 'Zinseszins · 500 € zu 4 % für 2 Jahre',
  frage: 'Ein Guthaben von 500 € wird jedes Jahr mit 4 % verzinst. Die Zinsen bleiben auf dem Konto und werden im nächsten Jahr mitverzinst.\n\nWie viel Euro sind nach 2 Jahren auf dem Konto?',
  einheit: '€', afb: 'I', afbGrund: 'Reproduzieren: zwei Jahre, Jahr für Jahr oder mit dem Faktor 1,04².',
  sach: false, prozess: 'Operieren', antwort: '540,80', r: '500*1.04^2',
  weg: 'Nach 1 Jahr: 500 € · 1,04 = 520 €.\nNach 2 Jahren: 520 € · 1,04 = 540,80 €.\n(Oder: 500 € · 1,04² = 500 € · 1,0816 = 540,80 €.)',
  ke: [
    ['540', 'prozente_addiert', '500+2*500*4/100', 'Jedes Jahr nur 4 % vom Startkapital: 500 + 20 + 20 = 540.', 'Wovon werden im zweiten Jahr die 4 % berechnet?'],
    ['40,80', 'nur_prozentwert', '500*1.04^2-500', 'Nur die Zinsen angegeben (40,80 €), nicht den Kontostand.', 'Was steht nach 2 Jahren auf dem Konto?'],
    ['980', 'wachstumsfaktor_falsch', '500*1.4^2', 'Faktor 1,4 statt 1,04: 500 · 1,4² = 980.', 'Welcher Faktor gehört zu einer Zunahme um 4 %?'],
  ] });
def({ ref: 'zins-zinseszins-02', skill: 'prozent_zins_zinseszins', titel: 'Zinseszins · 800 € zu 5 % für 3 Jahre',
  frage: 'Ein Guthaben von 800 € wird jedes Jahr mit 5 % verzinst. Die Zinsen bleiben auf dem Konto und werden mitverzinst.\n\nWie viel Euro sind nach 3 Jahren auf dem Konto?',
  einheit: '€', afb: 'II', afbGrund: 'Anwenden: drei Jahre, Faktor 1,05³ bzw. drei Schritte; Ergebnis mit Cent.',
  sach: false, prozess: 'Operieren', antwort: '926,10', r: '800*1.05^3',
  weg: 'Nach 1 Jahr: 800 € · 1,05 = 840 €.\nNach 2 Jahren: 840 € · 1,05 = 882 €.\nNach 3 Jahren: 882 € · 1,05 = 926,10 €.\n(Oder: 800 € · 1,05³ = 800 € · 1,157625 = 926,10 €.)',
  ke: [
    ['920', 'prozente_addiert', '800+3*800*5/100', 'Jedes Jahr nur 5 % vom Startkapital: 800 + 3 · 40 = 920.', 'Wovon werden im dritten Jahr die 5 % berechnet?'],
    ['126,10', 'nur_prozentwert', '800*1.05^3-800', 'Nur die Zinsen angegeben (126,10 €), nicht den Kontostand.', 'Was steht nach 3 Jahren auf dem Konto?'],
    ['926,40', 'zu_frueh_gerundet', '800*1.158', 'Faktor 1,157625 auf 1,158 gerundet: 800 · 1,158 = 926,40.', 'Rechne Jahr für Jahr nach: Geht jedes Jahr glatt auf?'],
    ['928', 'zu_frueh_gerundet', '800*1.16', 'Faktor 1,157625 auf 1,16 gerundet: 800 · 1,16 = 928.', 'Wann darfst du runden – vor oder nach dem Multiplizieren?'],
    ['2700', 'wachstumsfaktor_falsch', '800*1.5^3', 'Faktor 1,5 statt 1,05: 800 · 1,5³ = 2700.', 'Welcher Faktor gehört zu einer Zunahme um 5 %?'],
  ] });
def({ ref: 'zins-zinseszins-03', skill: 'prozent_zins_zinseszins', titel: 'Zinseszins · Zinsen nach 2 Jahren · 600 € zu 3 %',
  frage: 'Ein Guthaben von 600 € wird jedes Jahr mit 3 % verzinst. Die Zinsen bleiben auf dem Konto und werden mitverzinst.\n\nWie viel Euro Zinsen sind nach 2 Jahren insgesamt dazugekommen?',
  einheit: '€', afb: 'II', afbGrund: 'Anwenden: Zinseszins über zwei Jahre, dann die Zinsen als Differenz – gefragt ist nicht der Kontostand.',
  sach: false, prozess: 'Operieren', antwort: '36,54', r: '600*1.03^2-600',
  weg: 'Nach 1 Jahr: 600 € · 1,03 = 618 €.\nNach 2 Jahren: 618 € · 1,03 = 636,54 €.\nZinsen insgesamt: 636,54 € − 600 € = 36,54 €.',
  ke: [
    ['36', 'prozente_addiert', '2*600*3/100', 'Zweimal 3 % vom Startkapital: 18 + 18 = 36.', 'Bekommen auch die Zinsen aus dem ersten Jahr im zweiten Jahr Zinsen?'],
    ['636,54', 'falsche_groesse_beantwortet', '600*1.03^2', 'Kontostand statt der Zinsen angegeben: 636,54.', 'Gefragt sind nur die Zinsen – was musst du vom Kontostand noch abziehen?'],
    ['414', 'wachstumsfaktor_falsch', '600*1.3^2-600', 'Faktor 1,3 statt 1,03: 600 · 1,3² − 600 = 414.', 'Welcher Faktor gehört zu einer Zunahme um 3 %?'],
  ] });
def({ ref: 'zins-zinseszins-04', skill: 'prozent_zins_zinseszins', titel: 'Zinseszins · Laufzeit durch Probieren · 500 € zu 10 % über 700 €',
  frage: 'Ein Guthaben von 500 € wird jedes Jahr mit 10 % verzinst. Die Zinsen bleiben auf dem Konto und werden mitverzinst.\n\nNach wie vielen Jahren ist das Guthaben zum ersten Mal größer als 700 €?',
  einheit: 'Jahre', afb: 'III', afbGrund: 'Problemlösen (Ari-8): die Hochzahl ist gesucht und wird durch systematisches Probieren Jahr für Jahr gefunden.',
  sach: false, prozess: 'Problemlösen, Operieren', antwort: '4', r: '4',
  tabelle: [['500*1.1^3', '665.5'], ['500*1.1^4', '732.05']],
  weg: 'Jahr für Jahr mit dem Faktor 1,1 probieren:\n| Jahre | Guthaben |\n| 1 | 500 € · 1,1 = 550 € |\n| 2 | 550 € · 1,1 = 605 € |\n| 3 | 605 € · 1,1 = 665,50 € (noch nicht über 700 €) |\n| 4 | 665,50 € · 1,1 = 732,05 € (zum ersten Mal über 700 €) |\nNach 4 Jahren.',
  ke: [
    ['5', 'prozente_addiert', '(700-500)/(500*10/100)+1', 'Jedes Jahr nur 50 € (10 % vom Start) gerechnet: nach 4 Jahren genau 700, erst nach 5 Jahren mehr.', 'Bleiben die Zinsen jedes Jahr gleich, wenn sie mitverzinst werden?'],
  ] });
def({ ref: 'zins-zinseszins-05', skill: 'prozent_zins_zinseszins', titel: 'Kombinierte Veränderung · Preis +20 %, dann −20 % · 400 €',
  frage: 'Ein Fahrrad kostet 400 €. Der Preis wird zuerst um 20 % erhöht. Später wird der neue Preis um 20 % gesenkt.\n\nWie viel Euro kostet das Fahrrad danach?',
  einheit: '€', afb: 'II', afbGrund: 'Anwenden (Fkt-9): zwei Veränderungen nacheinander, die zweite bezieht sich auf den neuen Preis.',
  sach: true, prozess: 'Modellieren, Operieren', antwort: '384', r: '400*1.2*0.8',
  weg: 'Erhöhung: 400 € · 1,2 = 480 €.\nSenkung vom neuen Preis: 480 € · 0,8 = 384 €.\n(Oder: 400 € · 1,2 · 0,8 = 400 € · 0,96 = 384 €.)\nDer Preis ist also nicht wieder 400 €.',
  ke: [
    ['400', 'prozente_addiert', '400*(1+20/100-20/100)', 'Plus 20 % und minus 20 % gegeneinander aufgehoben: wieder 400 €.', 'Von welchem Preis werden die 20 % beim Senken berechnet?'],
    ['320', 'grundwert_verwechselt', '400*0.8', 'Die Senkung auf den alten Preis bezogen: 400 · 0,8 = 320.', 'Welcher Preis gilt, wenn gesenkt wird – der alte oder der erhöhte?'],
    ['480', 'bedingung_unvollstaendig', '400*1.2', 'Nur die Erhöhung gerechnet: 480 €.', 'Welche Preisänderung aus dem Text fehlt noch?'],
  ] });
def({ ref: 'zins-zinseszins-06', skill: 'prozent_zins_zinseszins', titel: 'Zinseszins · Zinssatz gesucht · 500 € werden in 2 Jahren 551,25 €',
  frage: 'Ein Guthaben wächst in 2 Jahren von 500 € auf 551,25 €. Der Zinssatz ist in beiden Jahren gleich, die Zinsen bleiben auf dem Konto.\n\nWie hoch ist der Zinssatz in Prozent?',
  einheit: '%', afb: 'III', afbGrund: 'Problemlösen: Rückrichtung über den Wachstumsfaktor – 1,1025 muss als 1,05² erkannt werden (Probieren mit Faktoren).',
  sach: false, prozess: 'Problemlösen, Operieren', antwort: '5', r: '5', probe: '500*(1+A/100)^2', probeSoll: '551.25',
  weg: 'Gesamtfaktor: 551,25 € : 500 € = 1,1025.\nGesucht ist q mit q · q = 1,1025.\nProbieren: 1,04² = 1,0816 (zu klein), 1,05² = 1,1025 (passt).\nq = 1,05, also 5 %.\nProbe: 500 € · 1,05 = 525 €, 525 € · 1,05 = 551,25 €.',
  ke: [
    ['5,125', 'prozente_addiert', '(551.25-500)/500*100/2', 'Gesamtzunahme halbiert: 10,25 % : 2 = 5,125 %.', 'Bekommen die Zinsen des ersten Jahres im zweiten Jahr wieder Zinsen?'],
    ['10,25', 'falsche_groesse_beantwortet', '(551.25-500)/500*100', 'Die Zunahme über beide Jahre zusammen angegeben (10,25 %), nicht den Zinssatz pro Jahr.', 'Gilt der gesuchte Zinssatz für beide Jahre zusammen oder für jedes Jahr?'],
    ['1,05', 'wachstumsfaktor_falsch', '1.05', 'Den Faktor 1,05 als Zinssatz angegeben.', 'Wie viel Prozent Zunahme stecken im Faktor 1,05?'],
  ] });

// ─── potenzen (Auffuellung, Tiefe 4) ───
const POT = { skill: 'potenzen', einheit: null, sach: false, prozess: 'Operieren', inhalt: 'arithmetik_algebra' };
def({ ...POT, ref: 'zins-potenzen-01', titel: 'Potenzen · 4³',
  frage: 'Berechne.\n\n4³ = ?', afb: 'I', afbGrund: 'Reproduzieren: Potenz mit natürlicher Basis und Hochzahl 3.',
  antwort: '64', r: '4^3', weg: '4³ = 4 · 4 · 4 = 16 · 4 = 64.',
  ke: [
    ['12', 'mal_exponent', '4*3', 'Basis mal Hochzahl: 4 · 3 = 12.', 'Was bedeutet die kleine 3 – wie oft wird 4 mit sich selbst multipliziert?'],
    ['81', 'basis_exponent_vertauscht', '3^4', 'Basis und Hochzahl vertauscht: 3⁴ = 81.', 'Welche Zahl wird multipliziert, und wie oft?'],
  ] });
def({ ...POT, ref: 'zins-potenzen-02', titel: 'Potenzen · 0,4²',
  frage: 'Berechne.\n\n0,4² = ?', afb: 'I', afbGrund: 'Reproduzieren: Quadrat einer Dezimalzahl mit einer Nachkommastelle.',
  antwort: '0,16', r: '0.4^2', weg: '0,4² = 0,4 · 0,4 = 0,16.\n(4 · 4 = 16, und das Ergebnis hat zwei Nachkommastellen.)',
  ke: [
    ['0,8', 'mal_exponent', '0.4*2', 'Basis mal Hochzahl: 0,4 · 2 = 0,8.', 'Was bedeutet die kleine 2 – womit wird 0,4 multipliziert?'],
    ['1,6', 'kommastellen_zu_wenig', '0.4^2*10', 'Komma falsch gesetzt: 1,6 statt 0,16.', 'Wie viele Nachkommastellen haben die beiden Faktoren zusammen?'],
  ] });
def({ ...POT, ref: 'zins-potenzen-03', titel: 'Potenzen · 2,5²',
  frage: 'Berechne.\n\n2,5² = ?', afb: 'II', afbGrund: 'Anwenden: Quadrat einer Dezimalzahl, das Ergebnis hat zwei Nachkommastellen und ist nicht auswendig bekannt.',
  antwort: '6,25', r: '2.5^2', weg: '2,5² = 2,5 · 2,5 = 6,25.',
  ke: [
    ['5', 'mal_exponent', '2.5*2', 'Basis mal Hochzahl: 2,5 · 2 = 5.', 'Was bedeutet die kleine 2 – womit wird 2,5 multipliziert?'],
    ['4,25', 'quadrat_gliedweise', '2^2+0.5^2', 'Ganzen Teil und Nachkommateil einzeln quadriert: 2² + 0,5² = 4,25.', 'Wenn du 2,5 · 2,5 ausführlich rechnest: Welche Teilprodukte entstehen?'],
  ] });
def({ ...POT, ref: 'zins-potenzen-04', titel: 'Potenzen · 1,05²',
  frage: 'Berechne.\n\n1,05² = ?', afb: 'II', afbGrund: 'Anwenden: Quadrat einer Dezimalzahl mit zwei Nachkommastellen (Wachstumsfaktor).',
  antwort: '1,1025', r: '1.05^2', weg: '1,05² = 1,05 · 1,05 = 1,1025.',
  ke: [
    ['2,1', 'mal_exponent', '1.05*2', 'Basis mal Hochzahl: 1,05 · 2 = 2,1.', 'Was bedeutet die kleine 2 – womit wird 1,05 multipliziert?'],
    ['1,0025', 'quadrat_gliedweise', '1^2+0.05^2', 'Gliedweise quadriert: 1² + 0,05² = 1,0025 – das mittlere Glied fehlt.', 'Rechne 1,05 · 1,05 ausführlich: Wie viele Teilprodukte entstehen?'],
  ] });
def({ ...POT, ref: 'zins-potenzen-05', titel: 'Potenzen · 1,05³',
  frage: 'Berechne.\n\n1,05³ = ?', afb: 'II', afbGrund: 'Anwenden: dritte Potenz einer Dezimalzahl, zwei Multiplikationen nacheinander.',
  antwort: '1,157625', r: '1.05^3', weg: '1,05² = 1,05 · 1,05 = 1,1025.\n1,05³ = 1,1025 · 1,05 = 1,157625.',
  ke: [
    ['3,15', 'mal_exponent', '1.05*3', 'Basis mal Hochzahl: 1,05 · 3 = 3,15.', 'Was bedeutet die kleine 3 – wie oft steht 1,05 als Faktor da?'],
    ['1,1025', 'basis_exponent_vertauscht', '1.05^2', 'Nur zweimal statt dreimal mit 1,05 multipliziert: 1,05² = 1,1025.', 'Wie viele Faktoren 1,05 gehören zu 1,05³?'],
  ] });
def({ ...POT, ref: 'zins-potenzen-06', titel: 'Potenzen · Würfelvolumen · Kante 0,4 m', sach: true, prozess: 'Modellieren, Operieren',
  frage: 'Ein würfelförmiger Karton hat die Kantenlänge 0,4 m. Für das Volumen gilt V = a³.\n\nWie viele Kubikmeter beträgt das Volumen?',
  einheit: 'm³', afb: 'II', afbGrund: 'Anwenden im Sachkontext: Formel gegeben, dritte Potenz einer Dezimalzahl mit Kommaverschiebung.',
  antwort: '0,064', r: '0.4^3', weg: 'V = a³ = 0,4³ = 0,4 · 0,4 · 0,4 = 0,16 · 0,4 = 0,064.\nDas Volumen beträgt 0,064 m³.',
  ke: [
    ['1,2', 'mal_exponent', '0.4*3', 'Basis mal Hochzahl: 0,4 · 3 = 1,2.', 'Was bedeutet a³ – wie oft wird a mit sich selbst multipliziert?'],
    ['0,64', 'kommastellen_zu_wenig', '0.4^3*10', 'Komma falsch gesetzt: 0,64 statt 0,064.', 'Wie viele Nachkommastellen haben drei Faktoren 0,4 zusammen?'],
  ] });

// ── stabile ids ────────────────────────────────────────────────────────────────
const IDS_PFAD = 'docs/prefill/k8-zins-ids.json';
const IDS = fs.existsSync(IDS_PFAD) ? JSON.parse(fs.readFileSync(IDS_PFAD, 'utf8')) : {};
for (const a of A) IDS[a.ref] ??= crypto.randomUUID();
fs.writeFileSync(IDS_PFAD, JSON.stringify(IDS, null, 1) + '\n');

// ── Charge bauen ───────────────────────────────────────────────────────────────
const fehler = [];
const punkt = (s) => s.replace(',', '.');
const nachgerechnet = (rechnung, soll, wo) => {
  const ist = zahl(rechnung), sollQ = zahl(punkt(soll));
  if (!ist.eq(sollQ)) fehler.push(`${wo}: ${rechnung} = ${ist}, nicht ${soll}`);
};
const slugsVerwendet = new Map();

const aufgaben = A.map((a, i) => {
  const wo = a.ref;
  const istZins = a.skill.startsWith('prozent_zins_');
  nachgerechnet(a.r, a.antwort, wo);
  if (a.probe) {
    const ist = zahl(a.probe.replace(/A/g, punkt(a.antwort))), soll = zahl(punkt(a.probeSoll));
    if (!ist.eq(soll)) fehler.push(`${wo}: Probe ${a.probe} = ${ist}, nicht ${a.probeSoll}`);
  }
  const known = {};
  for (const [wert, slug, rechnung] of a.ke) {
    nachgerechnet(rechnung, wert, `${wo} known_error ${slug}`);
    if (zahl(punkt(wert)).eq(zahl(punkt(a.antwort)))) fehler.push(`${wo}: falscher Wert ${wert} = richtige Antwort`);
    for (const f of formen(wert, a.einheit)) {
      if (known[f] && known[f] !== slug) fehler.push(`${wo}: Wert ${f} mit zwei Slugs`);
      known[f] = slug;
    }
    if (!slugsVerwendet.has(slug)) slugsVerwendet.set(slug, new Set());
    slugsVerwendet.get(slug).add(a.ref);
  }
  const zeit = ZEIT[a.afb] + (a.sach ? SACH : 0);
  const inhalt = a.inhalt ?? 'funktionen';
  const pruefung = [{ rechnung: a.r, antwort: a.antwort }];
  if (a.probe) pruefung.push({ probe: a.probe, antwort: a.antwort, soll: punkt(a.probeSoll), rolle: 'probe' });
  for (const [rechnung, wert] of a.tabelle ?? []) {
    nachgerechnet(rechnung, wert, `${wo} Probier-Tabelle`);
    pruefung.push({ rechnung, antwort: wert, rolle: 'probier-tabelle' });
  }
  for (const [wert, slug, rechnung] of a.ke) pruefung.push({ rechnung, antwort: wert, rolle: `fehlbild:${slug}` });
  return {
    nr: i + 1,
    id: IDS[a.ref],
    titel: a.titel,
    basis: {
      skill_key: a.skill, source_ref: a.ref, input_type: 'NUMERIC',
      ...(a.einheit ? { unit: a.einheit } : {}),
      frage: a.frage, known_errors: known,
    },
    felder: {
      afb: { wert: a.afb, sicher: 'mittel', grund: a.afbGrund },
      est_duration_sec: { wert: zeit, sicher: 'mittel', grund: `Zeitregel: AFB ${a.afb}${a.sach ? ' + Sachkontext' : ', kein Sachkontext'}.` },
      curriculum_grade: { wert: 7, sicher: 'hoch', grund: istZins
        ? 'Stoffanker Klasse 7: Erste Stufe (Fkt-8/Fkt-9/Ari-8); Kölner Gymnasien behandeln Zinsrechnung in Klasse 7.'
        : 'Stoffanker Klasse 7 wie alle potenzen-Aufgaben im Bestand.' },
      cluster_id: { wert: ZAHL_RECHNEN, sicher: 'hoch', grund: istZins
        ? 'Zahl & Rechnen wie die Prozent-Voraussetzungen (Entscheidung Rasit, Phase 0).'
        : 'Zahl & Rechnen wie alle potenzen-Aufgaben im Bestand.' },
      competency_content: { wert: inhalt, sicher: 'hoch', grund: istZins
        ? 'Inhaltsfeld Funktionen: KLP G9 führt Prozent- und Zinsrechnung unter Fkt-8/Fkt-9.'
        : 'Inhaltsfeld Arithmetik/Algebra wie alle potenzen-Aufgaben im Bestand.' },
      competency_process: { wert: a.prozess, sicher: 'mittel', grund: a.sach
        ? 'Sachsituation in eine Rechnung übersetzen, dann rechnen.'
        : a.prozess.startsWith('Problemlösen') ? 'Lösungsweg selbst finden, dann rechnen.' : 'Rechnen nach festem Verfahren.' },
      needs_image: { wert: false, sicher: 'hoch', grund: 'Alle Angaben stehen im Text, keine Abbildung nötig.' },
    },
    loesung: {
      correct_answers: { wert: formen(a.antwort, a.einheit), sicher: 'hoch', grund: 'Nachgerechnet; Schreibweisen mit Komma/Punkt, Endnull und Einheit.' },
      solution: { wert: a.weg, sicher: 'hoch', grund: 'Nachgerechnet.' },
      typical_errors: {
        wert: a.ke.map(([, , , error, socratic_question]) => ({ error, socratic_question })),
        sicher: 'hoch',
        grund: `Aus acceptance.known_errors (${[...new Set(a.ke.map((k) => k[1]))].join(', ')}).`,
      },
    },
    leer: { hints: 'Auftrag W1-2: ohne Hilfe lösbar (LSA), keine Hinweise.' },
    pruefung,
  };
});

// Jedes neue Fehlbild in mindestens drei Aufgaben
const NEU = ['zeitfaktor_vergessen', 'zinszeit_falsch_umgerechnet', 'prozente_addiert', 'wachstumsfaktor_falsch', 'zu_frueh_gerundet'];
for (const s of NEU) {
  const n = slugsVerwendet.get(s)?.size ?? 0;
  if (n < 3) fehler.push(`Fehlbild ${s} nur in ${n} Aufgaben`);
}
if (fehler.length) { console.error('Charge abgelehnt:\n  ' + fehler.join('\n  ')); process.exit(1); }

const charge = {
  batch: 'k8-zins',
  kopf: [
    `K8 Zinsrechnung, Migration 2 von 2 — ${aufgaben.length} Aufgaben: je sechs zu den vier prozent_zins_*-Knoten, sechs zur Auffuellung von potenzen.`,
    'Erzeugt von tools/vorlauf-build.mjs aus docs/prefill/k8-zins.json (Quelle: tools/k8-zins-charge.mjs) — nicht von Hand editieren.',
    '',
    'Einspiel-Reihenfolge: nach 20261001123347_substrat_k8_zins.sql (Knoten + Fehlbild-Slugs muessen stehen).',
  ],
  auswahl: 'Neue Aufgaben: je Zins-Knoten vier reine Anwendung mit steigender Schwierigkeit und zwei mit Sachkontext oder Rückrichtung (Sparen, Kredit, Ratenkauf, Überziehung, Preisänderung); dazu sechs potenzen-Aufgaben (Hochzahl 2 und 3, Dezimalbasis, Wachstumsfaktor), die auch der Kreis-Lauf nutzt. Teilzinsen nach kaufmännischer Konvention (30/360) im Aufgabentext; Zinseszins-Endkapital höchstens drei Jahre; alle Beträge unter 1000 €.',
  source: 'edvance_k8_zins',
  ohne_sondierrang: ['potenzen'],
  zeitregel: {
    beschreibung: 'est_duration_sec wie im Pilot/Vorlauf: AFB I 45 s, AFB II 60 s, AFB III 90 s; +30 s bei Sachkontext (Konsumsituation, die erst übersetzt werden muss). Nüchterne Zinsaufgaben mit Kapital und Zinssatz zählen als reine Anwendung.',
    basis: ZEIT,
    sachkontext_zuschlag: SACH,
  },
  aufgaben,
};
fs.writeFileSync('docs/prefill/k8-zins.json', JSON.stringify(charge, null, 1) + '\n');
console.log(`docs/prefill/k8-zins.json: ${aufgaben.length} Aufgaben`);
for (const s of NEU) console.log(`  ${s}: ${[...slugsVerwendet.get(s)].length} Aufgaben`);
