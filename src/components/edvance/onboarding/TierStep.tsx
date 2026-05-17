import { Check } from 'lucide-react'
import { EmptyState, LoadingPulse } from '@/components/edvance'
import type { TierStepProps } from '@/types'

const SELECTED_BG = 'color-mix(in srgb, var(--primary) 8%, transparent)'
const RECOMMENDED_INDEX = 1

function tierBorder(selected: boolean, isRecommended: boolean): string {
  if (selected) return 'var(--primary)'
  if (isRecommended) return 'var(--primary-light)'
  return 'var(--border)'
}

function formatPrice(cents: number): string {
  return `${(cents / 100).toLocaleString('de-DE')} €/Monat`
}

export function TierStep({ data, setData, tiers, loading }: TierStepProps): JSX.Element {
  if (loading) return <LoadingPulse type="list" lines={3} />
  if (tiers.length === 0) {
    return (
      <EmptyState
        icon="💳"
        title="Keine Tarife"
        description="Es sind noch keine Tarife angelegt. Bitte zuerst unter Tarif-Verwaltung anlegen."
      />
    )
  }
  return (
    <div className="flex flex-col gap-4">
      {tiers.map((tier, index) => {
        const selected = data.tier === tier.name
        const isRecommended = index === RECOMMENDED_INDEX
        return (
          <button
            key={tier.id}
            type="button"
            onClick={() => setData({ ...data, tier: tier.name })}
            className="relative flex items-start justify-between rounded-xl border px-5 py-4 text-left transition-all"
            style={{
              borderColor: tierBorder(selected, isRecommended),
              background: selected ? SELECTED_BG : 'var(--card)',
              boxShadow: selected ? '0 0 0 2px var(--primary)' : 'none',
            }}
          >
            {isRecommended && (
              <span
                className="absolute -top-3 left-4 rounded-full px-2.5 py-0.5 text-xs font-semibold text-white"
                style={{ background: 'var(--primary)' }}
              >
                Empfohlen
              </span>
            )}
            <div className="flex flex-col gap-1">
              <span className="font-semibold text-foreground">{tier.name}</span>
              <ul className="mt-1 flex flex-col gap-0.5">
                {tier.features.map((feature) => (
                  <li key={feature} className="flex items-center gap-1.5 text-sm text-muted">
                    <Check className="h-3.5 w-3.5 shrink-0 text-success" />
                    {feature}
                  </li>
                ))}
              </ul>
            </div>
            <div className="flex flex-col items-end gap-2 shrink-0 ml-4">
              <span className="font-bold text-foreground">{formatPrice(tier.price_cents)}</span>
              {selected && (
                <span
                  className="flex h-6 w-6 items-center justify-center rounded-full"
                  style={{ background: 'var(--primary)' }}
                >
                  <Check className="h-3.5 w-3.5 text-white" />
                </span>
              )}
            </div>
          </button>
        )
      })}
    </div>
  )
}
