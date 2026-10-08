/**
 * Erklärsequenz fkt_linear_graph (E2b). Aufbau wie tools/erklaer-k8-linfkt/steigung.mjs
 * (Muster): Variante A mit Erklärung und Beispiel, B/C für Fehlbilder aus den known_errors der
 * Aufgaben dieses Skills (docs/prefill/erklaer-k8-linfkt-bestand.md), zwei Checks je Kernidee.
 * Die Checks sind Ableseaufgaben: Ihre Figur zeigt nur die Gerade, ohne Punkte und ohne Dreieck.
 */

import { bild } from './bild.mjs';

export const SKILL = 'fkt_linear_graph';

const NUR_GERADE = 'Koordinatensystem mit Gitter und dem Graphen einer linearen Funktion.';

export const KERNIDEEN = [
  {
    nr: 1,
    titel: 'b und m am Graphen ablesen',
    varianten: {
      A: {
        erklaerung: {
          inhalt: '# b und m am Graphen ablesen\n\n'
            + 'b liest du dort ab, wo die Gerade die y-Achse schneidet.\n\n'
            + 'Geh nach rechts, bis die Gerade genau eine Kästchenecke trifft. Zähl, wie weit es hoch oder runter geht. Hoch durch rüber ist m.\n\n'
            + 'Hier: S(0|-1), rüber 2, hoch 4. Also $b = -1$ und $m = 4 : 2 = 2$.',
          bild: bild([-3, 4, -3, 5], 2, -1, [['S', 0, -1]], 'Steigende Gerade mit dem Punkt S auf der y-Achse. Ein Steigungsdreieck beginnt bei S.', [[0, -1, 2, 4]]),
          rechnungen: [['4/2', '2']],
        },
        beispiel: {
          inhalt: '# Beispiel: eine fallende Gerade\n\n'
            + '1. Die Gerade schneidet die y-Achse bei S(0|3). Also $b = 3$.\n'
            + '2. Von S geht es 2 nach rechts und 3 nach unten, also hoch -3.\n'
            + '3. $m = \\frac{-3}{2} = -1,5$. Die Gerade fällt, m ist negativ.',
          bild: bild([-2, 4, -2, 4], -1.5, 3, [['S', 0, 3]], 'Fallende Gerade mit dem Punkt S auf der y-Achse. Ein Steigungsdreieck beginnt bei S.', [[0, 3, 2, -3]]),
          rechnungen: [['-3/2', '-1,5']],
        },
      },
      B: {
        fehlbilder: ['m_b_vertauscht', 'achsenabschnitt_verwechselt'],
        erklaerung: {
          inhalt: '# b sitzt auf der y-Achse.\n\n'
            + 'b ist ein Wert auf der y-Achse. Es sagt nichts darüber, wie steil die Gerade ist.\n\n'
            + 'Wo die Gerade die x-Achse schneidet, liegt die Nullstelle. Das ist nicht b.\n\n'
            + 'Hier: S(0|2), also $b = 2$. Die Steigung ist 0,5, sie gehört nicht zu b. N(-4|0) ist die Nullstelle.',
          bild: bild([-5, 3, -2, 5], 0.5, 2, [['S', 0, 2], ['N', -4, 0]], 'Flach steigende Gerade mit dem Punkt S auf der y-Achse und dem Punkt N auf der x-Achse.'),
          rechnungen: [],
        },
      },
      C: {
        fehlbilder: ['steigung_kehrwert', 'betrag_fehler'],
        erklaerung: {
          inhalt: '# Vorzeichen und Bruch prüfen\n\n'
            + 'Liegt S unter der x-Achse, ist b negativ. Fällt die Gerade, ist m negativ.\n\n'
            + 'Hier: S(0|-1), also $b = -1$, nicht 1.\n\n'
            + 'Von S nach P(4|-2): rüber 4, hoch -1. $m = \\frac{-1}{4} = -0,25$. Nicht $\\frac{4}{-1} = -4$.',
          bild: bild([-2, 6, -4, 2], -0.25, -1, [['S', 0, -1], ['P', 4, -2]], 'Flach fallende Gerade mit den Punkten S und P unterhalb der x-Achse. Ein Steigungsdreieck reicht von S bis P.', [[0, -1, 4, -1]]),
          rechnungen: [['-1/4', '-0,25'], ['4/(-1)', '-4', 'falsch'], ['0-(-1)', '1', 'falsch']],
        },
      },
    },
    checks: [{
      ref: 'erklaer-graph-k1-c1', titel: 'Check · y-Achsenabschnitt am Graphen ablesen',
      frage: 'Die Abbildung zeigt den Graphen einer linearen Funktion.\n\nLies den y-Achsenabschnitt b ab.',
      afb: 'I', afbGrund: 'Reproduzieren: Schnittpunkt mit der y-Achse ablesen, negatives b.',
      prozess: 'Operieren', antwort: '-3', r: '2*0-3',
      weg: 'Die Gerade schneidet die y-Achse bei (0 | -3). Also b = -3.',
      figur: bild([-3, 4, -5, 5], 2, -3, [], NUR_GERADE),
      ke: [
        ['2', 'm_b_vertauscht', '2', 'Die Steigung 2 abgelesen statt b.', 'Wo schneidet die Gerade die y-Achse?'],
        ['3', 'betrag_fehler', '0-(-3)', 'Das Minus vergessen: 3 statt -3.', 'Liegt der Schnittpunkt über oder unter der x-Achse?'],
        ['1,5', 'achsenabschnitt_verwechselt', '3/2', 'Den Schnitt mit der x-Achse abgelesen: 1,5.', 'Auf welcher Achse liegt der y-Achsenabschnitt?'],
        ['3/2', 'achsenabschnitt_verwechselt', '3/2', 'Den Schnitt mit der x-Achse abgelesen: 3/2.', 'Auf welcher Achse liegt der y-Achsenabschnitt?'],
      ],
    }, {
      ref: 'erklaer-graph-k1-c2', titel: 'Check · Steigung am Graphen ablesen · fallend',
      frage: 'Die Abbildung zeigt den Graphen einer linearen Funktion.\n\nLies die Steigung m ab.',
      afb: 'I', afbGrund: 'Reproduzieren: Steigung am Gitter ablesen, fallende Gerade.',
      prozess: 'Operieren', antwort: '-2', r: '(-1-1)/(1-0)',
      weg: 'Von (0 | 1) geht es 1 nach rechts und 2 nach unten zu (1 | -1).\nm = -2 / 1 = -2.',
      figur: bild([-3, 3, -4, 5], -2, 1, [], NUR_GERADE),
      ke: [
        ['2', 'betrag_fehler', '2/1', 'Das Minus vergessen: 2 statt -2.', 'Steigt die Gerade oder fällt sie?'],
        ['-1/2', 'steigung_kehrwert', '1/(-2)', 'Rüber durch hoch geteilt: 1 / (-2) = -1/2.', 'Welche Zahl gehört nach oben in den Bruch: hoch oder rüber?'],
        ['-0,5', 'steigung_kehrwert', '1/(-2)', 'Rüber durch hoch geteilt: 1 / (-2) = -0,5.', 'Welche Zahl gehört nach oben in den Bruch: hoch oder rüber?'],
        ['1', 'm_b_vertauscht', '1', 'Den y-Achsenabschnitt 1 abgelesen statt m.', 'Was sagt dir, wie steil die Gerade ist?'],
      ],
    }],
  },
  {
    nr: 2,
    titel: 'Punkte am Graphen ablesen',
    varianten: {
      A: {
        erklaerung: {
          inhalt: '# Erst x, dann y\n\n'
            + 'Ist x gegeben: Geh von x auf der x-Achse senkrecht zur Geraden, dann waagerecht zur y-Achse. Dort liest du y ab.\n\n'
            + 'Ist y gegeben: Geh umgekehrt, von y auf der y-Achse waagerecht zur Geraden, dann senkrecht zur x-Achse.\n\n'
            + 'Hier: P(2|3). Zu x = 2 gehört y = 3. Umgekehrt gehört zu y = 3 die Stelle x = 2.\n\n'
            + '> Punkt P(x|y): erst x, dann y',
          bild: bild([-3, 4, -2, 5], 1, 1, [['P', 2, 3]], 'Steigende Gerade mit dem Punkt P.'),
          rechnungen: [],
        },
        beispiel: {
          inhalt: '# Welchen y-Wert hat die Gerade bei x = 3?\n\n'
            + '1. Starte auf der x-Achse bei 3.\n'
            + '2. Geh senkrecht bis zur Geraden. Du triffst P(3|-2).\n'
            + '3. Der y-Wert ist -2. Er liegt unter der x-Achse, also mit Minus.',
          bild: bild([-2, 5, -4, 3], -1, 1, [['P', 3, -2]], 'Fallende Gerade mit dem Punkt P unterhalb der x-Achse.'),
          rechnungen: [],
        },
      },
      B: {
        fehlbilder: ['koordinaten_vertauscht', 'falsche_groesse_beantwortet'],
        erklaerung: {
          inhalt: '# Was ist gegeben, was gesucht?\n\n'
            + 'Ist x gegeben, suchst du y. Ist y gegeben, suchst du x.\n\n'
            + 'Hier liegt Q(2|4) auf der Geraden. Zu x = 2 gehört y = 4, nicht 2.\n\n'
            + 'Zu y = 4 gehört x = 2, nicht 4. Dafür startest du auf der y-Achse bei 4 und gehst waagerecht zur Geraden.',
          bild: bild([-2, 4, -2, 6], 1.5, 1, [['Q', 2, 4]], 'Steigende Gerade mit dem Punkt Q.'),
          rechnungen: [],
        },
      },
      C: {
        fehlbilder: ['koordinate_vorzeichen_verloren'],
        erklaerung: {
          inhalt: '# Unter der x-Achse ist y negativ.\n\n'
            + 'Liegt ein Punkt unter der x-Achse, hat sein y-Wert ein Minus. Links der y-Achse hat x ein Minus.\n\n'
            + 'Hier: R(3|-4). Der y-Wert ist -4, nicht 4.',
          bild: bild([-2, 5, -5, 3], -1, -1, [['R', 3, -4]], 'Fallende Gerade mit dem Punkt R unterhalb der x-Achse.'),
          rechnungen: [['0-(-4)', '4', 'falsch']],
        },
      },
    },
    checks: [{
      ref: 'erklaer-graph-k2-c1', titel: 'Check · y-Wert am Graphen ablesen',
      frage: 'Die Abbildung zeigt den Graphen einer linearen Funktion.\n\nWelchen y-Wert hat der Graph an der Stelle x = 1?',
      afb: 'II', afbGrund: 'Anwenden: zu gegebenem x den y-Wert ablesen, Ergebnis negativ.',
      prozess: 'Operieren', antwort: '-2', r: '2*1-4',
      weg: 'Bei x = 1 senkrecht zur Geraden: Punkt (1 | -2). Der y-Wert ist -2.',
      figur: bild([-2, 5, -5, 5], 2, -4, [], NUR_GERADE),
      ke: [
        ['2', 'koordinate_vorzeichen_verloren', '0-(-2)', 'Richtig abgelesen, aber das Minus fehlt: 2 statt -2.', 'Liegt der Punkt über oder unter der x-Achse?'],
        ['2,5', 'koordinaten_vertauscht', '(1+4)/2', 'x und y vertauscht: die Stelle x mit y = 1 abgelesen, 2,5.', 'Ist x = 1 gegeben oder y = 1?'],
        ['5/2', 'koordinaten_vertauscht', '(1+4)/2', 'x und y vertauscht: die Stelle x mit y = 1 abgelesen, 5/2.', 'Ist x = 1 gegeben oder y = 1?'],
      ],
    }, {
      ref: 'erklaer-graph-k2-c2', titel: 'Check · Stelle x am Graphen ablesen',
      frage: 'Die Abbildung zeigt den Graphen einer linearen Funktion.\n\nAn welcher Stelle x hat der Graph den y-Wert -1?',
      afb: 'II', afbGrund: 'Anwenden: zu gegebenem y die Stelle x ablesen.',
      prozess: 'Operieren', antwort: '4', r: '(-1-1)/(-0.5)',
      weg: 'Bei y = -1 waagerecht zur Geraden: Punkt (4 | -1). Die Stelle ist x = 4.',
      figur: bild([-3, 6, -3, 4], -0.5, 1, [], NUR_GERADE),
      ke: [
        ['-1', 'falsche_groesse_beantwortet', '-1', 'Den gegebenen y-Wert als Antwort genommen.', 'Ist x oder y gesucht?'],
        ['1,5', 'koordinaten_vertauscht', '-0.5*(-1)+1', 'x und y vertauscht: den y-Wert an der Stelle x = -1 abgelesen, 1,5.', 'Gehst du bei -1 auf der x-Achse oder auf der y-Achse los?'],
        ['3/2', 'koordinaten_vertauscht', '-0.5*(-1)+1', 'x und y vertauscht: den y-Wert an der Stelle x = -1 abgelesen, 3/2.', 'Gehst du bei -1 auf der x-Achse oder auf der y-Achse los?'],
      ],
    }],
  },
  {
    nr: 3,
    titel: 'Graph im Sachzusammenhang',
    varianten: {
      A: {
        erklaerung: {
          inhalt: '# Startwert und pro Einheit\n\n'
            + 'Der Startwert bei x = 0 ist b. Du liest ihn an der y-Achse ab.\n\n'
            + 'Was pro Einheit dazukommt, ist m. Geh 1 nach rechts und lies ab, wie viel dazukommt.\n\n'
            + 'Trifft die Gerade bei 1 nach rechts keine Kästchenecke, geh weiter, bis sie eine trifft. Dann: hoch durch rüber.\n\n'
            + 'Hier: Start bei S(0|1), pro Einheit kommt 2 dazu.',
          bild: bild([0, 4, 0, 9], 2, 1, [['S', 0, 1]], 'Steigende Gerade im ersten Quadranten mit dem Startpunkt S. Ein Steigungsdreieck zeigt den Zuwachs pro Einheit.', [[1, 3, 1, 2]]),
          rechnungen: [],
        },
        beispiel: {
          inhalt: '# Handytarif: Kosten y in Euro für x GB\n\n'
            + '1. An der y-Achse startet die Gerade bei S(0|5). Der Grundpreis ist 5 Euro.\n'
            + '2. Von P(1|7) nach Q(2|9) geht es $9 - 7 = 2$ hoch.\n'
            + '3. Jedes weitere GB kostet 2 Euro.',
          bild: bild([0, 4, 0, 13], 2, 5, [['S', 0, 5], ['P', 1, 7], ['Q', 2, 9]], 'Steigende Gerade im ersten Quadranten mit dem Startpunkt S und den Punkten P und Q. Ein Steigungsdreieck reicht von P bis Q.', [[1, 7, 1, 2]]),
          rechnungen: [['9-7', '2']],
        },
      },
      B: {
        fehlbilder: ['groessen_vertauscht'],
        erklaerung: {
          inhalt: '# Start oder pro Einheit?\n\n'
            + 'Der Startwert steht an der y-Achse. Er kommt nur einmal vor.\n\n'
            + 'Pro Einheit zählt, wie weit es je Kästchen nach rechts hoch geht. Das ist m.\n\n'
            + 'Hier: Start 6. Rüber 2, hoch 3, also pro Einheit $3 : 2 = 1,5$. Die 6 ist der Start, nicht der Betrag pro Einheit.',
          bild: bild([0, 6, 0, 15], 1.5, 6, [['S', 0, 6]], 'Steigende Gerade im ersten Quadranten mit dem Startpunkt S. Ein Steigungsdreieck zeigt den Zuwachs.', [[2, 9, 2, 3]]),
          rechnungen: [['3/2', '1,5']],
        },
      },
      C: {
        fehlbilder: ['steigung_kehrwert'],
        erklaerung: {
          inhalt: '# Pro Einheit: hoch durch rüber\n\n'
            + 'Wie viel kommt pro Einheit dazu? Teile, wie weit es hoch geht, durch wie weit es rüber geht.\n\n'
            + 'Hier: rüber 2, hoch 5. $5 : 2 = 2,5$ pro Einheit. Nicht $2 : 5 = 0,4$.',
          bild: bild([0, 4, 0, 11], 2.5, 1, [['S', 0, 1]], 'Steile Gerade im ersten Quadranten mit dem Startpunkt S. Ein Steigungsdreieck zeigt den Zuwachs.', [[0, 1, 2, 5]]),
          rechnungen: [['5/2', '2,5'], ['2/5', '0,4', 'falsch']],
        },
      },
    },
    checks: [{
      ref: 'erklaer-graph-k3-c1', titel: 'Check · Graph im Sachzusammenhang · Taxi',
      frage: 'Der Graph zeigt die Kosten y in Euro für eine Taxifahrt in Abhängigkeit von der Strecke x in km.\n\nWie viel Euro kostet jeder weitere Kilometer?',
      afb: 'II', afbGrund: 'Anwenden: Steigung im Sachzusammenhang als Preis pro Kilometer deuten.',
      prozess: 'Modellieren', antwort: '3', r: '(7-4)/1',
      weg: 'Start bei 4 Euro. Pro Kilometer geht es 3 hoch, zum Beispiel von (0 | 4) nach (1 | 7).\nJeder weitere Kilometer kostet 3 Euro.',
      figur: bild([0, 3, 0, 13], 3, 4, [], 'Koordinatensystem im ersten Quadranten mit Gitter und einer steigenden Geraden.'),
      ke: [
        ['4', 'groessen_vertauscht', '4', 'Die Grundgebühr abgelesen statt des Preises pro Kilometer.', 'Welcher Betrag kommt für jeden Kilometer neu dazu?'],
        ['1/3', 'steigung_kehrwert', '1/3', 'Rüber durch hoch geteilt: 1 / 3.', 'Wie weit geht es hoch, wenn du 1 nach rechts gehst?'],
      ],
    }, {
      ref: 'erklaer-graph-k3-c2', titel: 'Check · Graph im Sachzusammenhang · Paket',
      frage: 'Der Graph zeigt die Kosten y in Euro für den Versand eines Pakets in Abhängigkeit vom Gewicht x in kg.\n\nWie viel Euro kostet jedes weitere Kilogramm?',
      afb: 'II', afbGrund: 'Anwenden: Steigung kleiner als 1 im Sachzusammenhang deuten.',
      prozess: 'Modellieren', antwort: '1/2', auch: ['0,5'], r: '(5-4)/2',
      weg: 'Start bei 4 Euro. Von (0 | 4) nach (2 | 5): rüber 2, hoch 1.\nm = 1 / 2 = 0,5. Jedes weitere Kilogramm kostet 0,50 Euro.',
      figur: bild([0, 8, 0, 9], 0.5, 4, [], 'Koordinatensystem im ersten Quadranten mit Gitter und einer flach steigenden Geraden.'),
      ke: [
        ['4', 'groessen_vertauscht', '4', 'Den Startpreis abgelesen statt des Preises pro Kilogramm.', 'Welcher Betrag kommt für jedes Kilogramm neu dazu?'],
        ['2', 'steigung_kehrwert', '2/1', 'Rüber durch hoch geteilt: 2 / 1 = 2.', 'Wie weit geht es hoch, wenn du 1 nach rechts gehst?'],
      ],
    }],
  },
];
