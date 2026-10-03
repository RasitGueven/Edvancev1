/**
 * k8-flaeche-aufgaben.mjs — Aufgaben des Laufs K8 Flaechen (W4 K8-Rest), Teil 1:
 * geo_flaeche_trapez, geo_flaeche_drachen_raute, geo_flaeche_zusammengesetzt.
 * Teil 2 (geo_flaeche_term, geo_flaeche_rueck): tools/k8-flaeche-aufgaben-2.mjs.
 * Gebaut wird die Charge von tools/k8-flaeche-charge.mjs; dort wird jede Zahl nachgerechnet.
 *
 * Felder je NUMERIC-Aufgabe:
 *   ref, skill, titel, frage, einheit, afb, afbGrund, sach (Sachkontext: +30 s), prozess,
 *   antwort (Komma-Schreibweise), r (Rechnung zur Antwort, Punkt als Dezimaltrenner),
 *   weg (Loesungsweg), ke: [falscher Wert, Slug, Rechnung, Fehlertext, sokratische Frage]
 * Keine Abbildungen: kein Generator zeichnet Trapez, Drachen, Raute oder Vielecke (phase1 a).
 * Jede Figur ist deshalb im Text mit allen Massen und ihrer Lage beschrieben.
 */

export const A = [];
const def = (o) => A.push(o);
const FL = 'Wie groß ist sein Flächeninhalt?';

// ─── geo_flaeche_trapez (Tiefe 5) ────────────────────────────────────────────
// Steigerung: ganzzahlig -> mit Klammerfalle -> Schenkel als Ablenker -> Dezimal -> Sachkontext.
const TR = { skill: 'geo_flaeche_trapez' };
def({ ...TR, ref: 'flaeche-trapez-01', titel: 'Trapez · a = 8 cm, c = 4 cm, h = 5 cm', einheit: 'cm²',
  frage: `Ein Trapez hat die parallelen Seiten a = 8 cm und c = 4 cm und die Höhe h = 5 cm.\n\n${FL}`,
  afb: 'I', afbGrund: 'Reproduzieren: Trapezformel mit ganzen Zahlen, Mittelwert der Grundseiten ganzzahlig.',
  sach: false, prozess: 'Operieren', antwort: '30', r: '(8+4)/2*5',
  weg: 'A = (a + c) : 2 · h = (8 cm + 4 cm) : 2 · 5 cm = 6 cm · 5 cm = 30 cm².',
  ke: [
    ['40', 'nur_eine_grundseite', '8*5', 'Nur mit der Seite a gerechnet: 8 · 5 = 40.', 'Welche beiden Seiten des Trapezes sind parallel – und kommen beide in deiner Rechnung vor?'],
    ['20', 'nur_eine_grundseite', '4*5', 'Nur mit der Seite c gerechnet: 4 · 5 = 20.', 'Welche beiden Seiten des Trapezes sind parallel – und kommen beide in deiner Rechnung vor?'],
    ['60', 'halbieren_vergessen', '(8+4)*5', 'Die Summe der parallelen Seiten nicht halbiert: 12 · 5 = 60.', 'Wie viel ist der Mittelwert von 8 cm und 4 cm?'],
  ] });
def({ ...TR, ref: 'flaeche-trapez-02', titel: 'Trapez · a = 10 cm, c = 6 cm, h = 7 cm', einheit: 'cm²',
  frage: `Ein Trapez hat die parallelen Seiten a = 10 cm und c = 6 cm und die Höhe h = 7 cm.\n\n${FL}`,
  afb: 'I', afbGrund: 'Reproduzieren: Trapezformel mit ganzen Zahlen.',
  sach: false, prozess: 'Operieren', antwort: '56', r: '(10+6)/2*7',
  weg: 'A = (a + c) : 2 · h = (10 cm + 6 cm) : 2 · 7 cm = 8 cm · 7 cm = 56 cm².',
  ke: [
    ['70', 'nur_eine_grundseite', '10*7', 'Nur mit der Seite a gerechnet: 10 · 7 = 70.', 'Ist ein Trapez ein Parallelogramm, bei dem eine Seite reicht?'],
    ['42', 'nur_eine_grundseite', '6*7', 'Nur mit der Seite c gerechnet: 6 · 7 = 42.', 'Ist ein Trapez ein Parallelogramm, bei dem eine Seite reicht?'],
    ['112', 'halbieren_vergessen', '(10+6)*7', 'Die Summe der parallelen Seiten nicht halbiert: 16 · 7 = 112.', 'Wäre ein Rechteck mit 10 cm Länge und 7 cm Breite größer oder kleiner als dein Ergebnis?'],
    ['31', 'klammer_vergessen', '10+6/2*7', 'Ohne Klammer gerechnet: 10 + 6 : 2 · 7 = 10 + 21 = 31.', 'Welche Rechnung muss zuerst passieren, damit beide Seiten halbiert werden?'],
  ] });
def({ ...TR, ref: 'flaeche-trapez-03', titel: 'Trapez · gleichschenklig, Schenkel als Ablenker', einheit: 'cm²',
  frage: `Ein gleichschenkliges Trapez hat die parallelen Seiten a = 11 cm und c = 5 cm. Die beiden Schenkel sind je 5 cm lang, die Höhe beträgt h = 4 cm.\n\n${FL}`,
  afb: 'II', afbGrund: 'Anwenden: Die Schenkellänge ist angegeben, aber nicht die Höhe; die richtige Länge muss ausgewählt werden.',
  sach: false, prozess: 'Operieren', antwort: '32', r: '(11+5)/2*4',
  weg: 'Die Schenkel stehen schräg, gebraucht wird die Höhe h = 4 cm.\nA = (11 cm + 5 cm) : 2 · 4 cm = 8 cm · 4 cm = 32 cm².',
  ke: [
    ['40', 'falsche_hoehe', '(11+5)/2*5', 'Die Schenkellänge statt der Höhe eingesetzt: 8 · 5 = 40.', 'Steht ein Schenkel senkrecht auf den parallelen Seiten?'],
    ['44', 'nur_eine_grundseite', '11*4', 'Nur mit der Seite a gerechnet: 11 · 4 = 44.', 'Welche beiden Seiten sind parallel – und kommen beide in deiner Rechnung vor?'],
    ['20', 'nur_eine_grundseite', '5*4', 'Nur mit der Seite c gerechnet: 5 · 4 = 20.', 'Welche beiden Seiten sind parallel – und kommen beide in deiner Rechnung vor?'],
    ['64', 'halbieren_vergessen', '(11+5)*4', 'Die Summe der parallelen Seiten nicht halbiert: 16 · 4 = 64.', 'Wie viel ist der Mittelwert von 11 cm und 5 cm?'],
  ] });
def({ ...TR, ref: 'flaeche-trapez-04', titel: 'Trapez · Dezimalmaße', einheit: 'cm²',
  frage: `Ein Trapez hat die parallelen Seiten a = 6,5 cm und c = 3,5 cm und die Höhe h = 4,2 cm.\n\n${FL}`,
  afb: 'II', afbGrund: 'Anwenden: Trapezformel mit Dezimalzahlen, Produkt mit einer Dezimalstelle.',
  sach: false, prozess: 'Operieren', antwort: '21', r: '(6.5+3.5)/2*4.2',
  weg: 'A = (6,5 cm + 3,5 cm) : 2 · 4,2 cm = 5 cm · 4,2 cm = 21 cm².',
  ke: [
    ['27,3', 'nur_eine_grundseite', '6.5*4.2', 'Nur mit der Seite a gerechnet: 6,5 · 4,2 = 27,3.', 'Kommen beide parallelen Seiten in deiner Rechnung vor?'],
    ['14,7', 'nur_eine_grundseite', '3.5*4.2', 'Nur mit der Seite c gerechnet: 3,5 · 4,2 = 14,7.', 'Kommen beide parallelen Seiten in deiner Rechnung vor?'],
    ['42', 'halbieren_vergessen', '(6.5+3.5)*4.2', 'Die Summe der parallelen Seiten nicht halbiert: 10 · 4,2 = 42.', 'Wie viel ist der Mittelwert von 6,5 cm und 3,5 cm?'],
    ['13,85', 'klammer_vergessen', '6.5+3.5/2*4.2', 'Ohne Klammer gerechnet: 6,5 + 3,5 : 2 · 4,2 = 6,5 + 7,35 = 13,85.', 'Wird bei dir die Seite a überhaupt halbiert und mit der Höhe malgenommen?'],
  ] });
def({ ...TR, ref: 'flaeche-trapez-05', titel: 'Trapez · Sachkontext · Dachfläche', einheit: 'm²',
  frage: 'Eine Dachfläche hat die Form eines Trapezes. Die untere Dachkante ist 12 m lang, die obere Dachkante 8 m. Beide Kanten sind parallel, ihr Abstand auf der Dachfläche beträgt 5 m.\n\nWie groß ist die Dachfläche?',
  afb: 'II', afbGrund: 'Anwenden im Sachkontext: parallele Kanten und Abstand als a, c und h erkennen.',
  sach: true, prozess: 'Modellieren, Operieren', antwort: '50', r: '(12+8)/2*5',
  weg: 'a = 12 m, c = 8 m, h = 5 m.\nA = (12 m + 8 m) : 2 · 5 m = 10 m · 5 m = 50 m².',
  ke: [
    ['60', 'nur_eine_grundseite', '12*5', 'Nur mit der unteren Kante gerechnet: 12 · 5 = 60.', 'Ist das Dach oben genauso breit wie unten?'],
    ['40', 'nur_eine_grundseite', '8*5', 'Nur mit der oberen Kante gerechnet: 8 · 5 = 40.', 'Ist das Dach unten genauso breit wie oben?'],
    ['100', 'halbieren_vergessen', '(12+8)*5', 'Die Summe der Kanten nicht halbiert: 20 · 5 = 100.', 'Kann das Dach größer sein als ein Rechteck mit 12 m und 5 m?'],
  ] });
def({ ...TR, ref: 'flaeche-trapez-06', titel: 'Trapez · Sachkontext · Grundstückspreis', einheit: '€',
  frage: 'Ein Grundstück hat die Form eines Trapezes. Die beiden parallelen Grundstücksseiten sind 32 m und 24 m lang, ihr Abstand beträgt 18 m. Ein Quadratmeter kostet 150 €.\n\nWie viel kostet das Grundstück?',
  afb: 'II', afbGrund: 'Anwenden im Sachkontext: Trapezfläche und anschließend Preis, zwei Schritte.',
  sach: true, prozess: 'Modellieren, Operieren', antwort: '75600', r: '(32+24)/2*18*150',
  weg: 'A = (32 m + 24 m) : 2 · 18 m = 28 m · 18 m = 504 m².\nPreis = 504 · 150 € = 75600 €.',
  ke: [
    ['86400', 'nur_eine_grundseite', '32*18*150', 'Nur mit der längeren Seite gerechnet: 32 · 18 = 576 m², 576 · 150 € = 86400 €.', 'Ist das Grundstück auf beiden parallelen Seiten gleich breit?'],
    ['64800', 'nur_eine_grundseite', '24*18*150', 'Nur mit der kürzeren Seite gerechnet: 24 · 18 = 432 m², 432 · 150 € = 64800 €.', 'Ist das Grundstück auf beiden parallelen Seiten gleich breit?'],
    ['151200', 'halbieren_vergessen', '(32+24)*18*150', 'Die Summe der Seiten nicht halbiert: 1008 m², 1008 · 150 € = 151200 €.', 'Wie viel ist der Mittelwert von 32 m und 24 m?'],
  ] });

// ─── geo_flaeche_drachen_raute (Tiefe 5) ─────────────────────────────────────
const DR = { skill: 'geo_flaeche_drachen_raute' };
def({ ...DR, ref: 'flaeche-drachen-01', titel: 'Drachenviereck · e = 8 cm, f = 6 cm', einheit: 'cm²',
  frage: `Ein Drachenviereck hat die Diagonalen e = 8 cm und f = 6 cm.\n\n${FL}`,
  afb: 'I', afbGrund: 'Reproduzieren: Formel A = e · f : 2 mit ganzen Zahlen.',
  sach: false, prozess: 'Operieren', antwort: '24', r: '8*6/2',
  weg: 'A = e · f : 2 = 8 cm · 6 cm : 2 = 48 cm² : 2 = 24 cm².',
  ke: [
    ['48', 'halbieren_vergessen', '8*6', 'Nicht halbiert: 8 · 6 = 48 ist das umschließende Rechteck.', 'Füllt der Drachen das Rechteck aus den beiden Diagonalen ganz aus?'],
    ['14', 'plus_statt_mal', '8+6', 'Die Diagonalen addiert: 8 + 6 = 14.', 'Kommt bei einer Summe von Längen eine Fläche heraus?'],
  ] });
def({ ...DR, ref: 'flaeche-raute-02', titel: 'Raute · e = 10 cm, f = 7 cm', einheit: 'cm²',
  frage: 'Eine Raute hat die Diagonalen e = 10 cm und f = 7 cm.\n\nWie groß ist ihr Flächeninhalt?',
  afb: 'I', afbGrund: 'Reproduzieren: Formel A = e · f : 2 mit ganzen Zahlen.',
  sach: false, prozess: 'Operieren', antwort: '35', r: '10*7/2',
  weg: 'A = e · f : 2 = 10 cm · 7 cm : 2 = 70 cm² : 2 = 35 cm².',
  ke: [
    ['70', 'halbieren_vergessen', '10*7', 'Nicht halbiert: 10 · 7 = 70 ist das umschließende Rechteck.', 'Welcher Teil des Rechtecks aus den Diagonalen gehört zur Raute?'],
    ['17', 'plus_statt_mal', '10+7', 'Die Diagonalen addiert: 10 + 7 = 17.', 'Kommt bei einer Summe von Längen eine Fläche heraus?'],
  ] });
def({ ...DR, ref: 'flaeche-raute-03', titel: 'Raute · Seitenlänge als Ablenker', einheit: 'cm²',
  frage: 'Eine Raute hat die Seitenlänge 13 cm. Ihre Diagonalen sind e = 24 cm und f = 10 cm lang.\n\nWie groß ist ihr Flächeninhalt?',
  afb: 'II', afbGrund: 'Anwenden: Seitenlänge ist gegeben, aber nicht nötig; die Diagonalen müssen ausgewählt werden.',
  sach: false, prozess: 'Operieren', antwort: '120', r: '24*10/2',
  weg: 'Die Seitenlänge wird nicht gebraucht.\nA = e · f : 2 = 24 cm · 10 cm : 2 = 240 cm² : 2 = 120 cm².',
  ke: [
    ['240', 'halbieren_vergessen', '24*10', 'Nicht halbiert: 24 · 10 = 240.', 'Füllt die Raute das Rechteck aus den beiden Diagonalen ganz aus?'],
    ['169', 'falsche_hoehe', '13*13', 'Die Seite als Höhe genommen: 13 · 13 = 169, als wäre die Raute ein Quadrat.', 'Steht bei einer Raute eine Seite senkrecht auf der anderen?'],
    ['52', 'umfang_statt_flaeche', '4*13', 'Den Umfang berechnet: 4 · 13 = 52.', 'Ist nach der Randlänge oder nach der Fläche gefragt?'],
  ] });
def({ ...DR, ref: 'flaeche-drachen-04', titel: 'Drachenviereck · Dezimalmaße', einheit: 'cm²',
  frage: `Ein Drachenviereck hat die Diagonalen e = 7,5 cm und f = 4,8 cm.\n\n${FL}`,
  afb: 'II', afbGrund: 'Anwenden: Produkt zweier Dezimalzahlen, dann halbieren.',
  sach: false, prozess: 'Operieren', antwort: '18', r: '7.5*4.8/2',
  weg: 'A = e · f : 2 = 7,5 cm · 4,8 cm : 2 = 36 cm² : 2 = 18 cm².',
  ke: [
    ['36', 'halbieren_vergessen', '7.5*4.8', 'Nicht halbiert: 7,5 · 4,8 = 36.', 'Füllt der Drachen das Rechteck aus den beiden Diagonalen ganz aus?'],
    ['12,3', 'plus_statt_mal', '7.5+4.8', 'Die Diagonalen addiert: 7,5 + 4,8 = 12,3.', 'Kommt bei einer Summe von Längen eine Fläche heraus?'],
  ] });
def({ ...DR, ref: 'flaeche-drachen-05', titel: 'Drachen · Sachkontext · Papierdrachen', einheit: 'cm²',
  frage: 'Ein Drachen aus Papier hat die Form eines Drachenvierecks. Seine beiden Holzstäbe bilden die Diagonalen: Der Längsstab ist 90 cm lang, der Querstab 60 cm.\n\nWie groß ist die Fläche des Drachens?',
  afb: 'II', afbGrund: 'Anwenden im Sachkontext: Holzstäbe als Diagonalen erkennen.',
  sach: true, prozess: 'Modellieren, Operieren', antwort: '2700', r: '90*60/2',
  weg: 'Die Stäbe sind die Diagonalen: e = 90 cm, f = 60 cm.\nA = 90 cm · 60 cm : 2 = 5400 cm² : 2 = 2700 cm².',
  ke: [
    ['5400', 'halbieren_vergessen', '90*60', 'Nicht halbiert: 90 · 60 = 5400 ist das Rechteck um den Drachen.', 'Füllt der Drachen das Rechteck aus Längsstab und Querstab ganz aus?'],
    ['150', 'plus_statt_mal', '90+60', 'Die Stablängen addiert: 90 + 60 = 150.', 'Kommt bei einer Summe von Längen eine Fläche heraus?'],
  ] });
def({ ...DR, ref: 'flaeche-raute-06', titel: 'Raute · Sachkontext · vierzig Fliesen', einheit: 'cm²',
  frage: 'Eine Wand wird mit 40 rautenförmigen Fliesen belegt. Jede Fliese hat die Diagonalen 20 cm und 12 cm. Die Fliesen liegen ohne Fugen aneinander.\n\nWie groß ist die belegte Fläche insgesamt?',
  afb: 'II', afbGrund: 'Anwenden im Sachkontext: Rautenfläche, dann mit der Anzahl malnehmen.',
  sach: true, prozess: 'Modellieren, Operieren', antwort: '4800', r: '40*20*12/2',
  weg: 'Eine Fliese: A = 20 cm · 12 cm : 2 = 120 cm².\n40 Fliesen: 40 · 120 cm² = 4800 cm².',
  ke: [
    ['9600', 'halbieren_vergessen', '40*20*12', 'Nicht halbiert: 20 · 12 = 240 je Fliese, 40 · 240 = 9600.', 'Ist eine Fliese so groß wie das Rechteck aus ihren beiden Diagonalen?'],
    ['1280', 'plus_statt_mal', '40*(20+12)', 'Die Diagonalen addiert: 20 + 12 = 32 je Fliese, 40 · 32 = 1280.', 'Kommt bei einer Summe von Längen eine Fläche heraus?'],
  ] });

// ─── geo_flaeche_zusammengesetzt (Tiefe 6) ───────────────────────────────────
// Nur Zusammensetzungen, die als Text eindeutig sind (Lage + alle Masse).
const ZU = { skill: 'geo_flaeche_zusammengesetzt' };
def({ ...ZU, ref: 'flaeche-zus-01', titel: 'Haus-Form · Rechteck mit aufgesetztem Dreieck', einheit: 'cm²',
  frage: 'Eine Figur besteht aus einem Rechteck mit der Länge 8 cm und der Breite 5 cm. Auf die obere, 8 cm lange Rechteckseite ist ein Dreieck aufgesetzt: Seine Grundseite ist genau diese Rechteckseite, seine Höhe beträgt 3 cm.\n\nWie groß ist der Flächeninhalt der ganzen Figur?',
  afb: 'I', afbGrund: 'Reproduzieren: zwei bekannte Teilflächen addieren.',
  sach: false, prozess: 'Operieren', antwort: '52', r: '8*5+8*3/2',
  weg: 'Rechteck: 8 cm · 5 cm = 40 cm².\nDreieck: 8 cm · 3 cm : 2 = 12 cm².\nGanze Figur: 40 cm² + 12 cm² = 52 cm².',
  ke: [
    ['40', 'teilflaeche_vergessen', '8*5', 'Nur das Rechteck berechnet, das Dreieck fehlt.', 'Gehört das aufgesetzte Dreieck zur Figur dazu?'],
    ['12', 'teilflaeche_vergessen', '8*3/2', 'Nur das Dreieck berechnet, das Rechteck fehlt.', 'Aus welchen Teilen besteht die ganze Figur?'],
    ['64', 'halbieren_vergessen', '8*5+8*3', 'Das Dreieck nicht halbiert: 40 + 24 = 64.', 'Ist das Dreieck so groß wie ein Rechteck mit 8 cm und 3 cm?'],
  ] });
def({ ...ZU, ref: 'flaeche-zus-02', titel: 'L-Form · Rechteck mit ausgeschnittener Ecke', einheit: 'cm²',
  frage: 'Aus einem Rechteck mit der Länge 10 cm und der Breite 8 cm wird an einer Ecke ein kleineres Rechteck mit den Seiten 4 cm und 3 cm herausgeschnitten. Übrig bleibt eine L-förmige Figur.\n\nWie groß ist ihr Flächeninhalt?',
  afb: 'I', afbGrund: 'Reproduzieren: große Rechteckfläche minus kleine Rechteckfläche.',
  sach: false, prozess: 'Operieren', antwort: '68', r: '10*8-4*3',
  weg: 'Großes Rechteck: 10 cm · 8 cm = 80 cm².\nAusschnitt: 4 cm · 3 cm = 12 cm².\nL-Form: 80 cm² - 12 cm² = 68 cm².',
  ke: [
    ['80', 'teilflaeche_vergessen', '10*8', 'Den Ausschnitt nicht abgezogen: nur das große Rechteck.', 'Was passiert mit der Fläche, wenn eine Ecke herausgeschnitten wird?'],
    ['36', 'umfang_statt_flaeche', '2*(10+8)', 'Den Umfang berechnet: 2 · (10 + 8) = 36.', 'Ist nach der Randlänge oder nach der Fläche gefragt?'],
  ] });
def({ ...ZU, ref: 'flaeche-zus-03', titel: 'Rechteck mit angesetztem Trapez', einheit: 'cm²',
  frage: 'Eine Figur besteht aus einem Rechteck und einem Trapez. Das Rechteck ist 6 cm lang und 4 cm breit. An eine 6 cm lange Rechteckseite ist ein Trapez so angesetzt, dass diese Seite seine längere parallele Seite ist. Die kürzere parallele Seite des Trapezes ist 2 cm lang, seine Höhe beträgt 3 cm.\n\nWie groß ist der Flächeninhalt der ganzen Figur?',
  afb: 'II', afbGrund: 'Anwenden: Zerlegung in Rechteck und Trapez, Trapezformel als Teilschritt.',
  sach: false, prozess: 'Operieren', antwort: '36', r: '6*4+(6+2)/2*3',
  weg: 'Rechteck: 6 cm · 4 cm = 24 cm².\nTrapez: (6 cm + 2 cm) : 2 · 3 cm = 12 cm².\nGanze Figur: 24 cm² + 12 cm² = 36 cm².',
  ke: [
    ['24', 'teilflaeche_vergessen', '6*4', 'Nur das Rechteck berechnet, das Trapez fehlt.', 'Gehört das angesetzte Trapez zur Figur dazu?'],
    ['12', 'teilflaeche_vergessen', '(6+2)/2*3', 'Nur das Trapez berechnet, das Rechteck fehlt.', 'Aus welchen Teilen besteht die ganze Figur?'],
    ['42', 'nur_eine_grundseite', '6*4+6*3', 'Beim Trapez nur die längere Seite genommen: 24 + 18 = 42.', 'Welche beiden Seiten des Trapezes sind parallel?'],
    ['30', 'nur_eine_grundseite', '6*4+2*3', 'Beim Trapez nur die kürzere Seite genommen: 24 + 6 = 30.', 'Welche beiden Seiten des Trapezes sind parallel?'],
    ['48', 'halbieren_vergessen', '6*4+(6+2)*3', 'Beim Trapez nicht halbiert: 24 + 24 = 48.', 'Wie viel ist der Mittelwert von 6 cm und 2 cm?'],
  ] });
def({ ...ZU, ref: 'flaeche-zus-04', titel: 'Quadrat mit ausgeschnittener Raute', einheit: 'cm²',
  frage: 'Aus einer quadratischen Platte mit der Seitenlänge 10 cm wird in der Mitte eine Raute ausgeschnitten. Die Diagonalen der Raute sind 6 cm und 4 cm lang.\n\nWie groß ist der Flächeninhalt der Platte nach dem Ausschneiden?',
  afb: 'II', afbGrund: 'Anwenden: Quadrat minus Raute, Rautenformel als Teilschritt.',
  sach: false, prozess: 'Operieren', antwort: '88', r: '10*10-6*4/2',
  weg: 'Quadrat: 10 cm · 10 cm = 100 cm².\nRaute: 6 cm · 4 cm : 2 = 12 cm².\nRest: 100 cm² - 12 cm² = 88 cm².',
  ke: [
    ['100', 'teilflaeche_vergessen', '10*10', 'Die Raute nicht abgezogen: nur das Quadrat.', 'Was passiert mit der Fläche der Platte, wenn ein Stück herausgeschnitten wird?'],
    ['76', 'halbieren_vergessen', '10*10-6*4', 'Die Raute nicht halbiert: 100 - 24 = 76.', 'Ist die Raute so groß wie das Rechteck aus ihren Diagonalen?'],
    ['12', 'falsche_groesse_beantwortet', '6*4/2', 'Die Fläche des Ausschnitts angegeben statt der Restfläche.', 'Ist nach dem Loch oder nach der übrigen Platte gefragt?'],
  ] });
def({ ...ZU, ref: 'flaeche-zus-05', titel: 'Sachkontext · Rasen um ein dreieckiges Beet', einheit: 'm²',
  frage: 'Ein rechteckiger Garten ist 12 m lang und 9 m breit. Darin liegt ein dreieckiges Beet mit der Grundseite 4 m und der zugehörigen Höhe 3 m. Der Rest des Gartens ist Rasen.\n\nWie groß ist die Rasenfläche?',
  afb: 'II', afbGrund: 'Anwenden im Sachkontext: Rasen als Rechteck minus Dreieck erkennen.',
  sach: true, prozess: 'Modellieren, Operieren', antwort: '102', r: '12*9-4*3/2',
  weg: 'Garten: 12 m · 9 m = 108 m².\nBeet: 4 m · 3 m : 2 = 6 m².\nRasen: 108 m² - 6 m² = 102 m².',
  ke: [
    ['108', 'teilflaeche_vergessen', '12*9', 'Das Beet nicht abgezogen: der ganze Garten.', 'Ist das Beet auch Rasen?'],
    ['96', 'halbieren_vergessen', '12*9-4*3', 'Das Dreieck nicht halbiert: 108 - 12 = 96.', 'Ist das Beet so groß wie ein Rechteck mit 4 m und 3 m?'],
    ['42', 'umfang_statt_flaeche', '2*(12+9)', 'Den Umfang des Gartens berechnet: 2 · (12 + 9) = 42.', 'Ist nach dem Zaun oder nach der Rasenfläche gefragt?'],
  ] });
def({ ...ZU, ref: 'flaeche-zus-06', titel: 'Sachkontext · Giebelwand mit Fenster', einheit: 'm²',
  frage: 'Die Giebelwand eines Hauses besteht aus einem Rechteck, das 9 m breit und 6 m hoch ist, und einem darauf sitzenden Dreieck mit der Grundseite 9 m und der Höhe 4 m. In der Wand ist ein rechteckiges Fenster, 1,5 m breit und 1,2 m hoch. Das Fenster wird nicht gestrichen.\n\nWie viele Quadratmeter Wandfläche müssen gestrichen werden?',
  afb: 'III', afbGrund: 'Problemlösen: drei Teilflächen, zwei addieren und eine abziehen, mit Dezimalzahlen.',
  sach: true, prozess: 'Problemlösen, Modellieren', antwort: '70,2', r: '9*6+9*4/2-1.5*1.2',
  weg: 'Rechteck: 9 m · 6 m = 54 m².\nDreieck: 9 m · 4 m : 2 = 18 m².\nFenster: 1,5 m · 1,2 m = 1,8 m².\nZu streichen: 54 m² + 18 m² - 1,8 m² = 70,2 m².',
  ke: [
    ['72', 'teilflaeche_vergessen', '9*6+9*4/2', 'Das Fenster nicht abgezogen: 54 + 18 = 72.', 'Wird das Fenster mitgestrichen?'],
    ['52,2', 'teilflaeche_vergessen', '9*6-1.5*1.2', 'Das Dreieck oben vergessen: 54 - 1,8 = 52,2.', 'Aus welchen Teilen besteht die Giebelwand?'],
    ['88,2', 'halbieren_vergessen', '9*6+9*4-1.5*1.2', 'Das Dreieck nicht halbiert: 54 + 36 - 1,8 = 88,2.', 'Ist das Giebeldreieck so groß wie ein Rechteck mit 9 m und 4 m?'],
  ] });
