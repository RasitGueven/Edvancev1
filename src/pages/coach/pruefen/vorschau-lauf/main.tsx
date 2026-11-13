// Vorschau „Lauf mit Prüfziel“ (IU-1b): „Gezielt prüfen“ und echte Prüfansicht, Lib-Aufrufe als Attrappen
// (vite.lauf.config.ts). Unten steht die aktuelle Adresse und die Liste der Entscheidungen für den Ansichtstest.
// ?pfad=/coach/pruefen?ziel=… (URL-kodiert).
import React from 'react'
import ReactDOM from 'react-dom/client'
import { MemoryRouter, Route, Routes, useLocation, useNavigate, useSearchParams } from 'react-router-dom'

import '@/i18n'
import '@/styles/globals.css'

import { leseZielFilter, pruefansichtPfad } from '@/lib/pruefung/gezielt'
import { GezieltPruefen } from '../GezieltPruefen'
import { PruefansichtPage } from '../PruefansichtPage'
import { BOARD, ENTSCHIEDEN } from './speicher'

function Liste(): JSX.Element {
  const navigate = useNavigate()
  const [params] = useSearchParams()
  return <GezieltPruefen board={BOARD} onOeffne={(id) => navigate(pruefansichtPfad(id, leseZielFilter(params)))} />
}
function Ort(): JSX.Element {
  const l = useLocation()
  return <output data-testid="ort" data-entschieden={ENTSCHIEDEN.join(',')} className="text-xs">{l.pathname + l.search}</output>
}

const pfad = new URLSearchParams(window.location.search).get('pfad') ?? '/coach/pruefen'
ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <MemoryRouter initialEntries={[pfad]}>
      <main className="mx-auto flex max-w-6xl flex-col gap-6 p-6">
        <Routes>
          <Route path="/coach/pruefen" element={<Liste />} />
          <Route path="/coach/pruefen/:taskId" element={<PruefansichtPage />} />
        </Routes>
        <Ort />
      </main>
    </MemoryRouter>
  </React.StrictMode>,
)
