// TP-L1, Entscheidung 4: Der Klick auf „Präsentation“ startet das Vollbild im
// Handler selbst; ohne Vollbild-Möglichkeit oder als Web-App passiert nichts
// weiter, ein Fehler wird still geschluckt.
import { renderHook } from '@testing-library/react'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'

import { usePraesentationAnsicht } from './praesentationAnsicht'

const requestFullscreen = vi.fn(() => Promise.resolve())
let ermoeglicht = true

function ansicht() {
  let suche = new URLSearchParams('fall=x')
  const setSuche = vi.fn((f: (alt: URLSearchParams) => URLSearchParams) => {
    suche = f(suche)
  })
  const { result } = renderHook(() => usePraesentationAnsicht(setSuche as never))
  return { result, suche: () => suche.toString() }
}

describe('usePraesentationAnsicht', () => {
  beforeEach(() => {
    ermoeglicht = true
    requestFullscreen.mockReset()
    requestFullscreen.mockImplementation(() => Promise.resolve())
    Object.defineProperty(document, 'fullscreenEnabled', { configurable: true, get: () => ermoeglicht })
    Object.defineProperty(document, 'fullscreenElement', { configurable: true, get: () => null })
    Object.defineProperty(document.documentElement, 'requestFullscreen', { configurable: true, value: requestFullscreen })
  })

  afterEach(() => vi.unstubAllGlobals())

  it('öffnen: Vollbild und ?ansicht=praesentation; schließen nimmt sie wieder weg', () => {
    const a = ansicht()
    a.result.current.oeffne()
    expect(requestFullscreen).toHaveBeenCalledTimes(1)
    expect(a.suche()).toBe('fall=x&ansicht=praesentation')
    a.result.current.schliesse()
    expect(a.suche()).toBe('fall=x')
  })

  it('ohne fullscreenEnabled kein Vollbild, die Präsentation öffnet trotzdem', () => {
    ermoeglicht = false
    const a = ansicht()
    a.result.current.oeffne()
    expect(requestFullscreen).not.toHaveBeenCalled()
    expect(a.suche()).toContain('ansicht=praesentation')
  })

  it('als Web-App vom Home-Bildschirm kein Vollbild', () => {
    vi.stubGlobal('matchMedia', (q: string) => ({ matches: q === '(display-mode: standalone)' }))
    const a = ansicht()
    a.result.current.oeffne()
    expect(requestFullscreen).not.toHaveBeenCalled()
  })

  it('scheitert das Vollbild, bleibt es still', async () => {
    requestFullscreen.mockImplementation(() => Promise.reject(new Error('denied')))
    const a = ansicht()
    expect(() => a.result.current.oeffne()).not.toThrow()
    await Promise.resolve()
    expect(a.suche()).toContain('ansicht=praesentation')
  })
})
