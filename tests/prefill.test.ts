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

const MIGRATION = 'supabase/migrations/20260930120000_prefill_mathe8_pilot.sql'
const tmp = (name: string, inhalt: string): string => {
  const pfad = path.join(fs.mkdtempSync(path.join(os.tmpdir(), 'prefill-')), name)
  fs.writeFileSync(pfad, inhalt)
  return pfad
}
const charge = () => JSON.parse(fs.readFileSync(CHARGE, 'utf8'))

describe('verify-prefill', () => {
  it('laesst den Pilot samt Migration ohne Charge-Fehler durch', async () => {
    const r = await pruefePrefill({ charge: CHARGE, snapshot: SNAPSHOT, blind: BLIND, migration: MIGRATION })
    expect(r.fehler).toEqual([])
  })

  it('findet eingebaute Fehler', async () => {
    const c = charge()
    c.aufgaben[0].felder.est_duration_sec.wert = 999
    c.aufgaben[0].loesung.solution.wert = '(2x + 3)² = 4x² + 9'
    c.aufgaben[1].loesung.hints.wert[0].text = 'Du hast es gemeistert'
    c.aufgaben[2].loesung.typical_errors.wert = [{ fehler: 'falsches Feld' }]
    delete c.aufgaben[10].leer.unit
    const { fehler } = await pruefePrefill({ charge: tmp('mutant.json', JSON.stringify(c)), snapshot: SNAPSHOT })
    const alle = fehler.join('\n')
    expect(alle).toMatch(/Zeitregel/)
    expect(alle).toMatch(/Loesungsweg nennt das richtige Ergebnis nicht/)
    expect(alle).toMatch(/Mastery-Sprache/)
    expect(alle).toMatch(/typical_errors: Form/)
    expect(alle).toMatch(/tasks.unit leer ohne Grund/)
  })

  it('meldet eine Abweichung des Blind-Loesers', async () => {
    const b = JSON.parse(fs.readFileSync(BLIND, 'utf8'))
    b[10].antwort = '10004'
    const r = await pruefePrefill({ charge: CHARGE, snapshot: SNAPSHOT, blind: tmp('blind.json', JSON.stringify(b)) })
    expect(r.bestand.join('\n')).toMatch(/Blind-Loeser 10004/)
  })

  it('lehnt eine VERA8-Aufgabe in der Charge ab', async () => {
    const snap = JSON.parse(fs.readFileSync(SNAPSHOT, 'utf8'))
    snap[0].task.source = 'VERA8_IQB'
    const { fehler } = await pruefePrefill({ charge: CHARGE, snapshot: tmp('snap.json', JSON.stringify(snap)) })
    expect(fehler.join('\n')).toMatch(/VERA8-Aufgabe \(source=VERA8_IQB\)/)
  })

  it('lehnt eine Migration ab, die VERA8 nicht ausschliesst oder fremde Aufgaben anfasst', async () => {
    const ohneGuard = fs.readFileSync(MIGRATION, 'utf8').replace(/ and source is distinct from 'VERA8_IQB'/, '')
    const r1 = await pruefePrefill({ charge: CHARGE, snapshot: SNAPSHOT, migration: tmp('a_prefill_x.sql', ohneGuard) })
    expect(r1.fehler.join('\n')).toMatch(/ohne VERA8-Ausschluss/)

    const fremd = `update public.tasks set afb = 'I' where id = '00000000-0000-0000-0000-000000000001' and source is distinct from 'VERA8_IQB';\n`
    const r2 = await pruefePrefill({ charge: CHARGE, snapshot: SNAPSHOT, migration: tmp('b_prefill_x.sql', fremd) })
    expect(r2.fehler.join('\n')).toMatch(/nicht in der Charge/)
  })
})
