// IU-1 U2 · Inhalte-Übersicht: beide Reiter, beide Details (Thema, MSA, Reihe), Filter Klasse, Tastatur, Zurück.
// 1180 × 820 und 1440 × 900 (Projekte der Config), Fotos nach IU_AUSGABE. Daten: echte Prod-Zahlen aus
// src/pages/admin/inhalte/vorschau/daten.json (dbread, Stand dort).
import { expect, test } from '@playwright/test'

const AUSGABE = process.env.IU_AUSGABE ?? 'docs/inhalte/iu1/abnahme'
const url = (pfad: string): string => `/vorschau/inhalte.html?pfad=${encodeURIComponent(pfad)}`
const foto = (name: string, projekt: string): { path: string; fullPage: true } =>
  ({ path: `${AUSGABE}/u2-${name}-${projekt}.png`, fullPage: true })

test('Reiter Lernstandsanalyse: Kennzahlen, MSA-Zeile oben, 22 Themen', async ({ page }, info) => {
  await page.goto(url('/admin/inhalte'))
  const tabelle = page.getByRole('table', { name: 'Themen der Lernstandsanalyse' })
  await expect(tabelle).toBeVisible()
  const zeilen = tabelle.getByRole('button')
  await expect(zeilen).toHaveCount(23)
  await expect(zeilen.first()).toContainText('MSA-Vorbereitung (ZP10)')
  await expect(zeilen.first()).toContainText('Prüfziel')
  await expect(page.getByRole('navigation', { name: 'Kennzahlen' })).toContainText('Aufgaben, die Lena noch prüft')
  await page.screenshot(foto('lsa-alle', info.project.name))
})

test('Filter Klasse 9: nur Themen der Klasse 9, keine MSA-Zeile', async ({ page }, info) => {
  await page.goto(url('/admin/inhalte'))
  await page.getByRole('button', { name: 'Klasse 9', exact: true }).click()
  const tabelle = page.getByRole('table', { name: 'Themen der Lernstandsanalyse' })
  await expect(tabelle.getByText('MSA-Vorbereitung (ZP10)')).toHaveCount(0)
  await expect(tabelle.getByText('Klasse 8')).toHaveCount(0)
  await expect(tabelle.getByText('Klasse 9').first()).toBeVisible()
  await page.screenshot(foto('lsa-klasse9', info.project.name))
})

test('Thema per Tastatur: Pflicht und Tiefe, In Lenas Liste, Zurück', async ({ page }, info) => {
  await page.goto(url('/admin/inhalte?reiter=lsa&klasse=9'))
  const zeile = page.getByRole('table').getByRole('button').filter({ hasText: 'Quadratische Funktionen' })
  await zeile.focus()
  await page.keyboard.press('Enter')
  await expect(page.getByRole('heading', { level: 1, name: 'Quadratische Funktionen' })).toBeVisible()
  await expect(page.getByText('Pflicht', { exact: true })).toBeVisible()
  await expect(page.getByText('Tiefe', { exact: true })).toBeVisible()
  await expect(page.getByRole('link', { name: /in Lenas Liste öffnen$/ }).first()).toBeVisible()
  await page.screenshot(foto('thema', info.project.name))
  await page.getByRole('link', { name: 'Zur Übersicht' }).click()
  await expect(page.getByRole('button', { name: 'Klasse 9', exact: true })).toHaveAttribute('aria-pressed', 'true')
})

test('MSA-Detail: vier Bereiche', async ({ page }, info) => {
  await page.goto(url('/admin/inhalte'))
  await page.getByRole('table').getByRole('button').first().click()
  for (const b of ['Arithmetik und Algebra', 'Funktionen', 'Geometrie', 'Stochastik'])
    await expect(page.getByRole('heading', { level: 3, name: b })).toBeVisible()
  await page.screenshot(foto('msa', info.project.name))
})

test('Reiter Session-Reihen und Reihe 1 mit 7 Sessions', async ({ page }, info) => {
  await page.goto(url('/admin/inhalte?reiter=reihen'))
  const reihen = page.getByRole('table', { name: 'Vorhandene Reihen' })
  await expect(reihen).toContainText('Quadratische Funktionen und Gleichungen')
  const ohne = page.getByRole('table', { name: 'Themen ohne Reihe' })
  await expect(ohne.getByRole('button', { name: 'Reihe anlegen' }).first()).toBeDisabled()
  await page.screenshot(foto('reihen', info.project.name))
  await reihen.getByRole('button').first().click()
  await expect(page.getByText(/^Session \d · /)).toHaveCount(7)
  await page.screenshot(foto('reihe', info.project.name))
})
