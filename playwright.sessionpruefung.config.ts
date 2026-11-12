import { defineConfig } from '@playwright/test'

// Ansichtstests „Session-Aufgaben prüfen“ (SP-1) bei 1180 × 820 und 1440 × 900, Fotos nach SP_AUSGABE:
//   SP_PORT=5191 SP_AUSGABE=docs/freigabe/sp1/abnahme npx playwright test -c playwright.sessionpruefung.config.ts
const PORT = Number(process.env.SP_PORT ?? 5191)

export default defineConfig({
  testDir: './e2e-sessionpruefung',
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
    command: `npx vite -c vite.sessionpruefung.config.ts --port ${PORT} --strictPort`,
    url: `http://localhost:${PORT}/vorschau/sessionpruefung.html`,
    reuseExistingServer: false,
    timeout: 120_000,
  },
})
