// L5 Teil B: Mathearbeiten im Erstgespräch — Anzahl, Themen, Vorauswahl, Payload.
import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import { describe, expect, it, vi } from 'vitest'
import '@/i18n'

import admin from '@/i18n/locales/de/admin.json'

import { EMPTY_INTAKE, kaAusForm, type IntakeFormState } from './formState'
import { KlassenarbeitFelder } from './KlassenarbeitFelder'

vi.mock('@/lib/supabase/kaFolge', () => ({
  listKaPlanThemen: () =>
    Promise.resolve({
      data: [
        { themaKey: 'reelle_zahlen', titel: 'Reelle Zahlen' },
        { themaKey: 'quadratische_funktionen', titel: 'Quadratische Funktionen' },
      ],
      error: null,
    }),
}))

const K = admin.intake.erstgespraech.klassenarbeit
const ALLE = { status: true, note: true }
const formMit = (teil: Partial<IntakeFormState>): IntakeFormState => ({
  ...EMPTY_INTAKE,
  schule_id: 'schule',
  class_level: 9,
  ...teil,
})

function zeige(form: IntakeFormState, kaFolge: { aktuellesThema: string | null } | null = { aktuellesThema: 'reelle_zahlen' }) {
  const patch = vi.fn()
  render(<KlassenarbeitFelder form={form} patch={patch} spalten={ALLE} kaFolge={kaFolge} />)
  return patch
}

describe('Erstgespräch · Mathearbeiten (L5)', () => {
  it('ohne kaFolge (Migration fehlt) keine neuen Felder', () => {
    zeige(formMit({}), null)
    expect(screen.queryByTestId('intake-ka-folge')).toBeNull()
  })

  it('Anzahl 4 · 5 · 6 · weiß nicht, ohne Vorauswahl, und der Hilfetext', () => {
    const patch = zeige(formMit({}))
    expect(screen.getByText(K.anzahl)).toBeInTheDocument()
    for (const n of ['4', '5', '6']) expect(screen.getByRole('button', { name: n })).toHaveAttribute('aria-pressed', 'false')
    expect(screen.getByText(K.termineHilfe)).toBeInTheDocument()
    fireEvent.click(screen.getByRole('button', { name: '5' }))
    expect(patch).toHaveBeenCalledWith({ ka_anzahl: 5 })
  })

  it('„steht noch an“: Frage nach den Themen der nächsten Arbeit, Mehrfachauswahl aus dem Plan', async () => {
    const patch = zeige(formMit({ klassenarbeit: 'bevorstehend', ka_themen: ['reelle_zahlen'] }))
    await waitFor(() => expect(screen.getByText(K.themenNaechste)).toBeInTheDocument())
    fireEvent.click(screen.getByRole('button', { name: 'Quadratische Funktionen' }))
    expect(patch).toHaveBeenCalledWith({ ka_themen: ['reelle_zahlen', 'quadratische_funktionen'] })
  })

  it('„schon geschrieben“: Frage „Was kam dran?“, beim Umschalten das aktuelle Thema vorausgewählt', async () => {
    const patch = zeige(formMit({}))
    fireEvent.click(screen.getByRole('button', { name: K.geschrieben }))
    expect(patch).toHaveBeenCalledWith({ klassenarbeit: 'geschrieben', ka_themen: ['reelle_zahlen'] })
    render(<KlassenarbeitFelder form={formMit({ klassenarbeit: 'geschrieben' })} patch={vi.fn()} spalten={ALLE} kaFolge={{ aktuellesThema: null }} />)
    await waitFor(() => expect(screen.getByText(K.themenGeschrieben)).toBeInTheDocument())
  })

  it('Payload: „weiß nicht“ als null, Themen nur mit Stand, Datum nur bei „steht an“, Note nur bei „geschrieben“', () => {
    expect(kaAusForm(formMit({ ka_anzahl: 'weissNicht', klassenarbeit: 'weissNicht', ka_themen: ['x'] }))).toEqual({
      anzahl: null,
      status: null,
      datum: null,
      themaKeys: [],
      note: null,
    })
    expect(
      kaAusForm(formMit({ ka_anzahl: 5, klassenarbeit: 'bevorstehend', naechste_arbeit_datum: '2026-11-12', ka_themen: ['a', 'b'], letzte_note: 3 })),
    ).toEqual({ anzahl: 5, status: 'bevorstehend', datum: '2026-11-12', themaKeys: ['a', 'b'], note: null })
    expect(kaAusForm(formMit({ klassenarbeit: 'geschrieben', naechste_arbeit_datum: '2026-11-12', ka_themen: ['a'], letzte_note: 4 }))).toEqual({
      anzahl: null,
      status: 'geschrieben',
      datum: null,
      themaKeys: ['a'],
      note: 4,
    })
  })
})
