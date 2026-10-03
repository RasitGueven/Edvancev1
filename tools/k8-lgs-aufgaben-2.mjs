/**
 * k8-lgs-aufgaben-2.mjs — Aufgaben des Laufs K8-Rest, Thema LGS, Teil 2: grafisch (Schnittpunkt,
 * Lösungsanzahl) und Sachaufgaben (je sechs). Felder wie in tools/k8-lgs-aufgaben.mjs, dazu:
 *   figur: Generator koordinatensystem mit zwei Geraden f und g (m, b); die Charge leitet das
 *          System daraus ab und prueft, dass gl genau diese Geraden beschreibt,
 *   typ 'sach3': Teil 1 MC „Welches Gleichungssystem passt?“ (options mit Gleichungen, ASCII-Minus,
 *          getrennt durch „;“), Teil 2 = x, Teil 3 = y.
 */

export const A = [];
const def = (o) => A.push({ typ: 'xy', teile: ['x =', 'y ='], einheit: {}, inFrage: false, ...o });
const fig = (f, g, fenster = {}) => ({
  generator: 'koordinatensystem',
  params: { x_min: -5, x_max: 5, y_min: -5, y_max: 5, ...fenster,
    funktionen: [{ typ: 'linear', m: f[0], b: f[1], label: 'f' }, { typ: 'linear', m: g[0], b: g[1], label: 'g' }] },
  alt_text: 'Koordinatensystem mit Gitter, eingezeichnet sind die Geraden f und g.',
});
const PASST = 'Welches Gleichungssystem passt zu der Situation?';

// ─── gleichung_lgs_grafisch (Tiefe 8) ────────────────────────────────────────
// Steigerung: Schnittpunkt im ersten Quadranten -> naeher am Rand -> dritter Quadrant
// -> Loesungsanzahl aus den Gleichungen (MC) -> Sachkontext Tarife -> parallele Geraden deuten (MC).
def({ ref: 'lgs-grafisch-01', skill: 'gleichung_lgs_grafisch', titel: 'LGS grafisch · Schnittpunkt ablesen',
  gl: ['y = x + 1', 'y = -0,5x + 4'], figur: fig([1, 1], [-0.5, 4]),
  frage: 'Die Geraden f und g im Koordinatensystem gehören zu den beiden Gleichungen eines linearen Gleichungssystems.\n\nLies die Lösung des Gleichungssystems am Schnittpunkt der Geraden ab.',
  afb: 'I', afbGrund: 'Reproduzieren: Schnittpunkt im ersten Quadranten auf einem Gitterpunkt ablesen.',
  sach: false, prozess: 'Darstellen', x: '2', y: '3',
  weg: 'Die Geraden schneiden sich im Punkt S(2 | 3).\nDie Koordinaten des Schnittpunkts sind die Lösung: x = 2, y = 3.',
  ke: [
    { slug: 'koordinaten_vertauscht', x: ['3', '3'], y: ['2', '2'],
      error: 'x- und y-Koordinate des Schnittpunkts vertauscht: (3 | 2) statt (2 | 3).', frage: 'Welche Koordinate liest du an der waagerechten Achse ab?' },
  ] });
def({ ref: 'lgs-grafisch-02', skill: 'gleichung_lgs_grafisch', titel: 'LGS grafisch · flache Gerade',
  gl: ['y = 0,5x - 1', 'y = -x + 5'], figur: fig([0.5, -1], [-1, 5], { x_min: -2, x_max: 7, y_min: -3, y_max: 6 }),
  frage: 'Im Koordinatensystem sind die Graphen der Funktionen f und g gezeichnet. Sie stellen ein lineares Gleichungssystem dar.\n\nBestimme die Lösung des Gleichungssystems mithilfe der Zeichnung.',
  afb: 'I', afbGrund: 'Reproduzieren: Schnittpunkt im ersten Quadranten ablesen, eine Gerade mit gebrochener Steigung.',
  sach: false, prozess: 'Darstellen', x: '4', y: '1',
  weg: 'Die Geraden schneiden sich im Punkt S(4 | 1).\nLösung: x = 4, y = 1.',
  ke: [
    { slug: 'koordinaten_vertauscht', x: ['1', '1'], y: ['4', '4'],
      error: 'x- und y-Koordinate des Schnittpunkts vertauscht: (1 | 4) statt (4 | 1).', frage: 'Wie weit liegt der Schnittpunkt rechts von der y-Achse, wie weit über der x-Achse?' },
  ] });
def({ ref: 'lgs-grafisch-03', skill: 'gleichung_lgs_grafisch', titel: 'LGS grafisch · Schnittpunkt im dritten Quadranten',
  gl: ['y = x + 1', 'y = -0,5x - 2'], figur: fig([1, 1], [-0.5, -2]),
  frage: 'Die Geraden f und g gehören zu einem linearen Gleichungssystem.\n\nGib die Lösung des Gleichungssystems an. Lies dazu den Schnittpunkt der beiden Geraden ab.',
  afb: 'II', afbGrund: 'Anwenden: Schnittpunkt mit zwei negativen Koordinaten ablesen.',
  sach: false, prozess: 'Darstellen', x: '-2', y: '-1',
  weg: 'Die Geraden schneiden sich im Punkt S(-2 | -1), links unterhalb des Ursprungs.\nLösung: x = -2, y = -1.',
  ke: [
    { slug: 'koordinaten_vertauscht', x: ['-1', '-1'], y: ['-2', '-2'],
      error: 'x- und y-Koordinate des Schnittpunkts vertauscht: (-1 | -2) statt (-2 | -1).', frage: 'Welche Koordinate gehört zur waagerechten Achse?' },
    { slug: 'koordinate_vorzeichen_verloren', x: ['2', '2'], y: ['1', '1'],
      error: 'Die Beträge richtig abgelesen, die Minuszeichen fehlen: (2 | 1).', frage: 'Liegt der Schnittpunkt rechts oder links von der y-Achse?' },
  ] });
def({ ref: 'lgs-grafisch-04', skill: 'gleichung_lgs_grafisch', typ: 'mc', titel: 'LGS · Lösungsanzahl · Geraden aufeinander',
  gl: ['y = 0,5x + 1', '2y = x + 2'], inFrage: true,
  frage: 'Gegeben ist das Gleichungssystem\nI: y = 0,5x + 1\nII: 2y = x + 2\n\nWie viele Lösungen hat es? Denke an die Lage der beiden zugehörigen Geraden.',
  afb: 'II', afbGrund: 'Anwenden: II in die Form y = mx + b bringen, Steigung und y-Achsenabschnitt vergleichen.',
  sach: false, prozess: 'Argumentieren', richtig: 'c',
  weg: 'II durch 2 teilen: y = 0,5x + 1.\nBeide Gleichungen haben dieselbe Steigung 0,5 und denselben y-Achsenabschnitt 1.\nDie Geraden liegen aufeinander, jeder Punkt der Geraden ist eine Lösung: unendlich viele Lösungen.',
  ke: [
    { slug: 'parallele_uebersehen', mc: 'a',
      error: 'Einen Schnittpunkt angenommen, ohne die Gleichungen in die Form y = mx + b zu bringen und zu vergleichen.', frage: 'Was erhältst du, wenn du II durch 2 teilst?' },
    { slug: 'loesungsanzahl_verwechselt', mc: 'b',
      error: 'Gleiche Steigung als „keine Lösung“ gelesen, obwohl auch der y-Achsenabschnitt gleich ist.', frage: 'Haben die beiden Geraden einen gemeinsamen Punkt, zum Beispiel auf der y-Achse?' },
  ] });
def({ ref: 'lgs-grafisch-05', skill: 'gleichung_lgs_grafisch', titel: 'LGS grafisch · Sachkontext · zwei Tarife',
  gl: ['y = x + 2', 'y = 0,5x + 4'], figur: fig([1, 2], [0.5, 4], { x_min: -1, x_max: 8, y_min: -1, y_max: 9 }),
  frage: 'Ein Kanuverleih bietet zwei Tarife an. Im Koordinatensystem gibt x die Leihdauer in Stunden an und y die Kosten in €. Die Gerade f gehört zu Tarif A, die Gerade g zu Tarif B.\n\nLies ab: Bei welcher Leihdauer kosten beide Tarife gleich viel, und wie viel kostet es dann?',
  teile: ['Leihdauer in Stunden: x =', 'Kosten in €: y ='], einheit: { y: '€' },
  afb: 'II', afbGrund: 'Anwenden: Schnittpunkt im Sachkontext ablesen und beide Koordinaten deuten.',
  sach: true, prozess: 'Modellieren', x: '4', y: '6',
  weg: 'Die Geraden schneiden sich im Punkt S(4 | 6).\nNach 4 Stunden kosten beide Tarife 6 €.',
  ke: [
    { slug: 'koordinaten_vertauscht', x: ['6', '6'], y: ['4', '4'],
      error: 'Leihdauer und Kosten vertauscht: (6 | 4) statt (4 | 6).', frage: 'An welcher Achse stehen die Stunden, an welcher die Euro?' },
  ] });
def({ ref: 'lgs-grafisch-06', skill: 'gleichung_lgs_grafisch', typ: 'mc', titel: 'LGS grafisch · parallele Geraden deuten',
  gl: ['y = 0,5x + 2', 'y = 0,5x - 1'], figur: fig([0.5, 2], [0.5, -1]),
  frage: 'Die Geraden f und g im Koordinatensystem gehören zu den beiden Gleichungen eines linearen Gleichungssystems.\n\nWie viele Lösungen hat das Gleichungssystem?',
  afb: 'II', afbGrund: 'Anwenden und deuten: aus der Lage der Geraden (parallel) auf die Lösungsanzahl schließen.',
  sach: false, prozess: 'Argumentieren', richtig: 'b',
  weg: 'Die Geraden f und g sind parallel: Sie haben dieselbe Steigung, aber verschiedene y-Achsenabschnitte.\nParallele Geraden schneiden sich nie. Das Gleichungssystem hat keine Lösung.',
  ke: [
    { slug: 'parallele_uebersehen', mc: 'a',
      error: 'Einen Schnittpunkt außerhalb des Bildes angenommen, obwohl die Geraden parallel sind.', frage: 'Kommen sich f und g näher, wenn du weiter nach rechts oder links schaust?' },
    { slug: 'loesungsanzahl_verwechselt', mc: 'c',
      error: 'Parallele Geraden als „unendlich viele Lösungen“ gelesen.', frage: 'Gibt es einen Punkt, der auf beiden Geraden liegt?' },
  ] });

// ─── gleichung_lgs_sachaufgabe (Tiefe 9) ─────────────────────────────────────
// Alle sechs mit Sachkontext, steigend: System auswaehlen + loesen (vier, AFB II), dann selbst
// aufstellen und loesen (zwei, AFB III).
const sach3 = (o) => def({ typ: 'sach3', mcPrompt: PASST, ...o });
sach3({ ref: 'lgs-sach-01', skill: 'gleichung_lgs_sachaufgabe', titel: 'LGS Sachaufgabe · Eintrittskarten · System wählen',
  gl: ['x + y = 120', '3x + 5y = 460'],
  frage: 'Ein Schwimmbad verkauft an einem Tag 120 Eintrittskarten. Eine Kinderkarte kostet 3 €, eine Erwachsenenkarte 5 €. Zusammen nimmt das Schwimmbad 460 € ein.\n\nx ist die Anzahl der Kinderkarten, y die Anzahl der Erwachsenenkarten.',
  options: [
    { id: 'a', label: 'I: x + y = 120; II: 5x + 3y = 460' },
    { id: 'b', label: 'I: x + y = 120; II: 3x + 5y = 460' },
    { id: 'c', label: 'I: x + y = 460; II: 3x + 5y = 120' },
  ], richtig: 'b',
  teile: ['Wie viele Kinderkarten wurden verkauft? x =', 'Wie viele Erwachsenenkarten wurden verkauft? y ='],
  afb: 'II', afbGrund: 'Anwenden: passendes System zu Anzahl und Einnahmen erkennen, dann mit Einsetzen lösen.',
  sach: true, prozess: 'Modellieren', x: '70', y: '50',
  weg: 'Anzahl: x + y = 120, Einnahmen: 3x + 5y = 460, also System b.\nI nach y: y = 120 - x\nIn II: 3x + 5·(120 - x) = 460\n3x + 600 - 5x = 460\n-2x = -140 | :(-2)\nx = 70\ny = 120 - 70 = 50\nEs wurden 70 Kinderkarten und 50 Erwachsenenkarten verkauft.',
  ke: [
    { slug: 'groessen_vertauscht', mc: 'a', x: ['50', '(460-3*120)/(5-3)'], y: ['70', '120-50'],
      error: 'Die Preise vertauscht: 5x + 3y = 460 statt 3x + 5y = 460.', frage: 'Was kostet eine Kinderkarte, und welche Variable zählt die Kinderkarten?' },
    { slug: 'groessen_vertauscht', mc: 'c',
      error: 'Anzahl und Einnahmen vertauscht: x + y = 460.', frage: 'Was zählt x + y: Karten oder Euro?' },
    { slug: 'vorzeichen_beim_umstellen', x: ['-70', '-(-140/(-2))'], y: ['190', '120-(-70)'],
      error: 'Bei -2x = -140 das Minus am Ergebnis gelassen: x = -70.', frage: 'Kann eine Anzahl von Karten negativ sein? Was ergibt -140 : (-2)?' },
  ] });
sach3({ ref: 'lgs-sach-02', skill: 'gleichung_lgs_sachaufgabe', titel: 'LGS Sachaufgabe · Mischung · System wählen',
  gl: ['x + y = 30', '12x + 18y = 420'],
  frage: 'Eine Rösterei mischt zwei Kaffeesorten. Sorte A kostet 12 € je kg, Sorte B 18 € je kg. Es sollen 30 kg einer Mischung entstehen, die 14 € je kg kostet.\n\nx ist die Menge von Sorte A in kg, y die Menge von Sorte B in kg.',
  options: [
    { id: 'a', label: 'I: x + y = 30; II: 12x + 18y = 14' },
    { id: 'b', label: 'I: x + y = 30; II: 18x + 12y = 420' },
    { id: 'c', label: 'I: x + y = 30; II: 12x + 18y = 420' },
  ], richtig: 'c',
  teile: ['Menge von Sorte A in kg: x =', 'Menge von Sorte B in kg: y ='], einheit: { x: 'kg', y: 'kg' },
  afb: 'II', afbGrund: 'Anwenden: Gesamtwert der Mischung (30 · 14 €) als zweite Gleichung erkennen, dann lösen.',
  sach: true, prozess: 'Modellieren', x: '20', y: '10',
  weg: 'Menge: x + y = 30, Wert: 12x + 18y = 30 · 14 = 420, also System c.\nI nach y: y = 30 - x\nIn II: 12x + 18·(30 - x) = 420\n12x + 540 - 18x = 420\n-6x = -120 | :(-6)\nx = 20\ny = 30 - 20 = 10\nGemischt werden 20 kg von Sorte A und 10 kg von Sorte B.',
  ke: [
    { slug: 'bedingung_unvollstaendig', mc: 'a',
      error: 'Den Preis je kg als Gesamtwert genommen: 12x + 18y = 14, die 30 kg fehlen.', frage: 'Was kosten 30 kg der Mischung zusammen?' },
    { slug: 'groessen_vertauscht', mc: 'b', x: ['10', '(420-12*30)/(18-12)'], y: ['20', '30-10'],
      error: 'Die Preise der Sorten vertauscht: 18x + 12y = 420.', frage: 'Welche Sorte kostet 12 € je kg, und welche Variable gehört zu ihr?' },
    { slug: 'vorzeichen_beim_umstellen', x: ['-20', '-(-120/(-6))'], y: ['50', '30-(-20)'],
      error: 'Bei -6x = -120 das Minus am Ergebnis gelassen: x = -20.', frage: 'Kann eine Menge negativ sein? Was ergibt -120 : (-6)?' },
  ] });
sach3({ ref: 'lgs-sach-03', skill: 'gleichung_lgs_sachaufgabe', titel: 'LGS Sachaufgabe · Zahlenrätsel · System wählen',
  gl: ['3x + y = 26', 'x - y = 2'],
  frage: 'Das Dreifache einer Zahl x und eine zweite Zahl y ergeben zusammen 26. Subtrahiert man y von x, erhält man 2.',
  options: [
    { id: 'a', label: 'I: 3x + y = 26; II: x - y = 2' },
    { id: 'b', label: 'I: x + 3y = 26; II: x - y = 2' },
    { id: 'c', label: 'I: 3(x + y) = 26; II: x - y = 2' },
  ], richtig: 'a',
  teile: ['Die Zahl x =', 'Die Zahl y ='],
  afb: 'II', afbGrund: 'Anwenden: Zahlenrätsel in Gleichungen übersetzen (das Dreifache nur von x), mit Addieren lösen.',
  sach: true, prozess: 'Modellieren', x: '7', y: '5',
  weg: 'Das Dreifache von x plus y: 3x + y = 26, x minus y: x - y = 2, also System a.\nI + II: 4x = 28 | :4\nx = 7\nIn II: 7 - y = 2, also y = 5\nDie Zahlen sind x = 7 und y = 5.',
  ke: [
    { slug: 'groessen_vertauscht', mc: 'b', x: ['8', '6+2'], y: ['6', '(26-2)/4'],
      error: 'Das Dreifache der falschen Zahl zugeordnet: x + 3y = 26.', frage: 'Von welcher Zahl wird das Dreifache genommen?' },
    { slug: 'klammer_falsch_gesetzt', mc: 'c',
      error: 'Eine Klammer um x + y gesetzt: Damit wird auch y verdreifacht.', frage: 'Wird im Text die Summe verdreifacht oder nur die Zahl x?' },
    { slug: 'seiten_ungleich_verknuepft', x: ['6', '(26-2)/4'], y: ['4', '6-2'],
      error: 'Links addiert, rechts subtrahiert: 4x = 26 - 2 = 24.', frage: 'Hast du die rechten Seiten genauso verknüpft wie die linken?' },
  ] });
sach3({ ref: 'lgs-sach-04', skill: 'gleichung_lgs_sachaufgabe', titel: 'LGS Sachaufgabe · zwei Tarife · System wählen',
  gl: ['y = 2x + 4', 'y = 1,5x + 7'],
  frage: 'Zwei Taxiunternehmen berechnen ihre Preise so: Unternehmen A verlangt 4 € Grundgebühr und 2 € je Kilometer, Unternehmen B 7 € Grundgebühr und 1,50 € je Kilometer.\n\nx ist die Strecke in km, y der Fahrpreis in €.',
  options: [
    { id: 'a', label: 'I: y = 4x + 2; II: y = 7x + 1,5' },
    { id: 'b', label: 'I: y = 2x + 4; II: y = 1,5x' },
    { id: 'c', label: 'I: y = 2x + 4; II: y = 1,5x + 7' },
  ], richtig: 'c',
  teile: ['Bei welcher Strecke in km kosten beide Fahrten gleich viel? x =', 'Wie viel Euro kostet die Fahrt dann? y ='], einheit: { x: 'km', y: '€' },
  afb: 'II', afbGrund: 'Anwenden: Grundgebühr und Preis je km den Parametern zuordnen, gleichsetzen mit Dezimalkoeffizient.',
  sach: true, prozess: 'Modellieren', x: '6', y: '16',
  weg: 'A: y = 2x + 4, B: y = 1,5x + 7, also System c.\nGleichsetzen: 2x + 4 = 1,5x + 7 | -1,5x\n0,5x + 4 = 7 | -4\n0,5x = 3 | :0,5\nx = 6\nIn A: y = 2·6 + 4 = 16\nBei 6 km kosten beide Fahrten 16 €.',
  ke: [
    { slug: 'groessen_vertauscht', mc: 'a',
      error: 'Grundgebühr und Preis je km vertauscht: y = 4x + 2.', frage: 'Welcher Betrag wird für jeden Kilometer neu fällig, welcher nur einmal?' },
    { slug: 'bedingung_unvollstaendig', mc: 'b',
      error: 'Die Grundgebühr von Unternehmen B weggelassen: y = 1,5x.', frage: 'Was zahlt man bei Unternehmen B, bevor der erste Kilometer gefahren ist?' },
    { slug: 'variablen_nicht_zusammengefuehrt', x: ['1,5', '(7-4)/2'], y: ['7', '2*1.5+4'],
      error: 'Durch 2 geteilt statt durch 2 - 1,5 = 0,5: x = 3 : 2 = 1,5.', frage: 'Wie viele x bleiben links, wenn du 1,5x auf beiden Seiten abziehst?' },
    { slug: 'division_vergessen', x: ['3', '7-4'], y: ['10', '2*3+4'],
      error: 'Bei 0,5x = 3 stehen geblieben und 3 als x genommen.', frage: 'Steht in 0,5x = 3 schon x allein?' },
  ] });
def({ ref: 'lgs-sach-05', skill: 'gleichung_lgs_sachaufgabe', titel: 'LGS Sachaufgabe · Eintrittspreise · selbst aufstellen',
  gl: ['2x + 3y = 35', '3x + 2y = 40'],
  frage: 'Ein Zoo verlangt für Erwachsene und Kinder unterschiedliche Eintrittspreise. 2 Erwachsene und 3 Kinder zahlen zusammen 35 €, 3 Erwachsene und 2 Kinder zahlen zusammen 40 €.\n\nStelle ein Gleichungssystem auf und berechne beide Eintrittspreise (x: Preis für Erwachsene, y: Preis für Kinder, in €).',
  teile: ['Preis für Erwachsene in €: x =', 'Preis für Kinder in €: y ='], einheit: { x: '€', y: '€' },
  afb: 'III', afbGrund: 'Problemlösen: System ohne Vorgabe aufstellen, beide Gleichungen mit verschiedenen Faktoren multiplizieren.',
  sach: true, prozess: 'Modellieren', x: '10', y: '5',
  weg: 'I: 2x + 3y = 35\nII: 3x + 2y = 40\nI · 3: 6x + 9y = 105\nII · 2: 6x + 4y = 80\n3·I - 2·II: 5y = 25 | :5\ny = 5\nIn I: 2x + 15 = 35, also 2x = 20 und x = 10\nErwachsene zahlen 10 €, Kinder 5 €.',
  ke: [
    { slug: 'groessen_vertauscht', x: ['5', '(40-3*10)/2'], y: ['10', '(3*40-2*35)/5'],
      error: 'Erwachsene und Kinder beim Aufstellen vertauscht: 3x + 2y = 35 und 2x + 3y = 40.', frage: 'Zu welcher Variablen gehören die 2 Erwachsenen in der ersten Angabe?' },
    { slug: 'nicht_alle_glieder_multipliziert', x: ['-2', '(35-3*13)/2'], y: ['13', '(105-40)/5'],
      error: 'Beim Multiplizieren von II die rechte Seite vergessen: 6x + 4y = 40 statt 80.', frage: 'Hast du beim Verdoppeln von II auch die 40 verdoppelt?' },
  ] });
def({ ref: 'lgs-sach-06', skill: 'gleichung_lgs_sachaufgabe', titel: 'LGS Sachaufgabe · Rechteck · selbst aufstellen',
  gl: ['2x + 2y = 34', 'x = y + 5'],
  frage: 'Ein rechteckiges Beet hat einen Umfang von 34 m. Es ist 5 m länger als breit.\n\nStelle ein Gleichungssystem auf und berechne Länge und Breite des Beets (x: Länge, y: Breite, in m).',
  teile: ['Länge in m: x =', 'Breite in m: y ='], einheit: { x: 'm', y: 'm' },
  afb: 'III', afbGrund: 'Problemlösen: Umfang mit allen vier Seiten und den Unterschied selbst als System aufstellen und lösen.',
  sach: true, prozess: 'Modellieren', x: '11', y: '6',
  weg: 'I: 2x + 2y = 34 (Umfang)\nII: x = y + 5\nII in I: 2·(y + 5) + 2y = 34\n2y + 10 + 2y = 34\n4y = 24 | :4\ny = 6\nx = 6 + 5 = 11\nDas Beet ist 11 m lang und 6 m breit.',
  ke: [
    { slug: 'umfang_falsch_modelliert', x: ['19,5', '14.5+5'], y: ['14,5', '(34-5)/2'],
      error: 'Den Umfang mit nur zwei Seiten angesetzt: x + y = 34.', frage: 'Wie viele Seiten hat ein Rechteck, und wie viele davon gehören zum Umfang?' },
    { slug: 'klammer_vergessen', x: ['12,25', '7.25+5'], y: ['7,25', '(34-5)/4'],
      error: 'Ohne Klammer eingesetzt: 2y + 5 + 2y = 34, die 2 trifft nur das y.', frage: 'Was wird verdoppelt, wenn du für x den Term y + 5 einsetzt?' },
  ] });
