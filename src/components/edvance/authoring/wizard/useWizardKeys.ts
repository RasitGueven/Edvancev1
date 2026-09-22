// Tastatur der Pflege-Strecke: Enter = weiter, V = Vorschau, Esc = Vorschau zu
// bzw. — ohne offene Vorschau — Strecke schliessen. Alles bis dahin Entschiedene
// ist gespeichert; die Warteschlange merkt sich die Position.
//
// Ein Listener, Refs fuer den aktuellen Stand — sonst haengt am Fenster ein
// veralteter Closure-Stand. Die Entscheidungstasten F / Z / L stehen in
// useReleaseActions.

import { useEffect, useRef } from 'react'

export function useWizardKeys(a: {
  previewOpen: boolean
  setPreviewOpen: (open: boolean) => void
  /** Schliesst ein offenes Feld der Seite (Zurueckweisen); true = war offen. */
  closeOverlay: () => boolean
  next: () => Promise<void>
  exit: () => void
}): void {
  const ctx = useRef(a)
  ctx.current = a
  useEffect(() => {
    const onKey = (e: KeyboardEvent): void => {
      const el = e.target as HTMLElement | null
      const tag = el?.tagName ?? ''
      const typing = tag === 'TEXTAREA' || tag === 'SELECT' || Boolean(el?.isContentEditable)
      const c = ctx.current
      // Esc schliesst von innen nach aussen: Vorschau, dann ein offenes Feld,
      // erst dann die Strecke. Beim Tippen nie die Strecke — ein Reflex-Esc im
      // Notizfeld soll nicht die Arbeit verlassen.
      if (e.key === 'Escape') {
        if (c.previewOpen) c.setPreviewOpen(false)
        else if (c.closeOverlay()) return
        else if (!typing && tag !== 'INPUT') c.exit()
        return
      }
      if (c.previewOpen) return
      if ((e.key === 'v' || e.key === 'V') && !typing && tag !== 'INPUT') {
        e.preventDefault()
        c.setPreviewOpen(true)
        return
      }
      if (e.key === 'Enter' && !typing && tag !== 'BUTTON' && tag !== 'A' && tag !== 'INPUT') {
        e.preventDefault()
        void c.next()
      }
    }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [])
}
