// Ansichtstests V4-S (docs/report/v4/Bauauftrag-V4-S.md, Prüfen 3): Station 03 mit der Karte „steht an“ für das
// Testkind Ida (bevorstehend) und für Batu (geschrieben, unverändert), je bei 1180×820 und 820×1180. Die Station
// passt, nichts ist abgeschnitten, Touch-Ziele ≥ 44 px. Fotos für den PR.
//
//   TP_PORT=5195 TP_AUSGABE=docs/report/v4/abnahme/v4-s npx playwright test -c playwright.praesentation.config.ts v4s
import { mkdirSync } from 'node:fs'
import { resolve } from 'node:path'

import { expect, test, type Page } from '@playwright/test'

import { kleineZiele, stationOben, verstoesse } from './messen'

const AUSGABE = resolve(process.env.TP_AUSGABE ?? 'docs/report/v4/abnahme/v4-s')
const MASSE: ReadonlyArray<[number, number]> = [
  [1180, 820],
  [820, 1180],
]
const FAELLE = ['idaBevorstehend', 'batuV4']

async function zuStation(page: Page, fall: string, nr: number): Promise<void> {
  await page.goto(`/vorschau/praesentation.html?fall=${fall}`)
  await page.locator('.tp').waitFor()
  await page.evaluate(() => document.fonts.ready)
  await page.locator('.tp-intro-los').click()
  const eintrag = page.locator('.tp-leiste-eintrag').nth(nr - 1)
  await eintrag.click()
  await expect(eintrag).toHaveAttribute('aria-current', 'step')
  await expect.poll(() => stationOben(page, nr).then(Math.abs)).toBeLessThanOrEqual(1)
}

test.use({ contextOptions: { reducedMotion: 'reduce' } })

for (const fall of FAELLE) {
  for (const [b, h] of MASSE) {
    const mass = `${b}x${h}`
    test(`Station 03 · ${fall} ${mass}`, async ({ page }) => {
      await page.setViewportSize({ width: b, height: h })
      await zuStation(page, fall, 3)
      const erste = page.getByTestId('tp-ka-karte').first()
      if (fall === 'idaBevorstehend') {
        await expect(erste.locator('.tp-ka-signal')).toHaveText('Voraussetzungen fehlen noch')
        await expect(erste.getByTestId('tp-ka-gruppe-imThema')).toBeVisible()
        await expect(erste.getByTestId('tp-ka-gruppe-voraus')).toBeVisible()
      } else {
        await expect(erste.locator('.tp-ka-signal')).toHaveCount(0)
      }
      expect(await verstoesse(page, 3), `Station 03 ${fall} ${mass}`).toEqual([])
      expect(await kleineZiele(page), `Station 03 ${fall} ${mass}`).toEqual([])
      mkdirSync(AUSGABE, { recursive: true })
      await page.screenshot({ path: resolve(AUSGABE, `${fall}_${mass}_03.png`) })
    })

    test(`Station 01 · ${fall} ${mass}`, async ({ page }) => {
      await page.setViewportSize({ width: b, height: h })
      await zuStation(page, fall, 1)
      const erste = page.getByTestId('tp-fp-station').first()
      if (fall === 'idaBevorstehend') await expect(erste).toContainText('Voraussetzungen fehlen noch')
      expect(await verstoesse(page, 1), `Station 01 ${fall} ${mass}`).toEqual([])
      mkdirSync(AUSGABE, { recursive: true })
      await page.screenshot({ path: resolve(AUSGABE, `${fall}_${mass}_01.png`) })
    })
  }
}
