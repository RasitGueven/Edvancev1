import { describe, expect, it } from 'vitest'
import type { VertragAktuell } from '@/types'
import {
  auslaufende,
  buendelVollstaendig,
  imVerzug,
  naechsteStufe,
  passtZumFilter,
  summen,
  LEERER_FILTER,
} from './menue'

function v(over: Partial<VertragAktuell> & { id: string }): VertragAktuell {
  return {
    wirksamer_status: 'aktiv',
    laufzeit_monat: 3,
    ist_aktueller_vertrag: true,
    beitrag_diesen_monat_cents: 38990,
    zugangscode_gueltig: true,
    endet_in_tagen: 200,
    eltern_vorname: 'ZZ_Anna',
    eltern_nachname: 'Muster',
    kind_vorname: 'ZZ_Mia',
    kind_nachname: 'Muster',
    klasse: 8,
    tier_id: 't3',
    laufzeit_monate: 6,
    preis_cents: 38990,
    zahlungsstatus: 'in_ordnung',
    zahlungsstatus_seit: null,
    verlaengerung_status: null,
    wiedervorlage_am: null,
    ...over,
  } as VertragAktuell
}

describe('summen', () => {
  // Die Zeile addiert Spaltenwerte der Sicht. Sie leitet nichts ab — sonst
  // koennte auf dem Bildschirm etwas anderes stehen als im Vertrag.
  it('zaehlt nur laufende Vertraege und summiert deren Beitrag', () => {
    const s = summen([
      v({ id: 'a', wirksamer_status: 'aktiv', beitrag_diesen_monat_cents: 38990 }),
      v({ id: 'b', wirksamer_status: 'im_widerruf', beitrag_diesen_monat_cents: 26990 }),
      v({ id: 'c', wirksamer_status: 'ausgelaufen', beitrag_diesen_monat_cents: 19990 }),
      v({ id: 'd', wirksamer_status: 'widerrufen', beitrag_diesen_monat_cents: 19990 }),
      v({ id: 'e', wirksamer_status: 'gekuendigt', beitrag_diesen_monat_cents: 19990 }),
    ])
    expect(s).toEqual({ laufend: 2, davonPilot: 0, abbuchungCents: 65980, imWiderruf: 1 })
  })

  // Ein Halbjahresvertrag im achten Monat laeuft noch, kostet aber nichts. Die
  // Sicht liefert dafuer 0 — die Summe darf daraus keinen Beitrag erfinden.
  it('uebernimmt die 0 eines beitragsfreien Monats', () => {
    const s = summen([v({ id: 'a', beitrag_diesen_monat_cents: 0, laufzeit_monat: 8 })])
    expect(s).toEqual({ laufend: 1, davonPilot: 0, abbuchungCents: 0, imWiderruf: 0 })
  })

  it('ist bei leerer Liste dreimal null', () => {
    expect(summen([])).toEqual({ laufend: 0, davonPilot: 0, abbuchungCents: 0, imWiderruf: 0 })
  })
})

describe('naechsteStufe', () => {
  it('rueckt eine Stufe vor', () => {
    expect(naechsteStufe('in_ordnung')).toBe('zahlung_offen')
    expect(naechsteStufe('mahnung_1')).toBe('mahnung_2')
  })

  it('endet bei Inkasso', () => {
    expect(naechsteStufe('inkasso')).toBeNull()
  })
})

describe('passtZumFilter', () => {
  it('zeigt standardmaessig nur den aktuellen Vertrag je Kind', () => {
    expect(passtZumFilter(v({ id: 'a', ist_aktueller_vertrag: false }), LEERER_FILTER)).toBe(false)
    expect(
      passtZumFilter(v({ id: 'a', ist_aktueller_vertrag: false }), {
        ...LEERER_FILTER,
        nurAktuelle: false,
      }),
    ).toBe(true)
  })

  it('sucht ueber Vertragspartner und Kind', () => {
    const x = v({ id: 'a' })
    expect(passtZumFilter(x, { ...LEERER_FILTER, suche: 'mia' })).toBe(true)
    expect(passtZumFilter(x, { ...LEERER_FILTER, suche: 'anna' })).toBe(true)
    expect(passtZumFilter(x, { ...LEERER_FILTER, suche: 'berta' })).toBe(false)
  })

  it('filtert ueber die Spaltenwerte', () => {
    const x = v({ id: 'a' })
    expect(passtZumFilter(x, { ...LEERER_FILTER, status: 'ausgelaufen' })).toBe(false)
    expect(passtZumFilter(x, { ...LEERER_FILTER, laufzeit: 12 })).toBe(false)
    expect(passtZumFilter(x, { ...LEERER_FILTER, laufzeit: 6 })).toBe(true)
    expect(passtZumFilter(x, { ...LEERER_FILTER, zahlungsstatus: 'mahnung_1' })).toBe(false)
  })
})

describe('auslaufende', () => {
  it('nimmt acht Wochen, naechstes Ende zuerst', () => {
    const liste = auslaufende([
      v({ id: 'spaet', endet_in_tagen: 50 }),
      v({ id: 'zu_spaet', endet_in_tagen: 57 }),
      v({ id: 'frueh', endet_in_tagen: 3 }),
      v({ id: 'vorbei', endet_in_tagen: -1 }),
    ])
    expect(liste.map((x) => x.id)).toEqual(['frueh', 'spaet'])
  })

  it('laesst abgehakte Vertraege verschwinden', () => {
    const liste = auslaufende([
      v({ id: 'offen', endet_in_tagen: 10 }),
      v({ id: 'keine', endet_in_tagen: 10, verlaengerung_status: 'keine_verlaengerung' }),
      v({ id: 'verlaengert', endet_in_tagen: 10, verlaengerung_status: 'verlaengert' }),
    ])
    expect(liste.map((x) => x.id)).toEqual(['offen'])
  })
})

describe('imVerzug', () => {
  it('zeigt alles ausser in_ordnung, laengster Verzug zuoberst', () => {
    const liste = imVerzug([
      v({ id: 'ok' }),
      v({ id: 'neu', zahlungsstatus: 'mahnung_1', zahlungsstatus_seit: '2026-09-20' }),
      v({ id: 'alt', zahlungsstatus: 'inkasso', zahlungsstatus_seit: '2026-07-01' }),
    ])
    expect(liste.map((x) => x.id)).toEqual(['alt', 'neu'])
  })
})

// V5 (Entscheidung 8): Pilotvereinbarungen zaehlen in keiner Kennzahl.
describe('Pilot in den Kennzahlen', () => {
  const pilot = v({
    id: 'pilot',
    vertragsart: 'pilot',
    tier_id: null,
    laufzeit_monate: null,
    preis_cents: 0,
    beitrag_diesen_monat_cents: 0,
  })

  it('summen zaehlt den Pilot als laufend (davon Pilot), aber nicht im Beitrag', () => {
    expect(summen([v({ id: 'a' }), pilot])).toEqual({ laufend: 2, davonPilot: 1, abbuchungCents: 38990, imWiderruf: 0 })
  })

  it('ein ausgelaufener Pilot zaehlt nicht als laufend', () => {
    expect(summen([{ ...pilot, wirksamer_status: 'ausgelaufen' }])).toMatchObject({ laufend: 0, davonPilot: 0 })
  })

  it('imVerzug laesst den Pilot aus, auch mit falschem Zahlungsstatus', () => {
    expect(imVerzug([{ ...pilot, zahlungsstatus: 'mahnung_1' }])).toEqual([])
  })

  it('das Buendel eines Pilots ist ohne SEPA-Mandat vollstaendig', () => {
    expect(buendelVollstaendig(['vertrag'], 'pilot')).toBe(true)
    expect(buendelVollstaendig(['vertrag'])).toBe(false)
    expect(buendelVollstaendig(['vertrag', 'sepa_mandat'])).toBe(true)
  })
})
