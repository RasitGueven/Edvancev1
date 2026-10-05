// Admin-Pruefansicht, reine Logik: Reihe (naechste, vorige, Ende, direkter Link ohne Reihe), Herkunft
// „Lena“/„Team“ je Aenderung und die Uebersetzung aller Auslass-Gruende und HINTs.

import { beforeEach, describe, expect, it } from 'vitest'
import i18n from '@/i18n'
import type { PruefAenderung } from '@/types'
import { ADMIN_HINWEISE, AUSLASS_GRUENDE, adminFehler, auslassText, nachGrund, uebersetze } from './adminTexte'
import { herkunftVon } from './herkunft'
import {
  leseReihe, naechste, neueReihe, position, reiheDerUebersprungenen, reiheFuer, speichereReihe, vergissReihe,
  vermerke, vorige,
} from './reihe'

describe('Reihe', () => {
  beforeEach(() => sessionStorage.clear())
  const r = neueReihe(['a', 'b', 'c', 'b'], 'liste', 'Expertenliste · Filter: Rückfrage', '/admin/authoring/liste')

  it('entfernt doppelte IDs und kennt naechste und vorige', () => {
    expect(r.ids).toEqual(['a', 'b', 'c'])
    expect(naechste(r, 'a')).toBe('b')
    expect(vorige(r, 'b')).toBe('a')
    expect(vorige(r, 'a')).toBeNull()
  })

  it('liefert am Ende null (Abschlussseite)', () => {
    expect(naechste(r, 'c')).toBeNull()
    expect(position(r, 'c')).toEqual({ nr: 3, anzahl: 3 })
  })

  it('ein direkter Link ohne Reihe oeffnet die einzelne Aufgabe', () => {
    expect(reiheFuer(leseReihe(), 'x')).toBeNull()
    speichereReihe(r)
    expect(reiheFuer(leseReihe(), 'x')).toBeNull()
    expect(position(reiheFuer(leseReihe(), 'x'), 'x')).toBeNull()
    expect(reiheFuer(leseReihe(), 'b')?.ids).toEqual(['a', 'b', 'c'])
    vergissReihe()
    expect(leseReihe()).toBeNull()
  })

  it('haelt je Aufgabe nur die letzte Entscheidung fest und baut die Reihe der Uebersprungenen', () => {
    let x = vermerke(r, 'a', 'uebersprungen')
    x = vermerke(x, 'c', 'uebersprungen')
    x = vermerke(x, 'a', 'freigegeben')
    expect(x.ergebnis).toEqual({ freigegeben: ['a'], anLena: [], zurueckgewiesen: [], uebersprungen: ['c'] })
    expect(reiheDerUebersprungenen(x).ids).toEqual(['c'])
  })

  it('verwirft einen kaputten Speicherstand', () => {
    sessionStorage.setItem('edvance.adminPruefReihe', '{"ids": []}')
    expect(leseReihe()).toBeNull()
    sessionStorage.setItem('edvance.adminPruefReihe', 'kein json')
    expect(leseReihe()).toBeNull()
  })
})

describe('Herkunft je Aenderung', () => {
  const lena: PruefAenderung[] = [
    { feld: 'richtige_antwort', teil: 1, vorher: ['3'], nachher: ['3', '+3'] },
    { feld: 'anforderungsbereich', teil: null, vorher: 'I', nachher: 'II' },
  ]

  it('markiert „Lena“, wenn Feld, Teil und nachher in Lenas letzter Entscheidung stehen', () => {
    expect(herkunftVon({ feld: 'richtige_antwort', teil: 1, vorher: ['3'], nachher: ['3', '+3'] }, lena)).toBe('lena')
    expect(herkunftVon({ feld: 'anforderungsbereich', teil: null, vorher: 'I', nachher: 'II' }, lena)).toBe('lena')
  })

  it('markiert „Team“ bei anderem nachher, anderem Teil oder ohne Lena-Entscheidung', () => {
    expect(herkunftVon({ feld: 'anforderungsbereich', teil: null, vorher: 'I', nachher: 'III' }, lena)).toBe('team')
    expect(herkunftVon({ feld: 'richtige_antwort', teil: 2, vorher: ['3'], nachher: ['3', '+3'] }, lena)).toBe('team')
    expect(herkunftVon({ feld: 'fertigkeit', teil: null, vorher: 'a', nachher: 'b' }, null)).toBe('team')
  })

  it('gleicht Unicode-Minus und Reihenfolge der Fehlerwerte an', () => {
    const l: PruefAenderung[] = [{ feld: 'typischer_fehler', teil: null, vorher: null,
      nachher: { slug: 'vz', text: 'Minus vergessen', werte: [{ teil: null, wert: '−3' }, { teil: null, wert: '3' }] } }]
    expect(herkunftVon({ feld: 'typischer_fehler', teil: null, vorher: null,
      nachher: { slug: 'vz', text: 'Minus vergessen', werte: [{ teil: null, wert: '3' }, { teil: null, wert: '-3' }] } }, l)).toBe('lena')
  })
})

describe('Uebersetzung der Auslass-Gruende und HINTs', () => {
  const t = i18n.t.bind(i18n) as (k: string, o?: Record<string, unknown>) => string

  it('jeder Auslass-Grund hat einen Text', () => {
    for (const g of AUSLASS_GRUENDE) {
      expect(i18n.exists(`pruefenAdmin:ausgelassen.${g}`), g).toBe(true)
    }
  })

  it('jeder neue HINT hat einen Text', () => {
    for (const h of ADMIN_HINWEISE) {
      expect(i18n.exists(`pruefenAdmin:fehler.${h}`), h).toBe(true)
      expect(uebersetze(t, adminFehler({ code: 'ED422', hint: h, message: '' })!)).not.toContain('fehler.')
    }
  })

  it('setzt den Ausschluss-Grund uebersetzt ein, auch „von Hand“', () => {
    expect(uebersetze(t, auslassText({ grund: 'nicht_bei_lena', text: 'vera8' }))).toBe('nicht bei Lena (VERA-8)')
    expect(uebersetze(t, auslassText({ grund: 'schon_ausgeschlossen', text: 'hand' }))).toBe('schon nicht bei Lena (von Hand herausgenommen)')
    expect(uebersetze(t, auslassText({ grund: 'befund', text: 'Stoffanker fehlt' }))).toBe('Befund vor der Freigabe: Stoffanker fehlt')
  })

  it('uebersetzt einen HINT als Grund und faellt sonst auf „Fehler“ zurueck', () => {
    expect(uebersetze(t, auslassText({ grund: 'regel_ungueltig', text: 'x' }))).toBe(t('pruefen:fehlermeldung.regel_ungueltig'))
    expect(uebersetze(t, auslassText({ grund: 'unbekannt', text: 'kaputt' }))).toBe('Fehler: kaputt')
    expect(adminFehler({ code: 'P0001', hint: null, message: 'task_status_set: Stoffanker fehlt' })).toEqual({ text: 'Stoffanker fehlt' })
    expect(uebersetze(t, auslassText({ grund: 'befund', text: 'task_status_set: Cluster fehlt' }))).toBe('Befund vor der Freigabe: Cluster fehlt')
  })

  it('gruppiert Ausgelassene nach Grund', () => {
    const g = nachGrund([
      { task_id: 'a', grund: 'geaendert', text: null }, { task_id: 'b', grund: 'rueckfrage_offen', text: null },
      { task_id: 'c', grund: 'geaendert', text: null },
    ])
    expect(g).toEqual([{ grund: 'geaendert', text: null, ids: ['a', 'c'] }, { grund: 'rueckfrage_offen', text: null, ids: ['b'] }])
  })
})
