import { defineConfig } from '@playwright/test'

// Ansichtstests „Lauf mit Prüfziel“ (IU-1b) bei 1180 × 820 und 1440 × 900, Fotos nach LF_AUSGABE:
//   LF_PORT=5199 LF_AUSGABE=docs/inhalte/iu1b/abnahme npx playwright test -c playwright.lauf.config.ts
const PORT = Number(process.env.LF_PORT ?? 5199)

export default defineConfig({
  testDir: './e2e-lauf',
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
    command: `npx vite -c vite.lauf.config.ts --port ${PORT} --strictPort`,
    url: `http://localhost:${PORT}/vorschau/lauf.html`,
    reuseExistingServer: false,
    timeout: 120_000,
  },
})
