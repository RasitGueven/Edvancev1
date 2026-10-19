// Druck-Tests des Eltern-Berichts R7 (Bauauftrag R7, Entscheidung 9).
//
// Geht ALLE Fälle aus FAELLE durch — neue Fälle oder neue Seiteninhalte
// (R7-3, R7-4) brauchen hier keine Änderung. Je Fall: Schrift geladen, kein
// Inhalt läuft über, Kopf und Fuß liegen auf den Maßen aus dem Maßblatt E7
// (±1 pt, gemessen an den gezeichneten Teilen), und das PDF hat fünf Seiten.
import { mkdirSync, writeFileSync } from 'node:fs'
import { resolve } from 'node:path'

import { expect, test, type Page } from '@playwright/test'

import { FAELLE } from '../src/lib/report/elternbericht/fixtures'

const AUSGABE = resolve(process.env.EB_AUSGABE ?? 'docs/report/r7/abnahme/r7-2')
const PT = 4 / 3 // CSS-px je pt
const TOLERANZ = 1 // pt
const NAV_X = [484, 497, 510, 523, 536]

type Rechteck = { x: number; y: number; b: number; h: number }

/** Lage eines Elements relativ zur Seite, in pt. */
async function lage(page: Page, seite: number, selektor: string): Promise<Rechteck[]> {
  return page.evaluate(
    ({ seite, selektor, PT }) => {
      const s = document.querySelector(`.eb-seite[data-seite="${seite}"]`)!
      const o = s.getBoundingClientRect()
      const treffer = selektor === ':scope' ? [s] : [...s.querySelectorAll(selektor)]
      return treffer.map((el) => {
        const r = el.getBoundingClientRect()
        return { x: (r.left - o.left) / PT, y: (r.top - o.top) / PT, b: r.width / PT, h: r.height / PT }
      })
    },
    { seite, selektor, PT },
  )
}

function nahe(ist: number, soll: number, was: string): void {
  expect(Math.abs(ist - soll), `${was}: ${ist.toFixed(2)} statt ${soll}`).toBeLessThanOrEqual(TOLERANZ)
}

async function pruefeSeiten(page: Page, testlauf: boolean, medium: string): Promise<void> {
  const seiten = await page.locator('.eb-seite').count()
  expect(seiten, medium).toBe(5)

  for (let n = 1; n <= 5; n++) {
    const wo = `${medium}, Seite ${n}`
    const [seite] = await lage(page, n, ':scope')
    nahe(seite.b, 595.28, `${wo} Breite`)
    nahe(seite.h, 841.89, `${wo} Höhe`)

    // Kein Überlauf: der Inhalt passt in seinen Kasten, und der endet bei y 800.
    const inhalt = await page.evaluate((n) => {
      const el = document.querySelector<HTMLElement>(`.eb-seite[data-seite="${n}"] .eb-inhalt`)!
      return { scroll: el.scrollHeight, client: el.clientHeight }
    }, n)
    expect(inhalt.scroll, `${wo}: Inhalt läuft über`).toBeLessThanOrEqual(inhalt.client)
    const [kasten] = await lage(page, n, '.eb-inhalt')
    expect(kasten.y + kasten.h, `${wo}: Inhaltskasten endet unter y 800`).toBeLessThanOrEqual(800 + 0.01)

    // Kopf- und Fußlinie (horizontale Linien: Oberkante = y).
    const [kopf] = await lage(page, n, '.eb-kopflinie')
    nahe(kopf.y, 78, `${wo} Kopflinie y`)
    nahe(kopf.x, 44, `${wo} Kopflinie x`)
    nahe(kopf.x + kopf.b, 551, `${wo} Kopflinie Ende`)
    const [fuss] = await lage(page, n, '.eb-fusslinie')
    nahe(fuss.y, 810, `${wo} Fußlinie y`)
    nahe(fuss.x + fuss.b, 551, `${wo} Fußlinie Ende`)

    // Navigationspunkte: Mitte bei x 484 … 536, y 39, Ø 6,8; genau einer aktiv.
    const punkte = await lage(page, n, '.eb-nav-punkt')
    expect(punkte, wo).toHaveLength(5)
    punkte.forEach((p, i) => {
      nahe(p.x + p.b / 2, NAV_X[i], `${wo} Punkt ${i + 1} x`)
      nahe(p.y + p.h / 2, 39, `${wo} Punkt ${i + 1} y`)
      nahe(p.b, 6.8, `${wo} Punkt ${i + 1} Ø`)
    })
    const aktiv = await lage(page, n, '.eb-nav-punkt-aktiv')
    expect(aktiv, wo).toHaveLength(1)
    nahe(aktiv[0].x + aktiv[0].b / 2, NAV_X[n - 1], `${wo} aktiver Punkt`)

    // Chip „Testdaten“ (381,30), 82 × 21 — nur im Testlauf.
    const chip = await lage(page, n, '.eb-chip')
    if (testlauf) {
      expect(chip, wo).toHaveLength(1)
      nahe(chip[0].x, 381, `${wo} Chip x`)
      nahe(chip[0].y, 30, `${wo} Chip y`)
      nahe(chip[0].b, 82, `${wo} Chip Breite`)
      nahe(chip[0].h, 21, `${wo} Chip Höhe`)
    } else {
      expect(chip, wo).toHaveLength(0)
    }
  }
}

/** Seiten im PDF: die Seitenobjekte, nicht der Seitenbaum (/Pages). */
function pdfSeiten(pdf: Buffer): number {
  return (pdf.toString('latin1').match(/\/Type\s*\/Page(?![s\w])/g) ?? []).length
}

for (const [name, fall] of Object.entries(FAELLE)) {
  test(`Druckbogen ${name}`, async ({ page }) => {
    await page.goto(`/vorschau/elternbericht.html?fall=${name}`)
    await page.waitForSelector('.eb-seite, [data-testid="eb-leer"]')
    await page.evaluate(() => document.fonts.ready)

    // Ohne Katalog oder ohne geprüfte Bereiche gibt es keinen Bogen (Entscheidung 3).
    if ((await page.locator('.eb-bogen').count()) === 0) {
      await expect(page.getByTestId('eb-leer')).toBeVisible()
      return
    }

    // Die Schriften des Musters sind wirklich geladen, nicht der Rückfall.
    // (document.fonts.check gäbe auch ohne geladene Schrift true zurück.)
    const geladen = await page.evaluate(() =>
      [...document.fonts]
        .filter((f) => f.status === 'loaded')
        .map((f) => `${f.family.replace(/["']/g, '')} ${f.weight}`),
    )
    expect(geladen).toContain('Fraunces 500')
    expect(geladen).toContain('Schibsted Grotesk 400')

    await pruefeSeiten(page, fall.data.testlauf, 'Bildschirm')
    await page.emulateMedia({ media: 'print' })
    await pruefeSeiten(page, fall.data.testlauf, 'Druck')

    const pdf = await page.pdf({ preferCSSPageSize: true, printBackground: true })
    mkdirSync(AUSGABE, { recursive: true })
    writeFileSync(resolve(AUSGABE, `${name}.pdf`), pdf)
    expect(pdfSeiten(pdf)).toBe(5)
  })
}
