// Der Zuschnitt darf das Original nicht verlieren. Genau das wird hier geprueft —
// nicht die Zeichen-Geste (die lebt in crop.ts und im Canvas), sondern die
// Buchhaltung drumherum: welche URL steht danach im Datensatz, und kommt der
// Pfleger aus einem Fehlschnitt wieder heraus.
//
// Der Cropper selbst ist gemockt: er braucht Canvas + Pointer-Events, die es in
// jsdom nicht gibt. Gemockt wird nur SEIN Ausgang (onCropped mit einer URL) —
// die Regeln, um die es geht, liegen ohnehin in AssetsSection.

import { describe, expect, it, vi } from 'vitest'
import { fireEvent, render, screen } from '@testing-library/react'
import '@/i18n'
import type { TaskAsset } from '@/types'

const CROP_URL = 'https://xyz.supabase.co/storage/v1/object/public/task-assets/lsa/e/f-crop-2.png'
const ORIGINAL = 'https://xyz.supabase.co/storage/v1/object/public/task-assets/lsa/e/f.png'

vi.mock('./AssetCropper', () => ({
  AssetCropper: ({
    sourceUrl,
    onCropped,
  }: {
    sourceUrl: string
    onCropped: (url: string) => void
  }) => (
    <button type="button" data-testid="fake-cropper" data-source={sourceUrl} onClick={() => onCropped(CROP_URL)}>
      crop
    </button>
  ),
}))

import { AssetsSection } from './AssetsSection'

function setup(initial: TaskAsset[], canWrite = true) {
  const state = { assets: initial }
  const onChange = vi.fn((next: TaskAsset[]) => {
    state.assets = next
  })
  const view = render(
    <AssetsSection assets={initial} onChange={onChange} taskId="task-1" canWrite={canWrite} />,
  )
  return { state, onChange, view }
}

describe('AssetsSection — Zuschnitt', () => {
  it('schreibt den Zuschnitt in url und bewahrt das Original in original_url', () => {
    const { state } = setup([{ url: ORIGINAL, alt: 'Figur' }])

    fireEvent.click(screen.getByRole('button', { name: /zuschneiden/i }))
    fireEvent.click(screen.getByTestId('fake-cropper'))

    expect(state.assets[0]).toEqual({
      url: CROP_URL,
      alt: 'Figur',
      original_url: ORIGINAL,
    })
  })

  it('stellt das Original wieder her und laesst kein original_url zurueck', () => {
    const { state } = setup([{ url: CROP_URL, alt: 'Figur', original_url: ORIGINAL }])

    fireEvent.click(screen.getByRole('button', { name: /original wiederherstellen/i }))

    expect(state.assets[0]).toEqual({ url: ORIGINAL, alt: 'Figur' })
    expect(state.assets[0]).not.toHaveProperty('original_url')
  })

  it('schneidet immer aus dem Original, nicht aus dem letzten Zuschnitt', () => {
    setup([{ url: CROP_URL, alt: 'Figur', original_url: ORIGINAL }])

    fireEvent.click(screen.getByRole('button', { name: /zuschneiden/i }))

    expect(screen.getByTestId('fake-cropper')).toHaveAttribute('data-source', ORIGINAL)
  })

  it('haelt original_url auf dem echten Original, auch beim zweiten Zuschnitt', () => {
    const { state } = setup([{ url: CROP_URL, alt: 'Figur', original_url: ORIGINAL }])

    fireEvent.click(screen.getByRole('button', { name: /zuschneiden/i }))
    fireEvent.click(screen.getByTestId('fake-cropper'))

    expect(state.assets[0].original_url).toBe(ORIGINAL)
  })

  it('zeigt dem Coach keinen Zuschnitt-Knopf', () => {
    setup([{ url: ORIGINAL, alt: 'Figur' }], false)

    expect(screen.queryByRole('button', { name: /zuschneiden/i })).toBeNull()
    expect(screen.queryByRole('button', { name: /original wiederherstellen/i })).toBeNull()
  })

  it('bietet keinen Zuschnitt fuer ein Asset ohne Bild an', () => {
    setup([{ url: '', alt: '' }])

    expect(screen.queryByRole('button', { name: /zuschneiden/i })).toBeNull()
  })
})
