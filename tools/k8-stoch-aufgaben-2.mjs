/**
 * k8-stoch-aufgaben-2.mjs — zweiter Teil der Aufgabenliste (Pfadregeln), Felder wie in
 * tools/k8-stoch-aufgaben.mjs. Hängt die zwölf Aufgaben an dieselbe Liste A an.
 */

import { A } from './k8-stoch-aufgaben.mjs';

const def = (o) => A.push(o);
const PB = 'Gib die Wahrscheinlichkeit als Bruch an.';
const PA = 'Gib die Wahrscheinlichkeit als Bruch, als Dezimalzahl oder in Prozent an.';

// ─── stoch_pfad_produkt (Tiefe 6) ────────────────────────────────────────────
const P = { skill: 'stoch_pfad_produkt', art: 'p' };
def({ ...P, ref: 'stoch-pfad-produkt-01', titel: 'Produktregel · Münze · zweimal Kopf',
  frage: `Eine faire Münze wird zweimal geworfen.\n\nWie groß ist die Wahrscheinlichkeit, zweimal Kopf zu werfen? ${PA}`,
  afb: 'I', afbGrund: 'Reproduzieren: ein Pfad, zwei gleiche Stufen, multiplizieren.',
  sach: false, prozess: 'Operieren', antwort: '1/4', r: '1/2*1/2', roh: [4],
  weg: 'Pfad Kopf – Kopf: P = 1/2 · 1/2 = 1/4 = 0,25 = 25 %.',
  ke: [
    ['1', 'pfadregel_addiert', '1/2+1/2', 'Entlang des Pfades addiert: 1/2 + 1/2 = 1.', 'Ist „zweimal Kopf“ wirklich sicher?', [2]],
  ] });
def({ ...P, ref: 'stoch-pfad-produkt-02', titel: 'Produktregel · Würfel · zweimal Sechs',
  frage: `Ein fairer Würfel wird zweimal geworfen.\n\nWie groß ist die Wahrscheinlichkeit, zweimal eine Sechs zu werfen? ${PB}`,
  afb: 'I', afbGrund: 'Reproduzieren: ein Pfad, zwei gleiche Stufen, multiplizieren.',
  sach: false, prozess: 'Operieren', antwort: '1/36', r: '1/6*1/6', roh: [36],
  weg: 'Pfad Sechs – Sechs: P = 1/6 · 1/6 = 1/36.',
  ke: [
    ['1/3', 'pfadregel_addiert', '1/6+1/6', 'Entlang des Pfades addiert: 1/6 + 1/6 = 2/6.', 'Ist zweimal eine Sechs wahrscheinlicher oder unwahrscheinlicher als einmal eine Sechs?', [6]],
  ] });
def({ ...P, ref: 'stoch-pfad-produkt-03', titel: 'Produktregel · Urne · mit Zurücklegen',
  frage: `In einer Urne liegen 3 rote und 2 blaue Kugeln. Es wird zweimal eine Kugel gezogen. Nach dem ersten Zug wird die Kugel zurückgelegt.\n\nWie groß ist die Wahrscheinlichkeit, zweimal eine rote Kugel zu ziehen? ${PA}`,
  afb: 'II', afbGrund: 'Anwenden: zweistufig mit Zurücklegen, gleiche Wahrscheinlichkeit auf beiden Stufen.',
  sach: false, prozess: 'Operieren', antwort: '9/25', r: '3/5*3/5', roh: [25],
  weg: 'Mit Zurücklegen bleibt P(rot) in beiden Zügen 3/5.\nP(rot, rot) = 3/5 · 3/5 = 9/25 = 0,36 = 36 %.',
  ke: [
    ['6/5', 'pfadregel_addiert', '3/5+3/5', 'Entlang des Pfades addiert: 3/5 + 3/5 = 6/5.', 'Kann eine Wahrscheinlichkeit größer als 1 sein?', [5]],
    ['3/10', 'zuruecklegen_ignoriert', '3/5*2/4', 'Im zweiten Zug so gerechnet, als fehlte die erste Kugel: 3/5 · 2/4.', 'Wie viele Kugeln liegen beim zweiten Zug in der Urne, wenn zurückgelegt wird?', [20]],
  ] });
def({ ...P, ref: 'stoch-pfad-produkt-04', titel: 'Produktregel · Urne · ohne Zurücklegen',
  frage: `In einer Urne liegen 4 rote und 6 blaue Kugeln. Es werden nacheinander zwei Kugeln ohne Zurücklegen gezogen.\n\nWie groß ist die Wahrscheinlichkeit, zwei blaue Kugeln zu ziehen? ${PB}`,
  afb: 'II', afbGrund: 'Anwenden: zweistufig ohne Zurücklegen, Inhalt der Urne ändert sich.',
  sach: false, prozess: 'Operieren', antwort: '1/3', r: '6/10*5/9', roh: [90],
  weg: '1. Zug: P(blau) = 6/10. Danach liegen noch 9 Kugeln da, 5 davon blau.\n2. Zug: P(blau) = 5/9.\nP(blau, blau) = 6/10 · 5/9 = 30/90 = 1/3.',
  ke: [
    ['9/25', 'zuruecklegen_ignoriert', '6/10*6/10', 'Im zweiten Zug mit der alten Anzahl gerechnet: 6/10 · 6/10.', 'Wie viele blaue Kugeln liegen nach dem ersten Zug noch in der Urne?', [100]],
    ['52/45', 'pfadregel_addiert', '6/10+5/9', 'Entlang des Pfades addiert: 6/10 + 5/9.', 'Kann eine Wahrscheinlichkeit größer als 1 sein?', [90]],
  ] });
def({ ...P, ref: 'stoch-pfad-produkt-05', titel: 'Produktregel · Sachkontext · zwei Gewinnlose',
  frage: `In einer Lostrommel liegen 10 Lose, 3 davon sind Gewinne. Es werden nacheinander zwei Lose gezogen, ein gezogenes Los kommt nicht zurück.\n\nWie groß ist die Wahrscheinlichkeit, dass beide Lose Gewinne sind? ${PB}`,
  afb: 'II', afbGrund: 'Anwenden: Ziehen ohne Zurücklegen im Sachkontext erkennen und multiplizieren.',
  sach: true, prozess: 'Modellieren', antwort: '1/15', r: '3/10*2/9', roh: [90],
  weg: '1. Los: P(Gewinn) = 3/10. Danach 9 Lose, 2 davon Gewinne.\n2. Los: P(Gewinn) = 2/9.\nP = 3/10 · 2/9 = 6/90 = 1/15.',
  ke: [
    ['9/100', 'zuruecklegen_ignoriert', '3/10*3/10', 'Im zweiten Zug mit der alten Anzahl gerechnet: 3/10 · 3/10.', 'Wie viele Gewinnlose sind nach dem ersten Zug noch in der Trommel?', [100]],
    ['47/90', 'pfadregel_addiert', '3/10+2/9', 'Entlang des Pfades addiert: 3/10 + 2/9.', 'Ist „beide gewinnen“ wahrscheinlicher als „das erste gewinnt“?', [90]],
  ] });
def({ ...P, ref: 'stoch-pfad-produkt-06', titel: 'Produktregel · Sachkontext · drei Stufen',
  frage: `Eine Maschine füllt Tüten ab. 10 % der Tüten sind zu leicht. Es werden drei Tüten zufällig und unabhängig voneinander geprüft.\n\nWie groß ist die Wahrscheinlichkeit, dass alle drei Tüten zu leicht sind? ${PA}`,
  afb: 'II', afbGrund: 'Anwenden: dreistufiger Pfad mit Prozentangabe, multiplizieren.',
  sach: true, prozess: 'Modellieren', antwort: '0,001', r: '0.1*0.1*0.1', roh: [1000],
  weg: 'P(zu leicht) = 10 % = 0,1 für jede Tüte.\nP(alle drei) = 0,1 · 0,1 · 0,1 = 0,001 = 1/1000 = 0,1 %.',
  ke: [
    ['0,3', 'pfadregel_addiert', '0.1+0.1+0.1', 'Entlang des Pfades addiert: 0,1 + 0,1 + 0,1 = 0,3.', 'Sind drei zu leichte Tüten häufiger als eine?', [10]],
  ] });

// ─── stoch_pfad_summe (Tiefe 7) ──────────────────────────────────────────────
const S = { skill: 'stoch_pfad_summe', art: 'p' };
def({ ...S, ref: 'stoch-pfad-summe-01', titel: 'Summenregel · Münze · genau einmal Kopf',
  frage: `Eine faire Münze wird zweimal geworfen.\n\nWie groß ist die Wahrscheinlichkeit, genau einmal Kopf zu werfen? ${PA}`,
  afb: 'I', afbGrund: 'Reproduzieren: zwei Pfade, je multiplizieren, dann addieren.',
  sach: false, prozess: 'Operieren', antwort: '1/2', r: '1/2*1/2+1/2*1/2', roh: [4],
  weg: 'Passende Pfade: Kopf – Zahl und Zahl – Kopf.\nP = 1/2 · 1/2 + 1/2 · 1/2 = 1/4 + 1/4 = 1/2 = 0,5 = 50 %.',
  ke: [
    ['1/4', 'nur_ein_pfad', '1/2*1/2', 'Nur den Pfad Kopf – Zahl gezählt.', 'Auf welchen Wegen kann genau einmal Kopf fallen?', [4]],
    ['2', 'pfadregel_addiert', '(1/2+1/2)+(1/2+1/2)', 'Entlang der Pfade addiert statt multipliziert.', 'Kann eine Wahrscheinlichkeit größer als 1 sein?'],
  ] });
def({ ...S, ref: 'stoch-pfad-summe-02', titel: 'Summenregel · Urne · zwei Farben mit Zurücklegen',
  frage: `In einer Urne liegen 3 rote und 2 blaue Kugeln. Es wird zweimal eine Kugel gezogen. Nach dem ersten Zug wird die Kugel zurückgelegt.\n\nWie groß ist die Wahrscheinlichkeit, zwei verschiedenfarbige Kugeln zu ziehen? ${PA}`,
  afb: 'I', afbGrund: 'Reproduzieren: zwei Pfade mit Zurücklegen, gleiche Faktoren in beiden Reihenfolgen.',
  sach: false, prozess: 'Operieren', antwort: '12/25', r: '3/5*2/5+2/5*3/5', roh: [25],
  weg: 'Passende Pfade: rot – blau und blau – rot.\nP = 3/5 · 2/5 + 2/5 · 3/5 = 6/25 + 6/25 = 12/25 = 0,48 = 48 %.',
  ke: [
    ['6/25', 'nur_ein_pfad', '3/5*2/5', 'Nur den Pfad rot – blau gezählt.', 'Kann die blaue Kugel auch zuerst gezogen werden?', [25]],
    ['3/5', 'zuruecklegen_ignoriert', '3/5*2/4+2/5*3/4', 'Im zweiten Zug so gerechnet, als fehlte die erste Kugel.', 'Wie viele Kugeln liegen beim zweiten Zug in der Urne, wenn zurückgelegt wird?', [20]],
  ] });
def({ ...S, ref: 'stoch-pfad-summe-03', titel: 'Summenregel · Urne · gleiche Farbe ohne Zurücklegen',
  frage: `In einer Urne liegen 4 rote und 6 blaue Kugeln. Es werden nacheinander zwei Kugeln ohne Zurücklegen gezogen.\n\nWie groß ist die Wahrscheinlichkeit, zwei Kugeln derselben Farbe zu ziehen? ${PB}`,
  afb: 'II', afbGrund: 'Anwenden: zwei Pfade ohne Zurücklegen, verschiedene Faktoren je Pfad.',
  sach: false, prozess: 'Operieren', antwort: '7/15', r: '4/10*3/9+6/10*5/9', roh: [90],
  weg: 'Passende Pfade: rot – rot und blau – blau.\nP = 4/10 · 3/9 + 6/10 · 5/9 = 12/90 + 30/90 = 42/90 = 7/15.',
  ke: [
    ['1/3', 'nur_ein_pfad', '6/10*5/9', 'Nur den Pfad blau – blau gezählt.', 'Welche zwei Farbpaare haben „dieselbe Farbe“?', [90]],
    ['2/15', 'nur_ein_pfad', '4/10*3/9', 'Nur den Pfad rot – rot gezählt.', 'Welche zwei Farbpaare haben „dieselbe Farbe“?', [90]],
    ['13/25', 'zuruecklegen_ignoriert', '4/10*4/10+6/10*6/10', 'Im zweiten Zug mit der alten Anzahl gerechnet.', 'Wie viele Kugeln liegen nach dem ersten Zug noch in der Urne?', [100]],
  ] });
def({ ...S, ref: 'stoch-pfad-summe-04', titel: 'Summenregel · Würfel · mindestens eine Sechs',
  frage: `Ein fairer Würfel wird zweimal geworfen.\n\nWie groß ist die Wahrscheinlichkeit, mindestens eine Sechs zu werfen? ${PB}`,
  afb: 'II', afbGrund: 'Anwenden: „mindestens einmal“ über das Gegenereignis „keine Sechs“ oder über drei Pfade.',
  sach: false, prozess: 'Operieren', antwort: '11/36', r: '1-5/6*5/6', roh: [36],
  weg: 'Gegenereignis: keine Sechs in beiden Würfen, P = 5/6 · 5/6 = 25/36.\nP(mindestens eine Sechs) = 1 − 25/36 = 11/36.\n(Oder drei Pfade: 1/36 + 5/36 + 5/36 = 11/36.)',
  ke: [
    ['25/36', 'gegenereignis_nicht_abgezogen', '5/6*5/6', 'P(keine Sechs) angegeben, nicht von 1 abgezogen.', 'Nach welchem Ereignis war gefragt?', [36]],
    ['1/3', 'pfadregel_addiert', '1/6+1/6', 'Die Wahrscheinlichkeiten der beiden Würfe addiert: 1/6 + 1/6.', 'Wie oft passt „zweimal Sechs“ in deine Rechnung – einmal oder zweimal?', [6, 36]],
    ['5/36', 'nur_ein_pfad', '1/6*5/6', 'Nur den Pfad Sechs – keine Sechs gezählt.', 'Auf welchen Wegen kann mindestens eine Sechs fallen?', [36]],
  ] });
def({ ...S, ref: 'stoch-pfad-summe-05', titel: 'Summenregel · Sachkontext · mindestens ein Gewinn',
  frage: `Bei einem Glücksspiel auf einem Jahrmarkt gewinnt man bei jeder Drehung eines Glücksrads mit der Wahrscheinlichkeit 0,2. Man dreht dreimal.\n\nWie groß ist die Wahrscheinlichkeit, mindestens einmal zu gewinnen? ${PA}`,
  afb: 'II', afbGrund: 'Anwenden: dreistufig, „mindestens einmal“ über das Gegenereignis.',
  sach: true, prozess: 'Modellieren', antwort: '0,488', r: '1-0.8*0.8*0.8', roh: [125, 1000],
  weg: 'Gegenereignis: dreimal kein Gewinn, P = 0,8 · 0,8 · 0,8 = 0,512.\nP(mindestens ein Gewinn) = 1 − 0,512 = 0,488 = 48,8 %.',
  ke: [
    ['0,512', 'gegenereignis_nicht_abgezogen', '0.8*0.8*0.8', 'P(kein Gewinn) angegeben, nicht von 1 abgezogen.', 'Nach welchem Ereignis war gefragt?', [125, 1000]],
    ['0,6', 'pfadregel_addiert', '0.2+0.2+0.2', 'Die Gewinnwahrscheinlichkeiten der drei Drehungen addiert.', 'Was käme bei sechs Drehungen heraus – passt das noch?', [5, 10]],
  ] });
def({ ...S, ref: 'stoch-pfad-summe-06', titel: 'Summenregel · Sachkontext · genau ein Gewinnlos',
  frage: `In einer Lostrommel liegen 10 Lose, 3 davon sind Gewinne. Es werden nacheinander zwei Lose gezogen, ein gezogenes Los kommt nicht zurück.\n\nWie groß ist die Wahrscheinlichkeit, genau ein Gewinnlos zu ziehen? ${PB}`,
  afb: 'II', afbGrund: 'Anwenden: zwei Pfade ohne Zurücklegen im Sachkontext.',
  sach: true, prozess: 'Modellieren', antwort: '7/15', r: '3/10*7/9+7/10*3/9', roh: [90],
  weg: 'Passende Pfade: Gewinn – Niete und Niete – Gewinn.\nP = 3/10 · 7/9 + 7/10 · 3/9 = 21/90 + 21/90 = 42/90 = 7/15.',
  ke: [
    ['7/30', 'nur_ein_pfad', '3/10*7/9', 'Nur den Pfad Gewinn – Niete gezählt.', 'Kann das Gewinnlos auch als zweites gezogen werden?', [90]],
    ['21/50', 'zuruecklegen_ignoriert', '3/10*7/10+7/10*3/10', 'Im zweiten Zug mit der alten Anzahl gerechnet.', 'Wie viele Lose liegen nach dem ersten Zug noch in der Trommel?', [100]],
  ] });
