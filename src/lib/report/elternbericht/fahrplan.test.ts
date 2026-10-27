// Bericht v4: der Fahrplan der Klassenarbeiten (Bauauftrag V4, V4-1, Entscheidungen 1–3).
import { describe, expect, it } from 'vitest'

import { KOMMENDE_MAX, baueFahrplan } from '@/lib/report/elternbericht/fahrplan'
import { bericht } from '@/lib/report/elternbericht/fixtures/berichtV4Hilfe'
import { FAELLE } from '@/lib/report/elternbericht/fixtures'
import type { EbFahrplan } from '@/types'

/** FWG-Plan Klasse 9 von batuV4 ohne jedes Signal (alle Themen „ohne“). */
const LEER = {
  plan: FAELLE.batuV4.data.erzaehlung.plan,
  themaKey: FAELLE.batuV4.data.erzaehlung.raum?.themaKey ?? null,
  datum: FAELLE.batuV4.data.analysedAt,
  klassenarbeitStatus: 'geschrieben' as const,
  signale: new Map(),
}

const fp = (name: string): EbFahrplan => {
  const f = bericht(name).fahrplan
  if (!f) throw new Error(`kein Fahrplan für ${name}`)
  return f
}
const kommende = (f: EbFahrplan) => f.stationen.filter((s) => s.nummer > 1)

describe('Station 1 nach Stand der Klassenarbeit', () => {
  it('geschrieben', () => {
    const s = fp('batuV4').stationen[0]
    expect(s).toMatchObject({ nummer: 1, stand: 'geschrieben', signal: null, schuljahr: 'dieses' })
  })

  it('bevorstehend (Folge unbekannt, L5): Station 1 steht an, dann „als Nächstes im Unterricht“ und „danach“', () => {
    const f = fp('batuBevorstehend')
    expect(f.stationen[0].stand).toBe('steht')
    expect(kommende(f).map((s) => s.stand)).toEqual(['unterricht', 'danach', 'danach', 'danach'])
  })

  it('ohne Angabe: aktuell', () => {
    expect(fp('batuOhneStatus').stationen[0].stand).toBe('aktuell')
  })

  it('Folge unbekannt (L5): keine „nächste Arbeit“, keine Nummer einer Klassenarbeit', () => {
    for (const name of ['batuV4', 'batuOhneStatus', 'batuBevorstehend', 'batuMitNote']) {
      const f = fp(name)
      expect(f.folge, name).toBe('unbekannt')
      expect(f.stationen.filter((s) => s.stand === 'naechste' || s.stand === 'voraussichtlich'), name).toEqual([])
      expect(f.stationen.every((s) => s.ka === null), name).toBe(true)
    }
  })
})

describe('Stationen von batuV4', () => {
  // Abweichung von Anhang B (bewusst, datengetrieben): Station 1 heißt im FWG-Plan
  // (schul_themenplan.uv_titel) „Reelle Zahlen“, und „Potenzen und Potenzgesetze“
  // (Signal ohne) ist Station 4; deshalb ist Pythagoras Station 5, nicht 4.
  it('Titel, Nummern, Signale in Plan-Reihenfolge', () => {
    expect(fp('batuV4').stationen.map((s) => [s.nummer, s.titel, s.signal])).toEqual([
      [1, 'Reelle Zahlen', null],
      [2, 'Quadratische Funktionen', 'fehlt'],
      [3, 'Kreise, Prismen und Zylinder', 'fehlt'],
      [4, 'Potenzen und Potenzgesetze', 'ohne'],
      [5, 'Der Satz des Pythagoras und Berechnungen in Körpern', 'fehlt'],
    ])
  })

  it('Quelle Schule, ein weiteres Thema, kein Trenner, Satz „fehlt“', () => {
    expect(fp('batuV4')).toMatchObject({
      quelle: 'schule',
      schulname: 'Friedrich-Wilhelm-Gymnasium',
      weitere: 1,
      halbjahrTrenner: false,
      klassenTrenner: null,
      satz: 'fehlt',
    })
  })

  it('Station 1 hat nie ein Signal, alle kommenden eines', () => {
    for (const name of ['batuV4', 'fahrplanKlp', 'fahrplanLang', 'fahrplanAuffuellen']) {
      const f = fp(name)
      expect(f.stationen[0].signal, name).toBeNull()
      expect(kommende(f).every((s) => s.signal !== null), name).toBe(true)
    }
  })
})

describe('Note', () => {
  it('batuMitNote: 4 an Station 1; batuV4: null', () => {
    expect(fp('batuMitNote').stationen[0].note).toBe(4)
    expect(fp('batuV4').stationen[0].note).toBeNull()
  })

  it('die Note steht nur bei „geschrieben“ und nie an kommenden Stationen', () => {
    const eingabe = { ...LEER, note: 4 }
    expect(baueFahrplan({ ...eingabe, klassenarbeitStatus: 'bevorstehend' })!.stationen[0].note).toBeNull()
    expect(baueFahrplan({ ...eingabe, klassenarbeitStatus: null })!.stationen[0].note).toBeNull()
    expect(baueFahrplan({ ...eingabe, klassenarbeitStatus: 'geschrieben' })!.stationen[0].note).toBe(4)
    expect(kommende(fp('batuMitNote')).every((s) => s.note === null)).toBe(true)
  })
})

describe('Halbjahre und Trenner', () => {
  it('fahrplanHalbjahr: Halbjahre 1 und 2 → Trenner', () => {
    const f = fp('fahrplanHalbjahr')
    expect(f.halbjahrTrenner).toBe(true)
    expect(f.stationen.map((s) => s.halbjahr)).toEqual([1, 1, 1, 2, 2])
  })

  it('ohne gesetzte Halbjahre kein Trenner', () => {
    expect(fp('batuV4').halbjahrTrenner).toBe(false)
  })
})

describe('Länge und Auffüllen', () => {
  it('fahrplanLang: vier kommende, weitere = n − 4', () => {
    const f = fp('fahrplanLang')
    expect(kommende(f)).toHaveLength(KOMMENDE_MAX)
    // FWG-Plan Klasse 9 (1 aktuell + 4 im Plan + 1 weiteres) um drei Themen verlängert: 8 kommende.
    expect(f.weitere).toBe(8 - KOMMENDE_MAX)
    expect(f.weitere).toBe(fp('batuV4').weitere + 3)
  })

  it('fahrplanKlp: Kernlehrplan als Quelle ohne Schulname', () => {
    expect(fp('fahrplanKlp')).toMatchObject({ quelle: 'klp', schulname: null })
    expect(fp('fahrplanKlp').weitere).toBeGreaterThan(0)
  })

  it('fahrplanAuffuellen: vier Stationen, Klassen-Trenner 8, schuljahr „naechstes“ ab Station 4', () => {
    const f = fp('fahrplanAuffuellen')
    expect(f.klassenTrenner).toBe(8)
    expect(f.weitere).toBe(0)
    expect(f.stationen.map((s) => s.schuljahr)).toEqual(['dieses', 'dieses', 'dieses', 'naechstes', 'naechstes'])
    expect(f.stationen.map((s) => s.halbjahr).slice(3)).toEqual([null, null])
    // Auch für Themen des nächsten Schuljahrs gibt es ein Signal.
    expect(f.stationen[3].signal).not.toBeNull()
    expect(fp('batuV4').klassenTrenner).toBeNull()
  })

  it('jedes Thema steht nur einmal im Fahrplan', () => {
    for (const name of ['batuV4', 'fahrplanLang', 'fahrplanAuffuellen', 'fahrplanKlp']) {
      const keys = fp(name).stationen.map((s) => s.themaKey)
      expect(new Set(keys).size, name).toBe(keys.length)
    }
  })
})

describe('ohne Plan', () => {
  it('ohnePlan: Fahrplan null, Signale trotzdem gerechnet, kein Lernpfad-Ziel', () => {
    const b = bericht('ohnePlan')
    expect(b.fahrplan).toBeNull()
    expect(b.lueckenwegV4).toBeNull()
    expect(b.lernpfad.every((p) => p.ziele.length === 0)).toBe(true)
  })

  it('baueFahrplan ohne Plan → null', () => {
    expect(baueFahrplan({ ...LEER, plan: null })).toBeNull()
  })
})

describe('Satz unter dem Fahrplan (Entscheidung 3)', () => {
  it('fehlt, sobald eine kommende Station fehlt', () => {
    expect(fp('batuV4').satz).toBe('fehlt')
    expect(fp('fahrplanHalbjahr').satz).toBe('fehlt')
  })

  it('erfuellt, wenn kommende Stationen nur sichere Bereiche haben (allesErfuellt)', () => {
    const f = fp('allesErfuellt')
    expect(kommende(f).map((s) => s.signal)).toEqual(['erfuellt', 'erfuellt', 'ohne', 'erfuellt'])
    expect(f.satz).toBe('erfuellt')
  })

  it('null, wenn alle kommenden Stationen „ohne“ sind (nur eine Station mit Signal ohne)', () => {
    const f = baueFahrplan(LEER)!
    expect(kommende(f).every((s) => s.signal === 'ohne')).toBe(true)
    expect(f.satz).toBeNull()
  })
})
