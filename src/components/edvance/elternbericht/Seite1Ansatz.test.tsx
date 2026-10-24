// Bericht v2, Seite 1: „Ihr Anliegen“ mit der Antwort der Analyse und der
// Startsatz — über den ganzen Bogen, damit die Rechnung dieselbe ist wie im Druck.
import { render, within } from '@testing-library/react'
import { describe, expect, it } from 'vitest'
import '@/i18n'

import { ElternberichtBogen } from '@/components/edvance/elternbericht/Bogen'
import de from '@/i18n/locales/de/elternbericht.json'
import { FAELLE } from '@/lib/report/elternbericht/fixtures'
import type { ReportData, ReportErstgespraech, ReportFehlbild } from '@/types'

function seite1(data: ReportData) {
  const { container } = render(<ElternberichtBogen data={data} notes={null} tiers={[]} />)
  const el = container.querySelector<HTMLElement>('.eb-seite[data-seite="1"]')!
  return { ...within(el), el }
}

const eg = (teil: Partial<ReportErstgespraech> = {}): ReportErstgespraech => ({
  note: null,
  trend: null,
  seit: null,
  ziele: null,
  klassenarbeit: null,
  klassenarbeitDatum: null,
  ...teil,
})

/** Die Ursachen, wie sie der Lesepfad liefert: Rohwerte (weak_topics) und Anzeigenamen. */
const mitUrsachen = (data: ReportData, ursachen: string[], erstgespraech?: ReportErstgespraech): ReportData => ({
  ...data,
  parentAssessment: { note: null, weakTopics: ursachen },
  erzaehlung: { ...data.erzaehlung, anlassNamen: ursachen },
  ...(erstgespraech ? { erstgespraech } : {}),
})

const fehlbild = (familie: string, aufgaben: number): ReportFehlbild => ({
  slug: `${familie}-slug`,
  familie,
  familieElterntext: null,
  anzahl: aufgaben,
  aufgaben,
  skills: [],
  skillUebergreifend: false,
  einstufung: 'befund',
})

describe('Seite 1 — Ihr Anliegen', () => {
  it('Notenlage, Trend, Seit und Ursache aus dem Erstgespräch und den Anlassnamen', () => {
    const s = seite1(
      mitUrsachen(FAELLE.ilkay.data, ['Rechenwege'], eg({ note: '4', trend: 'besser', seit: 'dieses_halbjahr' })),
    )
    expect(s.getByTestId('eb-anliegen').querySelector('.eb-s1-anliegen-satz')?.textContent).toBe(
      'Die letzte Zeugnisnote von Ilkay in Mathematik war eine 4. Zuletzt ist sie besser geworden. Die Schwierigkeiten gibt es seit diesem Halbjahr. Als Ursache vermuten Sie Rechenwege.',
    )
  })

  it('ohne Namen die Fassung ohne Namen', () => {
    const s = seite1(mitUrsachen(FAELLE.ohneName.data, [], eg({ note: '3' })))
    expect(s.getByTestId('eb-anliegen')).toHaveTextContent('Die letzte Zeugnisnote in Mathematik war eine 3.')
  })

  it('nur die Ursache aus den Anlassnamen, wenn kein Erstgespräch vorliegt', () => {
    const s = seite1(FAELLE.anliegenGemischt.data)
    expect(s.getByTestId('eb-anliegen').querySelector('.eb-s1-anliegen-satz')?.textContent).toBe(
      'Als Ursache vermuten Sie Noten und Konzentration.',
    )
  })

  it('weder Erstgespräch noch Ursache: der Kasten entfällt, „So gehen wir vor“ in voller Breite', () => {
    const s = seite1(mitUrsachen(FAELLE.ilkay.data, []))
    expect(s.queryByTestId('eb-anliegen')).toBeNull()
    expect(s.queryByTestId('eb-antwort')).toBeNull()
    expect(s.getByTestId('eb-geprueft').parentElement).toHaveClass('eb-s1-kaesten-voll')
  })

  it('Anliegen ohne Antwort: der Kasten steht, der Antwortblock entfällt', () => {
    const s = seite1(mitUrsachen(FAELLE.ilkay.data, [], eg({ seit: 'laenger' })))
    expect(s.getByTestId('eb-anliegen')).toHaveTextContent('Die Schwierigkeiten bestehen schon länger.')
    expect(s.queryByTestId('eb-antwort')).toBeNull()
  })
})

describe('Seite 1 — Was die Analyse dazu zeigt', () => {
  const antwort = (data: ReportData): string | undefined =>
    seite1(data).queryByTestId('eb-antwort')?.querySelector('.eb-s1-antwort-satz')?.textContent ?? undefined

  it('Grundlagen: Klasse 5/6 sitzt, die Lücken liegen in Klasse 7/8 (abgestuft)', () => {
    const s = seite1(mitUrsachen(FAELLE.abgestuft.data, ['Grundlagen fehlen']))
    expect(s.getByTestId('eb-antwort')).toHaveTextContent('Was die Analyse dazu zeigt')
    expect(s.getByTestId('eb-antwort').querySelector('.eb-s1-antwort-satz')?.textContent).toBe(
      'Die Grundlagen aus Klasse 5/6 sitzen weitgehend. Die Lücken liegen vor allem im Stoff von Klasse 7/8.',
    )
  })

  it('Grundlagen: Lücken bis in Klasse 5/6 (ilkay)', () => {
    expect(antwort(mitUrsachen(FAELLE.ilkay.data, ['Grundlagen fehlen']))).toBe(
      'Die Lücken reichen bis in den Stoff von Klasse 5/6.',
    )
  })

  it('Grundlagen: Lücken im aktuellen Stoff sprechen eher dagegen', () => {
    expect(antwort(mitUrsachen(FAELLE.abgestuftPlanrang.data, ['Grundlagen fehlen']))).toBe(
      'Die Grundlagen aus früheren Klassen sitzen weitgehend. Die Lücken liegen vor allem im aktuellen Stoff von Klasse 9.',
    )
  })

  it('Konzentration: bestätigt nur mit dem Sorgfalts-Muster, sonst „misst diese Analyse nicht direkt“', () => {
    expect(antwort(FAELLE.ilkay.data)).toBe('Konzentration misst diese Analyse nicht direkt.')
    const mit = { ...FAELLE.ilkay.data, fehlbilder: [fehlbild('vorzeichen', 3)] }
    expect(antwort(mit)).toBe(de.ursache.konzentration.bestaetigt)
  })

  it('Prüfungsangst und Zeiteinteilung lassen sich nicht messen; jede Ursache bekommt ihre Antwort', () => {
    expect(antwort(mitUrsachen(FAELLE.ilkay.data, ['Prüfungsangst', 'Zeiteinteilung']))).toBe(
      'Prüfungsangst lässt sich in einer Analyse ohne Notendruck nicht messen. Zeiteinteilung misst diese Analyse nicht direkt.',
    )
  })

  it('Textverständnis: sicher gelöste Sachaufgaben sprechen eher dagegen, ohne solche Aufgabe fehlt die Aussage', () => {
    const data = mitUrsachen(FAELLE.ilkay.data, ['Textverständnis'])
    expect(antwort(data)).toBe(
      'Aufgaben mit längerem Text löste Ilkay sicher. Die Schwierigkeiten liegen eher an anderer Stelle.',
    )
    const ohneSkill = data.erzaehlung.kompetenzen.filter((k) => k.skillKey !== 'gleichung_modellieren')
    expect(antwort({ ...data, erzaehlung: { ...data.erzaehlung, kompetenzen: ohneSkill } })).toBe(
      'Zum Textverständnis gab es in dieser Analyse zu wenige Aufgaben für eine Aussage.',
    )
  })

  it('Ursachen, die der Bericht nicht kennt (Noten, Hausaufgaben): keine Antwort, Block entfällt', () => {
    const s = seite1(mitUrsachen(FAELLE.ilkay.data, ['Noten', 'Hausaufgaben']))
    expect(s.getByTestId('eb-anliegen')).toBeInTheDocument()
    expect(s.queryByTestId('eb-antwort')).toBeNull()
  })
})

describe('Seite 1 — Startsatz nach dem Stand der Klassenarbeit', () => {
  const start = (data: ReportData): string => seite1(data).getByTestId('eb-start').textContent ?? ''

  it('bevorstehend: das Thema, weil die Klassenarbeit bevorsteht', () => {
    expect(start({ ...FAELLE.abgestuft.data, erstgespraech: eg({ klassenarbeit: 'bevorstehend' }) })).toBe(
      'Wir beginnen mit dem Thema Reelle Zahlen, weil die Klassenarbeit zu diesem Thema bevorsteht.',
    )
  })

  it('geschrieben: ohne Voraussetzung eines kommenden Themas bleibt das Thema vorn', () => {
    expect(start({ ...FAELLE.abgestuft.data, erstgespraech: eg({ klassenarbeit: 'geschrieben' }) })).toBe(
      'Wir beginnen mit dem Thema Reelle Zahlen, weil im aktuellen Schulthema noch eine Lücke offen ist.',
    )
  })

  it('geschrieben: Felder, auf denen ein kommendes Thema aufbaut, kommen zuerst', () => {
    const text = start({ ...FAELLE.abgestuftPlanrang.data, erstgespraech: eg({ klassenarbeit: 'geschrieben' }) })
    expect(text).toMatch(/^Wir beginnen mit der Geometrie, weil das kommende Schulthema .+ darauf aufbaut\.$/)
    expect(start(FAELLE.abgestuftPlanrang.data)).toMatch(/^Wir beginnen mit dem Thema /)
  })
})
