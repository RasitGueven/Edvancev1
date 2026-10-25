import { useContext, useLayoutEffect, useRef, useState, type RefObject } from 'react'

import { LUECKENWEG_STUFEN } from '@/lib/report/elternbericht/lueckenweg'

import { NamensMessungFertig } from './namensMessung'

/**
 * Stufe des Ausdünnens (duenneLueckenweg): Läuft die Seite über, geht sie eine
 * Stufe weiter, bis alles passt oder die letzte erreicht ist. Gemessen wie auf
 * Seite 4 am Inhaltskasten, nach der Namensentscheidung und den Schriften.
 */
export function useAusduennen(schluessel: unknown): { ref: RefObject<HTMLDivElement>; stufe: number } {
  const ref = useRef<HTMLDivElement>(null)
  const [stufe, setStufe] = useState(0)
  const nameEntschieden = useContext(NamensMessungFertig)

  useLayoutEffect(() => setStufe(0), [schluessel])
  useLayoutEffect(() => {
    const kasten = ref.current?.parentElement
    if (!nameEntschieden || !kasten || stufe >= LUECKENWEG_STUFEN - 1) return
    let aktiv = true
    const pruefen = (): void => {
      if (aktiv && kasten.scrollHeight > kasten.clientHeight + 0.5) setStufe(stufe + 1)
    }
    void kasten.offsetHeight
    if (!document.fonts || document.fonts.status === 'loaded') pruefen()
    else void document.fonts.ready.then(pruefen)
    return () => {
      aktiv = false
    }
  }, [stufe, nameEntschieden])

  return { ref, stufe }
}
