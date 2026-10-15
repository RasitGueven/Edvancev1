import { describe, expect, it } from 'vitest'
import type { KindBuchbar, StundenplanSession } from '@/types/stundenplan'
import { gemischt, kinderSortiert, nachCoach, nachTag, raeumeAktivAm } from './stundenplan.model'

const s = (id: string, at: string, coach = 'c1'): StundenplanSession => ({
  session_id: id, scheduled_at: at, room: 'Raum 1', status: 'upcoming', testlauf: false, gestartet: false,
  coach_id: coach, coach_name: null, coach_rolle: 'coach', kinder: [],
})
const k = (id: string, name: string, code: KindBuchbar['code'], ist_test = false): KindBuchbar =>
  ({ student_id: id, name, klasse: null, ist_test, code, detail: null })

describe('Stundenplan-Logik (Slots S2)', () => {
  it('gruppiert nach Berliner Tag (23:30 UTC gehört zum Folgetag) und sortiert nach Beginn', () => {
    const tage = nachTag([s('b', '2027-11-04T15:00:00Z'), s('a', '2027-11-04T08:00:00Z'), s('c', '2027-11-04T23:30:00Z')])
    expect(tage.map((t) => [t.datum, t.sessions.map((x) => x.session_id)])).toEqual([
      ['2027-11-04', ['a', 'b']],
      ['2027-11-05', ['c']],
    ])
  })

  it('Coach-Filter: leer = alle', () => {
    const liste = [s('a', '2027-11-04T08:00:00Z', 'c1'), s('b', '2027-11-04T09:00:00Z', 'c2')]
    expect(nachCoach(liste, '')).toHaveLength(2)
    expect(nachCoach(liste, 'c2').map((x) => x.session_id)).toEqual(['b'])
  })

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
