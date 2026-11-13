import { defineConfig } from '@playwright/test'

// Ansichtstests „Inhalte-Übersicht“ (IU-1 U2) bei 1180 × 820 und 1440 × 900, Fotos nach IU_AUSGABE:
//   IU_PORT=5197 IU_AUSGABE=docs/inhalte/iu1/abnahme npx playwright test -c playwright.inhalte.config.ts
const PORT = Number(process.env.IU_PORT ?? 5197)

export default defineConfig({
  testDir: './e2e-inhalte',
  timeout: 60_000,
  workers: 2,
  fullyParallel: true,
  reporter: [['list']],
  use: { baseURL: `http://localhost:${PORT}`, reducedMotion: 'reduce' },
  projects: [
    { name: '1180x820', use: { browserName: 'chromium', viewport: { width: 1180, height: 820 } } },
    { name: '1440x900', use: { browserName: 'chromium', viewport: { width: 1440, height: 900 } } },
  ],
  webServer: {
    command: `npx vite -c vite.inhalte.config.ts --port ${PORT} --strictPort`,
    url: `http://localhost:${PORT}/vorschau/inhalte.html`,
    reuseExistingServer: false,
    timeout: 120_000,
  },
})
