// tools/eltern-konten-entfernen.mjs (K1b): Planung und Bericht ohne Netz und ohne DB.
// Geprüft: Abbruch bei echtem Kind, bei Profil ohne students-Zeile und bei blockierenden
// Fremdbezügen; der Bericht nennt nur Anzahlen, nie Adressen oder IDs. lauf() mit eingespritzten
// Effekten: Bei jedem Abbruch, bei einem Lesefehler und bei abweichendem Projekt wird nichts gelöscht.

import { describe, expect, it, vi } from 'vitest'
import { bericht, lauf, planen, type Bestand, type Konten } from '../tools/eltern-konten-entfernen.mjs'

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
      cascade: 0,
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

describe('lauf', () => {
  const sauber: Bestand = { eltern: [P1, P2], links: [{ parent: P1, istTest: true }], blockierend: 0, cascade: 0 }

  function konten(pruefung: Record<string, 'parent' | 'fehlt' | 'andere_rolle'> = {}): Konten & {
    verknuepfungenLoeschen: ReturnType<typeof vi.fn>
    kontoLoeschen: ReturnType<typeof vi.fn>
  } {
    return {
      pruefen: vi.fn(async (id: string) => pruefung[id] ?? 'parent'),
      verknuepfungenLoeschen: vi.fn(async () => {}),
      kontoLoeschen: vi.fn(async () => {}),
    }
  }

  it('dry-run löscht nie', async () => {
    const k = konten()
    const r = await lauf({ modus: 'dry-run', lesen: () => sauber, konten: k, log: () => {} })
    expect(r).toEqual({ geloescht: 0, abbruch: false })
    expect(k.verknuepfungenLoeschen).not.toHaveBeenCalled()
    expect(k.kontoLoeschen).not.toHaveBeenCalled()
  })

  it('ausfuehren: erst parent_student, dann jedes Konto', async () => {
    const k = konten()
    const r = await lauf({ modus: 'ausfuehren', lesen: () => sauber, konten: k, log: () => {} })
    expect(r).toEqual({ geloescht: 2, abbruch: false })
    expect(k.verknuepfungenLoeschen).toHaveBeenCalledWith([P1, P2])
    expect(k.kontoLoeschen.mock.calls.map((c) => c[0])).toEqual([P1, P2])
    expect(k.verknuepfungenLoeschen.mock.invocationCallOrder[0]).toBeLessThan(k.kontoLoeschen.mock.invocationCallOrder[0])
  })

  it.each([
    ['echtes Kind', { ...sauber, links: [{ parent: P1, istTest: false }] }],
    ['Profil ohne students-Zeile', { ...sauber, links: [{ parent: P1, istTest: null }] }],
    ['blockierender Fremdbezug', { ...sauber, blockierend: 1 }],
  ])('Abbruch (%s): nichts gelöscht', async (_fall, bestand) => {
    const k = konten()
    const r = await lauf({ modus: 'ausfuehren', lesen: () => bestand as Bestand, konten: k, log: () => {} })
    expect(r.abbruch).toBe(true)
    expect(k.verknuepfungenLoeschen).not.toHaveBeenCalled()
    expect(k.kontoLoeschen).not.toHaveBeenCalled()
  })

  it('echtes Kind taucht zwischen erstem und zweitem Lesen auf: nichts gelöscht', async () => {
    const k = konten()
    const lesen = vi.fn().mockReturnValueOnce(sauber).mockReturnValue({ ...sauber, links: [{ parent: P2, istTest: false }] })
    const r = await lauf({ modus: 'ausfuehren', lesen, konten: k, log: () => {} })
    expect(r.abbruch).toBe(true)
    expect(k.kontoLoeschen).not.toHaveBeenCalled()
  })

  it('Lesefehler: wirft, nichts gelöscht', async () => {
    const k = konten()
    const lesen = () => {
      throw new Error('dbread fehlgeschlagen (Exit 2)')
    }
    await expect(lauf({ modus: 'ausfuehren', lesen, konten: k, log: () => {} })).rejects.toThrow('dbread')
    expect(k.verknuepfungenLoeschen).not.toHaveBeenCalled()
    expect(k.kontoLoeschen).not.toHaveBeenCalled()
  })

  it.each(['fehlt', 'andere_rolle'] as const)('Konto über die Admin-API %s (anderes Projekt): nichts gelöscht', async (stand) => {
    const k = konten({ [P2]: stand })
    const zeilen: string[] = []
    const r = await lauf({ modus: 'ausfuehren', lesen: () => sauber, konten: k, log: (z) => zeilen.push(z) })
    expect(r.abbruch).toBe(true)
    expect(zeilen.join()).toContain('anderes Projekt')
    expect(k.verknuepfungenLoeschen).not.toHaveBeenCalled()
    expect(k.kontoLoeschen).not.toHaveBeenCalled()
  })

  it('ohne Schreibrechte: Abbruch, nichts gelöscht', async () => {
    const r = await lauf({ modus: 'ausfuehren', lesen: () => sauber, konten: null, log: () => {} })
    expect(r).toEqual({ geloescht: 0, abbruch: true })
  })
})
