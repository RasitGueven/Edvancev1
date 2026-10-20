// Eltern-Bericht R7 — ob der Bogen den Rufnamen tragen kann (Gründer-
// Entscheidung 4, Fassung nach R7-5).
//
// Vorab entscheidet die Länge (NAME_MAX). Danach misst der Bogen einmal, sobald
// die Schriften geladen sind: Wird der Titel auf Seite 2 mehr als zweizeilig
// oder läuft eine Seite mit Namen über, nimmt der ganze Bogen die Fassungen ohne
// Namen. Erst danach misst Seite 4 ihre Stufen (NamensMessungFertig).

import { createContext, useLayoutEffect, useRef, useState, type RefObject } from 'react'

/** Rufnamen mit mehr Zeichen nimmt der Bogen gar nicht erst auf. */
export const NAME_MAX = 24

/** Höchstens so viele Zeilen darf der Titel auf Seite 2 mit Namen haben. */
const TITEL_ZEILEN_MAX = 2

/**
 * Seiten, auf denen der Name steht. Seite 4 trägt ihn nicht und regelt Überlauf
 * mit ihren eigenen Stufen; ihr Überlauf vor den Stufen sagt über den Namen nichts.
 */
const SEITEN_MIT_NAMEN = [1, 2, 3, 5]

/**
 * true, sobald die Namensentscheidung gefallen ist. Ohne Bogen (Seite 4 allein,
 * etwa in Tests) gibt es nichts zu entscheiden.
 */
export const NamensMessungFertig = createContext(true)

/** Passt der Bogen mit Namen? Gemessen am gerenderten Bogen. */
function passtMitNamen(bogen: HTMLElement): boolean {
  const titel = bogen.querySelector<HTMLElement>('.eb-seite[data-seite="2"] .eb-titel')
  if (titel) {
    const zeile = parseFloat(getComputedStyle(titel).lineHeight)
    const hoehe = titel.getBoundingClientRect().height
    if (zeile > 0 && Math.round(hoehe / zeile) > TITEL_ZEILEN_MAX) return false
  }
  return SEITEN_MIT_NAMEN.every((n) => {
    const inhalt = bogen.querySelector<HTMLElement>(`.eb-seite[data-seite="${n}"] .eb-inhalt`)
    return !inhalt || inhalt.scrollHeight <= inhalt.clientHeight
  })
}

/**
 * Misst einmal nach dem Layout — solange Schriften laden, erst nach
 * `document.fonts.ready` (wie die Stufen auf Seite 4). Der Wechsel auf die
 * Fassungen ohne Namen passiert höchstens einmal und gilt für den ganzen Bogen.
 */
export function useNamensMessung(mitName: boolean): {
  ref: RefObject<HTMLDivElement>
  nameBleibt: boolean
  fertig: boolean
} {
  const ref = useRef<HTMLDivElement>(null)
  const [nameBleibt, setNameBleibt] = useState(true)
  const [fertig, setFertig] = useState(!mitName)

  useLayoutEffect(() => {
    const bogen = ref.current
    if (fertig || !bogen) return
    let aktiv = true
    const messen = (): void => {
      if (!aktiv) return
      if (!passtMitNamen(bogen)) setNameBleibt(false)
      setFertig(true)
    }
    if (!document.fonts || document.fonts.status === 'loaded') messen()
    else void document.fonts.ready.then(messen)
    return () => {
      aktiv = false
    }
  }, [fertig])

  return { ref, nameBleibt, fertig }
}
