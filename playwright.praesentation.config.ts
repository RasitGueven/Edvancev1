import { defineConfig, type Project } from '@playwright/test'

// Ansichtstests der Tablet-Präsentation (T2, Entscheidung 10) — getrennt von
// e2e/ und e2e-druck/. Jedes Paket nutzt einen eigenen Port und Ausgabeordner:
//   TP_PORT=5185 TP_AUSGABE=docs/report/praesentation/abnahme/t2 npx playwright test -c playwright.praesentation.config.ts
// Der Dev-Server dient nur der Vorschauseite (vorschau/praesentation.html), die
// ohne Supabase-Client und ohne .env läuft. Fehlt Chromium:
// npx playwright install chromium. WebKit (Safari) zusätzlich mit TP_WEBKIT=1 —
// braucht npx playwright install --with-deps webkit (in WSL mit sudo).
const PORT = Number(process.env.TP_PORT ?? 5185)

const projekte: Project[] = [{ name: 'chromium', use: { browserName: 'chromium' } }]
if (process.env.TP_WEBKIT === '1') projekte.push({ name: 'webkit', use: { browserName: 'webkit' } })

export default defineConfig({
  testDir: './e2e-praesentation',
  timeout: 120_000,
  workers: 4,
  fullyParallel: true,
  reporter: [['list']],
  use: {
    baseURL: `http://localhost:${PORT}`,
  },
  projects: projekte,
  webServer: {
    command: `npx vite --port ${PORT} --strictPort`,
    url: `http://localhost:${PORT}/vorschau/praesentation.html`,
    reuseExistingServer: false,
    timeout: 120_000,
  },
})
