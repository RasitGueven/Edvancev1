/**
 * k8-winkel-aufgaben-2.mjs — zweite Hälfte der Aufgaben (Dreieck, Thales), Feldbeschreibung
 * in tools/k8-winkel-aufgaben.mjs. Getrennt nur wegen der Dateigröße (CLAUDE.md, 400 Zeilen).
 */

import { B, R, AU, S360, D, HV } from './k8-winkel-aufgaben.mjs';

export const A2 = [];
const def = (o) => A2.push(o);

// ─── geo_winkel_dreieck (Tiefe 4) ────────────────────────────────────────────
const DR = 'geo_winkel_dreieck';
const GLS = 'Das Dreieck ABC ist gleichschenklig mit den gleich langen Seiten AC und BC.';
def({ ref: 'winkel-dreieck-01', skill: DR, titel: 'Basiswinkel · aus dem Winkel an der Spitze',
  frage: `${GLS} Der Winkel γ bei C ist 40° groß.\n\nWie groß ist der Winkel α bei A?`,
  afb: 'I', afbGrund: 'Reproduzieren: Basiswinkelsatz und Winkelsumme, Spitze gegeben.',
  sach: false, prozess: 'Operieren', antwort: '70', r: '(180-40)/2',
  weg: 'C liegt zwischen den gleich langen Seiten, also ist γ der Winkel an der Spitze; α und β sind die gleich großen Basiswinkel.\nα = (180° - 40°) : 2 = 70°.',
  ke: [
    ['40', B, '40', 'Den Winkel an der Spitze für einen Basiswinkel gehalten: α = 40°.', 'Welche Ecke liegt zwischen den beiden gleich langen Seiten?'],
    ['140', HV, '180-40', 'Den Rest für beide Basiswinkel zusammen nicht halbiert: 180° - 40° = 140°.', 'Wie viele Basiswinkel teilen sich die restlichen 140°?'],
    ['160', S360, '(360-40)/2', 'Mit 360° statt 180° als Winkelsumme gerechnet: (360° - 40°) : 2 = 160°.', 'Wie groß ist die Winkelsumme in einem Dreieck?'],
  ] });
def({ ref: 'winkel-dreieck-02', skill: DR, titel: 'Außenwinkel · aus zwei Innenwinkeln',
  frage: 'Im Dreieck ABC ist α = 50° und β = 60°. Der Außenwinkel bei C liegt zwischen der Seite BC und der Verlängerung der Seite AC über C hinaus; er ist der Nebenwinkel von γ.\n\nWie groß ist der Außenwinkel bei C?',
  afb: 'I', afbGrund: 'Reproduzieren: Außenwinkel als Nebenwinkel des Innenwinkels (oder Außenwinkelsatz).',
  sach: false, prozess: 'Operieren', antwort: '110', r: '50+60',
  weg: 'γ = 180° - 50° - 60° = 70°.\nAußenwinkel bei C = 180° - 70° = 110°.\n(Außenwinkelsatz: 50° + 60° = 110°.)',
  ke: [
    ['70', AU, '180-50-60', 'Den Innenwinkel γ angegeben statt des Außenwinkels: 70°.', 'Liegt der gesuchte Winkel innerhalb oder außerhalb des Dreiecks?'],
  ] });
def({ ref: 'winkel-dreieck-03', skill: DR, titel: 'Dreieck und Parallele · Winkel bei B',
  frage: 'Im Dreieck ABC liegt A links und B rechts. Die Gerade g geht durch C und ist parallel zur Seite AB. Auf g liegt links von C der Punkt P und rechts von C der Punkt Q. Der Winkel ∠PCA ist 52° groß, der Winkel γ = ∠ACB ist 67° groß.\n\nWie groß ist der Winkel β bei B?',
  afb: 'II', afbGrund: 'Anwenden: gestreckter Winkel auf g und Wechselwinkel an Parallelen kombinieren.',
  sach: false, prozess: 'Problemlösen', antwort: '61', r: '180-52-67',
  weg: 'Auf g bilden ∠PCA, γ und ∠QCB zusammen einen gestreckten Winkel: ∠QCB = 180° - 52° - 67° = 61°.\n∠QCB und β sind Wechselwinkel an den Parallelen g und AB: β = 61°.',
  ke: [
    ['119', D, '52+67', 'Die beiden bekannten Winkel nur addiert, nicht von 180° abgezogen: 52° + 67° = 119°.', 'Wie viel Grad haben die drei Winkel auf der Geraden g bei C zusammen?'],
    ['241', S360, '360-52-67', 'Mit 360° statt 180° gerechnet: 360° - 52° - 67° = 241°.', 'Bilden die drei Winkel bei C eine gerade Linie oder eine volle Drehung?'],
  ] });
def({ ref: 'winkel-dreieck-04', skill: DR, titel: 'Außenwinkel · gleichschenkliges Dreieck',
  frage: `${GLS} Der Winkel γ bei C ist 50° groß. Der Außenwinkel bei A liegt zwischen der Seite AC und der Verlängerung der Seite BA über A hinaus.\n\nWie groß ist der Außenwinkel bei A?`,
  afb: 'II', afbGrund: 'Anwenden: Basiswinkelsatz, Winkelsumme und Außenwinkel in drei Schritten.',
  sach: false, prozess: 'Operieren', antwort: '115', r: '180-(180-50)/2',
  weg: 'γ liegt an der Spitze, α und β sind Basiswinkel: α = (180° - 50°) : 2 = 65°.\nAußenwinkel bei A = 180° - 65° = 115°.',
  ke: [
    ['65', AU, '(180-50)/2', 'Den Innenwinkel α angegeben statt des Außenwinkels: 65°.', 'Liegt der gesuchte Winkel innerhalb oder außerhalb des Dreiecks?'],
    ['130', B, '180-50', 'γ als Basiswinkel bei A genommen und davon den Außenwinkel gebildet: 180° - 50° = 130°.', 'Welche Ecke liegt zwischen den beiden gleich langen Seiten?'],
  ] });
def({ ref: 'winkel-dreieck-05', skill: DR, titel: 'Basiswinkel · Neigung eines Satteldachs',
  frage: 'Der Querschnitt eines Satteldachs ist ein gleichschenkliges Dreieck: Die beiden Dachflächen sind gleich lang, die Grundseite ist der waagerechte Dachboden. Oben am First schließen die beiden Dachflächen einen Winkel von 110° ein.\n\nWie groß ist der Winkel zwischen einer Dachfläche und dem Dachboden?',
  afb: 'II', afbGrund: 'Anwenden im Sachkontext: Querschnitt als gleichschenkliges Dreieck lesen, Spitze am First.',
  sach: true, prozess: 'Modellieren', antwort: '35', r: '(180-110)/2',
  weg: 'Der First liegt zwischen den gleich langen Dachflächen: Er ist die Spitze. Die Winkel am Dachboden sind die gleich großen Basiswinkel.\n(180° - 110°) : 2 = 35°.',
  ke: [
    ['110', B, '110', 'Den Winkel am First für einen Basiswinkel gehalten: 110°.', 'Liegt der Winkel am First zwischen den beiden gleich langen Seiten oder an der Grundseite?'],
    ['70', HV, '180-110', 'Den Rest für beide Basiswinkel zusammen nicht halbiert: 180° - 110° = 70°.', 'Auf wie viele Winkel am Dachboden verteilen sich die restlichen 70°?'],
    ['125', S360, '(360-110)/2', 'Mit 360° statt 180° als Winkelsumme gerechnet: (360° - 110°) : 2 = 125°.', 'Wie groß ist die Winkelsumme in einem Dreieck?'],
  ] });
def({ ref: 'winkel-dreieck-06', skill: DR, titel: 'Außenwinkel · Rückrichtung, Innenwinkel gesucht',
  frage: 'Im Dreieck ABC ist α = 48°. Der Außenwinkel bei C (der Nebenwinkel von γ) ist 125° groß.\n\nWie groß ist der Winkel β bei B?',
  afb: 'III', afbGrund: 'Rückrichtung: aus Außenwinkel und einem Innenwinkel den dritten Winkel erschließen.',
  sach: false, prozess: 'Problemlösen', antwort: '77', r: '125-48',
  weg: 'γ = 180° - 125° = 55°.\nβ = 180° - 48° - 55° = 77°.\n(Außenwinkelsatz: 125° = 48° + β, also β = 77°.)',
  ke: [
    ['7', AU, '180-125-48', 'Den Außenwinkel wie den Innenwinkel γ verwendet: 180° - 125° - 48° = 7°.', 'Ist 125° der Winkel im Dreieck bei C oder der daneben?'],
    ['173', D, '125+48', 'Die beiden gegebenen Winkel addiert statt subtrahiert: 125° + 48° = 173°.', 'Der Außenwinkel ist so groß wie zwei Innenwinkel zusammen – welcher davon fehlt noch?'],
  ] });

// ─── geo_winkel_thales (Tiefe 5) ─────────────────────────────────────────────
const TH = 'geo_winkel_thales';
const KR = 'Die Strecke AB ist ein Durchmesser eines Kreises mit dem Mittelpunkt M. Der Punkt C liegt auf dem Kreis (C ≠ A, B); so entsteht das Dreieck ABC mit den Winkeln α bei A, β bei B und γ bei C.';
def({ ref: 'winkel-thales-01', skill: TH, titel: 'Thales · Winkel β aus α',
  frage: `${KR} Der Winkel α ist 35° groß.\n\nWie groß ist β?`,
  afb: 'I', afbGrund: 'Reproduzieren: Satz des Thales (γ = 90°) und Winkelsumme.',
  sach: false, prozess: 'Operieren', antwort: '55', r: '180-90-35',
  weg: 'C liegt auf dem Kreis über dem Durchmesser AB: Nach dem Satz des Thales ist γ = 90°.\nβ = 180° - 90° - 35° = 55°.',
  ke: [
    ['90', R, '90', 'Den rechten Winkel bei B statt bei C angenommen: β = 90°.', 'Welche Ecke liegt auf dem Kreis und nicht am Durchmesser?'],
    ['125', D, '90+35', 'Die bekannten Winkel nur addiert, nicht von 180° abgezogen: 90° + 35° = 125°.', 'Wie groß ist die Winkelsumme, und was fehlt noch bis dahin?'],
  ] });
def({ ref: 'winkel-thales-02', skill: TH, titel: 'Thales · Winkel bei C',
  frage: `${KR} Der Winkel α ist 28° groß.\n\nWie groß ist γ?`,
  afb: 'I', afbGrund: 'Reproduzieren: Satz des Thales erkennen, der gegebene Winkel ist Ablenkung.',
  sach: false, prozess: 'Operieren', antwort: '90', r: '90',
  weg: 'C liegt auf dem Kreis über dem Durchmesser AB: Nach dem Satz des Thales ist γ = 90°, unabhängig von α.',
  ke: [
    ['62', R, '180-90-28', 'Den rechten Winkel bei B angenommen und γ aus der Winkelsumme berechnet: 180° - 90° - 28° = 62°.', 'Welche Ecke liegt dem Durchmesser gegenüber?'],
  ] });
def({ ref: 'winkel-thales-03', skill: TH, titel: 'Thales · Winkel am Mittelpunkt-Dreieck AMC',
  frage: `${KR} Der Winkel α ist 40° groß.\n\nWie groß ist der Winkel ∠ACM zwischen den Strecken CA und CM?`,
  afb: 'II', afbGrund: 'Anwenden: Dreieck AMC als gleichschenklig erkennen (MA = MC = Radius).',
  sach: false, prozess: 'Problemlösen', antwort: '40', r: '40',
  weg: 'MA und MC sind Radien, also gleich lang: Das Dreieck AMC ist gleichschenklig mit der Spitze M.\nDie Basiswinkel bei A und C sind gleich: ∠ACM = α = 40°.',
  ke: [
    ['70', B, '(180-40)/2', 'α für den Winkel an der Spitze von Dreieck AMC gehalten: (180° - 40°) : 2 = 70°.', 'Welche Ecke von Dreieck AMC liegt zwischen den beiden gleich langen Radien?'],
  ] });
def({ ref: 'winkel-thales-04', skill: TH, titel: 'Thales · α aus dem Winkel bei M',
  frage: `${KR} Der Winkel ∠BMC zwischen den Strecken MB und MC ist 64° groß.\n\nWie groß ist α?`,
  afb: 'II', afbGrund: 'Anwenden: Nebenwinkel bei M, dann gleichschenkliges Dreieck AMC (zwei Schritte).',
  sach: false, prozess: 'Problemlösen', antwort: '32', r: '(180-(180-64))/2',
  weg: '∠AMC ist Nebenwinkel von ∠BMC: 180° - 64° = 116°.\nDas Dreieck AMC ist gleichschenklig (MA = MC), Spitze M: α = (180° - 116°) : 2 = 32°.',
  ke: [
    ['26', B, '90-64', '64° als Basiswinkel β im Dreieck BMC genommen, dann α = 90° - 64° = 26°.', 'Liegt der Winkel bei M zwischen den beiden gleich langen Radien?'],
    ['64', HV, '180-(180-64)', 'Den Rest im Dreieck AMC nicht halbiert: 180° - 116° = 64°.', 'Auf wie viele gleich große Winkel verteilen sich die restlichen 64° im Dreieck AMC?'],
  ] });
def({ ref: 'winkel-thales-05', skill: TH, titel: 'Thales · Streben im Halbkreisfenster',
  frage: 'Ein Fenster hat oben einen Halbkreisbogen. Die waagerechte Unterkante AB des Bogens ist ein Durchmesser des Halbkreises. Eine gerade Strebe verläuft von A zu einem Punkt C auf dem Bogen, eine zweite von C zu B. Die Strebe AC bildet mit der Unterkante einen Winkel von 32°.\n\nWie groß ist der Winkel zwischen der Strebe CB und der Unterkante?',
  afb: 'II', afbGrund: 'Anwenden im Sachkontext: Thales-Situation im Fenster erkennen, dann Winkelsumme.',
  sach: true, prozess: 'Modellieren', antwort: '58', r: '180-90-32',
  weg: 'AB ist Durchmesser, C liegt auf dem Bogen: Nach dem Satz des Thales ist der Winkel bei C ein rechter.\nWinkel bei B = 180° - 90° - 32° = 58°.',
  ke: [
    ['90', R, '90', 'Den rechten Winkel bei B angenommen: 90°.', 'Welche Ecke des Dreiecks liegt auf dem Bogen?'],
    ['122', D, '90+32', 'Die bekannten Winkel nur addiert: 90° + 32° = 122°.', 'Was muss mit 122° noch geschehen, damit der dritte Winkel herauskommt?'],
  ] });
def({ ref: 'winkel-thales-06', skill: TH, titel: 'Thales · Rückrichtung über die Winkel bei M',
  frage: `${KR} Der Winkel ∠AMC ist um 40° größer als der Winkel ∠BMC.\n\nWie groß ist α?`,
  afb: 'III', afbGrund: 'Rückrichtung: Winkel bei M aus Summe und Unterschied bestimmen, dann gleichschenkliges Dreieck AMC.',
  sach: false, prozess: 'Problemlösen', antwort: '35', r: '(180-(180+40)/2)/2',
  weg: '∠AMC und ∠BMC sind Nebenwinkel: zusammen 180°. ∠BMC = (180° - 40°) : 2 = 70°, ∠AMC = 110°.\nDreieck AMC ist gleichschenklig (MA = MC), Spitze M: α = (180° - 110°) : 2 = 35°.',
  ke: [
    ['70', HV, '180-(180+40)/2', 'Den Rest im Dreieck AMC nicht halbiert: 180° - 110° = 70°.', 'Auf wie viele gleich große Winkel verteilen sich die restlichen 70° im Dreieck AMC?'],
  ] });
