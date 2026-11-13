// Vorschau „Gezielt prüfen mit Prüfziel“ (IU-1 U3): eigener Vite-Einstieg für vorschau/gezielt.html (Ansichtstests,
// nicht im Build). ?pfad=/coach/pruefen?ziel=…&skill=… (URL-kodiert).
import React from 'react'
import ReactDOM from 'react-dom/client'
import { MemoryRouter, Route, Routes } from 'react-router-dom'

import '@/i18n'
import '@/styles/globals.css'

import type { PruefBoardZeile } from '@/types'
import { GezieltPruefen } from '../GezieltPruefen'
import daten from './daten.json'

const pfad = new URLSearchParams(window.location.search).get('pfad') ?? '/coach/pruefen'

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <MemoryRouter initialEntries={[pfad]}>
      <main className="mx-auto flex max-w-4xl flex-col gap-6 p-6">
        <Routes>
          <Route path="/coach/pruefen" element={<GezieltPruefen board={daten.board as PruefBoardZeile[]} onOeffne={() => undefined} />} />
        </Routes>
      </main>
    </MemoryRouter>
  </React.StrictMode>,
)
