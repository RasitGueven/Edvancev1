// Seite 3 · Lernweg passt immer (R7-12). Ergänzt elternbericht.spec.ts (dort
// für alle Fälle: kein data-ueberlauf, keine Linie durch eine Insel).
//
// Fotos von Seite 3 je Fall nach EB_FOTOS (Vergleich vorher/nachher), die von
// sehrViele und abgestuft (Batu) zusätzlich nach docs/report/r7/r7-12/ mit
// der Endung aus EB_STAND (vorher | nachher):
//   EB_PORT=5192 EB_FOTOS=<ordner> EB_STAND=nachher npx playwright test -c playwright.elternbericht.config.ts lernweg-grenzen
import { mkdirSync } from 'node:fs'
import { resolve } from 'node:path'

import { expect, test } from '@playwright/test'

import { FAELLE } from '../src/lib/report/elternbericht/fixtures'

const FOTOS = process.env.EB_FOTOS ? resolve(process.env.EB_FOTOS) : null
const STAND = process.env.EB_STAND ?? 'nachher'
const ABNAHME = resolve('docs/report/r7/r7-12')
const ABNAHME_FAELLE = new Set(['sehrViele', 'abgestuft'])

for (const name of Object.keys(FAELLE)) {
  test(`Seite 3 ${name}`, async ({ page }) => {
    await page.goto(`/vorschau/elternbericht.html?fall=${name}`)
    await page.waitForSelector('.eb-seite, [data-testid="eb-leer"]')
    await page.evaluate(() => document.fonts.ready)
    if ((await page.locator('.eb-bogen').count()) === 0) return
    await page.emulateMedia({ media: 'print' })
    const seite = page.locator('.eb-seite[data-seite="3"]')
    const weg = seite.getByTestId('eb-s3-weg')
    if ((await weg.count()) === 0) return
    // Die Kürzung läuft über Layout-Effekte; warten, bis die Stufe steht.
    await page.waitForTimeout(300)

    if (name === 'sehrViele' && STAND === 'nachher') {
      await expect(weg).not.toHaveAttribute('data-ueberlauf')
      await expect(seite.locator('.eb-s3-hinweis')).toContainText(
        'Nicht alle Bereiche passen auf diese Seite. Wie viele es je Themenfeld sind, steht auf Seite 2.',
      )
      console.log(`sehrViele: Seite 3 auf Stufe ${await weg.getAttribute('data-stufe')}`)
    }
    if (FOTOS) {
      mkdirSync(FOTOS, { recursive: true })
      await seite.screenshot({ path: resolve(FOTOS, `${name}_s3.png`) })
    }
    if (ABNAHME_FAELLE.has(name)) {
      mkdirSync(ABNAHME, { recursive: true })
      await seite.screenshot({ path: resolve(ABNAHME, `${name}_seite3_${STAND}.png`) })
    }
  })
}
