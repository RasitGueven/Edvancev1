import { useEffect, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { cn } from '@/lib/utils'
import { STUFEN } from '@/lib/themen/suche'
import { chipGruppen } from '@/lib/themen/vorbelegung'
import type { SchulPlanZeile, Stufe, Thema } from '@/types'
import { ThemaChip, type ThemaChipZustand } from './ThemaChip'

type Modus = 'aktuell' | 'behandelt'

type StufenChipsProps = {
  katalog: Thema[]
  plan: SchulPlanZeile[]
  kindStufe: Stufe | null
  zustandVon: (themaKey: string) => ThemaChipZustand
  ausPlan: (themaKey: string) => boolean
  disabled: boolean
  onAktuell: (themaKey: string) => void
  onBehandelt: (themaKey: string) => void
}

const SEGMENT =
  'min-h-[44px] rounded-xl border px-4 py-2 text-sm font-medium transition-colors'
const SEGMENT_AN =
  'border-[var(--color-primary)] bg-[color-mix(in_srgb,var(--color-primary)_10%,transparent)] text-[var(--color-text-primary)]'
const SEGMENT_AUS =
  'border-[var(--color-border)] bg-[var(--color-bg-surface)] text-[var(--color-text-secondary)] hover:border-[var(--color-primary)]'

/**
 * Themen einer Stufe ohne Tippen ("das hatten wir letztes Jahr"). Vorgewaehlt
 * ist die Stufe des Kindes. Mit Schulplan gruppiert nach Klasse dieser Schule
 * in Plan-Reihenfolge. Ein Tipp setzt das aktuelle Thema oder — im zweiten
 * Modus — markiert es als schon behandelt. Die Chip-Flaeche scrollt in sich.
 */
export function StufenChips({
  katalog,
  plan,
  kindStufe,
  zustandVon,
  ausPlan,
  disabled,
  onAktuell,
  onBehandelt,
}: StufenChipsProps): JSX.Element {
  const { t } = useTranslation('admin')
  const [stufe, setStufe] = useState<Stufe>(kindStufe ?? 'erste')
  const [modus, setModus] = useState<Modus>('aktuell')

  useEffect(() => {
    if (kindStufe) setStufe(kindStufe)
  }, [kindStufe])

  const gruppen = chipGruppen(katalog, stufe, plan)

  return (
    <div className="flex flex-col gap-2">
      <p className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
        {t('intake.stufen.titel')}
      </p>
      <div className="flex flex-wrap items-center justify-between gap-2">
        <div className="flex gap-2" role="group" aria-label={t('intake.stufen.titel')}>
          {STUFEN.map((s) => (
            <button
              key={s}
              type="button"
              aria-pressed={s === stufe}
              onClick={() => setStufe(s)}
              className={cn(SEGMENT, s === stufe ? SEGMENT_AN : SEGMENT_AUS)}
            >
              {t(`intake.stufen.kurz.${s}`)}
            </button>
          ))}
        </div>
        <div className="flex gap-2" role="group">
          {(['aktuell', 'behandelt'] as const).map((m) => (
            <button
              key={m}
              type="button"
              aria-pressed={m === modus}
              onClick={() => setModus(m)}
              className={cn(SEGMENT, m === modus ? SEGMENT_AN : SEGMENT_AUS)}
            >
              {t(m === 'aktuell' ? 'intake.stufen.modusAktuell' : 'intake.stufen.modusBehandelt')}
            </button>
          ))}
        </div>
      </div>

      <div
        className="flex max-h-[50vh] flex-col gap-4 overflow-y-auto overscroll-contain rounded-xl border border-[var(--color-border)] p-4"
        data-testid="stufen-chips"
      >
        {gruppen.map((g) => (
          <div key={g.klasse ?? 'rest'} className="flex flex-col gap-2">
            {(g.klasse !== null || gruppen.length > 1) && (
              <p className="text-xs text-[var(--color-text-tertiary)]">
                {g.klasse !== null
                  ? t('intake.stufen.klasse', { klasse: g.klasse })
                  : t('intake.stufen.nichtImPlan')}
              </p>
            )}
            <div className="flex flex-wrap gap-2">
              {g.themen.map((thema) => (
                <ThemaChip
                  key={thema.thema_key}
                  label={thema.label}
                  zustand={zustandVon(thema.thema_key)}
                  ausPlan={ausPlan(thema.thema_key)}
                  disabled={disabled}
                  onClick={() =>
                    modus === 'aktuell' ? onAktuell(thema.thema_key) : onBehandelt(thema.thema_key)
                  }
                />
              ))}
            </div>
          </div>
        ))}
      </div>
    </div>
  )
}
