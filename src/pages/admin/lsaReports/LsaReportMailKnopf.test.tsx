// „Per E-Mail senden“ (LR-2, Entscheidung 8): gesperrt nur aus fünf Gründen,
// je mit dem Grund als Tooltip — jeder Fall einzeln. Kein echter Zugriff:
// die Lib ist gemockt.
import { describe, expect, it, vi } from 'vitest'
import { render, screen, waitFor } from '@testing-library/react'
import '@/i18n'
import type { ReportData } from '@/types'

const lead = vi.hoisted(() => ({ wert: { full_name: 'ZZ_Ilkay B', first_name: 'ZZ_Ilkay', contact_email: 'zz@example.org' } as Record<string, unknown> }))
vi.mock('@/lib/supabase/lsaReportMail', () => ({
  ladeLsaReportEmpfaenger: vi.fn(() => Promise.resolve({ data: lead.wert, error: null })),
  listLsaReportVersand: vi.fn(() => Promise.resolve({ data: [], error: null })),
  lsaReportHochladen: vi.fn(),
  lsaReportSenden: vi.fn(),
}))

import { LsaReportMailKnopf } from './LsaReportMailKnopf'
import { mailSperre } from './mailSperre'

const DATA = {
  sessionId: '0f0e0d0c-0b0a-4908-8706-050403020100',
  leadId: 'ZZ_lead',
  auswertbar: true,
  testlauf: false,
  analysedAt: '2026-10-24T08:30:00.000Z',
} as ReportData

const knopf = (): HTMLElement => screen.getByRole('button', { name: /Per E-Mail senden/ })
const grund = (): string | null => knopf().parentElement!.getAttribute('title')

describe('mailSperre', () => {
  const frei = { admin: true, laedt: false, nichtAuswertbar: false, elternMail: 'zz@example.org', ungespeichert: false }
  it.each([
    ['rolle', { admin: false }],
    ['laedt', { laedt: true }],
    ['nichtAuswertbar', { nichtAuswertbar: true }],
    ['keineMail', { elternMail: '  ' }],
    ['keineMail', { elternMail: null }],
    ['ungespeichert', { ungespeichert: true }],
  ] as const)('%s', (soll, abweichung) => {
    expect(mailSperre({ ...frei, ...abweichung })).toBe(soll)
  })
  it('frei, wenn nichts davon zutrifft', () => {
    expect(mailSperre(frei)).toBeNull()
  })
})

describe('LsaReportMailKnopf', () => {
  it('frei: kein Tooltip', async () => {
    lead.wert = { full_name: 'ZZ_Ilkay B', first_name: 'ZZ_Ilkay', contact_email: 'zz@example.org' }
    render(<LsaReportMailKnopf data={DATA} admin laedt={false} ungespeichert={false} />)
    await waitFor(() => expect(knopf()).toBeEnabled())
    expect(grund()).toBeNull()
  })

  it('Rolle nicht Admin', () => {
    render(<LsaReportMailKnopf data={DATA} admin={false} laedt={false} ungespeichert={false} />)
    expect(knopf()).toBeDisabled()
    expect(grund()).toBe('Nur ein Admin kann den Bericht verschicken.')
  })

  it('LSA nicht auswertbar', async () => {
    render(<LsaReportMailKnopf data={{ ...DATA, auswertbar: false }} admin laedt={false} ungespeichert={false} />)
    await waitFor(() => expect(grund()).toBe('Diese LSA ist nicht auswertbar, es gibt keinen Bericht zu verschicken.'))
    expect(knopf()).toBeDisabled()
  })

  it('keine Eltern-Mail am Lead', async () => {
    lead.wert = { full_name: 'ZZ_Ilkay B', first_name: 'ZZ_Ilkay', contact_email: null }
    render(<LsaReportMailKnopf data={DATA} admin laedt={false} ungespeichert={false} />)
    await waitFor(() => expect(grund()).toBe('Am Lead ist keine Eltern-Mail hinterlegt.'))
    expect(knopf()).toBeDisabled()
  })

  it('kein Lead zur Sitzung', async () => {
    render(<LsaReportMailKnopf data={{ ...DATA, leadId: null }} admin laedt={false} ungespeichert={false} />)
    await waitFor(() => expect(grund()).toBe('Am Lead ist keine Eltern-Mail hinterlegt.'))
  })

  it('Ausblick ungespeichert', async () => {
    lead.wert = { full_name: 'ZZ_Ilkay B', first_name: 'ZZ_Ilkay', contact_email: 'zz@example.org' }
    render(<LsaReportMailKnopf data={DATA} admin laedt={false} ungespeichert />)
    await waitFor(() => expect(grund()).toBe('Der Ausblick hat ungespeicherte Änderungen. Bitte erst speichern.'))
    expect(knopf()).toBeDisabled()
  })

  it('Bericht oder Pakete laden noch', () => {
    render(<LsaReportMailKnopf data={DATA} admin laedt ungespeichert={false} />)
    expect(knopf()).toBeDisabled()
    expect(grund()).toBe('Bericht und Pakete laden noch.')
  })
})
