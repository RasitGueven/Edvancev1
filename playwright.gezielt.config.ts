import { defineConfig } from '@playwright/test'

// Ansichtstests „Gezielt prüfen mit Prüfziel“ (IU-1 U3) bei 1180 × 820 und 1440 × 900, Fotos nach GZ_AUSGABE:
//   GZ_PORT=5198 GZ_AUSGABE=docs/inhalte/iu1/abnahme npx playwright test -c playwright.gezielt.config.ts
const PORT = Number(process.env.GZ_PORT ?? 5198)

export default defineConfig({
  testDir: './e2e-gezielt',
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
    command: `npx vite -c vite.gezielt.config.ts --port ${PORT} --strictPort`,
    url: `http://localhost:${PORT}/vorschau/gezielt.html`,
    reuseExistingServer: false,
    timeout: 120_000,
  },
})
