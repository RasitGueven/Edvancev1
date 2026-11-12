// Vorschau „Archiv“ (MSA-1 M3): eigener Vite-Einstieg für vorschau/archiv.html (Ansichtstests, nicht im Build).
// vite.archiv.config.ts biegt Supabase-Client und useAuth auf Attrappen um. ?pfad=/admin/authoring | /admin/authoring/archiv
// | /coach/pruefen, ?rolle=admin|coach.
import React from 'react'
import ReactDOM from 'react-dom/client'
import { MemoryRouter, Route, Routes } from 'react-router-dom'

import '@/i18n'
import '@/styles/globals.css'

import { ItemBoardPage } from '@/pages/admin/ItemBoardPage'
import { PruefenUebersichtPage } from '@/pages/coach/pruefen/PruefenUebersichtPage'
import { ArchivPage } from '../ArchivPage'

const pfad = new URLSearchParams(window.location.search).get('pfad') ?? '/admin/authoring'

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <MemoryRouter initialEntries={[pfad]}>
      <main className="mx-auto flex max-w-6xl flex-col gap-6 p-6">
        <Routes>
          <Route path="/admin/authoring" element={<ItemBoardPage />} />
          <Route path="/admin/authoring/archiv" element={<ArchivPage />} />
          <Route path="/coach/pruefen" element={<PruefenUebersichtPage />} />
        </Routes>
      </main>
    </MemoryRouter>
  </React.StrictMode>,
)
