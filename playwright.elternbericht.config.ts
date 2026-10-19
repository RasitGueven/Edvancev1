import { defineConfig } from '@playwright/test'

// Druck-Tests des Eltern-Berichts R7 (Bauauftrag R7, Entscheidung 9) — getrennt
// vom bestehenden e2e/. Jedes Paket nutzt einen eigenen Port und Ausgabeordner:
//   EB_PORT=5182 EB_AUSGABE=docs/report/r7/abnahme/r7-2 npx playwright test -c playwright.elternbericht.config.ts
// Der Dev-Server dient nur der Vorschauseite (vorschau/elternbericht.html), die
// ohne Supabase-Client und ohne .env läuft.
const PORT = Number(process.env.EB_PORT ?? 5182)

export default defineConfig({
  testDir: './e2e-druck',
  timeout: 120_000,
  // Ein Server, viele Fälle: parallel ja, aber nicht mehr Worker als nötig.
  workers: 4,
  reporter: [['list']],
  use: {
    baseURL: `http://localhost:${PORT}`,
    browserName: 'chromium',
  },
  webServer: {
    command: `npx vite --port ${PORT} --strictPort`,
    url: `http://localhost:${PORT}/vorschau/elternbericht.html`,
    reuseExistingServer: false,
    timeout: 120_000,
  },
})
