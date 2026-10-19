// Vorschau der Tablet-Präsentation — eigener Vite-Einstieg für
// vorschau/praesentation.html (Dev-Server und Ansichtstests, nicht im Build).
//
// Ohne Router, ohne Anmeldung und ohne ein Modul, das den Supabase-Client
// lädt: Die Fälle kommen aus PRAESENTATION_FAELLE, der Worktree braucht keine
// .env. Schließen führt zurück zur Liste der Fälle.

import React from 'react'
import ReactDOM from 'react-dom/client'

import '@/i18n'
import '@/styles/globals.css'

import { Praesentation } from '@/components/edvance/praesentation/Praesentation'
import { PRAESENTATION_FAELLE } from '@/lib/report/praesentation/fixtures'

const name = new URLSearchParams(window.location.search).get('fall')
const fall = name ? PRAESENTATION_FAELLE[name] : undefined

const zurListe = (): void => {
  window.location.search = ''
}

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    {fall ? (
      <Praesentation
        data={fall.data}
        notes={fall.notes}
        tiers={fall.tiers}
        tiersFehler={false}
        sessionId={fall.data.sessionId}
        laden={false}
        onSchliessen={zurListe}
      />
    ) : (
      <ul className="flex flex-col gap-2 p-6 text-sm">
        {Object.keys(PRAESENTATION_FAELLE).map((f) => (
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
