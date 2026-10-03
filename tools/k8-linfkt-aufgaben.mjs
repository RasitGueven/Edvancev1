/**
 * k8-linfkt-aufgaben.mjs — die 30 Aufgaben des Laufs K8 Lineare Funktionen (W1-1).
 * Gebaut wird die Charge von tools/k8-linfkt-charge.mjs; dort wird jede Zahl nachgerechnet.
 *
 * Felder je Aufgabe:
 *   ref, skill, titel, frage, einheit?, afb, afbGrund, sach (Sachkontext: +30 s),
 *   prozess, antwort (+ auch: weitere gleichwertige Schreibweisen), r (Rechnung zur Antwort),
 *   weg (Lösungsweg), figur? (Generator koordinatensystem),
 *   ke: [falscher Wert, Slug, Rechnung, Fehlertext, sokratische Frage]
 * Rechnungen: Punkt als Dezimaltrenner, "/" fuer Brueche (exakt, prefill-rechnen).
 */

const fig = (m, b, fenster = {}, label = 'f') => ({
  params: { x_min: -5, x_max: 5, y_min: -5, y_max: 5, ...fenster, funktionen: [{ typ: 'linear', m, b, label }] },
  alt_text: `Koordinatensystem mit Gitter, eingezeichnet ist der Graph der linearen Funktion ${label}.`,
});

export const A = [];
const def = (o) => A.push(o);

// ─── fkt_linear_steigung (Tiefe 5) ───────────────────────────────────────────
// Steigerung: ganzzahlig positiv -> negative Differenz -> Bruch -> Sachkontext -> Rueckrichtung.
def({ ref: 'linfkt-steigung-01', skill: 'fkt_linear_steigung', titel: 'Steigung · zwei Punkte · erster Quadrant',
  frage: 'Eine Gerade geht durch die Punkte A(1 | 2) und B(3 | 8).\n\nBerechne die Steigung m der Geraden.',
  afb: 'I', afbGrund: 'Reproduzieren: Steigungsformel mit positiven, ganzzahligen Koordinaten, Ergebnis ganzzahlig.',
  sach: false, prozess: 'Operieren', antwort: '3', r: '(8-2)/(3-1)',
  weg: 'm = (y₂ - y₁) / (x₂ - x₁) = (8 - 2) / (3 - 1) = 6 / 2 = 3.',
  ke: [
    ['1/3', 'steigung_kehrwert', '(3-1)/(8-2)', 'Waagerechte durch senkrechte Änderung geteilt: 2 / 6 = 1/3.', 'Um wie viel geht es nach oben, wenn du einen Schritt nach rechts gehst?'],
    ['-3', 'seiten_verwechselt', '(8-2)/(1-3)', 'Die Differenzen in verschiedener Reihenfolge gebildet: 6 / (-2) = -3.', 'Hast du oben und unten mit demselben Punkt angefangen?'],
  ] });
def({ ref: 'linfkt-steigung-02', skill: 'fkt_linear_steigung', titel: 'Steigung · zwei Punkte · Punkt auf der y-Achse',
  frage: 'Eine Gerade geht durch die Punkte A(0 | 1) und B(2 | 5).\n\nBerechne die Steigung m der Geraden.',
  afb: 'I', afbGrund: 'Reproduzieren: Steigungsformel, ein Punkt auf der y-Achse, kleine ganze Zahlen.',
  sach: false, prozess: 'Operieren', antwort: '2', r: '(5-1)/(2-0)',
  weg: 'm = (5 - 1) / (2 - 0) = 4 / 2 = 2.',
  ke: [
    ['1/2', 'steigung_kehrwert', '(2-0)/(5-1)', 'Waagerechte durch senkrechte Änderung geteilt: 2 / 4 = 1/2.', 'Welche Änderung gehört in den Zähler: die nach oben oder die nach rechts?'],
    ['-2', 'seiten_verwechselt', '(5-1)/(0-2)', 'Die Differenzen in verschiedener Reihenfolge gebildet: 4 / (-2) = -2.', 'Steigt die Gerade von A nach B oder fällt sie? Passt dein Vorzeichen dazu?'],
  ] });
def({ ref: 'linfkt-steigung-03', skill: 'fkt_linear_steigung', titel: 'Steigung · zwei Punkte · fallende Gerade',
  frage: 'Eine Gerade geht durch die Punkte A(-1 | 4) und B(2 | -2).\n\nBerechne die Steigung m der Geraden.',
  afb: 'II', afbGrund: 'Anwenden: Differenzen mit negativen Koordinaten, Minus vor Minus im Nenner.',
  sach: false, prozess: 'Operieren', antwort: '-2', r: '(-2-4)/(2-(-1))',
  weg: 'm = (-2 - 4) / (2 - (-1)) = -6 / 3 = -2.',
  ke: [
    ['-1/2', 'steigung_kehrwert', '(2-(-1))/(-2-4)', 'Waagerechte durch senkrechte Änderung geteilt: 3 / (-6) = -1/2.', 'Wie weit geht es von A nach B nach rechts, wie weit nach unten – und was davon steht im Zähler?'],
    ['2', 'betrag_fehler', '-(-2-4)/(2-(-1))', 'Betrag richtig, das Vorzeichen gekippt: 2 statt -2.', 'Fällt die Gerade von links nach rechts oder steigt sie?'],
  ] });
def({ ref: 'linfkt-steigung-04', skill: 'fkt_linear_steigung', titel: 'Steigung · zwei Punkte · Ergebnis als Bruch',
  frage: 'Eine Gerade geht durch die Punkte A(-2 | -1) und B(4 | 2).\n\nBerechne die Steigung m der Geraden.',
  afb: 'II', afbGrund: 'Anwenden: negative Koordinaten in beiden Punkten, Ergebnis als gekürzter Bruch.',
  sach: false, prozess: 'Operieren', antwort: '1/2', auch: ['0,5'], r: '(2-(-1))/(4-(-2))',
  weg: 'm = (2 - (-1)) / (4 - (-2)) = 3 / 6 = 1/2 = 0,5.',
  ke: [
    ['2', 'steigung_kehrwert', '(4-(-2))/(2-(-1))', 'Waagerechte durch senkrechte Änderung geteilt: 6 / 3 = 2.', 'Geht die Gerade bei einem Schritt nach rechts um mehr oder um weniger als eins nach oben?'],
    ['-1/2', 'seiten_verwechselt', '(2-(-1))/(-2-4)', 'Die Differenzen in verschiedener Reihenfolge gebildet: 3 / (-6) = -1/2.', 'Hast du oben und unten mit demselben Punkt angefangen?'],
  ] });
def({ ref: 'linfkt-steigung-05', skill: 'fkt_linear_steigung', titel: 'Steigung · Sachkontext · Preis je Kilometer',
  frage: 'Eine Taxifahrt kostet bei 4 km Strecke 11 € und bei 10 km Strecke 20 €. Der Preis steigt gleichmäßig mit der Strecke.\n\nWie viel Euro kostet jeder weitere Kilometer?',
  einheit: '€', afb: 'II', afbGrund: 'Anwenden: Sachsituation als zwei Punkte lesen, Steigung als Preis je km deuten (Fkt-6).',
  sach: true, prozess: 'Modellieren', antwort: '1,5', r: '(20-11)/(10-4)',
  weg: 'Punkte (4 | 11) und (10 | 20).\nm = (20 - 11) / (10 - 4) = 9 / 6 = 1,50 € pro km.',
  ke: [
    ['2/3', 'steigung_kehrwert', '(10-4)/(20-11)', 'Kilometer durch Euro geteilt: 6 / 9 = 2/3.', 'Gefragt sind Euro pro Kilometer – was gehört dann in den Zähler?'],
    ['2,75', 'b_ignoriert', '11/4', 'Den Gesamtpreis durch die Strecke geteilt, als gäbe es keinen Grundpreis: 11 / 4 = 2,75.', 'Kostet die Fahrt bei 10 km dann wirklich 20 €?'],
  ] });
def({ ref: 'linfkt-steigung-06', skill: 'fkt_linear_steigung', titel: 'Steigung · Rückrichtung · Punkt aus Steigung',
  frage: 'Eine Gerade hat die Steigung 2 und geht durch den Punkt P(1 | 3).\n\nWelche y-Koordinate hat der Punkt der Geraden mit der x-Koordinate 4?',
  afb: 'II', afbGrund: 'Anwenden in Rückrichtung: aus Steigung und Punkt den Zuwachs über drei Schritte bestimmen.',
  sach: false, prozess: 'Problemlösen', antwort: '9', r: '3+2*(4-1)',
  weg: 'Von x = 1 bis x = 4 sind es 3 Schritte nach rechts.\nJeder Schritt bringt 2 nach oben: 3 + 3 · 2 = 9.',
  ke: [
    ['4,5', 'steigung_kehrwert', '3+(4-1)/2', 'Mit dem Kehrwert der Steigung gerechnet: 3 + 3 · 1/2 = 4,5.', 'Wie viel geht es bei einem Schritt nach rechts nach oben?'],
    ['5', 'nur_einmal_addiert', '3+2', 'Die Steigung nur einmal addiert: 3 + 2 = 5.', 'Wie viele Schritte nach rechts liegen zwischen x = 1 und x = 4?'],
    ['8', 'b_ignoriert', '2*4', 'Wie bei einer Ursprungsgeraden gerechnet: 2 · 4 = 8.', 'Geht die Gerade durch den Ursprung? Prüfe es mit dem Punkt P.'],
  ] });

// ─── fkt_linear_yabschnitt (Tiefe 6) ─────────────────────────────────────────
// Steigerung: ablesen positiv -> negative Steigung -> negatives b -> aus Punkt -> zwei Sachkontexte.
def({ ref: 'linfkt-yabschnitt-01', skill: 'fkt_linear_yabschnitt', titel: 'y-Achsenabschnitt · aus der Gleichung',
  frage: 'Gegeben ist die Funktion f(x) = 3x + 5.\n\nGib den y-Achsenabschnitt des Graphen von f an.',
  afb: 'I', afbGrund: 'Reproduzieren: b direkt aus y = mx + b ablesen, beide Zahlen positiv.',
  sach: false, prozess: 'Operieren', antwort: '5', r: '3*0+5',
  weg: 'In f(x) = mx + b ist b der y-Achsenabschnitt: b = 5 (f(0) = 3 · 0 + 5 = 5).',
  ke: [
    ['3', 'm_b_vertauscht', '3', 'Die Steigung statt des y-Achsenabschnitts angegeben.', 'Welche Zahl steht beim x – und welche steht allein?'],
  ] });
def({ ref: 'linfkt-yabschnitt-02', skill: 'fkt_linear_yabschnitt', titel: 'y-Achsenabschnitt · fallende Gerade',
  frage: 'Gegeben ist die Funktion f(x) = -2x + 7.\n\nGib den y-Achsenabschnitt des Graphen von f an.',
  afb: 'I', afbGrund: 'Reproduzieren: b ablesen, Steigung negativ als Ablenkung.',
  sach: false, prozess: 'Operieren', antwort: '7', r: '-2*0+7',
  weg: 'b ist die Zahl ohne x: b = 7 (f(0) = -2 · 0 + 7 = 7).',
  ke: [
    ['-2', 'm_b_vertauscht', '-2', 'Die Steigung statt des y-Achsenabschnitts angegeben.', 'Welchen Wert hat f, wenn x = 0 ist?'],
    ['3,5', 'achsenabschnitt_verwechselt', '7/2', 'Die Nullstelle statt des y-Achsenabschnitts berechnet: -2x + 7 = 0 ergibt 3,5.', 'Wo schneidet der Graph die senkrechte Achse – bei x = 0 oder bei y = 0?'],
  ] });
def({ ref: 'linfkt-yabschnitt-03', skill: 'fkt_linear_yabschnitt', titel: 'y-Achsenabschnitt · negativer Abschnitt',
  frage: 'Gegeben ist die Funktion f(x) = 4x - 6.\n\nGib den y-Achsenabschnitt des Graphen von f an.',
  afb: 'II', afbGrund: 'Anwenden: b steht als Subtraktion da und muss als negative Zahl gelesen werden.',
  sach: false, prozess: 'Operieren', antwort: '-6', r: '4*0-6',
  weg: 'f(x) = 4x - 6 = 4x + (-6), also b = -6 (f(0) = -6).',
  ke: [
    ['4', 'm_b_vertauscht', '4', 'Die Steigung statt des y-Achsenabschnitts angegeben.', 'Welche Zahl steht beim x – und welche steht allein?'],
    ['6', 'betrag_fehler', '6', 'Betrag richtig, das Minus vor der 6 nicht übernommen.', 'Schneidet der Graph die y-Achse oberhalb oder unterhalb des Ursprungs?'],
    ['1,5', 'achsenabschnitt_verwechselt', '6/4', 'Die Nullstelle statt des y-Achsenabschnitts berechnet: 4x - 6 = 0 ergibt 1,5.', 'Wo schneidet der Graph die senkrechte Achse – bei x = 0 oder bei y = 0?'],
  ] });
def({ ref: 'linfkt-yabschnitt-04', skill: 'fkt_linear_yabschnitt', titel: 'y-Achsenabschnitt · aus Steigung und Punkt',
  frage: 'Eine Gerade hat die Steigung 2 und geht durch den Punkt P(3 | 4).\n\nBestimme den y-Achsenabschnitt b der Geraden.',
  afb: 'II', afbGrund: 'Anwenden: Punkt in y = mx + b einsetzen und nach b auflösen.',
  sach: false, prozess: 'Operieren', antwort: '-2', r: '4-2*3',
  weg: 'P einsetzen: 4 = 2 · 3 + b, also 4 = 6 + b und b = 4 - 6 = -2.',
  ke: [
    ['10', 'addiert_statt_subtrahiert', '4+2*3', 'Beim Auflösen addiert statt subtrahiert: b = 4 + 6 = 10.', 'Was musst du auf beiden Seiten tun, damit die 6 neben dem b verschwindet?'],
    ['2', 'betrag_fehler', '2*3-4', 'Betrag richtig, Vorzeichen gekippt: 6 - 4 = 2.', 'Liegt der Punkt P unter- oder oberhalb der Geraden y = 2x? Was heißt das für b?'],
  ] });
def({ ref: 'linfkt-yabschnitt-05', skill: 'fkt_linear_yabschnitt', titel: 'y-Achsenabschnitt · Sachkontext · Grundpreis',
  frage: 'Bei einem Handytarif setzen sich die monatlichen Kosten aus einem festen Grundpreis und einem Preis pro Minute zusammen. Die Kosten in Euro für x Minuten werden durch K(x) = 0,1x + 8 beschrieben.\n\nWie hoch ist der monatliche Grundpreis in Euro?',
  einheit: '€', afb: 'II', afbGrund: 'Anwenden: Parameter b in der Sachsituation als Grundpreis deuten (Fkt-6).',
  sach: true, prozess: 'Modellieren', antwort: '8', r: '0.1*0+8',
  weg: 'Der Grundpreis fällt auch bei 0 Minuten an: K(0) = 0,1 · 0 + 8 = 8 €.',
  ke: [
    ['0,1', 'groessen_vertauscht', '0.1', 'Den Preis pro Minute statt des Grundpreises angegeben.', 'Was kostet der Monat, wenn man gar nicht telefoniert?'],
    ['-80', 'achsenabschnitt_verwechselt', '-8/0.1', 'Die Nullstelle von K berechnet: 0,1x + 8 = 0 ergibt -80.', 'Welche Bedeutung hat x = 0 in diesem Tarif?'],
  ] });
def({ ref: 'linfkt-yabschnitt-06', skill: 'fkt_linear_yabschnitt', titel: 'y-Achsenabschnitt · Sachkontext · Anfangswert',
  frage: 'Ein Wassertank wird gleichmäßig geleert. Der Wasserstand in cm nach t Minuten wird durch h(t) = -4t + 120 beschrieben.\n\nWie hoch steht das Wasser zu Beginn, also bei t = 0?',
  einheit: 'cm', afb: 'II', afbGrund: 'Anwenden: y-Achsenabschnitt als Anfangswert einer Sachsituation deuten (Fkt-6).',
  sach: true, prozess: 'Modellieren', antwort: '120', r: '-4*0+120',
  weg: 'Zu Beginn ist t = 0: h(0) = -4 · 0 + 120 = 120 cm.',
  ke: [
    ['-4', 'groessen_vertauscht', '-4', 'Die Änderung pro Minute statt des Anfangswerts angegeben.', 'Was beschreibt die -4 – einen Wasserstand oder eine Änderung?'],
    ['30', 'achsenabschnitt_verwechselt', '120/4', 'Den Zeitpunkt berechnet, an dem der Tank leer ist: -4t + 120 = 0 ergibt 30.', 'Gefragt ist ein Wasserstand – passt dazu die Zeit, nach der der Tank leer ist?'],
  ] });

// ─── fkt_linear_graph (Tiefe 7) — Figur ist die Aufgabe ─────────────────────
// Steigerung: b ablesen -> m ganzzahlig -> m als Bruch -> Funktionswert -> Rueckrichtung -> Sachgraph.
def({ ref: 'linfkt-graph-01', skill: 'fkt_linear_graph', titel: 'Graph · y-Achsenabschnitt ablesen',
  frage: 'Die Abbildung zeigt den Graphen einer linearen Funktion f.\n\nLies den y-Achsenabschnitt des Graphen ab.',
  afb: 'I', afbGrund: 'Reproduzieren: Schnittpunkt mit der y-Achse auf einem Gitterpunkt ablesen.',
  sach: false, prozess: 'Operieren', antwort: '1', r: '2*0+1', figur: fig(2, 1),
  weg: 'Der Graph schneidet die y-Achse im Punkt (0 | 1), also b = 1.',
  ke: [
    ['-0,5', 'achsenabschnitt_verwechselt', '-1/2', 'Den Schnittpunkt mit der x-Achse statt mit der y-Achse abgelesen.', 'Welche der beiden Achsen ist die senkrechte?'],
    ['2', 'm_b_vertauscht', '(3-1)/1', 'Die Steigung statt des y-Achsenabschnitts abgelesen.', 'Gefragt ist ein Punkt auf einer Achse – oder eine Änderung?'],
  ] });
def({ ref: 'linfkt-graph-02', skill: 'fkt_linear_graph', titel: 'Graph · Steigung ablesen · fallend',
  frage: 'Die Abbildung zeigt den Graphen einer linearen Funktion f.\n\nLies die Steigung m des Graphen ab.',
  afb: 'I', afbGrund: 'Reproduzieren: Steigungsdreieck mit einem Schritt nach rechts, Steigung ganzzahlig.',
  sach: false, prozess: 'Operieren', antwort: '-1', r: '(1-2)/(1-0)', figur: fig(-1, 2),
  weg: 'Von (0 | 2) einen Schritt nach rechts geht der Graph einen Schritt nach unten, also m = -1.',
  ke: [
    ['1', 'betrag_fehler', '1', 'Betrag richtig, die Richtung übersehen: der Graph fällt.', 'Geht der Graph von links nach rechts nach oben oder nach unten?'],
    ['2', 'm_b_vertauscht', '2', 'Den y-Achsenabschnitt statt der Steigung abgelesen.', 'Gefragt ist eine Änderung – oder ein Punkt auf der y-Achse?'],
  ] });
def({ ref: 'linfkt-graph-03', skill: 'fkt_linear_graph', titel: 'Graph · Steigung ablesen · Bruch',
  frage: 'Die Abbildung zeigt den Graphen einer linearen Funktion g.\n\nLies die Steigung m des Graphen von g ab.',
  afb: 'II', afbGrund: 'Anwenden: Steigungsdreieck über zwei Kästchen nach rechts, Steigung als Bruch.',
  sach: false, prozess: 'Operieren', antwort: '1/2', auch: ['0,5'], r: '(0-(-1))/(2-0)', figur: fig(0.5, -1, {}, 'g'),
  weg: 'Von (0 | -1) zwei Schritte nach rechts und einen nach oben bis (2 | 0): m = 1/2 = 0,5.',
  ke: [
    ['2', 'steigung_kehrwert', '(2-0)/(0-(-1))', 'Zwei nach rechts durch eins nach oben geteilt: 2 statt 1/2.', 'Ist der Graph steiler oder flacher als eine Gerade, die bei jedem Schritt nach rechts einen nach oben geht?'],
    ['-1', 'm_b_vertauscht', '-1', 'Den y-Achsenabschnitt statt der Steigung abgelesen.', 'Gefragt ist eine Änderung – oder ein Punkt auf der y-Achse?'],
  ] });
def({ ref: 'linfkt-graph-04', skill: 'fkt_linear_graph', titel: 'Graph · Funktionswert ablesen',
  frage: 'Die Abbildung zeigt den Graphen einer linearen Funktion f.\n\nWelchen y-Wert hat der Graph an der Stelle x = 2?',
  afb: 'II', afbGrund: 'Anwenden: Funktionswert im vierten Quadranten ablesen, Ergebnis negativ.',
  sach: false, prozess: 'Operieren', antwort: '-1', r: '-2*2+3', figur: fig(-2, 3),
  weg: 'Bei x = 2 senkrecht zum Graphen: der Punkt liegt bei (2 | -1), also f(2) = -1.',
  ke: [
    ['0,5', 'koordinaten_vertauscht', '(3-2)/2', 'Die Stelle gesucht, an der der y-Wert 2 ist: x = 0,5.', 'Ist 2 hier ein x-Wert oder ein y-Wert?'],
    ['1', 'koordinate_vorzeichen_verloren', '1', 'Den Abstand zur x-Achse richtig abgelesen, das Minus fehlt.', 'Liegt der Punkt über oder unter der x-Achse?'],
  ] });
def({ ref: 'linfkt-graph-05', skill: 'fkt_linear_graph', titel: 'Graph · Rückrichtung · Stelle zu einem y-Wert',
  frage: 'Die Abbildung zeigt den Graphen einer linearen Funktion f.\n\nAn welcher Stelle x hat der Graph den y-Wert 1?',
  afb: 'II', afbGrund: 'Anwenden in Rückrichtung: vom y-Wert waagerecht zum Graphen, dann die Stelle ablesen.',
  sach: false, prozess: 'Problemlösen', antwort: '2', r: '(1-(-2))/1.5', figur: fig(1.5, -2),
  weg: 'Waagerecht bei y = 1 zum Graphen: der Punkt liegt bei (2 | 1), also x = 2.',
  ke: [
    ['-0,5', 'koordinaten_vertauscht', '1.5*1-2', 'Den y-Wert an der Stelle x = 1 abgelesen statt die Stelle zum y-Wert 1.', 'Ist 1 hier ein x-Wert oder ein y-Wert?'],
    ['1', 'falsche_groesse_beantwortet', '1', 'Den gegebenen y-Wert als Antwort wiederholt.', 'Gesucht ist ein x-Wert – auf welcher Achse liest du ihn ab?'],
  ] });
def({ ref: 'linfkt-graph-06', skill: 'fkt_linear_graph', titel: 'Graph · Sachkontext · Leihgebühr pro Stunde',
  frage: 'Der Graph zeigt die Kosten y in Euro für das Ausleihen eines Fahrrads in Abhängigkeit von der Leihdauer x in Stunden.\n\nWie viel Euro kostet jede weitere Stunde?',
  einheit: '€', afb: 'II', afbGrund: 'Anwenden: Steigung am Graphen ablesen und als Preis pro Stunde deuten (Fkt-6).',
  sach: true, prozess: 'Modellieren', antwort: '2', r: '(5-3)/(1-0)', figur: fig(2, 3, { x_min: 0, x_max: 5, y_min: 0, y_max: 13 }),
  weg: 'Der Graph beginnt bei (0 | 3) und steigt pro Stunde um 2: (1 | 5), (2 | 7), …\nJede weitere Stunde kostet 2 €.',
  ke: [
    ['3', 'groessen_vertauscht', '3', 'Den Grundpreis statt des Preises pro Stunde abgelesen.', 'Was kostet die Ausleihe für 0 Stunden – und was kommt pro Stunde dazu?'],
    ['1/2', 'steigung_kehrwert', '1/2', 'Stunden durch Euro geteilt: 1 / 2.', 'Gefragt sind Euro pro Stunde – was gehört in den Zähler?'],
  ] });

// ─── fkt_linear_gleichung (Tiefe 7) — Gleichung aufstellen, Wert ausrechnen ──
def({ ref: 'linfkt-gleichung-01', skill: 'fkt_linear_gleichung', titel: 'Funktionsgleichung · aus m und b · Funktionswert',
  frage: 'Eine lineare Funktion f hat die Steigung 3 und den y-Achsenabschnitt -2.\n\nStelle die Funktionsgleichung auf und berechne damit f(4).',
  afb: 'I', afbGrund: 'Reproduzieren: m und b in y = mx + b einsetzen, dann einen Wert berechnen.',
  sach: false, prozess: 'Operieren', antwort: '10', r: '3*4-2',
  weg: 'f(x) = 3x - 2.\nf(4) = 3 · 4 - 2 = 12 - 2 = 10.',
  ke: [
    ['-5', 'm_b_vertauscht', '-2*4+3', 'Steigung und Achsenabschnitt vertauscht: f(x) = -2x + 3, f(4) = -5.', 'Welche der beiden Zahlen gehört zum x?'],
    ['14', 'vorzeichen_ignoriert', '3*4+2', 'Das Minus vor der 2 weggelassen: 3 · 4 + 2 = 14.', 'Liegt der Schnittpunkt mit der y-Achse über oder unter null?'],
  ] });
def({ ref: 'linfkt-gleichung-02', skill: 'fkt_linear_gleichung', titel: 'Funktionsgleichung · fallend · Funktionswert',
  frage: 'Eine lineare Funktion f hat die Steigung -2 und schneidet die y-Achse bei y = 5.\n\nStelle die Funktionsgleichung auf und berechne damit f(3).',
  afb: 'I', afbGrund: 'Reproduzieren: Gleichung aus m und b, Einsetzen mit negativem Faktor.',
  sach: false, prozess: 'Operieren', antwort: '-1', r: '-2*3+5',
  weg: 'f(x) = -2x + 5.\nf(3) = -2 · 3 + 5 = -6 + 5 = -1.',
  ke: [
    ['13', 'm_b_vertauscht', '5*3-2', 'Steigung und Achsenabschnitt vertauscht: f(x) = 5x - 2, f(3) = 13.', 'Welche der beiden Zahlen gehört zum x?'],
    ['1', 'betrag_fehler', '-(-2*3+5)', 'Betrag richtig, Vorzeichen gekippt: 1 statt -1.', 'Ist -6 + 5 größer oder kleiner als null?'],
  ] });
def({ ref: 'linfkt-gleichung-03', skill: 'fkt_linear_gleichung', titel: 'Funktionsgleichung · aus zwei Punkten · Funktionswert',
  frage: 'Eine Gerade geht durch die Punkte A(0 | 4) und B(2 | 10).\n\nBestimme die Funktionsgleichung und berechne damit f(5).',
  afb: 'II', afbGrund: 'Anwenden: m aus zwei Punkten, b aus dem Punkt auf der y-Achse, dann einsetzen.',
  sach: false, prozess: 'Operieren', antwort: '19', r: '(10-4)/(2-0)*5+4',
  weg: 'm = (10 - 4) / (2 - 0) = 3, b = 4 (A liegt auf der y-Achse).\nf(x) = 3x + 4, f(5) = 15 + 4 = 19.',
  ke: [
    ['23', 'm_b_vertauscht', '4*5+3', 'Steigung und Achsenabschnitt vertauscht: f(x) = 4x + 3, f(5) = 23.', 'Welche Zahl hast du als Änderung pro Schritt berechnet, welche abgelesen?'],
    ['-11', 'seiten_verwechselt', '(10-4)/(0-2)*5+4', 'Die Differenzen in verschiedener Reihenfolge gebildet: m = -3, f(5) = -11.', 'Steigt die Gerade von A nach B oder fällt sie?'],
  ] });
def({ ref: 'linfkt-gleichung-04', skill: 'fkt_linear_gleichung', titel: 'Funktionsgleichung · aus zwei Punkten · Achsenabschnitt',
  frage: 'Eine Gerade geht durch die Punkte A(1 | 1) und B(3 | 7). Ihre Funktionsgleichung hat die Form y = mx + b.\n\nWelchen Wert hat b?',
  afb: 'II', afbGrund: 'Anwenden: erst m aus zwei Punkten, dann b durch Einsetzen; kein Punkt auf der y-Achse.',
  sach: false, prozess: 'Operieren', antwort: '-2', r: '1-(7-1)/(3-1)*1',
  weg: 'm = (7 - 1) / (3 - 1) = 3.\nA einsetzen: 1 = 3 · 1 + b, also b = 1 - 3 = -2.',
  ke: [
    ['4', 'addiert_statt_subtrahiert', '1+3', 'Beim Auflösen nach b addiert statt subtrahiert: 1 + 3 = 4.', 'Was musst du auf beiden Seiten tun, damit die 3 neben dem b verschwindet?'],
    ['2/3', 'steigung_kehrwert', '1-(3-1)/(7-1)', 'Mit dem Kehrwert der Steigung gerechnet: m = 1/3, b = 2/3.', 'Um wie viel geht es nach oben, wenn du einen Schritt nach rechts gehst?'],
  ] });
def({ ref: 'linfkt-gleichung-05', skill: 'fkt_linear_gleichung', titel: 'Funktionsgleichung · Sachkontext · Carsharing',
  frage: 'Ein Carsharing-Tarif kostet 5 € Grundgebühr pro Fahrt und zusätzlich 0,30 € pro gefahrenem Kilometer.\n\nStelle eine Funktionsgleichung für die Kosten auf und berechne die Kosten in Euro für eine Fahrt von 20 km.',
  einheit: '€', afb: 'II', afbGrund: 'Anwenden: Grundgebühr und Preis pro km als b und m deuten, Gleichung aufstellen und auswerten (Fkt-6).',
  sach: true, prozess: 'Modellieren', antwort: '11', r: '0.3*20+5',
  weg: 'K(x) = 0,3x + 5 (x in km, K in €).\nK(20) = 0,3 · 20 + 5 = 6 + 5 = 11 €.',
  ke: [
    ['100,3', 'groessen_vertauscht', '5*20+0.3', 'Grundgebühr und Kilometerpreis vertauscht: 5 · 20 + 0,30 = 100,30.', 'Welcher Betrag fällt bei jedem Kilometer an, welcher nur einmal?'],
    ['6', 'b_ignoriert', '0.3*20', 'Nur die Kilometerkosten berechnet, die Grundgebühr fehlt.', 'Was kostet die Fahrt, wenn man null Kilometer fährt?'],
  ] });
def({ ref: 'linfkt-gleichung-06', skill: 'fkt_linear_gleichung', titel: 'Funktionsgleichung · Sachkontext · Kerze',
  frage: 'Eine Kerze ist 24 cm lang. Sie brennt gleichmäßig ab und wird dabei pro Stunde 1,5 cm kürzer.\n\nStelle eine Funktionsgleichung für die Länge der Kerze nach x Stunden auf. Wie lang ist die Kerze nach 6 Stunden noch?',
  einheit: 'cm', afb: 'II', afbGrund: 'Anwenden: fallende Größe als negative Steigung modellieren, dann auswerten (Fkt-6).',
  sach: true, prozess: 'Modellieren', antwort: '15', r: '-1.5*6+24',
  weg: 'L(x) = -1,5x + 24 (x in Stunden, L in cm).\nL(6) = -1,5 · 6 + 24 = -9 + 24 = 15 cm.',
  ke: [
    ['33', 'vorzeichen_ignoriert', '1.5*6+24', 'Mit positiver Steigung gerechnet, als würde die Kerze wachsen: 9 + 24 = 33.', 'Wird die Kerze länger oder kürzer? Welches Vorzeichen hat dann die Steigung?'],
    ['9', 'falsche_groesse_beantwortet', '1.5*6', 'Die abgebrannte Länge statt der Restlänge angegeben.', 'Gefragt ist, wie lang die Kerze noch ist – ist das der abgebrannte Teil?'],
  ] });

// ─── fkt_linear_nullstelle (Tiefe 8) ─────────────────────────────────────────
// Steigerung: ganzzahlig -> negative Nullstelle -> negatives m -> Dezimal-m -> Sachkontext -> Rueckrichtung.
def({ ref: 'linfkt-nullstelle-01', skill: 'fkt_linear_nullstelle', titel: 'Nullstelle · positive Steigung',
  frage: 'Gegeben ist die Funktion f(x) = 2x - 8.\n\nBerechne die Nullstelle von f.',
  afb: 'I', afbGrund: 'Reproduzieren: f(x) = 0 setzen, zwei Umformungsschritte, Ergebnis ganzzahlig.',
  sach: false, prozess: 'Operieren', antwort: '4', r: '8/2',
  weg: '2x - 8 = 0 | + 8\n2x = 8 | : 2\nx = 4.',
  ke: [
    ['-4', 'betrag_fehler', '-8/2', 'Betrag richtig, Vorzeichen gekippt: b / m statt -b / m.', 'Setze dein Ergebnis in f ein – kommt 0 heraus?'],
    ['8', 'division_vergessen', '8', 'Nach dem ersten Schritt aufgehört: 2x = 8, aber nicht durch 2 geteilt.', 'Steht nach deinem letzten Schritt wirklich x allein da?'],
  ] });
def({ ref: 'linfkt-nullstelle-02', skill: 'fkt_linear_nullstelle', titel: 'Nullstelle · negative Nullstelle',
  frage: 'Gegeben ist die Funktion f(x) = 3x + 6.\n\nBerechne die Nullstelle von f.',
  afb: 'I', afbGrund: 'Reproduzieren: f(x) = 0 setzen und auflösen, Ergebnis negativ und ganzzahlig.',
  sach: false, prozess: 'Operieren', antwort: '-2', r: '-6/3',
  weg: '3x + 6 = 0 | - 6\n3x = -6 | : 3\nx = -2.',
  ke: [
    ['2', 'betrag_fehler', '6/3', 'Betrag richtig, Vorzeichen gekippt: b / m statt -b / m.', 'Setze dein Ergebnis in f ein – kommt 0 heraus?'],
    ['-6', 'division_vergessen', '-6', 'Nach dem ersten Schritt aufgehört: 3x = -6, aber nicht durch 3 geteilt.', 'Steht nach deinem letzten Schritt wirklich x allein da?'],
    ['6', 'achsenabschnitt_verwechselt', '3*0+6', 'Den y-Achsenabschnitt statt der Nullstelle angegeben.', 'An welcher Achse liegt die Nullstelle?'],
  ] });
def({ ref: 'linfkt-nullstelle-03', skill: 'fkt_linear_nullstelle', titel: 'Nullstelle · negative Steigung',
  frage: 'Gegeben ist die Funktion f(x) = -4x + 10.\n\nBerechne die Nullstelle von f.',
  afb: 'II', afbGrund: 'Anwenden: Division durch einen negativen Koeffizienten, Ergebnis als Dezimalzahl.',
  sach: false, prozess: 'Operieren', antwort: '2,5', auch: ['5/2'], r: '-10/(-4)',
  weg: '-4x + 10 = 0 | - 10\n-4x = -10 | : (-4)\nx = 2,5.',
  ke: [
    ['-2,5', 'vorzeichen_beim_umstellen', '-10/4', 'Betrag richtig, das Minus des Koeffizienten bleibt am Ergebnis hängen.', 'Was kommt heraus, wenn du eine negative Zahl durch eine negative Zahl teilst?'],
    ['10', 'achsenabschnitt_verwechselt', '-4*0+10', 'Den y-Achsenabschnitt statt der Nullstelle angegeben.', 'An welcher Achse liegt die Nullstelle?'],
  ] });
def({ ref: 'linfkt-nullstelle-04', skill: 'fkt_linear_nullstelle', titel: 'Nullstelle · Steigung als Dezimalzahl',
  frage: 'Gegeben ist die Funktion f(x) = 0,5x + 3.\n\nBerechne die Nullstelle von f.',
  afb: 'II', afbGrund: 'Anwenden: Division durch eine Dezimalzahl kleiner als eins, das Ergebnis wird betragsmäßig größer.',
  sach: false, prozess: 'Operieren', antwort: '-6', r: '-3/0.5',
  weg: '0,5x + 3 = 0 | - 3\n0,5x = -3 | : 0,5\nx = -6.',
  ke: [
    ['6', 'betrag_fehler', '3/0.5', 'Betrag richtig, Vorzeichen gekippt: b / m statt -b / m.', 'Setze dein Ergebnis in f ein – kommt 0 heraus?'],
    ['-1,5', 'falsche_gegenoperation', '-3*0.5', 'Mit 0,5 multipliziert statt durch 0,5 geteilt.', 'Wie oft passt 0,5 in 3?'],
  ] });
def({ ref: 'linfkt-nullstelle-05', skill: 'fkt_linear_nullstelle', titel: 'Nullstelle · Sachkontext · Akku leer',
  frage: 'Der Ladestand eines Akkus in Prozent nach t Stunden wird durch L(t) = -16t + 80 beschrieben.\n\nNach wie vielen Stunden ist der Akku leer?',
  einheit: 'h', afb: 'II', afbGrund: 'Anwenden: die Frage „leer" als Nullstelle erkennen und im Sachkontext deuten (Fkt-6/7).',
  sach: true, prozess: 'Modellieren', antwort: '5', r: '-80/(-16)',
  weg: 'Leer heißt L(t) = 0:\n-16t + 80 = 0 | - 80\n-16t = -80 | : (-16)\nt = 5 Stunden.',
  ke: [
    ['80', 'achsenabschnitt_verwechselt', '-16*0+80', 'Den Anfangswert statt der Nullstelle angegeben.', 'Beschreibt 80 den Ladestand am Anfang oder am Ende?'],
    ['-5', 'vorzeichen_beim_umstellen', '-80/16', 'Betrag richtig, das Minus des Koeffizienten bleibt am Ergebnis hängen.', 'Kann eine Zeitdauer negativ sein?'],
  ] });
def({ ref: 'linfkt-nullstelle-06', skill: 'fkt_linear_nullstelle', titel: 'Nullstelle · Rückrichtung · Achsenabschnitt aus Nullstelle',
  frage: 'Eine Gerade hat die Steigung 3 und die Nullstelle x = 2.\n\nBestimme den y-Achsenabschnitt b der Geraden.',
  afb: 'III', afbGrund: 'Verallgemeinern/Rückrichtung: die Bedingung f(2) = 0 selbst aufstellen und nach dem Parameter b auflösen.',
  sach: false, prozess: 'Problemlösen', antwort: '-6', r: '0-3*2',
  weg: 'Die Nullstelle liegt auf der Geraden: f(2) = 0.\n3 · 2 + b = 0, also b = -6.',
  ke: [
    ['6', 'betrag_fehler', '3*2', 'Betrag richtig, Vorzeichen gekippt: b = 6 statt -6.', 'Setze x = 2 in f(x) = 3x + b mit deinem b ein – kommt 0 heraus?'],
    ['2', 'achsenabschnitt_verwechselt', '2', 'Die Nullstelle als y-Achsenabschnitt übernommen.', 'An welcher Achse liegt die Nullstelle, an welcher der y-Achsenabschnitt?'],
  ] });
