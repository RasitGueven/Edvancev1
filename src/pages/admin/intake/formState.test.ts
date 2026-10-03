import { describe, expect, it } from 'vitest'
import { freigabeZustand } from './formState'

const basis = {
  klasse: 8,
  fach: 'Mathematik',
  einwilligung: true,
  aktuellesThema: null,
  altesCluster: null,
  katalogLeer: false,
}

describe('freigabeZustand', () => {
  it('mit Thema: direkt freigeben', () => {
    expect(freigabeZustand({ ...basis, aktuellesThema: 'reelle_zahlen' })).toBe('bereit')
  })

  it('ohne Thema: Bestaetigung noetig', () => {
    expect(freigabeZustand(basis)).toBe('bestaetigen')
  })

  it('Fach ohne Katalog (Deutsch/Englisch): keine Bestaetigung', () => {
    expect(freigabeZustand({ ...basis, fach: 'Deutsch', katalogLeer: true })).toBe('bereit')
  })

  it('Bestandslead mit altem Cluster: keine Bestaetigung', () => {
    expect(freigabeZustand({ ...basis, altesCluster: 'ZZ_cluster' })).toBe('bereit')
  })

  it('ohne Einwilligung, Klasse oder Fach: gesperrt', () => {
    expect(freigabeZustand({ ...basis, einwilligung: false })).toBe('gesperrt')
    expect(freigabeZustand({ ...basis, klasse: null })).toBe('gesperrt')
    expect(freigabeZustand({ ...basis, fach: null, aktuellesThema: 'x' })).toBe('gesperrt')
  })
})
