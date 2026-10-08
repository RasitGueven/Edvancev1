/**
 * Erklärsequenz fkt_linear_nullstelle (E2b). Aufbau wie tools/erklaer-k8-linfkt/steigung.mjs
 * (Muster): Variante A mit Erklärung und Beispiel, B/C für Fehlbilder aus den known_errors der
 * Aufgaben dieses Skills (docs/prefill/erklaer-k8-linfkt-bestand.md), zwei Checks je Kernidee.
 */

import { bild } from './bild.mjs';

export const SKILL = 'fkt_linear_nullstelle';

const NUR_GERADE = 'Koordinatensystem mit Gitter und dem Graphen einer linearen Funktion.';

export const KERNIDEEN = [
  {
    nr: 1,
    titel: 'Nullstelle: Schnitt mit der x-Achse',
    varianten: {
      A: {
        erklaerung: {
          inhalt: '# Wo trifft die Gerade die x-Achse?\n\n'
            + 'Auf der x-Achse ist y = 0. Die Stelle x, an der die Gerade die x-Achse trifft, heißt Nullstelle.\n\n'
            + 'Hier trifft sie die x-Achse in N(2|0). Die Nullstelle ist x = 2.\n\n'
            + '> Nullstelle: die Stelle x mit y = 0',
          bild: bild([-3, 5, -3, 4], 1, -2, [['N', 2, 0]], 'Steigende Gerade, die die x-Achse im Punkt N schneidet.'),
          rechnungen: [],
        },
        beispiel: {
          inhalt: '# Beispiel: Lies die Nullstelle ab.\n\n'
            + '1. Die Gerade gehört zu $f(x) = -2x - 2$. Such die Stelle, an der sie die x-Achse trifft.\n'
            + '2. Das ist N(-1|0). Dort ist y = 0.\n'
            + '3. Die Nullstelle ist x = -1. Probe: $-2 \\cdot (-1) - 2 = 0$.',
          bild: bild([-4, 3, -4, 4], -2, -2, [['N', -1, 0]], 'Fallende Gerade, die die x-Achse links vom Ursprung im Punkt N schneidet.'),
          rechnungen: [['-2*(-1)-2', '0']],
        },
      },
      B: {
        fehlbilder: ['achsenabschnitt_verwechselt'],
        erklaerung: {
          inhalt: '# x-Achse, nicht y-Achse\n\n'
            + 'Die Nullstelle liegt auf der x-Achse. Der Punkt auf der y-Achse gehört zum y-Achsenabschnitt.\n\n'
            + 'Hier: N(2|0) ist die Nullstelle, also x = 2. S(0|1) gehört zum y-Achsenabschnitt, nicht zur Nullstelle.',
          bild: bild([-3, 4, -2, 3], -0.5, 1, [['N', 2, 0], ['S', 0, 1]], 'Flach fallende Gerade mit dem Punkt N auf der x-Achse und dem Punkt S auf der y-Achse.'),
          rechnungen: [],
        },
      },
      C: {
        fehlbilder: ['betrag_fehler'],
        erklaerung: {
          inhalt: '# Links vom Ursprung ist x negativ.\n\n'
            + 'Trifft die Gerade die x-Achse links vom Ursprung, ist die Nullstelle negativ.\n\n'
            + 'Hier: N(-2|0). Die Nullstelle ist -2, nicht 2.',
          bild: bild([-4, 2, -2, 5], 1.5, 3, [['N', -2, 0]], 'Steigende Gerade, die die x-Achse links vom Ursprung im Punkt N schneidet.'),
          rechnungen: [['0-(-2)', '2', 'falsch']],
        },
      },
    },
    checks: [{
      ref: 'erklaer-nullstelle-k1-c1', titel: 'Check · Nullstelle am Graphen ablesen · negativ',
      frage: 'Die Abbildung zeigt den Graphen einer linearen Funktion.\n\nAn welcher Stelle x schneidet der Graph die x-Achse?',
      afb: 'I', afbGrund: 'Reproduzieren: Schnitt mit der x-Achse ablesen, links vom Ursprung.',
      prozess: 'Operieren', antwort: '-4', r: '-2/0.5',
      weg: 'Die Gerade schneidet die x-Achse bei (-4 | 0). Die Nullstelle ist x = -4.',
      figur: bild([-6, 3, -2, 5], 0.5, 2, [], NUR_GERADE),
      ke: [
        ['2', 'achsenabschnitt_verwechselt', '0.5*0+2', 'Den Schnitt mit der y-Achse abgelesen: 2.', 'Liegt die Nullstelle auf der x-Achse oder auf der y-Achse?'],
        ['4', 'betrag_fehler', '0-(-4)', 'Das Minus vergessen: 4 statt -4.', 'Liegt der Schnittpunkt links oder rechts vom Ursprung?'],
      ],
    }, {
      ref: 'erklaer-nullstelle-k1-c2', titel: 'Check · Nullstelle am Graphen ablesen',
      frage: 'Die Abbildung zeigt den Graphen einer linearen Funktion.\n\nBestimme die Nullstelle der Funktion.',
      afb: 'I', afbGrund: 'Reproduzieren: Schnitt mit der x-Achse ablesen.',
      prozess: 'Operieren', antwort: '3', r: '6/2',
      weg: 'Die Gerade schneidet die x-Achse bei (3 | 0). Die Nullstelle ist x = 3.',
      figur: bild([-2, 5, -7, 4], 2, -6, [], NUR_GERADE),
      ke: [
        ['-6', 'achsenabschnitt_verwechselt', '2*0-6', 'Den Schnitt mit der y-Achse abgelesen: -6.', 'Liegt die Nullstelle auf der x-Achse oder auf der y-Achse?'],
        ['-3', 'betrag_fehler', '-(6/2)', 'Vorzeichen gekippt: -3 statt 3.', 'Liegt der Schnittpunkt links oder rechts vom Ursprung?'],
      ],
    }],
  },
  {
    nr: 2,
    titel: 'Nullstelle berechnen',
    varianten: {
      A: {
        erklaerung: {
          inhalt: '# f(x) = 0 setzen und umstellen\n\n'
            + 'Setz $f(x) = 0$. Rechne b mit der Gegenrechnung auf die andere Seite. Teile dann durch m.\n\n'
            + 'Bei $f(x) = 3x - 9$: $3x - 9 = 0$. Plus 9 auf beiden Seiten: $3x = 9$. Durch 3: $x = 3$.\n\n'
            + '> Nullstelle: $mx + b = 0$ nach x umstellen',
          bild: bild([-1, 5, -10, 4], 3, -9, [['N', 3, 0]], 'Steile Gerade, die die x-Achse im Punkt N schneidet.'),
          rechnungen: [['0+9', '9'], ['9/3', '3']],
        },
        beispiel: {
          inhalt: '# Nullstelle von f(x) = -3x + 3\n\n'
            + '1. $-3x + 3 = 0$.\n'
            + '2. Minus 3 auf beiden Seiten: $-3x = -3$.\n'
            + '3. Durch -3 teilen: $x = 1$. Probe: $-3 \\cdot 1 + 3 = 0$.',
          bild: bild([-2, 3, -3, 5], -3, 3, [['N', 1, 0]], 'Fallende Gerade, die die x-Achse im Punkt N schneidet.'),
          rechnungen: [['0-3', '-3'], ['-3/(-3)', '1'], ['-3*1+3', '0']],
        },
      },
      B: {
        fehlbilder: ['division_vergessen', 'falsche_gegenoperation'],
        erklaerung: {
          inhalt: '# Zum Schluss durch m teilen\n\n'
            + 'Rechne jeden Schritt rückwärts: Aus minus wird plus, aus mal wird geteilt.\n\n'
            + 'Nach dem Umstellen steht dort noch $m \\cdot x$. Teile durch m, dann steht x allein.\n\n'
            + '$2x - 10 = 0$. Plus 10: $2x = 10$. Durch 2: $x = 5$. Nicht 10 und nicht $10 \\cdot 2 = 20$.',
          rechnungen: [['0+10', '10'], ['10/2', '5'], ['2*5-10', '0'], ['10*2', '20', 'falsch']],
        },
      },
      C: {
        fehlbilder: ['betrag_fehler', 'vorzeichen_beim_umstellen'],
        erklaerung: {
          inhalt: '# Passt das Vorzeichen?\n\n'
            + 'Mach die Probe: Setz dein Ergebnis in f ein. Es muss 0 herauskommen.\n\n'
            + '$f(x) = 2x + 8$: $x = -4$, denn $2 \\cdot (-4) + 8 = 0$. Mit 4 käme 16 heraus.\n\n'
            + 'Ist m negativ: $-2x + 6 = 0$, $-2x = -6$, $x = 3$. Minus durch Minus gibt Plus.',
          bild: bild([-6, 2, -3, 10], 2, 8, [['N', -4, 0]], 'Steigende Gerade, die die x-Achse links vom Ursprung im Punkt N schneidet.'),
          rechnungen: [['-8/2', '-4'], ['2*(-4)+8', '0'], ['2*4+8', '16', 'falsch'], ['0-6', '-6'], ['-6/(-2)', '3']],
        },
      },
    },
    ohne_variante: {
      achsenabschnitt_verwechselt: 'Die Verwechslung mit dem y-Achsenabschnitt hat ihre Variante in Kernidee 1 (B). Hier nimmt die Engine die nächste ungezeigte Variante (B).',
    },
    checks: [{
      ref: 'erklaer-nullstelle-k2-c1', titel: 'Check · Nullstelle berechnen',
      frage: 'Gegeben ist die Funktion f(x) = 3x - 12.\n\nBerechne die Nullstelle von f.',
      afb: 'I', afbGrund: 'Reproduzieren: f(x) = 0 setzen, b wegrechnen, durch m teilen.',
      prozess: 'Operieren', antwort: '4', r: '12/3',
      weg: '3x - 12 = 0, also 3x = 12 und x = 12 : 3 = 4.',
      ke: [
        ['12', 'division_vergessen', '12', 'Nach 3x = 12 nicht durch 3 geteilt.', 'Steht nach dem Umstellen schon x allein da?'],
        ['36', 'falsche_gegenoperation', '12*3', 'Mit 3 malgenommen statt durch 3 geteilt: 36.', 'Wie machst du „mal 3“ rückgängig?'],
        ['-4', 'betrag_fehler', '-12/3', 'Vorzeichen gekippt: -4 statt 4.', 'Setz dein Ergebnis in f ein. Kommt 0 heraus?'],
        ['-12', 'achsenabschnitt_verwechselt', '3*0-12', 'Den y-Achsenabschnitt angegeben: -12.', 'Ist die Stelle gesucht, an der f(x) = 0 ist, oder der Wert bei x = 0?'],
      ],
    }, {
      ref: 'erklaer-nullstelle-k2-c2', titel: 'Check · Nullstelle berechnen · fallend',
      frage: 'Gegeben ist die Funktion f(x) = -5x + 10.\n\nBerechne die Nullstelle von f.',
      afb: 'II', afbGrund: 'Anwenden: negativer Koeffizient beim Umstellen.',
      prozess: 'Operieren', antwort: '2', r: '-10/(-5)',
      weg: '-5x + 10 = 0, also -5x = -10 und x = -10 : (-5) = 2.',
      ke: [
        ['-2', 'vorzeichen_beim_umstellen', '10/(-5)', 'Das Minus von -5 bleibt am Ergebnis hängen: -2.', 'Setz dein Ergebnis in f ein. Kommt 0 heraus?'],
        ['-10', 'division_vergessen', '-10', 'Nach -5x = -10 nicht durch -5 geteilt.', 'Steht nach dem Umstellen schon x allein da?'],
        ['10', 'achsenabschnitt_verwechselt', '-5*0+10', 'Den y-Achsenabschnitt angegeben: 10.', 'Ist die Stelle gesucht, an der f(x) = 0 ist, oder der Wert bei x = 0?'],
      ],
    }],
  },
  {
    nr: 3,
    titel: 'Nullstelle im Sachzusammenhang',
    varianten: {
      A: {
        erklaerung: {
          inhalt: '# Wann ist es leer?\n\n'
            + 'In Sachaufgaben fragt die Nullstelle: Wann ist der Wert 0? Zum Beispiel: Wann ist der Tank leer?\n\n'
            + 'Setz den Term gleich 0 und stell nach x um.\n\n'
            + '> leer, verbraucht, aufgebraucht: Wert = 0',
          bild: bild([0, 5, 0, 8], -2, 6, [['S', 0, 6], ['N', 3, 0]], 'Fallende Gerade im ersten Quadranten vom Startpunkt S bis zum Punkt N auf der x-Achse.'),
          rechnungen: [],
        },
        beispiel: {
          inhalt: '# Ein Tank: V(x) = -3x + 12 Liter nach x Minuten\n\n'
            + '1. Leer heißt $V(x) = 0$: $-3x + 12 = 0$.\n'
            + '2. $-3x = -12$, also $x = 4$.\n'
            + '3. Nach 4 Minuten ist der Tank leer.',
          bild: bild([0, 5, 0, 13], -3, 12, [['S', 0, 12], ['N', 4, 0]], 'Fallende Gerade im ersten Quadranten vom Startpunkt S bis zum Punkt N auf der x-Achse.'),
          rechnungen: [['0-12', '-12'], ['-12/(-3)', '4']],
        },
      },
      B: {
        fehlbilder: ['achsenabschnitt_verwechselt'],
        erklaerung: {
          inhalt: '# Gesucht ist das Ende, nicht der Start.\n\n'
            + 'Der Wert bei x = 0 ist der Start. Die Nullstelle ist der Zeitpunkt, an dem nichts mehr da ist.\n\n'
            + '$V(x) = -2x + 10$: Am Start sind 10 Liter drin. Leer: $-2x + 10 = 0$, $-2x = -10$, also nach 5 Minuten.',
          bild: bild([0, 6, 0, 11], -2, 10, [['S', 0, 10], ['N', 5, 0]], 'Fallende Gerade im ersten Quadranten vom Startpunkt S bis zum Punkt N auf der x-Achse.'),
          rechnungen: [['0-10', '-10'], ['-10/(-2)', '5']],
        },
      },
      C: {
        fehlbilder: ['vorzeichen_beim_umstellen'],
        erklaerung: {
          inhalt: '# Eine Zeit ist nie negativ.\n\n'
            + 'Kommt bei einer Zeit ein Minus heraus, prüf das Umstellen.\n\n'
            + '$-4x + 8 = 0$, also $-4x = -8$. Durch -4 teilen: $x = 2$. Minus durch Minus gibt Plus.',
          bild: bild([0, 4, 0, 9], -4, 8, [['S', 0, 8], ['N', 2, 0]], 'Steil fallende Gerade im ersten Quadranten vom Startpunkt S bis zum Punkt N auf der x-Achse.'),
          rechnungen: [['0-8', '-8'], ['-8/(-4)', '2']],
        },
      },
    },
    checks: [{
      ref: 'erklaer-nullstelle-k3-c1', titel: 'Check · Nullstelle im Sachzusammenhang · Tank',
      frage: 'Ein Wassertank wird gleichmäßig geleert. Die Wassermenge in Litern nach x Minuten ist W(x) = -5x + 40.\n\nNach wie vielen Minuten ist der Tank leer?',
      afb: 'II', afbGrund: 'Anwenden: Nullstelle im Sachzusammenhang als Zeitpunkt deuten.',
      prozess: 'Modellieren', antwort: '8', r: '-40/(-5)',
      weg: 'Leer heißt W(x) = 0: -5x + 40 = 0, also -5x = -40 und x = 8.',
      ke: [
        ['40', 'achsenabschnitt_verwechselt', '-5*0+40', 'Die Anfangsmenge angegeben statt des Zeitpunkts.', 'Ist nach dem Anfang oder nach dem Ende gefragt?'],
        ['-8', 'vorzeichen_beim_umstellen', '40/(-5)', 'Das Minus von -5 bleibt am Ergebnis hängen: -8.', 'Kann eine Zeit negativ sein?'],
      ],
    }, {
      ref: 'erklaer-nullstelle-k3-c2', titel: 'Check · Nullstelle im Sachzusammenhang · Guthaben',
      frage: 'Ein Handyguthaben wird jede Woche kleiner. Das Guthaben in Euro nach x Wochen ist G(x) = -2x + 30.\n\nNach wie vielen Wochen ist das Guthaben aufgebraucht?',
      afb: 'II', afbGrund: 'Anwenden: Nullstelle im Sachzusammenhang als Zeitpunkt deuten.',
      prozess: 'Modellieren', antwort: '15', r: '-30/(-2)',
      weg: 'Aufgebraucht heißt G(x) = 0: -2x + 30 = 0, also -2x = -30 und x = 15.',
      ke: [
        ['30', 'achsenabschnitt_verwechselt', '-2*0+30', 'Das Anfangsguthaben angegeben statt des Zeitpunkts.', 'Ist nach dem Anfang oder nach dem Ende gefragt?'],
        ['-15', 'vorzeichen_beim_umstellen', '30/(-2)', 'Das Minus von -2 bleibt am Ergebnis hängen: -15.', 'Kann eine Zeit negativ sein?'],
      ],
    }],
  },
];
