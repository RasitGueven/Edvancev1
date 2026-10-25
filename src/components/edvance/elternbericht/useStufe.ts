import { useContext, useLayoutEffect, useRef, useState, type RefObject } from 'react'

import { NamensMessungFertig } from './namensMessung'

/**
 * Läuft die Seite mit den Abständen des Musters über (langes Fazit, lange
 * Texte), geht sie eine Stufe weiter, bis alles passt oder `hoechste` erreicht
 * ist — statt dass die Fußnote am Papierrand abgeschnitten wird. Text wird nie
 * gekürzt, nur weggelassen. Geprüft nach dem Layout, solange Schriften laden
 * aber erst nach `document.fonts.ready` — sonst bliebe eine Stufe stehen, die
 * nur die Ersatzschrift brauchte. Eine erreichte Stufe bleibt.
 */
export function useStufe(hoechste: number): { ref: RefObject<HTMLDivElement>; wert: number } {
  const ref = useRef<HTMLDivElement>(null)
  const [wert, setWert] = useState(0)
  // Erst entscheidet der Bogen über den Namen, dann misst Seite 4.
  const nameEntschieden = useContext(NamensMessungFertig)

  useLayoutEffect(() => {
    const kasten = ref.current?.parentElement
    if (!nameEntschieden || !kasten || wert >= hoechste) return
    let aktiv = true
    const pruefen = (): void => {
      if (aktiv && kasten.scrollHeight > kasten.clientHeight) setWert(wert + 1)
    }
    void kasten.offsetHeight // Layout erzwingen, damit die Schriften angefordert sind
    if (!document.fonts || document.fonts.status === 'loaded') pruefen()
    else void document.fonts.ready.then(pruefen)
    return () => {
      aktiv = false
    }
  }, [wert, hoechste, nameEntschieden])

  return { ref, wert }
}
