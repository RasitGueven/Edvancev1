// Hinweise (KI-Entwurf, E3) für gleichung_quadr_wurzel: nach x² bzw. dem Quadrat umstellen, Wurzel mit ±.
// Schlüssel ist tasks.source_ref; Belege siehe tools/hinweise-e3-lib.mjs.

const ZUERST = 'trag die kleinere Lösung zuerst ein';

export default {
  skill: 'gleichung_quadr_wurzel',
  aufgaben: {
    'quadrgl-wurzel-01': {
      stufen: [
        { text: 'Gesucht sind alle Zahlen, die mit sich selbst multipliziert 49 ergeben. Denk daran, dass es mehr als eine gibt.',
          fehlbild: 'negative_loesung_vergessen' },
        { text: 'Zieh auf beiden Seiten die Wurzel. Dabei entstehen zwei Lösungen, eine positive und eine negative.' },
        { text: `Wir erhalten x = √49 oder x = −√49. Rechne √49 aus und ${ZUERST}.` },
      ],
    },
    'quadrgl-wurzel-02': {
      stufen: [
        { text: 'In der Gleichung steht x nur als x². Bring x² allein auf eine Seite und zieh dann die Wurzel.' },
        { text: 'Rechne auf beiden Seiten + 18: 2x² = 18.', belege: [['gl', '2x² − 18 = 0', '2x² = 18', '1']] },
        { text: `Wir teilen durch 2: x² = 9. Jetzt ziehst du die Wurzel; denk an beide Vorzeichen und ${ZUERST}.`,
          belege: [['gl', '2x² = 18', 'x² = 9', '1/2']], fehlbild: ['falsche_gegenoperation', 'wurzel_vergessen', 'negative_loesung_vergessen'] },
      ],
    },
    'quadrgl-wurzel-03': {
      stufen: [
        { text: 'Links steht ein Quadrat, rechts eine Zahl. Welche Zahlen ergeben quadriert 25?' },
        { text: 'Zieh auf beiden Seiten die Wurzel; dabei entstehen zwei Gleichungen: x − 2 = 5 oder x − 2 = −5.',
          belege: [['√', '25', '5']], fehlbild: 'negative_loesung_vergessen' },
        { text: `Wir lösen beide Gleichungen, indem wir auf beiden Seiten + 2 rechnen. Achte auf das Vorzeichen und ${ZUERST}.`,
          fehlbild: 'vorzeichen_aus_klammer' },
      ],
    },
    'quadrgl-wurzel-04': {
      stufen: [
        { text: 'Bring x² allein auf eine Seite und zieh dann die Wurzel. Denk daran, dass es zwei Lösungen gibt.' },
        { text: 'Teile beide Seiten durch 3: x² = 20.', belege: [['gl', '3x² = 60', 'x² = 20', '1/3']], fehlbild: 'division_vergessen' },
        { text: `Wir ziehen die Wurzel: x = √20 oder x = −√20. Rechne √20 mit dem Taschenrechner, runde auf zwei Stellen nach dem Komma und ${ZUERST}.`,
          fehlbild: ['wurzel_vergessen', 'negative_loesung_vergessen'] },
      ],
    },
    'quadrgl-wurzel-05': {
      stufen: [
        { text: 'Nenne die Breite x; dann kannst du auch die Länge mit x ausdrücken. Stell mit dem Flächeninhalt eine Gleichung auf.' },
        { text: 'Die Länge ist 2x, also gilt x · 2x = 98.', belege: [['begr', '2', 'doppelt so lang wie breit']] },
        { text: 'Wir fassen zusammen und teilen durch 2: 2x² = 98, also x² = 49. Zieh die Wurzel; als Breite zählt nur die positive Lösung.',
          belege: [['≡', 'x · 2x', '2x²'], ['gl', '2x² = 98', 'x² = 49', '1/2']], fehlbild: ['division_vergessen', 'falsche_gegenoperation', 'wurzel_vergessen'] },
      ],
    },
    'quadrgl-wurzel-06': {
      stufen: [
        { text: 'Nenne die ursprüngliche Seite x; die neue Seite ist dann um 3 cm länger. Stell mit dem Flächeninhalt eine Gleichung auf.' },
        { text: 'Die neue Seite ist x + 3, also gilt (x + 3)² = 121. Am schnellsten geht es, wenn du jetzt die Wurzel ziehst.',
          fehlbild: 'quadrat_gliedweise' },
        { text: 'Wir ziehen die Wurzel: x + 3 = 11 oder x + 3 = −11. Rechne auf beiden Seiten − 3; gefragt ist die ursprüngliche Seite, und nur eine positive Länge ist sinnvoll.',
          belege: [['√', '121', '11']], fehlbild: ['vorzeichen_aus_klammer', 'falsche_groesse_beantwortet'] },
      ],
    },
  },
};
