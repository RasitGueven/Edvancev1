// Was dieser Test seit A02 NICHT mehr prueft: dass die Vorschau keine Loesung aus
// dem FormState rendert. Diese Zusage ist kein Testgegenstand mehr, sondern eine
// Struktureigenschaft — die Komponente BEKOMMT keinen FormState. Sie rendert ein
// Payload, das der Server gebaut hat, und in dessen Vertrag eine Loesung nie
// vorkam. Der Beweis dafuer liegt dort, wo er hingehoert: in pgTAP
// (supabase/tests/inv8_vorschau_ohne_loesung.test.sql, rekursiv bis in parts und
// table hinein).
//
// Was hier bleibt, ist das, was im Frontend noch brechen KANN:
//   1. Die Verdrahtung: gespeichert → RPC ohne Draft. Ungespeichert → RPC MIT dem
//      Draft, den ein Speichern schriebe. Wer das verwechselt, zeigt dem Pfleger
//      einen Stand, den es nicht gibt.
//   2. Das Etikett: ein Entwurf muss als Entwurf erkennbar sein.
//   3. Das Rendering des Vertrags: Bild mit Alt-Text, Tabelle (F01), Multi-Part mit
//      EINEM Weiter-Button (P02), MC-Optionen, Kurzantwort mit Einheit.

import { describe, expect, it, vi, beforeEach } from 'vitest'
import { render, screen, waitFor } from '@testing-library/react'
import '@/i18n'
import type { AuthoringTaskPatch, PreviewPayload } from '@/types'
import { AuthoringPreview } from './AuthoringPreview'
import { PreviewStage } from './PreviewStage'

const { getTaskPreview } = vi.hoisted(() => ({ getTaskPreview: vi.fn() }))

vi.mock('@/lib/supabase/taskPreview', () => ({
  getTaskPreview,
  PREVIEW_RPC_MISSING: 'PREVIEW_RPC_MISSING',
}))

const flat: PreviewPayload = {
  task_id: 't1',
  kind: 'short_input',
  prompt: 'Berechne 20 % von 80 m.',
  unit: 'm',
  assets: [{ url: 'https://example.test/bild.png', alt: 'Ein Balkendiagramm' }],
  table: {
    headers: ['Bundesland', 'Einwohner pro km2'],
    rows: [
      ['Baden-Wuerttemberg', '301'],
      ['Bayern', '177'],
    ],
  },
}

const multi: PreviewPayload = {
  task_id: 't2',
  kind: 'multi_part',
  stem: 'Die Tabelle zeigt die Bevoelkerungsdichte.',
  assets: [],
  table: { headers: ['Land', 'Wert'], rows: [['Bayern', '177']] },
  parts: [
    { nr: 1, kind: 'short_input', prompt: 'Wie gross ist die Differenz?', unit: 'E/km2' },
    {
      nr: 2,
      kind: 'mc',
      prompt: 'Welches Land liegt darueber?',
      options: [
        { id: 'a', label: 'Hessen' },
        { id: 'b', label: 'Bayern' },
      ],
    },
  ],
}

const draft: AuthoringTaskPatch = { question: 'Neu getippt', input_type: 'SHORT_TEXT' }

describe('AuthoringPreview — eine Wahrheit, nicht zwei', () => {
  beforeEach(() => {
    getTaskPreview.mockReset()
    getTaskPreview.mockResolvedValue({ data: flat, error: null })
  })

  it('holt den GESPEICHERTEN Stand, solange nichts geaendert wurde (kein Draft an den Server)', async () => {
    render(<AuthoringPreview taskId="t1" draft={draft} dirty={false} />)
    await waitFor(() => expect(getTaskPreview).toHaveBeenCalledWith('t1', null))
  })

  it('schickt bei ungespeicherten Aenderungen den Draft mit — der Server baut daraus', async () => {
    render(<AuthoringPreview taskId="t1" draft={draft} dirty />)
    await waitFor(() => expect(getTaskPreview).toHaveBeenCalledWith('t1', draft))
  })

  it('markiert den Entwurfsstand sichtbar als ungespeichert', async () => {
    render(<AuthoringPreview taskId="t1" draft={draft} dirty />)
    expect(await screen.findByText('Ungespeichert')).toBeInTheDocument()
  })

  it('nennt den gespeicherten Stand beim Namen — kein stilles Entwurfs-Etikett', async () => {
    render(<AuthoringPreview taskId="t1" draft={draft} dirty={false} />)
    expect(await screen.findByText('Gespeicherter Stand')).toBeInTheDocument()
  })

  // Fehlt die RPC, gibt es keine Vorschau — und ausdruecklich keinen Frontend-Nachbau.
  it('zeigt bei fehlender RPC einen Hinweis statt eines nachgebauten Payloads', async () => {
    getTaskPreview.mockResolvedValue({ data: null, error: 'PREVIEW_RPC_MISSING' })
    render(<AuthoringPreview taskId="t1" draft={draft} dirty={false} />)
    expect(await screen.findByText('Vorschau nicht verfügbar')).toBeInTheDocument()
  })
})

describe('PreviewStage — der Vertrag, wie das Kind ihn sieht', () => {
  it('rendert Stamm, Bild mit Alt-Text, Tabelle und die Einheit', () => {
    render(<PreviewStage payload={flat} />)
    expect(screen.getByText(/Berechne 20 % von 80 m\./)).toBeInTheDocument()
    expect(screen.getByAltText('Ein Balkendiagramm')).toBeInTheDocument()
    expect(screen.getByText('Einwohner pro km2')).toBeInTheDocument()
    expect(screen.getByText('177')).toBeInTheDocument()
    expect(screen.getByText('m')).toBeInTheDocument()
  })

  it('rendert Multi-Part: Stamm oben, Teilaufgaben darunter, EIN Weiter-Button', () => {
    render(<PreviewStage payload={multi} />)
    expect(screen.getByText(/Die Tabelle zeigt die Bevoelkerungsdichte\./)).toBeInTheDocument()
    expect(screen.getByText(/Wie gross ist die Differenz\?/)).toBeInTheDocument()
    expect(screen.getByText(/Welches Land liegt darueber\?/)).toBeInTheDocument()
    expect(screen.getByText('Hessen')).toBeInTheDocument()
    // P02: das Kind beantwortet den Block, nicht Teilaufgabe fuer Teilaufgabe.
    expect(screen.getAllByRole('button')).toHaveLength(1)
  })

  it('bewertet nicht — die Eingaben sind Attrappen', () => {
    render(<PreviewStage payload={flat} />)
    expect(screen.getByPlaceholderText('Deine Antwort')).toBeDisabled()
    expect(screen.getByRole('button', { name: 'Antworten' })).toBeDisabled()
  })
})
