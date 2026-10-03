#!/usr/bin/env node
/**
 * k9-koerper-charge.mjs — erzeugt docs/prefill/k9-koerper.json (Charge-Format von vorlauf-build.mjs)
 * fuer das Thema "Koerper" des Laufs K9-Rest (Prisma, Zylinder, Pyramide, Kegel, Kugel; KLP Geo-5).
 *
 *   node tools/k9-koerper-charge.mjs
 *
 * Alles als Text mit allen Massen, keine Abbildung. Jeder Wert ist ein Ausdruck, den
 * tools/k9-rest-lib.mjs exakt nachrechnet (bei π-Aufgaben zweimal: π-Taste und 3,14).
 * Die ids stehen in docs/prefill/k9-koerper-ids.json: ein zweiter Lauf erzeugt dieselbe Charge.
 */

import { baueCharge, CLUSTER, SATZ_PI } from './k9-rest-lib.mjs';

const SATZ_2 = `${SATZ_PI} Runde das Ergebnis auf zwei Stellen nach dem Komma.`;
const SATZ_1 = `${SATZ_PI} Runde das Ergebnis auf eine Stelle nach dem Komma.`;
const GENAU = 'Gib das Ergebnis genau an, ohne zu runden.';
const NOETIG = 'Runde, falls nötig, auf zwei Stellen nach dem Komma.';

const BASIS = {
  cluster: CLUSTER.geo, inhalt: 'geometrie', stoff: 9,
  stoffGrund: 'Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Geo-5 (Oberfläche und Volumen von Prisma, Zylinder, Pyramide, Kegel, Kugel).',
  clusterGrund: 'Geometrie & Messen wie geo_volumen_quader und geo_kreis_* im Bestand.',
  inhaltGrund: 'Inhaltsfeld Geometrie (Geo-5).',
};
const A = [];
const def = (o) => A.push({ ...BASIS, ...o });

// ─── geo_koerper_prisma (Tiefe 5) ─── ohne π
const PR = { skill: 'geo_koerper_prisma' };
def({ ...PR, ref: 'koerper-prisma-01', titel: 'Prisma · Volumen eines Dreiecksprismas', einheit: 'cm³', afb: 'I', sach: false, n: 'exakt',
  afbGrund: 'Reproduzieren: Dreiecksfläche als Grundfläche, dann V = G · h.',
  frage: `Ein gerades Prisma hat als Grundfläche ein Dreieck. Die Grundseite des Dreiecks ist 6 cm lang, die zugehörige Höhe des Dreiecks beträgt 4 cm. Das Prisma ist 10 cm hoch.\n\nWie groß ist das Volumen des Prismas? ${GENAU}`,
  r: '1/2*6*4*10',
  weg: 'Grundfläche: G = ½ · 6 cm · 4 cm = 12 cm².\nV = G · h = 12 cm² · 10 cm = {A} cm³.',
  ke: [['halbieren_vergessen', '6*4*10', 'Bei der Dreiecksfläche das ½ vergessen: 6 · 4 · 10 = 240.', 'Wie berechnest du den Flächeninhalt eines Dreiecks?'],
    ['falsche_groesse_beantwortet', '1/2*6*4', 'Nur die Grundfläche berechnet, nicht das Volumen.', 'Hast du die Höhe des Prismas schon verwendet?']] });
def({ ...PR, ref: 'koerper-prisma-02', titel: 'Prisma · Oberfläche eines Dreiecksprismas', einheit: 'cm²', afb: 'I', sach: false, n: 'exakt',
  afbGrund: 'Reproduzieren: O = 2 · G + Mantel mit gegebenen Dreiecksseiten.',
  frage: `Ein gerades Prisma hat als Grundfläche ein rechtwinkliges Dreieck mit den Seiten 3 cm, 4 cm und 5 cm. Der rechte Winkel liegt zwischen den Seiten 3 cm und 4 cm. Das Prisma ist 8 cm hoch.\n\nWie groß ist die Oberfläche des Prismas? ${GENAU}`,
  r: '2*(1/2*3*4)+(3+4+5)*8',
  weg: 'Grundfläche: G = ½ · 3 cm · 4 cm = 6 cm².\nMantel: M = Umfang · Höhe = (3 + 4 + 5) cm · 8 cm = 96 cm².\nO = 2 · G + M = 12 cm² + 96 cm² = {A} cm².',
  ke: [['mal_zwei_vergessen', '1/2*3*4+(3+4+5)*8', 'Nur eine Grundfläche gezählt: 6 + 96 = 102.', 'Wie viele Dreiecksflächen hat das Prisma?'],
    ['halbieren_vergessen', '2*(3*4)+(3+4+5)*8', 'Bei der Dreiecksfläche das ½ vergessen: 2 · 12 + 96 = 120.', 'Ist das Dreieck mit den Katheten 3 cm und 4 cm wirklich 12 cm² groß?'],
    ['volumen_statt_oberflaeche', '1/2*3*4*8', 'Das Volumen berechnet statt der Oberfläche: 6 · 8 = 48.', 'Ist nach dem Rauminhalt oder nach der Fläche aller Seiten gefragt?']] });
def({ ...PR, ref: 'koerper-prisma-03', titel: 'Prisma · Volumen mit Trapez als Grundfläche', einheit: 'cm³', afb: 'II', sach: false, n: 'exakt',
  afbGrund: 'Anwenden: Grundfläche ist ein Trapez, erst die Fläche bestimmen, dann V = G · h.',
  frage: `Ein gerades Prisma hat als Grundfläche ein Trapez. Die parallelen Seiten des Trapezes sind 8 cm und 5 cm lang, ihr Abstand beträgt 4 cm. Das Prisma ist 12 cm hoch.\n\nWie groß ist das Volumen des Prismas? ${GENAU}`,
  r: '(8+5)/2*4*12',
  weg: 'Grundfläche: G = (8 cm + 5 cm) : 2 · 4 cm = 26 cm².\nV = G · h = 26 cm² · 12 cm = {A} cm³.',
  ke: [['halbieren_vergessen', '(8+5)*4*12', 'Bei der Trapezfläche das Halbieren vergessen: 13 · 4 · 12 = 624.', 'Wie lautet die Formel für den Flächeninhalt eines Trapezes?'],
    ['falsche_groesse_beantwortet', '(8+5)/2*4', 'Nur die Grundfläche berechnet, nicht das Volumen.', 'Hast du die Höhe des Prismas schon verwendet?']] });
def({ ...PR, ref: 'koerper-prisma-04', titel: 'Prisma · Höhe aus Volumen und Dreiecksgrundfläche', einheit: 'cm', afb: 'II', sach: false, n: 'exakt',
  afbGrund: 'Anwenden: V = G · h nach h umstellen, Grundfläche erst aus dem Dreieck bestimmen.',
  frage: `Ein gerades Prisma hat das Volumen 180 cm³. Seine Grundfläche ist ein Dreieck mit der Grundseite 8 cm und der zugehörigen Höhe 5 cm.\n\nWie hoch ist das Prisma? ${GENAU}`,
  r: '180/(1/2*8*5)',
  weg: 'Grundfläche: G = ½ · 8 cm · 5 cm = 20 cm².\nV = G · h, also h = V : G = 180 cm³ : 20 cm² = {A} cm.',
  ke: [['halbieren_vergessen', '180/(8*5)', 'Bei der Dreiecksfläche das ½ vergessen: 180 : 40 = 4,5.', 'Wie groß ist das Dreieck mit Grundseite 8 cm und Höhe 5 cm wirklich?'],
    ['multipliziert_statt_dividiert', '180*(1/2*8*5)', 'Volumen mit der Grundfläche multipliziert statt durch sie geteilt.', 'Kann ein Prisma mit 180 cm³ Volumen so hoch sein?']] });
def({ ...PR, ref: 'koerper-prisma-05', titel: 'Prisma · Wassertrog mit dreieckigem Querschnitt', einheit: 'l', afb: 'II', sach: true, n: 'exakt',
  afbGrund: 'Anwenden im Sachkontext: Trog als Dreiecksprisma erkennen, Einheiten angleichen und in Liter umrechnen.',
  frage: `Ein Wassertrog hat die Form eines liegenden Dreiecksprismas. Der Querschnitt ist ein Dreieck: oben 60 cm breit und 40 cm tief. Der Trog ist 2 m lang. Es gilt 1 dm³ = 1 l.\n\nWie viele Liter Wasser fasst der Trog, wenn er randvoll ist? ${GENAU}`,
  r: '1/2*6*4*20',
  weg: 'In Dezimeter umrechnen: 60 cm = 6 dm, 40 cm = 4 dm, 2 m = 20 dm.\nGrundfläche: G = ½ · 6 dm · 4 dm = 12 dm².\nV = G · Länge = 12 dm² · 20 dm = 240 dm³ = {A} l.',
  ke: [['halbieren_vergessen', '6*4*20', 'Bei der Dreiecksfläche das ½ vergessen: 24 · 20 = 480.', 'Ist der Querschnitt ein Rechteck oder ein Dreieck?'],
    ['liter_kubik_falsch', '1/2*60*40*200', 'In Kubikzentimetern gerechnet und die Zahl als Liter angegeben.', 'Wie viele Kubikzentimeter passen in einen Liter?'],
    ['einheit_uebersprungen', '1/2*60*40*2', 'Zentimeter und Meter gemischt, ohne umzurechnen.', 'Sind alle drei Maße in derselben Einheit?']] });
def({ ...PR, ref: 'koerper-prisma-06', titel: 'Prisma · Höhe aus der Oberfläche', einheit: 'cm', afb: 'III', sach: false, n: 'exakt',
  afbGrund: 'Problemlösen: Rückrichtung über die Oberfläche – Grundflächen abziehen, dann durch den Umfang teilen.',
  frage: `Ein gerades Prisma hat als Grundfläche ein rechtwinkliges Dreieck mit den Seiten 6 cm, 8 cm und 10 cm. Der rechte Winkel liegt zwischen den Seiten 6 cm und 8 cm. Die Oberfläche des Prismas beträgt 288 cm².\n\nWie hoch ist das Prisma? ${GENAU}`,
  r: '(288-2*(1/2*6*8))/(6+8+10)',
  weg: 'Grundfläche: G = ½ · 6 cm · 8 cm = 24 cm², zwei Grundflächen: 48 cm².\nMantel: M = 288 cm² − 48 cm² = 240 cm².\nM = Umfang · h mit Umfang 6 cm + 8 cm + 10 cm = 24 cm.\nh = 240 cm² : 24 cm = {A} cm.',
  ke: [['mal_zwei_vergessen', '(288-1/2*6*8)/(6+8+10)', 'Nur eine Grundfläche abgezogen: 264 : 24 = 11.', 'Wie viele Dreiecksflächen gehören zur Oberfläche?'],
    ['halbieren_vergessen', '(288-2*6*8)/(6+8+10)', 'Bei der Dreiecksfläche das ½ vergessen: (288 − 96) : 24 = 8.', 'Wie groß ist ein rechtwinkliges Dreieck mit den Katheten 6 cm und 8 cm?'],
    ['volumen_statt_oberflaeche', '288/(1/2*6*8)', 'Die Oberfläche wie ein Volumen durch die Grundfläche geteilt: 288 : 24 = 12.', 'Ist 288 cm² ein Volumen oder eine Fläche?']] });

// ─── geo_koerper_zylinder (Tiefe 7) ─── mit π
const ZY = { skill: 'geo_koerper_zylinder', pi: true, n: 2 };
def({ ...ZY, ref: 'koerper-zylinder-01', titel: 'Zylinder · Volumen, Radius 3 cm', einheit: 'cm³', afb: 'I', sach: false,
  afbGrund: 'Reproduzieren: Volumenformel mit gegebenem Radius und gegebener Höhe.',
  frage: `Ein Zylinder hat den Radius 3 cm und die Höhe 10 cm.\n\nWie groß ist sein Volumen? ${SATZ_2}`,
  r: 'P*3^2*10',
  weg: 'V = π · r² · h = π · 9 cm² · 10 cm = π · 90 cm³ ≈ {A} cm³ (π-Taste).\nMit π ≈ 3,14: V = 3,14 · 90 cm³ = {B} cm³.',
  ke: [['radius_durchmesser_verwechselt', 'P*6^2*10', 'Mit 6 cm statt 3 cm gerechnet, Radius und Durchmesser verwechselt: π · 6² · 10.', 'Ist 3 cm schon der Radius?'],
    ['pi_vergessen', '3^2*10', 'π weggelassen: 9 · 10 = 90.', 'Welcher Faktor gehört zur Kreisfläche?'],
    ['oberflaeche_statt_volumen', '2*P*3^2+2*P*3*10', 'Die Oberfläche berechnet statt des Volumens.', 'Ist nach dem Rauminhalt oder nach der Fläche gefragt?']] });
def({ ...ZY, ref: 'koerper-zylinder-02', titel: 'Zylinder · Oberfläche, Durchmesser 8 cm', einheit: 'cm²', afb: 'I', sach: false,
  afbGrund: 'Reproduzieren: Radius aus dem Durchmesser, dann O = 2 · G + M.',
  frage: `Ein Zylinder hat den Durchmesser 8 cm und die Höhe 5 cm.\n\nWie groß ist seine Oberfläche? ${SATZ_2}`,
  r: '2*P*4^2+2*P*4*5',
  weg: 'r = 8 cm : 2 = 4 cm.\nZwei Grundflächen: 2 · π · (4 cm)² = π · 32 cm².\nMantel: 2 · π · 4 cm · 5 cm = π · 40 cm².\nO = π · 72 cm² ≈ {A} cm² (π-Taste).\nMit π ≈ 3,14: O = 3,14 · 72 cm² = {B} cm².',
  ke: [['radius_durchmesser_verwechselt', '2*P*8^2+2*P*8*5', 'Den Durchmesser als Radius eingesetzt.', 'Ist 8 cm der Radius oder der Durchmesser?'],
    ['mal_zwei_vergessen', 'P*4^2+2*P*4*5', 'Nur eine Kreisfläche gezählt (Deckel oder Boden fehlt).', 'Wie viele Kreisflächen hat ein geschlossener Zylinder?'],
    ['volumen_statt_oberflaeche', 'P*4^2*5', 'Das Volumen berechnet statt der Oberfläche.', 'Kommt bei deiner Rechnung cm² oder cm³ heraus?']] });
def({ ...ZY, ref: 'koerper-zylinder-03', titel: 'Zylinder · Volumen, Radius 1,5 m', einheit: 'm³', afb: 'II', sach: false,
  afbGrund: 'Anwenden: Quadrat einer Dezimalzahl in der Volumenformel.',
  frage: `Ein Zylinder hat den Radius 1,5 m und die Höhe 3,2 m.\n\nWie groß ist sein Volumen in Kubikmetern? ${SATZ_2}`,
  r: 'P*1.5^2*3.2',
  weg: 'V = π · (1,5 m)² · 3,2 m = π · 2,25 m² · 3,2 m = π · 7,2 m³ ≈ {A} m³ (π-Taste).\nMit π ≈ 3,14: V = 3,14 · 7,2 m³ ≈ {B} m³.',
  ke: [['mal_exponent', 'P*2*1.5*3.2', '1,5² als 2 · 1,5 gerechnet: π · 3 · 3,2.', 'Was ist 1,5² – 1,5 · 2 oder 1,5 · 1,5?'],
    ['radius_durchmesser_verwechselt', 'P*0.75^2*3.2', 'Den Radius wie einen Durchmesser halbiert: π · 0,75² · 3,2.', 'Ist 1,5 m schon der Radius?'],
    ['pi_vergessen', '1.5^2*3.2', 'π weggelassen: 2,25 · 3,2 = 7,2.', 'Welcher Faktor gehört zur Kreisfläche?'],
    ['oberflaeche_statt_volumen', '2*P*1.5^2+2*P*1.5*3.2', 'Die Oberfläche berechnet statt des Volumens.', 'Ist nach dem Rauminhalt oder nach der Fläche gefragt?']] });
def({ ...ZY, ref: 'koerper-zylinder-04', titel: 'Zylinder · Oberfläche in m² bei gemischten Einheiten', einheit: 'm²', afb: 'II', sach: false,
  afbGrund: 'Anwenden: Oberflächenformel, vorher Zentimeter in Meter umrechnen.',
  frage: `Ein Zylinder hat den Radius 0,4 m und die Höhe 90 cm.\n\nWie groß ist seine Oberfläche in Quadratmetern? ${SATZ_2}`,
  r: '2*P*0.4^2+2*P*0.4*0.9',
  weg: 'h = 90 cm = 0,9 m.\nZwei Grundflächen: 2 · π · (0,4 m)² = π · 0,32 m².\nMantel: 2 · π · 0,4 m · 0,9 m = π · 0,72 m².\nO = π · 1,04 m² ≈ {A} m² (π-Taste).\nMit π ≈ 3,14: O = 3,14 · 1,04 m² ≈ {B} m².',
  ke: [['einheit_uebersprungen', '2*P*0.4^2+2*P*0.4*90', 'Die Höhe nicht in Meter umgerechnet: mit 90 statt 0,9 gerechnet.', 'Sind Radius und Höhe in derselben Einheit?'],
    ['mal_zwei_vergessen', 'P*0.4^2+2*P*0.4*0.9', 'Nur eine Kreisfläche gezählt (Deckel oder Boden fehlt).', 'Wie viele Kreisflächen hat ein geschlossener Zylinder?'],
    ['radius_durchmesser_verwechselt', '2*P*0.2^2+2*P*0.2*0.9', 'Den Radius wie einen Durchmesser halbiert.', 'Ist 0,4 m schon der Radius?']] });
def({ ...ZY, ref: 'koerper-zylinder-05', titel: 'Zylinder · Wassertank in Litern', einheit: 'l', afb: 'II', sach: true, n: 0,
  afbGrund: 'Anwenden im Sachkontext: Durchmesser halbieren, Volumen in m³ berechnen und in Liter umrechnen.',
  frage: `Ein zylinderförmiger Wassertank hat innen einen Durchmesser von 1,2 m und eine Höhe von 1,5 m. Es gilt 1 dm³ = 1 l, also 1 m³ = 1000 l.\n\nWie viele Liter fasst der Tank? ${SATZ_PI} Runde auf ganze Liter.`,
  r: 'P*0.6^2*1.5*1000',
  weg: 'r = 1,2 m : 2 = 0,6 m.\nV = π · (0,6 m)² · 1,5 m = π · 0,54 m³ ≈ 1,69646 m³ (π-Taste), mit 3,14: 1,6956 m³.\n1 m³ = 1000 l: V ≈ {A} l (π-Taste), mit π ≈ 3,14 ebenfalls ≈ {B} l.',
  ke: [['radius_durchmesser_verwechselt', 'P*1.2^2*1.5*1000', 'Den Durchmesser als Radius eingesetzt: π · 1,2² · 1,5.', 'Ist 1,2 m der Radius oder der Durchmesser des Tanks?'],
    ['liter_kubik_falsch', 'P*0.6^2*1.5', 'Den Wert in Kubikmetern als Liter angegeben.', 'Wie viele Liter passen in einen Kubikmeter?', 2],
    ['pi_vergessen', '0.6^2*1.5*1000', 'π weggelassen: 0,54 m³ = 540 l.', 'Welcher Faktor gehört zur Kreisfläche?']] });
def({ ...ZY, ref: 'koerper-zylinder-06', titel: 'Zylinder · Dosenhöhe für einen Liter', einheit: 'cm', afb: 'III', sach: true, n: 1,
  afbGrund: 'Problemlösen: Rückrichtung – Liter in cm³ umrechnen, Volumenformel nach h umstellen.',
  frage: `Eine zylinderförmige Dose soll genau 1 Liter fassen. Ihr Durchmesser innen beträgt 10 cm. Es gilt 1 l = 1 dm³ = 1000 cm³.\n\nWie hoch muss die Dose innen sein? ${SATZ_1}`,
  r: '1000/(P*5^2)',
  weg: 'V = 1 l = 1000 cm³, r = 10 cm : 2 = 5 cm.\nV = π · r² · h, also h = V : (π · r²) = 1000 cm³ : (π · 25 cm²) ≈ 12,73 cm, gerundet {A} cm (π-Taste).\nMit π ≈ 3,14: h = 1000 : 78,5 ≈ 12,74 cm, gerundet {B} cm.',
  ke: [['radius_durchmesser_verwechselt', '1000/(P*10^2)', 'Den Durchmesser als Radius eingesetzt: 1000 : (π · 100).', 'Ist 10 cm der Radius oder der Durchmesser?'],
    ['liter_kubik_falsch', '100/(P*5^2)', 'Mit 1 l = 100 cm³ gerechnet.', 'Wie viele Kubikzentimeter hat ein Liter?'],
    ['pi_vergessen', '1000/5^2', 'π weggelassen: 1000 : 25 = 40.', 'Welcher Faktor gehört zur Kreisfläche?']] });

// ─── geo_koerper_pyramide (Tiefe 6) ─── ohne π
const PY = { skill: 'geo_koerper_pyramide' };
def({ ...PY, ref: 'koerper-pyramide-01', titel: 'Pyramide · Volumen einer quadratischen Pyramide', einheit: 'cm³', afb: 'I', sach: false, n: 'exakt',
  afbGrund: 'Reproduzieren: V = ⅓ · G · h mit quadratischer Grundfläche.',
  frage: `Eine Pyramide hat eine quadratische Grundfläche mit der Seitenlänge 6 cm. Sie ist 10 cm hoch.\n\nWie groß ist ihr Volumen? ${GENAU}`,
  r: '1/3*6^2*10',
  weg: 'G = (6 cm)² = 36 cm².\nV = ⅓ · G · h = ⅓ · 36 cm² · 10 cm = {A} cm³.',
  ke: [['drittel_vergessen', '6^2*10', 'Den Faktor ⅓ vergessen: 36 · 10 = 360.', 'Wie viel von einem Prisma mit gleicher Grundfläche und Höhe füllt eine Pyramide?'],
    ['falsche_groesse_beantwortet', '6^2', 'Nur die Grundfläche berechnet, nicht das Volumen.', 'Hast du die Höhe der Pyramide schon verwendet?']] });
def({ ...PY, ref: 'koerper-pyramide-02', titel: 'Pyramide · Oberfläche mit Körperhöhe und Seitenhöhe', einheit: 'cm²', afb: 'I', sach: false, n: 'exakt',
  afbGrund: 'Reproduzieren: Grundfläche plus vier Dreiecke; die passende Höhe auswählen.',
  frage: `Eine Pyramide hat eine quadratische Grundfläche mit der Seitenlänge 8 cm. Die Pyramide ist 3 cm hoch. Jede dreieckige Seitenfläche hat die Höhe h_s = 5 cm.\n\nWie groß ist die Oberfläche der Pyramide? ${GENAU}`,
  r: '8^2+4*(1/2*8*5)',
  weg: 'Grundfläche: G = (8 cm)² = 64 cm².\nEine Seitenfläche: ½ · 8 cm · 5 cm = 20 cm², vier Seitenflächen: 80 cm².\nO = 64 cm² + 80 cm² = {A} cm².\n(Für die Dreiecke zählt die Seitenhöhe h_s, nicht die Körperhöhe.)',
  ke: [['falsche_hoehe', '8^2+4*(1/2*8*3)', 'Für die Seitenflächen die Körperhöhe 3 cm statt h_s = 5 cm verwendet.', 'Welche Höhe steht senkrecht auf der Grundseite eines Seitendreiecks?'],
    ['halbieren_vergessen', '8^2+4*(8*5)', 'Bei den Dreiecken das ½ vergessen: 64 + 160 = 224.', 'Wie berechnest du den Flächeninhalt eines Dreiecks?'],
    ['volumen_statt_oberflaeche', '1/3*8^2*3', 'Das Volumen berechnet statt der Oberfläche.', 'Ist nach dem Rauminhalt oder nach der Fläche aller Seiten gefragt?']] });
def({ ...PY, ref: 'koerper-pyramide-03', titel: 'Pyramide · Volumen mit rechteckiger Grundfläche', einheit: 'm³', afb: 'II', sach: false, n: 'exakt',
  afbGrund: 'Anwenden: rechteckige Grundfläche mit Dezimalzahlen, dann V = ⅓ · G · h.',
  frage: `Eine Pyramide hat eine rechteckige Grundfläche mit den Seiten 4,5 m und 3,2 m. Sie ist 5 m hoch.\n\nWie groß ist ihr Volumen in Kubikmetern? ${GENAU}`,
  r: '1/3*4.5*3.2*5',
  weg: 'G = 4,5 m · 3,2 m = 14,4 m².\nV = ⅓ · 14,4 m² · 5 m = ⅓ · 72 m³ = {A} m³.',
  ke: [['drittel_vergessen', '4.5*3.2*5', 'Den Faktor ⅓ vergessen: 14,4 · 5 = 72.', 'Wie viel von einem Quader mit gleicher Grundfläche und Höhe füllt eine Pyramide?'],
    ['falsche_groesse_beantwortet', '4.5*3.2', 'Nur die Grundfläche berechnet, nicht das Volumen.', 'Hast du die Höhe der Pyramide schon verwendet?']] });
def({ ...PY, ref: 'koerper-pyramide-04', titel: 'Pyramide · Oberfläche mit rechteckiger Grundfläche', einheit: 'cm²', afb: 'II', sach: false, n: 'exakt',
  afbGrund: 'Anwenden: zwei Sorten Seitendreiecke mit verschiedenen Seitenhöhen richtig zuordnen, dann Grundfläche plus Mantel.',
  frage: `Eine Pyramide hat eine rechteckige Grundfläche mit den Seiten 10 cm und 4 cm. Die beiden dreieckigen Seitenflächen über den 10-cm-Seiten haben jeweils die Höhe 10 cm. Die beiden dreieckigen Seitenflächen über den 4-cm-Seiten haben jeweils die Höhe 11 cm.\n\nWie groß ist die Oberfläche der Pyramide? ${GENAU}`,
  r: '10*4+2*(1/2*10*10)+2*(1/2*4*11)',
  weg: 'Grundfläche: G = 10 cm · 4 cm = 40 cm².\nZwei Dreiecke über den 10-cm-Seiten: 2 · ½ · 10 cm · 10 cm = 100 cm².\nZwei Dreiecke über den 4-cm-Seiten: 2 · ½ · 4 cm · 11 cm = 44 cm².\nO = 40 cm² + 100 cm² + 44 cm² = {A} cm².',
  ke: [['falsche_hoehe', '10*4+2*(1/2*10*11)+2*(1/2*4*10)', 'Die Seitenhöhen vertauscht: zur 10-cm-Seite die Höhe 11 cm genommen.', 'Welche Höhe gehört zu dem Dreieck über der 10-cm-Seite?'],
    ['halbieren_vergessen', '10*4+2*(10*10)+2*(4*11)', 'Bei den Dreiecken das ½ vergessen: 40 + 200 + 88 = 328.', 'Wie berechnest du den Flächeninhalt eines Dreiecks?'],
    ['falsche_groesse_beantwortet', '2*(1/2*10*10)+2*(1/2*4*11)', 'Nur die vier Seitenflächen berechnet, die Grundfläche fehlt.', 'Gehört die rechteckige Grundfläche zur Oberfläche?']] });
def({ ...PY, ref: 'koerper-pyramide-05', titel: 'Pyramide · Dachfläche eines Pyramidendachs', einheit: 'm²', afb: 'II', sach: true, n: 'exakt',
  afbGrund: 'Anwenden im Sachkontext: Dachfläche als vier Seitendreiecke erkennen, ohne Boden, mit der Seitenhöhe.',
  frage: `Ein Turm hat ein Dach in Form einer quadratischen Pyramide. Die Grundkante ist 6 m lang. Das Dach ist 4 m hoch, jede dreieckige Dachfläche hat die Höhe h_s = 5 m.\n\nWie viele Quadratmeter Dachfläche müssen gedeckt werden? Der Boden des Dachs gehört nicht dazu. ${GENAU}`,
  r: '4*(1/2*6*5)',
  weg: 'Gedeckt werden nur die vier dreieckigen Dachflächen.\nEine Fläche: ½ · 6 m · 5 m = 15 m².\nDachfläche: 4 · 15 m² = {A} m².',
  ke: [['halbieren_vergessen', '4*(6*5)', 'Bei den Dreiecken das ½ vergessen: 4 · 30 = 120.', 'Wie berechnest du den Flächeninhalt eines Dreiecks?'],
    ['falsche_hoehe', '4*(1/2*6*4)', 'Die Dachhöhe 4 m statt der Höhe der Dachfläche verwendet.', 'Welche Höhe gehört zu einer dreieckigen Dachfläche?'],
    ['falsche_groesse_beantwortet', '6^2+4*(1/2*6*5)', 'Den Boden mitgezählt: ganze Oberfläche statt Dachfläche.', 'Wird der Boden des Dachs auch gedeckt?']] });
def({ ...PY, ref: 'koerper-pyramide-06', titel: 'Pyramide · Grundkante aus Volumen und Höhe', einheit: 'cm', afb: 'III', sach: false, n: 2,
  afbGrund: 'Problemlösen: Rückrichtung in zwei Schritten – aus V = ⅓ · G · h die Grundfläche, daraus die Seitenlänge.',
  frage: `Eine Pyramide mit quadratischer Grundfläche hat das Volumen 192 cm³ und ist 9 cm hoch.\n\nWie lang ist eine Seite der Grundfläche? ${NOETIG}`,
  r: 'W(3*192/9)',
  weg: 'V = ⅓ · G · h, also G = 3 · V : h = 3 · 192 cm³ : 9 cm = 64 cm².\nG = a², also a = √64 cm = {A} cm.',
  ke: [['drittel_vergessen', 'W(192/9)', 'Den Faktor ⅓ vergessen: G = 192 : 9, a = √21,33.', 'Wie viel von einem Prisma mit gleicher Grundfläche und Höhe füllt eine Pyramide?'],
    ['wurzel_vergessen', '3*192/9', 'Die Grundfläche 64 cm² angegeben statt der Seitenlänge.', 'Ist nach einer Fläche oder nach einer Länge gefragt?'],
    ['mal_exponent', '3*192/9/2', 'a² als 2 · a gelesen: a = 64 : 2 = 32.', 'Was bedeutet a² – a · 2 oder a · a?']] });

// ─── geo_koerper_kegel (Tiefe 8) ───
const KE = { skill: 'geo_koerper_kegel', n: 2 };
def({ ...KE, ref: 'koerper-kegel-01', titel: 'Kegel · Volumen, Radius 3 cm', einheit: 'cm³', afb: 'I', sach: false, pi: true,
  afbGrund: 'Reproduzieren: V = ⅓ · π · r² · h mit gegebenem Radius und Höhe.',
  frage: `Ein Kegel hat den Radius 3 cm und die Höhe 8 cm.\n\nWie groß ist sein Volumen? ${SATZ_2}`,
  r: '1/3*P*3^2*8',
  weg: 'V = ⅓ · π · r² · h = ⅓ · π · 9 cm² · 8 cm = π · 24 cm³ ≈ {A} cm³ (π-Taste).\nMit π ≈ 3,14: V = 3,14 · 24 cm³ = {B} cm³.',
  ke: [['drittel_vergessen', 'P*3^2*8', 'Den Faktor ⅓ vergessen: π · 9 · 8 = π · 72.', 'Wie viel von einem Zylinder mit gleicher Grundfläche und Höhe füllt ein Kegel?'],
    ['pi_vergessen', '1/3*3^2*8', 'π weggelassen: ⅓ · 9 · 8 = 24.', 'Welcher Faktor gehört zur Kreisfläche?'],
    ['radius_durchmesser_verwechselt', '1/3*P*1.5^2*8', 'Den Radius wie einen Durchmesser halbiert.', 'Ist 3 cm schon der Radius?']] });
def({ ...KE, ref: 'koerper-kegel-02', titel: 'Kegel · Mantellinie aus Radius und Höhe', einheit: 'cm', afb: 'I', sach: false,
  afbGrund: 'Reproduzieren: Mantellinie mit dem Satz des Pythagoras, s = √(r² + h²).',
  frage: `Ein Kegel hat den Radius 5 cm und die Höhe 12 cm.\n\nWie lang ist seine Mantellinie s (die Strecke von der Spitze zum Rand der Grundfläche)? ${NOETIG}`,
  r: 'W(5^2+12^2)',
  weg: 'Radius, Höhe und Mantellinie bilden ein rechtwinkliges Dreieck, s ist die Hypotenuse.\ns = √(r² + h²) = √(25 + 144) cm = √169 cm = {A} cm.',
  ke: [['wurzel_vergessen', '5^2+12^2', 'Die Wurzel nicht gezogen: s² = 169 als Länge angegeben.', 'Hast du s oder s² ausgerechnet?'],
    ['hypotenuse_verwechselt', 'W(12^2-5^2)', 'Die Quadrate subtrahiert statt addiert: √(144 − 25).', 'Welche Seite liegt dem rechten Winkel gegenüber?']] });
def({ ...KE, ref: 'koerper-kegel-03', titel: 'Kegel · Oberfläche aus Durchmesser und Mantellinie', einheit: 'cm²', afb: 'II', sach: false, pi: true,
  afbGrund: 'Anwenden: Radius aus dem Durchmesser, Grundfläche und Mantel M = π · r · s addieren.',
  frage: `Ein Kegel hat den Durchmesser 12 cm und die Mantellinie s = 10 cm.\n\nWie groß ist seine Oberfläche? ${SATZ_2}`,
  r: 'P*6^2+P*6*10',
  weg: 'r = 12 cm : 2 = 6 cm.\nGrundfläche: π · (6 cm)² = π · 36 cm².\nMantel: M = π · r · s = π · 6 cm · 10 cm = π · 60 cm².\nO = π · 96 cm² ≈ {A} cm² (π-Taste).\nMit π ≈ 3,14: O = 3,14 · 96 cm² = {B} cm².',
  ke: [['radius_durchmesser_verwechselt', 'P*12^2+P*12*10', 'Den Durchmesser als Radius eingesetzt.', 'Ist 12 cm der Radius oder der Durchmesser?'],
    ['falsche_groesse_beantwortet', 'P*6*10', 'Nur den Mantel berechnet, die Grundfläche fehlt.', 'Gehört die runde Grundfläche zur Oberfläche?'],
    ['pi_vergessen', '6^2+6*10', 'π weggelassen: 36 + 60 = 96.', 'Welcher Faktor gehört zu Kreisfläche und Mantel?']] });
def({ ...KE, ref: 'koerper-kegel-04', titel: 'Kegel · Oberfläche aus Radius und Höhe', einheit: 'cm²', afb: 'II', sach: false, pi: true,
  afbGrund: 'Anwenden: erst die Mantellinie mit dem Satz des Pythagoras, dann Grundfläche plus Mantel.',
  frage: `Ein Kegel hat den Radius 8 cm und die Höhe 6 cm.\n\nWie groß ist seine Oberfläche? ${SATZ_2}`,
  r: 'P*8^2+P*8*W(8^2+6^2)',
  weg: 's = √(r² + h²) = √(64 + 36) cm = √100 cm = 10 cm.\nGrundfläche: π · 64 cm², Mantel: π · 8 cm · 10 cm = π · 80 cm².\nO = π · 144 cm² ≈ {A} cm² (π-Taste).\nMit π ≈ 3,14: O = 3,14 · 144 cm² = {B} cm².',
  ke: [['falsche_hoehe', 'P*8^2+P*8*6', 'Im Mantel die Höhe 6 cm statt der Mantellinie verwendet.', 'Welche Strecke steht in der Mantelformel M = π · r · s?'],
    ['wurzel_vergessen', 'P*8^2+P*8*(8^2+6^2)', 'Für s die Wurzel nicht gezogen: mit s = 100 gerechnet.', 'Kann die Mantellinie länger sein als Radius und Höhe zusammen?'],
    ['hypotenuse_verwechselt', 'P*8^2+P*8*W(8^2-6^2)', 'Für s die Quadrate subtrahiert statt addiert: √(64 − 36).', 'Ist die Mantellinie kürzer oder länger als der Radius?']] });
def({ ...KE, ref: 'koerper-kegel-05', titel: 'Kegel · Trichter in Millilitern', einheit: 'ml', afb: 'II', sach: true, pi: true, n: 0,
  afbGrund: 'Anwenden im Sachkontext: Trichter als Kegel erkennen, Durchmesser halbieren, cm³ als ml angeben.',
  frage: `Ein kegelförmiger Trichter ist oben innen 6 cm breit und innen 12 cm tief. Es gilt 1 cm³ = 1 ml.\n\nWie viele Milliliter passen in den Trichter, wenn unten zugehalten wird? ${SATZ_PI} Runde auf ganze Milliliter.`,
  r: '1/3*P*3^2*12',
  weg: 'Die obere Öffnung ist der Durchmesser: r = 6 cm : 2 = 3 cm.\nV = ⅓ · π · (3 cm)² · 12 cm = π · 36 cm³ ≈ 113,10 cm³ (π-Taste), mit 3,14: 113,04 cm³.\nGerundet: {A} ml (π-Taste), mit π ≈ 3,14 ebenfalls {B} ml.',
  ke: [['drittel_vergessen', 'P*3^2*12', 'Den Faktor ⅓ vergessen: π · 9 · 12 = π · 108.', 'Wie viel von einem Zylinder mit gleicher Grundfläche und Höhe füllt ein Kegel?'],
    ['radius_durchmesser_verwechselt', '1/3*P*6^2*12', 'Die Breite 6 cm als Radius eingesetzt.', 'Ist die Breite der Öffnung der Radius oder der Durchmesser?'],
    ['pi_vergessen', '1/3*3^2*12', 'π weggelassen: ⅓ · 9 · 12 = 36.', 'Welcher Faktor gehört zur Kreisfläche?']] });
def({ ...KE, ref: 'koerper-kegel-06', titel: 'Kegel · Volumen aus Mantellinie und Radius', einheit: 'cm³', afb: 'III', sach: false, pi: true,
  afbGrund: 'Problemlösen: die fehlende Höhe erst mit dem Satz des Pythagoras aus s und r gewinnen, dann das Volumen.',
  frage: `Ein Kegel hat den Radius 8 cm und die Mantellinie s = 17 cm.\n\nWie groß ist sein Volumen? ${SATZ_2}`,
  r: '1/3*P*8^2*W(17^2-8^2)',
  weg: 'Die Mantellinie ist die Hypotenuse: h = √(s² − r²) = √(289 − 64) cm = √225 cm = 15 cm.\nV = ⅓ · π · 64 cm² · 15 cm = π · 320 cm³ ≈ {A} cm³ (π-Taste).\nMit π ≈ 3,14: V = 3,14 · 320 cm³ = {B} cm³.',
  ke: [['hypotenuse_verwechselt', '1/3*P*8^2*W(17^2+8^2)', 'Für h die Quadrate addiert statt subtrahiert: √(289 + 64).', 'Ist die Höhe kürzer oder länger als die Mantellinie?'],
    ['falsche_hoehe', '1/3*P*8^2*17', 'Die Mantellinie 17 cm als Höhe eingesetzt.', 'Steht die Mantellinie senkrecht auf der Grundfläche?'],
    ['drittel_vergessen', 'P*8^2*W(17^2-8^2)', 'Den Faktor ⅓ vergessen: π · 64 · 15 = π · 960.', 'Wie viel von einem Zylinder mit gleicher Grundfläche und Höhe füllt ein Kegel?']] });

// ─── geo_koerper_kugel (Tiefe 7) ─── mit π
const KU = { skill: 'geo_koerper_kugel', pi: true, n: 2 };
def({ ...KU, ref: 'koerper-kugel-01', titel: 'Kugel · Volumen, Radius 6 cm', einheit: 'cm³', afb: 'I', sach: false,
  afbGrund: 'Reproduzieren: V = 4/3 · π · r³ mit gegebenem Radius.',
  frage: `Eine Kugel hat den Radius 6 cm.\n\nWie groß ist ihr Volumen? ${SATZ_2}`,
  r: '4/3*P*6^3',
  weg: 'V = 4/3 · π · r³ = 4/3 · π · 216 cm³ = π · 288 cm³ ≈ {A} cm³ (π-Taste).\nMit π ≈ 3,14: V = 3,14 · 288 cm³ = {B} cm³.',
  ke: [['oberflaeche_statt_volumen', '4*P*6^2', 'Die Oberfläche berechnet statt des Volumens: 4 · π · 36.', 'Ist nach dem Rauminhalt oder nach der Fläche gefragt?'],
    ['radius_durchmesser_verwechselt', '4/3*P*3^3', 'Den Radius wie einen Durchmesser halbiert.', 'Ist 6 cm schon der Radius?'],
    ['pi_vergessen', '4/3*6^3', 'π weggelassen: 4/3 · 216 = 288.', 'Welcher Faktor fehlt in der Volumenformel?']] });
def({ ...KU, ref: 'koerper-kugel-02', titel: 'Kugel · Oberfläche, Durchmesser 10 cm', einheit: 'cm²', afb: 'I', sach: false,
  afbGrund: 'Reproduzieren: Radius aus dem Durchmesser, dann O = 4 · π · r².',
  frage: `Eine Kugel hat den Durchmesser 10 cm.\n\nWie groß ist ihre Oberfläche? ${SATZ_2}`,
  r: '4*P*5^2',
  weg: 'r = 10 cm : 2 = 5 cm.\nO = 4 · π · r² = 4 · π · 25 cm² = π · 100 cm² ≈ {A} cm² (π-Taste).\nMit π ≈ 3,14: O = 3,14 · 100 cm² = {B} cm².',
  ke: [['radius_durchmesser_verwechselt', '4*P*10^2', 'Den Durchmesser als Radius eingesetzt: 4 · π · 100.', 'Ist 10 cm der Radius oder der Durchmesser?'],
    ['volumen_statt_oberflaeche', '4/3*P*5^3', 'Das Volumen berechnet statt der Oberfläche.', 'Kommt bei deiner Rechnung cm² oder cm³ heraus?'],
    ['pi_vergessen', '4*5^2', 'π weggelassen: 4 · 25 = 100.', 'Welcher Faktor fehlt in der Oberflächenformel?']] });
def({ ...KU, ref: 'koerper-kugel-03', titel: 'Kugel · Volumen, Radius 2,5 m', einheit: 'm³', afb: 'II', sach: false,
  afbGrund: 'Anwenden: dritte Potenz einer Dezimalzahl in der Volumenformel.',
  frage: `Eine Kugel hat den Radius 2,5 m.\n\nWie groß ist ihr Volumen in Kubikmetern? ${SATZ_2}`,
  r: '4/3*P*2.5^3',
  weg: 'r³ = 2,5 · 2,5 · 2,5 m³ = 15,625 m³.\nV = 4/3 · π · 15,625 m³ ≈ {A} m³ (π-Taste).\nMit π ≈ 3,14: V = 4/3 · 3,14 · 15,625 m³ ≈ {B} m³.',
  ke: [['mal_exponent', '4/3*P*3*2.5', '2,5³ als 3 · 2,5 gerechnet.', 'Was ist 2,5³ – 2,5 · 3 oder 2,5 · 2,5 · 2,5?'],
    ['oberflaeche_statt_volumen', '4*P*2.5^2', 'Die Oberfläche berechnet statt des Volumens.', 'Ist nach dem Rauminhalt oder nach der Fläche gefragt?'],
    ['radius_durchmesser_verwechselt', '4/3*P*1.25^3', 'Den Radius wie einen Durchmesser halbiert.', 'Ist 2,5 m schon der Radius?']] });
def({ ...KU, ref: 'koerper-kugel-04', titel: 'Kugel · Oberfläche in m², Radius 40 cm', einheit: 'm²', afb: 'II', sach: false,
  afbGrund: 'Anwenden: Oberflächenformel plus Umrechnung von Zentimetern in Meter.',
  frage: `Eine Kugel hat den Radius 40 cm.\n\nWie groß ist ihre Oberfläche in Quadratmetern? ${SATZ_2}`,
  r: '4*P*0.4^2',
  weg: 'r = 40 cm = 0,4 m.\nO = 4 · π · (0,4 m)² = π · 0,64 m² ≈ {A} m² (π-Taste).\nMit π ≈ 3,14: O = 3,14 · 0,64 m² ≈ {B} m².',
  ke: [['einheit_uebersprungen', '4*P*40^2', 'Nicht umgerechnet: die Oberfläche in Quadratzentimetern.', 'In welcher Einheit ist das Ergebnis gefragt?'],
    ['volumen_statt_oberflaeche', '4/3*P*0.4^3', 'Das Volumen berechnet statt der Oberfläche.', 'Kommt bei deiner Rechnung m² oder m³ heraus?'],
    ['radius_durchmesser_verwechselt', '4*P*0.2^2', 'Den Radius wie einen Durchmesser halbiert.', 'Ist 40 cm schon der Radius?']] });
def({ ...KU, ref: 'koerper-kugel-05', titel: 'Kugel · kugelförmiger Behälter in Litern', einheit: 'l', afb: 'II', sach: true, n: 1,
  afbGrund: 'Anwenden im Sachkontext: Durchmesser halbieren, in Dezimeter umrechnen, Volumen als Liter angeben.',
  frage: `Ein kugelförmiger Behälter hat innen einen Durchmesser von 40 cm. Es gilt 1 dm³ = 1 l.\n\nWie viele Liter fasst der Behälter? ${SATZ_1}`,
  r: '4/3*P*2^3',
  weg: 'r = 40 cm : 2 = 20 cm = 2 dm.\nV = 4/3 · π · (2 dm)³ = 4/3 · π · 8 dm³ ≈ 33,51 dm³ (π-Taste), mit 3,14: 33,49 dm³.\nGerundet: {A} l (π-Taste), mit π ≈ 3,14 ebenfalls {B} l.',
  ke: [['radius_durchmesser_verwechselt', '4/3*P*4^3', 'Den Durchmesser als Radius eingesetzt: 4/3 · π · 4³.', 'Ist 40 cm der Radius oder der Durchmesser?'],
    ['oberflaeche_statt_volumen', '4*P*2^2', 'Die Oberfläche berechnet statt des Volumens.', 'Ist nach dem Inhalt oder nach der Hülle gefragt?'],
    ['liter_kubik_falsch', '4/3*P*20^3/100', 'In Kubikzentimetern gerechnet und mit 1 l = 100 cm³ umgerechnet.', 'Wie viele Kubikzentimeter hat ein Liter?'],
    ['pi_vergessen', '4/3*2^3', 'π weggelassen: 4/3 · 8 ≈ 10,7.', 'Welcher Faktor fehlt in der Volumenformel?']] });
def({ ...KU, ref: 'koerper-kugel-06', titel: 'Kugel · Halbkugel auf einem Zylinder', einheit: 'cm³', afb: 'III', sach: false,
  afbGrund: 'Problemlösen: zusammengesetzten Körper zerlegen, Halbkugel als halbe Kugel erkennen und Volumen addieren.',
  frage: `Ein Körper besteht aus einem Zylinder mit aufgesetzter Halbkugel. Zylinder und Halbkugel haben beide den Durchmesser 6 cm. Der Zylinder ist 10 cm hoch.\n\nWie groß ist das Volumen des ganzen Körpers? ${SATZ_2}`,
  r: 'P*3^2*10+1/2*4/3*P*3^3',
  weg: 'r = 6 cm : 2 = 3 cm.\nZylinder: π · (3 cm)² · 10 cm = π · 90 cm³.\nHalbkugel: ½ · 4/3 · π · (3 cm)³ = π · 18 cm³.\nV = π · 108 cm³ ≈ {A} cm³ (π-Taste).\nMit π ≈ 3,14: V = 3,14 · 108 cm³ = {B} cm³.',
  ke: [['halbieren_vergessen', 'P*3^2*10+4/3*P*3^3', 'Eine ganze Kugel statt einer Halbkugel addiert.', 'Wie viel von einer Kugel sitzt auf dem Zylinder?'],
    ['radius_durchmesser_verwechselt', 'P*6^2*10+1/2*4/3*P*6^3', 'Den Durchmesser als Radius eingesetzt.', 'Ist 6 cm der Radius oder der Durchmesser?'],
    ['falsche_groesse_beantwortet', 'P*3^2*10', 'Nur den Zylinder berechnet, die Halbkugel fehlt.', 'Aus welchen Teilen besteht der Körper?'],
    ['pi_vergessen', '3^2*10+1/2*4/3*3^3', 'π weggelassen: 90 + 18 = 108.', 'Welcher Faktor gehört zu Zylinder und Kugel?']] });

baueCharge({
  thema: 'koerper', batch: 'k9-koerper', source: 'edvance_k9_koerper', idsPfad: 'docs/prefill/k9-koerper-ids.json',
  kopf: [
    `K9-Rest, Thema koerper — ${A.length} Aufgaben (Prisma, Zylinder, Pyramide, Kegel, Kugel; je Knoten 6, AFB I/I/II/II/II-Sach/III), alle als Text ohne Abbildung.`,
    'Erzeugt von tools/vorlauf-build.mjs aus docs/prefill/k9-koerper.json (Quelle: tools/k9-koerper-charge.mjs) — nicht von Hand editieren.',
    '',
    'Einspiel-Reihenfolge: nach 20261003105858_substrat_k9_koerper.sql (Knoten + Fehlbild-Slugs muessen stehen).',
  ],
  auswahl: 'Je Knoten vier reine Anwendung mit steigender Schwierigkeit, eine mit Sachkontext (Wassertrog, Wassertank, Pyramidendach, Trichter, kugelförmiger Behälter) und eine AFB III (Rückrichtung oder zusammengesetzter Körper). Alle ohne Abbildung lösbar, alle Maße im Text. Jede Aufgabe nennt die Rundung; π-Aufgaben nennen π-Taste oder 3,14, beide Ergebnisse stehen als Varianten in correct_answers und acceptance.equivalents (exakter Textvergleich, keine Toleranz).',
  aufgaben: A,
});
