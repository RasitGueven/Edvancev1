// Hinweise (KI-Entwurf, E3) für term_ausklammern (MC): größten gemeinsamen Teiler ausklammern.
// Die Aufgaben haben keinen gespeicherten Lösungsweg und keine known_errors; die Hinweise folgen dem Standardweg.
// Die Ablenker sind: nicht ganz ausgeklammert, nur einen Summanden geteilt, falsch geteilt. Keine Stufe nennt eine Option.
// Schlüssel ist tasks.source_ref; Belege siehe tools/hinweise-e3-lib.mjs.

const ggt = (a, b) => (b ? ggt(b, a % b) : a);

/** a · x + b */
const aus = (a, b) => {
  const g = ggt(a, b);
  return {
    stufen: [
      { text: 'Ausklammern heißt: Du suchst eine Zahl, die in beiden Summanden steckt. „So weit wie möglich“ heißt, du nimmst die größte solche Zahl.' },
      { text: `Suche die größte Zahl, durch die sich ${a} und ${b} beide ohne Rest teilen lassen.` },
      { text: `Wir klammern ${g} aus: Teile ${a}x und ${b} jeweils durch ${g} und schreib die Ergebnisse in die Klammer. Rechne zur Probe die Klammer wieder aus und vergleiche mit den Antworten.`,
        belege: [['ggT', `${a}, ${b}`, String(g)]] },
    ],
  };
};

export default {
  skill: 'term_ausklammern',
  aufgaben: {
    'term-ausklammern-01': aus(4, 8),
    'term-ausklammern-02': aus(6, 12),
    'term-ausklammern-03': aus(4, 20),
    'term-ausklammern-04': aus(9, 27),
    'term-ausklammern-05': aus(8, 12),
    'term-ausklammern-06': aus(12, 18),
  },
};
