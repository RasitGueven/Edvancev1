// Dialog „Bericht per E-Mail senden“ (LR-2, Entscheidung 9): Vorschau mit
// Empfänger, Dateiname und Größe; Senden = hochladen + mail_senden; Fehler mit
// Meldung; „Erneut versuchen“ schickt dieselbe Datei ohne neuen Upload.
// Kein echter Versand: die Lib ist vollständig gemockt.
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import '@/i18n'
import type { LeadMailVersand } from '@/types'

const SID = '0f0e0d0c-0b0a-4908-8706-050403020100'
const PFAD = `${SID}/20261103-101500.pdf`
let log: LeadMailVersand[] = []

vi.mock('@/lib/supabase/lsaReportMail', () => ({
  listLsaReportVersand: vi.fn(() => Promise.resolve({ data: log, error: null })),
  lsaReportHochladen: vi.fn(() => Promise.resolve({ data: PFAD, error: null })),
  lsaReportSenden: vi.fn(() => Promise.resolve({ data: { an: 'zz@example.org', anhaenge: [] }, error: null })),
}))

import { lsaReportHochladen, lsaReportSenden } from '@/lib/supabase/lsaReportMail'
import { LsaReportMailModal } from './LsaReportMailModal'

const MAIL = {
  betreff: 'Lernstandsanalyse von ZZ_Ilkay – Ihr Bericht',
  text: 'Guten Tag,\n\nAnbei finden Sie den Bericht zur Lernstandsanalyse von ZZ_Ilkay vom 24.10.2026.',
  datei: 'Edvance LSA-Report ZZ_Ilkay 24.10.2026.pdf',
}
const PDF = new Blob([new Uint8Array(1_250_000)], { type: 'application/pdf' })

function oeffne(erzeugePdf: () => Promise<Blob> = () => Promise.resolve(PDF)) {
  return render(
    <LsaReportMailModal open onClose={vi.fn()} sessionId={SID} an="zz@example.org" mail={MAIL} erzeugePdf={erzeugePdf} />,
  )
}
const senden = (): HTMLElement => screen.getByRole('button', { name: /^(Senden|Erneut senden|Erneut versuchen)$/ })

describe('LsaReportMailModal', () => {
  beforeEach(() => {
    log = []
    vi.clearAllMocks()
  })

  it('zeigt Empfänger, Vorschau und Anhang mit Größe', async () => {
    oeffne()
    expect(screen.getByText('An: zz@example.org')).toBeInTheDocument()
    expect(screen.getByText(MAIL.betreff)).toBeInTheDocument()
    expect(screen.getByTestId('lsa-mail-text')).toHaveTextContent('vom 24.10.2026')
    await waitFor(() => expect(screen.getByTestId('lsa-mail-anhang')).toHaveTextContent(`Anhang: ${MAIL.datei} (1,3 MB)`))
    expect(senden()).toBeEnabled()
  })

  it('nennt den letzten Versand über dem Knopf; erneutes Senden bleibt möglich', async () => {
    log = [
      { id: '1', anlass: 'lsa_report', empfaenger: 'alt@example.org', ort: null, termin_at: null, fehler: null, erfolgt_at: '2026-11-02T09:00:00.000Z' },
    ]
    oeffne()
    expect(await screen.findByText(/Zuletzt versendet am .* an alt@example\.org\./)).toBeInTheDocument()
    await waitFor(() => expect(senden()).toHaveTextContent('Erneut senden'))
    expect(senden()).toBeEnabled()
  })

  it('Senden: hochladen, dann mail_senden mit dem Pfad, Erfolg mit Empfänger', async () => {
    oeffne()
    await waitFor(() => expect(senden()).toBeEnabled())
    fireEvent.click(senden())
    expect(await screen.findByText('Gesendet an zz@example.org.')).toBeInTheDocument()
    expect(lsaReportHochladen).toHaveBeenCalledWith(SID, PDF)
    expect(lsaReportSenden).toHaveBeenCalledWith(SID, PFAD)
  })

  it('Fehler: Meldung, „Erneut versuchen“ nutzt dieselbe Datei ohne neuen Upload', async () => {
    vi.mocked(lsaReportSenden).mockResolvedValueOnce({ data: null, error: 'Graph sendMail 403: ZZ verweigert' })
    oeffne()
    await waitFor(() => expect(senden()).toBeEnabled())
    fireEvent.click(senden())
    expect(await screen.findByText('Graph sendMail 403: ZZ verweigert')).toBeInTheDocument()
    expect(senden()).toHaveTextContent('Erneut versuchen')

    fireEvent.click(senden())
    expect(await screen.findByText('Gesendet an zz@example.org.')).toBeInTheDocument()
    expect(lsaReportHochladen).toHaveBeenCalledTimes(1)
    expect(lsaReportSenden).toHaveBeenCalledTimes(2)
    expect(vi.mocked(lsaReportSenden).mock.calls.map((c) => c[1])).toEqual([PFAD, PFAD])
  })

  it('PDF zu groß: Meldung, Senden gesperrt, nichts hochgeladen', async () => {
    const zuGross = Object.assign(new Error('PDF too large'), { name: 'PdfZuGross', bytes: 2_900_000 })
    oeffne(() => Promise.reject(zuGross))
    expect(await screen.findByText(/noch 2,9 MB groß \(höchstens 2,5 MB\)\. Es wurde nichts verschickt\./)).toBeInTheDocument()
    expect(senden()).toBeDisabled()
    expect(lsaReportHochladen).not.toHaveBeenCalled()
  })
})
