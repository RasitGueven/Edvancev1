#!/usr/bin/env node
/**
 * k9-bedingt-charge.mjs — erzeugt docs/prefill/k9-bedingt.json (Charge-Format von vorlauf-build.mjs).
 *
 *   node tools/k9-bedingt-charge.mjs
 *
 * K9-Rest, Thema bedingt: Vierfeldertafel, bedingte Wahrscheinlichkeit, Unabhängigkeit, Umkehrung
 * in Testsituationen, irreführende Darstellungen. Der Tablet-Player zeigt den Aufgabentext als
 * REINEN TEXT (keine Markdown-Tabelle). Eine Vierfeldertafel steht deshalb als Liste benannter
 * Felder da, eine Zeile je Feld bzw. Summe („Mädchen mit Haustier: 48"), gesuchte Felder mit „?"
 * und als MULTI_PART-Teil mit genau diesem Namen. Alle Daten sind frei erfunden. Jeder Wert wird
 * über die Ausdrücke von tools/k9-rest-lib.mjs exakt gerechnet.
 */

import { baueCharge, CLUSTER } from './k9-rest-lib.mjs';

const EXAKT = 'Gib das Ergebnis exakt an.';
const GANZ = 'Gib jeweils die Anzahl als ganze Zahl an.';
const PROZ1 = 'Gib die Zahl ohne %-Zeichen an und runde auf eine Stelle nach dem Komma.';
const DEZ2 = 'Gib die Wahrscheinlichkeit als Dezimalzahl an und runde auf zwei Stellen nach dem Komma.';
const STO = {
  cluster: CLUSTER.daten, inhalt: 'stochastik', stoff: 9,
  stoffGrund: 'Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Sto-3/Sto-4/Sto-5 (Vierfeldertafel, bedingte Wahrscheinlichkeit, Darstellungen beurteilen).',
  clusterGrund: 'Daten & Zufall wie die Stochastik-Knoten im Bestand.',
  inhaltGrund: 'Inhaltsfeld Stochastik (Sto-3 bis Sto-5).',
};
const A = [];
const def = (o) => A.push({ ...STO, n: 'exakt', ...o });

// Vollständige Tafeln, die mehrfach vorkommen
const TAFEL_HAUSTIER = 'Mädchen mit Haustier: 48\nMädchen ohne Haustier: 62\nJungen mit Haustier: 60\nJungen ohne Haustier: 30\n'
  + 'Mädchen insgesamt: 110\nJungen insgesamt: 90\nMit Haustier insgesamt: 108\nOhne Haustier insgesamt: 92\nAlle Befragten: 200';

// ─── stoch_bedingt_vierfeld (Tiefe 5) ───
const VF = { skill: 'stoch_bedingt_vierfeld' };
def({ ...VF, ref: 'bedingt-vierfeld-01', titel: 'Vierfeldertafel · Haustier, zwei Felder', afb: 'I', sach: false,
  afbGrund: 'Reproduzieren: je ein fehlendes Feld als Randsumme minus bekanntes Feld.',
  frage: `In einer Befragung wurden 200 Jugendliche gefragt, ob sie ein Haustier haben.\nMädchen mit Haustier: 48\nMädchen ohne Haustier: ?\nJungen mit Haustier: ?\nJungen ohne Haustier: 30\nMädchen insgesamt: 110\nMit Haustier insgesamt: 108\nAlle Befragten: 200\n\nErgänze die beiden fehlenden Felder. ${GANZ}`,
  teile: [
    { prompt: 'Mädchen ohne Haustier', r: '110-48', n: 'exakt',
      ke: [['randsumme_verwechselt', '108-48', 'Von der falschen Summe abgezogen: „Mit Haustier insgesamt“ statt „Mädchen insgesamt“: 108 − 48.', 'Zu welcher Summe gehören die Mädchen ohne Haustier – zu allen Mädchen oder zu allen mit Haustier?'],
        ['falsche_operation', '110+48', 'Addiert statt subtrahiert: 110 + 48.', 'Können die Mädchen ohne Haustier mehr sein als alle Mädchen zusammen?']] },
    { prompt: 'Jungen mit Haustier', r: '108-48', n: 'exakt',
      ke: [['randsumme_verwechselt', '110-48', 'Von der falschen Summe abgezogen: „Mädchen insgesamt“ statt „Mit Haustier insgesamt“: 110 − 48.', 'Welche Summe besteht aus Mädchen mit Haustier und Jungen mit Haustier?'],
        ['falsche_operation', '108+48', 'Addiert statt subtrahiert: 108 + 48.', 'Können die Jungen mit Haustier mehr sein als alle mit Haustier?']] },
  ],
  weg: 'Mädchen ohne Haustier = Mädchen insgesamt − Mädchen mit Haustier = 110 − 48 = {1}.\nJungen mit Haustier = Mit Haustier insgesamt − Mädchen mit Haustier = 108 − 48 = {2}.\nProbe: Jungen insgesamt = 200 − 110 = 90 = 60 + 30.' });
def({ ...VF, ref: 'bedingt-vierfeld-02', titel: 'Vierfeldertafel · Bus und Stufe, drei Felder', afb: 'I', sach: false,
  afbGrund: 'Reproduzieren: drei fehlende Felder nacheinander über Randsummen.',
  frage: `Eine Schule hat 300 Schülerinnen und Schüler gefragt, ob sie mit dem Bus zur Schule kommen.\nUnterstufe mit Bus: 72\nUnterstufe ohne Bus: ?\nOberstufe mit Bus: ?\nOberstufe ohne Bus: ?\nUnterstufe insgesamt: 160\nMit Bus insgesamt: 126\nAlle Befragten: 300\n\nErgänze die drei fehlenden Felder. ${GANZ}`,
  teile: [
    { prompt: 'Unterstufe ohne Bus', r: '160-72', n: 'exakt',
      ke: [['randsumme_verwechselt', '126-72', 'Von „Mit Bus insgesamt“ statt von „Unterstufe insgesamt“ abgezogen: 126 − 72.', 'Welche Summe besteht aus Unterstufe mit Bus und Unterstufe ohne Bus?'],
        ['falsche_operation', '160+72', 'Addiert statt subtrahiert: 160 + 72.', 'Kann ein Teil der Unterstufe größer sein als die ganze Unterstufe?']] },
    { prompt: 'Oberstufe mit Bus', r: '126-72', n: 'exakt',
      ke: [['randsumme_verwechselt', '160-72', 'Von „Unterstufe insgesamt“ statt von „Mit Bus insgesamt“ abgezogen: 160 − 72.', 'Welche Summe besteht aus Unterstufe mit Bus und Oberstufe mit Bus?'],
        ['falsche_operation', '126+72', 'Addiert statt subtrahiert: 126 + 72.', 'Kann ein Teil der Busfahrer größer sein als alle Busfahrer?']] },
    { prompt: 'Oberstufe ohne Bus', r: '300-160-(126-72)', n: 'exakt',
      ke: [['falsche_groesse_beantwortet', '300-160', 'Die ganze Oberstufe angegeben statt nur die Oberstufe ohne Bus.', 'Sind in deiner Zahl auch die Oberstufenschüler mit Bus enthalten?'],
        ['randsumme_verwechselt', '126-(126-72)', 'Von „Mit Bus insgesamt“ abgezogen statt von „Oberstufe insgesamt“: 126 − 54.', 'Zu welcher Summe gehört das Feld „Oberstufe ohne Bus“ – zu den Busfahrern?']] },
  ],
  weg: 'Unterstufe ohne Bus = 160 − 72 = {1}.\nOberstufe mit Bus = 126 − 72 = {2}.\nOberstufe insgesamt = 300 − 160 = 140, also Oberstufe ohne Bus = 140 − 54 = {3}.\nProbe: Ohne Bus insgesamt = 88 + 86 = 174 = 300 − 126.' });
def({ ...VF, ref: 'bedingt-vierfeld-03', titel: 'Vierfeldertafel · Feld und relative Häufigkeit', afb: 'II', sach: false,
  afbGrund: 'Anwenden: fehlendes Feld ergänzen und als relative Häufigkeit (Anteil an allen) mit Rundung angeben.',
  frage: `Eine Gärtnerei hat 250 Pflanzen beobachtet. Ein Teil wurde gedüngt.\nGedüngt, blüht: 86\nGedüngt, blüht nicht: ?\nNicht gedüngt, blüht: ?\nNicht gedüngt, blüht nicht: ?\nGedüngt insgesamt: 120\nBlüht insgesamt: 140\nAlle Pflanzen: 250\n\nGib die Anzahl im Feld „Nicht gedüngt, blüht“ an und dann die relative Häufigkeit dieses Feldes bezogen auf alle 250 Pflanzen als Dezimalzahl, gerundet auf zwei Stellen nach dem Komma.`,
  teile: [
    { prompt: 'Nicht gedüngt, blüht (Anzahl)', r: '140-86', n: 'exakt',
      ke: [['randsumme_verwechselt', '120-86', 'Von „Gedüngt insgesamt“ statt von „Blüht insgesamt“ abgezogen: 120 − 86.', 'Welche Summe besteht aus „Gedüngt, blüht“ und „Nicht gedüngt, blüht“?'],
        ['falsche_operation', '140+86', 'Addiert statt subtrahiert: 140 + 86.', 'Kann ein Teil der blühenden Pflanzen mehr sein als alle blühenden?']] },
    { prompt: 'Relative Häufigkeit von „Nicht gedüngt, blüht“ (Dezimalzahl, zwei Stellen)', r: '(140-86)/250', n: 2,
      ke: [['randsumme_verwechselt', '(120-86)/250', 'Mit dem falsch ergänzten Feld 120 − 86 = 34 weitergerechnet: 34 : 250.', 'Stimmt die Anzahl, die du durch 250 geteilt hast?'],
        ['bezug_vertauscht', '250/(140-86)', 'Den Kehrwert gebildet: 250 : 54.', 'Kann ein Anteil an allen Pflanzen größer als 1 sein?'],
        ['dezimalverschiebung', '(140-86)/250*100', 'Als Prozentzahl statt als Dezimalzahl angegeben: 21,6.', 'Ist nach Prozent oder nach einer Dezimalzahl zwischen 0 und 1 gefragt?', 1]] },
  ],
  weg: 'Nicht gedüngt, blüht = Blüht insgesamt − Gedüngt, blüht = 140 − 86 = {1}.\nRelative Häufigkeit = 54 : 250 = 0,216 ≈ {2}.' });
def({ ...VF, ref: 'bedingt-vierfeld-04', titel: 'Vierfeldertafel · aus Prozentangaben, Werkstücke', afb: 'II', sach: false,
  afbGrund: 'Anwenden: Felder erst aus Prozentangaben bestimmen, dann über Randsummen ergänzen.',
  frage: `Eine Fabrik prüft 400 Werkstücke. 60 % davon stammen von Maschine A, der Rest von Maschine B. Von den Werkstücken aus Maschine A sind 5 % fehlerhaft. Insgesamt sind 26 Werkstücke fehlerhaft.\n\nBestimme die drei Felder der Vierfeldertafel. ${GANZ}`,
  teile: [
    { prompt: 'Fehlerhafte Werkstücke von Maschine A', r: '400*60/100*5/100', n: 'exakt',
      ke: [['grundwert_verwechselt', '400*5/100', '5 % von allen 400 Werkstücken genommen statt von den 240 aus Maschine A.', 'Worauf beziehen sich die 5 % – auf alle Werkstücke oder nur auf die von Maschine A?'],
        ['dezimalverschiebung', '400*60/100*50/100', '5 % als 0,5 gerechnet statt als 0,05: 240 · 0,5.', 'Wie schreibt man 5 % als Dezimalzahl?']] },
    { prompt: 'Fehlerhafte Werkstücke von Maschine B', r: '26-400*60/100*5/100', n: 'exakt',
      ke: [['falsche_operation', '26+400*60/100*5/100', 'Addiert statt subtrahiert: 26 + 12.', 'Können die fehlerhaften von Maschine B mehr sein als alle fehlerhaften?'],
        ['grundwert_verwechselt', '26-400*5/100', 'Mit den falschen 20 fehlerhaften von A weitergerechnet: 26 − 20.', 'Wie viele Werkstücke kommen von Maschine A, und wie viele davon sind fehlerhaft?']] },
    { prompt: 'Fehlerfreie Werkstücke von Maschine B', r: '400*40/100-(26-400*60/100*5/100)', n: 'exakt',
      ke: [['randsumme_verwechselt', '(400-26)-(26-400*60/100*5/100)', 'Von „Fehlerfrei insgesamt“ (374) statt von „Maschine B insgesamt“ (160) abgezogen: 374 − 14.', 'Welche Summe besteht aus fehlerhaften und fehlerfreien Werkstücken von Maschine B?'],
        ['falsche_groesse_beantwortet', '400*40/100', 'Alle Werkstücke von Maschine B angegeben, auch die fehlerhaften.', 'Sind in deiner Zahl auch fehlerhafte Werkstücke enthalten?']] },
  ],
  weg: 'Maschine A: 60 % von 400 = 240 Werkstücke, davon 5 % fehlerhaft: 240 · 0,05 = {1}.\nFehlerhaft von Maschine B = 26 − 12 = {2}.\nMaschine B: 400 − 240 = 160 Werkstücke, davon fehlerfrei 160 − 14 = {3}.' });
def({ ...VF, ref: 'bedingt-vierfeld-05', titel: 'Vierfeldertafel · relative Häufigkeiten, Verkehrszählung', afb: 'II', sach: true,
  afbGrund: 'Anwenden im Sachkontext: Tafel mit relativen Häufigkeiten ergänzen und auf die Zahl der Fahrzeuge zurückrechnen.',
  frage: `Bei einer Verkehrszählung an einer Kreuzung wurde festgehalten, ob ein Fahrzeug ein Auto ist und ob es abbiegt. Die Anteile beziehen sich auf alle gezählten Fahrzeuge.\nAutos, die abbiegen: 0,18\nAutos, die geradeaus fahren: ?\nAndere Fahrzeuge, die abbiegen: ?\nAndere Fahrzeuge, die geradeaus fahren: ?\nAutos insgesamt: 0,65\nAbbiegende Fahrzeuge insgesamt: 0,30\nAlle Fahrzeuge: 1\n\nGezählt wurden 400 Fahrzeuge. Ergänze die drei fehlenden Anteile exakt als Dezimalzahl und gib an, wie viele andere Fahrzeuge abgebogen sind.`,
  teile: [
    { prompt: 'Anteil: Autos, die geradeaus fahren', r: '0.65-0.18', n: 'exakt',
      ke: [['randsumme_verwechselt', '0.30-0.18', 'Von „Abbiegende insgesamt“ statt von „Autos insgesamt“ abgezogen: 0,30 − 0,18.', 'Welche Summe besteht aus abbiegenden und geradeaus fahrenden Autos?'],
        ['falsche_operation', '0.65+0.18', 'Addiert statt subtrahiert: 0,65 + 0,18.', 'Kann ein Teil der Autos einen größeren Anteil haben als alle Autos?']] },
    { prompt: 'Anteil: Andere Fahrzeuge, die abbiegen', r: '0.30-0.18', n: 'exakt',
      ke: [['randsumme_verwechselt', '0.65-0.18', 'Von „Autos insgesamt“ statt von „Abbiegende insgesamt“ abgezogen: 0,65 − 0,18.', 'Welche Summe besteht aus abbiegenden Autos und abbiegenden anderen Fahrzeugen?'],
        ['falsche_operation', '0.30+0.18', 'Addiert statt subtrahiert: 0,30 + 0,18.', 'Kann ein Teil der Abbieger einen größeren Anteil haben als alle Abbieger?']] },
    { prompt: 'Anteil: Andere Fahrzeuge, die geradeaus fahren', r: '1-0.65-(0.30-0.18)', n: 'exakt',
      ke: [['falsche_groesse_beantwortet', '1-0.65', 'Den Anteil aller anderen Fahrzeuge angegeben, auch der abbiegenden.', 'Sind in deinem Anteil auch andere Fahrzeuge enthalten, die abbiegen?'],
        ['randsumme_verwechselt', '(1-0.30)-(0.30-0.18)', 'Von „Geradeaus insgesamt“ (0,70) die abbiegenden anderen Fahrzeuge abgezogen: 0,70 − 0,12.', 'Gehören die abbiegenden anderen Fahrzeuge zu den Geradeausfahrern?']] },
    { prompt: 'Anzahl anderer Fahrzeuge, die abgebogen sind', r: '400*(0.30-0.18)', n: 'exakt',
      ke: [['randsumme_verwechselt', '400*(0.65-0.18)', 'Mit dem falschen Anteil 0,47 weitergerechnet: 400 · 0,47.', 'Welcher Anteil gehört zu den anderen Fahrzeugen, die abbiegen?'],
        ['dezimalverschiebung', '400*1.2', 'Das Komma verschoben: 400 · 1,2 statt 400 · 0,12.', 'Können mehr Fahrzeuge abgebogen sein als gezählt wurden?']] },
  ],
  weg: 'Autos geradeaus = 0,65 − 0,18 = {1}.\nAndere abbiegend = 0,30 − 0,18 = {2}.\nAndere insgesamt = 1 − 0,65 = 0,35, also andere geradeaus = 0,35 − 0,12 = {3}.\nAnzahl andere abbiegend = 400 · 0,12 = {4}.' });
def({ ...VF, ref: 'bedingt-vierfeld-06', titel: 'Vierfeldertafel · Instrument und Chor aus Prozentangaben', afb: 'III', sach: true,
  afbGrund: 'Problemlösen im Sachkontext: Tafel selbst anlegen, Prozent vom richtigen Grundwert nehmen und über zwei Summen ergänzen.',
  frage: `In einer Jahrgangsstufe mit 150 Schülerinnen und Schülern spielen 40 % ein Instrument. Von denen, die ein Instrument spielen, singen 25 % im Chor. Insgesamt singen 33 Schülerinnen und Schüler im Chor.\n\nWie viele singen im Chor, spielen aber kein Instrument? Wie viele singen nicht im Chor und spielen auch kein Instrument? ${GANZ}`,
  teile: [
    { prompt: 'Im Chor, kein Instrument', r: '33-150*40/100*25/100', n: 'exakt',
      ke: [['randsumme_verwechselt', '150*40/100-150*40/100*25/100', 'Von „Instrument insgesamt“ (60) statt von „Chor insgesamt“ (33) abgezogen: 60 − 15.', 'Welche Summe besteht aus „Chor mit Instrument“ und „Chor ohne Instrument“?'],
        ['falsche_operation', '33+150*40/100*25/100', 'Addiert statt subtrahiert: 33 + 15.', 'Können mehr Chorsänger kein Instrument spielen, als es Chorsänger gibt?']] },
    { prompt: 'Nicht im Chor, kein Instrument', r: '150-150*40/100-(33-150*40/100*25/100)', n: 'exakt',
      ke: [['falsche_groesse_beantwortet', '150-33', 'Alle angegeben, die nicht im Chor singen, auch die mit Instrument.', 'Sind in deiner Zahl auch Schülerinnen und Schüler mit Instrument enthalten?'],
        ['randsumme_verwechselt', '150-33-(33-150*40/100*25/100)', 'Von „Nicht im Chor insgesamt“ (117) die Chorsänger ohne Instrument (18) abgezogen: 117 − 18.', 'Gehören die Chorsänger ohne Instrument zu denen, die nicht im Chor singen?']] },
  ],
  weg: 'Instrument: 40 % von 150 = 60. Davon im Chor: 25 % von 60 = 15.\nChor ohne Instrument = 33 − 15 = {1}.\nKein Instrument: 150 − 60 = 90. Davon nicht im Chor: 90 − 18 = {2}.\nProbe: Nicht im Chor insgesamt = 150 − 33 = 117 = (60 − 15) + 72.' });

// ─── stoch_bedingt_wkeit (Tiefe 6) ───
const WK = { skill: 'stoch_bedingt_wkeit' };
def({ ...WK, ref: 'bedingt-wkeit-01', titel: 'P(Haustier | Junge) · Dezimalzahl', afb: 'I', sach: false, n: 2,
  afbGrund: 'Reproduzieren: Zellwert durch die passende Randsumme, Werte direkt ablesbar.',
  frage: `In einer Befragung wurden 200 Jugendliche gefragt, ob sie ein Haustier haben.\n${TAFEL_HAUSTIER}\n\nEine zufällig ausgewählte befragte Person ist ein Junge. Wie groß ist die Wahrscheinlichkeit, dass er ein Haustier hat? ${DEZ2}`,
  r: '60/90',
  weg: 'Bedingung: Junge. Es zählen nur die 90 Jungen.\nP(Haustier | Junge) = 60 : 90 ≈ {A}.',
  ke: [['gesamtheit_statt_bedingung', '60/200', 'Durch alle 200 Befragten geteilt statt durch die 90 Jungen.', 'Aus welcher Gruppe wird gezogen, wenn schon feststeht, dass es ein Junge ist?'],
    ['bedingung_vertauscht', '60/108', 'Durch alle mit Haustier geteilt: Das ist die Wahrscheinlichkeit, dass eine Person mit Haustier ein Junge ist.', 'Steht fest, dass die Person ein Junge ist, oder dass sie ein Haustier hat?'],
    ['bezug_vertauscht', '90/60', 'Den Kehrwert gebildet: 90 : 60.', 'Kann eine Wahrscheinlichkeit größer als 1 sein?']] });
def({ ...WK, ref: 'bedingt-wkeit-02', titel: 'P(Lieferant B | fehlerhaft) · Prozent', afb: 'I', sach: false, n: 1,
  afbGrund: 'Reproduzieren: Zellwert durch Spaltensumme, Ergebnis in Prozent mit Rundung.',
  frage: `Ein Materialprüfgerät hat 500 Bauteile von zwei Lieferanten geprüft.\nLieferant A, fehlerhaft: 18\nLieferant A, in Ordnung: 282\nLieferant B, fehlerhaft: 11\nLieferant B, in Ordnung: 189\nLieferant A insgesamt: 300\nLieferant B insgesamt: 200\nFehlerhaft insgesamt: 29\nIn Ordnung insgesamt: 471\nAlle Bauteile: 500\n\nAus den fehlerhaften Bauteilen wird eines zufällig ausgewählt. Mit welcher Wahrscheinlichkeit in Prozent stammt es von Lieferant B? ${PROZ1}`,
  r: '11/29*100',
  weg: 'Bedingung: fehlerhaft. Es zählen nur die 29 fehlerhaften Bauteile, davon 11 von Lieferant B.\nP(B | fehlerhaft) = 11 : 29 ≈ 0,3793, also ≈ {A} %.',
  ke: [['gesamtheit_statt_bedingung', '11/500*100', 'Durch alle 500 Bauteile geteilt statt durch die 29 fehlerhaften.', 'Aus welchen Bauteilen wird gezogen?'],
    ['bedingung_vertauscht', '11/200*100', 'Durch alle Bauteile von Lieferant B geteilt: Das ist der Anteil fehlerhafter Teile bei Lieferant B.', 'Steht fest, dass das Teil fehlerhaft ist, oder dass es von Lieferant B kommt?'],
    ['bezug_vertauscht', '29/11*100', 'Den Kehrwert gebildet: 29 : 11.', 'Kann eine Wahrscheinlichkeit mehr als 100 % betragen?']] });
def({ ...WK, ref: 'bedingt-wkeit-03', titel: 'P(Schwimmen | Erwachsene) · gekürzter Bruch', afb: 'II', sach: false, bruch: true,
  afbGrund: 'Anwenden: richtige Teilgruppe wählen und das Ergebnis als gekürzten Bruch angeben.',
  frage: `Ein Sportverein hat 120 Mitglieder gefragt, ob sie das Schwimmangebot nutzen.\nKinder, schwimmen: 42\nKinder, schwimmen nicht: 28\nErwachsene, schwimmen: 18\nErwachsene, schwimmen nicht: 32\nKinder insgesamt: 70\nErwachsene insgesamt: 50\nSchwimmen insgesamt: 60\nSchwimmen nicht insgesamt: 60\nAlle Mitglieder: 120\n\nEin zufällig ausgewähltes Mitglied ist erwachsen. Wie groß ist die Wahrscheinlichkeit, dass es das Schwimmangebot nutzt? Gib die Wahrscheinlichkeit exakt als gekürzten Bruch oder als Dezimalzahl an.`,
  r: '18/50',
  weg: 'Bedingung: erwachsen. Es zählen nur die 50 Erwachsenen, davon schwimmen 18.\nP(schwimmt | erwachsen) = 18/50 = 9/25 = {A}.',
  ke: [['gesamtheit_statt_bedingung', '18/120', 'Durch alle 120 Mitglieder geteilt statt durch die 50 Erwachsenen.', 'Aus welcher Gruppe wird gezogen, wenn feststeht, dass das Mitglied erwachsen ist?'],
    ['bedingung_vertauscht', '18/60', 'Durch alle Schwimmer geteilt: Das ist die Wahrscheinlichkeit, dass ein Schwimmer erwachsen ist.', 'Steht fest, dass das Mitglied erwachsen ist, oder dass es schwimmt?'],
    ['bezug_vertauscht', '50/18', 'Den Kehrwert gebildet: 50/18.', 'Kann eine Wahrscheinlichkeit größer als 1 sein?']] });
def({ ...WK, ref: 'bedingt-wkeit-04', titel: 'P(Popcorn | Kind) · erst ergänzen', afb: 'II', sach: false, n: 2,
  afbGrund: 'Anwenden: zwei Felder der Tafel erst ergänzen, dann die bedingte Wahrscheinlichkeit bilden.',
  frage: `Ein Kino hat an einem Nachmittag 250 Besucherinnen und Besucher gezählt.\nErwachsene mit Popcorn: 45\nErwachsene insgesamt: 150\nMit Popcorn insgesamt: 105\nAlle Besucher: 250\n\nEine zufällig ausgewählte Person ist ein Kind. Wie groß ist die Wahrscheinlichkeit, dass es Popcorn gekauft hat? ${DEZ2}`,
  r: '(105-45)/(250-150)',
  weg: 'Kinder insgesamt = 250 − 150 = 100.\nKinder mit Popcorn = 105 − 45 = 60.\nP(Popcorn | Kind) = 60 : 100 = {A}.',
  ke: [['gesamtheit_statt_bedingung', '(105-45)/250', 'Durch alle 250 Besucher geteilt statt durch die 100 Kinder.', 'Aus welcher Gruppe wird gezogen, wenn feststeht, dass es ein Kind ist?'],
    ['bedingung_vertauscht', '(105-45)/105', 'Durch alle mit Popcorn geteilt: Das ist die Wahrscheinlichkeit, dass eine Person mit Popcorn ein Kind ist.', 'Steht fest, dass die Person ein Kind ist, oder dass sie Popcorn hat?'],
    ['randsumme_verwechselt', '(105-45)/(250-105)', 'Die Kinder falsch ergänzt: 250 − 105 = 145 (das sind alle ohne Popcorn) statt 250 − 150 = 100.', 'Welche Summe besteht aus Erwachsenen und Kindern?']] });
def({ ...WK, ref: 'bedingt-wkeit-05', titel: 'Bibliothek · verlängerte Romane in Prozent', afb: 'II', sach: true, n: 1,
  afbGrund: 'Anwenden im Sachkontext: Tafel aus einem Text gewinnen, Bedingung „Roman“ erkennen und in Prozent angeben.',
  frage: `Eine Bibliothek wertet 600 Ausleihen aus. 240 davon waren Sachbücher, der Rest Romane. 180 Ausleihen wurden verlängert, davon waren 96 Sachbücher.\n\nWie viel Prozent der ausgeliehenen Romane wurden verlängert? ${PROZ1}`,
  r: '(180-96)/(600-240)*100',
  weg: 'Romane = 600 − 240 = 360.\nVerlängerte Romane = 180 − 96 = 84.\nAnteil = 84 : 360 ≈ 0,2333, also ≈ {A} %.',
  ke: [['gesamtheit_statt_bedingung', '(180-96)/600*100', 'Durch alle 600 Ausleihen geteilt statt durch die 360 Romane.', 'Bezieht sich die Frage auf alle Ausleihen oder nur auf die Romane?'],
    ['bedingung_vertauscht', '(180-96)/180*100', 'Durch alle verlängerten Ausleihen geteilt: Das ist der Anteil der Romane unter den Verlängerungen.', 'Wird nach den Romanen gefragt, die verlängert wurden, oder nach den Verlängerungen, die Romane waren?'],
    ['bezug_vertauscht', '(600-240)/(180-96)*100', 'Den Kehrwert gebildet: 360 : 84.', 'Können mehr als 100 % der Romane verlängert worden sein?']] });
def({ ...WK, ref: 'bedingt-wkeit-06', titel: 'Rückrichtung · P(Junge | Haustier) aus P(Haustier | Junge)', afb: 'III', sach: true, n: 2,
  afbGrund: 'Problemlösen: aus einer bedingten Wahrscheinlichkeit die Tafel aufbauen und die umgekehrte Bedingung bestimmen.',
  frage: `Von 250 befragten Jugendlichen sind 100 Jungen. 70 % der Jungen haben ein Haustier. Insgesamt haben 160 der Befragten ein Haustier.\n\nEine zufällig ausgewählte Person mit Haustier wird befragt. Wie groß ist die Wahrscheinlichkeit, dass es ein Junge ist? ${DEZ2}`,
  r: '100*70/100/160',
  weg: 'Jungen mit Haustier = 70 % von 100 = 70.\nBedingung: Haustier. Es zählen nur die 160 Personen mit Haustier.\nP(Junge | Haustier) = 70 : 160 = 0,4375 ≈ {A}.',
  ke: [['bedingung_vertauscht', '70/100', 'Die gegebene Wahrscheinlichkeit P(Haustier | Junge) = 0,70 übernommen.', 'Steht diesmal fest, dass es ein Junge ist, oder dass die Person ein Haustier hat?'],
    ['gesamtheit_statt_bedingung', '100*70/100/250', 'Durch alle 250 Befragten geteilt statt durch die 160 mit Haustier.', 'Aus welcher Gruppe wird die Person ausgewählt?'],
    ['falsche_groesse_beantwortet', '100*70/100', 'Die Anzahl der Jungen mit Haustier (70) angegeben statt einer Wahrscheinlichkeit.', 'Ist nach einer Anzahl oder nach einer Wahrscheinlichkeit gefragt?']] });

// ─── stoch_bedingt_unabhaengig (Tiefe 7) ───
const UA = { skill: 'stoch_bedingt_unabhaengig' };
def({ ...UA, ref: 'bedingt-unabhaengig-01', titel: 'Erwartete Anzahl bei Unabhängigkeit', afb: 'I', sach: false,
  afbGrund: 'Reproduzieren: erwartete Anzahl = Zeilensumme · Spaltensumme : Gesamtzahl.',
  frage: `Von 200 befragten Jugendlichen sind 120 Mädchen. 90 der Befragten haben ein Haustier.\n\nWie viele Mädchen mit Haustier wären zu erwarten, wenn Geschlecht und Haustierbesitz unabhängig voneinander wären? Gib die Anzahl als ganze Zahl an.`,
  r: '120*90/200',
  weg: 'Bei Unabhängigkeit haben die Mädchen denselben Anteil an Haustieren wie alle: 90 : 200 = 0,45.\nErwartete Anzahl = 120 · 0,45 = 120 · 90 : 200 = {A}.',
  ke: [['falsche_groesse_beantwortet', '120/200*90/200', 'Die Wahrscheinlichkeit 0,6 · 0,45 = 0,27 angegeben statt der Anzahl.', 'Ist nach einer Wahrscheinlichkeit oder nach einer Anzahl von Mädchen gefragt?'],
    ['falsche_operation', '200*(120/200+90/200)', 'Die Anteile addiert statt multipliziert: (0,6 + 0,45) · 200.', 'Können mehr Mädchen ein Haustier haben, als es Mädchen gibt?']] });
def({ ...UA, ref: 'bedingt-unabhaengig-02', titel: 'P(A | B) und P(A) vergleichen · Prozentpunkte', afb: 'I', sach: false, n: 1,
  afbGrund: 'Reproduzieren: zwei Anteile in Prozent berechnen und ihren Abstand angeben.',
  frage: `Von 200 befragten Jugendlichen sind 120 Mädchen. 63 der Mädchen haben ein Haustier. Insgesamt haben 90 der Befragten ein Haustier.\n\nUm wie viele Prozentpunkte ist der Anteil der Haustierbesitzer unter den Mädchen größer als der Anteil der Haustierbesitzer unter allen Befragten? ${PROZ1}`,
  r: '63/120*100-90/200*100',
  weg: 'Unter den Mädchen: 63 : 120 = 0,525 = 52,5 %.\nUnter allen: 90 : 200 = 0,45 = 45 %.\nUnterschied: 52,5 − 45 = {A} Prozentpunkte. Die Anteile sind verschieden, also sind Geschlecht und Haustierbesitz nicht unabhängig.',
  ke: [['gesamtheit_statt_bedingung', '90/200*100-63/200*100', 'Die Mädchen mit Haustier durch alle 200 geteilt (31,5 %) und mit 45 % verglichen.', 'Auf welche Gruppe bezieht sich „Anteil unter den Mädchen“?'],
    ['bedingung_vertauscht', '63/90*100-120/200*100', 'Den Anteil der Mädchen unter den Haustierbesitzern (70 %) mit dem Mädchenanteil (60 %) verglichen.', 'Welche beiden Anteile nennt die Frage genau?']] });
def({ ...UA, ref: 'bedingt-unabhaengig-03', titel: 'Fehlende Zahl für Unabhängigkeit · Pflanzen', afb: 'II', sach: false,
  afbGrund: 'Anwenden: Bedingung für Unabhängigkeit (gleiche Anteile) als Rechnung umsetzen.',
  frage: `Von 300 Pflanzen wurden 120 gedüngt. Von den 180 nicht gedüngten Pflanzen blühen 117.\n\nWie viele der gedüngten Pflanzen müssten blühen, damit Blühen und Düngen unabhängig voneinander sind? ${EXAKT}`,
  r: '120*117/180',
  weg: 'Unabhängig heißt: Der Anteil blühender Pflanzen ist bei gedüngten und nicht gedüngten gleich.\nAnteil bei nicht gedüngten: 117 : 180 = 0,65.\nGedüngte, die blühen müssten: 120 · 0,65 = {A}.',
  ke: [['absolut_statt_relativ', '117', 'Dieselbe Anzahl wie bei den nicht gedüngten übernommen statt denselben Anteil.', 'Sind gleich viele blühende Pflanzen dasselbe wie ein gleicher Anteil, wenn die Gruppen verschieden groß sind?'],
    ['gesamtheit_statt_bedingung', '117/300*120', 'Den Anteil 117 : 300 an allen Pflanzen genommen statt 117 : 180 an den nicht gedüngten.', 'Aus welcher Gruppe stammen die 117 blühenden Pflanzen?']] });
def({ ...UA, ref: 'bedingt-unabhaengig-04', titel: 'Befall im Gewächshaus und Freiland · Prozentpunkte', afb: 'II', sach: false, n: 1,
  afbGrund: 'Anwenden: zwei bedingte Anteile aus der Tafel bilden und vergleichen, Rundung erst am Ende.',
  frage: `Eine Gärtnerei hat 240 Tomatenpflanzen auf Schädlingsbefall untersucht.\nGewächshaus mit Befall: 18\nGewächshaus ohne Befall: 132\nFreiland mit Befall: 24\nFreiland ohne Befall: 66\nGewächshaus insgesamt: 150\nFreiland insgesamt: 90\nMit Befall insgesamt: 42\nOhne Befall insgesamt: 198\nAlle Pflanzen: 240\n\nUm wie viele Prozentpunkte ist der Anteil befallener Pflanzen im Freiland größer als im Gewächshaus? ${PROZ1}`,
  r: '24/90*100-18/150*100',
  weg: 'Freiland: 24 : 90 ≈ 26,67 %.\nGewächshaus: 18 : 150 = 12 %.\nUnterschied: 26,67 − 12 ≈ {A} Prozentpunkte. Der Befall hängt also vom Standort ab.',
  ke: [['absolut_statt_relativ', '24-18', 'Die Anzahlen verglichen statt der Anteile: 24 − 18.', 'Sind die Gruppen im Gewächshaus und im Freiland gleich groß?'],
    ['gesamtheit_statt_bedingung', '24/240*100-18/240*100', 'Beide Anzahlen durch alle 240 Pflanzen geteilt statt durch die Pflanzen des jeweiligen Standorts.', 'Auf welche Pflanzen bezieht sich „Anteil im Freiland“?'],
    ['zu_frueh_gerundet', '27-12', 'Den Freiland-Anteil vorher auf 27 % gerundet: 27 − 12.', 'Wann solltest du runden – zwischendurch oder erst am Ende?']] });
def({ ...UA, ref: 'bedingt-unabhaengig-05', titel: 'Mensa und Unterstufe · Erwartung und Abweichung', afb: 'II', sach: true,
  afbGrund: 'Anwenden im Sachkontext: erwartete Anzahl aus zwei Prozentangaben bilden und mit dem beobachteten Wert vergleichen.',
  frage: `An einer Schule mit 400 Schülerinnen und Schülern essen 35 % regelmäßig in der Mensa. 55 % aller Schülerinnen und Schüler gehören zur Unterstufe.\n\nWie viele Unterstufenschüler würden regelmäßig in der Mensa essen, wenn Mensabesuch und Stufe unabhängig voneinander wären? Tatsächlich sind es 95 Unterstufenschüler. Um wie viele liegt die tatsächliche Zahl über der erwarteten? ${GANZ}`,
  teile: [
    { prompt: 'Erwartete Anzahl bei Unabhängigkeit', r: '400*35/100*55/100', n: 'exakt',
      ke: [['falsche_groesse_beantwortet', '35/100*55/100', 'Die Wahrscheinlichkeit 0,35 · 0,55 angegeben statt der Anzahl.', 'Ist nach einer Wahrscheinlichkeit oder nach einer Anzahl gefragt?'],
        ['falsche_operation', '400*(35+55)/100', 'Die Prozentsätze addiert statt multipliziert: 90 % von 400.', 'Können mehr Unterstufenschüler in die Mensa gehen, als es Mensagänger gibt?']] },
    { prompt: 'Unterschied zur tatsächlichen Zahl', r: '95-400*35/100*55/100', n: 'exakt',
      ke: [['falsche_operation', '95+400*35/100*55/100', 'Addiert statt subtrahiert: 95 + 77.', 'Wie bestimmt man, um wie viel eine Zahl größer ist als eine andere?']] },
  ],
  weg: 'Bei Unabhängigkeit essen in der Unterstufe ebenfalls 35 %: Unterstufe = 55 % von 400 = 220, davon 35 %: 220 · 0,35 = {1}.\nUnterschied: 95 − 77 = {2}. Die Zahl liegt deutlich über der Erwartung, Mensabesuch und Stufe sind nicht unabhängig.' });
def({ ...UA, ref: 'bedingt-unabhaengig-06', titel: 'Garten und Lastenrad · Unabhängigkeit und Abstand', afb: 'III', sach: true,
  afbGrund: 'Problemlösen im Sachkontext: Bedingung für Unabhängigkeit selbst ansetzen und die beobachteten Anteile vergleichen.',
  frage: `Eine Gemeinde hat 500 Haushalte befragt. 200 Haushalte haben einen Garten. Von den Haushalten mit Garten besitzen 30 % ein Lastenrad.\n\nWie viele Haushalte ohne Garten müssten ein Lastenrad besitzen, damit Garten und Lastenrad unabhängig voneinander sind?\nTatsächlich besitzen insgesamt 114 Haushalte ein Lastenrad. Um wie viele Prozentpunkte ist der Anteil der Lastenradbesitzer bei den Haushalten mit Garten größer als bei den Haushalten ohne Garten? ${EXAKT}`,
  teile: [
    { prompt: 'Haushalte ohne Garten mit Lastenrad bei Unabhängigkeit', r: '(500-200)*30/100', n: 'exakt',
      ke: [['absolut_statt_relativ', '200*30/100', 'Dieselbe Anzahl wie bei den Haushalten mit Garten (60) übernommen statt denselben Anteil.', 'Sind die Gruppen mit und ohne Garten gleich groß?'],
        ['grundwert_verwechselt', '500*30/100', '30 % von allen 500 Haushalten genommen statt von den 300 ohne Garten.', 'Von welcher Gruppe sollen 30 % ein Lastenrad haben?']] },
    { prompt: 'Unterschied der Anteile in Prozentpunkten', r: '30-(114-200*30/100)/(500-200)*100', n: 'exakt',
      ke: [['absolut_statt_relativ', '200*30/100-(114-200*30/100)', 'Die Anzahlen 60 und 54 verglichen statt der Anteile.', 'Wird nach einem Unterschied von Anzahlen oder von Anteilen gefragt?'],
        ['gesamtheit_statt_bedingung', '200*30/100/500*100-(114-200*30/100)/500*100', 'Beide Anzahlen durch alle 500 Haushalte geteilt statt durch die Größe der jeweiligen Gruppe.', 'Auf welche Haushalte bezieht sich „Anteil bei den Haushalten ohne Garten“?']] },
  ],
  weg: 'Unabhängig heißt: Auch ohne Garten besitzen 30 % ein Lastenrad. Ohne Garten: 500 − 200 = 300 Haushalte, davon 30 %: {1}.\nMit Garten und Lastenrad: 30 % von 200 = 60. Ohne Garten mit Lastenrad: 114 − 60 = 54, das sind 54 : 300 = 18 %.\nUnterschied: 30 − 18 = {2} Prozentpunkte.' });

// ─── stoch_bedingt_umkehr (Tiefe 7) ───
const UK = { skill: 'stoch_bedingt_umkehr' };
def({ ...UK, ref: 'bedingt-umkehr-01', titel: 'Schnelltest · befallene und erkannte Proben', afb: 'I', sach: false,
  afbGrund: 'Reproduzieren: zwei Prozentwerte nacheinander als natürliche Häufigkeiten.',
  frage: `Ein Labor untersucht 1000 Blattproben mit einem Schnelltest auf eine Pflanzenkrankheit. 2 % der Proben sind befallen. Der Test erkennt 90 % der befallenen Proben.\n\nWie viele Proben sind befallen? Wie viele Proben sind befallen und haben einen positiven Test? ${GANZ}`,
  teile: [
    { prompt: 'Befallene Proben', r: '1000*2/100', n: 'exakt',
      ke: [['dezimalverschiebung', '1000*20/100', '2 % als 0,2 gerechnet statt als 0,02.', 'Wie schreibt man 2 % als Dezimalzahl?']] },
    { prompt: 'Befallene Proben mit positivem Test', r: '1000*2/100*90/100', n: 'exakt',
      ke: [['grundwert_verwechselt', '1000*90/100', '90 % von allen 1000 Proben genommen statt von den 20 befallenen.', 'Worauf beziehen sich die 90 % – auf alle Proben oder nur auf die befallenen?']] },
  ],
  weg: 'Befallen: 2 % von 1000 = {1}.\nDavon erkannt: 90 % von 20 = {2}.' });
def({ ...UK, ref: 'bedingt-umkehr-02', titel: 'Prüfgerät · intakte Teile und Fehlalarme', afb: 'I', sach: false,
  afbGrund: 'Reproduzieren: Gegenwahrscheinlichkeit als Anzahl und Fehlalarmquote auf die richtige Gruppe anwenden.',
  frage: `Ein Prüfgerät kontrolliert 5000 Bauteile. 4 % der Bauteile sind defekt. Bei 3 % der intakten Bauteile meldet das Gerät fälschlich einen Defekt.\n\nWie viele Bauteile sind intakt? Bei wie vielen intakten Bauteilen meldet das Gerät fälschlich einen Defekt? ${GANZ}`,
  teile: [
    { prompt: 'Intakte Bauteile', r: '5000-5000*4/100', n: 'exakt',
      ke: [['falsche_groesse_beantwortet', '5000*4/100', 'Die defekten Bauteile angegeben statt der intakten.', 'Sind die 4 % die intakten oder die defekten Teile?'],
        ['dezimalverschiebung', '5000-5000*40/100', '4 % als 0,4 gerechnet: 5000 − 2000.', 'Wie schreibt man 4 % als Dezimalzahl?']] },
    { prompt: 'Intakte Bauteile mit Fehlalarm', r: '(5000-5000*4/100)*3/100', n: 'exakt',
      ke: [['grundwert_verwechselt', '5000*3/100', '3 % von allen 5000 Bauteilen genommen statt von den 4800 intakten.', 'Worauf beziehen sich die 3 % – auf alle Teile oder nur auf die intakten?'],
        ['dezimalverschiebung', '(5000-5000*4/100)*30/100', '3 % als 0,3 gerechnet: 4800 · 0,3.', 'Wie schreibt man 3 % als Dezimalzahl?']] },
  ],
  weg: 'Defekt: 4 % von 5000 = 200, also intakt: 5000 − 200 = {1}.\nFehlalarme: 3 % von 4800 = {2}.' });
def({ ...UK, ref: 'bedingt-umkehr-03', titel: 'Schnelltest · positive Tests und Anteil wirklich befallen', afb: 'II', sach: false,
  afbGrund: 'Anwenden: Tafel mit natürlichen Häufigkeiten aufbauen, positive Tests zählen und umkehren.',
  frage: `Ein Labor untersucht 1000 Blattproben mit einem Schnelltest auf eine Pflanzenkrankheit. 2 % der Proben sind befallen. Der Test erkennt 90 % der befallenen Proben. Bei 5 % der gesunden Proben schlägt er fälschlich an.\n\nWie viele Proben haben insgesamt einen positiven Test? Wie viel Prozent der Proben mit positivem Test sind wirklich befallen? Gib die Anzahl als ganze Zahl an. Gib den Prozentsatz ohne %-Zeichen an und runde auf eine Stelle nach dem Komma.`,
  teile: [
    { prompt: 'Proben mit positivem Test insgesamt', r: '1000*2/100*90/100+1000*98/100*5/100', n: 'exakt',
      ke: [['grundwert_verwechselt', '1000*2/100*90/100+1000*5/100', 'Die 5 % Fehlalarme von allen 1000 Proben genommen statt von den 980 gesunden: 18 + 50.', 'Bei welchen Proben kann der Test fälschlich anschlagen?'],
        ['falsche_groesse_beantwortet', '1000*2/100*90/100', 'Nur die befallenen Proben mit positivem Test gezählt, die Fehlalarme fehlen.', 'Schlägt der Test auch bei gesunden Proben an?']] },
    { prompt: 'Anteil wirklich befallener Proben unter den positiven (in %)', r: '18/67*100', n: 1,
      ke: [['bedingung_vertauscht', '90', 'Die Erkennungsrate 90 % übernommen: Das ist der Anteil positiver Tests unter den befallenen Proben.', 'Wird nach den befallenen Proben gefragt, die positiv sind, oder nach den positiven, die befallen sind?'],
        ['gesamtheit_statt_bedingung', '18/1000*100', 'Durch alle 1000 Proben geteilt statt durch die 67 positiven.', 'Aus welchen Proben wird hier ausgewählt?'],
        ['grundwert_verwechselt', '18/68*100', 'Mit den falsch gezählten 68 positiven Tests gerechnet.', 'Wie viele gesunde Proben gibt es, und wie viele davon testen positiv?']] },
  ],
  weg: 'Befallen: 20, davon positiv 90 %: 18.\nGesund: 980, davon fälschlich positiv 5 %: 49.\nPositiv insgesamt: 18 + 49 = {1}.\nAnteil wirklich befallen: 18 : 67 ≈ 0,2687, also ≈ {2} %.' });
def({ ...UK, ref: 'bedingt-umkehr-04', titel: 'Schnelltest · 1 % Befall, Anteil wirklich befallen', afb: 'II', sach: false, n: 1,
  afbGrund: 'Anwenden: ganze Umkehrung in einem Zug, ohne vorgegebene Zwischenschritte.',
  frage: `Eine Gärtnerei testet 10 000 Setzlinge auf einen Pilz. 1 % der Setzlinge ist befallen. Der Test erkennt 95 % der befallenen Setzlinge. Bei 2 % der gesunden Setzlinge schlägt er fälschlich an.\n\nWie viel Prozent der Setzlinge mit positivem Test sind wirklich befallen? ${PROZ1}`,
  r: '10000*1/100*95/100/(10000*1/100*95/100+10000*99/100*2/100)*100',
  weg: 'Befallen: 1 % von 10 000 = 100, davon positiv 95 %: 95.\nGesund: 9900, davon fälschlich positiv 2 %: 198.\nPositiv insgesamt: 95 + 198 = 293.\nAnteil wirklich befallen: 95 : 293 ≈ 0,3242, also ≈ {A} %.',
  ke: [['bedingung_vertauscht', '95', 'Die Erkennungsrate 95 % übernommen: Das ist der Anteil positiver Tests unter den befallenen Setzlingen.', 'Wird nach den befallenen Setzlingen gefragt, die positiv sind, oder nach den positiven, die befallen sind?'],
    ['gesamtheit_statt_bedingung', '10000*1/100*95/100/10000*100', 'Durch alle 10 000 Setzlinge geteilt statt durch die 293 positiven.', 'Aus welchen Setzlingen wird hier ausgewählt?', 2],
    ['grundwert_verwechselt', '95/(95+10000*2/100)*100', 'Die 2 % Fehlalarme von allen 10 000 Setzlingen genommen statt von den 9900 gesunden.', 'Bei welchen Setzlingen kann der Test fälschlich anschlagen?']] });
def({ ...UK, ref: 'bedingt-umkehr-05', titel: 'Saatgut · positive Tests und Anteil befallen', afb: 'II', sach: true,
  afbGrund: 'Anwenden im Sachkontext: aus der Beschreibung eines Prüfverfahrens die Tafel aufbauen und umkehren.',
  frage: `Ein Labor prüft 2000 Saatgutproben mit einem Schnelltest auf einen Pilz. 5 % der Proben sind befallen. Der Test erkennt 80 % der befallenen Proben. Bei 4 % der gesunden Proben schlägt er fälschlich an.\n\nWie viele Proben haben insgesamt einen positiven Test? Wie viel Prozent der positiv getesteten Proben sind wirklich befallen? Gib die Anzahl als ganze Zahl an. Gib den Prozentsatz ohne %-Zeichen an und runde auf eine Stelle nach dem Komma.`,
  teile: [
    { prompt: 'Proben mit positivem Test insgesamt', r: '2000*5/100*80/100+2000*95/100*4/100', n: 'exakt',
      ke: [['grundwert_verwechselt', '2000*5/100*80/100+2000*4/100', 'Die 4 % Fehlalarme von allen 2000 Proben genommen statt von den 1900 gesunden: 80 + 80.', 'Bei welchen Proben kann der Test fälschlich anschlagen?'],
        ['falsche_groesse_beantwortet', '2000*5/100*80/100', 'Nur die befallenen Proben mit positivem Test gezählt, die Fehlalarme fehlen.', 'Schlägt der Test auch bei gesunden Proben an?']] },
    { prompt: 'Anteil wirklich befallener Proben unter den positiven (in %)', r: '80/156*100', n: 1,
      ke: [['bedingung_vertauscht', '80', 'Die Erkennungsrate 80 % übernommen: Das ist der Anteil positiver Tests unter den befallenen Proben.', 'Wird nach den befallenen Proben gefragt, die positiv sind, oder nach den positiven, die befallen sind?'],
        ['gesamtheit_statt_bedingung', '80/2000*100', 'Durch alle 2000 Proben geteilt statt durch die 156 positiven.', 'Aus welchen Proben wird hier ausgewählt?'],
        ['bezug_vertauscht', '156/80*100', 'Den Kehrwert gebildet: 156 : 80.', 'Können mehr als 100 % der positiven Proben befallen sein?']] },
  ],
  weg: 'Befallen: 5 % von 2000 = 100, davon positiv 80 %: 80.\nGesund: 1900, davon fälschlich positiv 4 %: 76.\nPositiv insgesamt: 80 + 76 = {1}.\nAnteil wirklich befallen: 80 : 156 ≈ 0,5128, also ≈ {2} %.' });
def({ ...UK, ref: 'bedingt-umkehr-06', titel: 'Schweißnähte · Anteil echter Fehler ohne Gesamtzahl', afb: 'III', sach: true, n: 1,
  afbGrund: 'Problemlösen im Sachkontext: Eine Gesamtzahl selbst wählen, Tafel aufbauen und umkehren.',
  frage: `Ein Materialprüfgerät untersucht Schweißnähte. 4 % der Nähte sind fehlerhaft. Das Gerät meldet 95 % der fehlerhaften Nähte. Bei 10 % der fehlerfreien Nähte meldet es fälschlich einen Fehler.\n\nWie viel Prozent der gemeldeten Nähte sind tatsächlich fehlerhaft? ${PROZ1}`,
  r: '1000*4/100*95/100/(1000*4/100*95/100+1000*96/100*10/100)*100',
  weg: 'Man denkt sich zum Beispiel 1000 Nähte.\nFehlerhaft: 40, davon gemeldet 95 %: 38.\nFehlerfrei: 960, davon fälschlich gemeldet 10 %: 96.\nGemeldet insgesamt: 38 + 96 = 134.\nAnteil tatsächlich fehlerhaft: 38 : 134 ≈ 0,2836, also ≈ {A} %.',
  ke: [['bedingung_vertauscht', '95', 'Die Erkennungsrate 95 % übernommen: Das ist der Anteil gemeldeter Nähte unter den fehlerhaften.', 'Wird nach den fehlerhaften Nähten gefragt, die gemeldet werden, oder nach den gemeldeten, die fehlerhaft sind?'],
    ['gesamtheit_statt_bedingung', '1000*4/100*95/100/1000*100', 'Durch alle Nähte geteilt statt durch die gemeldeten.', 'Aus welchen Nähten wird hier ausgewählt?'],
    ['grundwert_verwechselt', '38/(38+1000*10/100)*100', 'Die 10 % Fehlmeldungen von allen Nähten genommen statt von den fehlerfreien.', 'Bei welchen Nähten kann das Gerät fälschlich einen Fehler melden?']] });

// ─── stoch_bedingt_irrefuehrend (Tiefe 8) ───
const IR = { skill: 'stoch_bedingt_irrefuehrend' };
def({ ...IR, ref: 'bedingt-irrefuehrend-01', titel: 'Abgeschnittene Achse · gezeichnetes Verhältnis', afb: 'I', sach: false,
  afbGrund: 'Reproduzieren: sichtbare Säulenhöhen ab Achsenbeginn ins Verhältnis setzen.',
  frage: `In einem Säulendiagramm steht Säule A für den Wert 52 und Säule B für den Wert 48. Die Hochachse beginnt nicht bei 0, sondern bei 44.\n\nWie viel mal so hoch ist Säule A gezeichnet wie Säule B? ${EXAKT}`,
  r: '(52-44)/(48-44)',
  weg: 'Gezeichnet wird nur der Teil ab 44.\nSäule A: 52 − 44 = 8, Säule B: 48 − 44 = 4.\n8 : 4 = {A}. Säule A wirkt doppelt so hoch, obwohl die Werte kaum verschieden sind.',
  ke: [['achse_abgeschnitten_uebersehen', '52/48', 'Die Werte statt der gezeichneten Höhen verglichen: 52 : 48 ≈ 1,08.', 'Ab welcher Höhe beginnen die Säulen im Diagramm?', 2],
    ['achse_abgeschnitten_uebersehen', '52/48', 'Die Werte statt der gezeichneten Höhen verglichen: 52 : 48 ≈ 1,1.', 'Ab welcher Höhe beginnen die Säulen im Diagramm?', 1],
    ['falsche_operation', '52-48', 'Den Unterschied der Werte angegeben statt eines Verhältnisses.', 'Fragt „wie viel mal so hoch“ nach einer Differenz oder nach einem Faktor?']] });
def({ ...IR, ref: 'bedingt-irrefuehrend-02', titel: 'Abgeschnittene Achse · tatsächliches Verhältnis', afb: 'I', sach: false, n: 2,
  afbGrund: 'Reproduzieren: das echte Verhältnis der Werte bestimmen, unabhängig von der Zeichnung.',
  frage: `In einem Säulendiagramm steht Säule A für den Wert 75 und Säule B für den Wert 60. Die Hochachse beginnt bei 50, deshalb wirkt Säule A deutlich größer.\n\nWie viel mal so groß ist der Wert von A wie der Wert von B? Runde auf zwei Stellen nach dem Komma.`,
  r: '75/60',
  weg: 'Es zählen die Werte, nicht die gezeichneten Höhen.\n75 : 60 = {A}. Gezeichnet ist Säule A dagegen (75 − 50) : (60 − 50) = 2,5-mal so hoch.',
  ke: [['achse_abgeschnitten_uebersehen', '(75-50)/(60-50)', 'Die gezeichneten Höhen ab 50 verglichen statt der Werte.', 'Ist nach den Werten oder nach den gezeichneten Höhen gefragt?'],
    ['falsche_operation', '75-60', 'Den Unterschied der Werte angegeben statt eines Verhältnisses.', 'Fragt „wie viel mal so groß“ nach einer Differenz oder nach einem Faktor?'],
    ['bezug_vertauscht', '60/75', 'Den Kehrwert gebildet: 60 : 75.', 'Ist A größer oder kleiner als B – muss der Faktor dann über oder unter 1 liegen?']] });
def({ ...IR, ref: 'bedingt-irrefuehrend-03', titel: 'Absolut oder relativ · Radfahrer an zwei Schulen', afb: 'II', sach: false,
  afbGrund: 'Anwenden: zwei Anteile mit verschiedenen Grundwerten bilden und in Prozentpunkten vergleichen.',
  frage: `Eine Meldung lautet: „An Schule A fahren mehr Jugendliche mit dem Rad zur Schule als an Schule B.“ An Schule A fahren 36 von 240 Jugendlichen mit dem Rad, an Schule B 22 von 88.\n\nUm wie viele Prozentpunkte ist der Anteil der Radfahrer an Schule B größer als an Schule A? Gib die Zahl ohne %-Zeichen exakt an.`,
  r: '22/88*100-36/240*100',
  weg: 'Schule A: 36 : 240 = 0,15 = 15 %.\nSchule B: 22 : 88 = 0,25 = 25 %.\nUnterschied: 25 − 15 = {A} Prozentpunkte. A hat zwar mehr Radfahrer, B aber den größeren Anteil.',
  ke: [['absolut_statt_relativ', '36-22', 'Die Anzahlen verglichen statt der Anteile: 36 − 22.', 'Sind beide Schulen gleich groß?'],
    ['dezimalverschiebung', '22/88-36/240', 'Den Unterschied der Anteile als Dezimalzahl angegeben (0,1) statt in Prozentpunkten.', 'Wie viele Prozentpunkte sind 0,1?']] });
def({ ...IR, ref: 'bedingt-irrefuehrend-04', titel: 'Schlagzeile mit vertauschter Bedingung · Kettenriss', afb: 'II', sach: false, n: 1,
  afbGrund: 'Anwenden: die Bedingung einer Schlagzeile prüfen und die gemeinte bedingte Wahrscheinlichkeit richtig berechnen.',
  frage: `Eine Fahrradwerkstatt hat 1200 Fahrräder untersucht. 400 davon waren nie geölt worden. Bei 40 Fahrrädern war die Kette gerissen, 30 davon waren nie geölt worden.\nEine Schlagzeile lautet: „75 % der ungeölten Ketten reißen!“\n\nWie viel Prozent der nie geölten Fahrräder hatten tatsächlich eine gerissene Kette? ${PROZ1}`,
  r: '30/400*100',
  weg: '75 % stimmt nur so: 30 von 40 Fahrrädern mit gerissener Kette waren nie geölt. Die Schlagzeile vertauscht die Bedingung.\nGefragt: Bedingung „nie geölt“, also 30 : 400 = 0,075 = {A} %.',
  ke: [['bedingung_vertauscht', '30/40*100', 'Die Zahl der Schlagzeile übernommen: Das ist der Anteil ungeölter Räder unter denen mit gerissener Kette.', 'Steht fest, dass das Rad nie geölt wurde, oder dass die Kette gerissen ist?'],
    ['gesamtheit_statt_bedingung', '30/1200*100', 'Durch alle 1200 Fahrräder geteilt statt durch die 400 nie geölten.', 'Auf welche Fahrräder bezieht sich die Frage?'],
    ['falsche_groesse_beantwortet', '30', 'Die Anzahl 30 angegeben statt eines Prozentsatzes.', 'Ist nach einer Anzahl oder nach einem Anteil in Prozent gefragt?']] });
def({ ...IR, ref: 'bedingt-irrefuehrend-05', titel: 'Absolut oder relativ · Diebstähle je 1000 Einwohner', afb: 'II', sach: true,
  afbGrund: 'Anwenden im Sachkontext: eine Aussage über absolute Zahlen durch eine Rate je 1000 Einwohner prüfen.',
  frage: `Ein Bericht meldet: „In Ort A wurden im letzten Jahr 45 Fahrräder gestohlen, in Ort B nur 18. In Ort A ist das Rad also weniger sicher.“ Ort A hat 15 000 Einwohner, Ort B hat 4000 Einwohner.\n\nUm wie viele Diebstähle je 1000 Einwohner liegt Ort B über Ort A? ${EXAKT}`,
  r: '18/4000*1000-45/15000*1000',
  weg: 'Ort A: 45 Diebstähle auf 15 000 Einwohner = 3 je 1000 Einwohner.\nOrt B: 18 Diebstähle auf 4000 Einwohner = 4,5 je 1000 Einwohner.\nUnterschied: 4,5 − 3 = {A} Diebstähle je 1000 Einwohner. Gemessen an der Einwohnerzahl liegt B vorn.',
  ke: [['absolut_statt_relativ', '45-18', 'Die absoluten Anzahlen verglichen: 45 − 18.', 'Sind beide Orte gleich groß?'],
    ['dezimalverschiebung', '18/4000-45/15000', 'Die Rate je Einwohner berechnet statt je 1000 Einwohner: 0,0015.', 'Auf wie viele Einwohner soll sich die Rate beziehen?']] });
def({ ...IR, ref: 'bedingt-irrefuehrend-06', titel: 'Rückrichtung · Achsenbeginn aus dem gezeichneten Verhältnis', afb: 'III', sach: true,
  afbGrund: 'Problemlösen: aus dem gezeichneten Verhältnis eine Gleichung für den Achsenbeginn aufstellen und lösen.',
  frage: `Ein Werbeblatt zeigt ein Säulendiagramm. Säule A steht für den Wert 66, Säule B für den Wert 54. Gezeichnet ist Säule A genau dreimal so hoch wie Säule B, weil die Hochachse nicht bei 0 beginnt.\n\nBei welchem Wert beginnt die Hochachse? ${EXAKT}`,
  r: '(3*54-66)/2',
  weg: 'Achsenbeginn s: Gezeichnete Höhen 66 − s und 54 − s.\n66 − s = 3 · (54 − s) = 162 − 3s, also 2s = 96 und s = {A}.\nProbe: 66 − 48 = 18 und 54 − 48 = 6; 18 = 3 · 6.',
  ke: [['achse_abgeschnitten_uebersehen', '0', 'Angenommen, die Achse beginne bei 0.', 'Wäre Säule A bei einem Achsenbeginn von 0 wirklich dreimal so hoch wie B?'],
    ['halbieren_vergessen', '3*54-66', 'Bei 2s = 96 nicht durch 2 geteilt.', 'Was steht nach dem Umformen links – s oder 2s?']] });

baueCharge({
  thema: 'bedingt',
  batch: 'k9-bedingt',
  source: 'edvance_k9_bedingt',
  idsPfad: 'docs/prefill/k9-bedingt-ids.json',
  kopf: [
    `K9-Rest, Thema bedingt — ${A.length} Aufgaben: je sechs zu stoch_bedingt_vierfeld, _wkeit, _unabhaengig, _umkehr und _irrefuehrend.`,
    'Erzeugt von tools/vorlauf-build.mjs aus docs/prefill/k9-bedingt.json (Quelle: tools/k9-bedingt-charge.mjs) — nicht von Hand editieren.',
    '',
    'Einspiel-Reihenfolge: nach 20261003105859_substrat_k9_bedingt.sql (Knoten + Fehlbild-Slugs muessen stehen).',
  ],
  auswahl: 'Je Knoten vier reine Anwendung mit steigender Schwierigkeit (AFB I, I, II, II), eine mit Sachkontext (AFB II) und eine Sachkontext- oder Rückrichtungsaufgabe (AFB III): Haustier-Befragung, Bus und Stufe, Gärtnerei, Werkstücke, Verkehrszählung, Chor, Bibliothek, Kino, Mensa, Lastenrad, Schnelltests auf Pflanzenkrankheiten, Prüfgerät, Schweißnähte, Säulendiagramme, Schlagzeile, Diebstahlraten. Der Tablet-Player zeigt reinen Text: Vierfeldertafeln stehen als Liste benannter Felder (eine Zeile je Feld bzw. Summe), gesuchte Felder sind MULTI_PART-Teile mit genau diesem Namen. Jede Aufgabe nennt Form und Rundung der Antwort. Alle Daten frei erfunden.',
  aufgaben: A,
});
