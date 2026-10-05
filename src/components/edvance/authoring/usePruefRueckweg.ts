// Rueckweg aus dem Editor in die Admin-Pruefansicht (Bauauftrag D 17). Ersetzt usePflegeRueckweg und ?pflege=.
//
// Kam der Editor aus der Pruefansicht (?zurueck=pruefen), heisst der Zurueck-Link „Zurück zur Prüfansicht“, und
// nach dem Speichern steht „Gespeichert.“ mit demselben Weg — ohne automatische Weiterleitung, damit man mehrere
// Abschnitte nacheinander aendern kann. ?abschnitt= oeffnet den passenden Abschnitt und scrollt dorthin. Die
// Pruefansicht findet ihre Position in der Reihe ueber die Aufgabe in der Adresse und laedt sie neu.

import { useEffect, useRef } from 'react'
import { useParams, useSearchParams } from 'react-router-dom'
import { EDITOR_ABSCHNITTE, type EditorAbschnitt } from '@/lib/pruefung/befunde'

export type PruefRueckweg = {
  ausPruefen: boolean
  zurueck: { to: string; labelKey: string }
  /** Soll dieser Abschnitt offen starten? (Stoffanker liegt in der Einordnung.) */
  offen: (a: EditorAbschnitt) => boolean
}

export function usePruefRueckweg(bereit = false): PruefRueckweg {
  const { id } = useParams<{ id: string }>()
  const [params] = useSearchParams()
  const ausPruefen = params.get('zurueck') === 'pruefen' && !!id
  const roh = params.get('abschnitt')
  const abschnitt = (EDITOR_ABSCHNITTE as readonly string[]).includes(roh ?? '') ? (roh as EditorAbschnitt) : null
  const gescrollt = useRef(false)

  useEffect(() => {
    if (!bereit || !abschnitt || gescrollt.current) return
    gescrollt.current = true
    document.getElementById(`abschnitt-${abschnitt}`)?.scrollIntoView?.({ block: 'start' })
  }, [bereit, abschnitt])

  return {
    ausPruefen,
    zurueck: ausPruefen
      ? { to: `/admin/pruefen/${id}`, labelKey: 'editor.zurueckPruefen' }
      : { to: '/admin/authoring', labelKey: 'page.backToList' },
    offen: (a) => abschnitt === a || (abschnitt === 'stoffanker' && a === 'einordnung'),
  }
}
