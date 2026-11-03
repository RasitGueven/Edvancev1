// TP-L1: Faktor der Bühne, --tp-zoom an der Ebene, Vollbild-Knopf im Kopf,
// Schließen beendet das Vollbild, Escape im Vollbild schließt nicht.
import { act, fireEvent, render, screen } from '@testing-library/react'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import '@/i18n'

import { PRAESENTATION_FAELLE } from '@/lib/report/praesentation/fixtures'

import { Praesentation } from './Praesentation'
import { buehnenFaktor, inBuehnenPx, zoomVon } from './useBuehnenZoom'

describe('buehnenFaktor', () => {
  it.each([
    [1180, 820, 1],
    [820, 1180, 1],
    [1024, 700, 1],
    [1440, 900, 900 / 820],
    [1920, 1080, 1080 / 820],
    [2560, 1440, 1440 / 820],
  ])('%i × %i → %f', (b, h, f) => {
    expect(buehnenFaktor(b, h)).toBeCloseTo(f, 6)
  })

  it('rundet wie im Auftrag', () => {
    expect(buehnenFaktor(1440, 900)).toBeCloseTo(1.098, 3)
    expect(buehnenFaktor(1920, 1080)).toBeCloseTo(1.317, 3)
    expect(buehnenFaktor(2560, 1440)).toBeCloseTo(1.756, 3)
  })

  it('richtet sich nach der knapperen Richtung, ohne Obergrenze', () => {
    expect(buehnenFaktor(3440, 1440)).toBeCloseTo(1440 / 820, 6)
    expect(buehnenFaktor(1300, 2000)).toBeCloseTo(1300 / 1180, 6)
  })
})

describe('inBuehnenPx', () => {
  it('teilt Bildschirm-px durch den Faktor der Ebene, außerhalb der Ebene durch 1', () => {
    const tp = document.createElement('div')
    tp.className = 'tp'
    tp.style.setProperty('--tp-zoom', '2')
    const kind = document.createElement('span')
    tp.appendChild(kind)
    expect(zoomVon(kind)).toBe(2)
    expect(inBuehnenPx(100, kind)).toBe(50)
    expect(inBuehnenPx(100, document.createElement('span'))).toBe(100)
    expect(inBuehnenPx(100, null)).toBe(100)
  })
})

const { ilkay } = PRAESENTATION_FAELLE
let vollbildElement: Element | null = null
let ermoeglicht = true
const requestFullscreen = vi.fn(() => Promise.resolve())
const exitFullscreen = vi.fn(() => Promise.resolve())

function bildschirm(b: number, h: number): void {
  Object.defineProperty(window, 'innerWidth', { configurable: true, value: b })
  Object.defineProperty(window, 'innerHeight', { configurable: true, value: h })
}

function oeffne() {
  const onSchliessen = vi.fn()
  render(
    <Praesentation
      data={ilkay.data}
      notes={ilkay.notes}
      tiers={ilkay.tiers}
      tiersFehler={false}
      sessionId={ilkay.data.sessionId}
      laden={false}
      onSchliessen={onSchliessen}
    />,
  )
  return { onSchliessen }
}

const knopf = (): HTMLElement | null => screen.queryByTestId('tp-vollbild')

describe('Präsentation — Zoom und Vollbild (TP-L1)', () => {
  const vorher = { b: window.innerWidth, h: window.innerHeight }

  beforeEach(() => {
    vollbildElement = null
    ermoeglicht = true
    requestFullscreen.mockClear()
    exitFullscreen.mockClear()
    Object.defineProperty(document, 'fullscreenEnabled', { configurable: true, get: () => ermoeglicht })
    Object.defineProperty(document, 'fullscreenElement', { configurable: true, get: () => vollbildElement })
    Object.defineProperty(document, 'exitFullscreen', { configurable: true, value: exitFullscreen })
    Object.defineProperty(document.documentElement, 'requestFullscreen', { configurable: true, value: requestFullscreen })
    bildschirm(1920, 1080)
  })

  afterEach(() => {
    bildschirm(vorher.b, vorher.h)
    document.documentElement.classList.remove('tp-offen')
  })

  it('setzt --tp-zoom an der Ebene und rechnet bei resize neu', () => {
    oeffne()
    const tp = screen.getByRole('dialog')
    expect(Number(tp.style.getPropertyValue('--tp-zoom'))).toBeCloseTo(1080 / 820, 6)
    act(() => {
      bildschirm(1180, 820)
      window.dispatchEvent(new Event('resize'))
    })
    expect(tp.style.getPropertyValue('--tp-zoom')).toBe('1')
  })

  it('Knopf „Vollbild“ auf großem Bildschirm, wenn Vollbild geht und nicht läuft; Klick startet es', () => {
    oeffne()
    const k = knopf()
    expect(k).not.toBeNull()
    expect(k).toHaveAccessibleName('Vollbild')
    expect(k).toHaveAttribute('title')
    fireEvent.click(k!)
    expect(requestFullscreen).toHaveBeenCalledTimes(1)
  })

  it('kein Knopf ohne fullscreenEnabled', () => {
    ermoeglicht = false
    oeffne()
    expect(knopf()).toBeNull()
  })

  it('kein Knopf, solange Vollbild läuft; nach dem Ende ist er wieder da', () => {
    vollbildElement = document.documentElement
    oeffne()
    expect(knopf()).toBeNull()
    act(() => {
      vollbildElement = null
      document.dispatchEvent(new Event('fullscreenchange'))
    })
    expect(knopf()).not.toBeNull()
  })

  it('kein Knopf auf dem iPad (Faktor 1): der Kopf bleibt, wie er ist', () => {
    bildschirm(1180, 820)
    oeffne()
    expect(knopf()).toBeNull()
  })

  it('Schließen beendet das Vollbild', () => {
    vollbildElement = document.documentElement
    const { onSchliessen } = oeffne()
    fireEvent.click(screen.getByRole('button', { name: 'Präsentation schließen' }))
    expect(exitFullscreen).toHaveBeenCalledTimes(1)
    expect(onSchliessen).toHaveBeenCalledTimes(1)
  })

  it('Escape im Vollbild schließt nicht (der Browser beendet nur das Vollbild), sonst schon', () => {
    vollbildElement = document.documentElement
    const { onSchliessen } = oeffne()
    fireEvent.keyDown(document, { key: 'Escape' })
    expect(onSchliessen).not.toHaveBeenCalled()
    vollbildElement = null
    fireEvent.keyDown(document, { key: 'Escape' })
    expect(onSchliessen).toHaveBeenCalledTimes(1)
    expect(exitFullscreen).not.toHaveBeenCalled()
  })
})
