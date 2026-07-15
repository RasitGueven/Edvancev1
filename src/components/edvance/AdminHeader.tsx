import type { ReactNode } from 'react'
import { Link } from 'react-router-dom'
import { ArrowLeft } from 'lucide-react'

/**
 * AdminHeader — das navy „Midnight Academy"-Kopfband für die Admin-Oberfläche.
 *
 * Trägt die Schüler-Sprache in die (hellen) Verwaltungsseiten: ein ruhiges Navy-
 * Band auf dem Midnight-Gradient, Fraunces-Serif-Titel in warmem Off-White, eine
 * matte Gold-Haarlinie als Akzent (kein Glow). Darunter leben die Inhalte weiter
 * auf hellen Karten — die Coach-Regel „Navy-Header, weiße Cards".
 *
 * Primär-CTAs gehören NICHT in dieses Band (Gold-CTA auf dunkel / Navy-CTA auf
 * hell): der `actions`-Slot ist für sekundäre, gold-getönte Aktionen gedacht.
 */
interface AdminHeaderProps {
  title: string
  eyebrow?: string
  description?: string
  /** Zurück-Ziel; `null` blendet den Zurück-Link aus. Default: /admin. */
  backTo?: string | null
  backLabel?: string
  actions?: ReactNode
}

export function AdminHeader({
  title,
  eyebrow,
  description,
  backTo = '/admin',
  backLabel = 'Admin',
  actions,
}: AdminHeaderProps): JSX.Element {
  return (
    <header className="relative overflow-hidden rounded-[var(--radius-xl)] bg-[image:var(--gradient-midnight)] px-6 py-7 shadow-lg sm:px-8">
      {/* Matte Gold-Haarlinie als Akzent — kein Glow. */}
      <span
        aria-hidden="true"
        className="absolute inset-x-0 top-0 h-px bg-[color-mix(in_srgb,var(--color-stage-gold-edge)_45%,transparent)]"
      />
      <div className="flex flex-col gap-4">
        {backTo && (
          <Link
            to={backTo}
            className="inline-flex w-fit items-center gap-1 text-xs font-medium text-[color-mix(in_srgb,var(--color-stage-text)_60%,transparent)] transition-colors hover:text-[var(--color-stage-text)]"
          >
            <ArrowLeft className="h-3.5 w-3.5" /> {backLabel}
          </Link>
        )}
        <div className="flex flex-wrap items-end justify-between gap-4">
          <div className="flex min-w-0 flex-col gap-2">
            {eyebrow && (
              <p className="text-eyebrow text-[color-mix(in_srgb,var(--color-stage-gold-edge)_85%,white)]">
                {eyebrow}
              </p>
            )}
            <h1 className="font-serif text-3xl font-semibold leading-tight text-[var(--color-stage-text)]">
              {title}
            </h1>
            {description && (
              <p className="max-w-xl text-sm leading-relaxed text-[color-mix(in_srgb,var(--color-stage-text)_72%,transparent)]">
                {description}
              </p>
            )}
          </div>
          {actions && <div className="flex shrink-0 items-center gap-2">{actions}</div>}
        </div>
      </div>
    </header>
  )
}
