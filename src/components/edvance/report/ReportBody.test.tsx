import { render, screen, within } from '@testing-library/react'
import i18n from 'i18next'
import { initReactI18next } from 'react-i18next'
import { beforeAll, describe, expect, it } from 'vitest'

import { ReportBody } from '@/components/edvance/report/ReportBody'
import deReport from '@/i18n/locales/de/report.json'
import { familienBefunde, familienBestand } from '@/lib/report/familien'
import { baueFundament } from '@/lib/report/fundament'
import { baueSuche, type SucheEingabe } from '@/lib/report/suche'
import { FALL_A, FALL_B, FALL_C, FALL_D } from '@/lib/report/suche.fixtures'
import type { FundamentSkill, ReportBaustein, ReportData } from '@/types'

/**
 * Rendertest der Erzählung in sechs Schritten (R6).
 *
 * Typecheck und Lint sagen nichts darüber, ob die Abschnitte tatsächlich
 * erscheinen und ob die Bausteine an der richtigen Stelle landen. Genau dort
 * lag der Aufwand des Umbaus, also wird genau das geprüft.
 *
 * Die Daten sind die echte Sitzung d8b0d885 vom 16.08. — dieselben Zahlen, die
 * im abgestimmten HTML-Entwurf stehen.
 */

const s = (
  skillKey: string,
  label: string,
  fundamentTiefe: number,
  zustand: string,
  proben = 1,
): FundamentSkill => ({ skillKey, label, fundamentTiefe, zustand, proben })

const TOLUNAY: FundamentSkill[] = [
  s('gleichung_modellieren', 'Gleichungen aufstellen (Sachkontext)', 8, 'traegt'),
  s('prozent_veraenderung', 'Prozentuale Veränderung', 8, 'traegt'),
  s('gleichung_neg_koeffizient', 'Gleichungen mit negativem Koeffizienten', 7, 'traegt'),
  s('prozent_prozentsatz', 'Prozentsatz berechnen', 7, 'traegt'),
  s('term_ausklammern', 'Ausklammern', 7, 'traegt_teilweise', 2),
  s('groessen_volumen', 'Volumeneinheiten', 6, 'traegt_nicht', 2),
  s('term_minusklammer', 'Minusklammer auflösen', 6, 'traegt_nicht', 2),
  s('geo_massstab', 'Maßstab', 5, 'traegt_nicht', 2),
  s('groessen_flaechen', 'Flächeneinheiten', 5, 'traegt_nicht', 2),
  s('groessen_gemischt', 'Gemischte Schreibweise', 5, 'traegt'),
  s('bruch_dezimal', 'Bruch in Dezimalzahl', 4, 'traegt'),
  s('geo_flaeche_dreieck', 'Fläche von Dreieck und Parallelogramm', 4, 'traegt_nicht', 2),
  s('geo_volumen_quader', 'Volumen und Oberfläche des Quaders', 4, 'traegt_teilweise', 2),
  s('potenzen', 'Potenzen und Quadratzahlen', 4, 'traegt_teilweise', 2),
  s('bruch_div', 'Brüche dividieren', 3, 'traegt'),
  s('geo_flaeche_rechteck', 'Fläche von Rechteck und Quadrat', 3, 'traegt'),
  s('groessen_laengen', 'Längen umrechnen', 3, 'traegt'),
]

const BESTAND = familienBestand([
  ...TOLUNAY.map((x) => x.skillKey),
  // Auffüllen auf den echten Bestand, damit die Nenner stimmen.
  'bruch_add', 'bruch_mult', 'bruch_kuerzen', 'dezimal_div', 'dezimal_mult', 'dezimal_add_sub',
  'prozent_grundwert', 'prozent_prozentwert', 'proportionalitaet',
  'gleichung_beidseitig', 'gleichung_zweischrittig', 'gleichung_einschrittig',
  'term_ausmultiplizieren', 'term_zusammenfassen',
  'geo_umfang', 'geo_winkel_summe', 'groessen_zeit', 'groessen_massen',
  'vorzeichen_vorrang', 'vorzeichen_mult_div', 'vorzeichen_add_sub',
])

const b = (slot: string, fall: string, text: string): ReportBaustein[] => [
  { schluessel: `${slot}.${fall}.a`, slot, fall, variante: 'a', text },
  { schluessel: `${slot}.${fall}.b`, slot, fall, variante: 'b', text },
]

const BAUSTEINE: ReportBaustein[] = [
  ...b('suche', 'einstieg_traegt_fundament_luecken', 'Beim aktuellen Thema kommt Ihr Kind zurecht.'),
  ...b('abstieg_boden', 'vollstaendig', 'Ganz unten steht das Fundament.'),
  ...b('befund_traegt', 'standard', '{traegt} von {geprueft} geprüften Bereichen tragen sicher.'),
  ...b('fazit', 'zwei', 'Die offenen Bereiche verteilen sich auf zwei Themen.'),
  ...b('empfehlung', 'zwei', 'Zwei Themen nacheinander brauchen mehr Termine als eines.'),
  ...b('rueckbezug', 'textverstaendnis_entlastend_schmal', 'Die eine Aufgabe mit Sachkontext hat Ihr Kind richtig abgeleitet.'),
  ...b('rueckbezug', 'grundlagen_bestaetigend_mitte', 'Ihr Eindruck bestätigt sich — allerdings nicht ganz unten.'),
]

function baueDaten(fall: SucheEingabe = FALL_A): ReportData {
  const fundament = baueFundament(TOLUNAY)!
  return {
    sessionId: 'd8b0d885-b72d-4b68-a17b-6b35db301103',
    firstName: 'Tolunay',
    grade: 8,
    subject: 'Mathematik',
    status: 'completed',
    analysedAt: '2026-08-16T13:01:38.000Z',
    aufgaben: 25,
    naechstesThema: 'Lineare Gleichungen',
    parentAssessment: { note: null, weakTopics: ['Textverständnis', 'Grundlagen fehlen'] },
    skillbefunde: null,
    fehlbilder: [],
    erzaehlung: {
      fundament,
      suche: baueSuche(fall),
      raum: fall.raum,
      profil: familienBefunde(TOLUNAY, BESTAND),
      rueckbezuege: [
        { thema: 'Textverständnis', fall: 'textverstaendnis_entlastend_schmal', richtung: 'entlastend', belege: 1 },
        { thema: 'Grundlagen fehlen', fall: 'grundlagen_bestaetigend_mitte', richtung: 'bestaetigend', belege: 15 },
      ],
      verteilung: 'zwei',
      bausteine: BAUSTEINE,
      ansprechpartner: { name: 'Rasit Güven', email: 'rasit@edvanceacademy.de' },
      anlassNamen: ['Textverständnis', 'fehlende Grundlagen'],
    },
  }
}

beforeAll(async () => {
  await i18n.use(initReactI18next).init({
    lng: 'de',
    fallbackLng: 'de',
    resources: { de: { report: deReport } },
    interpolation: { escapeValue: false },
  })
})

describe('ReportBody — die sechs Schritte', () => {
  it('nennt das Kind beim Namen und den Umfang in Aufgaben', () => {
    render(<ReportBody data={baueDaten()} />)
    expect(screen.getByText('Was wir bei Tolunay gesehen haben')).toBeInTheDocument()
    expect(screen.getByText('25 Aufgaben')).toBeInTheDocument()
  })

  it('greift den Anlass mit geglätteten Anzeigenamen auf', () => {
    render(<ReportBody data={baueDaten()} />)
    // „fehlende Grundlagen", nicht der Rohwert „Grundlagen fehlen".
    expect(
      screen.getByText(/Textverständnis und fehlende Grundlagen als Schwierigkeiten/),
    ).toBeInTheDocument()
    expect(screen.getByText(/Lineare Gleichungen/)).toBeInTheDocument()
  })

  it('a) gliedert nach Thema, Grundlagen darunter und außerdem angesehen', () => {
    render(<ReportBody data={baueDaten(FALL_A)} />)
    const aktuell = screen.getByTestId('suche-aktuell')
    expect(within(aktuell).getByText('Terme und Gleichungen')).toBeInTheDocument()
    expect(within(aktuell).getByText('0 von 1 sicher')).toBeInTheDocument()

    const grundlagen = screen.getByTestId('suche-grundlagen')
    expect(within(grundlagen).getByText('Grundlagen darunter')).toBeInTheDocument()
    expect(within(grundlagen).getByText('Klasse 7/8')).toBeInTheDocument()
    expect(grundlagen.textContent).toMatch(/Beidseitige Gleichungen · sicher/)
    expect(grundlagen.textContent).not.toMatch(/Volumeneinheiten|Brüche/)

    const angesehen = screen.getByTestId('suche-angesehen')
    expect(within(angesehen).getByText('Außerdem angesehen')).toBeInTheDocument()
    expect(angesehen.textContent).toMatch(/Volumeneinheiten · noch nicht sicher/)
    expect(angesehen.textContent).toMatch(/Brüche dividieren · noch nicht sicher/)
    expect(within(angesehen).getByText('Klasse 5/6')).toBeInTheDocument()
    expect(within(angesehen).getAllByText('1 von 3 sicher')).toHaveLength(2)
    expect(screen.getByText(/bis wir sicheren Boden gefunden haben/)).toBeInTheDocument()
  })

  it.each([
    ['b', FALL_B],
    ['c', FALL_C],
    ['d', FALL_D],
  ])('%s) kein „sicherer Boden", kein „darunter" ohne Abstieg', (_, fall) => {
    const { container } = render(<ReportBody data={baueDaten(fall)} />)
    expect(container.textContent).not.toMatch(/sicheren Boden/)
    expect(screen.queryByTestId('suche-grundlagen')).toBeNull()
  })

  it('b) alte Sitzung: alles unter „Angesehen", mit Satz zum fehlenden Thema', () => {
    render(<ReportBody data={baueDaten(FALL_B)} />)
    expect(screen.queryByTestId('suche-aktuell')).toBeNull()
    expect(screen.getByText('Angesehen')).toBeInTheDocument()
    expect(screen.getByText(/Diese Analyse lief ohne gewähltes Thema/)).toBeInTheDocument()
  })

  it('markiert Urteile aus nur einer Aufgabe', () => {
    render(<ReportBody data={baueDaten(FALL_C)} />)
    expect(screen.getByText('(nur eine Aufgabe)')).toBeInTheDocument()
  })

  it.each([
    ['a', FALL_A],
    ['b', FALL_B],
    ['c', FALL_C],
    ['d', FALL_D],
  ])('%s) keine Ebenen mehr, kein „trägt" im Suchabschnitt', (_, fall) => {
    const { container } = render(<ReportBody data={baueDaten(fall)} />)
    expect(container.textContent).not.toMatch(/Ebene tiefer|Ebenen tiefer/)
    const suche = container.querySelector('section:has(.report-suche-block)')!
    expect(suche.textContent).not.toMatch(/trägt|trug|gemeistert/)
  })

  it('setzt die Platzhalter der Bausteine ein', () => {
    render(<ReportBody data={baueDaten()} />)
    expect(
      screen.getByText('9 von 17 geprüften Bereichen tragen sicher.'),
    ).toBeInTheDocument()
  })

  it('trennt im Profil "nicht geprüft" von einem echten Nullwert', () => {
    render(<ReportBody data={baueDaten()} />)
    // Vorzeichen wurde in dieser Sitzung nicht geprüft.
    expect(screen.getByText('nicht geprüft')).toBeInTheDocument()
    // Terme wurde geprüft und trägt nicht — der Nenner sagt das aus.
    expect(
      screen.getByText(/Terme: 2 von 4 geprüft, 0 tragen/),
    ).toBeInTheDocument()
    expect(
      screen.getByText(/Vorzeichen: 0 von 3 geprüft/),
    ).toBeInTheDocument()
  })

  it('führt beide Befundlisten mit Labels, nie mit Skill-Schlüsseln', () => {
    const { container } = render(<ReportBody data={baueDaten()} />)
    expect(screen.getByText('Gleichungen aufstellen (Sachkontext)')).toBeInTheDocument()
    expect(screen.getByText('Minusklammer auflösen')).toBeInTheDocument()
    // INV-4.3: kein roher Registry-Schlüssel auf der Elternfläche.
    expect(container.textContent).not.toMatch(/\b[a-z]+_[a-z_]+\b/)
  })

  it('beantwortet im Schluss jeden genannten Punkt', () => {
    render(<ReportBody data={baueDaten()} />)
    expect(
      screen.getByText(/Die eine Aufgabe mit Sachkontext/),
    ).toBeInTheDocument()
    expect(screen.getByText(/Ihr Eindruck bestätigt sich/)).toBeInTheDocument()
    // Die Richtung haengt nicht allein an der Farbe.
    expect(screen.getByText('Hat sich so nicht bestätigt')).toBeInTheDocument()
    expect(screen.getByText('Deckt sich mit der Analyse')).toBeInTheDocument()
  })

  it('nennt den Ansprechpartner am Dokumentende', () => {
    render(<ReportBody data={baueDaten()} />)
    const link = screen.getByRole('link', { name: 'rasit@edvanceacademy.de' })
    expect(link).toHaveAttribute('href', 'mailto:rasit@edvanceacademy.de')
    expect(screen.getByText(/Diese Analyse hat Rasit Güven begleitet/)).toBeInTheDocument()
  })

  it('laesst Abschnitte still weg, wenn ihre Daten fehlen', () => {
    const leer: ReportData = {
      ...baueDaten(),
      naechstesThema: null,
      erzaehlung: {
        fundament: null,
        suche: null,
        raum: null,
        profil: [],
        rueckbezuege: [],
        verteilung: null,
        bausteine: [],
        ansprechpartner: { name: null, email: null },
        anlassNamen: [],
      },
    }
    const { container } = render(<ReportBody data={leer} />)
    // Kopf steht, alles andere entfaellt — kein leerer Kasten, keine
    // Platzhaltersaetze.
    expect(screen.getByText('Was wir bei Tolunay gesehen haben')).toBeInTheDocument()
    expect(within(container).queryByText('Wie wir gesucht haben')).toBeNull()
    expect(within(container).queryByText('Was wir gefunden haben')).toBeNull()
    expect(within(container).queryByText(/Diese Analyse hat/)).toBeNull()
  })
})

describe('ReportBody — nachgetragener Themenraum (W5-d Teil 5)', () => {
  // Das Thema hat niemand gewählt: Die alte LSA begann für alle bei den
  // Gleichungen. Kein Satz darf eine Wahl im Gespräch voraussetzen.
  const nach = (f: SucheEingabe): SucheEingabe => ({
    ...f,
    raum: f.raum && { ...f.raum, herkunft: 'nachgetragen' },
  })
  const AUSGANGSPUNKT = [
    ...b('ausgangspunkt', 'ungeprueft', 'Ausgangspunkt der Analyse war das Thema „{thema}“.'),
    ...b('ausgangspunkt', 'thema', 'Ausgangspunkt der Analyse war das Thema „{thema}“.'),
  ]
  const mitBausteinen = (d: ReportData, extra: ReportBaustein[]): ReportData => ({
    ...d,
    erzaehlung: { ...d.erzaehlung, bausteine: [...d.erzaehlung.bausteine, ...extra] },
  })

  it('zeigt nie „Gewählt war das Thema" — ohne abgenommenen Baustein entfällt der Satz', () => {
    const { container } = render(<ReportBody data={baueDaten(nach(FALL_D))} />)
    expect(container.textContent).not.toMatch(/Gewählt|gewählt/)
    expect(container.textContent).not.toMatch(/Ausgangspunkt der Analyse war/)
    expect(container.textContent).toMatch(/Angesehen haben wir 3 Bereiche/)
  })

  it('nimmt den abgenommenen Ausgangspunkt-Baustein', () => {
    const d = mitBausteinen(baueDaten(nach(FALL_D)), AUSGANGSPUNKT)
    const { container } = render(<ReportBody data={d} />)
    expect(container.textContent).toMatch(
      /Ausgangspunkt der Analyse war das Thema „Proportionale und antiproportionale Zuordnungen“/,
    )
    expect(container.textContent).not.toMatch(/Gewählt/)
  })

  it('sagt beim Anlass nicht „genau dort haben wir angesetzt"', () => {
    const { container } = render(<ReportBody data={baueDaten(nach(FALL_A))} />)
    expect(container.textContent).toMatch(/Als nächstes Thema steht Lineare Gleichungen an\./)
    expect(container.textContent).not.toMatch(/angesetzt/)
  })

  it('heißt Block 1 „Ausgangspunkt der Analyse", nicht „Aktuelles Thema"', () => {
    render(<ReportBody data={baueDaten(nach(FALL_A))} />)
    const aktuell = screen.getByTestId('suche-aktuell')
    expect(within(aktuell).getByText('Ausgangspunkt der Analyse')).toBeInTheDocument()
    expect(within(aktuell).queryByText('Aktuelles Thema')).toBeNull()
  })

  it('bleibt bei gespeichertem Raum wie bisher', () => {
    const { container } = render(<ReportBody data={baueDaten(FALL_D)} />)
    expect(container.textContent).toMatch(/Gewählt war das Thema/)
    expect(container.textContent).toMatch(/genau dort haben wir angesetzt/)
  })
})
