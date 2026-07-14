// Die offenen Punkte eines Items — getrennt nach "blockiert die Freigabe" und
// "Hinweis". Die Trennung ist der ganze Punkt: ein Pfleger, der 12 gleichrangige
// Meckerpunkte sieht, weiss nicht, was ihn wirklich aufhaelt.

import type { JSX } from 'react'
import { useTranslation } from 'react-i18next'
import { AlertTriangle, CheckCircle2, Info } from 'lucide-react'
import type { ItemFlag } from '@/types'

function FlagRow({ flag }: { flag: ItemFlag }): JSX.Element {
  const { t } = useTranslation('authoring')
  const color = flag.blocking
    ? 'text-[var(--color-destructive)]'
    : 'text-[var(--color-text-tertiary)]'
  return (
    <li className="flex items-start gap-2 text-sm leading-relaxed">
      {flag.blocking ? (
        <AlertTriangle className={`mt-0.5 h-4 w-4 shrink-0 ${color}`} />
      ) : (
        <Info className={`mt-0.5 h-4 w-4 shrink-0 ${color}`} />
      )}
      <span className="text-[var(--color-text-secondary)]">
        {t(`flags.${flag.code}`, flag.vars)}
      </span>
    </li>
  )
}

export function FlagList({ flags }: { flags: ItemFlag[] }): JSX.Element {
  const { t } = useTranslation('authoring')
  const blocking = flags.filter((f) => f.blocking)
  const warnings = flags.filter((f) => !f.blocking)

  if (flags.length === 0) {
    return (
      <div className="flex items-start gap-2 text-sm leading-relaxed text-[var(--color-success)]">
        <CheckCircle2 className="mt-0.5 h-4 w-4 shrink-0" />
        <span>{t('flags.allClear')}</span>
      </div>
    )
  }

  return (
    <div className="flex flex-col gap-4">
      {blocking.length > 0 && (
        <div className="flex flex-col gap-2">
          <span className="text-xs font-semibold uppercase tracking-widest text-[var(--color-destructive)]">
            {t('flags.blockingTitle')}
          </span>
          <ul className="flex flex-col gap-2">
            {blocking.map((f, i) => (
              <FlagRow key={`${f.code}-${i}`} flag={f} />
            ))}
          </ul>
        </div>
      )}
      {warnings.length > 0 && (
        <div className="flex flex-col gap-2">
          <span className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
            {t('flags.warningTitle')}
          </span>
          <ul className="flex flex-col gap-2">
            {warnings.map((f, i) => (
              <FlagRow key={`${f.code}-${i}`} flag={f} />
            ))}
          </ul>
        </div>
      )}
    </div>
  )
}
