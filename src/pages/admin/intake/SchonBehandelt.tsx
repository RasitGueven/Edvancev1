import { useTranslation } from 'react-i18next'
import { stufeDarunter } from '@/lib/themen/suche'
import type { LeadThema, Stufe, Thema } from '@/types'
import { ThemaChip } from './ThemaChip'

type SchonBehandeltProps = {
  katalog: Thema[]
  kindStufe: Stufe
  leadThemen: LeadThema[]
  aktuell: string | null
  /** Schule gewaehlt und ihr Plan hinterlegt. */
  hatPlan: boolean
  stand: string | null
  disabled: boolean
  onToggle: (themaKey: string) => void
}

/**
 * Themen der eigenen Stufe und der Stufe darunter als Mehrfachauswahl. Was
 * schon als behandelt erfasst ist (auch aus anderen Stufen), steht immer mit
 * da, damit es sichtbar und abwaehlbar bleibt. Vorbelegungen aus dem
 * Schulplan tragen einen Punkt; die Legende nennt den Stand des Plans.
 */
export function SchonBehandelt({
  katalog,
  kindStufe,
  leadThemen,
  aktuell,
  hatPlan,
  stand,
  disabled,
  onToggle,
}: SchonBehandeltProps): JSX.Element {
  const { t } = useTranslation('admin')
  const stufen = [kindStufe, stufeDarunter(kindStufe)]
  const behandelt = new Map(
    leadThemen.filter((x) => x.status === 'behandelt').map((x) => [x.thema_key, x.quelle]),
  )
  const themen = [...katalog]
    .filter((x) => x.thema_key !== aktuell)
    .filter((x) => stufen.includes(x.stufe) || behandelt.has(x.thema_key))
    .sort((a, b) => (a.sort ?? 0) - (b.sort ?? 0))
  const mitPlanMarke = [...behandelt.values()].includes('schulplan')

  return (
    <div className="flex flex-col gap-2">
      <p className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
        {t('intake.behandelt.titel')}
      </p>
      <p className="text-xs text-[var(--color-text-tertiary)]">{t('intake.behandelt.hinweis')}</p>
      {!hatPlan && (
        <p className="text-sm text-[var(--color-text-secondary)]">
          {t('intake.behandelt.keinPlan')}
        </p>
      )}
      <div className="flex flex-wrap gap-2">
        {themen.map((thema) => (
          <ThemaChip
            key={thema.thema_key}
            label={thema.label}
            zustand={behandelt.has(thema.thema_key) ? 'behandelt' : 'frei'}
            ausPlan={behandelt.get(thema.thema_key) === 'schulplan'}
            disabled={disabled}
            onClick={() => onToggle(thema.thema_key)}
          />
        ))}
      </div>
      {mitPlanMarke && (
        <p className="inline-flex items-center gap-2 text-xs text-[var(--color-text-tertiary)]">
          <span className="h-2 w-2 rounded-full bg-[var(--color-text-tertiary)]" aria-hidden />
          {stand
            ? t('intake.behandelt.ausPlan', { stand })
            : t('intake.behandelt.ausPlanOhneStand')}
        </p>
      )}
    </div>
  )
}
