import { useTranslation } from 'react-i18next'
import { ArrowDown, ArrowUp, Plus, X } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import type { ScreeningTeilaufgabe } from '@/types'

const NUMERIC_KEY_BG = 'bg-[var(--color-repair-light)] text-[var(--color-repair)]'

export function TeilaufgabenEditor({
  items,
  onChange,
}: {
  items: ScreeningTeilaufgabe[]
  onChange: (items: ScreeningTeilaufgabe[]) => void
}): JSX.Element {
  const { t } = useTranslation('screening-editor')

  const add = (): void => {
    const nextKey = String.fromCharCode(97 + items.length)
    onChange([
      ...items,
      { key: nextKey, prompt: '', input_type: 'NUMERIC', accepted: [] },
    ])
  }

  const update = (idx: number, patch: Partial<ScreeningTeilaufgabe>): void => {
    onChange(items.map((it, i) => (i === idx ? { ...it, ...patch } : it)))
  }

  const remove = (idx: number): void => {
    onChange(items.filter((_, i) => i !== idx))
  }

  const move = (idx: number, dir: -1 | 1): void => {
    const j = idx + dir
    if (j < 0 || j >= items.length) return
    const next = items.slice()
    ;[next[idx], next[j]] = [next[j], next[idx]]
    onChange(next)
  }

  if (items.length === 0) {
    return (
      <div className="flex flex-col gap-2">
        <p className="text-xs text-[var(--color-text-tertiary)]">{t('teil.empty')}</p>
        <Button size="sm" variant="outline" onClick={add}>
          <Plus className="mr-1 h-3.5 w-3.5" /> {t('teil.addTeilaufgabe')}
        </Button>
      </div>
    )
  }

  return (
    <div className="flex flex-col gap-3">
      {items.map((it, idx) => (
        <TeilRow
          key={idx}
          item={it}
          index={idx}
          total={items.length}
          onUpdate={(patch) => update(idx, patch)}
          onRemove={() => remove(idx)}
          onMove={(dir) => move(idx, dir)}
        />
      ))}
      <Button size="sm" variant="outline" onClick={add} className="self-start">
        <Plus className="mr-1 h-3.5 w-3.5" /> {t('teil.addTeilaufgabe')}
      </Button>
    </div>
  )
}

function TeilRow({
  item,
  index,
  total,
  onUpdate,
  onRemove,
  onMove,
}: {
  item: ScreeningTeilaufgabe
  index: number
  total: number
  onUpdate: (patch: Partial<ScreeningTeilaufgabe>) => void
  onRemove: () => void
  onMove: (dir: -1 | 1) => void
}): JSX.Element {
  const { t } = useTranslation('screening-editor')
  const type = item.input_type ?? 'NUMERIC'

  return (
    <div className="rounded-xl border border-[var(--color-border)] bg-[var(--color-bg-subtle)]">
      <div className="flex flex-wrap items-center gap-2 border-b border-[var(--color-border)] bg-[var(--color-bg-surface)] px-3 py-2">
        <div
          className={`grid h-8 w-8 place-items-center rounded-lg font-bold ${NUMERIC_KEY_BG}`}
        >
          <input
            value={item.key}
            onChange={(e) => onUpdate({ key: e.target.value })}
            maxLength={2}
            className="h-full w-full bg-transparent text-center font-bold outline-none"
            aria-label="Key"
          />
        </div>
        <div className="inline-flex gap-0.5 rounded-lg bg-[var(--color-bg-subtle)] p-0.5">
          {(['NUMERIC', 'FREE_TEXT'] as const).map((tp) => (
            <button
              key={tp}
              type="button"
              onClick={() => onUpdate({ input_type: tp })}
              className={`rounded-md px-2 py-1 text-xs font-semibold transition ${
                type === tp
                  ? 'bg-[var(--color-primary)] text-white'
                  : 'text-[var(--color-text-secondary)]'
              }`}
            >
              {tp === 'NUMERIC' ? t('teil.typeNumeric') : t('teil.typeOpen')}
            </button>
          ))}
        </div>
        <div className="ml-auto flex gap-0.5">
          <IconBtn
            disabled={index === 0}
            onClick={() => onMove(-1)}
            label={t('common:moveUp', { defaultValue: 'Nach oben' })}
          >
            <ArrowUp className="h-3.5 w-3.5" />
          </IconBtn>
          <IconBtn
            disabled={index === total - 1}
            onClick={() => onMove(1)}
            label={t('common:moveDown', { defaultValue: 'Nach unten' })}
          >
            <ArrowDown className="h-3.5 w-3.5" />
          </IconBtn>
          <IconBtn onClick={onRemove} label="Entfernen" danger>
            <X className="h-3.5 w-3.5" />
          </IconBtn>
        </div>
      </div>
      <div className="flex flex-col gap-3 p-3">
        <Input
          value={item.prompt}
          onChange={(e) => onUpdate({ prompt: e.target.value })}
          placeholder={t('teil.promptPlaceholder')}
        />
        {type === 'FREE_TEXT' && (
          <AcceptedList
            items={item.accepted ?? []}
            onChange={(accepted) => onUpdate({ accepted })}
          />
        )}
      </div>
    </div>
  )
}

function AcceptedList({
  items,
  onChange,
}: {
  items: string[]
  onChange: (next: string[]) => void
}): JSX.Element {
  const { t } = useTranslation('screening-editor')
  return (
    <div className="flex flex-col gap-1.5">
      <span className="text-xs font-semibold text-[var(--color-text-secondary)]">
        {t('open.label')}
      </span>
      {items.map((v, i) => (
        <div key={i} className="flex gap-1.5">
          <Input
            value={v}
            onChange={(e) =>
              onChange(items.map((x, j) => (j === i ? e.target.value : x)))
            }
          />
          <IconBtn
            onClick={() => onChange(items.filter((_, j) => j !== i))}
            label="Entfernen"
            danger
          >
            <X className="h-3.5 w-3.5" />
          </IconBtn>
        </div>
      ))}
      <Button
        size="sm"
        variant="outline"
        onClick={() => onChange([...items, ''])}
        className="self-start"
      >
        <Plus className="mr-1 h-3.5 w-3.5" /> {t('open.add')}
      </Button>
    </div>
  )
}

function IconBtn({
  onClick,
  disabled,
  label,
  danger,
  children,
}: {
  onClick: () => void
  disabled?: boolean
  label: string
  danger?: boolean
  children: React.ReactNode
}): JSX.Element {
  return (
    <button
      type="button"
      onClick={onClick}
      disabled={disabled}
      aria-label={label}
      title={label}
      className={`grid h-7 w-7 place-items-center rounded-md transition hover:bg-[var(--color-bg-subtle)] disabled:opacity-40 ${
        danger ? 'hover:bg-[var(--color-error-exam)]/10 hover:text-[var(--color-error-exam)]' : ''
      }`}
    >
      {children}
    </button>
  )
}
