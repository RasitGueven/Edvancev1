// SP-1b N4, SP-1c C2/C4 · Jede der 47 Bauformen in der Vorschau öffnen: Die Karte „Stufen“ zeigt Klartext (keine
// Generator-Regel), kein „∈“, keine geschweifte Klammer, kein Schlüssel im sichtbaren Text. In keinem Lösungsbeispiel
// steht ein Platzhalter (SP-1b B2, NF-2), auch nicht im „Warum?“ des Steckbriefs, das das Kind sieht.
import { readFileSync } from 'node:fs'
import { expect, test } from '@playwright/test'

const daten = JSON.parse(readFileSync('src/pages/coach/pruefen/bauformen/vorschau/fixtures.json', 'utf8')) as {
  plan: { bauform_id: string; schluessel: string }[]
  detail: Record<string, { s0: {
    stufen: { stufe: number; beschreibung: string | null }[]
    steckbrief: { warum?: { frage: string; bausteine: { text: string }[] } | null }
  } }>
}
const SCHLUESSEL = /qf_|graph_auswahl|warmup|\{[a-z_][a-z0-9_]*\}/i
const PLATZHALTER = /\{[A-Za-z_]+\}/

test.describe.configure({ mode: 'parallel' })

for (const z of daten.plan) {
  test(`${z.schluessel}: Stufen in Klartext`, async ({ page }, info) => {
    test.skip(info.project.name !== '1440x900', 'eine Größe reicht für den Textabgleich')
    await page.goto(`/vorschau/sessionpruefung.html?rolle=coach&pfad=/coach/pruefen/bauformen/${z.bauform_id}`)
    const karte = page.locator('#anker-stufen')
    await expect(karte).toBeVisible()
    const text = await karte.innerText()
    expect(text).not.toMatch(/∈|[{}]/)
    const sichtbar = await page.locator('main').innerText()
    expect(sichtbar).not.toMatch(SCHLUESSEL)
    // Lösungsbeispiele: weder Karte noch „Warum?“ aus dem Steckbrief mit Platzhalter
    for (const beispiel of await page.locator('[id^="anker-beispiel-"]').all()) {
      expect(await beispiel.innerText()).not.toMatch(PLATZHALTER)
    }
    const warum = daten.detail[z.bauform_id].s0.steckbrief.warum
    for (const w of warum ? [warum.frage, ...warum.bausteine.map((b) => b.text)] : []) {
      expect(w, `${z.schluessel} Warum`).not.toMatch(PLATZHALTER)
    }
    const stufen = daten.detail[z.bauform_id].s0.stufen
    expect(stufen.length).toBeGreaterThan(0)
    for (const s of stufen) expect(s.beschreibung, `${z.schluessel} Stufe ${s.stufe}`).toBeTruthy()
    for (const s of stufen) expect(text).toContain(s.beschreibung as string)
  })
}
