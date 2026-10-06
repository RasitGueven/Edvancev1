// Feste Leisten der Pruefansicht ruecken in der Huelle um die Seitenleiste ein (Layout-Modi spalte/voll,
// Breiten aus den Tokens), ausserhalb der Huelle bleiben sie volle Breite.

import { describe, expect, it, vi } from 'vitest'
import { render, screen } from '@testing-library/react'
import '@/i18n'
import { ShellContext } from '@/components/edvance/shell/shellContext'
import { EntscheidungsMeldung } from './Entscheidungsleiste'
import { leisteLinks, meldungMitte } from './leistenRand'

describe('leistenRand', () => {
  it('in der Huelle: Einrueckung je Layout-Modus ueber die Tokens, ohne feste Pixel', () => {
    expect(leisteLinks(true)).toBe('left-0 spalte:left-[var(--container-leiste-schmal)] voll:left-[var(--container-leiste)]')
    expect(meldungMitte(true)).toContain('voll:left-[calc(50%+var(--container-leiste)/2)]')
    expect(`${leisteLinks(true)} ${meldungMitte(true)}`).not.toMatch(/\d+px/)
  })
  it('ausserhalb der Huelle: volle Breite', () => {
    expect(leisteLinks(false)).toBe('left-0')
    expect(meldungMitte(false)).toBe('left-1/2')
  })
  it('die Meldung liest den Huellen-Kontext', () => {
    render(<ShellContext.Provider value={true}><EntscheidungsMeldung text="x" onZu={vi.fn()} /></ShellContext.Provider>)
    expect(screen.getByRole('status').className).toContain('voll:left-[calc(50%+var(--container-leiste)/2)]')
  })
})
