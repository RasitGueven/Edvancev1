// Station 03 · Lernweg — was während der Fahrt schon zu sehen ist (PF-1,
// Entscheidungen 3 und 5).
//
// Je Bild nur Klassen und Attribute über Refs: Eine Insel oder Zone bekommt
// tp-s3-da, sobald sie in den sichtbaren Ausschnitt kommt; „Sie sind hier“
// erscheint mit der Front. Der React-State (sicht, hier) zieht erst nach, wenn
// alles aufgedeckt ist (Ende, Unterbrechen, reduzierte Bewegung), damit React
// und DOM wieder übereinstimmen.

import { useCallback, useRef, useState, type RefObject } from 'react'

const DA = 'tp-s3-da'

type Lage = { x: number; el: HTMLElement }

export type Sicht = {
  /** null = alles sichtbar. */
  sicht: Set<string> | null
  hier: boolean
  hierRef: RefObject<HTMLParagraphElement>
  /** Nach dem Messen: die Lage (Layout-x in der Spur) jeder Zone und Insel und der Anfang von Kommt noch. */
  erfassen: (lagen: Lage[], kommtX: number) => void
  /** Je Bild: alles links von `grenze` ist da, „Sie sind hier“ ab `front` ≥ Kommt noch. Kein setState. */
  bis: (grenze: number, front: number) => void
  /** Nichts aufgedeckt (vor dem ersten Betreten, Anfang der Fahrt). */
  leer: () => void
  /** Alles aufgedeckt; der State zieht einmal nach. */
  alles: () => void
}

export function useLernwegSicht(): Sicht {
  const [sicht, setSicht] = useState<Set<string> | null>(null)
  const [hier, setHier] = useState(true)
  const hierRef = useRef<HTMLParagraphElement>(null)
  const lagen = useRef<Lage[]>([])
  const kommtX = useRef(Infinity)
  const voll = useRef(true)

  const erfassen = useCallback((l: Lage[], k: number): void => {
    lagen.current = l
    kommtX.current = k
  }, [])

  const alles = useCallback((): void => {
    for (const l of lagen.current) l.el.classList.add(DA)
    if (hierRef.current) hierRef.current.hidden = false
    if (voll.current) return
    voll.current = true
    setSicht(null)
    setHier(true)
  }, [])

  const leer = useCallback((): void => {
    voll.current = false
    for (const l of lagen.current) l.el.classList.remove(DA)
    if (hierRef.current) hierRef.current.hidden = true
    setSicht((alt) => (alt && alt.size === 0 ? alt : new Set()))
    setHier(false)
  }, [])

  const bis = useCallback(
    (grenze: number, front: number): void => {
      if (grenze === Infinity) return alles()
      // Auch Elemente, die React zwischendurch neu geschrieben hat, bekommen die Klasse wieder.
      for (const l of lagen.current) if (l.x <= grenze && !l.el.classList.contains(DA)) l.el.classList.add(DA)
      const h = hierRef.current
      if (h && h.hidden && front >= kommtX.current) h.hidden = false
    },
    [alles],
  )

  return { sicht, hier, hierRef, erfassen, bis, leer, alles }
}
