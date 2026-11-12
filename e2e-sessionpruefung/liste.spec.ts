// SP-1 S3 · Liste „Session-Aufgaben prüfen“ bei 1180 × 820 und 1440 × 900 (Projekte der Config), Fotos nach SP_AUSGABE.
import { expect, test } from '@playwright/test'

const AUSGABE = process.env.SP_AUSGABE ?? 'docs/freigabe/sp1/abnahme'
const url = (rolle: string): string => `/vorschau/sessionpruefung.html?rolle=${rolle}&pfad=/coach/pruefen/bauformen`

test('Lena: Titel, Thema, Fortschritt, vier Filter, Karten ohne Schlüssel im Text, keine Freigabe-Knöpfe', async ({ page }, info) => {
  await page.goto(url('coach'))
  await expect(page.getByRole('heading', { level: 1, name: 'Session-Aufgaben prüfen' })).toBeVisible()
  await expect(page.getByText(/Thema: Quadratische Funktionen und Gleichungen · Klasse 9/)).toBeVisible()
  await expect(page.getByText(/von 47 Bauformen geprüft/)).toBeVisible()
  await expect(page.getByRole('progressbar')).toBeVisible()
  for (const f of ['Alle', 'Zu prüfen', 'Rückfrage', 'Zur Freigabe']) {
    await expect(page.getByRole('button', { name: new RegExp(`^${f} \\d+$`) })).toBeVisible()
  }
  await expect(page.getByRole('button', { name: /^Freigegeben/ })).toHaveCount(0)
  await expect(page.getByRole('button', { name: /freigeben/ })).toHaveCount(0)
  const text = await page.locator('main').innerText()
  expect(text).not.toMatch(/qf_|graph_auswahl|warmup|\{/)
  await page.screenshot({ path: `${AUSGABE}/s3-liste-lena-${info.project.name}.png` })
})

test('Admin: Filter „Freigegeben“ und Freigabe-Knöpfe', async ({ page }, info) => {
  await page.goto(url('admin'))
  await expect(page.getByRole('button', { name: /^Freigegeben \d+$/ })).toBeVisible()
  await expect(page.getByRole('button', { name: 'Reihe freigeben' })).toBeVisible()
  await expect(page.getByRole('button', { name: 'Session 1 freigeben' })).toBeVisible()
  await page.screenshot({ path: `${AUSGABE}/s3-liste-admin-${info.project.name}.png` })
})

test('Reiter Auffällig und Prüffragen bleiben erreichbar', async ({ page }) => {
  await page.goto(url('coach'))
  await page.getByRole('tab', { name: /Auffällig/ }).click()
  await expect(page.getByText('Nichts auffällig.')).toBeVisible()
  await page.getByRole('tab', { name: 'Prüffragen' }).click()
  await expect(page.getByText('Keine Prüffragen.')).toBeVisible()
})
