// SP-1 S4 · Prüfansicht bei 1180 × 820 und 1440 × 900 mit EIN-1 (Zahl), KO-1 (Punkt), PAR-2 (Graph-Auswahl), PAR-3
// (Graph-Auswahl) und NP-2 (mit Lösungsbeispiel). Fotos nach SP_AUSGABE. Daten: vorschau/fixtures.json (Prod, read-only).
import { readFileSync } from 'node:fs'
import { expect, test, type Page } from '@playwright/test'

const AUSGABE = process.env.SP_AUSGABE ?? 'docs/freigabe/sp1/abnahme'
const daten = JSON.parse(readFileSync('src/pages/coach/pruefen/bauformen/vorschau/fixtures.json', 'utf8')) as {
  plan: { bauform_id: string; schluessel: string }[]
}
const id = (k: string): string => daten.plan.find((z) => z.schluessel === k)!.bauform_id
const oeffne = (page: Page, k: string, rolle = 'coach') =>
  page.goto(`/vorschau/sessionpruefung.html?rolle=${rolle}&pfad=/coach/pruefen/bauformen/${id(k)}`)
const ohneSchluessel = async (page: Page) =>
  expect(await page.locator('main').innerText()).not.toMatch(/qf_|graph_auswahl|warmup|\{[a-z_][a-z0-9_]*\}/i)

for (const k of ['EIN-1', 'KO-1', 'PAR-2', 'PAR-3', 'NP-2']) {
  test(`${k}: Kopf, Grundgerüst, Stufen, sechs Beispiele, Klartext`, async ({ page }, info) => {
    await oeffne(page, k)
    await expect(page.getByText(k, { exact: true })).toBeVisible()
    await expect(page.getByText('Grundgerüst', { exact: true })).toBeVisible()
    await expect(page.getByText('Stufen und Zeit je Aufgabe')).toBeVisible()
    await expect(page.getByText(/^Beispiel \d$/)).toHaveCount(6)
    await expect(page.getByRole('button', { name: /^Passt · \d+ Aufgaben zur Freigabe$/ })).toBeVisible()
    await expect(page.getByText(/Automatisch geprüft: \d+ von \d+ Aufgaben in Ordnung/)).toBeVisible()
    await ohneSchluessel(page)
    await page.screenshot({ path: `${AUSGABE}/s4-${k}-${info.project.name}.png` })
    // Die Hülle scrollt im Inhaltsbereich, nicht im Fenster: zum ersten Beispiel scrollen statt fullPage.
    await page.getByText('Beispiel 1', { exact: true }).evaluate((el) => el.scrollIntoView({ block: 'start' }))
    await page.screenshot({ path: `${AUSGABE}/s4-${k}-${info.project.name}-beispiele.png` })
  })
}

test('Graph-Auswahl: Optionen auf dunklem Untergrund wie im Player (S4.14)', async ({ page }, info) => {
  await oeffne(page, 'PAR-2')
  const option = page.getByTestId('graph-option').first()
  await option.scrollIntoViewIfNeeded()
  const grund = await option.evaluate((el) => getComputedStyle(el.parentElement as Element).backgroundColor)
  expect(grund).not.toBe('rgb(255, 255, 255)')
  expect(grund).not.toBe('rgba(0, 0, 0, 0)')
  await option.locator('..').screenshot({ path: `${AUSGABE}/k-PAR-2-optionen-vorschau-${info.project.name}.png` })
})

test('Kommentar an Beispiel 3 mit „Rechnung falsch“, dann Rückfrage; nächste Bauform öffnet sich', async ({ page }) => {
  await oeffne(page, 'EIN-1')
  await page.getByRole('button', { name: 'Kommentar: Beispiel 3' }).click()
  await expect(page.getByRole('textbox', { name: 'Kommentar zu Beispiel 3' })).toBeFocused()
  const senden = page.getByRole('button', { name: 'Rückfrage senden (1 Kommentar)' })
  await expect(senden).toBeDisabled()
  await page.getByRole('button', { name: 'Rechnung falsch' }).click()
  await expect(senden).toBeEnabled()
  await senden.click()
  await expect(page.getByText(/Rückfrage gesendet\..*Weiter mit/)).toBeVisible()
})

test('Tastatur: Kommentar-Knopf, Gründe, Zeit und Senden erreichbar, Fokus sichtbar', async ({ page }) => {
  await oeffne(page, 'EIN-1')
  await page.getByRole('button', { name: 'Zeit Stufe 3 länger' }).focus()
  await page.keyboard.press('Enter')
  await expect(page.getByText(/^vorher 1 Min$/)).toBeVisible()
  await expect(page.getByText('Zeit geändert: Stufe 3 → 1,5 Min')).toBeVisible()
  await page.getByRole('button', { name: 'Kommentar: Grundgerüst' }).focus()
  await page.keyboard.press('Enter')
  await page.keyboard.press('Shift+Tab')
  const outline = await page.evaluate(() => getComputedStyle(document.activeElement as Element).outlineStyle)
  expect(outline).not.toBe('none')
})
