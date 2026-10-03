import { useState } from 'react'
import { useTranslation } from 'react-i18next'
import { ChevronDown, ChevronRight, Search } from 'lucide-react'
import { Input } from '@/components/ui/input'
import { nachStufe, sucheThemen } from '@/lib/themen/suche'
import type { Stufe, Thema } from '@/types'
import { ThemaChip } from './ThemaChip'

type ThemaSucheProps = {
  katalog: Thema[]
  /** Stufe des Kindes; ihre Treffer stehen oben. */
  stufe: Stufe | null
  aktuell: string | null
  disabled: boolean
  onWaehle: (themaKey: string) => void
}

/**
 * Ein Eingabefeld fuer das, was das Kind sagt ("wurzel", "zinsen"). Hoechstens
 * sechs Vorschlaege, die Stufe des Kindes zuerst, andere Stufen eingeklappt.
 * Kein Freitext-Thema: ohne Treffer nur der Hinweis aufs Mathe-Heft.
 */
export function ThemaSuche({
  katalog,
  stufe,
  aktuell,
  disabled,
  onWaehle,
}: ThemaSucheProps): JSX.Element {
  const { t } = useTranslation('admin')
  const [eingabe, setEingabe] = useState('')
  const [andereOffen, setAndereOffen] = useState(false)

  const treffer = sucheThemen(katalog, eingabe)
  const { eigene, andere } = nachStufe(treffer, stufe)
  // Ohne Treffer in der eigenen Stufe waere eingeklappt = leer; dann offen.
  const andereSichtbar = andereOffen || eigene.length === 0
  const gesucht = eingabe.trim() !== ''

  const chip = (thema: Thema): JSX.Element => (
    <ThemaChip
      key={thema.thema_key}
      label={thema.label}
      zustand={thema.thema_key === aktuell ? 'aktuell' : 'frei'}
      disabled={disabled}
      onClick={() => onWaehle(thema.thema_key)}
    />
  )

  return (
    <div className="flex flex-col gap-2">
      <div className="relative">
        <Search
          className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-[var(--color-text-tertiary)]"
          aria-hidden
        />
        <Input
          id="thema-suche"
          className="h-12 pl-9"
          value={eingabe}
          onChange={(e) => setEingabe(e.target.value)}
          placeholder={t('intake.thema.placeholder')}
          aria-label={t('intake.thema.label')}
          autoComplete="off"
        />
      </div>

      {gesucht && treffer.length === 0 && (
        <p className="text-sm text-[var(--color-text-secondary)]" role="status">
          {t('intake.thema.keinTreffer')}
        </p>
      )}

      {eigene.length > 0 && <div className="flex flex-wrap gap-2">{eigene.map(chip)}</div>}

      {andere.length > 0 && (
        <div className="flex flex-col gap-2">
          {eigene.length > 0 && (
            <button
              type="button"
              aria-expanded={andereSichtbar}
              onClick={() => setAndereOffen((v) => !v)}
              className="inline-flex min-h-[44px] items-center gap-2 self-start text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]"
            >
              {andereSichtbar ? (
                <ChevronDown className="h-4 w-4" aria-hidden />
              ) : (
                <ChevronRight className="h-4 w-4" aria-hidden />
              )}
              {t('intake.thema.andereStufen', { count: andere.length })}
            </button>
          )}
          {andereSichtbar && <div className="flex flex-wrap gap-2">{andere.map(chip)}</div>}
        </div>
      )}
    </div>
  )
}
