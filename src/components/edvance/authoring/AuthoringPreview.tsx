// "Wie das Kind es sieht." Live, neben dem Editor.
//
// Die Vorschau rendert GENAU die Whitelist, die lsa_question_payload ans Kind
// gibt (P01 §4, P02): Stamm, Assets, und je nach Typ ein Eingabefeld, MC-Optionen
// oder die Teilaufgaben mit nr/kind/prompt/unit/options.
//
// Was hier bewusst NICHT vorkommt:
//   - Loesung, akzeptierte Antworten, Hinweise, typische Fehler
//   - AFB, Kompetenz, Stoffanker (Diagnostik-Metadaten, nicht fuer das Kind)
//   - jede Form von richtig/falsch-Feedback (CLAUDE §6 — in der LSA gibt es keins)
// Die Eingabefelder sind Attrappen (disabled): die Vorschau prueft das Layout,
// nicht die Antwort.

import type { JSX } from 'react'
import { useTranslation } from 'react-i18next'
import { EdvanceCard } from '@/components/edvance'
import { MathContent } from '@/lib/render/MathContent'
import type { PartOption, TaskAsset, TaskPart } from '@/types'
import type { FormState } from './editorState'
import { isMultiPart, normalizeParts } from './editorState'

function Assets({ assets }: { assets: TaskAsset[] }): JSX.Element | null {
  const visible = assets.filter((a) => a.url.trim() !== '')
  if (visible.length === 0) return null
  return (
    <div className="flex flex-col gap-2">
      {visible.map((asset, i) => (
        <figure key={`${asset.url}-${i}`} className="flex flex-col gap-1">
          <img
            src={asset.url}
            alt={asset.alt}
            className="max-w-full rounded-[var(--radius-md)] border border-[var(--color-border)]"
          />
          {asset.caption && (
            <figcaption className="text-xs text-[var(--color-text-tertiary)]">
              {asset.caption}
            </figcaption>
          )}
        </figure>
      ))}
    </div>
  )
}

function ShortInput({ unit, placeholder }: { unit?: string | null; placeholder: string }): JSX.Element {
  return (
    <div className="flex items-center gap-2">
      <input
        disabled
        placeholder={placeholder}
        className="h-12 w-full rounded-xl border border-[var(--color-border)] bg-[var(--color-bg-surface)] px-3 text-sm"
      />
      {unit && (
        <span className="text-sm font-semibold text-[var(--color-text-secondary)]">{unit}</span>
      )}
    </div>
  )
}

function McOptions({ options }: { options: PartOption[] }): JSX.Element | null {
  const visible = options.filter((o) => o.label.trim() !== '')
  if (visible.length === 0) return null
  return (
    <div className="flex flex-col gap-2">
      {visible.map((option, i) => (
        <div
          key={option.id || i}
          className="flex min-h-[44px] items-center gap-3 rounded-xl border border-[var(--color-border)] bg-[var(--color-bg-surface)] px-3 py-2"
        >
          <span className="h-4 w-4 shrink-0 rounded-full border-2 border-[var(--color-border)]" />
          <span className="text-sm text-[var(--color-text-primary)]">{option.label}</span>
        </div>
      ))}
    </div>
  )
}

function PartBlock({ part }: { part: TaskPart }): JSX.Element {
  const { t } = useTranslation('authoring')
  return (
    <div className="flex flex-col gap-3 border-t border-[var(--color-border)] pt-4">
      <span className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
        {t('parts.part', { nr: part.nr })}
      </span>
      {part.prompt && <MathContent text={part.prompt} />}
      {part.kind === 'mc' ? (
        <McOptions options={part.options ?? []} />
      ) : (
        <ShortInput unit={part.unit} placeholder={t('preview.answerPlaceholder')} />
      )}
    </div>
  )
}

export function AuthoringPreview({ state }: { state: FormState }): JSX.Element {
  const { t } = useTranslation('authoring')
  const multi = isMultiPart(state)
  const parts = multi ? normalizeParts(state.parts) : []

  return (
    <EdvanceCard className="flex flex-col gap-4 p-6">
      <div className="flex flex-col gap-1">
        <h3 className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
          {t('sections.preview')}
        </h3>
        <span className="text-xs leading-relaxed text-[var(--color-text-tertiary)]">
          {t('preview.hint')}
        </span>
      </div>

      <div className="flex flex-col gap-4 rounded-[var(--radius-md)] bg-[var(--color-bg-app)] p-4">
        {state.question.trim() === '' ? (
          <p className="text-sm italic text-[var(--color-text-tertiary)]">
            {t('preview.empty')}
          </p>
        ) : (
          <MathContent text={state.question} />
        )}

        <Assets assets={state.assets} />

        {multi ? (
          parts.map((part) => <PartBlock key={part.nr} part={part} />)
        ) : state.input_type === 'MC' ? (
          <McOptions options={state.mcOptions} />
        ) : (
          <ShortInput unit={state.unit} placeholder={t('preview.answerPlaceholder')} />
        )}

        <button
          disabled
          className="mt-2 h-12 rounded-xl bg-[var(--color-primary)] text-sm font-semibold text-white opacity-60"
        >
          {t('preview.submit')}
        </button>
      </div>
    </EdvanceCard>
  )
}
