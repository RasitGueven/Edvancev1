import { describe, expect, it } from 'vitest'
import {
  cropObjectPath,
  isUsableCrop,
  normalizeRect,
  objectPathFromPublicUrl,
  toNaturalRect,
} from './crop'

const BUCKET = 'task-assets'
const PUBLIC = `https://xyz.supabase.co/storage/v1/object/public/${BUCKET}`

describe('normalizeRect', () => {
  it('nimmt einen Drag nach rechts-unten', () => {
    expect(normalizeRect({ x: 10, y: 20 }, { x: 40, y: 60 })).toEqual({
      x: 10,
      y: 20,
      width: 30,
      height: 40,
    })
  })

  it('nimmt einen Drag nach links-oben genauso — keine negativen Breiten', () => {
    expect(normalizeRect({ x: 40, y: 60 }, { x: 10, y: 20 })).toEqual({
      x: 10,
      y: 20,
      width: 30,
      height: 40,
    })
  })
})

describe('toNaturalRect', () => {
  const display = { width: 400, height: 300 }
  const natural = { width: 800, height: 600 }

  it('rechnet Anzeige-Pixel auf Bild-Pixel hoch', () => {
    expect(toNaturalRect({ x: 10, y: 20, width: 100, height: 50 }, display, natural)).toEqual({
      x: 20,
      y: 40,
      width: 200,
      height: 100,
    })
  })

  it('klemmt einen Drag ueber den Rand hinaus auf das Bild', () => {
    const rect = { x: -50, y: -50, width: 1000, height: 1000 }
    expect(toNaturalRect(rect, display, natural)).toEqual({
      x: 0,
      y: 0,
      width: 800,
      height: 600,
    })
  })

  it('bleibt bei 1:1-Anzeige identisch', () => {
    const same = { width: 800, height: 600 }
    const rect = { x: 5, y: 7, width: 11, height: 13 }
    expect(toNaturalRect(rect, same, same)).toEqual(rect)
  })

  it('liefert ein leeres Rechteck, wenn die Anzeige noch keine Groesse hat', () => {
    const rect = { x: 0, y: 0, width: 10, height: 10 }
    expect(toNaturalRect(rect, { width: 0, height: 0 }, natural)).toEqual({
      x: 0,
      y: 0,
      width: 0,
      height: 0,
    })
  })
})

describe('isUsableCrop', () => {
  it('lehnt einen Fehlklick ab', () => {
    expect(isUsableCrop({ x: 0, y: 0, width: 2, height: 200 })).toBe(false)
  })

  it('nimmt einen echten Ausschnitt', () => {
    expect(isUsableCrop({ x: 0, y: 0, width: 120, height: 90 })).toBe(true)
  })
})

describe('objectPathFromPublicUrl', () => {
  it('holt den Objektpfad aus der public URL', () => {
    expect(objectPathFromPublicUrl(`${PUBLIC}/lsa/eiscafe/figur.png`, BUCKET)).toBe(
      'lsa/eiscafe/figur.png',
    )
  })

  it('ignoriert Query-Parameter', () => {
    expect(objectPathFromPublicUrl(`${PUBLIC}/lsa/eiscafe/figur.png?v=2`, BUCKET)).toBe(
      'lsa/eiscafe/figur.png',
    )
  })

  it('dekodiert Prozent-Escapes', () => {
    expect(objectPathFromPublicUrl(`${PUBLIC}/lsa/a%20b/figur.png`, BUCKET)).toBe(
      'lsa/a b/figur.png',
    )
  })

  it('sagt null bei einer Fremd-URL', () => {
    expect(objectPathFromPublicUrl('https://example.org/figur.png', BUCKET)).toBeNull()
  })
})

describe('cropObjectPath', () => {
  it('legt den Zuschnitt neben das Original, nie darauf', () => {
    const path = cropObjectPath(`${PUBLIC}/lsa/eiscafe/figur.png`, BUCKET, 'task-1', 1700)
    expect(path).toBe('lsa/eiscafe/figur-crop-1700.png')
    expect(path).not.toBe('lsa/eiscafe/figur.png')
  })

  it('gibt jedem Zuschnitt desselben Bildes einen eigenen Pfad', () => {
    const url = `${PUBLIC}/lsa/eiscafe/figur.png`
    const first = cropObjectPath(url, BUCKET, 'task-1', 1700)
    const second = cropObjectPath(url, BUCKET, 'task-1', 1800)
    expect(first).not.toBe(second)
  })

  it('haengt den Zuschnitt eines Zuschnitts an, statt ihn zu ueberschreiben', () => {
    const path = cropObjectPath(`${PUBLIC}/lsa/eiscafe/figur-crop-1700.png`, BUCKET, 't', 1800)
    expect(path).toBe('lsa/eiscafe/figur-crop-1700-crop-1800.png')
  })

  it('faellt fuer Fremd-URLs auf den Task-Ordner zurueck', () => {
    expect(cropObjectPath('https://example.org/figur.png', BUCKET, 'task-1', 1700)).toBe(
      'tasks/task-1/crop-1700.png',
    )
  })
})
