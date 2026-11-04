// Ansichtstests V4-S (docs/report/v4/Bauauftrag-V4-S.md, Prüfen 3): Bericht Seite 1 und 3 für das Testkind Ida
// (bevorstehend) und für Batu (geschrieben), je bei 1180×820 und 820×1180. Kein Überlauf prüft elternbericht.spec.ts
// für alle Fälle; hier die Inhalte der neuen Teile und die Fotos für den PR.
//
//   EB_PORT=5182 EB_AUSGABE=docs/report/v4/abnahme/v4-s npx playwright test -c playwright.elternbericht.config.ts v4s
import { mkdirSync } from 'node:fs'
import { resolve } from 'node:path'

import { expect, test } from '@playwright/test'

const AUSGABE = resolve(process.env.EB_AUSGABE ?? 'docs/report/v4/abnahme/v4-s')
const MASSE: ReadonlyArray<[number, number]> = [
  [1180, 820],
  [820, 1180],
]

for (const fall of ['idaBevorstehend', 'batuV4']) {
  for (const [b, h] of MASSE) {
    const mass = `${b}x${h}`
    test(`Bericht Seite 1 und 3 · ${fall} ${mass}`, async ({ page }) => {
      await page.setViewportSize({ width: b, height: h })
      await page.goto(`/vorschau/elternbericht.html?fall=${fall}&layout=B`)
      await page.waitForSelector('.eb-seite')
      await page.evaluate(() => document.fonts.ready)
      const s1 = page.locator('.eb-seite[data-seite="1"]')
      const s3 = page.locator('.eb-seite[data-seite="3"]')
      const erste = s1.getByTestId('eb-fp-station').first()
      if (fall === 'idaBevorstehend') {
        await expect(erste).toContainText('Voraussetzungen fehlen noch')
        await expect(s3.getByTestId('eb-s3-anstehend')).toBeVisible()
      } else {
        await expect(erste).not.toContainText('Voraussetzungen')
        await expect(s3.getByTestId('eb-s3-anstehend')).toHaveCount(0)
      }
      mkdirSync(AUSGABE, { recursive: true })
      await s1.screenshot({ path: resolve(AUSGABE, `${fall}_${mass}_bericht-s1.png`) })
      await s3.screenshot({ path: resolve(AUSGABE, `${fall}_${mass}_bericht-s3.png`) })
    })
  }
}
