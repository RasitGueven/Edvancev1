import { defineConfig } from '@playwright/test'

// Ansichtstests „Archiv“ (MSA-1 M3) bei 1180 × 820 und 1440 × 900, Fotos nach AR_AUSGABE:
//   AR_PORT=5193 AR_AUSGABE=docs/msa/msa1/abnahme npx playwright test -c playwright.archiv.config.ts
const PORT = Number(process.env.AR_PORT ?? 5193)

export default defineConfig({
  testDir: './e2e-archiv',
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
    command: `npx vite -c vite.archiv.config.ts --port ${PORT} --strictPort`,
    url: `http://localhost:${PORT}/vorschau/archiv.html`,
    reuseExistingServer: false,
    timeout: 120_000,
  },
})
