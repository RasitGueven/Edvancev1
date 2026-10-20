// Slots SL2, Test 6: keine hart codierten Strings in der Oberfläche, jeder benutzte Schlüssel steht in
// de/slots.json (auch die aus Template-Strings), jeder SL-Code hat einen Text.

import { readFileSync, readdirSync, statSync } from 'node:fs'
import { join } from 'node:path'
import { describe, expect, it } from 'vitest'
import de from '@/i18n/locales/de/slots.json'
import { SLOTS_CODES } from '@/lib/slots/fehler'

const WURZEL = join(__dirname)

function dateien(ordner: string): string[] {
  return readdirSync(ordner).flatMap((n) => {
    const p = join(ordner, n)
    if (statSync(p).isDirectory()) return dateien(p)
    return /\.tsx?$/.test(n) && !/\.test\.tsx?$/.test(n) ? [p] : []
  })
}

function hat(schluessel: string): boolean {
  const wert = (k: string): unknown => k.split('.').reduce<unknown>((o, x) => (o as Record<string, unknown> | undefined)?.[x], de)
  return typeof wert(schluessel) === 'string' || typeof wert(`${schluessel}_one`) === 'string'
}

const QUELLEN = dateien(WURZEL).map((p) => ({ p, s: readFileSync(p, 'utf8') }))
const OBEN = Object.keys(de)

describe('Slots-Texte', () => {
  it('jeder Schlüssel aus den Quellen steht in de/slots.json', () => {
    const fehlend: string[] = []
    for (const { p, s } of QUELLEN) {
      for (const m of s.matchAll(/['`]([a-z][a-zA-Z0-9]*(?:\.[a-zA-Z0-9_]+)+)['`]/g)) {
        const k = m[1]
        if (!OBEN.includes(k.split('.')[0]) || /\.(tsx?|json)$/.test(k)) continue
        if (!hat(k)) fehlend.push(`${p.replace(WURZEL, '')}: ${k}`)
      }
    }
    expect(fehlend).toEqual([])
  })

  it('auch die Schlüssel aus Template-Strings', () => {
    const erwartet = [
      ...['planned', 'present', 'cancelled', 'unexcused', 'cancelled_by_us'].map((z) => `zustand.${z}`),
      ...['kein_stammplatz', 'aufgebraucht', 'reicht_bis', 'ohne_termin', 'passt'].map((a) => `planbilanz.art.${a}`),
      ...['ohne_termin', 'ohne_einheit'].map((a) => `planbilanz.satz.abweichung.${a}`),
      ...['vertretung', 'zusatz', 'faellt_aus'].map((a) => `raumArt.${a}`),
      ...['woechentlich', 'a_woche', 'b_woche'].map((k) => `takt.${k}`),
      ...['a_woche', 'b_woche'].map((k) => `taktKurz.${k}`),
      'laufzeit.6', 'laufzeit.12',
      ...['alle', 'kein_stammplatz', 'reicht_nicht', 'einheiten_uebrig', 'aufgebraucht', 'passt'].map((f) => `kinder.filter.${f}`),
      ...['verbraucht', 'geplant', 'gesamt'].map((k) => `einheiten.${k}Label`),
      ...SLOTS_CODES.map((c) => `fehler.${c}`),
      // W2
      ...['rot', 'gelb', 'gruen', 'leer', 'keinCoach'].map((f) => `wochenplan2.legende.${f}`),
      ...['einmal', 'jedeWoche'].map((m) => `wochenplan2.kind.modus.${m}`),
      ...['kein_vertrag', 'vertrag_ab', 'SL001', 'SL002', 'SL003', 'SL004', 'SL005', 'SL006', 'SL007', 'SL011', 'SL012', 'SL013']
        .map((c) => `wochenplan2.grund.${c}`),
    ]
    expect(erwartet.filter((k) => !hat(k))).toEqual([])
  })

  it('kein deutscher Text direkt im JSX oder in Attributen', () => {
    const funde: string[] = []
    for (const { p, s } of QUELLEN.filter((q) => q.p.endsWith('.tsx'))) {
      const ohneKommentare = s.replace(/\/\*[\s\S]*?\*\//g, '').replace(/^\s*\/\/.*$/gm, '')
      // Textknoten: nach einem schließenden Tag (nicht "=>"), ohne Code-Zeichen, in einer Zeile.
      for (const m of ohneKommentare.matchAll(/(?<![=-])>[ \t]*([A-Za-zÄÖÜäöüß][^<>{}()=;'"?&|\n]*[a-zäöüß]{2,}[^<>{}()=;'"?&|\n]*)</g)) {
        funde.push(`${p}: ${m[1].trim()}`)
      }
      for (const m of ohneKommentare.matchAll(/\b(?:placeholder|title|aria-label|alt)="([^"]*[A-Za-zÄÖÜäöüß]{2,}[^"]*)"/g)) funde.push(`${p}: ${m[1]}`)
    }
    expect(funde).toEqual([])
  })
})
