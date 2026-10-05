// Sammelleiste der Expertenliste (Bauauftrag E 18): ab einer Auswahl unten, immer sichtbar. Links „n ausgewählt“ und
// „Auswahl aufheben“, rechts „Ausgewählte prüfen“, „Zurück an Lena“, „Freigeben“ und „Mehr“. Schmal (iPad hoch und
// darunter) stehen nur „Ausgewählte prüfen“ und „Mehr“, der Rest liegt im Menue.

import { useEffect, useRef, useState, type JSX } from 'react'
import { useTranslation } from 'react-i18next'
import { ChevronDown, Play } from 'lucide-react'
import { Button } from '@/components/ui'
import { cn } from '@/lib/utils'
import type { SammelAktion } from '@/types'

const MEHR: SammelAktion[] = ['pilot_an', 'pilot_aus', 'ausschliessen', 'aufnehmen', 'fertigkeit', 'afb']

type Props = {
  anzahl: number
  onAufheben: () => void
  onPruefen: () => void
  onAktion: (a: SammelAktion) => void
}

export function Sammelleiste({ anzahl, onAufheben, onPruefen, onAktion }: Props): JSX.Element {
  const { t } = useTranslation('pruefenAdmin')
  const [menue, setMenue] = useState(false)
  const box = useRef<HTMLDivElement>(null)

  useEffect(() => {
    if (!menue) return
    const zu = (e: Event): void => {
      if (e instanceof KeyboardEvent && e.key !== 'Escape') return
      if (e instanceof PointerEvent && box.current?.contains(e.target as Node)) return
      setMenue(false)
    }
    document.addEventListener('keydown', zu)
    document.addEventListener('pointerdown', zu)
    return () => {
      document.removeEventListener('keydown', zu)
      document.removeEventListener('pointerdown', zu)
    }
  }, [menue])

  const waehle = (a: SammelAktion): void => {
    setMenue(false)
    onAktion(a)
  }
  const eintrag = (a: SammelAktion, nurSchmal = false): JSX.Element => (
    <button key={a} type="button" role="menuitem" onClick={() => waehle(a)}
      className={cn('flex min-h-[44px] w-full items-center rounded-[var(--radius-sm)] px-3 text-left text-sm hover:bg-[var(--color-bg-subtle)]',
        nurSchmal && 'lg:hidden')}>
      {t(`sammel.aktion.${a}`)}
    </button>
  )

  return (
    <div role="region" aria-label={t('sammel.leiste')}
      className="sticky bottom-0 z-20 -mx-4 flex flex-wrap items-center gap-3 border-t border-[var(--color-border)] bg-[var(--color-bg-surface)] px-4 py-3 shadow-elevation-lg spalte:-mx-7 spalte:px-7 voll:-mx-9 voll:px-9">
      <p className="flex flex-wrap items-center gap-3 text-sm text-[var(--color-text-secondary)]">
        <strong className="text-[var(--color-text-primary)]">{t('sammel.ausgewaehlt', { count: anzahl })}</strong>
        <Button variant="ghost" onClick={onAufheben}>{t('sammel.aufheben')}</Button>
      </p>
      <div ref={box} className="relative ml-auto flex flex-wrap items-center gap-2">
        <Button variant="outline" onClick={onPruefen}>
          <Play className="h-4 w-4" aria-hidden="true" /> {t('sammel.pruefen')}
        </Button>
        <Button variant="outline" className="hidden lg:inline-flex" onClick={() => onAktion('an_lena')}>{t('sammel.aktion.an_lena')}</Button>
        <Button className="hidden lg:inline-flex" onClick={() => onAktion('freigeben')}>✓ {t('sammel.aktion.freigeben')}</Button>
        <Button variant="outline" aria-haspopup="menu" aria-expanded={menue} onClick={() => setMenue((m) => !m)}>
          {t('sammel.mehr')} <ChevronDown className="h-4 w-4" aria-hidden="true" />
        </Button>
        {menue && (
          <div role="menu" className="absolute bottom-full right-0 z-30 mb-2 min-w-64 rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-bg-surface)] p-1 shadow-elevation-lg">
            {eintrag('freigeben', true)}
            {eintrag('an_lena', true)}
            {MEHR.map((a) => eintrag(a))}
          </div>
        )}
      </div>
    </div>
  )
}
