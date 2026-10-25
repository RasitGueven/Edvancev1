// Eltern-Bericht v2 — Seite 1, „Auf einen Blick“: eine Zeile je Klassenstufe.
//
// Stufe eines Bereichs wie im Lernweg (zoneFuer): Klasse 5/6 Grundlagen, 7/8
// weiterführend, ab der Stufe des Kindes „aktuell“. Gezählt werden die
// direkt geprüften Bereiche, die auch Seite 2 zählt (ohne unsichere Vorgriffe).
// Der Kurzsatz je Zeile folgt STUFEN_REGEL (berichtKonfig.ts).

import { STUFEN_REGEL } from '@/lib/report/elternbericht/berichtKonfig'
import { zoneFuer } from '@/lib/report/elternbericht/lernweg'
import type { EbBereich, EbStufeKey, EbStufenUrteil, EbStufenZeile } from '@/types'

const REIHENFOLGE: readonly EbStufeKey[] = ['grundlagen', 'weiterfuehrend', 'aktuell']

/** Die Stufe eines Bereichs für ein Kind dieser Klasse. */
export function stufeFuer(bereichKlasse: number, kindKlasse: number): EbStufeKey {
  const zone = zoneFuer(bereichKlasse, kindKlasse)
  return zone === 'kommt' ? 'aktuell' : zone
}

export function baueStufen(bereiche: readonly EbBereich[], kindKlasse: number): EbStufenZeile[] {
  const zeilen = REIHENFOLGE.flatMap((stufe) => {
    const drin = bereiche.filter((b) => stufeFuer(b.klasse, kindKlasse) === stufe)
    if (drin.length === 0) return []
    const sicher = drin.filter((b) => b.sicher).length
    const klassen = drin.map((b) => b.klasse)
    return [{ stufe, von: Math.min(...klassen), bis: Math.max(...klassen), sicher, uebung: drin.length - sicher }]
  })
  const luecken = lueckenStufe(zeilen)
  return zeilen.map((z) => ({ ...z, urteil: urteil(z, z.stufe === luecken) }))
}

/**
 * Die Stufe mit dem meisten Übungsbedarf (Gleichstand: die tiefere), wenn dort
 * mindestens STUFEN_REGEL.lueckenAnteil Übungsbedarf ist; sonst null.
 */
export function lueckenStufe(zeilen: readonly Pick<EbStufenZeile, 'stufe' | 'sicher' | 'uebung'>[]): EbStufeKey | null {
  let beste: Pick<EbStufenZeile, 'stufe' | 'sicher' | 'uebung'> | null = null
  for (const z of zeilen) if (z.uebung > 0 && (!beste || z.uebung > beste.uebung)) beste = z
  if (!beste) return null
  return beste.uebung / (beste.sicher + beste.uebung) >= STUFEN_REGEL.lueckenAnteil ? beste.stufe : null
}

function urteil(z: Pick<EbStufenZeile, 'sicher' | 'uebung'>, istLueckenStufe: boolean): EbStufenUrteil {
  if (istLueckenStufe) return 'luecken'
  const anteil = z.sicher / (z.sicher + z.uebung)
  if (anteil === 1) return 'sicher'
  if (anteil >= STUFEN_REGEL.weitgehendAnteil) return 'weitgehend'
  if (anteil >= STUFEN_REGEL.gemischtAnteil) return 'gemischt'
  return 'luecken'
}
