import { describe, expect, it } from 'vitest'
import type { Lead, VertragMitLead } from '@/types'
import type { VertragFormState } from './vertragForm'
import { EMPTY_FILTERS } from '../leads/boardModel'
import {
  VERTRAG_ARCHIV,
  VERTRAG_COLUMNS,
  fehlendeAngaben,
  fehlendeFormAngaben,
  kindName,
  matchesVertragFilters,
  vertragFollowUp,
  vertraegeForColumn,
} from './vertragModel'

const lead = {
  id: 'l1',
  full_name: 'ZZ_Mia Muster',
  subjects: ['Mathematik'],
  class_level: 8,
} as Lead

function vertrag(over: Partial<VertragMitLead> & { id: string }): VertragMitLead {
  return {
    created_at: '2026-09-01T10:00:00.000Z',
    lead_id: 'l1',
    status: 'in_vorbereitung',
    in_vorbereitung_at: '2026-09-01T10:00:00.000Z',
    unterschrift_ausstehend_at: null,
    abgeschlossen_at: null,
    abgelehnt_at: null,
    abgelehnt_grund: null,
    abgelehnt_notiz: null,
    abschluss_weg: null,
    unterschrieben_am: null,
    student_id: null,
    schule_id: null,
    vorgaenger_id: null,
    vertrag_status: null,
    abgeschlossen_am: null,
    eingang_datum: null,
    vertrag_ende: null,
    ferientage: null,
    widerruf_bis: null,
    widerrufen_am: null,
    gekuendigt_zum: null,
    kuendigung_grund: null,
    zahlungsstatus: 'in_ordnung',
    zahlungsstatus_seit: null,
    offener_betrag_cents: null,
    verlaengerung_status: null,
    verlaengerung_grund: null,
    wiedervorlage_am: null,
    rueckmeldung_bis: null,
    abweichung_vermerk: null,
    zugangscode: null,
    zugangscode_erzeugt_am: null,
    zugangscode_gesperrt_am: null,
    scan_pfad: null,
    eltern_vorname: 'ZZ_Anna',
    eltern_nachname: 'Muster',
    strasse: 'Teststr.',
    hausnummer: '1',
    plz: '50667',
    ort: 'Köln',
    eltern_telefon: '0221 000000',
    eltern_email: 'zz@example.org',
    kind_vorname: 'ZZ_Mia',
    kind_nachname: 'Muster',
    kind_geburtsdatum: '2013-04-01',
    klasse: 8,
    fach: 'Mathematik',
    schule: null,
    laufzeit_monate: 12,
    tier_id: 't1',
    preis_cents: 26990,
    einheiten: 57,
    vertragsbeginn: '2026-10-01',
    kontoinhaber: 'ZZ_Anna Muster',
    iban_masked: 'DE** **** 3000',
    mandatsreferenz: 'EDV-2026-000001',
    glaeubiger_id: null,
    lead,
    ...over,
  }
}

describe('Spalten', () => {
  it('ordnet nach Status zu, abgelehnt nur ins Archiv', () => {
    const all = [
      vertrag({ id: 'a' }),
      vertrag({ id: 'b', status: 'unterschrift_ausstehend', unterschrift_ausstehend_at: '2026-09-10T10:00:00.000Z' }),
      vertrag({ id: 'c', status: 'abgelehnt', abgelehnt_at: '2026-09-10T10:00:00.000Z' }),
    ]
    const ids = VERTRAG_COLUMNS.map((col) => vertraegeForColumn(all, col, EMPTY_FILTERS).map((v) => v.id))
    expect(ids).toEqual([['a'], ['b'], []])
    expect(vertraegeForColumn(all, VERTRAG_ARCHIV, EMPTY_FILTERS).map((v) => v.id)).toEqual(['c'])
  })

  it('stellt den am laengsten wartenden Vertrag nach oben', () => {
    const all = [
      vertrag({ id: 'neu', in_vorbereitung_at: '2026-09-12T10:00:00.000Z' }),
      vertrag({ id: 'alt', in_vorbereitung_at: '2026-09-02T10:00:00.000Z' }),
    ]
    expect(vertraegeForColumn(all, VERTRAG_COLUMNS[0], EMPTY_FILTERS).map((v) => v.id)).toEqual([
      'alt',
      'neu',
    ])
  })
})

describe('matchesVertragFilters', () => {
  it('sucht in Kind- und Elternnamen und filtert Fach/Klasse', () => {
    const v = vertrag({ id: 'a' })
    expect(matchesVertragFilters(v, { ...EMPTY_FILTERS, query: 'anna' })).toBe(true)
    expect(matchesVertragFilters(v, { ...EMPTY_FILTERS, query: 'xyz' })).toBe(false)
    expect(matchesVertragFilters(v, { ...EMPTY_FILTERS, subject: 'Deutsch' })).toBe(false)
    expect(matchesVertragFilters(v, { ...EMPTY_FILTERS, classLevel: 8 })).toBe(true)
  })

  it('faellt ohne Vertragsdaten auf den Lead zurueck', () => {
    const v = vertrag({ id: 'a', kind_vorname: null, kind_nachname: null, fach: null, klasse: null })
    expect(kindName(v)).toBe('ZZ_Mia Muster')
    expect(matchesVertragFilters(v, { ...EMPTY_FILTERS, subject: 'Mathematik', classLevel: 8 })).toBe(true)
  })
})

describe('vertragFollowUp', () => {
  const now = new Date('2026-09-15T12:00:00.000Z')

  it('meldet sich nur in "Unterschrift ausstehend" ab 7 Tagen', () => {
    const offen = vertrag({
      id: 'a',
      status: 'unterschrift_ausstehend',
      unterschrift_ausstehend_at: '2026-09-08T12:00:00.000Z',
    })
    expect(vertragFollowUp(offen, now)).toBe(7)
    expect(vertragFollowUp({ ...offen, unterschrift_ausstehend_at: '2026-09-10T12:00:00.000Z' }, now)).toBeNull()
    expect(vertragFollowUp(vertrag({ id: 'b', in_vorbereitung_at: '2026-09-01T12:00:00.000Z' }), now)).toBeNull()
  })
})

describe('fehlendeAngaben', () => {
  it('ist leer bei vollstaendigen Daten mit IBAN', () => {
    expect(fehlendeAngaben(vertrag({ id: 'a' }), true)).toEqual([])
  })

  it('meldet leere Pflichtfelder und die fehlende IBAN', () => {
    const v = vertrag({ id: 'a', plz: ' ', tier_id: null })
    expect(fehlendeAngaben(v, false)).toEqual(['plz', 'tier_id', 'iban'])
  })

  // Alles ist Pflicht ausser diesen beiden — sie fehlen im Alltag oft und
  // wuerden sonst einen sonst vollstaendigen Vertrag aufhalten.
  it('verlangt weder Telefon noch Schule', () => {
    expect(
      fehlendeAngaben(vertrag({ id: 'a', schule: null, eltern_telefon: null }), true),
    ).toEqual([])
  })

  it('verlangt den Kontoinhaber', () => {
    expect(fehlendeAngaben(vertrag({ id: 'a', kontoinhaber: null }), true)).toEqual([
      'kontoinhaber',
    ])
  })
})

const vollesFormular: VertragFormState = {
  eltern_vorname: 'ZZ_Anna',
  eltern_nachname: 'Muster',
  strasse: 'Teststr',
  hausnummer: '1',
  plz: '50667',
  ort: 'Koeln',
  eltern_telefon: '',
  eltern_email: 'zz@edvance.invalid',
  kind_vorname: 'ZZ_Mia',
  kind_nachname: 'Muster',
  kind_geburtsdatum: '2012-05-04',
  fach: 'Mathematik',
  schule: '',
  schule_id: '',
  tier_id: 't3',
  vertragsbeginn: '2027-11-01',
  kontoinhaber: 'ZZ_Anna Muster',
  klasse: '8',
  laufzeit_monate: '6',
  iban: '',
}

describe('fehlendeFormAngaben', () => {
  it('ist zufrieden, wenn die IBAN schon hinterlegt ist', () => {
    expect(fehlendeFormAngaben(vollesFormular, true)).toEqual([])
  })

  // Der Grund fuer die zweite Funktion: der Knopf prueft das Getippte. Eine
  // frisch eingegebene IBAN zaehlt, auch wenn noch nichts gespeichert ist.
  it('nimmt eine neu eingetippte IBAN an', () => {
    expect(
      fehlendeFormAngaben({ ...vollesFormular, iban: 'DE89370400440532013000' }, false),
    ).toEqual([])
  })

  it('meldet die fehlende IBAN, wenn weder gespeichert noch getippt', () => {
    expect(fehlendeFormAngaben(vollesFormular, false)).toEqual(['iban'])
  })

  it('nennt leere Felder in der Reihenfolge der Pflichtliste', () => {
    const luecken = { ...vollesFormular, plz: '', tier_id: '', kontoinhaber: '   ' }
    expect(fehlendeFormAngaben(luecken, true)).toEqual(['plz', 'tier_id', 'kontoinhaber'])
  })

  it('haelt Telefon und Schule weiter fuer entbehrlich', () => {
    expect(
      fehlendeFormAngaben({ ...vollesFormular, eltern_telefon: '', schule: '', schule_id: '' }, true),
    ).toEqual([])
  })
})
