// Slots SL2b, Test 6: Kennzeichen „Test“ an allen vier Stellen (Wochenplan, Slot-Panel, Kinder, Kind) und die
// Kennzahl „Belegt“ nennt die Testkonten getrennt (W2, Entscheidung 7). Daten: Ausgabe der Slot-Funktionen aus einer
// Wegwerf-DB (sl2b.fixture.json, erfundene Namen).

import { beforeEach, describe, expect, it, vi } from 'vitest'
import { act, render, screen, within } from '@testing-library/react'
import { MemoryRouter, Route, Routes } from 'react-router-dom'
import '@/i18n'
import type { SlotsKind, SlotsKinderZeile, SlotsTermin, SlotsWoche } from '@/types/slotplan'
import fixture from './sl2b.fixture.json'

const sp = vi.hoisted(() => ({ ladeTermin: vi.fn(), ladeKinder: vi.fn(), ladeKind: vi.fn() }))
vi.mock('@/lib/supabase/slotplan', () => sp)

const { WochenZelle } = await import('./wochenplan/WochenZelle')
const { WochenplanReiter } = await import('./wochenplan/WochenplanReiter')
const { SlotPanel } = await import('./panel/SlotPanel')
const { KinderReiter } = await import('./kinder/KinderReiter')
const { KindPage } = await import('./kind/KindPage')

const woche = fixture.woche as unknown as SlotsWoche
const terminTest = fixture.termin_test as unknown as SlotsTermin
const kinder = fixture.kinder as unknown as SlotsKinderZeile[]
const kindTest = fixture.kind_test as unknown as SlotsKind

async function zeige(pfad: string, muster: string, element: JSX.Element): Promise<void> {
  render(
    <MemoryRouter initialEntries={[pfad]}>
      <Routes>
        <Route path={muster} element={element} />
      </Routes>
    </MemoryRouter>,
  )
  await act(async () => {})
}

beforeEach(() => {
  sp.ladeTermin.mockReset()
  sp.ladeKinder.mockReset()
  sp.ladeKind.mockReset()
})

describe('Testkonten in den Slots (SL2b)', () => {
  it('Wochenplan: Zelle mit Testkonten trägt „Test“, Zellen ohne nicht', async () => {
    const mitTest = woche.zellen.find((z) => (z.test ?? 0) > 0)
    const ohneTest = woche.zellen.find((z) => (z.test ?? 0) === 0 && z.belegt > 0)
    expect(mitTest && ohneTest).toBeTruthy()
    await zeige('/', '/', <WochenZelle zelle={mitTest!} onOeffnen={() => {}} />)
    expect(screen.getByText('Test')).toBeTruthy()
    expect(screen.getByRole('button').getAttribute('aria-label')).toContain('Test')
    document.body.innerHTML = ''
    await zeige('/', '/', <WochenZelle zelle={ohneTest!} onOeffnen={() => {}} />)
    expect(screen.queryByText('Test')).toBeNull()
  })

  it('Wochenplan (W2, Entscheidung 7): Kopf „Belegt“ zählt Testkonten sichtbar mit und nennt sie getrennt', async () => {
    const testkonten = woche.zellen.reduce((s, z) => s + (z.test ?? 0), 0)
    expect(testkonten).toBeGreaterThan(0)
    // Die Fixture stammt aus SL2b; die W1-Felder des Kopfs ergänzt der Test aus den Zellen.
    const w1 = { ...woche, kopf: { ...woche.kopf, belegt_test: testkonten, auslastung_mit_test: null, ohne_stammplatz_test: 0, raeume_ohne_coach: 0 } }
    const leer = { daten: null, fehler: null, laedt: false } as never
    await zeige('/', '/', <WochenplanReiter woche={{ daten: w1, fehler: null, laedt: false } as never} einzel={leer} montag={woche.montag} onWoche={() => {}} onPanel={() => {}} />)
    expect(screen.getByText(`${woche.kopf.belegt} Kinder · ${testkonten} ${testkonten === 1 ? 'Testkonto' : 'Testkonten'}`)).toBeTruthy()
    expect(screen.getByText(String(woche.kopf.belegt + testkonten))).toBeTruthy()
  })

  it('Termin: jedes Testkonto im Raum trägt „Test“', async () => {
    sp.ladeTermin.mockResolvedValue({ data: terminTest, error: null })
    await zeige('/', '/', <SlotPanel datum={terminTest.datum} zeitId={terminTest.zeit.id} einzel={[]} onPanel={() => {}} onClose={() => {}} onGeaendert={() => {}} />)
    const kinderImRaum = terminTest.raeume.flatMap((r) => r.kinder)
    expect(kinderImRaum.length).toBeGreaterThan(0)
    expect(kinderImRaum.every((k) => k.ist_test)).toBe(true)
    expect(screen.getAllByText('Test')).toHaveLength(kinderImRaum.length)
  })

  it('Kinder: das Testkonto trägt „Test“, das echte Kind nicht', async () => {
    sp.ladeKinder.mockResolvedValue({ data: kinder, error: null })
    await zeige('/admin/slots', '/admin/slots', <KinderReiter />)
    const zeile = (name: string): HTMLElement => screen.getAllByText(name)[0].closest('li, tr, article') as HTMLElement
    expect(within(zeile('Test Anton')).getByText('Test')).toBeTruthy()
    expect(within(zeile('Mila Schröder')).queryByText('Test')).toBeNull()
  })

  it('Kind: Kennzeichen und Satz unter dem Kopf', async () => {
    sp.ladeKind.mockResolvedValue({ data: kindTest, error: null })
    await zeige(`/admin/slots/kind/${kindTest.kind.student_id}`, '/admin/slots/kind/:studentId', <KindPage />)
    expect(screen.getByText('Test')).toBeTruthy()
    expect(screen.getByText(/Testkonto\. Es zählt in den Kennzahlen nicht mit/)).toBeTruthy()
  })
})
