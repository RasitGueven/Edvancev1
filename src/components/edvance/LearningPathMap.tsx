import type { CSSProperties, JSX } from 'react'
import { Lock, Star, Play } from 'lucide-react'
import { cn } from '@/lib/utils'
import { MASTERY_STAGE_COLOR } from '@/lib/mastery'
import type { LearningPathNode } from '@/lib/mocks/lernpfad'

interface LearningPathMapProps {
  nodes: LearningPathNode[]
  /** Wird nur für freigeschaltete Knoten (done/current) aufgerufen. */
  onSelectNode: (id: string) => void
  /** i18n-Labels (Komponente bleibt sprach-agnostisch). */
  labels: { locked: string; current: string }
}

const ROW_PX = 124 // vertikaler Abstand zwischen zwei Leveln
const AMPLITUDE = 30 // Auslenkung der Serpentine in %

/** x-Position (in %) des Knotens i — sanftes Hin-und-Her wie eine Mario-Welt. */
function nodeX(i: number): number {
  return 50 + AMPLITUDE * Math.sin(i * 0.9)
}
function nodeY(i: number): number {
  return i * ROW_PX + ROW_PX / 2
}

export function LearningPathMap({
  nodes,
  onSelectNode,
  labels,
}: LearningPathMapProps): JSX.Element {
  const totalPx = nodes.length * ROW_PX

  // Pfad-Segmente: erreicht (bis current) vs. gesperrt — getrennt eingefärbt.
  const reachedPath: string[] = []
  const lockedPath: string[] = []
  for (let i = 0; i < nodes.length - 1; i++) {
    const seg = `M ${nodeX(i)} ${nodeY(i)} L ${nodeX(i + 1)} ${nodeY(i + 1)}`
    if (nodes[i + 1].status === 'locked') lockedPath.push(seg)
    else reachedPath.push(seg)
  }

  return (
    <div className="relative mx-auto w-full max-w-md" style={{ height: totalPx }}>
      {/* Verbindungs-Pfad */}
      <svg
        className="absolute inset-0 h-full w-full"
        viewBox={`0 0 100 ${totalPx}`}
        preserveAspectRatio="none"
        aria-hidden="true"
      >
        <path
          d={lockedPath.join(' ')}
          fill="none"
          strokeWidth={3}
          strokeLinecap="round"
          strokeDasharray="1 6"
          style={{ stroke: 'var(--color-border)' }}
          vectorEffect="non-scaling-stroke"
        />
        <path
          d={reachedPath.join(' ')}
          fill="none"
          strokeWidth={5}
          strokeLinecap="round"
          style={{ stroke: 'var(--color-primary)' }}
          vectorEffect="non-scaling-stroke"
        />
      </svg>

      {/* Level-Knoten */}
      {nodes.map((node, i) => (
        <LevelNode
          key={node.id}
          node={node}
          index={i}
          x={nodeX(i)}
          y={nodeY(i)}
          onSelect={() => onSelectNode(node.id)}
          labels={labels}
        />
      ))}
    </div>
  )
}

interface LevelNodeProps {
  node: LearningPathNode
  index: number
  x: number
  y: number
  onSelect: () => void
  labels: { locked: string; current: string }
}

function LevelNode({
  node,
  index,
  x,
  y,
  onSelect,
  labels,
}: LevelNodeProps): JSX.Element {
  const isLocked = node.status === 'locked'
  const isCurrent = node.status === 'current'
  const isDone = node.status === 'done'

  const circleStyle: CSSProperties = isLocked
    ? { backgroundColor: 'var(--color-bg-subtle)' }
    : isCurrent
      ? { backgroundColor: 'var(--color-primary)' }
      : { backgroundColor: MASTERY_STAGE_COLOR[node.stage] }

  return (
    <div
      className="absolute flex -translate-x-1/2 -translate-y-1/2 flex-col items-center gap-1.5"
      style={{ left: `${x}%`, top: y }}
    >
      {isCurrent && (
        <span className="absolute -top-7 animate-bounce whitespace-nowrap rounded-[var(--radius-full)] bg-[var(--color-primary)] px-2.5 py-1 text-[10px] font-bold text-white shadow-md">
          {labels.current}
        </span>
      )}

      <button
        type="button"
        onClick={onSelect}
        disabled={isLocked}
        aria-label={`${node.clusterName}${isLocked ? ` — ${labels.locked}` : ''}`}
        className={cn(
          'relative flex h-16 w-16 items-center justify-center rounded-[var(--radius-full)]',
          'border-4 border-[var(--color-bg-surface)] shadow-lg transition-all duration-base ease-bounce',
          isLocked
            ? 'cursor-not-allowed opacity-60'
            : 'hover:-translate-y-1 hover:shadow-xl active:translate-y-0',
          isCurrent && 'ring-4 ring-[var(--color-primary-light)] animate-pulse',
        )}
        style={circleStyle}
      >
        {isLocked ? (
          <Lock className="h-6 w-6 text-[var(--color-text-tertiary)]" aria-hidden="true" />
        ) : isCurrent ? (
          <Play className="h-7 w-7 fill-white text-white" aria-hidden="true" />
        ) : (
          <Star className="h-7 w-7 fill-white text-white" aria-hidden="true" />
        )}

        <span
          className={cn(
            'absolute -bottom-1 -right-1 flex h-6 w-6 items-center justify-center',
            'rounded-[var(--radius-full)] border-2 border-[var(--color-bg-surface)] text-[11px] font-bold',
            isDone || isCurrent
              ? 'bg-[var(--color-bg-surface)] text-[var(--color-text-primary)]'
              : 'bg-[var(--color-bg-subtle)] text-[var(--color-text-tertiary)]',
          )}
        >
          {index + 1}
        </span>
      </button>

      <span
        className={cn(
          'max-w-[7rem] truncate text-center text-xs font-semibold',
          isLocked
            ? 'text-[var(--color-text-tertiary)]'
            : 'text-[var(--color-text-primary)]',
        )}
      >
        {node.shortLabel}
      </span>
    </div>
  )
}
