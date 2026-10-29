// Kachel „Sessions“ im Item-Board: Session-Aufgaben entstehen aus Mustern (Bauformen) und werden im Muster-Board
// geprueft, nicht hier. Die Kachel fuehrt dorthin und zeigt den Stand (M1).
import type { JSX } from 'react'
import { Link } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import type { MusterStand } from '@/lib/pruefung/bauformStand'

export function MusterKachel({ titel, stand }: { titel: string; stand: MusterStand | null }): JSX.Element {
  const { t } = useTranslation('authoring')
  return (
    <Link
      to="/coach/pruefen/bauformen"
      className="flex min-h-[44px] flex-col gap-2 rounded-[var(--radius-xl)] border border-[var(--color-border)] bg-[var(--color-bg-surface)] p-6 text-left shadow-card transition hover:border-[var(--color-primary)] hover:shadow-elevation-md"
    >
      <span className="text-base font-semibold text-[var(--color-text-primary)]">{titel}</span>
      <span className="text-sm text-[var(--color-text-link)]">{t('board.muster.pruefen')}</span>
      {stand && (
        <span className="text-sm text-[var(--color-text-secondary)]">
          {t('board.muster.stand', { geprueft: stand.geprueft, total: stand.total })}
        </span>
      )}
    </Link>
  )
}
