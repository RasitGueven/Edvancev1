// Vorbefuellung fuer Lenas Pruefung: Rechen-Engine und Pruefer.
// Der Pruefer ist das Gate der Chargen — er muss richtige Werte durchlassen und
// falsche finden. Deshalb neben dem gruenen Pilot auch gezielt verdorbene Kopien.

import fs from 'node:fs'
import os from 'node:os'
import path from 'node:path'
import { describe, expect, it } from 'vitest'
import { Q, faktoren, gleichwertig, zahl } from '../tools/prefill-rechnen.mjs'
import { pruefePrefill } from '../tools/verify-prefill.mjs'

const CHARGE = 'docs/prefill/mathe8-pilot.json'
const SNAPSHOT = 'docs/prefill/mathe8-pilot-snapshot.json'
const BLIND = 'docs/prefill/mathe8-pilot-blind.json'

describe('prefill-rechnen', () => {
  it('rechnet exakt mit Bruechen und Dezimalkomma', () => {
    expect(zahl('30/50*5+1').toString()).toBe('4')
    expect(zahl('4*0.80+0.50').eq(zahl('3,70'))).toBe(true)
    expect(zahl('0.1+0.2').eq(zahl('0.3'))).toBe(true)
  })

  it('rundet kaufmaennisch', () => {
    expect(zahl('round(A/100*5+1,1)', { A: Q.von('89') }).toString()).toBe('11/2')
    expect(zahl('round(A/100*5+1,1)', { A: Q.von('91') }).toString()).toBe('28/5')
  })

  it('erkennt gleichwertige und falsche Terme', () => {
    expect(gleichwertig('(2x + 3)²', '4x² + 12x + 9')).toBe(true)
    expect(gleichwertig('(2x + 3)²', '4x² + 9')).toBe(false)
    expect(gleichwertig('x⁴ - 16', '(x² + 4)(x + 2)(x - 2)')).toBe(true)
  })

  it('zaehlt Faktoren fuer "vollstaendig faktorisiert"', () => {
    expect(faktoren('3(x + 2)²')).toBeGreaterThan(faktoren('3(x² + 4x + 4)'))
    expect(faktoren('(x² + 4)(x + 2)(x - 2)')).toBeGreaterThan(faktoren('(x² + 4)(x² - 4)'))
  })
})

describe('verify-prefill', () => {
  it('laesst den Pilot ohne Charge-Fehler durch', async () => {
    const r = await pruefePrefill({ charge: CHARGE, snapshot: SNAPSHOT, blind: BLIND })
    expect(r.fehler).toEqual([])
  })

  it('findet eingebaute Fehler', async () => {
    const c = JSON.parse(fs.readFileSync(CHARGE, 'utf8'))
    c.aufgaben[0].teile['2'].antwort.wert = ['91']
    c.aufgaben[0].teile['1'].competency_content.wert = 'algebra'
    c.aufgaben[3].felder.est_duration_sec.wert = 999
    c.aufgaben[15].loesung.hints.wert[0].text = 'Du hast es gemeistert'
    delete c.aufgaben[16].leer.curriculum_grade
    const pfad = path.join(fs.mkdtempSync(path.join(os.tmpdir(), 'prefill-')), 'mutant.json')
    fs.writeFileSync(pfad, JSON.stringify(c))

    const { fehler } = await pruefePrefill({ charge: pfad, snapshot: SNAPSHOT, blind: BLIND })
    const alle = fehler.join('\n')
    expect(alle).toMatch(/nachgerechneter Wert 90 fehlt/)
    expect(alle).toMatch(/nicht im Katalog/)
    expect(alle).toMatch(/Zeitregel/)
    expect(alle).toMatch(/Mastery-Sprache/)
    expect(alle).toMatch(/curriculum_grade leer ohne Grund/)
    expect(alle).toMatch(/Blind-Loeser 90;89/)
  })
})
