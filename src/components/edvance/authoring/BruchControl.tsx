// Die Bruch-Angabe einer Aufgabe bzw. Teilaufgabe (LSA-Erlebnis L1, Punkt 1).
//
// Sie bestimmt das Eingabeformat beim Kind (input_hint): Bruch → Bruchmaske, Zahl → Zifferntastatur.
// Drei Zustaende wie bei der Bild-Notwendigkeit: „Automatisch“ (NULL) nimmt den Vorschlag aus den
// Loesungen; der steht darunter. Ist er nicht eindeutig (gemischt, Text, fremde Einheit), kommt die Aufgabe
// nicht in den LSA-Pool, bis hier „Bruch“ oder „Zahl“ gewaehlt ist. Die Migration hat nur Bruch-Treffer
// fest gesetzt; alles andere steht auf „Automatisch“.

import type { JSX } from 'react'
import { useTranslation } from 'react-i18next'
import { formatVorschlag } from '@/lib/authoring/bruch'
import { Field } from './ui'

type Choice = { value: boolean | null; key: 'auto' | 'yes' | 'no' }

const CHOICES: Choice[] = [
  { value: null, key: 'auto' },
  { value: true, key: 'yes' },
  { value: false, key: 'no' },
]

export function BruchControl({
  feld,
  value,
  answers,
  unit,
  onChange,
}: {
  /** Schluessel im Vorbefuellt-Kennzeichen ('bruch' / 'parts.<nr>.bruch'). */
  feld: string
  value: boolean | null
  /** Die Loesungen — Grundlage fuer den Vorschlag bei „Automatisch“. */
  answers: string[]
  /** Die Einheit, die das Feld zeigt — eine Loesung mit genau dieser Einheit zaehlt als Zahl. */
  unit?: string | null
  onChange: (next: boolean | null) => void
}): JSX.Element {
  const { t } = useTranslation('authoring')
  const ergebnis = formatVorschlag(answers.filter((a) => a.trim() !== ''), unit) ?? 'offen'

  return (
    <Field label={t('bruch.label')} feld={feld} hint={value === null ? t(`bruch.auto_${ergebnis}`) : undefined}>
      <div className="flex flex-wrap gap-2" role="radiogroup" aria-label={t('bruch.label')}>
        {CHOICES.map((choice) => {
          const active = value === choice.value
          return (
            <button
              key={choice.key}
              type="button"
              role="radio"
              aria-checked={active}
              onClick={() => onChange(choice.value)}
              className={`min-h-[44px] rounded-xl border px-4 text-xs font-semibold transition ${
                active
                  ? 'border-[var(--color-primary)] bg-[var(--color-primary)] text-white'
                  : 'border-[var(--color-border)] bg-[var(--color-bg-surface)] text-[var(--color-text-secondary)]'
              }`}
            >
              {t(`bruch.${choice.key}`)}
            </button>
          )
        })}
      </div>
    </Field>
  )
}
