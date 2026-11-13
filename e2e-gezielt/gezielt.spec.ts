// IU-1 U3 · Lenas Liste mit Prüfziel MSA: Umschalter, Gruppen je Bereich, erledigte eingeklappt, Filter auf eine
// Kompetenz mit „Filter aufheben“. 1180 × 820 und 1440 × 900, Fotos nach GZ_AUSGABE. Daten: echte Prod-Zahlen
// (src/pages/coach/pruefen/vorschau-ziel/daten.json, dbread als Lena).
import { expect, test } from '@playwright/test'

const AUSGABE = process.env.GZ_AUSGABE ?? 'docs/inhalte/iu1/abnahme'
const url = (pfad: string): string => `/vorschau/gezielt.html?pfad=${encodeURIComponent(pfad)}`
const foto = (name: string, projekt: string): { path: string; fullPage: true } =>
  ({ path: `${AUSGABE}/u3-${name}-${projekt}.png`, fullPage: true })

test('Alle: Liste wie bisher, Umschalter steht auf Alle', async ({ page }, info) => {
  await page.goto(url('/coach/pruefen'))
  await expect(page.getByRole('button', { name: 'Alle', exact: true })).toHaveAttribute('aria-pressed', 'true')
  await expect(page.getByTestId('gezielt-kopf')).toContainText('weiteren Schulen')
  await page.screenshot(foto('alle', info.project.name))
})

test('MSA: Kopfzeile, vier Bereiche, erledigte eingeklappt', async ({ page }, info) => {
  await page.goto(url('/coach/pruefen'))
  await page.getByRole('button', { name: 'MSA (ZP10)' }).click()
  await expect(page.getByTestId('gezielt-kopf')).toContainText('danach ist die MSA-LSA möglich')
  for (const b of ['Arithmetik und Algebra', 'Funktionen', 'Geometrie', 'Stochastik'])
    await expect(page.getByRole('heading', { level: 2, name: b })).toBeVisible()
  await expect(page.getByText(/Kompetenzen? erledigt/).first()).toBeVisible()
  await expect(page.getByText('1 von 2').first()).toBeVisible()
  await page.screenshot(foto('msa', info.project.name))
  await page.getByText(/Kompetenzen erledigt/).first().click()
  await page.screenshot(foto('msa-erledigt-offen', info.project.name))
})

test('Sprung mit Kompetenz: gefiltert, Filter aufheben', async ({ page }, info) => {
  await page.goto(url('/coach/pruefen?ziel=msa_zp10&skill=geo_flaeche_drachen_raute'))
  await expect(page.getByTestId('gezielt-filter')).toContainText('Gefiltert:')
  await expect(page.getByRole('heading', { level: 2 })).toHaveCount(1)
  await page.screenshot(foto('gefiltert', info.project.name))
  await page.getByRole('button', { name: 'Filter aufheben' }).click()
  await expect(page.getByTestId('gezielt-filter')).toHaveCount(0)
  await expect(page.getByRole('heading', { level: 2 })).toHaveCount(4)
})
