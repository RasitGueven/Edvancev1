// MSA-1 M3 · Archiv: Item-Pflege und Lena-Board zeigen und zählen keine archivierte Aufgabe, die Archiv-Seite zeigt
// sie, Wiederherstellen holt eine zurück. 1180 × 820 und 1440 × 900 (Projekte der Config), Fotos nach AR_AUSGABE.
// Daten: src/pages/admin/archiv/vorschau/daten.ts (3 aktive, 2 archivierte LSA-Aufgaben, im Speicher).
import { expect, test } from '@playwright/test'

const AUSGABE = process.env.AR_AUSGABE ?? 'docs/msa/msa1/abnahme'
const url = (pfad: string, rolle = 'admin'): string => `/vorschau/archiv.html?rolle=${rolle}&pfad=${pfad}`

test('Item-Pflege: zählt nur die 3 aktiven LSA-Aufgaben, Link „Archiv (2)“ am Fuß', async ({ page }, info) => {
  await page.goto(url('/admin/authoring'))
  await expect(page.getByRole('button', { name: /^Lernstandsanalyse 3 Aufgaben/ })).toBeVisible()
  await expect(page.getByText(/5 Aufgaben/)).toHaveCount(0)
  await expect(page.getByRole('link', { name: 'Archiv (2)' })).toBeVisible()
  await expect(page.getByRole('navigation').getByText('Archiv')).toHaveCount(0)
  await page.screenshot({ path: `${AUSGABE}/m3-item-pflege-${info.project.name}.png`, fullPage: true })
})

test('Lena-Board: keine archivierte Aufgabe', async ({ page }, info) => {
  await page.goto(url('/coach/pruefen', 'coach'))
  // Reiter „Für die LSA“: 3 Aufgaben im Bereich (2 offen, 1 freigegeben), die 2 archivierten fehlen.
  await expect(page.getByRole('tab', { name: /^Für die LSA \d+ offen \/ 3$/ })).toBeVisible()
  await page.getByRole('tab', { name: /^Für die LSA/ }).click()
  await page.getByRole('button', { name: 'Brüche aufklappen' }).click()
  await expect(page.getByText('Aktiv Pizza').first()).toBeVisible()
  const text = await page.locator('main').innerText()
  expect(text).not.toMatch(/Archiv Brot|Archiv Torte/)
  await page.screenshot({ path: `${AUSGABE}/m3-lena-board-${info.project.name}.png`, fullPage: true })
})

test('Archiv-Seite: zeigt beide archivierten, Filter, kein Löschen-Knopf', async ({ page }, info) => {
  await page.goto(url('/admin/authoring/archiv'))
  await expect(page.getByRole('heading', { level: 1, name: 'Archiv' })).toBeVisible()
  await expect(page.getByRole('button', { name: 'Archiv Brot' })).toBeVisible()
  await expect(page.getByRole('button', { name: 'Archiv Torte' })).toBeVisible()
  await expect(page.getByText('Aktiv Pizza')).toHaveCount(0)
  await expect(page.getByRole('button', { name: /löschen/i })).toHaveCount(0)
  await page.getByRole('button', { name: 'Archiv Brot' }).click()
  await expect(page.getByRole('link', { name: 'Aufgabe öffnen' })).toBeVisible()
  await page.screenshot({ path: `${AUSGABE}/m3-archiv-${info.project.name}.png`, fullPage: true })
})

test('Wiederherstellen nach Rückfrage holt eine Aufgabe zurück in die Item-Pflege', async ({ page }, info) => {
  await page.goto(url('/admin/authoring/archiv'))
  await page.getByLabel('Auswählen: Archiv Brot').check()
  await page.getByRole('button', { name: 'Auswahl wiederherstellen (1)' }).click()
  await expect(page.getByRole('alertdialog')).toBeVisible()
  await page.screenshot({ path: `${AUSGABE}/m3-rueckfrage-${info.project.name}.png`, fullPage: true })
  await page.getByRole('button', { name: 'Ja, wiederherstellen' }).click()
  await expect(page.getByText('1 Aufgabe wiederhergestellt')).toBeVisible()
  await expect(page.getByRole('button', { name: 'Archiv Brot' })).toHaveCount(0)
  await expect(page.getByRole('button', { name: 'Archiv Torte' })).toBeVisible()
  // Zurück zur Item-Pflege im selben Speicher: jetzt 4 aktive, Archiv (1).
  await page.getByRole('link', { name: 'Item-Pflege' }).click()
  await expect(page.getByRole('button', { name: /^Lernstandsanalyse 4 Aufgaben/ })).toBeVisible()
  await expect(page.getByRole('link', { name: 'Archiv (1)' })).toBeVisible()
  await page.screenshot({ path: `${AUSGABE}/m3-nach-wiederherstellen-${info.project.name}.png`, fullPage: true })
})
