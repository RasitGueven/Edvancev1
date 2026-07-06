import { useState, type JSX } from 'react'
import { useTranslation } from 'react-i18next'
import { Check } from 'lucide-react'
import { EmptyState } from '@/components/edvance'
import { Modal } from '@/components/edvance/Modal'
import { MASTERY_STAGE_LABEL } from '@/lib/mastery'
import { displayStage } from '@/lib/mocks/sessionMachine'
import { cn } from '@/lib/utils'
import { SessionShell } from '../components/SessionShell'
import { SessionButton, STAGE_BG, STAGE_TEXT } from '@/components/student'
import { SkillTree } from '../components/SkillTree'
import { MOCK_SKILL_TREE, type SkillNode } from '@/lib/mocks/session'
import type { ScreenProps } from '../screenProps'

const LEGEND = [
  { key: 'session.progress.legendMastered', dot: 'bg-[var(--color-mastery-mastered)]' },
  { key: 'session.progress.legendActive', dot: 'bg-[var(--color-mastery-developing)]' },
  { key: 'session.progress.legendLocked', dot: 'bg-[var(--color-neutral-inactive)]' },
  { key: 'session.progress.legendUnknown', dot: 'bg-[var(--color-neutral-unknown)]' },
] as const

function NodeDetail({ node }: { node: SkillNode }): JSX.Element {
  const { t } = useTranslation('mock')

  if (node.status === 'unknown') {
    return (
      <EmptyState
        icon="🧭"
        title={t('session.progress.unknownTitle')}
        description={t('session.progress.unknownBody')}
      />
    )
  }
  if (node.status === 'locked') {
    return (
      <EmptyState
        icon="🔒"
        title={t('session.progress.lockedTitle')}
        description={t('session.progress.lockedBody')}
      />
    )
  }

  const score = node.score ?? 0
  const stage = displayStage(score, node.coachGranted ?? false)
  return (
    <div className="flex flex-col gap-2">
      <div className="flex items-center justify-between">
        <span className="text-xs font-semibold uppercase tracking-wider text-[var(--color-text-tertiary)]">
          {t('session.progress.detailScore')}
        </span>
        <span className={cn('text-sm font-bold', STAGE_TEXT[stage])}>
          {MASTERY_STAGE_LABEL[stage]} · {score}%
        </span>
      </div>
      <div className="h-2.5 w-full overflow-hidden rounded-[var(--radius-full)] bg-[var(--color-border)]">
        <div
          className={cn('h-full rounded-[var(--radius-full)]', STAGE_BG[stage])}
          style={{ width: `${score}%` }}
        />
      </div>
    </div>
  )
}

/**
 * Screen 9 — Fortschritt / Skill-Tree. „Wo stehe ich, wohin geht's." Erreichte
 * Themen prominent, keine Lücken betont, kein Vergleich. Nur aus Hub/Abschluss
 * erreichbar (Reducer-Invariante schützt die 60 Minuten).
 */
export function ProgressScreen({ dispatch }: ScreenProps): JSX.Element {
  const { t } = useTranslation('mock')
  const [selected, setSelected] = useState<SkillNode | null>(null)
  const masteredCount = MOCK_SKILL_TREE.filter((n) => n.status === 'mastered').length

  return (
    <SessionShell maxWidth="md" showExit>
      <div className="flex flex-col gap-6">
        <div>
          <p className="text-eyebrow text-warm-56">{t('session.progress.eyebrow')}</p>
          <h1 className="text-display mt-1 text-3xl text-warm">
            {t('session.progress.title')}
          </h1>
          <p className="mt-2 inline-flex items-center gap-1.5 rounded-[var(--radius-full)] bg-[var(--color-mastery-mastered)] px-3 py-1 text-sm font-bold text-warm shadow-md">
            <Check className="h-4 w-4" aria-hidden="true" />
            {t('session.progress.masteredCount', { count: masteredCount })}
          </p>
        </div>

        <div className="flex flex-wrap gap-x-5 gap-y-2">
          {LEGEND.map((l) => (
            <span key={l.key} className="flex items-center gap-2 text-xs text-warm-72">
              <span
                className={cn('h-3 w-3 rounded-[var(--radius-full)]', l.dot)}
                aria-hidden="true"
              />
              {t(l.key)}
            </span>
          ))}
        </div>

        <SkillTree nodes={MOCK_SKILL_TREE} onSelect={setSelected} />

        <SessionButton block onClick={() => dispatch({ type: 'BACK_TO_HUB' })}>
          {t('session.progress.cta')}
        </SessionButton>
      </div>

      {selected && (
        <Modal open onClose={() => setSelected(null)} title={selected.name} size="md">
          <NodeDetail node={selected} />
        </Modal>
      )}
    </SessionShell>
  )
}
