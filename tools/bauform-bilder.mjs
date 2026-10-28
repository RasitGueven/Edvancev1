// bauform-bilder.mjs — rendert die Figuren-SVGs des Blindloesers (docs/reihe1/A/blindloeser/<KEY>/*.svg) zu PNG,
// damit der Blindloeser das Bild sieht wie das Kind. Aufruf: node tools/bauform-bilder.mjs <ordner> …
import { readdirSync, readFileSync } from 'node:fs'
import { join } from 'node:path'
import { chromium } from 'playwright'

const browser = await chromium.launch()
const page = await browser.newPage({ viewport: { width: 600, height: 600 } })
for (const ordner of process.argv.slice(2)) {
  for (const datei of readdirSync(ordner).filter((d) => d.endsWith('.svg'))) {
    await page.setContent(`<body style="margin:0;background:#fff">${readFileSync(join(ordner, datei), 'utf8')}</body>`)
    await page.locator('svg').first().screenshot({ path: join(ordner, datei.replace(/\.svg$/, '.png')) })
  }
}
await browser.close()
