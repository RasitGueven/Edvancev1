// PS-1: Bildschirmfotos der schlanken Präsentation für die Abnahme — drei Fälle,
// iPad quer 1180×820 und hoch 820×1180, alle vier Stationen, fertiger Zustand.
// Nur Attrappen-Daten aus den Fixtures (Vorschauseite, keine Anmeldung).
//
//   TP_PORT=5193 npx playwright test -c playwright.praesentation.config.ts ps1
import { mkdirSync } from 'node:fs'
import { resolve } from 'node:path'

import { expect, test, type Page } from '@playwright/test'

import { kleineZiele, stationOben, verstoesse } from './messen'

const AUSGABE = resolve(process.env.TP_AUSGABE ?? 'docs/report/praesentation/ps-1')
/** Thema mit Lücke (wie Batu/Emre), alles sicher (wie Lina), kaum etwas sicher (wie Jonas). */
const FAELLE = ['abgestuft', 'allesSicher', 'nichtsSicher']
/** Zusätzlich nur Station 03: die Kette mit einem Kasten (Thema sitzt). */
const NUR_KETTE = ['abgestuftThemaSicher']
const MASSE: ReadonlyArray<[number, number]> = [
  [1180, 820],
  [820, 1180],
]
const nn = (n: number): string => String(n).padStart(2, '0')

async function oeffne(page: Page, fall: string): Promise<void> {
  await page.goto(`/vorschau/praesentation.html?fall=${fall}`)
  await page.locator('.tp').waitFor()
  await page.evaluate(() => document.fonts.ready)
  await page.locator('.tp-intro-los').click()
  await expect(page.locator('.tp-intro')).toBeHidden()
}

async function geheZu(page: Page, station: number): Promise<void> {
  const eintrag = page.locator('.tp-leiste-eintrag').nth(station - 1)
  await eintrag.click()
  await expect(eintrag).toHaveAttribute('aria-current', 'step')
  await expect.poll(() => stationOben(page, station).then(Math.abs)).toBeLessThanOrEqual(1)
}

const foto = async (page: Page, name: string): Promise<void> => {
  mkdirSync(AUSGABE, { recursive: true })
  await page.screenshot({ path: resolve(AUSGABE, `${name}.png`) })
}

test.use({ contextOptions: { reducedMotion: 'reduce' } })

for (const fall of [...FAELLE, ...NUR_KETTE]) {
  for (const [b, h] of MASSE) {
    test(`${fall} ${b}x${h}`, async ({ page }) => {
      await page.setViewportSize({ width: b, height: h })
      await oeffne(page, fall)
      for (const n of NUR_KETTE.includes(fall) ? [3] : [1, 2, 3, 4]) {
        await geheZu(page, n)
        expect(await verstoesse(page, n), `Station ${nn(n)}`).toEqual([])
        expect(await kleineZiele(page), `Station ${nn(n)}`).toEqual([])
        await foto(page, `${fall}_${b}x${h}_${nn(n)}`)
        if (n === 2 && (await page.getByTestId('tp-s2-zahl-ueber').count())) {
          await page.getByTestId('tp-s2-zahl-ueber').click()
          await foto(page, `${fall}_${b}x${h}_02-uebersprungen`)
        }
        if (n === 3 && (await page.getByTestId('tp-s3-glied').count())) {
          const glieder = page.getByTestId('tp-s3-glied')
          // Der zweite Kasten („Hier hakt es“), sonst der einzige.
          await glieder.nth((await glieder.count()) > 1 ? 1 : 0).click()
          await foto(page, `${fall}_${b}x${h}_03-angetippt`)
          if (await page.getByTestId('tp-s3-ganz').count()) {
            await page.getByTestId('tp-s3-ganz').click()
            await expect(page.getByTestId('tp-s3-scroller')).toBeVisible()
            await foto(page, `${fall}_${b}x${h}_03-ganzer-weg`)
            await page.getByTestId('tp-s3-zurueck').click()
          }
        }
      }
    })
  }
}
