// Board-Kontext der Warteschlange: nur Starts aus dem Lena-Board tragen ihn, und
// er ueberlebt einen Reload — sonst liefe die Strecke nach F5 wieder ueber VERA8.

import { beforeEach, describe, expect, it } from 'vitest'
import { clearQueue, initialRun, restoreQueue } from './wizardQueue'

describe('Warteschlange: Board-Kontext', () => {
  beforeEach(() => clearQueue())

  it('Start aus dem Board merkt sich den Kontext, auch nach Reload', () => {
    const run = initialRun({ ids: ['a', 'b'], label: 'Mathe 8', kontext: 'board' })
    expect(run?.queue.kontext).toBe('board')
    expect(restoreQueue()?.queue.kontext).toBe('board')
  })

  it('Start aus Expertenliste oder Content-Gesundheit hat keinen Board-Kontext', () => {
    const run = initialRun({ ids: ['a'], label: 'Item-Liste' })
    expect(run?.queue.kontext).toBeUndefined()
    expect(restoreQueue()?.queue.kontext).toBeUndefined()
  })

  it('unbekannte Kontextwerte werden verworfen', () => {
    expect(initialRun({ ids: ['a'], label: 'x', kontext: 'irgendwas' })?.queue.kontext).toBeUndefined()
  })
})
