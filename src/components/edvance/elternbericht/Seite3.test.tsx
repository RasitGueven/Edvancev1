// Seite 3 des Eltern-Berichts R7: der Lernweg (R7-9) für die Fixture-Fälle.
import { render, within } from '@testing-library/react'
import { describe, expect, it } from 'vitest'
import '@/i18n'

import { ElternberichtBogen } from '@/components/edvance/elternbericht/Bogen'
import { FAELLE } from '@/lib/report/elternbericht/fixtures'
import type { ReportData } from '@/types'

function bogen(data: ReportData) {
  const { container } = render(<ElternberichtBogen data={data} notes={null} tiers={[]} />)
  const seite = (n: number) => container.querySelector<HTMLElement>(`.eb-seite[data-seite="${n}"]`)!
  return { container, seite, s3: within(seite(3)) }
}

const legende = (data: ReportData): string[] =>
  [...bogen(data).seite(3).querySelectorAll('[data-legende]')].map((l) => l.getAttribute('data-legende')!)

describe('Seite 3 — Lernweg, abgestuft (Batu)', () => {
  it('Kicker, Titel und Intro mit Schule', () => {
    const { seite } = bogen(FAELLE.abgestuft.data)
    const s = seite(3)
    expect(s.querySelector('.eb-s3-kicker')).toHaveTextContent('Ilkays Lernweg')
    expect(s.querySelector('h1')).toHaveTextContent('Auf vorhandenen Stärken aufbauen.')
    expect(s.querySelector('.eb-s3-intro')).toHaveTextContent(
      'was in Klasse 9 laut Schulplan der Schule Friedrich-Wilhelm-Gymnasium noch kommt.',
    )
  })

  it('Zonen mit Klassenangabe, Kommt noch mit Schulplan', () => {
    const s = bogen(FAELLE.abgestuft.data).seite(3)
    const zonen = [...s.querySelectorAll('.eb-s3-zone-kopf')].map((k) => k.textContent)
    expect(zonen).toEqual([
      'GrundlagenKlasse 5/6',
      'WeiterführendKlasse 7/8',
      'AktuellKlasse 9 · Reelle Zahlen',
      'Kommt nochKlasse 9, Schulplan',
    ])
  })

  it('↳ mit Unterzeile: beide Verfahren, Stand', () => {
    const s = bogen(FAELLE.abgestuft.data).seite(3)
    const unter = [...s.querySelectorAll('.eb-s3-unter')].map((u) => u.textContent)
    expect(unter).toContain(
      '↳Gleichungssysteme aus Sachaufgaben aufstellen und lösenbaut auf beiden Verfahren auf · noch nicht geprüft',
    )
    expect(unter).toContain('↳Teilweise die Wurzel ziehenbaut darauf auf · Übungsbedarf')
  })

  it('gebröckelt nur Geometrie und Zahlen & Rechnen', () => {
    const s = bogen(FAELLE.abgestuft.data).seite(3)
    const titel = [...s.querySelectorAll('[data-broeckelt] .eb-s3-insel-titel')].map((t) => t.textContent)
    expect(titel).toEqual(['Geometrie', 'Zahlen & Rechnen'])
  })

  it('„Sie sind hier“ mit demselben Monat wie im Kopf von Seite 1', () => {
    const { seite } = bogen(FAELLE.abgestuft.data)
    const kopfDatum = [...seite(1).querySelectorAll('*')].find((e) => /\d{4}$/.test(e.textContent ?? '') && e.children.length === 0)!
      .textContent!
    const monat = kopfDatum.split(' ')[1]
    expect(monat).toBe('Oktober')
    expect(within(seite(3)).getByTestId('eb-s3-hier')).toHaveTextContent(`Sie sind hier · ${monat}`)
  })

  it('Hinweis unten nennt die Quelle, keine Lesehilfe der Pyramide mehr', () => {
    const s = bogen(FAELLE.abgestuft.data).seite(3)
    expect(s.querySelector('.eb-s3-hinweis')).toHaveTextContent(
      'die Reihenfolge der kommenden Themen aus dem Schulplan der Schule Friedrich-Wilhelm-Gymnasium.',
    )
    expect(s).not.toHaveTextContent(/Pyramide|keine feste Voraussetzung/)
  })

  it('kein Skill-Schlüssel und kein „trägt“ auf der Seite, auch nicht in Attributen', () => {
    const s = bogen(FAELLE.abgestuft.data).seite(3)
    expect(s.innerHTML).not.toMatch(/bruch_dezimal|zahl_wurzel|gleichung_lgs/)
    expect(s.textContent).not.toMatch(/tr(ä|ae)gt|Fundament|Ebene|\bLGS\b/)
  })
})

describe('Seite 3 — Legende nur mit vorkommenden Einträgen (Entscheidung 12)', () => {
  it('abgestuft: alle sieben', () => {
    expect(legende(FAELLE.abgestuft.data)).toEqual(['sicher', 'uebung', 'offen', 'linie', 'unter', 'broeckelt', 'kommt'])
  })
  it('ohneKanten: ohne Linie, ohne ↳, ohne noch nicht geprüft', () => {
    expect(legende(FAELLE.ohneKanten.data)).toEqual(['sicher', 'uebung', 'broeckelt', 'kommt'])
  })
  it('allesSicher: kein Übungsbedarf, nichts gebröckelt', () => {
    const l = legende(FAELLE.allesSicher.data)
    expect(l).not.toContain('uebung')
    expect(l).not.toContain('broeckelt')
  })
})

describe('Seite 3 — Kernlehrplan und Klassen', () => {
  it('ilkay: ohne Schule nach dem Kernlehrplan NRW, Klasse 9/10', () => {
    const s = bogen(FAELLE.ilkay.data).seite(3)
    expect(s.querySelector('.eb-s3-intro')).toHaveTextContent('nach dem Kernlehrplan NRW noch kommt.')
    expect(s.querySelector('.eb-s3-zone-kommt .eb-s3-zone-klasse')).toHaveTextContent('Kernlehrplan NRW, Klasse 9/10')
  })
  it('klasse7: Grundlagen, Aktuell, Kommt noch', () => {
    const s = bogen(FAELLE.klasse7.data).seite(3)
    expect([...s.querySelectorAll('[data-spalte]')].map((z) => z.getAttribute('data-spalte'))).toEqual([
      'grundlagen',
      'aktuell',
      'kommt',
    ])
  })
  it('spaeter: Stoff einer späteren Klasse steht in Aktuell mit seiner Klasse', () => {
    const s = bogen(FAELLE.spaeter.data).seite(3)
    expect(s.querySelector('.eb-s3-zone-aktuell .eb-s3-spaeter')).toHaveTextContent('Stoff aus Klasse 9')
  })
  it('ohneName: Kicker und Intro ohne Namen', () => {
    const s = bogen(FAELLE.ohneName.data).seite(3)
    expect(s.querySelector('.eb-s3-kicker')).toHaveTextContent(/^Lernweg$/)
    expect(s.querySelector('.eb-s3-intro')).toHaveTextContent('was Ihr Kind schon hinter sich hat')
  })
})
