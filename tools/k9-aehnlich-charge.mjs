#!/usr/bin/env node
/**
 * k9-aehnlich-charge.mjs — erzeugt docs/prefill/k9-aehnlich.json (Charge-Format von vorlauf-build.mjs).
 *
 *   node tools/k9-aehnlich-charge.mjs
 *
 * K9-Rest, Thema aehnlich: Streckfaktor, Flächen/Volumen bei Ähnlichkeit, erster und zweiter
 * Strahlensatz. Alles als Text ohne Abbildung. Jede Strahlensatzfigur wird mit demselben Satz
 * beschrieben (FIGUR): Scheitel S, erste Parallele durch A und B, zweite durch C und D, A zwischen
 * S und C, B zwischen S und D. Strecken heißen immer „von X bis Y". Jeder Wert wird über die
 * Ausdrücke von tools/k9-rest-lib.mjs exakt gerechnet.
 */

import { baueCharge, CLUSTER } from './k9-rest-lib.mjs';

const EXAKT = 'Gib das Ergebnis exakt an.';
const FIGUR = 'Zwei Strahlen beginnen im Punkt S. Eine Gerade schneidet den ersten Strahl im Punkt A und den zweiten im Punkt B. '
  + 'Eine dazu parallele Gerade schneidet den ersten Strahl im Punkt C und den zweiten im Punkt D. '
  + 'A liegt zwischen S und C, B zwischen S und D.';
const GEO = {
  cluster: CLUSTER.geo, inhalt: 'geometrie', stoff: 9,
  stoffGrund: 'Stoffanker Klasse 9: KLP G9 NRW, Zweite Stufe, Geo-2/Geo-9 (zentrische Streckung, Ähnlichkeit, Strahlensätze).',
  clusterGrund: 'Geometrie & Messen wie geo_massstab und die Kreis-Knoten im Bestand.',
  inhaltGrund: 'Inhaltsfeld Geometrie (Geo-2, Geo-9).',
};
const A = [];
const def = (o) => A.push({ ...GEO, n: 'exakt', ...o });

// ─── geo_aehnlich_streckfaktor (Tiefe 6) ───
const SF = { skill: 'geo_aehnlich_streckfaktor' };
def({ ...SF, ref: 'aehnlich-streckfaktor-01', titel: 'Streckfaktor · 4 cm werden 10 cm', afb: 'I', sach: false,
  afbGrund: 'Reproduzieren: k = Bild : Original, eine Division.',
  frage: `Bei einer zentrischen Streckung wird eine 4 cm lange Strecke auf eine 10 cm lange Bildstrecke abgebildet.\n\nWie groß ist der Streckfaktor k? Gib k exakt als Dezimalzahl an.`, r: '10/4',
  weg: 'k = Bildlänge : Originallänge = 10 cm : 4 cm = {A}.',
  ke: [['streckfaktor_kehrwert', '4/10', 'Original durch Bild geteilt: 4 : 10 = 0,4.', 'Wird die Strecke länger oder kürzer – muss k dann größer oder kleiner als 1 sein?'],
    ['additiv_statt_multiplikativ', '10-4', 'Den Zuwachs berechnet statt des Faktors: 10 − 4 = 6.', 'Ist k ein Unterschied oder ein Faktor, mit dem man malnimmt?']] });
def({ ...SF, ref: 'aehnlich-streckfaktor-02', titel: 'Bildlänge · 3,5 cm mit k = 4', einheit: 'cm', afb: 'I', sach: false,
  afbGrund: 'Reproduzieren: Bildlänge = k · Originallänge, eine Multiplikation.',
  frage: `Eine 3,5 cm lange Strecke wird zentrisch mit dem Streckfaktor k = 4 gestreckt.\n\nWie lang ist die Bildstrecke? ${EXAKT}`, r: '3.5*4',
  weg: 'Bildlänge = k · Originallänge = 4 · 3,5 cm = {A} cm.',
  ke: [['additiv_statt_multiplikativ', '3.5+4', 'k addiert statt multipliziert: 3,5 + 4 = 7,5.', 'Was bedeutet „Streckfaktor 4“ – 4 cm länger oder 4-mal so lang?'],
    ['streckfaktor_kehrwert', '3.5/4', 'Durch k geteilt statt mit k multipliziert: 3,5 : 4.', 'Bei k = 4 wird die Strecke größer oder kleiner?']] });
def({ ...SF, ref: 'aehnlich-streckfaktor-03', titel: 'Verkleinerung · Seite b aus a = 12 cm, a′ = 9 cm', einheit: 'cm', afb: 'II', sach: false,
  afbGrund: 'Anwenden: Streckfaktor einer Verkleinerung (0 < k < 1) bestimmen und auf eine zweite Seite anwenden.',
  frage: `Ein Dreieck wird zentrisch gestreckt. Die Seite a ist 12 cm lang, ihre Bildseite a′ nur 9 cm. Die Seite b des Dreiecks ist 6 cm lang.\n\nWie lang ist die Bildseite b′? ${EXAKT}`, r: '6*9/12',
  weg: 'k = 9 cm : 12 cm = 0,75 (Verkleinerung, k < 1).\nb′ = k · b = 0,75 · 6 cm = {A} cm.',
  ke: [['streckfaktor_kehrwert', '6*12/9', 'Mit dem Kehrwert gerechnet: k = 12 : 9, also b′ = 8 cm.', 'Wird das Dreieck größer oder kleiner – passt dazu ein b′ über 6 cm?'],
    ['additiv_statt_multiplikativ', '6-(12-9)', 'Gleich viel abgezogen wie bei a: 6 cm − 3 cm.', 'Wird jede Seite um gleich viel kürzer oder auf denselben Bruchteil verkleinert?']] });
def({ ...SF, ref: 'aehnlich-streckfaktor-04', titel: 'Rückrichtung · Original aus 7 cm Bild und k = 2,5', einheit: 'cm', afb: 'II', sach: false,
  afbGrund: 'Anwenden: Rückrichtung, Originallänge = Bildlänge : k mit Dezimalfaktor.',
  frage: `Bei einer zentrischen Streckung mit dem Streckfaktor k = 2,5 entsteht eine 7 cm lange Bildstrecke.\n\nWie lang war die Originalstrecke? ${EXAKT}`, r: '7/2.5',
  weg: 'Bildlänge = k · Originallänge, also Originallänge = Bildlänge : k.\nOriginallänge = 7 cm : 2,5 = {A} cm.',
  ke: [['streckfaktor_kehrwert', '7*2.5', 'Mit k multipliziert statt durch k geteilt: 7 · 2,5.', 'Ist die Originalstrecke bei k = 2,5 länger oder kürzer als ihr Bild?'],
    ['additiv_statt_multiplikativ', '7-2.5', 'k abgezogen statt durch k geteilt: 7 − 2,5.', 'Wie kommt man vom Bild zurück, wenn man beim Strecken malgenommen hat?']] });
def({ ...SF, ref: 'aehnlich-streckfaktor-05', titel: 'Foto · 9 cm × 13 cm auf 27 cm Breite vergrößert', einheit: 'cm', afb: 'II', sach: true,
  afbGrund: 'Anwenden im Sachkontext: Faktor aus einer Seite erkennen und auf die andere Seite übertragen.',
  frage: `Ein Foto ist 9 cm breit und 13 cm hoch. Es wird ohne Verzerrung vergrößert, sodass es 27 cm breit ist.\n\nWie hoch ist das vergrößerte Foto? ${EXAKT}`, r: '13*27/9',
  weg: 'k = 27 cm : 9 cm = 3.\nHöhe = 3 · 13 cm = {A} cm.',
  ke: [['additiv_statt_multiplikativ', '13+(27-9)', 'Zur Höhe dieselben 18 cm addiert wie zur Breite: 13 + 18.', 'Bleibt das Foto unverzerrt, wenn beide Seiten um gleich viel wachsen?'],
    ['falsche_groesse_beantwortet', '27/9', 'Nur den Vergrößerungsfaktor 3 angegeben.', 'Gefragt ist die Höhe in Zentimetern – was fehlt noch?'],
    ['streckfaktor_kehrwert', '13*9/27', 'Durch 3 geteilt statt mit 3 multipliziert: 13 : 3.', 'Wird das Foto größer oder kleiner?', 2]] });
def({ ...SF, ref: 'aehnlich-streckfaktor-06', titel: 'Rückrichtung · kürzeste Seite aus dem Bildumfang 45 cm', einheit: 'cm', afb: 'III', sach: false,
  afbGrund: 'Problemlösen: Den Streckfaktor über den Umfang erschließen, dann eine Seite strecken – Weg selbst finden.',
  frage: `Ein Dreieck hat die Seitenlängen 5 cm, 6 cm und 7 cm. Es wird zentrisch gestreckt. Das Bilddreieck hat den Umfang 45 cm.\n\nWie lang ist die kürzeste Seite des Bilddreiecks? ${EXAKT}`, r: '5*45/(5+6+7)',
  weg: 'Umfang des Originals: 5 cm + 6 cm + 7 cm = 18 cm.\nAuch der Umfang wird mit k gestreckt: k = 45 cm : 18 cm = 2,5.\nKürzeste Bildseite: 2,5 · 5 cm = {A} cm.',
  ke: [['additiv_statt_multiplikativ', '5+(45-18)/3', 'Den Zuwachs von 27 cm gleichmäßig verteilt: jede Seite 9 cm länger, also 14 cm.', 'Wäre das Bilddreieck dann noch ähnlich zum Original?'],
    ['streckfaktor_kehrwert', '5/(45/18)', 'Durch k geteilt statt mit k multipliziert: 5 : 2,5.', 'Das Bild hat einen größeren Umfang – muss die Seite länger oder kürzer werden?'],
    ['falsche_groesse_beantwortet', '45/18', 'Nur den Streckfaktor 2,5 angegeben.', 'Gefragt ist eine Seitenlänge – was musst du mit k noch tun?']] });

// ─── geo_aehnlich_flaeche (Tiefe 7) ───
const FL = { skill: 'geo_aehnlich_flaeche' };
def({ ...FL, ref: 'aehnlich-flaeche-01', titel: 'Bildfläche · 6 cm² mit k = 3', einheit: 'cm²', afb: 'I', sach: false,
  afbGrund: 'Reproduzieren: Flächen wachsen mit k², ein Schritt.',
  frage: `Eine Figur hat den Flächeninhalt 6 cm². Sie wird zentrisch mit dem Streckfaktor k = 3 gestreckt.\n\nWie groß ist der Flächeninhalt der Bildfigur? ${EXAKT}`, r: '6*3^2',
  weg: 'Flächen wachsen mit k²: A′ = k² · A = 3² · 6 cm² = 9 · 6 cm² = {A} cm².',
  ke: [['linearer_faktor', '6*3', 'Nur mit k multipliziert: 3 · 6 = 18.', 'Wenn Länge und Breite je 3-mal so groß werden – wie viel mal so groß wird die Fläche?'],
    ['mal_exponent', '6*2*3', 'k² als 2 · k gerechnet: 6 · 6 = 36.', 'Ist 3² dasselbe wie 2 · 3?']] });
def({ ...FL, ref: 'aehnlich-flaeche-02', titel: 'Volumen · 5 cm³ mit k = 2', einheit: 'cm³', afb: 'I', sach: false,
  afbGrund: 'Reproduzieren: Volumen wachsen mit k³, ein Schritt.',
  frage: `Ein Körper hat das Volumen 5 cm³. Ein dazu ähnlicher Körper ist mit dem Streckfaktor k = 2 vergrößert.\n\nWie groß ist das Volumen des vergrößerten Körpers? ${EXAKT}`, r: '5*2^3',
  weg: 'Volumen wachsen mit k³: V′ = k³ · V = 2³ · 5 cm³ = 8 · 5 cm³ = {A} cm³.',
  ke: [['linearer_faktor', '5*2', 'Nur mit k multipliziert: 2 · 5 = 10.', 'Wie viele Richtungen hat ein Körper – und in jeder wird mit k gestreckt?'],
    ['linearer_faktor', '5*2^2', 'Mit k² gerechnet wie bei Flächen: 4 · 5 = 20.', 'Wächst ein Volumen wie eine Fläche oder in einer Richtung mehr?'],
    ['mal_exponent', '5*3*2', 'k³ als 3 · k gerechnet: 6 · 5 = 30.', 'Ist 2³ dasselbe wie 3 · 2?']] });
def({ ...FL, ref: 'aehnlich-flaeche-03', titel: 'Streckfaktor aus 12 cm² und 75 cm²', afb: 'II', sach: false,
  afbGrund: 'Anwenden: Rückrichtung über das Flächenverhältnis, Wurzel ziehen.',
  frage: `Eine Figur mit dem Flächeninhalt 12 cm² wird zentrisch gestreckt. Die Bildfigur hat den Flächeninhalt 75 cm².\n\nWie groß ist der Streckfaktor k? Gib k exakt als Dezimalzahl an.`, r: 'W(75/12)',
  weg: 'Flächenverhältnis: k² = 75 cm² : 12 cm² = 6,25.\nk = √6,25 = {A}.',
  ke: [['linearer_faktor', '75/12', 'Das Flächenverhältnis als Streckfaktor genommen: 6,25.', 'Welcher Faktor gehört zu den Flächen – k oder k²?'],
    ['streckfaktor_kehrwert', 'W(12/75)', 'Original durch Bild geteilt: √(12 : 75) = 0,4.', 'Die Figur wird größer – muss k dann größer oder kleiner als 1 sein?'],
    ['wurzel_halbiert', '75/12/2', 'k² halbiert statt die Wurzel gezogen: 6,25 : 2.', 'Welche Zahl ergibt mit sich selbst multipliziert 6,25?']] });
def({ ...FL, ref: 'aehnlich-flaeche-04', titel: 'Volumen · ähnliche Quader mit Kanten 4 cm und 6 cm', einheit: 'cm³', afb: 'II', sach: false,
  afbGrund: 'Anwenden: Streckfaktor aus entsprechenden Kanten bestimmen, dann mit k³ rechnen.',
  frage: `Zwei Quader sind zueinander ähnlich. Eine Kante des kleinen Quaders ist 4 cm lang, die entsprechende Kante des großen Quaders 6 cm. Der kleine Quader hat das Volumen 32 cm³.\n\nWie groß ist das Volumen des großen Quaders? ${EXAKT}`, r: '32*(6/4)^3',
  weg: 'k = 6 cm : 4 cm = 1,5.\nk³ = 1,5³ = 3,375.\nV = 3,375 · 32 cm³ = {A} cm³.',
  ke: [['linearer_faktor', '32*6/4', 'Nur mit k multipliziert: 1,5 · 32 = 48.', 'Wird ein Körper nur in einer Richtung gestreckt?'],
    ['linearer_faktor', '32*(6/4)^2', 'Mit k² gerechnet wie bei Flächen: 2,25 · 32 = 72.', 'Ein Volumen hat drei Richtungen – welche Hochzahl gehört zu k?'],
    ['streckfaktor_kehrwert', '32*(4/6)^3', 'Mit dem Kehrwert 4 : 6 gerechnet: das Volumen wird kleiner.', 'Soll das Volumen des großen Quaders größer oder kleiner als 32 cm³ sein?', 2]] });
def({ ...FL, ref: 'aehnlich-flaeche-05', titel: 'Farbe · Wandbild mit 2,5-mal so langen Seiten', einheit: 'l', afb: 'II', sach: true,
  afbGrund: 'Anwenden im Sachkontext: Die Farbmenge als Fläche erkennen und mit k² rechnen.',
  frage: `Für ein Wandbild werden 0,4 Liter Farbe gebraucht. Ein zweites Wandbild hat dieselbe Form, aber alle Seiten sind 2,5-mal so lang. Die Farbe wird gleich dick aufgetragen.\n\nWie viele Liter Farbe braucht das zweite Wandbild? ${EXAKT}`, r: '0.4*2.5^2',
  weg: 'Die Farbmenge wächst wie die Fläche, also mit k².\nk² = 2,5² = 6,25.\nFarbe = 6,25 · 0,4 l = {A} l.',
  ke: [['linearer_faktor', '0.4*2.5', 'Nur mit k multipliziert: 2,5 · 0,4 = 1.', 'Hängt die Farbmenge an einer Länge oder an einer Fläche?'],
    ['mal_exponent', '0.4*2*2.5', '2,5² als 2 · 2,5 gerechnet: 5 · 0,4 = 2.', 'Ist 2,5² dasselbe wie 2 · 2,5?'],
    ['falsche_groesse_beantwortet', '2.5^2', 'Nur den Flächenfaktor 6,25 angegeben.', 'Gefragt ist die Farbmenge in Litern – was fehlt noch?']] });
def({ ...FL, ref: 'aehnlich-flaeche-06', titel: 'Modell · Tank im Maßstab 1 : 50 fasst 0,2 Liter', einheit: 'm³', afb: 'III', sach: true,
  afbGrund: 'Problemlösen im Sachkontext: Maßstab als Streckfaktor, k³ und Umrechnung von Litern in Kubikmeter verbinden.',
  frage: `Ein Modell eines Wassertanks ist im Maßstab 1 : 50 gebaut. Das Modell fasst 0,2 Liter.\n\nWie viele Kubikmeter fasst der echte Tank? ${EXAKT}`, r: '0.2*50^3/1000',
  weg: 'Der echte Tank ist in jeder Richtung 50-mal so groß: k = 50, Volumen wächst mit k³ = 125 000.\nV = 125 000 · 0,2 l = 25 000 l.\n1 m³ = 1000 l, also V = 25 000 l : 1000 = {A} m³.',
  ke: [['linearer_faktor', '0.2*50/1000', 'Nur mit k = 50 multipliziert: 10 l = 0,01 m³.', 'Wird der Tank nur in einer Richtung 50-mal so groß?'],
    ['linearer_faktor', '0.2*50^2/1000', 'Mit k² gerechnet wie bei Flächen: 500 l = 0,5 m³.', 'Ein Volumen hat drei Richtungen – welche Hochzahl gehört zu k?'],
    ['einheit_uebersprungen', '0.2*50^3', 'Nicht in Kubikmeter umgerechnet: 25 000 (Liter).', 'In welcher Einheit ist das Volumen gefragt?']] });

// ─── geo_aehnlich_strahlen_abschnitt (Tiefe 7) ───
const AB = { skill: 'geo_aehnlich_strahlen_abschnitt', einheit: 'cm' };
def({ ...AB, ref: 'aehnlich-abschnitt-01', titel: 'Erster Strahlensatz · SD aus SA, SC und SB', afb: 'I', sach: false,
  afbGrund: 'Reproduzieren: Verhältnisgleichung SD : SB = SC : SA direkt aufstellen.',
  frage: `${FIGUR}\n\nDie Strecke von S bis A ist 3 cm lang, die Strecke von S bis C 7,5 cm und die Strecke von S bis B 4 cm.\n\nWie lang ist die Strecke von S bis D? ${EXAKT}`, r: '4*7.5/3',
  weg: 'Erster Strahlensatz: SD : SB = SC : SA.\nSD = SB · SC : SA = 4 cm · 7,5 : 3 = {A} cm.',
  ke: [['strahlensatz_falsch_zugeordnet', '4*3/7.5', 'Die Verhältnisse vertauscht: SD = SB · SA : SC = 1,6 cm.', 'D liegt weiter von S entfernt als B – kann SD kürzer als SB sein?'],
    ['additiv_statt_multiplikativ', '4+(7.5-3)', 'Auf dem zweiten Strahl gleich viel addiert wie auf dem ersten: 4 cm + 4,5 cm.', 'Wachsen die Abschnitte um gleich viel oder im gleichen Verhältnis?']] });
def({ ...AB, ref: 'aehnlich-abschnitt-02', titel: 'Erster Strahlensatz · SC aus SA, SB und SD', afb: 'I', sach: false,
  afbGrund: 'Reproduzieren: Verhältnisgleichung aufstellen und nach dem gesuchten Abschnitt auflösen.',
  frage: `${FIGUR}\n\nDie Strecke von S bis A ist 2 cm lang, die Strecke von S bis B 5 cm und die Strecke von S bis D 15 cm.\n\nWie lang ist die Strecke von S bis C? ${EXAKT}`, r: '2*15/5',
  weg: 'Erster Strahlensatz: SC : SA = SD : SB.\nSC = SA · SD : SB = 2 cm · 15 : 5 = {A} cm.',
  ke: [['strahlensatz_falsch_zugeordnet', '5*15/2', 'Strecken falsch zugeordnet: SC = SB · SD : SA = 37,5 cm.', 'Welche Strecke liegt auf demselben Strahl wie SC?'],
    ['additiv_statt_multiplikativ', '2+(15-5)', 'Auf dem ersten Strahl gleich viel addiert wie auf dem zweiten: 2 cm + 10 cm.', 'Wachsen die Abschnitte um gleich viel oder im gleichen Verhältnis?']] });
def({ ...AB, ref: 'aehnlich-abschnitt-03', titel: 'Erster Strahlensatz · Teilstück BD', afb: 'II', sach: false,
  afbGrund: 'Anwenden: Gegeben und gesucht sind Teilstücke; ganze Strecke und Teilstück sauber trennen.',
  frage: `${FIGUR}\n\nDie Strecke von S bis A ist 4 cm lang, die Strecke von A bis C 6 cm und die Strecke von S bis B 5 cm.\n\nWie lang ist die Strecke von B bis D? ${EXAKT}`, r: '5*6/4',
  weg: 'Erster Strahlensatz für die Teilstücke: BD : SB = AC : SA.\nBD = SB · AC : SA = 5 cm · 6 : 4 = {A} cm.\nProbe: SC = 10 cm, SD = 5 cm · 10 : 4 = 12,5 cm, BD = 12,5 cm − 5 cm.',
  ke: [['strahlensatz_falsch_zugeordnet', '5*6/(4+6)', 'Teilstück AC mit der ganzen Strecke SC verglichen: BD = SB · AC : SC = 3 cm.', 'Gehört zu SB auf dem ersten Strahl SA oder SC?'],
    ['falsche_groesse_beantwortet', '5*(4+6)/4', 'Die ganze Strecke SD berechnet statt des Teilstücks BD.', 'Ist nach der Strecke von S bis D oder von B bis D gefragt?'],
    ['additiv_statt_multiplikativ', '6+(5-4)', 'Den Unterschied der Anfangsstücke addiert: 6 cm + 1 cm.', 'Wachsen die Abschnitte um gleich viel oder im gleichen Verhältnis?']] });
def({ ...AB, ref: 'aehnlich-abschnitt-04', titel: 'Erster Strahlensatz · BD aus SC, SD und AC', afb: 'II', sach: false,
  afbGrund: 'Anwenden: Teilstück auf dem zweiten Strahl aus ganzen Strecken und einem Teilstück.',
  frage: `${FIGUR}\n\nDie Strecke von S bis C ist 9 cm lang, die Strecke von A bis C 3 cm und die Strecke von S bis D 12 cm.\n\nWie lang ist die Strecke von B bis D? ${EXAKT}`, r: '12*3/9',
  weg: 'Erster Strahlensatz: BD : SD = AC : SC.\nBD = SD · AC : SC = 12 cm · 3 : 9 = {A} cm.\nProbe: SA = 6 cm, SB = 12 cm · 6 : 9 = 8 cm, BD = 12 cm − 8 cm.',
  ke: [['strahlensatz_falsch_zugeordnet', '12*3/(9-3)', 'BD : SD = AC : SA gesetzt, also SD mit SA statt mit SC verglichen: 12 · 3 : 6 = 6.', 'Zu SD gehört auf dem ersten Strahl welche Strecke – SA oder SC?'],
    ['falsche_groesse_beantwortet', '12*(9-3)/9', 'Die Strecke SB berechnet statt BD.', 'Ist nach der Strecke von S bis B oder von B bis D gefragt?']] });
def({ ...AB, ref: 'aehnlich-abschnitt-05', titel: 'Erster Strahlensatz · zwei Straßen mit parallelen Querstraßen', einheit: 'm', afb: 'II', sach: true,
  afbGrund: 'Anwenden im Sachkontext: Strahlensatzfigur in der Situation erkennen, Teilstück berechnen.',
  frage: `Zwei gerade Straßen gehen von einer Kreuzung S aus. Zwei zueinander parallele Querstraßen verbinden sie. Die erste Querstraße trifft die erste Straße im Punkt A und die zweite Straße im Punkt B. Die zweite Querstraße trifft die erste Straße im Punkt C und die zweite Straße im Punkt D. A liegt zwischen S und C, B zwischen S und D.\n\nVon S bis A sind es 240 m, von A bis C 360 m und von S bis B 300 m.\n\nWie lang ist der Weg von B bis D? ${EXAKT}`, r: '300*360/240',
  weg: 'Erster Strahlensatz: BD : SB = AC : SA.\nBD = 300 m · 360 : 240 = {A} m.',
  ke: [['strahlensatz_falsch_zugeordnet', '300*360/(240+360)', 'Das Teilstück AC mit der ganzen Strecke SC verglichen: 300 · 360 : 600 = 180.', 'Gehört zu SB auf der ersten Straße SA oder SC?'],
    ['falsche_groesse_beantwortet', '300*(240+360)/240', 'Die ganze Strecke von S bis D berechnet: 750 m.', 'Ist nach dem Weg von S bis D oder von B bis D gefragt?'],
    ['additiv_statt_multiplikativ', '360+(300-240)', 'Den Unterschied der Anfangsstücke addiert: 360 m + 60 m.', 'Wachsen die Abschnitte um gleich viel oder im gleichen Verhältnis?']] });
def({ ...AB, ref: 'aehnlich-abschnitt-06', titel: 'Erster Strahlensatz · Metallgestell mit parallelen Streben', einheit: 'm', afb: 'III', sach: true,
  afbGrund: 'Problemlösen im Sachkontext: Figur aus der Beschreibung aufbauen, erst SB, dann das Teilstück BD bestimmen.',
  frage: `Zwei gerade Metallstangen sind oben im Punkt S verbunden und laufen schräg auseinander nach unten. Zwei zueinander parallele Querstreben verbinden sie. Die obere Strebe ist an der ersten Stange im Punkt A und an der zweiten Stange im Punkt B befestigt, die untere Strebe an der ersten Stange im Punkt C und an der zweiten Stange im Punkt D. A liegt zwischen S und C, B zwischen S und D.\n\nAuf der ersten Stange ist es von S bis A 1 m und von S bis C 2,5 m. Auf der zweiten Stange ist es von S bis D 3 m.\n\nWie weit ist B auf der zweiten Stange von D entfernt? ${EXAKT}`, r: '3-3*1/2.5',
  weg: 'Erster Strahlensatz: SB : SD = SA : SC.\nSB = 3 m · 1 : 2,5 = 1,2 m.\nBD = SD − SB = 3 m − 1,2 m = {A} m.',
  ke: [['falsche_groesse_beantwortet', '3*1/2.5', 'Die Strecke SB angegeben statt des Abstands von B bis D.', 'Ist nach der Strecke von S bis B oder von B bis D gefragt?'],
    ['strahlensatz_falsch_zugeordnet', '3*1/(2.5-1)', 'SA mit dem Teilstück AC statt mit SC verglichen: 3 · 1 : 1,5 = 2.', 'Gehört zu SD auf der ersten Stange SC oder AC?'],
    ['additiv_statt_multiplikativ', '2.5-1', 'Auf der zweiten Stange denselben Abstand angenommen wie auf der ersten: 1,5 m.', 'Sind die Stangen gleich lang – wachsen die Abschnitte um gleich viel oder im gleichen Verhältnis?']] });

// ─── geo_aehnlich_strahlen_parallel (Tiefe 8) ───
const PA = { skill: 'geo_aehnlich_strahlen_parallel', einheit: 'cm' };
def({ ...PA, ref: 'aehnlich-parallel-01', titel: 'Zweiter Strahlensatz · CD aus SA, SC und AB', afb: 'I', sach: false,
  afbGrund: 'Reproduzieren: Verhältnisgleichung CD : AB = SC : SA direkt aufstellen.',
  frage: `${FIGUR}\n\nDie Strecke von S bis A ist 2 cm lang, die Strecke von S bis C 5 cm und die Strecke von A bis B 3 cm.\n\nWie lang ist die Strecke von C bis D? ${EXAKT}`, r: '3*5/2',
  weg: 'Zweiter Strahlensatz: CD : AB = SC : SA.\nCD = AB · SC : SA = 3 cm · 5 : 2 = {A} cm.',
  ke: [['strahlensatz_falsch_zugeordnet', '3*2/5', 'Die Verhältnisse vertauscht: CD = AB · SA : SC = 1,2 cm.', 'Die Parallele durch C liegt weiter von S entfernt – muss CD länger oder kürzer als AB sein?'],
    ['additiv_statt_multiplikativ', '3+(5-2)', 'Gleich viel addiert wie auf dem Strahl: 3 cm + 3 cm.', 'Wachsen die Parallelstrecken um gleich viel oder im gleichen Verhältnis?']] });
def({ ...PA, ref: 'aehnlich-parallel-02', titel: 'Zweiter Strahlensatz · SA aus den Parallelstrecken', afb: 'I', sach: false,
  afbGrund: 'Reproduzieren: Verhältnisgleichung aufstellen und nach dem Scheitelabschnitt auflösen.',
  frage: `${FIGUR}\n\nDie Strecke von S bis C ist 10 cm lang, die Strecke von A bis B 3 cm und die Strecke von C bis D 7,5 cm.\n\nWie lang ist die Strecke von S bis A? ${EXAKT}`, r: '10*3/7.5',
  weg: 'Zweiter Strahlensatz: SA : SC = AB : CD.\nSA = SC · AB : CD = 10 cm · 3 : 7,5 = {A} cm.',
  ke: [['strahlensatz_falsch_zugeordnet', '10*7.5/3', 'Die Parallelstrecken vertauscht: SA = SC · CD : AB = 25 cm.', 'A liegt zwischen S und C – kann SA länger als SC sein?'],
    ['additiv_statt_multiplikativ', '10-(7.5-3)', 'Denselben Unterschied abgezogen wie bei den Parallelen: 10 cm − 4,5 cm.', 'Hängen die Strecken über einen Unterschied oder über ein Verhältnis zusammen?']] });
def({ ...PA, ref: 'aehnlich-parallel-03', titel: 'Zweiter Strahlensatz · CD aus SA, AC und AB', afb: 'II', sach: false,
  afbGrund: 'Anwenden: Aus dem Teilstück AC erst SC bilden, dann den zweiten Strahlensatz anwenden.',
  frage: `${FIGUR}\n\nDie Strecke von S bis A ist 5 cm lang, die Strecke von A bis C 3 cm und die Strecke von A bis B 4 cm.\n\nWie lang ist die Strecke von C bis D? ${EXAKT}`, r: '4*(5+3)/5',
  weg: 'SC = SA + AC = 5 cm + 3 cm = 8 cm.\nZweiter Strahlensatz: CD : AB = SC : SA.\nCD = 4 cm · 8 : 5 = {A} cm.',
  ke: [['strahlensatz_falsch_zugeordnet', '4*3/5', 'Das Teilstück AC statt der ganzen Strecke SC verwendet: 4 · 3 : 5 = 2,4.', 'Gehört zu den Parallelstrecken das Teilstück AC oder die Strecke vom Scheitel S aus?'],
    ['streckfaktor_kehrwert', '4*5/(5+3)', 'Mit dem Kehrwert des Faktors gerechnet: 4 · 5 : 8 = 2,5.', 'Muss CD länger oder kürzer als AB sein?'],
    ['additiv_statt_multiplikativ', '4+3', 'AC einfach zu AB addiert: 4 cm + 3 cm.', 'Wachsen die Parallelstrecken um gleich viel oder im gleichen Verhältnis?']] });
def({ ...PA, ref: 'aehnlich-parallel-04', titel: 'Zweiter Strahlensatz · AB aus SB, BD und CD', afb: 'II', sach: false,
  afbGrund: 'Anwenden: Werte auf dem zweiten Strahl, Teilstück BD, Rückrichtung zur kürzeren Parallelstrecke.',
  frage: `${FIGUR}\n\nDie Strecke von S bis B ist 6 cm lang, die Strecke von B bis D 4,5 cm und die Strecke von C bis D 7 cm.\n\nWie lang ist die Strecke von A bis B? ${EXAKT}`, r: '7*6/(6+4.5)',
  weg: 'SD = SB + BD = 6 cm + 4,5 cm = 10,5 cm.\nZweiter Strahlensatz: AB : CD = SB : SD.\nAB = 7 cm · 6 : 10,5 = {A} cm.',
  ke: [['strahlensatz_falsch_zugeordnet', '7*4.5/6', 'Das Teilstück BD mit SB verglichen: 7 · 4,5 : 6 = 5,25.', 'Gehört zu den Parallelstrecken das Teilstück BD oder die Strecke vom Scheitel S aus?'],
    ['strahlensatz_falsch_zugeordnet', '7*(6+4.5)/6', 'Die Verhältnisse vertauscht: 7 · 10,5 : 6 = 12,25.', 'AB liegt näher an S als CD – muss AB länger oder kürzer sein?'],
    ['additiv_statt_multiplikativ', '7-4.5', 'Den Abschnitt BD von CD abgezogen: 7 cm − 4,5 cm.', 'Hängen die Strecken über einen Unterschied oder über ein Verhältnis zusammen?']] });
def({ ...PA, ref: 'aehnlich-parallel-05', titel: 'Zweiter Strahlensatz · Baumhöhe über den Schatten', einheit: 'm', afb: 'II', sach: true,
  afbGrund: 'Anwenden im Sachkontext: Stab und Baum als Parallelstrecken, Schatten als Abschnitte erkennen.',
  frage: `Ein 1,5 m langer Stab steht senkrecht auf ebenem Boden und wirft einen 2 m langen Schatten. Ein senkrecht stehender Baum wirft zur selben Zeit einen 12 m langen Schatten.\n\nWie hoch ist der Baum? ${EXAKT}`, r: '1.5*12/2',
  weg: 'Die Sonnenstrahlen sind parallel; Höhe und Schatten stehen beim Stab und beim Baum im selben Verhältnis.\nHöhe : 12 m = 1,5 m : 2 m.\nHöhe = 1,5 m · 12 : 2 = {A} m.',
  ke: [['strahlensatz_falsch_zugeordnet', '2*12/1.5', 'Höhe und Schatten vertauscht: 2 · 12 : 1,5 = 16.', 'Der Stab ist kürzer als sein Schatten – gilt das dann auch für den Baum?'],
    ['additiv_statt_multiplikativ', '1.5+(12-2)', 'Zur Stabhöhe den Unterschied der Schatten addiert: 1,5 m + 10 m.', 'Wächst die Höhe um gleich viel wie der Schatten oder im gleichen Verhältnis?']] });
def({ ...PA, ref: 'aehnlich-parallel-06', titel: 'Zweiter Strahlensatz · Baumhöhe über einen Peilstab', einheit: 'm', afb: 'III', sach: true,
  afbGrund: 'Problemlösen im Sachkontext: Strahlensatzfigur aus der Beschreibung bilden, die ganze Strecke von S bis zum Baum zusammensetzen.',
  frage: `Auf ebenem Boden liegen ein Punkt S, der Fußpunkt eines senkrechten, 1,6 m hohen Stabs und der Fußpunkt eines senkrechten Baums in dieser Reihenfolge auf einer Geraden. Der Punkt S ist 2,5 m vom Stab entfernt, der Stab steht 10 m vom Baum entfernt. Die Gerade durch S und die Spitze des Stabs geht genau durch die Spitze des Baums.\n\nWie hoch ist der Baum? ${EXAKT}`, r: '1.6*(2.5+10)/2.5',
  weg: 'Entfernung von S bis zum Baum: 2,5 m + 10 m = 12,5 m.\nStab und Baum sind parallel. Zweiter Strahlensatz: Höhe : 1,6 m = 12,5 m : 2,5 m.\nHöhe = 1,6 m · 12,5 : 2,5 = {A} m.',
  ke: [['strahlensatz_falsch_zugeordnet', '1.6*10/2.5', 'Den Abstand Stab–Baum statt der ganzen Strecke von S bis zum Baum verwendet: 1,6 · 10 : 2,5 = 6,4.', 'Gemessen von welchem Punkt aus stehen die Entfernungen im Verhältnis der Höhen?'],
    ['streckfaktor_kehrwert', '1.6*2.5/(2.5+10)', 'Mit dem Kehrwert des Faktors gerechnet: 1,6 · 2,5 : 12,5 = 0,32.', 'Ist der Baum weiter von S entfernt als der Stab – muss er dann höher oder niedriger sein?'],
    ['additiv_statt_multiplikativ', '1.6+10', 'Den Abstand zum Baum einfach zur Stabhöhe addiert: 1,6 m + 10 m.', 'Wächst die Höhe um gleich viel wie die Entfernung oder im gleichen Verhältnis?']] });

baueCharge({
  thema: 'aehnlich',
  batch: 'k9-aehnlich',
  source: 'edvance_k9_aehnlich',
  idsPfad: 'docs/prefill/k9-aehnlich-ids.json',
  kopf: [
    `K9-Rest, Thema aehnlich — ${A.length} Aufgaben: je sechs zu geo_aehnlich_streckfaktor, _flaeche, _strahlen_abschnitt und _strahlen_parallel.`,
    'Erzeugt von tools/vorlauf-build.mjs aus docs/prefill/k9-aehnlich.json (Quelle: tools/k9-aehnlich-charge.mjs) — nicht von Hand editieren.',
    '',
    'Einspiel-Reihenfolge: nach 20261003105900_substrat_k9_aehnlich.sql (Knoten + Fehlbild-Slugs muessen stehen).',
  ],
  auswahl: 'Je Knoten vier reine Anwendung mit steigender Schwierigkeit (AFB I, I, II, II), eine mit Sachkontext (AFB II) und eine Sachkontext- oder Rückrichtungsaufgabe (AFB III): Foto, Umfang des Bilddreiecks, Wandfarbe, Tankmodell im Maßstab, Straßen mit Querstraßen, Metallgestell, Schatten, Peilstab. Alles als Text ohne Abbildung; jede Strahlensatzfigur ist mit Scheitel S, Parallelen durch A, B und C, D und der Lage „A zwischen S und C, B zwischen S und D“ vollständig beschrieben. Alle Ergebnisse exakt.',
  aufgaben: A,
});
