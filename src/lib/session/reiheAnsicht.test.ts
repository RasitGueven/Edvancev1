import { describe, expect, it } from 'vitest'
import type { ReiheCoach, ReihePlan } from '@/types/reihe'
import { reiheAenderungen, reiheAnsicht } from './reiheAnsicht'

const ki = (skill: string, k: string) => ({ skill_key: skill, kernidee_key: k, stand: 'neu' as const, minuten: 12 })
const plan = (over: Partial<ReihePlan> = {}): ReihePlan => ({
  modus: 'klassenarbeit', ka_datum: '2027-03-02', sessions_bisher: 1,
  sessions: [
    { nr: 2, datum: '2027-01-18', art: 'normal', kernideen: [ki('p', 'K3'), ki('s', 'K1')], skills: ['p', 's'], transfer: false, minuten: 24 },
    { nr: 3, datum: '2027-01-25', art: 'generalprobe', kernideen: [], skills: ['p', 's'], transfer: true, minuten: 0 },
  ],
  warnung: { passt: false, sessions: 3, entfallen: [{ art: 'kernidee', skill_key: 'x', kernidee_key: 'K1' }, { art: 'transfer' }] },
  ...over,
})
const reihe = (p: ReihePlan): ReiheCoach => ({
  reihe_id: 'r', thema_keys: ['t'], ka_datum: '2027-03-02', plan: p, system: p, vorher: null, sessions_gesamt: 3,
  labels: { p: 'Parabel', s: 'Scheitel', x: 'Extremwerte' }, kernideen: { 'x.K1': 'Die Größe als Funktion' },
})

describe('reiheAnsicht', () => {
  it('Session des Tages, n von N, bis zur Arbeit, Entfallenes', () => {
    const a = reiheAnsicht(reihe(plan()), '2027-01-18')
    expect(a.nr).toBe(2)
    expect(a.gesamt).toBe(3)
    expect(a.bisArbeit).toBe(2)
    expect(a.entfallen).toEqual(['Die Größe als Funktion', 'transfer'])
    expect(a.passt).toBe(false)
  })
  it('ohne Datum kein „bis zur Arbeit“', () => {
    expect(reiheAnsicht(reihe(plan({ modus: 'rollierend' })), '2027-01-01').bisArbeit).toBeNull()
  })
})

describe('reiheAenderungen', () => {
  it('meldet verschobene und neue Kernideen', () => {
    const alt = plan({ sessions: [{ ...plan().sessions[0], kernideen: [ki('p', 'K3')] }, { ...plan().sessions[0], datum: '2027-01-25', kernideen: [ki('s', 'K1')] }] })
    expect(reiheAenderungen(plan(), alt)).toEqual([{ schluessel: 's.K1', von: '2027-01-25', nach: '2027-01-18' }])
  })
})
