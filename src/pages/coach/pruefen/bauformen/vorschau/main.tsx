// Vorschau „Session-Aufgaben prüfen“ (SP-1): eigener Vite-Einstieg für vorschau/sessionpruefung.html (Ansichtstests,
// nicht im Build). vite.sessionpruefung.config.ts biegt die Lib, useAuth und den Supabase-Client auf Attrappen um.
// ?rolle=coach|admin, ?pfad=/coach/pruefen/bauformen[/<id>].
import React from 'react'
import ReactDOM from 'react-dom/client'
import { MemoryRouter, Route, Routes } from 'react-router-dom'

import '@/i18n'
import '@/styles/globals.css'

import { AppShell } from '@/components/edvance/shell/AppShell'
import { coachNav } from '@/components/edvance/coach/coachNav'
import { BauformListePage } from '../BauformListePage'
import { BauformDetailPage } from '../BauformDetailPage'

const pfad = new URLSearchParams(window.location.search).get('pfad') ?? '/coach/pruefen/bauformen'

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <MemoryRouter initialEntries={[pfad]}>
      <AppShell konfig={coachNav(true)} zaehler={{}}>
        <Routes>
          <Route path="/coach/pruefen/bauformen" element={<BauformListePage />} />
          <Route path="/coach/pruefen/bauformen/:bauformId" element={<BauformDetailPage />} />
          <Route path="*" element={<BauformListePage />} />
        </Routes>
      </AppShell>
    </MemoryRouter>
  </React.StrictMode>,
)
