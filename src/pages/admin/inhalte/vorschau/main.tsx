// Vorschau „Inhalte-Übersicht“ (IU-1 U2): eigener Vite-Einstieg für vorschau/inhalte.html (Ansichtstests, nicht im
// Build). vite.inhalte.config.ts biegt den Supabase-Client auf eine Attrappe mit Prod-Zahlen um.
// ?pfad=/admin/inhalte?reiter=… (URL-kodiert).
import React from 'react'
import ReactDOM from 'react-dom/client'
import { MemoryRouter, Route, Routes } from 'react-router-dom'

import '@/i18n'
import '@/styles/globals.css'

import { InhalteUebersichtPage } from '../InhalteUebersichtPage'

const pfad = new URLSearchParams(window.location.search).get('pfad') ?? '/admin/inhalte'

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <MemoryRouter initialEntries={[pfad]}>
      <main className="mx-auto flex max-w-7xl flex-col gap-6 p-6">
        <Routes>
          <Route path="/admin/inhalte" element={<InhalteUebersichtPage />} />
          <Route path="*" element={<p data-testid="sprungziel">Sprungziel</p>} />
        </Routes>
      </main>
    </MemoryRouter>
  </React.StrictMode>,
)
