// Tastenkuerzel der Admin-Pruefansicht (Bauauftrag C 14):
// Enter = Freigeben (nicht bei Fokus in einem Feld oder auf einem Knopf); ← / → = Zurueck / Ueberspringen;
// E = Editor; Esc der Reihe nach: Erklaerung oder Bild schliessen (fangen InfoTip und Modal selbst ab) →
// Feld verlassen → offenes Feld ueber der Leiste schliessen → Schliessen. Am Touchgeraet blendet Taste die
// Hinweise aus; bedienbar ist alles auch ohne Tastatur.

import { useEffect, useRef } from 'react'

type Aktionen = {
  aktiv: boolean
  panelOffen: boolean
  freigeben: () => void
  zurueck: () => void
  weiter: () => void
  editor: () => void
  panelZu: () => void
  schliessen: () => void
}

export function useAdminTasten(a: Aktionen): void {
  const ref = useRef(a)
  useEffect(() => {
    ref.current = a
  })

  useEffect(() => {
    const taste = (e: KeyboardEvent): void => {
      const x = ref.current
      if (!x.aktiv || e.defaultPrevented) return
      const el = document.activeElement as HTMLElement | null
      const tippt = !!el && ['INPUT', 'TEXTAREA', 'SELECT'].includes(el.tagName)
      if (e.key === 'Escape') {
        if (document.querySelector('[role="dialog"], [role="menu"]')) return
        if (tippt) el?.blur()
        else if (x.panelOffen) x.panelZu()
        else x.schliessen()
        return
      }
      if (tippt || e.metaKey || e.ctrlKey || e.altKey) return
      const aufKnopf = !!el && (el.tagName === 'BUTTON' || el.getAttribute('role') === 'button' || el.tagName === 'A'
        || el.tagName === 'SUMMARY')
      if (e.key === 'Enter' && !aufKnopf && !x.panelOffen) { e.preventDefault(); x.freigeben() }
      else if (e.key === 'ArrowLeft') x.zurueck()
      else if (e.key === 'ArrowRight') x.weiter()
      else if (e.key === 'e' || e.key === 'E') { e.preventDefault(); x.editor() }
    }
    window.addEventListener('keydown', taste)
    return () => window.removeEventListener('keydown', taste)
  }, [])
}
