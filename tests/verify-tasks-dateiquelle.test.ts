// Der Prüfpfad für Aufgaben-Chargen — geprüft am echten Skript, nicht an einer
// Nachbildung. Jeder Fall startet `node tools/verify-tasks.mjs` als eigenen
// Prozess und liest Ausgabe und Exit-Code.
//
// Warum ein eigener Löser statt der echten API: Stufe 2 ist eine LLM-Anfrage.
// Ein Test, der ins Netz greift, ist weder deterministisch noch offline grün —
// und der Schlüssel in .env wird von der API mit 401 abgewiesen. Der Löser hier
// hängt sich über ANTHROPIC_BASE_URL ein und rechnet die Aufgabe WIRKLICH aus
// dem Aufgabentext aus (kleiner Parser für `a op b`). Er ist damit genau das,
// was Stufe 2 sein soll: eine zweite Instanz, die nur die Frage sieht.
//
// Die wichtigste Zusage dieser Suite ist nicht die Trefferquote, sondern der Fall
// "schickt die hinterlegte Lösung NICHT an den Prüfer": er liest mit, was der
// Prüfer wirklich abgeschickt hat. Ein Prüfer, der die Lösung kennt, bestätigt
// sie — er prüft sie nicht.

import { execFile } from 'node:child_process'
import { createServer, type Server } from 'node:http'
import { mkdtemp, rm } from 'node:fs/promises'
import { tmpdir } from 'node:os'
import path from 'node:path'
import { promisify } from 'node:util'
import { afterAll, beforeAll, describe, expect, it } from 'vitest'

const ausfuehren = promisify(execFile)

const WURZEL = path.resolve(__dirname, '..')
const SKRIPT = path.join(WURZEL, 'tools', 'verify-tasks.mjs')
const FIX = (name: string) => path.join(__dirname, 'fixtures', 'verify-tasks', name)

// ── Der blinde Löser ────────────────────────────────────────────────────────

/** Rechnet `a op b` aus einem Aufgabentext aus. Kein eval, nur die vier Grundrechenarten. */
function loese(frage: string): string | null {
  const m = frage.match(/(-?\d+(?:[.,]\d+)?)\s*([+\-*·×:/])\s*(-?\d+(?:[.,]\d+)?)/)
  if (!m) return null
  const a = Number(m[1].replace(',', '.'))
  const b = Number(m[3].replace(',', '.'))
  const r = { '+': a + b, '-': a - b, '*': a * b, '·': a * b, '×': a * b, ':': a / b, '/': a / b }[m[2]]
  return r === undefined || !Number.isFinite(r) ? null : String(r)
}

/** Zerlegt den Sammel-Prompt in `--- id: <id>` + Aufgabentext. */
function bloecke(inhalt: string): { id: string; frage: string }[] {
  return inhalt
    .split(/^--- id: /m)
    .slice(1)
    .map((teil) => {
      const zeilenumbruch = teil.indexOf('\n')
      return { id: teil.slice(0, zeilenumbruch).trim(), frage: teil.slice(zeilenumbruch + 1) }
    })
}

let server: Server
let basisUrl = ''
/** Jeder Anfrage-Rumpf, den der Prüfer geschickt hat — für die Lösungs-Prüfung. */
let gesendet: string[] = []

beforeAll(async () => {
  server = createServer((req, res) => {
    let roh = ''
    req.on('data', (c) => (roh += c))
    req.on('end', () => {
      gesendet.push(roh)
      const anfrage = JSON.parse(roh)
      const inhalt: string = anfrage.messages[0].content
      const istPlausibilitaet = String(anfrage.system).includes('Realitätsnähe')

      const antwort = bloecke(inhalt).map(({ id, frage }) => {
        if (istPlausibilitaet) return { id, ok: true, einwand: '' }
        const wert = loese(frage)
        return wert === null
          ? { id, antwort: '', eindeutig: false, anmerkung: 'kein rechenbarer Ausdruck' }
          : { id, antwort: wert, eindeutig: true, anmerkung: '' }
      })

      res.writeHead(200, { 'content-type': 'application/json' })
      res.end(JSON.stringify({ content: [{ type: 'text', text: JSON.stringify(antwort) }] }))
    })
  })
  await new Promise<void>((f) => server.listen(0, '127.0.0.1', f))
  const adr = server.address()
  basisUrl = `http://127.0.0.1:${typeof adr === 'object' && adr ? adr.port : 0}`
})

afterAll(() => new Promise<void>((f) => server.close(() => f())))

// ── Aufruf ──────────────────────────────────────────────────────────────────

/**
 * Startet den Prüfer. Arbeitsverzeichnis ist ein leeres Temp-Verzeichnis: dort
 * liegt keine .env, der Lauf erbt also nichts aus dem Repo, und out/ landet
 * nicht im Arbeitsbaum.
 */
async function pruefer(args: string[], env: Record<string, string | undefined> = {}) {
  gesendet = []
  const cwd = await mkdtemp(path.join(tmpdir(), 'verify-tasks-'))
  try {
    const { stdout, stderr } = await ausfuehren('node', [SKRIPT, ...args], {
      cwd,
      env: { PATH: process.env.PATH, HOME: process.env.HOME,
             ANTHROPIC_API_KEY: 'test-schluessel', ANTHROPIC_BASE_URL: basisUrl, ...env },
    })
    return { code: 0, ausgabe: stdout + stderr }
  } catch (e) {
    const f = e as { code?: number; stdout?: string; stderr?: string }
    return { code: f.code ?? -1, ausgabe: (f.stdout ?? '') + (f.stderr ?? '') }
  } finally {
    await rm(cwd, { recursive: true, force: true })
  }
}

/** Alles, was der Prüfer je an den Löser geschickt hat. */
const gesendetesGanz = () => gesendet.join('\n')

// ── Fälle ───────────────────────────────────────────────────────────────────

describe('Dateiquelle', () => {
  it('lässt eine korrekte Charge durch — Trefferquote 100 %, Exit 0', async () => {
    const { code, ausgabe } = await pruefer([
      '--quelle', 'datei', '--pfad', FIX('charge-korrekt.json'), '--ohne-plausibel',
    ])
    expect(ausgabe).toContain('4 Aufgabe(n) zu prüfen')
    expect(ausgabe).toMatch(/Trefferquote\s+100\.0 %/)
    expect(ausgabe).toMatch(/abweichung\s+0/)   // die Zeile steht immer da, der Wert muss 0 sein
    expect(code).toBe(0)
  })

  it('erkennt die absichtlich falsche Lösung und fällt durch', async () => {
    const { code, ausgabe } = await pruefer([
      '--quelle', 'datei', '--pfad', FIX('charge-falsch.json'), '--ohne-plausibel',
    ])
    // 13 * 7 = 91; hinterlegt ist 84. Der Prüfer rechnet 91 und widerspricht.
    expect(ausgabe).toContain('abweichung')
    expect(ausgabe).toContain('hinterlegt: ["84"]')
    expect(ausgabe).toContain('Prüfer: 91')
    expect(ausgabe).toMatch(/Trefferquote\s+75\.0 %/)
    expect(code).toBe(1)
  })

  it('schickt die hinterlegte Lösung NICHT an den Prüfer', async () => {
    await pruefer(['--quelle', 'datei', '--pfad', FIX('charge-korrekt.json'), '--ohne-plausibel'])
    expect(gesendet.length).toBeGreaterThan(0)
    const raus = gesendetesGanz()

    // Kein Lösungsfeld geht mit.
    for (const feld of ['correct_answers', 'correct_answer', 'acceptance', 'solution']) {
      expect(raus).not.toContain(feld)
    }
    // Und keiner der hinterlegten Werte. 12 fehlt in der Liste mit Absicht: es
    // steht in "144 / 12" in der Aufgabe selbst, wäre als Nachweis also wertlos.
    for (const wert of ['42', '91', '63']) expect(raus).not.toContain(wert)

    // Gegenprobe: die Fragen sind sehr wohl angekommen.
    expect(raus).toContain('24 + 18')
  })

  it('meldet fehlende Lösung, fehlenden skill_key und leeren Text ohne LLM', async () => {
    const { code, ausgabe } = await pruefer(
      ['--quelle', 'datei', '--pfad', FIX('charge-luecken.json'), '--nur-struktur'],
      { ANTHROPIC_API_KEY: undefined, ANTHROPIC_BASE_URL: undefined },
    )
    expect(ausgabe).toContain('3 beanstandet')
    expect(ausgabe).toContain('keine Lösung hinterlegt')
    expect(ausgabe).toContain('kein skill_key')
    expect(ausgabe).toContain('leerer Aufgabentext')
    expect(code).toBe(1)
  })

  it('wendet --skill und --status auch auf die Datei an', async () => {
    const { ausgabe } = await pruefer([
      '--quelle', 'datei', '--pfad', FIX('charge-korrekt.json'),
      '--status', 'draft', '--ohne-plausibel',
    ])
    expect(ausgabe).toContain('3 Aufgabe(n) zu prüfen')
  })
})

describe('Abbruch statt stillem Fehlschlag', () => {
  it('bricht ohne ANTHROPIC_API_KEY mit klarer Meldung ab, nicht mit 401', async () => {
    const { code, ausgabe } = await pruefer(
      ['--quelle', 'datei', '--pfad', FIX('charge-korrekt.json')],
      { ANTHROPIC_API_KEY: undefined },
    )
    expect(ausgabe).toContain('ANTHROPIC_API_KEY ist nicht gesetzt')
    expect(ausgabe).toContain('--nur-struktur')
    expect(ausgabe).not.toContain('401')
    expect(code).toBe(2)
  })

  it('bricht bei abgewiesenem Schlüssel ab, statt alles als ungeprüft zu zählen', async () => {
    // Ein Server, der wie die echte API bei ungültigem Schlüssel antwortet.
    const abweisend = createServer((_req, res) => {
      res.writeHead(401, { 'content-type': 'application/json' })
      res.end(JSON.stringify({ type: 'error', error: { message: 'API key is invalid.' } }))
    })
    await new Promise<void>((f) => abweisend.listen(0, '127.0.0.1', f))
    const adr = abweisend.address()
    const url = `http://127.0.0.1:${typeof adr === 'object' && adr ? adr.port : 0}`
    try {
      const { code, ausgabe } = await pruefer(
        ['--quelle', 'datei', '--pfad', FIX('charge-korrekt.json')],
        { ANTHROPIC_BASE_URL: url },
      )
      expect(ausgabe).toContain('wird abgelehnt (HTTP 401)')
      expect(ausgabe).not.toContain('Vollständig: out/verify-tasks.csv')   // kein Bericht, kein Urteil
      expect(code).toBe(2)
    } finally {
      await new Promise<void>((f) => abweisend.close(() => f()))
    }
  })

  it('verlangt --pfad zur Dateiquelle', async () => {
    const { code, ausgabe } = await pruefer(['--quelle', 'datei'])
    expect(ausgabe).toContain('--quelle datei braucht --pfad')
    expect(code).toBe(2)
  })

  it('weist eine unbekannte Quelle ab', async () => {
    const { code, ausgabe } = await pruefer(['--quelle', 'irgendwas'])
    expect(ausgabe).toContain('--quelle kennt nur')
    expect(code).toBe(2)
  })

  it('nennt Datei und Grund, wenn das JSON kaputt ist', async () => {
    const { code, ausgabe } = await pruefer(['--quelle', 'datei', '--pfad', SKRIPT])
    expect(ausgabe).toContain('ist kein gültiges JSON')
    expect(code).toBe(2)
  })
})
