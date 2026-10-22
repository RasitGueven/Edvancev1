// R7-6: Seite 1 mit Thema-Satz, und auf Seite 1 und 2 nur noch Geprüftes.
import { render, within } from '@testing-library/react'
import { describe, expect, it } from 'vitest'
import i18n from '@/i18n'

import { ElternberichtBogen } from '@/components/edvance/elternbericht/Bogen'
import { themaSaetze } from '@/components/edvance/elternbericht/themaSatz'
import de from '@/i18n/locales/de/elternbericht.json'
import { elternLabel } from '@/lib/report/elternbericht/elternLabel'
import { FAELLE } from '@/lib/report/elternbericht/fixtures'
import { themaAbdeckungAus } from '@/lib/report/elternbericht/themaAbdeckung'
import type { ReportData } from '@/types'

function bogen(data: ReportData) {
  const { container } = render(<ElternberichtBogen data={data} notes={null} tiers={[]} />)
  const seite = (n: number): HTMLElement => container.querySelector<HTMLElement>(`.eb-seite[data-seite="${n}"]`)!
  return { container, seite, s1: within(seite(1)) }
}

const t = i18n.getFixedT('de', 'elternbericht')

describe('Seite 1 — Thema-Satz (abgestufte LSA mit Thema)', () => {
  it('abgestuft: Umfang, direkt, die übrigen ergeben sich; Hinweis auf direkt Geprüftes', () => {
    const kasten = bogen(FAELLE.abgestuft.data).s1.getByTestId('eb-geprueft')
    expect(kasten).toHaveTextContent(
      'Ausgehend vom Thema Reelle Zahlen hat das System je nach Antwort die nächste Aufgabe gewählt. So wurden 12 Bereiche gezielt geprüft.',
    )
    expect(within(kasten).getByTestId('eb-thema-satz').textContent).toBe(
      'Zum Thema Reelle Zahlen gehören 14 Bereiche. 5 davon haben wir direkt geprüft, die übrigen 9 ergeben sich aus diesen Aufgaben.',
    )
    // R7-8: Seite 2 nennt jetzt auch Zahlen für Abgeleitetes — der Hinweis spricht nur noch von Farben.
    expect(kasten).toHaveTextContent('Die Farben in diesem Bericht zeigen nur die direkt geprüften Bereiche.')
    expect(kasten).not.toHaveTextContent('Weitere Bereiche lernen wir')
  })

  it('abgestuftMitOffen: ein Teil ergibt sich, der Rest bleibt offen', () => {
    const satz = bogen(FAELLE.abgestuftMitOffen.data).s1.getByTestId('eb-thema-satz')
    expect(satz.textContent).toBe(
      'Zum Thema Reelle Zahlen gehören 14 Bereiche. 6 davon haben wir direkt geprüft, 5 weitere ergeben sich aus diesen Aufgaben. Die übrigen 3 klären wir in den ersten Sitzungen.',
    )
  })

  it('ilkay (fest): kein Thema-Satz, der allgemeine Hinweis', () => {
    const { s1 } = bogen(FAELLE.ilkay.data)
    expect(s1.queryByTestId('eb-thema-satz')).toBeNull()
    expect(s1.getByTestId('eb-geprueft')).toHaveTextContent('Weitere Bereiche lernen wir in den ersten Sitzungen kennen.')
  })

  it('ilkay mit modus adaptiv: der Raum ist nachgetragen, kein Thema-Satz', () => {
    const { data } = FAELLE.ilkay
    const s = bogen({ ...data, erzaehlung: { ...data.erzaehlung, modus: 'adaptiv' } })
    expect(s.s1.queryByTestId('eb-thema-satz')).toBeNull()
  })

  it('ohne Thema: Prüftext ohne Thema, kein Thema-Satz', () => {
    const { data } = FAELLE.abgestuft
    const suche = data.erzaehlung.suche ? { ...data.erzaehlung.suche, themaLabel: null } : null
    const kasten = bogen({ ...data, erzaehlung: { ...data.erzaehlung, suche } }).s1.getByTestId('eb-geprueft')
    expect(kasten.querySelector('.eb-s1-geprueft-text')?.textContent).toBe(
      'Je nach Antwort hat das System die nächste Aufgabe gewählt. So wurden 12 Bereiche gezielt geprüft.',
    )
    expect(within(kasten).queryByTestId('eb-thema-satz')).toBeNull()
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
        expect(text, `${name} S.${n}`).not.toMatch(/von \d+ Bereich/)
        expect(text, `${name} S.${n}`).not.toMatch(/\d+ von \d+/)
      }
    }
  })

  it('abgeleitete Urteile erscheinen nirgends als Eintrag, Segment oder in einer Liste', () => {
    for (const name of ['abgestuft', 'abgestuftMitOffen'] as const) {
      const { data } = FAELLE[name]
      const { container, seite } = bogen(data)
      const direkt = data.erzaehlung.kompetenzen
      // Farbige Kästchen auf Seite 2 = direkt geprüfte Bereiche; abgeleitete
      // stehen dort seit R7-8 nur als Umriss, je einer pro Bereich des Thema-Satzes.
      expect(seite(2).querySelectorAll('.eb-s2-spur .eb-s2-segment-sicher, .eb-s2-spur .eb-s2-segment-uebung'), name).toHaveLength(direkt.length)
      expect(seite(2).querySelectorAll('.eb-s2-spur .eb-s2-segment-abgeleitet'), name).toHaveLength(
        themaAbdeckungAus(data.erzaehlung)!.abgeleitet,
      )
      // Listeneinträge auf Seite 1 nur aus den direkt geprüften Labels.
      // Seit R7-9 in der Elternbezeichnung (elternLabel, Entscheidung 4).
      const labels = new Set(direkt.map((k) => elternLabel(k.label)))
      for (const li of seite(1).querySelectorAll('.eb-s1-liste li')) expect(labels, name).toContain(li.textContent)
      // Kein Schlüssel eines abgeleiteten Urteils im ganzen Bogen.
      const text = container.textContent ?? ''
      for (const key of data.erzaehlung.abgeleitet) expect(text, `${name} ${key}`).not.toContain(key)
    }
  })

  it('abgestuft: die Labels der abgeleiteten Bereiche stehen nirgends im Bogen', () => {
    // Labels aus skills (dbread 20.10.2026) für die abgeleiteten Schlüssel im Raum.
    const abgeleitet = [
      'Brüche kürzen',
      'Dezimalzahlen addieren/subtrahieren',
      'Dezimalzahlen dividieren',
      'Dezimalzahlen multiplizieren',
      'Potenzen und Quadratzahlen',
      'Runden und Überschlag',
      'Negative Zahlen addieren/subtrahieren',
      'Negative Zahlen multiplizieren/dividieren',
      'Quadratwurzel als Umkehrung des Quadrierens',
    ]
    const text = bogen(FAELLE.abgestuft.data).container.textContent ?? ''
    for (const label of abgeleitet) expect(text, label).not.toContain(label)
  })

  it('Seite 1 und 2 nennen dieselben Zahlen', () => {
    for (const [name, { data }] of faelle) {
      const { seite } = bogen(data)
      const zeile = seite(1).querySelector('.eb-s1-zeile')!.textContent!
      const [geprueft, sicher, uebung] = [...zeile.matchAll(/\d+/g)].map((m) => m[0])
      const zahlen = [...seite(2).querySelectorAll('.eb-s2-zahl')].map((z) => z.textContent)
      expect(zahlen, name).toEqual([sicher, uebung, geprueft])
      // Ein farbiges Kästchen je geprüftem Bereich: Profil-Summe = „Bereiche geprüft“.
      expect(String(seite(2).querySelectorAll('.eb-s2-spur .eb-s2-segment-sicher, .eb-s2-spur .eb-s2-segment-uebung').length), name).toBe(geprueft)
      // Umrisse = „ergeben sich“ im Thema-Satz (R7-8).
      expect(seite(2).querySelectorAll('.eb-s2-spur .eb-s2-segment-abgeleitet').length, name).toBe(
        themaAbdeckungAus(data.erzaehlung)?.abgeleitet ?? 0,
      )
      expect(seite(2).querySelector('.eb-s2-intro')!.textContent, name).toBe(
        `Geprüft: ${geprueft} Bereiche. Davon ${sicher} sicher, ${uebung} mit Übungsbedarf.`,
      )
    }
  })
})
