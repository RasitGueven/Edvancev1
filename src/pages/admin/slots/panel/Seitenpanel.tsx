import { useEffect, useId, useRef, type ReactNode } from 'react'
import { X } from 'lucide-react'
import { useTranslation } from 'react-i18next'

type Props = {
  /** Kleine Zeile über dem Titel („KW 45 · Slot“). */
  rubrik?: string
  titel: string
  satz?: string
  /** Rechts neben dem Titel (z. B. „…“-Menü). */
  aktionen?: ReactNode
  /** Tagespanel etwas breiter. */
  breit?: boolean
  /** false, solange ein Dialog darüber liegt (Escape gehört dann dem Dialog). */
  escape?: boolean
  onClose: () => void
  children: ReactNode
}

/**
 * Seitenpanel rechts über dem Wochenplan (W2, Entscheidung 6), auf dem Telefon volle Breite. Escape, Klick auf den
 * Hintergrund und das X schließen; der Aufrufer entscheidet, was Schließen heißt (Zurück in der Geschichte).
 */
export function Seitenpanel({ rubrik, titel, satz, aktionen, breit = false, escape = true, onClose, children }: Props): JSX.Element {
  const { t } = useTranslation('slots')
  const titelId = useId()
  const flaeche = useRef<HTMLElement>(null)

  useEffect(() => {
    flaeche.current?.focus()
  }, [titel])

  useEffect(() => {
    if (!escape) return undefined
    const onKey = (e: KeyboardEvent): void => {
      if (e.key === 'Escape') onClose()
    }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [escape, onClose])

  return (
    <div className="fixed inset-0 z-40 flex justify-end">
      <button
        type="button"
        tabIndex={-1}
        aria-label={t('wochenplan2.panel.schliessen')}
        className="absolute inset-0 bg-[var(--color-overlay)] animate-fade-in"
        onClick={onClose}
      />
      <aside
        ref={flaeche}
        role="dialog"
        aria-modal="true"
        aria-labelledby={titelId}
        tabIndex={-1}
        // Ohne Animation an der Fläche: ein transform machte sie zum Bezugsrahmen der fixed-Dialoge darin.
        className={`relative flex h-full w-full flex-col bg-[var(--color-bg-app)] shadow-lg outline-none ${breit ? 'max-w-3xl' : 'max-w-2xl'}`}
      >
        <header className="flex items-start gap-4 border-b border-[var(--color-border)] bg-[var(--color-bg-surface)] px-6 py-4">
          <div className="flex min-w-0 flex-1 flex-col gap-1">
            {rubrik && <span className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">{rubrik}</span>}
            <h2 id={titelId} className="text-2xl font-bold text-[var(--color-text-primary)]">{titel}</h2>
            {satz && <p className="text-sm text-[var(--color-text-secondary)]">{satz}</p>}
          </div>
          {aktionen}
          <button
            type="button"
            onClick={onClose}
            aria-label={t('wochenplan2.panel.schliessen')}
            className="flex h-11 w-11 shrink-0 items-center justify-center rounded-full text-[var(--color-text-tertiary)] hover:bg-[var(--color-bg-subtle)]"
          >
            <X aria-hidden="true" className="h-5 w-5" />
          </button>
        </header>
        <div className="flex flex-1 flex-col gap-4 overflow-y-auto px-6 py-6">{children}</div>
      </aside>
    </div>
  )
}
