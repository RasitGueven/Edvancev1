// Entscheidungsleiste der Erklaersequenz (L6): Passt, Passt nicht mit Gruenden, Unsicher mit Frage,
// gesperrte Knoepfe mit Tooltip.

import { describe, expect, it, vi } from 'vitest'
import { fireEvent, render, screen } from '@testing-library/react'
import { useState, type JSX } from 'react'
import '@/i18n'
import { ErklaerLeiste, type ErklaerPanel } from './ErklaerLeiste'

type Aufrufe = { onPasst?: () => void; onNicht?: () => void; onUnsicher?: () => void }

function Leiste(p: Aufrufe & { passtGesperrt?: string | null; nichtGesperrt?: string | null }): JSX.Element {
  const [panel, setPanel] = useState<ErklaerPanel>(null)
  return (
    <ErklaerLeiste panel={panel} setPanel={setPanel} info="Info" passtGesperrt={p.passtGesperrt ?? null}
      nichtGesperrt={p.nichtGesperrt ?? null} arbeitet={false} fehler={null}
      onPasst={p.onPasst ?? vi.fn()} onNicht={p.onNicht ?? vi.fn()} onUnsicher={p.onUnsicher ?? vi.fn()} />
  )
}

describe('ErklaerLeiste', () => {
  it('„Passt“ ruft onPasst', () => {
    const onPasst = vi.fn()
    render(<Leiste onPasst={onPasst} />)
    fireEvent.click(screen.getByRole('button', { name: /✓ Passt/ }))
    expect(onPasst).toHaveBeenCalledOnce()
  })

  it('gesperrtes „Passt“ und „Passt nicht“ nennen den Grund als Tooltip', () => {
    render(<Leiste passtGesperrt="Schon freigegeben" nichtGesperrt="Erst zurücknehmen" />)
    const passt = screen.getByRole('button', { name: /✓ Passt/ })
    expect(passt).toBeDisabled()
    expect(passt.parentElement).toHaveAttribute('title', 'Schon freigegeben')
    const nicht = screen.getByRole('button', { name: /^Passt nicht/ })
    expect(nicht).toBeDisabled()
    expect(nicht.parentElement).toHaveAttribute('title', 'Erst zurücknehmen')
  })

  it('„Passt nicht“ verlangt einen Grund, bei „Sonstiges“ eine Notiz', () => {
    const onNicht = vi.fn()
    render(<Leiste onNicht={onNicht} />)
    fireEvent.click(screen.getByRole('button', { name: /^Passt nicht/ }))
    fireEvent.click(screen.getByRole('button', { name: 'Als „Passt nicht“ speichern' }))
    expect(screen.getByRole('alert')).toHaveTextContent('Bitte mindestens einen Grund wählen.')
    fireEvent.click(screen.getByRole('button', { name: 'Sonstiges' }))
    fireEvent.click(screen.getByRole('button', { name: 'Als „Passt nicht“ speichern' }))
    expect(screen.getByRole('alert')).toHaveTextContent('Bei „Sonstiges“')
    expect(onNicht).not.toHaveBeenCalled()

    fireEvent.click(screen.getByRole('button', { name: 'Sonstiges' }))
    fireEvent.click(screen.getByRole('button', { name: 'Zu lang für einen Bildschirm' }))
    fireEvent.click(screen.getByRole('button', { name: 'Variante passt nicht zum Fehlbild' }))
    fireEvent.click(screen.getByRole('button', { name: 'Als „Passt nicht“ speichern' }))
    expect(onNicht).toHaveBeenCalledWith(['zu_lang', 'variante_fehlbild'], '')
  })

  it('„Unsicher“ verlangt eine Frage und gibt sie weiter', () => {
    const onUnsicher = vi.fn()
    render(<Leiste onUnsicher={onUnsicher} />)
    fireEvent.click(screen.getByRole('button', { name: /^Unsicher/ }))
    fireEvent.click(screen.getByRole('button', { name: 'Als „Unsicher“ speichern' }))
    expect(screen.getByRole('alert')).toHaveTextContent('Bitte kurz schreiben')
    fireEvent.change(screen.getByLabelText('Was ist dir unklar?'), { target: { value: '  Ist B für den Kehrwert?  ' } })
    fireEvent.click(screen.getByRole('button', { name: 'Als „Unsicher“ speichern' }))
    expect(onUnsicher).toHaveBeenCalledWith('Ist B für den Kehrwert?')
  })
})
