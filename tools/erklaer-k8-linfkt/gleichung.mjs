/**
 * Erklärsequenz fkt_linear_gleichung (E2b). Aufbau wie tools/erklaer-k8-linfkt/steigung.mjs
 * (Muster): Variante A mit Erklärung und Beispiel, B/C für Fehlbilder aus den known_errors der
 * Aufgaben dieses Skills (docs/prefill/erklaer-k8-linfkt-bestand.md), zwei Checks je Kernidee.
 */

import { bild } from './bild.mjs';

export const SKILL = 'fkt_linear_gleichung';

export const KERNIDEEN = [
  {
    nr: 1,
    titel: 'Gleichung aus m und b, dann einsetzen',
    varianten: {
      A: {
        erklaerung: {
          inhalt: '# m und b einsetzen\n\n'
            + 'Eine lineare Funktion hat die Form $y = mx + b$. Statt y schreibt man auch f(x).\n\n'
            + 'Für m setzt du die Steigung ein, für b den y-Achsenabschnitt. Ein Minus schreibst du mit.\n\n'
            + 'Bei $m = 2$ und $b = -1$ heißt sie $y = 2x - 1$.\n\n'
            + '> $f(x) = mx + b$',
          bild: bild([-3, 4, -4, 6], 2, -1, [['S', 0, -1]], 'Steigende Gerade mit dem Punkt S auf der y-Achse. Ein Steigungsdreieck zeigt, wie weit es rüber und hoch geht.', [[1, 1, 1, 2]]),
          rechnungen: [['2*0-1', '-1']],
        },
        beispiel: {
          inhalt: '# m = -3 und b = 5. Wie groß ist f(2)?\n\n'
            + '1. Die Gleichung heißt $f(x) = -3x + 5$.\n'
            + '2. Setz x = 2 ein: $f(2) = -3 \\cdot 2 + 5$.\n'
            + '3. $-6 + 5 = -1$. Also ist f(2) = -1, der Punkt P(2|-1).',
          bild: bild([-2, 4, -3, 7], -3, 5, [['S', 0, 5], ['P', 2, -1]], 'Fallende Gerade mit dem Punkt S auf der y-Achse und dem Punkt P unterhalb der x-Achse.'),
          rechnungen: [['-3*2', '-6'], ['-6+5', '-1']],
        },
      },
      B: {
        fehlbilder: ['m_b_vertauscht'],
        erklaerung: {
          inhalt: '# m steht vor dem x.\n\n'
            + 'Die Steigung gehört direkt vor das x. Der y-Achsenabschnitt steht allein am Ende.\n\n'
            + 'Steigung 3, y-Achsenabschnitt 1: $y = 3x + 1$. Nicht $y = 1x + 3$.\n\n'
            + 'Im Bild startet die Gerade bei S(0|1) und steigt steil.',
          bild: bild([-2, 4, -3, 8], 3, 1, [['S', 0, 1]], 'Steile Gerade mit dem Punkt S auf der y-Achse. Ein Steigungsdreieck zeigt, wie weit es rüber und hoch geht.', [[1, 4, 1, 3]]),
          rechnungen: [],
        },
      },
      C: {
        fehlbilder: ['vorzeichen_ignoriert', 'betrag_fehler'],
        erklaerung: {
          inhalt: '# Das Minus gehört zur Zahl.\n\n'
            + 'Ist m oder b negativ, schreibst du das Minus mit in die Gleichung.\n\n'
            + 'Steigung 2, y-Achsenabschnitt -3: $y = 2x - 3$. Bei x = 2: $4 - 3 = 1$. Nicht $4 + 3 = 7$.\n\n'
            + 'Prüf dein Ergebnis am Bild: Liegt der Punkt über oder unter der x-Achse?',
          bild: bild([-2, 4, -4, 5], 2, -3, [['S', 0, -3], ['P', 2, 1]], 'Steigende Gerade mit dem Punkt S unterhalb der x-Achse auf der y-Achse und dem Punkt P darüber.'),
          rechnungen: [['2*2', '4'], ['4-3', '1'], ['4+3', '7', 'falsch']],
        },
      },
    },
    checks: [{
      ref: 'erklaer-gleichung-k1-c1', titel: 'Check · Gleichung aus m und b · negatives b',
      frage: 'Eine lineare Funktion f hat die Steigung 4 und den y-Achsenabschnitt -3.\n\nStelle die Funktionsgleichung auf und berechne damit f(3).',
      afb: 'I', afbGrund: 'Reproduzieren: m und b einsetzen, einmal auswerten.',
      prozess: 'Operieren', antwort: '9', r: '4*3+(-3)',
      weg: 'f(x) = 4x - 3.\nf(3) = 4 · 3 - 3 = 12 - 3 = 9.',
      ke: [
        ['-5', 'm_b_vertauscht', '-3*3+4', 'Steigung und Abschnitt vertauscht: f(x) = -3x + 4, f(3) = -5.', 'Welche Zahl gehört direkt vor das x?'],
        ['15', 'vorzeichen_ignoriert', '4*3+3', 'Das Minus von b weggelassen: 4 · 3 + 3 = 15.', 'Ist der y-Achsenabschnitt positiv oder negativ?'],
      ],
    }, {
      ref: 'erklaer-gleichung-k1-c2', titel: 'Check · Gleichung aus m und b · fallend',
      frage: 'Eine lineare Funktion f hat die Steigung -4 und schneidet die y-Achse bei y = 3.\n\nStelle die Funktionsgleichung auf und berechne damit f(2).',
      afb: 'I', afbGrund: 'Reproduzieren: m und b einsetzen, negative Steigung.',
      prozess: 'Operieren', antwort: '-5', r: '-4*2+3',
      weg: 'f(x) = -4x + 3.\nf(2) = -4 · 2 + 3 = -8 + 3 = -5.',
      ke: [
        ['2', 'm_b_vertauscht', '3*2+(-4)', 'Steigung und Abschnitt vertauscht: f(x) = 3x - 4, f(2) = 2.', 'Welche Zahl gehört direkt vor das x?'],
        ['5', 'betrag_fehler', '-(-4*2+3)', 'Betrag richtig, Vorzeichen gekippt: 5 statt -5.', 'Die Gerade fällt. Liegt f(2) über oder unter der x-Achse?'],
        ['11', 'vorzeichen_ignoriert', '4*2+3', 'Das Minus der Steigung weggelassen: 4 · 2 + 3 = 11.', 'Ist die Steigung positiv oder negativ?'],
      ],
    }],
  },
  {
    nr: 2,
    titel: 'Gleichung aus zwei Punkten',
    varianten: {
      A: {
        erklaerung: {
          inhalt: '# Erst m, dann b\n\n'
            + 'Aus den Punkten A und B rechnest du zuerst die Steigung: hoch durch rüber.\n\n'
            + 'Dann setzt du einen Punkt ein und rechnest b aus: $b = y - m \\cdot x$.\n\n'
            + '> erst $m = \\dfrac{y_B - y_A}{x_B - x_A}$, dann b',
          bild: bild([-2, 5, -2, 8], 2, 0, [['A', 1, 2], ['B', 3, 6]], 'Steigende Gerade mit den Punkten A und B. Ein Steigungsdreieck zeigt, wie weit es rüber und hoch geht.', [[1, 2, 2, 4]]),
          rechnungen: [],
        },
        beispiel: {
          inhalt: '# Die Gerade geht durch A(1|-2) und B(3|4).\n\n'
            + '1. $m = \\frac{4 - (-2)}{3 - 1} = \\frac{6}{2} = 3$. Minus Minus heißt plus.\n'
            + '2. A einsetzen: $b = -2 - 3 \\cdot 1 = -5$.\n'
            + '3. Die Gleichung heißt $y = 3x - 5$.',
          bild: bild([-1, 5, -6, 8], 3, -5, [['A', 1, -2], ['B', 3, 4]], 'Steigende Gerade mit den Punkten A und B. Ein Steigungsdreieck zeigt, wie weit es rüber und hoch geht.', [[1, -2, 2, 6]]),
          rechnungen: [['4-(-2)', '6'], ['3-1', '2'], ['6/2', '3'], ['-2-3*1', '-5'], ['3*0-5', '-5']],
        },
      },
      B: {
        fehlbilder: ['steigung_kehrwert', 'seiten_verwechselt'],
        erklaerung: {
          inhalt: '# Hoch durch rüber, gleiche Reihenfolge\n\n'
            + 'Oben stehen die y-Werte, unten die x-Werte. Fang oben und unten mit demselben Punkt an.\n\n'
            + 'A(1|2) und B(4|8): $m = \\frac{8 - 2}{4 - 1} = \\frac{6}{3} = 2$.\n\n'
            + 'Nicht $\\frac{3}{6}$ und nicht $\\frac{8 - 2}{1 - 4} = -2$.',
          bild: bild([-1, 6, -1, 9], 2, 0, [['A', 1, 2], ['B', 4, 8]], 'Steigende Gerade mit den Punkten A und B. Ein Steigungsdreieck zeigt, wie weit es rüber und hoch geht.', [[1, 2, 3, 6]]),
          rechnungen: [['8-2', '6'], ['4-1', '3'], ['6/3', '2'], ['3/6', '1/2', 'falsch'], ['(8-2)/(1-4)', '-2', 'falsch']],
        },
      },
      C: {
        fehlbilder: ['addiert_statt_subtrahiert', 'falsche_groesse_beantwortet'],
        erklaerung: {
          inhalt: '# Für b wird abgezogen.\n\n'
            + 'Setz einen Punkt in $y = mx + b$ ein. Dann ziehst du $m \\cdot x$ auf beiden Seiten ab.\n\n'
            + 'P(2|9) und $m = 3$: $9 = 3 \\cdot 2 + b$, also $b = 9 - 6 = 3$.\n\n'
            + 'Nicht $9 + 6 = 15$. Lies genau, was gefragt ist: m oder b.',
          bild: bild([-2, 4, -2, 11], 3, 3, [['S', 0, 3], ['P', 2, 9]], 'Steile Gerade mit dem Punkt P und dem Punkt S auf der y-Achse.'),
          rechnungen: [['3*2', '6'], ['9-6', '3'], ['9+6', '15', 'falsch']],
        },
      },
    },
    checks: [{
      ref: 'erklaer-gleichung-k2-c1', titel: 'Check · Gleichung aus zwei Punkten · b bestimmen',
      frage: 'Eine Gerade geht durch die Punkte A(1 | 3) und B(3 | 7). Ihre Funktionsgleichung hat die Form y = mx + b.\n\nWelchen Wert hat b?',
      afb: 'II', afbGrund: 'Anwenden: m aus zwei Punkten, dann b durch Einsetzen und Umstellen.',
      prozess: 'Operieren', antwort: '1', r: '3-(7-3)/(3-1)*1',
      weg: 'm = (7 - 3) / (3 - 1) = 4 / 2 = 2.\nA einsetzen: 3 = 2 · 1 + b, also b = 3 - 2 = 1.',
      ke: [
        ['5', 'addiert_statt_subtrahiert', '3+2*1', 'Beim Umstellen addiert statt abgezogen: b = 3 + 2 = 5.', 'Was musst du auf beiden Seiten tun, damit b allein steht?'],
        ['2', 'falsche_groesse_beantwortet', '(7-3)/(3-1)', 'Die Steigung m = 2 angegeben statt b.', 'Welche der beiden Zahlen in y = mx + b ist gesucht?'],
        ['5/2', 'steigung_kehrwert', '3-1/2*1', 'Mit dem Kehrwert m = 1/2 gerechnet: b = 3 - 1/2 = 5/2.', 'Welche Werte gehören nach oben in den Bruch: die x-Werte oder die y-Werte?'],
        ['2,5', 'steigung_kehrwert', '3-1/2', 'Mit dem Kehrwert m = 1/2 gerechnet: b = 3 - 0,5 = 2,5.', 'Welche Werte gehören nach oben in den Bruch: die x-Werte oder die y-Werte?'],
      ],
    }, {
      ref: 'erklaer-gleichung-k2-c2', titel: 'Check · Gleichung aus zwei Punkten · einsetzen',
      frage: 'Eine Gerade geht durch die Punkte A(0 | -1) und B(3 | 5).\n\nBestimme die Funktionsgleichung und berechne damit f(4).',
      afb: 'II', afbGrund: 'Anwenden: m aus zwei Punkten, b aus dem Punkt auf der y-Achse, dann auswerten.',
      prozess: 'Operieren', antwort: '7', r: '(5-(-1))/(3-0)*4+(-1)',
      weg: 'm = (5 - (-1)) / (3 - 0) = 6 / 3 = 2, b = -1 (A liegt auf der y-Achse).\nf(x) = 2x - 1, f(4) = 2 · 4 - 1 = 7.',
      ke: [
        ['-9', 'seiten_verwechselt', '(5-(-1))/(0-3)*4-1', 'Oben B minus A, unten A minus B: m = -2, f(4) = -2 · 4 - 1 = -9.', 'Hast du oben und unten mit demselben Punkt angefangen?'],
        ['1', 'steigung_kehrwert', '3/6*4-1', 'Rüber durch hoch: m = 1/2, f(4) = 1/2 · 4 - 1 = 1.', 'Welche Werte gehören nach oben in den Bruch: die x-Werte oder die y-Werte?'],
      ],
    }],
  },
  {
    nr: 3,
    titel: 'Gleichung im Sachzusammenhang',
    varianten: {
      A: {
        erklaerung: {
          inhalt: '# Was ist m, was ist b?\n\n'
            + 'Der feste Betrag am Anfang ist b. Was pro Stück, Stunde oder Kilometer dazukommt, ist m.\n\n'
            + 'Nimmt etwas ab, ist m negativ: 15 cm, pro Stunde 2 cm weniger, $h(x) = -2x + 15$.\n\n'
            + '> Wert = m · Menge + Startwert b',
          bild: bild([0, 4, 0, 11], 2, 3, [['S', 0, 3]], 'Steigende Gerade im ersten Quadranten mit dem Startpunkt S auf der y-Achse. Ein Steigungsdreieck zeigt den Zuwachs pro Einheit.', [[1, 5, 1, 2]]),
          rechnungen: [['-2*0+15', '15']],
        },
        beispiel: {
          inhalt: '# Eintritt: 3 Euro Grundpreis, 2 Euro pro Stunde\n\n'
            + '1. Grundpreis $b = 3$, pro Stunde $m = 2$.\n'
            + '2. Die Gleichung heißt $K(x) = 2x + 3$.\n'
            + '3. Für 4 Stunden: $K(4) = 2 \\cdot 4 + 3 = 11$ Euro.',
          bild: bild([0, 5, 0, 13], 2, 3, [['S', 0, 3], ['P', 4, 11]], 'Steigende Gerade im ersten Quadranten mit dem Startpunkt S und dem Punkt P.'),
          rechnungen: [['2*4+3', '11']],
        },
      },
      B: {
        fehlbilder: ['groessen_vertauscht', 'b_ignoriert'],
        erklaerung: {
          inhalt: '# Grundbetrag einmal, Betrag pro Stück jedes Mal\n\n'
            + 'Der Grundbetrag kommt nur einmal dazu. Der Betrag pro Stück kommt für jedes Stück dazu.\n\n'
            + '5 Euro Grundgebühr, 2 Euro pro km, 3 km: $2 \\cdot 3 + 5 = 11$ Euro.\n\n'
            + 'Nicht $5 \\cdot 3 + 2 = 17$. Und nicht nur $2 \\cdot 3 = 6$, dann fehlt die Grundgebühr.',
          bild: bild([0, 4, 0, 13], 2, 5, [['S', 0, 5], ['P', 3, 11]], 'Steigende Gerade im ersten Quadranten mit dem Startpunkt S und dem Punkt P.'),
          rechnungen: [['2*3+5', '11'], ['5*3+2', '17', 'falsch'], ['2*3', '6', 'falsch']],
        },
      },
      C: {
        fehlbilder: ['vorzeichen_ignoriert', 'falsche_groesse_beantwortet'],
        erklaerung: {
          inhalt: '# Nimmt es ab, ist m negativ.\n\n'
            + 'Ein Tank hat 12 Liter. Pro Minute fließen 2 Liter ab. Also $V(x) = -2x + 12$.\n\n'
            + 'Nach 4 Minuten: $-2 \\cdot 4 + 12 = 4$ Liter. Nicht $2 \\cdot 4 + 12 = 20$.\n\n'
            + 'Gefragt ist, was noch drin ist. Nicht die $2 \\cdot 4 = 8$ Liter, die abgeflossen sind.',
          bild: bild([0, 7, 0, 13], -2, 12, [['S', 0, 12], ['P', 4, 4]], 'Fallende Gerade im ersten Quadranten mit dem Startpunkt S und dem Punkt P.'),
          rechnungen: [['-2*4+12', '4'], ['2*4+12', '20', 'falsch'], ['2*4', '8', 'falsch']],
        },
      },
    },
    checks: [{
      ref: 'erklaer-gleichung-k3-c1', titel: 'Check · Gleichung im Sachzusammenhang · Abnahme',
      frage: 'In einem Becken stehen 50 cm Wasser. Pro Stunde sinkt der Wasserstand gleichmäßig um 4 cm.\n\nStelle eine Funktionsgleichung für den Wasserstand nach x Stunden auf. Wie hoch steht das Wasser nach 5 Stunden, in cm?',
      afb: 'II', afbGrund: 'Anwenden: abnehmende Größe, negative Steigung, dann auswerten.',
      prozess: 'Modellieren', antwort: '30', r: '-4*5+50',
      weg: 'h(x) = -4x + 50.\nh(5) = -4 · 5 + 50 = -20 + 50 = 30.',
      ke: [
        ['70', 'vorzeichen_ignoriert', '4*5+50', 'Die Abnahme addiert: 4 · 5 + 50 = 70.', 'Wird das Wasser mehr oder weniger?'],
        ['246', 'groessen_vertauscht', '50*5-4', 'Startwert und Abnahme pro Stunde vertauscht: 50 · 5 - 4 = 246.', 'Welche Zahl ist der Wasserstand am Anfang, welche die Änderung pro Stunde?'],
        ['20', 'falsche_groesse_beantwortet', '4*5', 'Die Abnahme angegeben statt des Wasserstands: 4 · 5 = 20.', 'Ist gefragt, wie viel abgeflossen ist, oder wie hoch das Wasser noch steht?'],
      ],
    }, {
      ref: 'erklaer-gleichung-k3-c2', titel: 'Check · Gleichung im Sachzusammenhang · Kosten',
      frage: 'Ein Fitnessstudio verlangt einmalig 20 € Aufnahmegebühr und 15 € pro Monat.\n\nStelle eine Funktionsgleichung für die Kosten auf und berechne die Kosten in Euro für 6 Monate.',
      afb: 'II', afbGrund: 'Anwenden: Grundbetrag und Rate zuordnen, dann auswerten.',
      prozess: 'Modellieren', antwort: '110', r: '15*6+20',
      weg: 'K(x) = 15x + 20.\nK(6) = 15 · 6 + 20 = 90 + 20 = 110.',
      ke: [
        ['135', 'groessen_vertauscht', '20*6+15', 'Grundbetrag und Rate vertauscht: 20 · 6 + 15 = 135.', 'Welcher Betrag kommt jeden Monat neu dazu, welcher nur einmal?'],
        ['90', 'b_ignoriert', '15*6', 'Die Aufnahmegebühr vergessen: 15 · 6 = 90.', 'Hast du alles bezahlt, was beim Start fällig ist?'],
      ],
    }],
  },
];
