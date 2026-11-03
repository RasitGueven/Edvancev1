// PDF für den Mailversand (Bauauftrag LR-2, Abnahme 3).
//
// Für alle FAELLE mit Bogen: bogenZuPdf erzeugt das PDF aus dem Bogen der
// Vorschau. Geprüft: gleiche Seitenzahl wie die Druckfassung (page.pdf im
// Druckmedium), jede Seite A4, höchstens 2,5 MB. Die eingebetteten Seitenbilder
// landen je Seite unter docs/report/lr-2/abnahme/ zum Sichtvergleich mit dem
// Druck-PDF daneben — auf 150 dpi verkleinert, sonst wäre der Ordner über 200 MB.
// Das Mail-PDF selbst nur mit LR2_PDF=1.
//
//   EB_PORT=5183 LR2_AUSGABE=docs/report/lr-2/abnahme npx playwright test -c playwright.elternbericht.config.ts e2e-druck/bogen-pdf.spec.ts
import { mkdirSync, writeFileSync } from 'node:fs'
import { resolve } from 'node:path'

import { expect, test, type Page } from '@playwright/test'

import { FAELLE } from '../src/lib/report/elternbericht/fixtures'

const AUSGABE = resolve(process.env.LR2_AUSGABE ?? 'docs/report/lr-2/abnahme')
const MAX_BYTES = 2_500_000

/** Seitenobjekte, nicht der Seitenbaum (/Pages) — wie elternbericht.spec.ts. */
function pdfSeiten(pdf: Buffer): number {
  return (pdf.toString('latin1').match(/\/Type\s*\/Page(?![s\w])/g) ?? []).length
}

function mediaBoxen(pdf: Buffer): number[][] {
  return [...pdf.toString('latin1').matchAll(/\/MediaBox\s*\[([^\]]+)\]/g)].map((m) => m[1].trim().split(/\s+/).map(Number))
}

/** Die JPEG-Ströme (DCTDecode) in Reihenfolge: genau die Seitenbilder des PDFs. */
function jpegs(pdf: Buffer): Buffer[] {
  const roh = pdf.toString('latin1')
  const raus: Buffer[] = []
  const muster = /\/Filter\s*\/DCTDecode[^]*?stream\r?\n/g
  for (let m = muster.exec(roh); m; m = muster.exec(roh)) {
    const start = m.index + m[0].length
    const strom = pdf.subarray(start, roh.indexOf('endstream', start))
    // Bis zum JPEG-Ende (FF D9); danach folgt nur noch der Zeilenumbruch vor endstream.
    raus.push(strom.subarray(0, strom.lastIndexOf(Buffer.from([0xff, 0xd9])) + 2))
  }
  return raus
}

/** Das Seitenbild auf 1240 px Breite (150 dpi bei A4), im Browser verkleinert. */
async function verkleinert(page: Page, jpeg: Buffer): Promise<string> {
  return page.evaluate(async (b64) => {
    const bild = new Image()
    bild.src = `data:image/jpeg;base64,${b64}`
    await bild.decode()
    const canvas = document.createElement('canvas')
    canvas.width = 1240
    canvas.height = Math.round((bild.naturalHeight * 1240) / bild.naturalWidth)
    canvas.getContext('2d')!.drawImage(bild, 0, 0, canvas.width, canvas.height)
    return canvas.toDataURL('image/jpeg', 0.8).split(',')[1]
  }, jpeg.toString('base64'))
}

for (const name of Object.keys(FAELLE)) {
  test(`PDF für die Mail: ${name}`, async ({ page }) => {
    await page.goto(`/vorschau/elternbericht.html?fall=${name}`)
    await page.waitForSelector('.eb-seite, [data-testid="eb-leer"]')
    await page.evaluate(() => document.fonts.ready)
    if ((await page.locator('.eb-bogen').count()) === 0) return

    const b64 = await page.evaluate(async (fall) => {
      const { bogenZuPdf } = await import('/src/lib/report/bogenPdf.ts')
      const blob = await bogenZuPdf(document.querySelector<HTMLElement>('.eb-bogen')!, `Edvance LSA-Report ${fall}`)
      const bytes = new Uint8Array(await blob.arrayBuffer())
      let s = ''
      for (let i = 0; i < bytes.length; i += 0x8000) s += String.fromCharCode(...bytes.subarray(i, i + 0x8000))
      return btoa(s)
    }, name)
    const pdf = Buffer.from(b64, 'base64')

    await page.emulateMedia({ media: 'print' })
    const druck = await page.pdf({ preferCSSPageSize: true, printBackground: true })

    mkdirSync(AUSGABE, { recursive: true })
    if (process.env.LR2_PDF === '1') writeFileSync(resolve(AUSGABE, `${name}-mail.pdf`), pdf)
    writeFileSync(resolve(AUSGABE, `${name}-druck.pdf`), druck)
    const bilder = jpegs(pdf)
    for (const [i, b] of bilder.entries()) {
      writeFileSync(resolve(AUSGABE, `${name}-seite-${i + 1}.jpg`), Buffer.from(await verkleinert(page, b), 'base64'))
    }

    expect(pdf.length, `${name}: ${pdf.length} Bytes`).toBeLessThanOrEqual(MAX_BYTES)
    expect(pdfSeiten(pdf), name).toBe(pdfSeiten(druck))
    expect(bilder, name).toHaveLength(pdfSeiten(druck))
    const boxen = mediaBoxen(pdf)
    expect(boxen.length, name).toBeGreaterThan(0)
    for (const [x0, y0, x1, y1] of boxen) {
      expect(Math.abs(x1 - x0 - 595.28), `${name}: Breite`).toBeLessThan(0.5)
      expect(Math.abs(y1 - y0 - 841.89), `${name}: Höhe`).toBeLessThan(0.5)
    }
  })
}
