// Slots SL2b, Test 6: Kennzeichen „Test“ an allen vier Stellen (Wochenplan, Termin, Kinder, Kind) und die
// Kennzahl „Belegt“ sagt, wie viele Testkonten sie nicht zählt. Daten: Ausgabe der Slot-Funktionen aus einer
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
const { TerminPage } = await import('./termin/TerminPage')
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
    await zeige('/', '/', <WochenZelle zelle={mitTest!} ziel="/x" />)
    expect(screen.getByText('Test')).toBeTruthy()
    expect(screen.getByRole('link').getAttribute('aria-label')).toContain('Test')
    document.body.innerHTML = ''
    await zeige('/', '/', <WochenZelle zelle={ohneTest!} ziel="/x" />)
    expect(screen.queryByText('Test')).toBeNull()
  })

  it('Wochenplan: Kopf „Belegt“ zählt nur echte Kinder und nennt die Testkonten', async () => {
    await zeige('/', '/', <WochenplanReiter woche={{ daten: woche, fehler: null, laedt: false } as never} montag={woche.montag} onWoche={() => {}} />)
    const testkonten = woche.zellen.reduce((s, z) => s + (z.test ?? 0), 0)
    expect(testkonten).toBeGreaterThan(0)
    expect(screen.getByText(`ohne ${testkonten} Testkonten`)).toBeTruthy()
    expect(screen.getByText(String(woche.kopf.belegt))).toBeTruthy()
  })

  it('Termin: jedes Testkonto im Raum trägt „Test“', async () => {
    sp.ladeTermin.mockResolvedValue({ data: terminTest, error: null })
    await zeige(`/admin/slots/termin/${terminTest.datum}/${terminTest.zeit.id}`, '/admin/slots/termin/:datum/:zeitId', <TerminPage />)
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
