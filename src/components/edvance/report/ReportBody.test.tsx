import { render, screen, within } from '@testing-library/react'
import i18n from 'i18next'
import { initReactI18next } from 'react-i18next'
import { beforeAll, describe, expect, it } from 'vitest'

import { ReportBody } from '@/components/edvance/report/ReportBody'
import deReport from '@/i18n/locales/de/report.json'
import { familienBefunde, familienBestand } from '@/lib/report/familien'
import { baueFundament } from '@/lib/report/fundament'
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

function baueDaten(): ReportData {
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

  it('zeigt die Ebenenspur mit Untertiteln und Zählung', () => {
    render(<ReportBody data={baueDaten()} />)
    expect(screen.getByText('Aktuelles Thema')).toBeInTheDocument()
    expect(screen.getByText('Fünf Ebenen tiefer')).toBeInTheDocument()
    // Die schärfste Ebene der Sitzung.
    expect(screen.getByText('0 von 2')).toBeInTheDocument()
    expect(
      screen.getByText('Minusklammer auflösen, Volumeneinheiten'),
    ).toBeInTheDocument()
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
