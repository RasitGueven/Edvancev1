import { describe, expect, it } from 'vitest'
import type { KindBuchbar } from '@/types/stundenplan'
import { gemischt, kinderSortiert, raeumeAktivAm } from './stundenplan.model'

const k = (id: string, name: string, code: KindBuchbar['code'], ist_test = false): KindBuchbar =>
  ({ student_id: id, name, klasse: null, ist_test, code, detail: null })

describe('Stundenplan-Logik (Slots S2)', () => {
  it('Räume aktiv am Tag: aktiv_ab einschließlich, inaktiv_ab ausschließlich', () => {
    const r = (id: string, aktiv_ab: string, inaktiv_ab: string | null) => ({ id, name: id, aktiv_ab, inaktiv_ab, stammschichten: 0 })
    const raeume = [r('B', '2027-01-01', null), r('A', '2027-11-04', '2027-11-05'), r('C', '2027-11-05', null), r('D', '2027-01-01', '2027-11-04')]
    expect(raeumeAktivAm(raeume, '2027-11-04').map((x) => x.id)).toEqual(['A', 'B'])
  })

  it('buchbare Kinder zuerst, dann nach Name; Suche ohne Groß-/Kleinschreibung', () => {
    const liste = [k('1', 'Zoe', 'ok'), k('2', 'Anna', 'kein_vertrag'), k('3', 'Ben', 'ok')]
    expect(kinderSortiert(liste, '').map((x) => x.name)).toEqual(['Ben', 'Zoe', 'Anna'])
    expect(kinderSortiert(liste, 'AN').map((x) => x.name)).toEqual(['Anna'])
  })

  it('gemischt: Testkonto und echtes Kind gewählt', () => {
    const liste = [k('e', 'Echt', 'ok'), k('t', 'Test', 'ok', true), k('t2', 'Test 2', 'ok', true)]
    expect(gemischt(liste, ['e', 't'])).toBe(true)
    expect(gemischt(liste, ['t', 't2'])).toBe(false)
    expect(gemischt(liste, [])).toBe(false)
  })
})
