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

  it('Breite min(28, (226 − (n_max − 1) · Lücke) / n_max) für n_max = 1, 4, 7, 17, 31, 40', () => {
    expect(massstab(1).breite).toBe(28)
    expect(massstab(4).breite).toBe(28)
    expect(massstab(7).breite).toBe(28) // (226 − 24) / 7 = 28,86
    expect(massstab(17).breite).toBeCloseTo((226 - 16 * 2) / 17) // 11,41
    expect(massstab(31).breite).toBeCloseTo((226 - 30) / 31) // 6,32
    expect(massstab(40).breite).toBeCloseTo((226 - 39) / 40) // 4,68
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
    expect(m).toEqual(massstab(40))
    const alle = zeilen.flatMap((z) => segmente(z, m))
    expect(new Set(alle.map((s) => s.breite)).size).toBe(1)
    for (const z of zeilen) {
      const s = segmente(z, m)
      if (s.length > 1) expect(s[1].x - s[0].x - s[0].breite).toBeCloseTo(1)
    }
  })

  it('Spur 206 pt für alle Zeilen, sobald eine Zeile abgeleitete hat, sonst 226 pt', () => {
    const z = (abgeleitet: number): ProfilZeile => ({ feld: 'zahlen', sicher: 4, uebung: 5, abgeleitet, klasse: null })
    expect(massstabFuer([z(0)])).toEqual(massstab(9, SPUR))
    expect(massstabFuer([z(0), { ...z(2), feld: 'brueche', sicher: 0, uebung: 0 }])).toEqual(
      massstab(9, SPUR_MIT_ABGELEITETEN),
    )
    // Längster Fall: 12 geprüft + 14 abgeleitet in einer Zeile.
    const lang = massstabFuer(zeilenVon('abgestuftLang'))
    expect(lang).toEqual(massstab(26, 206))
    expect(26 * lang.breite + 25 * lang.luecke).toBeCloseTo(206)
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
    expect(z.map((x) => [x.feld, kaestchen(x)])).toEqual([
      ['brueche', 5],
      ['prozent', 4],
      ['terme', 4],
      ['geometrie', 6],
      ['groessen', 5],
      ['zahlen', 3],
    ])
    expect(z.every((x) => x.abgeleitet === 0)).toBe(true)
  })

  it('direkt geprüft wie im Profil (zaehle unverändert), auch weitereBereiche', () => {
    for (const fall of ['ilkay', 'allesSicher', 'weitereBereiche', 'abgestuft'] as const) {
      const direkt = bericht(fall).profil.filter((x) => x.sicher + x.uebung > 0)
      const z = zeilenVon(fall).filter((x) => x.sicher + x.uebung > 0)
      expect(z.map((x) => [x.feld, x.sicher, x.uebung]), fall).toEqual(
        direkt.map((x) => [x.feld, x.sicher, x.uebung]),
      )
    }
    expect(zeilenVon('weitereBereiche').at(-1)!.feld).toBe('weitere')
  })

  it('Umrisse nur bei den abgestuften Fällen; Summe = themaAbdeckung.abgeleitet', () => {
    for (const fall of Object.keys(FAELLE).filter((f) => f !== 'ohneKatalog') as (keyof typeof FAELLE)[]) {
      const summe = zeilenVon(fall).reduce((n, x) => n + x.abgeleitet, 0)
      const erwartet = { abgestuft: 9, abgestuftMitOffen: 5, abgestuftLang: 14 }[fall as string] ?? 0
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
    expect(deutung(zeilenVon('abgestuft'))).toEqual({ sicher: ['terme'], uebung: ['geometrie', 'zahlen'] })
  })

  it('ilkay: unverändert, jedes Feld hat mindestens 3 geprüfte Bereiche', () => {
    const p = bericht('ilkay').profil
    expect(p.filter((z) => z.sicher + z.uebung > 0).every((z) => z.sicher + z.uebung >= 3)).toBe(true)
    expect(deutung(zeilenVon('ilkay'))).toEqual({ sicher: ['groessen', 'zahlen'], uebung: ['geometrie', 'brueche'] })
  })
})
