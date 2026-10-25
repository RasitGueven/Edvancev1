// Bericht v4, V4-E: Klassenarbeit im Erstgespräch — Formular, Sichtbarkeit, Speicher-Payload.
import { fireEvent, render, screen } from '@testing-library/react'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import '@/i18n'

import admin from '@/i18n/locales/de/admin.json'

import { EMPTY_INTAKE, intakeFromLead, klassenarbeitAusForm, type IntakeFormState } from './formState'
import { KlassenarbeitFelder } from './KlassenarbeitFelder'
import type { Lead } from '@/types'

const mock = vi.hoisted(() => ({ updates: [] as Record<string, unknown>[], fehlend: new Set<string>() }))

vi.mock('@/lib/supabase/client', () => ({
  supabase: {
    from: () => ({
      select: (spalte: string) => ({
        limit: () =>
          Promise.resolve(mock.fehlend.has(spalte) ? { error: { message: `column ${spalte} does not exist` } } : { error: null }),
      }),
      update: (patch: Record<string, unknown>) => {
        mock.updates.push(patch)
        return { eq: () => Promise.resolve({ error: null }) }
      },
    }),
  },
}))

const { ladeKlassenarbeitSpalten, saveLeadKlassenarbeit } = await import('@/lib/supabase/leads')
const K = admin.intake.erstgespraech.klassenarbeit
const ALLE = { status: true, note: true }

function formMit(teil: Partial<IntakeFormState>): IntakeFormState {
  return { ...EMPTY_INTAKE, ...teil }
}

function zeige(form: IntakeFormState, spalten = ALLE) {
  const patch = vi.fn()
  render(<KlassenarbeitFelder form={form} patch={patch} spalten={spalten} />)
  return patch
}

beforeEach(() => {
  mock.updates = []
  mock.fehlend = new Set()
})

describe('klassenarbeitAusForm', () => {
  it('drei Optionen: bevorstehend, geschrieben, weiß nicht → null; ohne Auswahl null', () => {
    expect(klassenarbeitAusForm(formMit({ klassenarbeit: 'bevorstehend' })).status).toBe('bevorstehend')
    expect(klassenarbeitAusForm(formMit({ klassenarbeit: 'geschrieben' })).status).toBe('geschrieben')
    expect(klassenarbeitAusForm(formMit({ klassenarbeit: 'weissNicht' })).status).toBeNull()
    expect(klassenarbeitAusForm(formMit({})).status).toBeNull()
  })

  it('Datum nur bei bevorstehend, Note nur bei geschrieben', () => {
    const f = { naechste_arbeit_datum: '2026-11-12', letzte_note: 4 }
    expect(klassenarbeitAusForm(formMit({ ...f, klassenarbeit: 'bevorstehend' }))).toEqual({
      status: 'bevorstehend',
      datum: '2026-11-12',
      note: null,
    })
    expect(klassenarbeitAusForm(formMit({ ...f, klassenarbeit: 'geschrieben' }))).toEqual({
      status: 'geschrieben',
      datum: null,
      note: 4,
    })
    expect(klassenarbeitAusForm(formMit({ klassenarbeit: 'bevorstehend', naechste_arbeit_datum: '' })).datum).toBeNull()
  })

  it('intakeFromLead übernimmt Status, Datum und Note; fehlende Spalten → leer', () => {
    const lead = { klassenarbeit_status: 'geschrieben', next_exam_date: null, letzte_klassenarbeit_note: 3 } as unknown as Lead
    const form = intakeFromLead({ ...lead, full_name: 'X' } as Lead)
    expect([form.klassenarbeit, form.naechste_arbeit_datum, form.letzte_note]).toEqual(['geschrieben', '', 3])
    const alt = intakeFromLead({ full_name: 'X', next_exam_date: '2026-11-01' } as unknown as Lead)
    expect([alt.klassenarbeit, alt.naechste_arbeit_datum, alt.letzte_note]).toEqual([null, '2026-11-01', null])
  })
})

describe('KlassenarbeitFelder', () => {
  it('zeigt die drei Optionen und den Hilfetext, sonst nichts', () => {
    zeige(formMit({}))
    for (const o of [K.bevorstehend, K.geschrieben, K.weissNicht]) expect(screen.getByText(o)).toBeInTheDocument()
    expect(screen.getByText(K.hilfe)).toBeInTheDocument()
    expect(screen.queryByText(K.datum)).toBeNull()
    expect(screen.queryByTestId('intake-letzte-note')).toBeNull()
  })

  it('Datum nur bei „steht noch an“', () => {
    zeige(formMit({ klassenarbeit: 'bevorstehend' }))
    expect(screen.getByLabelText(K.datum)).toHaveAttribute('type', 'date')
    expect(screen.queryByTestId('intake-letzte-note')).toBeNull()
  })

  it('Note 1–6 nur bei „schon geschrieben“, mit Hilfetext', () => {
    const patch = zeige(formMit({ klassenarbeit: 'geschrieben' }))
    expect(screen.getByTestId('intake-letzte-note')).toBeInTheDocument()
    expect(screen.getByText(K.noteHilfe)).toBeInTheDocument()
    fireEvent.click(screen.getByText('4'))
    expect(patch).toHaveBeenCalledWith({ letzte_note: 4 })
    expect(screen.queryByText(K.datum)).toBeNull()
  })

  it('ohne Spalte für die Note bleibt das Notenfeld aus; ohne Status-Spalte der ganze Block', () => {
    zeige(formMit({ klassenarbeit: 'geschrieben' }), { status: true, note: false })
    expect(screen.queryByTestId('intake-letzte-note')).toBeNull()
    const { container } = render(<KlassenarbeitFelder form={formMit({})} patch={vi.fn()} spalten={{ status: false, note: false }} />)
    expect(container).toBeEmptyDOMElement()
  })

  it('Klick auf die gewählte Option wählt sie ab (= null)', () => {
    const patch = zeige(formMit({ klassenarbeit: 'bevorstehend' }))
    fireEvent.click(screen.getByText(K.bevorstehend))
    expect(patch).toHaveBeenCalledWith({ klassenarbeit: null })
  })
})

describe('leads.ts — Klassenarbeit speichern', () => {
  it('ladeKlassenarbeitSpalten meldet fehlende Spalten', async () => {
    mock.fehlend.add('letzte_klassenarbeit_note')
    const warn = vi.spyOn(console, 'warn').mockImplementation(() => {})
    expect(await ladeKlassenarbeitSpalten()).toEqual({ status: true, note: false })
    warn.mockRestore()
  })

  it('schreibt nur vorhandene Spalten; Datum nur bei bevorstehend, Note nur bei geschrieben', async () => {
    await saveLeadKlassenarbeit('id', { status: 'bevorstehend', datum: '2026-11-12', note: 4 }, ALLE)
    await saveLeadKlassenarbeit('id', { status: 'geschrieben', datum: '2026-11-12', note: 4 }, ALLE)
    await saveLeadKlassenarbeit('id', { status: null, datum: null, note: null }, ALLE)
    await saveLeadKlassenarbeit('id', { status: 'geschrieben', datum: null, note: 2 }, { status: true, note: false })
    expect(mock.updates).toEqual([
      { next_exam_date: '2026-11-12', klassenarbeit_status: 'bevorstehend', letzte_klassenarbeit_note: null },
      { next_exam_date: null, klassenarbeit_status: 'geschrieben', letzte_klassenarbeit_note: 4 },
      { next_exam_date: null, klassenarbeit_status: null, letzte_klassenarbeit_note: null },
      { next_exam_date: null, klassenarbeit_status: 'geschrieben' },
    ])
  })
})
