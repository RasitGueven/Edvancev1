// Editor-Rueckweg in die Admin-Pruefansicht (Bauauftrag D 17): Zurueck-Link, „Gespeichert.“ mit Knopf ohne
// automatische Weiterleitung, Sprungziel offen; dazu die Sperre „erst an Lena“ im ReleaseGate.

import { describe, expect, it } from 'vitest'
import { fireEvent, render, screen } from '@testing-library/react'
import { MemoryRouter, Route, Routes } from 'react-router-dom'
import '@/i18n'
import { EditorKopf } from './EditorKopf'
import { ReleaseGate } from './ReleaseGate'
import { usePruefRueckweg } from './usePruefRueckweg'

function Offen(): JSX.Element {
  const r = usePruefRueckweg()
  return <p>{(['aufgabe', 'antwort', 'einordnung', 'bilder'] as const).filter((a) => r.offen(a)).join(',')}</p>
}

const zeige = (url: string, gespeichert = false) => render(
  <MemoryRouter initialEntries={[url]}>
    <Routes>
      <Route path="/admin/authoring/:id" element={<><EditorKopf titel="Umfang · Radius 3,6 m" gespeichert={gespeichert} /><Offen /></>} />
      <Route path="/admin/pruefen/:taskId" element={<p>Prüfansicht</p>} />
    </Routes>
  </MemoryRouter>,
)

describe('Editor-Rueckweg', () => {
  it('aus der Pruefansicht heisst der Zurueck-Link „Zurück zur Prüfansicht“ und fuehrt zur Aufgabe', () => {
    zeige('/admin/authoring/t1?zurueck=pruefen&abschnitt=stoffanker')
    const link = screen.getByRole('link', { name: /Zurück zur Prüfansicht/ })
    expect(link.getAttribute('href')).toBe('/admin/pruefen/t1')
    expect(screen.queryByText('Gespeichert.')).toBeNull()
    expect(screen.getByText('einordnung')).toBeTruthy()
  })

  it('nach dem Speichern: „Gespeichert.“ mit Knopf, der zur Pruefansicht fuehrt', () => {
    zeige('/admin/authoring/t1?zurueck=pruefen', true)
    expect(screen.getByText('Gespeichert.')).toBeTruthy()
    expect(screen.queryByText('Prüfansicht')).toBeNull()
    fireEvent.click(screen.getByRole('button', { name: 'Zurück zur Prüfansicht' }))
    expect(screen.getByText('Prüfansicht')).toBeTruthy()
  })

  it('ohne ?zurueck=pruefen bleibt der Weg zur Item-Pflege, ohne Knopf', () => {
    zeige('/admin/authoring/t1', true)
    expect(screen.queryByRole('link', { name: /Prüfansicht/ })).toBeNull()
    expect(screen.queryByText('Gespeichert.')).toBeNull()
  })
})

describe('ReleaseGate bei beanstandet', () => {
  it('sperrt „zur Prüfung“ und „freigeben“ mit dem Grund als Tooltip', () => {
    render(
      <ReleaseGate status="beanstandet" blocking={[]} dirty={false} busy={false} canWrite hasAudit
        reviewerName={null} reviewedAt={null} error={null} onSetStatus={() => undefined} />,
    )
    const grund = 'Erst überarbeiten, dann in der Admin-Prüfansicht zurück an Lena.'
    const knoepfe = screen.getAllByRole('button').filter((b) => b.closest('[title]')?.getAttribute('title') === grund)
    expect(knoepfe).toHaveLength(2)
    for (const k of knoepfe) expect((k as HTMLButtonElement).disabled).toBe(true)
  })
})
