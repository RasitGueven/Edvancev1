import { describe, expect, it } from 'vitest'
import type { InhalteReihe, InhalteThema } from '@/types/inhalte'
import {
  anteile, ansichtAusSuche, heuteIso, lsaReihenfolge, lenaListe, lsaKennzahlen, lsaSchritte, monate, reihenKennzahlen, reihenSchritte,
  sucheAusAnsicht,
} from './uebersicht'

const thema = (p: Partial<InhalteThema>): InhalteThema => ({
  thema_key: 't', titel: 'T', klasse: 9, quartal: 2, von: '2026-11-16', bis: '2027-01-20', komp_bereit: 0, komp_teil: 0,
  komp_offen: 0, pflicht_bereit: 0, pflicht_gesamt: 0, hat_einstieg: true, aufgaben_frei: 0, aufgaben_zur_freigabe: 0,
  aufgaben_zu_pruefen: 0, aufgaben_fehlen: 0, ampel: 'noch_nicht', schulen: 1, schulen_bestaetigt: 0, alle_zu_pruefen: 7, ...p,
})
const reihe = (p: Partial<InhalteReihe>): InhalteReihe => ({
  reihe: 'r', titel: 'R', thema_keys: [], klasse: 9, sessions: 7, quartal: 2, von: null, bis: null, bf_freigegeben: 0,
  bf_zur_freigabe: 0, bf_rueckfrage: 0, bf_offen: 0, bf_zu_pruefen: 0, vid_freigegeben: 0, vid_in_pruefung: 0,
  vid_fehlt: 0, vid_gesamt: 0, ampel: 'nicht_bereit', schulen: 0, schulen_bestaetigt: 0, ...p,
})

describe('Adresse', () => {
  it('liest Reiter, Klasse und Detail; Unsinn fällt auf die Standards', () => {
    expect(ansichtAusSuche(new URLSearchParams('reiter=reihen&klasse=9&reihe=x'))).toEqual(
      { reiter: 'reihen', klasse: 9, thema: null, ziel: null, reihe: 'x' })
    expect(ansichtAusSuche(new URLSearchParams('reiter=foo&klasse=7'))).toMatchObject({ reiter: 'lsa', klasse: null })
  })
  it('schreibt Reiter und Klasse mit, Detail nur wenn gesetzt', () => {
    expect(sucheAusAnsicht({ reiter: 'lsa', klasse: 10, thema: 'potenzen' }).toString()).toBe('reiter=lsa&klasse=10&thema=potenzen')
    expect(sucheAusAnsicht({ reiter: 'reihen', klasse: null }).toString()).toBe('reiter=reihen')
  })
})

describe('Kennzahlen', () => {
  it('zählt Ampeln; Lena-Zahl kommt aus alle_zu_pruefen (je Kompetenz einmal)', () => {
    expect(lsaKennzahlen([thema({ ampel: 'vollstaendig' }), thema({ ampel: 'eingeschraenkt' }), thema({})])).toEqual(
      { vollstaendig: 1, eingeschraenkt: 1, nochNicht: 1, zuPruefen: 7 })
    expect(lsaKennzahlen([]).zuPruefen).toBe(0)
  })
  it('Reihen: in Arbeit umfasst nicht bereit', () => {
    expect(reihenKennzahlen([reihe({ ampel: 'bereit' }), reihe({}), reihe({ ampel: 'in_arbeit' })], 20)).toEqual(
      { bereit: 1, inArbeit: 2, inPlanung: 0, ohneReihe: 20 })
  })
})

describe('Nächste Schritte', () => {
  it('Lena, Admin, fehlende Aufgaben in dieser Reihenfolge, mit Sprungziel', () => {
    expect(lsaSchritte({ aufgaben_zu_pruefen: 3, aufgaben_zur_freigabe: 2, aufgaben_fehlen: 1 }, 'msa_zp10')).toEqual([
      { wer: 'lena', art: 'lenaPrueft', anzahl: 3, ziel: '/coach/pruefen?ziel=msa_zp10' },
      { wer: 'admin', art: 'adminGibtFrei', anzahl: 2, ziel: '/admin/lsa-abdeckung' },
      { wer: 'neu', art: 'aufgabenFehlen', anzahl: 1, ziel: null },
    ])
    expect(lsaSchritte({ aufgaben_zu_pruefen: 0, aufgaben_zur_freigabe: 0, aufgaben_fehlen: 0 })[0].wer).toBe('keiner')
  })
  it('Reihen: Bauformen prüfen, freigeben, Videos', () => {
    expect(reihenSchritte(reihe({ bf_zu_pruefen: 47, vid_fehlt: 9 })).map((s) => [s.wer, s.anzahl, s.ziel])).toEqual([
      ['lena', 47, '/coach/pruefen/bauformen'], ['studio', 9, '/admin/studio']])
  })
  it('Lenas Liste mit Kompetenz', () => {
    expect(lenaListe({ skill: 'potenzen' })).toBe('/coach/pruefen?skill=potenzen')
    expect(lenaListe()).toBe('/coach/pruefen')
  })
})

describe('Anzeige', () => {
  it('Monate in Europe/Berlin', () => {
    expect(monate('2026-11-16', '2027-01-20', 'de')).toEqual({ von: 'Nov', bis: 'Jan', einMonat: false })
    expect(monate('2027-03-02', '2027-03-28', 'de')).toEqual({ von: 'März', bis: 'März', einMonat: true })
    expect(monate(null, '2027-01-20', 'de')).toBeNull()
  })
  it('Anteile summieren auf 100, leer ist 0', () => {
    expect(anteile([1, 1, 2])).toEqual([25, 25, 50])
    expect(anteile([0, 0])).toEqual([0, 0])
  })
})

describe('IU-1b Reihenfolge', () => {
  it('laufende und kommende zuerst (Quartal, dann Schulen), vorbei ans Ende', () => {
    const t = (key: string, quartal: number, schulen: number, bis: string | null) => ({ key, quartal, schulen, bis })
    const r = lsaReihenfolge([t('alt', 1, 30, '2026-10-20'), t('q3', 3, 5, '2027-03-01'), t('jetzt', 1, 2, '2026-11-20'),
      t('q2', 2, 27, '2027-01-10'), t('ohne', 2, 30, null)], '2026-11-13')
    expect(r.laufend.map((x) => x.key)).toEqual(['jetzt', 'ohne', 'q2', 'q3'])
    expect(r.vorbei.map((x) => x.key)).toEqual(['alt'])
  })
  it('heute in Europe/Berlin', () => {
    expect(heuteIso(new Date('2026-11-13T23:30:00Z'))).toBe('2026-11-14')
  })
})
