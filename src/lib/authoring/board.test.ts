import { describe, expect, it } from 'vitest'
import type { AuthoringTask, TaskStatus } from '@/types'
import {
  fachVon,
  inKlasse,
  standVon,
  themenVon,
  warteschlange,
  warteschlangeAb,
  type BoardCluster,
} from './board'

function task(id: string, over: Partial<AuthoringTask> = {}): AuthoringTask {
  return {
    id,
    title: id,
    status: 'draft' as TaskStatus,
    cluster_id: null,
    class_level: null,
    ...over,
  } as AuthoringTask
}

const clusters = new Map<string, BoardCluster>([
  ['c1', { id: 'c1', name: 'Zahl & Rechnen', subject_name: 'Mathematik' }],
  ['c2', { id: 'c2', name: 'Geometrie & Messen', subject_name: 'Mathematik' }],
])

describe('inKlasse', () => {
  it('Klasse 8 nimmt class_level <= 8 und leer', () => {
    expect(inKlasse(task('a', { class_level: 8 }), 8)).toBe(true)
    expect(inKlasse(task('a', { class_level: null }), 8)).toBe(true)
    expect(inKlasse(task('a', { class_level: 9 }), 8)).toBe(false)
  })

  it('9 und 10 sind noch leer', () => {
    expect(inKlasse(task('a', { class_level: 8 }), 9)).toBe(false)
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

describe('themenVon und warteschlange', () => {
  const tasks = [
    task('z', { cluster_id: 'c1', title: 'Zeta' }),
    task('a', { cluster_id: 'c1', title: 'Alpha', status: 'ready' }),
    task('g', { cluster_id: 'c2', title: 'Gamma' }),
    task('o', { title: 'Ohne' }),
  ]

  it('sortiert Themen nach Name, ohne Themengebiet zuletzt, darin nach Titel', () => {
    const themen = themenVon(tasks, clusters)
    expect(themen.map((t) => t.name)).toEqual(['Geometrie & Messen', 'Zahl & Rechnen', null])
    expect(themen[1].tasks.map((t) => t.id)).toEqual(['a', 'z'])
  })

  it('ergibt bei jedem Start dieselbe Reihenfolge, nur passende Zustaende', () => {
    const themen = themenVon(tasks, clusters)
    expect(warteschlange(themen, 'offen')).toEqual(['g', 'z', 'o'])
    expect(warteschlange(themenVon([...tasks].reverse(), clusters), 'offen')).toEqual(['g', 'z', 'o'])
  })

  it('startet bei einer Aufgabe und haengt nur offene desselben Themas an', () => {
    const [, zahl] = themenVon(tasks, clusters)
    expect(warteschlangeAb(zahl, 'a', 'offen')).toEqual(['a', 'z'])
  })
})
