#!/usr/bin/env node
/**
 * k9-pythagoras-charge.mjs — erzeugt docs/prefill/k9-pythagoras.json (Charge-Format von vorlauf-build.mjs).
 *
 *   node tools/k9-pythagoras-charge.mjs
 *
 * Lauf "Klasse 9 vervollstaendigen", Thema pythagoras (KLP Geo-1/Geo-2, Zweite Stufe).
 * Jeder Wert wird ueber Ausdruecke der Bibliothek (W(x) = Wurzel) exakt gerechnet, nie von Hand
 * eingetippt. Jede Aufgabe nennt, ob exakt oder auf wie viele Stellen gerundet wird.
 * Abbildungen nur ueber den Generator koordinatensystem (Punkte, keine Strecken); bei
 * Figur-Aufgaben stehen die Koordinaten NICHT im Text.
 * Die ids stehen in docs/prefill/k9-pythagoras-ids.json: ein zweiter Lauf erzeugt dieselbe Charge.
 */

import { baueCharge, CLUSTER } from './k9-rest-lib.mjs';

const BASIS = {
  inhalt: 'geometrie', cluster: CLUSTER.geo, stoff: 9,
  stoffGrund: 'Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Geo-1/Geo-2 (Satz des Pythagoras).',
  clusterGrund: 'Geometrie & Messen wie geo_kreis_* und geo_flaeche_* im Bestand.',
  inhaltGrund: 'Inhaltsfeld Geometrie (Geo-1, Satz des Pythagoras).',
};
const EXAKT = 'Gib das Ergebnis exakt an.';
const R1 = 'Runde auf eine Stelle nach dem Komma.';
const R2 = 'Runde auf zwei Stellen nach dem Komma.';

const A = [];
const def = (o) => A.push({ ...BASIS, ...o });

// ─── geo_pythagoras_hypotenuse (Tiefe 6) ───
const HY = { skill: 'geo_pythagoras_hypotenuse' };
def({ ...HY, ref: 'pyth-hypotenuse-01', titel: 'Hypotenuse · Katheten 6 cm und 8 cm', einheit: 'cm', afb: 'I', sach: false,
  afbGrund: 'Reproduzieren: Satz des Pythagoras mit zwei gegebenen Katheten, Ergebnis ganzzahlig.',
  frage: `Ein rechtwinkliges Dreieck hat die Katheten a = 6 cm und b = 8 cm.\n\nWie lang ist die Hypotenuse c? ${EXAKT}`,
  r: 'W(6^2+8^2)', n: 'exakt',
  weg: 'c² = a² + b² = 6² + 8² = 36 + 64 = 100.\nc = √100 = {A} cm.',
  ke: [['wurzel_vergessen', '6^2+8^2', 'c² = 100 ausgerechnet, aber die Wurzel nicht gezogen.', 'Hast du schon c ausgerechnet oder erst c²?'],
    ['wurzel_gliedweise', '6+8', 'Die Wurzel Glied für Glied gezogen: √(6² + 8²) als 6 + 8.', 'Ist √(36 + 64) dasselbe wie √36 + √64?'],
    ['hypotenuse_verwechselt', 'W(8^2-6^2)', 'Die Quadrate subtrahiert, als wäre eine Kathete gesucht: √(64 − 36).', 'Ist die Hypotenuse die längste oder eine kürzere Seite des Dreiecks?', 2]] });
def({ ...HY, ref: 'pyth-hypotenuse-02', titel: 'Hypotenuse · Katheten 5 cm und 7 cm, gerundet', einheit: 'cm', afb: 'I', sach: false,
  afbGrund: 'Reproduzieren: Satz des Pythagoras, Wurzel aus einer Nicht-Quadratzahl runden.',
  frage: `Ein rechtwinkliges Dreieck hat die Katheten a = 5 cm und b = 7 cm.\n\nWie lang ist die Hypotenuse c? ${R2}`,
  r: 'W(5^2+7^2)', n: 2,
  weg: 'c² = 5² + 7² = 25 + 49 = 74.\nc = √74 ≈ {A} cm.',
  ke: [['wurzel_vergessen', '5^2+7^2', 'c² = 74 ausgerechnet, aber die Wurzel nicht gezogen.', 'Kann die Hypotenuse länger sein als beide Katheten zusammen?', 'exakt'],
    ['wurzel_gliedweise', '5+7', 'Die Wurzel Glied für Glied gezogen: c = 5 + 7.', 'Ist √(25 + 49) dasselbe wie √25 + √49?', 'exakt'],
    ['hypotenuse_verwechselt', 'W(7^2-5^2)', 'Die Quadrate subtrahiert: √(49 − 25).', 'Muss die Hypotenuse länger oder kürzer als 7 cm sein?']] });
def({ ...HY, ref: 'pyth-hypotenuse-03', titel: 'Hypotenuse · Katheten 4,5 cm und 6 cm', einheit: 'cm', afb: 'II', sach: false,
  afbGrund: 'Anwenden: Quadrat einer Dezimalzahl und Wurzel aus einer Dezimalzahl.',
  frage: `Ein rechtwinkliges Dreieck hat die Katheten a = 4,5 cm und b = 6 cm.\n\nWie lang ist die Hypotenuse c? ${EXAKT}`,
  r: 'W(4.5^2+6^2)', n: 'exakt',
  weg: 'c² = 4,5² + 6² = 20,25 + 36 = 56,25.\nc = √56,25 = {A} cm.',
  ke: [['wurzel_vergessen', '4.5^2+6^2', 'c² = 56,25 ausgerechnet, aber die Wurzel nicht gezogen.', 'Ist 56,25 schon die Länge oder erst ihr Quadrat?'],
    ['wurzel_gliedweise', '4.5+6', 'Die Wurzel Glied für Glied gezogen: c = 4,5 + 6.', 'Ist √(20,25 + 36) dasselbe wie √20,25 + √36?'],
    ['mal_exponent', 'W(2*4.5+2*6)', 'Quadrate als Verdopplung gerechnet: 4,5² als 2 · 4,5 und 6² als 2 · 6.', 'Was bedeutet 4,5²: 4,5 · 2 oder 4,5 · 4,5?', 2],
    ['hypotenuse_verwechselt', 'W(6^2-4.5^2)', 'Die Quadrate subtrahiert: √(36 − 20,25).', 'Ist die Hypotenuse länger oder kürzer als die Katheten?', 2]] });
def({ ...HY, ref: 'pyth-hypotenuse-04', titel: 'Hypotenuse · Katheten 12 cm und 0,35 m', einheit: 'cm', afb: 'II', sach: false,
  afbGrund: 'Anwenden: Einheiten angleichen, dann Satz des Pythagoras mit größeren Zahlen.',
  frage: `Ein rechtwinkliges Dreieck hat die Katheten a = 12 cm und b = 0,35 m.\n\nWie lang ist die Hypotenuse c in Zentimetern? ${EXAKT}`,
  r: 'W(12^2+35^2)', n: 'exakt',
  weg: 'b = 0,35 m = 35 cm.\nc² = 12² + 35² = 144 + 1225 = 1369.\nc = √1369 = {A} cm.',
  ke: [['einheit_uebersprungen', 'W(12^2+0.35^2)', 'Nicht umgerechnet: mit 12 und 0,35 gerechnet.', 'Sind beide Katheten in derselben Einheit angegeben?', 2],
    ['wurzel_vergessen', '12^2+35^2', 'c² = 1369 ausgerechnet, aber die Wurzel nicht gezogen.', 'Hast du schon c ausgerechnet oder erst c²?'],
    ['wurzel_gliedweise', '12+35', 'Die Wurzel Glied für Glied gezogen: c = 12 + 35.', 'Ist √(144 + 1225) dasselbe wie √144 + √1225?']] });
def({ ...HY, ref: 'pyth-hypotenuse-05', titel: 'Hypotenuse · Boot 9 km nach Norden, 4 km nach Osten', einheit: 'km', afb: 'II', sach: true,
  afbGrund: 'Anwenden im Sachkontext: Die Luftlinie muss als Hypotenuse eines rechtwinkligen Dreiecks erkannt werden.',
  frage: `Ein Boot fährt vom Hafen aus 9 km genau nach Norden und danach 4 km genau nach Osten.\n\nWie weit ist das Boot jetzt in Luftlinie vom Hafen entfernt? ${R1}`,
  r: 'W(9^2+4^2)', n: 1,
  weg: 'Nord- und Ostrichtung stehen senkrecht aufeinander; die Luftlinie ist die Hypotenuse.\nc² = 9² + 4² = 81 + 16 = 97.\nc = √97 ≈ {A} km.',
  ke: [['wurzel_vergessen', '9^2+4^2', 'c² = 97 ausgerechnet, aber die Wurzel nicht gezogen.', 'Kann die Luftlinie länger sein als der gefahrene Weg?', 'exakt'],
    ['wurzel_gliedweise', '9+4', 'Die gefahrenen Strecken addiert: 9 + 4.', 'Ist die Luftlinie so lang wie der Umweg über beide Strecken?', 'exakt'],
    ['hypotenuse_verwechselt', 'W(9^2-4^2)', 'Die Quadrate subtrahiert: √(81 − 16).', 'Kann die Luftlinie kürzer sein als die 9 km nach Norden?']] });
def({ ...HY, ref: 'pyth-hypotenuse-06', titel: 'Hypotenuse · Abkürzung über ein Feld', einheit: 'm', afb: 'III', sach: true, n: 0,
  afbGrund: 'Problemlösen: Diagonale als Hypotenuse erkennen und mit dem Weg entlang zweier Seiten vergleichen.',
  frage: `Ein rechteckiges Feld ist 120 m lang und 50 m breit. Ein Weg führt von einer Ecke an zwei Seiten entlang zur gegenüberliegenden Ecke. Quer über das Feld verläuft ein gerader Pfad zwischen denselben Ecken.\n\nWie viele Meter ist der Pfad kürzer als der Weg an den Seiten? Runde, falls nötig, auf ganze Meter.`,
  r: '120+50-W(120^2+50^2)',
  weg: 'Weg an den Seiten: 120 m + 50 m = 170 m.\nPfad = Diagonale: √(120² + 50²) = √(14 400 + 2 500) = √16 900 = 130 m.\nErsparnis: 170 m − 130 m = {A} m.',
  ke: [['falsche_groesse_beantwortet', 'W(120^2+50^2)', 'Die Länge des Pfades angegeben statt des Unterschieds.', 'Gefragt ist, um wie viel der Pfad kürzer ist – was fehlt noch?'],
    ['hypotenuse_verwechselt', '120+50-W(120^2-50^2)', 'Für die Diagonale die Quadrate subtrahiert: √(120² − 50²).', 'Ist die Diagonale länger oder kürzer als die lange Seite des Feldes?']] });

// ─── geo_pythagoras_kathete (Tiefe 7) ───
const KA = { skill: 'geo_pythagoras_kathete' };
const DREIECK = 'Im rechtwinkligen Dreieck ABC mit dem rechten Winkel bei C';
def({ ...KA, ref: 'pyth-kathete-01', titel: 'Kathete · Hypotenuse 13 cm, Kathete 5 cm', einheit: 'cm', afb: 'I', sach: false,
  afbGrund: 'Reproduzieren: Satz des Pythagoras nach einer Kathete umstellen, Ergebnis ganzzahlig.',
  frage: `${DREIECK} ist die Hypotenuse c = 13 cm lang und die Kathete a = 5 cm lang.\n\nWie lang ist die Kathete b? ${EXAKT}`,
  r: 'W(13^2-5^2)', n: 'exakt',
  weg: 'b² = c² − a² = 13² − 5² = 169 − 25 = 144.\nb = √144 = {A} cm.',
  ke: [['hypotenuse_verwechselt', 'W(13^2+5^2)', 'Die Quadrate addiert, als wäre die Hypotenuse gesucht: √(169 + 25).', 'Kann eine Kathete länger sein als die Hypotenuse?', 2],
    ['wurzel_vergessen', '13^2-5^2', 'b² = 144 ausgerechnet, aber die Wurzel nicht gezogen.', 'Hast du schon b ausgerechnet oder erst b²?'],
    ['wurzel_gliedweise', '13-5', 'Die Wurzel Glied für Glied gezogen: √(13² − 5²) als 13 − 5.', 'Ist √(169 − 25) dasselbe wie √169 − √25?']] });
def({ ...KA, ref: 'pyth-kathete-02', titel: 'Kathete · Hypotenuse 10 cm, Kathete 7 cm, gerundet', einheit: 'cm', afb: 'I', sach: false,
  afbGrund: 'Reproduzieren: Kathete berechnen, Wurzel aus einer Nicht-Quadratzahl runden.',
  frage: `${DREIECK} ist die Hypotenuse c = 10 cm lang und die Kathete a = 7 cm lang.\n\nWie lang ist die Kathete b? ${R2}`,
  r: 'W(10^2-7^2)', n: 2,
  weg: 'b² = c² − a² = 10² − 7² = 100 − 49 = 51.\nb = √51 ≈ {A} cm.',
  ke: [['hypotenuse_verwechselt', 'W(10^2+7^2)', 'Die Quadrate addiert: √(100 + 49).', 'Kann eine Kathete länger sein als die Hypotenuse?'],
    ['wurzel_vergessen', '10^2-7^2', 'b² = 51 ausgerechnet, aber die Wurzel nicht gezogen.', 'Kann eine Kathete länger sein als die Hypotenuse mit 10 cm?'],
    ['wurzel_gliedweise', '10-7', 'Die Wurzel Glied für Glied gezogen: b = 10 − 7.', 'Ist √(100 − 49) dasselbe wie √100 − √49?']] });
def({ ...KA, ref: 'pyth-kathete-03', titel: 'Kathete · Hypotenuse 7,5 cm, Kathete 4,5 cm', einheit: 'cm', afb: 'II', sach: false,
  afbGrund: 'Anwenden: Kathete aus Dezimalzahlen, Quadrate von Dezimalzahlen.',
  frage: `${DREIECK} ist die Hypotenuse c = 7,5 cm lang und die Kathete a = 4,5 cm lang.\n\nWie lang ist die Kathete b? ${EXAKT}`,
  r: 'W(7.5^2-4.5^2)', n: 'exakt',
  weg: 'b² = 7,5² − 4,5² = 56,25 − 20,25 = 36.\nb = √36 = {A} cm.',
  ke: [['hypotenuse_verwechselt', 'W(7.5^2+4.5^2)', 'Die Quadrate addiert: √(56,25 + 20,25).', 'Welche Seite liegt dem rechten Winkel bei C gegenüber?', 2],
    ['wurzel_vergessen', '7.5^2-4.5^2', 'b² = 36 ausgerechnet, aber die Wurzel nicht gezogen.', 'Ist 36 schon die Länge oder erst ihr Quadrat?'],
    ['wurzel_gliedweise', '7.5-4.5', 'Die Wurzel Glied für Glied gezogen: b = 7,5 − 4,5.', 'Ist √(56,25 − 20,25) dasselbe wie 7,5 − 4,5?']] });
def({ ...KA, ref: 'pyth-kathete-04', titel: 'Kathete · Flächeninhalt aus Hypotenuse 25 cm und Kathete 7 cm', einheit: 'cm²', afb: 'II', sach: false,
  afbGrund: 'Anwenden: erst die fehlende Kathete, dann den Flächeninhalt des Dreiecks berechnen.',
  frage: `${DREIECK} ist die Hypotenuse c = 25 cm lang und die Kathete a = 7 cm lang.\n\nWie groß ist der Flächeninhalt des Dreiecks? ${EXAKT}`,
  r: '7*W(25^2-7^2)/2', n: 'exakt',
  weg: 'b² = 25² − 7² = 625 − 49 = 576, also b = 24 cm.\nDie Katheten stehen senkrecht aufeinander: A = a · b : 2 = 7 cm · 24 cm : 2 = {A} cm².',
  ke: [['falsche_groesse_beantwortet', 'W(25^2-7^2)', 'Nur die Kathete b angegeben statt des Flächeninhalts.', 'Ist nach einer Seite oder nach der Fläche gefragt?'],
    ['halbieren_vergessen', '7*W(25^2-7^2)', 'Beim Flächeninhalt nicht halbiert: 7 · 24.', 'Welchen Teil des Rechtecks mit den Seiten 7 cm und 24 cm bedeckt das Dreieck?'],
    ['hypotenuse_verwechselt', '7*W(25^2+7^2)/2', 'Für b die Quadrate addiert: √(625 + 49).', 'Kann die Kathete b länger sein als die Hypotenuse?', 2]] });
def({ ...KA, ref: 'pyth-kathete-05', titel: 'Kathete · Drachen an 60 m Schnur', einheit: 'm', afb: 'II', sach: true,
  afbGrund: 'Anwenden im Sachkontext: Schnur als Hypotenuse erkennen, die Höhe ist eine Kathete.',
  frage: `Ein Drachen hängt an einer 60 m langen, straff gespannten Schnur, die direkt am Boden festgehalten wird. Der Drachen steht genau über einem Punkt am Boden, der 25 m von dieser Stelle entfernt ist.\n\nIn welcher Höhe fliegt der Drachen? ${R1}`,
  r: 'W(60^2-25^2)', n: 1,
  weg: 'Schnur (60 m) = Hypotenuse, Abstand am Boden (25 m) und Höhe h = Katheten.\nh² = 60² − 25² = 3600 − 625 = 2975.\nh = √2975 ≈ {A} m.',
  ke: [['hypotenuse_verwechselt', 'W(60^2+25^2)', 'Die Quadrate addiert: √(3600 + 625).', 'Kann der Drachen höher fliegen, als die Schnur lang ist?'],
    ['wurzel_vergessen', '60^2-25^2', 'h² = 2975 ausgerechnet, aber die Wurzel nicht gezogen.', 'Kann der Drachen höher sein, als die Schnur lang ist?', 'exakt'],
    ['wurzel_gliedweise', '60-25', 'Die Wurzel Glied für Glied gezogen: h = 60 − 25.', 'Ist √(3600 − 625) dasselbe wie 60 − 25?']] });
def({ ...KA, ref: 'pyth-kathete-06', titel: 'Kathete · Höhe eines abgespannten Mastes', einheit: 'm', afb: 'III', sach: true,
  afbGrund: 'Problemlösen: rechtwinkliges Dreieck in der Situation finden, Kathete berechnen und das Reststück ergänzen.',
  frage: `Ein senkrechter Mast wird mit einem 25 m langen, straff gespannten Seil gehalten. Das Seil ist am Boden 7 m vom Fuß des Mastes entfernt befestigt. Am Mast ist es 2 m unterhalb der Spitze befestigt.\n\nWie hoch ist der Mast? ${EXAKT}`,
  r: 'W(25^2-7^2)+2', n: 'exakt',
  weg: 'Seil (25 m) = Hypotenuse, Bodenabstand (7 m) = Kathete.\nBefestigungshöhe: √(25² − 7²) = √(625 − 49) = √576 = 24 m.\nMasthöhe: 24 m + 2 m = {A} m.',
  ke: [['falsche_groesse_beantwortet', 'W(25^2-7^2)', 'Die Höhe der Befestigung angegeben, die 2 m bis zur Spitze fehlen.', 'Ist das Seil an der Spitze des Mastes befestigt?'],
    ['hypotenuse_verwechselt', 'W(25^2+7^2)+2', 'Die Quadrate addiert: √(625 + 49).', 'Kann die Befestigung höher liegen, als das Seil lang ist?', 2],
    ['wurzel_gliedweise', '25-7+2', 'Die Wurzel Glied für Glied gezogen: 25 − 7.', 'Ist √(625 − 49) dasselbe wie 25 − 7?']] });

// ─── geo_pythagoras_umkehrung (Tiefe 7) ───
const UM = { skill: 'geo_pythagoras_umkehrung' };
def({ ...UM, ref: 'pyth-umkehrung-01', titel: 'Umkehrung · längste Seite zu 9 cm und 12 cm', einheit: 'cm', afb: 'I', sach: false,
  afbGrund: 'Reproduzieren: Länge der dritten Seite aus der Umkehrung a² + b² = c², Ergebnis ganzzahlig.',
  frage: `Die beiden kürzeren Seiten eines Dreiecks sind 9 cm und 12 cm lang.\n\nWie lang muss die längste Seite sein, damit das Dreieck rechtwinklig ist? ${EXAKT}`,
  r: 'W(9^2+12^2)', n: 'exakt',
  weg: 'Rechtwinklig genau dann, wenn 9² + 12² = c² für die längste Seite c.\nc² = 81 + 144 = 225, c = √225 = {A} cm.',
  ke: [['wurzel_vergessen', '9^2+12^2', 'c² = 225 ausgerechnet, aber die Wurzel nicht gezogen.', 'Hast du schon die Seitenlänge oder erst ihr Quadrat?'],
    ['wurzel_gliedweise', '9+12', 'Die Wurzel Glied für Glied gezogen: c = 9 + 12.', 'Kann ein Dreieck eine Seite haben, die so lang ist wie die beiden anderen zusammen?'],
    ['hypotenuse_verwechselt', 'W(12^2-9^2)', 'Die Quadrate subtrahiert: √(144 − 81).', 'Soll die gesuchte Seite die längste oder eine kürzere sein?', 2]] });
def({ ...UM, ref: 'pyth-umkehrung-02', titel: 'Umkehrung · welches der vier Dreiecke ist rechtwinklig?', afb: 'I', sach: false,
  afbGrund: 'Reproduzieren: a² + b² = c² für vier gegebene Dreiecke prüfen.',
  frage: 'Genau eines der vier Dreiecke ist rechtwinklig.\n(1) 5 cm, 6 cm, 8 cm\n(2) 7 cm, 24 cm, 25 cm\n(3) 5 cm, 7 cm, 8,6 cm\n(4) 2 cm, 2,5 cm, 3 cm\n\nGib die Nummer des rechtwinkligen Dreiecks an. Die Antwort ist eine ganze Zahl.',
  r: '2', n: 'exakt',
  weg: 'Prüfe jeweils: Summe der Quadrate der kürzeren Seiten = Quadrat der längsten Seite?\n(1) 25 + 36 = 61, 8² = 64: nein.\n(2) 49 + 576 = 625, 25² = 625: ja.\n(3) 25 + 49 = 74, 8,6² = 73,96: nein (nur ungefähr).\n(4) 4 + 6,25 = 10,25, 3² = 9: nein.\nRechtwinklig ist Dreieck {A}.',
  ke: [['zu_frueh_gerundet', '3', 'Dreieck (3) gewählt: √74 ≈ 8,6 wie eine Gleichheit behandelt, dabei ist 8,6² = 73,96 und nicht 74.', 'Ist 8,6² genau 74 oder nur ungefähr?'],
    ['mal_exponent', '4', 'Dreieck (4) gewählt: 2,5² als 2 · 2,5 = 5 gerechnet, dann 4 + 5 = 9 = 3².', 'Was ist 2,5²: 2,5 · 2 oder 2,5 · 2,5?']] });
def({ ...UM, ref: 'pyth-umkehrung-03', titel: 'Umkehrung · Abstand zur Rechtwinkligkeit bei 6, 7, 9 cm', einheit: 'cm²', afb: 'II', sach: false,
  afbGrund: 'Anwenden: Summe der Kathetenquadrate mit dem Quadrat der längsten Seite vergleichen und den Unterschied angeben.',
  frage: 'Ein Dreieck hat die Seitenlängen 6 cm, 7 cm und 9 cm. Mit a und b sind die beiden kürzeren Seiten gemeint, mit c die längste.\n\nUm wie viele Quadratzentimeter ist a² + b² größer als c²? Gib das Ergebnis exakt an.',
  r: '6^2+7^2-9^2', n: 'exakt',
  weg: 'a² + b² = 6² + 7² = 36 + 49 = 85.\nc² = 9² = 81.\n85 − 81 = {A} cm². Das Dreieck ist also nicht rechtwinklig.',
  ke: [['hypotenuse_verwechselt', '6^2+9^2-7^2', 'Die falsche Seite als c genommen: 6² + 9² − 7².', 'Welche der drei Seiten ist die längste?'],
    ['mal_exponent', '2*6+2*7-2*9', 'Quadrate als Verdopplung gerechnet: 2 · 6 + 2 · 7 − 2 · 9.', 'Was bedeutet 6²: 6 · 2 oder 6 · 6?'],
    ['falsche_groesse_beantwortet', '6^2+7^2', 'Nur a² + b² angegeben statt des Unterschieds zu c².', 'Gefragt ist, um wie viel a² + b² größer ist – was fehlt noch?']] });
def({ ...UM, ref: 'pyth-umkehrung-04', titel: 'Umkehrung · wie viel länger müsste die längste Seite sein?', einheit: 'cm', afb: 'II', sach: false,
  afbGrund: 'Anwenden: Soll-Länge der längsten Seite aus der Umkehrung bestimmen und mit der Ist-Länge vergleichen.',
  frage: `Ein Dreieck hat die Seitenlängen 2,5 cm, 4 cm und 4,5 cm.\n\nUm wie viele Zentimeter müsste die längste Seite länger sein, damit das Dreieck mit den beiden anderen Seiten rechtwinklig wird? ${R2}`,
  r: 'W(2.5^2+4^2)-4.5', n: 2,
  weg: 'Für einen rechten Winkel müsste die längste Seite √(2,5² + 4²) = √(6,25 + 16) = √22,25 ≈ 4,717 cm lang sein.\n4,717 cm − 4,5 cm ≈ {A} cm.',
  ke: [['wurzel_vergessen', '2.5^2+4^2-4.5^2', 'Nur die Quadrate verglichen: 22,25 − 20,25 = 2, ohne Wurzel.', 'Ist nach einem Unterschied von Längen oder von Quadraten gefragt?', 'exakt'],
    ['falsche_groesse_beantwortet', 'W(2.5^2+4^2)', 'Die nötige Länge der Seite angegeben statt des Unterschieds.', 'Gefragt ist, um wie viel die Seite länger sein müsste – was fehlt noch?'],
    ['zu_frueh_gerundet', '4.7-4.5', '√22,25 vorher auf 4,7 gerundet: 4,7 − 4,5 = 0,2.', 'Was passiert mit einem kleinen Unterschied, wenn du vorher rundest?']] });
def({ ...UM, ref: 'pyth-umkehrung-05', titel: 'Umkehrung · rechte Ecke beim Abstecken', einheit: 'm', afb: 'II', sach: true,
  afbGrund: 'Anwenden im Sachkontext: Die Umkehrung des Satzes als Prüfverfahren für einen rechten Winkel erkennen.',
  frage: `Beim Bau eines Gartenhauses soll eine Ecke genau rechtwinklig werden. Von der Ecke aus wird auf der einen Seite 1,2 m abgemessen, auf der anderen Seite 1,6 m. Die beiden Endpunkte werden markiert.\n\nWie groß muss der Abstand der beiden Markierungen sein, damit die Ecke ein rechter Winkel ist? ${EXAKT}`,
  r: 'W(1.2^2+1.6^2)', n: 'exakt',
  weg: 'Die Ecke ist genau dann rechtwinklig, wenn der Abstand d die Gleichung 1,2² + 1,6² = d² erfüllt.\nd² = 1,44 + 2,56 = 4, d = √4 = {A} m.',
  ke: [['wurzel_vergessen', '1.2^2+1.6^2', 'd² = 4 ausgerechnet, aber die Wurzel nicht gezogen.', 'Ist 4 schon der Abstand oder erst sein Quadrat?'],
    ['wurzel_gliedweise', '1.2+1.6', 'Die Wurzel Glied für Glied gezogen: d = 1,2 + 1,6.', 'Ist der direkte Abstand so lang wie beide Seiten zusammen?'],
    ['hypotenuse_verwechselt', 'W(1.6^2-1.2^2)', 'Die Quadrate subtrahiert: √(2,56 − 1,44).', 'Liegt der gesuchte Abstand dem rechten Winkel gegenüber?', 2]] });
def({ ...UM, ref: 'pyth-umkehrung-06', titel: 'Umkehrung · Latte um wie viele Zentimeter kürzen?', einheit: 'cm', afb: 'III', sach: true,
  afbGrund: 'Problemlösen: Soll-Länge über die Umkehrung bestimmen, mit der Ist-Länge vergleichen und in Zentimeter umrechnen.',
  frage: `Aus drei Latten wird ein Dreieck gelegt. Die beiden kürzeren Latten sind 3 m und 4 m lang, die längste ist 5,10 m lang. Der Winkel zwischen den beiden kürzeren Latten soll ein rechter Winkel werden.\n\nUm wie viele Zentimeter muss die längste Latte dafür gekürzt werden? ${EXAKT}`,
  r: '510-W(300^2+400^2)', n: 'exakt',
  weg: 'Für einen rechten Winkel muss die längste Seite √(3² + 4²) m = √25 m = 5 m = 500 cm lang sein.\n510 cm − 500 cm = {A} cm.',
  ke: [['falsche_groesse_beantwortet', 'W(300^2+400^2)', 'Die nötige Länge der Latte angegeben statt des Stücks, das ab muss.', 'Gefragt ist, wie viel abgesägt wird – was fehlt noch?'],
    ['einheit_uebersprungen', '5.1-W(3^2+4^2)', 'Den Unterschied in Metern angegeben: 0,1.', 'In welcher Einheit ist das Ergebnis gefragt?'],
    ['wurzel_vergessen', '(5.1^2-(3^2+4^2))*100', 'Nur die Quadrate verglichen: 26,01 − 25 = 1,01, ohne Wurzel, dann mal 100.', 'Ist nach einem Unterschied von Längen oder von Quadraten gefragt?']] });

// ─── geo_pythagoras_abstand (Tiefe 7) ───
const AB = { skill: 'geo_pythagoras_abstand' };
const ALT = (namen) => `Koordinatensystem mit Gitter und den Punkten ${namen}.`;
def({ ...AB, ref: 'pyth-abstand-01', titel: 'Abstand · P(1|2) und Q(4|6)', afb: 'I', sach: false,
  afbGrund: 'Reproduzieren: Koordinatendifferenzen bilden und den Satz des Pythagoras anwenden, Ergebnis ganzzahlig.',
  frage: `Gegeben sind die Punkte P(1|2) und Q(4|6) in einem Koordinatensystem.\n\nWie groß ist der Abstand der Punkte P und Q in Längeneinheiten? ${EXAKT}`,
  r: 'W((4-1)^2+(6-2)^2)', n: 'exakt',
  weg: 'Unterschied der x-Werte: 4 − 1 = 3, der y-Werte: 6 − 2 = 4.\nAbstand² = 3² + 4² = 9 + 16 = 25.\nAbstand = √25 = {A} Längeneinheiten.',
  ke: [['wurzel_vergessen', '3^2+4^2', 'Abstand² = 25 ausgerechnet, aber die Wurzel nicht gezogen.', 'Hast du schon den Abstand oder erst sein Quadrat?'],
    ['wurzel_gliedweise', '3+4', 'Die Wurzel Glied für Glied gezogen: 3 + 4.', 'Ist der direkte Weg so lang wie der Weg erst nach rechts und dann nach oben?']] });
def({ ...AB, ref: 'pyth-abstand-02', titel: 'Abstand · zwei Punkte aus der Abbildung', afb: 'I', sach: false,
  afbGrund: 'Reproduzieren: Koordinaten im ersten Quadranten ablesen, Abstand mit dem Satz des Pythagoras, Ergebnis ganzzahlig.',
  frage: `Die Abbildung zeigt die Punkte P und Q in einem Koordinatensystem.\n\nLies ihre Koordinaten ab. Wie groß ist der Abstand der Punkte P und Q in Längeneinheiten? ${EXAKT}`,
  figur: { params: { x_min: -1, x_max: 8, y_min: -1, y_max: 10, punkte: [{ x: 1, y: 1, label: 'P' }, { x: 7, y: 9, label: 'Q' }] }, alt_text: ALT('P und Q') },
  r: 'W((7-1)^2+(9-1)^2)', n: 'exakt',
  weg: 'Abgelesen: P(1|1), Q(7|9).\nUnterschied der x-Werte: 7 − 1 = 6, der y-Werte: 9 − 1 = 8.\nAbstand = √(6² + 8²) = √(36 + 64) = √100 = {A} Längeneinheiten.',
  ke: [['wurzel_vergessen', '6^2+8^2', 'Abstand² = 100 ausgerechnet, aber die Wurzel nicht gezogen.', 'Hast du schon den Abstand oder erst sein Quadrat?'],
    ['wurzel_gliedweise', '6+8', 'Die Wurzel Glied für Glied gezogen: 6 + 8.', 'Ist der direkte Weg so lang wie der Weg erst nach rechts und dann nach oben?'],
    ['hypotenuse_verwechselt', 'W(8^2-6^2)', 'Die Quadrate subtrahiert: √(64 − 36).', 'Ist der Abstand länger oder kürzer als die beiden Koordinatenunterschiede?', 2]] });
def({ ...AB, ref: 'pyth-abstand-03', titel: 'Abstand · P(−2|3) und Q(4|−5) über die Achsen', afb: 'II', sach: false,
  afbGrund: 'Anwenden: Koordinatendifferenzen über die Achsen hinweg mit Vorzeichen bilden.',
  frage: `Gegeben sind die Punkte P(−2|3) und Q(4|−5) in einem Koordinatensystem.\n\nWie groß ist der Abstand der Punkte P und Q in Längeneinheiten? ${EXAKT}`,
  r: 'W((4-(0-2))^2+(3-(0-5))^2)', n: 'exakt',
  weg: 'Unterschied der x-Werte: 4 − (−2) = 6, der y-Werte: 3 − (−5) = 8.\nAbstand² = 6² + 8² = 36 + 64 = 100.\nAbstand = √100 = {A} Längeneinheiten.',
  ke: [['vorzeichen_ignoriert', 'W((4-2)^2+(5-3)^2)', 'Die Vorzeichen übersehen: 4 − 2 = 2 und 5 − 3 = 2, also √8.', 'Wie viele Einheiten liegen auf der x-Achse zwischen −2 und 4?', 2],
    ['wurzel_vergessen', '6^2+8^2', 'Abstand² = 100 ausgerechnet, aber die Wurzel nicht gezogen.', 'Hast du schon den Abstand oder erst sein Quadrat?'],
    ['wurzel_gliedweise', '6+8', 'Die Wurzel Glied für Glied gezogen: 6 + 8.', 'Ist √(36 + 64) dasselbe wie 6 + 8?']] });
def({ ...AB, ref: 'pyth-abstand-04', titel: 'Abstand · zwei Punkte über die Achsen aus der Abbildung, gerundet', afb: 'II', sach: false,
  afbGrund: 'Anwenden: Koordinaten in verschiedenen Quadranten ablesen, Differenzen mit Vorzeichen, Wurzel runden.',
  frage: `Die Abbildung zeigt die Punkte P und Q in einem Koordinatensystem.\n\nLies ihre Koordinaten ab. Wie groß ist der Abstand der Punkte P und Q in Längeneinheiten? ${R2}`,
  figur: { params: { x_min: -5, x_max: 5, y_min: -5, y_max: 5, punkte: [{ x: -3, y: 2, label: 'P' }, { x: 2, y: -1, label: 'Q' }] }, alt_text: ALT('P und Q') },
  r: 'W((2-(0-3))^2+(2-(0-1))^2)', n: 2,
  weg: 'Abgelesen: P(−3|2), Q(2|−1).\nUnterschied der x-Werte: 2 − (−3) = 5, der y-Werte: 2 − (−1) = 3.\nAbstand = √(5² + 3²) = √(25 + 9) = √34 ≈ {A} Längeneinheiten.',
  ke: [['vorzeichen_ignoriert', 'W((3-2)^2+(2-1)^2)', 'Die Vorzeichen übersehen: 3 − 2 = 1 und 2 − 1 = 1, also √2.', 'Wie viele Kästchen liegen zwischen P und Q in x-Richtung?'],
    ['wurzel_vergessen', '5^2+3^2', 'Abstand² = 34 ausgerechnet, aber die Wurzel nicht gezogen.', 'Hast du schon den Abstand oder erst sein Quadrat?', 'exakt'],
    ['wurzel_gliedweise', '5+3', 'Die Wurzel Glied für Glied gezogen: 5 + 3.', 'Ist der direkte Weg so lang wie der Weg über die Kästchenlinien?', 'exakt']] });
def({ ...AB, ref: 'pyth-abstand-05', titel: 'Abstand · Hafen und Leuchtturm auf einer Karte', einheit: 'km', afb: 'II', sach: true,
  afbGrund: 'Anwenden im Sachkontext: Karte als Koordinatensystem lesen, Luftlinie als Abstand zweier Punkte berechnen.',
  frage: `Die Abbildung zeigt eine Karte mit Gitter. Der Punkt H ist ein Hafen, der Punkt L ein Leuchtturm. Eine Längeneinheit entspricht 1 km.\n\nWie weit ist der Leuchtturm in Luftlinie vom Hafen entfernt? ${R1}`,
  figur: { params: { x_min: -5, x_max: 5, y_min: -3, y_max: 5, punkte: [{ x: -4, y: -2, label: 'H' }, { x: 3, y: 4, label: 'L' }] }, alt_text: 'Karte als Koordinatensystem mit Gitter und den Punkten H und L.' },
  r: 'W((3-(0-4))^2+(4-(0-2))^2)', n: 1,
  weg: 'Abgelesen: H(−4|−2), L(3|4).\nUnterschied der x-Werte: 3 − (−4) = 7, der y-Werte: 4 − (−2) = 6.\nAbstand = √(7² + 6²) = √(49 + 36) = √85 ≈ {A} km.',
  ke: [['vorzeichen_ignoriert', 'W((4-3)^2+(4-2)^2)', 'Die Vorzeichen übersehen: 4 − 3 = 1 und 4 − 2 = 2, also √5.', 'Wie viele Kästchen liegen zwischen H und L in x-Richtung?'],
    ['wurzel_vergessen', '7^2+6^2', 'Abstand² = 85 ausgerechnet, aber die Wurzel nicht gezogen.', 'Kann die Luftlinie länger sein als der Weg entlang der Gitterlinien?', 'exakt'],
    ['wurzel_gliedweise', '7+6', 'Die Wege entlang der Gitterlinien addiert: 7 + 6.', 'Ist die Luftlinie so lang wie der Weg erst nach rechts und dann nach oben?', 'exakt']] });
def({ ...AB, ref: 'pyth-abstand-06', titel: 'Abstand · fehlende Koordinate aus dem Abstand', afb: 'III', sach: false,
  afbGrund: 'Problemlösen: Rückrichtung – aus Abstand und einer Koordinatendifferenz die andere Differenz und daraus die Koordinate bestimmen.',
  frage: `Gegeben sind die Punkte P(−2|1) und Q(x|−5). Q liegt rechts von P. Der Abstand der Punkte P und Q beträgt 10 Längeneinheiten.\n\nWie groß ist die x-Koordinate von Q? ${EXAKT}`,
  r: '0-2+W(10^2-(1-(0-5))^2)', n: 'exakt',
  weg: 'Unterschied der y-Werte: 1 − (−5) = 6.\nUnterschied der x-Werte: √(10² − 6²) = √(100 − 36) = √64 = 8.\nQ liegt rechts von P: x = −2 + 8 = {A}.',
  ke: [['falsche_groesse_beantwortet', 'W(10^2-6^2)', 'Den Unterschied der x-Werte angegeben statt der Koordinate von Q.', 'Bei welcher x-Koordinate beginnst du, wenn du von P aus 8 Einheiten nach rechts gehst?'],
    ['wurzel_gliedweise', '0-2+(10-6)', 'Die Wurzel Glied für Glied gezogen: √(10² − 6²) als 10 − 6.', 'Ist √(100 − 36) dasselbe wie 10 − 6?'],
    ['wurzel_vergessen', '0-2+(10^2-6^2)', 'Den x-Unterschied als 64 genommen, ohne die Wurzel zu ziehen.', 'Ist 64 schon der Unterschied der x-Werte oder erst sein Quadrat?'],
    ['vorzeichen_ignoriert', '0-2+W(10^2-(5-1)^2)', 'Die Vorzeichen übersehen: y-Unterschied 5 − 1 = 4 statt 6.', 'Wie viele Einheiten liegen auf der y-Achse zwischen 1 und −5?', 2]] });

// ─── geo_pythagoras_anwendung (Tiefe 8) ───
const AN = { skill: 'geo_pythagoras_anwendung' };
def({ ...AN, ref: 'pyth-anwendung-01', titel: 'Anwendung · Diagonale eines Rechtecks 12 cm × 5 cm', einheit: 'cm', afb: 'I', sach: false,
  afbGrund: 'Reproduzieren: Diagonale als Hypotenuse im Rechteck erkennen, Ergebnis ganzzahlig.',
  frage: `Ein Rechteck ist 12 cm lang und 5 cm breit.\n\nWie lang ist seine Diagonale? ${EXAKT}`,
  r: 'W(12^2+5^2)', n: 'exakt',
  weg: 'Die Diagonale teilt das Rechteck in zwei rechtwinklige Dreiecke; sie ist die Hypotenuse.\nd² = 12² + 5² = 144 + 25 = 169.\nd = √169 = {A} cm.',
  ke: [['wurzel_gliedweise', '12+5', 'Die Wurzel Glied für Glied gezogen: d = 12 + 5.', 'Ist die Diagonale so lang wie zwei Seiten zusammen?'],
    ['wurzel_vergessen', '12^2+5^2', 'd² = 169 ausgerechnet, aber die Wurzel nicht gezogen.', 'Hast du schon die Diagonale oder erst ihr Quadrat?'],
    ['hypotenuse_verwechselt', 'W(12^2-5^2)', 'Die Quadrate subtrahiert: √(144 − 25).', 'Kann die Diagonale kürzer sein als die lange Seite?', 2]] });
def({ ...AN, ref: 'pyth-anwendung-02', titel: 'Anwendung · Höhe eines gleichseitigen Dreiecks mit 6 cm', einheit: 'cm', afb: 'I', sach: false,
  afbGrund: 'Reproduzieren: Höhe teilt das gleichseitige Dreieck in zwei rechtwinklige Dreiecke mit halber Grundseite.',
  frage: `Ein gleichseitiges Dreieck hat die Seitenlänge 6 cm.\n\nWie lang ist seine Höhe? ${R2}`,
  r: 'W(6^2-3^2)', n: 2,
  weg: 'Die Höhe halbiert die Grundseite: rechtwinkliges Dreieck mit Hypotenuse 6 cm und Kathete 3 cm.\nh² = 6² − 3² = 36 − 9 = 27.\nh = √27 ≈ {A} cm.',
  ke: [['hypotenuse_verwechselt', 'W(6^2+3^2)', 'Die Quadrate addiert: √(36 + 9).', 'Kann die Höhe länger sein als eine Seite des Dreiecks?'],
    ['wurzel_vergessen', '6^2-3^2', 'h² = 27 ausgerechnet, aber die Wurzel nicht gezogen.', 'Kann die Höhe länger sein als eine Seite des Dreiecks?'],
    ['wurzel_gliedweise', '6-3', 'Die Wurzel Glied für Glied gezogen: h = 6 − 3.', 'Ist √(36 − 9) dasselbe wie 6 − 3?']] });
def({ ...AN, ref: 'pyth-anwendung-03', titel: 'Anwendung · Raumdiagonale eines Quaders 4 × 6 × 10 cm', einheit: 'cm', afb: 'II', sach: false,
  afbGrund: 'Anwenden: zweimal Satz des Pythagoras – erst Flächendiagonale der Grundfläche, dann Raumdiagonale.',
  frage: `Ein Quader ist 4 cm breit, 6 cm tief und 10 cm hoch.\n\nWie lang ist seine Raumdiagonale? ${R1}`,
  r: 'W(4^2+6^2+10^2)', n: 1,
  weg: 'Diagonale der Grundfläche: e² = 4² + 6² = 16 + 36 = 52.\nRaumdiagonale: d² = e² + 10² = 52 + 100 = 152.\nd = √152 ≈ {A} cm.',
  ke: [['falsche_groesse_beantwortet', 'W(4^2+6^2)', 'Nur die Diagonale der Grundfläche angegeben, nicht die Raumdiagonale.', 'Geht deine Diagonale auch durch den Raum nach oben?'],
    ['wurzel_vergessen', '4^2+6^2+10^2', 'd² = 152 ausgerechnet, aber die Wurzel nicht gezogen.', 'Hast du schon die Diagonale oder erst ihr Quadrat?', 'exakt'],
    ['wurzel_gliedweise', '4+6+10', 'Die Wurzel Glied für Glied gezogen: 4 + 6 + 10.', 'Ist die Raumdiagonale so lang wie alle drei Kanten zusammen?', 'exakt']] });
def({ ...AN, ref: 'pyth-anwendung-04', titel: 'Anwendung · Flächeninhalt eines gleichseitigen Dreiecks mit 8 cm', einheit: 'cm²', afb: 'II', sach: false,
  afbGrund: 'Anwenden: Höhe mit dem Satz des Pythagoras, dann Flächeninhalt des Dreiecks.',
  frage: `Ein gleichseitiges Dreieck hat die Seitenlänge 8 cm.\n\nWie groß ist sein Flächeninhalt? ${R2}`,
  r: '8*W(8^2-4^2)/2', n: 2,
  weg: 'Höhe: h² = 8² − 4² = 64 − 16 = 48, h = √48 ≈ 6,928 cm.\nA = g · h : 2 = 8 cm · √48 cm : 2 ≈ {A} cm².\n(Erst am Ende runden.)',
  ke: [['halbieren_vergessen', '8*W(8^2-4^2)', 'Beim Flächeninhalt nicht halbiert: 8 · h.', 'Welcher Teil des Rechtecks mit den Seiten g und h ist das Dreieck?'],
    ['falsche_groesse_beantwortet', 'W(8^2-4^2)', 'Nur die Höhe angegeben statt des Flächeninhalts.', 'Ist nach der Höhe oder nach der Fläche gefragt?'],
    ['hypotenuse_verwechselt', '8*W(8^2+4^2)/2', 'Für die Höhe die Quadrate addiert: √(64 + 16).', 'Kann die Höhe länger sein als eine Seite des Dreiecks?']] });
def({ ...AN, ref: 'pyth-anwendung-05', titel: 'Anwendung · Leiter an einer Wand', einheit: 'm', afb: 'II', sach: true,
  afbGrund: 'Anwenden im Sachkontext: Leiter als Hypotenuse, Wandhöhe als Kathete erkennen.',
  frage: `Eine 5 m lange Leiter lehnt an einer senkrechten Hauswand. Ihr Fuß steht auf ebenem Boden 1,4 m von der Wand entfernt.\n\nIn welcher Höhe berührt die Leiter die Wand? ${EXAKT}`,
  r: 'W(5^2-1.4^2)', n: 'exakt',
  weg: 'Leiter (5 m) = Hypotenuse, Bodenabstand (1,4 m) und Höhe h = Katheten.\nh² = 5² − 1,4² = 25 − 1,96 = 23,04.\nh = √23,04 = {A} m.',
  ke: [['hypotenuse_verwechselt', 'W(5^2+1.4^2)', 'Die Quadrate addiert: √(25 + 1,96).', 'Kann die Leiter höher reichen, als sie lang ist?', 2],
    ['wurzel_vergessen', '5^2-1.4^2', 'h² = 23,04 ausgerechnet, aber die Wurzel nicht gezogen.', 'Kann die Leiter höher reichen, als sie lang ist?'],
    ['wurzel_gliedweise', '5-1.4', 'Die Wurzel Glied für Glied gezogen: h = 5 − 1,4.', 'Ist √(25 − 1,96) dasselbe wie 5 − 1,4?']] });
def({ ...AN, ref: 'pyth-anwendung-06', titel: 'Anwendung · Leiterfuß näher an die Wand rücken', einheit: 'cm', afb: 'III', sach: true, n: 0,
  afbGrund: 'Problemlösen: zwei Lagen der Leiter je mit dem Satz des Pythagoras berechnen, den Unterschied bilden und umrechnen.',
  frage: `Eine 4 m lange Leiter lehnt an einer senkrechten Wand und reicht bis in 3,60 m Höhe. Sie soll bis in 3,80 m Höhe reichen.\n\nUm wie viele Zentimeter muss ihr Fuß dafür näher an die Wand gerückt werden? Runde auf ganze Zentimeter.`,
  r: '(W(4^2-3.6^2)-W(4^2-3.8^2))*100',
  weg: 'Abstand vorher: √(4² − 3,6²) = √(16 − 12,96) = √3,04 ≈ 1,7436 m.\nAbstand nachher: √(4² − 3,8²) = √(16 − 14,44) = √1,56 ≈ 1,2490 m.\nUnterschied: 1,7436 m − 1,2490 m ≈ 0,4946 m ≈ {A} cm.\n(Erst am Ende runden.)',
  ke: [['falsche_groesse_beantwortet', 'W(4^2-3.8^2)*100', 'Den neuen Abstand des Fußes angegeben statt des Unterschieds.', 'Gefragt ist, um wie viel der Fuß gerückt wird – was fehlt noch?'],
    ['zu_frueh_gerundet', '(1.7-1.2)*100', 'Die Abstände vorher auf 1,7 m und 1,2 m gerundet: 50 cm.', 'Was passiert mit dem Unterschied, wenn du die Abstände vorher rundest?'],
    ['hypotenuse_verwechselt', '(W(4^2+3.8^2)-W(4^2+3.6^2))*100', 'Für die Abstände die Quadrate addiert statt subtrahiert.', 'Kann der Abstand am Boden länger sein als die Leiter?']] });

// ── Charge ─────────────────────────────────────────────────────────────────────
baueCharge({
  thema: 'pythagoras',
  batch: 'k9-pythagoras',
  source: 'edvance_k9_pythagoras',
  idsPfad: 'docs/prefill/k9-pythagoras-ids.json',
  kopf: [
    `K9-Rest, Thema pythagoras — ${A.length} Aufgaben: je sechs zu geo_pythagoras_hypotenuse, _kathete, _umkehrung, _abstand und _anwendung.`,
    'Erzeugt von tools/vorlauf-build.mjs aus docs/prefill/k9-pythagoras.json (Quelle: tools/k9-pythagoras-charge.mjs) — nicht von Hand editieren.',
    '',
    'Einspiel-Reihenfolge: nach 20261003105857_substrat_k9_pythagoras.sql (Knoten + Fehlbild-Slugs muessen stehen).',
  ],
  auswahl: 'Je Knoten vier reine Anwendung mit steigender Schwierigkeit und zwei mit Sachkontext oder Rückrichtung (Boot, Feld, Drachen, Mast, Gartenhaus, Latten, Karte, Leiter). Drei Abstands-Aufgaben mit Abbildung (Koordinatensystem, Punkte ablesen), alle übrigen ohne Abbildung lösbar. Jede Aufgabe nennt, ob exakt oder auf wie viele Stellen gerundet wird; Werte exakt nachgerechnet (Wurzel auf 40 Stellen).',
  aufgaben: A,
});
