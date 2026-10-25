// Station 03 · Lernweg (R7-9): Fahrt, Bedienung und Video. Ergänzt die
// Ansichtstests in praesentation.spec.ts (dort je Maß und Fall die Passform).
//
//   TP_PORT=5191 TP_AUSGABE=docs/report/praesentation/abnahme/r7-9 npx playwright test -c playwright.praesentation.config.ts
import { mkdirSync, renameSync, rmSync } from 'node:fs'
import { resolve } from 'node:path'

import { expect, test, type Page } from '@playwright/test'

import { lernwegVerstoesse, stationOben } from './messen'

const AUSGABE = resolve(process.env.TP_AUSGABE ?? 'docs/report/praesentation/abnahme/r7-9')

async function zuStation3(page: Page, fall: string): Promise<void> {
  await page.goto(`/vorschau/praesentation.html?fall=${fall}&v4=aus`)
  await page.locator('.tp').waitFor()
  await page.evaluate(() => document.fonts.ready)
  await page.locator('.tp-intro-los').click()
  const eintrag = page.locator('.tp-leiste-eintrag').nth(2)
  await eintrag.click()
  await expect(eintrag).toHaveAttribute('aria-current', 'step')
  await expect.poll(() => stationOben(page, 3).then(Math.abs)).toBeLessThanOrEqual(1)
  // PS-1: Standard ist die Kette; die volle Karte steht hinter „Ganzen Lernweg zeigen".
  const ganz = page.getByTestId('tp-s3-ganz')
  if (await ganz.count()) await ganz.click()
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

      // Genug Fläche, dass der Pfeil sie sichtbar schiebt (Nachbesserung, Tests).
      const bereich = await sc.evaluate((el) => ({ scroll: el.scrollWidth - el.clientWidth, breite: el.clientWidth }))
      expect(bereich.scroll, `Scrollbereich ${bereich.scroll} px bei ${bereich.breite} px Breite`).toBeGreaterThanOrEqual(1.5 * bereich.breite)

      // Jedes Bild der Schiebe-Phase, im Seitenkontext je Frame gemessen: Spitze bei
      // 55–70 % der Breite, solange die Kamera mitläuft; keine Linie wächst in einem
      // Bild um mehr als 40 Entwurfs-px (auch nicht senkrecht).
      const m = await sc.evaluate(
        (el) =>
          new Promise<{ anteile: number[]; sprung: number }>((fertig) => {
            const anteile: number[] = []
            const vorher = new Map<Element, number>()
            let sprung = 0
            const bild = (): void => {
              if (el.getAttribute('data-phase') !== 'schieben') return fertig({ anteile, sprung })
              const links = el.scrollLeft
              const max = el.scrollWidth - el.clientWidth
              if (links > 0.5 && links < max - 0.5) anteile.push(Number(el.getAttribute('data-spitze')) / el.clientWidth)
              for (const p of el.querySelectorAll<SVGPathElement>('path.tp-s3-linie')) {
                const laenge = p.getTotalLength()
                const gezeichnet = laenge - (parseFloat(p.style.strokeDashoffset) || 0)
                const alt = vorher.get(p)
                if (alt !== undefined) sprung = Math.max(sprung, gezeichnet - alt)
                vorher.set(p, gezeichnet)
              }
              requestAnimationFrame(bild)
            }
            requestAnimationFrame(bild)
          }),
      )
      expect(m.anteile.length, 'gemessene Bilder mit mitlaufender Kamera').toBeGreaterThanOrEqual(60)
      for (const a of m.anteile) {
        expect(a).toBeGreaterThanOrEqual(0.55)
        expect(a).toBeLessThanOrEqual(0.7)
      }
      expect(m.sprung, 'größtes Wachstum einer Linie in einem Bild (Entwurfs-px)').toBeLessThanOrEqual(40)

      // In der Pause (alles aufgedeckt, noch während der ersten Fahrt): Die Linien
      // liegen an den Inseln, wie sie jetzt stehen, nicht wie sie beim Einblenden standen.
      await expect(sc).toHaveAttribute('data-phase', 'pause', { timeout: 10_000 })
      await page.waitForTimeout(1100) // Einblenden der letzten Inseln (1 s) abwarten
      expect(await lernwegVerstoesse(page), 'Lernweg während der ersten Fahrt').toEqual([])

      // Danach: Kamera allein, Pause, zurück; das Gespräch beginnt bei den Grundlagen.
      await expect(sc).toHaveAttribute('data-phase', 'fertig', { timeout: 20_000 })
      await expect.poll(() => sc.evaluate((el) => el.scrollLeft)).toBe(0)
      await expect(zoneAn(page)).toHaveText('Grundlagen')
      await expect(page.getByTestId('tp-s3-hier')).toBeVisible()
    })
  }
})

test.describe('Abbruch der Fahrt (abgestuft)', () => {
  test.use({ contextOptions: { reducedMotion: 'no-preference' } })

  test('Antippen mitten im Schieben: alles steht da, die Ansicht bleibt, wo sie ist', async ({ page }) => {
    test.setTimeout(60_000)
    await page.setViewportSize({ width: 820, height: 1180 })
    await zuStation3(page, 'abgestuft')
    const sc = scroller(page)
    await expect(sc).toHaveAttribute('data-phase', 'schieben', { timeout: 5000 })
    await expect.poll(() => sc.evaluate((el) => el.scrollLeft), { timeout: 10_000 }).toBeGreaterThan(60)
    await page.getByRole('button', { name: /^Wurzeln abschätzen/ }).click()
    const dort = await sc.evaluate((el) => el.scrollLeft)
    await page.waitForTimeout(1500)
    expect(Math.abs((await sc.evaluate((el) => el.scrollLeft)) - dort)).toBeLessThanOrEqual(1)
    await expect(sc).toHaveAttribute('data-phase', 'unterbrochen')
    expect(await page.locator('.tp-s3-insel:not(.tp-s3-da)').count()).toBe(0)
    expect(await lernwegVerstoesse(page), 'Lernweg nach dem Abbruch').toEqual([])
  })
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
  for (const [b, h, datei] of [
    [1180, 820, 'fahrt.webm'],
    [820, 1180, 'fahrt-hoch.webm'],
  ] as const) {
    test(`Fahrt abgestuft ${b}x${h} → ${datei}`, async ({ browser }) => {
      test.setTimeout(90_000)
      mkdirSync(AUSGABE, { recursive: true })
      const roh = resolve(AUSGABE, `video-roh-${b}`)
      const ctx = await browser.newContext({
        viewport: { width: b, height: h },
        reducedMotion: 'no-preference',
        recordVideo: { dir: roh, size: { width: b, height: h } },
      })
      const page = await ctx.newPage()
      await zuStation3(page, 'abgestuft')
      await expect(scroller(page)).toHaveAttribute('data-phase', 'fertig', { timeout: 40_000 })
      await page.waitForTimeout(800)
      const video = page.video()!
      await ctx.close()
      renameSync(await video.path(), resolve(AUSGABE, datei))
      rmSync(roh, { recursive: true, force: true })
    })
  }
})
