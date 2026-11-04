// V4-S (docs/report/v4/Bauauftrag-V4-S.md): Signal und Gruppen a/b der aktuellen Station bei 'bevorstehend'.
import { describe, expect, it } from 'vitest'

import { baueAnstehend, signalAnstehend } from '@/lib/report/elternbericht/anstehend'
import { idaMit } from '@/lib/report/elternbericht/fixtures/idaV4'
import { bericht, berichtVon, gezaehlt } from '@/lib/report/elternbericht/fixtures/berichtV4Hilfe'
import { gruppiereSchwerpunkte } from '@/lib/report/elternbericht/lernpfadV4'
import type { EbBereich, EbFahrplan, EbSchwerpunkt } from '@/types'

const labels = (l: readonly EbBereich[]): string[] => l.map((b) => b.label)

describe('V4-S: die anstehende Arbeit (Testkind Ida, Ähnlichkeit, bevorstehend)', () => {
  const b = bericht('idaBevorstehend')

  it('die aktuelle Station trägt das Signal (fehlt), die kommenden wie vorher', () => {
    const [erste, ...kommende] = b.fahrplan!.stationen
    expect(erste).toMatchObject({ nummer: 1, themaKey: 'aehnlichkeit', stand: 'steht', signal: 'fehlt' })
    expect(kommende.every((s) => s.signal !== null)).toBe(true)
  })

  it('a: der Stoff der Arbeit selbst — direkt geprüfte Bereiche mit Heimat-Thema Ähnlichkeit', () => {
    const a = b.anstehend!
    expect(labels(a.imThema.sitzt)).toEqual(['Streckfaktor und zentrische Streckung'])
    expect(labels(a.imThema.fehlt)).toEqual(['Erster Strahlensatz', 'Flächen und Volumen bei Ähnlichkeit', 'Zweiter Strahlensatz'])
  })

  it('b: was das Thema voraussetzt (Kante wie signaleJeThema), ohne die aus a', () => {
    const a = b.anstehend!
    expect(labels(a.voraus.sitzt)).toEqual(['Einschrittige Gleichungen'])
    expect(labels(a.voraus.fehlt)).toEqual(['Potenzen und Quadratzahlen'])
    // Maßstab ist nur abgeleitet, zählt also nicht.
    expect([...labels(a.voraus.sitzt), ...labels(a.voraus.fehlt)]).not.toContain('Maßstab')
  })

  it('a und b nur aus den gezählten Bereichen, kein Bereich doppelt', () => {
    const a = b.anstehend!
    const alle = [...a.imThema.sitzt, ...a.imThema.fehlt, ...a.voraus.sitzt, ...a.voraus.fehlt]
    const gezaehlte = new Set(gezaehlt('idaBevorstehend').map((x) => x.skillKey))
    expect(alle.every((x) => gezaehlte.has(x.skillKey))).toBe(true)
    expect(new Set(alle.map((x) => x.skillKey)).size).toBe(alle.length)
  })

  it('Lernpfad beginnt mit der anstehenden Arbeit und allen Lücken aus a und b', () => {
    const [erster] = b.lernpfad
    expect(erster.ziele[0]).toBe(1)
    const a = b.anstehend!
    for (const l of labels([...a.imThema.fehlt, ...a.voraus.fehlt])) expect(erster.teile).toContain(l)
  })
})

describe('V4-S: Signal-Regel', () => {
  const bereich = (skillKey: string, sicher: boolean): EbBereich => ({ skillKey, label: skillKey, feld: 'geometrie', klasse: 9, sicher })
  const heimat = [{ skillKey: 'x', themaKey: 't' }, { skillKey: 'y', themaKey: 't' }]
  const zu = (bereiche: EbBereich[], voraus: EbBereich[] = []) =>
    baueAnstehend({ themaKey: 't', titel: 'T', bereiche, heimatThemen: heimat, voraus: { sitzt: voraus.filter((v) => v.sicher), fehlt: voraus.filter((v) => !v.sicher) } })

  it('fehlt, sobald in a oder b etwas fehlt; erfuellt nur mit Sicherem; ohne ohne Bereich', () => {
    expect(signalAnstehend(zu([bereich('x', true)], [bereich('v', false)]))).toBe('fehlt')
    expect(signalAnstehend(zu([bereich('x', false)]))).toBe('fehlt')
    expect(signalAnstehend(zu([bereich('x', true)], [bereich('v', true)]))).toBe('erfuellt')
    expect(signalAnstehend(zu([bereich('z', true)]))).toBe('ohne')
  })

  it('ein Bereich in a und b zählt zu a', () => {
    const a = zu([bereich('x', true), bereich('y', false)], [bereich('x', true), bereich('v', false)])
    expect(labels(a.imThema.sitzt)).toEqual(['x'])
    expect(labels(a.voraus.fehlt)).toEqual(['v'])
    expect(a.voraus.sitzt).toEqual([])
  })
})

describe('V4-S: nur bei bevorstehend', () => {
  for (const status of ['geschrieben', null] as const) {
    it(`Ida mit ${status ?? 'unbekanntem Stand'}: kein Signal an Station 1, kein Feld anstehend`, () => {
      const b = berichtVon(idaMit(status, '462'))!
      expect(b.fahrplan!.stationen[0].signal).toBeNull()
      expect('anstehend' in b).toBe(false)
    })
  }

  it('Batu bevorstehend: Signal aus dem Thema selbst (b leer)', () => {
    const b = bericht('batuBevorstehend')
    expect(b.fahrplan!.stationen[0].signal).toBe('fehlt')
    expect(labels(b.anstehend!.imThema.fehlt)).toEqual(['Teilweise die Wurzel ziehen'])
    expect(b.anstehend!.voraus.sitzt.length + b.anstehend!.voraus.fehlt.length).toBe(0)
  })
})

describe('V4-S: Lernpfad, wenn eine Voraussetzung außerhalb des Themenraums fehlt', () => {
  const sp = (feld: EbSchwerpunkt['feld'], uebung: string[]): EbSchwerpunkt => ({
    feld, thema: feld ? null : 'Thema', gemischt: false, sicher: [], uebung, start: null, naechster: null,
  })
  const station = (nummer: number, themaKey: string, stand: 'steht' | 'danach', signal: 'fehlt' | null) => ({
    nummer, ka: null, themaKey, titel: themaKey.toUpperCase(), themen: [{ themaKey, titel: themaKey.toUpperCase() }],
    datum: null, halbjahr: null, schuljahr: 'dieses' as const, stand, signal, note: null,
  })
  const fahrplan: EbFahrplan = {
    stationen: [station(1, 'jetzt', 'steht', 'fehlt'), station(2, 'spaeter', 'danach', 'fehlt')],
    weitere: 0, halbjahrTrenner: false, klassenTrenner: null, quelle: 'schule', schulname: null, satz: 'fehlt', folge: 'unbekannt',
  }
  const signale = [{ themaKey: 'spaeter', sitzt: [], fehlt: [{ skillKey: 'g', label: 'G', feld: 'geometrie' as const, klasse: 7, sicher: false }] }]
  const anstehend = {
    themaKey: 'jetzt', titel: 'JETZT', imThema: { sitzt: [], fehlt: [] },
    voraus: { sitzt: [], fehlt: [{ skillKey: 'z', label: 'Z', feld: 'zahlen' as const, klasse: 7, sicher: false }] },
  }
  const schwerpunkte = [sp('geometrie', ['G']), sp('zahlen', ['Z'])]

  it('das Feld mit der fehlenden Voraussetzung rückt nach vorn und bereitet Station 1 vor', () => {
    const p = gruppiereSchwerpunkte({ schwerpunkte, gruende: [], danach: [], fahrplan, signale, anstehend })
    expect(p.map((x) => [x.titelFeld, x.ziele])).toEqual([['zahlen', [1]], ['geometrie', [2]]])
  })

  it('ohne anstehend bleibt die Reihenfolge der Schwerpunkte', () => {
    const p = gruppiereSchwerpunkte({ schwerpunkte, gruende: [], danach: [], fahrplan, signale })
    expect(p.map((x) => [x.titelFeld, x.ziele])).toEqual([['geometrie', [2]], ['zahlen', []]])
  })
})
