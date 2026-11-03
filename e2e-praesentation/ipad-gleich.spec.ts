// TP-L1 (Präsentation füllt den Laptop): Auf dem iPad ändert sich nichts. Je
// Station ein Bildvergleich bei 1180×820 und 820×1180 gegen den Stand vor dem
// Umbau (Referenzbilder in ipad-gleich.spec.ts-snapshots/, aufgenommen auf dev
// 40bc8bf vor dem Zoom). Pixelgleich: keine Abweichung erlaubt.
//
//   TP_PORT=5185 npx playwright test -c playwright.praesentation.config.ts ipad-gleich
import { expect, test, type Page } from '@playwright/test'

import { stationOben } from './messen'

const MASSE: ReadonlyArray<[number, number]> = [
  [1180, 820],
  [820, 1180],
]
/** Wie in lernweg.spec.ts (Lernweg, vor V4) und zwei Fälle mit Fahrplan (V4). */
const FAELLE: ReadonlyArray<{ fall: string; v4: boolean }> = [
  { fall: 'abgestuft', v4: false },
  { fall: 'batuV4', v4: true },
  { fall: 'ilkay', v4: true },
]
const nn = (n: number): string => String(n).padStart(2, '0')

async function geheZu(page: Page, station: number): Promise<void> {
  const eintrag = page.locator('.tp-leiste-eintrag').nth(station - 1)
  await eintrag.click()
  await expect(eintrag).toHaveAttribute('aria-current', 'step')
  await expect.poll(() => stationOben(page, station).then(Math.abs)).toBeLessThanOrEqual(1)
}

const gleich = { maxDiffPixels: 0, animations: 'disabled', caret: 'hide' } as const

test.use({ contextOptions: { reducedMotion: 'reduce' } })

for (const { fall, v4 } of FAELLE) {
  for (const [b, h] of MASSE) {
    test(`${fall}${v4 ? '' : ' (vor V4)'} ${b}x${h}`, async ({ page }) => {
      await page.setViewportSize({ width: b, height: h })
      await page.goto(`/vorschau/praesentation.html?fall=${fall}${v4 ? '' : '&v4=aus'}`)
      await page.locator('.tp').waitFor()
      await page.evaluate(() => document.fonts.ready)
      const name = `${fall}${v4 ? '' : '-lernweg'}_${b}x${h}`
      await expect(page).toHaveScreenshot(`${name}_00.png`, gleich)

      await page.locator('.tp-intro-los').click()
      await expect(page.locator('.tp-intro')).toBeHidden()
      for (const n of [1, 2, 3, 4]) {
        await geheZu(page, n)
        await expect(page).toHaveScreenshot(`${name}_${nn(n)}.png`, gleich)
        if (n === 3 && (await page.getByTestId('tp-s3-ganz').count())) {
          await page.getByTestId('tp-s3-ganz').click()
          await expect(page.getByTestId('tp-s3-scroller')).toBeVisible()
          await expect(page).toHaveScreenshot(`${name}_03-ganzer-weg.png`, gleich)
          await page.getByTestId('tp-s3-zurueck').click()
        }
      }
    })
  }
}
