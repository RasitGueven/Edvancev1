// Reihe 1 A1: die Pflege-Liste nennt den Pool (tasks.einsatz) je Aufgabe.
import { describe, expect, it } from 'vitest'
import { render, screen } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import '@/i18n'
import type { AuthoringTask } from '@/types'
import { ItemRow } from './ItemRow'

const task = (einsatz: string[] | undefined): AuthoringTask => ({
  id: 'id-1', title: 'Zwanzig Prozent', question: 'Berechne 20 % von 80 m.', status: 'draft', input_type: 'SHORT_TEXT',
  afb: 'I', competency_content: 'arithmetik_algebra', competency_process: 'ope', cluster_id: 'c1', unit: 'm',
  skill_key: 'prozent_prozentwert', est_duration_sec: 120, class_level: 8, parts: [], assets: [], needs_image: null,
  licence_text: null, question_payload: null, source: 'test', source_ref: 'x', is_active: true,
  created_at: '2026-10-27T00:00:00Z', einsatz,
})

const zeile = (einsatz: string[] | undefined) =>
  render(
    <MemoryRouter>
      <ItemRow row={{ task: task(einsatz), flagCount: 0, blockingCount: 0, hasTable: false }} />
    </MemoryRouter>,
  )

describe('ItemRow · Pool', () => {
  it('zeigt Pool LSA', () => {
    zeile(['lsa'])
    expect(screen.getByText('Pool LSA')).toBeInTheDocument()
  })
  it('zeigt Pool Session', () => {
    zeile(['session'])
    expect(screen.getByText('Pool Session')).toBeInTheDocument()
  })
  it('ohne Einsatz (alter Schemastand) keine Pool-Angabe', () => {
    zeile(undefined)
    expect(screen.queryByText(/Pool/)).toBeNull()
  })
})
