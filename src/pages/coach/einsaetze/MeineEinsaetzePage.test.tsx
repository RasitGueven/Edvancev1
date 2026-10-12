// Slots SL3: Coach „Meine Einsätze“ mit gemockten Slot-Aufrufen (erfundene Daten).

import { beforeEach, describe, expect, it, vi } from 'vitest'
import { fireEvent, render, screen, within } from '@testing-library/react'
import { MemoryRouter, Route, Routes, useLocation } from 'react-router-dom'
import '@/i18n'
import type { MeinEinsatz } from '@/types/slotplan'

const daten = vi.hoisted(() => ({ einsaetze: [] as unknown[], anlegen: null as unknown }))

vi.mock('@/lib/supabase/slotplan', () => ({
  ladeMeineEinsaetze: vi.fn((montag: string) =>
    Promise.resolve({ data: { montag, kw: 11, heute: '2028-03-13', einsaetze: daten.einsaetze }, error: null }),
  ),
  terminSessionAnlegen: vi.fn(() => Promise.resolve(daten.anlegen)),
}))

import { terminSessionAnlegen } from '@/lib/supabase/slotplan'
import { MeineEinsaetzePage } from './MeineEinsaetzePage'

const kind = (id: string, name: string, fach: string): MeinEinsatz['kinder'][number] => ({ student_id: id, name, klasse: 8, fach })
const einsatz = (datum: string, beginn: string, extra: Partial<MeinEinsatz> = {}): MeinEinsatz => ({
  datum, zeit_id: `z-${beginn}`, beginn, ende: '00:00', raum_id: 'r1', raum_name: 'ZZ Raum 1', heute: false, session_id: null, kinder: [], ...extra,
})

function Ort(): JSX.Element {
  return <p data-testid="ort">{useLocation().pathname}</p>
}

const zeige = (): void => {
  render(
    <MemoryRouter initialEntries={['/coach/einsaetze']}>
      <Routes>
        <Route path="/coach/einsaetze" element={<MeineEinsaetzePage />} />
        <Route path="*" element={<Ort />} />
      </Routes>
    </MemoryRouter>,
  )
}

beforeEach(() => {
  vi.mocked(terminSessionAnlegen).mockClear()
  daten.anlegen = { data: { session_id: 'neu-s', neu: true, ausgelassen: [] }, error: null }
  daten.einsaetze = [
    einsatz('2028-03-13', '15:00', { heute: true, kinder: [kind('k1', 'ZZ_Ada', 'Mathematik'), kind('k2', 'ZZ_Ben', 'Deutsch')] }),
    einsatz('2028-03-13', '16:00', { heute: true }),
    einsatz('2028-03-15', '17:00', { kinder: [kind('k3', 'ZZ_Cem', 'Englisch'), kind('k1', 'ZZ_Ada', 'Mathematik')] }),
  ]
})

describe('Meine Einsätze', () => {
  it('Seitenkopf mit Woche, Einsätzen und Kindern; Tage als Überschriften, heute markiert', async () => {
    zeige()
    expect(await screen.findByText('KW 11 · 3 Einsätze · 3 Kinder')).toBeTruthy()
    const tage = screen.getAllByRole('heading', { level: 2 }).map((h) => h.textContent)
    expect(tage).toEqual(['Montag, 13. Märzheute', 'Mittwoch, 15. März'])
  })

  it('„Session öffnen“ nur am Tag des Einsatzes, sonst der ruhige Satz', async () => {
    zeige()
    const heute = await screen.findByRole('region', { name: 'Einsatz 15:00, ZZ Raum 1' })
    expect(within(heute).getByRole('button', { name: 'Session öffnen' })).toBeTruthy()
    expect(within(heute).getByText('ZZ_Ada')).toBeTruthy()
    expect(within(heute).getAllByText('Kl. 8')).toHaveLength(2)
    expect(within(heute).getByText('Mathematik')).toBeTruthy()
    const spaeter = screen.getByRole('region', { name: 'Einsatz 17:00, ZZ Raum 1' })
    expect(within(spaeter).queryByRole('button')).toBeNull()
    expect(within(spaeter).getByText('Öffnen am Tag des Einsatzes')).toBeTruthy()
  })

  it('ein Einsatz ohne Kinder ist eine ruhige Zeile, keine Karte', async () => {
    zeige()
    const ruhig = await screen.findByTestId('einsatz-ruhig')
    expect(within(ruhig).getByText('Noch keine Kinder in deinem Raum.')).toBeTruthy()
    expect(screen.getAllByTestId('einsatz-karte')).toHaveLength(2)
  })

  it('„Session öffnen“ schreibt fest und führt in die Live-Sicht', async () => {
    zeige()
    const heute = await screen.findByRole('region', { name: 'Einsatz 15:00, ZZ Raum 1' })
    fireEvent.click(within(heute).getByRole('button', { name: 'Session öffnen' }))
    expect((await screen.findByTestId('ort')).textContent).toBe('/coach/session/neu-s/live')
    expect(terminSessionAnlegen).toHaveBeenCalledWith('2028-03-13', 'z-15:00', 'r1')
  })

  it('Fehler „nur am Tag“ erscheint übersetzt, nie als Rohtext', async () => {
    daten.anlegen = { data: null, error: 'raw db text', code: '22023', hint: 'nur_am_tag' }
    zeige()
    const heute = await screen.findByRole('region', { name: 'Einsatz 15:00, ZZ Raum 1' })
    fireEvent.click(within(heute).getByRole('button', { name: 'Session öffnen' }))
    expect((await screen.findByRole('alert')).textContent).toBe('Eine Session lässt sich nur am Tag des Termins öffnen.')
    expect(screen.queryByText('raw db text')).toBeNull()
  })

  it('leer: einladender EmptyState', async () => {
    daten.einsaetze = []
    zeige()
    expect(await screen.findByText('Diese Woche hast du keine Einsätze.')).toBeTruthy()
  })
})
