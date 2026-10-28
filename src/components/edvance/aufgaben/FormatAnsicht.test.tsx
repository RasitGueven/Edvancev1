// Reihe 1 A3.4: Lenas Vorschau rendert jedes neue Format aus dem Payload, ohne Loesung.
import { describe, expect, it } from 'vitest'
import { render, screen } from '@testing-library/react'
import '@/i18n'
import type { FormatPayload } from '@/types'
import { FormatAnsicht, LoesungsbeispielAnsicht } from './FormatAnsicht'

const FAELLE: FormatPayload[] = [
  { format: 'feldmaske', schablone: [{ text: 'f(x) = ' }, { feld: 'a', typ: 'zahl' }, { feld: 'v', typ: 'vorzeichen' }, { feld: 'd', typ: 'zahl' }] },
  { format: 'loesungsmenge', element: 'zahl', max_felder: 3, variable: 'x' },
  { format: 'graph_auswahl', optionen: [{ id: 'a', alt: 'nach oben', bild: 'https://x/a.svg' }, { id: 'b', alt: 'nach unten' }] },
  { format: 'fehler_finden', zeilen: [{ nr: 1, text: '√75 = √(25 · 3)' }], warum: [{ id: 'w1', text: 'Mal statt Plus' }] },
  { format: 'bausteine', anzahl: 2, bausteine: [{ id: 'a', text: 'Ein Quadrat ist nie negativ.' }] },
  { format: 'schritte_ordnen', schritte: [{ id: 's2', text: '= (x + 3)² − 4' }, { id: 's1', text: 'x² + 6x + 5' }] },
]

describe('FormatAnsicht', () => {
  it('zeigt die Felder der Feldmaske als Attrappen', () => {
    render(<FormatAnsicht payload={FAELLE[0]} />)
    expect(screen.getByText('f(x) =')).toBeInTheDocument()
    expect(screen.getAllByRole('textbox')).toHaveLength(2)
    expect(screen.getAllByRole('textbox')[0]).toBeDisabled()
  })
  it('Lösungsmenge mit „Keine Lösung“', () => {
    render(<FormatAnsicht payload={FAELLE[1]} />)
    expect(screen.getByText('Keine Lösung')).toBeInTheDocument()
  })
  it('Graph-Auswahl: Bild, sonst der Hinweis, dass es fehlt', () => {
    render(<FormatAnsicht payload={FAELLE[2]} />)
    expect(screen.getByAltText('nach oben')).toBeInTheDocument()
    expect(screen.getByText('Bild noch nicht erzeugt: nach unten')).toBeInTheDocument()
  })
  it('Fehler finden, Bausteine, Schritte in der Reihenfolge des Payloads', () => {
    render(<FormatAnsicht payload={FAELLE[3]} />)
    expect(screen.getByText('Mal statt Plus')).toBeInTheDocument()
    render(<FormatAnsicht payload={FAELLE[4]} />)
    expect(screen.getByText('Wähle die zwei passenden Begründungen.')).toBeInTheDocument()
    render(<FormatAnsicht payload={FAELLE[5]} />)
    const texte = screen.getAllByText(/x/).map((e) => e.textContent)
    expect(texte.indexOf('= (x + 3)² − 4')).toBeLessThan(texte.indexOf('x² + 6x + 5'))
  })
  it('Lösungsbeispiel: alle Schritte und der passende Baustein markiert', () => {
    render(<LoesungsbeispielAnsicht beispiel={{ aufgabe: 'Löse x² = 4x.', schritte: [{ text: 'x² − 4x = 0' }, { text: 'x(x − 4) = 0' }],
      warum: { bei_schritt: 1, frage: 'Warum?', bausteine: [{ id: 'a', text: 'Ausklammern' }, { id: 'b', text: 'Teilen' }], richtig: 'a' } }} />)
    expect(screen.getByText('x(x − 4) = 0')).toBeInTheDocument()
    expect(screen.getByText('Ausklammern · passt')).toBeInTheDocument()
  })
})
