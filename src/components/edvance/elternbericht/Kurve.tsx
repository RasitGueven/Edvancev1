import { useLayoutEffect, useRef, useState } from 'react'

import { KNOTEN_X, kurvenPfade } from './kurve'

/** Die Seite 4 beginnt an der Oberkante des Inhaltskastens (y 80, x 44). */
const OBEN = 80
const LINKS = 44
const BREITE = 507
const HOEHE = 720
/** Knotenmitte über der Grundlinie des Titels. */
const KNOTEN_UEBER_GRUNDLINIE = 3.4
/** Mitte der Kicker-Zeile unter der Oberkante des Lernziel-Kastens. */
const ZIEL_UNTER_KASTEN = 16.3

type Lage = { knoten: number[]; ziel: number | null }

/** Grundlinien der Titel (`.eb-s4-grund`) und Lernziel-Kasten, in pt der Seite. */
function miss(bereich: HTMLElement): Lage | null {
  const r = bereich.getBoundingClientRect()
  if (r.width === 0) return null
  const pt = BREITE / r.width
  const y = (px: number): number => OBEN + (px - r.top) * pt

  const knoten = [...bereich.querySelectorAll('.eb-s4-grund')].map(
    (el) => y(el.getBoundingClientRect().bottom) - KNOTEN_UEBER_GRUNDLINIE,
  )
  const kasten = bereich.querySelector('[data-kurve-ziel]')
  const ziel = kasten ? y(kasten.getBoundingClientRect().top) + ZIEL_UNTER_KASTEN : null
  return { knoten, ziel }
}

const gleich = (a: Lage | null, b: Lage | null): boolean =>
  a === b ||
  (a !== null &&
    b !== null &&
    a.ziel === b.ziel &&
    a.knoten.length === b.knoten.length &&
    a.knoten.every((k, i) => k === b.knoten[i]))

/**
 * Die Kurve auf Seite 4 wie im Logo: Knoten in der Höhe jedes Schwerpunkt-
 * Titels, dazwischen Kurvenstücke, am Ende der Auslauf mit goldener Spitze ins
 * Lernziel. Die Lagen werden nach dem Layout gemessen (auch nach dem Laden der
 * Schriften und bei jeder Größenänderung); der Bogen skaliert nie, deshalb
 * gelten sie im Druck genauso. Die Rechnung steht in kurve.ts.
 *
 * Gemessen wird das Elternelement des SVG (die Seite): Ein Ref am Eltern-
 * element wäre im Layout-Effekt des Kinds noch nicht gesetzt.
 */
export function Kurve(): JSX.Element {
  const svg = useRef<SVGSVGElement>(null)
  const [lage, setLage] = useState<Lage | null>(null)

  useLayoutEffect(() => {
    const el = svg.current?.parentElement
    if (!el) return
    let aktiv = true
    const messen = (): void => {
      if (!aktiv) return
      const neu = miss(el)
      setLage((alt) => (gleich(alt, neu) ? alt : neu))
    }
    messen()
    void document.fonts?.ready.then(messen)
    const beobachter = typeof ResizeObserver === 'undefined' ? null : new ResizeObserver(messen)
    beobachter?.observe(el)
    return () => {
      aktiv = false
      beobachter?.disconnect()
    }
  }, [])

  const { pfad, auslauf, spitze } = kurvenPfade(lage?.knoten ?? [], lage?.ziel ?? null)

  return (
    <svg
      ref={svg}
      className="eb-s4-kurve"
      viewBox={`${LINKS} ${OBEN} ${BREITE} ${HOEHE}`}
      aria-hidden="true"
      focusable="false"
      data-testid="eb-kurve"
    >
      {pfad && <path className="eb-s4-pfad" d={pfad} />}
      {auslauf && <path className="eb-s4-pfad" d={auslauf} />}
      {spitze && <path className="eb-s4-spitze" d={spitze} />}
      {lage?.knoten.map((y, i) => (
        <circle key={i} className="eb-s4-knoten" cx={KNOTEN_X} cy={y} r="6" />
      ))}
    </svg>
  )
}
