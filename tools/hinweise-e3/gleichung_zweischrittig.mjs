// Hinweise (KI-Entwurf, E3) für gleichung_zweischrittig: a · x + b = c, erst − b, dann : a.
// Die Aufgaben haben keinen gespeicherten Lösungsweg (solution null); die Hinweise folgen dem Standardweg.
// Schlüssel ist tasks.source_ref; Belege siehe tools/hinweise-e3-lib.mjs.

const zwei = (a, b, c) => ({
  stufen: [
    { text: 'Gesucht ist die Zahl für x. Überlege, welche Rechnung du zuerst rückgängig machst: das Plus oder das Mal.' },
    { text: `Rechne zuerst auf beiden Seiten − ${b}: ${a}x = ${c - b}. Links steht jetzt noch ${a}x, nicht x.`,
      belege: [['gl', `${a}x + ${b} = ${c}`, `${a}x = ${c - b}`, '1']], fehlbild: ['b_ignoriert', 'addiert_statt_subtrahiert'] },
    { text: `Aus ${a}x = ${c - b} teilen wir beide Seiten durch ${a}: x = ${c - b} : ${a}. Rechne die Division aus.`,
      belege: [['gl', `${a}x = ${c - b}`, `x = ${c - b} : ${a}`, `1/${a}`]], fehlbild: 'division_vergessen' },
  ],
});

export default {
  skill: 'gleichung_zweischrittig',
  aufgaben: {
    'gleichung-zweischrittig-01': zwei(3, 6, 24),
    'gleichung-zweischrittig-02': zwei(2, 4, 20),
    'gleichung-zweischrittig-03': zwei(5, 10, 45),
    'gleichung-zweischrittig-04': zwei(4, 8, 40),
    'gleichung-zweischrittig-05': zwei(3, 9, 30),
    'gleichung-zweischrittig-06': zwei(6, 12, 42),
  },
};
