/**
 * Erklärsequenz fkt_linear_steigung (E2b, Muster). Gebaut wird die Charge von
 * tools/erklaer-k8-linfkt-charge.mjs, nachgerechnet von tools/erklaer-rechnen.mjs.
 *
 * Aufbau je Kernidee (Bauauftrag Entscheidung 18):
 *   varianten.A  erklaerung + beispiel, ohne Fehlbild
 *   varianten.B/C  erklaerung für die Fehlbilder in `fehlbilder` (Slugs aus den known_errors
 *                  der Aufgaben dieses Skills, docs/prefill/erklaer-k8-linfkt-bestand.md)
 *   ohne_variante  Slugs, die ein Check kennt, für die es in DIESER Kernidee keine eigene
 *                  Variante gibt (die Engine nimmt dann die nächste ungezeigte), mit Grund
 *   checks        Check-Aufgaben (NUMERIC), Felder wie tools/k8-linfkt-aufgaben.mjs
 * Schritt: inhalt (Markdown: "# " Überschrift, Absätze, "> " Merksatz, "1. " Schritte,
 *   Formeln in $…$), bild (Generator koordinatensystem), rechnungen [[Term, Wert, 'falsch'?]].
 *   Jede Zahl in inhalt und Bild muss in rechnungen oder als Bildpunkt belegt sein.
 */

import { bild } from './bild.mjs';

export const SKILL = 'fkt_linear_steigung';

export const KERNIDEEN = [
  {
    nr: 1,
    titel: 'Steigung: hoch durch rüber',
    varianten: {
      A: {
        erklaerung: {
          inhalt: '# Wie steil ist die Gerade?\n\n'
            + 'Geh auf der Geraden von A nach B. Zähl die Kästchen nach rechts und die Kästchen nach oben.\n\n'
            + 'Dann teilst du: hoch durch rüber. Das Ergebnis heißt Steigung $m$.\n\n'
            + '> Steigung = hoch : rüber',
          bild: bild([-1, 4, -2, 6], 2, -1, [['A', 1, 1], ['B', 3, 5]], 'Steigende Gerade mit den Punkten A und B im Gitter.'),
          rechnungen: [],
        },
        beispiel: {
          inhalt: '# Die Gerade geht durch A(0|-1) und B(2|5).\n\n'
            + '1. Von A nach B geht es 2 nach rechts.\n'
            + '2. Dabei geht es 6 nach oben.\n'
            + '3. Hoch durch rüber: $m = \\frac{6}{2} = 3$.',
          bild: bild([-2, 4, -2, 7], 3, -1, [['A', 0, -1], ['B', 2, 5]], 'Steile Gerade durch die Punkte A und B.'),
          rechnungen: [['2-0', '2'], ['5-(-1)', '6'], ['6/2', '3']],
        },
      },
      B: {
        fehlbilder: ['steigung_kehrwert'],
        erklaerung: {
          inhalt: '# Erst hoch, dann durch rüber.\n\n'
            + 'Wie weit es nach oben geht, steht oben im Bruch. Wie weit es nach rechts geht, steht unten.\n\n'
            + 'Von C nach D: 3 nach rechts, 6 nach oben. Also $m = \\frac{6}{3} = 2$.\n\n'
            + 'Umgekehrt wäre $\\frac{3}{6}$ viel zu flach.\n\n'
            + '> Steigung = hoch : rüber',
          bild: bild([-2, 3, -4, 5], 2, -1, [['C', -1, -3], ['D', 2, 3]], 'Steigende Gerade mit den Punkten C und D im Gitter.'),
          rechnungen: [['2-(-1)', '3'], ['3-(-3)', '6'], ['6/3', '2'], ['3/6', '1/2', 'falsch']],
        },
      },
    },
    checks: [{
      ref: 'erklaer-steigung-k1-c1', titel: 'Check · Steigung am Graphen ablesen',
      frage: 'Die Abbildung zeigt eine Gerade durch die Punkte A und B.\n\nBestimme die Steigung m der Geraden.',
      afb: 'I', afbGrund: 'Reproduzieren: Steigung am Gitter abzählen, ganzzahlig, steigende Gerade.',
      prozess: 'Operieren', antwort: '4', r: '(6-(-2))/(1-(-1))',
      weg: 'Von A(-1 | -2) nach B(1 | 6): 2 nach rechts, 8 nach oben.\nm = 8 / 2 = 4.',
      figur: bild([-2, 2, -3, 7], 4, 2, [['A', -1, -2], ['B', 1, 6]], 'Koordinatensystem mit Gitter und einer steigenden Geraden durch die Punkte A und B.'),
      ke: [
        ['1/4', 'steigung_kehrwert', '(1-(-1))/(6-(-2))', 'Rüber durch hoch geteilt: 2 / 8 = 1/4.', 'Welche Zahl gehört nach oben in den Bruch: die Kästchen nach oben oder nach rechts?'],
        ['0,25', 'steigung_kehrwert', '2/8', 'Rüber durch hoch geteilt: 2 / 8 = 0,25.', 'Welche Zahl gehört nach oben in den Bruch: die Kästchen nach oben oder nach rechts?'],
      ],
    }],
  },
  {
    nr: 2,
    titel: 'Steigung aus zwei Punkten berechnen',
    varianten: {
      A: {
        erklaerung: {
          inhalt: '# Rechnen statt zählen\n\n'
            + 'Hoch = y von B minus y von A. Rüber = x von B minus x von A.\n\n'
            + 'A(-2|0) und B(2|2): $m = \\frac{2 - 0}{2 - (-2)} = \\frac{2}{4}$, also 0,5.\n\n'
            + 'Fällt die Gerade, wird hoch negativ und $m$ auch.\n\n'
            + '> $m = \\dfrac{y_B - y_A}{x_B - x_A}$',
          bild: bild([-3, 3, -1, 4], 0.5, 1, [['A', -2, 0], ['B', 2, 2]], 'Flach steigende Gerade mit den Punkten A und B.'),
          rechnungen: [['2-0', '2'], ['2-(-2)', '4'], ['2/4', '0,5']],
        },
        beispiel: {
          inhalt: '# Die Gerade geht durch A(-1|3) und B(2|-3).\n\n'
            + '1. Hoch: $-3 - 3 = -6$. Es geht nach unten.\n'
            + '2. Rüber: $2 - (-1) = 3$.\n'
            + '3. $m = \\frac{-6}{3} = -2$. Die Gerade fällt.',
          bild: bild([-2, 3, -4, 4], -2, 1, [['A', -1, 3], ['B', 2, -3]], 'Fallende Gerade durch die Punkte A und B.'),
          rechnungen: [['-3-3', '-6'], ['2-(-1)', '3'], ['-6/3', '-2']],
        },
      },
      B: {
        fehlbilder: ['seiten_verwechselt'],
        erklaerung: {
          inhalt: '# Passt das Vorzeichen?\n\n'
            + 'Steigt die Gerade, ist $m$ positiv. Fällt sie, ist $m$ negativ. Ohne Bild: Wird y mit x größer, steigt sie.\n\n'
            + 'Rechne oben und unten in derselben Reihenfolge: erst Q, dann P.\n\n'
            + 'P(-2|4) und Q(2|0): $m = \\frac{0 - 4}{2 - (-2)} = \\frac{-4}{4} = -1$.',
          bild: bild([-3, 3, -2, 5], -1, 2, [['P', -2, 4], ['Q', 2, 0]], 'Fallende Gerade mit den Punkten P und Q.'),
          rechnungen: [['0-4', '-4'], ['2-(-2)', '4'], ['-4/4', '-1']],
        },
      },
      C: {
        fehlbilder: ['steigung_kehrwert'],
        erklaerung: {
          inhalt: '# Die y-Werte gehören nach oben.\n\n'
            + 'Im Bruch stehen oben die y-Werte und unten die x-Werte. So bleibt es: hoch durch rüber.\n\n'
            + 'A(0|-3) und B(2|5): $m = \\frac{5 - (-3)}{2 - 0} = \\frac{8}{2} = 4$.\n\n'
            + 'Umgekehrt käme $\\frac{2}{8}$ heraus. Das passt nicht zur steilen Geraden.',
          bild: bild([-1, 3, -4, 6], 4, -3, [['A', 0, -3], ['B', 2, 5]], 'Sehr steile Gerade mit den Punkten A und B.'),
          rechnungen: [['5-(-3)', '8'], ['2-0', '2'], ['8/2', '4'], ['2/8', '1/4', 'falsch']],
        },
      },
    },
    checks: [{
      ref: 'erklaer-steigung-k2-c1', titel: 'Check · Steigung aus zwei Punkten · negative Koordinaten',
      frage: 'Eine Gerade geht durch die Punkte A(-3 | -2) und B(1 | 4).\n\nBerechne die Steigung m der Geraden.',
      afb: 'II', afbGrund: 'Anwenden: Differenzen mit negativen Koordinaten (Minus vor Minus), Ergebnis als Bruch.',
      prozess: 'Operieren', antwort: '3/2', auch: ['1,5'], r: '(4-(-2))/(1-(-3))',
      weg: 'm = (4 - (-2)) / (1 - (-3)) = 6 / 4 = 3/2 = 1,5.',
      ke: [
        ['-3/2', 'seiten_verwechselt', '(4-(-2))/(-3-1)', 'Oben B minus A, unten A minus B gerechnet: 6 / (-4) = -3/2.', 'Hast du oben und unten mit demselben Punkt angefangen?'],
        ['-1,5', 'seiten_verwechselt', '6/(-4)', 'Oben B minus A, unten A minus B gerechnet: 6 / (-4) = -1,5.', 'Steigt die Gerade von A nach B oder fällt sie? Passt dein Vorzeichen dazu?'],
        ['2/3', 'steigung_kehrwert', '(1-(-3))/(4-(-2))', 'Rüber durch hoch geteilt: 4 / 6 = 2/3.', 'Welche Werte gehören nach oben in den Bruch: die x-Werte oder die y-Werte?'],
      ],
    }],
  },
  {
    nr: 3,
    titel: 'Mit der Steigung weiterrechnen',
    varianten: {
      A: {
        erklaerung: {
          inhalt: '# Jeder Schritt bringt m dazu.\n\n'
            + 'Ein Schritt heißt: 1 nach rechts. Bei jedem Schritt geht es um $m$ nach oben.\n\n'
            + 'Gehst du mehrere Schritte, kommt $m$ für jeden Schritt einmal dazu.\n\n'
            + '> neuer y-Wert = alter y-Wert + Schritte · m',
          bild: bild([-1, 4, -3, 4], 2, -2, [['P', 0, -2], ['Q', 1, 0], ['R', 2, 2]], 'Steigende Gerade mit drei Punkten P, Q und R im Abstand von je einem Kästchen nach rechts.'),
          rechnungen: [],
        },
        beispiel: {
          inhalt: '# Von P(1|-1) mit m = 2 bis x = 4\n\n'
            + '1. Von x = 1 bis x = 4 sind es 3 Schritte.\n'
            + '2. Jeder Schritt bringt 2 nach oben: $3 \\cdot 2 = 6$.\n'
            + '3. $-1 + 6 = 5$. Der Punkt heißt Q(4|5).',
          bild: bild([-1, 5, -4, 6], 2, -3, [['P', 1, -1], ['Q', 4, 5]], 'Steigende Gerade mit den Punkten P und Q.'),
          rechnungen: [['4-1', '3'], ['3*2', '6'], ['-1+6', '5']],
        },
      },
      B: {
        fehlbilder: ['nur_einmal_addiert'],
        erklaerung: {
          inhalt: '# Zähl die Schritte mit.\n\n'
            + 'Die Steigung gilt für einen Schritt nach rechts. Bei 4 Schritten kommt sie 4-mal dazu.\n\n'
            + 'P(0|-4), $m = 2$, 4 Schritte: $-4 + 4 \\cdot 2 = 4$, also Q(4|4). Nicht $-4 + 2 = -2$.',
          bild: bild([-1, 5, -5, 5], 2, -4, [['P', 0, -4], ['Q', 4, 4]], 'Steigende Gerade mit den Punkten P und Q.'),
          rechnungen: [['4-0', '4'], ['4*2', '8'], ['-4+4*2', '4'], ['-4+2', '-2', 'falsch']],
        },
      },
      C: {
        fehlbilder: ['b_ignoriert'],
        erklaerung: {
          inhalt: '# Starte beim Punkt, nicht im Ursprung.\n\n'
            + 'Diese Gerade geht nicht durch den Ursprung. Steigung mal x allein reicht deshalb nicht.\n\n'
            + 'Starte beim y-Wert des Punktes und zähl die Schritte dazu.\n\n'
            + 'P(1|5), $m = 3$, gesucht y bei x = 3: 2 Schritte, $5 + 2 \\cdot 3 = 11$. Nicht $3 \\cdot 3 = 9$.',
          bild: bild([-1, 4, -1, 13], 3, 2, [['P', 1, 5], ['Q', 3, 11]], 'Steigende Gerade, die die y-Achse oberhalb des Ursprungs schneidet, mit den Punkten P und Q.'),
          rechnungen: [['3-1', '2'], ['5+2*3', '11'], ['3*3', '9', 'falsch']],
        },
      },
    },
    ohne_variante: {
      steigung_kehrwert: 'Der Kehrwert hat seine Varianten in Kernidee 1 (B) und 2 (C). Hier nimmt die Engine die nächste ungezeigte Variante (B).',
    },
    checks: [{
      ref: 'erklaer-steigung-k3-c1', titel: 'Check · Punkt aus Steigung und Punkt',
      frage: 'Eine Gerade hat die Steigung 3 und geht durch den Punkt P(2 | 1).\n\nWelche y-Koordinate hat der Punkt der Geraden mit der x-Koordinate 5?',
      afb: 'II', afbGrund: 'Anwenden in Rückrichtung: Schritte zählen, Steigung mehrfach addieren, beim Punkt starten.',
      prozess: 'Problemlösen', antwort: '10', r: '1+3*(5-2)',
      weg: 'Von x = 2 bis x = 5 sind es 3 Schritte nach rechts.\nJeder Schritt bringt 3 nach oben: 1 + 3 · 3 = 10.',
      ke: [
        ['4', 'nur_einmal_addiert', '1+3', 'Die Steigung nur einmal addiert: 1 + 3 = 4.', 'Wie viele Schritte nach rechts liegen zwischen x = 2 und x = 5?'],
        ['15', 'b_ignoriert', '3*5', 'Wie bei einer Ursprungsgeraden gerechnet: 3 · 5 = 15.', 'Geht die Gerade durch den Ursprung? Prüfe es mit dem Punkt P.'],
        ['2', 'steigung_kehrwert', '1+(5-2)/3', 'Mit dem Kehrwert der Steigung gerechnet: 1 + 3 · 1/3 = 2.', 'Wie viel geht es bei einem Schritt nach rechts nach oben?'],
      ],
    }],
  },
];
