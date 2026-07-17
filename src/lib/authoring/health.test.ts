import { describe, expect, it } from 'vitest'
import {
  computeDefects,
  countDefects,
  deadAssets,
  graphicLicenseHints,
  hasRealAsset,
  imageRefFinding,
  isDeadAssetUrl,
} from './health'
import type { AuthoringTask, GroundingRecord } from '@/types'

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
  question_payload: null,
  source: 'VERA8_IQB',
  source_ref: 'abc',
  is_active: true,
  created_at: '2026-07-01T00:00:00Z',
}

const task = (over: Partial<AuthoringTask> = {}): AuthoringTask => ({ ...baseTask, ...over })
const BUCKET = 'https://x.supabase.co/storage/v1/object/public/task-assets/lsa/s/1.png'

describe('isDeadAssetUrl', () => {
  it('erkennt relative Render-Pfade als tot', () => {
    expect(isDeadAssetUrl('data/r01_render/mein-slug/abb1.png')).toBe(true)
  })
  it('lässt Bucket-URLs in Ruhe', () => {
    expect(isDeadAssetUrl(BUCKET)).toBe(false)
    expect(isDeadAssetUrl('HTTPS://x/y.png')).toBe(false)
  })
  it('ignoriert leere Pfade', () => {
    expect(isDeadAssetUrl('   ')).toBe(false)
  })
})

describe('computeDefects', () => {
  it('meldet nichts bei einem gepflegten Item ohne Asset-Pflicht', () => {
    // Kein Asset ist selbst ein Mangel — hier bewusst mit Bucket-Bild + Alt.
    const t = task({ assets: [{ url: BUCKET, alt: 'Ein Diagramm' }] })
    expect([...computeDefects(t, true)]).toEqual([])
  })

  it('meldet toten Bildpfad', () => {
    const t = task({ assets: [{ url: 'data/r01_render/s/1.png', alt: 'x' }] })
    expect(computeDefects(t, true).has('deadPath')).toBe(true)
  })

  it('meldet fehlenden Stoffanker nur wenn die Spalte existiert', () => {
    const t = task({ curriculum_grade: null, assets: [{ url: BUCKET, alt: 'x' }] })
    expect(computeDefects(t, true).has('stoffankerMissing')).toBe(true)
    expect(computeDefects(t, false).has('stoffankerMissing')).toBe(false)
  })

  it('meldet Bild ohne Alt-Text', () => {
    const t = task({ assets: [{ url: BUCKET, alt: '  ' }] })
    expect(computeDefects(t, true).has('altMissing')).toBe(true)
  })

  it('meldet fehlendes Asset', () => {
    expect(computeDefects(task({ assets: [] }), true).has('noAsset')).toBe(true)
  })

  it('ein totes Bild ohne Alt zählt für beide Mängel', () => {
    const t = task({ assets: [{ url: 'data/r01_render/s/1.png', alt: '' }] })
    const d = computeDefects(t, true)
    expect(d.has('deadPath')).toBe(true)
    expect(d.has('altMissing')).toBe(true)
    expect(d.has('noAsset')).toBe(false)
  })
})

describe('computeDefects — needsImageUnjudged (A08)', () => {
  it('meldet offene Bild-Notwendigkeit bei Bildverweis ohne Beurteilung', () => {
    const t = task({
      question: 'Welcher Winkel ist in der Abbildung markiert?',
      assets: [],
      needs_image: null,
    })
    expect(computeDefects(t, true).has('needsImageUnjudged')).toBe(true)
  })

  it('meldet offene Bild-Notwendigkeit auch bei totem Pfad ohne Beurteilung', () => {
    const t = task({ assets: [{ url: 'data/r01_render/s/1.png', alt: 'x' }], needs_image: null })
    expect(computeDefects(t, true).has('needsImageUnjudged')).toBe(true)
  })

  it('ist beurteilt: needs_image=true schweigt trotz Bildverweis', () => {
    const t = task({
      question: 'Welcher Winkel ist in der Abbildung markiert?',
      assets: [],
      needs_image: true,
    })
    expect(computeDefects(t, true).has('needsImageUnjudged')).toBe(false)
  })

  it('ist beurteilt: needs_image=false schweigt trotz totem Pfad', () => {
    const t = task({ assets: [{ url: 'data/r01_render/s/1.png', alt: 'x' }], needs_image: false })
    expect(computeDefects(t, true).has('needsImageUnjudged')).toBe(false)
  })

  it('kein Bild-Signal, keine offene Bild-Notwendigkeit', () => {
    // Reiner Text ohne Verweis, ohne totes Asset — nichts zu beurteilen.
    const t = task({ question: 'Berechne 20 % von 80 m.', assets: [], needs_image: null })
    expect(computeDefects(t, true).has('needsImageUnjudged')).toBe(false)
  })
})

describe('hasRealAsset', () => {
  it('zählt nur echte http(s)-Bilder', () => {
    expect(hasRealAsset(task({ assets: [{ url: BUCKET, alt: 'x' }] }))).toBe(true)
    expect(hasRealAsset(task({ assets: [] }))).toBe(false)
    expect(hasRealAsset(task({ assets: [{ url: 'data/r01_render/s/1.png', alt: 'x' }] }))).toBe(false)
  })
})

describe('imageRefFinding', () => {
  it('erkennt „in der Abbildung" ohne Asset als Verdacht', () => {
    const t = task({ question: 'Welcher Winkel ist in der Abbildung markiert?', assets: [] })
    const f = imageRefFinding(t)
    expect(f?.source).toBe('question')
    expect(f?.match.toLowerCase()).toContain('abbildung')
    expect(f?.excerpt).toContain('Abbildung')
  })

  it('erkennt weitere Verweiswörter (schraffiert, nebenstehend, siehe Grafik)', () => {
    expect(imageRefFinding(task({ question: 'Wie groß ist die schraffierte Fläche?', assets: [] }))).not.toBeNull()
    expect(imageRefFinding(task({ question: 'Lies den Wert im nebenstehenden Diagramm ab.', assets: [] }))).not.toBeNull()
    expect(imageRefFinding(task({ question: 'Siehe Grafik oben.', assets: [] }))).not.toBeNull()
  })

  it('ist kein Verdacht bei echtem Asset', () => {
    const t = task({ question: 'Welcher Winkel ist in der Abbildung markiert?', assets: [{ url: BUCKET, alt: 'Winkel' }] })
    expect(imageRefFinding(t)).toBeNull()
  })

  it('bleibt Verdacht bei totem Pfad — das ist kein echtes Asset', () => {
    const t = task({ question: 'Was ist in der Skizze dargestellt?', assets: [{ url: 'data/r01_render/s/1.png', alt: 'x' }] })
    expect(imageRefFinding(t)?.source).toBe('question')
  })

  it('ignoriert Ortsangaben ohne Bildbezug', () => {
    expect(imageRefFinding(task({ question: 'Rechne die rechte Seite der Gleichung aus.', assets: [] }))).toBeNull()
    expect(imageRefFinding(task({ question: 'Berechne 20 % von 80 m.', assets: [] }))).toBeNull()
  })

  it('findet den Verweis auch in einer Teilaufgabe', () => {
    const t = task({
      question: 'Betrachte die Werte.',
      assets: [],
      parts: [
        { nr: 1, kind: 'short_input', prompt: 'Addiere die Zahlen.' },
        { nr: 2, kind: 'short_input', prompt: 'Welche Figur ist eingezeichnet?' },
      ],
    })
    const f = imageRefFinding(t)
    expect(f?.source).toBe(2)
    expect(f?.excerpt).toContain('eingezeichnet')
  })

  it('meldet den Mangel imageRefNoAsset in computeDefects', () => {
    const t = task({ question: 'Welcher Punkt ist in der Abbildung markiert?', assets: [] })
    expect(computeDefects(t, true).has('imageRefNoAsset')).toBe(true)
  })
})

describe('deadAssets + countDefects', () => {
  it('liefert nur die toten Einträge', () => {
    const t = task({
      assets: [
        { url: BUCKET, alt: 'ok' },
        { url: 'data/r01_render/s/2.png', alt: 'tot' },
      ],
    })
    expect(deadAssets(t).map((a) => a.alt)).toEqual(['tot'])
  })

  it('summiert Mängel über mehrere Items', () => {
    const items = [
      { defects: computeDefects(task({ assets: [] }), true) },
      { defects: computeDefects(task({ curriculum_grade: null, assets: [] }), true) },
    ]
    const c = countDefects(items)
    expect(c.noAsset).toBe(2)
    expect(c.stoffankerMissing).toBe(1)
  })
})

describe('graphicLicenseHints', () => {
  it('filtert Grafik- und Lizenzzeilen aus flags/import_flags', () => {
    const record: GroundingRecord = {
      id: 'abc',
      flags: [
        "G7: Lizenzzeile nennt NUR Text, keine 'Grafik' -> Abbildung NICHT verwenden",
        'unrelated note',
      ],
      import_flags: ['IMPORT: 1 Abbildung(en) weggelassen'],
    }
    const hints = graphicLicenseHints(record)
    expect(hints).toHaveLength(2)
    expect(hints[0]).toContain('Grafik')
  })

  it('ist leer ohne Record', () => {
    expect(graphicLicenseHints(null)).toEqual([])
  })
})
