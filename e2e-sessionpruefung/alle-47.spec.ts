// SP-1b N4 · Jede der 47 Bauformen in der Vorschau öffnen: Die Karte „Stufen“ zeigt Klartext (keine Generator-Regel),
// kein „∈“, keine geschweifte Klammer, kein Schlüssel im sichtbaren Text. Bekannte Ausnahme: NS-4 (sp1b/offen.md B1).
import { readFileSync } from 'node:fs'
import { expect, test } from '@playwright/test'

const daten = JSON.parse(readFileSync('src/pages/coach/pruefen/bauformen/vorschau/fixtures.json', 'utf8')) as {
  plan: { bauform_id: string; schluessel: string }[]
  detail: Record<string, { s0: { stufen: { stufe: number; beschreibung: string | null }[]; steckbrief: { stufen?: Record<string, string> } } }>
}
const AUSNAHME = new Set(['NS-4'])
// NF-2: „Warum?“-Frage des Lösungsbeispiels mit Platzhalter im Steckbrief (sp1b/offen.md B2). Wird sie behoben,
// schlägt dieser Fall fehl und die Ausnahme entfällt.
const WARUM_PLATZHALTER = new Set(['NF-2'])
const SCHLUESSEL = /qf_|graph_auswahl|warmup|\{[a-z_][a-z0-9_]*\}/i

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
    if (WARUM_PLATZHALTER.has(z.schluessel)) {
      expect(sichtbar).toContain('Warum zieht man ({h})² wieder ab?')
      expect(sichtbar.replaceAll('({h})', '')).not.toMatch(SCHLUESSEL)
    } else {
      expect(sichtbar).not.toMatch(SCHLUESSEL)
    }
    const stufen = daten.detail[z.bauform_id].s0.stufen
    expect(stufen.length).toBeGreaterThan(0)
    if (AUSNAHME.has(z.schluessel)) {
      // ohne geprüften Klartext: je Stufe die Regel aus dem Steckbrief, keine leere Zeile
      for (const r of Object.values(daten.detail[z.bauform_id].s0.steckbrief.stufen ?? {})) expect(text).toContain(r)
    } else {
      for (const s of stufen) expect(s.beschreibung, `${z.schluessel} Stufe ${s.stufe}`).toBeTruthy()
      for (const s of stufen) expect(text).toContain(s.beschreibung as string)
    }
  })
}
