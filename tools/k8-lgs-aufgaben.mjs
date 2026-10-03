/**
 * k8-lgs-aufgaben.mjs — Aufgaben des Laufs K8-Rest, Thema LGS, Teil 1: Einsetzungs-,
 * Gleichsetzungs- und Additionsverfahren (je sechs). Teil 2 (grafisch, Sachaufgaben) steht in
 * tools/k8-lgs-aufgaben-2.mjs. Gebaut wird die Charge von tools/k8-lgs-charge.mjs; dort wird
 * jede Zahl nachgerechnet und jede Gleichung gegen das Koeffizientensystem geprueft.
 *
 * Felder je Aufgabe:
 *   ref, skill, titel, frage, afb, afbGrund, sach (Sachkontext: +30 s), prozess, weg,
 *   typ: 'xy' (MULTI_PART x | y), 'mc' (Loesungsanzahl, MC), 'sach3' (MC-Teil + x + y),
 *   gl: [Gleichung I, Gleichung II] — das System, ASCII-Minus; steht es in der Frage, muss es
 *       dort woertlich vorkommen (inFrage: true),
 *   x, y: richtige Werte (Komma als Dezimaltrenner), teile: Prompts der Zahlteile,
 *   einheit: { x?, y? } fester Zusatz, nur als Schreibweise in correct_answers/known_errors,
 *   ke: [{ slug, x?: [Wert, Rechnung], y?: [Wert, Rechnung], mc?: Options-id, error, frage }]
 * Rechnungen: Punkt als Dezimaltrenner, "/" fuer Brueche (exakt, prefill-rechnen).
 */

export const A = [];
const def = (o) => A.push({ typ: 'xy', teile: ['x =', 'y ='], einheit: {}, inFrage: true, ...o });
const EINSETZEN = 'Löse das Gleichungssystem mit dem Einsetzungsverfahren.';
const GLEICHSETZEN = 'Löse das Gleichungssystem mit dem Gleichsetzungsverfahren.';
const ADDITION = 'Löse das Gleichungssystem mit dem Additionsverfahren.';
const sys = (kopf, gl) => `${kopf}\n\nI: ${gl[0]}\nII: ${gl[1]}`;

// ─── gleichung_lgs_einsetzen (Tiefe 7) ───────────────────────────────────────
// Steigerung: Variable steht frei (ohne/mit Klammer) -> Minusklammer -> erst umstellen -> zwei Sachkontexte.
def({ ref: 'lgs-einsetzen-01', skill: 'gleichung_lgs_einsetzen', titel: 'Einsetzungsverfahren · y steht frei · Klammer',
  gl: ['y = x + 1', '3x + 2y = 17'], frage: sys(EINSETZEN, ['y = x + 1', '3x + 2y = 17']),
  afb: 'I', afbGrund: 'Reproduzieren: y ist schon freigestellt, Einsetzen mit einer Plusklammer, Ergebnis ganzzahlig.',
  sach: false, prozess: 'Operieren', x: '3', y: '4',
  weg: 'I in II einsetzen: 3x + 2·(x + 1) = 17\n3x + 2x + 2 = 17\n5x + 2 = 17 | -2\n5x = 15 | :5\nx = 3\nIn I einsetzen: y = 3 + 1 = 4\nLösung: x = 3, y = 4.',
  ke: [
    { slug: 'klammer_vergessen', x: ['3,2', '16/5'], y: ['4,2', '16/5+1'],
      error: 'Ohne Klammer eingesetzt: 3x + 2x + 1 = 17, also 5x = 16 und x = 3,2.', frage: 'Womit wird die 2 in 2y multipliziert, wenn du für y den ganzen Term x + 1 einsetzt?' },
    { slug: 'division_vergessen', x: ['15', '17-2'], y: ['16', '15+1'],
      error: 'Bei 5x = 15 stehen geblieben und 15 als x genommen.', frage: 'Steht in der Zeile 5x = 15 schon x allein auf einer Seite?' },
  ] });
def({ ref: 'lgs-einsetzen-02', skill: 'gleichung_lgs_einsetzen', titel: 'Einsetzungsverfahren · x steht frei',
  gl: ['x = 2y', 'x + 3y = 20'], frage: sys(EINSETZEN, ['x = 2y', 'x + 3y = 20']),
  afb: 'I', afbGrund: 'Reproduzieren: x ist freigestellt, Einsetzen ohne Klammer, gleichartige Glieder zusammenfassen.',
  sach: false, prozess: 'Operieren', x: '8', y: '4',
  weg: 'I in II einsetzen: 2y + 3y = 20\n5y = 20 | :5\ny = 4\nIn I einsetzen: x = 2·4 = 8\nLösung: x = 8, y = 4.',
  ke: [
    { slug: 'division_vergessen', x: ['40', '2*20'], y: ['20', '20'],
      error: 'Bei 5y = 20 stehen geblieben: y = 20 und dann x = 40.', frage: 'Was musst du mit 5y = 20 noch tun, damit y allein steht?' },
    { slug: 'falsche_groesse_beantwortet', x: ['4', '20/5'],
      error: 'Den Wert von y als x angegeben, das Rückeinsetzen in I fehlt.', frage: 'Welche Variable hast du mit 5y = 20 berechnet, und wie kommst du jetzt an x?' },
  ] });
def({ ref: 'lgs-einsetzen-03', skill: 'gleichung_lgs_einsetzen', titel: 'Einsetzungsverfahren · Minusklammer',
  gl: ['y = 2x - 3', '4x - y = 7'], frage: sys(EINSETZEN, ['y = 2x - 3', '4x - y = 7']),
  afb: 'II', afbGrund: 'Anwenden: Einsetzen in ein Minus, die Klammer muss aufgelöst werden (Vorzeichenwechsel).',
  sach: false, prozess: 'Operieren', x: '2', y: '1',
  weg: 'I in II einsetzen: 4x - (2x - 3) = 7\n4x - 2x + 3 = 7\n2x + 3 = 7 | -3\n2x = 4 | :2\nx = 2\nIn I einsetzen: y = 2·2 - 3 = 1\nLösung: x = 2, y = 1.',
  ke: [
    { slug: 'klammer_vergessen', x: ['5', '(7+3)/2'], y: ['7', '2*5-3'],
      error: 'Ohne Klammer eingesetzt: 4x - 2x - 3 = 7, das Minus trifft nur 2x.', frage: 'Was wird von 4x abgezogen: nur 2x oder der ganze Term 2x - 3?' },
    { slug: 'division_vergessen', x: ['4', '7-3'], y: ['5', '2*4-3'],
      error: 'Bei 2x = 4 stehen geblieben und 4 als x genommen.', frage: 'Steht in 2x = 4 schon x allein?' },
  ] });
def({ ref: 'lgs-einsetzen-04', skill: 'gleichung_lgs_einsetzen', titel: 'Einsetzungsverfahren · erst umstellen',
  gl: ['x + 2y = 11', '3x - 4y = 3'],
  frage: sys('Löse das Gleichungssystem mit dem Einsetzungsverfahren. Stelle dazu zuerst Gleichung I nach x um.', ['x + 2y = 11', '3x - 4y = 3']),
  afb: 'II', afbGrund: 'Anwenden: erst umstellen, dann einen Term mit zwei Gliedern in eine Klammer einsetzen und ausmultiplizieren.',
  sach: false, prozess: 'Operieren', x: '5', y: '3',
  weg: 'I nach x umstellen: x = 11 - 2y\nIn II einsetzen: 3·(11 - 2y) - 4y = 3\n33 - 6y - 4y = 3\n33 - 10y = 3 | -33\n-10y = -30 | :(-10)\ny = 3\nIn I einsetzen: x = 11 - 2·3 = 5\nLösung: x = 5, y = 3.',
  ke: [
    { slug: 'klammer_vergessen', x: ['1', '11-2*5'], y: ['5', '(33-3)/6'],
      error: 'Ohne Klammer eingesetzt: 3·11 - 2y - 4y = 3, die 3 trifft nur die 11.', frage: 'Womit wird die 3 multipliziert, wenn du für x den Term 11 - 2y einsetzt?' },
    { slug: 'vorzeichen_beim_umstellen', x: ['17', '11-2*(-3)'], y: ['-3', '-(-30/(-10))'],
      error: 'Bei -10y = -30 das Minus am Ergebnis gelassen: y = -3.', frage: 'Was ergibt eine negative Zahl geteilt durch eine negative Zahl?' },
  ] });
def({ ref: 'lgs-einsetzen-05', skill: 'gleichung_lgs_einsetzen', titel: 'Einsetzungsverfahren · Sachkontext · Kinokarten',
  gl: ['x + y = 50', '6x + 9y = 360'], inFrage: false,
  frage: 'Ein Kino verkauft an einem Nachmittag 50 Karten. Eine Kinderkarte kostet 6 €, eine Erwachsenenkarte 9 €. Zusammen nimmt das Kino 360 € ein.\n\nStelle ein Gleichungssystem auf (x: Anzahl der Kinderkarten, y: Anzahl der Erwachsenenkarten) und löse es mit dem Einsetzungsverfahren.',
  teile: ['Anzahl der Kinderkarten: x =', 'Anzahl der Erwachsenenkarten: y ='],
  afb: 'II', afbGrund: 'Anwenden: zwei Bedingungen aus dem Text als Gleichungen aufstellen, dann einsetzen mit Klammer.',
  sach: true, prozess: 'Modellieren', x: '30', y: '20',
  weg: 'I: x + y = 50 (Anzahl der Karten)\nII: 6x + 9y = 360 (Einnahmen in €)\nI nach x umstellen: x = 50 - y\nIn II einsetzen: 6·(50 - y) + 9y = 360\n300 - 6y + 9y = 360\n300 + 3y = 360 | -300\n3y = 60 | :3\ny = 20\nx = 50 - 20 = 30\nLösung: x = 30 Kinderkarten, y = 20 Erwachsenenkarten.',
  ke: [
    { slug: 'groessen_vertauscht', x: ['20', '(360-6*50)/(9-6)'], y: ['30', '50-20'],
      error: 'Die Preise vertauscht: 9x + 6y = 360 statt 6x + 9y = 360.', frage: 'Welcher Preis gehört zu x, der Anzahl der Kinderkarten?' },
    { slug: 'klammer_vergessen', x: ['42,5', '50-7.5'], y: ['7,5', '(360-300)/8'],
      error: 'Ohne Klammer eingesetzt: 6·50 - y + 9y = 360, die 6 trifft nur die 50.', frage: 'Womit wird die 6 multipliziert, wenn du für x den Term 50 - y einsetzt?' },
  ] });
def({ ref: 'lgs-einsetzen-06', skill: 'gleichung_lgs_einsetzen', titel: 'Einsetzungsverfahren · Zahlenrätsel',
  gl: ['x = y + 6', '2x + y = 36'], inFrage: false,
  frage: 'Von zwei Zahlen ist die erste um 6 größer als die zweite. Das Doppelte der ersten Zahl und die zweite Zahl ergeben zusammen 36.\n\nBestimme beide Zahlen mit dem Einsetzungsverfahren (x: erste Zahl, y: zweite Zahl).',
  teile: ['erste Zahl: x =', 'zweite Zahl: y ='],
  afb: 'II', afbGrund: 'Anwenden: Zahlenrätsel in zwei Gleichungen übersetzen, „um 6 größer“ richtig zuordnen, mit Klammer einsetzen.',
  sach: true, prozess: 'Modellieren', x: '14', y: '8',
  weg: 'I: x = y + 6\nII: 2x + y = 36\nI in II einsetzen: 2·(y + 6) + y = 36\n2y + 12 + y = 36\n3y + 12 = 36 | -12\n3y = 24 | :3\ny = 8\nx = 8 + 6 = 14\nLösung: x = 14, y = 8.',
  ke: [
    { slug: 'klammer_vergessen', x: ['16', '10+6'], y: ['10', '(36-6)/3'],
      error: 'Ohne Klammer eingesetzt: 2y + 6 + y = 36, die 2 trifft nur das y.', frage: 'Was wird verdoppelt: nur y oder die ganze erste Zahl y + 6?' },
    { slug: 'groessen_vertauscht', x: ['10', '(36-6)/3'], y: ['16', '10+6'],
      error: 'Die zweite Zahl um 6 größer gemacht: y = x + 6 statt x = y + 6.', frage: 'Welche der beiden Zahlen ist die größere?' },
  ] });

// ─── gleichung_lgs_gleichsetzen (Tiefe 8) ────────────────────────────────────
// Steigerung: beide nach y aufgeloest, positiv -> mit Minus -> negativer Koeffizient -> erst umstellen
// -> Sachkontext Tarife -> Sachkontext gleiche Steigung (keine Loesung, MC).
def({ ref: 'lgs-gleichsetzen-01', skill: 'gleichung_lgs_gleichsetzen', titel: 'Gleichsetzungsverfahren · beide nach y aufgelöst',
  gl: ['y = 2x + 1', 'y = x + 4'], frage: sys(GLEICHSETZEN, ['y = 2x + 1', 'y = x + 4']),
  afb: 'I', afbGrund: 'Reproduzieren: beide Gleichungen nach y aufgelöst, positive Koeffizienten, ganzzahlige Lösung.',
  sach: false, prozess: 'Operieren', x: '3', y: '7',
  weg: 'Gleichsetzen: 2x + 1 = x + 4 | -x\nx + 1 = 4 | -1\nx = 3\nIn II einsetzen: y = 3 + 4 = 7\nLösung: x = 3, y = 7.',
  ke: [
    { slug: 'variablen_nicht_zusammengefuehrt', x: ['1,5', '(4-1)/2'], y: ['4', '2*1.5+1'],
      error: 'Das x auf der rechten Seite nicht abgezogen und durch 2 geteilt: x = 3 : 2 = 1,5.', frage: 'Auf welchen Seiten steht x? Wie bringst du alle x auf eine Seite?' },
    { slug: 'falsches_vorzeichen_beim_zusammenfuehren', x: ['5', '4+1'], y: ['9', '5+4'],
      error: 'Die 1 addiert statt abgezogen: x = 4 + 1 = 5.', frage: 'Wie bekommst du die +1 von der linken Seite weg?' },
  ] });
def({ ref: 'lgs-gleichsetzen-02', skill: 'gleichung_lgs_gleichsetzen', titel: 'Gleichsetzungsverfahren · Konstante mit Minus',
  gl: ['y = 3x - 2', 'y = x + 6'], frage: sys(GLEICHSETZEN, ['y = 3x - 2', 'y = x + 6']),
  afb: 'I', afbGrund: 'Reproduzieren: beide nach y aufgelöst, eine negative Konstante, ganzzahlige Lösung.',
  sach: false, prozess: 'Operieren', x: '4', y: '10',
  weg: 'Gleichsetzen: 3x - 2 = x + 6 | -x\n2x - 2 = 6 | +2\n2x = 8 | :2\nx = 4\nIn II einsetzen: y = 4 + 6 = 10\nLösung: x = 4, y = 10.',
  ke: [
    { slug: 'falsches_vorzeichen_beim_zusammenfuehren', x: ['2', '(6-2)/2'], y: ['8', '2+6'],
      error: 'Die -2 falsch herübergebracht: 2x = 6 - 2 = 4 statt 2x = 6 + 2 = 8.', frage: 'Mit welcher Rechnung verschwindet die -2 auf der linken Seite?' },
    { slug: 'division_vergessen', x: ['8', '6+2'], y: ['14', '8+6'],
      error: 'Bei 2x = 8 stehen geblieben und 8 als x genommen.', frage: 'Steht in 2x = 8 schon x allein?' },
  ] });
def({ ref: 'lgs-gleichsetzen-03', skill: 'gleichung_lgs_gleichsetzen', titel: 'Gleichsetzungsverfahren · negativer Koeffizient',
  gl: ['y = -2x + 7', 'y = x - 5'], frage: sys(GLEICHSETZEN, ['y = -2x + 7', 'y = x - 5']),
  afb: 'II', afbGrund: 'Anwenden: negativer Koeffizient, Division durch eine negative Zahl, negatives y.',
  sach: false, prozess: 'Operieren', x: '4', y: '-1',
  weg: 'Gleichsetzen: -2x + 7 = x - 5 | -x\n-3x + 7 = -5 | -7\n-3x = -12 | :(-3)\nx = 4\nIn II einsetzen: y = 4 - 5 = -1\nLösung: x = 4, y = -1.',
  ke: [
    { slug: 'vorzeichen_beim_umstellen', x: ['-4', '-(-12/(-3))'], y: ['-9', '-4-5'],
      error: 'Bei -3x = -12 das Minus am Ergebnis gelassen: x = -4.', frage: 'Was ergibt -12 geteilt durch -3?' },
    { slug: 'variablen_nicht_zusammengefuehrt', x: ['6', '-12/(-2)'], y: ['1', '6-5'],
      error: 'Nur durch den linken Koeffizienten -2 geteilt, das x von rechts nicht abgezogen.', frage: 'Wie viele x stehen links, nachdem du das x von der rechten Seite herübergebracht hast?' },
  ] });
def({ ref: 'lgs-gleichsetzen-04', skill: 'gleichung_lgs_gleichsetzen', titel: 'Gleichsetzungsverfahren · erst nach y auflösen',
  gl: ['x + y = 5', '2x - y = 4'],
  frage: sys('Löse das Gleichungssystem mit dem Gleichsetzungsverfahren. Löse dazu zuerst beide Gleichungen nach y auf.', ['x + y = 5', '2x - y = 4']),
  afb: 'II', afbGrund: 'Anwenden: beide Gleichungen erst nach y umstellen (II mit -y), dann gleichsetzen, negativer Koeffizient.',
  sach: false, prozess: 'Operieren', x: '3', y: '2',
  weg: 'I nach y: y = -x + 5\nII nach y: -y = -2x + 4, also y = 2x - 4\nGleichsetzen: -x + 5 = 2x - 4 | -2x\n-3x + 5 = -4 | -5\n-3x = -9 | :(-3)\nx = 3\nIn I einsetzen: y = -3 + 5 = 2\nLösung: x = 3, y = 2.',
  ke: [
    { slug: 'vorzeichen_beim_umstellen', x: ['-3', '-(-9/(-3))'], y: ['8', '-(-3)+5'],
      error: 'Bei -3x = -9 das Minus am Ergebnis gelassen: x = -3.', frage: 'Welches Vorzeichen hat der Quotient zweier negativer Zahlen?' },
    { slug: 'variablen_nicht_zusammengefuehrt', x: ['9', '-9/(-1)'], y: ['-4', '-9+5'],
      error: 'Nur durch den linken Koeffizienten -1 geteilt, das 2x von rechts nicht herübergebracht.', frage: 'Stehen nach deinem Schritt alle x auf einer Seite?' },
  ] });
def({ ref: 'lgs-gleichsetzen-05', skill: 'gleichung_lgs_gleichsetzen', titel: 'Gleichsetzungsverfahren · Sachkontext · zwei Tarife',
  gl: ['y = 2x + 5', 'y = x + 11'], inFrage: false,
  frage: 'Ein Fahrradverleih bietet zwei Tarife an. Tarif A: 5 € Grundgebühr und 2 € je Stunde. Tarif B: 11 € Grundgebühr und 1 € je Stunde.\n\nBei welcher Leihdauer kosten beide Tarife gleich viel, und wie viel kostet es dann? Stelle für jeden Tarif eine Gleichung auf (x: Leihdauer in Stunden, y: Kosten in €) und löse mit dem Gleichsetzungsverfahren.',
  teile: ['Leihdauer in Stunden: x =', 'Kosten in €: y ='], einheit: { y: '€' },
  afb: 'II', afbGrund: 'Anwenden: zwei Tarife als Gleichungen y = mx + b aufstellen, gleichsetzen, Ergebnis im Kontext deuten.',
  sach: true, prozess: 'Modellieren', x: '6', y: '17',
  weg: 'Tarif A: y = 2x + 5\nTarif B: y = x + 11\nGleichsetzen: 2x + 5 = x + 11 | -x\nx + 5 = 11 | -5\nx = 6\nIn B einsetzen: y = 6 + 11 = 17\nNach 6 Stunden kosten beide Tarife 17 €.',
  ke: [
    { slug: 'variablen_nicht_zusammengefuehrt', x: ['3', '(11-5)/2'], y: ['11', '2*3+5'],
      error: 'Das x von Tarif B nicht abgezogen und durch 2 geteilt: x = 6 : 2 = 3.', frage: 'Auf welchen Seiten der Gleichung 2x + 5 = x + 11 steht x?' },
    { slug: 'falsches_vorzeichen_beim_zusammenfuehren', x: ['16', '11+5'], y: ['27', '16+11'],
      error: 'Die 5 addiert statt abgezogen: x = 11 + 5 = 16.', frage: 'Wie bekommst du die +5 von der linken Seite weg?' },
  ] });
def({ ref: 'lgs-gleichsetzen-06', skill: 'gleichung_lgs_gleichsetzen', typ: 'mc', titel: 'Gleichsetzungsverfahren · Sachkontext · gleiche Stundenpreise',
  gl: ['y = 2x + 4', 'y = 2x + 6'],
  frage: 'Ein Kletterpark bietet zwei Tarife an. Tarif A: 4 € Grundgebühr und 2 € je Stunde. Tarif B: 6 € Grundgebühr und 2 € je Stunde.\n\nMit x = Stunden und y = Kosten in € gilt:\nI: y = 2x + 4\nII: y = 2x + 6\n\nWie viele Lösungen hat das Gleichungssystem? Nutze das Gleichsetzungsverfahren.',
  afb: 'II', afbGrund: 'Anwenden und deuten: Gleichsetzen endet mit einer falschen Aussage, daraus die Lösungsanzahl schließen.',
  sach: true, prozess: 'Argumentieren', richtig: 'b',
  weg: 'Gleichsetzen: 2x + 4 = 2x + 6 | -2x\n4 = 6\nDas ist eine falsche Aussage, für kein x erfüllt.\nDas Gleichungssystem hat keine Lösung: Tarif B ist immer 2 € teurer, die Geraden sind parallel.',
  ke: [
    { slug: 'parallele_uebersehen', mc: 'a',
      error: 'Genau eine Lösung angenommen, obwohl beide Tarife denselben Stundenpreis haben.', frage: 'Wie groß ist der Preisunterschied nach einer, nach zwei, nach zehn Stunden?' },
    { slug: 'loesungsanzahl_verwechselt', mc: 'c',
      error: 'Die falsche Aussage 4 = 6 als „unendlich viele Lösungen“ gelesen.', frage: 'Gibt es eine Stundenzahl, für die 4 = 6 stimmt?' },
  ] });

// ─── gleichung_lgs_addition (Tiefe 8) ────────────────────────────────────────
// Steigerung: y faellt direkt weg -> mit negativer rechter Seite -> eine Gleichung mal Faktor
// -> Faktor selbst finden -> Sachkontext Eintritt -> Sachkontext Vielfaches (unendlich viele, MC).
def({ ref: 'lgs-addition-01', skill: 'gleichung_lgs_addition', titel: 'Additionsverfahren · y fällt direkt weg',
  gl: ['x + 2y = 12', 'x - 2y = 4'], frage: sys(ADDITION, ['x + 2y = 12', 'x - 2y = 4']),
  afb: 'I', afbGrund: 'Reproduzieren: Addieren genügt, y fällt sofort weg, ganzzahlige Lösung.',
  sach: false, prozess: 'Operieren', x: '8', y: '2',
  weg: 'I + II: (x + 2y) + (x - 2y) = 12 + 4\n2x = 16 | :2\nx = 8\nIn I einsetzen: 8 + 2y = 12 | -8\n2y = 4 | :2\ny = 2\nLösung: x = 8, y = 2.',
  ke: [
    { slug: 'seiten_ungleich_verknuepft', x: ['4', '(12-4)/2'], y: ['4', '(12-4)/2'],
      error: 'Links addiert, rechts subtrahiert: 2x = 12 - 4 = 8.', frage: 'Hast du links und rechts dieselbe Rechenart benutzt?' },
    { slug: 'division_vergessen', x: ['16', '12+4'], y: ['-2', '(12-16)/2'],
      error: 'Bei 2x = 16 stehen geblieben und 16 als x genommen.', frage: 'Steht in 2x = 16 schon x allein?' },
  ] });
def({ ref: 'lgs-addition-02', skill: 'gleichung_lgs_addition', titel: 'Additionsverfahren · negative rechte Seite',
  gl: ['3x + 2y = 18', 'x - 2y = -2'], frage: sys(ADDITION, ['3x + 2y = 18', 'x - 2y = -2']),
  afb: 'I', afbGrund: 'Reproduzieren: Addieren genügt, rechts wird eine negative Zahl addiert.',
  sach: false, prozess: 'Operieren', x: '4', y: '3',
  weg: 'I + II: 4x = 18 + (-2) = 16 | :4\nx = 4\nIn I einsetzen: 12 + 2y = 18 | -12\n2y = 6 | :2\ny = 3\nLösung: x = 4, y = 3.',
  ke: [
    { slug: 'seiten_ungleich_verknuepft', x: ['5', '(18-(-2))/4'], y: ['1,5', '(18-3*5)/2'],
      error: 'Links addiert, rechts subtrahiert: 4x = 18 - (-2) = 20.', frage: 'Wenn du links die Gleichungen addierst, was musst du dann rechts mit 18 und -2 tun?' },
    { slug: 'division_vergessen', x: ['16', '18+(-2)'], y: ['-15', '(18-3*16)/2'],
      error: 'Bei 4x = 16 stehen geblieben und 16 als x genommen.', frage: 'Steht in 4x = 16 schon x allein?' },
  ] });
def({ ref: 'lgs-addition-03', skill: 'gleichung_lgs_addition', titel: 'Additionsverfahren · eine Gleichung mal Faktor',
  gl: ['2x + 3y = 13', 'x + y = 5'],
  frage: sys('Löse das Gleichungssystem mit dem Additionsverfahren. Multipliziere dazu Gleichung II mit 2.', ['2x + 3y = 13', 'x + y = 5']),
  afb: 'II', afbGrund: 'Anwenden: eine Gleichung mit einem Faktor multiplizieren, dann subtrahieren.',
  sach: false, prozess: 'Operieren', x: '2', y: '3',
  weg: 'II · 2: 2x + 2y = 10\nI - 2·II: (2x + 3y) - (2x + 2y) = 13 - 10\ny = 3\nIn II einsetzen: x + 3 = 5 | -3\nx = 2\nLösung: x = 2, y = 3.',
  ke: [
    { slug: 'nicht_alle_glieder_multipliziert', x: ['-3', '5-8'], y: ['8', '13-5'],
      error: 'Beim Multiplizieren die rechte Seite vergessen: 2x + 2y = 5 statt 10.', frage: 'Hast du nach dem Malnehmen mit 2 jedes Glied der Gleichung II verdoppelt, auch die 5?' },
    { slug: 'seiten_ungleich_verknuepft', x: ['-18', '5-23'], y: ['23', '13+10'],
      error: 'Links subtrahiert, rechts addiert: y = 13 + 10 = 23.', frage: 'Welche Rechenart hast du links benutzt, welche rechts?' },
  ] });
def({ ref: 'lgs-addition-04', skill: 'gleichung_lgs_addition', titel: 'Additionsverfahren · Faktor selbst finden',
  gl: ['4x + 3y = 5', '2x - y = 5'],
  frage: sys('Löse das Gleichungssystem mit dem Additionsverfahren. Multipliziere dazu eine Gleichung mit einer passenden Zahl.', ['4x + 3y = 5', '2x - y = 5']),
  afb: 'II', afbGrund: 'Anwenden: den Faktor selbst wählen (II mal 3), negativer Koeffizient, negatives y.',
  sach: false, prozess: 'Problemlösen', x: '2', y: '-1',
  weg: 'II · 3: 6x - 3y = 15\nI + 3·II: (4x + 3y) + (6x - 3y) = 5 + 15\n10x = 20 | :10\nx = 2\nIn II einsetzen: 2·2 - y = 5, also y = 4 - 5 = -1\nLösung: x = 2, y = -1.',
  ke: [
    { slug: 'nicht_alle_glieder_multipliziert', x: ['1', '(5+5)/10'], y: ['-3', '2*1-5'],
      error: 'Beim Multiplizieren die rechte Seite vergessen: 6x - 3y = 5 statt 15.', frage: 'Hast du nach dem Malnehmen mit 3 auch die rechte Seite von II verdreifacht?' },
    { slug: 'seiten_ungleich_verknuepft', x: ['-1', '(5-15)/10'], y: ['-7', '2*(-1)-5'],
      error: 'Links addiert, rechts subtrahiert: 10x = 5 - 15 = -10.', frage: 'Hast du die rechten Seiten genauso verknüpft wie die linken?' },
  ] });
def({ ref: 'lgs-addition-05', skill: 'gleichung_lgs_addition', titel: 'Additionsverfahren · Sachkontext · Eintrittspreise',
  gl: ['2x + 3y = 34', 'x + 2y = 20'], inFrage: false,
  frage: 'In einem Museum zahlen 2 Erwachsene und 3 Kinder zusammen 34 € Eintritt. 1 Erwachsener und 2 Kinder zahlen zusammen 20 €.\n\nWie viel kostet eine Karte für Erwachsene und wie viel eine Karte für Kinder? Stelle ein Gleichungssystem auf (x: Preis für Erwachsene, y: Preis für Kinder, in €) und löse es mit dem Additionsverfahren.',
  teile: ['Preis für Erwachsene in €: x =', 'Preis für Kinder in €: y ='], einheit: { x: '€', y: '€' },
  afb: 'II', afbGrund: 'Anwenden: zwei Preisangaben als Gleichungen aufstellen, eine Gleichung mit 2 multiplizieren und subtrahieren.',
  sach: true, prozess: 'Modellieren', x: '8', y: '6',
  weg: 'I: 2x + 3y = 34\nII: x + 2y = 20\nII · 2: 2x + 4y = 40\n2·II - I: (2x + 4y) - (2x + 3y) = 40 - 34\ny = 6\nIn II einsetzen: x + 12 = 20, also x = 8\nEine Karte für Erwachsene kostet 8 €, für Kinder 6 €.',
  ke: [
    { slug: 'groessen_vertauscht', x: ['6', '(34-2*8)/3'], y: ['8', '20-2*6'],
      error: 'Erwachsene und Kinder beim Aufstellen vertauscht: 3x + 2y = 34 und 2x + y = 20.', frage: 'Zu welcher Variablen gehört die Anzahl der Erwachsenen in der ersten Angabe?' },
    { slug: 'nicht_alle_glieder_multipliziert', x: ['48', '20-2*(-14)'], y: ['-14', '20-34'],
      error: 'Beim Multiplizieren die rechte Seite vergessen: 2x + 4y = 20 statt 40.', frage: 'Hast du beim Verdoppeln von II auch die 20 verdoppelt?' },
  ] });
def({ ref: 'lgs-addition-06', skill: 'gleichung_lgs_addition', typ: 'mc', titel: 'Additionsverfahren · Sachkontext · Vielfaches',
  gl: ['2x + 3y = 7', '4x + 6y = 14'],
  frage: 'In einem Schreibwarenladen kosten 2 Hefte und 3 Stifte zusammen 7 €. 4 Hefte und 6 Stifte kosten zusammen 14 €.\n\nMit x = Preis eines Heftes und y = Preis eines Stiftes (in €) gilt:\nI: 2x + 3y = 7\nII: 4x + 6y = 14\n\nWie viele Lösungen hat das Gleichungssystem? Nutze das Additionsverfahren.',
  afb: 'II', afbGrund: 'Anwenden und deuten: Das Verfahren endet mit einer wahren Aussage, daraus die Lösungsanzahl schließen.',
  sach: true, prozess: 'Argumentieren', richtig: 'c',
  weg: 'I · 2: 4x + 6y = 14\nII - 2·I: 0 = 0\nDas ist eine wahre Aussage, jedes Zahlenpaar, das I erfüllt, erfüllt auch II.\nDas Gleichungssystem hat unendlich viele Lösungen: Die zweite Angabe ist nur die doppelte erste, die Preise lassen sich so nicht eindeutig bestimmen.',
  ke: [
    { slug: 'parallele_uebersehen', mc: 'a',
      error: 'Genau eine Lösung angenommen, obwohl II nur das Doppelte von I ist.', frage: 'Was erhältst du, wenn du Gleichung I mit 2 multiplizierst?' },
    { slug: 'loesungsanzahl_verwechselt', mc: 'b',
      error: 'Die wahre Aussage 0 = 0 als „keine Lösung“ gelesen.', frage: 'Stimmt 0 = 0? Für welche Zahlenpaare?' },
  ] });
