import { useEffect, useState } from 'react'

export type LayoutModus = 'schublade' | 'spalte' | 'voll'

// Die Grenzen stehen als Tokens in globals.css (@theme static), nicht hier:
// dieselben Werte treiben die Tailwind-Varianten spalte: und voll:.
function abfragen(): [MediaQueryList, MediaQueryList] | null {
  if (typeof window === 'undefined' || typeof window.matchMedia !== 'function') return null
  const css = getComputedStyle(document.documentElement)
  const spalte = css.getPropertyValue('--breakpoint-spalte').trim()
  const voll = css.getPropertyValue('--breakpoint-voll').trim()
  if (!spalte || !voll) return null
  return [window.matchMedia(`(min-width: ${spalte})`), window.matchMedia(`(min-width: ${voll})`)]
}

function bestimme(): LayoutModus {
  const q = abfragen()
  // Ohne Media-Queries (Tests, SSR) gilt die volle Leiste.
  if (!q) return 'voll'
  if (q[1].matches) return 'voll'
  return q[0].matches ? 'spalte' : 'schublade'
}

/** 'schublade' unter --breakpoint-spalte, 'spalte' bis --breakpoint-voll, darüber 'voll'. */
export function useLayoutModus(): LayoutModus {
  const [modus, setModus] = useState<LayoutModus>(bestimme)

  useEffect(() => {
    const q = abfragen()
    if (!q) return
    const update = (): void => setModus(bestimme())
    q.forEach((m) => m.addEventListener('change', update))
    update()
    return () => q.forEach((m) => m.removeEventListener('change', update))
  }, [])

  return modus
}
