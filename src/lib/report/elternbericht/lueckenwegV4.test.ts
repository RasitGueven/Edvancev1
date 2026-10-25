// Bericht v4, Seite 3: Signale je Thema und Blöcke im Modus 'jeThemaVollstaendig'
// (Bauauftrag V4, V4-1, Entscheidung 2). Modus 'einmal' bleibt exakt v3.
import { describe, expect, it } from 'vitest'

import { gezaehlteBereiche } from '@/lib/report/elternbericht/bericht'
import { FAELLE } from '@/lib/report/elternbericht/fixtures'
import { bericht, berichtVon, gezaehlt, quelleVon } from '@/lib/report/elternbericht/fixtures/berichtV4Hilfe'
import v3 from '@/lib/report/elternbericht/fixtures/lueckenwegV3.json'
import { kommtNoch } from '@/lib/report/elternbericht/lernweg'
import { baueLueckenweg, signaleJeThema, type LueckenwegEingabe } from '@/lib/report/elternbericht/lueckenweg'
import type { EbBereich, EbLueckenweg, PlanEintrag } from '@/types'

const bereich = (skillKey: string, sicher: boolean, klasse = 8): EbBereich => ({
  skillKey,
  label: `Label ${skillKey}`,
  feld: 'zahlen',
  klasse,
  sicher,
})
const eintrag = (position: number, themaKey: string | null, titel: string): PlanEintrag => ({
  position,
  themaKey,
  titel,
  halbjahr: null,
})

// Thema T1 und T2 bauen beide auf „a“ auf (T1 über s1, T2 über s2); T2 allein auf „b“.
const GRAPH = {
  kanten: [
    { skillKey: 's1', voraussetzt: 'a' },
    { skillKey: 's2', voraussetzt: 'a' },
    { skillKey: 's2', voraussetzt: 'b' },
  ],
  heimatThemen: [
    { skillKey: 's1', themaKey: 't1' },
    { skillKey: 's2', themaKey: 't2' },
  ],
}

describe('signaleJeThema', () => {
  it('ein Bereich betrifft jedes Thema, das auf ihm aufbaut (erstes und „auch“)', () => {
    const je = signaleJeThema({ bereiche: [bereich('a', false), bereich('b', true)], ...GRAPH })
    expect(je.get('t1')!.fehlt.map((b) => b.skillKey)).toEqual(['a'])
    // „a“ ist für t1 das erste, für t2 nur „auch“ — und setzt dort trotzdem fehlt.
    expect(je.get('t2')!.fehlt.map((b) => b.skillKey)).toEqual(['a'])
    expect(je.get('t2')!.sitzt.map((b) => b.skillKey)).toEqual(['b'])
    expect(je.get('t1')!.sitzt).toEqual([])
  })

  it('Thema ohne betreffenden Bereich fehlt in der Map (Signal „ohne“)', () => {
    const je = signaleJeThema({ bereiche: [bereich('b', true)], ...GRAPH })
    expect(je.has('t1')).toBe(false)
    expect(je.has('t2')).toBe(true)
    expect(signaleJeThema({ bereiche: [], ...GRAPH }).size).toBe(0)
  })

  it('Reihenfolge je Liste: Klasse, dann Label', () => {
    const je = signaleJeThema({
      bereiche: [bereich('a', false, 9), { ...bereich('b', false, 7), label: 'Zzz' }, { ...bereich('c', false, 7), label: 'Aaa' }],
      kanten: ['a', 'b', 'c'].map((v) => ({ skillKey: 's1', voraussetzt: v })),
      heimatThemen: [{ skillKey: 's1', themaKey: 't1' }],
    })
    expect(je.get('t1')!.fehlt.map((b) => b.skillKey)).toEqual(['c', 'b', 'a'])
  })

  it('Vorgriffe zählen nicht: bericht.signale kennt nur gezählte Bereiche', () => {
    let mitVorgriff = 0
    for (const [name, { data }] of Object.entries(FAELLE)) {
      const b = berichtVon(data)
      if (!b) continue
      const { vorgriff } = gezaehlteBereiche(data.erzaehlung.kompetenzen, quelleVon(data))
      if (vorgriff.size > 0) mitVorgriff++
      const gezaehltKeys = new Set(gezaehlt(name).map((x) => x.skillKey))
      for (const s of b.signale) {
        for (const x of [...s.sitzt, ...s.fehlt]) expect(gezaehltKeys.has(x.skillKey), `${name} ${x.skillKey}`).toBe(true)
        for (const x of s.fehlt) expect(vorgriff.has(x.skillKey), `${name} ${x.skillKey}`).toBe(false)
      }
    }
    expect(mitVorgriff).toBeGreaterThan(0)
  })

  it('batuV4: Potenzen und Potenzgesetze hat keinen Eintrag, Pythagoras fehlt „Teilweise die Wurzel ziehen“', () => {
    const je = new Map(bericht('batuV4').signale.map((s) => [s.themaKey, s]))
    expect(je.get('pythagoras')!.fehlt.map((b) => b.label)).toEqual(['Teilweise die Wurzel ziehen'])
    const fahrplan = bericht('batuV4').fahrplan!
    const potenzen = fahrplan.stationen.find((s) => s.titel === 'Potenzen und Potenzgesetze')!
    expect(je.has(potenzen.themaKey)).toBe(false)
    expect(potenzen.signal).toBe('ohne')
  })
})

describe("baueLueckenweg, Modus 'jeThemaVollstaendig'", () => {
  const eingabe = (teil: Partial<LueckenwegEingabe> = {}): LueckenwegEingabe => ({
    bereiche: [bereich('a', false), bereich('b', true), bereich('x', false), bereich('y', true)],
    ...GRAPH,
    plan: null,
    kommt: [eintrag(2, 't1', 'Thema 1'), eintrag(3, 't2', 'Thema 2')],
    raum: new Set(),
    thema: null,
    ...teil,
  })

  it('ein Bereich steht in zwei Blöcken, ohne „auch“', () => {
    const lw = baueLueckenweg(eingabe(), { modus: 'jeThemaVollstaendig' })
    expect(lw.themen.map((t) => [t.titel, t.fehlt.map((z) => z.label)])).toEqual([
      ['Thema 1', ['Label a']],
      ['Thema 2', ['Label a']],
    ])
    expect(lw.themen[1].sitzt.map((z) => z.label)).toEqual(['Label b'])
    expect(lw.themen.flatMap((t) => [...t.sitzt, ...t.fehlt]).every((z) => z.auch.length === 0)).toBe(true)
  })

  it("derselbe Fall im Modus 'einmal': a nur im ersten Block, mit „auch“", () => {
    const lw = baueLueckenweg(eingabe())
    expect(lw.themen[0].fehlt).toEqual([{ label: 'Label a', auch: ['Thema 2'] }])
    expect(lw.themen[1].fehlt).toEqual([])
  })

  it('Restgruppen: nur Bereiche ohne jedes kommende Thema', () => {
    const lw = baueLueckenweg(eingabe(), { modus: 'jeThemaVollstaendig' })
    expect(lw.weitereStaerken).toEqual(['Label y'])
    expect(lw.weitere.flatMap((g) => g.labels)).toEqual(['Label x'])
  })

  it('Thema ohne betreffenden Bereich bekommt keinen Block', () => {
    const lw = baueLueckenweg(eingabe({ bereiche: [bereich('b', true)] }), { modus: 'jeThemaVollstaendig' })
    expect(lw.themen.map((t) => t.titel)).toEqual(['Thema 2'])
  })

  it('Eigenschaft über alle FAELLE: jeder gezählte Bereich steht in mindestens einem Block oder einer Restgruppe', () => {
    let geprueft = 0
    for (const [name, { data }] of Object.entries(FAELLE)) {
      const lw = berichtVon(data)?.lueckenwegV4
      if (!lw) continue
      const imWeg = new Set([
        ...lw.themen.flatMap((t) => [...t.sitzt, ...t.fehlt].map((z) => z.label)),
        ...lw.weitereStaerken,
        ...lw.weitere.flatMap((g) => g.labels),
      ])
      for (const b of gezaehlt(name)) {
        expect(imWeg.has(b.label), `${name}: ${b.label}`).toBe(true)
        geprueft++
      }
    }
    expect(geprueft).toBeGreaterThan(100)
  })

  it('Block ↔ Signal: genau die Stationen mit Signal ≠ „ohne“ haben einen Block, mit allen Bereichen', () => {
    for (const name of ['batuV4', 'fahrplanLang', 'fahrplanAuffuellen', 'allesErfuellt', 'fahrplanKlp']) {
      const b = bericht(name)
      const mitSignal = b.fahrplan!.stationen.filter((s) => s.nummer > 1 && s.signal !== 'ohne')
      expect(b.lueckenwegV4!.themen.map((t) => t.titel), name).toEqual(mitSignal.map((s) => s.titel))
      for (const s of mitSignal) {
        const block = b.lueckenwegV4!.themen.find((t) => t.titel === s.titel)!
        const sig = b.signale.find((x) => x.themaKey === s.themaKey)!
        expect(block.fehlt.map((z) => z.label), `${name} ${s.titel}`).toEqual(sig.fehlt.map((x) => x.label))
        expect(block.sitzt.map((z) => z.label), `${name} ${s.titel}`).toEqual(sig.sitzt.map((x) => x.label))
      }
    }
  })

  it('batuV4: Anhang-B-Bereiche stehen in ihren Blöcken (Fehlt/Sitzt „mindestens“)', () => {
    const lw = bericht('batuV4').lueckenwegV4!
    const fehlt = (titel: string) => lw.themen.find((t) => t.titel === titel)!.fehlt.map((z) => z.label)
    const sitzt = (titel: string) => lw.themen.find((t) => t.titel === titel)!.sitzt.map((z) => z.label)
    expect(fehlt('Quadratische Funktionen')).toEqual(
      expect.arrayContaining(['Binomische Formeln (Quadrat einer Summe/Differenz)', 'Faktorisieren mit binomischer Formel']),
    )
    expect(fehlt('Kreise, Prismen und Zylinder')).toEqual(
      expect.arrayContaining(['Flächeneinheiten', 'Fläche von Dreieck und Parallelogramm', 'Werte in Terme einsetzen']),
    )
    expect(fehlt('Der Satz des Pythagoras und Berechnungen in Körpern')).toEqual(['Teilweise die Wurzel ziehen'])
    expect(sitzt('Quadratische Funktionen')).toContain('Gleichungen aufstellen (Sachkontext)')
    expect(sitzt('Der Satz des Pythagoras und Berechnungen in Körpern')).toContain('Punkte im Koordinatensystem')
    // „Wird später wichtig“ (Anhang B, Ziel 4).
    expect(lw.weitere.flatMap((g) => g.labels)).toEqual(
      expect.arrayContaining(['Additionsverfahren', 'Flächeninhalt des Trapezes', 'Flächeninhalt von Drachen und Raute']),
    )
  })
})

describe("Modus 'einmal' ist exakt v3", () => {
  // lueckenwegV3.json: einmalig mit lueckenweg.ts aus f8695e34 (vor V4-1) für alle
  // FAELLE erzeugt, mit denselben Eingaben wie bericht.ts sie bildet.
  const snapshot = v3 as unknown as Record<string, EbLueckenweg | null>

  it('der Snapshot deckt alle Fälle ab', () => {
    expect(Object.keys(snapshot).sort()).toEqual(Object.keys(FAELLE).sort())
  })

  it('bericht.lueckenweg ist für jeden Fall identisch zu v3', () => {
    for (const [name, { data }] of Object.entries(FAELLE)) {
      const b = berichtVon(data)
      if (!b) continue
      expect(JSON.parse(JSON.stringify(b.lueckenweg)), name).toEqual(snapshot[name])
    }
  })

  it("Standard und ausdrücklich 'einmal' liefern dasselbe", () => {
    for (const [name, { data }] of Object.entries(FAELLE)) {
      const e = data.erzaehlung
      if (!berichtVon(data)) continue
      const eingabe: LueckenwegEingabe = {
        bereiche: gezaehlt(name),
        kanten: e.kanten,
        heimatThemen: e.heimatThemen,
        plan: e.plan,
        kommt: kommtNoch({ plan: e.plan, themaKey: e.raum?.themaKey ?? null, datum: data.analysedAt }),
        raum: new Set(),
        thema: null,
      }
      expect(baueLueckenweg(eingabe, { modus: 'einmal' }), name).toEqual(baueLueckenweg(eingabe))
    }
  })
})
