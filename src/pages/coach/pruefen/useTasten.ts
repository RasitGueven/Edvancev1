// Tastenkuerzel der Pruefansicht (Anforderung F 50, Entscheidung 35):
// 1 / 2 / 3 = Passt nicht / Unsicher / Passt; Enter = Passt (nicht bei Fokus in einem Feld oder auf
// einem Knopf); ← / → = zurueck / ueberspringen; Esc der Reihe nach: Erklaerung oder Bild schliessen
// (fangen InfoTip und Modal selbst ab) → Eingabefeld verlassen → offenes Feld schliessen → Pause.

import { useEffect, useRef } from 'react'

type Aktionen = {
  aktiv: boolean
  panelOffen: boolean
  passt: () => void
  panel: (p: 'nicht' | 'unsicher') => void
  panelZu: () => void
  zurueck: () => void
  weiter: () => void
  pause: () => void
}

export function useTasten(a: Aktionen): void {
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
        if (document.querySelector('[role="dialog"]')) return
        if (tippt) el?.blur()
        else if (x.panelOffen) x.panelZu()
        else x.pause()
        return
      }
      if (tippt || e.metaKey || e.ctrlKey || e.altKey || x.panelOffen) return
      const aufKnopf = !!el && (el.tagName === 'BUTTON' || el.getAttribute('role') === 'button' || el.tagName === 'A')
      if (e.key === '1') { e.preventDefault(); x.panel('nicht') }
      else if (e.key === '2') { e.preventDefault(); x.panel('unsicher') }
      else if (e.key === '3' || (e.key === 'Enter' && !aufKnopf)) { e.preventDefault(); x.passt() }
      else if (e.key === 'ArrowLeft') x.zurueck()
      else if (e.key === 'ArrowRight') x.weiter()
    }
    window.addEventListener('keydown', taste)
    return () => window.removeEventListener('keydown', taste)
  }, [])
}
