// Zustand der Expertenliste zwischen Liste und Admin-Pruefansicht (Bauauftrag B 4, E 18): Filter, Auswahl und
// Scrollposition. Beim Oeffnen der Pruefansicht gemerkt (sessionStorage, nur Komfort); „Schliessen“ fuehrt auf
// /admin/authoring/liste?wiederherstellen=1 zurueck, und die Liste stellt alles wieder her.
// Ein Filterwechsel leert die Auswahl und sagt das (filterGeaendert).

import { useCallback, useEffect, useRef, useState, type RefObject } from 'react'
import { EMPTY_FILTERS, type FilterState } from '@/components/edvance/authoring/AuthoringFilters'
import { filterGeaendert } from '@/lib/authoring/auswahl'

const KEY = 'edvance.expertenliste'
export const LISTE_ZURUECK = '/admin/authoring/liste?wiederherstellen=1'

type Gemerkt = { filters: FilterState; auswahl: string[]; scroll: number }

function lese(): Gemerkt | null {
  try {
    const raw = sessionStorage.getItem(KEY)
    if (!raw) return null
    const g = JSON.parse(raw) as Partial<Gemerkt>
    return {
      filters: { ...EMPTY_FILTERS, ...(g.filters ?? {}) },
      auswahl: Array.isArray(g.auswahl) ? g.auswahl.filter((x): x is string => typeof x === 'string') : [],
      scroll: typeof g.scroll === 'number' ? g.scroll : 0,
    }
  } catch {
    return null
  }
}

/** Das naechste scrollende Elternelement (in der Huelle scrollt der Inhaltsbereich, nicht das Fenster). */
function behaelter(el: HTMLElement | null): HTMLElement | null {
  for (let e = el?.parentElement ?? null; e; e = e.parentElement) {
    const y = getComputedStyle(e).overflowY
    if (y === 'auto' || y === 'scroll') return e
  }
  return null
}

export function useListenZustand(start: FilterState, wiederherstellen: boolean, anker: RefObject<HTMLElement | null>, bereit: boolean) {
  const [gemerkt] = useState(() => (wiederherstellen ? lese() : null))
  const [filters, setFiltersRoh] = useState<FilterState>(gemerkt?.filters ?? start)
  const [auswahl, setAuswahl] = useState<Set<string>>(() => new Set(gemerkt?.auswahl ?? []))
  const [hinweis, setHinweis] = useState<string | null>(null)
  const gescrollt = useRef(false)

  const setFilters = useCallback((neu: FilterState): void => {
    if (filterGeaendert(filters, neu) && auswahl.size > 0) {
      setAuswahl(new Set())
      setHinweis('aufgehoben')
    }
    setFiltersRoh(neu)
  }, [filters, auswahl])

  useEffect(() => {
    if (!hinweis) return
    const timer = setTimeout(() => setHinweis(null), 5000)
    return () => clearTimeout(timer)
  }, [hinweis])

  // Nach dem Laden einmal an die gemerkte Stelle scrollen.
  useEffect(() => {
    if (!bereit || !gemerkt || gescrollt.current) return
    gescrollt.current = true
    const b = behaelter(anker.current)
    if (b) b.scrollTop = gemerkt.scroll
  }, [bereit, gemerkt, anker])

  const merke = useCallback((): void => {
    try {
      const g: Gemerkt = { filters, auswahl: [...auswahl], scroll: behaelter(anker.current)?.scrollTop ?? 0 }
      sessionStorage.setItem(KEY, JSON.stringify(g))
    } catch {
      // Ohne Storage geht nur das Wiederherstellen verloren.
    }
  }, [filters, auswahl, anker])

  return { filters, setFilters, setFiltersRoh, auswahl, setAuswahl, hinweis, setHinweis, merke }
}
