import { existsSync, readFileSync } from 'node:fs'
import { resolve } from 'node:path'
import { describe, expect, it } from 'vitest'

import { baueElternbericht } from '@/lib/report/elternbericht/bericht'
import { FAELLE } from '@/lib/report/elternbericht/fixtures'
import { themaAbdeckungAus } from '@/lib/report/elternbericht/themaAbdeckung'
import { gruppiereFehlbilderNachFamilie } from '@/lib/reportFehlbilder'

const SRC = resolve(__dirname, '../../../..')

/** Alle Module, die von `start` aus über '@/…'-Importe erreichbar sind (ohne Typ-Importe). */
function erreichbar(start: string): Set<string> {
  const gesehen = new Set<string>()
  const offen = [start]
  while (offen.length > 0) {
    const datei = offen.pop()!
    if (gesehen.has(datei)) continue
    gesehen.add(datei)
    const text = readFileSync(datei, 'utf8')
    for (const [, art, ziel] of text.matchAll(/^(?:import|export)\s+(type\s+)?[^;]*?from '@\/([^']+)'/gm)) {
      if (art) continue
      const kandidat = [`${ziel}.ts`, `${ziel}.tsx`, `${ziel}/index.ts`]
        .map((k) => resolve(SRC, k))
        .find((k) => existsSync(k))
      if (kandidat) offen.push(kandidat)
    }
  }
  return gesehen
}

describe('Fixtures des Eltern-Berichts', () => {
  it('kein Modul lädt den Supabase-Client, auch nicht über Umwege (Vorschau ohne .env)', () => {
    const module = [...erreichbar(resolve(__dirname, 'index.ts'))].map((d) => d.slice(SRC.length + 1))
    expect(module).toContain('lib/report/familien.ts')
    expect(module.filter((m) => m.startsWith('lib/supabase/'))).toEqual([])
  })

  it('vieleRueckbezuege hat vier Rückbezüge, ilkay einen', () => {
    expect(FAELLE.vieleRueckbezuege.data.erzaehlung.rueckbezuege).toHaveLength(4)
    expect(FAELLE.ilkay.data.erzaehlung.rueckbezuege.map((r) => r.fall)).toEqual([
      'konzentration_nicht_messbar',
    ])
  })

  it('jeder Rückbezug hat einen abgenommenen Baustein', () => {
    for (const { data } of Object.values(FAELLE)) {
      const faelle = new Set(data.erzaehlung.bausteine.filter((b) => b.slot === 'rueckbezug').map((b) => b.fall))
      for (const r of data.erzaehlung.rueckbezuege) expect(faelle, r.fall).toContain(r.fall)
    }
  })

  it('Sitzungs-IDs sind Platzhalter und eindeutig', () => {
    const ids = Object.entries(FAELLE)
      .filter(([n]) => n !== 'ilkay')
      .map(([, f]) => f.data.sessionId)
    expect(new Set(ids).size).toBe(ids.length)
    for (const { data } of Object.values(FAELLE)) expect(data.sessionId).toMatch(/^00000000-0000-4000-8000-/)
  })

  it('testlauf nur im Fall testlauf, ohne Namen nur in ohneName, ohne Notizen nur in ohneNotizen', () => {
    for (const [name, f] of Object.entries(FAELLE)) {
      expect(f.data.testlauf, name).toBe(name === 'testlauf')
      expect(f.data.firstName === null, name).toBe(name === 'ohneName')
      expect(f.notes === null, name).toBe(name === 'ohneNotizen')
      expect(f.tiers.filter((t) => t.active)).toHaveLength(3)
    }
  })

  it('modus ausdrücklich gesetzt; Thema-Satz nur in abgestuft und abgestuftMitOffen (R7-6)', () => {
    const abdeckung = (name: string) => themaAbdeckungAus(FAELLE[name].data.erzaehlung)
    for (const [name, f] of Object.entries(FAELLE)) {
      expect(f.data.erzaehlung.modus, name).not.toBeNull()
      expect(abdeckung(name) !== null, name).toBe(name === 'abgestuft' || name === 'abgestuftMitOffen')
    }
    expect(FAELLE.ilkay.data.erzaehlung.modus).toBe('fest')
    // Wie 6220b7e8 und 09cf8baa (Befund R7-6).
    expect(abdeckung('abgestuft')).toEqual({ thema: 'Reelle Zahlen', umfang: 14, direkt: 5, abgeleitet: 9, offen: 0 })
    expect(abdeckung('abgestuftMitOffen')).toMatchObject({ umfang: 14, direkt: 6, abgeleitet: 5, offen: 3 })
    expect(FAELLE.abgestuft.data.erzaehlung.kompetenzen).toHaveLength(12)
  })

  describe('Grenzfälle R7-5', () => {
    const bericht = (name: keyof typeof FAELLE) => {
      const { kompetenzen, katalog } = FAELLE[name].data.erzaehlung
      return baueElternbericht({ kompetenzen, katalog, klasse: FAELLE[name].data.grade })!
    }
    const familien = (name: keyof typeof FAELLE) => gruppiereFehlbilderNachFamilie(FAELLE[name].data.fehlbilder)

    it('mitFazit: zwei Familien über der Schwelle, die längsten Elterntexte zuerst', () => {
      expect(familien('mitFazit').map((f) => f.familie)).toEqual(['potenzen_wurzeln', 'geraden_schaubilder'])
      expect(familien('mitFazit').map((f) => f.elterntext.length)).toEqual([221, 208])
    })

    it('fazitLang: drei Familien, vier Schwerpunkte und „Danach …“, langes Lernziel', () => {
      expect(familien('fazitLang').map((f) => f.elterntext.length)).toEqual([221, 208, 194])
      expect(bericht('fazitLang').schwerpunkte).toHaveLength(4)
      expect(bericht('fazitLang').danach.length).toBeGreaterThan(0)
      expect(FAELLE.fazitLang.notes!.zielbild.length).toBeGreaterThan(500)
    })

    it('Rufnamen an der Grenze: 24 und 25 Zeichen', () => {
      expect([...FAELLE.langerName.data.firstName!]).toHaveLength(24)
      expect([...FAELLE.zuLangerName.data.firstName!]).toHaveLength(25)
      expect([...FAELLE.breiterName.data.firstName!]).toHaveLength(24)
      expect(bericht('langerName').profil).toHaveLength(8)
      for (const n of ['langerName', 'zuLangerName', 'breiterName'] as const) {
        expect(FAELLE[n].data.erzaehlung.anlassNamen.length, n).toBeGreaterThan(1)
        expect(FAELLE[n].data.erzaehlung.rueckbezuege, n).toHaveLength(1)
      }
    })

    it('weitereBereiche: neunte Profilzeile „weitere“', () => {
      const profil = bericht('weitereBereiche').profil
      expect(profil).toHaveLength(9)
      expect(profil.at(-1)!.feld).toBe('weitere')
    })

    it('vieleAnliegen: vier Anliegen, Thema, drei Rückbezüge mit den längsten Bausteinen', () => {
      const { data } = FAELLE.vieleAnliegen
      expect(data.erzaehlung.anlassNamen).toHaveLength(4)
      expect(data.naechstesThema).not.toBeNull()
      expect(data.erzaehlung.rueckbezuege.map((r) => r.fall)).toEqual([
        'textverstaendnis_entlastend_schmal',
        'rechenwege_offen',
        'grundlagen_entlastend_schmal',
      ])
    })

    it('keinSchwerpunktMitZiel: kein Schwerpunkt, Zielbild gesetzt', () => {
      expect(bericht('keinSchwerpunktMitZiel').schwerpunkte).toHaveLength(0)
      expect(FAELLE.keinSchwerpunktMitZiel.notes?.zielbild).toBeTruthy()
    })
  })
})
