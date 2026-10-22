// Tablet-Präsentation — die Kette in Station 03 (PS-1, Entscheidungen 10 und 11).
//
// Statt der vollen Karte zeigt Station 03 zuerst den Weg zum Thema in höchstens
// fünf Kästen: Sitzt schon → Hier hakt es → Baut darauf auf → Ihr Thema →
// Kommt als Nächstes. Alles aus PraesentationDaten, also aus derselben
// Rechnung wie der Druckbogen; die Kette lässt nur weg.
//
// Fälle:
//   - Thema-Schwerpunkt (Schwerpunkt 1 ist das Thema): die volle Kette.
//   - Thema ohne Übungsbedarf: „Ihr Thema · sitzt", dann das nächste Thema.
//   - Ohne Thema: der erste Schwerpunkt — erster sicherer Bereich, erster
//     Bereich mit Übungsbedarf, Themenfeld, dann das nächste Thema.
//   - Ohne Schwerpunkt und ohne Thema: null (Station 03 zeigt die volle Karte).

import type { PraesentationDaten, TpGlied, TpKette, TpThemaWeg } from '@/types'

/** Höchstens so viele Kästen. */
export const MAX_GLIEDER = 5

type KetteEingabe = Pick<PraesentationDaten, 'schwerpunkte' | 'thema' | 'themaWeg' | 'naechstesThema'>

/**
 * Der sichere Bereich, auf dem die Startstelle aufbaut: zuerst über eine
 * direkte Kante (bei mehreren der späteste in der Thema-Reihenfolge), sonst
 * der letzte sichere Bereich vor der Startstelle in der Thema-Reihenfolge.
 */
export function basisFuer(start: string, weg: TpThemaWeg | null): { label: string; kante: boolean } | null {
  if (!weg) return null
  const sicher = new Set(weg.reihe.filter((r) => r.sicher).map((r) => r.label))
  const ueberKante = new Set(weg.kanten.filter((k) => k.zu === start && sicher.has(k.von)).map((k) => k.von))
  const kante = weg.reihe.filter((r) => ueberKante.has(r.label)).at(-1)
  if (kante) return { label: kante.label, kante: true }
  const stelle = weg.reihe.findIndex((r) => r.label === start)
  const davor = weg.reihe.slice(0, Math.max(0, stelle)).filter((r) => r.sicher).at(-1)
  return davor ? { label: davor.label, kante: false } : null
}

export function kette(p: KetteEingabe): TpKette | null {
  const kommt: TpGlied[] = p.naechstesThema ? [{ art: 'kommt', label: p.naechstesThema }] : []
  const erster = p.schwerpunkte[0]

  let k: TpKette
  if (erster?.thema && erster.start) {
    const basis = basisFuer(erster.start, p.themaWeg)
    k = {
      fall: 'thema',
      glieder: [
        ...(basis ? [{ art: 'basis' as const, label: basis.label, kante: basis.kante }] : []),
        { art: 'start', label: erster.start },
        ...(erster.naechster ? [{ art: 'naechster' as const, label: erster.naechster }] : []),
        { art: 'thema', label: erster.thema },
        ...kommt,
      ],
    }
  } else if (p.thema) {
    k = { fall: 'themaSitzt', glieder: [{ art: 'themaSitzt', label: p.thema }, ...kommt] }
  } else if (erster?.feld) {
    k = {
      fall: 'feld',
      glieder: [
        ...(erster.sicher[0] ? [{ art: 'basis' as const, label: erster.sicher[0] }] : []),
        ...(erster.uebung[0] ? [{ art: 'start' as const, label: erster.uebung[0] }] : []),
        { art: 'feld', feld: erster.feld },
        ...kommt,
      ],
    }
  } else {
    return null
  }
  return { ...k, glieder: k.glieder.slice(0, MAX_GLIEDER) }
}
