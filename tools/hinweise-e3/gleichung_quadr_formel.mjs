// Hinweise (KI-Entwurf, E3) für gleichung_quadr_formel: Normalform, p und q ablesen, p-q-Formel.
// Schlüssel ist tasks.source_ref; Belege siehe tools/hinweise-e3-lib.mjs.

const ZUERST = 'trag die kleinere Lösung zuerst ein';
const NORMALFORM = 'Die Gleichung hat schon die Normalform x² + px + q = 0. Welche Formel löst solche Gleichungen?';

export default {
  skill: 'gleichung_quadr_formel',
  aufgaben: {
    'quadrgl-formel-01': {
      stufen: [
        { text: NORMALFORM },
        { text: 'Lies p und q ab: p = 2 und q = −15. Achte beim Ablesen auf die Vorzeichen.' },
        { text: `Wir setzen ein: x = −1 ± √(1 + 15). Rechne die Wurzel aus, dann einmal minus und einmal plus, und ${ZUERST}.`,
          belege: [['=', '2/2', '1']], fehlbild: ['pq_vorzeichen', 'wurzel_vergessen'] },
      ],
    },
    'quadrgl-formel-02': {
      stufen: [
        { text: NORMALFORM },
        { text: 'Lies p und q ab: p = −6 und q = 5. Achte beim Ablesen auf die Vorzeichen.' },
        { text: `Wir setzen ein: x = 3 ± √(9 − 5), denn −p/2 ist hier positiv. Rechne die Wurzel aus, dann einmal minus und einmal plus, und ${ZUERST}.`,
          belege: [['begr', '2', 'p/2 in der p-q-Formel'], ['=', '6/2', '3'], ['=', '3 · 3', '9']], fehlbild: ['pq_vorzeichen', 'wurzel_vergessen'] },
      ],
    },
    'quadrgl-formel-03': {
      stufen: [
        { text: 'Für die p-q-Formel darf vor x² keine Zahl stehen. Was musst du deshalb zuerst tun?' },
        { text: 'Teile die ganze Gleichung durch 2: x² − 2x − 3 = 0.',
          belege: [['gl', '2x² − 4x − 6 = 0', 'x² − 2x − 3 = 0', '1/2']], fehlbild: 'division_vergessen' },
        { text: `Jetzt ist p = −2 und q = −3, also x = 1 ± √(1 + 3). Rechne die Wurzel aus, dann einmal minus und einmal plus, und ${ZUERST}.`,
          belege: [['=', '2/2', '1']], fehlbild: 'pq_vorzeichen',
          frei: [['1', '−p/2 = 1, nicht die Lösung −1'], ['3', 'q = −3 aus der Normalform, nicht die Lösung 3']] },
      ],
    },
    'quadrgl-formel-04': {
      stufen: [
        { text: NORMALFORM },
        { text: 'Lies p und q ab: p = 4 und q = −1. Achte beim Ablesen auf die Vorzeichen.' },
        { text: `Wir setzen ein: x = −2 ± √(4 + 1) = −2 ± √5. Rechne √5 mit dem Taschenrechner, dann minus und plus; runde auf zwei Stellen nach dem Komma, kleinere Lösung zuerst.`,
          belege: [['begr', '2', 'p/2 in der p-q-Formel'], ['=', '4/2', '2'], ['=', '2 · 2', '4'], ['=', '4 + 1', '5']], fehlbild: ['pq_vorzeichen', 'wurzel_vergessen'] },
      ],
    },
    'quadrgl-formel-05': {
      stufen: [
        { text: 'Gefragt ist die längere Seite. Nenne die Breite x und überlege, wie du die Länge mit x ausdrückst.' },
        { text: 'Die Länge ist x + 4, also x · (x + 4) = 60; bring alles auf eine Seite: x² + 4x − 60 = 0.',
          belege: [['gl', 'x · (x + 4) = 60', 'x² + 4x − 60 = 0', '1']] },
        { text: 'Mit p = 4 und q = −60 ergibt die p-q-Formel x = −2 ± √(4 + 60). Nur die positive Breite ist sinnvoll; rechne danach + 4, denn gefragt ist die längere Seite.',
          belege: [['begr', '2', 'p/2 in der p-q-Formel'], ['=', '4/2', '2']], fehlbild: ['falsche_groesse_beantwortet', 'pq_vorzeichen'] },
      ],
    },
    'quadrgl-formel-06': {
      stufen: [
        { text: 'Nenne die Wegbreite x. Überlege, wie lang und wie breit Beet und Weg zusammen sind.' },
        { text: 'Der Weg liegt auf beiden Seiten, also sind Beet und Weg zusammen 20 + 2x lang und 15 + 2x breit: (20 + 2x) · (15 + 2x) = 500.',
          belege: [['begr', '2', 'Weg rundherum, also auf beiden Seiten']] },
        { text: 'Ausmultiplizieren, 500 abziehen und durch 4 teilen ergibt x² + 17,5x − 50 = 0, also x = −8,75 ± √(76,5625 + 50). Nur die positive Breite ist sinnvoll.',
          belege: [['=', '2 · 2', '4'], ['gl', '(20 + 2x) · (15 + 2x) = 500', 'x² + 17,5x − 50 = 0', '1/4'],
            ['=', '17,5/2', '8,75'], ['=', '8,75 · 8,75', '76,5625']],
          fehlbild: ['division_vergessen', 'pq_vorzeichen'] },
      ],
    },
  },
};
