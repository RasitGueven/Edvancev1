// Erklaersequenzen (E2b): Die Nachrechnung ist das Gate der Erklaer-Charge. Sie muss die echte
// Charge durchlassen und gezielt verdorbene Kopien finden.

import fs from 'node:fs'
import { describe, expect, it } from 'vitest'
import { bloecke, punkteImText, zahlen } from '../tools/erklaer-lib.mjs'
import { ladeUndPruefe, pruefeCharge, varianteNach } from '../tools/erklaer-rechnen.mjs'

const PFAD = 'docs/prefill/erklaer-k8-linfkt.json'
const lies = (p: string) => JSON.parse(fs.readFileSync(p, 'utf8'))
const laden = () => {
  const charge = lies(PFAD)
  return { charge, checks: lies(charge.check_charge), bestand: lies(charge.bestand), thema: lies(charge.aufgaben_charge) }
}
const pruefe = (x: ReturnType<typeof laden>) => pruefeCharge(x.charge, x.checks, x.bestand, x.thema)

describe('erklaer-lib', () => {
  it('liest Zahlen aus Text und TeX, Minus nur als Vorzeichen', () => {
    const z = (t: string) => zahlen(t).map(String)
    expect(z('$m = \\frac{-6}{3} = -2$')).toEqual(['-6', '3', '-2'])
    expect(z('$2 - (-1) = 3$ und 5-(-1)')).toEqual(['2', '-1', '3', '5', '-1'])
    expect(z('1. Von x = 1 bis x = 4 sind es 3 Schritte.')).toEqual(['1', '4', '3'])
    expect(z('$\\frac{y_B - y_A}{x_B - x_A}$')).toEqual([])
  })

  it('findet Punkte und Bloecke', () => {
    expect(punkteImText('A(-1|3) und B(2 | -3)').map((p) => `${p.label}${p.x}|${p.y}`)).toEqual(['A-1|3', 'B2|-3'])
    expect(bloecke('# T\n\nText\n\n1. a\n2. b\n\n> M').map((b) => b.art)).toEqual(['titel', 'absatz', 'schritte', 'merk'])
  })
})

describe('erklaer-rechnen', () => {
  it('laesst die Charge durch', () => {
    expect(ladeUndPruefe(PFAD)).toEqual([])
  })

  it('findet eine falsche Rechnung und eine unbelegte Zahl', () => {
    const x = laden()
    const s = x.charge.kernideen[0].schritte.find((y: { art: string }) => y.art === 'beispiel')
    s.rechnungen[2][1] = '4'
    s.inhalt += '\n\nUnd 17.'
    const f = pruefe(x)
    expect(f.some((m) => m.includes('Rechnung 6/2'))).toBe(true)
    expect(f.some((m) => m.includes('Zahl 17'))).toBe(true)
  })

  it('findet einen Bildpunkt neben der Geraden und ein Fehlbild ausserhalb des Bestands', () => {
    const x = laden()
    const k = x.charge.kernideen[0]
    k.schritte[0].bild.params.punkte[0].y = 2
    k.schritte.find((y: { variante: string }) => y.variante === 'B').fehlbild_slugs = ['vorzeichen_ignoriert']
    const f = pruefe(x)
    expect(f.some((m) => m.includes('liegt nicht auf der Geraden'))).toBe(true)
    expect(f.some((m) => m.includes('vorzeichen_ignoriert nicht in den known_errors'))).toBe(true)
  })

  it('verbietet einen Schritt, der die Antwort eines Checks nennt', () => {
    const x = laden()
    const k = x.charge.kernideen[0]
    k.schritte.find((y: { art: string }) => y.art === 'beispiel').rechnungen.push(['8/2', '4'])
    expect(pruefe(x).some((m) => m.includes('= Antwort von erklaer-steigung-k1-c1'))).toBe(true)
  })

  it('waehlt die Variante wie erklaer_check_abgeben', () => {
    const { charge } = laden()
    const [k1, k2, k3] = charge.kernideen
    expect(varianteNach(k1, 'steigung_kehrwert')).toEqual({ variante: 'B', grund: 'Fehlbild' })
    expect(varianteNach(k2, 'steigung_kehrwert')).toEqual({ variante: 'C', grund: 'Fehlbild' })
    expect(varianteNach(k3, 'steigung_kehrwert')).toEqual({ variante: 'B', grund: 'nächste ungezeigte' })
  })
})
