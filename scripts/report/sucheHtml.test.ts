import { describe, expect, it } from 'vitest'

import { baueSuche } from '@/lib/report/suche'
import { FALL_A, FALL_B, FALL_C, FALL_D } from '@/lib/report/suche.fixtures'

import { sucheAbschnitt } from './sucheHtml'

/**
 * Der HTML-Entwurf (Druck/Mail an Eltern) zeigt Abschnitt 02 in derselben
 * Gliederung wie die App — dieselbe Rechnung, dieselben Texte.
 */
describe('sucheAbschnitt — Entwurf', () => {
  it('a) Volumen und Brüche stehen unter „Außerdem angesehen", nicht darunter', () => {
    const html = sucheAbschnitt(baueSuche(FALL_A)!)
    const grundlagen = html.indexOf('Grundlagen darunter')
    const ausserdem = html.indexOf('Außerdem angesehen')
    expect(html.indexOf('Aktuelles Thema')).toBeLessThan(grundlagen)
    expect(grundlagen).toBeLessThan(ausserdem)
    const block2 = html.slice(grundlagen, ausserdem)
    expect(block2).toMatch(/Beidseitige Gleichungen · sicher/)
    expect(block2).not.toMatch(/Volumeneinheiten|Brüche/)
    expect(html.slice(ausserdem)).toMatch(/Volumeneinheiten · noch nicht sicher/)
    expect(html).toMatch(/sicheren Boden/)
  })

  it.each([
    ['b', FALL_B],
    ['c', FALL_C],
    ['d', FALL_D],
  ])('%s) kein „sicherer Boden", kein Block „darunter"', (_, fall) => {
    const html = sucheAbschnitt(baueSuche(fall)!)
    expect(html).not.toMatch(/sicheren Boden|Grundlagen darunter/)
  })

  it.each([
    ['a', FALL_A],
    ['b', FALL_B],
    ['c', FALL_C],
    ['d', FALL_D],
  ])('%s) keine Ebenen, kein „trägt"', (_, fall) => {
    const html = sucheAbschnitt(baueSuche(fall)!)
    expect(html).not.toMatch(/Ebene|trägt|gemeistert/)
  })
})
