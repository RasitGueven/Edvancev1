// SP-1 S5 · Abnahme in der Vorschau (Fixtures aus Prod, Entscheidungen nur im Speicher): Fälle a, b, c, d, i.
import { readFileSync } from 'node:fs'
import { expect, test, type Page } from '@playwright/test'

const AUSGABE = process.env.SP_AUSGABE ?? 'docs/freigabe/sp1/abnahme'
const daten = JSON.parse(readFileSync('src/pages/coach/pruefen/bauformen/vorschau/fixtures.json', 'utf8')) as {
  plan: { bauform_id: string; schluessel: string }[]
}
const id = (k: string): string => daten.plan.find((z) => z.schluessel === k)!.bauform_id
const oeffne = (page: Page, k: string) =>
  page.goto(`/vorschau/sessionpruefung.html?rolle=coach&pfad=/coach/pruefen/bauformen/${id(k)}`)
const SCHLUESSEL = /qf_|graph_auswahl|warmup|\{[a-z_][a-z0-9_]*\}/i

test.describe.configure({ mode: 'serial' })

test('a) EIN-1 ohne Klick „Passt“: nächste Bauform öffnet sich', async ({ page }, info) => {
  await oeffne(page, 'EIN-1')
  await page.getByRole('button', { name: 'Passt · 71 Aufgaben zur Freigabe' }).click()
  await expect(page.getByRole('heading', { level: 1, name: 'Punkt im Koordinatensystem ablesen' })).toBeVisible()
  await expect(page.getByText(/^Passt\. Werte in Terme einsetzen steht zur Freigabe\. Weiter mit/)).toBeVisible()
  await page.screenshot({ path: `${AUSGABE}/abnahme-a-${info.project.name}.png` })
})

test('b) Kommentar an Beispiel 3 mit „Rechnung falsch“: Knopf „Rückfrage senden (1 Kommentar)“, danach Rückfrage', async ({ page }, info) => {
  await oeffne(page, 'EIN-1')
  await page.getByRole('button', { name: 'Kommentar: Beispiel 3' }).click()
  await page.getByRole('button', { name: 'Rechnung falsch' }).click()
  const senden = page.getByRole('button', { name: 'Rückfrage senden (1 Kommentar)' })
  await expect(senden).toBeEnabled()
  await page.screenshot({ path: `${AUSGABE}/abnahme-b-${info.project.name}.png` })
  await senden.click()
  await expect(page.getByText(/^Rückfrage gesendet\./)).toBeVisible()
})

test('c) Kommentar ohne Grund und Text: Senden gesperrt', async ({ page }, info) => {
  await oeffne(page, 'KO-1')
  await page.getByRole('button', { name: 'Kommentar: Stufen' }).click()
  const senden = page.getByRole('button', { name: 'Rückfrage senden (1 Kommentar)' })
  await expect(senden).toBeDisabled()
  await expect(senden).toHaveAttribute('title', /Grund/)
  await expect(page.getByText('Bitte bei jedem Kommentar einen Grund wählen oder kurz schreiben, was nicht stimmt.')).toBeVisible()
  await page.screenshot({ path: `${AUSGABE}/abnahme-c-${info.project.name}.png` })
})

test('d) „Andere Beispiele“ lässt das kommentierte Beispiel stehen', async ({ page }) => {
  await oeffne(page, 'PAR-3')
  const karte = page.locator('section[id^="anker-beispiel-"]').nth(1)
  const anker = await karte.getAttribute('id')
  await page.getByRole('button', { name: 'Kommentar: Beispiel 2' }).click()
  const vorher = await page.locator('section[id^="anker-beispiel-"]').evaluateAll((e) => e.map((x) => x.id))
  await page.getByRole('button', { name: 'Andere Beispiele' }).click()
  await expect(page.locator(`section[id="${anker}"]`)).toBeVisible()
  const nachher = await page.locator('section[id^="anker-beispiel-"]').evaluateAll((e) => e.map((x) => x.id))
  expect(nachher).toContain(anker)
  expect(nachher.filter((x) => !vorher.includes(x)).length).toBeGreaterThan(0)
})

test('i) kein Schlüssel im sichtbaren Text außer dem Kürzel (Liste und fünf Prüfansichten)', async ({ page }) => {
  await page.goto('/vorschau/sessionpruefung.html?rolle=coach&pfad=/coach/pruefen/bauformen')
  await expect(page.getByText(/von 47 Bauformen geprüft/)).toBeVisible()
  expect(await page.locator('main').innerText()).not.toMatch(SCHLUESSEL)
  for (const k of ['EIN-1', 'KO-1', 'PAR-2', 'PAR-3', 'NP-2']) {
    await oeffne(page, k)
    await expect(page.getByText(/^Beispiel 6$/)).toBeVisible()
    expect(await page.locator('main').innerText(), k).not.toMatch(SCHLUESSEL)
  }
})

test('h) Lena sieht keine Freigabe-Knöpfe', async ({ page }) => {
  await page.goto('/vorschau/sessionpruefung.html?rolle=coach&pfad=/coach/pruefen/bauformen')
  await expect(page.getByText(/von 47 Bauformen geprüft/)).toBeVisible()
  await expect(page.getByRole('button', { name: /freigeben/i })).toHaveCount(0)
})
