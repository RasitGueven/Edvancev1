// SP-1b N3 · Graph-Optionen groß genug: PAR-2, PAR-3, NS-4 (Breite je Option, richtige markiert, Dialog öffnet und
// schließt mit Esc und Knopf, Fokus zurück), EIN-1 und KO-1 als Gegenprobe. Fotos nach SP_AUSGABE.
import { readFileSync } from 'node:fs'
import { expect, test, type Page } from '@playwright/test'

const AUSGABE = process.env.SP_AUSGABE ?? 'docs/freigabe/sp1b/abnahme'
const daten = JSON.parse(readFileSync('src/pages/coach/pruefen/bauformen/vorschau/fixtures.json', 'utf8')) as {
  plan: { bauform_id: string; schluessel: string }[]
}
const id = (k: string): string => daten.plan.find((z) => z.schluessel === k)!.bauform_id
const oeffne = (page: Page, k: string) =>
  page.goto(`/vorschau/sessionpruefung.html?rolle=coach&pfad=/coach/pruefen/bauformen/${id(k)}`)
const MIN: Record<string, number> = { '1440x900': 280, '1180x820': 230 }

for (const k of ['PAR-2', 'PAR-3', 'NS-4']) {
  test(`${k}: Optionen breit genug, richtige markiert, Dialog`, async ({ page }, info) => {
    await oeffne(page, k)
    const optionen = page.getByTestId('graph-option-gross')
    await expect(optionen.first()).toBeVisible()
    const n = await optionen.count()
    expect(n).toBeGreaterThan(2)
    for (let i = 0; i < n; i++) {
      const b = await optionen.nth(i).boundingBox()
      expect(b!.width, `Option ${i + 1}`).toBeGreaterThanOrEqual(MIN[info.project.name])
    }
    // je Beispiel genau eine Option „richtig“
    const karten = page.locator('section[id^="anker-beispiel-"]')
    for (let i = 0; i < (await karten.count()); i++) {
      await expect(karten.nth(i).getByText('richtig', { exact: true })).toHaveCount(1)
    }
    await optionen.first().evaluate((el) => el.scrollIntoView({ block: 'start' }))
    await page.screenshot({ path: `${AUSGABE}/n3-${k}-${info.project.name}.png` })

    await optionen.first().click()
    const dialog = page.getByRole('dialog')
    await expect(dialog).toBeVisible()
    await page.screenshot({ path: `${AUSGABE}/n3-${k}-dialog-${info.project.name}.png` })
    await page.keyboard.press('Escape')
    await expect(dialog).toHaveCount(0)
    await expect(optionen.first()).toBeFocused()
    await optionen.nth(1).click()
    await dialog.getByRole('button', { name: 'Schließen', exact: true }).last().click()
    await expect(dialog).toHaveCount(0)
    await expect(optionen.nth(1)).toBeFocused()
  })
}

for (const k of ['EIN-1', 'KO-1']) {
  test(`${k}: Gegenprobe, Vorschau wie bisher`, async ({ page }, info) => {
    await oeffne(page, k)
    await expect(page.getByText(/^Beispiel 6$/)).toBeVisible()
    await expect(page.getByTestId('graph-option-gross')).toHaveCount(0)
    await expect(page.locator('.preview-stage').first()).toBeVisible()
    await page.getByText('Beispiel 1', { exact: true }).evaluate((el) => el.scrollIntoView({ block: 'start' }))
    await page.screenshot({ path: `${AUSGABE}/n3-${k}-gegenprobe-${info.project.name}.png` })
  })
}
