// Hinweise (KI-Entwurf, E3) für gleichung_quadr_anzahl: Diskriminante D = (p/2)² − q und Anzahl der Lösungen.
// Schlüssel ist tasks.source_ref; Belege siehe tools/hinweise-e3-lib.mjs.

const HALB = ['begr', '2', 'p/2 in der Diskriminante'];

export default {
  skill: 'gleichung_quadr_anzahl',
  aufgaben: {
    'quadrgl-anzahl-01': {
      stufen: [
        { text: 'Die Anzahl der Lösungen hängt davon ab, was in der p-q-Formel unter der Wurzel steht. Wie heißt dieser Teil?' },
        { text: 'Lies p und q ab: p = 4 und q = 5. Berechne damit die Diskriminante D = (p/2)² − q.' },
        { text: 'Wir halbieren p und rechnen D = 2² − 5. Schau dann, ob D positiv, null oder negativ ist; davon hängt die Anzahl der Lösungen ab.',
          belege: [HALB, ['=', '4/2', '2']], fehlbild: 'halbieren_vergessen' },
      ],
    },
    'quadrgl-anzahl-02': {
      stufen: [
        { text: 'Die Formel für D steht schon in der Aufgabe. Du brauchst dafür nur p und q aus der Gleichung.' },
        { text: 'Lies p und q mit ihren Vorzeichen ab: p = −6 und q = 8. Setze beide in D = (p/2)² − q ein.' },
        { text: 'Wir halbieren p: p/2 = −3, also D = (−3)² − 8. Denk daran, dass das Quadrat einer negativen Zahl positiv ist.',
          belege: [['=', '−6/2', '−3']], fehlbild: ['halbieren_vergessen', 'vorzeichen_potenz'] },
      ],
    },
    'quadrgl-anzahl-03': {
      stufen: [
        { text: 'Die Formel für D steht schon in der Aufgabe. Du brauchst dafür nur p und q aus der Gleichung.' },
        { text: 'Lies p und q mit ihren Vorzeichen ab: p = −5 und q = −6. Setze beide in D = (p/2)² − q ein.' },
        { text: 'Wir halbieren p: p/2 = −2,5, also D = (−2,5)² − (−6). Das Quadrat einer negativen Zahl ist positiv, und minus (−6) heißt plus 6.',
          belege: [['=', '−5/2', '−2,5']], fehlbild: ['halbieren_vergessen', 'vorzeichen_potenz'] },
      ],
    },
    'quadrgl-anzahl-04': {
      stufen: [
        { text: 'Die Anzahl der Lösungen erkennst du an der Diskriminante. Prüf zuerst, ob die Gleichung schon die Normalform x² + px + q = 0 hat.' },
        { text: 'Teile die ganze Gleichung durch 2: x² − 4x + 4 = 0.',
          belege: [['gl', '2x² − 8x + 8 = 0', 'x² − 4x + 4 = 0', '1/2']], fehlbild: 'division_vergessen' },
        { text: 'Jetzt ist p = −4 und q = 4, also D = (−2)² − 4. Denk daran, dass das Quadrat einer negativen Zahl positiv ist, und überlege, was D für die Anzahl bedeutet.',
          belege: [['=', '−4/2', '−2']], fehlbild: 'vorzeichen_potenz' },
      ],
    },
    'quadrgl-anzahl-05': {
      stufen: [
        { text: 'Bring die Gleichung zuerst in die Normalform x² + px + q = 0. Dann entscheidet die Diskriminante über die Anzahl.' },
        { text: 'Multipliziere aus: 10x − x² = 25. Bring alles nach rechts, damit x² mit Plus dasteht: 0 = x² − 10x + 25.',
          belege: [['≡', 'x · (10 − x)', '10x − x²'], ['gl', 'x · (10 − x) = 25', '0 = x² − 10x + 25', '1']] },
        { text: 'Mit p = −10 und q = 25 ist p/2 = −5, also D = (−5)² − 25. Denk daran, dass das Quadrat einer negativen Zahl positiv ist.',
          belege: [['=', '−10/2', '−5']], fehlbild: ['halbieren_vergessen', 'vorzeichen_potenz'] },
      ],
    },
    'quadrgl-anzahl-06': {
      gesucht: 'q',
      stufen: [
        { text: 'Überlege, welchen Wert die Diskriminante haben muss, wenn es genau eine Lösung gibt.' },
        { text: 'Genau eine Lösung heißt D = 0. Stell D für diese Gleichung auf: D = (6/2)² − q.', belege: [HALB] },
        { text: 'Wir rechnen (6/2)² aus; diese Zahl minus q muss null ergeben. Stell nach q um und setz dein q zur Probe ein: Ergibt sich wirklich null?',
          fehlbild: ['halbieren_vergessen', 'betrag_fehler'] },
      ],
    },
  },
};
