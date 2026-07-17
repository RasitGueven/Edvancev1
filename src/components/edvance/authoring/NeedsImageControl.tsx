// Die didaktische Frage: Braucht das hier eine Abbildung? (A08)
//
// Bewusst DREI Zustaende, nicht ein Ja/Nein-Haken: NULL = noch nicht beurteilt
// ist ein eigener, sichtbarer Zustand — keine automatische Vorbelegung, keine
// Heuristik. Erst der Mensch faellt die Entscheidung (true/false). Deshalb ein
// Radiogroup mit "offen" als gleichberechtigter Option, kein Schalter mit
// implizitem Default.
//
// Getrennt vom Bild-Zustand der Assets (C10-EMF-Befund): "ist ein Bild da und
// heil?" ist Technik, "braucht die Aufgabe ueberhaupt eines?" ist Didaktik.

import type { JSX } from 'react'
import { useTranslation } from 'react-i18next'
import { Field } from './ui'

type Choice = { value: boolean | null; key: 'open' | 'yes' | 'no' }

const CHOICES: Choice[] = [
  { value: null, key: 'open' },
  { value: true, key: 'yes' },
  { value: false, key: 'no' },
]

export function NeedsImageControl({
  label,
  value,
  canWrite,
  onChange,
}: {
  label: string
  value: boolean | null
  canWrite: boolean
  onChange: (next: boolean | null) => void
}): JSX.Element {
  const { t } = useTranslation('authoring')

  return (
    <Field label={label}>
      <div className="flex flex-wrap gap-2" role="radiogroup" aria-label={label}>
        {CHOICES.map((choice) => {
          const active = value === choice.value
          return (
            <button
              key={choice.key}
              type="button"
              role="radio"
              aria-checked={active}
              disabled={!canWrite}
              onClick={() => onChange(choice.value)}
              className={`min-h-[44px] rounded-xl border px-4 text-xs font-semibold transition disabled:cursor-not-allowed disabled:opacity-60 ${
                active
                  ? 'border-[var(--color-primary)] bg-[var(--color-primary)] text-white'
                  : 'border-[var(--color-border)] bg-[var(--color-bg-surface)] text-[var(--color-text-secondary)]'
              }`}
            >
              {t(`needsImage.${choice.key}`)}
            </button>
          )
        })}
      </div>
    </Field>
  )
}
