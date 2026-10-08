/**
 * Erklärsequenz fkt_linear_yabschnitt (E2b). Aufbau wie tools/erklaer-k8-linfkt/steigung.mjs
 * (Muster): Variante A mit Erklärung und Beispiel, B/C für Fehlbilder aus den known_errors der
 * Aufgaben dieses Skills (docs/prefill/erklaer-k8-linfkt-bestand.md), zwei Checks je Kernidee.
 */

import { bild } from './bild.mjs';

export const SKILL = 'fkt_linear_yabschnitt';

export const KERNIDEEN = [
  {
    nr: 1,
    titel: 'b ist der Schnitt mit der y-Achse',
    varianten: {
      A: {
        erklaerung: {
          inhalt: '# Wo trifft die Gerade die y-Achse?\n\n'
            + 'In $y = mx + b$ ist m die Steigung. Die y-Achse liegt bei x = 0. Dort fällt $m \\cdot x$ weg.\n\n'
            + 'Übrig bleibt b. Bei $y = 2x + 1$ ist das 1, der Punkt S(0|1).\n\n'
            + '> Der y-Achsenabschnitt ist b, die Zahl ohne x.',
          bild: bild([-3, 3, -3, 5], 2, 1, [['S', 0, 1]], 'Steigende Gerade, die die y-Achse im Punkt S schneidet.'),
          rechnungen: [['2*0+1', '1']],
        },
        beispiel: {
          inhalt: '# Beispiel: f(x) = 3x - 5\n\n'
            + '1. Die Zahl ohne x ist -5. Das Minus davor gehört dazu.\n'
            + '2. Probe mit x = 0: $3 \\cdot 0 - 5 = -5$.\n'
            + '3. Der Graph trifft die y-Achse in S(0|-5). Der y-Achsenabschnitt ist -5.',
          bild: bild([-2, 4, -7, 5], 3, -5, [['S', 0, -5]], 'Steigende Gerade, die die y-Achse unterhalb der x-Achse im Punkt S schneidet.'),
          rechnungen: [['3*0-5', '-5']],
        },
      },
      B: {
        fehlbilder: ['m_b_vertauscht', 'betrag_fehler'],
        erklaerung: {
          inhalt: '# Welche Zahl ist b?\n\n'
            + 'In $y = mx + b$ steht m direkt vor dem x. b steht allein, ohne x.\n\n'
            + 'Das Vorzeichen gehört zu b. Bei $y = 2x - 3$ ist $b = -3$, nicht 2 und nicht 3.\n\n'
            + 'Im Bild trifft die Gerade die y-Achse unterhalb der x-Achse, in S(0|-3).',
          bild: bild([-3, 4, -5, 4], 2, -3, [['S', 0, -3]], 'Steigende Gerade, die die y-Achse unterhalb der x-Achse im Punkt S schneidet.'),
          rechnungen: [['2*0-3', '-3']],
        },
      },
      C: {
        fehlbilder: ['achsenabschnitt_verwechselt'],
        erklaerung: {
          inhalt: '# y-Achse, nicht x-Achse\n\n'
            + 'Der y-Achsenabschnitt liegt auf der y-Achse, also bei x = 0.\n\n'
            + 'Wo die Gerade die x-Achse trifft, ist y = 0. Das ist die Nullstelle, etwas anderes.\n\n'
            + 'Bei $y = 2x - 2$: S(0|-2) auf der y-Achse, N(1|0) auf der x-Achse.',
          bild: bild([-3, 4, -4, 5], 2, -2, [['S', 0, -2], ['N', 1, 0]], 'Steigende Gerade mit dem Punkt S auf der y-Achse und dem Punkt N auf der x-Achse.'),
          rechnungen: [['2*1-2', '0']],
        },
      },
    },
    checks: [{
      ref: 'erklaer-yabschnitt-k1-c1', titel: 'Check · y-Achsenabschnitt aus der Gleichung',
      frage: 'Gegeben ist die Funktion f(x) = -2x + 6.\n\nGib den y-Achsenabschnitt des Graphen von f an.',
      afb: 'I', afbGrund: 'Reproduzieren: b direkt aus der Normalform ablesen.',
      prozess: 'Operieren', antwort: '6', r: '-2*0+6',
      weg: 'Der y-Achsenabschnitt ist die Zahl ohne x: b = 6.\nProbe: f(0) = -2 · 0 + 6 = 6.',
      ke: [
        ['-2', 'm_b_vertauscht', '-2', 'Die Steigung -2 angegeben statt b.', 'Welche Zahl steht in f(x) = mx + b allein, ohne x?'],
        ['3', 'achsenabschnitt_verwechselt', '6/2', 'Die Nullstelle angegeben: -2x + 6 = 0 bei x = 3.', 'Liegt der y-Achsenabschnitt auf der x-Achse oder auf der y-Achse?'],
      ],
    }, {
      ref: 'erklaer-yabschnitt-k1-c2', titel: 'Check · y-Achsenabschnitt · negatives b',
      frage: 'Gegeben ist die Funktion f(x) = 5x - 4.\n\nAn welcher Stelle schneidet der Graph von f die y-Achse? Gib den y-Wert an.',
      afb: 'I', afbGrund: 'Reproduzieren: b mit Vorzeichen aus der Normalform ablesen.',
      prozess: 'Operieren', antwort: '-4', r: '5*0-4',
      weg: 'Bei x = 0 fällt 5x weg: f(0) = 5 · 0 - 4 = -4.',
      ke: [
        ['5', 'm_b_vertauscht', '5', 'Die Steigung 5 angegeben statt b.', 'Welche Zahl steht in f(x) = mx + b allein, ohne x?'],
        ['4', 'betrag_fehler', '0-(-4)', 'Das Minus von b weggelassen: 4 statt -4.', 'Gehört das Minus vor der 4 zu b dazu?'],
        ['0,8', 'achsenabschnitt_verwechselt', '4/5', 'Die Nullstelle angegeben: 5x - 4 = 0 bei x = 0,8.', 'Liegt der y-Achsenabschnitt auf der x-Achse oder auf der y-Achse?'],
      ],
    }],
  },
  {
    nr: 2,
    titel: 'b aus Steigung und Punkt berechnen',
    varianten: {
      A: {
        erklaerung: {
          inhalt: '# Zurück zur y-Achse\n\n'
            + 'Kennst du m und einen Punkt P, gehst du von P zurück bis x = 0. Jeder Schritt nach links nimmt m einmal weg.\n\n'
            + 'P(3|7), $m = 2$: $b = 7 - 2 \\cdot 3 = 1$, also S(0|1).\n\n'
            + '> $b = y_P - m \\cdot x_P$',
          bild: bild([-2, 5, -2, 8], 2, 1, [['S', 0, 1], ['P', 3, 7]], 'Steigende Gerade mit dem Punkt P und dem Punkt S auf der y-Achse. Ein Steigungsdreieck reicht von S bis P.', [[0, 1, 3, 6]]),
          rechnungen: [['7-2*3', '1']],
        },
        beispiel: {
          inhalt: '# m = -1, die Gerade geht durch P(4|1).\n\n'
            + '1. Von P bis x = 0 sind es 4 Schritte nach links.\n'
            + '2. $b = 1 - (-1) \\cdot 4 = 1 + 4 = 5$.\n'
            + '3. Die Gerade trifft die y-Achse in S(0|5). Das Dreieck zeigt denselben Weg von S aus: rüber 4, hoch -4.',
          bild: bild([-1, 6, -1, 7], -1, 5, [['S', 0, 5], ['P', 4, 1]], 'Fallende Gerade mit dem Punkt P und dem Punkt S auf der y-Achse. Ein Steigungsdreieck reicht von S bis P.', [[0, 5, 4, -4]]),
          rechnungen: [['4-0', '4'], ['1-(-1)*4', '5'], ['1+4', '5']],
        },
      },
      B: {
        fehlbilder: ['addiert_statt_subtrahiert'],
        erklaerung: {
          inhalt: '# Zurück heißt: abziehen.\n\n'
            + 'Von P zur y-Achse gehst du nach links. Dabei nimmst du m für jeden Schritt weg.\n\n'
            + 'P(1|5), $m = 4$: $b = 5 - 4 \\cdot 1 = 1$. Nicht $5 + 4 \\cdot 1 = 9$.\n\n'
            + 'Die Gerade steigt, also liegt S(0|1) tiefer als P.',
          bild: bild([-1, 3, -1, 7], 4, 1, [['S', 0, 1], ['P', 1, 5]], 'Steile Gerade mit dem Punkt P und dem tiefer liegenden Punkt S auf der y-Achse.'),
          rechnungen: [['5-4*1', '1'], ['5+4*1', '9', 'falsch']],
        },
      },
      C: {
        fehlbilder: ['betrag_fehler'],
        erklaerung: {
          inhalt: '# Passt das Vorzeichen von b?\n\n'
            + 'Über der x-Achse ist b positiv, darunter negativ. Ohne Bild: Rechne Schritt für Schritt und schreib jedes Minus mit.\n\n'
            + 'P(3|2), $m = 2$: $b = 2 - 2 \\cdot 3 = -4$. S(0|-4) liegt unter der x-Achse.',
          bild: bild([-1, 5, -6, 4], 2, -4, [['S', 0, -4], ['P', 3, 2]], 'Steigende Gerade mit dem Punkt P über und dem Punkt S unter der x-Achse. Ein Steigungsdreieck reicht von S bis P.', [[0, -4, 3, 6]]),
          rechnungen: [['2-2*3', '-4']],
        },
      },
    },
    checks: [{
      ref: 'erklaer-yabschnitt-k2-c1', titel: 'Check · b aus Steigung und Punkt',
      frage: 'Eine Gerade hat die Steigung 3 und geht durch den Punkt P(2 | 5).\n\nBestimme den y-Achsenabschnitt b der Geraden.',
      afb: 'II', afbGrund: 'Anwenden: b = y - m · x mit einem Punkt, Ergebnis negativ.',
      prozess: 'Operieren', antwort: '-1', r: '5-3*2',
      weg: 'b = 5 - 3 · 2 = 5 - 6 = -1.',
      ke: [
        ['11', 'addiert_statt_subtrahiert', '5+3*2', 'Steigung mal x addiert statt abgezogen: 5 + 3 · 2 = 11.', 'Gehst du von P zur y-Achse nach rechts oder nach links?'],
        ['1', 'betrag_fehler', '-(5-3*2)', 'Vorzeichen gekippt: 1 statt -1.', 'Liegt der Schnittpunkt mit der y-Achse über oder unter der x-Achse?'],
      ],
    }, {
      ref: 'erklaer-yabschnitt-k2-c2', titel: 'Check · b aus Steigung und Punkt · fallend',
      frage: 'Eine Gerade hat die Steigung -2 und geht durch den Punkt P(3 | 1).\n\nBestimme den y-Achsenabschnitt b der Geraden.',
      afb: 'II', afbGrund: 'Anwenden: b = y - m · x mit negativer Steigung (Minus vor Minus).',
      prozess: 'Operieren', antwort: '7', r: '1-(-2)*3',
      weg: 'b = 1 - (-2) · 3 = 1 + 6 = 7.',
      ke: [
        ['-5', 'addiert_statt_subtrahiert', '1+(-2)*3', 'Steigung mal x addiert statt abgezogen: 1 + (-2) · 3 = -5.', 'Gehst du von P zur y-Achse nach rechts oder nach links?'],
        ['-7', 'betrag_fehler', '-(1-(-2)*3)', 'Vorzeichen gekippt: -7 statt 7.', 'Die Gerade fällt. Liegt sie links von P höher oder tiefer?'],
      ],
    }],
  },
  {
    nr: 3,
    titel: 'b ist der Startwert',
    varianten: {
      A: {
        erklaerung: {
          inhalt: '# Der Startwert ist b.\n\n'
            + 'In Sachaufgaben steht x oft für eine Zeit oder eine Menge. Bei x = 0 ist noch nichts passiert.\n\n'
            + 'Dann bleibt nur b übrig. Das ist der Startwert, zum Beispiel ein Grundpreis. Hier startet die Gerade bei 3.\n\n'
            + '> Startwert = Wert bei x = 0 = b',
          bild: bild([0, 4, 0, 10], 2, 3, [['S', 0, 3]], 'Steigende Gerade im ersten Quadranten. Der Punkt S auf der y-Achse markiert den Startwert.'),
          rechnungen: [],
        },
        beispiel: {
          inhalt: '# Ein Abo kostet K(x) = 2x + 5 Euro für x Filme.\n\n'
            + '1. Ohne Film ist x = 0.\n'
            + '2. $K(0) = 2 \\cdot 0 + 5 = 5$.\n'
            + '3. Der Grundpreis ist 5 Euro. Pro Film kommen 2 Euro dazu.',
          bild: bild([0, 4, 0, 12], 2, 5, [['S', 0, 5]], 'Steigende Gerade im ersten Quadranten mit dem Punkt S auf der y-Achse.'),
          rechnungen: [['2*0+5', '5']],
        },
      },
      B: {
        fehlbilder: ['groessen_vertauscht'],
        erklaerung: {
          inhalt: '# Fest oder pro Stück?\n\n'
            + 'Die Zahl vor dem x kommt bei jedem Stück neu dazu. Das ist die Rate m.\n\n'
            + 'Die Zahl ohne x ist von Anfang an da. Das ist der Grundbetrag b.\n\n'
            + 'Bei $K(x) = 2x + 6$ ist der Grundbetrag 6 Euro, nicht 2 Euro.',
          bild: bild([0, 4, 0, 14], 2, 6, [['S', 0, 6]], 'Steigende Gerade im ersten Quadranten mit dem Punkt S auf der y-Achse. Ein Steigungsdreieck zeigt den Zuwachs pro Stück.', [[1, 8, 1, 2]]),
          rechnungen: [],
        },
      },
      C: {
        fehlbilder: ['achsenabschnitt_verwechselt'],
        erklaerung: {
          inhalt: '# Gesucht ist der Anfang.\n\n'
            + 'Der Startwert ist der Wert bei x = 0. Er liegt auf der y-Achse.\n\n'
            + 'Wann der Wert 0 erreicht, ist eine andere Frage. Das ist die Nullstelle.\n\n'
            + 'Ein Tank hat $h(x) = -2x + 8$ Liter. Zu Beginn sind 8 Liter drin. Leer ist er erst bei x = 4.',
          bild: bild([0, 5, 0, 9], -2, 8, [['S', 0, 8], ['N', 4, 0]], 'Fallende Gerade mit dem Startpunkt S auf der y-Achse und dem Punkt N auf der x-Achse.'),
          rechnungen: [['-2*0+8', '8']],
        },
      },
    },
    checks: [{
      ref: 'erklaer-yabschnitt-k3-c1', titel: 'Check · Startwert im Sachzusammenhang · Taxi',
      frage: 'Ein Taxi berechnet für eine Fahrt von x km den Preis P(x) = 2x + 4 in Euro.\n\nWie hoch ist die Grundgebühr in Euro?',
      afb: 'II', afbGrund: 'Anwenden: den Startwert b im Sachzusammenhang deuten.',
      prozess: 'Modellieren', antwort: '4', r: '2*0+4',
      weg: 'Die Grundgebühr ist der Preis bei x = 0: P(0) = 2 · 0 + 4 = 4.',
      ke: [
        ['2', 'groessen_vertauscht', '2', 'Den Preis pro Kilometer angegeben statt der Grundgebühr.', 'Welcher Betrag kommt für jeden Kilometer neu dazu, welcher ist von Anfang an da?'],
        ['-2', 'achsenabschnitt_verwechselt', '-4/2', 'Die Nullstelle angegeben: 2x + 4 = 0 bei x = -2.', 'Wie viel kostet die Fahrt, bevor ein Kilometer gefahren ist?'],
      ],
    }, {
      ref: 'erklaer-yabschnitt-k3-c2', titel: 'Check · Startwert im Sachzusammenhang · Kerze',
      frage: 'Eine Kerze brennt gleichmäßig ab. Ihre Höhe in cm nach x Stunden ist h(x) = -3x + 15.\n\nWie hoch ist die Kerze zu Beginn, in cm?',
      afb: 'II', afbGrund: 'Anwenden: den Startwert b bei fallender Größe deuten.',
      prozess: 'Modellieren', antwort: '15', r: '-3*0+15',
      weg: 'Zu Beginn ist x = 0: h(0) = -3 · 0 + 15 = 15.',
      ke: [
        ['-3', 'groessen_vertauscht', '-3', 'Die Änderung pro Stunde angegeben statt der Anfangshöhe.', 'Welche Zahl sagt, wie hoch die Kerze ist, bevor sie brennt?'],
        ['5', 'achsenabschnitt_verwechselt', '15/3', 'Die Nullstelle angegeben: Nach 5 Stunden ist die Kerze abgebrannt.', 'Ist nach dem Anfang oder nach dem Ende gefragt?'],
      ],
    }],
  },
];
