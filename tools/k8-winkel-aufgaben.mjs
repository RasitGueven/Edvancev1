/**
 * k8-winkel-aufgaben.mjs — die 24 Aufgaben des Laufs K8-Rest, Thema 4 (Thales und Winkelsätze).
 * Gebaut wird die Charge von tools/k8-winkel-charge.mjs; dort wird jede Zahl nachgerechnet.
 *
 * Felder je Aufgabe:
 *   ref, skill, titel, frage, afb, afbGrund, sach (Sachkontext: +30 s), prozess,
 *   antwort, r (Rechnung zur Antwort), weg (Lösungsweg), figur? (Generator winkel),
 *   ke: [falscher Wert, Slug, Rechnung, Fehlertext, sokratische Frage]
 * Einheit ist überall ° (fester Zusatz am Eingabefeld). Alle Werte ganzzahlig und positiv.
 * Lagen werden im Text beschrieben (kein Generator zeichnet Parallelen, Dreiecke, Kreise).
 */

export const A = [];
const def = (o) => A.push(o);

const W = 'winkelbeziehung_verwechselt';
const B = 'basiswinkel_falsch_zugeordnet';
const R = 'rechter_winkel_falsche_ecke';
const AU = 'aussenwinkel_verwechselt';
const S360 = 'summe_360_statt_180';
const D = 'differenz_vergessen';
const HV = 'halbieren_vergessen';

const figur = (grad) => ({
  generator: 'winkel',
  params: { grad, benennung: 'α', mit_bogen: true },
  alt_text: 'Ein Winkel α: zwei Schenkel mit gemeinsamem Scheitel, Winkelbogen und Gradangabe.',
});

// ─── geo_winkel_neben_scheitel (Tiefe 2) ─────────────────────────────────────
const NS = 'geo_winkel_neben_scheitel';
const KREUZ = 'Zwei Geraden schneiden sich im Punkt S. Rund um S liegen der Reihe nach die vier Winkel α, β, γ und δ: α liegt γ gegenüber, β liegt δ gegenüber.';
def({ ref: 'winkel-neben-01', skill: NS, titel: 'Nebenwinkel · Winkel aus der Abbildung',
  frage: 'Die Abbildung zeigt den Winkel α. Verlängert man einen seiner Schenkel über den Scheitel hinaus, entsteht ein Nebenwinkel von α.\n\nWie groß ist dieser Nebenwinkel?',
  figur: figur(50), afb: 'I', afbGrund: 'Reproduzieren: Nebenwinkel als Ergänzung zu 180°, Gradzahl im Bild.',
  sach: false, prozess: 'Operieren', antwort: '130', r: '180-50',
  weg: 'α = 50° (Abbildung).\nNebenwinkel ergänzen sich zu 180°: 180° - 50° = 130°.',
  ke: [
    ['50', W, '50', 'Den Nebenwinkel für gleich groß gehalten: 50°.', 'Bilden α und sein Nebenwinkel zusammen eine gerade Linie? Wie viel Grad hat sie?'],
    ['310', S360, '360-50', 'Zu 360° statt zu 180° ergänzt: 360° - 50° = 310°.', 'Ist der Nebenwinkel spitz, stumpf oder überstumpf?'],
  ] });
def({ ref: 'winkel-neben-02', skill: NS, titel: 'Scheitelwinkel · Winkel aus der Abbildung',
  frage: 'Die Abbildung zeigt den Winkel α. Verlängert man beide Schenkel über den Scheitel hinaus, entsteht gegenüber von α sein Scheitelwinkel.\n\nWie groß ist der Scheitelwinkel von α?',
  figur: figur(115), afb: 'I', afbGrund: 'Reproduzieren: Scheitelwinkel sind gleich groß, Gradzahl im Bild.',
  sach: false, prozess: 'Operieren', antwort: '115', r: '115',
  weg: 'α = 115° (Abbildung).\nScheitelwinkel sind gleich groß: Der Scheitelwinkel ist 115°.',
  ke: [
    ['65', W, '180-115', 'Den Scheitelwinkel wie einen Nebenwinkel zu 180° ergänzt: 180° - 115° = 65°.', 'Liegt der gesuchte Winkel neben α oder gegenüber?'],
  ] });
def({ ref: 'winkel-neben-03', skill: NS, titel: 'Nebenwinkel · Schnitt zweier Geraden',
  frage: `${KREUZ} Der Winkel α ist 72° groß.\n\nWie groß ist β?`,
  afb: 'II', afbGrund: 'Anwenden: Lage aus dem Text erschließen (β liegt neben α), dann Nebenwinkel.',
  sach: false, prozess: 'Operieren', antwort: '108', r: '180-72',
  weg: 'β liegt neben α, beide zusammen bilden eine gerade Linie: Nebenwinkel.\nβ = 180° - 72° = 108°.',
  ke: [
    ['72', W, '72', 'β für den Scheitelwinkel von α gehalten: 72°.', 'Liegt β gegenüber von α oder direkt daneben?'],
    ['288', S360, '360-72', 'Zu 360° statt zu 180° ergänzt: 360° - 72° = 288°.', 'Wie viel Grad haben zwei Winkel, die zusammen eine gerade Linie bilden?'],
  ] });
def({ ref: 'winkel-neben-04', skill: NS, titel: 'Neben- und Scheitelwinkel · Summe zweier Gegenwinkel',
  frage: `${KREUZ} Die Winkel α und γ sind zusammen 140° groß.\n\nWie groß ist β?`,
  afb: 'II', afbGrund: 'Anwenden: Scheitelwinkel (α = γ) und Nebenwinkel kombinieren, zwei Schritte.',
  sach: false, prozess: 'Problemlösen', antwort: '110', r: '180-140/2',
  weg: 'α und γ sind Scheitelwinkel, also gleich groß: α = 140° : 2 = 70°.\nβ ist Nebenwinkel von α: β = 180° - 70° = 110°.',
  ke: [
    ['70', W, '140/2', 'β für gleich groß wie α gehalten: 70°.', 'Liegt β gegenüber von α oder direkt daneben?'],
    ['220', HV, '360-140', 'β und δ zusammen berechnet, aber nicht halbiert: 360° - 140° = 220°.', 'Ist 220° ein einzelner Winkel oder zwei zusammen?'],
  ] });
def({ ref: 'winkel-neben-05', skill: NS, titel: 'Nebenwinkel · Leiter auf dem Boden',
  frage: 'Eine gerade Leiter lehnt an einer Wand und steht auf einem waagerechten Boden. Auf der Seite zur Wand hin bilden Leiter und Boden einen Winkel von 68°.\n\nWie groß ist der Winkel zwischen Leiter und Boden auf der anderen Seite der Leiter, von der Wand weg?',
  afb: 'II', afbGrund: 'Anwenden im Sachkontext: Die beiden Winkel am Fuß der Leiter als Nebenwinkel erkennen.',
  sach: true, prozess: 'Modellieren', antwort: '112', r: '180-68',
  weg: 'Der Boden ist eine gerade Linie; die Leiter teilt den gestreckten Winkel am Fuß in zwei Nebenwinkel.\n180° - 68° = 112°.',
  ke: [
    ['68', W, '68', 'Den Winkel auf der anderen Seite für gleich groß gehalten: 68°.', 'Ergeben die beiden Winkel am Fuß der Leiter zusammen den geraden Boden?'],
    ['292', S360, '360-68', 'Zu 360° statt zu 180° ergänzt: 360° - 68° = 292°.', 'Wie viel Grad hat der gerade Boden an der Stelle, an der die Leiter steht?'],
  ] });
def({ ref: 'winkel-neben-06', skill: NS, titel: 'Nebenwinkel · Kreuzung, ein Winkel viermal so groß',
  frage: 'Zwei gerade Straßen kreuzen sich. An der Kreuzung entstehen vier Winkel. Einer davon ist viermal so groß wie ein Winkel, der direkt neben ihm liegt.\n\nWie groß ist der kleinere dieser beiden Winkel?',
  afb: 'II', afbGrund: 'Rückrichtung: aus dem Verhältnis zweier Nebenwinkel und ihrer Summe 180° den kleineren bestimmen.',
  sach: true, prozess: 'Problemlösen', antwort: '36', r: '180/5',
  weg: 'Zwei Winkel, die direkt nebeneinander liegen, sind Nebenwinkel: zusammen 180°.\nKleiner Winkel x, großer 4x: x + 4x = 5x = 180°, also x = 36°.\n(Probe: 4 · 36° = 144°, 36° + 144° = 180°.)',
  ke: [
    ['72', S360, '360/5', 'Mit 360° statt 180° gerechnet: 360° : 5 = 72°.', 'Wie viel Grad haben zwei Winkel, die direkt nebeneinander an einer geraden Straße liegen?'],
  ] });

// ─── geo_winkel_parallelen (Tiefe 3) ─────────────────────────────────────────
const PA = 'geo_winkel_parallelen';
const PAR = 'Die Geraden g und h sind parallel, g liegt oberhalb von h. Eine dritte Gerade s schneidet g im Punkt A und h im Punkt B.';
def({ ref: 'winkel-parallel-01', skill: PA, titel: 'Stufenwinkel · benannt',
  frage: `${PAR} Der Winkel α liegt bei A oberhalb von g und rechts von s, er ist 65° groß. Der Winkel β liegt bei B oberhalb von h und rechts von s. α und β sind Stufenwinkel.\n\nWie groß ist β?`,
  afb: 'I', afbGrund: 'Reproduzieren: Stufenwinkel an Parallelen sind gleich groß, Beziehung genannt.',
  sach: false, prozess: 'Operieren', antwort: '65', r: '65',
  weg: 'Stufenwinkel an parallelen Geraden sind gleich groß: β = α = 65°.',
  ke: [
    ['115', W, '180-65', 'Stufenwinkel zu 180° ergänzt: 180° - 65° = 115°.', 'Liegen α und β an ihrer Geraden an derselben Stelle – oben rechts?'],
  ] });
def({ ref: 'winkel-parallel-02', skill: PA, titel: 'Wechselwinkel · benannt',
  frage: `${PAR} Der Winkel α liegt bei A unterhalb von g und rechts von s, er ist 48° groß. Der Winkel β liegt bei B oberhalb von h und links von s. α und β sind Wechselwinkel.\n\nWie groß ist β?`,
  afb: 'I', afbGrund: 'Reproduzieren: Wechselwinkel an Parallelen sind gleich groß, Beziehung genannt.',
  sach: false, prozess: 'Operieren', antwort: '48', r: '48',
  weg: 'Wechselwinkel an parallelen Geraden sind gleich groß: β = α = 48°.',
  ke: [
    ['132', W, '180-48', 'Wechselwinkel zu 180° ergänzt: 180° - 48° = 132°.', 'Was gilt für Wechselwinkel an Parallelen: gleich groß oder zusammen 180°?'],
  ] });
def({ ref: 'winkel-parallel-03', skill: PA, titel: 'Stufen- und Nebenwinkel · Lage gegeben',
  frage: `${PAR} Der Winkel α liegt bei A oberhalb von g und rechts von s, er ist 70° groß. Der Winkel β liegt bei B oberhalb von h und links von s.\n\nWie groß ist β?`,
  afb: 'II', afbGrund: 'Anwenden: Beziehung selbst erkennen, zwei Schritte (Stufenwinkel, dann Nebenwinkel).',
  sach: false, prozess: 'Operieren', antwort: '110', r: '180-70',
  weg: 'Bei B oberhalb von h und rechts von s liegt der Stufenwinkel von α: 70°.\nβ ist dessen Nebenwinkel: β = 180° - 70° = 110°.',
  ke: [
    ['70', W, '70', 'β für einen Stufenwinkel von α gehalten: 70°.', 'Liegt β bei B auf derselben Seite von s wie α bei A?'],
    ['290', S360, '360-70', 'Zu 360° statt zu 180° ergänzt: 360° - 70° = 290°.', 'Wie viel Grad haben zwei Nebenwinkel zusammen?'],
  ] });
def({ ref: 'winkel-parallel-04', skill: PA, titel: 'Wechsel-, Stufen- und Nebenwinkel · Lage gegeben',
  frage: `${PAR} Der Winkel α liegt bei A unterhalb von g und rechts von s, er ist 105° groß. Der Winkel β liegt bei B unterhalb von h und links von s.\n\nWie groß ist β?`,
  afb: 'II', afbGrund: 'Anwenden: Beziehung selbst erkennen, Kette aus Nebenwinkel und Wechselwinkel.',
  sach: false, prozess: 'Problemlösen', antwort: '75', r: '180-105',
  weg: 'Bei A oberhalb von g und rechts von s liegt der Nebenwinkel von α: 180° - 105° = 75°.\nDessen Stufenwinkel bei B (oberhalb von h, rechts von s) ist ebenfalls 75°, und β ist sein Scheitelwinkel: β = 75°.',
  ke: [
    ['105', W, '105', 'β für gleich groß wie α gehalten: 105°.', 'Ist β spitz oder stumpf, wenn α stumpf ist und β auf der anderen Seite von s liegt?'],
    ['255', S360, '360-105', 'Zu 360° statt zu 180° ergänzt: 360° - 105° = 255°.', 'Kann ein Winkel zwischen zwei Geraden größer als 180° sein?'],
  ] });
def({ ref: 'winkel-parallel-05', skill: PA, titel: 'Nachbarwinkel · Weg über zwei Bahnschienen',
  frage: 'Zwei gerade Bahnschienen verlaufen parallel. Ein gerader Weg überquert beide Schienen schräg. Zwischen den Schienen bildet der Weg mit der ersten Schiene auf der rechten Seite des Weges einen Winkel von 58°.\n\nWie groß ist der Winkel, den der Weg zwischen den Schienen mit der zweiten Schiene auf der rechten Seite des Weges bildet?',
  afb: 'II', afbGrund: 'Anwenden im Sachkontext: Lage übersetzen, Beziehung selbst erkennen (Ergänzung zu 180°).',
  sach: true, prozess: 'Modellieren', antwort: '122', r: '180-58',
  weg: 'Schienen = Parallelen, Weg = schneidende Gerade. Beide Winkel liegen zwischen den Schienen auf derselben Seite des Weges.\nDer Stufenwinkel des 58°-Winkels an der zweiten Schiene liegt außerhalb der Schienen; der gesuchte Winkel ist sein Nebenwinkel: 180° - 58° = 122°.',
  ke: [
    ['58', W, '58', 'Die beiden Winkel für gleich groß gehalten: 58°.', 'Liegen beide Winkel auf derselben Seite des Weges und zwischen den Schienen – was gilt dann?'],
    ['302', S360, '360-58', 'Zu 360° statt zu 180° ergänzt: 360° - 58° = 302°.', 'Kann der Winkel zwischen Weg und Schiene größer als 180° sein?'],
  ] });
def({ ref: 'winkel-parallel-06', skill: PA, titel: 'Wechselwinkel · schräge Querlatte am Zaun',
  frage: 'Bei einem Gartenzaun stehen die senkrechten Latten parallel zueinander. Eine gerade Querlatte ist schräg über alle Latten genagelt. An der ersten Latte schließen Latte und Querlatte oberhalb der Querlatte und rechts der Latte einen Winkel von 112° ein.\n\nWie groß ist an der zweiten Latte, die rechts neben der ersten steht, der Winkel unterhalb der Querlatte und links der Latte?',
  afb: 'II', afbGrund: 'Anwenden im Sachkontext: Beziehung selbst erkennen (Wechselwinkel zwischen zwei Latten).',
  sach: true, prozess: 'Modellieren', antwort: '112', r: '112',
  weg: 'Latten = Parallelen, Querlatte = schneidende Gerade. Beide Winkel liegen zwischen den beiden Latten, auf verschiedenen Seiten der Querlatte: Wechselwinkel.\nWechselwinkel sind gleich groß: 112°.',
  ke: [
    ['68', W, '180-112', 'Wechselwinkel zu 180° ergänzt: 180° - 112° = 68°.', 'Liegen die beiden Winkel auf derselben Seite der Querlatte oder auf verschiedenen?'],
  ] });

// Dreieck und Thales: tools/k8-winkel-aufgaben-2.mjs (Dateigröße).
export { W, B, R, AU, S360, D, HV };
