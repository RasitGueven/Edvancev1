#!/usr/bin/env node
/**
 * k10-sinus-charge.mjs — erzeugt docs/prefill/k10-sinus.json (Charge-Format von vorlauf-build.mjs).
 *
 *   node tools/k10-sinus-charge.mjs
 *
 * Thema sinus (Sinusfunktion, KLP G9 NRW Fkt-13/Fkt-14, Zweite Stufe, Klasse 10), je sechs Aufgaben
 * zu fkt_sinus_einheitskreis, _bogenmass, _graph, _parameter und _periodisch. Keine Abbildungen:
 * Der Generator koordinatensystem zeichnet keine Sinuskurve; Graph-Eigenschaften stehen im Text
 * oder werden aus dem Term bestimmt. Jede Zahl über die Ausdrücke von tools/k10-rest-lib.mjs.
 * Sinuswerte an Bogenmaß-Stellen wie π/6 als S(30) (Gradmaß, exakt gleichwertig), damit der
 * 3,14-Rechenweg bei pi: true nicht künstlich abweicht. pi: true nur, wo mit π gerechnet und
 * gerundet wird. Eingabe nur Zahl oder Bruch; k in „k · π" mit bruch: true; Terme als MULTI_PART.
 * Die ids stehen in docs/prefill/k10-sinus-ids.json: ein zweiter Lauf erzeugt dieselbe Charge.
 */

import { baueCharge, CLUSTER, SATZ_PI } from './k10-rest-lib.mjs';

const A = [];
const BASIS = {
  inhalt: 'funktionen',
  cluster: CLUSTER.algebra,
  stoff: 10,
  stoffGrund: 'KLP Mathematik G9 NRW, Zweite Stufe, Fkt-13/Fkt-14: Sinus und Kosinus am Einheitskreis, Sinusfunktion, periodische Vorgänge; alle Kölner Schulpläne legen das Thema in Klasse 10.',
  clusterGrund: 'Die Sinusfunktion gehört wie lineare, quadratische und exponentielle Funktionen zu „Algebra & Funktionen".',
  inhaltGrund: 'Inhaltsbereich Funktionen (Sinusfunktion, Einheitskreis, Bogenmaß).',
};
const def = (o) => A.push({ ...BASIS, ...o });
const R1 = 'Runde auf eine Stelle nach dem Komma.';
const R2 = 'Runde auf zwei Stellen nach dem Komma.';
const EXAKT = 'Gib den exakten Wert an.';
const KPI = 'Gib k exakt an, als ganze Zahl oder als Bruch (zum Beispiel 2/3).';

// ─── fkt_sinus_einheitskreis (Tiefe 8) ───
const EK = { skill: 'fkt_sinus_einheitskreis' };
def({ ...EK, ref: 'sinus-einheitskreis-01', titel: 'sin 150° · exakter Wert', afb: 'I', sach: false, n: 'exakt',
  afbGrund: 'Reproduzieren: Sinuswert im zweiten Viertel über den Bezugswinkel 30° bestimmen.',
  frage: `Der Winkel α = 150° ist im Gradmaß angegeben.\n\nBestimme sin 150°. ${EXAKT}`, r: 'S(150)',
  weg: 'Am Einheitskreis liegt der Punkt zu 150° im zweiten Viertel, oberhalb der x-Achse.\nBezugswinkel: 180° − 150° = 30°, sin 30° = 0,5.\nIm zweiten Viertel ist der Sinus positiv: sin 150° = {A}.',
  ke: [['quadrant_vorzeichen', '0-S(30)', 'Im zweiten Viertel ein Minus vor den Sinus gesetzt: −0,5.', 'Liegt der Punkt zu 150° oberhalb oder unterhalb der x-Achse?'],
    ['bogenmass_modus', 'SR(150)', 'Den Taschenrechner im Bogenmaß gelassen: sin(150) im Bogenmaß ≈ −0,71.', 'Steht dein Taschenrechner auf DEG oder auf RAD?', 2]] });
def({ ...EK, ref: 'sinus-einheitskreis-02', titel: 'cos 200° · gerundet', afb: 'I', sach: false, n: 2,
  afbGrund: 'Reproduzieren: Kosinuswert im dritten Viertel mit dem Taschenrechner bestimmen und runden.',
  frage: `Der Winkel α = 200° ist im Gradmaß angegeben.\n\nBestimme cos 200°. ${R2}`, r: 'C(200)',
  weg: 'Taschenrechner im Gradmaß (DEG): cos 200° ≈ −0,9397.\nDer Punkt zu 200° liegt im dritten Viertel links der y-Achse, der Kosinus ist negativ.\ncos 200° ≈ {A}.',
  ke: [['quadrant_vorzeichen', 'C(20)', 'Nur den Wert des Bezugswinkels 20° genommen, ohne Minus: 0,94.', 'Liegt der Punkt zu 200° links oder rechts der y-Achse?'],
    ['bogenmass_modus', 'CR(200)', 'Den Taschenrechner im Bogenmaß gelassen: cos(200) im Bogenmaß ≈ 0,49.', 'Steht dein Taschenrechner auf DEG oder auf RAD?']] });
def({ ...EK, ref: 'sinus-einheitskreis-03', titel: 'Punkt auf dem Einheitskreis · α = 240°', afb: 'II', sach: false,
  afbGrund: 'Anwenden: Koordinaten (cos α | sin α) im dritten Viertel mit beiden Vorzeichen angeben.',
  frage: `Der Punkt P liegt auf dem Einheitskreis (Mittelpunkt im Ursprung, Radius 1). Die Strecke vom Ursprung zu P bildet mit der positiven x-Achse den Winkel α = 240° (Gradmaß, gegen den Uhrzeigersinn gemessen).\n\nGib die Koordinaten von P an. ${R2}`,
  teile: [{ prompt: 'x-Koordinate von P', r: 'C(240)', n: 2,
    ke: [['quadrant_vorzeichen', 'C(60)', 'Das Minus im dritten Viertel übersehen: 0,5 statt −0,5.', 'Liegt P links oder rechts der y-Achse?'],
      ['koordinaten_vertauscht', 'S(240)', 'Den Sinus als x-Koordinate genommen.', 'Welche Koordinate gehört am Einheitskreis zum Kosinus?']] },
  { prompt: 'y-Koordinate von P', r: 'S(240)', n: 2,
    ke: [['quadrant_vorzeichen', 'S(60)', 'Das Minus im dritten Viertel übersehen: 0,87 statt −0,87.', 'Liegt P oberhalb oder unterhalb der x-Achse?'],
      ['koordinaten_vertauscht', 'C(240)', 'Den Kosinus als y-Koordinate genommen.', 'Welche Koordinate gehört am Einheitskreis zum Sinus?']] }],
  weg: 'Am Einheitskreis gilt P(cos α | sin α).\n240° liegt im dritten Viertel: beide Koordinaten sind negativ. Bezugswinkel 240° − 180° = 60°.\nx = cos 240° = −cos 60° = {1}.\ny = sin 240° = −sin 60° ≈ {2}.' });
def({ ...EK, ref: 'sinus-einheitskreis-04', titel: 'Winkel aus cos α = −0,6 · zweites Viertel', einheit: '°', afb: 'II', sach: false, n: 1,
  afbGrund: 'Anwenden: Winkel aus einem negativen Kosinuswert mit cos⁻¹ bestimmen und das Viertel prüfen.',
  frage: `Für einen Winkel α zwischen 90° und 180° gilt cos α = −0,6.\n\nWie groß ist α im Gradmaß? ${R1}`, r: 'AC(0-0.6)',
  weg: 'Taschenrechner im Gradmaß: α = cos⁻¹(−0,6) ≈ 126,87°.\nDer Wert liegt zwischen 90° und 180°, passt also.\nα ≈ {A}°.',
  ke: [['quadrant_vorzeichen', 'AC(0.6)', 'Das Minus weggelassen: cos⁻¹(0,6) ≈ 53,1° liegt im ersten Viertel.', 'Ist der Kosinus im ersten Viertel positiv oder negativ?'],
    ['bogenmass_modus', 'AC(0-0.6)*P/180', 'Den Taschenrechner im Bogenmaß gelassen: cos⁻¹(−0,6) ≈ 2,2.', 'Kann ein Winkel zwischen 90° und 180° die Größe 2,2 haben?']] });
def({ ...EK, ref: 'sinus-einheitskreis-05', titel: 'Rückrichtung · zweiter Winkel mit sin α = sin 50°', einheit: '°', afb: 'II', sach: false, n: 'exakt',
  afbGrund: 'Anwenden in der Rückrichtung: den zweiten Winkel mit gleichem Sinuswert über die Symmetrie zur y-Achse finden.',
  frage: `Es gilt sin 50° ≈ 0,77 (Gradmaß).\n\nEs gibt einen zweiten Winkel α zwischen 0° und 360°, für den sin α = sin 50° gilt. Wie groß ist α im Gradmaß? ${EXAKT}`, r: '180-50',
  weg: 'Gleicher Sinus heißt gleiche y-Koordinate am Einheitskreis.\nDer zweite Punkt liegt spiegelbildlich zur y-Achse im zweiten Viertel.\nα = 180° − 50° = {A}°.',
  ke: [['quadrant_vorzeichen', '360-50', 'Den Winkel im vierten Viertel genommen: Dort ist der Sinus negativ, sin 310° ≈ −0,77.', 'Liegt der Punkt zu 310° oberhalb oder unterhalb der x-Achse?'],
    ['quadrant_vorzeichen', '180+50', 'Den Winkel im dritten Viertel genommen: Dort ist der Sinus negativ, sin 230° ≈ −0,77.', 'Welches Vorzeichen hat der Sinus im dritten Viertel?']] });
def({ ...EK, ref: 'sinus-einheitskreis-06', titel: 'Rückrichtung · Punkt mit y = −0,6 im vierten Viertel', afb: 'III', sach: false,
  afbGrund: 'Problemlösen: aus der y-Koordinate über x² + y² = 1 die x-Koordinate und über sin⁻¹ den Winkel im vierten Viertel bestimmen.',
  frage: `Ein Punkt P auf dem Einheitskreis (Mittelpunkt im Ursprung, Radius 1) liegt im vierten Viertel und hat die y-Koordinate −0,6. α ist der Winkel zwischen der positiven x-Achse und der Strecke vom Ursprung zu P, gegen den Uhrzeigersinn gemessen, mit 0° ≤ α < 360°.\n\nBestimme die x-Koordinate von P und den Winkel α im Gradmaß. ${R2}`,
  teile: [{ prompt: 'x-Koordinate von P', r: 'W(1-0.6^2)', n: 2,
    ke: [['quadrant_vorzeichen', '0-W(1-0.6^2)', 'Ein Minus gesetzt: Im vierten Viertel liegt P rechts der y-Achse, x ist positiv.', 'Liegt das vierte Viertel links oder rechts der y-Achse?'],
      ['wurzel_vergessen', '1-0.6^2', 'x² = 0,64 ausgerechnet, aber die Wurzel nicht gezogen.', 'Hast du x oder x² berechnet?']] },
  { prompt: 'Winkel α in Grad', r: '360+AS(0-0.6)', n: 2,
    ke: [['quadrant_vorzeichen', '180+AS(0.6)', 'Den Winkel im dritten Viertel genommen: Dort ist der Kosinus negativ, P läge links der y-Achse.', 'Liegt dein Winkel im vierten Viertel, also zwischen 270° und 360°?'],
      ['bogenmass_modus', '2*P+AS(0-0.6)*P/180', 'Im Bogenmaß gerechnet: 2π + sin⁻¹(−0,6) ≈ 5,64.', 'Ist nach dem Winkel im Gradmaß gefragt?']] }],
  weg: 'Am Einheitskreis gilt x² + y² = 1, also x² = 1 − 0,36 = 0,64.\nIm vierten Viertel ist x positiv: x = √0,64 = {1}.\nsin⁻¹(−0,6) ≈ −36,87°; im Bereich 0° bis 360°: α = 360° − 36,87° ≈ {2}°.' });

// ─── fkt_sinus_bogenmass (Tiefe 8) ───
const BM = { skill: 'fkt_sinus_bogenmass' };
def({ ...BM, ref: 'sinus-bogenmass-01', titel: '60° als Vielfaches von π', afb: 'I', sach: false, n: 'exakt', bruch: true,
  afbGrund: 'Reproduzieren: Gradmaß über 180° = π in einen Faktor von π umrechnen.',
  frage: `Der Winkel 60° ist im Gradmaß angegeben. Im Bogenmaß lässt er sich als k · π schreiben.\n\nWie groß ist k? ${KPI}`, r: '60/180',
  weg: '180° entsprechen π.\n60° = 60/180 · π = 1/3 · π.\nk = {A}.',
  ke: [['kreisanteil_falsch', '60/360', 'Mit 360° = π gerechnet: 60/360 = 1/6.', 'Wie viel Grad entsprechen π: ein halber oder ein ganzer Kreis?'],
    ['grad_bogen_faktor_falsch', '180/60', 'Den Faktor umgedreht: 180/60 = 3.', 'Muss 60° ein größerer oder ein kleinerer Teil von π sein als 180°?']] });
def({ ...BM, ref: 'sinus-bogenmass-02', titel: '50° im Bogenmaß · Dezimalzahl', afb: 'I', sach: false, n: 2, pi: true,
  afbGrund: 'Reproduzieren: Gradmaß mit dem Faktor π/180 ins Bogenmaß umrechnen und runden.',
  frage: `Der Winkel 50° ist im Gradmaß angegeben.\n\nRechne ihn ins Bogenmaß um und gib das Ergebnis als Dezimalzahl an. ${SATZ_PI} ${R2}`, r: '50*P/180',
  weg: 'x = 50 · π/180 ≈ {A} (π-Taste).\nMit π ≈ 3,14: x = 50 · 3,14 : 180 ≈ {B}.',
  ke: [['grad_bogen_faktor_falsch', '50*180/P', 'Mit 180/π statt π/180 multipliziert: ≈ 2864,79.', 'Ein voller Kreis hat im Bogenmaß etwa 6,28 – kann 50° dann über 2000 sein?'],
    ['pi_vergessen', '50/180', 'π weggelassen: 50/180 ≈ 0,28.', 'Welcher Faktor gehört zu 180° im Bogenmaß?']] });
def({ ...BM, ref: 'sinus-bogenmass-03', titel: 'x = 4 im Bogenmaß · in Grad', einheit: '°', afb: 'II', sach: false, n: 1, pi: true,
  afbGrund: 'Anwenden: Rückrichtung vom Bogenmaß ins Gradmaß ohne π im Ausgangswert.',
  frage: `Ein Winkel hat im Bogenmaß die Größe x = 4.\n\nWie groß ist er im Gradmaß? ${SATZ_PI} ${R1}`, r: '4*180/P',
  weg: 'Bogenmaß → Gradmaß: mit 180/π multiplizieren.\nα = 4 · 180°/π ≈ {A}° (π-Taste).\nMit π ≈ 3,14: α = 720° : 3,14 ≈ {B}°.',
  ke: [['grad_bogen_faktor_falsch', '4*P/180', 'Mit π/180 statt 180/π multipliziert: ≈ 0,07.', 'π im Bogenmaß sind 180°. Ist 4 mehr oder weniger als π?', 2],
    ['pi_vergessen', '4*180', 'Nicht durch π geteilt: 4 · 180 = 720.', 'Welche Bogenmaß-Zahl gehört zu 180°: 1 oder π?']] });
def({ ...BM, ref: 'sinus-bogenmass-04', titel: 'x = 5π/4 im Bogenmaß · in Grad', einheit: '°', afb: 'II', sach: false, n: 'exakt',
  afbGrund: 'Anwenden: Bogenmaß mit π im Bruch ins Gradmaß umrechnen, π kürzt sich.',
  frage: `Ein Winkel hat im Bogenmaß die Größe x = 5π/4.\n\nWie groß ist er im Gradmaß? ${EXAKT}`, r: '5/4*180',
  weg: 'π entspricht 180°.\nx = 5/4 · π entspricht 5/4 · 180° = {A}°.',
  ke: [['kreisanteil_falsch', '5/4*360', 'Mit π = 360° gerechnet: 5/4 · 360° = 450°.', 'Entspricht π einem halben oder einem ganzen Kreis?'],
    ['grad_bogen_faktor_falsch', '5/4*P*P/180', 'Mit π/180 statt 180/π multipliziert: ≈ 0,07.', 'Ist 5π/4 mehr oder weniger als π, also mehr oder weniger als 180°?', 2]] });
def({ ...BM, ref: 'sinus-bogenmass-05', titel: 'Bogenlänge · Karussellsitz dreht sich um 130°', einheit: 'm', afb: 'II', sach: true, n: 2, pi: true,
  afbGrund: 'Anwenden im Sachkontext: Am Kreis mit Radius 1 ist die Bogenlänge gleich dem Bogenmaß des Winkels.',
  frage: `Ein Karussellsitz bewegt sich auf einem Kreis mit dem Radius 1 m. Er dreht sich um 130° (Gradmaß) weiter.\n\nWie viele Meter legt der Sitz auf dem Kreisbogen zurück? ${SATZ_PI} ${R2}`, r: '130*P/180',
  weg: 'Am Kreis mit Radius 1 ist die Bogenlänge gleich dem Bogenmaß: b = 130 · π/180.\nb ≈ {A} m (π-Taste).\nMit π ≈ 3,14: b = 130 · 3,14 : 180 ≈ {B} m.',
  ke: [['grad_bogen_faktor_falsch', '130*180/P', 'Mit 180/π statt π/180 multipliziert: ≈ 7448 m.', 'Ein ganzer Umlauf ist etwa 6,28 m lang – kann ein Teil davon länger sein?'],
    ['kreisanteil_falsch', '360/130*2*P', 'Den Anteil umgedreht: 360/130 statt 130/360 vom Umfang.', 'Ist der Bogen kürzer oder länger als ein ganzer Umlauf?'],
    ['pi_vergessen', '130/180', 'π weggelassen: 130/180 ≈ 0,72.', 'Welche Bogenlänge hat ein halber Kreis mit Radius 1?']] });
def({ ...BM, ref: 'sinus-bogenmass-06', titel: 'Rückrichtung · Winkel aus Bogen 5 cm am Kreis mit r = 3 cm', einheit: '°', afb: 'III', sach: false, n: 1, pi: true,
  afbGrund: 'Problemlösen: Bogenmaß als Bogenlänge durch Radius bilden, dann ins Gradmaß umrechnen.',
  frage: `Ein Kreis hat den Radius 3 cm. Ein Kreisbogen auf diesem Kreis ist 5 cm lang.\n\nWie groß ist der zugehörige Mittelpunktswinkel im Gradmaß? ${SATZ_PI} ${R1}`, r: '5/3*180/P',
  weg: 'Bogenmaß: x = Bogenlänge : Radius = 5 : 3.\nIn Grad: α = 5/3 · 180°/π ≈ {A}° (π-Taste).\nMit π ≈ 3,14: α = 300° : 3,14 ≈ {B}°.',
  ke: [['multipliziert_statt_dividiert', '5*3*180/P', 'Bogenlänge mal Radius statt geteilt durch den Radius.', 'Wie hängen Bogenlänge, Radius und Bogenmaß zusammen: b = x · r?'],
    ['grad_bogen_faktor_falsch', '5/3*P/180', 'Mit π/180 statt 180/π multipliziert: ≈ 0,03.', 'Ein Bogen von 5 cm bei 3 cm Radius: Ist der Winkel eher klein oder fast ein rechter?', 2]] });

// ─── fkt_sinus_graph (Tiefe 9) ───
const GR = { skill: 'fkt_sinus_graph' };
def({ ...GR, ref: 'sinus-graph-01', titel: 'Funktionswert · sin(7π/6)', afb: 'I', sach: false, n: 'exakt',
  afbGrund: 'Reproduzieren: Funktionswert an einer Bogenmaß-Stelle über den Einheitskreis bestimmen.',
  frage: `Gegeben ist f(x) = sin x, x im Bogenmaß.\n\nBerechne f(7π/6). ${EXAKT}`, r: 'S(210)',
  weg: '7π/6 im Bogenmaß entspricht 7/6 · 180° = 210°.\n210° liegt im dritten Viertel, der Sinus ist negativ. Bezugswinkel 30°, sin 30° = 0,5.\nf(7π/6) = sin 210° = {A}.',
  ke: [['quadrant_vorzeichen', 'S(30)', 'Das Minus im dritten Viertel übersehen: 0,5.', 'Liegt der Punkt zu 7π/6 oberhalb oder unterhalb der x-Achse?'],
    ['bogenmass_modus', 'S(7*P/6)', 'Den Taschenrechner im Gradmaß gelassen: sin(3,67°) ≈ 0,06.', 'Steht dein Taschenrechner auf DEG oder auf RAD?', 2]] });
def({ ...GR, ref: 'sinus-graph-02', titel: 'Funktionswert · sin(π/3) gerundet', afb: 'I', sach: false, n: 2,
  afbGrund: 'Reproduzieren: Funktionswert an einer Bogenmaß-Stelle im ersten Viertel bestimmen und runden.',
  frage: `Gegeben ist f(x) = sin x, x im Bogenmaß.\n\nBerechne f(π/3). ${R2}`, r: 'S(60)',
  weg: 'Taschenrechner im Bogenmaß (RAD): sin(π/3) ≈ 0,8660.\n(Gleichwertig: π/3 entspricht 60°, sin 60° ≈ 0,8660.)\nf(π/3) ≈ {A}.',
  ke: [['bogenmass_modus', 'S(P/3)', 'Den Taschenrechner im Gradmaß gelassen: sin(1,05°) ≈ 0,02.', 'Steht dein Taschenrechner auf DEG oder auf RAD?']] });
def({ ...GR, ref: 'sinus-graph-03', titel: 'Hoch- und Tiefpunkt in [0; 2π] als Vielfache von π', afb: 'II', sach: false, bruch: true,
  afbGrund: 'Anwenden: Lage von Hoch- und Tiefpunkt des Graphen aus dem Einheitskreis ins Bogenmaß übertragen.',
  frage: `Der Graph von f(x) = sin x (x im Bogenmaß) hat im Intervall [0; 2π] genau einen Hochpunkt und genau einen Tiefpunkt. Ihre x-Koordinaten lassen sich als k · π schreiben.\n\nGib jeweils k an. ${KPI}`,
  teile: [{ prompt: 'k für den Hochpunkt', r: '90/180', n: 'exakt', bruch: true,
    ke: [['falsche_groesse_beantwortet', '270/180', 'Die Stelle des Tiefpunkts angegeben.', 'Ist sin x an deiner Stelle 1 oder −1?'],
      ['einheit_uebersprungen', '90', 'Den Winkel im Gradmaß angegeben: 90.', 'Ist nach dem Gradmaß oder nach dem Faktor vor π gefragt?']] },
  { prompt: 'k für den Tiefpunkt', r: '270/180', n: 'exakt', bruch: true,
    ke: [['falsche_groesse_beantwortet', '90/180', 'Die Stelle des Hochpunkts angegeben.', 'Ist sin x an deiner Stelle 1 oder −1?'],
      ['einheit_uebersprungen', '270', 'Den Winkel im Gradmaß angegeben: 270.', 'Ist nach dem Gradmaß oder nach dem Faktor vor π gefragt?']] }],
  weg: 'Der Sinus ist am größten (1) bei 90° und am kleinsten (−1) bei 270°.\n90° = π/2, also k = {1} für den Hochpunkt.\n270° = 3π/2, also k = {2} für den Tiefpunkt.' });
def({ ...GR, ref: 'sinus-graph-04', titel: 'Funktionswert · sin(5) mit Vorzeichen', afb: 'II', sach: false, n: 2,
  afbGrund: 'Anwenden: Bogenmaß-Stelle ohne π, Lage im vierten Viertel erkennen, negatives Ergebnis.',
  frage: `Gegeben ist f(x) = sin x, x im Bogenmaß.\n\nBerechne f(5). ${R2}`, r: 'SR(5)',
  weg: 'Taschenrechner im Bogenmaß (RAD): sin(5) ≈ −0,9589.\nProbe: 3π/2 ≈ 4,71 < 5 < 2π ≈ 6,28, die Stelle liegt im vierten Viertel, dort ist sin x negativ.\nf(5) ≈ {A}.',
  ke: [['bogenmass_modus', 'S(5)', 'Den Taschenrechner im Gradmaß gelassen: sin 5° ≈ 0,09.', 'Steht dein Taschenrechner auf DEG oder auf RAD?'],
    ['quadrant_vorzeichen', '0-SR(5)', 'Das Minus weggelassen: 0,96.', 'Liegt x = 5 zwischen 3π/2 und 2π? Welches Vorzeichen hat sin x dort?']] });
def({ ...GR, ref: 'sinus-graph-05', titel: 'Rückrichtung · zweite Stelle mit sin x = sin(π/5)', afb: 'II', sach: false, n: 'exakt', bruch: true,
  afbGrund: 'Anwenden in der Rückrichtung: Symmetrie des Graphen zur Geraden x = π/2 nutzen.',
  frage: `Der Graph von f(x) = sin x (x im Bogenmaß) hat an der Stelle x = π/5 den Wert f(π/5) ≈ 0,59.\n\nEs gibt genau eine weitere Stelle im Intervall [0; 2π] mit demselben Funktionswert. Sie lässt sich als k · π schreiben. Wie groß ist k? ${KPI}`, r: '1-1/5',
  weg: 'Der Graph ist zwischen 0 und π symmetrisch zur Geraden x = π/2.\nZweite Stelle: π − π/5 = 4π/5.\nk = {A}.',
  ke: [['quadrant_vorzeichen', '1+1/5', 'π + π/5 genommen: Dort ist sin x negativ (≈ −0,59).', 'Ist sin x zwischen π und 2π positiv oder negativ?'],
    ['quadrant_vorzeichen', '2-1/5', '2π − π/5 genommen: Dort ist sin x negativ (≈ −0,59).', 'Ist sin x zwischen π und 2π positiv oder negativ?']] });
def({ ...GR, ref: 'sinus-graph-06', titel: 'Anzahl der Nullstellen in [0; 20]', afb: 'III', sach: false, n: 'ab',
  afbGrund: 'Problemlösen: Nullstellen als Vielfache von π erkennen und im Intervall abzählen, Randstelle 0 mitzählen.',
  frage: `Gegeben ist f(x) = sin x, x im Bogenmaß.\n\nWie viele Nullstellen hat f im Intervall [0; 20]? Die Intervallgrenzen gehören dazu. Gib eine ganze Zahl an.`, r: '20/P+1',
  weg: 'Die Nullstellen von sin x sind 0, π, 2π, 3π, …\n20 : π ≈ 6,37, also liegen 0, π, 2π, …, 6π im Intervall (6π ≈ 18,85; 7π ≈ 21,99 liegt außerhalb).\nDas sind {A} Nullstellen.',
  ke: [['pi_vergessen', '20/1+1', 'π weggelassen: Nullstellen bei 0, 1, 2, …, 20 gezählt.', 'Wo schneidet der Graph von sin x die x-Achse zum zweiten Mal: bei 1 oder bei π?'],
    ['bogenmass_modus', '20/180+1', 'Im Gradmaß gedacht: Zwischen 0° und 20° liegt nur die Nullstelle 0.', 'Ist das Intervall [0; 20] im Gradmaß oder im Bogenmaß gemeint?']] });

// ─── fkt_sinus_parameter (Tiefe 10) ───
const PA = { skill: 'fkt_sinus_parameter' };
def({ ...PA, ref: 'sinus-parameter-01', titel: 'Amplitude · f(x) = 3·sin(2x)', afb: 'I', sach: false, n: 'exakt',
  afbGrund: 'Reproduzieren: Amplitude als Faktor a vor dem Sinus ablesen.',
  frage: `Gegeben ist f(x) = 3 · sin(2x), x im Bogenmaß.\n\nWie groß ist die Amplitude von f? ${EXAKT}`, r: '3',
  weg: 'Bei f(x) = a · sin(b · x) ist die Amplitude |a|.\nHier ist a = 3, die Amplitude ist {A}.\nDie Funktionswerte liegen zwischen −3 und 3.',
  ke: [['amplitude_verwechselt', '2*3', 'Den Abstand zwischen Hoch- und Tiefpunkt angegeben: 3 − (−3) = 6.', 'Wie weit liegt der Hochpunkt über der x-Achse?'],
    ['amplitude_verwechselt', '3/2', 'Die Amplitude halbiert: 1,5.', 'Welchen größten Wert nimmt 3 · sin(2x) an?']] });
def({ ...PA, ref: 'sinus-parameter-02', titel: 'Periode · f(x) = sin(4x) als Vielfaches von π', afb: 'I', sach: false, n: 'exakt', bruch: true,
  afbGrund: 'Reproduzieren: Periode mit p = 2π : b bestimmen.',
  frage: `Gegeben ist f(x) = sin(4x), x im Bogenmaß. Die Periode p von f lässt sich als p = k · π schreiben.\n\nWie groß ist k? ${KPI}`, r: '2/4',
  weg: 'Periode p = 2π : b = 2π : 4 = π/2.\nk = {A}.',
  ke: [['periode_falsch', '4', 'Den Faktor b = 4 als Periode genommen.', 'Wird der Graph durch b = 4 gestreckt oder gestaucht?'],
    ['periode_falsch', '2*4', '2π · 4 = 8π statt 2π : 4 gerechnet.', 'Wiederholt sich sin(4x) schneller oder langsamer als sin x?']] });
def({ ...PA, ref: 'sinus-parameter-03', titel: 'Periode · f(x) = 2·sin(0,5x) als Dezimalzahl', afb: 'II', sach: false, n: 2, pi: true,
  afbGrund: 'Anwenden: Periode bei b < 1 berechnen (Streckung) und als Dezimalzahl runden.',
  frage: `Gegeben ist f(x) = 2 · sin(0,5x), x im Bogenmaß.\n\nWie groß ist die Periode von f? Gib sie als Dezimalzahl an. ${SATZ_PI} ${R2}`, r: '2*P/0.5',
  weg: 'Periode p = 2π : b = 2π : 0,5 = 4π.\np ≈ {A} (π-Taste).\nMit π ≈ 3,14: p = 4 · 3,14 = {B}.',
  ke: [['periode_falsch', '2*P*0.5', '2π · 0,5 = π statt 2π : 0,5 gerechnet.', 'Wiederholt sich sin(0,5x) schneller oder langsamer als sin x?'],
    ['periode_falsch', '0.5', 'Den Faktor b = 0,5 als Periode genommen.', 'Welche Periode hat sin x – und was macht der Faktor 0,5 damit?'],
    ['pi_vergessen', '2/0.5', 'π weggelassen: 2 : 0,5 = 4.', 'Welche Periode hat sin x im Bogenmaß?']] });
def({ ...PA, ref: 'sinus-parameter-04', titel: 'Größter Wert und Periode · f(x) = −4·sin(2x)', afb: 'II', sach: false,
  afbGrund: 'Anwenden: negativer Faktor a – größter Funktionswert ist |a|; Periode als Vielfaches von π.',
  frage: `Gegeben ist f(x) = −4 · sin(2x), x im Bogenmaß.\n\nBestimme den größten Funktionswert von f und die Periode p = k · π. ${EXAKT} ${KPI}`,
  teile: [{ prompt: 'größter Funktionswert', r: '4', n: 'exakt',
    ke: [['betrag_fehler', '0-4', 'Den Faktor −4 als größten Wert genommen.', 'Welchen Wert hat f an einer Stelle, an der sin(2x) = −1 ist?'],
      ['amplitude_verwechselt', '2*4', 'Den Abstand zwischen größtem und kleinstem Wert angegeben: 8.', 'Wie weit liegt der höchste Punkt über der x-Achse?']] },
  { prompt: 'k in p = k · π', r: '2/2', n: 'exakt', bruch: true,
    ke: [['periode_falsch', '2*2', '2π · 2 = 4π statt 2π : 2 gerechnet.', 'Wiederholt sich sin(2x) schneller oder langsamer als sin x?'],
      ['periode_falsch', '1/2', 'Mit p = π : b statt 2π : b gerechnet.', 'Welche Periode hat sin x?']] }],
  weg: 'Das Minus spiegelt den Graphen an der x-Achse, die Werte liegen weiter zwischen −4 und 4.\nGrößter Funktionswert: {1} (z. B. bei sin(2x) = −1).\nPeriode: p = 2π : 2 = π, also k = {2}.' });
def({ ...PA, ref: 'sinus-parameter-05', titel: 'Rückrichtung · a und b aus Amplitude 1,5 und Periode π', afb: 'II', sach: false,
  afbGrund: 'Anwenden in der Rückrichtung: a aus der Amplitude, b aus b = 2π : p.',
  frage: `Eine Funktion f(x) = a · sin(b · x) mit a > 0 und b > 0 (x im Bogenmaß) hat die Amplitude 1,5 und die Periode π.\n\nBestimme a und b. ${EXAKT}`,
  teile: [{ prompt: 'a', r: '1.5', n: 'exakt',
    ke: [['amplitude_verwechselt', '2*1.5', 'Die Amplitude verdoppelt: a = 3.', 'Wie weit liegt der Hochpunkt von f über der x-Achse?'],
      ['amplitude_verwechselt', '1.5/2', 'Die Amplitude halbiert: a = 0,75.', 'Welchen größten Wert hat a · sin(b · x)?']] },
  { prompt: 'b', r: '2*P/P', n: 'exakt',
    ke: [['periode_falsch', 'P', 'Die Periode π als b genommen: b ≈ 3,14.', 'Ist b die Periode oder der Faktor, der die Periode bestimmt?', 2],
      ['periode_falsch', 'P/(2*P)', 'b = p : 2π statt 2π : p gerechnet.', 'Wird der Graph mit Periode π gegenüber sin x gestaucht oder gestreckt?']] }],
  weg: 'Die Amplitude ist a, also a = {1}.\nAus p = 2π : b folgt b = 2π : p = 2π : π = {2}.\nf(x) = 1,5 · sin(2x).' });
def({ ...PA, ref: 'sinus-parameter-06', titel: 'Rückrichtung · a und b aus Hoch- und Tiefpunkt', afb: 'III', sach: false,
  afbGrund: 'Problemlösen: aus benachbartem Hoch- und Tiefpunkt Amplitude und halbe Periode gewinnen, dann b bestimmen.',
  frage: `Der Graph von f(x) = a · sin(b · x) mit a > 0 und b > 0 (x im Bogenmaß) hat den Hochpunkt H(π/8 | 2,5). Der nächste Tiefpunkt rechts davon ist T(3π/8 | −2,5).\n\nBestimme a und b. ${EXAKT}`,
  teile: [{ prompt: 'a', r: '2.5', n: 'exakt',
    ke: [['amplitude_verwechselt', '2.5-(0-2.5)', 'Den Abstand zwischen Hoch- und Tiefpunkt als a genommen: 5.', 'Wie weit liegt H über der x-Achse?']] },
  { prompt: 'b', r: '2*P/(2*(3*P/8-P/8))', n: 'exakt',
    ke: [['periode_falsch', '2*(3*P/8-P/8)/(2*P)', 'b = p : 2π statt 2π : p gerechnet: 0,25.', 'Wird der Graph gegenüber sin x gestaucht oder gestreckt?'],
      ['falsche_groesse_beantwortet', '2*P/(3*P/8-P/8)', 'Den Abstand von H zu T als ganze Periode genommen: b = 8.', 'Wie viele Perioden liegen zwischen einem Hochpunkt und dem nächsten Tiefpunkt?']] }],
  weg: 'Die Amplitude ist der Abstand des Hochpunkts von der x-Achse: a = {1}.\nVon H zu T ist eine halbe Periode: 3π/8 − π/8 = π/4, also p = π/2.\nb = 2π : p = 2π : π/2 = {2}.' });

// ─── fkt_sinus_periodisch (Tiefe 11) ───
const PE = { skill: 'fkt_sinus_periodisch', sach: true };
const RIESENRAD = 'Die Höhe einer Gondel eines Riesenrads über dem Boden wird beschrieben durch h(t) = 18 · sin(0,2 · t) + 20. Dabei ist t die Zeit in Minuten und h(t) die Höhe in Metern; das Argument des Sinus ist im Bogenmaß.';
def({ ...PE, ref: 'sinus-periodisch-01', titel: 'Riesenrad · größte Höhe der Gondel', einheit: 'm', afb: 'I', n: 'exakt',
  afbGrund: 'Reproduzieren im Sachkontext: Höchstwert als Mittellinie plus Amplitude ablesen.',
  frage: `${RIESENRAD}\n\nWie hoch ist die Gondel höchstens über dem Boden? ${EXAKT}`, r: '20+18',
  weg: 'Der Sinus nimmt höchstens den Wert 1 an.\nh = 18 · 1 + 20 = {A} m.',
  ke: [['falsche_groesse_beantwortet', '18', 'Nur die Amplitude angegeben, die Mittellinie 20 m fehlt.', 'In welcher Höhe liegt die Mitte des Riesenrads?'],
    ['amplitude_verwechselt', '2*18', 'Den Abstand zwischen höchstem und tiefstem Punkt angegeben: 36 m.', 'Ist nach der größten Höhe über dem Boden oder nach dem Durchmesser gefragt?']] });
def({ ...PE, ref: 'sinus-periodisch-02', titel: 'Gezeiten · Unterschied zwischen Hoch- und Niedrigwasser', einheit: 'm', afb: 'I', n: 'exakt',
  afbGrund: 'Reproduzieren im Sachkontext: Abstand von Höchst- und Tiefstwert als doppelte Amplitude.',
  frage: `An einem Hafen wird der Wasserstand gegenüber dem mittleren Wasserstand beschrieben durch w(t) = 1,8 · sin(0,5 · t). Dabei ist t die Zeit in Stunden und w(t) der Wasserstand in Metern; das Argument des Sinus ist im Bogenmaß.\n\nWie viele Meter liegt Hochwasser über Niedrigwasser? ${EXAKT}`, r: '1.8-(0-1.8)',
  weg: 'Hochwasser: w = 1,8 m über dem Mittel. Niedrigwasser: w = −1,8 m.\nUnterschied: 1,8 m − (−1,8 m) = {A} m.',
  ke: [['amplitude_verwechselt', '1.8', 'Nur die Amplitude angegeben: Abstand vom Mittel, nicht von Hoch- zu Niedrigwasser.', 'Wie tief liegt Niedrigwasser unter dem mittleren Wasserstand?']] });
def({ ...PE, ref: 'sinus-periodisch-03', titel: 'Riesenrad · Dauer einer Umdrehung', einheit: 'min', afb: 'II', n: 1, pi: true,
  afbGrund: 'Anwenden im Sachkontext: Umlaufzeit als Periode 2π : b deuten.',
  frage: `${RIESENRAD}\n\nWie viele Minuten dauert eine volle Umdrehung? ${SATZ_PI} ${R1}`, r: '2*P/0.2',
  weg: 'Eine Umdrehung ist eine Periode: p = 2π : b = 2π : 0,2 = 10π.\np ≈ {A} min (π-Taste).\nMit π ≈ 3,14: p = 10 · 3,14 = {B} min.',
  ke: [['periode_falsch', '2*P*0.2', '2π · 0,2 statt 2π : 0,2 gerechnet: ≈ 1,3 min.', 'Dreht sich ein großes Riesenrad in gut einer Minute einmal herum?'],
    ['pi_vergessen', '2/0.2', 'π weggelassen: 2 : 0,2 = 10 min.', 'Welche Periode hat sin t?']] });
def({ ...PE, ref: 'sinus-periodisch-04', titel: 'Tageslänge · 50 Tage nach Frühlingsanfang', einheit: 'h', afb: 'II', n: 1,
  afbGrund: 'Anwenden im Sachkontext: Zeitpunkt in einen Sinusterm mit Mittellinie einsetzen, Taschenrechner im Bogenmaß.',
  frage: `Die Tageslänge an einem Ort wird beschrieben durch L(t) = 4,3 · sin(0,0172 · t) + 12,2. Dabei ist t die Zeit in Tagen nach Frühlingsanfang und L(t) die Tageslänge in Stunden; das Argument des Sinus ist im Bogenmaß.\n\nWie lang ist der Tag 50 Tage nach Frühlingsanfang? Rechne ohne Zwischenrunden. ${R1}`, r: '4.3*SR(0.0172*50)+12.2',
  weg: 'Argument: 0,0172 · 50 = 0,86 (Bogenmaß).\nsin(0,86) ≈ 0,7578 (Taschenrechner auf RAD).\nL(50) = 4,3 · 0,7578… + 12,2 ≈ {A} h.',
  ke: [['bogenmass_modus', '4.3*S(0.0172*50)+12.2', 'Den Taschenrechner im Gradmaß gelassen: sin(0,86°) ≈ 0,015.', 'Steht dein Taschenrechner auf DEG oder auf RAD?'],
    ['zu_frueh_gerundet', '4.3*0.8+12.2', 'sin(0,86) auf 0,8 gerundet und damit weitergerechnet.', 'Mit wie vielen Stellen hast du den Sinuswert weiterverwendet?']] });
def({ ...PE, ref: 'sinus-periodisch-05', titel: 'Schaukel · b aus der Schwingungsdauer 3 s', afb: 'II', n: 2, pi: true,
  afbGrund: 'Anwenden im Sachkontext, Rückrichtung: aus der Periode den Faktor b = 2π : p bestimmen.',
  frage: `Die Auslenkung einer Schaukel aus der Ruhelage wird beschrieben durch s(t) = 1,2 · sin(b · t). Dabei ist t die Zeit in Sekunden und s(t) die Auslenkung in Metern; das Argument des Sinus ist im Bogenmaß. Eine volle Schwingung dauert 3 s.\n\nBestimme b. ${SATZ_PI} ${R2}`, r: '2*P/3',
  weg: 'Die Schwingungsdauer ist die Periode: p = 3.\nb = 2π : p = 2π : 3 ≈ {A} (π-Taste).\nMit π ≈ 3,14: b = 6,28 : 3 ≈ {B}.',
  ke: [['periode_falsch', '3', 'Die Periode 3 als b genommen.', 'Ist b die Schwingungsdauer oder der Faktor, der sie bestimmt?'],
    ['periode_falsch', '2*P*3', '2π · 3 statt 2π : 3 gerechnet.', 'Schwingt die Schaukel mit größerem b schneller oder langsamer?'],
    ['falsche_groesse_beantwortet', '1.2', 'Die Amplitude 1,2 m als b angegeben.', 'Welche Zahl im Term gibt an, wie weit die Schaukel ausschlägt, und welche, wie schnell?']] });
def({ ...PE, ref: 'sinus-periodisch-06', titel: 'Gezeiten · Modell w(t) = a·sin(b·t) + d aufstellen', afb: 'III',
  afbGrund: 'Problemlösen: Amplitude, Mittellinie und Periode aus Hoch- und Niedrigwasser selbst bestimmen, b aus der Periode.',
  pi: true,
  frage: `An einer Küste beträgt der Wasserstand bei Hochwasser 6,5 m und bei Niedrigwasser 1,5 m. Von einem Hochwasser bis zum nächsten Niedrigwasser vergehen 6,2 Stunden. Der Wasserstand soll durch w(t) = a · sin(b · t) + d beschrieben werden, mit a > 0 und b > 0, t in Stunden, w(t) in Metern, das Argument des Sinus im Bogenmaß. d ist der mittlere Wasserstand.\n\nBestimme a, d und b. Gib a und d exakt an, b auf zwei Stellen nach dem Komma gerundet. ${SATZ_PI}`,
  teile: [{ prompt: 'a in m', r: '(6.5-1.5)/2', n: 'exakt',
    ke: [['amplitude_verwechselt', '6.5-1.5', 'Den ganzen Unterschied zwischen Hoch- und Niedrigwasser als a genommen: 5 m.', 'Wie weit liegt Hochwasser über dem mittleren Wasserstand?']] },
  { prompt: 'd in m', r: '(6.5+1.5)/2', n: 'exakt',
    ke: [['falsche_groesse_beantwortet', '(6.5-1.5)/2', 'Die Amplitude statt des mittleren Wasserstands angegeben: 2,5 m.', 'Welcher Wasserstand liegt genau in der Mitte zwischen 1,5 m und 6,5 m?']] },
  { prompt: 'b', r: '2*P/(2*6.2)', n: 2,
    ke: [['periode_falsch', '2*6.2/(2*P)', 'b = p : 2π statt 2π : p gerechnet: ≈ 1,97.', 'Wird die Kurve mit Periode 12,4 h gegenüber sin t gestreckt oder gestaucht?'],
      ['falsche_groesse_beantwortet', '2*P/6.2', 'Die Zeit von Hoch- bis Niedrigwasser als ganze Periode genommen: ≈ 1,01.', 'Ist nach 6,2 h wieder Hochwasser oder erst Niedrigwasser?']] }],
  weg: 'Amplitude: a = (6,5 − 1,5) : 2 = {1} m.\nMittlerer Wasserstand: d = (6,5 + 1,5) : 2 = {2} m.\nVon Hoch- zu Niedrigwasser ist eine halbe Periode: p = 2 · 6,2 h = 12,4 h.\nb = 2π : 12,4 ≈ {3} (π-Taste; mit π ≈ 3,14 ebenfalls 0,51).' });

baueCharge({
  thema: 'sinus',
  batch: 'k10-sinus',
  source: 'edvance_k10_sinus',
  idsPfad: 'docs/prefill/k10-sinus-ids.json',
  kopf: [
    `K10-Rest, Thema sinus — ${A.length} Aufgaben: je sechs zu fkt_sinus_einheitskreis, _bogenmass, _graph, _parameter und _periodisch.`,
    'Erzeugt von tools/vorlauf-build.mjs aus docs/prefill/k10-sinus.json (Quelle: tools/k10-sinus-charge.mjs) — nicht von Hand editieren.',
    '',
    'Einspiel-Reihenfolge: nach 20261003121329_substrat_k10_trigo.sql und 20261003121331_substrat_k10_sinus.sql (Knoten + Fehlbild-Slugs muessen stehen).',
    'Keine Abbildungen: Der Generator koordinatensystem zeichnet keine Sinuskurve; Graph-Eigenschaften stehen im Text.',
  ],
  auswahl: 'Je Knoten vier reine Anwendung mit steigender Schwierigkeit und zwei mit Sachkontext oder Rückrichtung (zweiter Winkel mit gleichem Sinus, Punkt aus y-Koordinate, Bogen → Winkel, Stelle mit gleichem Funktionswert, a und b aus Amplitude/Periode bzw. Hoch-/Tiefpunkt; Karussell, Riesenrad, Gezeiten, Tageslänge, Schaukel). Koordinaten und Parameter als MULTI_PART (Eingabe nur Zahlen). Bogenmaß als Dezimalzahl (π-Regel, beide Rechenwege richtig) oder als Faktor k in k · π (Bruch erlaubt). Jede Aufgabe nennt die Winkeleinheit und die Rundung; keine Abbildungen; alle Werte exakt nachgerechnet.',
  aufgaben: A,
});
