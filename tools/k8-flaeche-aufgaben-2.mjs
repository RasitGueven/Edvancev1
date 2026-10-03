/**
 * k8-flaeche-aufgaben-2.mjs — Aufgaben des Laufs K8 Flaechen, Teil 2:
 * geo_flaeche_term und geo_flaeche_rueck. Felder wie in tools/k8-flaeche-aufgaben.mjs.
 *
 * MC-Aufgaben (Terme fuer Flaecheninhalte) tragen statt antwort/r/ke:
 *   mc: true, term (Flaechenterm aus der Geometrie, in x),
 *   options: [id, label, slug|null, Fehlerterm|null, Fehlertext|null, sokratische Frage|null]
 * Das Charge-Skript prueft: genau die richtige Option ist gleichwertig zu term, jede
 * Option mit Slug ist gleichwertig zu ihrem Fehlerterm, keine zwei Optionen gleichwertig.
 * Kein TERM-Format: dort sind keine known_errors moeglich (phase1 c).
 */

export const A = [];
const def = (o) => A.push(o);

// ─── geo_flaeche_term (Tiefe 6) ──────────────────────────────────────────────
// Steigerung: Term ohne Klammer -> Klammer -> Dreieck mit Klammer -> zusammengesetzt
// -> Term aufstellen und auswerten (Sachkontext).
const TE = { skill: 'geo_flaeche_term' };
const WT = 'Welcher Term beschreibt seinen Flächeninhalt in cm²?';
def({ ...TE, mc: true, ref: 'flaeche-term-01', titel: 'Term · Rechteck x mal 5',
  frage: `Ein Rechteck ist x cm lang und 5 cm breit.\n\n${WT}`,
  afb: 'I', afbGrund: 'Reproduzieren: Rechteckformel mit einer Variablen als Seitenlänge.',
  sach: false, prozess: 'Darstellen, Operieren', term: 'x*5',
  weg: 'A = Länge · Breite = x · 5 = 5x.',
  options: [
    ['a', 'x + 5', 'plus_statt_mal', 'x+5', 'Länge und Breite addiert statt multipliziert.', 'Rechnest du beim Rechteck die Seiten zusammen oder malgenommen?'],
    ['b', '5x', null, null, null, null],
    ['c', '2x + 10', 'umfang_statt_flaeche', '2*(x+5)', 'Den Umfang beschrieben: 2 · (x + 5).', 'Beschreibt dein Term die Randlänge oder die Fläche?'],
    ['d', 'x²', null, null, null, null],
  ] });
def({ ...TE, mc: true, ref: 'flaeche-term-02', titel: 'Term · Rechteck (x + 3) mal 4',
  frage: `Ein Rechteck ist (x + 3) cm lang und 4 cm breit.\n\n${WT}`,
  afb: 'I', afbGrund: 'Reproduzieren: Rechteckformel, die Summe als Seitenlänge muss als Ganzes multipliziert werden.',
  sach: false, prozess: 'Darstellen, Operieren', term: '4*(x+3)',
  weg: 'A = 4 · (x + 3) = 4x + 12.',
  options: [
    ['a', '4x + 3', 'klammer_vergessen', '4*x+3', 'Ohne Klammer gerechnet: nur x mit 4 multipliziert.', 'Ist die ganze Länge x + 3 mit der Breite malzunehmen oder nur das x?'],
    ['b', 'x + 7', 'plus_statt_mal', 'x+3+4', 'Länge und Breite addiert: x + 3 + 4.', 'Rechnest du beim Rechteck die Seiten zusammen oder malgenommen?'],
    ['c', '4x + 12', null, null, null, null],
    ['d', '2x + 14', 'umfang_statt_flaeche', '2*(x+3)+2*4', 'Den Umfang beschrieben: 2 · (x + 3) + 2 · 4.', 'Beschreibt dein Term die Randlänge oder die Fläche?'],
  ] });
def({ ...TE, mc: true, ref: 'flaeche-term-03', titel: 'Term · Dreieck mit Grundseite x + 4',
  frage: `Ein Dreieck hat die Grundseite (x + 4) cm und die zugehörige Höhe 6 cm.\n\n${WT}`,
  afb: 'II', afbGrund: 'Anwenden: Dreiecksformel mit Summe als Grundseite, halbieren und ausmultiplizieren.',
  sach: false, prozess: 'Darstellen, Operieren', term: '(x+4)*6/2',
  weg: 'A = g · h : 2 = (x + 4) · 6 : 2 = 3 · (x + 4) = 3x + 12.',
  options: [
    ['a', '6x + 24', 'halbieren_vergessen', '(x+4)*6', 'Nicht halbiert: (x + 4) · 6.', 'Ist ein Dreieck so groß wie das Rechteck aus Grundseite und Höhe?'],
    ['b', '3x + 12', null, null, null, null],
    ['c', '3x + 4', 'klammer_vergessen', 'x*6/2+4', 'Ohne Klammer gerechnet: nur x mit 6 multipliziert und halbiert.', 'Ist die ganze Grundseite x + 4 mit der Höhe malzunehmen oder nur das x?'],
    ['d', 'x + 10', 'plus_statt_mal', 'x+4+6', 'Grundseite und Höhe addiert: x + 4 + 6.', 'Rechnest du Grundseite und Höhe zusammen oder malgenommen?'],
  ] });
def({ ...TE, mc: true, ref: 'flaeche-term-04', titel: 'Term · Rechteck mit angesetztem Quadrat',
  frage: 'Eine Figur besteht aus einem Rechteck und einem Quadrat. Das Rechteck ist x cm lang und 4 cm breit. An eine 4 cm lange Seite des Rechtecks ist ein Quadrat mit der Seitenlänge 4 cm angesetzt.\n\nWelcher Term beschreibt den Flächeninhalt der ganzen Figur in cm²?',
  afb: 'II', afbGrund: 'Anwenden: Teilflächen als Terme aufstellen und zusammenfassen.',
  sach: false, prozess: 'Darstellen, Operieren', term: 'x*4+4*4',
  weg: 'Rechteck: x · 4 = 4x.\nQuadrat: 4 · 4 = 16.\nGanze Figur: 4x + 16.',
  options: [
    ['a', '4x', 'teilflaeche_vergessen', 'x*4', 'Nur das Rechteck beschrieben, das Quadrat fehlt.', 'Gehört das angesetzte Quadrat zur Figur dazu?'],
    ['b', '4x + 8', null, null, null, null],
    ['c', '4x + 16', null, null, null, null],
    ['d', '8x', null, null, null, null],
  ] });
const UNIT_X = 'Stelle einen Term für';
def({ ...TE, ref: 'flaeche-term-05', titel: 'Term · Sachkontext · Terrasse 3 m länger als breit', einheit: 'm²',
  frage: `Eine rechteckige Terrasse ist 3 m länger als breit. Ihre Breite beträgt x m.\n\n${UNIT_X} ihren Flächeninhalt auf und berechne den Flächeninhalt für x = 4.`,
  afb: 'II', afbGrund: 'Anwenden im Sachkontext: Länge als x + 3 erkennen, Term aufstellen und auswerten.',
  sach: true, prozess: 'Modellieren, Operieren', antwort: '28', r: '(4+3)*4',
  weg: 'Länge: x + 3, Breite: x.\nA = (x + 3) · x.\nFür x = 4: A = 7 · 4 = 28, also 28 m².',
  ke: [
    ['16', 'klammer_vergessen', '4+3*4', 'Ohne Klammer gerechnet: x + 3 · x = 4 + 12 = 16.', 'Wird die ganze Länge x + 3 mit der Breite malgenommen?'],
    ['11', 'plus_statt_mal', '(4+3)+4', 'Länge und Breite addiert: 7 + 4 = 11.', 'Rechnest du beim Rechteck die Seiten zusammen oder malgenommen?'],
    ['22', 'umfang_statt_flaeche', '2*((4+3)+4)', 'Den Umfang berechnet: 2 · (7 + 4) = 22.', 'Ist nach dem Rand der Terrasse oder nach ihrer Fläche gefragt?'],
  ] });
def({ ...TE, ref: 'flaeche-term-06', titel: 'Term · Sachkontext · Beet doppelt so lang wie breit', einheit: 'm²',
  frage: `Ein rechteckiges Beet ist doppelt so lang wie breit. Seine Breite beträgt x m.\n\n${UNIT_X} den Flächeninhalt des Beetes auf und berechne ihn für x = 3,5.`,
  afb: 'II', afbGrund: 'Anwenden im Sachkontext: Länge als 2x erkennen, Term 2x · x mit Dezimalzahl auswerten.',
  sach: true, prozess: 'Modellieren, Operieren', antwort: '24,5', r: '2*3.5*3.5',
  weg: 'Länge: 2x, Breite: x.\nA = 2x · x = 2x².\nFür x = 3,5: A = 2 · 3,5 · 3,5 = 7 · 3,5 = 24,5, also 24,5 m².',
  ke: [
    ['10,5', 'plus_statt_mal', '2*3.5+3.5', 'Länge und Breite addiert: 7 + 3,5 = 10,5.', 'Rechnest du beim Rechteck die Seiten zusammen oder malgenommen?'],
    ['21', 'umfang_statt_flaeche', '2*(2*3.5+3.5)', 'Den Umfang berechnet: 2 · (7 + 3,5) = 21.', 'Ist nach dem Rand des Beetes oder nach seiner Fläche gefragt?'],
  ] });

// ─── geo_flaeche_rueck (Tiefe 6) ─────────────────────────────────────────────
// Rueckrichtung: Parallelogramm, Dreieck, Trapez (Hoehe, dann fehlende Seite), zwei Sachkontexte.
const RU = { skill: 'geo_flaeche_rueck' };
def({ ...RU, ref: 'flaeche-rueck-01', titel: 'Rückrichtung · Höhe im Parallelogramm', einheit: 'cm',
  frage: 'Ein Parallelogramm hat den Flächeninhalt 42 cm² und die Grundseite g = 7 cm.\n\nWie lang ist die zugehörige Höhe h?',
  afb: 'I', afbGrund: 'Reproduzieren: A = g · h nach h umstellen, eine Division.',
  sach: false, prozess: 'Operieren', antwort: '6', r: '42/7',
  weg: 'A = g · h, also h = A : g = 42 cm² : 7 cm = 6 cm.',
  ke: [
    ['294', 'falsche_gegenoperation', '42*7', 'Multipliziert statt geteilt: 42 · 7 = 294.', 'Welche Rechnung macht das „mal g“ aus der Formel rückgängig?'],
    ['12', 'halbieren_faelschlich', '2*42/7', 'Mit der Dreiecksformel gerechnet: h = 2 · 42 : 7 = 12.', 'Wird beim Parallelogramm halbiert?'],
  ] });
def({ ...RU, ref: 'flaeche-rueck-02', titel: 'Rückrichtung · Höhe im Dreieck', einheit: 'cm',
  frage: 'Ein Dreieck hat den Flächeninhalt 30 cm² und die Grundseite g = 12 cm.\n\nWie lang ist die zugehörige Höhe h?',
  afb: 'I', afbGrund: 'Reproduzieren: A = g · h : 2 nach h umstellen.',
  sach: false, prozess: 'Operieren', antwort: '5', r: '2*30/12',
  weg: 'A = g · h : 2, also h = 2 · A : g = 2 · 30 cm² : 12 cm = 60 cm² : 12 cm = 5 cm.',
  ke: [
    ['2,5', 'halbieren_vergessen', '30/12', 'Das Halbieren beim Umstellen vergessen: 30 : 12 = 2,5.', 'Wie groß wäre die Fläche mit h = 2,5 cm wirklich?'],
    ['180', 'falsche_gegenoperation', '30*12/2', 'Die Formel vorwärts angewendet statt umgestellt: 30 · 12 : 2 = 180.', 'Welche Rechnung macht das „mal g“ aus der Formel rückgängig?'],
  ] });
def({ ...RU, ref: 'flaeche-rueck-03', titel: 'Rückrichtung · Höhe im Trapez', einheit: 'cm',
  frage: 'Ein Trapez hat den Flächeninhalt 63 cm² und die parallelen Seiten a = 12 cm und c = 6 cm.\n\nWie groß ist seine Höhe h?',
  afb: 'II', afbGrund: 'Anwenden: Trapezformel umstellen, Mittelwert der parallelen Seiten bilden.',
  sach: false, prozess: 'Operieren', antwort: '7', r: '63/((12+6)/2)',
  weg: 'A = (a + c) : 2 · h, also h = A : ((a + c) : 2).\n(12 cm + 6 cm) : 2 = 9 cm.\nh = 63 cm² : 9 cm = 7 cm.',
  ke: [
    ['10,5', 'nur_eine_grundseite', '63/12*2', 'Nur mit der Seite a gerechnet: 2 · 63 : 12 = 10,5.', 'Kommen beide parallelen Seiten in deiner Rechnung vor?'],
    ['21', 'nur_eine_grundseite', '63/6*2', 'Nur mit der Seite c gerechnet: 2 · 63 : 6 = 21.', 'Kommen beide parallelen Seiten in deiner Rechnung vor?'],
    ['3,5', 'halbieren_vergessen', '63/(12+6)', 'Durch die Summe statt durch den Mittelwert geteilt: 63 : 18 = 3,5.', 'Wie groß wäre die Fläche mit h = 3,5 cm wirklich?'],
  ] });
def({ ...RU, ref: 'flaeche-rueck-04', titel: 'Rückrichtung · fehlende parallele Seite im Trapez', einheit: 'cm',
  frage: 'Ein Trapez hat den Flächeninhalt 40 cm². Die parallele Seite a ist 9 cm lang, die Höhe beträgt h = 5 cm.\n\nWie lang ist die andere parallele Seite c?',
  afb: 'II', afbGrund: 'Anwenden: Trapezformel in zwei Schritten umstellen (Summe a + c, dann c).',
  sach: false, prozess: 'Problemlösen, Operieren', antwort: '7', r: '2*40/5-9',
  weg: 'A = (a + c) : 2 · h, also a + c = 2 · A : h = 2 · 40 cm² : 5 cm = 16 cm.\nc = 16 cm - 9 cm = 7 cm.',
  ke: [
    ['8', 'nur_eine_grundseite', '40/5', 'Gerechnet, als gäbe es nur eine parallele Seite: 40 : 5 = 8.', 'Welche Rolle spielt die Seite a in der Trapezformel?'],
    ['16', 'falsche_groesse_beantwortet', '2*40/5', 'Die Summe a + c angegeben statt der Seite c.', 'Ist nach a + c oder nach c allein gefragt?'],
  ] });
def({ ...RU, ref: 'flaeche-rueck-05', titel: 'Rückrichtung · Sachkontext · Beet als Parallelogramm', einheit: 'm',
  frage: 'Ein Beet hat die Form eines Parallelogramms und ist 18 m² groß. Eine Seite des Beetes ist 4,5 m lang.\n\nWie groß ist die Höhe des Beetes zu dieser Seite?',
  afb: 'II', afbGrund: 'Anwenden im Sachkontext: Parallelogrammformel umstellen, Division durch eine Dezimalzahl.',
  sach: true, prozess: 'Modellieren, Operieren', antwort: '4', r: '18/4.5',
  weg: 'A = g · h mit g = 4,5 m, also h = 18 m² : 4,5 m = 4 m.',
  ke: [
    ['81', 'falsche_gegenoperation', '18*4.5', 'Multipliziert statt geteilt: 18 · 4,5 = 81.', 'Welche Rechnung macht das „mal g“ aus der Formel rückgängig?'],
    ['8', 'halbieren_faelschlich', '2*18/4.5', 'Mit der Dreiecksformel gerechnet: 2 · 18 : 4,5 = 8.', 'Wird beim Parallelogramm halbiert?'],
  ] });
def({ ...RU, ref: 'flaeche-rueck-06', titel: 'Rückrichtung · Sachkontext · dreieckiges Segel', einheit: 'm',
  frage: 'Ein dreieckiges Segel hat den Flächeninhalt 7,5 m². Seine untere Kante ist 3 m lang.\n\nWie lang ist die Höhe des Segels zu dieser Kante?',
  afb: 'II', afbGrund: 'Anwenden im Sachkontext: Dreiecksformel umstellen, Dezimalfläche.',
  sach: true, prozess: 'Modellieren, Operieren', antwort: '5', r: '2*7.5/3',
  weg: 'A = g · h : 2 mit g = 3 m, also h = 2 · 7,5 m² : 3 m = 15 m² : 3 m = 5 m.',
  ke: [
    ['2,5', 'halbieren_vergessen', '7.5/3', 'Das Halbieren beim Umstellen vergessen: 7,5 : 3 = 2,5.', 'Wie groß wäre das Segel mit h = 2,5 m wirklich?'],
    ['11,25', 'falsche_gegenoperation', '7.5*3/2', 'Die Formel vorwärts angewendet statt umgestellt: 7,5 · 3 : 2 = 11,25.', 'Welche Rechnung macht das „mal g“ aus der Formel rückgängig?'],
  ] });
