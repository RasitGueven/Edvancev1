// Hinweise (KI-Entwurf, E3) für gleichung_einschrittig: eine Gegenrechnung auf beiden Seiten.
// Die Aufgaben haben keinen gespeicherten Lösungsweg (solution null); die Hinweise folgen dem Standardweg.
// Schlüssel ist tasks.source_ref; Belege siehe tools/hinweise-e3-lib.mjs.

const S1 = { text: 'Gesucht ist die Zahl für x. Überlege, welche Rechnung mit x gemacht wird und wie du sie rückgängig machst.' };

/** a · x = b */
const mal = (a, b) => ({
  stufen: [
    S1,
    { text: `In ${a}x = ${b} wird x mit ${a} multipliziert. Teile deshalb beide Seiten durch ${a}.`, fehlbild: 'falsche_gegenoperation' },
    { text: `Wir teilen beide Seiten durch ${a}: x = ${b} : ${a}. Rechne die Division aus.`,
      belege: [['gl', `${a}x = ${b}`, `x = ${b} : ${a}`, `1/${a}`]] },
  ],
});

/** x + a = b */
const plus = (a, b) => ({
  stufen: [
    S1,
    { text: `Zu x wird ${a} addiert. Ziehe deshalb auf beiden Seiten ${a} ab.`, fehlbild: 'falsche_gegenoperation' },
    { text: `Wir ziehen auf beiden Seiten ${a} ab: x = ${b} − ${a}. Rechne die Differenz genau in dieser Reihenfolge aus.`,
      belege: [['gl', `x + ${a} = ${b}`, `x = ${b} − ${a}`, '1']], fehlbild: 'seiten_verwechselt' },
  ],
});

/** x − a = b */
const minus = (a, b) => ({
  stufen: [
    S1,
    { text: `Von x wird ${a} abgezogen. Addiere deshalb auf beiden Seiten ${a}.`, fehlbild: ['falsche_gegenoperation', 'seiten_verwechselt'] },
    { text: `Wir addieren auf beiden Seiten ${a}: x = ${b} + ${a}. Rechne die Summe aus.`,
      belege: [['gl', `x − ${a} = ${b}`, `x = ${b} + ${a}`, '1']] },
  ],
});

export default {
  skill: 'gleichung_einschrittig',
  aufgaben: {
    'gleichung-einschrittig-01': plus(7, 12),
    'gleichung-einschrittig-02': minus(4, 9),
    'gleichung-einschrittig-03': mal(3, 18),
    'gleichung-einschrittig-04': plus(12, 20),
    'gleichung-einschrittig-05': minus(9, 6),
    'gleichung-einschrittig-06': mal(4, 24),
  },
};
