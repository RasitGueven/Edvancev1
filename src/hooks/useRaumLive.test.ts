// F1 Test 4 (Trockenlauf 08.10., Befund A5): Die Abfrage der Live-Sicht ueberlappt nicht, und eine aeltere
// Antwort ueberschreibt nie eine neuere (langsame Quelle per Hand aufgeloest).

import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { act, renderHook } from '@testing-library/react'
import type { CoachLiveRaum } from '@/types/coachLive'
import type { SupabaseResult } from '@/types/ui'

type Offen = { resolve: (r: SupabaseResult<CoachLiveRaum>) => void }
const offen: Offen[] = []
const ladeRaumLive = vi.fn(
  () => new Promise<SupabaseResult<CoachLiveRaum>>((resolve) => offen.push({ resolve })),
)
vi.mock('@/lib/session/coachLive', () => ({ LIVE_ABFRAGE_MS: 4000, ladeRaumLive: () => ladeRaumLive() }))

import { useRaumLive } from './useRaumLive'

const raum = (stand: string): SupabaseResult<CoachLiveRaum> => ({ data: { stand } as CoachLiveRaum, error: null })

describe('F1 A5 useRaumLive', () => {
  beforeEach(() => {
    vi.useFakeTimers()
    offen.length = 0
    ladeRaumLive.mockClear()
  })
  afterEach(() => vi.useRealTimers())

  it('naechste Runde erst nach dem Ende der vorigen, dann im Takt', async () => {
    renderHook(() => useRaumLive('s1'))
    expect(ladeRaumLive).toHaveBeenCalledTimes(1)
    // Quelle braucht laenger als der Takt: kein zweiter Aufruf, solange der erste laeuft.
    await act(async () => { await vi.advanceTimersByTimeAsync(12_000) })
    expect(ladeRaumLive).toHaveBeenCalledTimes(1)
    await act(async () => { offen[0].resolve(raum('1')) })
    await act(async () => { await vi.advanceTimersByTimeAsync(3_999) })
    expect(ladeRaumLive).toHaveBeenCalledTimes(1)
    await act(async () => { await vi.advanceTimersByTimeAsync(1) })
    expect(ladeRaumLive).toHaveBeenCalledTimes(2)
  })

  it('eine aeltere Antwort ueberschreibt keine neuere', async () => {
    const { result } = renderHook(() => useRaumLive('s1'))
    // Runde 1 laeuft noch; der Coach handelt, neuLaden startet Abfrage 2.
    let fertig: Promise<void> = Promise.resolve()
    act(() => { fertig = result.current.neuLaden() })
    expect(ladeRaumLive).toHaveBeenCalledTimes(2)
    await act(async () => { offen[1].resolve(raum('neu')); await fertig })
    expect(result.current.raum?.stand).toBe('neu')
    await act(async () => { offen[0].resolve(raum('alt')) })
    expect(result.current.raum?.stand).toBe('neu')
  })

  it('nach dem Verlassen keine weitere Runde', async () => {
    const { unmount } = renderHook(() => useRaumLive('s1'))
    unmount()
    await act(async () => { offen[0].resolve(raum('1')); await vi.advanceTimersByTimeAsync(10_000) })
    expect(ladeRaumLive).toHaveBeenCalledTimes(1)
  })
})
