// tools/eltern-konten-entfernen.mjs (K1b): Planung und Bericht ohne Netz und ohne DB.
// Geprüft: Abbruch bei echtem Kind, bei Profil ohne students-Zeile und bei blockierenden
// Fremdbezügen; der Bericht nennt nur Anzahlen, nie Adressen oder IDs.

import { describe, expect, it } from 'vitest'
import { bericht, planen } from '../tools/eltern-konten-entfernen.mjs'

const P1 = '11111111-0000-4000-8000-000000000001'
const P2 = '11111111-0000-4000-8000-000000000002'
const P3 = '11111111-0000-4000-8000-000000000003'

describe('planen', () => {
  it('nur Testkinder und keine Fremdbezüge: löschen erlaubt, Zahlen stimmen', () => {
    const p = planen({
      eltern: [P1, P2, P3],
      links: [
        { parent: P1, istTest: true },
        { parent: P1, istTest: true },
        { parent: P2, istTest: true },
      ],
      blockierend: 0,
    })
    expect(p.abbruch).toBe(false)
    expect(p.zahlen).toEqual({
      eltern: 3,
      elternMitKind: 2,
      parentStudent: 3,
      kinderTest: 3,
      kinderEcht: 0,
      kinderOhneSchuelerzeile: 0,
      blockierend: 0,
    })
  })

  it('ein echtes Kind: Abbruch', () => {
    const p = planen({ eltern: [P1, P2], links: [{ parent: P1, istTest: true }, { parent: P2, istTest: false }], blockierend: 0 })
    expect(p.abbruch).toBe(true)
    expect(p.gruende.join()).toContain('nicht ist_test')
  })

  it('Verknüpfung ohne students-Zeile: Abbruch (nicht als Test belegt)', () => {
    const p = planen({ eltern: [P1], links: [{ parent: P1, istTest: null }], blockierend: 0 })
    expect(p.abbruch).toBe(true)
    expect(p.gruende.join()).toContain('ohne students-Zeile')
  })

  it('blockierende Fremdbezüge: Abbruch', () => {
    const p = planen({ eltern: [P1], links: [], blockierend: 2 })
    expect(p.abbruch).toBe(true)
    expect(p.gruende.join()).toContain('Fremdschlüssel')
  })

  it('keine Eltern-Konten: nichts zu tun', () => {
    const p = planen({ eltern: [], links: [], blockierend: 0 })
    expect(p.abbruch).toBe(false)
    expect(bericht(p, 'dry-run')).toContain('Nichts zu tun.')
  })
})

describe('bericht', () => {
  it('nennt nur Anzahlen, keine IDs', () => {
    const p = planen({ eltern: [P1, P2], links: [{ parent: P1, istTest: true }], blockierend: 0 })
    const text = bericht(p, 'dry-run')
    expect(text).toContain('Konten mit Rolle parent:                 2')
    expect(text).toContain('parent_student-Zeilen:                   1')
    expect(text).toContain('--ausfuehren würde 1 parent_student-Zeilen und 2 Konten löschen.')
    for (const id of [P1, P2]) expect(text).not.toContain(id)
    expect(text).not.toMatch(/@/)
  })

  it('Abbruch steht mit Grund im Bericht', () => {
    const p = planen({ eltern: [P1], links: [{ parent: P1, istTest: false }], blockierend: 0 })
    expect(bericht(p, 'ausfuehren')).toContain('ABBRUCH — es wird nichts gelöscht')
  })
})
