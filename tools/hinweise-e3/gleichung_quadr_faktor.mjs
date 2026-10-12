// Hinweise (KI-Entwurf, E3) für gleichung_quadr_faktor: Ausklammern und Satz vom Nullprodukt.
// Schlüssel ist tasks.source_ref; Belege siehe tools/hinweise-e3-lib.mjs.

export default {
  skill: 'gleichung_quadr_faktor',
  aufgaben: {
    'quadrgl-faktor-01': {
      stufen: [
        { text: 'Gesucht sind alle Zahlen für x, die die Gleichung erfüllen. Schau, ob in beiden Summanden derselbe Faktor steckt.' },
        { text: 'Klammere x aus. Was bleibt von x² − 5x in der Klammer übrig?' },
        { text: 'Wir klammern x aus: x · (x − 5) = 0. Setze beide Faktoren gleich null, überlege bei x − 5 genau, wann die Klammer null wird, und trag die kleinere Lösung zuerst ein.',
          belege: [['≡', 'x² − 5x', 'x · (x − 5)']], fehlbild: ['loesung_null_verloren', 'vorzeichen_aus_klammer'] },
      ],
    },
    'quadrgl-faktor-02': {
      stufen: [
        { text: 'Links steht schon ein Produkt, rechts steht null. Was weißt du über ein Produkt, das null ergibt?' },
        { text: 'Ein Produkt ist null, wenn ein Faktor null ist. Setze deshalb jede Klammer einzeln gleich null: x − 3 = 0 und x + 5 = 0.' },
        { text: 'Wir stellen beide Gleichungen nach x um, indem wir die Zahl neben x auf die andere Seite bringen. Achte dabei auf das Vorzeichen und trag die kleinere Lösung zuerst ein.',
          fehlbild: 'vorzeichen_aus_klammer' },
      ],
    },
    'quadrgl-faktor-03': {
      stufen: [
        { text: 'Gesucht sind alle x, für die beide Seiten gleich sind. Teile nicht durch x, sonst geht eine Lösung verloren; bring lieber alles auf eine Seite.',
          fehlbild: 'loesung_null_verloren' },
        { text: 'Bring 12x auf die linke Seite: 3x² − 12x = 0.',
          belege: [['gl', '3x² = 12x', '3x² − 12x = 0', '1']] },
        { text: 'Wir klammern 3x aus: 3x · (x − 4) = 0. Setze jeden Faktor gleich null, löse beide kleinen Gleichungen und trag die kleinere Lösung zuerst ein.',
          belege: [['≡', '3x² − 12x', '3x · (x − 4)']] },
      ],
    },
    'quadrgl-faktor-04': {
      stufen: [
        { text: 'Links steht ein Produkt aus zwei Faktoren, rechts steht null. Was folgt daraus für die einzelnen Faktoren?' },
        { text: 'Setze jeden der beiden Faktoren einzeln gleich null. Aus dem zweiten Faktor wird die Gleichung 2x − 7 = 0.' },
        { text: 'Wir lösen 2x − 7 = 0: Rechne erst auf beiden Seiten + 7 und teile dann durch 2. Vergiss die Lösung aus dem Faktor x nicht und trag die kleinere Lösung zuerst ein.',
          fehlbild: ['division_vergessen', 'loesung_null_verloren'] },
      ],
    },
    'quadrgl-faktor-05': {
      var: 't',
      stufen: [
        { text: 'Am Boden hat der Ball die Höhe null. Welche Gleichung entsteht daraus für t?' },
        { text: 'Setze h = 0: 20t − 5t² = 0.' },
        { text: 'Wir klammern t aus: t · (20 − 5t) = 0. Die Lösung t = 0 ist der Abwurf; löse also 20 − 5t = 0 nach t auf, achte auf das Vorzeichen und rechne, bis t allein steht.',
          belege: [['≡', '20t − 5t²', 't · (20 − 5t)']], fehlbild: ['vorzeichen_beim_umstellen', 'division_vergessen'] },
      ],
    },
    'quadrgl-faktor-06': {
      gesucht: 'b',
      vars: { b: ['7', '-2', '13'] },
      stufen: [
        { text: 'Du kennst beide Lösungen und suchst die Zahl b. Überlege, wie die Gleichung nach dem Ausklammern aussieht.' },
        { text: 'Klammere x aus: x · (2x + b) = 0.', belege: [['≡', '2x² + b·x', 'x · (2x + b)']] },
        { text: 'Die Lösung 3 macht den zweiten Faktor null, also setzen wir x = 3 ein: 2 · 3 + b = 0. Stell diese Gleichung nach b um und achte auf das Vorzeichen.',
          fehlbild: 'vorzeichen_aus_klammer' },
      ],
    },
  },
};
