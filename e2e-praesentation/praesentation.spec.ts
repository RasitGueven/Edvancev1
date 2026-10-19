// Ansichtstests der Tablet-Präsentation (T2, Entscheidung 10).
//
// Geht ALLE Fälle aus PRAESENTATION_FAELLE und alle Maße aus Entscheidung 10
// der Anforderung durch — neue Fälle oder neue Inhalte der Stationen (T3, T4)
// brauchen hier keine Änderung. Die Verträge (data-tp-*) stehen in messen.ts.
//
//   TP_PORT=5185 TP_AUSGABE=docs/report/praesentation/abnahme/t2 npx playwright test -c playwright.praesentation.config.ts
import { mkdirSync } from 'node:fs'
import { resolve } from 'node:path'

import { expect, test, type Page } from '@playwright/test'

import { PRAESENTATION_FAELLE } from '../src/lib/report/praesentation/fixtures'
import { kleineZiele, stationOben, verstoesse } from './messen'

const AUSGABE = resolve(process.env.TP_AUSGABE ?? 'docs/report/praesentation/abnahme/t2')
const MASSE: ReadonlyArray<[number, number]> = [
  [820, 1180],
  [820, 1100],
  [1180, 820],
  [1180, 740],
  [744, 1133],
  [744, 1060],
  [1133, 744],
  [1032, 1376],
  [1376, 1032],
]
/** Bei diesen Maßen entstehen Bildschirmfotos aller Fälle und Stationen. */
const FOTOS = new Set(['820x1180', '1180x820'])
const STATIONEN = [1, 2, 3, 4]
const nn = (n: number): string => String(n).padStart(2, '0')

async function oeffne(page: Page, fall: string): Promise<void> {
  await page.goto(`/vorschau/praesentation.html?fall=${fall}`)
  await page.locator('.tp').waitFor()
  await page.evaluate(() => document.fonts.ready)
}

/** Über die Leiste zu einer Station; wartet, bis sie oben steht. */
async function geheZu(page: Page, station: number): Promise<void> {
  const eintrag = page.locator('.tp-leiste-eintrag').nth(station - 1)
  await eintrag.click()
  await expect(eintrag).toHaveAttribute('aria-current', 'step')
  await expect.poll(() => stationOben(page, station).then(Math.abs)).toBeLessThanOrEqual(1)
}

/** Die Zeile mit den meisten Bereichen in Station 02 öffnen, falls es Zeilen gibt. */
async function oeffneGroessteZeile(page: Page): Promise<boolean> {
  const zeilen = page.locator('.tp-station[data-station="2"] [data-tp-zeile]')
  if ((await zeilen.count()) === 0) return false
  const index = await zeilen.evaluateAll((els) => {
    const n = els.map((el) => Number(el.getAttribute('data-tp-bereiche') ?? 0))
    return n.indexOf(Math.max(...n))
  })
  const knopf = zeilen.nth(index).locator('[aria-expanded]').first()
  await knopf.click()
  await expect(knopf).toHaveAttribute('aria-expanded', 'true')
  return true
}

for (const fall of Object.keys(PRAESENTATION_FAELLE)) {
  test.describe(fall, () => {
    test.use({ reducedMotion: 'reduce' })

    for (const [breite, hoehe] of MASSE) {
      const mass = `${breite}x${hoehe}`

      test(`passt bei ${mass}`, async ({ page }) => {
        await page.setViewportSize({ width: breite, height: hoehe })
        await oeffne(page, fall)

        if ((await page.locator('.tp-station').count()) === 0) {
          // Keine Rechnung möglich (ohne Katalog / ohne Kompetenzen): Hinweis mit Schließen.
          await expect(page.getByTestId('tp-leer')).toBeVisible()
          expect(await kleineZiele(page)).toEqual([])
          return
        }

        await page.locator('.tp-intro-los').click()
        await expect(page.locator('.tp-intro')).toBeHidden()

        for (const n of STATIONEN) {
          await geheZu(page, n)
          expect(await verstoesse(page, n), `Station ${nn(n)}`).toEqual([])
          expect(await kleineZiele(page), `Station ${nn(n)}`).toEqual([])
          if (FOTOS.has(mass)) {
            mkdirSync(AUSGABE, { recursive: true })
            await page.screenshot({ path: resolve(AUSGABE, `${fall}_${mass}_${nn(n)}.png`) })
          }
        }

        await geheZu(page, 2)
        if (await oeffneGroessteZeile(page)) {
          expect(await verstoesse(page, 2), 'Station 02 mit Detail').toEqual([])
          expect(await kleineZiele(page), 'Station 02 mit Detail').toEqual([])
        }
      })
    }
  })
}

test.describe('Bewegung und Bedienung (ilkay)', () => {
  for (const [breite, hoehe] of [MASSE[0], MASSE[2]]) {
    test(`bei ${breite}x${hoehe}`, async ({ page }) => {
      await page.setViewportSize({ width: breite, height: hoehe })
      await oeffne(page, 'ilkay')

      // Intro zuerst, Kopf und Leiste noch nicht.
      const intro = page.locator('.tp-intro')
      await expect(intro).toBeVisible()
      await expect(page.locator('.tp-kopf')).toBeHidden()
      await expect(page.locator('.tp-leiste')).toBeHidden()
      await page.waitForTimeout(2300) // alles steht nach etwa 2,2 s
      if (breite === 820) {
        mkdirSync(AUSGABE, { recursive: true })
        await page.screenshot({ path: resolve(AUSGABE, `ilkay_${breite}x${hoehe}_intro.png`) })
      }

      // „Gemeinsam ansehen" führt zu 01; danach verlässt das Intro den Fluss, ohne Sprung.
      await page.locator('.tp-intro-los').click()
      await expect(page.locator('.tp-leiste-eintrag').first()).toHaveAttribute('aria-current', 'step')
      await expect(intro).toBeHidden()
      await expect(page.locator('.tp-kopf')).toBeVisible()
      expect(Math.abs(await stationOben(page, 1))).toBeLessThanOrEqual(1)
      await page.waitForTimeout(500)
      expect(Math.abs(await stationOben(page, 1)), 'kein Sprung nach dem Intro').toBeLessThanOrEqual(1)
      await expect(intro).toBeHidden()

      // Erster Besuch von 02 mit Bewegung, Wiederbesuch still.
      const s2 = page.locator('.tp-station[data-station="2"]')
      await geheZu(page, 2)
      await expect(s2).toHaveClass(/\bentered\b/)
      await expect(s2).not.toHaveClass(/motion-complete/)
      await page.waitForTimeout(4000)
      await geheZu(page, 3)
      await expect(s2).toHaveClass(/motion-complete/)
      await page.locator('.tp-leiste-eintrag').nth(1).click()
      const unruhig = await s2.evaluate((el) => ({
        laufend: document
          .getAnimations()
          .filter((a) => a.playState === 'running')
          .filter((a) => {
            const ziel = (a.effect as KeyframeEffect | null)?.target
            return ziel instanceof Element && el.contains(ziel)
          }).length,
        verdeckt: [...el.querySelectorAll('.tp-reveal')].filter((r) => getComputedStyle(r).opacity !== '1').length,
      }))
      expect(unruhig, 'Wiederbesuch von 02 ohne Animation').toEqual({ laufend: 0, verdeckt: 0 })
      await expect.poll(() => stationOben(page, 2).then(Math.abs)).toBeLessThanOrEqual(1)

      // Höchstens ein Detail offen (sobald T3 Zeilen liefert).
      const knoepfe = s2.locator('[data-tp-zeile] [aria-expanded]')
      if ((await knoepfe.count()) >= 2) {
        await knoepfe.nth(0).click()
        await knoepfe.nth(1).click()
        await expect(s2.locator('[data-tp-zeile] [aria-expanded="true"]')).toHaveCount(1)
      }

      // Tippen in der Leiste springt; das Logo führt zu 01.
      await geheZu(page, 4)
      await page.locator('.tp-marke').click()
      await expect(page.locator('.tp-leiste-eintrag').first()).toHaveAttribute('aria-current', 'step')
      await expect.poll(() => stationOben(page, 1).then(Math.abs)).toBeLessThanOrEqual(1)

      // Schließen führt zur Liste zurück.
      await page.locator('.tp-schliessen').click()
      await expect(page.locator('a[data-fall="ilkay"]')).toBeVisible()
      await expect(page.locator('.tp')).toHaveCount(0)
    })
  }
})
