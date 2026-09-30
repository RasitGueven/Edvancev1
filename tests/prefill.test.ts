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

const MIGRATION = 'supabase/migrations/20260930150000_prefill_mathe8_pilot.sql'
const tmp = (name: string, inhalt: string): string => {
  const pfad = path.join(fs.mkdtempSync(path.join(os.tmpdir(), 'prefill-')), name)
  fs.writeFileSync(pfad, inhalt)
  return pfad
}
const charge = () => JSON.parse(fs.readFileSync(CHARGE, 'utf8'))
const snapshot = () => JSON.parse(fs.readFileSync(SNAPSHOT, 'utf8'))
const migration = () => fs.readFileSync(MIGRATION, 'utf8')

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
    delete c.aufgaben[3].loesung.hints
    const { fehler } = await pruefePrefill({ charge: tmp('mutant.json', JSON.stringify(c)), snapshot: SNAPSHOT })
    const alle = fehler.join('\n')
    expect(alle).toMatch(/Zeitregel/)
    expect(alle).toMatch(/Loesungsweg nennt das richtige Ergebnis nicht/)
    expect(alle).toMatch(/Mastery-Sprache/)
    expect(alle).toMatch(/typical_errors: Form/)
    expect(alle).toMatch(/task_solutions.hints leer ohne Grund/)
  })

  it('wertet Coach-Hinweise und Einheit bei reinen Zahlen nicht als Luecke', async () => {
    const r = await pruefePrefill({ charge: CHARGE, snapshot: SNAPSHOT })
    expect(r.bericht).not.toMatch(/coach_hints/)
    expect(r.bericht).not.toMatch(/tasks\.unit/)
  })

  it('lehnt eine Ueberschreibung ohne Begruendung und Nachweis ab', async () => {
    const c = charge()
    c.aufgaben[0].felder.afb = { wert: 'I', alt: 'II', sicher: 'hoch', grund: 'x' }
    const { fehler } = await pruefePrefill({ charge: tmp('ueber.json', JSON.stringify(c)), snapshot: SNAPSHOT })
    expect(fehler.join('\n')).toMatch(/Ueberschreibung ohne Begruendung/)
    expect(fehler.join('\n')).toMatch(/ohne Nachweis/)
  })

  it('laesst eine begruendete Ueberschreibung mit exaktem Altwert durch und nennt sie', async () => {
    const c = charge()
    c.aufgaben[0].felder.afb = {
      wert: 'I', alt: 'II', sicher: 'hoch', grund: 'Test', begruendung: 'Testfall', nachweis: 'status draft, keine Review',
    }
    const r = await pruefePrefill({ charge: tmp('ueber2.json', JSON.stringify(c)), snapshot: SNAPSHOT })
    expect(r.fehler.join('\n')).not.toMatch(/Ueberschreibung/)
    expect(r.bericht).toMatch(/"II" → "I" \(ueberschrieben\)/)
  })

  it('verlangt Bildbedarf bei jeder Aufgabe', async () => {
    const snap = snapshot()
    snap[0].task.needs_image = null
    const { fehler } = await pruefePrefill({ charge: CHARGE, snapshot: tmp('snap.json', JSON.stringify(snap)) })
    expect(fehler.join('\n')).toMatch(/needs_image nicht gesetzt/)
  })

  it('meldet eine Abweichung des Blind-Loesers', async () => {
    const b = JSON.parse(fs.readFileSync(BLIND, 'utf8'))
    b[10].antwort = '10004'
    const r = await pruefePrefill({ charge: CHARGE, snapshot: SNAPSHOT, blind: tmp('blind.json', JSON.stringify(b)) })
    expect(r.bestand.join('\n')).toMatch(/Blind-Loeser 10004/)
  })

  it('lehnt eine VERA8-Aufgabe in der Charge ab', async () => {
    const snap = snapshot()
    snap[0].task.source = 'VERA8_IQB'
    const { fehler } = await pruefePrefill({ charge: CHARGE, snapshot: tmp('snap.json', JSON.stringify(snap)) })
    expect(fehler.join('\n')).toMatch(/VERA8-Aufgabe \(source=VERA8_IQB\)/)
  })

  it('lehnt Migrationen ohne VERA8-Ausschluss, ohne Compare-and-set, mit fremden Aufgaben oder Werten im Kennzeichen ab', async () => {
    const pruef = (name: string, sql: string) =>
      pruefePrefill({ charge: CHARGE, snapshot: SNAPSHOT, migration: tmp(name, sql) }).then((r) => r.fehler.join('\n'))

    expect(await pruef('a_prefill_x.sql', migration().replace(/ and source is distinct from 'VERA8_IQB'/, ''))).toMatch(/ohne VERA8-Ausschluss/)
    expect(await pruef('b_prefill_x.sql', migration().replace('/*cas*/ ', ''))).toMatch(/UPDATE ohne Compare-and-set/)
    const fremd = `update public.tasks set afb = 'I' where id = '00000000-0000-0000-0000-000000000001' and source is distinct from 'VERA8_IQB' and /*cas*/ (afb is null);\n`
    expect(await pruef('c_prefill_x.sql', fremd)).toMatch(/nicht in der Charge/)
    expect(await pruef('d_prefill_x.sql', migration().replace('"grund":"Nachgerechnet."', '"grund":"Antwort 9996"'))).toMatch(/Loesungsschutz/)
  })
})
