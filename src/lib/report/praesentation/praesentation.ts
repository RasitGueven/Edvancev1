// Tablet-Präsentation — alles, was die vier Stationen zeigen, an einer Stelle.
//
// Eine Rechnung für Tablet und Papier (Entscheidung 2 der Anforderung):
// baueElternbericht (R7) liefert Zahlen, Profil, Pyramide, Schwerpunkte und
// „danach". Die Präsentation teilt diese Werte nur nach „übersprungen" auf
// (zustand 'nicht_angesetzt', auch vorläufig) und zählt nie selbst gegen den
// Katalog. Neu gerechnet werden nur Überblick, Empfehlung und Kurvenpunkte.
// Schwerpunkte und Anliegen kommen aus schwerpunkte.ts und anliegen.ts (R7-11).

import { anliegenAus } from '@/lib/report/elternbericht/anliegen'
import { baueElternbericht } from '@/lib/report/elternbericht/bericht'
import { bereicheAus } from '@/lib/report/elternbericht/bereiche'
import { genitiv } from '@/lib/report/elternbericht/genitiv'
import { stufeAusKlasse } from '@/lib/report/inhaltsbereiche'
import { empfehlungAus } from '@/lib/report/praesentation/empfehlung'
import { ueberblick } from '@/lib/report/praesentation/ueberblick'
import type {
  EbBereich,
  Elternbericht,
  PraesentationDaten,
  ReportData,
  ReportNotes,
  Stufe,
  SucheSkill,
  TierPlan,
  TpAnzeige,
  TpAnzeigeZahlen,
  TpEbene,
  TpSchwerpunkt,
  TpZeile,
} from '@/types'

/** Der Zustand „übersprungen": bei allen Proben „Weiß ich nicht" oder leer. */
export const UEBERSPRUNGEN = 'nicht_angesetzt'

export type PraesentationEingabe = {
  data: ReportData
  notes: ReportNotes | null
  tiers: readonly TierPlan[]
}

export type PraesentationFehlt = { fehlt: 'kompetenzen' | 'katalog' }

/** Die drei Zustände eines direkt geprüften Bereichs auf dem Tablet. */
export function zustandAufTablet(zustand: string): 'sicher' | 'uebung' | 'uebersprungen' {
  if (zustand === 'traegt') return 'sicher'
  if (zustand === UEBERSPRUNGEN) return 'uebersprungen'
  return 'uebung'
}

/** Schlüssel der übersprungenen Bereiche. Bei Doppeln gilt der letzte, wie in bereicheAus. */
export function uebersprungeneSchluessel(kompetenzen: readonly SucheSkill[]): Set<string> {
  const letzter = new Map(kompetenzen.map((k) => [k.skillKey, k.zustand]))
  return new Set([...letzter].filter(([, z]) => zustandAufTablet(z) === 'uebersprungen').map(([k]) => k))
}

const nachKlasseLabel = (a: EbBereich, b: EbBereich): number =>
  a.klasse - b.klasse || a.label.localeCompare(b.label, 'de')

const STUFEN: readonly Stufe[] = ['erprobung', 'erste', 'zweite']

function zeilenAus(bericht: Elternbericht, bereiche: EbBereich[], ueber: Set<string>): TpZeile[] {
  return bericht.profil
    .filter((z) => z.sicher + z.uebung > 0)
    .map((z) => {
      const drin = bereiche.filter((b) => b.feld === z.feld).sort(nachKlasseLabel)
      return {
        feld: z.feld,
        vorhanden: z.vorhanden,
        sicher: drin.filter((b) => b.sicher),
        uebung: drin.filter((b) => !b.sicher && !ueber.has(b.skillKey)),
        uebersprungen: drin.filter((b) => !b.sicher && ueber.has(b.skillKey)),
      }
    })
}

function pyramideAus(bericht: Elternbericht, ueber: Set<string>): TpEbene[] {
  return bericht.pyramide.map((e) => {
    const uebersprungen = e.gruppen
      .flatMap((g) => g.eintraege)
      .filter((b) => !b.sicher && ueber.has(b.skillKey)).length
    return {
      ebene: e.ebene,
      stufen: [...e.stufen],
      sicher: e.sicher,
      uebung: e.uebung - uebersprungen,
      uebersprungen,
    }
  })
}

/** Genau die Schwerpunkte aus schwerpunkte.ts (R7-11, Entscheidung 6), nur um die Stufen ergänzt. */
function schwerpunkteAus(bericht: Elternbericht, bereiche: EbBereich[]): TpSchwerpunkt[] {
  return bericht.schwerpunkte.map((s) => {
    // Thema: die Bereiche des Schwerpunkts (Übungsbedarf, sonst die sicheren); Feld: wie bisher.
    const labels = new Set(s.uebung.length > 0 ? s.uebung : s.sicher)
    const drin = s.feld
      ? bereiche.filter((b) => b.feld === s.feld && !b.sicher)
      : bereiche.filter((b) => labels.has(b.label))
    const stufen = new Set(drin.map((b) => stufeAusKlasse(b.klasse)))
    return {
      feld: s.feld,
      thema: s.thema,
      gemischt: s.gemischt,
      stufen: STUFEN.filter((st) => stufen.has(st)),
      sicher: [...s.sicher],
      uebung: [...s.uebung],
    }
  })
}

export function bauePraesentation({
  data,
  notes,
  tiers,
}: PraesentationEingabe): PraesentationDaten | PraesentationFehlt {
  const { kompetenzen, katalog } = data.erzaehlung
  const bericht = baueElternbericht({
    kompetenzen,
    katalog,
    klasse: data.grade,
    lernweg: { erzaehlung: data.erzaehlung, datum: data.analysedAt },
  })
  if (!bericht) return { fehlt: kompetenzen.length === 0 ? 'kompetenzen' : 'katalog' }

  const bereiche = bereicheAus(kompetenzen)
  const ueber = uebersprungeneSchluessel(kompetenzen)
  const uebersprungen = bereiche.filter((b) => !b.sicher && ueber.has(b.skillKey)).length
  const { zaehlung } = bericht
  const name = data.firstName?.trim() || null

  return {
    name,
    wessen: name ? genitiv(name) : null,
    fach: data.subject,
    klasse: data.grade,
    naechstesThema: data.naechstesThema,
    testlauf: data.testlauf,
    laeuftNoch: data.status === 'in_progress',
    kopfFall: bericht.kopfFall,
    ueberblick: ueberblick(bericht),
    zahlen: {
      sicher: zaehlung.sicher,
      uebung: zaehlung.uebung - uebersprungen,
      uebersprungen,
      untersucht: zaehlung.untersucht,
      katalog: zaehlung.katalog,
      bisKlasse: zaehlung.bisKlasse,
    },
    zeilen: zeilenAus(bericht, bereiche, ueber),
    pyramide: pyramideAus(bericht, ueber),
    lernweg: bericht.lernweg,
    schwerpunkte: schwerpunkteAus(bericht, bereiche),
    danach: [...bericht.danach],
    empfehlung: empfehlungAus(notes?.paket ?? null, tiers),
    anliegen: anliegenAus({
      anlassNamen: data.erzaehlung.anlassNamen,
      naechstesThema: data.naechstesThema,
      schwerpunkte: bericht.schwerpunkte,
    }),
  }
}

/** Sicher, Übungsbedarf (ohne) und übersprungen — für Zahlen, Zeile oder Ebene. */
export type TpAnteile = { sicher: number; uebung: number; uebersprungen: number }

/** Die Anteile einer Zeile aus ihren Listen. */
export const anteileZeile = (z: TpZeile): TpAnteile => ({
  sicher: z.sicher.length,
  uebung: z.uebung.length,
  uebersprungen: z.uebersprungen.length,
})

/**
 * Die drei Zahlen je Zählweise (Entscheidung 4). kombiniert: Übungsbedarf mit
 * übersprungen, dritte „davon"; getrennt: ohne, dritte „eigen". Ohne
 * übersprungene Bereiche keine dritte Zahl.
 */
export function anzeigeZahlen(anteile: TpAnteile, anzeige: TpAnzeige): TpAnzeigeZahlen {
  const { sicher, uebung, uebersprungen } = anteile
  const kombiniert = anzeige === 'kombiniert'
  return {
    sicher,
    uebung: kombiniert ? uebung + uebersprungen : uebung,
    dritte: uebersprungen > 0 ? { wert: uebersprungen, art: kombiniert ? 'davon' : 'eigen' } : null,
  }
}
