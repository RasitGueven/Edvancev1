// Vorschau des Eltern-Berichts R7 — eigener Vite-Einstieg für
// vorschau/elternbericht.html (Dev-Server und Druck-Tests, nicht im Build).
//
// Ohne Router, ohne Anmeldung und ohne ein Modul, das den Supabase-Client
// lädt: Die Fälle kommen aus den Fixtures, der Worktree braucht keine .env.

import React from 'react'
import ReactDOM from 'react-dom/client'

import '@/i18n'
import '@/styles/globals.css'

import { ElternberichtBogen } from '@/components/edvance/elternbericht/Bogen'
import { FAELLE } from '@/lib/report/elternbericht/fixtures'

const name = new URLSearchParams(window.location.search).get('fall')
const fall = name ? FAELLE[name] : undefined

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    {fall ? (
      <div className="eb-ansicht">
        <ElternberichtBogen data={fall.data} notes={fall.notes} tiers={fall.tiers} />
      </div>
    ) : (
      <ul className="flex flex-col gap-2 p-6 text-sm">
        {Object.keys(FAELLE).map((f) => (
          <li key={f}>
            <a className="underline" data-fall={f} href={`?fall=${f}`}>
              {f}
            </a>
          </li>
        ))}
      </ul>
    )}
  </React.StrictMode>,
)
