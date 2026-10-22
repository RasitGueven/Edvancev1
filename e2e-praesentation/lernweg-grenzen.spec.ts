// Station 03 · volle Karte passt immer (R7-12, Entscheidungen 9–11): keine
// Insel ragt über die Spur hinaus, „+ n weitere“ füllt das Infofeld. Fotos
// (iPad quer) nach docs/report/r7/r7-12/ mit der Endung aus TP_STAND:
//   TP_PORT=5193 TP_STAND=nachher npx playwright test -c playwright.praesentation.config.ts e2e-praesentation/lernweg-grenzen.spec.ts
import { mkdirSync } from 'node:fs'
import { resolve } from 'node:path'

import { expect, test, type Page } from '@playwright/test'

import { lernwegVerstoesse, stationOben } from './messen'

const STAND = process.env.TP_STAND ?? 'nachher'
const ABNAHME = resolve('docs/report/r7/r7-12')

test.use({ contextOptions: { reducedMotion: 'reduce' } })

async function volleKarte(page: Page, fall: string): Promise<void> {
  await page.setViewportSize({ width: 1180, height: 820 })
  await page.goto(`/vorschau/praesentation.html?fall=${fall}`)
  await page.locator('.tp').waitFor()
  await page.evaluate(() => document.fonts.ready)
  await page.locator('.tp-intro-los').click()
  const eintrag = page.locator('.tp-leiste-eintrag').nth(2)
  await eintrag.click()
  await expect(eintrag).toHaveAttribute('aria-current', 'step')
  await expect.poll(() => stationOben(page, 3).then(Math.abs)).toBeLessThanOrEqual(1)
  const ganz = page.getByTestId('tp-s3-ganz')
  if (await ganz.count()) await ganz.click()
  await page.getByTestId('tp-s3-scroller').waitFor()
  await page.waitForTimeout(500)
}

/** Inseln, deren Unterkante unter der sichtbaren Fläche des Scrollers liegt (px). */
async function ueberstand(page: Page): Promise<string[]> {
  return page.getByTestId('tp-s3-scroller').evaluate((sc) => {
    const unten = sc.getBoundingClientRect().bottom
    return [...sc.querySelectorAll<HTMLElement>('[data-insel]')]
      .map((i) => ({ titel: i.querySelector('.tp-s3-insel-titel')?.textContent ?? i.dataset.insel, b: i.getBoundingClientRect().bottom }))
      .filter((i) => i.b > unten + 0.5)
      .map((i) => `${i.titel}: ${(i.b - unten).toFixed(1)} px`)
  })
}

for (const fall of ['sehrViele', 'abgestuft']) {
  test(`volle Karte ${fall} (1180x820)`, async ({ page }) => {
    await volleKarte(page, fall)
    mkdirSync(ABNAHME, { recursive: true })
    await page.screenshot({ path: resolve(ABNAHME, `${fall}_karte_${STAND}.png`) })
    if (STAND !== 'nachher') return
    expect(await ueberstand(page), 'Inseln unter der Spur').toEqual([])
    expect(await lernwegVerstoesse(page), 'Lernweg').toEqual([])
    if (fall === 'sehrViele') {
      const stufe = await page.locator('[data-stufe]').first().getAttribute('data-stufe')
      console.log(`sehrViele: volle Karte auf Stufe ${stufe}`)
    }
  })
}

test('„+ n weitere“ füllt das Infofeld (sehrViele)', async ({ page }) => {
  await volleKarte(page, 'sehrViele')
  const weitere = page.locator('.tp-s3-weitere').first()
  await weitere.scrollIntoViewIfNeeded()
  await weitere.click()
  await expect(page.getByTestId('tp-s3-info')).toContainText('Weitere Bereiche:')
})
