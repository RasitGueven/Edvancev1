// tools/platz-konten.mjs: Platz-Konten für Tablets anlegen (Paket T1).
// Geprüft wird die Planung und der Lauf mit eingespritzten Effekten, ohne Netz und ohne Datei.

import { describe, expect, it, vi } from 'vitest'
import { labelFuer, lauf, mailFuer, nummernLesen, passwortErzeugen, planen } from '../tools/platz-konten.mjs'

describe('nummernLesen', () => {
  it('liest Bereiche, Listen und Einzelwerte, sortiert und ohne Doppelte', () => {
    expect(nummernLesen(['2-5'])).toEqual([2, 3, 4, 5])
    expect(nummernLesen(['5,3', '3', '2'])).toEqual([2, 3, 5])
  })

  it('weist alles außerhalb von 1 bis 99 und Unsinn ab', () => {
    expect(() => nummernLesen(['0'])).toThrow()
    expect(() => nummernLesen(['5-2'])).toThrow()
    expect(() => nummernLesen(['100'])).toThrow()
    expect(() => nummernLesen(['zwei'])).toThrow()
    expect(() => nummernLesen([])).toThrow()
  })
})

describe('planen', () => {
  it('überspringt belegte Nummern und meldet halb angelegte Konten', () => {
    const plan = planen([1, 2, 3], { belegt: new Set([1]), mails: new Set([1, 3]) })
    expect(plan.map((p) => p.aktion)).toEqual(['ueberspringen', 'anlegen', 'konflikt'])
  })

  it('benennt wie das vorhandene Gerät, Label „Tablet n“', () => {
    expect(mailFuer(4)).toBe('platz4@edvance.invalid')
    expect(labelFuer(4)).toBe('Tablet 4')
  })
})

describe('lauf', () => {
  const plan = planen([1, 2, 3], { belegt: new Set([1]), mails: new Set([1]) })

  it('schreibt im Trockenlauf nichts', async () => {
    const anlegen = vi.fn()
    const notieren = vi.fn()
    const stand = await lauf({ plan, dryRun: true, anlegen, notieren, log: () => {} })
    expect(stand).toEqual({ angelegt: 0, uebersprungen: 1, konflikt: 0 })
    expect(anlegen).not.toHaveBeenCalled()
    expect(notieren).not.toHaveBeenCalled()
  })

  it('legt nur die freien Nummern an und gibt kein Passwort aus', async () => {
    const anlegen = vi.fn().mockResolvedValue(undefined)
    const notieren = vi.fn()
    const zeilen: string[] = []
    const stand = await lauf({ plan, dryRun: false, anlegen, notieren, log: (z) => zeilen.push(z) })
    expect(stand.angelegt).toBe(2)
    expect(anlegen.mock.calls.map(([k]) => k.nr)).toEqual([2, 3])
    const passwoerter = notieren.mock.calls.map(([z]) => z.passwort)
    expect(zeilen.join('\n')).not.toMatch(new RegExp(passwoerter.join('|')))
    expect(zeilen.join('\n')).not.toContain('@')
  })

  it('schreibt bei einem Konflikt gar nichts', async () => {
    const anlegen = vi.fn()
    const konflikt = planen([2, 3], { belegt: new Set(), mails: new Set([3]) })
    const stand = await lauf({ plan: konflikt, dryRun: false, anlegen, notieren: vi.fn(), log: () => {} })
    expect(stand.konflikt).toBe(1)
    expect(anlegen).not.toHaveBeenCalled()
  })

  it('hält beim ersten Fehler an', async () => {
    const anlegen = vi.fn().mockRejectedValueOnce(new Error('kaputt'))
    const notieren = vi.fn()
    await expect(lauf({ plan, dryRun: false, anlegen, notieren, log: () => {} })).rejects.toThrow('kaputt')
    expect(anlegen).toHaveBeenCalledTimes(1)
    expect(notieren).not.toHaveBeenCalled()
  })
})

describe('passwortErzeugen', () => {
  it('liefert lange, verschiedene Passwörter', () => {
    const a = passwortErzeugen()
    expect(a.length).toBeGreaterThanOrEqual(24)
    expect(a).not.toBe(passwortErzeugen())
  })
})
