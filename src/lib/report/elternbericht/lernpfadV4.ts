// Eltern-Bericht v4 — der Lernpfad nach Klassenarbeiten (Bauauftrag V4,
// Entscheidung 5; Seite 4 und Station 04 der Präsentation).
//
// Grundlage sind die Schwerpunkte aus schwerpunkte.ts in ihrer Reihenfolge und
// mit ihrer Startlogik (hier nicht geändert). Neu je Schwerpunkt: die Ziele =
// die kommenden Stationen des Fahrplans, die seine Übungsbedarf-Bereiche
// betreffen, aufsteigend; bei einer Lücke im aktuellen Thema zuerst Station 1,
// wenn deren Arbeit noch ansteht.
// Aufeinanderfolgende Schwerpunkte mit derselben ersten Ziel-Station werden
// zu einem Punkt („Grundlagen für …“). Am Ende ein Punkt „später“ mit den
// Feldern aus `danach`.

import type {
  EbFahrplan,
  EbGrund,
  EbLernpfadPunkt,
  EbSchwerpunkt,
  EbThemaSignal,
  ThemenfeldKey,
} from '@/types'

/** Höchstens so viele Bereiche im Kasten „Das üben wir“. */
export const TEILE_MAX = 4

const teileAus = (labels: readonly string[]): Pick<EbLernpfadPunkt, 'teile' | 'rest'> => {
  const einmal = [...new Set(labels)]
  return { teile: einmal.slice(0, TEILE_MAX), rest: Math.max(0, einmal.length - TEILE_MAX) }
}

/**
 * @param schwerpunkte bericht.schwerpunkte (Reihenfolge aus schwerpunkte.ts)
 * @param gruende bericht.gruende, parallel dazu
 * @param danach bericht.danach
 * @param fahrplan bericht.fahrplan; null → keine Ziele, jeder Schwerpunkt einzeln
 * @param signale bericht.signale (Bereiche je Thema)
 */
export function gruppiereSchwerpunkte({
  schwerpunkte,
  gruende,
  danach,
  fahrplan,
  signale,
}: {
  schwerpunkte: readonly EbSchwerpunkt[]
  gruende: readonly (EbGrund | undefined)[]
  danach: readonly ThemenfeldKey[]
  fahrplan: EbFahrplan | null
  signale: readonly EbThemaSignal[]
}): EbLernpfadPunkt[] {
  const kommende = (fahrplan?.stationen ?? []).filter((s) => s.nummer > 1)
  // Steht die Arbeit zum aktuellen Thema noch an, bereitet eine Lücke in diesem Thema genau sie vor.
  const ansteht = fahrplan?.stationen[0]?.stand === 'naechste' || fahrplan?.stationen[0]?.stand === 'steht'
  const fehltJeThema = new Map(signale.map((s) => [s.themaKey, new Set(s.fehlt.map((b) => b.label))]))
  const zieleVon = (s: EbSchwerpunkt): number[] => [
    ...(ansteht && s.feld === null ? [1] : []),
    ...kommende.filter((st) => s.uebung.some((l) => fehltJeThema.get(st.themaKey)?.has(l))).map((st) => st.nummer),
  ]

  const einzeln: EbLernpfadPunkt[] = schwerpunkte.map((s, i) => ({
    art: s.feld ? 'feld' : 'luecke',
    titelFeld: s.feld,
    titelThema: s.feld ? null : s.thema,
    ziele: zieleVon(s),
    ...teileAus(s.uebung),
    grund: gruende[i] ?? null,
  }))

  // Gruppieren: gleiche erste Ziel-Station hintereinander → ein Punkt.
  const punkte: EbLernpfadPunkt[] = []
  for (const p of einzeln) {
    const vorher = punkte[punkte.length - 1]
    const gleich = vorher && vorher.ziele.length > 0 && p.ziele.length > 0 && vorher.ziele[0] === p.ziele[0]
    if (!gleich) {
      punkte.push(p)
      continue
    }
    const titel = kommende.find((st) => st.nummer === p.ziele[0])?.titel ?? null
    // Die Teile beider Punkte zusammen, wieder höchstens vier; der Rest addiert sich.
    const rest = vorher.rest + p.rest
    const { teile, rest: ueber } = teileAus([...vorher.teile, ...p.teile])
    punkte[punkte.length - 1] = {
      art: 'gruppe',
      titelFeld: null,
      titelThema: titel,
      ziele: [...new Set([...vorher.ziele, ...p.ziele])].sort((a, b) => a - b),
      teile,
      rest: rest + ueber,
      grund: vorher.grund,
    }
  }

  if (danach.length > 0) {
    punkte.push({
      art: 'spaeter',
      titelFeld: null,
      titelThema: null,
      ziele: [],
      teile: [],
      rest: 0,
      grund: null,
      felder: [...danach],
    })
  }
  return punkte
}
