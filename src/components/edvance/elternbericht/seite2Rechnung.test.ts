import { describe, expect, it } from 'vitest'

import {
  KAESTCHEN_MAX,
  MIN_GEPRUEFT_DEUTUNG,
  SPUR,
  SPUR_MIT_ABGELEITETEN,
  deutung,
  kaestchen,
  linienLage,
  luecke,
  massstab,
  massstabFuer,
  meisterUebung,
  profilZeilen,
  segmente,
  teile,
  zeilenAbstand,
  type ProfilZeile,
} from '@/components/edvance/elternbericht/seite2Rechnung'
import { baueElternbericht } from '@/lib/report/elternbericht/bericht'
import { FAELLE } from '@/lib/report/elternbericht/fixtures'
import { themaAbdeckungAus, type AbgeleiteterBereich } from '@/lib/report/elternbericht/themaAbdeckung'
import type { EbBereich, EbProfilZeile, Elternbericht } from '@/types'

const bericht = (fall: keyof typeof FAELLE): Elternbericht => {
  const { data } = FAELLE[fall]
  const b = baueElternbericht({
    kompetenzen: data.erzaehlung.kompetenzen,
    katalog: data.erzaehlung.katalog,
    klasse: data.grade,
  })
  if (!b) throw new Error(fall)
  return b
}

/** Die Zeilen von Seite 2 wie in Seite2.tsx. */
const zeilenVon = (fall: keyof typeof FAELLE): ProfilZeile[] => {
  const b = bericht(fall)
  const e = FAELLE[fall].data.erzaehlung
  return profilZeilen({
    profil: b.profil,
    bereiche: [...b.sicherListe, ...b.uebungListe],
    abgeleitet: themaAbdeckungAus(e)?.abgeleiteteBereiche ?? [],
  })
}

const zeile = (vorhanden: number, sicher = 0, uebung = 0): EbProfilZeile => ({
  feld: 'brueche',
  vorhanden,
  sicher,
  uebung,
})

const bereich = (skillKey: string, feld: EbBereich['feld'], klasse: number): EbBereich => ({
  skillKey,
  label: skillKey,
  feld,
  klasse,
  sicher: true,
})

describe('massstab — ein Maßstab für alle Zeilen (R7-8)', () => {
  it('Lücke 4 pt bis 16 Kästchen, 2 pt bis 30, darüber 1 pt', () => {
    expect([1, 16, 17, 30, 31, 40].map(luecke)).toEqual([4, 4, 2, 2, 1, 1])
  })

  it('Spur fest 195 pt, auch mit abgeleiteten (Bericht v3)', () => {
    expect(SPUR).toBe(195)
    expect(SPUR_MIT_ABGELEITETEN).toBe(SPUR)
  })

  it('Breite min(28, (195 − (n_max − 1) · Lücke) / n_max) für n_max = 1, 4, 6, 17, 31, 40', () => {
    expect(massstab(1).breite).toBe(28)
    expect(massstab(4).breite).toBe(28)
    expect(massstab(6).breite).toBe(28) // (195 − 20) / 6 = 29,17 → Deckel
    expect(massstab(7).breite).toBeCloseTo((195 - 6 * 4) / 7) // 24,43
    expect(massstab(17).breite).toBeCloseTo((195 - 16 * 2) / 17) // 9,59
    expect(massstab(31).breite).toBeCloseTo((195 - 30) / 31) // 5,32
    expect(massstab(40).breite).toBeCloseTo((195 - 39) / 40) // 3,9
    for (const n of [1, 4, 7, 17, 31, 40]) {
      const m = massstab(n)
      expect(m.radius, String(n)).toBeCloseTo(Math.min(3.5, m.breite / 3))
      // Die längste Zeile bleibt in der Spur.
      expect(n * m.breite + (n - 1) * m.luecke, String(n)).toBeLessThanOrEqual(SPUR + 1e-9)
    }
  })

  it('alle Zeilen eines Profils haben dieselbe Kästchenbreite und Lücke', () => {
    const zeilen: ProfilZeile[] = [1, 4, 7, 17, 31, 40].map((n, i) => ({
      feld: (['brueche', 'prozent', 'terme', 'geometrie', 'groessen', 'zahlen'] as const)[i],
      sicher: n,
      uebung: 0,
      abgeleitet: 0,
      klasse: null,
    }))
    const m = massstabFuer(zeilen)
    expect(m).toEqual(massstab(40, SPUR))
    const alle = zeilen.flatMap((z) => segmente(z, m))
    expect(new Set(alle.map((s) => s.breite)).size).toBe(1)
    for (const z of zeilen) {
      const s = segmente(z, m)
      if (s.length > 1) expect(s[1].x - s[0].x - s[0].breite).toBeCloseTo(1)
    }
  })

  it('massstabFuer nimmt immer SPUR: ohne Umrisse, mit Umrissen, bei zehn und mehr Kästchen', () => {
    const z = (sicher: number, uebung: number, abgeleitet = 0): ProfilZeile => ({
      feld: 'zahlen',
      sicher,
      uebung,
      abgeleitet,
      klasse: null,
    })
    expect(massstabFuer([z(5, 4)])).toEqual(massstab(9, SPUR))
    expect(massstabFuer([z(6, 4)])).toEqual(massstab(10, SPUR))
    expect(massstabFuer([z(9, 9)])).toEqual(massstab(18, SPUR))
    expect(massstabFuer([z(4, 5, 0), { ...z(0, 0, 2), feld: 'brueche' }])).toEqual(massstab(9, SPUR))
    // Längster Fall: 12 geprüft + 14 abgeleitet in einer Zeile.
    const lang = massstabFuer(zeilenVon('abgestuftLang'))
    expect(lang).toEqual(massstab(26, SPUR))
    expect(26 * lang.breite + 25 * lang.luecke).toBeCloseTo(SPUR)
  })

  it('wenige Bereiche: höchstens 28 pt breit', () => {
    expect(massstabFuer(zeilenVon('ilkay')).breite).toBe(KAESTCHEN_MAX)
  })
})

describe('segmente', () => {
  it('reiht erst sicher, dann Übungsbedarf, dahinter die Umrisse', () => {
    const m = massstab(6)
    expect(segmente({ sicher: 2, uebung: 1, abgeleitet: 2 }, m).map((s) => s.art)).toEqual([
      'sicher',
      'sicher',
      'uebung',
      'abgeleitet',
      'abgeleitet',
    ])
    expect(segmente({ sicher: 0, uebung: 0, abgeleitet: 0 }, m)).toEqual([])
  })
})

describe('profilZeilen', () => {
  it('ilkay: nur Felder mit geprüften Bereichen, keine Umrisse', () => {
    const z = zeilenVon('ilkay')
    // Bericht v3: nach Klassenband aufsteigend (von, dann bis), Gleichstand in Feldfolge.
    expect(z.map((x) => [x.feld, kaestchen(x)])).toEqual([
      ['groessen', 5],
      ['geometrie', 6],
      ['zahlen', 3],
      ['brueche', 5],
      ['prozent', 4],
      ['terme', 4],
    ])
    expect(z.every((x) => x.abgeleitet === 0)).toBe(true)
  })

  it('sortiert nach Klassenband aufsteigend: von, dann bis; ohne Klasse ans Ende; Gleichstand nach Feldfolge', () => {
    const profil: EbProfilZeile[] = [
      { feld: 'brueche', vorhanden: 1, sicher: 1, uebung: 0 },
      { feld: 'prozent', vorhanden: 1, sicher: 1, uebung: 0 },
      { feld: 'terme', vorhanden: 1, sicher: 1, uebung: 0 },
      { feld: 'geometrie', vorhanden: 1, sicher: 1, uebung: 0 },
      { feld: 'zahlen', vorhanden: 0, sicher: 0, uebung: 0 },
    ]
    const z = profilZeilen({
      profil,
      bereiche: [
        bereich('b', 'brueche', 8),
        bereich('p', 'prozent', 5),
        bereich('t', 'terme', 5),
        bereich('g1', 'geometrie', 5),
        bereich('g2', 'geometrie', 9),
      ],
      abgeleitet: [{ feld: 'zahlen', klasse: null }],
    })
    // prozent (5–5) und terme (5–5) in Feldfolge, dann geometrie (5–9), dann brueche (8–8), zahlen ohne Klasse zuletzt.
    expect(z.map((x) => x.feld)).toEqual(['prozent', 'terme', 'geometrie', 'brueche', 'zahlen'])
  })

  it('direkt geprüft wie im Profil (zaehle unverändert), auch weitereBereiche', () => {
    for (const fall of ['ilkay', 'allesSicher', 'weitereBereiche', 'abgestuft'] as const) {
      const direkt = bericht(fall).profil.filter((x) => x.sicher + x.uebung > 0)
      const z = zeilenVon(fall).filter((x) => x.sicher + x.uebung > 0)
      // Gleiche Zeilen wie im Profil; die Reihenfolge ordnet Seite 2 nach Klassenband.
      const je = (x: { feld: string; sicher: number; uebung: number }) => `${x.feld}:${x.sicher}/${x.uebung}`
      expect(z.map(je).sort(), fall).toEqual(direkt.map(je).sort())
    }
    expect(zeilenVon('weitereBereiche').map((x) => x.feld)).toContain('weitere')
  })

  it('Umrisse nur bei den abgestuften Fällen; Summe = themaAbdeckung.abgeleitet', () => {
    for (const fall of Object.keys(FAELLE).filter((f) => f !== 'ohneKatalog') as (keyof typeof FAELLE)[]) {
      const summe = zeilenVon(fall).reduce((n, x) => n + x.abgeleitet, 0)
      // ohneKanten und langeLabels sind aus abgestuft abgeleitet (R7-9), mit demselben Thema-Satz.
      const erwartet = { abgestuft: 9, abgestuftMitOffen: 5, abgestuftLang: 14, ohneKanten: 9, langeLabels: 9 }[fall as string] ?? 0
      expect(summe, fall).toBe(erwartet)
      expect(summe, fall).toBe(themaAbdeckungAus(FAELLE[fall].data.erzaehlung)?.abgeleitet ?? 0)
    }
  })

  it('ein Feld nur mit abgeleiteten Bereichen bekommt eine Zeile', () => {
    const z = profilZeilen({
      profil: [{ feld: 'brueche', vorhanden: 3, sicher: 1, uebung: 0 }],
      bereiche: [bereich('bruch_a', 'brueche', 6)],
      abgeleitet: [{ feld: 'zahlen', klasse: 9 }],
    })
    const nur = z.find((x) => x.sicher + x.uebung === 0)!
    expect(nur).toMatchObject({ abgeleitet: 1, klasse: { von: 9, bis: 9 } })
  })

  it('Klassenspanne: eine Stufe, Spanne, abgeleiteter ohne Katalog-Klasse zählt nicht', () => {
    const profil: EbProfilZeile[] = [{ feld: 'brueche', vorhanden: 5, sicher: 2, uebung: 0 }]
    const zwei = [bereich('bruch_a', 'brueche', 6), bereich('bruch_b', 'brueche', 6)]
    const ohne = (abgeleitet: AbgeleiteterBereich[]) =>
      profilZeilen({ profil, bereiche: zwei, abgeleitet })[0]
    expect(ohne([]).klasse).toEqual({ von: 6, bis: 6 })
    expect(ohne([{ feld: 'brueche', klasse: 8 }]).klasse).toEqual({ von: 6, bis: 8 })
    const fehlt = ohne([{ feld: 'brueche', klasse: null }])
    expect(fehlt.abgeleitet).toBe(1)
    expect(fehlt.klasse).toEqual({ von: 6, bis: 6 })
  })
})

describe('zeilenAbstand und teile', () => {
  it('40,8 pt bis sechs Zeilen, ab sieben 33,4 pt', () => {
    expect(zeilenAbstand(6)).toBe(40.8)
    expect(zeilenAbstand(7)).toBe(33.4)
    expect(zeilenAbstand(8)).toBe(33.4)
    expect(zeilenAbstand(9)).toBe(30)
  })

  it('Trennlinie zwischen Unterzeile (Grundlinie 20) und nächster Spur', () => {
    for (const n of [6, 7, 9]) {
      const a = zeilenAbstand(n)
      expect(linienLage(a)).toBeGreaterThan(22)
      expect(linienLage(a)).toBeLessThan(a - 3)
    }
  })

  it('nennt nur die von null verschiedenen Teile', () => {
    expect(teile(zeile(5, 2, 0))).toEqual([{ art: 'sicher', anzahl: 2 }])
    expect(teile(zeile(5, 0, 3))).toEqual([{ art: 'uebung', anzahl: 3 }])
    expect(teile(zeile(5, 2, 3))).toEqual([
      { art: 'sicher', anzahl: 2 },
      { art: 'uebung', anzahl: 3 },
    ])
    expect(teile(zeile(5))).toEqual([])
  })
})

describe('deutung', () => {
  it('ilkay: je höchstens zwei Felder, keins in beiden Sätzen', () => {
    // Profil ilkay: brueche 2/3, prozent 1/3, terme 2/2, geometrie 1/5, groessen 3/2, zahlen 2/1
    const d = deutung(bericht('ilkay').profil)
    expect(d.sicher).toEqual(['groessen', 'zahlen'])
    expect(d.uebung).toEqual(['geometrie', 'brueche'])
  })

  it('allesSicher: nur der Sicher-Satz', () => {
    const d = deutung(bericht('allesSicher').profil)
    expect(d.sicher.length).toBeGreaterThan(0)
    expect(d.uebung).toEqual([])
  })

  it('nichtsSicher: nur der Übungs-Satz', () => {
    const d = deutung(bericht('nichtsSicher').profil)
    expect(d.sicher).toEqual([])
    expect(d.uebung.length).toBeGreaterThan(0)
  })

  it('kein Feld steht in beiden Sätzen, Gleichstand nach Reihenfolge der Felder', () => {
    for (const fall of Object.keys(FAELLE).filter((f) => f !== 'ohneKatalog')) {
      const d = deutung(bericht(fall as keyof typeof FAELLE).profil)
      expect(d.sicher.filter((f) => d.uebung.includes(f)), fall).toEqual([])
    }
    const d = deutung([
      { feld: 'terme', sicher: 0, uebung: 2 },
      { feld: 'brueche', sicher: 0, uebung: 2 },
      { feld: 'zahlen', sicher: 0, uebung: 3 },
    ])
    expect(d.uebung).toEqual(['zahlen', 'terme'])
  })
})

describe('deutung — erst ab zwei geprüften Bereichen (R7-10)', () => {
  it('Schwelle ist 2', () => {
    expect(MIN_GEPRUEFT_DEUTUNG).toBe(2)
  })

  it('Sicher-Satz: 1 geprüft (sicher) nicht genannt, mit 2 genannt', () => {
    expect(deutung([{ feld: 'brueche', sicher: 1, uebung: 0 }]).sicher).toEqual([])
    expect(deutung([{ feld: 'brueche', sicher: 2, uebung: 0 }]).sicher).toEqual(['brueche'])
  })

  it('1 sicher + 1 Übungsbedarf: genannt nach Mehrheit, also im Übungssatz', () => {
    expect(deutung([{ feld: 'terme', sicher: 1, uebung: 1 }])).toEqual({ sicher: [], uebung: ['terme'] })
  })

  it('Schwelle auch im Übungssatz: 1 Übungsbedarf nicht genannt, 2 genannt', () => {
    expect(deutung([{ feld: 'geometrie', sicher: 0, uebung: 1 }]).uebung).toEqual([])
    expect(deutung([{ feld: 'geometrie', sicher: 0, uebung: 2 }]).uebung).toEqual(['geometrie'])
  })

  it('abgeleitete zählen nicht: 1 sicher + 4 abgeleitet bleibt ungenannt', () => {
    const z: ProfilZeile = { feld: 'brueche', sicher: 1, uebung: 0, abgeleitet: 4, klasse: null }
    expect(deutung([z])).toEqual({ sicher: [], uebung: [] })
  })

  it('abgestuft (Batu): sicher nur Terme & Gleichungen, Übung Geometrie und Zahlen & Rechnen', () => {
    // brueche 1/0 (+4 abgeleitet), terme 2/1, geometrie 0/3, zahlen 1/3 (+5), zufall 0/1
    // Gleichstand (je drei Übungsbedarf) folgt der Zeilenfolge, und die ist seit v3 nach Klassenband.
    expect(deutung(zeilenVon('abgestuft'))).toEqual({ sicher: ['terme'], uebung: ['zahlen', 'geometrie'] })
  })

  it('ilkay: unverändert, jedes Feld hat mindestens 3 geprüfte Bereiche', () => {
    const p = bericht('ilkay').profil
    expect(p.filter((z) => z.sicher + z.uebung > 0).every((z) => z.sicher + z.uebung >= 3)).toBe(true)
    expect(deutung(zeilenVon('ilkay'))).toEqual({ sicher: ['groessen', 'zahlen'], uebung: ['geometrie', 'brueche'] })
  })
})

describe('meisterUebung — Anteil statt Anzahl (Bericht v2)', () => {
  const z = (feld: EbProfilZeile['feld'], sicher: number, uebung: number) => ({ feld, sicher, uebung })

  it('ohne Übungsbedarf oder ohne Profil: null', () => {
    expect(meisterUebung([])).toBeNull()
    expect(meisterUebung([z('brueche', 4, 0)])).toBeNull()
  })

  it('Felder mit weniger als zwei geprüften Bereichen zählen nicht', () => {
    expect(meisterUebung([z('brueche', 0, 1)])).toBeNull()
  })

  it('der höchste Anteil gewinnt, nicht die höchste Anzahl', () => {
    // 3 von 10 (30 %) hat mehr Bereiche als 2 von 2 (100 %), verliert aber.
    expect(meisterUebung([z('brueche', 7, 3), z('geometrie', 0, 2)])).toEqual({
      felder: ['geometrie'],
      uebung: 2,
      geprueft: 2,
    })
  })

  it('gleicher Anteil: mehr Übungsbedarf zuerst', () => {
    expect(meisterUebung([z('brueche', 1, 1), z('geometrie', 3, 3)])).toMatchObject({ felder: ['geometrie'], uebung: 3, geprueft: 6 })
  })

  it('gleicher Anteil und gleiche Anzahl: beide Felder in Profil-Reihenfolge', () => {
    expect(meisterUebung([z('prozent', 2, 2), z('terme', 2, 2), z('zahlen', 5, 1)])).toEqual({
      felder: ['prozent', 'terme'],
      uebung: 2,
      geprueft: 4,
    })
  })
})
