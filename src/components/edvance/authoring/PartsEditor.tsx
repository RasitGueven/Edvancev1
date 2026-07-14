// Teilaufgaben (tasks.parts, P02).
//
// Die Teilaufgabe ist der diagnostische Datenpunkt — nicht das Item. Deshalb traegt
// SIE die Kompetenz und das AFB, und deshalb steht beides hier und nicht oben am
// Item. Ein Item mit drei Teilaufgaben liefert drei Kompetenz-Messungen; ein
// "2 von 3"-Gesamtergebnis gibt es bewusst nicht.
//
// Die Loesung je Teilaufgabe wird hier miterfasst, landet aber NICHT in
// tasks.parts: lsa_parts_valid verbietet dort jedes Loesungsfeld per CHECK. Sie
// geht getrennt nach task_solutions.correct_answers unter dem Schluessel `nr`.

import type { JSX } from 'react'
import { useTranslation } from 'react-i18next'
import { ChevronDown, ChevronUp, X } from 'lucide-react'
import { Input } from '@/components/ui/input'
import { SELECT_SM, TEXTAREA_MD } from '@/lib/formStyles'
import type { Afb, PartKind, PartOption, TaskPart } from '@/types'
import { AddButton, Field, IconButton, StringList } from './ui'
import { AFB_VALUES } from './editorState'

const KINDS: PartKind[] = ['short_input', 'mc']

function optionId(index: number): string {
  return String.fromCharCode(97 + index) // a, b, c …
}

function PartCard({
  part,
  index,
  total,
  answers,
  competencies,
  onChange,
  onAnswers,
  onMove,
  onRemove,
}: {
  part: TaskPart
  index: number
  total: number
  answers: string[]
  competencies: string[]
  onChange: (next: TaskPart) => void
  onAnswers: (next: string[]) => void
  onMove: (dir: -1 | 1) => void
  onRemove: () => void
}): JSX.Element {
  const { t } = useTranslation('authoring')
  const set = <K extends keyof TaskPart>(key: K, value: TaskPart[K]): void =>
    onChange({ ...part, [key]: value })

  return (
    <div className="flex flex-col gap-4 rounded-[var(--radius-md)] border border-[var(--color-border)] p-4">
      <div className="flex items-center justify-between gap-2">
        <span className="text-sm font-semibold text-[var(--color-text-primary)]">
          {t('parts.part', { nr: index + 1 })}
        </span>
        <div className="flex items-center gap-2">
          <IconButton label={t('parts.moveUp')} onClick={() => onMove(-1)}>
            <ChevronUp className={`h-4 w-4 ${index === 0 ? 'opacity-30' : ''}`} />
          </IconButton>
          <IconButton label={t('parts.moveDown')} onClick={() => onMove(1)}>
            <ChevronDown className={`h-4 w-4 ${index === total - 1 ? 'opacity-30' : ''}`} />
          </IconButton>
          <IconButton label={t('parts.remove')} onClick={onRemove}>
            <X className="h-4 w-4" />
          </IconButton>
        </div>
      </div>

      <Field label={t('parts.prompt')}>
        <textarea
          className={`${TEXTAREA_MD} w-full`}
          value={part.prompt}
          placeholder={t('parts.promptPlaceholder')}
          onChange={(e) => set('prompt', e.target.value)}
        />
      </Field>

      <div className="grid gap-4 sm:grid-cols-2">
        <Field label={t('parts.kind')}>
          <select
            className={`${SELECT_SM} w-full`}
            value={part.kind}
            onChange={(e) => set('kind', e.target.value as PartKind)}
          >
            {KINDS.map((k) => (
              <option key={k} value={k}>
                {t(k === 'mc' ? 'parts.kindMc' : 'parts.kindShortInput')}
              </option>
            ))}
          </select>
        </Field>

        {part.kind === 'short_input' && (
          <Field label={t('fields.unit')}>
            <Input
              value={part.unit ?? ''}
              placeholder={t('fields.unitPlaceholder')}
              onChange={(e) => set('unit', e.target.value)}
            />
          </Field>
        )}
      </div>

      {part.kind === 'mc' && (
        <Field label={t('fields.mcOptions')}>
          <StringList
            values={(part.options ?? []).map((o) => o.label)}
            placeholder={t('fields.optionPlaceholder')}
            addLabel={t('fields.addOption')}
            removeLabel={t('fields.remove')}
            onChange={(labels) =>
              set(
                'options',
                labels.map((label, i): PartOption => ({
                  id: part.options?.[i]?.id ?? optionId(i),
                  label,
                })),
              )
            }
          />
        </Field>
      )}

      <Field label={t('parts.solution')}>
        <StringList
          values={answers}
          placeholder={t('fields.answerPlaceholder')}
          addLabel={t('fields.addAnswer')}
          removeLabel={t('fields.remove')}
          onChange={onAnswers}
        />
      </Field>

      <div className="grid gap-4 sm:grid-cols-2">
        <Field label={t('fields.afb')}>
          <select
            className={`${SELECT_SM} w-full`}
            value={part.afb ?? ''}
            onChange={(e) => set('afb', (e.target.value || null) as Afb | null)}
          >
            <option value="">{t('fields.none')}</option>
            {AFB_VALUES.map((a) => (
              <option key={a} value={a}>
                {t(`afbLevel.${a}`)}
              </option>
            ))}
          </select>
        </Field>

        <Field label={t('fields.competencyContent')}>
          <Input
            list="authoring-competencies"
            value={part.competency_content ?? ''}
            onChange={(e) => set('competency_content', e.target.value)}
          />
        </Field>
      </div>

      <datalist id="authoring-competencies">
        {competencies.map((c) => (
          <option key={c} value={c} />
        ))}
      </datalist>
    </div>
  )
}

export function PartsEditor({
  parts,
  partAnswers,
  competencies,
  onParts,
  onPartAnswers,
}: {
  parts: TaskPart[]
  partAnswers: Record<string, string[]>
  competencies: string[]
  onParts: (next: TaskPart[]) => void
  onPartAnswers: (next: Record<string, string[]>) => void
}): JSX.Element {
  const { t } = useTranslation('authoring')

  /**
   * Die Loesungen haengen an der NUMMER, die Reihenfolge an der Position. Wer eine
   * Teilaufgabe verschiebt oder loescht, muss beides mitziehen — sonst haengt die
   * Loesung von Teilaufgabe 2 ploetzlich an Teilaufgabe 3. Deshalb wird nach jeder
   * Strukturaenderung neu durchnummeriert und die Antwort-Map mitgezogen.
   */
  const commit = (nextParts: TaskPart[]): void => {
    const renumbered = nextParts.map((p, i) => ({ ...p, nr: i + 1 }))
    const nextAnswers: Record<string, string[]> = {}
    nextParts.forEach((part, i) => {
      const previous = partAnswers[String(part.nr)]
      if (previous) nextAnswers[String(i + 1)] = previous
    })
    onParts(renumbered)
    onPartAnswers(nextAnswers)
  }

  const move = (index: number, dir: -1 | 1): void => {
    const target = index + dir
    if (target < 0 || target >= parts.length) return
    const next = [...parts]
    ;[next[index], next[target]] = [next[target], next[index]]
    commit(next)
  }

  return (
    <div className="flex flex-col gap-4">
      <p className="text-xs leading-relaxed text-[var(--color-text-tertiary)]">
        {t('parts.hint')}
      </p>

      {parts.length === 0 && (
        <p className="text-sm text-[var(--color-text-tertiary)]">{t('parts.empty')}</p>
      )}

      {parts.map((part, i) => (
        <PartCard
          key={i}
          part={part}
          index={i}
          total={parts.length}
          answers={partAnswers[String(part.nr)] ?? []}
          competencies={competencies}
          onChange={(next) => onParts(parts.map((p, j) => (j === i ? next : p)))}
          onAnswers={(next) =>
            onPartAnswers({ ...partAnswers, [String(part.nr)]: next })
          }
          onMove={(dir) => move(i, dir)}
          onRemove={() => commit(parts.filter((_, j) => j !== i))}
        />
      ))}

      <AddButton
        label={t('parts.add')}
        onClick={() =>
          commit([
            ...parts,
            { nr: parts.length + 1, kind: 'short_input', prompt: '', afb: null },
          ])
        }
      />
    </div>
  )
}
