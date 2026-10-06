// ⓘ mit Erklaerung (Entscheidung 36): Wortlaut aus pruefen.json → info.<schluessel>, uebernommen aus
// dem INFO-Objekt des Dummy v2. Oeffnet bei Hover (Maus), Tastatur-Fokus oder Antippen; schliesst mit
// Esc oder Antippen daneben. Esc wird hier abgefangen, damit es nicht zugleich die Pause ausloest.

import { useEffect, useRef, useState, type JSX } from 'react'
import { useTranslation } from 'react-i18next'
import { RotateCcw } from 'lucide-react'
import { cn } from '@/lib/utils'

export type InfoSchluessel =
  | 'antwort' | 'teile' | 'mc' | 'regel' | 'weg' | 'fehler' | 'fert' | 'afb' | 'sicher' | 'testen'
  | 'hilfsmittel' | 'entscheidung' | 'hinweise'

type Absatz = { b?: string; t: string }

export function InfoTip({ schluessel, hell = false }: { schluessel: InfoSchluessel; hell?: boolean }): JSX.Element {
  const { t } = useTranslation('pruefen')
  const [offen, setOffen] = useState(false)
  const box = useRef<HTMLSpanElement>(null)
  const absaetze = t(`info.${schluessel}`, { returnObjects: true }) as Absatz[]

  useEffect(() => {
    if (!offen) return
    const esc = (e: KeyboardEvent): void => {
      if (e.key !== 'Escape') return
      e.preventDefault()
      e.stopPropagation()
      setOffen(false)
    }
    const daneben = (e: PointerEvent): void => {
      if (box.current && !box.current.contains(e.target as Node)) setOffen(false)
    }
    document.addEventListener('keydown', esc, true)
    document.addEventListener('pointerdown', daneben, true)
    return () => {
      document.removeEventListener('keydown', esc, true)
      document.removeEventListener('pointerdown', daneben, true)
    }
  }, [offen])

  return (
    <span ref={box} className="relative inline-flex align-middle">
      <button
        type="button"
        aria-label={t('info.erklaerung', { was: t(`info.was.${schluessel}`) })}
        aria-expanded={offen}
        onPointerEnter={(e) => e.pointerType === 'mouse' && setOffen(true)}
        onPointerLeave={(e) => e.pointerType === 'mouse' && setOffen(false)}
        onFocus={(e) => e.currentTarget.matches(':focus-visible') && setOffen(true)}
        onBlur={() => setOffen(false)}
        onClick={(e) => {
          e.preventDefault()
          e.stopPropagation()
          setOffen((o) => !o)
        }}
        className={cn(
          'relative inline-flex h-[18px] w-[18px] items-center justify-center rounded-full border text-xs font-semibold italic leading-none normal-case tracking-normal',
          "after:absolute after:-inset-3 after:content-['']",
          hell
            ? 'border-[var(--color-stage-text)] text-[var(--color-stage-text)]'
            : 'border-[var(--color-border)] bg-[var(--color-bg-surface)] text-[var(--color-text-tertiary)] hover:border-[var(--color-primary)] hover:text-[var(--color-primary)]',
        )}
      >
        i
      </button>
      {offen && (
        <span
          role="tooltip"
          className="absolute left-1/2 top-full z-40 mt-2 flex w-[min(340px,calc(100vw-32px))] -translate-x-1/2 flex-col gap-2 rounded-[var(--radius-md)] bg-[var(--color-navy-deep)] p-3 text-left text-xs font-normal normal-case leading-relaxed tracking-normal text-[var(--color-stage-text)] shadow-lg"
        >
          {absaetze.map((a, i) => (
            <span key={i}>
              {a.b && <span className="mr-1 font-semibold text-[var(--color-gold-altgold)]">{a.b}</span>}
              {a.t}
            </span>
          ))}
        </span>
      )}
    </span>
  )
}

/** "geaendert ↺": weicht von der Vorbefuellung ab; ↺ setzt das Feld zurueck. */
export function GeaendertMarke({ an, onZurueck }: { an: boolean; onZurueck: () => void }): JSX.Element | null {
  const { t } = useTranslation('pruefen')
  if (!an) return null
  return (
    <span className="inline-flex items-center gap-1 rounded-[var(--radius-sm)] bg-[var(--color-primary-light)] py-0.5 pl-2 pr-0.5 text-xs font-semibold normal-case tracking-normal text-[var(--color-primary)]">
      {t('marke.geaendert')}
      <button
        type="button"
        onClick={onZurueck}
        title={t('marke.zuruecksetzen')}
        aria-label={t('marke.zuruecksetzen')}
        className="relative inline-flex h-6 w-6 items-center justify-center rounded hover:bg-[var(--color-bg-surface)] after:absolute after:-inset-2.5 after:content-['']"
      >
        <RotateCcw className="h-3.5 w-3.5" aria-hidden="true" />
      </button>
    </span>
  )
}

/** Tastenhinweis; am Touchgeraet ausgeblendet (Entscheidung 35). */
export function Taste({ children }: { children: string }): JSX.Element {
  return (
    <kbd className="rounded border border-current px-1 text-xs font-medium leading-normal opacity-60 [@media(hover:none)]:hidden">
      {children}
    </kbd>
  )
}
