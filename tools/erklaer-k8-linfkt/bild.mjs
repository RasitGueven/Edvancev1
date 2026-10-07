/**
 * Bild einer Erklärsequenz bzw. Figur einer Check-Aufgabe: eine Gerade y = m·x + b mit
 * beschrifteten Punkten, Generator koordinatensystem (scripts/figures, wie task_figures).
 * Die Punkte tragen nur Buchstaben; Koordinaten im Bild überlappen die Gerade.
 *
 *   bild([x_min, x_max, y_min, y_max], m, b, [['A', x, y], …], alt, [[x, y, dx, dy], …])
 * Das letzte Argument (optional) zeichnet Steigungsdreiecke („rüber dx“, „hoch dy“);
 * nur in Erklärbildern, nie in Check-Figuren (die Beschriftung wäre die Lösung).
 */
export const bild = ([x_min, x_max, y_min, y_max], m, b, punkte, alt, dreiecke = []) => ({
  generator: 'koordinatensystem',
  params: {
    x_min, x_max, y_min, y_max,
    funktionen: [{ typ: 'linear', m, b }],
    punkte: punkte.map(([label, x, y]) => ({ x, y, label })),
    ...(dreiecke.length ? { steigungsdreiecke: dreiecke.map(([x, y, dx, dy]) => ({ x, y, dx, dy })) } : {}),
  },
  alt,
});
