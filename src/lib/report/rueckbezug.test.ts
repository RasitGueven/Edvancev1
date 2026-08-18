import { describe, expect, it } from 'vitest'

import { baueFundament } from '@/lib/report/fundament'
import { baueRueckbezuege } from '@/lib/report/rueckbezug'
import type { ReportFehlbildFamilie } from '@/lib/reportFehlbilder'
import type { AnlassZuordnung, FundamentSkill } from '@/types'

const s = (
  skillKey: string,
  fundamentTiefe: number,
  zustand: string,
  proben = 1,
): FundamentSkill => ({ skillKey, label: skillKey, fundamentTiefe, zustand, proben })

// Wörtlich die drei Zeilen aus report_anlass_zuordnung (R4-Migration).
const ZUORDNUNGEN: AnlassZuordnung[] = [
  {
    thema: 'Textverständnis',
    anzeigename: 'Textverständnis',
    skillKeys: ['gleichung_modellieren'],
    fehlbildFamilien: ['sachaufgaben'],
    strukturell: false,
    messbar: true,
  },
  {
    thema: 'Rechenwege',
    anzeigename: 'Rechenwege',
    skillKeys: [],
    fehlbildFamilien: ['gleichungen_umformen', 'rechenreihenfolge'],
    strukturell: false,
    messbar: true,
  },
  {
    thema: 'Grundlagen fehlen',
    anzeigename: 'fehlende Grundlagen',
    skillKeys: [],
    fehlbildFamilien: [],
    strukturell: true,
    messbar: true,
  },
  {
    thema: 'Konzentration',
    anzeigename: 'Konzentration',
    skillKeys: [],
    fehlbildFamilien: [],
    strukturell: false,
    messbar: false,
  },
]

const familie = (key: string): ReportFehlbildFamilie => ({
  familie: key,
  elterntext: 'Satz.',
  anzahl: 2,
  aufgaben: 2,
})

/** Die Lage beider echter Sitzungen: Einstieg trägt, unten trägt, Mitte bricht. */
const ECHTE_SKILLS: FundamentSkill[] = [
  s('gleichung_modellieren', 8, 'traegt'),
  s('prozent_veraenderung', 8, 'traegt'),
  s('term_minusklammer', 6, 'traegt_nicht', 2),
  s('groessen_volumen', 6, 'traegt'),
  s('bruch_div', 3, 'traegt'),
]

function lauf(
  weakTopics: string[],
  skills = ECHTE_SKILLS,
  familien: ReportFehlbildFamilie[] = [],
) {
  return baueRueckbezuege({
    weakTopics,
    zuordnungen: ZUORDNUNGEN,
    skills,
    familien,
    fundament: baueFundament(skills)!,
  })
}

describe('baueRueckbezuege — jeder genannte Bereich bekommt eine Antwort', () => {
  it('sagt bei nicht messbaren Bereichen, dass sie nicht messbar sind', () => {
    // R5: Bis dahin fielen sie still weg. Ein unbeantworteter Punkt aus
    // Abschnitt 01 liest sich aber wie ein stillschweigendes „unauffällig".
    const r = lauf(['Konzentration'])
    expect(r).toHaveLength(1)
    expect(r[0].richtung).toBe('nicht_messbar')
    expect(r[0].fall).toBe('konzentration_nicht_messbar')
  })

  it('lässt einen Bereich ohne Zuordnung weiterhin weg', () => {
    // Ohne Zeile in report_anlass_zuordnung fehlt der Baustein-Namensraum —
    // und einen Satz ohne abgenommenen Baustein gibt es nicht.
    expect(lauf(['Prüfungsangst'])).toEqual([])
  })

  it('folgt der Reihenfolge, in der die Eltern die Bereiche genannt haben', () => {
    const r = lauf(['Grundlagen fehlen', 'Textverständnis'])
    expect(r.map((x) => x.thema)).toEqual(['Grundlagen fehlen', 'Textverständnis'])
  })

  it('nennt denselben Bereich nur einmal, auch wenn er doppelt im Array steht', () => {
    const r = lauf(['Textverständnis', 'Textverständnis'])
    expect(r).toHaveLength(1)
  })
})

describe('Entlastung braucht positive Evidenz', () => {
  it('entlastet Textverständnis, weil der Sachkontext-Skill trägt', () => {
    const r = lauf(['Textverständnis'])
    expect(r[0].richtung).toBe('entlastend')
  })

  it('wechselt bei nur einer Aufgabe in die vorsichtige Fassung', () => {
    // Genau die Lage beider echter Sitzungen: gleichung_modellieren wurde mit
    // EINER Aufgabe geprüft (ein MULTI_PART-Item mit zwei Teilaufgaben).
    const r = lauf(['Textverständnis'])
    expect(r[0].belege).toBe(1)
    expect(r[0].fall).toBe('textverstaendnis_entlastend_schmal')
  })

  it('nutzt ab zwei Aufgaben die volle Fassung', () => {
    const r = lauf(
      ['Textverständnis'],
      ECHTE_SKILLS.map((x) =>
        x.skillKey === 'gleichung_modellieren' ? { ...x, proben: 3 } : x,
      ),
    )
    expect(r[0].belege).toBe(3)
    expect(r[0].fall).toBe('textverstaendnis_entlastend')
  })

  it('entlastet Rechenwege NIE — meldet den Bereich aber als offen', () => {
    // Der Kern der Asymmetrie. In Sitzung 920d00ae tragen fünf falsche
    // Antworten null fehlbild_slug; „keine Familie über der Schwelle" heißt
    // dort nur, dass nichts katalogisiert wurde.
    //
    // Seit R5 wird daraus nicht Schweigen, sondern ein eigener Satz: messbar,
    // aber diese Sitzung gibt nichts her.
    const r = lauf(['Rechenwege'])
    expect(r).toHaveLength(1)
    expect(r[0].richtung).toBe('offen')
    expect(r[0].fall).toBe('rechenwege_offen')
  })

  it('bestätigt Rechenwege, sobald eine zugeordnete Familie über der Schwelle liegt', () => {
    const r = lauf(['Rechenwege'], ECHTE_SKILLS, [familie('gleichungen_umformen')])
    expect(r[0].richtung).toBe('bestaetigend')
    expect(r[0].fall).toBe('rechenwege_bestaetigend')
  })

  it('ignoriert Familien, die dem Bereich nicht zugeordnet sind', () => {
    const r = lauf(['Rechenwege'], ECHTE_SKILLS, [familie('einheiten_massstab')])
    expect(r[0].richtung).toBe('offen')
  })

  it('bestätigt vor entlasten, wenn beides zutrifft', () => {
    const r = lauf(['Textverständnis'], ECHTE_SKILLS, [familie('sachaufgaben')])
    expect(r[0].richtung).toBe('bestaetigend')
  })
})

describe('"Grundlagen fehlen" — belegt an der Form des Fundaments', () => {
  it('bestätigt, benennt aber die tragende Sohle', () => {
    const r = lauf(['Grundlagen fehlen'])
    expect(r[0].richtung).toBe('bestaetigend')
    expect(r[0].fall).toBe('grundlagen_bestaetigend_mitte')
  })

  it('unterscheidet Lücken bis ganz nach unten', () => {
    const bisUnten = [
      s('a', 8, 'traegt'),
      s('b', 6, 'traegt_nicht', 2),
      s('c', 3, 'traegt_nicht', 2),
    ]
    const r = lauf(['Grundlagen fehlen'], bisUnten)
    expect(r[0].fall).toBe('grundlagen_bestaetigend_durchgehend')
  })

  it('entlastet, wenn unterhalb des Einstiegs alles trägt', () => {
    const sauber = [
      s('a', 8, 'traegt'),
      s('b', 6, 'traegt'),
      s('c', 3, 'traegt'),
      s('d', 2, 'traegt'),
    ]
    const r = lauf(['Grundlagen fehlen'], sauber)
    expect(r[0].richtung).toBe('entlastend')
    expect(r[0].fall).toBe('grundlagen_entlastend')
    expect(r[0].belege).toBe(3)
  })

  it('wird vorsichtig, wenn unterhalb nur ein Bereich geprüft wurde', () => {
    const duenn = [s('a', 8, 'traegt'), s('b', 6, 'traegt')]
    const r = lauf(['Grundlagen fehlen'], duenn)
    expect(r[0].fall).toBe('grundlagen_entlastend_schmal')
  })

  it('meldet den Bereich als offen, wenn gar kein Abstieg stattgefunden hat', () => {
    const nurEinstieg = [s('a', 8, 'traegt'), s('b', 8, 'traegt')]
    const r = lauf(['Grundlagen fehlen'], nurEinstieg)
    expect(r[0].richtung).toBe('offen')
    expect(r[0].fall).toBe('grundlagen_offen')
  })

  it('beantwortet ALLE vier Punkte der Sitzung 920d00ae', () => {
    // Genau der Befund, der R5 ausgeloest hat: Abschnitt 01 nannte vier
    // Punkte, der Schluss behandelte zwei.
    const r = lauf([
      'Grundlagen fehlen',
      'Textverständnis',
      'Rechenwege',
      'Konzentration',
    ])
    expect(r.map((x) => x.thema)).toEqual([
      'Grundlagen fehlen',
      'Textverständnis',
      'Rechenwege',
      'Konzentration',
    ])
    expect(r.map((x) => x.richtung)).toEqual([
      'bestaetigend',
      'entlastend',
      'offen',
      'nicht_messbar',
    ])
  })
})
