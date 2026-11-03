// TP-L1: Die Präsentation füllt Laptop und große Bildschirme. Die Bühne
// (iPad quer, 1180 × 820) wird per CSS zoom gleichmäßig vergrößert; geprüft
// wird, dass dabei nichts überläuft, die Maße mitwachsen und alle Messungen
// in Bühnen-px rechnen (Entscheidung 5).
//
//   TP_PORT=5185 TP_AUSGABE=docs/report/praesentation/abnahme/laptop npx playwright test -c playwright.praesentation.config.ts laptop
// WebKit zusätzlich mit TP_WEBKIT=1. Abnahmebilder entstehen nur in Chromium.
import { mkdirSync } from 'node:fs'
import { resolve } from 'node:path'

import { expect, test, type Page } from '@playwright/test'

import { buehnenFaktor } from '../src/components/edvance/praesentation/useBuehnenZoom'
import { introVerstoesse, kleineZiele, lernwegVerstoesse, stationOben, verstoesse } from './messen'

const AUSGABE = resolve(process.env.TP_AUSGABE ?? 'docs/report/praesentation/abnahme/laptop')
const MASSE: ReadonlyArray<[number, number]> = [
  [1440, 900],
  [1920, 1080],
  [2560, 1440],
]
/** Wie in lernweg.spec.ts (Lernweg vor V4) und mit Fahrplan (V4). */
const FAELLE: ReadonlyArray<{ fall: string; v4: boolean }> = [
  { fall: 'abgestuft', v4: false },
  { fall: 'batuV4', v4: true },
]
const nn = (n: number): string => String(n).padStart(2, '0')

async function oeffne(page: Page, fall: string, v4: boolean): Promise<void> {
  await page.goto(`/vorschau/praesentation.html?fall=${fall}${v4 ? '' : '&v4=aus'}`)
  await page.locator('.tp').waitFor()
  await page.evaluate(() => document.fonts.ready)
}

async function geheZu(page: Page, station: number): Promise<void> {
  const eintrag = page.locator('.tp-leiste-eintrag').nth(station - 1)
  await eintrag.click()
  await expect(eintrag).toHaveAttribute('aria-current', 'step')
  await expect.poll(() => stationOben(page, station).then(Math.abs)).toBeLessThanOrEqual(1)
}

const zoom = (page: Page): Promise<number> =>
  page.locator('.tp').evaluate((el) => Number((el as HTMLElement).style.getPropertyValue('--tp-zoom')))

/** Titel der Station zur Bühnenbreite, beides in Bühnen-px. */
const titelAnteil = (page: Page, n: number): Promise<number> =>
  page.evaluate((nr) => {
    const tp = document.querySelector<HTMLElement>('.tp')!
    const titel = document.querySelector(`.tp-station[data-station="${nr}"] .tp-titel`)!
    return parseFloat(getComputedStyle(titel).fontSize) / tp.offsetWidth
  }, n)

/**
 * Station 03: Die Kette läuft unter den Karten durch, ihre Enden liegen unter
 * der ersten und der letzten Karte (sichtbar setzt sie an deren Kanten an). In
 * der vollen Karte beginnt jede Linie an einer Kartenkante und ihre
 * Spitze endet an einer. Liefert die Abweichungen in Bildschirm-px über 1 px.
 */
const linienAbweichung = (page: Page): Promise<string[]> =>
  page.evaluate(() => {
    const s = document.querySelector('.tp-station[data-station="3"]')!
    const f: string[] = []
    const linie = s.querySelector('.tp-s3-kette-linie')
    const glieder = [...s.querySelectorAll('[data-testid="tp-s3-glied"]')]
    if (linie && glieder.length > 1) {
      const l = linie.getBoundingClientRect()
      const a = glieder[0].getBoundingClientRect()
      const b = glieder[glieder.length - 1].getBoundingClientRect()
      if (l.left < a.left + 1 || l.left > a.right - 1) f.push(`Kette beginnt bei ${l.left.toFixed(1)}, erste Karte ${a.left.toFixed(1)}–${a.right.toFixed(1)}`)
      if (l.right < b.left + 1 || l.right > b.right - 1) f.push(`Kette endet bei ${l.right.toFixed(1)}, letzte Karte ${b.left.toFixed(1)}–${b.right.toFixed(1)}`)
      const kanteA = Math.abs(l.top + l.height / 2 - (a.top + a.height / 2))
      if (kanteA > 1) f.push(`Kette sitzt ${kanteA.toFixed(2)} px neben der Kartenmitte`)
    }
    const karten = [...s.querySelectorAll('[data-insel]')].map((el) => el.getBoundingClientRect())
    const anKante = (x: number, y: number): number => {
      let best = Infinity
      for (const r of karten) if (y >= r.top - 1 && y <= r.bottom + 1) best = Math.min(best, Math.abs(x - r.left), Math.abs(x - r.right))
      return best
    }
    for (const p of s.querySelectorAll<SVGPathElement>('path.tp-s3-linie')) {
      const q = new DOMPoint(p.getPointAtLength(0).x, p.getPointAtLength(0).y).matrixTransform(p.getScreenCTM()!)
      const d = anKante(q.x, q.y)
      if (d > 1) f.push(`Linie beginnt ${d.toFixed(2)} px neben der Kartenkante`)
    }
    for (const p of s.querySelectorAll<SVGPathElement>('path.tp-s3-spitze')) {
      const bb = p.getBBox()
      const ctm = p.getScreenCTM()!
      const enden = [bb.x, bb.x + bb.width].map((x) => new DOMPoint(x, bb.y + bb.height / 2).matrixTransform(ctm))
      const d = Math.min(...enden.map((q) => anKante(q.x, q.y)))
      if (d > 1) f.push(`Spitze endet ${d.toFixed(2)} px neben der Kartenkante`)
    }
    return f
  })

test.use({ contextOptions: { reducedMotion: 'reduce' } })

for (const { fall, v4 } of FAELLE) {
  test(`Bezug bei 1180x820 und alle Größen · ${fall}${v4 ? '' : ' (vor V4)'}`, async ({ page }, info) => {
    test.setTimeout(180_000)
    const name = `${fall}${v4 ? '' : '-lernweg'}`

    // Bezug: Titel zur Bühnenbreite auf dem iPad.
    await page.setViewportSize({ width: 1180, height: 820 })
    await oeffne(page, fall, v4)
    expect(await zoom(page)).toBe(1)
    await page.locator('.tp-intro-los').click()
    const bezug: number[] = []
    for (const n of [1, 2, 3, 4]) {
      await geheZu(page, n)
      bezug[n] = await titelAnteil(page, n)
    }

    for (const [b, h] of MASSE) {
      const mass = `${b}x${h}`
      await page.setViewportSize({ width: b, height: h })
      await oeffne(page, fall, v4)
      expect(await zoom(page), `--tp-zoom bei ${mass}`).toBeCloseTo(buehnenFaktor(b, h), 6)
      expect(await introVerstoesse(page), `Intro ${mass}`).toEqual([])
      const foto = async (teil: string): Promise<void> => {
        if (info.project.name !== 'chromium') return
        mkdirSync(AUSGABE, { recursive: true })
        await page.screenshot({ path: resolve(AUSGABE, `${name}_${mass}_${teil}.png`) })
      }
      await foto('00')

      await page.locator('.tp-intro-los').click()
      await expect(page.locator('.tp-intro')).toBeHidden()
      for (const n of [1, 2, 3, 4]) {
        await geheZu(page, n)
        expect(await verstoesse(page, n), `Station ${nn(n)} ${mass}`).toEqual([])
        expect(await kleineZiele(page), `Station ${nn(n)} ${mass}`).toEqual([])
        const anteil = await titelAnteil(page, n)
        expect(Math.abs(anteil / bezug[n] - 1), `Titel/Bühne Station ${nn(n)} ${mass}: ${anteil} statt ${bezug[n]}`).toBeLessThanOrEqual(0.02)
        await foto(nn(n))

        if (n === 3 && !v4) {
          expect(await linienAbweichung(page), `Kette ${mass}`).toEqual([])
          await page.getByTestId('tp-s3-ganz').click()
          await expect(page.getByTestId('tp-s3-scroller')).toBeVisible()
          expect(await page.locator('path.tp-s3-linie').count()).toBeGreaterThan(0)
          expect(await linienAbweichung(page), `Ganzer Lernweg ${mass}`).toEqual([])
          expect(await lernwegVerstoesse(page), `Ganzer Lernweg ${mass}`).toEqual([])
          await foto('03-ganzer-weg')
          await page.getByTestId('tp-s3-zurueck').click()
        }
      }
    }
  })
}

test('iPad Pro 13" quer (1376x1032) wird vergrößert und läuft nirgends über', async ({ page }) => {
  await page.setViewportSize({ width: 1376, height: 1032 })
  await oeffne(page, 'batuV4', true)
  expect(await zoom(page)).toBeCloseTo(buehnenFaktor(1376, 1032), 6)
  expect(await zoom(page)).toBeGreaterThan(1)
  await page.locator('.tp-intro-los').click()
  for (const n of [1, 2, 3, 4]) {
    await geheZu(page, n)
    expect(await verstoesse(page, n), `Station ${nn(n)}`).toEqual([])
  }
})

test.describe('Messungen in Bühnen-px (1920x1080)', () => {
  test('Ziehen in Station 03: der Inhalt folgt dem Zeiger 1:1', async ({ page }) => {
    await page.setViewportSize({ width: 1920, height: 1080 })
    await oeffne(page, 'abgestuft', false)
    await page.locator('.tp-intro-los').click()
    await geheZu(page, 3)
    await page.getByTestId('tp-s3-ganz').click()
    const sc = page.getByTestId('tp-s3-scroller')
    await expect(sc).toBeVisible()
    const f = await zoom(page)
    const vorher = await sc.evaluate((el) => el.scrollLeft)
    const box = (await sc.boundingBox())!
    const y = box.y + box.height - 12 // unten in der Fläche, nicht auf einer Insel
    await page.mouse.move(box.x + 600, y)
    await page.mouse.down()
    await page.mouse.move(box.x + 560, y, { steps: 4 })
    await page.mouse.move(box.x + 500, y, { steps: 4 })
    // Vor dem Loslassen messen: danach rastet die Ansicht ein.
    const verschoben = ((await sc.evaluate((el) => el.scrollLeft)) - vorher) * f
    await page.mouse.up()
    expect(Math.abs(verschoben - 100), `Inhalt um ${verschoben.toFixed(1)} px statt 100 px`).toBeLessThanOrEqual(2)
  })

  test.describe('Zeile in Sicht', () => {
    // Mit Bewegung: im ruhigen Modus misst holeInSicht vor dem Ende der Öffnung.
    test.use({ contextOptions: { reducedMotion: 'no-preference' } })

    test('Station 02: die geöffnete Zeile ist ganz zu sehen, nicht weiter gescrollt als nötig', async ({ page }) => {
      await page.setViewportSize({ width: 1920, height: 1080 })
      await oeffne(page, 'batuV4', true)
      await page.locator('.tp-intro-los').click()
      await geheZu(page, 2)
      await page.waitForTimeout(4000) // erster Besuch: Zeilen und Fußzeile blenden bis 3,6 s ein (rahmen.css)
      const liste = page.locator('.tp-station[data-station="2"] [data-tp-liste]')
      // Bei 1920 × 1080 passen alle Zeilen; die Liste wird für den Test kürzer, damit sie
      // ein gutes Stück scrollen muss (mit Bildschirm-px statt Bühnen-px wären es gut 20 px zu viel).
      await liste.evaluate((el) => {
        ;(el as HTMLElement).style.maxHeight = '260px'
        el.scrollTop = 0
      })
      const zeile = liste.locator('[data-tp-zeile]').nth(2)
      await zeile.locator('[aria-expanded]').first().click()
      await expect(zeile.locator('[aria-expanded]').first()).toHaveAttribute('aria-expanded', 'true')
      await page.waitForTimeout(1500) // Öffnen (400 ms) und weiches Scrollen
      const f = await zoom(page)
      const m = await liste.evaluate((el, i) => {
        const l = el.getBoundingClientRect()
        const r = el.querySelectorAll('[data-tp-zeile]')[i].getBoundingClientRect()
        return { oben: r.top - l.top, abstandUnten: l.bottom - r.bottom, scroll: el.scrollTop }
      }, 2)
      expect(m.scroll, 'die Liste hat gescrollt').toBeGreaterThan(0)
      expect(m.oben, 'Zeile oben ganz zu sehen').toBeGreaterThanOrEqual(-0.5)
      // Unten genau der Rand von 10 Bühnen-px, nicht mehr.
      expect(Math.abs(m.abstandUnten - 10 * f), `Abstand unten ${m.abstandUnten.toFixed(2)} px statt ${(10 * f).toFixed(2)}`).toBeLessThanOrEqual(1)
    })
  })
})
