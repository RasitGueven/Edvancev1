// Admin-Teil der Erklaerung (L6.3): was zur Freigabe fehlt, gesperrtes „Freigeben“ mit Tooltip, Ruecknahme
// nur mit Grund, Lenas Ergebnis.

import { describe, expect, it, vi } from 'vitest'
import { fireEvent, render, screen } from '@testing-library/react'
import '@/i18n'
import type { ErklaerDetail } from '@/types/erklaerPruefung'
import { ErklaerAdminBereich } from './ErklaerAdminBereich'

function detail(teil: Partial<ErklaerDetail> = {}, status: ErklaerDetail['kernidee']['status'] = 'geprueft'): ErklaerDetail {
  return {
    kernidee: {
      id: 'k', skill_key: 's', skill_label: 'S', klasse: 8, nr: 1, titel: 'T', status, quelle: 'ki', pruef_version: 7,
      geaendert_am: '2026-10-07T10:00:00Z', stand: status === 'freigegeben' ? 'freigegeben' : 'passt', rueckfrage: false, kernideen: 3,
    },
    schritte: [], fehlbilder: [], checks: [], checks_soll: 1, freigabe_fehlt: [],
    protokoll: [{
      id: 1, entscheidung: 'passt', gruende: [], notiz: null, aenderungen: [], pruef_version: 6, von: 'Lena',
      am: '2026-10-07T10:00:00Z', antwort: null, beantwortet_von: null, beantwortet_am: null,
    }],
    ...teil,
  }
}

const aufrufe = { onFreigeben: vi.fn(), onZuruecknehmen: vi.fn(), onAntworten: vi.fn() }

describe('ErklaerAdminBereich', () => {
  it('nennt, was fehlt, und sperrt „Freigeben“ mit Tooltip', () => {
    render(<ErklaerAdminBereich {...aufrufe} arbeitet={false} fehler={null} fehltAusFehler={null}
      detail={detail({ freigabe_fehlt: [
        { was: 'formeln_fehlen', variante: 'A', art: 'erklaerung' }, { was: 'checks', soll: 1, ist: 0 }] })} />)
    const liste = screen.getByTestId('freigabe-fehlt')
    expect(liste).toHaveTextContent('Variante A, Erklärschritt: Formeln noch nicht als Bild erzeugt.')
    expect(liste).toHaveTextContent('Mini-Checks: 0 von 1 freigegeben, es fehlt 1 freigegebene Check-Aufgabe.')
    const knopf = screen.getByRole('button', { name: 'Freigeben' })
    expect(knopf).toBeDisabled()
    expect(knopf.parentElement).toHaveAttribute('title', 'Erst wenn nichts mehr fehlt, lässt sich freigeben.')
    expect(screen.getByText(/^Passt · Lena/)).toBeInTheDocument()
  })

  it('gibt frei, wenn nichts fehlt', () => {
    render(<ErklaerAdminBereich {...aufrufe} arbeitet={false} fehler={null} fehltAusFehler={null} detail={detail()} />)
    fireEvent.click(screen.getByRole('button', { name: 'Freigeben' }))
    expect(aufrufe.onFreigeben).toHaveBeenCalledOnce()
  })

  it('Ruecknahme nur mit Grund', () => {
    render(<ErklaerAdminBereich {...aufrufe} arbeitet={false} fehler={null} fehltAusFehler={null} detail={detail({}, 'freigegeben')} />)
    fireEvent.click(screen.getByRole('button', { name: 'Freigabe zurücknehmen' }))
    const senden = screen.getByRole('button', { name: 'Zurücknehmen' })
    expect(senden).toBeDisabled()
    fireEvent.change(screen.getByLabelText('Warum nimmst du die Freigabe zurück?'), { target: { value: 'Beispiel zu schwer' } })
    fireEvent.click(senden)
    expect(aufrufe.onZuruecknehmen).toHaveBeenCalledWith('Beispiel zu schwer')
  })
})
