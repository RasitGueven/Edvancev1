// Matching links → rechts. Linke Items sind Drag-Quellen, rechte Items sind
// die einzigen Drop-Targets — damit ist „nur links→rechts" strukturell
// erzwungen, nicht über Konvention. Tap-Fallback (links antippen → rechts
// antippen) bleibt erhalten. Farbtints zeigen, was zu was gehört.

import { useState, type JSX } from 'react'
import {
  DndContext,
  DragOverlay,
  PointerSensor,
  TouchSensor,
  useDraggable,
  useDroppable,
  useSensor,
  useSensors,
  type DragEndEvent,
  type DragStartEvent,
} from '@dnd-kit/core'
import { ArrowRight } from 'lucide-react'

export type MatchPairs = Map<number, number> // leftIdx → rightIdx

type Props = {
  left: string[]
  right: string[] // kann vorgemischt übergeben werden
  pairs: MatchPairs
  onChange: (p: MatchPairs) => void
  disabled: boolean
}

const TINTS: { line: string; tintVar: string }[] = [
  { line: 'var(--color-primary)', tintVar: 'var(--color-primary-light)' },
  { line: 'var(--color-success)', tintVar: 'var(--color-success-light)' },
  { line: 'var(--color-gold-warning)', tintVar: 'var(--color-gold-warning-light)' },
  { line: 'var(--color-primary)', tintVar: 'var(--color-primary-light)' },
]

const LEFT_PREFIX = 'L:'
const RIGHT_PREFIX = 'R:'

export function MatchingWidget({
  left,
  right,
  pairs,
  onChange,
  disabled,
}: Props): JSX.Element {
  const [armed, setArmed] = useState<number | null>(null) // linker Index, falls per Tap armiert
  const [dragLeft, setDragLeft] = useState<number | null>(null)

  // reverse + Insertion-Order für stabile Tint-Zuteilung
  const r2l = new Map<number, number>()
  pairs.forEach((r, l) => r2l.set(r, l))
  const orderL = Array.from(pairs.keys())
  const tintForLeft = (l: number): { line: string; tintVar: string } | null => {
    const idx = orderL.indexOf(l)
    return idx >= 0 ? TINTS[idx % TINTS.length] : null
  }

  const sensors = useSensors(
    useSensor(PointerSensor, { activationConstraint: { distance: 4 } }),
    useSensor(TouchSensor, { activationConstraint: { delay: 120, tolerance: 6 } }),
  )

  function pair(l: number, r: number): void {
    const next = new Map(pairs)
    // andere Slots aufräumen, in denen dieses links oder dieses rechts hing
    if (next.has(l)) next.delete(l)
    if (r2l.has(r)) next.delete(r2l.get(r)!)
    next.set(l, r)
    onChange(next)
  }

  function unpairLeft(l: number): void {
    if (!pairs.has(l)) return
    const next = new Map(pairs)
    next.delete(l)
    onChange(next)
  }

  function unpairRight(r: number): void {
    const l = r2l.get(r)
    if (l === undefined) return
    unpairLeft(l)
  }

  function tapLeft(i: number): void {
    if (disabled) return
    if (pairs.has(i)) {
      // Tap auf bereits verknüpftes links → trennen
      unpairLeft(i)
      return
    }
    setArmed((prev) => (prev === i ? null : i))
  }

  function tapRight(j: number): void {
    if (disabled) return
    if (armed !== null) {
      pair(armed, j)
      setArmed(null)
      return
    }
    // Tap auf verknüpftes rechts → trennen
    if (r2l.has(j)) unpairRight(j)
  }

  function handleDragStart(e: DragStartEvent): void {
    const id = String(e.active.id)
    if (id.startsWith(LEFT_PREFIX)) {
      setDragLeft(Number(id.slice(LEFT_PREFIX.length)))
      setArmed(null)
    }
  }

  function handleDragEnd(e: DragEndEvent): void {
    setDragLeft(null)
    const aId = String(e.active.id)
    if (!aId.startsWith(LEFT_PREFIX)) return
    const l = Number(aId.slice(LEFT_PREFIX.length))
    if (!e.over) {
      // Drop außerhalb → bestehende Verknüpfung lösen
      unpairLeft(l)
      return
    }
    const oId = String(e.over.id)
    if (!oId.startsWith(RIGHT_PREFIX)) return // kann nicht passieren, nur rechte Items sind droppable
    pair(l, Number(oId.slice(RIGHT_PREFIX.length)))
  }

  function handleDragCancel(): void {
    setDragLeft(null)
  }

  const draggedLeftLabel = dragLeft !== null ? left[dragLeft] : null

  return (
    <DndContext
      sensors={sensors}
      onDragStart={handleDragStart}
      onDragEnd={handleDragEnd}
      onDragCancel={handleDragCancel}
    >
      <div className="grid grid-cols-[1fr_auto_1fr] items-center gap-x-3 gap-y-2">
        <p className="text-[10px] font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
          Begriff
        </p>
        <span />
        <p className="text-[10px] font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
          {armed !== null ? '→ Tippe hier' : 'Zuordnung'}
        </p>

        {Array.from({ length: Math.max(left.length, right.length) }).map((_, row) => (
          <Row
            key={row}
            leftIdx={row < left.length ? row : null}
            leftItem={row < left.length ? left[row] : null}
            rightIdx={row < right.length ? row : null}
            rightItem={row < right.length ? right[row] : null}
            armed={armed}
            pairs={pairs}
            r2l={r2l}
            tintForLeft={tintForLeft}
            disabled={disabled}
            onTapLeft={tapLeft}
            onTapRight={tapRight}
          />
        ))}
      </div>
      <DragOverlay dropAnimation={null}>
        {draggedLeftLabel !== null ? (
          <div className="pointer-events-none inline-flex max-w-[16rem] items-center rounded-[var(--radius-md)] border border-[var(--color-primary)] bg-[var(--color-primary-light)] px-3 py-2 text-sm font-medium text-[var(--color-primary)] shadow-lg">
            {draggedLeftLabel}
          </div>
        ) : null}
      </DragOverlay>
    </DndContext>
  )
}

function Row({
  leftIdx,
  leftItem,
  rightIdx,
  rightItem,
  armed,
  pairs,
  r2l,
  tintForLeft,
  disabled,
  onTapLeft,
  onTapRight,
}: {
  leftIdx: number | null
  leftItem: string | null
  rightIdx: number | null
  rightItem: string | null
  armed: number | null
  pairs: MatchPairs
  r2l: Map<number, number>
  tintForLeft: (l: number) => { line: string; tintVar: string } | null
  disabled: boolean
  onTapLeft: (l: number) => void
  onTapRight: (r: number) => void
}): JSX.Element {
  const leftTint = leftIdx !== null ? tintForLeft(leftIdx) : null
  const rightL = rightIdx !== null ? r2l.get(rightIdx) ?? null : null
  const rightTint = rightL !== null ? tintForLeft(rightL) : null
  return (
    <>
      {leftIdx !== null && leftItem !== null ? (
        <LeftCell
          idx={leftIdx}
          label={leftItem}
          tint={leftTint}
          isArmed={armed === leftIdx}
          disabled={disabled}
          onTap={() => onTapLeft(leftIdx)}
        />
      ) : (
        <span />
      )}
      <ArrowRight
        className={`h-4 w-4 shrink-0 ${leftTint || armed !== null ? 'text-[var(--color-primary)]' : 'text-[var(--color-text-tertiary)]'}`}
      />
      {rightIdx !== null && rightItem !== null ? (
        <RightCell
          idx={rightIdx}
          label={rightItem}
          tint={rightTint}
          showDropHint={armed !== null && !r2l.has(rightIdx)}
          onTap={() => onTapRight(rightIdx)}
        />
      ) : (
        <span />
      )}
    </>
  )
}

const CELL_BASE =
  'flex min-h-[48px] w-full select-none items-center gap-2 rounded-[var(--radius-md)] border-2 px-3 py-2 text-sm leading-snug text-[var(--color-text-primary)] transition-colors duration-fast'

function LeftCell({
  idx,
  label,
  tint,
  isArmed,
  disabled,
  onTap,
}: {
  idx: number
  label: string
  tint: { line: string; tintVar: string } | null
  isArmed: boolean
  disabled: boolean
  onTap: () => void
}): JSX.Element {
  const { attributes, listeners, setNodeRef, isDragging } = useDraggable({
    id: `${LEFT_PREFIX}${idx}`,
    disabled,
  })
  const style: React.CSSProperties = { touchAction: 'none' }
  if (tint && !isArmed) {
    style.borderColor = tint.line
    style.background = tint.tintVar
  }
  return (
    <div
      ref={setNodeRef}
      role="button"
      tabIndex={0}
      onClick={onTap}
      onKeyDown={(e) => {
        if (e.key === 'Enter' || e.key === ' ') {
          e.preventDefault()
          onTap()
        }
      }}
      {...listeners}
      {...attributes}
      style={style}
      className={`${CELL_BASE} cursor-grab active:cursor-grabbing ${
        isArmed
          ? 'border-[var(--color-primary)] bg-[var(--color-primary-light)] shadow-md'
          : !tint
            ? 'border-[var(--color-border)] bg-[var(--color-bg-surface)] hover:border-[var(--color-primary)]'
            : ''
      } ${isDragging ? 'invisible' : ''}`}
    >
      {tint && (
        <span
          className="h-2.5 w-2.5 shrink-0 rounded-full"
          style={{ background: tint.line }}
        />
      )}
      <span className="flex-1">{label}</span>
    </div>
  )
}

function RightCell({
  idx,
  label,
  tint,
  showDropHint,
  onTap,
}: {
  idx: number
  label: string
  tint: { line: string; tintVar: string } | null
  showDropHint: boolean
  onTap: () => void
}): JSX.Element {
  const { setNodeRef, isOver } = useDroppable({ id: `${RIGHT_PREFIX}${idx}` })
  const style: React.CSSProperties = {}
  if (tint) {
    style.borderColor = tint.line
    style.background = tint.tintVar
  }
  return (
    <div
      ref={setNodeRef}
      role="button"
      tabIndex={0}
      onClick={onTap}
      onKeyDown={(e) => {
        if (e.key === 'Enter' || e.key === ' ') {
          e.preventDefault()
          onTap()
        }
      }}
      style={style}
      className={`${CELL_BASE} cursor-pointer ${
        isOver
          ? 'border-[var(--color-primary)] bg-[var(--color-primary-light)] shadow-md'
          : tint
            ? ''
            : showDropHint
              ? 'border-dashed border-[var(--color-primary)] bg-[var(--color-primary-light)]'
              : 'border-[var(--color-border)] bg-[var(--color-bg-surface)] hover:border-[var(--color-primary)]'
      }`}
    >
      {tint && (
        <span
          className="h-2.5 w-2.5 shrink-0 rounded-full"
          style={{ background: tint.line }}
        />
      )}
      <span className="flex-1">{label}</span>
    </div>
  )
}
