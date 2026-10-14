// Hinweise (KI-Entwurf, E3) für vorzeichen_add_sub: Addieren und Subtrahieren mit negativen Zahlen am Zahlenstrahl.
// Die Aufgaben haben keinen gespeicherten Lösungsweg (solution null); die Hinweise folgen dem Zahlenstrahl.
// Die Aufgabe schreibt das Minus als Bindestrich („-3 - 5“); die Hinweise schreiben „−“ wie die übrigen Lösungen.
// Schlüssel ist tasks.source_ref; Belege siehe tools/hinweise-e3-lib.mjs.

const S1 = { text: 'Stell dir die Rechnung am Zahlenstrahl vor. Wo startest du, und in welche Richtung gehst du?' };

/** −a − b: weiter ins Minus */
const beideMinus = (a, b) => ({
  stufen: [
    S1,
    { text: `Du startest bei −${a} und gehst ${b} Schritte nach links.` },
    { text: `Von der 0 bis −${a} sind es schon ${a} Schritte, dann kommen noch ${b} dazu. Zähl beide zusammen; das Ergebnis bleibt negativ.`,
      fehlbild: ['vorzeichen_ignoriert', 'betrag_fehler'] },
  ],
});

/** −a + b */
const minusPlus = (a, b) => ({
  stufen: [
    S1,
    { text: `Du startest bei −${a} und gehst ${b} Schritte nach rechts.` },
    b < a
      ? { text: `Mit ${b} Schritten nach rechts kommst du nicht bis zur 0; es fehlen noch ${a} − ${b} Schritte. So weit liegst du links von der 0, also im Minus.`,
          fehlbild: ['vorzeichen_ignoriert', 'betrag_fehler'] }
      : { text: `Nach ${a} Schritten bist du bei 0. Es bleiben noch ${b} − ${a} Schritte nach rechts, also ins Plus.`,
          fehlbild: ['vorzeichen_ignoriert', 'betrag_fehler'] },
  ],
});

/** a − b mit b > a: über die 0 ins Minus */
const ueberNull = (a, b) => ({
  stufen: [
    S1,
    { text: `Du startest bei ${a} und gehst ${b} Schritte nach links.` },
    { text: `Nach ${a} Schritten bist du bei 0. Es bleiben noch ${b} − ${a} Schritte nach links, also ins Minus.`,
      fehlbild: ['vorzeichen_ignoriert', 'betrag_fehler'] },
  ],
});

export default {
  skill: 'vorzeichen_add_sub',
  aufgaben: {
    'vorzeichen-addieren-01': beideMinus(3, 5),
    'vorzeichen-addieren-02': minusPlus(7, 4),
    'vorzeichen-addieren-03': ueberNull(2, 9),
    'vorzeichen-addieren-04': beideMinus(6, 2),
    'vorzeichen-addieren-05': minusPlus(4, 9),
    'vorzeichen-addieren-06': ueberNull(3, 8),
    'vorzeichen-addieren-07': minusPlus(9, 5),
  },
};
