import { useEffect, useState, type ReactNode } from 'react'
import { useLocation } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { Menu } from 'lucide-react'
import { EdvanceLogo } from '@/components/brand/EdvanceLogo'
import type { LeistenTon, NavKonfiguration, Zaehlerwerte } from './navTypes'
import { ShellContext } from './shellContext'
import { ShellSidebar } from './ShellSidebar'
import { useLayoutModus } from './useLayoutModus'

type Props = {
  konfig: NavKonfiguration
  zaehler: Zaehlerwerte
  ton?: LeistenTon
  children: ReactNode
}

/**
 * Rahmen für Verwaltungsflächen: Leiste | Inhalt als CSS-Grid. Die Leiste
 * steht, der Inhalt scrollt für sich (Entscheidungen 4 und 5).
 *   voll       ab --breakpoint-voll: volle Leiste
 *   spalte     ab --breakpoint-spalte: schmale Spalte, „Menü“ klappt die volle
 *              Leiste als Überlagerung aus
 *   schublade  darunter: Kopfzeile mit Menü-Knopf, Leiste als Schublade
 * Überlagerung und Schublade schließen bei Tippen daneben, Escape und
 * Seitenwechsel.
 */
export function AppShell({ konfig, zaehler, ton = 'navy', children }: Props): JSX.Element {
  const { t: tc } = useTranslation('common')
  const modus = useLayoutModus()
  const { pathname } = useLocation()
  const [offen, setOffen] = useState(false)

  useEffect(() => setOffen(false), [pathname, modus])

  useEffect(() => {
    if (!offen) return
    const beiTaste = (e: KeyboardEvent): void => {
      if (e.key === 'Escape') setOffen(false)
    }
    window.addEventListener('keydown', beiTaste)
    return () => window.removeEventListener('keydown', beiTaste)
  }, [offen])

  const raster =
    modus === 'voll'
      ? 'grid-cols-[var(--container-leiste)_minmax(0,1fr)]'
      : modus === 'spalte'
        ? 'grid-cols-[var(--container-leiste-schmal)_minmax(0,1fr)]'
        : 'grid-rows-[auto_minmax(0,1fr)]'

  return (
    <ShellContext.Provider value={true}>
      <div className={`grid h-dvh overflow-hidden bg-[var(--color-bg-app)] font-[family-name:var(--font-body)] print:block print:h-auto print:overflow-visible ${raster}`}>
        {modus === 'schublade' ? (
          <header className="print-hide flex items-center gap-2 border-b border-[var(--color-border)] bg-[var(--color-bg-surface)] px-4 py-2">
            <button
              type="button"
              onClick={() => setOffen(true)}
              aria-label={tc('shell.menueOeffnen')}
              aria-expanded={offen}
              className="flex h-11 w-11 items-center justify-center rounded-[var(--radius-md)] text-[var(--color-primary)] hover:bg-[var(--color-bg-app)]"
            >
              <Menu aria-hidden="true" className="h-6 w-6" />
            </button>
            <EdvanceLogo size={18} accentColor="var(--color-gold-altgold)" />
          </header>
        ) : (
          <ShellSidebar
            konfig={konfig}
            zaehler={zaehler}
            ton={ton}
            variante={modus === 'voll' ? 'voll' : 'schmal'}
            onMenue={modus === 'spalte' ? () => setOffen(true) : undefined}
          />
        )}

        <div className="@container min-h-0 overflow-y-auto print:overflow-visible">
          <main className="mx-auto flex w-full max-w-shell flex-col gap-6 px-4 py-8 spalte:px-7 voll:px-9 print:max-w-none print:p-0">
            {children}
          </main>
        </div>

        {offen && modus !== 'voll' && (
          <div className="fixed inset-0 z-50" role="dialog" aria-modal="true" aria-label={tc('shell.navigation')}>
            <button
              type="button"
              tabIndex={-1}
              aria-label={tc('shell.menueSchliessen')}
              onClick={() => setOffen(false)}
              className="absolute inset-0 h-full w-full bg-[var(--color-overlay)] animate-fade-in"
            />
            <div className="relative h-full w-leiste max-w-[85vw] shadow-elevation-lg">
              <ShellSidebar
                konfig={konfig}
                zaehler={zaehler}
                ton={ton}
                variante="voll"
                onSchliessen={() => setOffen(false)}
              />
            </div>
          </div>
        )}
      </div>
    </ShellContext.Provider>
  )
}
