// Station 04 (V4): die Punkte auf der Kurve in der Reihenfolge des Lernpfads,
// mit allem, was der feste Kasten rechts zeigt. Reine Rechnung auf dem
// Elternbericht aus v4Daten.ts; Texte über die übergebenen t-Funktionen.

import type { TFunction } from 'i18next'

import { grundText } from '@/components/edvance/elternbericht/berichtSaetze'
import { baueListe } from '@/components/edvance/elternbericht/liste'
import { voraussetzungText } from '@/components/edvance/elternbericht/fahrplanText'
import { VIEWBOX, kurvenPunkte, punktBei } from '@/lib/report/praesentation/kurve'
import type { EbLernpfadPunkt, TpSeite } from '@/types'

import { kommende, type PraesentationV4 } from './v4Daten'

/** Höchstens vier Punkte aus dem Lernpfad, dazu bei Sorgfalts-Muster der blaue Punkt. */
export const LERNPFAD_MAX = 4

export type FoerderPunkt = {
  key: string
  art: 'lernpfad' | 'sorgfalt'
  titel: string
  /** Beschriftung unter dem Titel am Punkt: „Klassenarbeit 2“ bzw. „in jeder Session“. */
  zeile: string
  /** Pille im Kasten: „Voraussetzung für Klassenarbeit 2“ bzw. „in jeder Session“. */
  pille: string
  grund: string
  sitzt: string[]
  angehen: string[]
  /** So viele Bereiche über die gezeigten hinaus. */
  rest: number
  ziel: string | null
}

export type Lage = { x: number; y: number; anteil: number; seite: TpSeite }

/** Lage der Punkte: für fünf die Werte aus dem Auftrag, sonst die Tabelle aus der Anforderung (Entscheidung 9). */
export function lagen(n: number): Lage[] {
  // Die Beschriftung des ersten Punkts steht darunter, alle weiteren links oben davon:
  // Die Kurve steigt nach rechts, links oberhalb eines Punkts ist sie frei.
  const seite = (i: number): TpSeite => (i === 0 ? 'unten' : 'linksOben')
  if (n !== 5) return kurvenPunkte(n).map((l, i) => ({ ...l, seite: seite(i) }))
  return [0.27, 0.47, 0.62, 0.76, 0.9].map((anteil, i) => {
    const [x, y] = punktBei(anteil)
    return { anteil, x: x / (VIEWBOX.w / 100), y: y / (VIEWBOX.h / 100), seite: seite(i) }
  })
}

type Texte = { tp: TFunction<'praesentation'>; tb: TFunction<'elternbericht'>; sprache: string }

function zielFuer(v4: PraesentationV4, art: 'vorbereitet' | 'spaeter' | 'sorgfalt' | 'weitere', { tb }: Texte): string | null {
  const z = v4.ziele.find((e) => e.schluessel.startsWith(`v4.s5.ziele.${art}`))
  return z ? tb(z.schluessel, z.werte) : null
}

/** Wie Seite 4 des Berichts: eine Lücke im aktuellen Thema heißt nach ihren Übungsbereichen, nicht nach dem Thema. */
function lueckeImThema(l: EbLernpfadPunkt, v4: PraesentationV4, { tb, sprache }: Texte): string | null {
  const luecke = l.grund?.art === 'spaeterGebraucht' || l.grund?.art === 'themaGeschrieben'
  const sp = v4.bericht.schwerpunkte.find((s) => s.feld === null)
  if (l.art !== 'luecke' || !luecke || !sp) return null
  return baueListe(tb, sprache)(sp.uebung)
}

function lernpfadPunkt(l: EbLernpfadPunkt, i: number, v4: PraesentationV4, texte: Texte): FoerderPunkt {
  const { tp, tb } = texte
  const { bericht } = v4
  const station = (nr: number) => v4.fahrplan.stationen.find((s) => s.nummer === nr)
  const erste = kommende(v4.fahrplan).find((s) => s.signal === 'fehlt')
  const [n] = l.ziele

  const titel =
    l.art === 'feld' && l.titelFeld
      ? tb(`feld.${l.titelFeld}`)
      : l.art === 'gruppe'
        ? tb('v4.s4.gruppe', { thema: l.titelThema })
        : lueckeImThema(l, v4, texte) ?? (l.titelThema ?? '')
  // Ohne kommende Station: eine Lücke im aktuellen Thema („Vorhandene Lücke“) oder Stoff, der später wichtig wird.
  const ohneZiel = tb(l.art === 'luecke' ? 's4.chip.luecke' : 'v4.s3.spaeter')
  // L5: Nummer der Klassenarbeit nur bei bekannter Folge, sonst das Thema.
  const pille = voraussetzungText(tb, v4.fahrplan, l.ziele) ?? ohneZiel
  const ziel = n === undefined ? undefined : station(n)
  // Die Zeile unter dem Kurvenpunkt bleibt kurz: ohne bekannte Arbeit der Stand der Station („als Nächstes im
  // Unterricht“), das Thema steht in der Pille im Kasten.
  const zeile = !ziel ? ohneZiel : ziel.ka !== null ? tp('v4.s3.karte', { n: ziel.ka }) : tb(`v4.stand.${ziel.stand}`)

  let sitzt: string[]
  if (l.art === 'gruppe' && n !== undefined) {
    const s = station(n)
    sitzt = (bericht.signale ?? []).find((x) => x.themaKey === s?.themaKey)?.sitzt.map((b) => b.label) ?? []
  } else {
    const sp = bericht.schwerpunkte.find((x) => (l.art === 'feld' ? x.feld === l.titelFeld : x.thema !== null))
    sitzt = sp?.sicher ?? []
  }

  const grund = l.grund
    ? l.grund.art === 'spaeterGebraucht'
      ? tb('s4.spaeterZeile', { titel: l.grund.titel })
      : tb('s4.grund', { grund: grundText(tb, l.grund) })
    : ''
  const art = n === undefined ? 'weitere' : n === erste?.nummer ? 'vorbereitet' : 'spaeter'
  return {
    key: `${l.art}-${l.titelFeld ?? l.titelThema ?? i}`,
    art: 'lernpfad',
    titel,
    zeile,
    pille,
    grund,
    sitzt,
    angehen: l.teile,
    rest: l.rest,
    // L5 Teil D: Passt kein Ziel zum ersten Punkt, trägt er das erste Systemziel (Ziele erscheinen immer).
    ziel: zielFuer(v4, art, texte) ?? (i === 0 && v4.ziele[0] ? texte.tb(v4.ziele[0].schluessel, v4.ziele[0].werte) : null),
  }
}

/** Die Punkte der Kurve: Lernpfad ohne „später“ (höchstens vier), dann Sorgfalt. */
export function baueFoerderPunkte(v4: PraesentationV4, name: string | null, texte: Texte): FoerderPunkt[] {
  const punkte = (v4.bericht.lernpfad ?? [])
    .filter((l) => l.art !== 'spaeter')
    .slice(0, LERNPFAD_MAX)
    .map((l, i) => lernpfadPunkt(l, i, v4, texte))
  if (v4.muster?.sorgfalt) {
    const { tp } = texte
    punkte.push({
      key: 'sorgfalt',
      art: 'sorgfalt',
      titel: tp('v4.s4.sorgfalt.titel'),
      zeile: tp('v4.s4.sorgfalt.zeile'),
      pille: tp('v4.s4.sorgfalt.zeile'),
      grund: tp(name ? 'v4.s4.sorgfalt.text' : 'v4.s4.sorgfalt.textOhneName', { name }),
      sitzt: [],
      angehen: [],
      rest: 0,
      ziel: zielFuer(v4, 'sorgfalt', texte),
    })
  }
  return punkte
}
