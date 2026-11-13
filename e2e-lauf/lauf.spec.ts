// IU-1b · Lauf mit Prüfziel: drei Entscheidungen in Folge bleiben in der MSA-Liste; der gefilterte Lauf bleibt bei
// der Kompetenz und kehrt gefiltert zur Liste zurück; Bereiche einklappbar. 1180 × 820 und 1440 × 900.
// Daten: Prod-Zahlen der U3-Vorschau (src/pages/coach/pruefen/vorschau-ziel/daten.json), Entscheidungen im Speicher.
import { readFileSync } from 'node:fs'
import { expect, test, type Page } from '@playwright/test'

type Zeile = { abschnitt: string; skill_key: string; task_ids: string[] }
const daten = JSON.parse(readFileSync('src/pages/coach/pruefen/vorschau-ziel/daten.json', 'utf8')) as {
  liste: Zeile[]; liste_msa: Zeile[]; board: { task_id: string; lena_status: string }[]
}
const offen = new Set(daten.board.filter((b) => b.lena_status === 'offen').map((b) => b.task_id))
const msaIds = new Set(daten.liste_msa.filter((z) => z.abschnitt === 'gezielt').flatMap((z) => z.task_ids))
const alleIds = new Set(daten.liste.filter((z) => z.abschnitt === 'gezielt').flatMap((z) => z.task_ids))
// Für den gefilterten Lauf: eine MSA-Kompetenz mit mindestens zwei offenen Vorschlägen.
const filter = daten.liste_msa.find((z) => z.abschnitt === 'gezielt' && z.task_ids.filter((id) => offen.has(id)).length >= 2)!

const AUSGABE = process.env.LF_AUSGABE ?? 'docs/inhalte/iu1b/abnahme'
const url = (pfad: string): string => `/vorschau/lauf.html?pfad=${encodeURIComponent(pfad)}`
const foto = (name: string, projekt: string): { path: string; fullPage: true } =>
  ({ path: `${AUSGABE}/${name}-${projekt}.png`, fullPage: true })
const ort = async (page: Page): Promise<string> => (await page.getByTestId('ort').textContent()) ?? ''
const aufgabe = (o: string): string => o.match(/\/coach\/pruefen\/([0-9a-f-]{36})/)?.[1] ?? ''

async function entscheide(page: Page, vorher: string): Promise<string> {
  await page.keyboard.press('3')
  await expect.poll(async () => aufgabe(await ort(page))).not.toBe(vorher)
  const jetzt = await ort(page)
  if (aufgabe(jetzt)) await expect(page.getByRole('button', { name: /^Passt/ }).first()).toBeVisible()
  return jetzt
}

test('MSA-Lauf: drei Entscheidungen in Folge bleiben in der MSA-Liste', async ({ page }, info) => {
  await page.goto(url('/coach/pruefen?ziel=msa_zp10'))
  await page.getByRole('button', { name: 'Gezielt prüfen starten' }).click()
  await expect(page.getByRole('button', { name: /^Passt/ }).first()).toBeVisible()
  let o = await ort(page)
  expect(o).toContain('liste=gezielt&ziel=msa_zp10')
  expect(msaIds.has(aufgabe(o))).toBe(true)
  const gesehen = [aufgabe(o)]
  for (let i = 0; i < 3; i++) {
    o = await entscheide(page, aufgabe(o))
    expect(o).toContain('&ziel=msa_zp10')
    expect(msaIds.has(aufgabe(o))).toBe(true)
    gesehen.push(aufgabe(o))
  }
  expect(new Set(gesehen).size).toBe(4)
  // Mindestens eine der Aufgaben gehört nur zur MSA-Liste, nicht zur Gesamtliste (Kompetenz ohne Paket) — oder alle
  // stammen aus MSA-Kompetenzen; entscheidend ist, dass keine fremde Aufgabe dazwischenkam.
  expect(gesehen.every((id) => msaIds.has(id))).toBe(true)
  await page.screenshot(foto('lauf-msa-nach-3', info.project.name))
})

test('Gefilterter Lauf bleibt bei der Kompetenz und kehrt gefiltert zurück', async ({ page }, info) => {
  const ids = new Set(filter.task_ids)
  await page.goto(url(`/coach/pruefen?ziel=msa_zp10&skill=${filter.skill_key}`))
  await expect(page.getByTestId('gezielt-filter')).toBeVisible()
  await page.screenshot(foto('lauf-gefiltert-liste', info.project.name))
  await page.getByRole('button', { name: 'Gezielt prüfen starten' }).click()
  await expect(page.getByRole('button', { name: /^Passt/ }).first()).toBeVisible()
  let o = await ort(page)
  expect(o).toContain(`skill=${filter.skill_key}`)
  for (let n = 0; n < 10 && aufgabe(o); n++) {
    expect(ids.has(aufgabe(o))).toBe(true)
    o = await entscheide(page, aufgabe(o))
  }
  expect(o).toBe(`/coach/pruefen?ziel=msa_zp10&skill=${filter.skill_key}`)
  await expect(page.getByTestId('gezielt-filter')).toBeVisible()
  await page.screenshot(foto('lauf-gefiltert-zurueck', info.project.name))
})

test('MSA-Liste: nur der erste Bereich mit offenen Aufgaben ist offen, Zustand bleibt beim Zurückkommen', async ({ page }, info) => {
  await page.goto(url('/coach/pruefen?ziel=msa_zp10'))
  const kopf = page.getByRole('button', { name: /Aufgaben? offen/ })
  await expect(kopf.first()).toHaveAttribute('aria-expanded', 'true')
  await expect(page.locator('[aria-expanded="true"]')).toHaveCount(1)
  await page.screenshot(foto('msa-bereiche', info.project.name))
  await kopf.nth(1).click()
  await page.getByRole('button', { name: 'Gezielt prüfen starten' }).click()
  await expect(page.getByRole('button', { name: /^Passt/ }).first()).toBeVisible()
  await page.getByRole('button', { name: 'Pause' }).click()
  await expect.poll(() => ort(page)).toBe('/coach/pruefen?ziel=msa_zp10')
  await expect(page.locator('[aria-expanded="true"]')).toHaveCount(2)
})

test('Ohne Prüfziel: Lauf wie bisher in der Gesamtliste', async ({ page }) => {
  await page.goto(url('/coach/pruefen'))
  await page.getByRole('button', { name: 'Gezielt prüfen starten' }).click()
  await expect(page.getByRole('button', { name: /^Passt/ }).first()).toBeVisible()
  let o = await ort(page)
  expect(o).not.toContain('ziel=')
  o = await entscheide(page, aufgabe(o))
  expect(o).not.toContain('ziel=')
  expect(alleIds.has(aufgabe(o))).toBe(true)
})
