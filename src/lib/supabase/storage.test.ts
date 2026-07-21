// listCandidateAssets — die Auswahl-Liste des Bilder-Schritts im Pflege-Wizard.
//
// Getestet wird das Filtern, nicht das Netz: was Supabase zurueckgibt, ist nicht
// deckungsgleich mit dem, was der Pfleger sehen soll. Ordner, Platzhalter und
// die eigenen Zuschnitte muessen raus — sonst klickt Lena auf etwas, das kein
// Quellbild ist.

import { describe, expect, it, vi, beforeEach } from 'vitest'

const list = vi.fn()
const getPublicUrl = vi.fn((path: string) => ({
  data: { publicUrl: `https://cdn.test/${path}` },
}))

vi.mock('./client', () => ({
  supabase: { storage: { from: () => ({ list, getPublicUrl }) } },
}))

import { listCandidateAssets } from './storage'

type Entry = { id: string | null; name: string }
const entry = (name: string, id: string | null = 'obj'): Entry => ({ id, name })

beforeEach(() => {
  list.mockReset()
  getPublicUrl.mockClear()
})

describe('listCandidateAssets', () => {
  it('macht aus Dateinamen oeffentliche URLs unter kandidaten/<taskId>/', async () => {
    list.mockResolvedValue({ data: [entry('figur.png'), entry('tabelle.jpg')], error: null })

    const res = await listCandidateAssets('t-1')

    expect(res.error).toBeNull()
    expect(res.data).toEqual([
      { url: 'https://cdn.test/kandidaten/t-1/figur.png', path: 'kandidaten/t-1/figur.png' },
      { url: 'https://cdn.test/kandidaten/t-1/tabelle.jpg', path: 'kandidaten/t-1/tabelle.jpg' },
    ])
  })

  it('wirft Ordner und den leeren Platzhalter raus', async () => {
    list.mockResolvedValue({
      data: [entry('unterordner', null), entry('.emptyFolderPlaceholder'), entry('figur.png')],
      error: null,
    })

    const res = await listCandidateAssets('t-1')

    expect(res.data?.map((f) => f.path)).toEqual(['kandidaten/t-1/figur.png'])
  })

  // Ein Zuschnitt landet neben seinem Original (cropObjectPath leitet den Pfad
  // aus dem Ordner der Quelle ab). Er ist Ergebnis, nicht Quellmaterial.
  it('wirft eigene Zuschnitte raus, nicht aber normale Namen mit "crop"', async () => {
    list.mockResolvedValue({
      data: [
        entry('figur.png'),
        entry('figur-crop-1737300000000.png'),
        entry('cropping-schere.png'),
      ],
      error: null,
    })

    const res = await listCandidateAssets('t-1')

    expect(res.data?.map((f) => f.path)).toEqual([
      'kandidaten/t-1/figur.png',
      'kandidaten/t-1/cropping-schere.png',
    ])
  })

  it('deckelt nicht still bei 100', async () => {
    list.mockResolvedValue({ data: [], error: null })

    await listCandidateAssets('t-1')

    expect(list).toHaveBeenCalledWith('kandidaten/t-1', { limit: 1000 })
  })

  // Leer heisst "nichts vorbereitet", nicht "kaputt" — der Wizard blendet den
  // Bereich dann aus und laesst den manuellen Upload-Weg stehen.
  it('meldet eine leere Ablage als leere Liste, nicht als Fehler', async () => {
    list.mockResolvedValue({ data: null, error: null })

    const res = await listCandidateAssets('t-1')

    expect(res).toEqual({ data: [], error: null })
  })

  it('reicht den Storage-Fehler als Meldung durch', async () => {
    list.mockResolvedValue({ data: null, error: { message: 'bucket not found' } })

    const res = await listCandidateAssets('t-1')

    expect(res).toEqual({ data: null, error: 'bucket not found' })
  })
})
