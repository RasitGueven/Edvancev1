// Das Kopfband der Pflege-Strecke: schmal, navy, mit der Position in der
// Warteschlange (12/47) und der duennen Fortschrittsleiste.
//
// "Hell arbeitet, Midnight inszeniert": das Band ist der einzige dunkle Streifen
// des Screens — Fraunces-Titel, matte Gold-Haarlinie, kein Glow, keine Pills.
// Darunter bleibt alles helle Arbeitsflaeche.

import type { JSX } from 'react'
import { Link } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { Eye, X } from 'lucide-react'

export function WizardTopBar({
  label,
  position,
  total,
  onPreview,
}: {
  /** Woher die Warteschlange kam ("Item-Liste", "Content-Gesundheit"). */
  label: string
  /** 1-basiert — Anzeige "12 / 47". */
  position: number
  total: number
  onPreview: () => void
}): JSX.Element {
  const { t } = useTranslation('authoring')
  // Fortschritt = abgeschlossene Items, nicht das angefangene: bei Item 1 von 47
  // ist noch nichts geschafft — eine volle erste Kachel waere gelogen.
  const percent = total > 0 ? ((position - 1) / total) * 100 : 0

  return (
    <header className="relative overflow-hidden rounded-[var(--radius-xl)] bg-[image:var(--gradient-midnight)] px-6 py-4 shadow-lg">
      {/* Matte Gold-Haarlinie als Akzent — kein Glow (wie AdminHeader). */}
      <span
        aria-hidden="true"
        className="absolute inset-x-0 top-0 h-px bg-[color-mix(in_srgb,var(--color-stage-gold-edge)_45%,transparent)]"
      />
      <div className="flex flex-wrap items-center justify-between gap-4">
        <div className="flex min-w-0 flex-col gap-0.5">
          <h1 className="font-serif text-xl font-semibold leading-tight text-[var(--color-stage-text)]">
            {t('wizard.title')}
          </h1>
          {label && (
            <p className="truncate text-xs text-[color-mix(in_srgb,var(--color-stage-text)_60%,transparent)]">
              {t('wizard.queueLabel', { label })}
            </p>
          )}
        </div>

        <div className="flex items-center gap-3">
          <span className="text-2xl font-bold tabular-nums text-[var(--color-stage-text)]">
            {t('wizard.queuePosition', { pos: position, total })}
          </span>
          <button
            type="button"
            onClick={onPreview}
            className="inline-flex min-h-[44px] items-center gap-2 rounded-xl border border-[color-mix(in_srgb,var(--color-stage-text)_30%,transparent)] px-3 text-xs font-semibold text-[var(--color-stage-text)] transition hover:border-[var(--color-stage-gold-edge)]"
          >
            <Eye className="h-4 w-4" aria-hidden="true" />
            {t('wizard.openPreview')}
          </button>
          <Link
            to="/admin/authoring"
            aria-label={t('wizard.exit')}
            title={t('wizard.exit')}
            className="inline-flex h-11 w-11 items-center justify-center rounded-xl border border-[color-mix(in_srgb,var(--color-stage-text)_30%,transparent)] text-[var(--color-stage-text)] transition hover:border-[var(--color-stage-gold-edge)]"
          >
            <X className="h-4 w-4" aria-hidden="true" />
          </Link>
        </div>
      </div>

      {/* Die schmale Fortschrittsleiste. Breite ist ein berechneter Wert — der
          eine erlaubte Fall fuer einen Inline-Style. */}
      <div
        className="mt-3 h-1.5 overflow-hidden rounded-[var(--radius-full)] bg-[color-mix(in_srgb,var(--color-stage-text)_15%,transparent)]"
        role="progressbar"
        aria-valuemin={0}
        aria-valuemax={total}
        aria-valuenow={position - 1}
      >
        <div
          className="h-full rounded-[var(--radius-full)] bg-[var(--color-stage-gold-edge)] transition-all"
          style={{ width: `${percent}%` }}
        />
      </div>
    </header>
  )
}
