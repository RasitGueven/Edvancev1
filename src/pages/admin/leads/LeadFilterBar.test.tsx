// Admin-Hülle H2, Punkt 5: Fach und Klasse als Chips statt Select.
import { describe, expect, it, vi } from 'vitest'
import { fireEvent, render, screen, within } from '@testing-library/react'
import '@/i18n'
import { EMPTY_FILTERS } from './boardModel'
import { LeadFilterBar } from './LeadFilterBar'

describe('LeadFilterBar', () => {
  it('Chips setzen und lösen Fach und Klasse, Archiv bleibt Schalter', () => {
    const onChange = vi.fn()
    const onToggleDone = vi.fn()
    render(
      <LeadFilterBar
        filters={{ ...EMPTY_FILTERS, subject: 'Mathematik' }}
        onChange={onChange}
        showDone={false}
        onToggleDone={onToggleDone}
      />,
    )
    const fach = screen.getByRole('group', { name: 'Fach' })
    expect(within(fach).getByRole('button', { name: 'Mathematik' }).getAttribute('aria-pressed')).toBe('true')
    fireEvent.click(within(fach).getByRole('button', { name: 'Alle' }))
    expect(onChange).toHaveBeenLastCalledWith({ subject: null })

    fireEvent.click(within(screen.getByRole('group', { name: 'Klasse' })).getByRole('button', { name: '9' }))
    expect(onChange).toHaveBeenLastCalledWith({ classLevel: 9 })

    fireEvent.click(screen.getByRole('checkbox'))
    expect(onToggleDone).toHaveBeenCalledWith(true)
  })
})
