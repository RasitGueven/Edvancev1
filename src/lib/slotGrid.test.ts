import { describe, expect, it } from 'vitest'
import { fillLevel, formatSlotTime, isFull, slotsAt, sortByFillFirst, timeRows } from './slotGrid'
import type { SlotWithLoad } from '@/types'

function slot(partial: Partial<SlotWithLoad> & { id: string }): SlotWithLoad {
  return {
    created_at: '2026-07-19T10:00:00Z',
    weekday: 0,
    start_time: '15:00:00',
    room: 'A',
    capacity: 5,
    active: true,
    belegt: 0,
    ...partial,
  }
}

describe('formatSlotTime', () => {
  it('kuerzt die Postgres-Sekunden weg', () => {
    expect(formatSlotTime('15:00:00')).toBe('15:00')
    expect(formatSlotTime('09:30')).toBe('09:30')
  })
})

describe('isFull / fillLevel', () => {
  it('erkennt den ausgebuchten Slot', () => {
    expect(isFull(slot({ id: 'a', belegt: 5, capacity: 5 }))).toBe(true)
    expect(isFull(slot({ id: 'b', belegt: 4, capacity: 5 }))).toBe(false)
  })

  it('stuft die Auslastung', () => {
    expect(fillLevel(slot({ id: 'a', belegt: 0 }))).toBe('empty')
    expect(fillLevel(slot({ id: 'b', belegt: 2 }))).toBe('filling')
    expect(fillLevel(slot({ id: 'c', belegt: 4 }))).toBe('almost')
    expect(fillLevel(slot({ id: 'd', belegt: 5 }))).toBe('full')
  })
})

describe('sortByFillFirst', () => {
  it('stellt vollere freie Slots nach vorn und ausgebuchte ans Ende', () => {
    const sorted = sortByFillFirst([
      slot({ id: 'leer', belegt: 0, room: 'A' }),
      slot({ id: 'voll', belegt: 5, room: 'B' }),
      slot({ id: 'fast', belegt: 4, room: 'C' }),
      slot({ id: 'halb', belegt: 2, room: 'D' }),
    ])
    expect(sorted.map((s) => s.id)).toEqual(['fast', 'halb', 'leer', 'voll'])
  })

  it('ist bei gleicher Auslastung stabil ueber den Raum', () => {
    const sorted = sortByFillFirst([
      slot({ id: 'z', belegt: 2, room: 'Z' }),
      slot({ id: 'a', belegt: 2, room: 'A' }),
    ])
    expect(sorted.map((s) => s.id)).toEqual(['a', 'z'])
  })
})

describe('timeRows', () => {
  it('liefert eindeutige Startzeiten aufsteigend', () => {
    const rows = timeRows([
      slot({ id: 'a', start_time: '17:00:00' }),
      slot({ id: 'b', start_time: '15:00:00' }),
      slot({ id: 'c', start_time: '15:00:00' }),
    ])
    expect(rows).toEqual(['15:00', '17:00'])
  })
})

describe('slotsAt', () => {
  it('filtert auf Wochentag und Uhrzeit', () => {
    const all = [
      slot({ id: 'mo15', weekday: 0, start_time: '15:00:00' }),
      slot({ id: 'di15', weekday: 1, start_time: '15:00:00' }),
      slot({ id: 'mo17', weekday: 0, start_time: '17:00:00' }),
    ]
    expect(slotsAt(all, 0, '15:00').map((s) => s.id)).toEqual(['mo15'])
  })
})
