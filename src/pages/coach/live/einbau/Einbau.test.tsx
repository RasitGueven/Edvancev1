import { afterEach, beforeEach, describe, expect, it } from 'vitest'
import { cleanup, render, screen } from '@testing-library/react'
import { AUFGABE_BEITRAEGE, AufgabeEinbau } from './AufgabeEinbau'
import { CHECKIN_BEITRAEGE, CheckinEinbau } from './CheckinEinbau'

// Reihe 1 A5 haengt den Melde-Knopf fest ein; die Tests pruefen den Einbaupunkt ohne ihn.
const FEST = [...AUFGABE_BEITRAEGE]
beforeEach(() => { AUFGABE_BEITRAEGE.length = 0 })

afterEach(() => {
  cleanup()
  CHECKIN_BEITRAEGE.length = 0
  AUFGABE_BEITRAEGE.length = 0
  AUFGABE_BEITRAEGE.push(...FEST)
})

describe('Einbaupunkte C0b', () => {
  it('zeigen ohne Beitrag nichts', () => {
    const { container } = render(<><CheckinEinbau kindId="k" sessionId="s" /><AufgabeEinbau kindId="k" sessionId="s" taskId="t" /></>)
    expect(container.innerHTML).toBe('')
  })

  it('reichen die festen Props an Beitraege weiter', () => {
    CHECKIN_BEITRAEGE.push((p) => <span>{`${p.kindId}/${p.sessionId}`}</span>)
    AUFGABE_BEITRAEGE.push((p) => <span>{`${p.kindId}/${p.sessionId}/${p.taskId}`}</span>)
    render(<><CheckinEinbau kindId="k" sessionId="s" /><AufgabeEinbau kindId="k" sessionId="s" taskId="t" /></>)
    expect(screen.getByTestId('einbau-checkin').textContent).toBe('k/s')
    expect(screen.getByTestId('einbau-aufgabe').textContent).toBe('k/s/t')
  })
})
