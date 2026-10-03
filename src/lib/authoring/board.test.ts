import { describe, expect, it } from 'vitest'
import type { AuthoringTask, SkillThema, TaskStatus } from '@/types'
import {
  aktiveKlassen,
  boardBestand,
  boardKlassen,
  fachVon,
  imBoard,
  inKlasse,
  standVon,
  stufenFolge,
  stufenGruppen,
  themenVon,
  warteschlange,
  warteschlangeAb,
  zuordnungAus,
  type BoardCluster,
} from './board'

function task(id: string, over: Partial<AuthoringTask> = {}): AuthoringTask {
  return {
    id,
    title: id,
    status: 'draft' as TaskStatus,
    cluster_id: null,
    class_level: null,
    skill_key: null,
    ...over,
  } as AuthoringTask
}

const clusters = new Map<string, BoardCluster>([
  ['c1', { id: 'c1', name: 'Zahl & Rechnen', subject_name: 'Mathematik' }],
  ['c2', { id: 'c2', name: 'Geometrie & Messen', subject_name: 'Mathematik' }],
])

const th = (skill_key: string, thema_key: string, label: string, stufe: SkillThema['stufe'], sort: number): SkillThema =>
  ({ skill_key, thema_key, label, stufe, sort })

const zuordnung = zuordnungAus([
  th('bruch_kuerzen', 'brueche', 'Brüche und Anteile', 'erprobung', 90),
  th('geo_umfang', 'flaeche_umfang', 'Flächen und Umfang', 'erprobung', 70),
  th('prozent_grundwert', 'zinsrechnung', 'Prozent- und Zinsrechnung', 'erste', 230),
  th('fkt_linear_steigung', 'lineare_funktionen', 'Lineare Funktionen', 'erste', 260),
  th('geo_kreis_umfang', 'kreis', 'Kreis: Umfang und Fläche', 'zweite', 470),
])

describe('Board-Bestand ohne VERA8', () => {
  const vera = task('vera', { source: 'VERA8_IQB', class_level: 8, cluster_id: 'c1', skill_key: 'bruch_kuerzen' })
  const eigen = task('eigen', { source: 'edvance_k8_binom', class_level: 8, cluster_id: 'c1', skill_key: 'bruch_kuerzen' })

  it('eine VERA8-Aufgabe erscheint nicht, eine Nicht-VERA-Aufgabe schon', () => {
    expect(imBoard(vera)).toBe(false)
    expect(imBoard(eigen)).toBe(true)
    expect(boardBestand([vera, eigen]).map((t) => t.id)).toEqual(['eigen'])
  })

  it('Zaehler, Themen und Warteschlange sehen VERA8 nicht', () => {
    const bestand = boardBestand([vera, eigen])
    expect(standVon(bestand.filter((t) => inKlasse(t, 8, [8]))).total).toBe(1)
    const themen = themenVon(bestand, zuordnung, 8)
    expect(themen.flatMap((x) => x.tasks.map((t) => t.id))).toEqual(['eigen'])
    expect(warteschlange(themen, 'offen')).toEqual(['eigen'])
  })
})

describe('aktive Klassen aus den Daten', () => {
  it('jedes vorkommende class_level ist aktiv, leere zaehlen nicht', () => {
    expect(aktiveKlassen([task('a', { class_level: 8 }), task('b'), task('c', { class_level: 8 })])).toEqual([8])
    expect(aktiveKlassen([task('a', { class_level: 9 }), task('b', { class_level: 8 })])).toEqual([8, 9])
  })

  it('Klasse 9 wird aktiv, sobald es eine Aufgabe mit class_level 9 gibt', () => {
    const ohne = [task('a', { class_level: 8 })]
    expect(inKlasse(task('x', { class_level: 8 }), 9, aktiveKlassen(ohne))).toBe(false)
    const mit = [...ohne, task('k', { class_level: 9 })]
    expect(inKlasse(task('x', { class_level: 8 }), 9, aktiveKlassen(mit))).toBe(true)
  })

  it('die Kacheln zeigen 8, 9, 10 und jede weitere aktive Klasse', () => {
    expect(boardKlassen([8])).toEqual([8, 9, 10])
    expect(boardKlassen([7, 9])).toEqual([7, 8, 9, 10])
  })
})

describe('inKlasse', () => {
  it('Klasse 8 nimmt class_level <= 8 und leer', () => {
    expect(inKlasse(task('a', { class_level: 8 }), 8, [8])).toBe(true)
    expect(inKlasse(task('a', { class_level: null }), 8, [8])).toBe(true)
    expect(inKlasse(task('a', { class_level: 9 }), 8, [8, 9])).toBe(false)
  })

  it('eine nicht aktive Klasse ist leer', () => {
    expect(inKlasse(task('a', { class_level: 8 }), 10, [8, 9])).toBe(false)
  })
})

describe('fachVon', () => {
  it('liest das Fach ueber den Cluster, ohne Cluster Mathematik', () => {
    expect(fachVon(task('a', { cluster_id: 'c1' }), clusters)).toBe('Mathematik')
    expect(fachVon(task('a'), clusters)).toBe('Mathematik')
  })
})

describe('standVon', () => {
  it('zaehlt je Zustand und gepruefter Fortschritt = review + ready', () => {
    const s = standVon([
      task('a', { status: 'draft' }),
      task('b', { status: 'review' }),
      task('c', { status: 'ready' }),
      task('d', { status: 'beanstandet' }),
    ])
    expect(s).toMatchObject({ total: 4, offen: 1, zurFreigabe: 1, freigegeben: 1, zurueckgewiesen: 1, geprueft: 2 })
  })
})

describe('stufenFolge', () => {
  it('die Stufe der Klasse zuerst, dann absteigend', () => {
    expect(stufenFolge(9)).toEqual(['zweite', 'erste', 'erprobung'])
    expect(stufenFolge(8)).toEqual(['erste', 'erprobung', 'zweite'])
    expect(stufenFolge(5)).toEqual(['erprobung', 'erste', 'zweite'])
  })
})

describe('themenVon und warteschlange', () => {
  const tasks = [
    task('z', { skill_key: 'prozent_grundwert', title: 'Zeta', cluster_id: 'c1' }),
    task('a', { skill_key: 'prozent_grundwert', title: 'Alpha', status: 'ready', cluster_id: 'c1' }),
    task('l', { skill_key: 'fkt_linear_steigung', title: 'Linear' }),
    task('b', { skill_key: 'bruch_kuerzen', title: 'Bruch', cluster_id: 'c1' }),
    task('u', { skill_key: 'geo_umfang', title: 'Umfang', cluster_id: 'c2' }),
    task('k', { skill_key: 'geo_kreis_umfang', title: 'Kreis', cluster_id: 'c2' }),
    task('p', { skill_key: 'potenzen', title: 'Potenz' }),
    task('o', { title: 'Ohne Skill' }),
  ]

  it('gruppiert nach Heimat-Thema, nicht nach Cluster', () => {
    const namen = themenVon(tasks, zuordnung, 9).map((x) => x.name)
    expect(namen).not.toContain('Zahl & Rechnen')
    expect(namen).toContain('Prozent- und Zinsrechnung')
  })

  it('Klasse 9: zweite Stufe, dann erste, dann Erprobung, je nach sort; Ohne Thema zuletzt', () => {
    const themen = themenVon(tasks, zuordnung, 9)
    expect(themen.map((x) => x.id)).toEqual([
      'kreis',
      'zinsrechnung',
      'lineare_funktionen',
      'flaeche_umfang',
      'brueche',
      null,
    ])
    expect(themen[1].tasks.map((t) => t.id)).toEqual(['a', 'z'])
  })

  it('Klasse 8: die erste Stufe vor der Erprobungsstufe', () => {
    const themen = themenVon(tasks.filter((t) => t.id !== 'k'), zuordnung, 8)
    expect(themen.map((x) => x.stufe)).toEqual(['erste', 'erste', 'erprobung', 'erprobung', null])
  })

  it('Ohne Thema sammelt Aufgaben ohne Skill und ohne Zuordnung, mit Zaehler', () => {
    const ohne = themenVon(tasks, zuordnung, 9).at(-1)
    expect(ohne?.id).toBeNull()
    expect(ohne?.tasks.map((t) => t.id)).toEqual(['o', 'p'])
    expect(ohne?.stand.total).toBe(2)
  })

  it('stufenGruppen schneidet in Abschnitte, Reihenfolge bleibt', () => {
    const gruppen = stufenGruppen(themenVon(tasks, zuordnung, 9))
    expect(gruppen.map((g) => [g.stufe, g.themen.length])).toEqual([
      ['zweite', 1],
      ['erste', 2],
      ['erprobung', 2],
      [null, 1],
    ])
  })

  it('ergibt bei jedem Start dieselbe Reihenfolge, nur passende Zustaende', () => {
    const erwartet = ['k', 'z', 'l', 'u', 'b', 'o', 'p']
    expect(warteschlange(themenVon(tasks, zuordnung, 9), 'offen')).toEqual(erwartet)
    expect(warteschlange(themenVon([...tasks].reverse(), zuordnung, 9), 'offen')).toEqual(erwartet)
  })

  it('startet bei einer Aufgabe und haengt nur offene desselben Themas an', () => {
    const zins = themenVon(tasks, zuordnung, 9)[1]
    expect(warteschlangeAb(zins, 'a', 'offen')).toEqual(['a', 'z'])
  })
})
