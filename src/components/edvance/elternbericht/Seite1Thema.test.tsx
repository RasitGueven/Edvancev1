// Bericht v2: Seite 1 und 2 zeigen nur direkt Geprüftes; themaSaetze (Präsentation) bleibt.
import { within } from '@testing-library/react'
import { describe, expect, it } from 'vitest'
import i18n from '@/i18n'
import { renderOhneFahrplan } from '@/test/elternberichtOhneFahrplan'

import { themaSaetze } from '@/components/edvance/elternbericht/themaSatz'
import de from '@/i18n/locales/de/elternbericht.json'
import { FAELLE } from '@/lib/report/elternbericht/fixtures'
import type { ReportData } from '@/types'

function bogen(data: ReportData) {
  const { container } = renderOhneFahrplan(data)
  const seite = (n: number): HTMLElement => container.querySelector<HTMLElement>(`.eb-seite[data-seite="${n}"]`)!
  return { container, seite, s1: within(seite(1)) }
}

const t = i18n.getFixedT('de', 'elternbericht')

describe('Seite 1 — kein Thema-Satz mehr (abgestufte LSA)', () => {
  it('abgestuft: weder Thema-Satz noch Zählung abgeleiteter Bereiche', () => {
    const { s1 } = bogen(FAELLE.abgestuft.data)
    expect(s1.queryByTestId('eb-thema-satz')).toBeNull()
    expect(s1.getByTestId('eb-geprueft').textContent).not.toMatch(/gehören|abgeleitet|ergeben sich|klären wir/)
  })

  it('der Prüftext ist für feste und abgestufte LSA derselbe Anfang', () => {
    const start = (d: ReportData): string =>
      bogen(d).s1.getByTestId('eb-geprueft').querySelector('.eb-s1-geprueft-text')!.textContent!.split('Klasse 5/6')[0]
    expect(start(FAELLE.abgestuft.data)).toBe(start(FAELLE.ilkay.data))
  })
})

describe('themaSaetze — alle Fassungen', () => {
  const a = (umfang: number, direkt: number, abgeleitet: number) => ({
    thema: 'Reelle Zahlen',
    umfang,
    direkt,
    abgeleitet,
    offen: umfang - direkt - abgeleitet,
    // Für den Satz ohne Belang (R7-8: nur Seite 2 nutzt sie).
    abgeleiteteSchluessel: [],
    abgeleiteteBereiche: [],
  })
  const satz = (...x: [number, number, number]): string => themaSaetze(t, a(...x)).join(' ')

  it('alle direkt', () => {
    expect(satz(4, 4, 0)).toBe('Zum Thema Reelle Zahlen gehören 4 Bereiche. Alle davon haben wir direkt geprüft.')
    expect(satz(1, 1, 0)).toBe('Zum Thema Reelle Zahlen gehört ein Bereich. Alle davon haben wir direkt geprüft.')
  })

  it('abgeleitet > 0, offen 0', () => {
    expect(satz(2, 1, 1)).toBe(
      'Zum Thema Reelle Zahlen gehören 2 Bereiche. Einen davon haben wir direkt geprüft, der übrige ergibt sich aus diesen Aufgaben.',
    )
  })

  it('abgeleitet > 0, offen > 0', () => {
    expect(satz(3, 1, 1)).toBe(
      'Zum Thema Reelle Zahlen gehören 3 Bereiche. Einen davon haben wir direkt geprüft, ein weiterer ergibt sich aus diesen Aufgaben. Einen Bereich klären wir in den ersten Sitzungen.',
    )
  })

  it('abgeleitet 0, offen > 0', () => {
    expect(satz(14, 6, 0)).toBe(
      'Zum Thema Reelle Zahlen gehören 14 Bereiche. 6 davon haben wir direkt geprüft. Die übrigen 8 klären wir in den ersten Sitzungen.',
    )
  })
})

describe('Seite 1 und 2 — nur Geprüftes', { timeout: 30_000 }, () => {
  const faelle = Object.entries(FAELLE).filter(([n]) => n !== 'ohneKatalog')

  it('kein Katalog-Nenner und kein „nicht untersucht“ in den Texten', () => {
    const texte = JSON.stringify({ s1: de.s1, s2: de.s2 })
    expect(texte).not.toMatch(/\{\{(katalog|offen|vorhanden)\}\}/)
    expect(texte).not.toMatch(/nicht untersucht/i)
  })

  it('kein Katalog-Nenner und kein „nicht untersucht“ auf den Seiten, für alle Fälle', () => {
    for (const [name, { data }] of faelle) {
      const { seite } = bogen(data)
      for (const n of [1, 2]) {
        const text = seite(n).textContent ?? ''
        expect(text, `${name} S.${n}`).not.toMatch(/nicht untersucht/i)
        expect(text, `${name} S.${n}`).not.toMatch(/von \d+ Bereich(?!en)/)
      }
    }
  })

  it('abgestufte LSA: Seite 2 zeigt keine Umrisse, nur ein farbiges Kästchen je direkt geprüftem Bereich', () => {
    for (const name of ['abgestuft', 'abgestuftMitOffen'] as const) {
      const { data } = FAELLE[name]
      const { seite } = bogen(data)
      const farbig = seite(2).querySelectorAll('.eb-s2-spur .eb-s2-segment-sicher, .eb-s2-spur .eb-s2-segment-uebung')
      expect(farbig, name).toHaveLength(data.erzaehlung.kompetenzen.length)
      expect(seite(2).querySelector('.eb-s2-segment-abgeleitet'), name).toBeNull()
      expect(seite(2).querySelector('.eb-s2-legende')?.textContent, name).toBe('SicherÜbungsbedarf')
    }
  })

  it('abgestuft: kein Schlüssel eines abgeleiteten Urteils und kein Label eines abgeleiteten Bereichs im Bogen', () => {
    const { data } = FAELLE.abgestuft
    const text = bogen(data).container.textContent ?? ''
    for (const key of data.erzaehlung.abgeleitet) expect(text, key).not.toContain(key)
    // Labels aus skills (dbread 20.10.2026) für die abgeleiteten Schlüssel im Raum.
    for (const label of ['Brüche kürzen', 'Dezimalzahlen dividieren', 'Potenzen und Quadratzahlen', 'Runden und Überschlag']) {
      expect(text, label).not.toContain(label)
    }
  })

  it('Seite 1 und 2 nennen dieselben Zahlen', () => {
    for (const [name, { data }] of faelle) {
      const { seite } = bogen(data)
      const zeile = seite(1).querySelector('.eb-s1-zeile')!.textContent!
      const [geprueft, sicher, uebung] = [...zeile.matchAll(/\d+/g)].map((m) => m[0])
      const zahlen = [...seite(2).querySelectorAll('.eb-s2-zahl')].map((z) => z.textContent)
      expect(zahlen, name).toEqual([sicher, uebung, geprueft])
      // Ein farbiges Kästchen je geprüftem Bereich: Profil-Summe = „Bereiche geprüft“.
      expect(
        String(seite(2).querySelectorAll('.eb-s2-spur .eb-s2-segment-sicher, .eb-s2-spur .eb-s2-segment-uebung').length),
        name,
      ).toBe(geprueft)
    }
  })
})
