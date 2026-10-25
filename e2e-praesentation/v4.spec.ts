// Ansichtstests V4-3: Station 04 mit jedem Punkt einmal gewählt — fester Kasten
// (Lage und Größe gleich nach jedem Tippen), nichts im Kasten abgeschnitten,
// Beschriftungen überlappen nicht, Touch-Ziele ≥ 44 px. Dazu Fotos je Punkt.
//
//   TP_PORT=5195 TP_AUSGABE=docs/report/v4/abnahme/v4-3 npx playwright test -c playwright.praesentation.config.ts
import { mkdirSync } from 'node:fs'
import { resolve } from 'node:path'

import { expect, test, type Page } from '@playwright/test'

import { kleineZiele, stationOben, verstoesse } from './messen'

const AUSGABE = resolve(process.env.TP_AUSGABE ?? 'docs/report/v4/abnahme/v4-3')
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
const FOTOS = new Set(['820x1180', '1180x820'])
/** batuV4: drei Lernpfad-Punkte plus Sorgfalt; fahrplanKlp: vier plus Sorgfalt (fünf Punkte). */
const FAELLE = ['batuV4', 'fahrplanKlp', 'fahrplanLang', 'sehrViele']

async function zuStation4(page: Page, fall: string): Promise<void> {
  await page.goto(`/vorschau/praesentation.html?fall=${fall}`)
  await page.locator('.tp').waitFor()
  await page.evaluate(() => document.fonts.ready)
  await page.locator('.tp-intro-los').click()
  const eintrag = page.locator('.tp-leiste-eintrag').nth(3)
  await eintrag.click()
  await expect(eintrag).toHaveAttribute('aria-current', 'step')
  await expect.poll(() => stationOben(page, 4).then(Math.abs)).toBeLessThanOrEqual(1)
}

const kasten = (page: Page) => page.getByTestId('tp-s4v-kasten')

for (const fall of FAELLE) {
  test.describe(`Station 04 · ${fall}`, () => {
    test.use({ contextOptions: { reducedMotion: 'reduce' } })

    for (const [breite, hoehe] of MASSE) {
      const mass = `${breite}x${hoehe}`
      test(`jeder Punkt bei ${mass}`, async ({ page }) => {
        await page.setViewportSize({ width: breite, height: hoehe })
        await zuStation4(page, fall)
        const punkte = page.getByRole('tab')
        const n = await punkte.count()
        expect(n).toBeGreaterThan(0)
        const erst = await kasten(page).boundingBox()

        for (let i = 0; i < n; i++) {
          await punkte.nth(i).click()
          await expect(punkte.nth(i)).toHaveAttribute('aria-selected', 'true')
          const box = await kasten(page).boundingBox()
          expect(box, `Kasten nach Punkt ${i + 1}`).toEqual(erst)
          expect(await verstoesse(page, 4), `Station 04, Punkt ${i + 1}`).toEqual([])
          expect(await kleineZiele(page), `Station 04, Punkt ${i + 1}`).toEqual([])
          // Nichts im Kasten ist abgeschnitten.
          const abgeschnitten = await page
            .getByTestId('tp-s4v-inhalt')
            .evaluate((el) => el.scrollHeight - el.clientHeight)
          expect(abgeschnitten, `Inhalt des Kastens bei Punkt ${i + 1}`).toBeLessThanOrEqual(1)
          if (fall === 'batuV4' && FOTOS.has(mass)) {
            mkdirSync(AUSGABE, { recursive: true })
            await page.screenshot({ path: resolve(AUSGABE, `${fall}_${mass}_04-punkt${i + 1}.png`) })
          }
        }
      })
    }
  })
}

test.describe('Station 04 · Bedienung', () => {
  test.use({ contextOptions: { reducedMotion: 'reduce' } })

  test('zurück, weiter und Pfeiltasten, Kasten bleibt stehen', async ({ page }) => {
    await page.setViewportSize({ width: 1180, height: 820 })
    await zuStation4(page, 'fahrplanKlp')
    const punkte = page.getByRole('tab')
    const erst = await kasten(page).boundingBox()

    await page.getByRole('button', { name: 'weiter' }).click()
    await expect(punkte.nth(1)).toHaveAttribute('aria-selected', 'true')
    await page.getByRole('button', { name: 'zurück' }).click()
    await expect(punkte.nth(0)).toHaveAttribute('aria-selected', 'true')

    await punkte.nth(0).focus()
    await page.keyboard.press('ArrowRight')
    await expect(punkte.nth(1)).toHaveAttribute('aria-selected', 'true')
    await expect(punkte.nth(1)).toBeFocused()
    await page.keyboard.press('ArrowLeft')
    await expect(punkte.nth(0)).toHaveAttribute('aria-selected', 'true')
    expect(await kasten(page).boundingBox()).toEqual(erst)
  })
})

test.describe('Station 02 · Bewegung', () => {
  test.use({ contextOptions: { reducedMotion: 'no-preference' }, viewport: { width: 1180, height: 820 } })

  test('Kästchen ploppen beim ersten Besuch auf', async ({ page }) => {
    await page.goto('/vorschau/praesentation.html?fall=batuV4')
    await page.locator('.tp-intro-los').click()
    await page.locator('.tp-leiste-eintrag').nth(1).click()
    const s2 = page.locator('.tp-station[data-station="2"]')
    await expect(s2).toHaveClass(/\bentered\b/)
    const laufend = (): Promise<string[]> =>
      s2.evaluate((el) =>
        document
          .getAnimations()
          .filter((a) => {
            const ziel = (a.effect as KeyframeEffect | null)?.target
            return ziel instanceof Element && el.contains(ziel)
          })
          .map((a) => (a as CSSAnimation).animationName ?? ''),
      )
    await expect.poll(laufend).toContain('tp-kasten-pop')
  })

  test('Wiederbesuch und prefers-reduced-motion: still', async ({ page }) => {
    await page.goto('/vorschau/praesentation.html?fall=batuV4')
    await page.locator('.tp-intro-los').click()
    await page.locator('.tp-leiste-eintrag').nth(1).click()
    await page.waitForTimeout(300)
    await page.locator('.tp-leiste-eintrag').nth(2).click()
    const s2 = page.locator('.tp-station[data-station="2"]')
    await expect(s2).toHaveClass(/motion-complete/)
    await page.locator('.tp-leiste-eintrag').nth(1).click()
    const unruhig = await s2.evaluate((el) =>
      document
        .getAnimations()
        .filter((a) => a.playState === 'running')
        .filter((a) => {
          const ziel = (a.effect as KeyframeEffect | null)?.target
          return ziel instanceof Element && el.contains(ziel)
        }).length,
    )
    expect(unruhig).toBe(0)
  })
})

test.describe('Station 02 · ruhig', () => {
  test.use({ contextOptions: { reducedMotion: 'reduce' }, viewport: { width: 1180, height: 820 } })

  test('alle Kästchen stehen sofort da', async ({ page }) => {
    await page.goto('/vorschau/praesentation.html?fall=batuV4')
    await page.locator('.tp-intro-los').click()
    await page.locator('.tp-leiste-eintrag').nth(1).click()
    const kaesten = page.getByTestId('tp-s2-kasten')
    await expect(kaesten.first()).toBeVisible()
    const unsichtbar = await kaesten.evaluateAll((els) => els.filter((e) => getComputedStyle(e).opacity !== '1').length)
    expect(unsichtbar).toBe(0)
  })
})
