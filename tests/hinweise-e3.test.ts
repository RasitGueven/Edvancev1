// Hinweise E3: Die Nachrechnung ist das Gate der Hinweis-Entwürfe. Sie muss die echten Quellen
// durchlassen und gezielt verdorbene Kopien finden.

import fs from 'node:fs'
import { describe, expect, it } from 'vitest'
import { pruefeAufgabe, zahlen } from '../tools/hinweise-e3-lib.mjs'
import { ladeQuellen, pruefen } from '../tools/hinweise-e3.mjs'

type Stufe = { text: string; belege?: unknown[]; fehlbild?: string | string[] }
type Eintrag = { stufen: Stufe[]; var?: string; vars?: Record<string, string[]>; gesucht?: string }

const bestand = JSON.parse(fs.readFileSync('docs/prefill/hinweise-e3-snapshot.json', 'utf8')).aufgaben
const aufgabe = (ref: string) => bestand.find((t: { source_ref: string }) => t.source_ref === ref)

/** quadrgl-faktor-03: 3x² = 12x, Lösungen 0 und 4 */
const gut = (): Eintrag => ({
  stufen: [
    { text: 'Gesucht sind alle x, für die beide Seiten gleich sind. Bring alles auf eine Seite.' },
    { text: 'Bring 12x auf die linke Seite: 3x² − 12x = 0.', belege: [['gl', '3x² = 12x', '3x² − 12x = 0', '1']] },
    { text: 'Wir klammern 3x aus: 3x · (x − 4) = 0. Setze jeden Faktor gleich null.', belege: [['≡', '3x² − 12x', '3x · (x − 4)']] },
  ],
})
const befunde = (e: Eintrag, ref = 'quadrgl-faktor-03') => pruefeAufgabe(aufgabe(ref), e).fehler
const mit = (i: number, s: Partial<Stufe>) => { const e = gut(); e.stufen[i] = { ...e.stufen[i], ...s }; return e }

describe('hinweise-e3-lib', () => {
  it('liest Zahlen, Minus nur direkt vor der Ziffer als Vorzeichen', () => {
    const z = (t: string) => zahlen(t).map((n: { wert: { toString(): string } }) => n.wert.toString())
    expect(z('3x² − 12x = 0')).toEqual(['3', '12', '0'])
    expect(z('also x = −5 und (−3,5)')).toEqual(['-5', '-7/2'])
  })

  it('lässt den guten Eintrag durch', () => {
    expect(befunde(gut())).toEqual([])
  })

  it('findet verdorbene Kopien', () => {
    const fall = (e: Eintrag, muster: RegExp) => expect(befunde(e).join('\n')).toMatch(muster)
    fall(mit(0, { text: 'Am Ende kommt 4 heraus. Bring alles auf eine Seite.' }), /Stufe 1 nennt 4/)
    fall(mit(2, { text: 'Wir klammern 3x aus. Also ist x = 4 eine Lösung.' }), /Ergebnis x = 4/)
    fall(mit(2, { text: 'Wir klammern 3x aus: 3x · (x − 4) = 0. Die zweite Lösung ist 4.' }), /Lösungszahl 4 steht frei/)
    fall(mit(2, { text: 'Wir klammern 3x aus: 3x · (x − 3) = 0. Setze jeden Faktor gleich null.', belege: [['≡', '3x² − 12x', '3x · (x − 3)']] }), /Beleg stimmt nicht/)
    fall(mit(1, { text: 'Bring 12x nach links: 3x² − 12x = 0.', belege: [['gl', '3x² = 12x', '3x² + 12x = 0', '1']] }), /steht nicht wörtlich/)
    fall(mit(1, { text: 'Bring 12x nach links und teile durch 6.', belege: [] }), /Zahl 6 ist nicht belegt/)
    fall(mit(2, { text: 'Wir klammern 3x aus. Die erste Lösung ist 0.' }), /nennt eine Lösung als Zahl/)
    fall(mit(0, { text: 'Das ist nicht falsch. Bring alles auf eine Seite.' }), /Wort „falsch“/)
    fall(mit(0, { text: 'Eins. Zwei. Drei.' }), /3 Sätze/)
    fall(mit(1, { text: 'Bring 12x auf die linke Seite: 3x² - 12x = 0.', belege: [] }), /Schreibweise/)
    fall(mit(0, { fehlbild: 'gibt_es_nicht' }), /Fehlbild gibt_es_nicht/)
    fall({ stufen: gut().stufen.slice(0, 2) }, /2 Stufen statt 3/)
    fall(mit(1, { text: 'x'.repeat(201) + '.' }), /Zeichen/)
  })

  it('prüft die gesuchte Größe mit Buchstaben (b = −6) und eine andere Unbekannte (t)', () => {
    const b: Eintrag = { gesucht: 'b', stufen: [
      { text: 'Du suchst b.' }, { text: 'Klammere x aus.' }, { text: 'Also ist b = −6.' }] }
    expect(befunde(b, 'quadrgl-faktor-06').join('\n')).toMatch(/Ergebnis b = −6|Ergebnis b = 6/)
    const t: Eintrag = { var: 't', stufen: [
      { text: 'Am Boden ist h null.' }, { text: 'Setze h = 0.' }, { text: 'Also ist t = 4.' }] }
    expect(befunde(t, 'quadrgl-faktor-05').join('\n')).toMatch(/Ergebnis t = 4/)
  })
})

describe('Quellen tools/hinweise-e3', () => {
  it('jede Quelle ist nachgerechnet und deckt ihren Skill ganz ab', async () => {
    const { fehler, liste } = pruefen(await ladeQuellen([]))
    expect(fehler).toEqual([])
    expect(liste.length).toBeGreaterThan(0)
  })
})
