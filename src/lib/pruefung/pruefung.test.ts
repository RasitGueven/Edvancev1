import { describe, expect, it } from 'vitest'
import type { LenaStatus, PruefBoardZeile, PruefSicht } from '@/types'
import { ersteImThema, naechsteOffene, positionImThema, stand, stufenMitAufgaben, themenDerStufe } from './reihenfolge'
import { fehlerSchluessel, kurztitel, satzZumAntworttyp } from './texte'
import {
  bearbeitungAus,
  bereichVorschlag,
  feldZuruecksetzen,
  fehlerErgaenzen,
  fehlerUmschalten,
  geaenderteFelder,
  lokaleAenderungen,
  sperrgrund,
  zahlVon,
  zuEntwurf,
} from './entwurf'

function zeile(id: string, reihenfolge: number, status: LenaStatus = 'offen', over: Partial<PruefBoardZeile> = {}): PruefBoardZeile {
  return {
    task_id: id, stufe: 'erste', thema_key: 'a', thema_label: 'A', thema_sort: 10, skill_key: 's', skill_label: 'S',
    kurztitel: id, reihenfolge, lena_status: status, geaendert: false, letzte_dauer_sek: null, ...over,
  }
}

describe('Reihenfolge und naechste offene Aufgabe', () => {
  const board = [zeile('t1', 1, 'passt'), zeile('t2', 2), zeile('t3', 3), zeile('t4', 4, 'unsicher'), zeile('t5', 5)]

  it('nimmt die naechste offene nach der aktuellen', () => {
    expect(naechsteOffene(board, 't2')).toBe('t3')
    expect(naechsteOffene(board, 't3')).toBe('t5')
  })
  it('faengt nach dem Ende vorn wieder an', () => {
    expect(naechsteOffene(board, 't5')).toBe('t2')
  })
  it('ohne aktuelle Aufgabe: die erste offene', () => {
    expect(naechsteOffene(board, null)).toBe('t2')
  })
  it('stellt uebersprungene ans Ende', () => {
    expect(naechsteOffene(board, 't2', ['t3'])).toBe('t5')
    expect(naechsteOffene(board, 't5', ['t3'])).toBe('t2')
    expect(naechsteOffene(board, 't2', ['t3', 't5'])).toBe('t3')
  })
  it('meldet null, wenn nichts mehr offen ist', () => {
    expect(naechsteOffene([zeile('t1', 1, 'passt')], 't1')).toBeNull()
  })
  it('sortiert nach reihenfolge, nicht nach Eingang', () => {
    expect(naechsteOffene([zeile('b', 2), zeile('a', 1)], null)).toBe('a')
  })
  it('Pruefen je Thema: erste offene, sonst die erste', () => {
    expect(ersteImThema(board, 'a')).toBe('t2')
    expect(ersteImThema([zeile('x', 1, 'passt')], 'a')).toBe('x')
  })
  it('zaehlt den Stand; freigegeben zaehlt als bewertet', () => {
    const s = stand([...board, zeile('t6', 6, 'freigegeben'), zeile('t7', 7, 'passt', { geaendert: true })])
    expect(s).toMatchObject({ gesamt: 7, geprueft: 4, offen: 3, passt: 2, geaendert: 1, unsicher: 1, freigegeben: 1 })
  })
  it('Reiter nur fuer Stufen mit Aufgaben, 7/8 vor 9/10 vor 5/6', () => {
    expect(stufenMitAufgaben([zeile('a', 1, 'offen', { stufe: 'erprobung' }), zeile('b', 2)])).toEqual(['erste', 'erprobung'])
  })
  it('gruppiert Themen und kennt die Position im Thema', () => {
    const z = [zeile('a', 1), zeile('b', 2, 'passt', { thema_key: 'b', thema_label: 'B' }), zeile('c', 3, 'passt')]
    expect(themenDerStufe(z, 'erste').map((g) => g.thema_key)).toEqual(['a', 'b'])
    expect(positionImThema(z, 'c')).toEqual({ thema_key: 'a', thema_label: 'A', nr: 2, anzahl: 2, bewertet: 1 })
  })
})

describe('Kurztitel und Satz zum Antworttyp', () => {
  it('schneidet nur das fuehrende AFB-Praefix ab', () => {
    expect(kurztitel('AFB I · Fläche · Dreieck')).toBe('Fläche · Dreieck')
    expect(kurztitel('AFB III · Beweis')).toBe('Beweis')
    expect(kurztitel('Potenzen · AFB II · x')).toBe('Potenzen · AFB II · x')
    expect(kurztitel(null)).toBe('')
  })
  it('waehlt den Satz nach Typ, Teilen, Optionen und Einheit', () => {
    const basis = { unit: null, parts: [], optionen: [] }
    expect(satzZumAntworttyp({ ...basis, input_type: 'NUMERIC' })).toEqual({ key: 'antworttyp.zahl' })
    expect(satzZumAntworttyp({ ...basis, input_type: 'NUMERIC', unit: 'm' })).toEqual({ key: 'antworttyp.zahl_einheit', einheit: 'm' })
    expect(satzZumAntworttyp({ ...basis, input_type: 'MC', optionen: [{ id: 'a', label: 'x' }, { id: 'b', label: 'y' }] }))
      .toEqual({ key: 'antworttyp.mc', count: 2 })
    expect(satzZumAntworttyp({ ...basis, input_type: 'MULTI_PART', parts: [{ nr: 1, kind: 'mc', prompt: 'a', unit: null, options: [] }] }))
      .toEqual({ key: 'antworttyp.teile', count: 1 })
    expect(satzZumAntworttyp({ ...basis, input_type: 'TERM' })).toEqual({ key: 'antworttyp.term' })
  })
})

describe('Uebersetzung von ED409 und ED422', () => {
  it('ED409 heisst: inzwischen geaendert', () => {
    expect(fehlerSchluessel({ code: 'ED409', hint: 'version', message: 'x' })).toBe('fehler.version')
  })
  it('ED422 uebersetzt den HINT, Unbekanntes faellt auf eingabe', () => {
    expect(fehlerSchluessel({ code: 'ED422', hint: 'notiz_fehlt', message: 'x' })).toBe('fehler.notiz_fehlt')
    expect(fehlerSchluessel({ code: 'ED422', hint: 'fertigkeit_unzulaessig', message: 'x' })).toBe('fehler.fertigkeit_unzulaessig')
    expect(fehlerSchluessel({ code: 'ED422', hint: 'gibt_es_nicht', message: 'x' })).toBe('fehler.eingabe')
  })
  it('Rechte und Sonstiges', () => {
    expect(fehlerSchluessel({ code: '42501', hint: null, message: 'x' })).toBe('fehler.kein_recht')
    expect(fehlerSchluessel({ code: null, hint: null, message: 'Netz' })).toBe('fehler.allgemein')
    expect(fehlerSchluessel(null)).toBeNull()
  })
})

const sicht: PruefSicht = {
  werte: [{ teil: null, werte: [{ wert: '−24', schreibweisen: ['−24', '-24'] }] }],
  mc: null,
  regel: { art: 'wert', mitte: null, toleranz: null, einheit_pflicht: false, einheit: 'm', einheit_am_feld: false },
  fehler: [{ slug: 'vorzeichen_ignoriert', werte: [{ teil: null, wert: '24' }], text: 'Minus vergessen.' }],
  weitere_hinweise: [],
  skill_key: 'geo_kreis_umfang',
  afb: 'II',
  flach_regel: true,
  ohne_erkennung: false,
}

describe('Entwurf ↔ Aenderungen', () => {
  const aus = bearbeitungAus(sicht)

  it('ohne Aenderung: nichts geaendert, Entwurf wie die Sicht', () => {
    expect(geaenderteFelder(aus, aus).size).toBe(0)
    expect(lokaleAenderungen(aus, aus)).toEqual([])
    expect(zuEntwurf(aus).werte).toEqual([{ teil: null, werte: ['−24'] }])
  })
  it('−24 → 24 ist eine Aenderung der richtigen Antwort', () => {
    const jetzt = { ...aus, werte: [{ teil: null, werte: ['24'] }] }
    expect([...geaenderteFelder(aus, jetzt)]).toEqual(['antwort'])
    expect(lokaleAenderungen(aus, jetzt)).toEqual([{ feld: 'richtige_antwort', teil: null, vorher: ['−24'], nachher: ['24'] }])
  })
  it('↺ setzt das Feld zurueck, die Aenderung verschwindet', () => {
    const jetzt = { ...aus, werte: [{ teil: null, werte: ['24'] }], afb: 'III' as const }
    const zurueck = feldZuruecksetzen(jetzt, aus, 'antwort')
    expect([...geaenderteFelder(aus, zurueck)]).toEqual(['afb'])
  })
  it('Bereich ersetzt die Liste durch die Mitte und ist eine Aenderung der Wertung', () => {
    const jetzt = { ...aus, regel: { art: 'bereich' as const, mitte: '70', toleranz: '5', einheit_pflicht: false } }
    expect(zuEntwurf(jetzt).werte).toEqual([{ teil: null, werte: ['70'] }])
    expect(geaenderteFelder(aus, jetzt).has('regel')).toBe(true)
    expect(lokaleAenderungen(aus, jetzt).map((a) => a.feld)).toContain('wertung')
  })
  it('typische Fehler: entfernen, wieder rein, ergaenzen', () => {
    const raus = fehlerUmschalten(aus, 0)
    expect(zuEntwurf(raus).fehler).toEqual([])
    expect(lokaleAenderungen(aus, raus)[0]).toMatchObject({ feld: 'typischer_fehler', nachher: null })
    expect(geaenderteFelder(aus, fehlerUmschalten(raus, 0)).size).toBe(0)
    const plus = fehlerErgaenzen(aus, { slug: 'pi_vergessen', teil: null, wert: '7,2', text: '' })
    expect(plus.fehler[1]).toMatchObject({ slug: 'pi_vergessen', neu: true, text: null })
    expect(fehlerUmschalten(plus, 1).fehler).toHaveLength(1)
    const dazu = fehlerErgaenzen(aus, { slug: 'vorzeichen_ignoriert', teil: null, wert: '+24', text: null })
    expect(zuEntwurf(dazu).fehler[0].werte).toHaveLength(2)
  })
  it('Passt gesperrt: keine Antwort, leerer Teil, ungueltiger Bereich', () => {
    expect(sperrgrund('NUMERIC', aus)).toBeNull()
    expect(sperrgrund('NUMERIC', { ...aus, werte: [{ teil: null, werte: [' '] }] })).toBe('antwort_fehlt')
    expect(sperrgrund('MULTI_PART', { ...aus, werte: [{ teil: 1, werte: ['3'] }, { teil: 2, werte: [] }] })).toBe('teil_fehlt')
    expect(sperrgrund('NUMERIC', { ...aus, regel: { art: 'bereich', mitte: '70', toleranz: '0', einheit_pflicht: false } }))
      .toBe('bereich_ungueltig')
    expect(sperrgrund('MC', { ...aus, mc: null })).toBe('antwort_fehlt')
  })
  it('liest Zahlen wie Lena sie tippt und schlaegt einen Bereich vor', () => {
    expect(zahlVon('−3,5')).toBe(-3.5)
    expect(zahlVon('+ 2')).toBe(2)
    expect(zahlVon('3/4')).toBe(0.75)
    expect(zahlVon('22,62 m')).toBe(22.62)
    expect(zahlVon('x')).toBeNull()
    expect(bereichVorschlag('70')).toEqual({ mitte: '70', toleranz: '3,5' })
    expect(bereichVorschlag('2')).toEqual({ mitte: '2', toleranz: '0,5' })
  })
})
