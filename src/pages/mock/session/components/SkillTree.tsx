import type { JSX } from 'react'
import { useTranslation } from 'react-i18next'
import { Check, Lock, HelpCircle, Circle } from 'lucide-react'
import { cn } from '@/lib/utils'
import { MASTERY_STAGE_LABEL, type MasteryStage } from '@/lib/mastery'
import { displayStage } from '@/lib/mocks/sessionMachine'
import type { SkillNode } from '@/lib/mocks/session'
import { STAGE_BG } from '@/components/student'

interface SkillTreeProps {
  nodes: SkillNode[]
  onSelect: (node: SkillNode) => void
}

function visualStage(node: SkillNode): MasteryStage {
  return displayStage(node.score ?? 0, node.coachGranted ?? false)
}

function markerClass(node: SkillNode): string {
  if (node.status === 'locked') return 'bg-[var(--color-neutral-inactive)]'
  if (node.status === 'unknown') return 'bg-[var(--color-neutral-unknown)]'
  return STAGE_BG[visualStage(node)]
}

function NodeIcon({ node }: { node: SkillNode }): JSX.Element {
  if (node.status === 'locked') return <Lock className="h-5 w-5" aria-hidden="true" />
  if (node.status === 'unknown') return <HelpCircle className="h-5 w-5" aria-hidden="true" />
  if (visualStage(node) === 'mastered') return <Check className="h-5 w-5" aria-hidden="true" />
  return <Circle className="h-4 w-4 fill-current" aria-hidden="true" />
}

function statusLabel(node: SkillNode, t: (k: string) => string): string {
  if (node.status === 'locked') return t('session.progress.legendLocked')
  if (node.status === 'unknown') return t('session.progress.legendUnknown')
  return MASTERY_STAGE_LABEL[visualStage(node)]
}

/**
 * Skill-Tree (Screen 9): vertikale Kompetenz-Knoten mit vier Zuständen —
 * gemeistert (grün), in Arbeit (Mastery-Farbe), gesperrt (grau), unbekannt (?).
 * „Gemeistert" erscheint nie ohne Coach-Freigabe (Hard Rule §6, via displayStage).
 */
export function SkillTree({ nodes, onSelect }: SkillTreeProps): JSX.Element {
  const { t } = useTranslation('mock')

  return (
    <ol className="flex flex-col">
      {nodes.map((node, i) => {
        const last = i === nodes.length - 1
        return (
          <li key={node.id} className="relative flex items-stretch gap-4 pb-3">
            {!last && (
              <span
                aria-hidden="true"
                className="absolute left-[21px] top-11 bottom-0 w-0.5 bg-white/15"
              />
            )}
            <button
              type="button"
              onClick={() => onSelect(node)}
              className="group flex min-h-[44px] w-full items-center gap-4 text-left"
            >
              <span
                className={cn(
                  'z-10 flex h-11 w-11 shrink-0 items-center justify-center rounded-[var(--radius-full)] text-warm shadow-md transition-transform duration-200 ease-bounce group-active:scale-95',
                  markerClass(node),
                )}
              >
                <NodeIcon node={node} />
              </span>
              <span className="flex min-w-0 flex-1 items-center justify-between gap-3 rounded-[var(--radius-lg)] bg-white/10 px-4 py-3">
                <span className="min-w-0">
                  <span className="block truncate font-semibold text-warm">{node.name}</span>
                  <span className="block text-xs text-warm-56">{statusLabel(node, t)}</span>
                </span>
                {typeof node.score === 'number' && node.status !== 'locked' && (
                  <span className="shrink-0 text-sm font-bold text-warm-72">{node.score}%</span>
                )}
              </span>
            </button>
          </li>
        )
      })}
    </ol>
  )
}
