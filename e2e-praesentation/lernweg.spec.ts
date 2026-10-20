// Station 03 · Lernweg (R7-9): Fahrt, Bedienung und Video. Ergänzt die
// Ansichtstests in praesentation.spec.ts (dort je Maß und Fall die Passform).
//
//   TP_PORT=5191 TP_AUSGABE=docs/report/praesentation/abnahme/r7-9 npx playwright test -c playwright.praesentation.config.ts
import { mkdirSync, renameSync, rmSync } from 'node:fs'
import { resolve } from 'node:path'

import { expect, test, type Page } from '@playwright/test'

import { stationOben } from './messen'

const AUSGABE = resolve(process.env.TP_AUSGABE ?? 'docs/report/praesentation/abnahme/r7-9')

async function zuStation3(page: Page, fall: string): Promise<void> {
  await page.goto(`/vorschau/praesentation.html?fall=${fall}`)
  await page.locator('.tp').waitFor()
  await page.evaluate(() => document.fonts.ready)
  await page.locator('.tp-intro-los').click()
  const eintrag = page.locator('.tp-leiste-eintrag').nth(2)
  await eintrag.click()
  await expect(eintrag).toHaveAttribute('aria-current', 'step')
  await expect.poll(() => stationOben(page, 3).then(Math.abs)).toBeLessThanOrEqual(1)
}

const scroller = (page: Page) => page.getByTestId('tp-s3-scroller')
const zoneAn = (page: Page) => page.locator('.tp-s3-zonennamen .tp-s3-an')

test.describe('Fahrt (abgestuft)', () => {
  test.use({ contextOptions: { reducedMotion: 'no-preference' } })

  for (const [b, h] of [
    [1180, 820],
    [820, 1180],
  ] as const) {
    test(`Pfeil und Fläche laufen gemeinsam, Ende bei den Grundlagen · ${b}x${h}`, async ({ page }) => {
      test.setTimeout(90_000)
      await page.setViewportSize({ width: b, height: h })
      await zuStation3(page, 'abgestuft')
      const sc = scroller(page)
      await expect(sc).toHaveAttribute('data-phase', 'schieben', { timeout: 5000 })

      // Jedes Bild, solange die Kamera mitläuft (im Seitenkontext je Frame gemessen,
      // damit Last auf dem Rechner keine Bilder verschluckt): Spitze bei 55–70 % der Breite.
      const bilder = await sc.evaluate(
        (el) =>
          new Promise<{ anteil: number; links: number; max: number }[]>((fertig) => {
            const liste: { anteil: number; links: number; max: number }[] = []
            const bild = (): void => {
              if (el.getAttribute('data-phase') !== 'schieben') return fertig(liste)
              const links = el.scrollLeft
              const max = el.scrollWidth - el.clientWidth
              const spitze = Number(el.getAttribute('data-spitze'))
              if (links > 0.5 && links < max - 0.5) liste.push({ anteil: spitze / el.clientWidth, links, max })
              requestAnimationFrame(bild)
            }
            requestAnimationFrame(bild)
          }),
      )
      expect(bilder.length, 'gemessene Bilder mit mitlaufender Kamera').toBeGreaterThan(5)
      for (const x of bilder) {
        expect(x.anteil, JSON.stringify(x)).toBeGreaterThanOrEqual(0.55)
        expect(x.anteil, JSON.stringify(x)).toBeLessThanOrEqual(0.7)
      }

      // Danach: Kamera allein, Pause, zurück; das Gespräch beginnt bei den Grundlagen.
      await expect(sc).toHaveAttribute('data-phase', 'fertig', { timeout: 20_000 })
      await expect.poll(() => sc.evaluate((el) => el.scrollLeft)).toBe(0)
      await expect(zoneAn(page)).toHaveText('Grundlagen')
      await expect(page.getByTestId('tp-s3-hier')).toBeVisible()
    })
  }
})

test.describe('Bedienung (abgestuft, ruhig)', () => {
  test.use({ contextOptions: { reducedMotion: 'reduce' } })

  test('Rad senkrecht in Station 03 führt zu Station 04', async ({ page }) => {
    await page.setViewportSize({ width: 1180, height: 820 })
    await zuStation3(page, 'abgestuft')
    const box = (await scroller(page).boundingBox())!
    await page.mouse.move(box.x + box.width / 2, box.y + box.height / 2)
    await page.mouse.wheel(0, 600)
    await expect(page.locator('.tp-leiste-eintrag').nth(3)).toHaveAttribute('aria-current', 'step')
  })

  test('Maus ziehen über 60 px rastet in der nächsten Zone ein', async ({ page }) => {
    // Hochformat: Dort ist die Fläche breiter als das Bild (im Querformat passt sie bei s ≈ 0,6 fast ganz hinein).
    await page.setViewportSize({ width: 820, height: 1180 })
    await zuStation3(page, 'abgestuft')
    await expect(zoneAn(page)).toHaveText('Grundlagen')
    const box = (await scroller(page).boundingBox())!
    const y = box.y + box.height - 12 // unten in der Fläche, nicht auf einer Insel
    await page.mouse.move(box.x + 300, y)
    await page.mouse.down()
    await page.mouse.move(box.x + 260, y, { steps: 3 })
    await page.mouse.move(box.x + 210, y, { steps: 3 })
    await page.mouse.up()
    await expect(zoneAn(page)).toHaveText('Weiterführend')
    const links = await scroller(page).evaluate((el) => el.scrollLeft)
    const rast = await page.locator('.tp-s3-rastpunkt').nth(1).evaluate((el) => (el as HTMLElement).offsetLeft)
    expect(Math.abs(links - rast)).toBeLessThanOrEqual(2)
  })

  test('fertiger Zustand: Fotos von Station 03 (abgestuft)', async ({ page }) => {
    mkdirSync(AUSGABE, { recursive: true })
    for (const [b, h] of [
      [820, 1180],
      [1180, 820],
    ] as const) {
      await page.setViewportSize({ width: b, height: h })
      await zuStation3(page, 'abgestuft')
      await page.screenshot({ path: resolve(AUSGABE, `abgestuft_${b}x${h}_03_lernweg.png`) })
    }
  })
})

test.describe('Video', () => {
  test('Fahrt abgestuft 1180x820 → fahrt.webm', async ({ browser }) => {
    test.setTimeout(90_000)
    mkdirSync(AUSGABE, { recursive: true })
    const ctx = await browser.newContext({
      viewport: { width: 1180, height: 820 },
      reducedMotion: 'no-preference',
      recordVideo: { dir: resolve(AUSGABE, 'video-roh'), size: { width: 1180, height: 820 } },
    })
    const page = await ctx.newPage()
    await zuStation3(page, 'abgestuft')
    await expect(scroller(page)).toHaveAttribute('data-phase', 'fertig', { timeout: 40_000 })
    await page.waitForTimeout(800)
    const video = page.video()!
    await ctx.close()
    renameSync(await video.path(), resolve(AUSGABE, 'fahrt.webm'))
    rmSync(resolve(AUSGABE, 'video-roh'), { recursive: true, force: true })
  })
})
