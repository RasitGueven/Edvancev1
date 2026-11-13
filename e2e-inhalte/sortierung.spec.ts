// IU-1b · Reiter Lernstandsanalyse: MSA oben, dann laufende und kommende Themen, am Ende „Schon geschrieben“;
// gleicher Monat als ein Monat. 1180 × 820 und 1440 × 900, Fotos nach docs/inhalte/iu1b/abnahme.
// Daten: Prod-Zahlen (src/pages/admin/inhalte/vorschau/daten.json); „heute“ ist das echte Datum.
import { expect, test } from '@playwright/test'

const AUSGABE = process.env.IU1B_AUSGABE ?? 'docs/inhalte/iu1b/abnahme'

test('Sortierung: MSA, laufend und kommend, dann „Schon geschrieben“', async ({ page }, info) => {
  await page.goto(`/vorschau/inhalte.html?pfad=${encodeURIComponent('/admin/inhalte')}`)
  const tabelle = page.getByRole('table', { name: 'Themen der Lernstandsanalyse' })
  await expect(tabelle).toBeVisible()
  const zeilen = tabelle.getByRole('button')
  await expect(zeilen.first()).toContainText('MSA-Vorbereitung (ZP10)')
  const trenner = tabelle.getByRole('rowheader', { name: 'Schon geschrieben' })
  await expect(trenner).toHaveCount(1)
  // Unter der Zwischenzeile stehen nur Themen, deren Zeitfenster vor heute endete (Q1, Sep bis Okt).
  const text = (await tabelle.textContent()) ?? ''
  const danach = text.slice(text.indexOf('Schon geschrieben'))
  expect(danach).toContain('Zufall und Wahrscheinlichkeit')
  expect(text.indexOf('Schon geschrieben')).toBeGreaterThan(text.indexOf('Potenzen'))
  // Gleicher Monat: „Q3 · März“ statt „Mär bis Mär“.
  await expect(tabelle.getByText(/^Q3 · März$/).first()).toBeVisible()
  await expect(tabelle.getByText(/Mär bis Mär/)).toHaveCount(0)
  await page.screenshot({ path: `${AUSGABE}/sortierung-${info.project.name}.png`, fullPage: true })
})
