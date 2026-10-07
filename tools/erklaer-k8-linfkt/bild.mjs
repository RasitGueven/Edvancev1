/**
 * Bild einer Erklärsequenz bzw. Figur einer Check-Aufgabe: eine Gerade y = m·x + b mit
 * beschrifteten Punkten, Generator koordinatensystem (scripts/figures, wie task_figures).
 * Die Punkte tragen nur Buchstaben; Koordinaten im Bild überlappen die Gerade.
 *
 *   bild([x_min, x_max, y_min, y_max], m, b, [['A', x, y], …], alt)
 */
export const bild = ([x_min, x_max, y_min, y_max], m, b, punkte, alt) => ({
  generator: 'koordinatensystem',
  params: {
    x_min, x_max, y_min, y_max,
    funktionen: [{ typ: 'linear', m, b }],
    punkte: punkte.map(([label, x, y]) => ({ x, y, label })),
  },
  alt,
});
