import { describe, expect, it } from 'vitest'
import { stepsForTask } from './wizardSteps'
import { clearQueue, persistPosition, persistQueue, restoreQueue } from './wizardQueue'
import type { AuthoringTask } from '@/types'

const baseTask: AuthoringTask = {
  id: 't1',
  title: 'Zwanzig Prozent',
  question: 'Berechne 20 % von 80 m.',
  status: 'draft',
  input_type: 'SHORT_TEXT',
  afb: 'I',
  competency_content: 'arithmetik_algebra',
  competency_process: 'ope',
  cluster_id: 'c1',
  unit: 'm',
  est_duration_sec: 120,
  class_level: 8,
  curriculum_grade: 7,
  parts: [],
  assets: [],
  needs_image: null,
  licence_text: null,
  question_payload: null,
  source: 'VERA8_IQB',
  source_ref: 'abc',
  is_active: true,
  created_at: '2026-07-01T00:00:00Z',
}

const task = (over: Partial<AuthoringTask> = {}): AuthoringTask => ({ ...baseTask, ...over })

describe('stepsForTask', () => {
  it('lässt den Bild-Schritt bei reinen Text-Items weg', () => {
    expect(stepsForTask(task())).toEqual(['read', 'anchor', 'solution', 'release'])
  })

  it('nimmt den Bild-Schritt auf, wenn Assets da sind', () => {
    const t = task({ assets: [{ url: 'https://x/y.png', alt: 'Diagramm' }] })
    expect(stepsForTask(t)).toEqual(['read', 'anchor', 'images', 'solution', 'release'])
  })

  it('nimmt den Bild-Schritt auf, wenn der Text auf eine Abbildung verweist', () => {
    const t = task({ question: 'Betrachte die folgende Abbildung und miss den Winkel.' })
    expect(stepsForTask(t)).toEqual(['read', 'anchor', 'images', 'solution', 'release'])
  })

  it('nimmt den Bild-Schritt auch bei totem Pfad auf — dort wohnt das Entfernen', () => {
    const t = task({ assets: [{ url: 'data/r01_render/s/1.png', alt: '' }] })
    expect(stepsForTask(t)).toEqual(['read', 'anchor', 'images', 'solution', 'release'])
  })
})

describe('wizardQueue', () => {
  it('überlebt einen Roundtrip und klemmt die Position auf die Länge', () => {
    persistQueue({ ids: ['a', 'b', 'c'], label: 'Item-Liste' })
    persistPosition(99)
    const restored = restoreQueue()
    expect(restored?.queue.ids).toEqual(['a', 'b', 'c'])
    expect(restored?.queue.label).toBe('Item-Liste')
    expect(restored?.pos).toBe(2)
    clearQueue()
    expect(restoreQueue()).toBeNull()
  })

  it('liefert null bei leerer oder kaputter Warteschlange', () => {
    sessionStorage.setItem('edvance.pflegeQueue', JSON.stringify({ ids: [] }))
    expect(restoreQueue()).toBeNull()
    sessionStorage.setItem('edvance.pflegeQueue', 'kein json')
    expect(restoreQueue()).toBeNull()
    clearQueue()
  })
})
