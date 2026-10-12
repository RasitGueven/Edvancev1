// Slots SL3: Modell der Coach-Einsätze (erfundene Daten).

import { describe, expect, it } from 'vitest'
import type { CoachingSession } from '@/types'
import type { MeinEinsatz } from '@/types/slotplan'
import { einsatzBeginnIso, einsatzVM, heuteEintraege, kinderZahl, nachTagen, naechsterBeginn } from './einsaetze.model'

const kind = (id: string, name: string, fach = 'Mathematik'): MeinEinsatz['kinder'][number] => ({ student_id: id, name, klasse: 8, fach })

const einsatz = (datum: string, beginn: string, raum: string, extra: Partial<MeinEinsatz> = {}): MeinEinsatz => ({
  datum, zeit_id: `z${beginn}`, beginn, ende: `${String(Number(beginn.slice(0, 2)) + 1).padStart(2, '0')}:00`, raum_id: raum,
  raum_name: `Raum ${raum}`, heute: false, session_id: null, kinder: [], ...extra,
})

const session = (id: string, scheduledAt: string, status: CoachingSession['status'] = 'upcoming'): CoachingSession =>
  ({ id, scheduled_at: scheduledAt, status, room: 'Raum 1', coach_id: 'c1' }) as CoachingSession

describe('nachTagen', () => {
  it('gruppiert nach Tagen, Tage und Uhrzeiten aufsteigend, heute markiert', () => {
    const tage = nachTagen([
      einsatz('2028-03-15', '17:00', '1'),
      einsatz('2028-03-13', '16:00', '1', { heute: true }),
      einsatz('2028-03-13', '15:00', '2', { heute: true }),
      einsatz('2028-03-15', '15:00', '1'),
    ])
    expect(tage.map((t) => t.datum)).toEqual(['2028-03-13', '2028-03-15'])
    expect(tage[0].heute).toBe(true)
    expect(tage[1].heute).toBe(false)
    expect(tage[0].einsaetze.map((e) => e.beginn)).toEqual(['15:00', '16:00'])
    expect(tage[1].einsaetze.map((e) => e.beginn)).toEqual(['15:00', '17:00'])
  })

  it('zählt jedes Kind der Woche einmal', () => {
    const k = kind('k1', 'ZZ_Ada')
    expect(kinderZahl([einsatz('2028-03-13', '15:00', '1', { kinder: [k] }), einsatz('2028-03-14', '15:00', '1', { kinder: [k, kind('k2', 'ZZ_Ben')] })])).toBe(2)
  })
})

describe('einsatzVM (Anforderung I 54)', () => {
  it('übernimmt keine Absage-, Vertrags- oder Planbilanz-Felder, auch wenn der Server sie liefern würde', () => {
    const roh = {
      ...einsatz('2028-03-13', '15:00', '1'),
      kinder: [{ ...kind('k1', 'ZZ_Ada'), zustand: 'cancelled', absage_eingang: '2028-03-13T07:00:00Z', paket: 'Basic', planbilanz: {} }],
      absagen: [{ termin_id: 't' }],
      vertrag: { paket: 'Basic' },
    } as unknown as MeinEinsatz
    const vm = einsatzVM(roh)
    expect(Object.keys(vm).sort()).toEqual(['beginn', 'datum', 'ende', 'heute', 'key', 'kinder', 'raum_id', 'raum_name', 'session_id', 'zeit_id'])
    expect(Object.keys(vm.kinder[0]).sort()).toEqual(['fach', 'klasse', 'name', 'student_id'])
    const text = JSON.stringify(vm)
    for (const verboten of ['absage', 'zustand', 'paket', 'vertrag', 'planbilanz', 'stammplatz', 'umgebucht']) {
      expect(text).not.toContain(verboten)
    }
  })
})

describe('heuteEintraege', () => {
  it('festgeschriebener Einsatz und seine Session stehen nur einmal da (als Session)', () => {
    const jetzt = '2026-10-12'
    const liste = heuteEintraege(
      [
        einsatz(jetzt, '15:00', '1', { heute: true, session_id: 's15' }),
        einsatz(jetzt, '16:00', '1', { heute: true }),
        einsatz('2026-10-13', '15:00', '1'),
      ],
      [session('s15', einsatzBeginnIso({ datum: jetzt, beginn: '15:00' })), session('einzel', einsatzBeginnIso({ datum: jetzt, beginn: '17:30' }))],
    )
    expect(liste.map((e) => (e.art === 'plan' ? `plan ${e.einsatz.beginn}` : `session ${e.session.id}`))).toEqual([
      'session s15',
      'plan 16:00',
      'session einzel',
    ])
  })

  it('festgeschriebener Einsatz ohne Session in der Liste bleibt als Plan sichtbar', () => {
    const liste = heuteEintraege([einsatz('2026-10-12', '15:00', '1', { heute: true, session_id: 'fremd' })], [])
    expect(liste).toHaveLength(1)
    expect(liste[0].art).toBe('plan')
  })
})

describe('naechsterBeginn', () => {
  const jetzt = Date.parse('2028-03-13T12:00:00Z')

  it('nimmt einen Slot-Termin, der noch nicht festgeschrieben ist', () => {
    const naechste = naechsterBeginn([einsatz('2028-03-14', '15:00', '1')], [session('alt', '2028-03-20T14:00:00Z')], jetzt)
    expect(naechste).toBe('2028-03-14T14:00:00.000Z')
  })

  it('erledigte und vergangene zählen nicht; ohne alles null', () => {
    expect(naechsterBeginn([einsatz('2028-03-13', '08:00', '1')], [session('x', '2028-03-14T10:00:00Z', 'done')], jetzt)).toBeNull()
  })
})
