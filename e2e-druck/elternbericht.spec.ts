// Druck-Tests des Eltern-Berichts R7 (Bauauftrag R7, Entscheidung 9).
//
// Geht ALLE Fälle aus FAELLE durch — neue Fälle oder neue Seiteninhalte
// (R7-3, R7-4) brauchen hier keine Änderung. Je Fall: Schrift geladen, kein
// Inhalt läuft über, Kopf und Fuß liegen auf den Maßen aus dem Maßblatt E7
// (±1 pt, gemessen an den gezeichneten Teilen), und das PDF hat fünf Seiten.
// Bericht v2: beschriftete Navigation oben rechts, Überschriften in Literata.
// Bericht v4: dazu die Leiste der Klassenarbeiten (Seite 2–5) und die Prüfung,
// dass nichts aus seinem Kasten oder aus .eb-inhalt ragt (pruefeKaesten).
import { mkdirSync, writeFileSync } from 'node:fs'
import { resolve } from 'node:path'

import { expect, test, type Page } from '@playwright/test'

import { FAELLE } from '../src/lib/report/elternbericht/fixtures'

const AUSGABE = resolve(process.env.EB_AUSGABE ?? 'docs/report/r7/abnahme/r7-2')
const PT = 4 / 3 // CSS-px je pt
const TOLERANZ = 1 // pt
// Bericht v2: beschriftete Navigation oben rechts (Seite.tsx).
const NAV_X = [256, 322, 388, 454, 520]
/** Mindestabstand zwischen Spur und rechtem Text einer Profilzeile (R7-8). */
const SPUR_ABSTAND = 6

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

    // Navigation (Bericht v2): fünf Kreise Ø 12,4 bei y 33, Mitten NAV_X, je mit
    // Beschriftung unter dem Kreis, die nicht über die Kopflinie hinausragt; genau einer aktiv.
    const punkte = await lage(page, n, '.eb-nav-punkt')
    expect(punkte, wo).toHaveLength(5)
    punkte.forEach((p, i) => {
      nahe(p.x + p.b / 2, NAV_X[i], `${wo} Punkt ${i + 1} x`)
      nahe(p.y + p.h / 2, 33, `${wo} Punkt ${i + 1} y`)
    })
    const namen = await lage(page, n, '.eb-nav-name')
    expect(namen, wo).toHaveLength(5)
    for (const [i, z] of namen.entries()) {
      expect(z.x + z.b, `${wo} Name ${i + 1} rechts`).toBeLessThanOrEqual(551 + TOLERANZ)
      if (i > 0) expect(z.x, `${wo} Name ${i + 1} überlappt`).toBeGreaterThan(namen[i - 1].x + namen[i - 1].b)
    }
    const aktiv = await lage(page, n, '.eb-nav-aktiv .eb-nav-punkt')
    expect(aktiv, wo).toHaveLength(1)
    nahe(aktiv[0].x + aktiv[0].b / 2, NAV_X[n - 1], `${wo} aktiver Punkt`)

    // Chip „Testdaten“ (Bericht v2: unter der Wortmarke, 70,52), 50 × 13 — nur im Testlauf.
    const chip = await lage(page, n, '.eb-chip')
    if (testlauf) {
      expect(chip, wo).toHaveLength(1)
      nahe(chip[0].x, 70, `${wo} Chip x`)
      nahe(chip[0].y, 52, `${wo} Chip y`)
      nahe(chip[0].b, 50, `${wo} Chip Breite`)
      nahe(chip[0].h, 13, `${wo} Chip Höhe`)
    } else {
      expect(chip, wo).toHaveLength(0)
    }
  }
}

/**
 * Seite 2, Kompetenzprofil (R7-8): In jeder Zeile endet die Spur mindestens
 * 6 pt vor dem rechten Text. Gibt die rechten Texte zurück.
 */
async function pruefeProfil(page: Page, wo: string): Promise<string[]> {
  const zeilen = await page.evaluate((PT) => {
    const s = document.querySelector('.eb-seite[data-seite="2"]')!
    return [...s.querySelectorAll('[data-testid="eb-profil-zeile"]')].map((z) => {
      const ende = Math.max(0, ...[...z.querySelectorAll('.eb-s2-spur rect')].map((r) => r.getBoundingClientRect().right))
      const texte = [...z.querySelectorAll('.eb-s2-geprueft, .eb-s2-teile')].filter((t) => t.textContent)
      const start = Math.min(...texte.map((t) => t.getBoundingClientRect().left))
      return { text: z.querySelector('.eb-s2-geprueft')?.textContent ?? '', luft: (start - ende) / PT }
    })
  }, PT)
  for (const z of zeilen) {
    expect(z.luft, `${wo}, Profilzeile „${z.text}“: Spur endet ${z.luft.toFixed(2)} pt vor dem Text`).toBeGreaterThanOrEqual(
      SPUR_ABSTAND,
    )
  }
  return zeilen.map((z) => z.text)
}

/**
 * Seite 3, Einordnung (Bericht v2): kein Text ragt aus seinem Kasten, und die
 * Pfeile bleiben in ihrer Zeile (nichts läuft quer über die Seite).
 */
async function pruefeEinordnung(page: Page, wo: string): Promise<void> {
  const fehler = await page.evaluate(() => {
    const s = document.querySelector('.eb-seite[data-seite="3"]')
    if (!s) return ['keine Seite 3']
    const f: string[] = []
    for (const k of s.querySelectorAll<HTMLElement>('.eb-s3v3-kasten, .eb-s3v3-thema, .eb-s3v2-weitere, .eb-s3v3-weitere-staerken')) {
      if (k.scrollWidth > k.clientWidth + 1 || k.scrollHeight > k.clientHeight + 1) f.push(`Text ragt aus Kasten: ${k.textContent?.slice(0, 40)}`)
    }
    for (const z of s.querySelectorAll<HTMLElement>('.eb-s3v3-zeile-a, .eb-s3v3-zeile-b')) {
      const r = z.getBoundingClientRect()
      const p = z.querySelector('.eb-s3v3-pfeil')?.getBoundingClientRect()
      if (p && (p.top < r.top - 0.5 || p.bottom > r.bottom + 0.5)) f.push('Pfeil verlässt seine Zeile')
    }
    return f
  })
  expect(fehler, wo).toEqual([])
}

/**
 * Bericht v4 (V4-2): Nichts ragt aus seinem Kasten oder aus `.eb-inhalt`, auf
 * jeder Seite und in jedem Fall. Geprüft außerhalb von SVG (das hat eigene Maße)
 * und ohne die Leiste-Titel, die mit Ellipse enden dürfen (voller Titel als
 * Vorlesetext):
 *   A. jeder sichtbare Kasten (Fläche oder Rand) liegt in `.eb-inhalt`,
 *   B. jede Textzeile liegt in `.eb-inhalt` und im nächsten Kasten darüber,
 *   C. ein Element mit verdecktem Überlauf schneidet nichts ab (scroll ≤ client,
 *      bei Höhe mit Luft für die Schriftmetrik).
 * Gemessen werden die Textzeilen selbst (Range), nicht die Spaltenkästen des
 * Musters (die Kopfdaten auf Seite 1 sind breiter als ihr Kasten, ohne dass Text
 * übersteht). Toleranz 2 px (Rundung, Schriftmetrik).
 */
async function pruefeKaesten(page: Page, wo: string): Promise<void> {
  const fehler = await page.evaluate(() => {
    const TOL = 2
    // Schriftmetrik: Die Glyphenbox ist höher als die Zeile (Titel mit enger Zeilenhöhe); eine abgeschnittene Zeile wäre mehr als 20 px.
    const SCHRIFT = 6
    const f: string[] = []
    const kurz = (el: Element): string =>
      `${el.tagName.toLowerCase()}.${[...el.classList].join('.')} „${(el.textContent ?? '').trim().slice(0, 30)}“`
    const sichtbarerKasten = (el: Element): boolean => {
      const cs = getComputedStyle(el)
      return cs.backgroundColor !== 'rgba(0, 0, 0, 0)' || parseFloat(cs.borderTopWidth) > 0
    }
    const aus = (r: DOMRect, k: DOMRect): boolean =>
      r.right > k.right + TOL || r.left < k.left - TOL || r.bottom > k.bottom + TOL || r.top < k.top - TOL
    for (const seite of document.querySelectorAll('.eb-seite')) {
      const n = seite.getAttribute('data-seite')
      const inhalt = seite.querySelector<HTMLElement>('.eb-inhalt')!
      const ri = inhalt.getBoundingClientRect()
      const ausgenommen = (el: Element): boolean =>
        el.closest('svg, .sr-only, .eb-leiste-titel') !== null

      for (const el of inhalt.querySelectorAll<HTMLElement>('*')) {
        if (ausgenommen(el)) continue
        const r = el.getBoundingClientRect()
        if (r.width === 0 || r.height === 0) continue
        if (sichtbarerKasten(el) && (r.right > ri.right + TOL || r.left < ri.left - TOL || r.bottom > ri.bottom + TOL)) {
          f.push(`Seite ${n}: Kasten ragt aus .eb-inhalt: ${kurz(el)}`)
        }
        if (getComputedStyle(el).overflow !== 'visible' && (el.scrollWidth > el.clientWidth + 1 || el.scrollHeight > el.clientHeight + SCHRIFT)) {
          f.push(`Seite ${n}: Überlauf wird abgeschnitten: ${kurz(el)}`)
        }
      }

      const wurzeln: Element[] = [inhalt, ...seite.querySelectorAll('.eb-leiste')]
      for (const wurzel of wurzeln) {
        const walker = document.createTreeWalker(wurzel, NodeFilter.SHOW_TEXT)
        for (let node = walker.nextNode(); node; node = walker.nextNode()) {
          const el = node.parentElement
          if (!el || !node.textContent?.trim() || ausgenommen(el)) continue
          const range = document.createRange()
          range.selectNodeContents(node)
          let kasten: Element | null = el
          while (kasten && kasten !== wurzel && !sichtbarerKasten(kasten)) {
            kasten = kasten.parentElement
          }
          for (const r of range.getClientRects()) {
            if (r.width === 0 || r.height === 0) continue
            if (wurzel === inhalt && aus(r, ri)) f.push(`Seite ${n}: Text ragt aus .eb-inhalt: ${kurz(el)}`)
            if (kasten && kasten !== wurzel && aus(r, kasten.getBoundingClientRect())) {
              f.push(`Seite ${n}: Text ragt aus seinem Kasten: ${kurz(el)} in ${kurz(kasten)}`)
            }
          }
        }
      }
    }
    return [...new Set(f)]
  })
  expect(fehler, wo).toEqual([])
}

/** Seiten im PDF: die Seitenobjekte, nicht der Seitenbaum (/Pages). */
function pdfSeiten(pdf: Buffer): number {
  return (pdf.toString('latin1').match(/\/Type\s*\/Page(?![s\w])/g) ?? []).length
}

// Bericht v3: Seite 3 in beiden Layouts (Vorschau: ?layout=A|B).
for (const [name, fall] of Object.entries(FAELLE).flatMap(([n, f]) => (['A', 'B'] as const).map((l) => [`${n} ${l}`, f] as const))) {
  test(`Druckbogen ${name}`, async ({ page }) => {
    const [fallName, layout] = name.split(' ')
    await page.goto(`/vorschau/elternbericht.html?fall=${fallName}&layout=${layout}`)
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
    expect(geladen).toContain('Literata 600')
    expect(geladen).toContain('Schibsted Grotesk 400')

    await pruefeSeiten(page, fall.data.testlauf, 'Bildschirm')
    await page.emulateMedia({ media: 'print' })
    await pruefeSeiten(page, fall.data.testlauf, 'Druck')
    await pruefeEinordnung(page, `${name}, Druck`)
    await pruefeKaesten(page, `${name}, Druck`)
    await pruefeProfil(page, 'Druck')

    const pdf = await page.pdf({ preferCSSPageSize: true, printBackground: true })
    mkdirSync(AUSGABE, { recursive: true })
    writeFileSync(resolve(AUSGABE, `${name.replace(' ', '-')}.pdf`), pdf)
    expect(pdfSeiten(pdf)).toBe(5)
  })
}
