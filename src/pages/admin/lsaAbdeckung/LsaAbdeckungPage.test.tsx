// FR-2 F2: Seite LSA-Abdeckung. Matrix mit Fokus oben, Kennzahlen, Paket-Detail mit „Lena prüft noch n“,
// Sammelfreigabe nur über pruef_sammel (Vorschau zählt, Ausführung meldet die Wirkung), Fokus schalten.

import { beforeEach, describe, expect, it, vi } from 'vitest'
import { fireEvent, render, screen, waitFor, within } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import '@/i18n'

vi.mock('@/context/AuthContext', () => ({ useAuthContext: () => ({ user: { id: 'a1' } }) }))
const m = vi.hoisted(() => ({
  abdeckung: vi.fn(), frisch: vi.fn(), skills: vi.fn(), liste: vi.fn(), fokus: vi.fn(), quartal: vi.fn(), sammel: vi.fn(),
}))
vi.mock('@/lib/supabase/lsaAbdeckung', () => ({
  getLsaAbdeckung: m.abdeckung, frischeLsaAbdeckung: m.frisch, getLsaPaketSkills: m.skills, getPruefZielListe: m.liste,
  setSchuleFokus: m.fokus, getFokusQuartal: m.quartal, getLsaWirkung: vi.fn(),
}))
vi.mock('@/lib/supabase/pruefungAdmin', () => ({ pruefSammel: m.sammel }))
vi.mock('@/lib/supabase/kaFolge', () => ({
  bestaetigeKaSchulArbeit: vi.fn(), listKaPlanThemen: vi.fn().mockResolvedValue({ data: [], error: null }),
  listKaSchulFolge: vi.fn().mockResolvedValue({ data: [], error: null }), schuljahrHeute: () => '2026/27',
}))

import type { LsaAbdeckungZeile, LsaPaketSkill, PruefZielZeile } from '@/types'
import { kennzahlen, matrix, wirkung } from './abdeckung'
import { LsaAbdeckungPage } from './LsaAbdeckungPage'

const paket = (p: Partial<LsaAbdeckungZeile>): LsaAbdeckungZeile => ({
  schule_id: 's1', schule: 'Albertus', fokus: false, klasse: 10, paket_nr: 1, thema_keys: ['potenzen'],
  thema_labels: ['Potenzen'], quelle: 'geschaetzt', datum: '2027-02-10', quartal: 3, lage: 0.5, ampel: 'rot',
  fehlende_pflicht_skills: 1, fehlende_skills: 3, fehlende_texte: 4, hat_einstieg: true, ...p,
})
const a1 = paket({})
const a2 = paket({ paket_nr: 2, thema_labels: ['Kreis'], ampel: 'gelb' })
const b1 = paket({ schule_id: 's2', schule: 'Zuse', fokus: true, ampel: 'gruen', quelle: 'bestaetigt' })
const skill = (s: Partial<LsaPaketSkill>): LsaPaketSkill => ({
  skill_key: 'dezimal_mult', skill_label: 'Dezimalzahlen multiplizieren', thema_label: 'Dezimalzahlen', fall: 'A',
  teil: 'tiefe', pflicht: false, erfuellt: false, texte_im_pool: 1, fehlende_texte: 1, vorschlaege: 1, ...s,
})
const ziel = (z: Partial<PruefZielZeile>): PruefZielZeile => ({
  abschnitt: 'gezielt', skill_key: 'dezimal_mult', skill_label: 'x', thema_key: null, thema_label: null,
  fehlende_texte: 1, rest: 0, hebel_pakete: 1, hebel_schulen: 1, fokus_treffer: 0, sort: 1, task_ids: [],
  freigabe_ids: ['t1', 't2'], pilot_fehlt: [], ...z,
})

beforeEach(() => {
  m.quartal.mockReset().mockResolvedValue(3)
  m.frisch.mockReset().mockResolvedValue({ data: false, error: null })
  m.abdeckung.mockReset().mockResolvedValue({ data: [a1, a2, b1], error: null })
  m.skills.mockReset().mockResolvedValue({
    data: [skill({}), skill({ skill_key: 'potenz_regel', skill_label: 'Potenzregeln', pflicht: true, teil: 'einstieg', vorschlaege: 2, fehlende_texte: 2 }),
      skill({ skill_key: 'vorzeichen', skill_label: 'Vorzeichen', erfuellt: true, vorschlaege: 0, fehlende_texte: 0 })],
    error: null,
  })
  m.liste.mockReset().mockResolvedValue({ data: [ziel({}), ziel({ abschnitt: 'nachpruefen', freigabe_ids: [] })], error: null })
  m.fokus.mockReset().mockResolvedValue({ data: null, error: null })
  m.sammel.mockReset().mockImplementation((_a: string, ids: string[], _w: unknown, vorschau: boolean) =>
    Promise.resolve({ data: { betrifft: vorschau ? ids : ['t1'], ausgelassen: [] }, error: null }))
})

const zeige = (): void => {
  render(<MemoryRouter><LsaAbdeckungPage /></MemoryRouter>)
}

describe('Rechnungen', () => {
  it('Kennzahlen, Matrix mit Fokus oben, Wirkung', () => {
    expect(kennzahlen([a1, a2, b1])).toEqual({ gruen: 1, gelb: 1, rot: 1, schulenBereit: 2, schulen: 2 })
    const mx = matrix([a2, a1, b1])
    expect(mx.spalten).toBe(2)
    expect(mx.zeilen.map((z) => z.schule)).toEqual(['Zuse', 'Albertus'])
    expect(mx.zeilen[1].zellen.map((z) => z?.paket_nr)).toEqual([1, 2])
    expect(wirkung([a1, b1], [{ ...a1, ampel: 'gelb' }, b1])).toEqual({ pakete: 1, schulen: 1 })
  })
})

describe('Seite', () => {
  it('lädt mit dem Quartal der Stellschraube und Klasse 10', async () => {
    zeige()
    await screen.findByText('Zuse')
    expect(m.abdeckung).toHaveBeenCalledWith({ klasse: 10, quartal: 3, nurFokus: false })
    expect(within(screen.getByTestId('kennzahlen')).getByText('2 von 2')).toBeTruthy()
  })

  it('Klick auf eine Zelle zeigt das Paket mit Lenas Restmenge (ohne Reserve, ohne erfüllte Skills)', async () => {
    zeige()
    fireEvent.click(await screen.findByTestId('zelle-s1:10:1'))
    expect(await screen.findByTestId('lena-satz')).toHaveTextContent('Lena prüft dafür noch 3 Aufgaben')
    expect(screen.getByText('Potenzregeln')).toBeTruthy()
  })

  it('Fokus schalten schreibt über setSchuleFokus und lädt neu', async () => {
    zeige()
    fireEvent.click(await screen.findByRole('button', { name: 'Albertus als Fokus-Schule markieren' }))
    await waitFor(() => expect(m.fokus).toHaveBeenCalledWith('s1', true))
    await waitFor(() => expect(m.abdeckung).toHaveBeenCalledTimes(2))
  })

  it('Alles Geprüfte freigeben: Zahl aus der Vorschau, Ausführung über pruef_sammel, Rückmeldung mit Wirkung', async () => {
    m.abdeckung.mockResolvedValueOnce({ data: [a1, a2, b1], error: null })
    zeige()
    const knopf = await screen.findByRole('button', { name: 'Alles Geprüfte freigeben (2)' })
    expect(m.sammel).toHaveBeenCalledWith('freigeben', ['t1', 't2'], {}, true)
    m.abdeckung.mockResolvedValueOnce({ data: [a1, a2, b1], error: null })
      .mockResolvedValueOnce({ data: [{ ...a1, ampel: 'gelb' }, a2, b1], error: null })
    fireEvent.click(knopf)
    await waitFor(() => expect(m.sammel).toHaveBeenCalledWith('freigeben', ['t1', 't2'], {}, false))
    expect(await screen.findByText('1 Aufgabe freigegeben, 1 Pakete jetzt grün oder gelb, an 1 Schulen')).toBeTruthy()
  })
})
