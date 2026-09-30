// Die Marke vorbefuellter Felder: dezent sichtbar, bewusst leere Felder zeigen ihren Grund.

import { render, screen } from '@testing-library/react'
import { describe, expect, it } from 'vitest'
import '@/i18n'
import { Field } from './ui'
import { VorbefuelltContext } from './VorbefuelltMarke'
import type { Vorbefuellt } from '@/types'

function zeige(marker: Vorbefuellt | undefined, feld: string): void {
  render(
    <VorbefuelltContext.Provider value={marker}>
      <Field label="Feld" feld={feld}>
        <input aria-label="wert" />
      </Field>
    </VorbefuelltContext.Provider>,
  )
}

describe('VorbefuelltMarke', () => {
  it('markiert ein vorbefuelltes Feld mit dem Grund als Tooltip', () => {
    zeige({ afb: { art: 'neu', grund: 'IQB-belegt' } }, 'afb')
    expect(screen.getByText('vorbefüllt')).toHaveAttribute('title', 'IQB-belegt')
  })

  it('zeigt bei bewusst leeren Feldern den Grund', () => {
    zeige({ curriculum_grade: { art: 'leer', grund: 'Klasse 7 oder 8 unklar' } }, 'curriculum_grade')
    expect(screen.getByText('Bewusst leer: Klasse 7 oder 8 unklar')).toBeInTheDocument()
  })

  it('zeigt nichts ohne Eintrag — auch nicht fuer Coach-Hinweise', () => {
    zeige({ afb: { art: 'neu', grund: 'x' } }, 'coach_hints')
    expect(screen.queryByText('vorbefüllt')).toBeNull()
    expect(screen.queryByText(/Bewusst leer/)).toBeNull()
  })
})
